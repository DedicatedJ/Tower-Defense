local Test = require("tests.test_utils")
local Tower = require("systems.tower")
local Enemy = require("systems.enemy")
local Wave = require("systems.wave")
local Map = require("systems.map")
local VisualEffects = require("systems.visual_effects")
local UI = require("systems.ui")

local function measure_time(func)
    local start = os.clock()
    func()
    return os.clock() - start
end

local function test_tower_performance()
    print("\nTesting Tower System Performance:")
    
    -- Test tower creation performance
    local creation_time = measure_time(function()
        for i = 1, 1000 do
            Tower.new("arrow", 100, 100)
        end
    end)
    print(string.format("Tower Creation: %.4f seconds for 1000 towers", creation_time))
    
    -- Test tower targeting performance
    local tower = Tower.new("arrow", 100, 100)
    local enemies = {}
    for i = 1, 100 do
        table.insert(enemies, {x = math.random(0, 800), y = math.random(0, 600), health = 100})
    end
    
    local targeting_time = measure_time(function()
        for i = 1, 1000 do
            tower:findTarget(enemies)
        end
    end)
    print(string.format("Tower Targeting: %.4f seconds for 1000 target searches", targeting_time))
end

local function test_enemy_performance()
    print("\nTesting Enemy System Performance:")
    
    -- Test enemy creation performance
    local creation_time = measure_time(function()
        for i = 1, 1000 do
            Enemy.new("goblin", 100, 100)
        end
    end)
    print(string.format("Enemy Creation: %.4f seconds for 1000 enemies", creation_time))
    
    -- Test enemy movement performance
    local enemy = Enemy.new("goblin", 100, 100)
    local path = {}
    for i = 1, 100 do
        table.insert(path, {x = math.random(0, 800), y = math.random(0, 600)})
    end
    enemy:setPath(path)
    
    local movement_time = measure_time(function()
        for i = 1, 1000 do
            enemy:updatePosition(0.016) -- 60 FPS
        end
    end)
    print(string.format("Enemy Movement: %.4f seconds for 1000 updates", movement_time))
end

local function test_wave_performance()
    print("\nTesting Wave System Performance:")
    
    -- Test wave generation performance
    local wave = Wave.new()
    wave.currentWave = 10
    
    local generation_time = measure_time(function()
        for i = 1, 100 do
            wave:generateEnemies()
        end
    end)
    print(string.format("Wave Generation: %.4f seconds for 100 waves", generation_time))
    
    -- Test wave scaling performance
    local scaling_time = measure_time(function()
        for i = 1, 1000 do
            wave:generateEnemy("goblin")
        end
    end)
    print(string.format("Enemy Scaling: %.4f seconds for 1000 enemies", scaling_time))
end

local function test_map_performance()
    print("\nTesting Map System Performance:")
    
    -- Test map creation performance
    local creation_time = measure_time(function()
        for i = 1, 100 do
            Map.new("sunlit_meadows")
        end
    end)
    print(string.format("Map Creation: %.4f seconds for 100 maps", creation_time))
    
    -- Test path finding performance
    local map = Map.new("sunlit_meadows")
    local path_finding_time = measure_time(function()
        for i = 1, 1000 do
            map:findPath(100, 100, 700, 500)
        end
    end)
    print(string.format("Path Finding: %.4f seconds for 1000 paths", path_finding_time))
end

local function test_effects_performance()
    print("\nTesting Visual Effects Performance:")
    
    -- Test particle system performance
    local effects = VisualEffects.new()
    local particle_time = measure_time(function()
        for i = 1, 1000 do
            effects:createParticleSystem("rain")
        end
    end)
    print(string.format("Particle Creation: %.4f seconds for 1000 particles", particle_time))
    
    -- Test effect updates performance
    local update_time = measure_time(function()
        for i = 1, 1000 do
            effects:update(0.016) -- 60 FPS
        end
    end)
    print(string.format("Effect Updates: %.4f seconds for 1000 updates", update_time))
end

local function test_ui_performance()
    print("\nTesting UI System Performance:")
    
    -- Test UI element creation performance
    local ui = UI.new()
    local creation_time = measure_time(function()
        for i = 1, 1000 do
            ui:createButton("Test Button", 100, 100, 200, 50)
        end
    end)
    print(string.format("UI Element Creation: %.4f seconds for 1000 elements", creation_time))
    
    -- Test UI update performance
    local update_time = measure_time(function()
        for i = 1, 1000 do
            ui:update(0.016) -- 60 FPS
        end
    end)
    print(string.format("UI Updates: %.4f seconds for 1000 updates", update_time))
end

local function run_tests()
    print("Running Performance Tests...")
    
    test_tower_performance()
    test_enemy_performance()
    test_wave_performance()
    test_map_performance()
    test_effects_performance()
    test_ui_performance()
    
    print("\nPerformance Tests Completed!")
end

return {
    run_tests = run_tests
} 