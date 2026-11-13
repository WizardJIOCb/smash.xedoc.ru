# Rig refinement — 2026-11-13

- User: "Доводим плавность и вес анимации"; reported duplicate sleeves on the torso. Fix original torso artwork before rig polish.
- Sources: [Godot Polygon2D](https://docs.godotengine.org/en/stable/classes/class_polygon2d.html), [2D skeletons](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html), [interpolation](https://docs.godotengine.org/en/stable/tutorials/math/interpolation.html).
- Native Polygon2D provides weighted Skeleton2D deformation. Use a small torso grid blending hips/body weights; preserve head and limbs as separate painted pieces.
- Animation is driven by actual displacement, not elapsed idle time. During support, save a foot's world X and solve two equal-length bones toward it; swing returns to the next foothold.
- Motion numbers live in data/rig_motion.json: 235 px/s, acceleration 1150 px/s2, braking 1650 px/s2; jump preparation 67 ms, launch 470 px/s, gravity 1500 px/s2; attack 110 ms anticipation, extension at 170 ms, recovery by 460 ms.
- Spring integration uses <=1/120 s substeps to prevent a low frame rate from creating unstable head/body oscillation. Pose blending uses exponential delta-based factors.
- Verify rendered seams in both directions, jump/landing and extension. Native fixed-fps capture is visual evidence, not a browser performance benchmark.
