/* Original Godot bootstrap: only immutable game assets enter this cache. */
'use strict';
(() => {
  const assets = __SMASH_ASSETS__;
  const sizes = __SMASH_ASSET_SIZES__;
  const received = Object.fromEntries(Object.keys(assets).map(name => [name, 0]));
  const total = Object.values(sizes).reduce((sum, size) => sum + size, 0);
  const writes = new Set();
  const cacheName = 'smash-game-assets-v1';
  const clear = new URL(location.href).searchParams.get('cache') === 'clear';
  const fresh = String(Date.now());
  const originalFetch = window.fetch.bind(window);
  const state = { clear, hits: 0, downloads: 0, enabled: false, ready: false };
  let storage;
  const publish = () => document.body.setAttribute('data-game-cache', JSON.stringify(state));
  const report = (name, bytes) => {
    received[name] = Math.min(bytes, sizes[name]);
    window.smashLoading?.progress(Object.values(received).reduce((sum, size) => sum + size, 0) / total, state.hits > 0 && state.downloads === 0);
  };
  function tracked(response, name) {
    if (!response.body) { report(name, sizes[name]); return response; }
    const reader = response.body.getReader();
    let count = 0;
    return new Response(new ReadableStream({
      async pull(controller) {
        try {
          const chunk = await reader.read();
          if (chunk.done) { report(name, sizes[name]); controller.close(); return; }
          count += chunk.value.byteLength;
          report(name, count);
          controller.enqueue(chunk.value);
        } catch (error) { controller.error(error); }
      },
      cancel: reason => reader.cancel(reason)
    }), {status: response.status, statusText: response.statusText, headers: response.headers});
  }
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
          report(name, sizes[name]);
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
      // Do not await a full cache write before Godot can consume the download stream.
      const write = storage.put(key, response.clone()).catch(() => {});
      writes.add(write);
      write.finally(() => writes.delete(write));
    }
    publish();
    return tracked(response, name);
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
    await Promise.allSettled([...writes]);
    const keep = new Set(Object.values(assets).map(name => new URL(name, location.href).href));
    try {
      const keys = await storage.keys();
      await Promise.all(keys.filter(key => !keep.has(key.url)).map(key => storage.delete(key)));
    } catch (_) { /* Best-effort cleanup after successful startup. */ }
  };
})();
