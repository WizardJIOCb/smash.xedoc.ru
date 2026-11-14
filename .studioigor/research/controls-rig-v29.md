# 2026-11-14 — drop, remap, turn and rig fixes
- User: drop gear; I sharp turn (supersedes U); controls editable; empty pistol attack throws it; two-hand firearms; enemy head alignment and hare knees.
- Godot InputMap: https://docs.godotengine.org/en/stable/classes/class_inputmap.html
- Physical key locations: https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html
- Runtime InputMap overrides, explicit physical keys, conflict rejection, Esc remains menu/cancel; native ConfigFile + Web localStorage. Restore original aliases on reset.
- G drop retains exact magazine/reserve; next empty-pistol attack throws once for18damage and leaves a recoverable pickup. Reload F remains optional before throwing.
- I flips facing; held movement can backpedal, a new movement press resumes automatic facing. Attack/stride contacts cancel on turn.
- Neck pivots moved onto painted necks for beaver/hare/foreman/fox/lynx. Intact neutral hare leg replaces torn pre-bent original; image_gen source/prompt retained.
- Two-arm wrist IK: extended pistol, shouldered rifle support, reload and recoil; retains block/kick/ultimate pose priorities.
