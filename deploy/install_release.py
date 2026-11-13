"""Install a frozen Web archive on the explicitly requested host and path."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import uuid


def switch_link(base, destination):
    temporary = base / ('current.' + uuid.uuid4().hex)
    temporary.symlink_to(destination)
    os.replace(temporary, base / 'current')


def main():
    archive, release, expected, configuration = sys.argv[1:]
    if not re.fullmatch(r'v\d+-[0-9a-f]{12}', release):
        raise ValueError('Invalid release name')
    if hashlib.sha256(Path(archive).read_bytes()).hexdigest() != expected:
        raise ValueError('Archive SHA256 mismatch')
    base = Path('/var/www/smash.xedoc.ru')
    if base.resolve() != base or not base.is_dir():
        raise ValueError('Unexpected deployment root')
    current = base / 'current'
    if current.exists() and not current.is_symlink():
        raise ValueError('Current is not a managed symlink')
    previous = str(current.resolve()) if current.is_symlink() else None
    target = base / 'releases' / release
    target.mkdir(mode=0o755)
    with tarfile.open(archive) as package:
        package.extractall(target, filter='data')
    manifest = json.loads((target / 'release-manifest.json').read_text())
    for name, digest in manifest.items():
        path = target / name
        if not path.resolve().is_relative_to(target) or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise ValueError('File SHA256 mismatch: ' + name)
    for path in target.rglob('*'):
        path.chmod(0o755 if path.is_dir() else 0o644)
    subprocess.run(['php', '-l', str(target / 'api/scores.php')], check=True)
    site = Path('/etc/nginx/sites-available/smash.xedoc.ru.conf')
    backup = base / ('nginx-before-' + release + '.conf')
    shutil.copy2(site, backup)
    switch_link(base, target)
    shutil.copy2(configuration, site)
    try:
        subprocess.run(['nginx', '-t'], check=True, capture_output=True)
        subprocess.run(['systemctl', 'reload', 'nginx'], check=True)
    except subprocess.CalledProcessError:
        shutil.copy2(backup, site)
        if previous:
            switch_link(base, previous)
        else:
            current.unlink()
        subprocess.run(['nginx', '-t'], check=True, capture_output=True)
        subprocess.run(['systemctl', 'reload', 'nginx'], check=True)
        raise
    record = {'release': release, 'archive_sha256': expected, 'files_verified': len(manifest),
              'current': str(target), 'previous': previous, 'domain': 'https://smash.xedoc.ru'}
    (base / ('deployment-' + release + '.json')).write_text(json.dumps(record, indent=2))
    print(json.dumps(record))


if __name__ == '__main__':
    main()
