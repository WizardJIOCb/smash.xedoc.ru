# Playtests

One session — one section. The user's feedback — verbatim. The first question is always "is it fun?".

## PT-01 — 2026-11-13 — first rig look-dev
- Build: 72bc709; local Web, accepted original painted moose and courtyard.
- User: "Доводим плавность и вес анимации (рекомендую)".
- Correction: "на куртке уже есть рукава и у нас есть ещё руки, получается как будто 4 руки"; screenshot supplied.
- Actions: edited torso artwork to remove baked sleeves; rechecked both directions. Added native weighted torso mesh, displacement-driven foot support, spring follow-through, 67 ms jump anticipation and landing absorption; motion parameters in data/rig_motion.json. Z allows close inspection.
- Self-check v2: TEST 4/4; close-up capture 68 frames / zero engine errors. Web reports revision=2, bones=15, mesh_vertices=35, jumps=1, landings=1 after real keyboard input.
- Art quality and fun verdict: awaiting user; no phase completion claimed.

## PT-02 — 2026-11-13 — rig v2 correction
- User: "Перепутаны z-index для рук как будто и кулак к руке прикреплён не тем углом, в горле куртки можно нарисовать шерсть и шею ото там пусто сейчас, жопа тоже странно смотрится ))".
- Follow-up: "и глаза на лице должны вперёд смотреть, эти глаза тоже можно оставить, чтобы он изредка как будто бы в камеру смотрел потому что текущие глаза смотрят в камеру а не вперёд".
- Actions: near shoulder moved to foreground side of jacket, far shoulder to front/back plane; explicit layer constants. Fist pivots moved from fingers to wrist and aligned to cuff axis. Slimmer pelvis overlays leg roots, below jacket. Added neck bridge plus painted fur inside opaque collar cavity.
- Gaze: generated forward eye donors composited only within the original eye areas, retaining exact head/antlers. Default forward; brief idle camera glance; active motion cancels it.
- User art approval remains open.
- Self-check: 79 current main-scene frames and 12 isolated idle-gaze frames, zero engine errors in both captures; 4/4 tests. Idle review recorded one camera_glance and returned to forward gaze. Live Web shows revision=3, forward gaze during movement/attack, glance counter advances during idle.

## PT-03 — 2026-11-13 — rig v3 correction
- User: near fist needs dorsal artwork; static pelvis/thigh connection and stripe discontinuity are visible; leg perspective/layers disagree on turns; near arm falls behind head. Follow-up: neck colour does not match head at seam.
- V4 actions: separate dorsal near fist; near arm above head; near hip aligned with near shoulder; 2 continuous skinned pant legs replace pelvis/thigh/shin stack, continuous stripes and shared hips root. Neck bridge cropped from actual head fur, collar fur matched to that palette.
- Validation: 6/6 tests including actual rig render priority in both directions and resolved normalized leg skin weights. Native 52 frames, zero engine errors; Web revision4/trouser_meshes2 checked with real keys.
- Visual approval remains open.

<!--
## PT-01 — 2026-09-28 — M01 Drift (gym)
- build: <commit> · run: `<command>`
- what we tried: …
- is it fun? … · feedback (verbatim): …
- conclusions → actions: …
-->
# PT-04 — 2026-11-13 — rig v5 surfaces and joints
- User: far inner arm/leg should have no stripes; near fist looks small/inverted. Follow-ups: far trouser cuff lost behind shoe; near elbow opens a transparent gap.
- Actions: separate inner cloth textures, compact dorsal fist remounted and enlarged, near elbow cloth overlap, far cuff over its own shoe and extended 3 units.
- Validation: 6/6 tests; native capture 52 frames, error_count=0; actual Web revision5 with movement and two punches in opposite directions. Browser screenshot `captures/browser-v5.png`, review board `boards/lookdev-r5`.
- User visual acceptance remains open.

