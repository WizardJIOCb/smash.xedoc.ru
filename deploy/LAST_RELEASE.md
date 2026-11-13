# Public release v24

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source: 01ad83f0c5ff2e33412f0a400b638b920d709d00
- Current: /var/www/smash.xedoc.ru/releases/v24-01ad83f0c5ff
- Previous/rollback: /var/www/smash.xedoc.ru/releases/v23-dad0678b2411
- Archive SHA256: 7e3b12b59a445b72f9a6a397b1dcf652e731b0058536d09f6776bdde6b1a5434

Changes:
- L holds guard; O ultimate impulse. T day/night and Q ultimate remain independent.
- Compound torso/pelvis/head supports the silhouette, articulated native limbs keep
  anatomical relative limits. Captured pose, inherited fall velocity and off-centre hit
  torque produce different falls. Intentionally stiff core, not a simulated human spine.
- Per-corpse collision layers prevent cross-corpse limb piles. Quiet bodies freeze and
  detach solver joints after0.45s of low motion; pose stays until the normal12s fade.
  Cached bindings/constraints, solver12 instead24. Three-corpse native resting-frame
  p95=5.925ms versus16.69ms before; active bodies41 while falling,0 after settling.
  Machine-specific native evidence, not a Web/mobile FPS guarantee.
- THIRD room floor545->529; soles, enemy spawn, physical terrain and blood agree.
- Irregular wet pools scatter -14..+7px in road depth (less on ledges), below bodies/shoes;
  stationary drawing cached, fading redraw12Hz, airborne droplets remain full-rate.
- Small unobtrusive top-right FPS, Settings toggle persists immediately in Web.
- Mobile-only multitouch stick: analog walk, outer ring run, down crouch. Action buttons
  use vector icons and small short captions; jump/punch/kick/guard/relay/day-night/ultimate/
  impulse/menu/fullscreen/retry. Pause/focus loss releases held controls.
- Sound starts muted. Content cache, accepted art and external shared records retained.

Validation:
-27/27 GUT,350 assertions; formatting/lint and final export without engine/script errors.
- Native: route70frames,5kills/3relays/100HP, all ledges reachable; gate-ground4frames;
  ragdoll32frames (head hit, trip, airborne Moose); defense43frames:3blocks ->85HP,
  death25.35s, physical corpse observed, R restores upright rig/100HP. Zero capture errors.
- Raw ScreenTouch native route:2alternating punches, air kick, crouch kick, jump,
  T/Q/O and menu; concurrent stick/action fingers. Final icon capture16frames/zero errors.
- Public revision24: scores online, muted, default FPS visible. Settings FPS off survives
  immediate reload; restored on. Repeat load cache hit3/download0.
- Public normal keys: L raises guard, Q then two O impulses ->1kill/1corpse,100HP,
  172ground marks; after landing active physical parts0. No browser console errors.
- Public mobile emulation915x412: auto touch=true, icons fit. Screenshot:
  .studioigor/captures/public-v24/mobile-icons.png. Actual phone hardware not tested.
  Temporary QA tab closed, device overrides cleared. No leaderboard result submitted.
- Installer verified archive and all15manifest hashes, PHP/nginx syntax; services active.
  External scores SHA identical before/after activation:
  1b87882d5a8956a75270bd5aae85fef70e5599bcf38c6ac809814415754af85e.

User art/feel approval remains open. Final Firewall and full map remain future work.
