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
| v4 cloth and near hand | character | continuous navy stripes and dorsal fist | 2 pant meshes x 133 vertices; 1 near fist sprite | original image_gen / head fur crop | review |

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

V4 replaces the pelvis/thigh/shin picture stack with continuous pant-leg skins. Upper rows blend hips to thigh, knee rows blend thigh to shin; stripes share one texture from waist to cuff. Far-leg UV shows the opposite seam. Near hip is now on the same side as near shoulder; relative near/far render priority is retained when mirroring. Near arm/fist are above head. Near fist uses fist_back.png; far fist retains fist.png. Neck bridge is an unpainted crop of head.png; fur inside collar was corrected to its brown palette. tools/prepare_rig_v4.py is the last step in canonical tools/slice_moose.py. Prompts and source paths: art/characters/los/parts-v4-prompts.md.
# V5 — inner surfaces and joints
- New original image_gen sources: `art/characters/los/*inner-v5.png`, `fist-back-v5.png`; exact prompts in `parts-v5-prompts.md`.
- Separate unstriped far upper sleeve, forearm and pant leg; near striped surfaces preserved.
- Compact dorsal near fist: wrist-to-knuckle mounting axis, length 23 instead of 18. Near elbow pivots inset for cloth overlap; original upper sleeve atlas fragments excluded by sprite region.
- Far cuff extends 3 units and draws over its own shoe. Near leg/shoe unchanged.
- Canonical `slice_moose.py` runs v3 → v4 → v5 preparation; original sources preserved.

## V6 — continuous near sleeve
- Original image_gen source `art/characters/los/sleeve-v6.png`, exact prompt `sleeve-v6-prompt.md`; export `tools/prepare_rig_v6.py`, final stage of canonical slicing.
- One 175-vertex native Polygon2D weighted to near arm and forearm replaces separate sleeve sprites; both stripes remain connected through elbow and straight extension. Far unstriped sleeves retained.

## Title/menu v26
Original generated paved courtyard: art/branding/menu-ground-v1.png and exact prompt
menu-ground-v1-prompt.md, built-in image_gen, no external pack or attribution assigned.
Loading portrait rendered from the existing rig; canonical conversion tools/prepare_branding.py.