## PT-05 — 2026-11-13 — combat animation iteration
- User: alternating hand series; kicks/air attacks; continuous elbow stripes; near foot behind in guard; crouch movement and attacks; inertia to end of walk; varied kick combos with whole-body high-kick motion; backpedal during punches; Shift run; swap arm counterbalances when the kicking leg changes.
- Implemented in attack_gym: buffered input, separate attack/pose modules, continuous near sleeve, three kick profiles and alternating legs across cycles, crouch, walk/run, backward swing direction and analytical stride stop. High kick transfers hips and leans torso from chamber; arms follow side of kicking leg.
- Checks: 13/13 pure motion/sequence/rig tests. Earlier native combat-v9/v10: 147 frames each, zero engine errors. Live v9 browser proved four alternating punches, air/low attacks, backpedalling and planned stopping distance (105.2644 planned/actual); current v11 final review recorded separately in captures/combos-v11.
- Awaiting user feedback on feel; full combat damage/enemies and phase5 visual acceptance remain open.
- Final follow-ups: rear airborne shoe gets a distinct toe angle; high kick v13 drives hips further toward support and torso farther back before extension. Native high-kick-v13: 94 frames, zero errors; combos-v12: 100 frames, zero errors. Web v11 accepted 6 live taps as kick1:near / kick2:far / kick3:near / kick1:far / kick2:near / kick3:far. Final browser revision13 verified separately.


## PT-06 — 2026-11-14 — physical deaths and guard v22
- User: align enemy boots with Moose; physical skeletal deaths responding to hit location,
  direction and height, blood mist/droplets/splashes and fading stains. Add a block key near attacks.
- I holds a raised guard: damage25% rounded up, slow walk, no sprint/attacks;3guarded boar
  hits leave85HP. Blood is smaller on ordinary hits, stronger on lethal; drones leak dark oil.
- Native26tests/296assertions. Final route70frames,5kills/3relays/upper ledge/100HP,
  no errors. Defense62frames: death25.35s,15physical bones, R restart restores upright hips.
- Stable physics gallery distinguishes head hit, trip and inherited airborne fall; anatomy,
  ground/ledge contacts, reflected skin, antlers and held weapons retain the painting.
- Public v22 observed: guard reduces damage, player death uses physics; R returns control;
  fatal impulse creates1corpse and34droplets with ground stains. Shared records remain online.
- User art/feel approval remains open. Release https://smash.xedoc.ru/; cache reset via ?cache=clear.

## PT-07 — 2026-11-14 — falls, performance, touch v24
- User: L block/O impulse; bodies fold into themselves; THIRD-room ground; blood forms
  a line; unobtrusive FPS with Settings toggle; ragdolls cause slowdown; mobile stick and
  action buttons, then replace overflowing labels with icons/smaller captions.
- Compound core preserves trunk/neck length, native articulated limbs and local hit torque;
  quiet corpses freeze/detach solver joints, avoid cross-corpse collision piles. Native
  benchmark resting p95 16.69->5.925ms, active parts47->0 after settling (machine-specific).
- Blood randomized depth and lobed wet pools below actors, cached static drawing. Third
  floor545->529 with enemy spawn/terrain/FX. Other rooms unchanged.
- 27GUT/350assertions; route70frames/zeroerrors/5kills/3relays/100HP; gate-ground4frames;
  ragdoll32frames distinguishes high strike, trip and airborne Moose. Core intentionally stiff.
- Native raw ScreenTouch route32frames: punch near/far,1air kick/1crouch kick,1jump,
  T world/Q ultimate/O impulse and touch pause. Independent stick/action fingers. Default
  desktop has no overlay; small FPS and Settings page checked in local Web. Physical phone
  browser and final public activation remain to be checked/reported separately.
- User feel/art approval stays open; final Firewall/full map remain future work.

- Public v24 final: FPS off persists after reload (cache hit3/download0), then restored on;
  L guard/Q+O twice ->1kill/100HP/172stains; settled corpse has0active physical parts.
  Mobile915x412 emulation auto-enables controls and fits all icon buttons. Console errors0.
  Screenshots public-v24/mobile-icons.png; physical phone still unverified. All15release
  hashes passed, records SHA unchanged during activation, previous v23 retained. Git source01ad83f.

