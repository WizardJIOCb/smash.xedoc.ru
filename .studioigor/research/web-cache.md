# Web asset cache, 2026-11-14

- https://developer.mozilla.org/en-US/docs/Web/API/CacheStorage/delete
- https://docs.godotengine.org/en/4.4/tutorials/platform/web/customizing_html5_shell.html

Hash JS/WASM/PCK independently after export, so an unchanged engine is reused.
HTML and the small loader revalidate; hashed files have immutable HTTP caching.
CacheStorage holds only these game assets, with network fallback if unavailable.
?cache=clear deletes only smash-game-assets-* and requests fresh network copies
with unique URLs and cache:reload. It never clears IndexedDB/user:// or scores.
No service worker intercepts API or navigation. Old game entries are pruned only
after successful startup; all three current assets remain available for reuse.
