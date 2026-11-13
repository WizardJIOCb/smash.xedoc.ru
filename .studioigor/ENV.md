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
| GUT | 9.7.1 | Two pure motion invariants |
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
- Web scene is an environment smoke test: flattened concept images + a movable marker, no live moose skeleton/combat yet. Text in scene states this explicitly.
- Capture uses a real renderer in a hidden, non-headless process. Native capture: .studioigor/captures/web-setup-native, zero engine errors; browser proof: .studioigor/captures/style/web-setup-quarantine.png.
- Local web server is terminal session 30173. It is bound to 127.0.0.1; there is no public deployment.
