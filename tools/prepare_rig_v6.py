"""Export the continuous near sleeve, preserving generated alpha."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
im = Image.open(root / 'art/characters/los/sleeve-v6.png').convert('RGBA')
box = im.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
im = im.crop(box)
im.thumbnail((512, 1024), Image.Resampling.LANCZOS)
im.save(root / 'assets/characters/los/sleeve.png')
print('sleeve', im.size, 'source crop', box)
