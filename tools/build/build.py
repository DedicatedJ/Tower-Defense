#!/usr/bin/env python3
"""Build a release of the game.

    python tools/build/build.py                 build dist/TowerDefense.love
    python tools/build/build.py --windows       also dist/TowerDefense-win64.zip
    python tools/build/build.py --verify        then run the smoke suite on the
                                                packaged files

The .love holds only what the game loads (code, data, art, sounds, fonts and
the HUMP library); the art pipeline, tools, tests and unused libraries stay
out. The Windows zip is LOVE's own love.exe with the .love fused onto it
(the standard way to ship a LOVE game), plus LOVE's DLLs and license.

--love-dir   folder with love.exe, lovec.exe and the DLLs
             (default: C:\\Program Files\\LOVE)
--verify     unpacks the .love into a temp folder, swaps in the smoke test
             harness as main.lua and runs it with lovec, so a file the game
             needs but the package lacks fails the build
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DIST = os.path.join(ROOT, "dist")
NAME = "TowerDefense"

# What the game loads at run time
INCLUDE = ["main.lua", "conf.lua", "data", "states", "systems", "utils", "libs/hump",
           "sprites", "assets", "sounds", "fonts"]
SKIP_DIRS = {".git", "__pycache__"}


def collect():
    files = []
    for item in INCLUDE:
        path = os.path.join(ROOT, item)
        if os.path.isfile(path):
            files.append(item)
            continue
        if not os.path.isdir(path):
            sys.exit("missing: " + item)
        for base, dirs, names in os.walk(path):
            dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
            for n in sorted(names):
                full = os.path.join(base, n)
                files.append(os.path.relpath(full, ROOT).replace(os.sep, "/"))
    return files


def build_love():
    os.makedirs(DIST, exist_ok=True)
    out = os.path.join(DIST, NAME + ".love")
    files = collect()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in files:
            z.write(os.path.join(ROOT, f), f)
    print("wrote %s (%d files, %.1f MB)" % (out, len(files), os.path.getsize(out) / 1e6))
    return out


def build_windows(love_file, love_dir):
    exe = os.path.join(love_dir, "love.exe")
    if not os.path.isfile(exe):
        sys.exit("love.exe not found in " + love_dir + " (use --love-dir)")
    stage = os.path.join(DIST, NAME + "-win64")
    if os.path.isdir(stage):
        shutil.rmtree(stage)
    os.makedirs(stage)
    # Fused executable: love.exe followed by the .love archive
    with open(os.path.join(stage, NAME + ".exe"), "wb") as out:
        for part in (exe, love_file):
            with open(part, "rb") as f:
                shutil.copyfileobj(f, out)
    for n in sorted(os.listdir(love_dir)):
        if n.lower().endswith(".dll"):
            shutil.copy2(os.path.join(love_dir, n), stage)
    if os.path.isfile(os.path.join(love_dir, "license.txt")):
        shutil.copy2(os.path.join(love_dir, "license.txt"), os.path.join(stage, "LOVE-license.txt"))
    zip_path = shutil.make_archive(stage, "zip", DIST, NAME + "-win64")
    print("wrote %s (%.1f MB)" % (zip_path, os.path.getsize(zip_path) / 1e6))
    return zip_path


def verify(love_file, love_dir):
    lovec = shutil.which("lovec") or os.path.join(love_dir, "lovec.exe")
    if not os.path.isfile(lovec) and not shutil.which("love"):
        sys.exit("no lovec/love to verify with")
    if not os.path.isfile(lovec):
        lovec = shutil.which("love")
    tmp = tempfile.mkdtemp(prefix="td-release-")
    try:
        with zipfile.ZipFile(love_file) as z:
            z.extractall(tmp)
        os.replace(os.path.join(tmp, "main.lua"), os.path.join(tmp, "game_main.lua"))
        shutil.copy2(os.path.join(ROOT, "tests", "smoke", "main.lua"), os.path.join(tmp, "main.lua"))
        print("verifying the packaged files with the smoke suite ...")
        proc = subprocess.run([lovec, tmp], capture_output=True, text=True, timeout=900)
        lines = [l for l in proc.stdout.splitlines() if "[SMOKE]" in l]
        for l in lines:
            if " FAIL " in l or "CRASH" in l:
                print(l)
        print(lines[-1] if lines else proc.stdout[-2000:])
        if proc.returncode != 0:
            sys.exit("the packaged game failed the smoke suite (exit %d)" % proc.returncode)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description="Build a release of the game")
    ap.add_argument("--windows", action="store_true", help="also build the Windows zip")
    ap.add_argument("--verify", action="store_true", help="run the smoke suite on the packaged files")
    ap.add_argument("--love-dir", default=r"C:\Program Files\LOVE", help="LOVE install folder")
    args = ap.parse_args()
    love_file = build_love()
    if args.windows:
        build_windows(love_file, args.love_dir)
    if args.verify:
        verify(love_file, args.love_dir)


if __name__ == "__main__":
    main()
