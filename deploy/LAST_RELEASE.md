# Public release v51

- URL: https://smash.xedoc.ru/
- Runtime source: 92aea45631fc495c509ef3fb77c7bc54976d68fc
- Current: /var/www/smash.xedoc.ru/releases/v51-92aea45631fc
- Rollback: /var/www/smash.xedoc.ru/releases/v50-5b9d6c57ca73
- Archive: 159231585 bytes; SHA256 d6dfa962c8b51854c66cea07913e953c56915101b448924c8dd5b4a8d5ab2ba1.
- All 21 installed hashes verified. PCK: game-6a50a604d73432da15eb.pck.

Painted two-car metro trains pass behind room-specific columns, walls and
railings with headlights and warm windows. The authoritative wind front drives
the nose; the remaining cars finish their pass after the damaging front exits.
Directions alternate. Railway rumble and wind beds respect sound and pause.
Two clean plates remove the formerly parked foreground trains. Original masters,
exact imagegen prompts and conversion recipe are in art/props and tools.

Validation:
- Format/lint, 92 GUT / 1393 assertions and Web export pass; no parse errors.
- Native chapter V: 237 frames, won in 52.35 s, 12 kills / 4 relays / 100 HP,
  no deaths, errors or warnings. All four metro backgrounds viewed during passes.
- Native audiovisual capture: 510 frames at 30 FPS; actual mixed engine audio
  nonzero, no clipped samples. Short motion clip retained as train.mp4.
- Local Web 51: first wave crouched, 100 HP / 0 player wave hits; both directions,
  full departure, mute and active-audio pause verified; console has no errors.
- Public Web 51: bounded R then S review, rule clock 4.95 s, train visible with
  wave, 100 HP / 0 player wave hits. Paused afterward, console has no errors.
  Initial pre-reset public input was uncontrolled; use the final bounded review.
- Four public hashes and exact release metadata match; 8 campaign boards,
  both survival boards and relay health pass. nginx / PHP / relay active.
- Active nginx configuration and both score-store hashes identical across
  activation; old rows retained. No QA score submitted. Temporary tabs closed,
  viewport override reset. Redundant uploaded archive verified and removed;
  installed v51, rollback v50 and the frozen local package retained.

Evidence: .studioigor/captures/metro-train-v51 (public-pass.jpg, gameplay and pause
metrics, local timing/audio proof, native-route.json, train.mp4 and deploy logs).
Full native frames: .claude/worktrees/campaign-rules/.studioigor/captures/metro-train-route.
User art/feel acceptance, physical-mobile and sixteen-human tests remain open.
