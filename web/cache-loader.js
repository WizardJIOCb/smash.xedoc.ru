/* Original Godot bootstrap: only immutable game assets enter this cache. */
'use strict';
(() => {
  const assets = __SMASH_ASSETS__;
  const cacheName = 'smash-game-assets-v1';
  const clear = new URL(location.href).searchParams.get('cache') === 'clear';
  const fresh = String(Date.now());
  const originalFetch = window.fetch.bind(window);
  const state = { clear, hits: 0, downloads: 0, enabled: false, ready: false };
  let storage;
  const publish = () => document.body.setAttribute('data-game-cache', JSON.stringify(state));
  const urlFor = (name) => {
    const url = new URL(assets[name], location.href);
    if (clear) url.searchParams.set('fresh', fresh);
    return url.href;
  };
  window.smashCacheReady = (async () => {
    if ('caches' in window) {
      try {
        if (clear) {
          const names = await caches.keys();
          await Promise.all(names.filter(name => name.startsWith('smash-game-assets-')).map(name => caches.delete(name)));
        }
        storage = await caches.open(cacheName);
        state.enabled = true;
      } catch (error) {
        console.warn('Game cache unavailable; loading from network.', error);
      }
    }
    publish();
  })();
  async function load(name, options) {
    await window.smashCacheReady;
    const key = new URL(assets[name], location.href).href;
    if (storage && !clear) {
      try {
        const saved = await storage.match(key);
        if (saved) {
          state.hits++;
          publish();
          return saved;
        }
      } catch (_) { /* Network remains available if storage is denied. */ }
    }
    const response = await originalFetch(urlFor(name), {
      ...options, cache: clear ? 'reload' : 'default'
    });
    if (!response.ok) throw new Error('Не удалось загрузить игру: ' + response.status);
    state.downloads++;
    if (storage) {
      try { await storage.put(key, response.clone()); }
      catch (_) { /* Quota pressure must never prevent the game from starting. */ }
    }
    publish();
    return response;
  }
  window.fetch = (input, options) => {
    const url = new URL(typeof input === 'string' || input instanceof URL ? input : input.url, location.href);
    const name = url.pathname.split('/').pop();
    if (url.origin === location.origin && ['index.wasm', 'index.pck'].includes(name)) {
      return load(name, options);
    }
    return originalFetch(input, options);
  };
  window.smashLoadEngine = async () => {
    const response = await load('index.js');
    const blob = URL.createObjectURL(await response.blob());
    try {
      await new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = blob;
        script.onload = resolve;
        script.onerror = () => reject(new Error('Не удалось запустить движок.'));
        document.head.appendChild(script);
      });
      state.ready = true;
      publish();
    } finally { URL.revokeObjectURL(blob); }
  };
  window.smashPruneCache = async () => {
    if (!storage) return;
    const keep = new Set(Object.values(assets).map(name => new URL(name, location.href).href));
    try {
      const keys = await storage.keys();
      await Promise.all(keys.filter(key => !keep.has(key.url)).map(key => storage.delete(key)));
    } catch (_) { /* Best-effort cleanup after successful startup. */ }
  };
})();
