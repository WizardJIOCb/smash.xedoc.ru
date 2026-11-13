# Blood draw-call bottleneck — 2026-11-14

User: blood appearance immediately reduces FPS, even with corpse settling enabled.

Sources: https://docs.godotengine.org/en/stable/classes/class_multimesh.html
https://docs.godotengine.org/en/stable/classes/class_multimeshinstance2d.html
https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html

- Blood-only rendered scene excludes enemies/ragdolls. Same scene/seed, no frame readback,
  vsync disabled,240FPS cap. Tools/blood_benchmark.tscn separates empty/airborne/pools/hidden/fade.
- v24: one lethal burst ->136marks ->816draw calls, plus1background;220marks ->1320+1.
  Hiding pools restores1call. Keeping CanvasItem geometry cached does not batch its circles.
- v25: shared raster masks prepared once on load; three pooled MultiMeshInstance2D batches
  for mist/drops/ground pools. Per-instance transform/tint/alpha, no hit-time node/mesh allocation.
  Both136and220ground marks now need1call, plus1background. Airborne sample p95=3totalcalls.
- Native frame p95 during airborne burst8.530->4.448ms. Stable mean capped near4.167ms;
  do not claim an uncapped FPS multiplier or phone FPS based on this run.
- Preserve9/34primary drops, secondary splashes, road depth,220mark cap,12-18s life/fade.
  Idle FX stop physics updates; room clear resets every visible GPU instance immediately.
- Existing landing/depth/fade test extended to cover GPU removal, room clear and idle updates.
- Full numerical report: blood-v25-benchmark.json. Physical phone remains a separate boundary.
