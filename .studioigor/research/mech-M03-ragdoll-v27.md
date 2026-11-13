# Ragdoll v27 — 2026-11-14
Sources checked: https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html
https://docs.godotengine.org/en/stable/classes/class_pinjoint2d.html
- Native impulses/torque and freeze retained; do not project transforms every frame.
- Heavy trunk overwhelmed soft knee/ankle torsion. Each leg now retains a captured anatomical
  bend (semi-rigid compound), with separate native hip hinge; arms remain articulated.
  This is deliberately not independently simulated knee/ankle motion.
- Moose9 physical bodies/8 pins drive15 bones; shield11 bodies/10 pins.
- Hip torsion stiffened with capped damping. Broad antler tips are decorative; brow contact8.
- At rest detach pins, zero velocities/freeze/disable contacts. Hit reattaches cached pins,
  wakes existing bodies, capped small kick/punch velocity and local impulse. No new body nodes.
- Cached physical-shape bounds follow moving corpse bones, not the enemy's old live hurtbox.
- Attack serial dedup shared across live/dead states; corpse hits do not reward score/charge.
- R previously queued corpse deletion then reset bones; its late process wrote dead pose back.
  Disable processing and detach immediately, then restore all rest transforms.
- Facing now requires movement input aligned with velocity, preserving punch backpedal behavior.
- No player hit grace or alpha blink; existing per-swing enemy hit flag remains authoritative.
