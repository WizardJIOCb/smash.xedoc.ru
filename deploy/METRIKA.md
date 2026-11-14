# Метрика игры — 114255834

Параметры визитов `game` доступны без создания целей: глава/комната, solo/coop,
host/guest, число игроков/вместимость, оружие, клавиатура/сенсор, источник входа,
версия, холодная/тёплая загрузка, диапазон FPS и результат.
`game.milestones` отмечает игровые действия; QA-визиты имеют `game.qa=true`.
Числовые итоги: время, убийства, смерти, реле, активное время и победы.

Для воронок в интерфейсе счётчика создайте цели типа «JavaScript-событие»
с идентификаторами:

- Загрузка: `game_load_start`, `game_ready`, `game_load_error`, `game_engaged`.
- Прохождение: `chapter_select`, `chapter_start`, `chapter_complete`, `chapter_fail`,
  `chapter_restart`, `chapter_pause`, `chapter_resume`, `chapter_leave`.
- Кооператив: `coop_open`, `coop_create_attempt`, `coop_join_attempt`,
  `coop_room_create`, `coop_room_join`, `coop_invite_copy`, `coop_leave`, `coop_error`.
- Бой: `room_enter`, `relay_clear`, `player_down`, `player_revive`,
  `weapon_change`, `power_use`.
- Остальное: `menu_open`, `performance_summary`, `game_session_end`.
- Выживание: `survival_start`, `survival_restart`, `survival_pause`, `survival_resume`,
  `survival_wave_start`, `survival_wave_complete`, `survival_end`; параметр `game_kind`
  разделяет кампанию и выживание, `wave` содержит достигнутую волну.

Цели в кабинете автоматически не создаются. Параметры событий передаются
внутри `game`; начните с воронки game_ready → chapter_start → chapter_complete.
Имена, коды комнат и произвольные ошибки исключены из параметров.
Приглашение извлекается до подключения SDK, затем room удаляется из URL;
UTM сохраняются. Блокировка Метрики не мешает загрузке и игре.

Проверка: `node --test tools/metrika.test.cjs`; в браузере
`?analytics_qa=1` и атрибут body `data-game-analytics`.
FPS — частота кадров браузерного цикла, а не оценка мощности устройства.
