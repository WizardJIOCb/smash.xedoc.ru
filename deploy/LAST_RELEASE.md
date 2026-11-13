# Public release v21

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source: be8d1e30f05e02b19c7c619725aef49a2800f996
- Current: /var/www/smash.xedoc.ru/releases/v21-be8d1e30f05e
- Rollback: /var/www/smash.xedoc.ru/releases/v20-9ece5d4be811
- Archive SHA256: 3611cce7bc4a63285bb5657c25c7e3e442a1daf3aac3805477d994aaefd720f7
- 15 manifest files verified before atomic activation; GitHub main pushed.

User requests fulfilled in v20/v21:
- T toggles persistent day/night, no charge cost or combat boost.
- Q activates 8s ultimate, now named Багровая ярость. L remains its impulse.
- Separate world-grade and power/aura strengths. Ultimate expiry preserves time
  of day; switching time works with zero charge and during the ultimate.
  Quarantine relay progression stays independent; daylight has a subtle warning
  wash, night uses the painted quarantine state and cool grade. New run starts day.
- Near fist uses local Sprite2D multiplier (0.80,0.82,0.84): about18% dimmer and
  slightly less orange, matching the head fur. Source painting, soft texture and
  four digits preserved; no new generated image or raster modification needed.

Validation:
- 22/22 GUT, Web export without SCRIPT ERROR/ERROR.
- day-power-v20: 28 native frames, zero errors/warnings, all four observed checks:
  night without power, day with power, night remaining after expiry, switches with
  empty charge. day-power-v21 repeated the scenario with initial tint adjustment.
- Final tint: menu-v21 4 frames, tone-modes-v21 10 frames, zero errors; inspected
  day, night and aura combinations. v20/v21 menu help and HUD bindings updated.
- Public v20 real keys: T -> world_night=true, ultimate=false, charge100, scale1;
  T then Q -> world_night=false, ultimate=true, charge0, scale1.12, one cast.
- Public v21 revision21/menu and actual final fist tone verified; shared scores
  available, muted=true, cache hit2/download1; browser error log empty.
- Public screenshot public-v21/menu-fur-tone.png; fur-tone-closeup.png is a crop
  retaining face, neck, jacket and both fists for color comparison.
- Nginx/PHP8.3-FPM active; release.json matches source. Scores unchanged across v21
  activation: af52413102fb21f5d10b15a5dddd68455097a88115b6a4a319136333842c27d4.
  Real players added records during the work; no synthetic record was submitted.

Earlier v19 enemy arms, soft four-digit fist and lowered second ledge retained.
Art/feel approval remains with user. Final Firewall and full map remain future work.
