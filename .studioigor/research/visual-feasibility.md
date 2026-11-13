# Visual feasibility — 2026-11-13

- Skill: https://github.com/studioigor/studioigor-skill — установлен локально; этап 1, концепция. Код игры пока не создан.
- https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html — Skeleton2D, Bone2D, деформация Polygon2D с весами; встроенная возможность. Страница помечена как ещё не обновлённая для 4.7: pipeline требует теста в выбранной версии.
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html — 2D-свет, тени, CanvasModulate.
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html — шейдеры для 2D-эффектов.
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html — браузер через WebAssembly/WebGL2; Compatibility renderer; C# Godot 4 для web не поддерживается.
- Вывод: Godot — кандидат для скелета и web, выбор движка открыт; сравнить с web-native стеком на этапе 3.
- Риск: качество рига и читаемость ударов в браузере. Проверить одного персонажа в одной комнате до производства контента.
- Преобразование уровня — предложение: согласованные состояния фона, света, частиц, материалов и музыки; изменения коллизий и врагов проектируются отдельно.
