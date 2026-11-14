# Public release v33

- Domain:https://smash.xedoc.ru/; fresh load:https://smash.xedoc.ru/?cache=clear
- Runtime source:3550764d45bf32413f49fed1a953dfc30d30f007
- Current:/var/www/smash.xedoc.ru/releases/v33-3550764d45bf
- Rollback:/var/www/smash.xedoc.ru/releases/v32-85a4574389fd
- Archive:86,434,863bytes;18verified files.
- SHA256:2c63474c760500ec305bf98cc00200c2ad5c68233a23ed59a677a8d8ae6f1d87

Changes:
- Moose support palm uses actual fore-end anchor transformed by same recoil angle as
  gun. Main grip, support and visible prop share recoil phase, including automatic fire.
- Enemy sleeve/prop/finger layers split; tool shaft behind own head, grip above sleeve
  and below fingers. Off hand guards, trunk leans into strike, gun support follows recoil.
- Melee damage delayed to forward impact; hare second beat rearms visibly, final
  recovery cannot jump into a fresh windup. Existing once-per-beat slow-frame logic kept.

Validation:
-47GUT/656assertions, format/lint, Web export. Contact regression checks90automatic
  frames per facing with palm/fore-end separation below0.05px. Hare test verifies
  no early damage, both contacts, neutral final return.
- Native gun76frames; actual AI96frames both facings; final melee timing78frames;
  final shaft/grip layers32frames.0errors; relevant frames viewed.
- Public revision33/muted/scores online, cache2hits/1download. Chapter2 enemy AI:
  4hits/3blocks/66HP. Chapter3 normal route4kills/1relay to room9, collect rifle,
  holdJ fires12rounds, loaded12/24, total26hits/5kills/100HP. Gun grip, enemies and
  deaths viewed; console errors0. QA tab closed; no leaderboard result submitted.
- HTTPS/release.json,18manifest hashes, PHP/nginx and active services verified.
  Shared scores unchanged during activation:
  09fd0b10d052787c195611a5c4f5f69163c46b74eb3ee0de6ff30faca2a1df3e.
- Evidence:.studioigor/captures/public-v33,rifle-grip-v33,enemy-final-v33,
  enemy-timing-v33,enemy-layers-v33. Physical phone/user appearance and feel approval open.
