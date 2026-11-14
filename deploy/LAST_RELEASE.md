# Public release v46

- URL: https://smash.xedoc.ru/
- Runtime source: af41454685132aa6aee060b244e52546472ce749
- Current: /var/www/smash.xedoc.ru/releases/v46-af4145468513
- Rollback: /var/www/smash.xedoc.ru/releases/v44-0613d279dc22; v43 also retained.
- Archive: 152961728 bytes, SHA256 331fbb2442ff9b05e39f1abdd756b7f93a004f6b07846a49af0772f2207ee2db.
- Installer verified all 20 manifest files. PCK: game-36163552265d508dac96.pck.

Ten original painted props replace flat mechanic scenery: alcoves, signal,
cargo deck, lift staging, vines, cover, supports, bridge and gap surfaces.
Thirteen room floors corrected individually; all sixteen new rooms reviewed.
Persistent cyan frontal-guard arc removed; guard mechanics retained.
Holiday effects use five instanced/static draws instead of 536 AA primitive draws.
Winter chapter preview now uses its dedicated background. Prepared Metrika
integration is included; QA browser visits used analytics_qa.

Validation:
- 77 GUT /1121 assertions, six analytics checks, format/lint and Web export pass.
- Native IV-VII: 296 captured frames, each chapter completion recorded, zero
  renderer/script errors or warnings. Additional 17-frame floor gallery clean.
  Lift6.3 walk-off: zero jumps/drop; rain/blood use the same sole planes.
- Controlled native2180x1316, RTX4070Ti, two rendered heroes: idle637->106 calls;
  six sleeping corpses699->168 calls. Mean frame6.200->1.431ms in the latter
  fixture, P957.310->1.787ms. All six corpses sleep; FX alone536->5 calls.
  A separate ordinary-input holiday run won7kills/100HP/0deaths. One isolated
  unattributed52ms peak was observed; these native timings are not a browser guarantee.
- Public Web46: correct winter preview and metro alcoves/floor605, console0errors.
  Solo holiday reached wave2:6hits/2kills/2corpses/57HP,132calls, sampled156FPS
  at1280x720. This is not directly comparable to the user's larger screenshot.
- Two hidden-IAB session disconnected; direct nativeWSS did not enter a room.
  Replacement test: headless authoritative host through an encrypted SSH tunnel
  to the same relay plus a publicWSS browser guest. Host won7kills/1relay/100HP
  in19.48s, no engine errors; guest rendered both heroes and two bodies, then
  showed the expected host-exit message after the review host closed itself.
- Four public file hashes and release metadata match. All8 score endpoints and
  chapter metadata valid; isolated PHP10checks plus8chapter contracts passed.
- Active nginx configuration preserved byte-for-byte. Score-file SHA256 before/
  after activation identical:65574a8b92aae43a12a45e5bbadf7ac27d7a24141d5d600f0d83127bd7cda65d.
  nginx, PHP and relay active. No QA leaderboard entry submitted.
- Removed only redundant uploaded archives after SHA256/local-copy verification;
  every installed release/rollback preserved. Cleanup audit saved with evidence.

Evidence: .studioigor/captures/props-v44, holiday-performance-report,
holiday-final, release-v44 and public-props-v46. Source art/prompts: art/props.
Physical-mobile, sixteen-human and overall art/feel acceptance remain open.
