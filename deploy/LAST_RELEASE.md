# Public release v16

- Domain: https://smash.xedoc.ru/
- Runtime source commit: a1e602446684fe7139a85a07fdcd28dfe09d2bf7
- Current: /var/www/smash.xedoc.ru/releases/v16-a1e602446684
- Previous rollback: /var/www/smash.xedoc.ru/releases/v15-e0a189152f80
- Archive SHA256: 609a4077c2a5cad71f8159190147449a3cbb2e72f3a1c8b5d9a0e011a3835e6e
- 12 files verified against the frozen manifest before atomic activation.
- GitHub main pushed; subsequent documentation-only commits do not change the runtime artifact.

Verified: public HTTPS and HTTP redirect; current release.json; actual browser revision16/menu/home; shared score fetch and score screen; no browser errors in the initial production smoke test. The public leaderboard already contains player-submitted WizardJIOCb results; no synthetic record was posted to it. PHP API validation/submission/replay/rate-limit checks ran in a separate temporary store (10 checks).

Game checks: 18/18 GUT; fist-v16 63 frames/0 errors; district-route-v16 65 frames/0 errors and completed=true; previous loss/checkpoint capture. W and Up were verified with actual browser keys in production/local web respectively. New near fist was generated with image_gen, source and exact prompt in art/characters/los/fist-back-v7*, fitted by prepare_rig_v7.py. Head and neck both shifted local (-4,+5) relative to v15.

Nginx and PHP8.3-FPM active. Certificate expires 2027-02-11, Certbot renewal configured. Score data is outside the release at /var/lib/smash-xedoc and was not replaced. First release created a new vhost; unrelated host configurations were not changed.
