/* Game analytics: meaningful milestones only, with an explicit parameter allowlist. */
(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root.document) api.boot(root);
})(typeof window === 'object' ? window : globalThis, function () {
  'use strict';
  const COUNTER = 114255834;
  const GOALS = new Set([
    'game_load_start', 'game_ready', 'game_load_error', 'game_engaged', 'game_session_end',
    'menu_open', 'chapter_select', 'chapter_start', 'chapter_resume', 'chapter_pause',
    'chapter_restart', 'chapter_complete', 'chapter_fail', 'chapter_leave',
    'room_enter', 'relay_clear', 'player_down', 'player_revive', 'weapon_change', 'power_use',
    'coop_open', 'coop_create_attempt', 'coop_join_attempt', 'coop_room_create',
    'coop_room_join', 'coop_invite_copy', 'coop_leave', 'coop_error', 'performance_summary'
  ]);
  const ENUMS = {
    mode: ['solo', 'coop'], role: ['solo', 'host', 'guest'],
    menu: ['home', 'chapters', 'intro', 'finish', 'records', 'help', 'settings', 'controls'],
    weapon: ['fists', 'knuckles', 'bat', 'shovel', 'hockey', 'pistol', 'rifle'],
    reason: ['client', 'connection', 'host_left', 'server', 'load', 'chapter_change', 'menu'],
    power: ['ultimate', 'impulse'], result: ['won', 'lost', 'left'],
    input: ['touch', 'keyboard'], entry: ['invite', 'direct'], cache: ['cold', 'warm', 'mixed'],
    fps_band: ['under_20', '20_39', '40_59', '60_plus'],
    load_band: ['under_5s', '5_15s', '15_30s', '30_60s', '60s_plus']
  };
  const LIMITS = {
    chapter: [1, 255], room: [1, 1024], players: [1, 16], capacity: [1, 16],
    seconds: [0, 86400], health: [0, 100], kills: [0, 10000], deaths: [0, 1000],
    relays: [0, 1024], wave: [1, 100], load_ms: [0, 600000], fps: [0, 240],
    cache_hits: [0, 100], downloads: [0, 100], active_seconds: [0, 86400],
    chapters_started: [0, 1000], chapters_won: [0, 1000], version: [1, 100000]
  };
  const UTM = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_content', 'utm_term'];
  function sanitize(values = {}) {
    const result = {};
    for (const [key, allowed] of Object.entries(ENUMS)) {
      if (allowed.includes(values[key])) result[key] = values[key];
    }
    for (const [key, [low, high]] of Object.entries(LIMITS)) {
      if (typeof values[key] === 'number' && Number.isFinite(values[key])) {
        result[key] = Math.round(Math.min(high, Math.max(low, values[key])));
      }
    }
    if (typeof values.qa === 'boolean') result.qa = values.qa;
    return result;
  }
  function cleanUrl(value, base, functional = false) {
    if (!value) return '';
    try {
      const url = new URL(value, base);
      if (!['https:', 'http:'].includes(url.protocol)) return '';
      const kept = new URLSearchParams();
      for (const key of UTM) {
        const text = (url.searchParams.get(key) || '').replace(/[\x00-\x1f]/g, '').slice(0, 100);
        if (text) kept.set(key, text);
      }
      if (functional && url.searchParams.get('cache') === 'clear') kept.set('cache', 'clear');
      url.search = kept.toString();
      url.hash = '';
      return url.href;
    } catch (_) { return ''; }
  }
  const fpsBand = fps => fps < 20 ? 'under_20' : fps < 40 ? '20_39' : fps < 60 ? '40_59' : '60_plus';
  function normalize(game = {}, coop = {}) {
    const inRoom = coop.connected === true || coop.active === true;
    const multiplayer = coop.active === true && coop.world && Array.isArray(coop.world.players);
    const world = multiplayer ? coop.world : {};
    const hero = multiplayer ? world.players.find(player => String(player.id) === String(coop.you)) : null;
    const raw = {
      mode: inRoom ? 'coop' : 'solo', role: inRoom ? (coop.host ? 'host' : 'guest') : 'solo',
      chapter: multiplayer ? Number(world.chapter) + 1 : game.chapter,
      room: multiplayer ? Number(world.room) + 1 : game.room,
      players: multiplayer ? world.players.length : inRoom ? coop.players?.length : 1,
      capacity: inRoom ? coop.capacity : 1,
      seconds: multiplayer ? world.seconds : game.seconds,
      health: multiplayer ? hero?.health : game.health,
      weapon: multiplayer ? hero?.gear?.equipped : game.weapon?.id,
      kills: multiplayer ? world.kills : game.kills, deaths: multiplayer ? undefined : game.deaths,
      relays: multiplayer ? world.cleared?.filter(Boolean).length : game.relays,
      wave: multiplayer ? Number(world.wave) + 1 : game.wave,
      fps: game.fps, input: game.touch_controls ? 'touch' : 'keyboard'
    };
    return {
      ...sanitize(raw), state: multiplayer ? world.state : game.run_state,
      epoch: multiplayer ? coop.epoch : null,
      casts: multiplayer ? hero?.power?.casts : game.night_casts,
      bursts: multiplayer ? hero?.power?.bursts : game.night_bursts,
      menu: game.menu
    };
  }
  function createTracker(send) {
    let previous = null;
    let run = null;
    let activeSeconds = 0;
    let started = 0;
    let won = 0;
    let engaged = false;
    let fpsSum = 0;
    let fpsCount = 0;
    const emit = (name, frame, extra = {}) => send(name, sanitize({...frame, ...extra}));
    function finish(reason) {
      if (run && !run.finished) emit('chapter_leave', previous, {reason, result: 'left'});
      run = null;
    }
    function sample(game, coop, delta, visible = true) {
      const frame = normalize(game, coop);
      const playing = frame.state === 'playing';
      if (!frame.chapter) return;
      const newChapter = playing && (!run || run.chapter !== frame.chapter || run.mode !== frame.mode);
      const freshTimer = playing && run && previous && frame.seconds + 0.5 < previous.seconds;
      const restart = playing && run && previous && (
        ['lost', 'won'].includes(previous.state) || freshTimer ||
        (frame.epoch !== previous.epoch && frame.room === previous.room)
      );
      if (newChapter) {
        if (run) finish('chapter_change');
        run = {chapter: frame.chapter, mode: frame.mode, finished: false};
        started++;
        emit('chapter_start', frame);
        emit('room_enter', frame);
      } else if (restart) {
        run.finished = false;
        emit('chapter_restart', frame);
      } else if (playing && previous?.state === 'paused') emit('chapter_resume', frame);
      if (run) {
        if (playing && visible) {
          activeSeconds += Math.min(2, Math.max(0, delta));
          if (Number.isFinite(frame.fps) && frame.fps > 0) { fpsSum += frame.fps; fpsCount++; }
          if (!engaged && activeSeconds >= 30) { engaged = true; emit('game_engaged', frame); }
        }
        if (previous && !newChapter && !restart) {
          if (frame.room !== previous.room && playing) emit('room_enter', frame);
          if (frame.relays > previous.relays) emit('relay_clear', frame);
          if (frame.weapon && frame.weapon !== previous.weapon && playing) emit('weapon_change', frame);
          if (frame.health === 0 && previous.health > 0) emit('player_down', frame);
          if (frame.health > 0 && previous.health === 0 && playing) emit('player_revive', frame);
          if (frame.casts > previous.casts) emit('power_use', frame, {power: 'ultimate'});
          if (frame.bursts > previous.bursts) emit('power_use', frame, {power: 'impulse'});
          if (frame.state === 'paused' && previous.state !== 'paused') emit('chapter_pause', frame);
        }
        if (frame.state === 'won' && !run.finished) {
          run.finished = true; won++; emit('chapter_complete', frame, {result: 'won'});
          if (fpsCount) emit('performance_summary', frame, {fps: fpsSum / fpsCount, fps_band: fpsBand(fpsSum / fpsCount)});
        } else if (frame.state === 'lost' && previous?.state !== 'lost') {
          emit('chapter_fail', frame, {result: 'lost'});
        } else if (frame.state === 'menu') finish('menu');
      }
      previous = frame;
    }
    return {
      sample,
      context: () => sanitize(previous || {}),
      summary: () => sanitize({active_seconds: activeSeconds, chapters_started: started, chapters_won: won}),
      end: () => {
        emit('game_session_end', previous || {}, {
          active_seconds: activeSeconds, chapters_started: started, chapters_won: won,
          ...(fpsCount ? {fps: fpsSum / fpsCount, fps_band: fpsBand(fpsSum / fpsCount)} : {})
        });
      }
    };
  }
  function boot(w) {
    if (w.smashAnalytics) return;
    const d = w.document;
    const original = new URL(w.location.href);
    w.smashInviteCode = original.searchParams.get('room') || '';
    const qa = original.searchParams.get('analytics_qa') === '1';
    const clean = cleanUrl(w.location.href, w.location.href, true);
    if (clean && clean !== w.location.href) w.history.replaceState(w.history.state, '', clean);
    const common = {
      version: Number('__GAME_BUILD_VERSION__'), qa,
      entry: w.smashInviteCode ? 'invite' : 'direct',
      input: w.navigator.maxTouchPoints > 0 ? 'touch' : 'keyboard'
    };
    w.dataLayer = w.dataLayer || [];
    w.ym = w.ym || function () { (w.ym.a = w.ym.a || []).push(arguments); };
    w.ym.l = w.ym.l || Date.now();
    w.ym(COUNTER, 'init', {
      ssr: true, webvisor: true, clickmap: true, ecommerce: 'dataLayer',
      accurateTrackBounce: true, trackLinks: true, triggerEvent: true,
      url: cleanUrl(w.location.href, w.location.href),
      referrer: cleanUrl(d.referrer || '', w.location.href),
      params: {game: sanitize(common)}
    });
    let count = 0;
    let ready = false;
    let lastAt = w.performance.now();
    let ended = false;
    const recent = [];
    const counts = new Map();
    const status = {counter: COUNTER, sdk: 'loading', events: 0, recent};
    const publish = () => d.body?.setAttribute('data-game-analytics', JSON.stringify(status));
    d.addEventListener('yacounter' + COUNTER + 'inited', () => { status.sdk = 'initialized'; publish(); });
    const visitKeys = ['mode', 'role', 'chapter', 'room', 'players', 'capacity', 'weapon', 'entry',
      'input', 'version', 'qa', 'cache', 'fps_band', 'load_band', 'result'];
    const call = (...args) => {
      try { w.ym(COUNTER, ...args); } catch (_) { status.sdk = 'unavailable'; }
    };
    function send(name, params = {}) {
      if (!GOALS.has(name) || count >= 250 || (counts.get(name) || 0) >= 40) return;
      const details = sanitize({...common, ...tracker.context(), ...params});
      count++; counts.set(name, (counts.get(name) || 0) + 1);
      call('reachGoal', name, {game: details});
      const visit = Object.fromEntries(visitKeys.filter(key => key in details).map(key => [key, details[key]]));
      visit.milestones = {[name]: true};
      if (['chapter_complete', 'chapter_fail', 'game_session_end'].includes(name)) {
        Object.assign(visit, tracker.summary(), sanitize({seconds: details.seconds, kills: details.kills,
          health: details.health, deaths: details.deaths, relays: details.relays}));
      }
      call('params', {game: visit});
      recent.push({name, params: details}); if (recent.length > 12) recent.shift();
      status.events = count; publish();
    }
    const tracker = createTracker(send);
    let frames = 0, fpsAt = w.performance.now(), clientFps = 0;
    const measureFps = now => {
      frames++;
      if (now - fpsAt >= 1000) { clientFps = frames * 1000 / (now - fpsAt); frames = 0; fpsAt = now; }
      w.requestAnimationFrame(measureFps);
    };
    w.requestAnimationFrame(measureFps);
    const jsonAttr = name => {
      try { return JSON.parse(d.body.getAttribute(name) || '{}'); } catch (_) { return {}; }
    };
    const sample = () => {
      const now = w.performance.now();
      const delta = Math.min(2, (now - lastAt) / 1000); lastAt = now;
      if (ready) {
        const game = jsonAttr('data-game-metrics');
        if (clientFps > 0) game.fps = clientFps;
        tracker.sample(game, jsonAttr('data-coop-metrics'), delta, d.visibilityState !== 'hidden');
      }
    };
    w.smashAnalytics = {
      event: (name, params) => { sample(); send(name, params); },
      ready: () => {
        if (ready) return;
        ready = true; lastAt = w.performance.now();
        const cache = jsonAttr('data-game-cache');
        const ms = w.performance.now();
        send('game_ready', {load_ms: ms, load_band: ms < 5000 ? 'under_5s' : ms < 15000 ? '5_15s' : ms < 30000 ? '15_30s' : ms < 60000 ? '30_60s' : '60s_plus',
          cache_hits: cache.hits || 0, downloads: cache.downloads || 0,
          cache: cache.hits > 0 ? (cache.downloads > 0 ? 'mixed' : 'warm') : 'cold'});
        sample();
      }
    };
    const script = d.createElement('script'); script.async = true;
    script.src = 'https://mc.yandex.ru/metrika/tag.js?id=' + COUNTER;
    script.onload = () => { if (status.sdk !== 'initialized') status.sdk = 'loaded'; publish(); };
    script.onerror = () => { status.sdk = 'unavailable'; publish(); };
    d.head.appendChild(script);
    send('game_load_start');
    w.setInterval(sample, 500);
    d.addEventListener('visibilitychange', sample);
    w.addEventListener('pagehide', () => { if (!ended) { sample(); tracker.end(); ended = true; } });
    w.addEventListener('pageshow', () => { ended = false; lastAt = w.performance.now(); });
    publish();
  }
  return {sanitize, cleanUrl, normalize, createTracker, boot, GOALS};
});
