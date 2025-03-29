local Test = require("tests.test_utils")
local Store = require("systems.store")

local function test_store_initialization()
    local store = Store.new()
    Test.assert_not_nil(store, "Store should be created")
    Test.assert_not_nil(store.upgrades, "Store should have upgrades")
    Test.assert_not_nil(store.items, "Store should have items")
    Test.assert_not_nil(store.factionItems, "Store should have faction items")
end

local function test_store_upgrades()
    local store = Store.new()
    Test.assert(#store.upgrades > 0, "Store should have upgrades")
    
    for _, upgrade in ipairs(store.upgrades) do
        Test.assert_not_nil(upgrade.id, "Upgrade should have ID")
        Test.assert_not_nil(upgrade.name, "Upgrade should have name")
        Test.assert_not_nil(upgrade.cost, "Upgrade should have cost")
        Test.assert_not_nil(upgrade.description, "Upgrade should have description")
    end
end

local function test_store_items()
    local store = Store.new()
    Test.assert(#store.items > 0, "Store should have items")
    
    for _, item in ipairs(store.items) do
        Test.assert_not_nil(item.id, "Item should have ID")
        Test.assert_not_nil(item.name, "Item should have name")
        Test.assert_not_nil(item.cost, "Item should have cost")
        Test.assert_not_nil(item.description, "Item should have description")
        Test.assert_not_nil(item.effect, "Item should have effect")
    end
end

local function test_store_faction_items()
    local store = Store.new()
    Test.assert(#store.factionItems > 0, "Store should have faction items")
    
    for _, item in ipairs(store.factionItems) do
        Test.assert_not_nil(item.id, "Faction item should have ID")
        Test.assert_not_nil(item.name, "Faction item should have name")
        Test.assert_not_nil(item.cost, "Faction item should have cost")
        Test.assert_not_nil(item.faction, "Faction item should have faction")
        Test.assert_not_nil(item.description, "Faction item should have description")
    end
end

local function test_store_purchases()
    local store = Store.new()
    local player = {gold = 1000}
    
    local upgrade = store.upgrades[1]
    Test.assert(store:canAffordUpgrade(player, upgrade.id), "Player should be able to afford upgrade")
    
    store:purchaseUpgrade(player, upgrade.id)
    Test.assert(player.gold < 1000, "Player gold should decrease after purchase")
    Test.assert(store:hasPurchasedUpgrade(upgrade.id), "Upgrade should be marked as purchased")
end

local function test_store_item_purchases()
    local store = Store.new()
    local player = {gold = 1000}
    
    local item = store.items[1]
    Test.assert(store:canAffordItem(player, item.id), "Player should be able to afford item")
    
    store:purchaseItem(player, item.id)
    Test.assert(player.gold < 1000, "Player gold should decrease after purchase")
    Test.assert(store:hasPurchasedItem(item.id), "Item should be marked as purchased")
end

local function test_store_faction_purchases()
    local store = Store.new()
    local player = {gold = 1000, faction = "radiant"}
    
    local factionItem = store:getFactionItems("radiant")[1]
    Test.assert(store:canAffordFactionItem(player, factionItem.id), "Player should be able to afford faction item")
    
    store:purchaseFactionItem(player, factionItem.id)
    Test.assert(player.gold < 1000, "Player gold should decrease after purchase")
    Test.assert(store:hasPurchasedFactionItem(factionItem.id), "Faction item should be marked as purchased")
end

local function test_store_save_load()
    local store = Store.new()
    local player = {gold = 1000}
    
    -- Purchase some items
    store:purchaseUpgrade(player, store.upgrades[1].id)
    store:purchaseItem(player, store.items[1].id)
    
    -- Save purchases
    local saveData = store:savePurchases()
    Test.assert_not_nil(saveData, "Store should save purchase data")
    
    -- Create new store and load purchases
    local newStore = Store.new()
    newStore:loadPurchases(saveData)
    
    Test.assert(newStore:hasPurchasedUpgrade(store.upgrades[1].id), "Purchased upgrades should persist after load")
    Test.assert(newStore:hasPurchasedItem(store.items[1].id), "Purchased items should persist after load")
end

local function test_store_ui()
    local store = Store.new()
    local ui = store:createUI()
    
    Test.assert_not_nil(ui, "Store should create UI")
    Test.assert_not_nil(ui.tabs, "Store UI should have tabs")
    Test.assert(#ui.tabs >= 3, "Store UI should have at least 3 tabs (upgrades, items, faction)")
end

local function run_tests()
    local tests = {
        test_store_initialization,
        test_store_upgrades,
        test_store_items,
        test_store_faction_items,
        test_store_purchases,
        test_store_item_purchases,
        test_store_faction_purchases,
        test_store_save_load,
        test_store_ui
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