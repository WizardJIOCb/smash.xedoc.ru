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
- Public v28: revision28, muted, chapter picker/depot bat/tower pistol verified visually.
  Seven real-key shots -> loaded0/hits7/kills2; F -> loaded7/reserve63; wave2 appears.
  Cache update2/1 then repeat3/0,100% ready; console errors0, QA tab closed.
- PHP symlink cache initially served prior handler; nginx SCRIPT_FILENAME changed to
  $realpath_root, nginx -t/reload passed. Live chapter1 keeps two legacy scores,
  chapter2/3 empty. No test score submitted. All18 release hashes verified, rollbackv27.

## PT-12 — 2026-11-14 — controls, weapons and enemy anatomy v29
- User: I turn (supersedes U), editable saved keys; G drop/E recover; next empty-pistol
  attack throws it; natural two-hand firearm grips for Moose/enemies; enemy heads/hare knees.
- 45GUT/620assertions, format/lint. Ammo conserved across drop/reload/recovery, one throw
  hit only, conflict/Esc rejection and manual turn survives held movement.
- Native tower route32frames/0errors/completed12kills4relays. Enemy anatomy36frames,
  weapon grips26frames, Moose firearm poses30frames; both facings reviewed.
- Local Web actual keys: I->U, conflicting J rejected, U persists across reload and
  turns facing1->-1. Reset restores I. G/E keeps7loaded/70reserve; seven shots away,
  next attack throws1/hits1, leaves1pickup/fists. Console errors0. No leaderboard row.
- Capture driver deliberately strips InputMap; native menu capture is visual/flow only,
  not remap persistence evidence. Browser above supplies real-key/save evidence.
- Hare leg original edit source/prompt retained in art/campaign/hare-leg-v29.json.
  Native artist/feel gates remain open; physical phone untested.
- Public v29: I facing1->-1; G/E keeps7/70; shots7 then throw1/hit1/pickup1,86HP.
  I->U persists across reload; reset I restored. Cache2/1->3/0,errors0,QA tab closed.
  New enemy grips/neck/legs seen in depot/tower.18manifest hashes,rollbackv28,scores
  unchanged during activation; no public score submitted.

## PT-13 — 2026-11-14 — all empty firearms throw; enemy weapon scale v30
- Removed pistol-only restriction. Throw happens on a new attack press; holding automatic
  fire stops at an empty magazine. F still reloads before discard. Exact reserve survives.
- Enemy gun sizes: fox88x34,lynx102x38,Firewall110x40; melee props moderately enlarged.
  Support hand targets adjusted to each fore-end. Both facing directions reviewed.
-45GUT/636assertions cover every ranged weapon, hold-versus-new-press, one throw contact,
  exact ammo/recovery/reload. Rifle native range20frames/0errors:24shots/24hits, then
  new press throws1/hits1,25contacts total,rifle removed/1pickup. Enemy gallery18/0errors.
- Public v30: normal inputs clear entry4kills/1relay, pick rifle in cooling. HoldJ24
  rounds -> rifle0/24/reserve120/throws0; next press -> throws1/hit1/pickup1/fists,76HP.
  Enlarged enemy guns viewed; errors0,QA tab closed. Cache2/1,18hashes,rollbackv29,
  scores unchanged during activation; no score submitted.

- 2026-11-14 v31: bat112px/two-hand handle, wind/sweep/follow/recover with standing/low/air timing; damage only sweep. Fox54x28 pistol + cup grip, lynx120x58 rifle + fore-end support; actual muzzle sockets. 46GUT/648, Web export clean. Native bat gallery63frames + range48frames/3contacts, enemy grips18frames, errors0; reviewed both facings. User feel approval remains open.
- v31 уточнение пользователя до публикации: замах именно назад за корпус, затем вперёд. Wind grip(-38,-37), bat angle-3rad, longer anticipation0.30s and fast forward0.12s; native56frames/0errors, viewed full backswing and impact in both directions.46GUT/648 repeated, final Web rebuilt.
- v31 опубликована3bde584: финальный замах назад за корпус проверен публично,4punches/6hits/1kill/100HP; fox/lynx grips viewed, revision31/muted/scores online, errors0. Cache2hits/1download,18hashes,rollbackv30; scores preserved. Resource pack excludes build/,32.2MB vs55.9MB. QA tab closed; no score submitted.

