# Campaign IV–VII preparation — 2026-11-14

User approved four further stories/chapters: four rooms each,
16 original backgrounds, eight ordinary enemy species and four bosses.
Decision 30 records the accepted scope. All four chapters are implemented.

Sources checked:
- https://docs.godotengine.org/en/stable/classes/class_animatablebody2d.html
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html

Decisions for preparation:
- Append chapter IDs and room indices; preserve existing completion keys and score rows.
- Remove three-chapter limits in finish navigation, picker and local/shared records.
- Release API receives the same chapters.json as the game; no second kill-count table.
- Keep single-thread Compatibility Web export and bounded effects for mobile.
- Existing movement uses custom skeleton floor contacts, so a moving deck must carry
  the hero explicitly, as the working lift already does. AnimatableBody2D alone is insufficient.
- New rule per chapter only after approval; no extra action keys or uncontrolled ragdoll props.
- Preserve Firewall victory: quarantine remains lifted; next arc restores city supplies.

Verified preparation: 51 GUT tests / 734 assertions, PHP isolated chapter contracts
and 10 API checks, native chapter menu capture 2 frames / 0 errors.
No public deployment or public score writes during preparation.

## Final integration — 2026-11-15

Rechecked the official AnimatableBody2D and Web export pages above.
Keep Compatibility, single-thread Web export and content-hashed JS/WASM/PCK.
New physical banks/decks are separate from blood/rain impact planes: water
must receive splashes without becoming a rigid-body floor. Settled corpses
must wake when a moving deck leaves them without support.

Combined integration: 65 GUT tests / 1051 assertions; seven isolated PHP
chapter contracts and ten original API checks pass. Ordinary-input routes
II–VII finish without deaths; all three lifts permit walking onto the bridge
with zero jumps and zero height drop. Native IV–VII captures complete without
engine errors. Final terrain integration: 70 tests / 1089 assertions, real-rig
deck carrying/pause/sinking and bridge support captures pass. Final Web export
is clean; the public release check follows.

Preserve the live nginx cooperative routes during the campaign release;
they have an independent coop-current deployment and shared-host snippet.
