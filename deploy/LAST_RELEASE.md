# Public release v50

- URL: https://smash.xedoc.ru/
- Runtime source: 5b9d6c57ca73330acfcd6dbad7ea8da1f965f336
- Current: /var/www/smash.xedoc.ru/releases/v50-5b9d6c57ca73
- Rollback: /var/www/smash.xedoc.ru/releases/v49-394b4593b46b.
- Archive:153009674bytes; SHA256 0c0e71929c1e24a4d36dfecaa62ce6ed4d15b63dfe3862a593a1ee0a6716cf78.
- All21 installed hashes verified. PCK: game-03ebfe8b7776e88bfb6a.pck.

Corrected the support arm itself: its fixed planar elbow branch previously
crossed the throat during load. The actual shoulder stays anchored; a downward
pole on a 3D elbow circle gives a continuous projected sleeve path to the bat.
Both wrists remain on the painted handle. Unequip restores native sleeve/bone
offsets. Existing bat timing and campaign/online/survival features remain.

Validation:
- Format/lint,91GUT/1381assertions and Web export pass; no export parse errors.
- Native98frames/both facings/standing/crouched/airborne/buffered swings,
  zero errors/warnings. Minimum support-elbow drop22.893rigpx below its shoulder;
  maximum wrist gap0.000183px, shoulder displacement0. Native contact gym3hits.
- Regression checks cover support-elbow clearance, continuity at240Hz, original
  sleeve/child-offset restoration on unequip and existing wrist/chain behavior.
- Local Web50:8swings/3hits/91HP. Ordinary loss followed by R restored100HP and
  an upright pose; Tab switched to fists and back to bat, console0errors.
- Public Web50:9swings/3hits/91HP, bat equipped, both facings captured and viewed,
  console0errors. Four small public hashes and release metadata match; all8
  campaign boards, both survival boards and relay health pass.
- nginx site configuration unchanged. Both score stores SHA256-identical across
  activation; all old score rows retained. PHP/nginx/relay active; no QA result sent.
- Verified and removed only the redundant uploaded v50 archive; installed v50,
  v49 rollback and local frozen archive retained. Temporary browser tabs closed.

Evidence: .studioigor/captures/bat-elbow-v50 (screenshots, metrics, swing.mp4,
contracts and deployment log); full native frames in
.claude/worktrees/campaign-rules/.studioigor/captures/bat-elbow-verified.
User art/feel acceptance, physical-mobile and sixteen-human testing remain open.
