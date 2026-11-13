"""Use the studioigor review template for actual engine captures."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
board = root / '.studioigor/boards/lookdev-r4'
board.mkdir(parents=True, exist_ok=True)
frames = [('frame_001.png', 'Ближний кулак с тыльной стороны; штаны без отдельной накладки таза.'),
          ('frame_007.png', 'Непрерывные полосы: сетка от талии через бедро и колено до манжеты.'),
          ('frame_017.png', 'Прыжок: проверка сгиба штанов и стыка с поясом.'),
          ('frame_030.png', 'Обратное направление: ближняя нога согласована с ближним плечом.'),
          ('frame_036.png', 'Ближняя рука и кулак выше головы в порядке отрисовки.')]
spec = {'title': 'Лось — цельные штаны и кисти v4',
        'subtitle': 'Кадры настоящего рендера Godot. Играть: http://127.0.0.1:8770/index.html',
        'question': 'Оцени движение в игре, затем ответь в чате: подходит ли направление и что поправить?',
        'mode': 'none', 'options': [{'id': 'rig', 'title': 'Лось в живописном дворе',
        'text': 'Две цельные деформируемые штанины, отдельный тыльный кулак, согласованные слои рук/ног. Шея использует шерсть из исходной головы, мех ворота приведён к её палитре. Врагов и расчёта урона пока нет.',
        'media': [{'src': '../../captures/lookdev-v4/' + file, 'caption': caption,
                   'generated': False, 'credit': 'Actual Godot render · original project art'}
                  for file, caption in frames]}]}
path = board / 'board.json'
path.write_text(json.dumps(spec, ensure_ascii=False, indent=2), encoding='utf-8')
subprocess.run([sys.executable, '-X', 'utf8', str(Path.home() / '.codex/skills/studioigor/scripts/board.py'),
                'build', str(path)], check=True)
