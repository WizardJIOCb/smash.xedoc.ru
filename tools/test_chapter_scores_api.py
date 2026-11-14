"""Exercise the real PHP API in isolated disposable storage, never public scores."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def main():
    api = Path(sys.argv[1]).resolve()
    campaign_path = api.parent / 'chapters.json'
    if not campaign_path.exists():
        campaign_path = api.parents[2] / 'data/chapters.json'
    campaign = json.loads(campaign_path.read_text(encoding='utf-8'))
    with tempfile.TemporaryDirectory(prefix='smash-v28-api-qa-') as folder:
        root = Path(folder)
        shutil.copy2(api, root / 'scores.php')
        shutil.copy2(campaign_path, root / 'chapters.json')
        state_dir = root / 'state'
        state_dir.mkdir()
        state_path = state_dir / 'scores.json'
        legacy = {'name': 'legacy', 'score': 8000, 'seconds': 20, 'health': 100, 'date': '2026-11-14'}
        state_path.write_text(json.dumps({'runs': {}, 'scores': [legacy]}))
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        env = dict(os.environ, SMASH_STATE_DIR=str(state_dir))
        process = subprocess.Popen(['php', '-S', f'127.0.0.1:{port}', '-t', str(root)],
                                   env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        endpoint = f'http://127.0.0.1:{port}/scores.php'

        def call(payload=None, query=''):
            request = Request(endpoint + query, data=None if payload is None else json.dumps(payload).encode(),
                              headers={'Content-Type': 'application/json'})
            try:
                with urlopen(request, timeout=5) as response:
                    return response.status, json.load(response)
            except HTTPError as error:
                return error.code, json.load(error)

        try:
            for attempt in range(30):
                try:
                    assert call()[0] == 200
                    break
                except URLError:
                    time.sleep(.1)
            for entry in campaign:
                chapter, kills = entry['id'], entry['kills']
                status, result = call({'op': 'start', 'chapter': chapter})
                assert status == 200
                token = result['token']
                state = json.loads(state_path.read_text())
                state['runs'][hashlib.sha256(token.encode()).hexdigest()]['started'] -= 10
                state_path.write_text(json.dumps(state))
                payload = dict(op='finish', token=token, chapter=chapter, name='test', seconds=6,
                               health=80, deaths=0, kills=kills, relays=entry['end'] - entry['start'] + 1)
                assert call(dict(payload, chapter=1 if chapter != 1 else 2))[0] == 422
                assert call(dict(payload, kills=kills + 1))[0] == 422
                assert call(payload)[0] == 200
                assert call(payload)[0] == 409
                assert len(call(query=f'?chapter={chapter}')[1]['scores']) == (2 if chapter == 1 else 1)
            state = json.loads(state_path.read_text())
            assert legacy in state['scores']
            assert len(state['scores']) == len(campaign) + 1
            assert call(query='?chapter=999')[0] == 422
            print(f'PASS: {len(campaign)} chapter contracts, separate tables, legacy preservation, token binding/replay')
            print('Storage: disposable test directory only; production scores were never read or changed')
        finally:
            process.terminate()
            process.wait(timeout=5)


if __name__ == '__main__':
    main()
