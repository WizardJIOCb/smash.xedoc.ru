# Continuations v28 — 2026-11-14
User approved two four-level chapters (depot, tower) and asked for ending bosses.
Sources: https://docs.godotengine.org/en/stable/classes/class_animatablebody2d.html
https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html
- Keep existing fixed-timestep custom feet controller; native AnimatableBody2D supports
  physical bodies, while explicit delta carry moves grounded custom-controller feet.
- One-way deck, upper exit bridge, E ride/call back from either landing, jump release.
- Content data: chapter boundaries + reinforcement waves; old first route ends as before.
- Each chapter ends with record/next screen. Direct chapter selection for immediate access.
  Completed chapter badges saved locally. Gear carries through Next, checkpoint restores ammo.
- Armory composition: J melee/gun, K stays kick, E pickup, Tab cycle, F reload (R restart).
  Pistol7/rifle24, finite reserves, swept nearest target/terrain/corpse projectile contact.
  Melee includes full shaft; switching cancels current swing; held gun blocked during O.
- Four new ordinary archetypes: beaver heavy tool/hare double strike/fox aimed shot/lynx burst.
  Foreman300HP/two phases; Firewall450HP/three phases, readable windup/recovery and ground pulse.
-15original image_gen assets:8backgrounds,6RGBA paperdoll sheets,1weapon sheet. Masters/prompts
  in art/campaign. Runtime backgrounds1280x720WebP; soft RGBA parts trimmed by connected alpha
  components so neighboring sheet cells cannot contaminate legs. Source masters unchanged.
- Same native skeleton/ragdoll/pooled blood; corpses do not create score/charge exploits.
- Leaderboards separate by chapter; legacy rows defaultchapter1. Tokens bind chapter, exact
  expected kills/relays checked. Real PHP handler exercised in disposable storage only.
- Native full normal-input chapter routes: chapter1 5kills/3relays, chapter2 14/4, chapter3 12/4;
  both bosses' phases observed. No fake HP/enemy edits in route driver. All complete/0errors.
- Mobile adds cycle/reload icons; physical phone still untested. Art/feel taste remains user gate.

## Lift landing correction v39 — 2026-11-14
- Rect2 end is position + size (official Rect2 documentation above); depot/tower
  deck ends at790, bridge started810 at the same350 height: a real20px gap.
- Extend the shared art/feet/physical ledge rect to786..1210, overlapping the deck
  by4px. No controller tolerance or invisible floor; the lower lift stays open.
- Campaign driver walks off without jump input and records jump delta/max drop.
