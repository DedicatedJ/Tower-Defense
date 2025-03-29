local Store = {}
Store.__index = Store

-- Store items
local STORE_ITEMS = {
    -- Permanent Upgrades
    upgrades = {
        {
            id = "tower_damage",
            name = "Tower Damage",
            description = "Increase all tower damage by 5%",
            cost = 1000,
            maxLevel = 10,
            effect = function(level)
                return 1 + (level * 0.05)
            end
        },
        {
            id = "tower_range",
            name = "Tower Range",
            description = "Increase all tower range by 5%",
            cost = 1000,
            maxLevel = 10,
            effect = function(level)
                return 1 + (level * 0.05)
            end
        },
        {
            id = "tower_attack_speed",
            name = "Attack Speed",
            description = "Increase all tower attack speed by 5%",
            cost = 1000,
            maxLevel = 10,
            effect = function(level)
                return 1 + (level * 0.05)
            end
        },
        {
            id = "resource_gain",
            name = "Resource Gain",
            description = "Increase resource gain by 10%",
            cost = 1500,
            maxLevel = 5,
            effect = function(level)
                return 1 + (level * 0.1)
            end
        },
        {
            id = "hero_health",
            name = "Hero Health",
            description = "Increase hero maximum health by 20%",
            cost = 2000,
            maxLevel = 5,
            effect = function(level)
                return 1 + (level * 0.2)
            end
        }
    },
    
    -- Consumable Items
    items = {
        {
            id = "extra_life",
            name = "Extra Life",
            description = "Gain an extra life for the next wave",
            cost = 500,
            effect = function()
                gameState.lives = gameState.lives + 1
                gameState:showNotification("Extra life gained!")
            end
        },
        {
            id = "damage_boost",
            name = "Damage Boost",
            description = "Increase all tower damage by 50% for 30 seconds",
            cost = 750,
            effect = function()
                gameState:addTemporaryBuff("damage", 1.5, 30)
                gameState:showNotification("Damage boost activated!")
            end
        },
        {
            id = "wave_skip",
            name = "Wave Skip",
            description = "Skip the current wave and receive rewards",
            cost = 1000,
            effect = function()
                gameState:completeWave()
                gameState:showNotification("Wave skipped!")
            end
        },
        {
            id = "resource_boost",
            name = "Resource Boost",
            description = "Double resource gain for the next wave",
            cost = 1000,
            effect = function()
                gameState:addTemporaryBuff("resource_gain", 2, 1)
                gameState:showNotification("Resource boost activated!")
            end
        }
    },
    
    -- Faction-Specific Items
    factionItems = {
        radiant = {
            {
                id = "holy_blessing",
                name = "Holy Blessing",
                description = "Increase holy tower damage by 100% for 20 seconds",
                cost = 800,
                effect = function()
                    gameState:addTemporaryBuff("holy_damage", 2, 20)
                    gameState:showNotification("Holy blessing activated!")
                end
            }
        },
        shadow = {
            {
                id = "soul_harvest",
                name = "Soul Harvest",
                description = "Increase minion health by 50% for 30 seconds",
                cost = 800,
                effect = function()
                    gameState:addTemporaryBuff("minion_health", 1.5, 30)
                    gameState:showNotification("Soul harvest activated!")
                end
            }
        },
        twilight = {
            {
                id = "balance_harmony",
                name = "Balance Harmony",
                description = "Increase hybrid damage by 75% for 25 seconds",
                cost = 800,
                effect = function()
                    gameState:addTemporaryBuff("hybrid_damage", 1.75, 25)
                    gameState:showNotification("Balance harmony activated!")
                end
            }
        }
    }
}

function Store.new()
    local self = setmetatable({}, Store)
    
    self.upgrades = {}
    self.items = {}
    self.factionItems = {}
    self:loadPurchases()
    
    return self
end

function Store:loadPurchases()
    -- Load purchased upgrades
    local success, data = pcall(function()
        return love.filesystem.read("purchases.json")
    end)
    
    if success and data then
        local purchases = json.decode(data)
        self.upgrades = purchases.upgrades or {}
        self.items = purchases.items or {}
        self.factionItems = purchases.factionItems or {}
    end
end

