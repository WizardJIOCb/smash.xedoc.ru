"""Isolated integration test on the deployment host. Never writes public records."""
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def main():
    script = Path(sys.argv[1]).resolve()
    with tempfile.TemporaryDirectory(prefix='smash-api-test-') as directory:
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            port = listener.getsockname()[1]
        env = os.environ.copy()
        env['SMASH_STATE_DIR'] = directory
        server = subprocess.Popen(['php', '-S', f'127.0.0.1:{port}', '-t', str(script.parent)], env=env,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        url = f'http://127.0.0.1:{port}/{script.name}'

        def call(payload=None, content_type='application/json', origin=None):
            headers = {'Content-Type': content_type}
            if origin:
                headers['Origin'] = origin
            raw = None if payload is None else json.dumps(payload).encode()
            request = Request(url, data=raw, headers=headers)
            try:
                with urlopen(request, timeout=3) as response:
                    return response.status, json.load(response)
            except HTTPError as error:
                return error.code, json.load(error)

        try:
            for attempt in range(50):
                try:
                    code, response = call()
                    break
                except URLError:
                    time.sleep(0.05)
            else:
                raise RuntimeError('PHP test server failed to start')
            assert code == 200 and response['scores'] == []
            assert call({'op': 'start'}, 'text/plain')[0] == 415
            assert call({'op': 'start'}, origin='https://example.invalid')[0] == 403
            code, response = call({'op': 'start'}, origin='https://smash.xedoc.ru')
            assert code == 200 and len(response['token']) == 48
            token = response['token']
            result = {'op': 'finish', 'token': token, 'name': 'Лось QA <script>',
                      'seconds': 60, 'health': 82, 'deaths': 1, 'kills': 5, 'relays': 3}
            assert call(result)[0] == 422, 'Premature finish rejected'
            # Adjust only this isolated fixture's server clock; no public state is touched.
            state_path = Path(directory) / 'scores.json'
            state = json.loads(state_path.read_text())
            state['runs'][hashlib.sha256(token.encode()).hexdigest()]['started'] = time.time() - 65
            state_path.write_text(json.dumps(state))
            code, response = call(result)
            assert code == 200 and response['saved']
            assert response['scores'][0]['score'] == 8020
            assert '<' not in response['scores'][0]['name']
            assert call(result)[0] == 409, 'Token replay rejected'
            assert len(call()[1]['scores']) == 1, 'Record survives separate requests'
            for attempt in range(9):
                code, _ = call({'op': 'start'})
            assert code == 429, 'Run start rate limit enforced'
            print('scores API: 10 checks passed; isolated state; no public record created')
        finally:
            server.terminate()
            server.wait(timeout=5)


if __name__ == '__main__':
    main()
