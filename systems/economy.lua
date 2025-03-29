local Economy = {}
Economy.__index = Economy

-- Faction-specific resources
local FACTION_RESOURCES = {
    radiant = {
        name = "Gold",
        color = {1, 0.8, 0},
        icon = "gold"
    },
    shadow = {
        name = "Shards",
        color = {0.5, 0, 0.5},
        icon = "shard"
    },
    twilight = {
        name = "Crystals",
        color = {0, 0.8, 1},
        icon = "crystal"
    }
}

-- Store items
local STORE_ITEMS = {
    -- Extra lives
    extraLife = {
        name = "Extra Life",
        description = "Gain an additional life",
        cost = 50,
        type = "consumable",
        effect = function()
            gameState.lives = gameState.lives + 1
            gameState:showNotification("Extra life gained!")
        end
    },
    -- Temporary buffs
    damageBoost = {
        name = "Damage Boost",
        description = "+20% tower damage for 1 wave",
        cost = 30,
        type = "temporary",
        duration = 1,
        effect = function()
            for _, tower in ipairs(gameState.towers) do
                tower.stats.damage = tower.stats.damage * 1.2
            end
            gameState:showNotification("Damage boost activated!")
        end
    },
    -- Permanent upgrades
    towerDamage = {
        name = "Tower Damage",
        description = "+5% tower damage permanently",
        cost = 200,
        type = "permanent",
        effect = function()
            gameState.permanentUpgrades.towerDamage = (gameState.permanentUpgrades.towerDamage or 0) + 0.05
            gameState:showNotification("Tower damage permanently increased!")
        end
    },
    towerRange = {
        name = "Tower Range",
        description = "+5% tower range permanently",
        cost = 200,
        type = "permanent",
        effect = function()
            gameState.permanentUpgrades.towerRange = (gameState.permanentUpgrades.towerRange or 0) + 0.05
            gameState:showNotification("Tower range permanently increased!")
        end
    }
}

-- Faction-specific store items
local FACTION_STORE_ITEMS = {
    radiant = {
        holyBlessing = {
            name = "Holy Blessing",
            description = "+10% healing for holy towers",
            cost = 300,
            type = "permanent",
            effect = function()
                gameState.permanentUpgrades.holyHealing = (gameState.permanentUpgrades.holyHealing or 0) + 0.1
                gameState:showNotification("Holy healing permanently increased!")
            end
        }
    },
    shadow = {
        soulHarvest = {
            name = "Soul Harvest",
            description = "+10% minion health",
            cost = 300,
            type = "permanent",
            effect = function()
                gameState.permanentUpgrades.minionHealth = (gameState.permanentUpgrades.minionHealth or 0) + 0.1
                gameState:showNotification("Minion health permanently increased!")
            end
        }
    },
    twilight = {
        balanceHarmony = {
            name = "Balance Harmony",
            description = "+5% hybrid damage",
            cost = 300,
            type = "permanent",
            effect = function()
                gameState.permanentUpgrades.hybridDamage = (gameState.permanentUpgrades.hybridDamage or 0) + 0.05
                gameState:showNotification("Hybrid damage permanently increased!")
            end
        }
    }
}

function Economy.new()
    local self = setmetatable({}, Economy)
    
    self.resources = 0
    self.essence = 0
    self.faction = nil
    self.factionResource = nil
    self.permanentUpgrades = {}
    self.temporaryBuffs = {}
    
    return self
end

function Economy:setFaction(faction)
    self.faction = faction
    self.factionResource = FACTION_RESOURCES[faction]
end

function Economy:addResources(amount)
    self.resources = self.resources + amount
end

function Economy:spendResources(amount)
    if self.resources >= amount then
        self.resources = self.resources - amount
        return true
    end
    return false
end

function Economy:addEssence(amount)
    self.essence = self.essence + amount
end

function Economy:spendEssence(amount)
    if self.essence >= amount then
        self.essence = self.essence - amount
        return true
    end
    return false
end

