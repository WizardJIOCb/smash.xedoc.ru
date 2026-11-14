const {test} = require('node:test');
const assert = require('node:assert/strict');
const {sanitize, cleanUrl, normalize, createTracker, boot} = require('../web/metrika.js');

const frame = changes => ({chapter: 1, room: 1, run_state: 'playing', seconds: 0,
  health: 100, kills: 0, deaths: 0, relays: 0, fps: 60,
  weapon: {id: 'fists'}, night_casts: 0, night_bursts: 0, ...changes});

test('invitation and arbitrary URL values never become analytics parameters', () => {
  const url = 'https://smash.xedoc.ru/?room=SECRET&name=PRIVATE&analytics_qa=1&cache=clear&utm_source=telegram#token';
  assert.equal(cleanUrl(url), 'https://smash.xedoc.ru/?utm_source=telegram');
  assert.equal(cleanUrl(url, url, true), 'https://smash.xedoc.ru/?utm_source=telegram&cache=clear');
  assert.equal(cleanUrl('', url), '');
  assert.equal(cleanUrl('javascript:alert(1)', url), '');
  assert.deepEqual(sanitize({name: 'PRIVATE', code: 'SECRET', error: 'PRIVATE',
    weapon: 'PRIVATE', players: 999, seconds: NaN, chapter: 8, qa: true}),
    {players: 16, chapter: 8, qa: true});
});

test('guest events use the authoritative snapshot and the guest hero', () => {
  const guest = normalize(frame({chapter: 2, seconds: 999, health: 100}), {
    active: true, host: false, you: 'guest', capacity: 16, epoch: 3, code: 'SECRET',
    players: [{name: 'PRIVATE'}], world: {chapter: 7, room: 27, seconds: 17,
      state: 'playing', kills: 4, wave: 2, cleared: [true, false], players: [
        {id: 'host', name: 'PRIVATE', health: 100, gear: {equipped: 'rifle'}},
        {id: 'guest', name: 'PRIVATE', health: 25, gear: {equipped: 'bat'}, power: {casts: 2}}
      ]}
  });
  assert.equal(guest.chapter, 8);
  assert.equal(guest.role, 'guest');
  assert.equal(guest.health, 25);
  assert.equal(guest.weapon, 'bat');
  assert.equal(guest.seconds, 17);
  assert.equal(guest.relays, 1);
  assert.equal(guest.players, 2);
  assert.doesNotMatch(JSON.stringify(guest), /PRIVATE|SECRET/);
});

test('pause, resume and repeated finish samples cannot inflate completed runs', () => {
  const events = [];
  const tracker = createTracker((name, params) => events.push({name, params}));
  const sample = changes => tracker.sample(frame(changes), {}, 0.5);
  sample({run_state: 'menu'});
  assert.equal(events.length, 0);
  sample({});
  sample({seconds: 1});
  sample({seconds: 1, run_state: 'paused'});
  sample({seconds: 1, run_state: 'paused'});
  sample({seconds: 1, run_state: 'playing'});
  sample({seconds: 8, run_state: 'won'});
  sample({seconds: 8, run_state: 'won'});
  sample({seconds: 0});
  sample({seconds: 9, run_state: 'won'});
  const count = name => events.filter(event => event.name === name).length;
  assert.equal(count('chapter_start'), 1);
  assert.equal(count('chapter_pause'), 1);
  assert.equal(count('chapter_resume'), 1);
  assert.equal(count('chapter_restart'), 1);
  assert.equal(count('chapter_complete'), 2);
  assert.equal(tracker.summary().chapters_won, 2);
});

test('hidden time is excluded, defeats deduplicate, checkpoint revival is not a new run', () => {
  const events = [];
  const tracker = createTracker(name => events.push(name));
  tracker.sample(frame({}), {}, 1);
  tracker.sample(frame({seconds: 20}), {}, 20, false);
  tracker.sample(frame({seconds: 21, health: 0, run_state: 'lost'}), {}, 1);
  tracker.sample(frame({seconds: 21, health: 0, run_state: 'lost'}), {}, 1);
  tracker.sample(frame({seconds: 21, health: 100}), {}, 1);
  assert.equal(events.filter(name => name === 'chapter_fail').length, 1);
  assert.equal(events.filter(name => name === 'chapter_start').length, 1);
  assert.equal(events.filter(name => name === 'chapter_restart').length, 1);
  assert.equal(tracker.summary().active_seconds, 2);
});

test('SDK unavailable: game still loads and all queued data is sanitized', () => {
  const attrs = new Map();
  const calls = [], scripts = [], handlers = {};
  const listeners = {};
  const w = {
    location: {href: 'https://smash.xedoc.ru/?room=SECRET&analytics_qa=1'},
    history: {state: null, replaceState: (_, __, url) => { w.location.href = url; }},
    navigator: {maxTouchPoints: 0}, performance: {now: () => 100},
    requestAnimationFrame: () => {}, setInterval: () => {},
    addEventListener: (name, callback) => { handlers[name] = callback; },
    ym: (...args) => calls.push(args),
    document: {
      referrer: 'https://smash.xedoc.ru/?room=SECRET', visibilityState: 'visible',
      body: {setAttribute: (name, value) => attrs.set(name, value), getAttribute: name => attrs.get(name)},
      addEventListener: (name, callback) => { listeners[name] = callback; },
      createElement: () => ({}), head: {appendChild: script => scripts.push(script)}
    }
  };
  boot(w);
  assert.equal(w.smashInviteCode, 'SECRET');
  assert.equal(w.location.href, 'https://smash.xedoc.ru/');
  const init = calls.find(call => call[1] === 'init');
  assert.equal(init[0], 114255834);
  assert.equal(init[2].webvisor, true);
  assert.equal(init[2].clickmap, true);
  assert.equal(init[2].ssr, true);
  assert.equal(init[2].ecommerce, 'dataLayer');
  assert.equal(init[2].referrer, 'https://smash.xedoc.ru/');
  scripts[0].onerror();
  attrs.set('data-game-metrics', JSON.stringify(frame({})));
  w.smashAnalytics.ready();
  w.smashAnalytics.event('coop_join_attempt', {code: 'SECRET', name: 'PRIVATE'});
  w.smashAnalytics.event('arbitrary_PRIVATE', {name: 'PRIVATE'});
  handlers.pagehide();
  handlers.pagehide();
  assert.equal(calls.filter(call => call[2] === 'game_ready').length, 1);
  assert.equal(calls.filter(call => call[2] === 'game_session_end').length, 1);
  assert.doesNotMatch(JSON.stringify(calls), /PRIVATE|SECRET/);
  assert.equal(JSON.parse(attrs.get('data-game-analytics')).sdk, 'unavailable');
  assert.ok(calls.some(call => call[1] === 'params' && call[2].game.milestones.chapter_start));
  w.ym = () => { throw new Error('SDK blocked'); };
  assert.doesNotThrow(() => w.smashAnalytics.event('coop_open'));
});
