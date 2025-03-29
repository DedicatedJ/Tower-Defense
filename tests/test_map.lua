local Test = require("tests.test_utils")
local Map = require("systems.map")

local function test_map_initialization()
    local map = Map.new("sunlit_meadows")
    Test.assert_not_nil(map, "Map should be created")
    Test.assert_equals(map.name, "Sunlit Meadows", "Map name should be set")
    Test.assert_equals(map.difficulty, 1, "Map difficulty should be set")
    Test.assert_not_nil(map.paths, "Map should have paths")
    Test.assert_not_nil(map.towerSpots, "Map should have tower spots")
end

local function test_map_features()
    local map = Map.new("crystal_spires")
    Test.assert(map.features.elevated, "Map should have elevated ground")
    Test.assert(map.features.teleporters, "Map should have teleporters")
    
    local shadowMap = Map.new("haunted_forest")
    Test.assert(shadowMap.features.fog, "Map should have fog")
    Test.assert(shadowMap.features.destructibles, "Map should have destructibles")
end

local function test_map_paths()
    local map = Map.new("sunlit_meadows")
    Test.assert(#map.paths > 0, "Map should have at least one path")
    
    for _, path in ipairs(map.paths) do
        Test.assert(#path > 1, "Path should have at least two points")
        for _, point in ipairs(path) do
            Test.assert_not_nil(point.x, "Path point should have x coordinate")
            Test.assert_not_nil(point.y, "Path point should have y coordinate")
        end
    end
end

local function test_map_tower_spots()
    local map = Map.new("sunlit_meadows")
    Test.assert(#map.towerSpots > 0, "Map should have tower spots")
    
    for _, spot in ipairs(map.towerSpots) do
        Test.assert_not_nil(spot.x, "Tower spot should have x coordinate")
        Test.assert_not_nil(spot.y, "Tower spot should have y coordinate")
        Test.assert_not_nil(spot.type, "Tower spot should have type")
    end
end

local function test_map_platforms()
    local map = Map.new("crystal_spires")
    Test.assert(#map.platforms > 0, "Map should have platforms")
    
    for _, platform in ipairs(map.platforms) do
        Test.assert_not_nil(platform.x, "Platform should have x coordinate")
        Test.assert_not_nil(platform.y, "Platform should have y coordinate")
        Test.assert_not_nil(platform.width, "Platform should have width")
        Test.assert_not_nil(platform.height, "Platform should have height")
    end
end

local function test_map_bridges()
    local map = Map.new("obsidian_caves")
    Test.assert(#map.bridges > 0, "Map should have bridges")
    
    for _, bridge in ipairs(map.bridges) do
        Test.assert_not_nil(bridge.start, "Bridge should have start point")
        Test.assert_not_nil(bridge.end_, "Bridge should have end point")
        Test.assert_not_nil(bridge.width, "Bridge should have width")
    end
end

local function test_map_zones()
    local map = Map.new("haunted_forest")
    Test.assert(#map.fogZones > 0, "Map should have fog zones")
    Test.assert(#map.lightZones > 0, "Map should have light zones")
    
    for _, zone in ipairs(map.fogZones) do
        Test.assert_not_nil(zone.x, "Fog zone should have x coordinate")
        Test.assert_not_nil(zone.y, "Fog zone should have y coordinate")
        Test.assert_not_nil(zone.radius, "Fog zone should have radius")
    end
    
    for _, zone in ipairs(map.lightZones) do
        Test.assert_not_nil(zone.x, "Light zone should have x coordinate")
        Test.assert_not_nil(zone.y, "Light zone should have y coordinate")
        Test.assert_not_nil(zone.radius, "Light zone should have radius")
    end
end

local function test_map_destructibles()
    local map = Map.new("haunted_forest")
    Test.assert(#map.destructibles > 0, "Map should have destructibles")
    
    for _, destructible in ipairs(map.destructibles) do
        Test.assert_not_nil(destructible.x, "Destructible should have x coordinate")
        Test.assert_not_nil(destructible.y, "Destructible should have y coordinate")
        Test.assert_not_nil(destructible.type, "Destructible should have type")
        Test.assert_not_nil(destructible.health, "Destructible should have health")
    end
end

local function test_map_teleporters()
    local map = Map.new("crystal_spires")
    Test.assert(#map.teleporters > 0, "Map should have teleporters")
    
    for _, teleporter in ipairs(map.teleporters) do
        Test.assert_not_nil(teleporter.entrance, "Teleporter should have entrance point")
        Test.assert_not_nil(teleporter.exit, "Teleporter should have exit point")
        Test.assert_not_nil(teleporter.cooldown, "Teleporter should have cooldown")
    end
end

local function run_tests()
    local tests = {
        test_map_initialization,
        test_map_features,
        test_map_paths,
        test_map_tower_spots,
        test_map_platforms,
        test_map_bridges,
        test_map_zones,
        test_map_destructibles,
        test_map_teleporters
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