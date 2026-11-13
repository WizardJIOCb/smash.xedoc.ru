"""Fetch pinned official engine/addon artifacts and web-only export templates."""
from pathlib import Path
import hashlib
import io
import json
import shutil
import sys
import urllib.request
import zipfile

from remotezip import RemoteFetcher, RemoteZip

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = ROOT / ".tools/downloads"
DOWNLOADS.mkdir(parents=True, exist_ok=True)
RELEASE = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/"


class TemplateFetcher(RemoteFetcher):
    def get_file_size(self):
        # Pinned official GitHub release metadata. requests.head does not follow
        # the release redirect, otherwise the suffix fallback computes an empty range.
        return 1281349702


def fetch(url: str, filename: str) -> Path:
    target = DOWNLOADS / filename
    if not target.exists():
        print(f"Downloading {filename}", flush=True)
        request = urllib.request.Request(url, headers={"User-Agent": "los-firewall-setup"})
        with urllib.request.urlopen(request, timeout=60) as response, target.open("wb") as out:
            shutil.copyfileobj(response, out, 1024 * 1024)
    return target


def install_engine() -> None:
    filename = "Godot_v4.7.2-stable_win64.exe.zip"
    archive = fetch(RELEASE + filename, filename)
    sums = fetch(RELEASE + "SHA512-SUMS.txt", "godot-4.7.2-SHA512-SUMS.txt").read_text()
    wanted = next(line.split()[0] for line in sums.splitlines() if line.split()[-1].lstrip("*") == filename)
    actual = hashlib.sha512(archive.read_bytes()).hexdigest()
    if wanted != actual:
        raise RuntimeError("Godot archive SHA512 mismatch")
    dest = ROOT / ".tools/godot"
    dest.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as package:
        for member in package.infolist():
            if Path(member.filename).name != member.filename:
                raise RuntimeError("Unexpected nested engine archive path")
            package.extract(member, dest)
    print("Official engine SHA512 verified; extracted to .tools/godot", flush=True)


def install_templates() -> None:
    import os
    dest = Path(os.environ["APPDATA"]) / "Godot/export_templates/4.7.2.stable"
    dest.mkdir(parents=True, exist_ok=True)
    url = RELEASE + "Godot_v4.7.2-stable_export_templates.tpz"
    print("Reading remote template ZIP directory; extracting web targets only", flush=True)
    with RemoteZip(url, fetcher=TemplateFetcher, support_suffix_range=False) as package:
        selected = [m for m in package.infolist() if
                    m.filename == "templates/version.txt" or
                    (m.filename.startswith("templates/") and Path(m.filename).name.startswith("web") and m.filename.endswith(".zip"))]
        if not any(Path(m.filename).name.startswith("web") for m in selected):
            raise RuntimeError("No web templates in official archive")
        for member in selected:
            target = dest / Path(member.filename).name
            if target.exists() and target.stat().st_size == member.file_size:
                print(f"Already present: {target.name}", flush=True)
                continue
            print(f"Extracting {member.filename}: {member.file_size / 1024**2:.1f} MiB", flush=True)
            with package.open(member) as source, target.open("wb") as out:
                shutil.copyfileobj(source, out, 1024 * 1024)
    print(f"Web templates installed: {dest}", flush=True)


def install_addons() -> None:
    addon_url = "https://github.com/hi-godot/godot-ai/releases/download/v4.4.1/"
    archive = fetch(addon_url + "godot-ai-plugin.zip", "godot-ai-4.4.1.zip")
    digest = fetch(addon_url + "godot-ai-plugin.zip.sha256", "godot-ai-4.4.1.sha256").read_text().split()[0]
    if hashlib.sha256(archive.read_bytes()).hexdigest() != digest:
        raise RuntimeError("Godot AI SHA256 mismatch")
    # The convenience release is a migration bootstrap, not the active v4 tree.
    with zipfile.ZipFile(archive) as bootstrap:
        manifest_name = "addons/godot_ai/migration_payload/godot-ai-v4-plugin.manifest.json"
        payload_name = "addons/godot_ai/migration_payload/godot-ai-v4-plugin.zip"
        manifest = json.loads(bootstrap.read(manifest_name))
        payload = bootstrap.read(payload_name)
    if hashlib.sha256(payload).hexdigest() != manifest["asset"]["sha256"]:
        raise RuntimeError("Godot AI v4 payload mismatch")
    with zipfile.ZipFile(io.BytesIO(payload)) as package:
        for record in manifest["inventory"]:
            if hashlib.sha256(package.read(record["path"])).hexdigest() != record["sha256"]:
                raise RuntimeError("Godot AI inventory mismatch")
    v4_archive = DOWNLOADS / "godot-ai-4.4.1-exact-tree.zip"
    v4_archive.write_bytes(payload)
    gut = fetch("https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip", "gut-9.7.1.zip")
    for package_path, marker in [(v4_archive, "addons/godot_ai/"), (gut, "addons/gut/")]:
        existing = ROOT / marker / "plugin.cfg"
        if existing.is_file():
            expected = "4.4.1" if "godot_ai" in marker else "9.7.1"
            if expected not in existing.read_text(encoding="utf-8"):
                raise RuntimeError("Existing addon differs; preserve it before replacing")
            print(f"Already installed: {marker}", flush=True)
            continue
        count = 0
        with zipfile.ZipFile(package_path) as package:
            for member in package.infolist():
                if marker not in member.filename or member.is_dir():
                    continue
                relative = member.filename[member.filename.index(marker):]
                target = (ROOT / relative).resolve()
                if not target.is_relative_to(ROOT):
                    raise RuntimeError("Addon path escapes project")
                target.parent.mkdir(parents=True, exist_ok=True)
                with package.open(member) as source, target.open("wb") as out:
                    shutil.copyfileobj(source, out)
                count += 1
        print(f"Installed {marker}: {count} files", flush=True)


if __name__ == "__main__":
    {"engine": install_engine, "templates": install_templates, "addons": install_addons}[sys.argv[1]]()
