"""Fit v4 generated parts; clone the original head's fur into its neck bridge."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/characters/los'
OUT = ROOT / 'assets/characters/los'
manifest = {}
for name, source in [('fist_back', 'fist-back-v4.png'), ('pant_leg', 'pant-leg-v4.png'),
                     ('torso', 'torso-v4.png')]:
    im = Image.open(ART / source).convert('RGBA')
    bounds = im.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    box = (max(0, bounds[0]-3), max(0, bounds[1]-3),
           min(im.width, bounds[2]+3), min(im.height, bounds[3]+3))
    im = im.crop(box)
    im.thumbnail((512, 768), Image.Resampling.LANCZOS)
    im.save(OUT / f'{name}.png')
    manifest[name] = {'source': 'art/characters/los/' + source, 'crop': box, 'size': im.size}
    print(name, im.size)
head = Image.open(OUT / 'head.png').convert('RGBA')
neck_box = (190, 224, 293, 330)
head.crop(neck_box).save(OUT / 'neck.png')
manifest['neck'] = {'source': 'assets/characters/los/head.png', 'crop': neck_box}
(OUT / 'parts_v4_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
