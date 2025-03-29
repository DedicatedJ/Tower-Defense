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
- SUITE (for UI)

## Installation

1. Install LÖVE framework from [love2d.org](https://love2d.org/)
2. Clone this repository
3. Install dependencies:
   ```bash
   git submodule add https://github.com/Yonaba/Jumper.git libs/jumper
   git submodule add https://github.com/kikito/bump.lua.git libs/bump
   git submodule add https://github.com/karai17/Simple-Tiled-Implementation.git libs/sti
   git submodule add https://github.com/vrld/hump.git libs/hump
   git submodule add https://github.com/pelevesque/suite.git libs/suite
   ```

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- Game assets created by [Your Name/Team]
- Sound effects from [Source]
- Music from [Source]
- Built with LÖVE framework 