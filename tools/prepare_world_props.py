"""Fit original transparent painted props to bounded runtime textures."""
import json
from pathlib import Path
from PIL import Image
from prepare_campaign_art import clean

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/props'
OUTPUT = ROOT / 'assets/environment/props'


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    report = []
    for job in json.loads((ART / 'prompts.json').read_text(encoding='utf-8')):
        source = ART / 'sources' / (job['id'] + '.png')
        if not source.exists():
            continue
        image = Image.open(source).convert('RGBA')
        opaque = job['id'] in ('river-opening', 'roof-opening')
        if not opaque:
            if image.getchannel('A').getextrema()[0] != 0:
                raise ValueError(f'{source.name}: transparency missing')
            image = clean(image)
        limit = tuple(job['size'])
        if job['id'] == 'metro-signal':
            limit = (512, 176)
        elif job['id'] == 'billboard-bridge':
            limit = (768, 224)
        elif job['id'] == 'port-carrier':
            limit = (512, 144)
        image.thumbnail(limit, Image.Resampling.LANCZOS)
        image.save(OUTPUT / (job['id'] + '.png'), optimize=True)
        report.append({'id': job['id'], 'size': image.size,
                       'source': source.relative_to(ROOT).as_posix()})
    (ART / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
