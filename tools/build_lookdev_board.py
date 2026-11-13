"""Use the studioigor review template for actual engine captures."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
board = root / '.studioigor/boards/lookdev-r5'
board.mkdir(parents=True, exist_ok=True)
frames = [('frame_001.png', 'Крупнее тыльный кулак; дальняя манжета поверх своей обуви.'),
          ('frame_007.png', 'На внутренних поверхностях дальней руки и ноги нет полос.'),
          ('frame_017.png', 'Прыжок: проверка сгиба штанов и стыка с поясом.'),
          ('frame_030.png', 'Обратное направление: проверка перспективы и слоёв.'),
          ('frame_036.png', 'Нахлёст ткани в сгибе ближнего локтя; удар.')]
spec = {'title': 'Лось — внутренние поверхности и суставы v5',
        'subtitle': 'Кадры настоящего рендера Godot. Играть: http://127.0.0.1:8770/index.html',
        'question': 'Оцени движение в игре, затем ответь в чате: подходит ли направление и что поправить?',
        'mode': 'none', 'options': [{'id': 'rig', 'title': 'Лось в живописном дворе',
        'text': 'Дальние рукав и штанина используют отдельный рисунок без полос. Ближний тыльный кулак перерисован и увеличен. Исправлены нахлёст локтя и дальняя манжета поверх обуви. Врагов и расчёта урона пока нет.',
        'media': [{'src': '../../captures/lookdev-v5/' + file, 'caption': caption,
                   'generated': False, 'credit': 'Actual Godot render · original project art'}
                  for file, caption in frames]}]}
path = board / 'board.json'
path.write_text(json.dumps(spec, ensure_ascii=False, indent=2), encoding='utf-8')
subprocess.run([sys.executable, '-X', 'utf8', str(Path.home() / '.codex/skills/studioigor/scripts/board.py'),
                'build', str(path)], check=True)
