# Tower Defense Game

A Tower Defense game built with Lua and the LÖVE framework: three factions, heroes that fight on the road, and a campaign of 9 levels.

## Features

- **Three factions** (Radiant Order, Shadow Covenant, Twilight Balance), each with a faction bonus, 3 towers and 3 heroes. All content is data in `data/factions.lua`.
- **Towers** with their own behavior (healing, burn, poison, crits and marks, summoning, converting the dead, life drain, light/dark hybrid damage, burn/freeze) and 2 upgrades each, bought in game. Sell for 70%.
- **Heroes** that hold the road and block enemies, walk to any road cell you click, auto-cast 3 abilities (Q/W/E to cast early), and level up to 10. Levels save to your profile.
- **Levels**: 3 per faction, unlocked in order, with up to 3 stars each. Maps have one or two roads, rock areas you cannot build on, and portals (`data/levels.lua`).
- **Waves** built from a difficulty curve per level: more and tougher enemies each wave, necromancers that raise skeletons, dragons that fly over your blockers as bosses, bonus gold for each wave cleared, and extra gold for calling the next wave early (`systems/wave.lua`).
- **Profiles**: 5 save slots, each keeping its faction, hero levels, shop gold and items, level stars and achievements. Continue opens the one you used last.
- **Shop**: gold earned in games buys permanent hero and tower boosts and one-use consumables.
- **Achievements**: 8, tracked across games and shown in the hub.
- **Feedback**: damage numbers, kill effects, gold popups, and a red flash when a life is lost; an end screen with the game's stats.
- **Sound**: every tower shot, hit, kill, build, sale, upgrade, wave, ability, level up, purchase, win and loss has a sound, with menu and battle music (`systems/audio.lua`). A missing sound falls back to the closest one that exists, and a new file in `sounds/sfx/` takes over by name. Volumes save with the settings.
- **First-time hints** on each faction's first level (turn off with Settings > Show Tutorial), and a How to Play screen.

## Controls

| Action | Mouse | Keys |
|---|---|---|
| Pick a tower to build | Click it on the right | 1, 2, 3 |
| Place it | Click open ground near the road | |
| Upgrade or sell a tower | Click the tower, then the strip under the map | |
| Start the next wave, or call it early | Start Wave button | Space |
| Move the hero | Click the hero, then a road cell | |
| Cast an ability early | Ability buttons | Q, W, E |
| Freeze Potion (from the shop) | | F |
| Game speed 1x / 2x / 3x | Speed button | Tab |
| Drop the current selection | Right click | Esc |
| Pause | | Esc (with nothing selected), P |
| Fullscreen | | F11 |

## Requirements

- [LÖVE](https://love2d.org/) 11.4 or newer (tested on 11.5)
- HUMP (gamestate and timer), included as a git submodule in `libs/hump`

## Installation

1. Install LÖVE from [love2d.org](https://love2d.org/).
2. Clone this repository with its submodules:
   ```bash
   git clone --recursive https://github.com/DedicatedJ/Tower-Defense.git
   ```
   In an existing clone: `git submodule update --init`.

## Running the Game

From the project folder:

```bash
love .
```

On Windows, if `love` is not on your PATH:

```powershell
& "C:\Program Files\LOVE\love.exe" .
```

The game is laid out for 1024 x 768 and scales to any window size or to fullscreen (F11), with bars where the screen shape differs.

Saves (profiles and settings) go to LÖVE's save folder for the `tower-defense` identity, for example `%APPDATA%\LOVE\tower-defense` on Windows.

## Project Structure

```
Tower-Defense/
├── main.lua, conf.lua     LÖVE entry point and window settings
├── data/                  game content as plain data
│   ├── factions.lua       factions, towers, heroes, abilities
│   ├── levels.lua         the 9 levels: roads, rocks, waves, gold, lives
│   ├── achievements.lua
│   └── shop_items.lua
├── systems/               game logic
│   ├── tower.lua, enemy.lua, unit.lua (heroes, minions), effects.lua
│   ├── level.lua, wave.lua
│   ├── save.lua, achievements.lua, audio.lua, fx.lua
├── states/                screens (menu, profiles, faction and hero select,
│                          hub, level select, game, pause, shop, settings ...)
├── utils/                 screen scaling, errors, JSON, selection helpers
├── sprites/, assets/      art used by the game (towers, enemies, maps, UI,
│                          hero portraits, backgrounds)
├── sounds/                sfx/ and Music/
├── fonts/
├── art/                   art pipeline: prompts, layout guides, manifest
├── tools/                 artkit (prompt pack) and artcut (cut and align art)
├── tests/                 unit, smoke and balance suites
└── libs/                  submodules (HUMP)
```

## Development

### Adding content

- **A tower or hero:** add it to its faction in `data/factions.lua`. Its art is picked up by name from `sprites/towers/<id>.png` or `sprites/heroes/<id>.png`.
- **A level:** add it to `data/levels.lua` (waypoints, rocks, waves). A painted map at `sprites/maps/<level id>.png` replaces the generated ground. Check the difficulty with `tests/run.sh balance`.
- **Art:** see `art/README.md`. `tools/artkit` writes the prompt pack and layout guides; `tools/artcut` cuts and aligns what comes back.

### Code Standards

- camelCase for variables and functions, PascalCase for module tables
- Prefer locals and modules over globals (the game still has a few: `gameState`, `fonts`, `playSound`)
- Keep content in `data/` and behavior in `systems/`

### Tests

The suites run the game's code under LÖVE 11.5 in a throwaway copy of the repo, with their own save folders (your saves are never touched). From Git Bash:

```bash
tests/run.sh          # unit, then smoke
tests/run.sh unit     # logic checks with exact expected values, a few seconds
tests/run.sh smoke    # drives the real game: every screen, tower, hero and level
```

Set `LOVEC` if `lovec.exe` is not at `C:\Program Files\LOVE\lovec.exe`. Exit code 0 = all passed, 1 = a check failed, 2 = crash.

Balance read-out (not run by default): a simple AI plays every level with that level's starting gold and prints the result, lives lost per wave and towers built. Use it after changing `data/levels.lua`, `systems/wave.lua` or tower stats.

```bash
tests/run.sh balance
BALANCE_LEVEL=necropolis tests/run.sh balance
```

### Building a release

```bash
python tools/build/build.py --windows --verify
```

This writes `dist/TowerDefense.love` (runs anywhere LÖVE 11.4+ is installed) and `dist/TowerDefense-win64.zip` (unzip and run `TowerDefense.exe`; no install needed). `--verify` runs the smoke suite on the packaged files, so a missing asset fails the build. Use `--love-dir` if LÖVE is not in `C:\Program Files\LOVE`. The package includes only what the game loads: code, data, art, sounds, fonts and HUMP.

### Browser build

```bash
python tools/build/build.py --web
cd dist/web && python -m http.server 8000
```

This writes `dist/web/`: a page that runs the game in the browser with [love.js](https://github.com/Davidobot/love.js) (LÖVE 11.4 compiled to WebAssembly, MIT; downloaded once and checked against its published hash), plus the game's files. Open `http://localhost:8000`; opening the file directly does not work. Profiles and settings save in the browser. The browser runs Lua 5.1 rather than LuaJIT, so the game code avoids `goto`, and images use `utils/image.lua`, which skips mipmaps where WebGL 1 cannot make them.

## License

No license has been chosen yet, so all rights are reserved by default. See `BLOCKED.md`.

## Credits

Built with [LÖVE](https://love2d.org/) and [HUMP](https://github.com/vrld/hump). Full credits are coming (see `BLOCKED.md`).
