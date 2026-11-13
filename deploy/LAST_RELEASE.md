# Public release v26

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source: d523f66c1eb2cfeaa9b2a0bb1e233a56b8be6bc8
- Current: /var/www/smash.xedoc.ru/releases/v26-d523f66c1eb2
- Previous/rollback: /var/www/smash.xedoc.ru/releases/v24-01ad83f0c5ff
- Archive SHA256: cb1b93422568fb34c0249d3a73e56269a8f3e2be5cd0bf9ec97e36461e88d155

Changes:
- Blood mist/drops/ground pools use3pooled MultiMesh batches. Same particle quantities,
  road-depth scatter and fade; empty FX stop updating and room clear empties GPU instances.
  Isolated native220pool benchmark1320->1ground draw call; airborne p95 8.530->4.448ms.
  Frame cap240; not a claimed all-device FPS multiplier.
- Both active kick feet lift their toes during extension, high extra0.36rad,
  normal/air0.22, crouch0.12, easing back during recovery. Rear airborne foot retained.
- New original generated title courtyard with broad wet foreground paving. Menu keeps
  live Moose rig, shadows follow both foot bones; extra portrait vertical bob removed.
  Built-in image_gen source and exact prompt: art/branding/menu-ground-v1*.
- Custom branded Web loader uses same courtyard plus actual rig portrait, real streamed
  byte progress0-90%, engine-start promise100%. Cache writes no longer block progress;
  repeat loads retain3asset hits, cache=clear reloads only game assets, settings retained.
  Responsive copy/progress, reduced-motion and error/retry states; Godot logo disabled.
- Rain formerly wrapped to y730. Now80pooled lifecycles stop at highest road/ledge,
  random shallow depth,4tiny ballistic droplets plus expanding rings,2draw batches.
  Ground/ledge plane resets with room; no extra rigid bodies or per-drop nodes.
- Jump-landing spray stores actual floor_y+8 instead of fixed565, including upper ledges.
- Existing quiet-first-load, mobile controls, L block/O impulse/T world/Q ultimate,
  prior character art, ragdoll mechanics and external shared scores preserved.

Validation:
-27/27 GUT,358assertions, formatting/lint; final export no engine/script errors.
- Native route70frames/0errors/0warnings:5kills,3relays, completed; weather48frames/0errors:
  third road and upper ledge415/spray423. Both high-kick legs reviewed in kick-toe-v25.
- Public revision26, new grounded menu, muted, scores online. First updated load hit2/
  download1 (retains engine); real keys enter game, run, guard, Q/O twice ->1kill/172marks,
  100HP. Later public sample180FPS/88drawcalls with172marks; native blood-only benchmark
  is the isolated evidence, public sample includes ragdoll and is not a controlled FPS comparison.
- Public screenshots: .studioigor/captures/public-v26/menu.png, loading.png, blood-rain.png.
- Installer verifies all18manifest hashes and archive; PHP/nginx checks pass, services active.
  External scores unchanged across activation:1b51717e53ce0c9121d537f82707440de633588f515bb09ba0878c755a6feaee.
  No leaderboard result submitted. Physical mobile hardware untested; taste gates stay open.
- Final public fresh-link check: clear=true/hit0/download3, progress100/menu ready/revision26.
  Repeat cached startup and console status verified at release closure below.
- Closure: repeat public load hit3/download0, progress100, revision26/menu ready, scores online,
  sound muted. Console errors0. Temporary tabs closed; network/device test overrides cleared.
