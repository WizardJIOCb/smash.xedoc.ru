"""Fit HD painted title assets smoothly; preserve the original generated PNG."""
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / 'art/branding/menu-ground-v1.png').convert('RGB')
ImageOps.fit(source, (1280, 720), method=Image.Resampling.LANCZOS, centering=(0.5, 1)).save(
    ROOT / 'assets/environment/menu-ground-v1.webp', quality=88, method=6)
hero = Image.open(ROOT / 'art/branding/loading-moose-v1.png').convert('RGBA')
hero = hero.crop(hero.getchannel('A').getbbox())
hero = ImageOps.contain(hero, (496, 744), method=Image.Resampling.LANCZOS)
canvas = Image.new('RGBA', (512, 768))
canvas.alpha_composite(hero, ((512 - hero.width) // 2, 768 - hero.height))
hero = canvas
hero.save(ROOT / 'art/branding/loading-moose-v1.webp', quality=90, method=6)
print('Prepared 1280x720 painted background and 512x768 transparent rig portrait')
