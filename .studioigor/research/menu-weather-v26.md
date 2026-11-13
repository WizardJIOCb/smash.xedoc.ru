# Title loading and grounded weather — 2026-11-14

Sources:
- https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html
- https://docs.godotengine.org/en/stable/tutorials/platform/web/html5_shell_classref.html
- https://docs.godotengine.org/en/stable/classes/class_multimesh.html

Custom HTML shell uses exported configuration and Engine.startGame promise. Real
streamed uncompressed JS/WASM/PCK bytes account for0–90%; engine-start resolution
finishes100%. Cache writes run concurrently instead of blocking the first progress
event; cleanup awaits writes. Cache unavailable/quota still permits network startup.
No default Godot image; responsive branded error/retry, reduced-motion support.

Rain formerly wrapped80lines throughy730 regardless of the floor. Two pooled
MultiMesh batches now draw80 bounded lifecycles, splashes and elliptical ripples.
Highest intersected ledge wins; ground impacts randomize−28..−5px from the shared
sole plane, ledges−12..−7px. Tail ends cannot extend beneath impact; secondary drops
stop when returning to that plane. Road plane comes from room data, independent of
the player's current platform. No rain rigid bodies or per-drop nodes.

Landing spray previously hardcodedy565; now stores floor_y+8 at the actual landing.
Native weather48frames/0errors checks room3 and upper alley ledge (sprayy423,
ledgefloor415). Native route70frames/0errors completes5kills/3relays. Captures include
GPU readback and are not FPS benchmarks. User visual acceptance remains open.
