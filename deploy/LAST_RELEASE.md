# Public release v34

- Domain:https://smash.xedoc.ru/
- Runtime source:11abd8fdc1ab7dcf29cf442c40176a1c86850baf
- Current:/var/www/smash.xedoc.ru/releases/v34-11abd8fdc1ab
- Rollback:/var/www/smash.xedoc.ru/releases/v33-3550764d45bf
- Archive:91,652,664bytes;18verified files.
- SHA256:85f25296c5b6f126f3fecc1ba328f56c6a8972bbb7060647507edce409fc630a

Changes:
- New transparent bat grip art with distinct left/right hands wrapped around handle.
  Original fists hidden only while equipped; both sleeves follow assembly wrist anchors.
- Beaver wrench and hare pipe have integrated wrapped hands; diagonal forearm cutoff
  preserves cuff continuity. Ready pose in front, rear windup, forward impact and return.
- Drop/swap/death restore original Moose hands; pickup art has no attached hands.

Validation:
-48GUT/672assertions, format/lint, clean Web export. Both wrist anchors stay within
  0.05px through standing/crouch/air swings in both facings; hand restoration tested.
- Native final bat63frames, worst wrist gap0.0002px at2.1scale; actual enemy AI96frames
  plus final cuff32frames, bat contact96frames/3contacts.0errors; relevant phases viewed.
- Smooth native review recorded390frames/60FPS,6.5s; MP4 decode verified.
- Public revision34:3bat attacks/4hits/100HP; enemy5hits/3blocks/70HP; Tab/G restores
  fists and creates1plain bat pickup. Actual frames viewed; console errors0.
  Cache2hits/1download; scores online. QA tab closed; no leaderboard result submitted.
- HTTPS/release.json,18manifest hashes, PHP/nginx and active services verified.
  Scores unchanged during activation:
  893bd1b467d8f909e8228bb3fb8fb752641e28f3bb49d1573d0e7ecaf8dd8e99.
- Evidence:.studioigor/captures/public-v34,bat-checked-v34,enemy-cuff-v34,
  bat-contact-v34,bat-motion-v34.mp4. User appearance/feel approval remains open.
