"""Trim/fit the redrawn near fist without altering the generated painting."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
source = ROOT / 'art/characters/los/fist-back-v7.png'
if not source.exists():
    original = Path.home() / '.codex/generated_images/01a1d5b0-8c34-7ab1-bdeb-50bc7720899a/exec-15322b87-571a-467e-951b-39a6a9ff7d69.png'
    source.write_bytes(original.read_bytes())
image = Image.open(source).convert('RGBA')
box = image.getchannel('A').point(lambda alpha: 255 if alpha > 24 else 0).getbbox()
image = image.crop(box)
image.thumbnail((512, 512), Image.Resampling.LANCZOS)
image.save(ROOT / 'assets/characters/los/fist_back.png')
print('Near fist v7:', image.size, 'alpha', image.getchannel('A').getextrema())
