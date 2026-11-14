"""Freeze the exact Godot export plus API into a versioned deployable archive."""
import gzip
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tarfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    version = json.loads((ROOT / 'data/build.json').read_text())['version']
    release = f'v{version}-' + revision[:12]
    output = ROOT / 'build/releases' / release
    if output.exists():
        raise RuntimeError('Release already frozen; do not mutate an existing release')
    output.mkdir(parents=True)
    for source in (ROOT / 'build/web').iterdir():
        if source.is_file() and not source.name.endswith('.import'):
            shutil.copy2(source, output / source.name)
    (output / 'api').mkdir()
    shutil.copy2(ROOT / 'deploy/api/scores.php', output / 'api/scores.php')
    chapters = json.loads((ROOT / 'data/chapters.json').read_text(encoding='utf-8'))
    holiday = json.loads((ROOT / 'data/holiday_chapter.json').read_text(encoding='utf-8'))
    total = len(json.loads((ROOT / 'data/district_rooms.json').read_text(encoding='utf-8')))
    holiday.update(id=len(chapters) + 1, start=total, end=total)
    chapters.append(holiday)
    (output / 'api/chapters.json').write_text(json.dumps(chapters, ensure_ascii=False), encoding='utf-8')
    cover = ROOT / f'.studioigor/captures/menu-v{version}/frame_002.png'
    if not cover.exists():
        cover = ROOT / 'art/site/cover.png'
    shutil.copy2(cover, output / 'cover.png')
    for name in [path.name for path in output.glob('game-*') if path.suffix in ('.js', '.wasm', '.pck')]:
        data = (output / name).read_bytes()
        (output / (name + '.gz')).write_bytes(gzip.compress(data, mtime=0))
    (output / 'release.json').write_text(json.dumps({'version': version, 'commit': revision, 'release': release}), encoding='utf-8')
    hashes = {str(path.relative_to(output)).replace('\\', '/'): hashlib.sha256(path.read_bytes()).hexdigest()
              for path in sorted(output.rglob('*')) if path.is_file()}
    (output / 'release-manifest.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    archive = ROOT / f'build/{release}.tar.gz'
    with tarfile.open(archive, 'w:gz') as bundle:
        for path in output.rglob('*'):
            if path.is_file():
                bundle.add(path, arcname=str(path.relative_to(output)))
    print(json.dumps({'release': release, 'files': len(hashes), 'archive': str(archive), 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest()}))


if __name__ == '__main__':
    main()
