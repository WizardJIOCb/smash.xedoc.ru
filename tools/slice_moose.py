"""Crop the generated nine-part atlas; preserve painted RGBA pixels unchanged."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NAMES = ['torso', 'pelvis', 'head', 'upper_arm', 'forearm', 'fist', 'thigh', 'shin', 'shoe']
image = Image.open(ROOT / 'art/characters/los/atlas-v1.png').convert('RGBA')
out = ROOT / 'assets/characters/los'
out.mkdir(parents=True, exist_ok=True)
manifest = {}
for index, name in enumerate(NAMES):
    col, row = index % 3, index // 3
    cell = (col * image.width // 3, row * image.height // 3,
            (col + 1) * image.width // 3, (row + 1) * image.height // 3)
    part = image.crop(cell)
    # Use visible artwork for trim bounds, without changing alpha values.
    bbox = part.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    assert bbox, name
    bbox = (max(0, bbox[0]-3), max(0, bbox[1]-3),
            min(part.width, bbox[2]+3), min(part.height, bbox[3]+3))
    part = part.crop(bbox)
    part.save(out / f'{name}.png')
    manifest[name] = {'cell': cell, 'trim': bbox, 'size': part.size,
                      'alpha_extrema': part.getchannel('A').getextrema()}
    print(name, part.size)
(out / 'source_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
