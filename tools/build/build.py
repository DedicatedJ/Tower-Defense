#!/usr/bin/env python3
"""Build a release of the game.

    python tools/build/build.py                 build dist/TowerDefense.love
    python tools/build/build.py --windows       also dist/TowerDefense-win64.zip
    python tools/build/build.py --verify        then run the smoke suite on the
                                                packaged files
    python tools/build/build.py --web           also dist/web/, a page that runs
                                                the game in a browser

The .love holds only what the game loads (code, data, art, sounds, fonts and
the HUMP library); the art pipeline, tools, tests and unused libraries stay
out. The Windows zip is LOVE's own love.exe with the .love fused onto it
(the standard way to ship a LOVE game), plus LOVE's DLLs and license.

--love-dir   folder with love.exe, lovec.exe and the DLLs
             (default: C:\\Program Files\\LOVE)
--verify     unpacks the .love into a temp folder, swaps in the smoke test
             harness as main.lua and runs it with lovec, so a file the game
             needs but the package lacks fails the build
--web        writes dist/web/: index.html (from tools/build/web/index.html),
             love.js and love.wasm (LOVE 11.4 compiled to WebAssembly, from
             the love.js npm package, MIT; downloaded once into dist/.cache
             and checked against its published SHA-1), the game's files
             under game/ and their list in game.json. Loose files rather
             than one archive, so every file is a plain web type (.lua goes
             as text). Serve the folder over http (python -m http.server);
             file:// does not work. The browser runs Lua 5.1, not LuaJIT:
             no goto, and the unit suite checks images load without
             mipmaps where WebGL 1 cannot make them.
"""

import hashlib
import io
import json
import tarfile
import urllib.request

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


LOVEJS_VERSION = "11.4.1"
LOVEJS_URL = "https://registry.npmjs.org/love.js/-/love.js-%s.tgz" % LOVEJS_VERSION
LOVEJS_SHA1 = "4b3772a53713c2404b760ae794562d8a72d457ec"  # npm dist.shasum
# File types the browser build ships; anything else in the package (the
# HUMP library's docs and repo files) the game never loads
WEB_EXTENSIONS = {".lua", ".png", ".jpg", ".jpeg", ".mp3", ".wav", ".ogg", ".ttf", ".otf"}
WEB_SKIP_PREFIXES = ("libs/hump/docs/", "libs/hump/spec/")


def lovejs_runtime():
    """The love.js npm package (cached), checked against its SHA-1."""
    cache = os.path.join(DIST, ".cache")
    os.makedirs(cache, exist_ok=True)
    tgz = os.path.join(cache, "love.js-%s.tgz" % LOVEJS_VERSION)
    if not os.path.isfile(tgz):
        print("downloading " + LOVEJS_URL)
        with urllib.request.urlopen(LOVEJS_URL, timeout=120) as r:
            data = r.read()
        with open(tgz, "wb") as f:
            f.write(data)
    with open(tgz, "rb") as f:
        data = f.read()
    if hashlib.sha1(data).hexdigest() != LOVEJS_SHA1:
        os.remove(tgz)
        sys.exit("love.js download does not match its published SHA-1; removed it")
    files = {}
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as t:
        for name in ("package/src/compat/love.js", "package/src/compat/love.wasm", "package/LICENSE"):
            files[name.rsplit("/", 1)[1]] = t.extractfile(name).read()
    return files


def build_web():
    out = os.path.join(DIST, "web")
    os.makedirs(out, exist_ok=True)
    for n in os.listdir(out):  # empty it (a local server may be running in it)
        p = os.path.join(out, n)
        shutil.rmtree(p) if os.path.isdir(p) else os.remove(p)
    runtime = lovejs_runtime()
    for name, data in (("love.js", runtime["love.js"]), ("love.wasm", runtime["love.wasm"]),
                       ("LOVEJS-LICENSE.txt", runtime["LICENSE"])):
        with open(os.path.join(out, name), "wb") as f:
            f.write(data)
    listing, skipped = [], 0
    for rel in collect():
        if (os.path.splitext(rel)[1].lower() not in WEB_EXTENSIONS
                or rel.startswith(WEB_SKIP_PREFIXES)):
            skipped += 1
            continue
        dest = os.path.join(out, "game", rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copyfile(os.path.join(ROOT, rel), dest)
        listing.append([rel, os.path.getsize(dest)])
    with open(os.path.join(out, "game.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(listing, f, separators=(",", ":"))
    total = sum(size for _, size in listing)
    with open(os.path.join(ROOT, "tools", "build", "web", "index.html"), encoding="utf-8") as f:
        page = f.read().replace("__SIZE__", "%.0f" % (total / 1e6))
    with open(os.path.join(out, "index.html"), "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    print("wrote %s (index.html, love.js, love.wasm, %d game files, %.1f MB; skipped %d non-game files)" % (
        out, len(listing), total / 1e6, skipped))
    return out


def main():
    ap = argparse.ArgumentParser(description="Build a release of the game")
    ap.add_argument("--windows", action="store_true", help="also build the Windows zip")
    ap.add_argument("--verify", action="store_true", help="run the smoke suite on the packaged files")
    ap.add_argument("--web", action="store_true", help="also build dist/web, the browser version")
    ap.add_argument("--love-dir", default=r"C:\Program Files\LOVE", help="LOVE install folder")
    args = ap.parse_args()
    love_file = build_love()
    if args.windows:
        build_windows(love_file, args.love_dir)
    if args.web:
        build_web()
    if args.verify:
        verify(love_file, args.love_dir)


if __name__ == "__main__":
    main()
