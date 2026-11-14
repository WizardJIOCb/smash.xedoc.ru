# Original aftermath art

Built-in image_gen generates each background and each character sheet separately.
Exact prompts: prompts.json. Generated masters are copied into sources/.

Runtime format verified from existing assets and drawing code:
- Background:1280x720 RGB WebP, side-on, feet y555 / pavement front near620.
- Enemy parts:soft RGBA PNG; head416x376,torso264x316,arm180x276,leg152x296.
- Source sheets:3columns x2rows; head/torso/arm then leg/weapon/extra.
- Art faces LEFT; skeleton mirrors right. Head bottom neck pivot near(0.5,0.87).
- Arm shoulder(0.77,0.10),elbow(0.65,0.52),wrist(0.20,0.87); neutral planted boot.
- Weapon shaft upright,handle low; gun horizontal LEFT. Verify hand placement in rig.
- Clean/trim source components, fit once with smooth Lanczos; preserve soft alpha.
