# Tower Defense Game

A Tower Defense game built with Lua and the LÖVE framework: three factions, heroes that fight on the road, and a campaign of 9 levels.

## Features

- **Three factions** (Radiant Order, Shadow Covenant, Twilight Balance), each with a faction bonus, 3 towers and 3 heroes. All content is data in `data/factions.lua`.
- **Towers** with their own behavior (healing, burn, poison, crits and marks, summoning, converting the dead, life drain, light/dark hybrid damage, burn/freeze) and 2 upgrades each, bought in game. Sell for 70%.
- **Heroes** that hold the road and block enemies, walk to any road cell you click, auto-cast 3 abilities (Q/W/E to cast early), and level up to 10. Levels save to your profile.
- **Levels**: 3 per faction, unlocked in order, with up to 3 stars each. Maps have one or two roads, rock areas you cannot build on, and portals (`data/levels.lua`).
- **Waves** built from a difficulty curve per level: more and tougher enemies each wave, necromancers that raise skeletons, dragons that fly over your blockers as bosses, and bonus gold for each wave cleared (`systems/wave.lua`).
- **Shop**: gold earned in games buys permanent hero and tower boosts and one-use consumables.

## Dependencies

- LÖVE 11.4 or higher
- Jumper (for pathfinding)
- Bump.lua (for collision detection)
- STI (for map loading)
- HUMP (for state management and timers)
- LoveFrames (submodule, not used by the game yet)

## Installation

1. Install LÖVE framework from [love2d.org](https://love2d.org/)
2. Clone this repository
3. Fetch the libraries (git submodules):
   ```bash
   git submodule update --init
   ```
   Or clone with `git clone --recursive`.

## Project Structure

```
Tower Defense/
├── fonts/
│   ├── main.ttf
│   └── title.ttf
├── sounds/
│   ├── music/
│   │   ├── defeat.mp3
│   │   ├── game.mp3
│   │   ├── menu.mp3
│   │   └── victory.mp3
│   └── sfx/
│       ├── button_click.wav
│       ├── enemy_die.wav
│       └── ...
├── sprites/
│   ├── enemies/
│   │   ├── air/
│   │   └── ground/
│   └── ranged/
│       ├── magic/
│       └── melee/
├── states/
│   ├── splash.lua
│   ├── menu.lua
│   ├── faction_select.lua
│   ├── game.lua
│   └── pause.lua
├── libs/
│   ├── jumper/
│   ├── bump/
│   ├── sti/
│   ├── hump/
│   └── suite/
├── main.lua
└── README.md
```

## Running the Game

1. Navigate to the project directory
2. Run with LÖVE:
   ```bash
   love .
   ```

## Development

### Code Standards

- Use camelCase for variable and function names
- Use PascalCase for class-like tables
- Avoid global variables; use local variables or modules
- Follow LÖVE's coding style guidelines

### Adding New Features

1. Create new state files in the `states/` directory
2. Add new assets to appropriate directories
3. Update `main.lua` to include new states
4. Follow the existing code structure and naming conventions

### Tests

Both suites run the game's code under LÖVE 11.5 in a throwaway copy of the repo, with their own save folders (your saves are never touched). From Git Bash:

```bash
tests/run.sh          # unit, then smoke
tests/run.sh unit     # logic checks with exact expected values, a few seconds
tests/run.sh smoke    # drives the real game: menus, every tower and hero, 10 waves per faction
```

Set `LOVEC` if `lovec.exe` is not at `C:\Program Files\LOVE\lovec.exe`. Exit code 0 = all passed, 1 = a check failed, 2 = crash.

Balance read-out (not run by default): a simple AI plays every level with that level's starting gold and prints the result, lives lost per wave and towers built. Use it after changing `data/levels.lua`, `systems/wave.lua` or tower stats.

```bash
tests/run.sh balance
BALANCE_LEVEL=necropolis tests/run.sh balance
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- Game assets created by [Your Name/Team]
- Sound effects from [Source]
- Music from [Source]
- Built with LÖVE framework 