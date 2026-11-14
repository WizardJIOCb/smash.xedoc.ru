# «Лось: район закрыт» — cooperative relay

Node.js 22+ and `ws`. The host runs the existing game simulation; the relay
isolates rooms and forwards inputs and snapshots. It does not validate gameplay,
persist campaigns, migrate the host or claim protection against a cheating host.

## Run

```sh
cd server/coop
npm ci --ignore-scripts
npm test
npm start
```

Defaults: `127.0.0.1:8791`, WebSocket `/coop`, HTTP `GET /health`.
Environment: `HOST`, `PORT`, `COOP_ORIGINS` (comma-separated exact origins,
default `https://smash.xedoc.ru`). HTTP(S) localhost origins are also accepted.
Clients without Origin are accepted for native Godot; Origin is a browser guard,
not authentication. Room codes are random six-character invitation codes.

Production: install dependencies in `/opt/los-firewall/server/coop`, adapt
`deploy/coop/los-coop.service` for the installed Node path and service user,
include `deploy/coop/nginx-location.conf` in the existing HTTPS vhost and perform
`nginx -t` before reload. Browser connects to `wss://smash.xedoc.ru/coop`.
Templates do not alter or deploy the current site automatically. Rooms are
in memory and disappear on service restart.

## Protocol

Each frame is text JSON. Names: 1–24 characters, build: 1–80 ASCII
letters/digits/dot/dash/underscore, IDs: strings (`"1"`, `"2"`, ...).
Build IDs must match exactly, including for late joiners.

| Client message | Effect |
| --- | --- |
| `{type:"create",name,capacity:2..16,build}` | Create a room; creator is host and first player. |
| `{type:"join",room:code,name,build}` | Join a room, including one already playing. |
| `{type:"start",chapter:0..255}` | Host only; minimum two players; start campaign chapter. |
| `{type:"chapter",chapter:0..255}` | Host only; load another chapter and discard cached previous snapshot. |
| `{type:"input",held:{action:bool},pressed:[action],seq:int}` | Guest only; host receives input with server-assigned `id`. Sequence increases within a chapter. |
| `{type:"snapshot",state:object}` | Host only; forward to guests and cache latest snapshot for late join. |
| `{type:"leave"}` | Leave room without closing socket; receives `{type:"left"}`. |

All members receive `{type:"room",you:own_id,room:{code,capacity,host,players:[{id,name}],started,chapter}}`
after membership changes. Start/chapter broadcasts `{type:"start",chapter}`
before the updated room frame. A late join receives room then latest snapshot;
the client loads `room.chapter` when `room.started` is true. A host departure
removes the room and sends `{type:"closed",reason}` to remaining peers, which
can create/join another room on the same connection. Other errors are
`{type:"error",message}` in Russian.

Frame caps: snapshot 256 KiB, input 4 KiB, control 2 KiB (entire JSON frame).
Snapshots max 40/s, guest inputs max 120/s, controls max 8/s, all frames max
180/s per socket. WebSocket compression is disabled. A slow socket with more
than 1 MiB queued is disconnected. Ping runs every 15 s; missing the next pong
disconnects a stale peer. Global limits: 2048 sockets and 512 rooms. Limits are
modest abuse safeguards, not an authenticated public matchmaking service.
