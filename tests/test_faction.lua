local Faction = require 'systems.faction'
local Test = require 'tests.test_utils'

local function test_faction_initialization()
    local faction = Faction.new('radiant')
    Test.assert(faction.type == 'radiant', "Faction type should be 'radiant'")
    Test.assert(#faction.heroes == 3, "Should have 3 heroes")
    Test.assert(#faction.towers == 3, "Should have 3 towers")
end

local function test_hero_abilities()
    local faction = Faction.new('radiant')
    local hero = faction:getHero('sir_galahad')
    
    Test.assert(hero ~= nil, "Should be able to get hero")
    Test.assert(#hero.abilities == 3, "Hero should have 3 abilities")
    
    -- Test ability effects
    local target = { damageReduction = 0 }
    hero.abilities[1].effect(hero, {target})
    Test.assert(target.damageReduction == 0.5, "Aegis of Dawn should reduce damage by 50%")
end

local function test_tower_upgrades()
    local faction = Faction.new('radiant')
    local tower = faction:getTower('holy_bastion')
    
    Test.assert(tower ~= nil, "Should be able to get tower")
    Test.assert(#tower.data.upgradePaths == 2, "Tower should have 2 upgrade paths")
    
    -- Test upgrade effects
    local towerInstance = {
        healAmount = 5,
        range = 150
    }
    
    tower.data.upgradePaths[1].effect(towerInstance)
    Test.assert(towerInstance.healAmount == 7.5, "Divine Light should increase heal amount by 50%")
    
    tower.data.upgradePaths[2].effect(towerInstance)
    Test.assert(towerInstance.range == 225, "Blessed Aura should increase range by 50%")
end

local function test_faction_bonuses()
    local radiant = Faction.new('radiant')
    local shadow = Faction.new('shadow')
    local twilight = Faction.new('twilight')
    
    local radiantBonus = radiant:getFactionBonus()
    local shadowBonus = shadow:getFactionBonus()
    local twilightBonus = twilight:getFactionBonus()
    
    Test.assert(radiantBonus.towerDamage == 0.1, "Radiant should have +10% tower damage")
    Test.assert(shadowBonus.poisonDamage == 0.15, "Shadow should have +15% poison damage")
    Test.assert(twilightBonus.hybridDamage == 0.1, "Twilight should have +10% hybrid damage")
end

local function test_hero_leveling()
    local faction = Faction.new('radiant')
    local hero = faction:getHero('sir_galahad')
    
    Test.assert(hero.level == 1, "Hero should start at level 1")
    Test.assert(hero.experience == 0, "Hero should start with 0 experience")
    
    faction:addExperience('sir_galahad', 100)
    Test.assert(hero.experience == 100, "Should add experience")
    
    faction:addExperience('sir_galahad', 150)
    Test.assert(hero.level == 2, "Should level up at 200 experience")
    Test.assert(hero.experience == 0, "Experience should reset after level up")
end

local function test_tower_unlocking()
    local faction = Faction.new('radiant')
    
    Test.assert(faction:unlockTower('holy_bastion') == true, "Should unlock existing tower")
    Test.assert(faction:unlockTower('nonexistent_tower') == false, "Should fail to unlock nonexistent tower")
end

local function run_tests()
    print("Running Faction System Tests...")
    
    test_faction_initialization()
    test_hero_abilities()
    test_tower_upgrades()
    test_faction_bonuses()
    test_hero_leveling()
    test_tower_unlocking()
    
    print("All Faction System Tests Passed!")
end

return {
    run = run_tests
} 