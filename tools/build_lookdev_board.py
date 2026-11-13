"""Use the studioigor review template for actual engine captures."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
board = root / '.studioigor/boards/lookdev-r3'
board.mkdir(parents=True, exist_ok=True)
frames = [('frame_001.png', 'Ближняя рука поверх корпуса; ворот заполнен шерстью, таз компактнее.'),
          ('frame_011.png', 'Удар: кисть закреплена за запястье и продолжает направление манжеты.'),
          ('frame_030.png', 'Бег в обратную сторону: порядок рук и силуэт таза.'),
          ('../gaze-v3/frame_009.png', 'Короткий взгляд в камеру во время стойки. При движении снова смотрит вперёд.')]
spec = {'title': 'Лось — сборка персонажа v3',
        'subtitle': 'Кадры настоящего рендера Godot. Играть: http://127.0.0.1:8770/index.html',
        'question': 'Оцени движение в игре, затем ответь в чате: подходит ли направление и что поправить?',
        'mode': 'none', 'options': [{'id': 'rig', 'title': 'Лось в живописном дворе',
        'text': 'Исправлены плечи, слои, запястья, ворот, таз и направление взгляда. Форма головы сохранена; меняется только область глаз. Врагов и расчёта урона пока нет.',
        'media': [{'src': '../../captures/lookdev-v3/' + file, 'caption': caption,
                   'generated': False, 'credit': 'Actual Godot render · original project art'}
                  for file, caption in frames]}]}
path = board / 'board.json'
path.write_text(json.dumps(spec, ensure_ascii=False, indent=2), encoding='utf-8')
subprocess.run([sys.executable, '-X', 'utf8', str(Path.home() / '.codex/skills/studioigor/scripts/board.py'),
                'build', str(path)], check=True)
