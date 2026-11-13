# Environment — Лось: район закрыт

<!-- Phase 4 (references/environment.md). Commands verified by a real run.
VERIFIED is switched only by `studio.py verify`. CAPTURE writes images to
.studioigor/captures/. -->
VERIFIED: yes

## Installed
| tool | version | why |
|---|---|---|
| Godot portable standard | 4.7.2.stable.official.ed1daf0bf | GDScript, Compatibility, web export |
| Web export templates | 4.7.2.stable | Official release archive, web targets only |
| Godot AI addon/server | 4.4.1 | Authenticated live editor MCP |
| GUT | 9.7.1 | Motion bounds, rig IK and spring stability |
| gdtoolkit | 4.5.0 | Format and lint in .tools/python |
| git-lfs | 3.6.1 | Local binary source storage; nothing pushed |

## Agent integrations
- Godot AI editor connection authenticated; tools/godot_mcp_probe.py discovered 47 tools and scene_get_hierarchy returned /WebSetup without errors.
- Access is the task-local stdio bridge, not a newly registered desktop tool namespace. No global Codex/Claude configuration changed.
- GDScript LSP listens on localhost:6005 while the task editor runs hidden (PID recorded in ignored .tools/editor.pid).
- Browser tab at http://127.0.0.1:8770/index.html was visually checked; real key input moved probe x=640→800.33 and changed quarantine=false→true in DOM metrics. Script errors from the first export were fixed by exporting all required resources.

## Commands
RUN: powershell -NoProfile -File tools/run.ps1 run
TEST: powershell -NoProfile -File tools/run.ps1 test
BUILD: powershell -NoProfile -File tools/run.ps1 build
CAPTURE: powershell -NoProfile -File tools/run.ps1 capture
EDITOR: powershell -NoProfile -File tools/run.ps1 editor

## Pitfalls
- Native Windows checker: .tools/python/Scripts/python.exe tools/envcheck_windows.py. Upstream checker is macOS/Claude-specific; local pipeline check adapted without changing skill files.
- Main scene is district_gym v16: start/help/pause/score menus, three connected painted locations, five enemies of three types, actual damage/guard/telegraphs/projectiles, three relays, jump ledges, win/loss and checkpoint repeat. W/Up/Space jump; established movement and J/K chains preserved. Native Skeleton2D heroes/enemies; v7 near fist and head/neck moved (-4,+5) local units. attack_gym and other art gyms remain runnable.
- CAPTURE now reviews attack_gym with fist_review.json: fist-v16, 63 frames, zero errors. district-route-v16 completed all 3 rooms / 5 enemies / 3 relays through ordinary gameplay inputs (65 frames, zero errors); district-loss-v15 proves defeat and R checkpoint recovery. Menu-v16 has 4 frames. FPS is not a browser benchmark. Native window is unfocusable; disposable process disconnects live keys while retaining scripted inputs.
- Local web server remains terminal session 30173 bound to 127.0.0.1. Public release: https://smash.xedoc.ru, /var/www/smash.xedoc.ru/current → versioned releases, Nginx and PHP8.3-FPM. Shared scores in /var/lib/smash-xedoc, separate from releases. GitHub WizardJIOCb/smash.xedoc.ru main, explicitly authorized push/deploy. Certbot renews domain certificate.
