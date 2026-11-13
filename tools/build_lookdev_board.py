"""Use the studioigor review template for actual engine captures."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
board = root / '.studioigor/boards/lookdev-r2'
board.mkdir(parents=True, exist_ok=True)
frames = [('frame_001.png', 'Корпус исправлен: без встроенных рукавов. Две отдельные руки.'),
          ('frame_010.png', 'Шаг следует за перемещением, опорная стопа привязана к земле.'),
          ('frame_021.png', 'Удар: подготовка, вынос руки и возврат в стойку.'),
          ('frame_032.png', 'Прыжок: подготовка, группировка и последующая амортизация.'),
          ('frame_056.png', 'Карантин, другая сторона персонажа. Z включает крупный план.')]
spec = {'title': 'Лось — анимация v2 и исправленные рукава',
        'subtitle': 'Кадры настоящего рендера Godot. Играть: http://127.0.0.1:8770/index.html',
        'question': 'Оцени движение в игре, затем ответь в чате: подходит ли направление и что поправить?',
        'mode': 'none', 'options': [{'id': 'rig', 'title': 'Лось в живописном дворе',
        'text': '15 костей, деформация куртки сеткой из 35 вершин, инерция головы и корпуса, подготовка прыжка и посадка. Врагов и расчёта урона пока нет.',
        'media': [{'src': '../../captures/lookdev-v2-close/' + file, 'caption': caption,
                   'generated': False, 'credit': 'Actual Godot render · original project art'}
                  for file, caption in frames]}]}
path = board / 'board.json'
path.write_text(json.dumps(spec, ensure_ascii=False, indent=2), encoding='utf-8')
subprocess.run([sys.executable, '-X', 'utf8', str(Path.home() / '.codex/skills/studioigor/scripts/board.py'),
                'build', str(path)], check=True)
