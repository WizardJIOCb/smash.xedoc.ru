# Playtests

One session — one section. The user's feedback — verbatim. The first question is always "is it fun?".

## PT-01 — 2026-11-13 — first rig look-dev
- Build: 72bc709; local Web, accepted original painted moose and courtyard.
- User: "Доводим плавность и вес анимации (рекомендую)".
- Correction: "на куртке уже есть рукава и у нас есть ещё руки, получается как будто 4 руки"; screenshot supplied.
- Actions: edited torso artwork to remove baked sleeves; rechecked both directions. Added native weighted torso mesh, displacement-driven foot support, spring follow-through, 67 ms jump anticipation and landing absorption; motion parameters in data/rig_motion.json. Z allows close inspection.
- Self-check v2: TEST 4/4; close-up capture 68 frames / zero engine errors. Web reports revision=2, bones=15, mesh_vertices=35, jumps=1, landings=1 after real keyboard input.
- Art quality and fun verdict: awaiting user; no phase completion claimed.

<!--
## PT-01 — 2026-09-28 — M01 Drift (gym)
- build: <commit> · run: `<command>`
- what we tried: …
- is it fun? … · feedback (verbatim): …
- conclusions → actions: …
-->
