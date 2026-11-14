# Public release v35

- Domain:https://smash.xedoc.ru/
- Runtime source:6b1e92c7a56eb065a6737c1743d0e6286428adcf
- Current:/var/www/smash.xedoc.ru/releases/v35-6b1e92c7a56e
- Rollback:/var/www/smash.xedoc.ru/releases/v34-11abd8fdc1ab
- Archive:93,535,571bytes;18verified files.
- SHA256:e24b76fdf56d3d95c5dcfe3bda6c642f31157832870c87824aa15d8997d36f3d

Changes:
- Bat motion rebuilt against real grip/sequence references: Little League coach photo,
  Texas Rangers Youth Academy Baseball101 and a full batting photo sequence.
- Shoulder-height ready/load; separate knob-led drive, level contact, wrap/finish and
  return. Rear-to-front weight shift before planted-leg IK; shoulder follows the turn.
- New palm-down/palm-up grip painting with wrists trailing toward forearms. Shared
  grip constrained to both arm reach annuli; no wrist gap or fully folded elbows.
- Projected depth changes barrel length only; painted hands retain width. Contact
  geometry follows the rendered shaft, damage remains confined to the forward sweep.

Validation:
-48GUT/674assertions, format/lint, clean Web export. Both wrists stay within0.05px
  through standing/crouch/air swings in both facings; maximum elbow below135degrees.
  Drop/death restore original hands; rifle recoil support and damage regressions pass.
- Final native63frames/0errors: worst wrist gap0.00019px at2.1scale, maxelbow133.70deg.
  Game range96frames/3contacts; phases reviewed. Final390frame/60FPS,6.5s MP4 decoded.
- Public revision35:6swings/7hits/2kills/100HP, right and left swing frames viewed;
  Tab/G restores fists and leaves1plain bat pickup. Console0errors,cache2hits/1download,
  scores online. QA/ref tabs closed; no leaderboard result submitted.
- HTTPS/release.json,18manifest hashes, PHP/nginx and active services verified.
  Scores unchanged during activation:
  1d1a996775589f0719e2124f0562c57c08c4a5aec54f48cd7bc25e7a1ee20ca7.
- Evidence:.studioigor/captures/public-v35,bat-final-v35,bat-contact-v35,
  bat-motion-final-v35.mp4; research/bat-v35.md,gauntlet/bat-v35.
  Reference comparison rounds record remaining style/feel judgment with the user.
