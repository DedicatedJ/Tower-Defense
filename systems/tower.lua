local Tower = {
    types = {},
    factionTowers = {}
}

-- Dependencies
local Error = require 'utils.error'
local Bump = require 'libs.bump.bump'
local Timer = require 'libs.hump.timer'

-- Tower class
local TowerInstance = {}
TowerInstance.__index = TowerInstance

-- Initialize the tower data
function Tower.init()
    Tower.types = {
        -- Human faction towers
        archer = {
            id = "archer",
            name = "Archer Tower",
            description = "Basic ranged tower with decent damage and range",
            faction = "human",
            cost = 100,
            damage = 15,
            range = 150,
            attackSpeed = 1.5,
            projectileSpeed = 300,
            projectileType = "arrow",
            upgrades = {
                {
                    name = "Improved Arrows",
                    description = "Increase damage by 20%",
                    cost = 75,
                    damageMod = 1.2
                },
                {
                    name = "Eagle Eye",
                    description = "Increase range by 15%",
                    cost = 90,
                    rangeMod = 1.15
                },
                {
                    name = "Rapid Fire",
                    description = "Increase attack speed by 25%",
                    cost = 120,
                    attackSpeedMod = 1.25
                }
            }
        },
        cannon = {
            id = "cannon",
            name = "Cannon Tower",
            description = "Slow-firing tower with area damage",
            faction = "human",
            cost = 175,
            damage = 40,
            range = 120,
            attackSpeed = 3.0,
            projectileSpeed = 200,
            projectileType = "cannonball",
            aoeRadius = 60,
            upgrades = {
                {
                    name = "Heavy Ammo",
                    description = "Increase damage by 30%",
                    cost = 120,
                    damageMod = 1.3
                },
                {
                    name = "Blast Radius",
                    description = "Increase AoE radius by 20%",
                    cost = 140,
                    aoeRadiusMod = 1.2
                }
            }
        },
        mage = {
            id = "mage",
            name = "Mage Tower",
            description = "Magic tower that slows enemies",
            faction = "human",
            cost = 150,
            damage = 10,
            range = 130,
            attackSpeed = 2.0,
            projectileSpeed = 250,
            projectileType = "magic",
            slowAmount = 0.3,
            slowDuration = 2.5,
            upgrades = {
                {
                    name = "Frost Magic",
                    description = "Increase slow effect by 15%",
                    cost = 100,
                    slowMod = 1.15
                },
                {
                    name = "Extended Curse",
                    description = "Increase slow duration by 30%",
                    cost = 110,
                    slowDurationMod = 1.3
                }
            }
        },
        
        -- Elf faction towers
        scout = {
            id = "scout",
            name = "Scout Tower",
            description = "Fast-firing tower with long range",
            faction = "elf",
            cost = 100,
            damage = 12,
            range = 180,
            attackSpeed = 1.0,
            projectileSpeed = 350,
            projectileType = "arrow",
            upgrades = {
                {
                    name = "Sharp Arrows",
                    description = "Increase damage by 15%",
                    cost = 80,
                    damageMod = 1.15
                },
                {
                    name = "Eagle Vision",
                    description = "Increase range by 20%",
                    cost = 100,
                    rangeMod = 1.2
                }
            }
        },
        druid = {
            id = "druid",
            name = "Druid Tower",
            description = "Nature magic that damages over time",
            faction = "elf",
            cost = 150,
            damage = 5,
            dotDamage = 20,
            dotDuration = 3,
            range = 140,
            attackSpeed = 2.5,
            projectileSpeed = 220,
            projectileType = "nature",
            upgrades = {
                {
                    name = "Toxic Spores",
                    description = "Increase DoT damage by 25%",
                    cost = 120,
                    dotDamageMod = 1.25
                },
                {
                    name = "Lingering Poison",
                    description = "Increase DoT duration by 30%",
                    cost = 130,
                    dotDurationMod = 1.3
                }
            }
        },
        enchanter = {
            id = "enchanter",
            name = "Enchanter Tower",
            description = "Buffs nearby towers, increasing their damage",
            faction = "elf",
            cost = 200,
            buffRange = 100,
            buffAmount = 0.2,
            range = 0,
            supportType = true,
            upgrades = {
                {
                    name = "Arcane Empowerment",
                    description = "Increase buff amount by 15%",
                    cost = 150,
                    buffMod = 1.15
                },
                {
                    name = "Extended Aura",
                    description = "Increase buff range by 25%",
                    cost = 120,
                    buffRangeMod = 1.25
                }
            }
        },
        
        -- Dwarf faction towers
        turret = {
            id = "turret",
            name = "Turret",
            description = "Mechanical tower with high attack speed",
            faction = "dwarf",
            cost = 125,
            damage = 8,
            range = 120,
            attackSpeed = 0.5,
            projectileSpeed = 400,
            projectileType = "bullet",
            upgrades = {
                {
                    name = "Reinforced Bullets",
                    description = "Increase damage by 25%",
                    cost = 110,
                    damageMod = 1.25
                },
                {
                    name = "Rapid Reloader",
                    description = "Increase attack speed by 20%",
                    cost = 130,
                    attackSpeedMod = 1.2
                }
            }
        },
        bombard = {
            id = "bombard",
            name = "Bombard",
            description = "Explosive tower with massive area damage",
            faction = "dwarf",
            cost = 200,
            damage = 30,
            range = 110,
            attackSpeed = 3.5,
            projectileSpeed = 180,
            projectileType = "bomb",
            aoeRadius = 80,
            upgrades = {
                {
                    name = "Bigger Bombs",
                    description = "Increase damage by 35%",
                    cost = 160,
                    damageMod = 1.35
                },
                {
                    name = "Shrapnel",
                    description = "Increase AoE radius by 25%",
                    cost = 140,
                    aoeRadiusMod = 1.25
                }
            }
        },
        flamethrower = {
            id = "flamethrower",
            name = "Flamethrower",
            description = "Short range tower that damages all enemies in a cone",
            faction = "dwarf",
            cost = 175,
            damage = 20,
            range = 80,
            attackSpeed = 0.3,
            coneAngle = 45,
            projectileType = "flame",
            upgrades = {
                {
                    name = "White-hot Flames",
                    description = "Increase damage by 30%",
                    cost = 150,
                    damageMod = 1.3
                },
                {
                    name = "Wider Spray",
                    description = "Increase cone angle by 20%",
                    cost = 120,
                    coneAngleMod = 1.2
                }
            }
        }
    }
    
    -- Organize towers by faction
    Tower.factionTowers = {
        human = {},
        elf = {},
        dwarf = {}
    }
    
    for id, tower in pairs(Tower.types) do
        if Tower.factionTowers[tower.faction] then
            table.insert(Tower.factionTowers[tower.faction], id)
        end
    end
    
    -- Load tower sprites
    Tower.sprites = {}
    local success, result = Error.pcall(function()
        for id, _ in pairs(Tower.types) do
            Tower.sprites[id] = love.graphics.newImage("sprites/towers/" .. id .. ".png")
        end
    end)
    
    if not success then
        Error.show("Failed to load tower sprites: " .. tostring(result))
    end
    
    -- Load projectile sprites
    Tower.projectileSprites = {}
    success, result = Error.pcall(function()
        local projectileTypes = {"arrow", "cannonball", "magic", "nature", "bullet", "bomb", "flame"}
        for _, type in ipairs(projectileTypes) do
            Tower.projectileSprites[type] = love.graphics.newImage("sprites/projectiles/" .. type .. ".png")
        end
    end)
    
    if not success then
        Error.show("Failed to load projectile sprites: " .. tostring(result))
    end
