"""Activate an isolated, hash-verified cooperative build alongside the main campaign."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile


def main():
    archive, release, digest = sys.argv[1:]
    if not re.fullmatch(r'v\d+-[a-f0-9]{12}', release):
        raise ValueError('Invalid release name')
    if hashlib.sha256(Path(archive).read_bytes()).hexdigest() != digest:
        raise ValueError('Archive digest mismatch')
    base = Path('/var/www/smash.xedoc.ru')
    destination = base / 'coop-releases' / release
    destination.mkdir(parents=True, exist_ok=False)
    with tarfile.open(archive) as package:
        package.extractall(destination, filter='data')
    hashes = json.loads((destination / 'release-manifest.json').read_text())
    for name, expected in hashes.items():
        path = destination / name
        if not path.resolve().is_relative_to(destination) or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise ValueError('File verification failed: ' + name)
    for path in destination.rglob('*'):
        path.chmod(0o755 if path.is_dir() else 0o644)
    subprocess.run(['php', '-l', str(destination / 'api/scores.php')], check=True)
    current = base / 'coop-current'
    previous = str(current.resolve()) if current.exists() else None
    link = base / 'coop-candidate'
    link.symlink_to(destination)
    site = Path('/etc/nginx/sites-available/smash.xedoc.ru.conf')
    old_config = site.read_text()
    backup = base / ('nginx-before-coop-' + release + '.conf')
    shutil.copy2(site, backup)
    marker = '    include /etc/nginx/snippets/smash-coop.conf;'
    config = old_config
    if marker not in config:
        config = config.replace('    gzip_static on;', '    gzip_static on;\n' + marker)
        if marker not in config:
            raise RuntimeError('Expected vhost anchor missing')
    site.write_text(config)
    try:
        subprocess.run(['nginx', '-t'], check=True)
        os.replace(link, current)
        subprocess.run(['systemctl', 'reload', 'nginx'], check=True)
    except Exception:
        site.write_text(old_config)
        if previous:
            rollback = base / 'coop-rollback'
            rollback.symlink_to(previous)
            os.replace(rollback, current)
        subprocess.run(['nginx', '-t'], check=True)
        subprocess.run(['systemctl', 'reload', 'nginx'], check=True)
        raise
    receipt = {'release': release, 'files': len(hashes), 'previous': previous,
               'url': 'https://smash.xedoc.ru/coop-game/', 'sha256': digest}
    (base / ('coop-deployment-' + release + '.json')).write_text(json.dumps(receipt, indent=2))
    print(json.dumps(receipt))


if __name__ == '__main__':
    main()
