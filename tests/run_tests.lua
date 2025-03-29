local TestFaction = require("tests.test_faction")
local TestTower = require("tests.test_tower")
local TestEnemy = require("tests.test_enemy")
local TestWave = require("tests.test_wave")
local TestMap = require("tests.test_map")
local TestStore = require("tests.test_store")
local TestVisualEffects = require("tests.test_visual_effects")
local TestUI = require("tests.test_ui")
local TestPerformance = require("tests.test_performance")
local TestIntegration = require("tests.test_integration")

local function run_all_tests()
    print("Starting Tower Defense Test Suite...")
    print("=====================================")
    
    -- Run unit tests
    print("\nRunning Unit Tests:")
    print("------------------")
    TestFaction.run_tests()
    TestTower.run_tests()
    TestEnemy.run_tests()
    TestWave.run_tests()
    TestMap.run_tests()
    TestStore.run_tests()
    TestVisualEffects.run_tests()
    TestUI.run_tests()
    
    -- Run performance tests
    print("\nRunning Performance Tests:")
    print("-------------------------")
    TestPerformance.run_tests()
    
    -- Run integration tests
    print("\nRunning Integration Tests:")
    print("-------------------------")
    TestIntegration.run_tests()
    
    print("\nAll Tests Completed!")
    print("=====================================")
end

-- Run the test suite
run_all_tests() 