# M01 — attack animation and input — 2026-11-13

- https://docs.godotengine.org/en/stable/classes/class_inputevent.html — event.is_action_pressed defaults to no keyboard echo.
- https://docs.godotengine.org/en/stable/classes/class_inputeventaction.html — synthetic actions reach Node._input; preserve native capture schedule support.
- https://docs.godotengine.org/en/stable/classes/class_bone2d.html — animate node rotation, retain rest transforms for skinned meshes.
- Implementation: event-driven one-slot buffer, physics-timed attack states, alternating camera-side hands, separate ground/air poses. Timings in data/attacks.json.
- Existing native Skeleton2D retained; one continuous near sleeve weighted across arm and forearm makes both cream stripes continuous through bends and straight punches.
- This step covers animation and chaining. Enemy damage, parry, dash and combat difficulty remain later work.
- Follow-up requests add crouch, backpedal, Shift sprint, alternating kick legs and a phase-aligned coast. Stride stop integrates constant deceleration over exactly the remaining cycle distance; planted end phase depends on movement relative to facing.
- Crouch and high-kick support use the existing two-bone IK, with pelvis displacement applied before solving the support leg; torso lean starts during chamber instead of waiting for foot extension.
