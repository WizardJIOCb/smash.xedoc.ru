# Design — Лось: район закрыт

A living document. Changes after playtests — with a line in "Changelog".

## Mechanics
<!-- Statuses: idea → spec → gym → playtest → locked, or cut. tier: mvp — needed
for the vertical slice; full — later. Before a mechanic — research research/mech-<id>.md. -->
| id | mechanic | tier | pillar | status | scene | notes |
|---|---|---|---|---|---|---|
| M01 | Движение и быстрый увесистый бой | mvp | Живой тяжёлый герой | idea | — | Риск: скелетный герой должен двигаться выразительно и отзывчиво в браузере; прыжок, комбо, рывок, парирование |
| M02 | Три врага и читаемые контратаки | mvp | Бой через чтение противника | playtest | scenes/gyms/district_gym.tscn | Кабан-щитовик, крыса с кабелем, дрон; пять врагов в трёх комнатах, реальный урон, замахи, поражение и повтор; публичный playtest |
| M03 | Карантин и освобождение района | mvp | Преображение всего района | idea | — | Фон, свет, частицы и музыка меняются согласованно; проверка на одной комнате |
| M04 | Способность и возврат к закрытому проходу | mvp | Способность меняет маршрут | idea | — | Конкретная способность выбирается после проверки движения |
| M05 | Короткие реплики и вступление | mvp | Характер в действии | idea | — | Цель понятна в первую минуту; реплики с интервалом, пропуск вступления |
| M06 | Мини-босс и завершение фрагмента | mvp | Бой через чтение противника | idea | — | Итог, повтор, контрольная точка перед боем |
| M07 | Firewall и перестраиваемая арена | full | Преображение всего района | idea | — | Финал полной игры; удар рогами по открытому ядру |
| M08 | Багровая ярость и независимое время суток | mvp | Преображение всего района | playtest | scenes/gyms/district_gym.tscn | T — день/ночь без расхода заряда; Q — ульта8с, красная аура, рост12%, урон×1.8; L — импульс52/радиус210 каждые2с. Ульта не меняет время суток. Заряд за реальные попадания12/победы18 вне ульты; пауза замораживает таймер |

## Game designer ideas
<!-- references/gamedesigner.md. Statuses: proposed → approved → M## | rejected (why) | deferred.
Do not propose rejected ideas again. Do not implement unapproved ones. -->
| id | idea | why it's fun | cost S/M/L | point (phase) | status |
|---|---|---|---|---|---|
| H01 | Узел Firewall меняет весь район | Видимый результат победы, знакомое место раскрывается заново | M | 1 | approved → M03; принято продолжение показанной концепции |
| H02 | Враги раскрываются разными контратаками | Игрок выбирает ответ, а не повторяет одну атаку | M | 1 | approved → M02; в показанной концепции щитовик, хлыстовик, дрон |
| H03 | Firewall перестраивает арену | Финал проверяет бой и перемещение вместе | L | 1 | approved → M07; full, в показанной концепции |

## Content
<!-- phase 8 (references/production.md): one line per unit. Statuses: sketch → blockout → art → final. -->
| id | new | signature moment | difficulty 1–10 | axes of difference from the neighbor | story beat | status |
|---|---|---|---|---|---|---|

## Progression and meta
- Первые 60 секунд: управление и понятная цель — выбраться из закрытого района.
- Через 5–10 минут: способность открывает знакомый проход и секрет.
- Финал фрагмента: мини-босс, освобождённая область, вид на дальнейший путь.

## Economy
<!-- resource: sources → sinks, rate (a guess is fine) -->
- Первый фрагмент без валюты и случайной экипировки; здоровье восстанавливается у контрольной точки.

## Difficulty
- philosophy: доступный вход и глубина в таймингах; частые контрольные точки, повтор без долгого забега.
- axes: исполнение и выбор ответа; у каждой опасной атаки есть подготовка и окно восстановления.

## Mechanic specs
<!-- ### M01 — Name
what · why (pillar) · controls · rules · parameters (in data files) ·
acceptance criteria · "feel" (targets) · research: research/mech-M01.md -->

### M01 — attack animation playtest v13
- J alternates near/far punches; K cycles front, low and high kicks while alternating legs across cycles. Arms counterbalance the kicking leg. All attacks have air and crouch variants. No enemy damage simulation yet.
- One-slot input buffer 0.28s; normal punch chain opens at 0.265s, cross at 0.29s; idle 0.6s resets to first hand. Timings in `data/attacks.json`.
- Ground attacks reduce movement speed; air momentum retained. Opposite arm counterbalances; landing accelerates aerial recovery.
- Near sleeve mesh keeps both stripes continuous through elbow. Guard feet: near behind (-19), far in front (+19), mirrored with facing; walk cycle retained.
- S/Down holds crouch; A/D moves low. Shift selects run (300 vs walk155), crouch88. Backpedal reverses foot swing while facing is held through a series.
- Releasing direction plans the remaining distance to a guard-compatible footfall, brakes into it and settles the feet; renewed input, attack or takeoff interrupts the stop.
- High kick transfers hips toward support, leans torso during chamber, raises the thigh and counterbalances with the opposite arm. Parameters in `attacks.json/kick_body`.
- Airborne ankle angles differ from grounded shoes; rear toe drops 0.65rad, independent of which leg attacks. Tune `rig_motion.json/air_front_toe` and `air_rear_toe`.
- Acceptance: J×4 alternates hands; J/K chain; Space→J and Space→K differ; no autonomous strikes after taps stop. Scene `scenes/gyms/attack_gym.tscn`, status playtest. Phase5 art approval remains open.
- Research: `research/mech-M01-attacks.md`.

## Changelog

| date | what | why |
|---|---|---|
| 2026-11-13 | Черновик первого фрагмента из принятой концепции | «да давай дальше» после показа концепции; цифры — рабочие оценки |
| 2026-11-13 | Серии рук/ног, присед, Shift, остановка по шагу и обратный ход | Прямые запросы пользователя в тесте анимаций; ждёт оценки |
| 2026-11-14 | Ночная ульта, тихий первый запуск, 4 пальца, двухслойные кроссовки и меховой край головы; Web-кеш с cache=clear | Прямые запросы по публичному playtest; художественная оценка остаётся у пользователя |
| 2026-11-14 | Исправлены плечи/локти врагов; второй уступ ниже20px; T время суток отдельно от Q ульты, L импульс; пушистая ближняя лапа приглушена до тона шерсти | Прямые замечания по публичной версии; проверены фактическое приземление, независимость режимов и новый тон |
