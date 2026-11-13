# Menus, shared scores and browser release — 2026-11-13

Sources:
- https://docs.godotengine.org/en/stable/classes/httprequest.html — HTTPRequest lifecycle and response signals.
- https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html — user:// persistence; exported resources are read-only.
- https://github.com/google/fonts/tree/main/ofl/manrope — Cyrillic Manrope, bundled with OFL license.

Requested: start screen, menu items, leaderboard, GitHub push and public HTTPS deployment. Corrected document root: /var/www/smash.xedoc.ru. Public domain smash.xedoc.ru. Existing server verified root access, Nginx, PHP8.3-FPM (nginx user), Certbot. DNS A already matches 82.146.42.213, no AAAA.

Decision: original painted world and animated moose for the title; keyboard/mouse menu, help, pause/resume and finish/name entry. Same-origin shared top10 via PHP JSON endpoint; persistent browser top10 fallback offline. Server computes scores, accepts one submission per short-lived run token, checks bounds and elapsed time; casual ranking, not authoritative anti-cheat. State remains /var/lib/smash-xedoc outside web root and Git. Deploy only exported web files and one PHP endpoint, with explicit MIME/cache rules and HTTPS.
