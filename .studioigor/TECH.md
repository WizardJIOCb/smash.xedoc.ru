# Technology — Лось: район закрыт

<!-- Phase 3 (references/stack.md). ENGINE — one of: godot, godot-mono, unity,
unreal, web, defold, bevy (read by studio.py and envcheck.py). DIMENSION — 2D or 3D
(2.5D with 3D models is 3D); envcheck.py recommends Blender for 3D. -->
ENGINE: godot
ENGINE VERSION: 4.7.2
DIMENSION: 2D
LANGUAGE: GDScript
PLATFORMS: web (desktop browser first)

## Decision
- context: painted 2D metroidvania; skeletal animation is the highest priority; browser by link.
- options: Godot — native bones/weights, animation editing and web export / WebGL2 Compatibility constraints; Phaser4 + TypeScript — web-native workflow / rig pipeline requires separate research and tooling.
- choice and why: user chose Godot 4.7.2 + GDScript after the comparison, 2026-11-13.
- consequences: author layered 2D art for a real rig; benchmark Compatibility web export early, no C# or Forward+ assumptions.

## Budgets
Targets, not measured: 60 fps on desktop browser; ≤30 MB compressed initial build where practical; reduce atmosphere before harming actor/ledge readability. Actual figures will be measured on a web build.

## Project structure
scenes/ (entities, gyms), scripts/ (typed GDScript), data/ (tuning), art/ (source and runtime images), addons/ (licensed editor/test tools), tools/ (build and verification), build/ (ignored exports), .tools/ (ignored portable engine/tool environment).