end

-- Get all towers for a specific faction
function Tower.getTowersByFaction(faction)
    if not Tower.factionTowers[faction] then
        return {}
    end
    
    local result = {}
    for _, id in ipairs(Tower.factionTowers[faction]) do
        table.insert(result, Tower.types[id])
    end
    
    return result
end

-- Create a new tower instance
function Tower.create(towerType, gridX, gridY)
    local towerData = Tower.types[towerType]
    if not towerData then
        Error.show("Invalid tower type: " .. tostring(towerType))
        return nil
    end
    
    local tower = setmetatable({}, TowerInstance)
    
    -- Copy tower data
    for k, v in pairs(towerData) do
        tower[k] = v
    end
    
    -- Instance-specific properties
    tower.gridX = gridX
    tower.gridY = gridY
    tower.level = 1
    tower.target = nil
    tower.attackTimer = 0
    tower.upgradeLevel = 0
    tower.appliedUpgrades = {}
    tower.buffs = {}
    tower.timer = Timer.new()
    
    return tower
end

-- Draw tower preview during placement
function Tower.drawPreview(towerType, x, y)
    local towerData = Tower.types[towerType]
    if not towerData then return end
    
    local sprite = Tower.sprites[towerType]
    if sprite then
        love.graphics.draw(sprite, x, y, 0, 1, 1)
    else
        -- Fallback if sprite is missing
        love.graphics.rectangle("fill", x + 5, y + 5, 40, 40)
    end
    
    -- Draw range indicator
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.circle("fill", x + 25, y + 25, towerData.range)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.circle("line", x + 25, y + 25, towerData.range)
end

