# World prop replacement — 2026-11-15

User rejects the flat mechanic placeholders and asks to finish all new scenery.
Scope: all four campaign rules, with individually aligned room floors.

Sources checked:
- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
- https://docs.godotengine.org/en/stable/classes/class_canvasitem.html
- https://docs.godotengine.org/en/stable/classes/class_gradienttexture2d.html

Use original transparent painted PNG sprites, trimmed and fitted once with
smooth resampling. Keep alpha; export only runtime images, not source masters.
Draw props behind actors and anchor their sills/feet to the same sole plane
as collisions and rain/blood. Keep functional warning text inside a physical
signal instrument, with no floating debug labels on scenery.

Replace alcoves, instrument, barricades, vines, supports, bridge, cargo deck,
water and alley patches. Runtime VFX remain bounded and physical rules retain
their existing hitboxes/timing. Review normal, warning and broken states in
native captures before the final Web and public release.

Soft contact shadows and signal halos share one radial texture mask instead of
layered antialiased circle geometry. Remove the persistent cyan guard arc;
existing hit feedback and frontal guard rules stay intact.