function Store:savePurchases()
    local purchases = {
        upgrades = self.upgrades,
        items = self.items,
        factionItems = self.factionItems
    }
    
    local success, err = pcall(function()
        return love.filesystem.write("purchases.json", json.encode(purchases))
    end)
    
    if not success then
        print("Failed to save purchases:", err)
    end
end

function Store:getUpgradeLevel(upgradeId)
    return self.upgrades[upgradeId] or 0
end

function Store:getUpgradeCost(upgradeId)
    local level = self:getUpgradeLevel(upgradeId)
    local upgrade = self:findUpgrade(upgradeId)
    
    if not upgrade then return 0 end
    return math.floor(upgrade.cost * (1.5 ^ level))
end

function Store:findUpgrade(upgradeId)
    for _, upgrade in ipairs(STORE_ITEMS.upgrades) do
        if upgrade.id == upgradeId then
            return upgrade
        end
    end
    return nil
end

function Store:findItem(itemId)
    for _, item in ipairs(STORE_ITEMS.items) do
        if item.id == itemId then
            return item
        end
    end
    return nil
end

function Store:findFactionItem(itemId, faction)
    if not STORE_ITEMS.factionItems[faction] then return nil end
    
    for _, item in ipairs(STORE_ITEMS.factionItems[faction]) do
        if item.id == itemId then
            return item
        end
    end
    return nil
end

function Store:canAffordUpgrade(upgradeId)
    local cost = self:getUpgradeCost(upgradeId)
    return gameState.essence >= cost
end

function Store:canAffordItem(itemId)
    local item = self:findItem(itemId)
    if not item then return false end
    return gameState.resources >= item.cost
end

function Store:canAffordFactionItem(itemId, faction)
    local item = self:findFactionItem(itemId, faction)
    if not item then return false end
    return gameState.resources >= item.cost
end

function Store:purchaseUpgrade(upgradeId)
    if not self:canAffordUpgrade(upgradeId) then
        gameState:showNotification("Not enough essence!")
        return false
    end
    
    local upgrade = self:findUpgrade(upgradeId)
    if not upgrade then return false end
    
    local level = self:getUpgradeLevel(upgradeId)
    if level >= upgrade.maxLevel then
        gameState:showNotification("Maximum level reached!")
        return false
    end
    
    local cost = self:getUpgradeCost(upgradeId)
    gameState.essence = gameState.essence - cost
    
    self.upgrades[upgradeId] = level + 1
    self:savePurchases()
    
    -- Apply upgrade effect
    local effect = upgrade.effect(level + 1)
    gameState:applyUpgrade(upgradeId, effect)
    
    gameState:showNotification("Upgrade purchased!")
    return true
end

function Store:purchaseItem(itemId)
    if not self:canAffordItem(itemId) then
        gameState:showNotification("Not enough resources!")
        return false
    end
    
    local item = self:findItem(itemId)
    if not item then return false end
    
    gameState.resources = gameState.resources - item.cost
    item.effect()
    
    gameState:showNotification("Item purchased!")
    return true
end

function Store:purchaseFactionItem(itemId, faction)
    if not self:canAffordFactionItem(itemId, faction) then
        gameState:showNotification("Not enough resources!")
        return false
    end
    
    local item = self:findFactionItem(itemId, faction)
    if not item then return false end
    
    gameState.resources = gameState.resources - item.cost
    item.effect()
    
    gameState:showNotification("Item purchased!")
    return true
end

