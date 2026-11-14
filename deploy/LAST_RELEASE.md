# Public release v39

- Domain:https://smash.xedoc.ru/
- Runtime source:0467d8267168d24fa03ed54ad8b56243b5a21631
- Current:/var/www/smash.xedoc.ru/releases/v39-0467d8267168
- Rollback:/var/www/smash.xedoc.ru/releases/v38-541ed783a16a
- Archive:93,547,638bytes;18verified files.
- SHA256:484860ef14077d024b3742c632241dd7496ad32750765158bac09284900f0f8b

Depot and tower upper walkways extend to786, overlapping the lift edge790 by4px.
The visible ledge, custom feet surface and physical terrain share the same rect;
both exits can be walked across without jumping. Updated hints describe walking.
The native campaign driver no longer jumps off lifts and checks zero jump delta
and zero downward drift during each transfer.

Validation:
-51GUT/722assertions, format/lint, clean Web export.
- Native ordinary-input routes won: depot58.77s/14kills and tower51.97s/12kills,
  both4relays/100HP/0deaths. Lift transfers each jumps0/drop0.0px; scores offline.
  Native depot capture71frames/0errors, walk across the seam reviewed.
- Public revision39: ordinary inputs cleared13enemies/2relays and rode the lift.
  Walked right714.75->899.85, back741.88, then stopped at seam809.48; feet350
  throughout, jumps0/100HP. Console0errors,cache2hits/1download; QA tab closed
  before victory, no score sent.
- HTTPS/release.json200,18manifest hashes verified, PHP/nginx valid, services active.
  Scores unchanged during activation:
  42a8acc7f1ba5320a61479249c63adce86a479e88682a7d3ae8a92f87986fa40.
- Evidence:.studioigor/captures/lift-walk-v39,public-v39;
  .tools/depot-route-v39.log,.tools/tower-route-v39.log. Overall art/feel gates open.
