# Enemy arm repair and ledge, 2026-11-14

User screenshots show hollow shoulders on boar/rat and a difficult upper ledge.
Existing source atlases contain complete painted arms; regeneration is unnecessary.
Left-facing enemy art has its visible shoulder on the RIGHT of the torso, but
the rig put the near arm on the left. Far arm hidden behind torso leaves the
actual shoulder hole exposed. Correct shoulder positions, add forearm/hand bones,
skin the existing continuous sleeve and attach equipment to hands with stable
world angles. Verify both facings and windup/contact/recovery in a dedicated gym.

Godot sources reviewed:
- https://docs.godotengine.org/en/4.4/tutorials/animation/2d_skeletons.html
- https://docs.godotengine.org/en/4.5/classes/class_bone2d.html

Use native rest transforms and normalized weights, no replacement animation engine.
Upper alley ledge lowered from y395 to y415: rise40 instead of60, versus jump
apex73.6 (470 squared / 3000). Relay lowered20 as well to retain its mounting.
Actual controls must reach and LAND on upper ledge before the review driver can
disable its relay. Preserve combat tuning and current online records.
