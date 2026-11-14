# Cooperative campaign — 2026-11-15

- https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html
- https://docs.godotengine.org/en/stable/classes/class_websocketpeer.html
- WebSocketPeer works in native and Web exports; poll every frame and check connection state.
- Browser requires secure same-origin WSS in production; no direct browser TCP/UDP listener.
- A small relay forwards guest inputs to host; host exclusively simulates enemies, damage,
  pickups, relays, lifts and room/chapter progress. Guests render authoritative snapshots.
- Room capacity is selectable 2–16. Same campaign build required; late joining gets latest state.
- Host departure closes room explicitly. No host migration in this version.
- Shared stages require living teammates at the exit; individual downed players return after
  a short recovery if somebody survives. Whole-team defeat uses the existing checkpoint.
- Keep cooperative runs out of the existing solo shared score table.