-- Tower instance methods

-- Update tower logic
function TowerInstance:update(dt, gameState)
    -- Skip if no map available
    if not gameState.map then return end
    
    -- Update timer
    self.timer:update(dt)
    
    -- Get world position
    local x, y = gameState.map:gridToWorld(self.gridX, self.gridY)
    x = x + gameState.map.tileSize / 2
    y = y + gameState.map.tileSize / 2
    
    -- Calculate total stats with upgrades and buffs
    local totalDamage = self.damage
    local totalRange = self.range
    local totalAttackSpeed = self.attackSpeed
    
    -- Apply upgrades
    for _, upgrade in ipairs(self.appliedUpgrades) do
        if upgrade.damageMod then
            totalDamage = totalDamage * upgrade.damageMod
        end
        if upgrade.rangeMod then
            totalRange = totalRange * upgrade.rangeMod
        end
        if upgrade.attackSpeedMod then
            totalAttackSpeed = totalAttackSpeed / upgrade.attackSpeedMod
        end
    end
    
    -- Apply buffs
    for _, buff in pairs(self.buffs) do
        if buff.damageMod then
            totalDamage = totalDamage * buff.damageMod
        end
        if buff.rangeMod then
            totalRange = totalRange * buff.rangeMod
        end
        if buff.attackSpeedMod then
            totalAttackSpeed = totalAttackSpeed / buff.attackSpeedMod
        end
    end
    
    -- Support towers give buffs to nearby towers
    if self.supportType then
        local buffRange = self.buffRange
        
        -- Apply upgrade modifiers to buff range
        for _, upgrade in ipairs(self.appliedUpgrades) do
            if upgrade.buffRangeMod then
                buffRange = buffRange * upgrade.buffRangeMod
            end
        end
        
        -- Calculate buff amount
        local buffAmount = self.buffAmount
        for _, upgrade in ipairs(self.appliedUpgrades) do
            if upgrade.buffMod then
                buffAmount = buffAmount * upgrade.buffMod
            end
        end
        
        -- Apply buffs to nearby towers
        for _, tower in ipairs(gameState.towers) do
            if tower ~= self then
                local towerX, towerY = gameState.map:gridToWorld(tower.gridX, tower.gridY)
                towerX = towerX + gameState.map.tileSize / 2
                towerY = towerY + gameState.map.tileSize / 2
                
                local dist = math.sqrt((x - towerX)^2 + (y - towerY)^2)
                if dist <= buffRange then
                    -- Apply buff
                    tower.buffs[self.id .. self.gridX .. self.gridY] = {
                        source = self,
                        damageMod = 1 + buffAmount,
                        duration = 0.5  -- Refresh every 0.5 seconds
                    }
                end
            end
        end
        
        return -- Support towers don't attack
    end
    
    -- Update attack timer
    self.attackTimer = self.attackTimer - dt
    
    -- Clean up expired buffs
    for id, buff in pairs(self.buffs) do
        buff.duration = buff.duration - dt
        if buff.duration <= 0 then
            self.buffs[id] = nil
        end
    end
    
    -- Find target if we don't have one or it's dead/out of range
    if not self.target or self.target.dead or self.target.reachedEnd then
        self.target = nil
    else
        local targetX, targetY = self.target.x, self.target.y
        local dist = math.sqrt((x - targetX)^2 + (y - targetY)^2)
        if dist > totalRange then
            self.target = nil
        end
    end
    
    -- Find a new target
    if not self.target then
        local closestEnemy = nil
        local closestDist = totalRange
        
        for _, enemy in ipairs(gameState.enemies) do
            if not enemy.dead and not enemy.reachedEnd then
                local dist = math.sqrt((x - enemy.x)^2 + (y - enemy.y)^2)
                if dist < closestDist then
                    closestEnemy = enemy
                    closestDist = dist
                end
            end
        end
        
        self.target = closestEnemy
    end
    
    -- Attack if we have a target and the timer is up
    if self.target and self.attackTimer <= 0 then
        self:attack(gameState)
        self.attackTimer = totalAttackSpeed
    end
