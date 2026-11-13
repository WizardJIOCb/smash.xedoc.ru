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
- Guard: hold I, cancel attacks, movement28%, no sprint; incoming damage25% rounded up,
  knockback60 vs190. Guard does not consume ultimate charge and can coexist with crouch.
- Risks to verify: mirrored skeleton constraints, ground penetration, player death/restart,
  freezing on menu, blood fading and the entire existing three-room route in Web.
