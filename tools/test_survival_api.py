"""Exercise the casual survival API against disposable local state only."""
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
    script = Path(sys.argv[1] if len(sys.argv) > 1 else 'deploy/api/survival.php').resolve()
    php = os.environ.get('PHP_BIN') or shutil.which('php')
    if not php:
        raise RuntimeError('PHP CLI required; set PHP_BIN')
    subprocess.run([php, '-l', str(script)], check=True)
    with tempfile.TemporaryDirectory(prefix='smash-survival-test-') as directory:
        state_path = Path(directory) / 'survival.json'
        campaign_path = Path(directory) / 'scores.json'
        campaign_path.write_text('{"campaign_sentinel":true}')
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            port = listener.getsockname()[1]
        env = dict(os.environ, SMASH_STATE_DIR=directory)
        server = subprocess.Popen([php, '-S', f'127.0.0.1:{port}', '-t', str(script.parent)], env=env,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        url = f'http://127.0.0.1:{port}/{script.name}'

        def call(payload=None, board='solo', content_type='application/json', origin=None, raw=None, method=None):
            headers = {'Content-Type': content_type}
            if origin:
                headers['Origin'] = origin
            data = raw if raw is not None else (None if payload is None else json.dumps(payload).encode())
            request = Request(url + '?board=' + board, data=data, headers=headers, method=method)
            try:
                with urlopen(request, timeout=3) as response:
                    return response.status, json.load(response)
            except HTTPError as error:
                return error.code, json.load(error)

        def read_state():
            return json.loads(state_path.read_text(encoding='utf-8'))

        def write_state(state):
            state_path.write_text(json.dumps(state), encoding='utf-8')

        def start(board='solo', players=1):
            code, response = call({'op': 'start', 'board': board, 'players': players})
            assert code == 200, response
            return response['token']

        def age(token, seconds=65):
            state = read_state()
            state['runs'][hashlib.sha256(token.encode()).hexdigest()]['started'] = time.time() - seconds
            write_state(state)

        def result(token, **overrides):
            return dict({'op': 'finish', 'token': token, 'board': 'solo', 'players': 1,
                         'name': 'Лось <script>😀', 'wave': 3, 'kills': 7, 'seconds': 60}, **overrides)

        try:
            for _ in range(50):
                try:
                    code, response = call()
                    break
                except URLError:
                    time.sleep(0.05)
            else:
                raise RuntimeError('PHP test server failed to start')
            assert code == 200 and response == {'board': 'solo', 'scores': []}
            assert call(board='coop')[1]['scores'] == []
            assert call(board='campaign')[0] == 422
            assert call(method='DELETE')[0] == 405
            base = {'op': 'start', 'board': 'solo', 'players': 1}
            assert call(base, content_type='text/plain')[0] == 415
            assert call(base, content_type='application/json-bad')[0] == 415
            assert call(base, origin='https://example.invalid')[0] == 403
            assert call(raw=b'{bad')[0] == 400
            assert call(raw=b'[]')[0] == 400
            assert call(raw=b' ' * 4097)[0] == 413
            for board, players in [('solo', 2), ('coop', 1), ('coop', 17), ('solo', True), ('solo', '1')]:
                assert call(dict(base, board=board, players=players))[0] == 422
            token = start()
            assert len(token) == 48
            assert call(result(token))[0] == 422, 'Premature finish rejected'
            age(token)
            for invalid in [{'board': 'coop', 'players': 2}, {'wave': '3'}, {'wave': True},
                            {'wave': 0}, {'wave': 10001}, {'kills': 1}, {'kills': 1000001},
                            {'seconds': '60'}, {'seconds': 4.99}, {'seconds': 86401}, {'name': []}]:
                assert call(result(token, **invalid))[0] == 422, invalid
            code, response = call(result(token), origin='https://smash.xedoc.ru')
            assert code == 200 and response['saved']
            row = response['scores'][0]
            assert row['wave'] == 3 and row['kills'] == 7 and row['seconds'] == 60
            assert row['name'] == 'Лось script'
            assert call(result(token))[0] == 409, 'One-use token replay rejected'
            coop = start('coop', 16)
            age(coop)
            assert call(result(coop, board='coop', players=2))[0] == 422, 'Party bound to token'
            assert call(result(coop, board='coop', players=16, wave=9, kills=50))[0] == 200
            assert call()[1]['scores'][0]['wave'] == 3
            assert call(board='coop')[1]['scores'][0]['players'] == 16
            expired = start()
            age(expired, 86401)
            assert call(result(expired))[0] == 409, '24h expiry'
            valid = start()
            age(valid, 86399)
            assert call(result(valid, seconds=86390))[0] == 200, 'Long survival accepted'
            # Seed disposable history, then submit through HTTP to test retention and all tie breakers.
            state = read_state()
            state['scores'] = [dict(row, board=group, players=1 if group == 'solo' else 2,
                                    wave=wave, kills=wave, seconds=60)
                               for group in ['solo', 'coop'] for wave in range(1, 53)]
            state['scores'] += [dict(row, wave=100, kills=100, seconds=30),
                                dict(row, wave=100, kills=101, seconds=40)]
            write_state(state)
            best = start()
            age(best)
            code, response = call(result(best, wave=100, kills=101, seconds=20))
            assert code == 200 and len(response['scores']) == 10
            assert [(x['kills'], x['seconds']) for x in response['scores'][:3]] == [(101, 20), (101, 40), (100, 30)]
            state = read_state()
            assert len([x for x in state['scores'] if x['board'] == 'solo']) == 50
            assert len([x for x in state['scores'] if x['board'] == 'coop']) == 50
            assert len(call(board='coop')[1]['scores']) == 10
            # Start/finish cycling does not evade the eight-starts/IP/minute budget.
            state['runs'] = {}
            write_state(state)
            for _ in range(8):
                recent = start()
                age(recent, 3)
                assert call(result(recent, wave=1, kills=0, seconds=5))[0] == 200
            assert call(base)[0] == 429
            assert campaign_path.read_text() == '{"campaign_sentinel":true}'
            print('survival API: isolation, ranking, caps, token binding/replay/expiry, rate and validation passed')
        finally:
            server.terminate()
            server.wait(timeout=5)


if __name__ == '__main__':
    main()
