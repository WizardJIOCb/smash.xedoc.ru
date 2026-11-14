# Public release v43

- URL: https://smash.xedoc.ru/
- Runtime source: 2d9e22ae4cc3b3f48be4713e34388f48f9330089
- Current: /var/www/smash.xedoc.ru/releases/v43-2d9e22ae4cc3
- Rollback: /var/www/smash.xedoc.ru/releases/v41-09555709073f
- Archive: 150315684 bytes; 19 files verified by installer.
- SHA256: f4bbe14489e1ffb960942a7db2189fe3ac73aea61bec3e4a6d12ca6b893ebfc3
- PCK: game-e71ffcb3dee7dc44f07e.pck

Main game now includes online host-authoritative cooperative rooms for 2-16 players,
create/join/invitation links, all seven campaign chapters and the holiday chapter.
The snowy courtyard adds three waves/seven enemies and a tree to light.
Campaign v41 mechanics/terrain/story fixes are preserved. Native invitations use
https://smash.xedoc.ru/?room=CODE; browsers preserve their current page path.
Relay: wss://smash.xedoc.ru/coop, los-coop.service, loopback127.0.0.1:18791.

Validation:
- Final full suite77GUT/1121assertions, format/lint and Web export passed.
  Regression checks cover interleaved barrier strikes and faded-rig revival for both roles.
- Real two-instance normal-input co-op completed IV-VII:12kills/4relays each.
  Final terrain port replay58.82s; final barrier fix garden49.75s/roofs48.73s,
  both clients won. Original I-III and holiday were verified in the preview run.
- Public WSS host plus15scripted guests:16slots,119-124snapshots per guest over8.26s,
  every guest moved/attacked;0errors. Native renderer16frames/0errors.
  This is a connection/load check, not sixteen human players.
- Public release metadata, manifest and four served file hashes match. All8score
  endpoints return isolated chapter rows. Heavy PCK is immutable. Relay health ok.
- Score-file SHA256 before/after activation identical:
  833468eee8ac8ad200b112c32c0dbaea1877f0bb5c1ece20434396c9b1848f54.
- nginx, PHP and relay active. Only this task's redundant temporary archives were
  removed for disk space. Audited superseded v42 (our temporary buggy release) retired
  after v43 passed; healthy v41 rollback and all prior installed releases preserved.
  About420MiB free remains on the production disk.
- Public two-browser v43: create4/join-by-code/start chapter8, guest moved234->316px
  and kick serial2000001 reached host; both rigs visible, both consoles0errors.
  Host exit returned guest to lobby with the expected explanation,0errors.
- Public WSS two native clients completed the final holiday7kills/1relay19.10s.
  Final native capture17frames/0errors. Faded-rig revival and readable mirrored labels fixed.
- Copy button showed success; automated clipboard returned empty, so browser join was
  tested through the visible room code rather than claiming clipboard contents verified.

Evidence: .studioigor/captures/public-main-v43, coop-main-validation,
coop-main-sixteen and coop-main-holiday-v43.
Known limit: host departure closes the room; guests can join a new room.
Physical mobile and sixteen-human playtests remain open.
