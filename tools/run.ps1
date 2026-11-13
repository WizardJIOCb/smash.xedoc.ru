param([ValidateSet('run', 'test', 'build', 'capture', 'editor')][string]$Action = 'run')
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$godotExecutable = Join-Path $taskRoot '.tools\godot\Godot_v4.7.2-stable_win64_console.exe'
Push-Location -LiteralPath $taskRoot
try {
    switch ($Action) {
        'run' { python -m http.server 8770 --bind 127.0.0.1 --directory build/web }
        'test' {
            & .\.tools\python\Scripts\gdformat.exe scripts tests --check
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            & .\.tools\python\Scripts\gdlint.exe scripts tests
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            & $godotExecutable --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
        }
        'build' {
            & $godotExecutable --headless --path . --export-release Web build/web/index.html
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            python tools/prepare_web_cache.py
        }
        'capture' {
            $captureProcess = Start-Process -FilePath $godotExecutable -ArgumentList '--path', '.',
                '--resolution', '1280x720', '--fixed-fps', '60', '--script', 'res://tools/capture.gd',
                '--', '--scene', 'res://scenes/gyms/attack_gym.tscn',
                '--out', '.studioigor/captures/fist-v16', '--duration', '6.5', '--every', '0.1',
                '--inputs', 'tools/inputs/fist_review.json' `
                -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru `
                -RedirectStandardOutput '.tools/capture-output.log' -RedirectStandardError '.tools/capture-error.log'
            $captureProcess.WaitForExit()
            Get-Content .tools/capture-output.log -Tail 2
            exit $captureProcess.ExitCode
        }
        'editor' {
            $env:GODOT_AI_DISABLE_TELEMETRY = 'true'
            $editorProcess = Start-Process -FilePath $godotExecutable -ArgumentList '--editor', '--path', '.' `
                -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru `
                -RedirectStandardOutput '.tools/editor-output.log' -RedirectStandardError '.tools/editor-error.log'
            $editorProcess.Id | Set-Content .tools/editor.pid
            'Started task editor PID ' + $editorProcess.Id
            exit 0
        }
    }
    exit $LASTEXITCODE
}
finally { Pop-Location }
