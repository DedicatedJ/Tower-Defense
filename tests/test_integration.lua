local Test = require("tests.test_utils")
local Tower = require("systems.tower")
local Enemy = require("systems.enemy")
local Wave = require("systems.wave")
local Map = require("systems.map")
local Store = require("systems.store")
local Faction = require("systems.faction")
local VisualEffects = require("systems.visual_effects")
local UI = require("systems.ui")

local function test_tower_enemy_interaction()
    print("\nTesting Tower-Enemy Integration:")
    
    -- Create a tower and enemy
    local tower = Tower.new("arrow", 100, 100)
    local enemy = Enemy.new("goblin", 150, 150)
    
    -- Test tower targeting enemy
    Test.assert(tower:isInRange(enemy), "Tower should detect enemy in range")
    local target = tower:findTarget({enemy})
    Test.assert(target == enemy, "Tower should select correct target")
    
    -- Test tower attacking enemy
    local initialHealth = enemy.health
    tower:attack(enemy)
    Test.assert(enemy.health < initialHealth, "Enemy should take damage from tower")
end

local function test_wave_enemy_map_integration()
    print("\nTesting Wave-Enemy-Map Integration:")
    
    -- Create map and wave
    local map = Map.new("sunlit_meadows")
    local wave = Wave.new()
    
    -- Test enemy path following
    local enemy = wave:generateEnemy("goblin")
    enemy:setPath(map.paths[1])
    
    local initialX = enemy.x
    local initialY = enemy.y
    
    enemy:updatePosition(1.0)
    Test.assert(enemy.x ~= initialX or enemy.y ~= initialY, "Enemy should move along path")
end

local function test_faction_tower_store_integration()
    print("\nTesting Faction-Tower-Store Integration:")
    
    -- Create faction and store
    local faction = Faction.new("radiant")
    local store = Store.new()
    
    -- Test tower unlocking and purchasing
    local tower = faction:getTower("holy_bastion")
    Test.assert(tower ~= nil, "Should be able to get faction tower")
    
    local player = {gold = 1000}
    Test.assert(store:canAffordUpgrade(player, tower.id), "Player should be able to afford tower")
    
    store:purchaseUpgrade(player, tower.id)
    Test.assert(store:hasPurchasedUpgrade(tower.id), "Tower should be marked as purchased")
end

local function test_effects_tower_enemy_integration()
    print("\nTesting Effects-Tower-Enemy Integration:")
    
    -- Create systems
    local effects = VisualEffects.new()
    local tower = Tower.new("magic", 100, 100)
    local enemy = Enemy.new("goblin", 150, 150)
    
    -- Test attack effects
    tower:attack(enemy)
    Test.assert(effects:hasEffect("magic_attack"), "Attack should create visual effect")
    
    -- Test enemy death effects
    enemy:takeDamage(enemy.maxHealth)
    Test.assert(effects:hasEffect("enemy_death"), "Death should create visual effect")
end

local function test_ui_game_state_integration()
    print("\nTesting UI-Game State Integration:")
    
    -- Create UI and game state
    local ui = UI.new()
    local wave = Wave.new()
    local player = {gold = 1000, lives = 3}
    
    -- Test wave info display
    local waveInfo = ui:createWaveInfo(wave)
    Test.assert(waveInfo ~= nil, "Should create wave info display")
    Test.assert(waveInfo.waveNumber == wave.currentWave, "Wave info should show correct wave")
    
    -- Test player stats display
    local statsDisplay = ui:createPlayerStats(player)
    Test.assert(statsDisplay ~= nil, "Should create player stats display")
    Test.assert(statsDisplay.gold == player.gold, "Stats should show correct gold")
    Test.assert(statsDisplay.lives == player.lives, "Stats should show correct lives")
end

local function test_save_load_integration()
    print("\nTesting Save-Load Integration:")
    
    -- Create game state
    local faction = Faction.new("radiant")
    local store = Store.new()
    local player = {gold = 1000}
    
    -- Purchase some items
    store:purchaseUpgrade(player, "holy_bastion")
    store:purchaseItem(player, "health_potion")
    
    -- Save game state
    local saveData = {
        faction = faction:saveState(),
        store = store:savePurchases(),
        player = player
    }
    
    -- Create new game state and load
    local newFaction = Faction.new("radiant")
    local newStore = Store.new()
    local newPlayer = {gold = 0}
    
    newFaction:loadState(saveData.faction)
    newStore:loadPurchases(saveData.store)
    newPlayer = saveData.player
    
    -- Verify state restoration
    Test.assert(newStore:hasPurchasedUpgrade("holy_bastion"), "Purchased upgrades should persist")
    Test.assert(newStore:hasPurchasedItem("health_potion"), "Purchased items should persist")
    Test.assert(newPlayer.gold == 1000, "Player gold should persist")
end

local function test_game_loop_integration()
    print("\nTesting Game Loop Integration:")
    
    -- Create game systems
    local map = Map.new("sunlit_meadows")
    local wave = Wave.new()
    local player = {gold = 1000, lives = 3}
    local towers = {}
    local enemies = {}
    
    -- Start wave
    wave:start()
    Test.assert(wave.isActive, "Wave should be active")
    
    -- Generate enemies
    enemies = wave:generateEnemies()
    Test.assert(#enemies > 0, "Wave should generate enemies")
    
    -- Place towers
    local tower = Tower.new("arrow", 100, 100)
    table.insert(towers, tower)
    
    -- Update game state
    for i = 1, 100 do
        -- Update enemies
        for _, enemy in ipairs(enemies) do
            enemy:updatePosition(0.016)
        end
        
        -- Update towers
        for _, tower in ipairs(towers) do
            tower:update(enemies, 0.016)
        end
        
        -- Check wave completion
        if wave:isComplete() then
            break
        end
    end
    
    Test.assert(wave:isComplete(), "Wave should complete after updates")
end

local function run_tests()
    print("Running Integration Tests...")
    
    test_tower_enemy_interaction()
    test_wave_enemy_map_integration()
    test_faction_tower_store_integration()
    test_effects_tower_enemy_integration()
    test_ui_game_state_integration()
    test_save_load_integration()
    test_game_loop_integration()
    
    print("\nIntegration Tests Completed!")
end

return {
    run_tests = run_tests
} 