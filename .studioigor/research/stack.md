# Stack research — 2026-11-13

Game: hand-painted 2D metroidvania, skeletal character animation, browser first. Art direction locked by user after original R2 concepts.

## Verified findings
- Godot official Windows page and GitHub latest release both identify 4.7.2-stable, released 2026-08-18. Standard Windows build is self-contained; no .NET version needed.
- Godot built-in Skeleton2D/Bone2D can deform Polygon2D through painted weights. Tutorial warns its content was not yet reviewed for 4.7: validate joints and weights in a real scene rather than trusting generated rig data.
- Godot 4 web export: GDScript, WebAssembly, WebGL2, Compatibility renderer. C# web export is unavailable. Forward+/Mobile renderers and their advanced effects are not a browser path.
- Single-thread export is the documented default; use this initially. Browser audio requires a player gesture. Browser performance and download size have not been measured for this project.
- Godot is MIT. Preserve copyright/license notices in the release. No paid skeletal editor is needed for its native skeleton pipeline.
- Godot CLI supports imports, project runs and exports; editor automation candidate: Coding-Solo/godot-mcp. It has not been installed or called here; editor MCP integration must be verified in environment phase.
- Phaser official stable download currently points to 4.2.1 (2026-07-09), a JavaScript framework. It is a viable web-first alternative; skeletal authoring pipeline must be chosen and tested separately. The attempted Spine concepts page was inaccessible, so current Phaser4 Spine integration details remain UNVERIFIED.
- Spine runtimes have separate licensing tied to the Spine Editor agreement; do not silently assume a free plugin grants distribution rights. No paid editor is being purchased.
- Local PATH: Node and npm available; godot/godot4 not found in PATH. Other installation locations have not been exhaustively searched.

## Recommendation for this project
- Prefer Godot 4.7.2 standard + GDScript: native 2D rig/weights, animation editing, scenes, collision, world state effects and web export in one project. This deviates from generic web-first recommendations because skeletal animation is the user's primary requirement.
- Alternative: Phaser4 + TypeScript, with an explicitly researched rig solution. Convenient for browser input/debugging and smaller engine packaging, but the same animation quality still requires authored layered art and poses; cannot promise it from procedural limb rotations.
- The most expensive risk is preserving the accepted painted character under deformation. First real test: one layered moose rig and one room, with idle/run/jump/strike and district-state blend, tested in the browser.
- Proposed targets, not measured results: 60 fps on desktop browser, ≤30 MB compressed initial build where practical, effects reduced before actor readability; benchmark after hello scene.
- Await the user's engine decision; no engine installation has started.

## Sources (checked this session)
- https://godotengine.org/download/windows/
- https://api.github.com/repos/godotengine/godot/releases/latest
- https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- https://godotengine.org/license/
- https://github.com/Coding-Solo/godot-mcp
- https://phaser.io/download/stable
- https://esotericsoftware.com/spine-runtimes-license
