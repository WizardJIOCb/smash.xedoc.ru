# Public release v36

- Domain:https://smash.xedoc.ru/
- Runtime source:b53e6fd56b4dc317fbfe9d60a42c5c14f55b1765
- Current:/var/www/smash.xedoc.ru/releases/v36-b53e6fd56b4d
- Rollback:/var/www/smash.xedoc.ru/releases/v35-6b1e92c7a56e
- Archive:93,540,779bytes;18verified files.
- SHA256:ede11aa5d91be348767afd835d3f0697de241e816e100fc7202ff4d8a0d8b91d

Changes:
- Bat recovery follows the shortest angular path; buffered follow-up starts from the
  displayed pose. Ready stance uses open elbows and a rear diagonal barrel.
- Barrel passes behind the head in ready/load/finish; hands retain their front layer.
- Furry wrist ends flex toward actual forearms while fingers remain on the handle.
  Far cuff anchor centered; both shoulders stay fixed to the torso throughout swings.
- Far upper arm stays behind the chest; forearm and hands retain their front layers.
  Grip skin is created only for an equipped bat, without adding skeletons to pickups.

Validation:
-49GUT/700assertions, format/lint and clean Web export. Regression covers recovery
  direction, buffered continuity, shoulder attachment, wrists, drop/death and gun recoil.
- Final native126chain frames/0errors, worst wrist gap0.00019px at2.1scale,
  maxelbow133.70deg. Attachment15frames shows shoulder drift0px. Firearms23frames/0errors.
  Final390frame/60FPS,6.5s motion clip decoded without errors.
- Public revision36:6swings/7hits/2kills/100HP. Right/left swing and ready frames viewed;
  Tab/G restores fists and leaves1plain bat pickup. Console0errors,cache2hits/1download;
  FPS171-180 during the bounded combat check. QA tab closed; no leaderboard submission.
- HTTPS/release.json and scores API200;18manifest hashes verified, PHP/nginx valid,
  nginx/php8.3-fpm active. Scores unchanged during activation:
  63649ebb1e88b410a541dd8c6d848f3e3aeb63856f9ef68d1ead70ccf031a2d6.
- Evidence:.studioigor/captures/public-v36,bat-final-v36,bat-attachment-v36,
  firearm-final-v36,bat-motion-final-v36.mp4. User appearance/feel acceptance stays open.
