# Public release v48

- URL: https://smash.xedoc.ru/
- Runtime source: 6a252cf841e5e9341ce8aedb2a842dadc98624f0
- Current: /var/www/smash.xedoc.ru/releases/v48-6a252cf841e5
- Immediate rollback: /var/www/smash.xedoc.ru/releases/v47-0d4fe28f7dd9.
- Previous feature release v46-af4145468513 and older rollback releases retained.
- Archive: 153011052 bytes; SHA256 45d22e3d26fe2a9dd5ad5c6280f7fcdac65f1632a1792a9c0034c00e71c86fe1.
- Installer verified all 21 manifest files and both PHP endpoints before activation.
- PCK: game-d5bda545eece655ab9b6.pck.

Endless survival has its own home-menu entry, solo and 2-16-player cooperative
starts, escalating waves, every-fifth-wave bosses, short rests, health and weapons.
Downed teammates wait for a wave clear; a total wipe ends the run. Results use
separate solo/team boards and separate storage from all eight campaign chapters.
Only the host submits a team result. The scoreboard shows fixed starting party
size and ranks wave descending, kills descending, time ascending.

Metrika counter 114255834 is live with supplied initialization options. Safe game
parameters and 36 event identifiers cover loading, campaign, cooperative rooms,
combat, performance and survival. Invitation codes are extracted and removed
before loading the SDK; player names, room codes and raw errors are excluded.
Blocking analytics does not block the game. Dashboard JavaScript goals require
manual creation in the counter cabinet; instructions are in deploy/METRIKA.md.
No dashboard goal creation is claimed.

Validation:
- 91 GUT tests /1365 assertions; seven analytics checks; isolated PHP survival
  integration (isolation, ranking, token binding/replay/expiry, rate, validation)
  pass. Format/lint and final Web export pass. v48 only fixes numeric display and
  neutral party-size wording after the v47 full gameplay test run.
- Normal-input native solo and two-instance relay runs reached wave3, then
  intentionally stopped fighting to verify defeat. Co-op matched wave3/7kills/
  69.87s. Host exited cleanly; the original guest review driver required stopping
  after the host closed; driver shutdown timing was subsequently corrected.
- Public v47: genuine solo defeat wave1/0kills/18.12s saved and displayed in solo
  board. Two IAB clients through public WSS showed the same authoritative loss
  wave4/11kills/71.70s; host saved, guest submission/retry disabled; team row
  displayed separately with two players. Both browser consoles had zero errors.
  Browser combat inputs were not a controlled benchmark; native review inputs
  provide the controlled wave-clear evidence.
- Public v48: both persisted rows render whole wave/kill numbers correctly;
  board switching and party count verified. Another genuine solo defeat loaded
  cleanly; survival_start, survival_wave_start, survival_end plus related events
  returned HTTP200 from the actual Metrika watch endpoint. Safe event proof
  contains no QA player names or room code. SDK initialized, revision48 confirmed.
- Public PCK, index and analytics SHA256 match manifest. All eight campaign score
  endpoints and both survival endpoints return200. Coop health:0rooms/0clients
  after QA. Only the two exact QA rows were removed under a storage lock, with
  their row-only recovery copy saved outside the web root; both boards rechecked.
- Campaign score SHA256 stayed identical during each activation. Final activation:
  9c86b1770fab6c33628f94aba06ccb9a5cc661f6a5373f208ef48bf5f987b991.
  nginx config test passes; nginx, PHP8.3-FPM and relay active. Existing relay
  process and routes preserved; room255 uses the existing accepted chapter range.
- Task upload archives/helpers removed from /dev/shm after verified installation.
  Installed releases and campaign player data preserved.

Evidence in the implementation worktree los-firewall-coop:
.studioigor/captures/public-metrika-v46, public-survival-v47, public-survival-v48;
.tools/tests-survival-release.log and native survival review JSON/log files.
Physical-mobile, sixteen-human, overall art/feel and balance acceptance remain open.
