"""Deterministic trim/fit of the original generated campaign sheets (soft RGBA)."""
import json
from pathlib import Path
from shutil import copy2
from PIL import Image
import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/campaign'


def clean(part):
    part = part.convert('RGBA')
    rgba = np.asarray(part).copy()
    mask = (rgba[:, :, 3] > 80).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    if count <= 1:
        raise ValueError('Empty generated part')
    largest = 1 + int(stats[1:, cv2.CC_STAT_AREA].argmax())
    keep = cv2.dilate((labels == largest).astype(np.uint8), np.ones((7, 7), np.uint8))
    rgba[:, :, 3] *= keep
    part = Image.fromarray(rgba)
    bounds = part.getchannel('A').getbbox()
    return part.crop(bounds)


def fit(part, size, stretch=False):
    part = clean(part)
    if stretch:
        return part.resize(size, Image.Resampling.LANCZOS)
    part.thumbnail(size, Image.Resampling.LANCZOS)
    result = Image.new('RGBA', size)
    result.alpha_composite(part, ((size[0] - part.width) // 2, size[1] - part.height))
    return result


def main():
    manifest = json.loads((ART / 'generated-manifest.json').read_text(encoding='utf8'))
    for item in manifest:
        source = Path(item['source'])
        if not source.is_absolute():
            source = ROOT / source
        saved = ART / 'sources' / (item['id'] + '.png')
        saved.parent.mkdir(parents=True, exist_ok=True)
        if source.resolve() != saved.resolve():
            copy2(source, saved)
        item['source'] = saved.relative_to(ROOT).as_posix()
        image = Image.open(saved)
        if not item['id'].startswith('enemy-'):
            output = ROOT / 'assets/environment' / (item['id'] + '.webp')
            image.convert('RGB').resize((1280, 720), Image.Resampling.LANCZOS).save(output, quality=91)
            continue
        kind = item['id'][6:]
        output = ROOT / 'assets/enemies' / kind
        output.mkdir(parents=True, exist_ok=True)
        cells = []
        for row in range(2):
            for col in range(3):
                cells.append(image.crop((col * image.width // 3, row * image.height // 2,
                                         (col + 1) * image.width // 3, (row + 1) * image.height // 2)))
        fit(cells[0], (416, 376)).save(output / 'head.png')
        fit(cells[1], (264, 316), True).save(output / 'torso.png')
        fit(cells[2], (180, 276), True).save(output / 'near_arm.png')
        fit(cells[2], (180, 276), True).save(output / 'far_arm.png')
        fit(cells[3], (152, 296), True).save(output / 'near_leg.png')
        fit(cells[3], (152, 296), True).save(output / 'far_leg.png')
        weapon = image.crop((int(image.width * .28), image.height // 2, int(image.width * .74), image.height))
        if kind not in ['fox', 'lynx', 'firewall']:
            weapon = weapon.rotate(-90, expand=True)
        fit(weapon, (240, 120) if kind in ['fox', 'lynx', 'firewall'] else (120, 308)).save(output / 'weapon.png')
        fit(cells[5], (104, 128)).save(output / 'extra.png')
    weapon_meta = json.loads((ART / 'weapon-source.json').read_text(encoding='utf8'))
    sheet = Image.open(ROOT / weapon_meta['source'])
    output = ROOT / 'assets/weapons'
    output.mkdir(exist_ok=True)
    for index, name in enumerate(['bat', 'shovel', 'hockey', 'knuckles', 'pistol', 'rifle']):
        row, col = divmod(index, 3)
        part = clean(sheet.crop((col * sheet.width // 3, row * sheet.height // 2,
                                 (col + 1) * sheet.width // 3, (row + 1) * sheet.height // 2)))
        part.thumbnail((400, 160), Image.Resampling.LANCZOS)
        part.save(output / (name + '.png'))
    (ART / 'generated-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf8')
    print('Prepared', len(manifest), 'original campaign assets')


if __name__ == '__main__':
    main()
