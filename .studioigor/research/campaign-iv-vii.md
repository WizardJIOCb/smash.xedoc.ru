# Campaign IV–VII preparation — 2026-11-14

User requested four further stories/chapters. Proposed scope: four rooms each,
16 original backgrounds, eight ordinary enemy species and four bosses.
Story/scale remain proposed; no new encounters or mechanics implemented yet.

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
