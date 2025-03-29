local Test = require("tests.test_utils")
local Enemy = require("systems.enemy")

local function test_enemy_initialization()
    local enemy = Enemy.new("goblin", 100, 100)
    Test.assert_not_nil(enemy, "Enemy should be created")
    Test.assert_equals(enemy.type, "goblin", "Enemy type should be set")
    Test.assert_equals(enemy.x, 100, "Enemy x position should be set")
    Test.assert_equals(enemy.y, 100, "Enemy y position should be set")
    Test.assert_equals(enemy.health, enemy.maxHealth, "Enemy should start at full health")
    Test.assert_equals(enemy.speed, 50, "Enemy should have correct base speed")
end

local function test_enemy_movement()
    local enemy = Enemy.new("goblin", 100, 100)
    local path = {
        {x = 150, y = 150},
        {x = 200, y = 200}
    }
    
    enemy:setPath(path)
    Test.assert_equals(enemy.currentPathIndex, 1, "Enemy should start at first path point")
    
    enemy:updatePosition(1.0)
    Test.assert_not_equals(enemy.x, 100, "Enemy should move from initial position")
    Test.assert_not_equals(enemy.y, 100, "Enemy should move from initial position")
end

local function test_enemy_combat()
    local enemy = Enemy.new("goblin", 100, 100)
    local initialHealth = enemy.health
    
    enemy:takeDamage(20)
    Test.assert_equals(enemy.health, initialHealth - 20, "Enemy should take damage")
    
    enemy:heal(10)
    Test.assert_equals(enemy.health, initialHealth - 10, "Enemy should heal")
end

local function test_enemy_death()
    local enemy = Enemy.new("goblin", 100, 100)
    local deathCallbackCalled = false
    
    enemy.onDeath = function()
        deathCallbackCalled = true
    end
    
    enemy:takeDamage(enemy.maxHealth)
    Test.assert_equals(enemy.health, 0, "Enemy should die when health reaches 0")
    Test.assert(deathCallbackCalled, "Death callback should be called")
end

local function test_enemy_special_mechanics()
    local boss = Enemy.new("boss", 100, 100)
    local minion = Enemy.new("goblin", 150, 150)
    
    boss:healNearMinions({minion})
    Test.assert_equals(minion.health, minion.maxHealth, "Minion should be healed by boss")
    
    boss:shockwave({minion})
    Test.assert(minion.health < minion.maxHealth, "Minion should take damage from shockwave")
end

local function test_enemy_status_effects()
    local enemy = Enemy.new("goblin", 100, 100)
    local initialSpeed = enemy.speed
    
    enemy:applyEffect("slow", 2.0, 0.5)
    Test.assert_equals(enemy.speed, initialSpeed * 0.5, "Enemy should be slowed")
    
    enemy:updateEffects(1.0)
    Test.assert_equals(enemy.speed, initialSpeed * 0.5, "Slow effect should persist")
    
    enemy:updateEffects(2.0)
    Test.assert_equals(enemy.speed, initialSpeed, "Slow effect should expire")
end

local function test_enemy_elemental_cycle()
    local elemental = Enemy.new("elemental", 100, 100)
    
    Test.assert_equals(elemental.element, "fire", "Elemental should start with fire element")
    
    elemental:cycleElement()
    Test.assert_equals(elemental.element, "water", "Elemental should cycle to water")
    
    elemental:cycleElement()
    Test.assert_equals(elemental.element, "earth", "Elemental should cycle to earth")
    
    elemental:cycleElement()
    Test.assert_equals(elemental.element, "air", "Elemental should cycle to air")
    
    elemental:cycleElement()
    Test.assert_equals(elemental.element, "fire", "Elemental should cycle back to fire")
end

local function test_enemy_reached_end()
    local enemy = Enemy.new("goblin", 100, 100)
    local endCallbackCalled = false
    
    enemy.onReachedEnd = function()
        endCallbackCalled = true
    end
    
    enemy:reachedEnd()
    Test.assert(endCallbackCalled, "End callback should be called")
end

local function run_tests()
    local tests = {
        test_enemy_initialization,
        test_enemy_movement,
        test_enemy_combat,
        test_enemy_death,
        test_enemy_special_mechanics,
        test_enemy_status_effects,
        test_enemy_elemental_cycle,
        test_enemy_reached_end
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