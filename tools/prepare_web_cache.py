"""Version heavy assets by content, then wrap the standard Godot bootstrap."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/web'


def main():
    assets = {}
    sizes = {}
    for name in ('index.js', 'index.wasm', 'index.pck'):
        source = OUT / name
        sizes[name] = source.stat().st_size
        digest = hashlib.sha256(source.read_bytes()).hexdigest()[:20]
        destination = f'game-{digest}{source.suffix}'
        assets[name] = destination
        source.replace(OUT / destination)
    # Remove only obsolete hashed exports in this exact build output directory.
    for candidate in OUT.glob('game-*'):
        if candidate.is_file() and candidate.name not in assets.values():
            candidate.unlink()
    loader = (ROOT / 'web/cache-loader.js').read_text(encoding='utf-8')
    loader = loader.replace('__SMASH_ASSETS__', json.dumps(assets))
    loader = loader.replace('__SMASH_ASSET_SIZES__', json.dumps(sizes))
    (OUT / 'cache-loader.js').write_text(loader, encoding='utf-8')
    page = (OUT / 'index.html').read_text(encoding='utf-8')
    page = page.replace('<script src="index.js"></script>', '<script src="cache-loader.js"></script>')
    page = page.replace('__SMASH_LOADING_CSS__', (ROOT / 'web/loading.css').read_text(encoding='utf-8'))
    page = page.replace('__SMASH_LOADING_UI__', (ROOT / 'web/loading-ui.js').read_text(encoding='utf-8'))
    if '__SMASH_' in page or '$GODOT_' in page:
        raise RuntimeError('Unresolved loading shell placeholders')
    (OUT / 'index.html').write_text(page, encoding='utf-8')
    for source, name in (
        ('assets/environment/menu-ground-v1.webp', 'loading-world.webp'),
        ('art/branding/loading-moose-v1.webp', 'loading-moose.webp'),
        ('assets/fonts/Manrope.ttf', 'loading-font.ttf'),
    ):
        shutil.copy2(ROOT / source, OUT / name)
    (OUT / 'asset-map.json').write_text(json.dumps(assets, indent=2), encoding='utf-8')
    print('Content-addressed web assets:', json.dumps(assets))


if __name__ == '__main__':
    main()
