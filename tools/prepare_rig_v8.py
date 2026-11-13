"""Four-digit outer fist and complementary shoe layers, preserving painted RGBA."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/characters/los'
fist = Image.open(ROOT / 'art/characters/los/fist-back-v8.png').convert('RGBA')
fist = fist.crop(fist.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox())
fist.thumbnail((512, 512), Image.Resampling.LANCZOS)
fist.save(OUT / 'fist_back.png')
# The existing inner fist already has three curled fingers and a thumb.
# Both shoe layers retain the same canvas and pivot. Rim follows the collar
# from the heel to the tongue; the trouser cuff sits between the two layers.
shoe = Image.open(OUT / 'shoe.png').convert('RGBA')
mask = Image.new('L', shoe.size, 0)
points = [(0, 105), (48, 105), (85, 104), (122, 83), (147, 65),
          (167, 30), (190, 0), (407, 0), (407, 227), (0, 227)]
points = [(round(x * shoe.width / 407), round(y * shoe.height / 227)) for x, y in points]
ImageDraw.Draw(mask).polygon(points, fill=255)
front = shoe.copy()
front.putalpha(ImageChops.multiply(shoe.getchannel('A'), mask))
front.save(OUT / 'shoe_front.png')
back = shoe.copy()
back.putalpha(ImageChops.multiply(shoe.getchannel('A'), ImageChops.invert(mask)))
back.save(OUT / 'shoe_back.png')
print('v8 fist', fist.size, '; shoe layers', shoe.size)
