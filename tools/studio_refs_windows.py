"""Run the unmodified studioigor reference collector on Windows."""
from pathlib import Path
import os
import runpy
import sys

if os.name == "nt":
    import msvcrt
    import time
    import types

    shim = types.ModuleType("fcntl")
    shim.LOCK_EX = 2

    def flock(file, operation):
        if operation != shim.LOCK_EX:
            raise ValueError("Only exclusive locks are used by refs.py")
        file.seek(0)
        deadline = time.monotonic() + 60
        while True:
            try:
                msvcrt.locking(file.fileno(), msvcrt.LK_NBLCK, 1)
                return
            except OSError:
                if time.monotonic() >= deadline:
                    raise
                time.sleep(0.05)

    shim.flock = flock
    sys.modules["fcntl"] = shim

script = Path.home() / ".codex/skills/studioigor/scripts/refs.py"
sys.argv[0] = str(script)
runpy.run_path(str(script), run_name="__main__")
