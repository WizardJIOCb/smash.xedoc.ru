# Public release v18

- Domain: https://smash.xedoc.ru/
- Fresh network load: https://smash.xedoc.ru/?cache=clear
- Runtime source: b2e4e1f43245f2889bd256c7dee92ca8c1e2491e
- Current: /var/www/smash.xedoc.ru/releases/v18-b2e4e1f43245
- Previous rollback: /var/www/smash.xedoc.ru/releases/v17-7a1979b4d36b
- Earlier v16 remains available in releases/v16-a1e602446684.
- Archive SHA256: f8c93b144e37d096411c4adbf676c1724cb552e5c9d592f8191b7228a2d4d1cf
- 15 frozen manifest files verified before atomic activation. GitHub main pushed.

T: Blood Night for 8 seconds, damage x1.8, size x1.12, additive red aura and
world-wide night grading. L: telegraphed impulse, shield break and projectile
clearing, 2s cooldown. Damaging hits and kills recharge outside night; shield
blocks do not. Pause freezes timers, room transitions retain them.
Fresh sound preference is muted. Toggles persist immediately in Web localStorage
and in user:// for native. Immediate Web reload retains the choice.

Near fist: built-in image_gen, art/characters/los/fist-back-v8.png and exact prompt
in fist-back-v8-prompt.md. Three curled fingers plus a thumb, matching the existing
inner-view fist. prepare_rig_v8.py also splits the unchanged shoe painting into
rear collar and front tongue/rim on identical canvases and pivots. Each cuff sits
between its own shoe layers. Head shader tapers the lower crop into fur tips over
the neck, preserving eye UVs and the accepted head pose.

Checks: 22/22 GUT. Native night-route-v17: 130 frames, 0 errors, completed=true,
5 kills, 3 relays in 32.13 seconds, 78 normal-attack night damage, 3 impulse hits,
expiry observed and charge replenished to 100. anatomy-v17: 49 frames/0 errors;
menu-v17: 4 frames; night-art-v17: 20 frames with final HUD and grade. v18 changes
only sound persistence/revision; its GUT/export and immediate local reload passed.
menu-v18 cover reuses the unchanged v17 menu capture.

Web cache: independent hashes for JS/WASM/PCK, small HTML/loader revalidation,
immutable heavy assets and gzip. CacheStorage failure falls back to network/HTTP
cache. No service worker. ?cache=clear deletes only game asset caches and reloads
with cache:reload and unique URLs; preserves IndexedDB, sound choice and scores.
Local verified: cold download3, warm hit3, clear download3, sound retained.
Public verified: v17 clear download3 / warm hit3; version update to v18 hit2 and
download1 (engine reused); v18 warm hit3/download0. Actual v18 T/L inputs produced
night_casts=1, night_bursts=1, power_scale=1.12, sound_muted=true, revision18.
Public immediate reload retained sound OFF. Shared score screen fetched normally.
Public capture: .studioigor/captures/public-v18/night-full.png, letterbox-only crop
night.png. No synthetic record submitted.

Server: HTTPS, release.json v18, immutable WASM header, gzip application/wasm,
nginx/PHP8.3-FPM active. Score-store SHA256 before/after deployment unchanged:
2e49946a80a8f2b2ebe60398e7c0688a048b744009077ae51a71f243f2554c94.
Records remain outside releases at /var/lib/smash-xedoc. Certificate/renewal and
unrelated host configurations were preserved. Art/feel gates await user feedback;
full metroidvania map and final Firewall boss remain future work.
