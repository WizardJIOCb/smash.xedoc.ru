# Public release v31

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source:3bde584d499327c9ec2330557cbd94fdbc206ba2
- Current:/var/www/smash.xedoc.ru/releases/v31-3bde584d4993
- Previous/rollback:/var/www/smash.xedoc.ru/releases/v30-613634cbea61
- Archive:86,430,186bytes;18verified manifest files.
- SHA256:bcd804de11d4839847d40dde6af7a35301f95e5f3c0e543ed452660d56c6a824

Changes:
- Bat112px, two hands on handle, clear backswing behind trunk then fast forward arc
  and follow-through. Standing/low/air timing; damage only during the strike.
- Fox54x28 pistol with compact support grip; lynx120x58 rifle with stock at shoulder
  and second hand under fore-end. Individual grip pivots and actual muzzle origins.
- Exclude build/ from Godot resource export: prior exports were recursively included.
  PCK32,223,528bytes versus v30 55,893,912; engine assets unchanged.

Validation:
-46GUT/648assertions, format/lint and clean final Web export.
- Native bat gallery63frames + range48frames/3contacts; final backswing56frames;
  enemy grips18frames. All0errors; viewed both directions, low/air gallery.
- Public revision31/muted/scores online. Ordinary E/J: bat4punches/6hits/1kill/100HP.
  Saved actual rear windup, strike follow-through, combat and chapter3 weapon grips.
  Console errors0; QA tab closed, no score submitted.
- Cache2hits/1download preserves engine. Installer18hashes, PHP/nginx checks pass,
  services active, HTTPS/release.json verified. Scores unchanged across activation:
  8627d9e6c134f8f4c44742cd7eae238b0cf698d317a75785c29fb7b1c649e75d.
- Captures/metrics:.studioigor/captures/public-v31,bat-backswing-v31,
  bat-poses-v31,bat-contacts-v31,enemy-grips-v31.
- Physical phone and user appearance/feel acceptance remain open.
