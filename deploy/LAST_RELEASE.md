# Public release v49

- URL: https://smash.xedoc.ru/
- Runtime source: 394b4593b46bd547ddf3e1e51f485e4e988f7896
- Current: /var/www/smash.xedoc.ru/releases/v49-394b4593b46b
- Rollback: /var/www/smash.xedoc.ru/releases/v48-6a252cf841e5; older releases retained.
- Archive: 153004973 bytes; SHA256 8adecc1f1b3ef77db640a388e44ca1861f4f78ad74a3536989850f107a99a15f.
- Installer verified all 21 files and both PHP endpoints. PCK: game-bea7d01e9f58aa126132.pck.

Bat motion keeps both wrists attached and the support sleeve visible above the
jacket. The swing plane passes below the muzzle; handle and barrel keep the
same drawing depth throughout the swing and recovery. Ordinary fist/sleeve
layers return on drop or death. Attack damage timing is preserved.

Removed the small foreground refuge doorways from every metro room, their safe
zones and niche instructions. Crouch S/Down protects against the warned train
wave; the physical signal and wave remain. Campaign, co-op, survival and
analytics from v48 are included.

Validation:
- Full GUT: 91 tests/1363 assertions. Final grip cleanup: targeted19/244 pass.
  Format/lint and Web export pass. No export parse errors.
- Native bat:98 frames, both facings, standing/crouched/airborne and buffered
  swings; zero errors/warnings. Maximum wrist gap0.000193px, shoulder drift0.
- Native metro:60 frames, chapter won52.35s/12kills/4relays/100HP/0deaths,
  zero errors/warnings. Updated the capture harness for the new start callback.
- Local Web49:5hits/2kills with bat; crouch survived a wave without damage.
- Public Web49: bat equipped,8swings/2hits/91HP, both facings captured;
  foreground doors absent, floor605 retained, browser console0errors.
  An earlier public attempt missed the pickup and was not used as bat proof;
  that disposable tab closed, then the complete check passed in a new tab.
- Four small public file hashes and release metadata match the frozen build;
  all8 campaign boards, both survival boards and relay health pass.
- nginx configuration unchanged byte-for-byte during activation. Both campaign
  and survival storage SHA256 values identical before/after activation; all old
  score rows preserved. nginx/PHP/relay active, no leaderboard result submitted.
- Verified and removed only this release's redundant upload from /dev/shm;
  local frozen archive, installed release and v48 rollback remain.

Evidence: .studioigor/captures/bat-metro-v49, metro-no-doors-v49;
additional bat frames in .claude/worktrees/campaign-rules/.studioigor/captures/bat-layer-final.
Physical-mobile, sixteen-human, overall art/feel and balance acceptance remain open.
