# Public release v32

- Domain:https://smash.xedoc.ru/; fresh load:https://smash.xedoc.ru/?cache=clear
- Runtime source:85a4574389fd438c3248c68b04323f6b185d8c37
- Current:/var/www/smash.xedoc.ru/releases/v32-85a4574389fd
- Rollback:/var/www/smash.xedoc.ru/releases/v31-3bde584d4993
- Archive:86,430,897bytes;18verified files.
- SHA256:9e542ec0d200115fb04965b72b893baaaabe3559c6abb127e16bb37d11c94d62

Changes:
- Bat fists wrap across handle, wrists limited0.7rad, support hand follows actual
  main-hand grip. Rear windup/forward strike retained.
- Enemy meshes skin the hand bone separately; tool wrists limited0.8rad and follow
  shaft angle. Hare/beaver windup paths avoid folding through shoulder; Foreman's
  two-hand windup remains within reach. Other enemy grips reviewed for regressions.

Validation:
-46GUT/648assertions, format/lint, clean Web build. Native final bat32frames includes
  standing/crouch/air and both facings; enemy gallery18frames.0errors, viewed frames.
- Public revision32/muted/scores online; ordinary E/J bat2punches/2hits/100HP.
  Rest/backswing/combat frames saved, hare/beaver grips visible. Console errors0.
  Cache2hits/1download; engine preserved. QA tab closed, no fake score submitted.
- HTTPS/release.json correct,18manifest files verified, PHP/nginx checks and services
  pass. Shared scores unchanged across activation:
  3538ca3e9765f4ae76567dd760fa28ff7316620aadb5cedc1d0ed83973e2358a.
- Captures:.studioigor/captures/public-v32 (full frames),bat-final-v32,
  enemy-grip-final-v32. Physical phone and user appearance/feel approval remain open.
