# Public release v30

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source:613634cbea61a15185e410110eb0cd4f7efe71e2
- Current:/var/www/smash.xedoc.ru/releases/v30-613634cbea61
- Previous/rollback:/var/www/smash.xedoc.ru/releases/v29-be6292e9acf6
- Archive:133,721,517bytes;18verified manifest files.
- SHA256:030aff29cda94bf18598e3b668e8c4414d85569cd91554330214c5a942f34a9f

Changes:
- Any empty ranged weapon throws on the next attack press, not just pistol. Holding
  automatic fire stops on empty without discarding; F can reload first. Ammo reserve
  and one-hit/recoverable thrown pickup preserved.
- Larger enemy guns: fox88x34,lynx102x38,Firewall110x40, with individual support-hand
  offsets; beaver/hare/Foreman melee props enlarged moderately. Both facings reviewed.

Validation:
-45GUT/636assertions, format/lint, clean Web export. Every ranged definition tested for
  hold-vs-new-press, single hit, exact reserve/recovery/reload.
- Native weapon gallery18frames/0errors; rifle range20frames/0errors:24shots/24hits,
  then next press throws1/hits1/contacts25,1pickup and fists. Actual frames reviewed.
- Public revision30/muted/scores online; enlarged guns viewed. Ordinary keys complete
  tower entry4kills/1relay and collect rifle in cooling room. HoldJ fires24 rounds,
  keeps rifle0/24/reserve120/throws0; release/newJ gives throws1/thrown_hits1,
  pickup1/rifle removed/fists,76HP. Console errors0. QA tab closed; no score submitted.
- Public cache update2hits/1download preserves engine. Installer verifies18manifest
  files/archive; PHP/nginx checks pass, services active, HTTPS/release.json verified.
- Score storage unchanged across activation:
  c2804544e57d02b1a4cd3c3661e3a9bc384066691039cdbd9b338589ad2badd8.
- Captures/metrics:.studioigor/captures/public-v30,rifle-throw-v30,weapons-v30.
- Physical phone and user appearance/feel acceptance remain open.
