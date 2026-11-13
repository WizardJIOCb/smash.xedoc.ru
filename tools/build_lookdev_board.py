"""Use the studioigor review template for actual engine captures."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
board = root / '.studioigor/boards/lookdev-r1'
board.mkdir(parents=True, exist_ok=True)
frames = [('frame_000.png', 'Стойка: настоящий собранный персонаж в Godot.'),
          ('frame_004.png', 'Бег: отдельные кости, постановка стоп и перенос веса.'),
          ('frame_015.png', 'Прыжок: ноги поджимаются, корпус сохраняет силуэт.'),
          ('frame_028.png', 'Карантин: второй световой режим всего района.'),
          ('frame_033.png', 'Отладочное отображение 15 костей — клавиша B в игре.')]
spec = {'title': 'Лось — первая проба скелетной анимации',
        'subtitle': 'Кадры настоящего рендера Godot. Играть: http://127.0.0.1:8770/index.html',
        'question': 'Оцени движение в игре, затем ответь в чате: подходит ли направление и что поправить?',
        'mode': 'none', 'options': [{'id': 'rig', 'title': 'Лось в живописном дворе',
        'text': 'Оригинальные нарисованные части на Skeleton2D. Первая проба: бег, прыжок, удар, смена атмосферы. Деформация сеткой и бой с врагами ещё впереди.',
        'media': [{'src': '../../captures/lookdev/' + file, 'caption': caption,
                   'generated': False, 'credit': 'Actual Godot render · original project art'}
                  for file, caption in frames]}]}
path = board / 'board.json'
path.write_text(json.dumps(spec, ensure_ascii=False, indent=2), encoding='utf-8')
subprocess.run([sys.executable, '-X', 'utf8', str(Path.home() / '.codex/skills/studioigor/scripts/board.py'),
                'build', str(path)], check=True)