end

-- Tower attacks its current target
function TowerInstance:attack(gameState)
    -- Skip if no target
    if not self.target then return end
    
    -- Get tower position
    local x, y = gameState.map:gridToWorld(self.gridX, self.gridY)
    x = x + gameState.map.tileSize / 2
    y = y + gameState.map.tileSize / 2
    
    -- Calculate direction
    local targetX, targetY = self.target.x, self.target.y
    local dx, dy = targetX - x, targetY - y
    local angle = math.atan2(dy, dx)
    
    -- Create projectile
    local projectile = {
        x = x,
        y = y,
        angle = angle,
        speed = self.projectileSpeed,
        damage = self.damage,
        type = self.projectileType,
        source = self,
        target = self.target,
        destroyed = false,
        
        -- Special properties
        aoeRadius = self.aoeRadius,
        slowAmount = self.slowAmount,
        slowDuration = self.slowDuration,
        dotDamage = self.dotDamage,
        dotDuration = self.dotDuration,
        
        -- Apply upgrades to projectile
        appliedUpgrades = self.appliedUpgrades,
        
        -- Cone attack for flamethrower
        coneAngle = self.coneAngle,
        
        -- Update projectile logic
        update = function(self, dt, gameState)
            -- Special case for flamethrower - damage all enemies in cone immediately
            if self.type == "flame" then
                self:damageEnemiesInCone(gameState)
                self.destroyed = true
                return
            end
            
            -- Move projectile
            self.x = self.x + math.cos(self.angle) * self.speed * dt
            self.y = self.y + math.sin(self.angle) * self.speed * dt
            
            -- Check if projectile is out of bounds
            if self.x < 0 or self.x > love.graphics.getWidth() or
               self.y < 0 or self.y > love.graphics.getHeight() then
                self.destroyed = true
                return
            end
            
            -- Check for collision with enemies
            for _, enemy in ipairs(gameState.enemies) do
                if not enemy.dead and not enemy.reachedEnd then
                    local dist = math.sqrt((self.x - enemy.x)^2 + (self.y - enemy.y)^2)
                    if dist < enemy.radius or enemy == self.target then
                        -- Hit enemy
                        self:damageEnemy(enemy, gameState)
                        
                        -- Destroy projectile unless it's a penetrating type
                        if self.type ~= "nature" then
                            self.destroyed = true
                        end
                        
                        -- AOE damage
                        if self.aoeRadius then
                            self:damageEnemiesInRadius(enemy.x, enemy.y, gameState)
                        end
                        
                        break
                    end
                end
            end
        end,
        
        -- Draw projectile
        draw = function(self)
            love.graphics.setColor(1, 1, 1, 1)
            
            local sprite = Tower.projectileSprites[self.type]
            if sprite then
                love.graphics.draw(sprite, self.x, self.y, self.angle, 0.5, 0.5, sprite:getWidth() / 2, sprite:getHeight() / 2)
            else
                -- Fallback if sprite is missing
                love.graphics.circle("fill", self.x, self.y, 5)
            end
        end,
        
        -- Damage a single enemy
        damageEnemy = function(self, enemy, gameState)
            -- Calculate total damage with upgrades
            local totalDamage = self.damage
            for _, upgrade in ipairs(self.appliedUpgrades) do
                if upgrade.damageMod then
                    totalDamage = totalDamage * upgrade.damageMod
                end
            end
            
            -- Apply damage
            enemy:takeDamage(totalDamage)
            
            -- Apply DoT effect
            if self.dotDamage and self.dotDuration then
                local dotDamage = self.dotDamage
                local dotDuration = self.dotDuration
                
                -- Apply upgrades to DoT
                for _, upgrade in ipairs(self.appliedUpgrades) do
                    if upgrade.dotDamageMod then
                        dotDamage = dotDamage * upgrade.dotDamageMod
                    end
                    if upgrade.dotDurationMod then
                        dotDuration = dotDuration * upgrade.dotDurationMod
                    end
                end
                
                enemy:applyDot(dotDamage, dotDuration)
            end
            
            -- Apply slow effect
            if self.slowAmount and self.slowDuration then
                local slowAmount = self.slowAmount
                local slowDuration = self.slowDuration
                
                -- Apply upgrades to slow
                for _, upgrade in ipairs(self.appliedUpgrades) do
                    if upgrade.slowMod then
                        slowAmount = slowAmount * upgrade.slowMod
                    end
                    if upgrade.slowDurationMod then
                        slowDuration = slowDuration * upgrade.slowDurationMod
                    end
                end
                
                enemy:applySlow(slowAmount, slowDuration)
            end
        end,
        
        -- Damage enemies in radius (for AOE attacks)
        damageEnemiesInRadius = function(self, centerX, centerY, gameState)
            -- Calculate total AOE radius with upgrades
            local totalRadius = self.aoeRadius
            for _, upgrade in ipairs(self.appliedUpgrades) do
                if upgrade.aoeRadiusMod then
                    totalRadius = totalRadius * upgrade.aoeRadiusMod
                end
            end
            
            for _, enemy in ipairs(gameState.enemies) do
                if not enemy.dead and not enemy.reachedEnd then
                    local dist = math.sqrt((centerX - enemy.x)^2 + (centerY - enemy.y)^2)
                    if dist <= totalRadius then
                        local distFactor = 1 - (dist / totalRadius)  -- More damage closer to center
                        self:damageEnemy(enemy, gameState, distFactor)
                    end
                end
            end
            
            -- Visual effect for AOE
            local effect = {
                x = centerX,
                y = centerY,
                radius = 5,
                maxRadius = totalRadius,
                duration = 0.5,
                currentTime = 0,
                
                update = function(self, dt)
                    self.currentTime = self.currentTime + dt
                    self.radius = (self.currentTime / self.duration) * self.maxRadius
                    if self.currentTime >= self.duration then
                        return true -- Done
                    end
                    return false
                end,
                
                draw = function(self)
                    love.graphics.setColor(1, 0.5, 0, 0.5 * (1 - self.currentTime / self.duration))
                    love.graphics.circle("fill", self.x, self.y, self.radius)
                    love.graphics.setColor(1, 0.7, 0, 0.7 * (1 - self.currentTime / self.duration))
                    love.graphics.circle("line", self.x, self.y, self.radius)
                end
            }
            
            -- Add effect to game state
            if gameState.effects then
                table.insert(gameState.effects, effect)
            end
        end,
        
        -- Damage enemies in cone (for flamethrower)
        damageEnemiesInCone = function(self, gameState)
            -- Calculate cone angle with upgrades
            local totalConeAngle = self.coneAngle
            for _, upgrade in ipairs(self.appliedUpgrades) do
                if upgrade.coneAngleMod then
                    totalConeAngle = totalConeAngle * upgrade.coneAngleMod
                end
            end
            
            -- Convert to radians and half-angle
            local halfAngle = math.rad(totalConeAngle) / 2
            
            -- Get tower position
            local x, y = self.x, self.y
            
            for _, enemy in ipairs(gameState.enemies) do
                if not enemy.dead and not enemy.reachedEnd then
                    local dx, dy = enemy.x - x, enemy.y - y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist <= self.source.range then
                        local angle = math.atan2(dy, dx)
                        local angleDiff = math.abs((angle - self.angle + math.pi) % (2 * math.pi) - math.pi)
                        
                        if angleDiff <= halfAngle then
                            self:damageEnemy(enemy, gameState)
                        end
                    end
                end
            end
        end
    }
    
    -- Add projectile to game state
    table.insert(gameState.projectiles, projectile)
    
    -- Play sound effect based on tower type
    local soundEffects = {
        arrow = "bowShot",
        cannonball = "cannonFire",
        magic = "magicCast",
        nature = "natureCast",
        bullet = "gunshot",
        bomb = "bombLaunch",
        flame = "flamethrower"
    }
    
    local soundEffect = soundEffects[self.projectileType]
    if soundEffect then
        playSound('sfx', soundEffect)
    end
