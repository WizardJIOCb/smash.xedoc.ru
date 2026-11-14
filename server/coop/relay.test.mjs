import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import WebSocket from 'ws';
import { createRelay } from './relay.mjs';

async function fixture(t, options = {}) {
  const relay = createRelay(options);
  const address = await relay.listen(0);
  const url = `ws://127.0.0.1:${address.port}/coop`;
  t.after(() => relay.close());
  async function connect() {
    const socket = new WebSocket(url, { origin: 'https://smash.xedoc.ru' });
    const queue = [];
    let waiter;
    socket.on('message', data => { queue.push(JSON.parse(data)); waiter?.(); });
    await once(socket, 'open');
    return {
      socket,
      send(message) { socket.send(JSON.stringify(message)); },
      async next(type) {
        const deadline = Date.now() + 3000;
        while (Date.now() < deadline) {
          const index = queue.findIndex(message => message.type === type);
          if (index >= 0) return queue.splice(index, 1)[0];
          await new Promise(resolve => {
            const timer = setTimeout(() => { waiter = null; resolve(); }, Math.max(1, deadline - Date.now()));
            waiter = () => { clearTimeout(timer); waiter = null; resolve(); };
          });
        }
        throw new Error(`Timed out waiting for ${type}; queued ${JSON.stringify(queue)}`);
      },
      queued(type) { return queue.filter(message => message.type === type); },
    };
  }
  return { relay, url, address, connect };
}
async function create(host, capacity = 2) {
  host.send({ type: 'create', name: 'Лось', capacity, build: 'test-build' });
  return (await host.next('room')).room;
}
async function join(guest, room, name = 'Друг') {
  guest.send({ type: 'join', name, room: room.code, build: 'test-build' });
  return guest.next('room');
}

test('health, two-player lobby, capacity and matching builds', async t => {
  const { connect, address } = await fixture(t);
  const health = await fetch(`http://127.0.0.1:${address.port}/health`).then(response => response.json());
  assert.equal(health.ok, true);
  const host = await connect();
  const room = await create(host);
  assert.equal(room.capacity, 2);
  assert.equal(room.host, '1');
  assert.match(room.code, /^[A-Z2-9]{6}$/);
  const guest = await connect();
  guest.send({ type: 'join', name: 'Old', room: room.code, build: 'old' });
  assert.match((await guest.next('error')).message, /Версии/);
  const joined = await join(guest, room);
  assert.equal(joined.you, '2');
  assert.equal(joined.room.players.length, 2);
  assert.equal((await host.next('room')).you, '1');
  const overflow = await connect();
  overflow.send({ type: 'join', name: 'Third', room: room.code, build: 'test-build' });
  assert.match((await overflow.next('error')).message, /заполнена/);
});

test('all sixteen slots join and slot seventeen is rejected', async t => {
  const { connect } = await fixture(t);
  const host = await connect();
  const room = await create(host, 16);
  const guests = [];
  let last;
  for (let i = 2; i <= 16; i++) {
    const guest = await connect();
    guests.push(guest);
    last = await join(guest, room, `Друг ${i}`);
    assert.equal(last.you, String(i));
  }
  assert.equal(last.room.players.length, 16);
  assert.equal(new Set(last.room.players.map(player => player.id)).size, 16);
  const overflow = await connect();
  overflow.send({ type: 'join', name: 'Overflow', room: room.code, build: 'test-build' });
  assert.match((await overflow.next('error')).message, /заполнена/);
  host.send({ type: 'start', chapter: 0 });
  await Promise.all(guests.map(guest => guest.next('start')));
  for (const guest of guests) guest.send({ type: 'input', held: { right: true }, pressed: [], seq: 1 });
  const receivedIds = [];
  for (const guest of guests) receivedIds.push((await host.next('input')).id);
  assert.equal(new Set(receivedIds).size, 15);
  const state = { players: Array.from({ length: 16 }, (_, index) => ({ id: String(index + 1), hp: 100 })) };
  host.send({ type: 'snapshot', state });
  for (const guest of guests) {
    assert.deepEqual((await guest.next('snapshot')).state, state);
    assert.equal(guest.queued('input').length, 0);
  }
});

