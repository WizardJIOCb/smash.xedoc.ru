"""Trim and fit v5 inner limb surfaces and compact dorsal fist, preserving alpha."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/characters/los'
OUT = ROOT / 'assets/characters/los'
manifest = {}
for name, source in [('pant_leg_inner', 'pant-leg-inner-v5.png'),
                     ('upper_arm_inner', 'upper-arm-inner-v5.png'),
                     ('forearm_inner', 'forearm-inner-v5.png'),
                     ('fist_back', 'fist-back-v5.png')]:
    im = Image.open(ART / source).convert('RGBA')
    bounds = im.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    box = (max(0, bounds[0]-3), max(0, bounds[1]-3),
           min(im.width, bounds[2]+3), min(im.height, bounds[3]+3))
    im = im.crop(box)
    im.thumbnail((512, 768), Image.Resampling.LANCZOS)
    im.save(OUT / f'{name}.png')
    manifest[name] = {'source': 'art/characters/los/' + source, 'crop': box, 'size': im.size}
    print(name, im.size)
(OUT / 'parts_v5_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
