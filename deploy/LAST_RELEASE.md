# Public release v38

- Domain:https://smash.xedoc.ru/
- Runtime source:541ed783a16a53c05ecdba46583e385497c8791d
- Current:/var/www/smash.xedoc.ru/releases/v38-541ed783a16a
- Rollback:/var/www/smash.xedoc.ru/releases/v37-a635d4febc0a
- Archive:93,548,116bytes;18verified files.
- SHA256:cad831e84732f85ae8c6fef42a3a1455b753f34e7838f19ecce90ba103bcc7ea

Foreman rear sleeve renders behind the vest; diagonal wrist skin weights prevent
the cuff folding into a hanging strip. Both hands grip the hammer at distinct
points and follow its front lift, strike and recovery.
Knuckle plates fit the visible knuckles on both actual fist sprites and follow
their transforms. Unequipping, dropping and death clear both plates. Damage,
knockback and the short six-pixel reach bonus are preserved.

Validation:
-51GUT/722assertions, format/lint, clean Web export.
- Native boss79frames/0errors, both facings/phases; support gap0.00019px.
  Knuckles41frames/0errors, five alternating near/far attacks; both facings viewed.
  Native ordinary-input depot route won58.68s/14kills/4relays/100HP/phases1,2;
  offline score service, no leaderboard entry.
- Public revision38: ordinary inputs cleared13enemies/3relays, used the freight
  lift/upper bridge and reached the boss. Knuckles ready right/left and two hits,
  boss lift/contact/recovery viewed; G restores fists and removes both plates.
  Console0errors,cache2hits/1download; QA tab closed before victory, no score sent.
- HTTPS/release.json200,18manifest hashes verified, PHP/nginx valid, services active.
  Scores unchanged during activation:
  229c259f574a2a440e83a07dcf46dd0f7538423ea20072c441b7808c19ff4994.
- Evidence:.studioigor/captures/foreman-final-v38,knuckles-final-v38,public-v38;
  .tools/depot-route-v38.log. User appearance/feel acceptance remains open.
