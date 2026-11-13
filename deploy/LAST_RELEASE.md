# Public release v19

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source: 7090e522849331b268acd6740cc6cd60059c0a81
- Current: /var/www/smash.xedoc.ru/releases/v19-7090e5228493
- Rollback: /var/www/smash.xedoc.ru/releases/v18-b2e4e1f43245
- Archive SHA256: 982fe14b314a17dfd63655ab52761c7a1de607533793b94a624b40f9ca13b250
- 15 manifest files checked before atomic activation. GitHub main pushed.

User-requested corrections:
- Softer, fluffy, cartoon near fist, 3 curled fingers plus thumb, no sinewy ridges
  or fingernail. Built-in image_gen source art/characters/los/fist-back-v9.png,
  exact prompt fist-back-v9-prompt.md; prepare_rig_v9.py fits runtime texture.
- Boar and rat near shoulder moved into the actual visible socket on right of
  left-facing source art. Existing complete arm paintings retained. Forearm/hand
  bones, continuous weighted elbow meshes; shield/baton/cable follow hands.
  Procedural whip line starts at the actual gripping hand. Both facings checked.
- Upper alley ledge y395 to415, rise now40 instead of60; relay moved down20 too.

Validation:
- 22/22 GUT; headless Web export, no SCRIPT ERROR/ERROR.
- Native enemy-arms-v19: 29 frames, 0 errors/warnings; both species and facings,
  guard, walk, windup, attack and recovery.
- Native ledge-route-v19: 70 frames, 0 errors/warnings, completed=true; 5 enemies,
  3 relays, 21.65 seconds. Upper ledge ACTUAL landing at 13.5667 seconds recorded
  before the driver permits its relay interaction. No health/position cheats.
- menu-v19: 4 frames, 0 errors. Local browser revision19 and soft fist checked.
- Public revision19, shared scores available, fresh run and real D/Z controls;
  new fist and boar arm visible, 100HP. Capture public-v19/hero-and-shield-full.png
  (1280x720) and identical-sized hero-and-shield.png. Browser error log empty.
- Cache version update: 2 asset hits and 1 download, unchanged engine reused.
- Nginx/PHP8.3-FPM active. Public release.json matches runtime source.

Persistent score-store SHA256 unchanged before/after deployment:
01374a70e10ca4a1bcbad5af9d001ae34f9a34e02a0410fcb976cd14bff0e40b.
No synthetic score submitted. Records, sound preference, night ability and cache
clear mechanism retained. Art approval remains with user; final Firewall boss
and full metroidvania map are still future work.
