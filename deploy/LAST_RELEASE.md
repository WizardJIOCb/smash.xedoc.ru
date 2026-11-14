# Public release v40

- Domain:https://smash.xedoc.ru/
- Runtime source:d73e2117475bb2834480f6f862848b6335f18bb4
- Current:/var/www/smash.xedoc.ru/releases/v40-d73e2117475b
- Rollback:/var/www/smash.xedoc.ru/releases/v39-0467d8267168
- Archive:93,547,752bytes;18verified files.
- SHA256:af69b68b526478c2ae4e84827f8721a11422e45ba0fca10639d4e866888c6bd9

Bat load pulls the hands farther back; early drive stays behind the shoulder
before accelerating into contact with the weight transfer. Recovery withdraws
the hands before raising the barrel behind the head. Distinct palms, wrist/shoulder
attachments, attack timing and active damage interval are preserved.

Validation:
-51GUT/734assertions, format/lint, clean Web export. Regression samples the return
  at240Hz to catch the brief upright phase in all stances and both facings.
- Native126frames/0errors, queued swings in both facings/standing/low/air reviewed;
  grip gap0.00019px, shoulder drift0px, maxelbow133.70deg. Native contact48frames,
  three hits/0errors; 3.2s motion clip encoded and decoded.
- Public revision40: left/right load, hit and recovery viewed;7swings/7hits/2kills/
  100HP. G restores fists/one plain bat pickup. Console0errors,cache2hits/1download;
  QA tab closed before victory, no score sent.
- HTTPS/release.json200,18manifest hashes verified, PHP/nginx valid, services active.
  Scores unchanged during activation:
  d6f928b45f98499c442a69bf5f6fd36486e0d7e2e9a15d10a29e7ae0997897d6.
- Evidence:.studioigor/captures/bat-return-final-v40,bat-contact-final-v40,public-v40.
  User appearance/feel acceptance remains open.
