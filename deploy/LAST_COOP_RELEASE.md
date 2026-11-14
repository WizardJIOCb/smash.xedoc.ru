Main promotion: v43 is now live at https://smash.xedoc.ru/; see LAST_RELEASE.md.
The isolated v40 preview described below is retained as historical/rollback evidence.

# Cooperative preview — 2026-11-15

- URL: https://smash.xedoc.ru/coop-game/
- Source: 4292eaf31ad2d4726a819eb15195c4b7e1c7ef82 on codex/network-coop.
- Active: /var/www/smash.xedoc.ru/coop-releases/v40-4292eaf31ad2
- Previous: /var/www/smash.xedoc.ru/coop-releases/v40-562fef75da1f
- Archive SHA256: 9104761ff226b3518ac8642ec6c1a1d81da03daccf50b382f501fadd0eac710d
- 19 manifest files verified. Main current remains independently managed by the campaign chat.
- Relay: los-coop.service, /opt/los-firewall-coop-relay, 127.0.0.1:18791, WSS /coop.
- Nginx includes /etc/nginx/snippets/smash-coop.conf; future main deploys need to retain that include.
- Rooms2–16, host-owned simulation, invitation URLs, late join, individual recovery6s,
  whole-party defeat/checkpoint, shared exits and chapter changes. Host departure ends room.
- New Year level: chapter8 / room28, painted winter background, snow/garlands, three
  groups / seven existing enemies, tree relay. Solo and cooperative modes supported.

Validation:
- 68 GUT tests /1069 assertions; final authority subset3/3. Format/lint and Web export passed.
- Relay6/6, including16slots/full rejection, host-only snapshots, late join, disconnect.
- Two real native game instances, ordinary input: first chapter5kills/3relays and
  winter level7kills/1relay both completed on both instances.
- Continuation regression: both instances won depot14kills/4relays/50.93s and
  tower12kills/4relays/43.78s. No errors in either process; lifts/shared exits traversed.
- Real rendered host with15WebSocket clients: each guest received133+snapshots/8seconds,
  all moved/attacked; capture13frames/0errors. This is a controlled load test, not16humans.
- Public two-browser WSS create/join/start winter level, guest attack serial observed
  at host. GET release/health/chapter8scores200, unknown API script404.
- Final public source4292eaf: nativeWSS host + browser guest, guest x234→332.09 and
  kick serial2000001 observed; winter host won7kills/1relay, browser correctly returned
  to lobby on host exit with0console errors. Public relay empty after QA cleanup.
- Added the same Nginx include to the main checkout's otherwise unchanged deployment
  template so its upcoming campaign release retains the isolated preview routes.
- Evidence: .studioigor/captures/coop-validation, coop-sixteen, holiday-coop.

The concurrent new campaign chapters were merged as source data; their full cooperative
routes and the additional chapter-specific mechanics have not been playtested here.
The tested public deliverable is this isolated cooperative preview, not the main release.
