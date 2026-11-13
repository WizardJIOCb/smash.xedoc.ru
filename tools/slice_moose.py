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
# User correction: the atlas torso included sleeves. Keep the approved local edit.
torso_source = ROOT / 'art/characters/los/torso-v2.png'
if torso_source.exists():
    torso = Image.open(torso_source).convert('RGBA')
    bounds = torso.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    bounds = (max(0, bounds[0]-3), max(0, bounds[1]-3),
              min(torso.width, bounds[2]+3), min(torso.height, bounds[3]+3))
    torso = torso.crop(bounds)
    torso.save(out / 'torso.png')
    manifest['torso'] = {'source': 'art/characters/los/torso-v2.png',
                         'trim': bounds, 'size': torso.size,
                         'alpha_extrema': torso.getchannel('A').getextrema()}
(out / 'source_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
if (ROOT / 'art/characters/los/neck-v3.png').exists():
    import subprocess
    import sys
    subprocess.run([sys.executable, str(ROOT / 'tools/prepare_rig_v3.py')], check=True)
    if (ROOT / 'art/characters/los/pant-leg-v4.png').exists():
        subprocess.run([sys.executable, str(ROOT / 'tools/prepare_rig_v4.py')], check=True)
    if (ROOT / 'art/characters/los/pant-leg-inner-v5.png').exists():
        subprocess.run([sys.executable, str(ROOT / 'tools/prepare_rig_v5.py')], check=True)
    if (ROOT / 'art/characters/los/sleeve-v6.png').exists():
        subprocess.run([sys.executable, str(ROOT / 'tools/prepare_rig_v6.py')], check=True)
    if (ROOT / 'art/characters/los/fist-back-v7.png').exists():
        subprocess.run([sys.executable, str(ROOT / 'tools/prepare_rig_v7.py')], check=True)
    if (ROOT / 'art/characters/los/fist-back-v8.png').exists():
        subprocess.run([sys.executable, str(ROOT / 'tools/prepare_rig_v8.py')], check=True)
    if (ROOT / 'art/characters/los/fist-back-v9.png').exists():
        subprocess.run([sys.executable, str(ROOT / 'tools/prepare_rig_v9.py')], check=True)
