# Asset conversion notes — v19

PNG RGBA with soft alpha, painterly HD art, smooth fitting. Moose fist points
right with wrist left: same normalized .09/.64 to .90/.47 segment anchors, trim
generated alpha >24 then fit within512x512. Far inner fist preserved (4 digits).
Enemy source art faces left, mirrored at root for right. Existing atlas arms
are complete shoulder-to-hand silhouettes on transparent PNGs. Arm meshes map
unchanged texture pixels to a grid and native upper/fore bones; props follow
hand bones. Final authority: scripts/actors/enemy_rig.gd and enemy_arm_skin.gd.

## Title art v26
Existing background: painted opaque landscape PNG scaled to1280x720; live soft-alpha
rig soles at~680/720 in menu. Built-in image_gen source art/branding/menu-ground-v1.png,
exact prompt alongside. tools/prepare_branding.py produces bottom-aligned smooth1280x720
WebP. Contact shadows follow foot bones; extra whole-character bob removed. Loading
portrait is the actual rig rendered transparent512x768, trimmed and fitted bottom-centre.
