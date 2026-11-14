// Against a real Godot host, not a substitute simulation. Run only against an
// explicitly prepared test room: this fills its fifteen remaining slots.
import WebSocket from 'ws';
import { setTimeout as delay } from 'node:timers/promises';

const flags = Object.fromEntries(process.argv.slice(2).map(argument => {
  const separator = argument.indexOf('=');
  if (!argument.startsWith('--') || separator < 0) throw new Error(`Invalid argument: ${argument}`);
  return [argument.slice(2, separator), argument.slice(separator + 1)];
}));
const room = flags.room?.trim().toUpperCase();
const build = flags.build;
const url = flags.url ?? 'ws://127.0.0.1:8791/coop';
const seconds = Number(flags.seconds ?? 10);
if (!room || !build || !Number.isFinite(seconds) || seconds < 2 || seconds > 300 ||
    Object.keys(flags).some(key => !['room', 'build', 'url', 'seconds'].includes(key))) {
  throw new Error('Usage: node stress-native.mjs --room=CODE --build=coop1-HASH [--url=ws://127.0.0.1:8791/coop] [--seconds=10]');
}

const errors = [];
const clients = [];
let stopping = false;
let recording = false;
let startedAt = 0;
function fail(message) {
  if (errors.length < 50 && !errors.includes(message)) errors.push(message);
}
function send(client, packet) {
  if (client.ws.readyState === WebSocket.OPEN) client.ws.send(JSON.stringify(packet));
}
function inspectSnapshot(client, state) {
  if (!state || !Array.isArray(state.players)) throw new Error('Snapshot has no players array');
  if (state.players.length !== 16) {
    if (recording) fail(`${client.name}: expected 16 players, received ${state.players.length}`);
    return;
  }
  const ids = state.players.map(player => String(player.id));
  if (new Set(ids).size !== 16) throw new Error('Duplicate player IDs');
  for (const player of state.players) {
    if (!Number.isFinite(player.x) || !Number.isFinite(player.y))
      throw new Error(`Non-finite position for ${player.id}`);
  }
  if (!client.id) throw new Error('Snapshot arrived before own ID');
  const own = state.players.find(player => String(player.id) === client.id);
  if (!own) throw new Error(`Missing own player ${client.id}`);
  client.started = true;
  client.fullSnapshots++;
  if (!recording) return;
  client.snapshots++;
  const sample = { x: own.x, y: own.y, serial: own.attack?.serial ?? null };
  if (sample.serial !== null && !Number.isFinite(sample.serial)) throw new Error('Non-finite attack serial');
  if (!client.first) client.first = sample;
  if (sample.x !== client.first.x || sample.y !== client.first.y || sample.serial !== client.first.serial)
    client.changed = true;
  client.last = sample;
}

async function connect(index) {
  const client = {
    name: `Нагрузка ${String(index + 1).padStart(2, '0')}`, id: '', ws: new WebSocket(url),
    started: false, snapshots: 0, fullSnapshots: 0, inputs: 0, changed: false,
    first: null, last: null, sequence: 0, lastKick: -1, jumped: false, timer: null,
  };
  clients.push(client);
  await new Promise((resolve, reject) => {
    let joined = false;
    const timeout = setTimeout(() => reject(new Error(`${client.name}: join timeout`)), 10000);
    const rejectJoin = error => { clearTimeout(timeout); reject(error); };
    client.ws.on('open', () => send(client, { type: 'join', room, build, name: client.name }));
    client.ws.on('error', error => {
      if (!stopping) fail(`${client.name}: socket ${error.message}`);
      if (!joined) rejectJoin(error);
    });
    client.ws.on('close', (code, reason) => {
      if (!stopping) fail(`${client.name}: disconnected ${code} ${reason.toString()}`);
      if (!joined) rejectJoin(new Error(`${client.name}: closed before join`));
    });
    client.ws.on('message', bytes => {
      if (stopping) return;
      try {
        const packet = JSON.parse(bytes.toString());
        if (packet.type === 'error' || packet.type === 'closed') {
          const message = `${client.name}: ${packet.message ?? packet.reason}`;
          fail(message);
          if (!joined) rejectJoin(new Error(message));
        } else if (packet.type === 'room') {
          client.id = String(packet.you);
          client.started ||= Boolean(packet.room.started);
          if (!joined) { joined = true; clearTimeout(timeout); resolve(); }
        } else if (packet.type === 'start') { client.started = true; }
        else if (packet.type === 'snapshot') { inspectSnapshot(client, packet.state); }
      } catch (error) { fail(`${client.name}: ${error.message}`); }
    });
  });
  client.timer = setInterval(() => {
    if (!client.started || !recording || stopping) return;
    const elapsed = (Date.now() - startedAt) / 1000;
    const right = (index + Math.floor(elapsed / 1.5)) % 2 === 0;
    const pressed = [];
    const kick = Math.floor(elapsed / 0.4);
    if (kick > client.lastKick) { pressed.push('kick'); client.lastKick = kick; }
    if (!client.jumped) { pressed.push('jump'); client.jumped = true; }
    send(client, {
      type: 'input', seq: ++client.sequence,
      held: { left: !right, right, sprint: true, kick: false, jump: false }, pressed,
    });
    client.inputs++;
  }, 50);
}

try {
  await Promise.all(Array.from({ length: 15 }, (_, index) => connect(index)));
  const readyDeadline = Date.now() + 15000;
  while (!clients.every(client => client.fullSnapshots > 0) && Date.now() < readyDeadline && errors.length === 0)
    await delay(25);
  if (!clients.every(client => client.fullSnapshots > 0)) throw new Error('No complete 16-player snapshots from Godot host within 15 seconds');
  if (new Set(clients.map(client => client.id)).size !== 15) throw new Error('Guests received duplicate IDs');
  startedAt = Date.now();
  recording = true;
  await delay(seconds * 1000);
  for (const client of clients) {
    if (client.snapshots <= 5) fail(`${client.name}: only ${client.snapshots} snapshots during run`);
    if (!client.changed) fail(`${client.name}: own position and attack serial never changed`);
    if (client.inputs < 5) fail(`${client.name}: only ${client.inputs} input packets sent`);
  }
} catch (error) { fail(error.message); }
finally {
  stopping = true;
  for (const client of clients) {
    clearInterval(client.timer);
    client.ws.close();
  }
  await Promise.all(clients.map(client => new Promise(resolve => {
    if (client.ws.readyState === WebSocket.CLOSED) { resolve(); return; }
    const timeout = setTimeout(() => { client.ws.terminate(); resolve(); }, 1000);
    client.ws.once('close', () => { clearTimeout(timeout); resolve(); });
  })));
}

console.log(JSON.stringify({
  ok: errors.length === 0, room, build, url, requestedSeconds: seconds,
  observedSeconds: startedAt ? Number(((Date.now() - startedAt) / 1000).toFixed(2)) : 0,
  guests: clients.map(({ name, id, snapshots, inputs, changed, first, last }) => ({ name, id, snapshots, inputs, changed, first, last })),
  errors,
}, null, 2));
if (errors.length > 0) process.exitCode = 1;