test('host authority, inputs, snapshots, late join and chapter reset', async t => {
  const { connect } = await fixture(t);
  const host = await connect();
  const room = await create(host, 3);
  const guest = await connect();
  await join(guest, room);
  guest.send({ type: 'start', chapter: 0 });
  assert.match((await guest.next('error')).message, /хозяин/);
  host.send({ type: 'start', chapter: 0 });
  assert.equal((await guest.next('start')).chapter, 0);
  await host.next('start');
  guest.send({ type: 'snapshot', state: { hacked: true } });
  assert.match((await guest.next('error')).message, /хозяин/);
  guest.send({ type: 'input', id: '1', held: { move_left: true }, pressed: ['jump'], seq: 3 });
  assert.deepEqual(await host.next('input'), {
    type: 'input', id: '2', held: { move_left: true }, pressed: ['jump'], seq: 3,
  });
  const state = { version: 2, players: [{ id: '1', x: 100 }], enemies: [{ hp: 50 }] };
  host.send({ type: 'snapshot', state });
  assert.deepEqual((await guest.next('snapshot')).state, state);
  const late = await connect();
  const lateRoom = await join(late, room, 'Опоздал');
  assert.equal(lateRoom.room.started, true);
  assert.equal(lateRoom.room.chapter, 0);
  assert.deepEqual((await late.next('snapshot')).state, state);
  guest.send({ type: 'chapter', chapter: 1 });
  assert.match((await guest.next('error')).message, /хозяин/);
  host.send({ type: 'chapter', chapter: 1 });
  assert.equal((await late.next('start')).chapter, 1);
  assert.equal((await guest.next('start')).chapter, 1);
  await host.next('start');
  guest.send({ type: 'input', held: {}, pressed: ['jump'], seq: 0 });
  assert.equal((await host.next('input')).seq, 0);
});

test('guest disconnect frees slot, explicit leave works, host disconnect closes room', async t => {
  const { connect } = await fixture(t);
  const host = await connect();
  const room = await create(host);
  const guest = await connect();
  await join(guest, room);
  await host.next('room');
  guest.socket.close();
  const departed = await host.next('room');
  assert.equal(departed.room.players.length, 1);
  const replacement = await connect();
  assert.equal((await join(replacement, room)).you, '3');
  replacement.send({ type: 'leave' });
  await replacement.next('left');
  await join(replacement, room);
  host.socket.close();
  assert.match((await replacement.next('closed')).reason, /Хозяин вышел/);
  const newcomer = await connect();
  newcomer.send({ type: 'join', name: 'New', room: room.code, build: 'test-build' });
  assert.match((await newcomer.next('error')).message, /не найдена/);
  assert.equal((await create(replacement)).host, '1');
});

test('invalid controls, payload bounds and browser Origin restrictions', async t => {
  const { connect, url } = await fixture(t);
  const host = await connect();
  for (const capacity of [1, 17, 2.5]) {
    host.send({ type: 'create', name: 'Лось', capacity, build: 'test-build' });
    assert.match((await host.next('error')).message, /2 до 16/);
  }
  const room = await create(host);
  host.send({ type: 'start', chapter: 0 });
  assert.match((await host.next('error')).message, /два игрока/);
  const guest = await connect();
  await join(guest, room);
  host.send({ type: 'start', chapter: 0 });
  await guest.next('start');
  guest.send({ type: 'input', held: { jump: 'yes' }, pressed: [], seq: 0 });
  assert.match((await guest.next('error')).message, /ввод/);
  const oversizedClosed = once(guest.socket, 'close');
  guest.send({ type: 'input', held: {}, pressed: [], seq: 1, padding: 'x'.repeat(4096) });
  assert.equal((await oversizedClosed)[0], 1009);
  const denied = new WebSocket(url, { origin: 'https://evil.example' });
  const deniedError = once(denied, 'error');
  assert.match((await deniedError)[0].message, /403/);
});

test('heartbeat removes unresponsive peers and host shutdown ends session', async t => {
  const { connect } = await fixture(t, { heartbeatMs: 25 });
  const host = await connect();
  const room = await create(host);
  const guest = await connect();
  await join(guest, room);
  host.socket._autoPong = false;
  assert.match((await guest.next('closed')).reason, /Хозяин вышел/);
});
