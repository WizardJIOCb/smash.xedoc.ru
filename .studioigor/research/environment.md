# Environment — 2026-11-13

- Native Windows + Codex. Upstream envcheck.py assumes Homebrew, macOS template paths and Claude config; its report was inspected, then a project-local native checker was added without changing the installed skill.
- Godot 4.7.2 official Windows archive SHA512 verified against release SHA512-SUMS; portable engine in .tools/godot, no system installation needed.
- Matching official export templates: only templates/web*.zip + version.txt extracted from the remote release ZIP with CRC verification. The range fallback needed the official pinned asset size because requests.head did not follow GitHub's redirect. No third-party binary mirror.
- Godot AI 4.4.1 release: bootstrap SHA256 verified; embedded v4 exact-tree archive and every file checked against the release manifest. Fresh exact-tree addon installed, bootstrap preserved under ignored .tools. Requires Godot 4.7+ and uv.
- Godot AI server and attach bridge pinned to 4.4.1; authenticated local editor connection and real scene_get_hierarchy call succeeded (WebSetup root). Telemetry disabled for task process. No global Codex MCP registration was changed; current access is through the local authenticated stdio bridge in tools/godot_mcp_probe.py.
- GUT release README maps 9.7.1 to Godot 4.7.x; installed that tag rather than GitHub's default/latest 9.6.1 branch. Two motion invariants pass on Godot 4.7.2.
- gdtoolkit 4.5.0 in .tools/python; format/lint tested on project scripts. Addon source is not reformatted.
- Git and git-lfs already available. Engine caches, tool environments and exports ignored; native art source excluded from Godot imports with art/.gdignore.
- Full editor runs hidden for MCP/LSP; user-facing output is the browser web export. No Claude plugin installed in a Codex session.
- Hello scene deliberately tests export/input with flattened accepted concept images and a movable light marker. It is not a playable moose rig or a finished look-dev scene.

## Sources
- https://github.com/godotengine/godot/releases/tag/4.7.2-stable
- https://github.com/hi-godot/godot-ai/releases/tag/v4.4.1
- https://github.com/hi-godot/godot-ai/blob/main/README.md
- https://github.com/bitwes/Gut/blob/v9.6.1/README.md (version compatibility table)
- https://github.com/bitwes/Gut/releases/tag/v9.7.1
- https://pypi.org/project/gdtoolkit/
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