end

-- Draw the tower
function TowerInstance:draw()
    -- Get the map from game state
    local gameState = _G.gameState
    if not gameState or not gameState.map then return end
    
    -- Get world position
    local x, y = gameState.map:gridToWorld(self.gridX, self.gridY)
    
    -- Draw tower sprite
    love.graphics.setColor(1, 1, 1, 1)
    local sprite = Tower.sprites[self.id]
    if sprite then
        love.graphics.draw(sprite, x, y, 0, 1, 1)
    else
        -- Fallback if sprite is missing
        love.graphics.rectangle("fill", x + 5, y + 5, gameState.map.tileSize - 10, gameState.map.tileSize - 10)
    end
    
    -- Draw upgrade indicator
    if self.upgradeLevel > 0 then
        love.graphics.setColor(1, 0.8, 0, 1)
        for i = 1, self.upgradeLevel do
            love.graphics.rectangle("fill", x + 5 + (i-1) * 8, y + 5, 6, 6)
        end
    end
    
    -- Draw buff indicator
    if next(self.buffs) ~= nil then
        love.graphics.setColor(0, 0.8, 1, 0.7)
        love.graphics.circle("line", x + gameState.map.tileSize / 2, y + gameState.map.tileSize / 2, gameState.map.tileSize / 2 + 3)
    end
    
    -- Draw range indicator if selected
    if gameState.selectedTowerX == self.gridX and gameState.selectedTowerY == self.gridY then
        -- Calculate total range with upgrades and buffs
        local totalRange = self.range
        
        -- Apply upgrades
        for _, upgrade in ipairs(self.appliedUpgrades) do
            if upgrade.rangeMod then
                totalRange = totalRange * upgrade.rangeMod
            end
        end
        
        -- Apply buffs
        for _, buff in pairs(self.buffs) do
            if buff.rangeMod then
                totalRange = totalRange * buff.rangeMod
            end
        end
        
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.circle("fill", x + gameState.map.tileSize / 2, y + gameState.map.tileSize / 2, totalRange)
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.circle("line", x + gameState.map.tileSize / 2, y + gameState.map.tileSize / 2, totalRange)
    end
