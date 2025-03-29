local Test = require("tests.test_utils")
local Wave = require("systems.wave")

local function test_wave_initialization()
    local wave = Wave.new()
    Test.assert_not_nil(wave, "Wave should be created")
    Test.assert_equals(wave.currentWave, 1, "Wave should start at wave 1")
    Test.assert_equals(wave.enemiesRemaining, 0, "Wave should start with no enemies")
    Test.assert_equals(wave.isActive, false, "Wave should start inactive")
end

local function test_wave_start()
    local wave = Wave.new()
    wave:start()
    Test.assert_equals(wave.isActive, true, "Wave should become active when started")
    Test.assert_equals(wave.enemiesRemaining, wave:getWaveEnemyCount(), "Wave should spawn correct number of enemies")
end

local function test_wave_generation()
    local wave = Wave.new()
    wave:start()
    
    local enemies = wave:generateEnemies()
    Test.assert_not_nil(enemies, "Wave should generate enemies")
    Test.assert(#enemies > 0, "Wave should generate at least one enemy")
    
    for _, enemy in ipairs(enemies) do
        Test.assert_not_nil(enemy.type, "Enemy should have a type")
        Test.assert_not_nil(enemy.health, "Enemy should have health")
        Test.assert_not_nil(enemy.speed, "Enemy should have speed")
    end
end

local function test_wave_scaling()
    local wave = Wave.new()
    wave.currentWave = 5
    
    local baseEnemy = wave:generateEnemy("goblin")
    Test.assert(baseEnemy.health > 100, "Enemy health should scale with wave number")
    Test.assert(baseEnemy.speed > 50, "Enemy speed should scale with wave number")
    Test.assert(baseEnemy.reward > 10, "Enemy reward should scale with wave number")
end

local function test_wave_mini_boss()
    local wave = Wave.new()
    wave.currentWave = 5
    
    local miniBoss = wave:generateMiniBoss()
    Test.assert_not_nil(miniBoss, "Wave should generate mini-boss")
    Test.assert(miniBoss.health > 500, "Mini-boss should have high health")
    Test.assert(miniBoss.reward > 100, "Mini-boss should have high reward")
    Test.assert(miniBoss.isElite, "Mini-boss should be elite")
end

local function test_wave_boss()
    local wave = Wave.new()
    wave.currentWave = 10
    
    local boss = wave:generateBoss()
    Test.assert_not_nil(boss, "Wave should generate boss")
    Test.assert(boss.health > 1000, "Boss should have very high health")
    Test.assert(boss.reward > 500, "Boss should have very high reward")
    Test.assert(boss.isBoss, "Boss should be marked as boss")
end

local function test_wave_elite_modifiers()
    local wave = Wave.new()
    local enemy = wave:generateEnemy("goblin")
    
    wave:applyEliteModifier(enemy)
    Test.assert(enemy.isElite, "Enemy should become elite")
    Test.assert(enemy.health > 100, "Elite enemy should have increased health")
    Test.assert(enemy.reward > 10, "Elite enemy should have increased reward")
end

local function test_wave_completion()
    local wave = Wave.new()
    wave:start()
    
    wave.enemiesRemaining = 0
    Test.assert(wave:isComplete(), "Wave should be complete when no enemies remain")
    
    wave:complete()
    Test.assert_equals(wave.isActive, false, "Wave should become inactive when completed")
    Test.assert_equals(wave.currentWave, 2, "Wave number should increment after completion")
end

local function test_wave_rewards()
    local wave = Wave.new()
    wave.currentWave = 5
    
    local rewards = wave:getWaveRewards()
    Test.assert_not_nil(rewards, "Wave should provide rewards")
    Test.assert(rewards.gold > 0, "Wave should provide gold reward")
    Test.assert(rewards.experience > 0, "Wave should provide experience reward")
end

local function run_tests()
    local tests = {
        test_wave_initialization,
        test_wave_start,
        test_wave_generation,
        test_wave_scaling,
        test_wave_mini_boss,
        test_wave_boss,
        test_wave_elite_modifiers,
        test_wave_completion,
        test_wave_rewards
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