## PT-08 — 2026-11-14 — blood rendering and kick toes v25
- User: FPS still drops immediately when blood appears; kick toes look rigid/straight on both legs.
- Isolated benchmark finds136marks generate816calls,220marks1320. Three MultiMesh batches
  replace individual primitives; ground marks now1call at either count, same9/34primary drops,
  secondary splashes/depth/fade. Cached masks built on load. Empty effects stop physics;
  clearing a room removes every GPU instance. Native burst-frame p95 8.530->4.448ms
  under240FPS cap, not an uncapped or phone FPS claim. Numerical report in research.
- Kick ankle dorsiflexion ramps during extension and eases out in recovery, for either active
  side: high0.36rad extra, normal/air0.22, crouch0.12. Existing rear airborne foot retained.
-27GUT/358assertions; blood28frame gallery/zeroerrors; six-kick visual review includes both
  high-kick legs. Public activation and full route recorded after export below.
- User art/feel gate stays open.

## PT-09 — 2026-11-14 — grounded menu, loading and rain v26
- Original generated courtyard with broad paving and live foot contact shadows. Source/prompt retained.
- Branded loader uses actual rig portrait; real byte0-90%, engine startup100%. Local repeat hit3/download0,
  cache=clear download3. Desktop/portrait inspected; physical phone untested. Default Godot splash disabled.
- Rain2pooled batches: uppermost road/ledge, random depth, ballistic droplets and fading rings.
- Landing spray floor_y+8:48nativeframes/0errors, room3 and upper ledge415/spray423.
- Full route70frames/0errors,5kills/3relays;27GUT/358assertions pass. User taste gates remain open.
- Public v26: new menu and branded loading seen; cache update hit2/download1, clear link hit0/download3
  reaches100/ready. Real-key battle1kill/172marks/100HP, later180FPS/88calls (includes corpse,
  not isolated benchmark). Console errors0; external records unchanged during activation.

## PT-10 — 2026-11-14 — ragdoll anatomy, wake and restart v27
- User requests: less folding/backwards knees and feet; antlers no longer prop Moose up.
  Keep facing after boar knockback; remove blink/grace; fix lying R revival; hit dead bodies.
-29GUT/390assertions: successive same-frame damage, facing, deferred corpse/R reset,
  mirrored natural knee/ankle bend, corpse hit dedup/no repeat kill, wake/air hit/resettle.
- Native mirrored road/air anatomy32frames reviewed; defense42frames/0errors,3blocks85HP,
  death and R restore upright hips/100HP. Full route35frames/0errors,5kills3relays/completed.
- Corpse input review36frames: normal inputs kill boar, wait for rest, crouch-kick actual
  moving physical shape; source metrics and screenshot reviewed before packaging.
- Semi-rigid legs trade independent knee motion for reliable anatomy; user taste gate open.
- Public v27: revision27, real-key4hits kill/1corpse; two crouch-kick corpse contacts, kills stay1.
  Cache update2hits/1download, scores online, muted. No leaderboard submission.
- Public death then R verified visually:100HP/upright/player_ragdoll=false; console errors0.

## PT-11 — 2026-11-14 — two continuation chapters v28
- User explicitly approved depot4levels/tower4levels, then added ending bosses.
- Native original first route35frames/0errors/completed5kills3relays100HP.
- Each continuation46frames/0errors/completed: depot14kills4relays,Foreman phases1/2;
  tower12kills4relays,Firewall phases1/2/3. Reviewed both full sheets and boss frames.
- Module reviews found/fixed endpoint-only long weapons, swap-active-frame reach exploit,
  double ult weapon scale, rifle during O, muzzle alignment, sheet-part contamination,
  lift return-call softlock and chapter-preview TextureRect intrinsic sizing.
-42GUT/589assertions, normal-input menu20frames selects tower/picks pistol/shoots7/reloads7,
  reserve70->63. Real PHP API isolated tests pass all3chapter contracts,legacy preservation,
  tokenchapter binding/replay and tables. No public record submitted.
- Source art/prompts retained; runtime8WebP backdrops+6skeletal enemy sets+painted weapons.
  Artist/feel gates remain open. Physical mobile hardware untested.