end

-- Upgrade the tower
function TowerInstance:upgrade(upgradeIndex)
    if not self.upgrades then return false end
    
    local upgrade = self.upgrades[upgradeIndex]
    if not upgrade then return false end
    
    -- Check if this upgrade is already applied
    for _, appliedUpgrade in ipairs(self.appliedUpgrades) do
        if appliedUpgrade.name == upgrade.name then
            return false
        end
    end
    
    -- Apply the upgrade
    table.insert(self.appliedUpgrades, upgrade)
    self.upgradeLevel = self.upgradeLevel + 1
    
    return true, upgrade.cost
end

-- Get available upgrades for this tower
function TowerInstance:getAvailableUpgrades()
    if not self.upgrades then return {} end
    
    local availableUpgrades = {}
    
    for i, upgrade in ipairs(self.upgrades) do
        local alreadyApplied = false
        
        -- Check if this upgrade is already applied
        for _, appliedUpgrade in ipairs(self.appliedUpgrades) do
            if appliedUpgrade.name == upgrade.name then
                alreadyApplied = true
                break
            end
        end
        
        if not alreadyApplied then
            table.insert(availableUpgrades, {
                index = i,
                name = upgrade.name,
                description = upgrade.description,
                cost = upgrade.cost
            })
        end
    end
    
    return availableUpgrades
end

-- Get tower info for display
function TowerInstance:getInfo()
    -- Calculate total stats with upgrades and buffs
    local totalDamage = self.damage
    local totalRange = self.range
    local totalAttackSpeed = self.attackSpeed
    
    -- Apply upgrades
    for _, upgrade in ipairs(self.appliedUpgrades) do
        if upgrade.damageMod then
            totalDamage = totalDamage * upgrade.damageMod
        end
        if upgrade.rangeMod then
            totalRange = totalRange * upgrade.rangeMod
        end
        if upgrade.attackSpeedMod then
            totalAttackSpeed = totalAttackSpeed / upgrade.attackSpeedMod
        end
    end
    
    -- Apply buffs
    for _, buff in pairs(self.buffs) do
        if buff.damageMod then
            totalDamage = totalDamage * buff.damageMod
        end
        if buff.rangeMod then
            totalRange = totalRange * buff.rangeMod
        end
        if buff.attackSpeedMod then
            totalAttackSpeed = totalAttackSpeed / buff.attackSpeedMod
        end
    end
    
    return {
        name = self.name,
        description = self.description,
        level = self.upgradeLevel + 1,
        damage = math.floor(totalDamage),
        range = math.floor(totalRange),
        attackSpeed = string.format("%.2f", math.floor(1 / totalAttackSpeed * 100) / 100),
        upgrades = self:getAvailableUpgrades(),
        special = {
            aoeRadius = self.aoeRadius,
            slowAmount = self.slowAmount,
            slowDuration = self.slowDuration,
            dotDamage = self.dotDamage,
            dotDuration = self.dotDuration,
            coneAngle = self.coneAngle,
            buffAmount = self.buffAmount,
            buffRange = self.buffRange
        }
    }
end

-- Return the module
return Tower 