function Economy:buyItem(itemId)
    local item = STORE_ITEMS[itemId]
    if not item then return false end
    
    if self:spendResources(item.cost) then
        item.effect()
        return true
    end
    return false
end

function Economy:buyFactionItem(itemId)
    local item = FACTION_STORE_ITEMS[self.faction][itemId]
    if not item then return false end
    
    if self:spendEssence(item.cost) then
        item.effect()
        return true
    end
    return false
end

function Economy:applyPermanentUpgrades()
    -- Apply all permanent upgrades to towers
    for _, tower in ipairs(gameState.towers) do
        if self.permanentUpgrades.towerDamage then
            tower.stats.damage = tower.stats.damage * (1 + self.permanentUpgrades.towerDamage)
        end
        if self.permanentUpgrades.towerRange then
            tower.stats.range = tower.stats.range * (1 + self.permanentUpgrades.towerRange)
        end
        if self.permanentUpgrades.holyHealing and tower.faction == "radiant" then
            tower.stats.healing = tower.stats.healing * (1 + self.permanentUpgrades.holyHealing)
        end
        if self.permanentUpgrades.minionHealth and tower.faction == "shadow" then
            tower.stats.minionHealth = tower.stats.minionHealth * (1 + self.permanentUpgrades.minionHealth)
        end
        if self.permanentUpgrades.hybridDamage and tower.faction == "twilight" then
            tower.stats.damage = tower.stats.damage * (1 + self.permanentUpgrades.hybridDamage)
        end
    end
end

function Economy:update(dt)
    -- Update temporary buffs
    for buffId, buff in pairs(self.temporaryBuffs) do
        buff.duration = buff.duration - dt
        if buff.duration <= 0 then
            self:removeTemporaryBuff(buffId)
        end
    end
    
    -- Passive essence generation
    if gameState.lives == gameState.maxLives then
        self:addEssence(10 * dt / 60) -- 10 essence per minute
    end
end

function Economy:addTemporaryBuff(buffId, duration)
    self.temporaryBuffs[buffId] = {
        duration = duration,
        effect = STORE_ITEMS[buffId].effect
    }
    STORE_ITEMS[buffId].effect()
end

function Economy:removeTemporaryBuff(buffId)
    local buff = self.temporaryBuffs[buffId]
    if buff then
        -- Remove effect
        if buffId == "damageBoost" then
            for _, tower in ipairs(gameState.towers) do
                tower.stats.damage = tower.stats.damage / 1.2
            end
        end
        self.temporaryBuffs[buffId] = nil
    end
end

function Economy:draw()
    -- Draw resources
    love.graphics.setColor(self.factionResource.color)
    love.graphics.draw(sprites.ui[self.factionResource.icon], 10, 10)
    love.graphics.print(self.resources, 40, 10)
    
    -- Draw essence
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.draw(sprites.ui.essence, 10, 40)
    love.graphics.print(self.essence, 40, 40)
    
    -- Draw temporary buffs
    local y = 70
    for buffId, buff in pairs(self.temporaryBuffs) do
        love.graphics.setColor(1, 0.8, 0)
        love.graphics.draw(sprites.ui.buff, 10, y)
        love.graphics.print(STORE_ITEMS[buffId].name .. " (" .. math.ceil(buff.duration) .. "s)", 40, y)
        y = y + 30
    end
end

function Economy:drawStore()
    -- Draw store UI
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw items
    local y = 100
    for itemId, item in pairs(STORE_ITEMS) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(item.name, 50, y)
        love.graphics.print(item.description, 50, y + 20)
        love.graphics.print(item.cost .. " " .. self.factionResource.name, 50, y + 40)
        y = y + 80
    end
    
    -- Draw faction-specific items
    y = y + 20
    love.graphics.setColor(self.factionResource.color)
    love.graphics.print("Faction-Specific Items:", 50, y)
    y = y + 40
    
    for itemId, item in pairs(FACTION_STORE_ITEMS[self.faction]) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(item.name, 50, y)
        love.graphics.print(item.description, 50, y + 20)
        love.graphics.print(item.cost .. " Essence", 50, y + 40)
        y = y + 80
    end
end

return Economy 