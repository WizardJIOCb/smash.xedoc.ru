import http from 'node:http';
import { randomInt } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import WebSocket, { WebSocketServer } from 'ws';

const SNAPSHOT_LIMIT = 256 * 1024;
const INPUT_LIMIT = 4 * 1024;
const CONTROL_LIMIT = 2 * 1024;
const ACTION = /^[a-zA-Z][a-zA-Z0-9_]{0,39}$/;
const isObject = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const isChapter = value => Number.isInteger(value) && value >= 0 && value <= 255;

export function createRelay(options = {}) {
  const rooms = new Map();
  const clients = new Set();
  const origins = new Set(options.origins ?? ['https://smash.xedoc.ru']);
  const heartbeatMs = options.heartbeatMs ?? 15000;
  const maxBuffered = options.maxBuffered ?? 1024 * 1024;
  const maxClients = options.maxClients ?? 2048;
  const maxRooms = options.maxRooms ?? 512;

  function originAllowed(origin) {
    // Native Godot / non-browser clients do not always send Origin. This is
    // browser cross-origin isolation, not player authentication.
    if (!origin || origins.has(origin)) return true;
    try {
      const url = new URL(origin);
      return ['http:', 'https:'].includes(url.protocol) &&
        ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
    } catch { return false; }
  }

  const server = http.createServer((request, response) => {
    if (request.method === 'GET' && request.url === '/health') {
      response.writeHead(200, { 'content-type': 'application/json', 'cache-control': 'no-store' });
      response.end(JSON.stringify({ ok: true, service: 'los-coop', rooms: rooms.size, clients: clients.size }));
    } else { response.writeHead(404); response.end(); }
  });
  const wss = new WebSocketServer({ noServer: true, maxPayload: SNAPSHOT_LIMIT, perMessageDeflate: false });
  server.on('upgrade', (request, socket, head) => {
    if (!['/', '/ws', '/coop', '/coop/'].includes(request.url?.split('?')[0])) {
      socket.end('HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n'); return;
    }
    if (!originAllowed(request.headers.origin) || clients.size >= maxClients) {
      socket.end('HTTP/1.1 403 Forbidden\r\nConnection: close\r\n\r\n'); return;
    }
    wss.handleUpgrade(request, socket, head, ws => wss.emit('connection', ws));
  });

  function send(client, message) {
    if (client.ws.readyState !== WebSocket.OPEN) return;
    if (client.ws.bufferedAmount > maxBuffered) {
      client.ws.terminate(); return;
    }
    client.ws.send(typeof message === 'string' ? message : JSON.stringify(message));
  }
  function fail(client, message) { send(client, { type: 'error', message }); }
  function roomState(room) {
    return {
      code: room.code, capacity: room.capacity, host: room.host.id,
      players: [...room.members.values()].map(client => ({ id: client.id, name: client.name })),
      started: room.started, chapter: room.chapter,
    };
  }
  function broadcastRoom(room) {
    const state = roomState(room);
    for (const member of room.members.values()) send(member, { type: 'room', you: member.id, room: state });
  }
  function broadcast(room, message, exclude) {
    const data = JSON.stringify(message);
    for (const member of room.members.values()) if (member !== exclude) send(member, data);
  }
  function leave(client) {
    const room = client.room;
    if (!room) return;
    client.room = null;
    room.members.delete(client.id);
    if (client === room.host) {
      rooms.delete(room.code);
      for (const member of room.members.values()) {
        member.room = null;
        send(member, { type: 'closed', reason: 'Хозяин вышел. Создайте новую игру, чтобы продолжить вместе.' });
      }
      room.members.clear();
      room.snapshot = null;
    } else { broadcastRoom(room); }
  }
  function validIdentity(message) {
    return typeof message.name === 'string' && message.name.trim().length >= 1 &&
      message.name.trim().length <= 24 && !/[\u0000-\u001f\u007f]/.test(message.name) &&
      typeof message.build === 'string' && /^[a-zA-Z0-9._-]{1,80}$/.test(message.build);
  }
  function code() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let result;
    do { result = Array.from({ length: 6 }, () => alphabet[randomInt(alphabet.length)]).join(''); }
    while (rooms.has(result));
    return result;
  }
  function charge(client, category, limit) {
    const now = Date.now();
    if (now - client.rateStart >= 1000) { client.rateStart = now; client.rates = {}; }
    client.rates[category] = (client.rates[category] ?? 0) + 1;
    if (client.rates[category] > limit) {
      client.ws.close(1008, 'Слишком много сообщений'); return false;
    }
    return true;
  }
  function handle(client, data, binary) {
    if (binary) return fail(client, 'Нужны текстовые сообщения JSON.');
    if (!charge(client, 'all', 180)) return;
    let message;
    try { message = JSON.parse(data.toString()); }
    catch { return fail(client, 'Не удалось прочитать JSON.'); }
    if (!isObject(message) || typeof message.type !== 'string') return fail(client, 'Некорректное сообщение.');
    const limit = message.type === 'snapshot' ? SNAPSHOT_LIMIT : message.type === 'input' ? INPUT_LIMIT : CONTROL_LIMIT;
    if (data.length > limit) { client.ws.close(1009, 'Слишком большое сообщение'); return; }
    if (['create', 'join', 'start', 'chapter', 'leave'].includes(message.type) && !charge(client, 'control', 8)) return;

    if (message.type === 'leave') { leave(client); send(client, { type: 'left' }); return; }
    if (message.type === 'create' || message.type === 'join') {
      if (client.room) return fail(client, 'Сначала выйдите из текущей комнаты.');
      if (!validIdentity(message)) return fail(client, 'Укажите имя (1–24 символа) и версию игры.');
      let room;
      if (message.type === 'create') {
        if (!Number.isInteger(message.capacity) || message.capacity < 2 || message.capacity > 16)
          return fail(client, 'В комнате может быть от 2 до 16 игроков.');
        if (rooms.size >= maxRooms) return fail(client, 'Сервер занят. Попробуйте создать игру позже.');
        room = { code: code(), capacity: message.capacity, build: message.build, host: client,
          members: new Map(), started: false, chapter: 0, nextId: 1, snapshot: null };
        rooms.set(room.code, room);
      } else {
        if (typeof message.room !== 'string') return fail(client, 'Укажите код комнаты.');
        room = rooms.get(message.room.trim().toUpperCase());
        if (!room) return fail(client, 'Комната не найдена. Проверьте код.');
        if (room.build !== message.build) return fail(client, 'Версии игры отличаются. Обновите страницу у всех игроков.');
        if (room.members.size >= room.capacity) return fail(client, 'Комната заполнена.');
      }
      client.id = String(room.nextId++);
      client.name = message.name.trim();
      client.room = room;
      client.lastSeq = -1;
      room.members.set(client.id, client);
      broadcastRoom(room);
      if (room.snapshot && client !== room.host) send(client, room.snapshot);
      return;
    }

    const room = client.room;
    if (!room) return fail(client, 'Сначала создайте комнату или вступите по коду.');
    if (message.type === 'start' || message.type === 'chapter') {
      if (client !== room.host) return fail(client, 'Начать игру может только хозяин комнаты.');
      if (!isChapter(message.chapter)) return fail(client, 'Некорректная глава.');
      if (message.type === 'start' && room.started) return fail(client, 'Игра уже началась.');
      if (room.members.size < 2) return fail(client, 'Для совместной игры нужны хотя бы два игрока.');
      room.started = true;
      room.chapter = message.chapter;
      room.snapshot = null;
      for (const member of room.members.values()) member.lastSeq = -1;
      broadcast(room, { type: 'start', chapter: room.chapter });
      broadcastRoom(room);
      return;
    }
    if (message.type === 'input') {
      if (!room.started) return fail(client, 'Игра ещё не началась.');
      if (client === room.host) return fail(client, 'Хозяин обрабатывает свой ввод локально.');
      if (!charge(client, 'input', 120)) return;
      if (!isObject(message.held) || Object.keys(message.held).length > 32 ||
          !Object.entries(message.held).every(([action, held]) => ACTION.test(action) && typeof held === 'boolean') ||
          !Array.isArray(message.pressed) || message.pressed.length > 32 ||
          !message.pressed.every(action => typeof action === 'string' && ACTION.test(action)) ||
          !Number.isSafeInteger(message.seq) || message.seq < 0)
        return fail(client, 'Некорректный ввод игрока.');
      if (message.seq <= client.lastSeq) return;
      client.lastSeq = message.seq;
      send(room.host, { type: 'input', id: client.id, held: message.held, pressed: message.pressed, seq: message.seq });
      return;
    }
    if (message.type === 'snapshot') {
      if (client !== room.host) return fail(client, 'Состояние игры передаёт только хозяин комнаты.');
      if (!room.started || !isObject(message.state)) return fail(client, 'Некорректное состояние игры.');
      if (!charge(client, 'snapshot', 40)) return;
      room.snapshot = JSON.stringify({ type: 'snapshot', state: message.state });
      for (const member of room.members.values()) if (member !== client) send(member, room.snapshot);
      return;
    }
    fail(client, 'Неизвестный тип сообщения.');
  }

  wss.on('connection', ws => {
    const client = { ws, room: null, id: null, name: '', alive: true, rateStart: Date.now(), rates: {} };
    clients.add(client);
    ws.on('pong', () => { client.alive = true; });
    ws.on('message', (data, binary) => handle(client, data, binary));
    ws.on('error', () => {}); // close handler releases room membership.
    ws.on('close', () => { leave(client); clients.delete(client); });
  });
  const heartbeat = setInterval(() => {
    for (const client of clients) {
      if (!client.alive) { client.ws.terminate(); continue; }
      client.alive = false;
      if (client.ws.readyState === WebSocket.OPEN) client.ws.ping();
    }
  }, heartbeatMs);
  heartbeat.unref();

  return {
    server,
    listen(port = 8791, host = '127.0.0.1') {
      return new Promise((resolve, reject) => {
        server.once('error', reject);
        server.listen(port, host, () => { server.off('error', reject); resolve(server.address()); });
      });
    },
    async close() {
      clearInterval(heartbeat);
      for (const client of clients) client.ws.terminate();
      await new Promise(resolve => wss.close(resolve));
      await new Promise(resolve => server.close(resolve));
    },
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const relay = createRelay({ origins: process.env.COOP_ORIGINS?.split(',').map(value => value.trim()).filter(Boolean) });
  const port = Number(process.env.PORT ?? 8791);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid PORT');
  const address = await relay.listen(port, process.env.HOST ?? '127.0.0.1');
  console.log(`Los coop relay listening on ${address.address}:${address.port}`);
  let stopping = false;
  const stop = async () => { if (stopping) return; stopping = true; await relay.close(); process.exit(0); };
  process.on('SIGTERM', stop);
  process.on('SIGINT', stop);
}
