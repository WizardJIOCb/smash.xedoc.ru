"""Use the studioigor review template for actual engine captures."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
board = root / '.studioigor/boards/lookdev-r13'
board.mkdir(parents=True, exist_ok=True)
frames = [('frame_001.png', 'Стойка: ближняя нога сзади, дальняя спереди.'),
          ('frame_005.png', 'Первый пинок: ближняя рука отводится для баланса.'),
          ('frame_011.png', 'Другая нога — другой замах рук.'),
          ('../high-kick-v13/frame_032.png', 'Высокий пинок v13: таз вперёд, корпус ближе к горизонтали.'),
          ('frame_050.png', 'Движение в приседе.'),
          ('frame_065.png', 'Низкий пинок в приседе.'),
          ('frame_079.png', 'В полёте задняя стопа повёрнута носком вниз.'),
          ('frame_090.png', 'Отдельная поза удара рукой в воздухе.')]
spec = {'title': 'Лось — бой и движение v13',
        'subtitle': 'Кадры настоящего рендера Godot. Играть: http://127.0.0.1:8770/index.html',
        'question': 'Оцени движение в игре, затем ответь в чате: подходит ли направление и что поправить?',
        'mode': 'none', 'options': [{'id': 'rig', 'title': 'Лось в живописном дворе',
        'text': 'A/D — ходьба, Shift — бег, S/↓ — присед. J — чередование рук, K — три разных пинка. Руки и ноги работают в приседе и в прыжке; шаг назад во время серии, завершение шага при остановке. Ближний рукав цельный, обе полосы проходят через локоть. Врагов и расчёта урона пока нет.',
        'media': [{'src': '../../captures/combos-v12/' + file, 'caption': caption,
                   'generated': False, 'credit': 'Actual Godot render · original project art'}
                  for file, caption in frames]}]}
path = board / 'board.json'
path.write_text(json.dumps(spec, ensure_ascii=False, indent=2), encoding='utf-8')
subprocess.run([sys.executable, '-X', 'utf8', str(Path.home() / '.codex/skills/studioigor/scripts/board.py'),
                'build', str(path)], check=True)
