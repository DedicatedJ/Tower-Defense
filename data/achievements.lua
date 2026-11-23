-- Achievements: one per icon in sprites/ui/achievements/. Pure data;
-- systems/achievements.lua checks them at the end of every game.
--
-- check: what unlocks it
--   total      a profile counter reaches `goal` (shows progress)
--   heroLevel  any hero reaches level `goal` (shows progress)
--   faction    all of one faction's levels won (shows progress)
--   flawless   win a level without losing a life
--   allTowers  win a level with every one of your faction's towers built

return {
    { id = "first_tower", name = "Foundation", description = "Build your first tower",
      check = "total", counter = "towersBuilt", goal = 1 },
    { id = "tower_master", name = "Tower Master", description = "Build 50 towers in total",
      check = "total", counter = "towersBuilt", goal = 50 },
    { id = "wave_survivor", name = "Wave Survivor", description = "Clear 100 waves in total",
      check = "total", counter = "wavesCleared", goal = 100 },
    { id = "perfect_wave", name = "Flawless", description = "Win a level without losing a life",
      check = "flawless" },
    { id = "tower_synergy", name = "Combined Arms", description = "Win a level with all three of your faction's towers built",
      check = "allTowers" },
    { id = "resource_king", name = "Treasurer", description = "Earn 2,000 shop gold in total",
      check = "total", counter = "shopGold", goal = 2000 },
    { id = "hero_legend", name = "Hero Legend", description = "Raise a hero to level 10",
      check = "heroLevel", goal = 10 },
    { id = "faction_master", name = "Faction Master", description = "Win all three levels of one faction",
      check = "faction", goal = 3 },
}
