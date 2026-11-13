"""Project-specific native Windows checks; upstream envcheck is macOS/Claude-specific."""
import json
import os
from pathlib import Path
import socket
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
engine = root / ".tools/godot/Godot_v4.7.2-stable_win64_console.exe"
templates = Path(os.environ["APPDATA"]) / "Godot/export_templates/4.7.2.stable"
checks = {}


def command(args):
    result = subprocess.run(args, cwd=root, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return result.returncode == 0, result.stdout.strip()


ok, version = command([str(engine), "--version"])
checks["Godot 4.7.2 native CLI"] = ok and version.startswith("4.7.2.stable")
checks["matching single-thread web export templates"] = (
    (templates / "version.txt").read_text().strip() == "4.7.2.stable"
    and (templates / "web_nothreads_release.zip").is_file()
)
checks["gdtoolkit"] = command([str(root / ".tools/python/Scripts/gdlint.exe"), "--version"])[0]
checks["GUT 9.7.1"] = '9.7.1' in (root / "addons/gut/plugin.cfg").read_text()
checks["git-lfs"] = command(["git", "lfs", "version"])[0]
checks["Godot AI 4.4.1 editor addon"] = '4.4.1' in (root / "addons/godot_ai/plugin.cfg").read_text()
probe = root / ".tools/mcp-probe-result.json"
if probe.is_file():
    result = json.loads(probe.read_text(encoding="utf-8"))
    checks["authenticated editor MCP read verified"] = (
        not result.get("is_error", result.get("isError", True))
        and "WebSetup" in probe.read_text(encoding="utf-8")
    )
else:
    checks["authenticated editor MCP read verified"] = False
try:
    with socket.create_connection(("127.0.0.1", 6005), timeout=1):
        checks["GDScript language server"] = True
except OSError:
    checks["GDScript language server"] = False
for name, passed in checks.items():
    print(("OK   " if passed else "FAIL ") + name)
sys.exit(0 if all(checks.values()) else 1)
