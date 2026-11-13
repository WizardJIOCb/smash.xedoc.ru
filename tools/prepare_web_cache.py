"""Version heavy assets by content, then wrap the standard Godot bootstrap."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/web'


def main():
    assets = {}
    for name in ('index.js', 'index.wasm', 'index.pck'):
        source = OUT / name
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
    (OUT / 'cache-loader.js').write_text(loader, encoding='utf-8')
    page = (OUT / 'index.html').read_text(encoding='utf-8')
    page = page.replace('<html lang="en">', '<html lang="ru">')
    page = page.replace('</head>', '<style>html,body{overscroll-behavior:none}canvas{touch-action:none;-webkit-user-select:none;user-select:none}</style></head>')
    page = page.replace('<script src="index.js"></script>', '<script src="cache-loader.js"></script>')
    page = page.replace('const GODOT_CONFIG = ', '(async () => {\nawait window.smashCacheReady;\nawait window.smashLoadEngine();\nconst GODOT_CONFIG = ', 1)
    page = page.replace("setStatusMode('hidden');", "setStatusMode('hidden');\n            window.smashPruneCache();", 1)
    page = page.replace('}());', "}());\n})().catch(error => { console.error(error); document.getElementById('status').style.visibility = 'visible'; document.getElementById('status-notice').style.display = 'block'; document.getElementById('status-notice').textContent = error.message; });", 1)
    (OUT / 'index.html').write_text(page, encoding='utf-8')
    (OUT / 'asset-map.json').write_text(json.dumps(assets, indent=2), encoding='utf-8')
    print('Content-addressed web assets:', json.dumps(assets))


if __name__ == '__main__':
    main()