function Store:createStoreUI()
    local panel = loveframes.Create("panel")
    panel:SetName("Store")
    panel:SetSize(600, 800)
    panel:Center()
    
    -- Create tabs
    local tabs = loveframes.Create("tabs", panel)
    tabs:SetPos(5, 30)
    tabs:SetSize(590, 765)
    
    -- Upgrades tab
    local upgradesTab = loveframes.Create("panel")
    upgradesTab:SetSize(590, 765)
    tabs:AddTab("Upgrades", upgradesTab)
    
    local upgradesList = loveframes.Create("list", upgradesTab)
    upgradesList:SetPos(5, 5)
    upgradesList:SetSize(580, 755)
    
    for _, upgrade in ipairs(STORE_ITEMS.upgrades) do
        local level = self:getUpgradeLevel(upgrade.id)
        local cost = self:getUpgradeCost(upgrade.id)
        local canAfford = self:canAffordUpgrade(upgrade.id)
        
        local item = loveframes.Create("panel")
        item:SetSize(570, 100)
        
        local name = loveframes.Create("text", item)
        name:SetText(upgrade.name)
        name:SetPos(5, 5)
        
        local description = loveframes.Create("text", item)
        description:SetText(upgrade.description)
        description:SetPos(5, 25)
        
        local levelText = loveframes.Create("text", item)
        levelText:SetText("Level: " .. level .. "/" .. upgrade.maxLevel)
        levelText:SetPos(5, 45)
        
        local costText = loveframes.Create("text", item)
        costText:SetText("Cost: " .. cost .. " essence")
        costText:SetPos(5, 65)
        
        local buyButton = loveframes.Create("button", item)
        buyButton:SetPos(470, 35)
        buyButton:SetSize(90, 30)
        buyButton:SetText("Buy")
        buyButton:SetEnabled(canAfford and level < upgrade.maxLevel)
        buyButton.OnClick = function(object, x, y)
            self:purchaseUpgrade(upgrade.id)
        end
        
        upgradesList:AddItem(item)
    end
    
    -- Items tab
    local itemsTab = loveframes.Create("panel")
    itemsTab:SetSize(590, 765)
    tabs:AddTab("Items", itemsTab)
    
    local itemsList = loveframes.Create("list", itemsTab)
    itemsList:SetPos(5, 5)
    itemsList:SetSize(580, 755)
    
    for _, item in ipairs(STORE_ITEMS.items) do
        local canAfford = self:canAffordItem(item.id)
        
        local itemPanel = loveframes.Create("panel")
        itemPanel:SetSize(570, 100)
        
        local name = loveframes.Create("text", itemPanel)
        name:SetText(item.name)
        name:SetPos(5, 5)
        
        local description = loveframes.Create("text", itemPanel)
        description:SetText(item.description)
        description:SetPos(5, 25)
        
        local costText = loveframes.Create("text", itemPanel)
        costText:SetText("Cost: " .. item.cost .. " resources")
        costText:SetPos(5, 45)
        
        local buyButton = loveframes.Create("button", itemPanel)
        buyButton:SetPos(470, 35)
        buyButton:SetSize(90, 30)
        buyButton:SetText("Buy")
        buyButton:SetEnabled(canAfford)
        buyButton.OnClick = function(object, x, y)
            self:purchaseItem(item.id)
        end
        
        itemsList:AddItem(itemPanel)
    end
    
    -- Faction Items tab
    local factionTab = loveframes.Create("panel")
    factionTab:SetSize(590, 765)
    tabs:AddTab("Faction Items", factionTab)
    
    local factionList = loveframes.Create("list", factionTab)
    factionList:SetPos(5, 5)
    factionList:SetSize(580, 755)
    
    local faction = gameState.selectedFaction
    if STORE_ITEMS.factionItems[faction] then
        for _, item in ipairs(STORE_ITEMS.factionItems[faction]) do
            local canAfford = self:canAffordFactionItem(item.id, faction)
            
            local itemPanel = loveframes.Create("panel")
            itemPanel:SetSize(570, 100)
            
            local name = loveframes.Create("text", itemPanel)
            name:SetText(item.name)
            name:SetPos(5, 5)
            
            local description = loveframes.Create("text", itemPanel)
            description:SetText(item.description)
            description:SetPos(5, 25)
            
            local costText = loveframes.Create("text", itemPanel)
            costText:SetText("Cost: " .. item.cost .. " resources")
            costText:SetPos(5, 45)
            
            local buyButton = loveframes.Create("button", itemPanel)
            buyButton:SetPos(470, 35)
            buyButton:SetSize(90, 30)
            buyButton:SetText("Buy")
            buyButton:SetEnabled(canAfford)
            buyButton.OnClick = function(object, x, y)
                self:purchaseFactionItem(item.id, faction)
            end
            
            factionList:AddItem(itemPanel)
        end
    end
    
    -- Close button
    local closeButton = loveframes.Create("button", panel)
    closeButton:SetPos(250, 760)
    closeButton:SetSize(100, 30)
    closeButton:SetText("Close")
    closeButton.OnClick = function(object, x, y)
        panel:Remove()
    end
    
    return panel
end

return Store 