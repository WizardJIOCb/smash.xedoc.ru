# Bat motion reference study — 2026-11-14

Sources viewed:
- Texas Rangers Youth Academy, Baseball 101: https://img.mlbstatic.com/mlb-images/image/upload/mlb/g910nvibmyw51tlbnslq.pdf
- Little League grip photograph: https://www.littleleague.org/university/articles/backyard-tip-gripping-a-bat-for-baseball-or-softball/
- Photo sequence: https://rhm001.blogspot.com/2012/01/chapter10-batting-tips-2.html
- Baseball Canada fundamentals: https://www.baseball.ca/?alias=hitting-fundamentals&lang=english

Observed gap: v34 holds hands at waist and rotates the entire bat in the screen plane,
so it reads as a chopping/stabbing prop instead of a two-handed swing.
Reference: adjacent hands by rear shoulder, elbows below/behind hands, weight gathered
on rear foot; hips start turn, knob leads and barrel lags; level contact and continued
rotation through to front shoulder. Head stays looking at target.

Implementation: shoulder-height grip, separate elbow bend directions, projected
horizontal swing plane with barrel foreshortening, weight shift before planted-leg IK.
Keep hand artwork full width while barrel shortens in depth; restore ordinary fists
on drop/death. Damage remains confined to the forward sweep.
Images are private reference evidence only, excluded from the game export.

## v40 trajectory correction — 2026-11-14
- Previous drive moved the grip forward while the barrel was still upright; its
  return also raised the barrel before the hands had withdrawn from the face.
- Load pulls both hands behind the shoulder. The early drive stays back, then
  accelerates into contact with the weight transfer. Recovery withdraws the
  hands before bringing the barrel behind the head and back to the ready pose.
- Preserve distinct hand artwork, native wrist/shoulder attachment, timing and
  active damage window. Review isolated/queued swings in both facings/three stances.
