"""Prepare original aftermath masters for the existing painted skeletal rig."""
import argparse
import json
from pathlib import Path

from PIL import Image
from prepare_campaign_art import clean, fit

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/aftermath'
GUNS = {'raccoon', 'owl', 'manager'}
PARTS = [('head', (416, 376), False), ('torso', (264, 316), True),
         ('arm', (180, 276), True), ('leg', (152, 296), True)]


def prepare(item):
    source = ART / 'sources' / (item['id'] + '.png')
    image = Image.open(source).convert('RGBA')
    if not item['id'].startswith('enemy-'):
        target = ROOT / 'assets/environment' / (item['id'] + '.webp')
        image.convert('RGB').resize((1280, 720), Image.Resampling.LANCZOS).save(target, quality=91)
        return
    kind = item['id'][6:]
    if image.getchannel('A').getextrema()[0] != 0:
        raise ValueError(f'{kind}: master has no transparency')
    output = ROOT / 'assets/enemies' / kind
    output.mkdir(parents=True, exist_ok=True)
    cells = [image.crop((col * image.width // 3, row * image.height // 2,
                         (col + 1) * image.width // 3, (row + 1) * image.height // 2))
             for row in range(2) for col in range(3)]
    for index, (name, size, stretch) in enumerate(PARTS):
        part = fit(cells[index], size, stretch)
        for filename in ([f'near_{name}', f'far_{name}'] if name in {'arm', 'leg'} else [name]):
            part.save(output / (filename + '.png'))
    fit(cells[4], (240, 120) if kind in GUNS else (120, 308)).save(output / 'weapon.png')
    fit(cells[5], (104, 128)).save(output / 'extra.png')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--id', action='append', help='Only prepare selected generated assets')
    parser.add_argument('--available', action='store_true', help='Skip masters still being generated')
    args = parser.parse_args()
    jobs = json.loads((ART / 'prompts.json').read_text(encoding='utf8'))
    prepared = []
    for item in jobs:
        if args.id and item['id'] not in args.id:
            continue
        if args.available and not (ART / 'sources' / (item['id'] + '.png')).exists():
            continue
        prepare(item)
        prepared.append({'id': item['id'], 'source': 'art/aftermath/sources/' + item['id'] + '.png'})
    if not args.id:
        (ART / 'generated-manifest.json').write_text(json.dumps(prepared, indent=2) + '\n', encoding='utf8')
    print(json.dumps({'prepared': len(prepared), 'ids': [item['id'] for item in prepared]}))


if __name__ == '__main__':
    main()
