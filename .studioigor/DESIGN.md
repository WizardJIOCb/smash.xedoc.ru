# Design — Лось: район закрыт

A living document. Changes after playtests — with a line in "Changelog".

## Mechanics
<!-- Statuses: idea → spec → gym → playtest → locked, or cut. tier: mvp — needed
for the vertical slice; full — later. Before a mechanic — research research/mech-<id>.md. -->
| id | mechanic | tier | pillar | status | scene | notes |
|---|---|---|---|---|---|---|
| M01 | Движение и быстрый увесистый бой | mvp | Живой тяжёлый герой | idea | — | Риск: скелетный герой должен двигаться выразительно и отзывчиво в браузере; прыжок, комбо, рывок, парирование |
| M02 | Три врага и читаемые контратаки | mvp | Бой через чтение противника | idea | — | Щитовик, кабельный хлыстовик, дрон; здоровье, урон, поражение и повтор |
| M03 | Карантин и освобождение района | mvp | Преображение всего района | idea | — | Фон, свет, частицы и музыка меняются согласованно; проверка на одной комнате |
| M04 | Способность и возврат к закрытому проходу | mvp | Способность меняет маршрут | idea | — | Конкретная способность выбирается после проверки движения |
| M05 | Короткие реплики и вступление | mvp | Характер в действии | idea | — | Цель понятна в первую минуту; реплики с интервалом, пропуск вступления |
| M06 | Мини-босс и завершение фрагмента | mvp | Бой через чтение противника | idea | — | Итог, повтор, контрольная точка перед боем |
| M07 | Firewall и перестраиваемая арена | full | Преображение всего района | idea | — | Финал полной игры; удар рогами по открытому ядру |

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

## Changelog
| date | what | why |
|---|---|---|
| 2026-11-13 | Черновик первого фрагмента из принятой концепции | «да давай дальше» после показа концепции; цифры — рабочие оценки |
