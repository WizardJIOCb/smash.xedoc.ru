# Выживание — 2026-11-15

- Запрос: отдельный режим волн и рейтинг; пользователь подтвердил solo + coop с раздельным зачётом.
- Godot: https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html — состояние волн RefCounted, существующие боевые Node2D переиспользуются.
- Godot: https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html — ограничиваем одновременно живых врагов и очищаем предыдущую волну, измеряем реальные кадры.
- Хост считает бой и волны, гости получают snapshot; party size фиксируется на старте, павшие возвращаются между волнами, общий wipe завершает забег.
- Рейтинг: волна ↓, убийства ↓, время ↑; отдельный survival.json и отдельные solo/coop группы.
- Без изменения relay: зарезервированный допустимый chapter255 означает Survival, новый build ID отделяет несовместимые клиенты.
