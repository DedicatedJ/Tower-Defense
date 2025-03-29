local Test = require("tests.test_utils")
local Tower = require("systems.tower")

local function test_tower_initialization()
    local tower = Tower.new("arrow", 100, 100)
    Test.assert_not_nil(tower, "Tower should be created")
    Test.assert_equals(tower.type, "arrow", "Tower type should be set")
    Test.assert_equals(tower.x, 100, "Tower x position should be set")
    Test.assert_equals(tower.y, 100, "Tower y position should be set")
    Test.assert_equals(tower.level, 1, "Tower should start at level 1")
    Test.assert_equals(tower.target, nil, "Tower should have no initial target")
end

local function test_tower_stats()
    local tower = Tower.new("arrow", 100, 100)
    Test.assert_equals(tower.damage, 10, "Tower should have correct base damage")
    Test.assert_equals(tower.attackSpeed, 1.0, "Tower should have correct base attack speed")
    Test.assert_equals(tower.range, 150, "Tower should have correct base range")
end

local function test_tower_targeting()
    local tower = Tower.new("arrow", 100, 100)
    local enemy = {x = 150, y = 150, health = 100}
    
    Test.assert(tower:isInRange(enemy), "Tower should detect enemy in range")
    Test.assert_not_nil(tower:findTarget({enemy}), "Tower should find valid target")
    
    local farEnemy = {x = 300, y = 300, health = 100}
    Test.assert(not tower:isInRange(farEnemy), "Tower should not detect enemy out of range")
    Test.assert_nil(tower:findTarget({farEnemy}), "Tower should not find target out of range")
end

local function test_tower_attacking()
    local tower = Tower.new("arrow", 100, 100)
    local enemy = {x = 150, y = 150, health = 100}
    
    tower:attack(enemy)
    Test.assert_equals(enemy.health, 90, "Enemy should take damage from tower attack")
end

local function test_tower_upgrades()
    local tower = Tower.new("arrow", 100, 100)
    local initialDamage = tower.damage
    local initialRange = tower.range
    
    tower:upgrade("damage")
    Test.assert_equals(tower.level, 2, "Tower level should increase after upgrade")
    Test.assert(tower.damage > initialDamage, "Tower damage should increase after upgrade")
    
    tower:upgrade("range")
    Test.assert(tower.range > initialRange, "Tower range should increase after upgrade")
end

local function test_tower_synergies()
    local arrowTower = Tower.new("arrow", 100, 100)
    local magicTower = Tower.new("magic", 150, 100)
    
    Test.assert(tower:hasSynergy(magicTower), "Tower should detect synergy with compatible tower")
    Test.assert(not tower:hasSynergy(arrowTower), "Tower should not detect synergy with incompatible tower")
end

local function test_tower_terrain_effects()
    local tower = Tower.new("arrow", 100, 100)
    local initialRange = tower.range
    
    tower:applyTerrainEffect("high_ground")
    Test.assert(tower.range > initialRange, "Tower range should increase on high ground")
    
    tower:applyTerrainEffect("foggy")
    Test.assert(tower.range < initialRange, "Tower range should decrease in fog")
end

local function test_tower_special_mechanics()
    local holyTower = Tower.new("holy", 100, 100)
    local nearbyTower = Tower.new("arrow", 150, 100)
    
    holyTower:healNearbyTowers({nearbyTower})
    Test.assert_equals(nearbyTower.health, nearbyTower.maxHealth, "Nearby tower should be healed")
end

local function run_tests()
    local tests = {
        test_tower_initialization,
        test_tower_stats,
        test_tower_targeting,
        test_tower_attacking,
        test_tower_upgrades,
        test_tower_synergies,
        test_tower_terrain_effects,
        test_tower_special_mechanics
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        local success, error = pcall(test)
        if success then
            passed = passed + 1
            print("✓ " .. test.name .. " passed")
        else
            failed = failed + 1
            print("✗ " .. test.name .. " failed: " .. error)
        end
    end
    
    print(string.format("\nTest Summary: %d passed, %d failed", passed, failed))
end

return {
    run_tests = run_tests
} 