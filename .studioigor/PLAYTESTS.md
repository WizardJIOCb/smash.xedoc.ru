# Playtests

One session — one section. The user's feedback — verbatim. The first question is always "is it fun?".

## PT-01 — 2026-11-13 — first rig look-dev
- Build: 72bc709; local Web, accepted original painted moose and courtyard.
- User: "Доводим плавность и вес анимации (рекомендую)".
- Correction: "на куртке уже есть рукава и у нас есть ещё руки, получается как будто 4 руки"; screenshot supplied.
- Actions: edited torso artwork to remove baked sleeves; rechecked both directions. Added native weighted torso mesh, displacement-driven foot support, spring follow-through, 67 ms jump anticipation and landing absorption; motion parameters in data/rig_motion.json. Z allows close inspection.
- Self-check v2: TEST 4/4; close-up capture 68 frames / zero engine errors. Web reports revision=2, bones=15, mesh_vertices=35, jumps=1, landings=1 after real keyboard input.
- Art quality and fun verdict: awaiting user; no phase completion claimed.

## PT-02 — 2026-11-13 — rig v2 correction
- User: "Перепутаны z-index для рук как будто и кулак к руке прикреплён не тем углом, в горле куртки можно нарисовать шерсть и шею ото там пусто сейчас, жопа тоже странно смотрится ))".
- Follow-up: "и глаза на лице должны вперёд смотреть, эти глаза тоже можно оставить, чтобы он изредка как будто бы в камеру смотрел потому что текущие глаза смотрят в камеру а не вперёд".
- Actions: near shoulder moved to foreground side of jacket, far shoulder to front/back plane; explicit layer constants. Fist pivots moved from fingers to wrist and aligned to cuff axis. Slimmer pelvis overlays leg roots, below jacket. Added neck bridge plus painted fur inside opaque collar cavity.
- Gaze: generated forward eye donors composited only within the original eye areas, retaining exact head/antlers. Default forward; brief idle camera glance; active motion cancels it.
- User art approval remains open.
- Self-check: 79 current main-scene frames and 12 isolated idle-gaze frames, zero engine errors in both captures; 4/4 tests. Idle review recorded one camera_glance and returned to forward gaze. Live Web shows revision=3, forward gaze during movement/attack, glance counter advances during idle.

<!--
## PT-01 — 2026-09-28 — M01 Drift (gym)
- build: <commit> · run: `<command>`
- what we tried: …
- is it fun? … · feedback (verbatim): …
- conclusions → actions: …
-->
