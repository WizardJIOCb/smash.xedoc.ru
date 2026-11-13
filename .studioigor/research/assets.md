# First rig asset pipeline — 2026-11-13

- Art direction and hero are locked to the three original v1 concepts; character must remain recognisable when assembled from parts.
- Native Godot Skeleton2D/Bone2D with child sprites supports cutout animation; deformable Polygon2D weights can be added where joints need skinning. Source: https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html and linked cutout tutorial.
- First kit: torso, pelvis, head, upper arm, forearm, fist, thigh, shin, shoe. Shared arm/leg art can be reused for far limbs with shading and draw order. Soft-alpha painted PNG, right-facing rest pose, pivots stored explicitly in data.
- Original character parts generated from accepted hero reference with image_gen; no borrowed game art. Nine-part atlas is an art source, not itself proof of a rig.
- Atlas slicing is deterministic cropping into cells and trimming transparent margins, with smooth downscaling for painted art, no palette reduction or nearest-neighbour fitting. Validate each part and reassembled figure at game scale.
- Background concept actors must be removed by image editing before using the environment under a moving rig; otherwise duplicated frozen figures would remain in the scene.
- First look-dev goal: one real assembled moose, weighted movement and clear joints in a single room. Do not produce the whole content list yet.
- Image generation is the same built-in tool already used for the approved concepts. No CLI/key fallback or paid marketplace assets.