- 2026-11-14 v32: bat wrists face across handle and clamp at0.7rad; support hand anchors to actual handle, rear windup retained. Enemy arm skin now weights wrist bone; tool grip follows weapon with0.8rad wrist cap. Hare/beaver windups avoid shoulder singularity, foreman keeps reachable two-hand grip. Bat32frames (standing/low/air/both facings), enemies18frames,0errors; images reviewed.46GUT/648 and Web export pass. Appearance acceptance remains with user.
- v32 public85a4574: bat2punches/2hits/100HP, grips viewed in actual chapter2 combat; revision32/muted/scores online/errors0/cache2hit1download.18hashes,rollbackv31,scores preserved; QA tab closed. User appearance/feel acceptance still open.

- 2026-11-14 v33: rifle support palm moved under actual fore-end and projected with shared recoil/reload angle; 90-frame automatic burst contact regression in each facing. Enemy arm/weapon/fingers separate draw layers; free hand guards, trunk follows strike, gun support tracks recoil. Tool blows land on forward swing, hare rearms second beat and returns without snap.47GUT/656, clean Web; gun gallery76frames, actual AI96frames + final melee78frames,0errors, viewed. User art/feel approval open.
- v33 published3550764: public enemy4hits/3blocks/66HP, normal tower route4kills/relay1 then rifle12round burst/12loaded/5kills/100HP, grip and layers viewed; revision33/errors0/cache2hit1download.47GUT/656,18hashes,rollbackv32,scores unchanged. QA tab closed; no fake score. Final tools split shaft/head/grip layers reviewed32frames0errors.

- 2026-11-14 v34: distinct anatomical bat hands generated after user rejected duplicate palms; native RGBA preserved. Wrapped hand/weapon assemblies, exact two wrist anchors, original fists hidden only while equipped. Beaver/hare integrated grips and diagonal sleeve cutoff, front ready pose.48GUT/672; standing/low/air both facings worst gap0.0002px; drop/death hand restoration regression. Final bat63frames, native contacts96frames/3contacts, actual enemy AI96 plus cuff32frames,0errors; relevant phases reviewed.390frame/60FPS motion clip exported and decoded.
- v34 published11abd8f: public3bat attacks/4hits/100HP, enemy5hits/3blocks/70HP; Tab/G restores fists and leaves1plain pickup, console0errors/cache2hit1download.18hashes,rollbackv33,scores preserved,QA tab closed,no score submitted. Distinct-hand asset correction implemented; user appearance/feel acceptance stays open.

- 2026-11-14 v35: user rejected v34 bat hold/swing and requested real references. Viewed Little League grip photo and batting photo sequence; Texas Rangers/MLB and Baseball Canada mechanics read. Three comparison rounds: low hands, folded elbows, weak drive. New palm-down/palm-up wrist art; shoulder ready/load, weight shift, knob-led drive, level contact, wrap/finish/return. Barrel projects in depth without shrinking hands; shared two-arm reach geometry prevents gaps/folding.48GUT/674, clean Web; final63frames/0errors/gap0.00019px/elbow133.70deg; native range96frames/3contacts,390frame60FPS clip decoded. User appearance/feel acceptance remains open.
- v35 published6b1e92c: public6swings/7hits/2kills/100HP; right/left frames, Tab/G hand restoration and plain pickup reviewed; console0/cache2hits1download.18hashes,rollbackv34,scores preserved; QA/ref tabs closed,no leaderboard submission.

- 2026-11-14 v36 published b53e6fd: shortest-angle return and continuous buffered swing; rear-diagonal ready, separate barrel/head layers. Wrist fur skinned toward forearms, cuff centered; fixed torso shoulders and rear upper-arm layer.49GUT/700, clean Web; final126chain/15attachment/23firearm frames,0errors, gap0.00019px/shoulder drift0px;390frame60FPS clip decoded. Public6swings7hits2kills100HP, both facings and Tab/G hand restoration/plain pickup viewed;console0/cache2hit1download/FPS171-180.18hashes,rollbackv35,scores preserved,QA tab closed,no score submitted. User art/feel acceptance remains open.
