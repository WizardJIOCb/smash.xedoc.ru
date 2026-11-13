# Public release v22

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source: 9298c0247cb840679ed5f4f929f68caee39b265a
- Current: /var/www/smash.xedoc.ru/releases/v22-9298c0247cb8
- Previous: /var/www/smash.xedoc.ru/releases/v22-1c4e5f3da423
- Previous stable before this iteration: /var/www/smash.xedoc.ru/releases/v21-be8d1e30f05e
- Archive SHA256: bcf729372ab13017a519726eee57665832689e2e714c3bb0831a78b5c459b5db

Changes:
- Enemy soles use the same actor-floor+10px plane as Moose; anchored ankle IK,
  forward knees in both facings, and a foot weight in each continuous painted leg.
- Physical player/enemy deaths: native rigid bodies and pin joints, relative torsion
  limits, captured pose/fall velocity, local impact impulse and mirrored mesh binding.
  Antlers, shield and baton collide with terrain. Drone uses a rigid-body fall.
  Bodies remain10s then fade2s; R restores bone rest transforms before normal animation.
- Small hits9drops / lethal34, mist, ballistic gravity, swept terrain/ledge contact,
  secondary splashes and 12-18s stains with4s fade; drones leak dark oil. Bounded counts.
- Hold I for guard: incoming damage25% rounded up (boar18 becomes5), weaker knockback,
  movement28%, no sprint or attacks. Raised arms, block feedback, updated help/HUD.
- Previous fist tint, shoe layers, independent T day/night and Q ultimate, L impulse,
  silent first load, browser cache and real shared leaderboard retained.

Validation:
- 26/26 GUT,296 assertions; formatting/lint and final Web export without SCRIPT ERROR/ERROR.
- Native physics gallery: head impact, low trip and airborne Moose with inherited fall speed;
  settled native joint errors below0.01px in the stable gallery. Head/weapon contact shapes.
- defense-v22-final:62frames, zero errors/warnings;3blocked attacks ->85HP,
  death at25.35s,15-body player ragdoll, R restart and upright hips confirmed.
- route-v22-final:70frames, zero errors/warnings;5kills,3relays,100HP, actual upper
  ledge landing at13.5667s. Last baton-only collision addition also passes the physics tests.
- Public initial v22: revision22, scores online, sound muted.2blocked hits plus one
  unblocked boar hit ->72HP. Real player death and ragdoll observed; R restores play.
  Two lethal ultimate impulses ->1kill/1corpse,34droplets and36stains observed in Web.
- No public score submitted. Scores kept outside releases; deployment never replaces them.

Art/feel approval remains with user. Final Firewall and full map remain future work.

Final activation:15 manifest hashes verified, PHP syntax and nginx configuration passed;
nginx/PHP active. Score store SHA after activation:
7ff045dcdba210e3e586476c633888774b02e22ad2f68255803be233fc8669e7.
It changed during the session with live play; no test result was submitted and the installer
never writes the external score store. First v22 activation retained its exact baseline hash.

Final public9298c02: refreshed package download with engine cache hit2/download1,
then isolated repeat load hit3/download0. Normal keys Return/Shift+D/Q/L produced
1kill/1corpse,100HP,172ground stains; final baton contact checked in rendered Web.
No browser console errors. Proof: captures/public-v22/final-enemy-death.png
(full viewport) and final-enemy-death-canvas.png (letterbox crop retaining all game HUD).
Temporary QA tab closed; no result sent to the public leaderboard.
