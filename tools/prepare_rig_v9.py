"""Trim/fit the softer four-digit fist, preserving generated painterly RGBA."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
image = Image.open(ROOT / 'art/characters/los/fist-back-v9.png').convert('RGBA')
image = image.crop(image.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox())
image.thumbnail((512, 512), Image.Resampling.LANCZOS)
image.save(ROOT / 'assets/characters/los/fist_back.png')
print('Soft fist v9', image.size)
