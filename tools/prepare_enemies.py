"""Reproducible alpha trimming and smooth fitting of generated enemy parts."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path.home() / '.codex/generated_images/01a1d5b0-8c34-7ab1-bdeb-50bc7720899a'
FILES = {
    'shield': 'exec-b78ef476-75ad-4d9c-8c2a-90f120d6f5ee.png',
    'whip': 'exec-5648fb67-9991-4d5c-941a-5db589a4d242.png',
    'drone': 'exec-d8e6c6cb-1dab-4ad0-95c5-1ece70aaef8e.png',
    'alley': 'exec-d1bb98dc-589a-4aee-8838-b101f5b32845.png',
    'gate': 'exec-9ac8661d-c23b-4a29-b8fe-21d38f82039b.png',
}


def trim(image, maximum=768):
    box = image.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    if box is None:
        raise ValueError('Empty alpha crop')
    image = image.crop(box)
    image.thumbnail((maximum, maximum), Image.Resampling.LANCZOS)
    return image


def main():
    art = ROOT / 'art/enemies'
    art.mkdir(parents=True, exist_ok=True)
    parts = ['head', 'torso', 'near_arm', 'far_arm', 'near_leg', 'far_leg', 'weapon', 'extra']
    for name, filename in FILES.items():
        dest = (ROOT / 'art/environment' if name in ('alley', 'gate') else art) / f'{name}-v1.png'
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.exists():
            dest.write_bytes((SOURCE / filename).read_bytes())
        if name == 'shield':
            clean = art / 'shield-v1-alpha.png'
            if not clean.exists():
                clean.write_bytes((SOURCE / 'exec-5c92b5b6-e1d8-4f77-b8bb-1628c1d523aa.png').read_bytes())
            dest = clean
        image = Image.open(dest).convert('RGBA')
        if name in ('alley', 'gate'):
            image = image.resize((1280, 720), Image.Resampling.LANCZOS)
            image.save(ROOT / f'assets/environment/{name}-alive.png')
            continue
        target = ROOT / f'assets/enemies/{name}'
        target.mkdir(parents=True, exist_ok=True)
        if name == 'drone':
            trim(image).save(target / 'body.png')
            continue
        # Unequal gutters follow actual generated alpha silhouettes, not guessed square cells.
        rows = [0, 397, 790, image.height] if name == 'shield' else [0, 412, 850, image.height]
        columns = [0, 438, 884, image.width] if name == 'shield' else [0, 422, 843, image.width]
        for i, part in enumerate(parts):
            row, col = divmod(i, 3)
            crop = image.crop((columns[col], rows[row], columns[col + 1], rows[row + 1]))
            trim(crop).save(target / f'{part}.png')
        print(name, image.size, 'alpha extrema', image.getchannel('A').getextrema())
    platform_source = ROOT / 'art/environment/service-ledge-v1.png'
    if not platform_source.exists():
        platform_source.write_bytes((SOURCE / 'exec-a9f64187-110e-4dff-bed1-efeb53bbe016.png').read_bytes())
    trim(Image.open(platform_source).convert('RGBA'), 1200).save(ROOT / 'assets/environment/service-ledge.png')


if __name__ == '__main__':
    main()
