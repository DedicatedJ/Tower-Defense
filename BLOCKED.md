# Blocked: needs the owner

Items that need your action before they can be finished. The rest of the plan carries on without them.
Plan steps refer to the game to-do list (steps 1 to 15) agreed on 2026-11-22.

## Art batch 2 (generate in Higgsfield)

- **Needed:** regenerate 6 level maps (Ethereal Ruins, Haunted Forest, Nexus of Balance, Celestial Citadel, Necropolis, and an edit of Misty Borderlands that removes the painted turrets and huts), 9 faction towers, 3 hero portraits, 9 hero walk sheets, 11 sounds. Use the corrected prompts (`art/prompts.md`, or the batch zip), aspect 4:3 for maps.
- **Why:** I cannot generate images or sounds from here.
- **Affects:** step 2 (the code that picks the art up is done in step 2 and works the moment files land), and the look of 7 of the 9 levels.
- **Date:** 2026-11-22

## Playtest

- **Needed:** play a few levels, especially the hard ones (Celestial Citadel, Necropolis, Nexus of Balance), and listen to the sound mix.
- **Why:** the balance read-out comes from an AI that never uses hero abilities, and I cannot hear the audio.
- **Affects:** step 15 (second balance pass).
- **Date:** 2026-11-22

## Merge the pull requests

- **Needed:** merge PR #2 (Model C), then retarget PR #3 (levels) to `master` and merge it, then the same for the polish PR.
- **Why:** each PR is stacked on the one before; merging is your call.
- **Affects:** none of the steps; it only decides when the work reaches `master`.
- **Date:** 2026-11-22

## OK to delete unused code (step 11)

- **Needed:** a yes (or a list of what to keep) before I delete code that nothing runs. I checked each by searching every `require` in the game.

  | What | Size | Why it is unused |
  |---|---|---|
  | `systems/achievement.lua`, `economy.lua`, `prestige.lua`, `settings.lua`, `store.lua`, `tutorial.lua`, `ui_enhancements.lua`, `visual_effects.lua`, `weather.lua` | 2,627 lines | Nothing requires them; achievements, shop, settings, tutorial and effects were rebuilt elsewhere |
  | `systems/map.lua` | 632 lines | The old map system; levels now come from `systems/level.lua` |
  | `systems/ui.lua`, `systems/ui_assets.lua` | 834 lines | `main.lua` loads `ui.lua` into a variable it never uses |
  | `utils/init.lua` | 32 lines | Nothing requires it |
  | Old slot saves in `systems/save.lua` (`Save.new`, `update`, `saveGame` x2, `loadGame`, `getSaveInfo`, `getAllSaveInfo`, `deleteSave`, `saveGameState`, `autoSave`) | about 300 lines | Profiles replaced them in step 4; `autoSave` only prints a message |
  | Submodules `libs/bump`, `libs/sti`, `libs/jumper`, `libs/loveframes` | 3.5 MB | Only the dead `map.lua` and `settings.lua` use them; the game uses `libs/hump` only |
  | `save/settings.json` (tracked) | 1 line | Holds the text `null` from the old broken save; settings now live in the LÖVE save folder. Also add `save/` to `.gitignore` |

- **Why:** about 4,400 lines and 4 submodules. My instructions say to stop before deleting a large amount of existing code, even unused, so this waits for you.
- **Affects:** step 11 only. Nothing else depends on it; the game and tests work with or without the deletion.
- **Date:** 2026-11-22

## License

- **Needed:** pick a license (for example MIT, or "all rights reserved"), or say none.
- **Why:** the README said "MIT, see the LICENSE file", but there is no LICENSE file. I changed the README to say no license is chosen yet; choosing one is yours.
- **Affects:** step 12 (README) and step 14 (a release you hand to others).
- **Date:** 2026-11-22

## Credits

- **Needed:** the names to show in the credits (game by, art, sound, music), or "leave as is".
- **Why:** the README and the credits screen still say "[Your Name/Team]" and "[Source]".
- **Affects:** step 12.
- **Date:** 2026-11-22
