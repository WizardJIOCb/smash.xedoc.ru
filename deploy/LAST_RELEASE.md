# Public release v27

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source: 04838e2f3646d27cf291795614bda9f726507f2a
- Current: /var/www/smash.xedoc.ru/releases/v27-04838e2f3646
- Previous/rollback: /var/www/smash.xedoc.ru/releases/v26-d523f66c1eb2
- Archive SHA256: a321be1865b4f75c96363e8bd8df1a8994958d53730818dfc9c80fcccfb86113
- Archive: 87,529,192 bytes;18 verified manifest files.

Changes:
- Moose/enemy ragdolls keep a natural captured knee/ankle bend with semi-rigid legs,
  separate hip hinges and articulated arms. Stronger capped hip support; decorative
  antler tips no longer prop Moose up.9 physical bodies Moose/11 shield enemy.
- Melee and O pulse affect actual moving corpse shapes. Resting bodies reattach cached
  pins and wake on hit, get small capped knockback, then stop physics again at rest.
  No new body allocations; shared attack serial prevents repeat contacts in one swing.
  Corpse hits do not grant kills or ultimate charge; small regular blood effect retained.
- Damage knockback preserves facing unless the user moves in the opposite direction.
  Removed damage alpha blink and player temporary invulnerability, including checkpoint grace.
- R immediately detaches/disables corpse before restoring rest bones, preventing a late
  ragdoll process from overwriting the revived stance.

Validation:
-29GUT/390assertions, format/lint; clean final Web export.
- Native anatomy32frames; defense42/0errors,3blocks=85HP, death/R/upright100HP.
  Full route35/0errors,5kills3relays/completed100HP. Corpse input36/0errors,
  10postmortem hits after boar settles,1kill retained,0active bodies when resting.
- Public revision27 ready, sound muted, scores online/session ready. Cache update hit2/
  download1 retains engine. Real keys kill boar, crouch-kick corpse twice: corpse_hits2,
  kills1/alive0. No record submitted. Browser death/restart closure follows below.
- Installer verified all18manifest hashes/archive, PHP/nginx checks, services active.
  Scores SHA unchanged across activation:
  2e71d73f8875c9ef3966ba72a41e97f0a021df163d843154c5d3e47125ef8b19.
- Semi-rigid legs are an explicit anatomy/stability tradeoff, not independently simulated
  knee/ankle joints. User appearance/feel gates remain open; physical phone untested.
- Public death/R closure:0HP/lost/player_ragdoll=true/facing1; R returns100HP,
  playing/player_ragdoll=false/x170, visually upright. Browser console errors0.
  Screenshots public-v27/death.png and restarted.png; temporary QA tab closed.
