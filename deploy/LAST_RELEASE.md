# Public release v28

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source: 374fd893bf59d4430061f5f67690a1757f157393
- Current: /var/www/smash.xedoc.ru/releases/v28-374fd893bf59
- Previous/rollback: /var/www/smash.xedoc.ru/releases/v27-04838e2f3646
- Archive SHA256: 86d283ac0183094e9b8f8dfef200a4eb4edc7b1a2c7ac436d43d3c8f8201c913
- Archive: 120,866,060 bytes; 18 verified manifest files.

Changes:
- Two continuation chapters of four rooms each: Rust Depot and Firewall Tower.
  Eight original backdrops, four ordinary enemy types, Foreman and Firewall bosses
  with two/three phases; all three chapters can be selected from the menu.
- Six weapons: knuckles, bat, shovel, hockey stick, seven-round pistol and rifle.
  E pickup/use, Tab cycle, F reload, J weapon, K kick. Gear carries to next chapter.
- Physical cargo lifts with return calls, reinforcements, checkpoints and separate
  per-chapter records. Original first chapter retained.
- Built-in image_gen originals, exact prompts and processed paths retained in
  art/campaign/prompts.json and generated-manifest.json.

Validation:
- 42 GUT tests / 589 assertions, format/lint; clean Web export.
- Full normal-input native routes: chapter1 35frames/5kills/3relays; chapter2
  46frames/14kills/4relays; chapter3 46frames/12kills/4relays. All completed with
  zero script errors. Both boss phase sequences observed and frames reviewed.
- Native menu input selects tower, picks pistol, fires seven and reloads seven.
  Actual PHP isolated tests pass all three finish contracts, token chapter binding,
  replay rejection and legacy preservation. Disposable storage only.
- Public revision28 ready and muted. Chapter2 selects/picks bat; chapter3 selects,
  picks pistol, fires7/loaded0/bullet_hits7/kills2, F reloads7/reserve70->63.
  Reinforcement wave2 observed. Console errors0. Screenshots public-v28.
- Cache upgrade2hits/1download preserves JS/WASM; repeat3hits/0downloads,100% ready.
- Live records: original two rows retained in chapter1, chapter2/3 empty at check.
  No public score submitted. PHP SCRIPT_FILENAME now uses $realpath_root so symlink
  releases cannot retain the previous API in FPM caches; nginx -t passed.
- All18 archive hashes verified by installer; HTTPS/public release.json confirmed;
  nginx and php8.3-fpm active. Scores SHA unchanged during activation:
  a581415790bdf837110ec7ab20b9fb45188a3e75eeaca1e1b98b5384215bb746.
  Subsequent QA creates ordinary run tokens, not leaderboard rows.
- Physical phone and user art/feel acceptance remain open. Full boss routes were
  verified natively; public browser review covered chapter selection and first rooms.

Operational config closure is committed after the frozen runtime source; it changes
nginx configuration and release notes, not the v28 game archive.
