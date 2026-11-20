# Tower Defense Game

A Tower Defense game built with Lua and the LÖVE framework, featuring a faction system, hero powers, and prestige mechanics.

## Features

- **Faction System**: Choose from three unique factions with distinct playstyles
  - Radiant Order: Holy warriors with defensive and healing abilities
  - Shadow Covenant: Dark magic users with crowd control and damage over time
  - Twilight Balance: Hybrid faction with versatile abilities

- **Hero System**: Each faction has two unique heroes with special abilities
  - Level up heroes through combat
  - Unlock and upgrade abilities
  - Passive bonuses for towers

- **Tower Types**:
  - Base towers (Arrow, Cannon, Magic)
  - Faction-specific towers
  - Upgrade paths and synergies

- **Enemy System**:
  - Multiple enemy types (Ground/Air, Melee/Ranged/Magic)
  - Wave-based progression
  - Boss encounters
  - Dynamic scaling

- **Game Progression**:
  - Multiple areas with unique maps
  - Prestige system for increased challenge
  - Unlockable content and upgrades

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- Game assets created by [Your Name/Team]
- Sound effects from [Source]
- Music from [Source]
- Built with LÖVE framework 