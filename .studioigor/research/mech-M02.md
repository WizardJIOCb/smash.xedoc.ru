# M02 — enemy encounters and first route (2026-11-13)

Sources:
- https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html — body motion and grounded contacts.
- https://docs.godotengine.org/en/stable/classes/class_area2d.html — overlap queries and collision masks.
- https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html — separation of motion and hit detection.

Decision: preserve the already playtested custom jump/stride controller for this small route. One-way service ledges select a floor below the feet. No claim of general slope/wall physics. Strike contacts use the actual animated hand/shoe position swept between active frames against enemy hurt rectangles. Serial contact memory prevents duplicate damage; no sprite-rectangle collisions across the entire reach.

AI: approach → visible windup → attack → vulnerable recovery. Shield guard answers punches but opens on a kick or windup. High cable misses a crouching body; drone locks aim before firing. All damage has reaction, sound, brief camera shake and a capped invulnerability interval. Tunings are in data/encounters.json.

Playable M02 gym: three connected original painted rooms; five enemies, two optional/required jump ledges for the second relay, three relays, healing, room checkpoint repeat, win/loss. Full metroidvania map, unlock ability, parry, dash and final Firewall boss remain later steps. User explicitly asked to add enemies and progression; no taste gate is marked approved by the agent.
