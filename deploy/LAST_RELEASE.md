# Public release v29

- Domain: https://smash.xedoc.ru/
- Fresh load: https://smash.xedoc.ru/?cache=clear
- Runtime source: be6292e9acf6248db6f0773f308e959b17492112
- Gameplay source: 028950796f5a (packing-only cover preservation follows it).
- Current: /var/www/smash.xedoc.ru/releases/v29-be6292e9acf6
- Previous/rollback: /var/www/smash.xedoc.ru/releases/v28-374fd893bf59
- Archive:125,762,760bytes;18verified manifest files.
- SHA256:f8f8abe99c5b215a8c37f6a50fc28a7f74a3c0cd0ef0ae044ac3f10a394f54ba

Changes:
- G drops current weapon, E recovers it with exact magazine/reserve. Next attack with
  an empty pistol throws it for18damage, one hit, leaving a recoverable pickup.
- I instantly turns facing; held movement permits backpedalling until a new movement
  input. Settings > key controls edits18actions with conflict/cancel/reset and native
  ConfigFile/Web localStorage persistence. Prompts follow saved physical keys.
- Two-hand extended pistol/shouldered rifle pose with wrist IK, recoil/reload and front
  support arm layers. Enemy guns and heavy hammer use actual two-hand grip targets.
- Individual neck sockets for beaver, hare, Foreman, fox and lynx. Intact neutral hare
  trouser leg replaces the torn pre-bent painting. Source/prompt in art/campaign/hare-leg-v29.json.
- Social share cover preserved in every package; PHP realpath release config retained.

Validation:
-45GUT/620assertions; format/lint, clean Web export. Throw contact once, ammo conservation,
  paused discard rejection, held-move turn, key conflict/reserved Esc and default reset.
- Native tower full route32frames/0errors/completed12kills4relays. Enemy anatomy36frames,
  grip gallery26frames, Moose guns30frames; both facings visually reviewed.
- Local Web actual-key remap conflict/save/reload/turn; G/E keeps7/70, next empty attack
  throws/hits1, pickup1/fists; errors0. Capture driver strips InputMap, so native menu
  capture is flow/visual evidence only; actual persistence verified in browser.
- Public revision29 ready/muted, settings I/G; I turns1->-1, G/E keeps7/70. Seven shots
  away then next attack: throws1/thrown_hits1/hits_landed1/pickups1/fists,86HP.
  Screenshots and metrics: .studioigor/captures/public-v29. No score submitted.
- Cache update2hits/1download preserves engine; repeated3hits/0downloads/ready.
  Public I->U persists across reload; reset restores I. Enemy depot art/grips viewed;
  browser errors0 and QA tab closed.
- Installer verifies18hashes/archive; PHP syntax/nginx config pass, services active,
  HTTPS/release.json/cover200 and separate chapter2/3score tables confirmed.
- Score storage unchanged across activation:
  dc9e431264cb13335d4c349a4914d3725a30ad53b220ed7120d1595a508413ad.
- Physical phone and user art/feel acceptance remain open. Public browser checks first
  rooms; full tower route verified natively. Frozen v29 runtime archive stays immutable.
