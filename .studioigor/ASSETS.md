# Assets — Лось: район закрыт

<!-- Phase 5 (references/assets.md). -->

## Inventory
<!-- one line per asset card (references/assets.md): name · category · style · budget · source · status -->
| asset | category | style | budget | source | status |
|---|---|---|---|---|---|
| Moose cutout kit | character | accepted painted burgundy tracksuit | 9 unique PNG parts, 15 bones | original image_gen using accepted concept | first rig in browser |
| Courtyard, alive and quarantine | environment | teal forest district / red lockdown | 2 backgrounds, 1672x941 | original image_gen edits | empty backgrounds in scene |
| Rain, spores, punch arc | VFX | quiet warm particles / cold rain | 80 streaks, 18 spores | GDScript drawing | first pass |
| v3 correction kit | character | same moose identity | neck, compact pelvis, fur-lined torso and two eye donor crops | original image_gen edits | review |

## Strategy by category
| category | source (pack / Blender / procedural / generation / user) | why | status |
|---|---|---|---|
| Character | original image generation + native cutout rig | preserve accepted painted identity and animate joints | ready for user review |
| Environment | original generation, actors removed by edit | evaluate character against accepted world | first backdrop; layered geometry later |
| Props | original generation / procedural assembly | match environment palette | later |
| VFX | engine code and shaders | responsive action feedback and world states | first pass |
| UI | engine controls and typography | readable browser controls | temporary playtest labels |
| Sound / music | source to be evaluated with user | needs combat timing before audio pass | not prepared |

## Conventions
1280x720 logical canvas, pixels, Y down. Painted RGBA PNG, linear filtering. Limb pivots defined by two source points and mounted on Bone2D; joint ends overlap. Atlas cells are cropped and trimmed by tools/slice_moose.py without repainting or alpha removal. Source manifest records crop bounds, including the torso-v2 override. Torso v2 removes baked-in sleeves; independent arms remain. Torso uses a native 35-vertex / 48-triangle Polygon2D with normalized hips/chest weights. Other pieces are rigid cutout attached to Skeleton2D. No character collision or damage shapes in this look-dev scene.

## Requests to the user
- none

## License registry
| asset / pack | source (URL) | license | author | path | attribution |
|---|---|---|---|---|---|
| Original moose kit and clean courtyard states | built-in image_gen, accepted concept references | generated project art; no external pack | project | art/characters/los, art/environment, assets | no third-party attribution assigned |

Reference-board screenshots remain reference-only; none is used in the game build. Engine/addon licenses remain in their installed source trees. Exact art prompts: art/characters/los/prompts-v1.md and torso-v2-prompt.md.

V3 overrides: tools/prepare_rig_v3.py crops and fits generated neck, pelvis and torso; crops the largest connected alpha component of the old atlas fist to exclude a stray tuft; crops forward eyes from generated head art. Head source stays unchanged. Runtime eye shader blends only two small rectangles with feathered edges; original camera gaze returns for 750 ms after 4.5 s idle, subsequent intervals 8–12 s. Moving/jumping/attacking cancels the glance. Prompts: art/characters/los/parts-v3-prompts.md. Export and crop bounds: assets/characters/los/parts_v3_manifest.json.
