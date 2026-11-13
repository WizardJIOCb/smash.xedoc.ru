# M03 — physical deaths, ground contact and guard (2026-11-14)

Sources: [RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html),
[PinJoint2D](https://docs.godotengine.org/en/stable/classes/class_pinjoint2d.html),
[PhysicalBone2D](https://docs.godotengine.org/en/stable/classes/class_physicalbone2d.html),
[Joint2D](https://docs.godotengine.org/en/stable/classes/class_joint2d.html).

- Engine supports native rigid bodies and pin joints. Discrete contacts are sufficient
  for the tuned velocities and 24px terrain; CCD was unstable with articulated contacts.
- PhysicalBone2D also needs manually created joints and a skeleton modification.
- Decision: native RigidBody2D + PinJoint2D with explicit world-to-bone bind transforms.
  This preserves our mirrored, scaled painterly meshes without a second visual skeleton.
- Capture the actual final pose, inherited movement/fall velocity and contact point.
  Apply a local impulse to the nearest anatomical body; gravity and surface contacts finish the fall.
- No self-collision between overlapping painted parts. Bodies collide with room ground/one-way ledges.
- [Engine source](https://github.com/godotengine/godot/blob/master/modules/godot_physics_2d/godot_joints_2d.cpp)
  reveals native pin limits constrain world center-to-center direction, fighting full-body rotation.
  Replaced them with equal/opposite bounded restoring torques on relative body angles.
  Waist/neck/wrist limits are narrower than shoulders/knees. Corpses remain 10s, fade over 2s.
- Alive enemies need planted ankle IK and a foot skin weight, not sinusoidal leg rotations.
  Shared sole plane is actor floor +10px, retaining accepted Moose placement against painted ground.
- Blood: small 9-drop hit /34-drop lethal burst, upward dispersion, gravity780px/s²,
  swept platform contacts, secondary splashes, 12–18s wet marks fading during the last4s.
  Bounded at300 droplets,48 mist clouds,220 stains; drones leak dark oil.
- Guard: hold L, cancel attacks, movement28%, no sprint; incoming damage25% rounded up,
  knockback60 vs190. Guard does not consume ultimate charge and can coexist with crouch.
- Risks to verify: mirrored skeleton constraints, ground penetration, player death/restart,
  freezing on menu, blood fading and the entire existing three-room route in Web.

## v24 follow-up: coherent bodies, cost and touch (2026-11-14)
- Sources: https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html
  and https://docs.godotengine.org/en/stable/classes/class_inputeventscreentouch.html;
  https://docs.godotengine.org/en/stable/classes/class_input.html#class-input-method-parse-input-event
- Compound trunk supports pelvis/chest/head; articulated limbs keep native pin joints and
  anatomical relative limits. 13 physical bodies drive 15 Moose bones; 15 for shield enemy.
  This intentionally stiffens the core; it is not a detailed simulated human spine.
- Per-corpse collision layer isolates corpses; only core versus distal legs self-collide.
  Solver12 instead24. Cache body/bone/constraint references. Once low motion persists0.45s,
  detach joints, disable contacts and freeze bodies; pose remains visible and fades normally.
- Three-corpse benchmark: actual rendered native frames, no screenshot readback/fixedfps.
  Before:47 active bodies even at rest, resting-frame p95=16.69ms.
  After:41 during fall,0 once settled; resting p95=5.925ms; falling p95=14.18 vs17.264ms.
  Native comparison on this machine, not a phone/Web FPS guarantee. Capture FPS is invalid
  for profiling because viewport readback stalls rendering. Tool: ragdoll_benchmark.tscn.
- Blood has randomized road depth -14..+7px, narrower on ledges, irregular lobed wet pools
  below shoes/bodies. Cache stable puddle drawing; fade redraw12Hz; moving drops stay60Hz.
- Mobile uses ScreenTouch/Drag indices and InputEventAction, same input path as keyboard.
  Stick: analog x, outer ring sprint, down crouch. Independent action buttons support
  multitouch; cancel on pause/focus loss. Icons with short small captions prevent overflow.
- Desktop L guard / O impulse; T day/night / Q ultimate stay independent. FPS default on,
  Settings toggle saved immediately in Web localStorage as well as ConfigFile.
