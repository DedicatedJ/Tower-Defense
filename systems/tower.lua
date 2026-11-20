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
    if Tower.initialized then return end
    
    -- Initialize tower data by faction
    Tower.HUMAN = {
        archer_tower = {
            id = "archer_tower",
            name = "Archer Tower",
            description = "Basic tower with arrows",
            faction = "human",
            cost = 100,
            damage = 15,
            range = 150,
            attackSpeed = 1.0,
            projectileType = "arrow",
            sprite = "sprites/towers/archer.png"
        },
        cannon_tower = {
            id = "cannon_tower",
            name = "Cannon Tower",
            description = "Slow but powerful tower",
            faction = "human",
            cost = 150,
            damage = 40,
            range = 120,
            attackSpeed = 2.0,
            projectileType = "cannonball",
            sprite = "sprites/towers/cannon.png"
        }
    }
    
    Tower.ELF = {
        magic_tower = {
            id = "magic_tower",
            name = "Magic Tower",
            description = "Deals magic damage to enemies",
            faction = "elf",
            cost = 125,
            damage = 20,
            range = 180,
            attackSpeed = 1.2,
            projectileType = "magic",
            sprite = "sprites/towers/magic.png"
        },
        frost_tower = {
            id = "frost_tower", 
            name = "Frost Tower",
            description = "Slows enemies with frost magic",
            faction = "elf",
            cost = 175,
            damage = 10,
            range = 150,
            attackSpeed = 1.0,
            projectileType = "frost",
            sprite = "sprites/towers/frost.png",
            special = {
                slowAmount = 0.5,
                slowDuration = 3.0
            }
        }
    }
    
    Tower.DWARF = {
        crossbow_tower = {
            id = "crossbow_tower",
            name = "Crossbow Tower",
            description = "Rapid fire tower",
            faction = "dwarf",
            cost = 125,
            damage = 8,
            range = 130,
            attackSpeed = 0.5,
            projectileType = "bolt",
            sprite = "sprites/towers/crossbow.png"
        },
        bombard_tower = {
            id = "bombard_tower",
            name = "Bombard Tower",
            description = "Area damage tower",
            faction = "dwarf",
            cost = 200,
            damage = 25,
            range = 120,
            attackSpeed = 2.5,
            projectileType = "bomb",
            sprite = "sprites/towers/bombard.png",
            special = {
                aoeRadius = 60,
                aoeDamageMultiplier = 0.5
            }
        }
    }
    
    -- Create default sprites for towers without images
    Tower.sprites = {}
    for _, faction in pairs({Tower.HUMAN, Tower.ELF, Tower.DWARF}) do
        for id, tower in pairs(faction) do
            Tower.sprites[id] = Tower.createDefaultSprite(tower)
        end
    end

    -- Painted sprites (see art/README.md), loaded once and shared by every
    -- instance. Towers without a file keep the generated default above.
    Tower.images = {}
    for _, faction in pairs({Tower.HUMAN, Tower.ELF, Tower.DWARF}) do
        for id, tower in pairs(faction) do
            if type(tower.sprite) == "string" and love.filesystem.getInfo(tower.sprite) then
                local ok, img = pcall(love.graphics.newImage, tower.sprite, { mipmaps = true })
                if ok then
                    img:setFilter("linear", "linear")
                    img:setMipmapFilter("linear")
                    Tower.images[id] = img
                else
                    print("WARNING: Failed to load tower sprite: " .. tower.sprite)
                end
            end
        end
    end

    -- Create default projectile sprites
    Tower.projectileSprites = {
        arrow = Tower.createDefaultProjectileSprite({1, 0.8, 0}),
        cannonball = Tower.createDefaultProjectileSprite({0.3, 0.3, 0.3}),
        magic = Tower.createDefaultProjectileSprite({0.5, 0, 0.8}),
        frost = Tower.createDefaultProjectileSprite({0, 0.7, 1}),
        bolt = Tower.createDefaultProjectileSprite({0.8, 0.5, 0}),
        bomb = Tower.createDefaultProjectileSprite({1, 0.3, 0})
    }
    
    Tower.initialized = true
end

-- Create a default sprite for a tower
function Tower.createDefaultSprite(tower)
    -- Create a new canvas for the tower sprite
    local size = 32
    local canvas = love.graphics.newCanvas(size, size)
    
    -- Set color based on tower faction
    local color = {0.5, 0.5, 0.5} -- Default gray
    if tower.faction == "human" then
        color = {0.9, 0.7, 0.4} -- Gold/brown for human
    elseif tower.faction == "elf" then
        color = {0, 0.8, 0.5} -- Green for elf
    elseif tower.faction == "dwarf" then
        color = {0.6, 0.4, 0.2} -- Brown for dwarf
    end
    
    -- Draw to canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Base
    love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7)
    love.graphics.rectangle("fill", 4, 4, 24, 24)
    
    -- Tower top
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", 8, 0, 16, 16)
    
    -- Outline
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", 4, 4, 24, 24)
    love.graphics.rectangle("line", 8, 0, 16, 16)
    
    -- Identifier based on attack type
    if tower.projectileType == "arrow" or tower.projectileType == "bolt" then
        -- Draw bow-like shape
        love.graphics.setColor(0.8, 0.6, 0.3)
        love.graphics.line(14, 4, 18, 4)
        love.graphics.line(14, 4, 14, 12)
        love.graphics.line(18, 4, 18, 12)
    elseif tower.projectileType == "cannonball" or tower.projectileType == "bomb" then
        -- Draw cannon-like shape
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 10, 8, 12, 8)
    elseif tower.projectileType == "magic" or tower.projectileType == "frost" then
        -- Draw crystal-like shape
        love.graphics.setColor(0.8, 0.8, 1.0)
        love.graphics.polygon("fill", 16, 4, 12, 10, 20, 10)
    end
    
    -- Reset canvas
    love.graphics.setCanvas()
    
    return canvas
end

-- Create a default projectile sprite
function Tower.createDefaultProjectileSprite(color)
    -- Create a new canvas for the projectile sprite
    local size = 16
    local canvas = love.graphics.newCanvas(size, size)
    
    -- Draw to canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Draw projectile
    love.graphics.setColor(color)
    love.graphics.circle("fill", 8, 8, 4)
    
    -- Draw outline
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", 8, 8, 4)
    
    -- Reset canvas
    love.graphics.setCanvas()
    
    return canvas
end

-- Get all towers for a specific faction
function Tower.getTowersByFaction(faction)
    if not Tower.initialized then
        Tower.init()
    end
    
    if not faction then
        print("ERROR: Faction is nil in getTowersByFaction")
        -- Return basic towers as fallback
        return {
            {
                id = "basic_archer",
                name = "Archer Tower",
                description = "Basic tower with medium range",
                cost = 100,
                damage = 10,
                range = 150,
                attackSpeed = 1.0
            },
            {
                id = "basic_cannon",
                name = "Cannon Tower",
                description = "Slow but powerful tower",
                cost = 150,
                damage = 30,
                range = 120,
                attackSpeed = 2.0
            }
        }
    end
    
    -- Try to find by faction id first
    local factionId = faction.id
    if not factionId and faction.name then
        -- Try to use lowercase name as fallback
        factionId = string.lower(faction.name)
    end
    
    print("Getting towers for faction: " .. tostring(factionId))
    
    -- Get faction towers
    local factionTowers = {}
    
    if factionId == "radiant" or factionId:find("radiant") or factionId:find("light") then
        factionTowers = Tower.HUMAN
    elseif factionId == "shadow" or factionId:find("shadow") or factionId:find("dark") then
        factionTowers = Tower.ELF
    elseif factionId == "twilight" or factionId:find("twilight") or factionId:find("balance") then
        factionTowers = Tower.DWARF
    else
        -- Return a mix of basic towers as fallback
        factionTowers = {
            Tower.HUMAN.archer_tower,
            Tower.ELF.magic_tower,
            Tower.DWARF.bombard_tower
        }
    end
    
    -- Convert to array
    local result = {}
    for id, tower in pairs(factionTowers) do
        if type(tower) == "table" then
            -- Clone the tower data
            local towerCopy = {}
            for k, v in pairs(tower) do
                towerCopy[k] = v
            end
            
            -- Ensure id is set from key if not present
            if not towerCopy.id then
                towerCopy.id = id
            end
            
            table.insert(result, towerCopy)
        end
    end
    
    print("Found " .. #result .. " towers for faction " .. tostring(factionId))
    
    return result
end

-- Create a new tower instance
function Tower.create(towerType, gridX, gridY, tileSize)
    if not Tower.initialized then
        Tower.init()
    end
    
    print("Creating tower: " .. tostring(towerType) .. " at grid position " .. gridX .. "," .. gridY)
    
    -- Find tower data
    local towerData = nil
    
    -- Search through all factions
    for _, faction in pairs({Tower.HUMAN, Tower.ELF, Tower.DWARF}) do
        for id, tower in pairs(faction) do
            if id == towerType or tower.id == towerType then
                towerData = tower
                break
            end
        end
        if towerData then break end
    end
    
    if not towerData then
        print("ERROR: Invalid tower type: " .. tostring(towerType))
        -- Use basic archer as fallback
        towerData = Tower.HUMAN.archer_tower
    end
    
    -- Clone the tower data
    local instance = {}
    for k, v in pairs(towerData) do
        instance[k] = v
    end
    
    -- Set instance-specific properties
    instance.gridX = gridX
    instance.gridY = gridY
    instance.tileSize = tileSize or 32
    instance.level = 1
    instance.target = nil
    instance.cooldown = 0

    -- Runtime state used by TowerInstance:update/attack/getInfo
    instance.timer = Timer.new()
    instance.attackTimer = 0
    instance.appliedUpgrades = {}
    instance.buffs = {}
    instance.upgradeLevel = 0
    instance.projectileSpeed = instance.projectileSpeed or 300

    -- Flatten `special` (slow, AOE, ...) into the fields projectiles read
    if type(towerData.special) == "table" then
        for k, v in pairs(towerData.special) do
            if instance[k] == nil then
                instance[k] = v
            end
        end
    end

    -- Painted sprite if one was loaded in Tower.init, else the generated default
    instance.painted = Tower.images and Tower.images[instance.id] ~= nil
    instance.spriteImg = (Tower.images and Tower.images[instance.id])
        or (Tower.sprites and Tower.sprites[instance.id])
    
    -- Mix in tower instance methods
    for k, v in pairs(TowerInstance) do
        instance[k] = v
    end
    
    print("Tower created successfully")
    return instance
end

-- Draw tower preview during placement
function Tower.drawPreview(towerType, x, y)
    if not Tower.initialized then
        Tower.init()
    end
    
    -- Find tower data
    local towerData = nil
    
    -- Search through all factions
    for _, faction in pairs({Tower.HUMAN, Tower.ELF, Tower.DWARF}) do
        for id, tower in pairs(faction) do
            if id == towerType or tower.id == towerType then
                towerData = tower
                break
            end
        end
        if towerData then break end
    end
    
    if not towerData then
        -- Draw default preview
        love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
        love.graphics.rectangle("fill", x, y, 32, 32)
        return
    end
    
    -- Draw tower sprite or placeholder
    local sprite = Tower.sprites and Tower.sprites[towerType]
    
    if sprite then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.draw(sprite, x + 16, y + 16, 0, 1, 1, sprite:getWidth() / 2, sprite:getHeight() / 2)
    else
        -- Draw placeholder
        love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
        love.graphics.rectangle("fill", x, y, 32, 32)
    end
    
    -- Draw range indicator
    if towerData.range then
        love.graphics.setColor(0, 0.5, 0.8, 0.2)
        love.graphics.circle("fill", x + 16, y + 16, towerData.range)
        love.graphics.setColor(0, 0.7, 1, 0.5)
        love.graphics.circle("line", x + 16, y + 16, towerData.range)
    end
end

-- Tower instance methods

-- Pixel center of the tower's grid cell. Grid cells are 1-based:
-- cell (gx, gy) spans (gx-1)*tileSize .. gx*tileSize.
function TowerInstance:getCenter()
    local ts = self.tileSize or 32
    return (self.gridX - 0.5) * ts, (self.gridY - 0.5) * ts
end

-- Update tower logic.
-- gameState must provide: towers, enemies, projectiles, effects (lists).
-- Enemies must provide: x, y (center), radius, dead, reachedEnd,
-- takeDamage(amount), applySlow(amount, duration), applyDot(damage, duration).
function TowerInstance:update(dt, gameState)
    -- Update timer
    self.timer:update(dt)

    -- Get world position
    local x, y = self:getCenter()
    
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
                local towerX, towerY = tower:getCenter()
                
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
    local x, y = self:getCenter()

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
            
            -- Home in on the target while it is alive, so moving enemies
            -- can't sidestep a shot that was aimed at their old position
            local t = self.target
            if t and not t.dead and not t.reachedEnd then
                self.angle = math.atan2(t.y - self.y, t.x - self.x)
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
                    if dist < (enemy.radius or 12) then
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
                        self.done = true
                    end
                    return self.done == true
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

-- On-map width of a painted tower in pixels, a little wider than one
-- 32 px cell so the base reads as filling it.
Tower.DRAW_WIDTH = 44

-- Draw a painted tower image standing on the cell centered at (cx, cy).
-- Painted towers sit on a diamond base that spans the image width; in this
-- three-quarter view the diamond is half as tall as it is wide, so its
-- center is a quarter of the width above the bottom edge. That point goes
-- on the cell center. No per-asset numbers needed.
function Tower.drawPainted(img, cx, cy, drawWidth, alpha, shadow)
    local w, h = img:getDimensions()
    local s = drawWidth / w
    if shadow then
        -- Light comes from the upper left, so the shadow falls down-right
        love.graphics.setColor(0, 0, 0, 0.28 * (alpha or 1))
        love.graphics.ellipse("fill", cx + drawWidth * 0.08, cy + drawWidth * 0.06,
            drawWidth * 0.46, drawWidth * 0.22)
    end
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(img, cx, cy, 0, s, s, w / 2, h - w / 4)
end

-- Draw a tower type as an icon fitted inside a box (UI panels)
function Tower.drawIcon(id, x, y, boxW, boxH)
    local img = Tower.images and Tower.images[id]
    if img then
        local w, h = img:getDimensions()
        local s = math.min(boxW / w, boxH / h)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, x + boxW / 2, y + boxH / 2, 0, s, s, w / 2, h / 2)
        return true
    end
    local sprite = Tower.sprites and Tower.sprites[id]
    if sprite then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, x + boxW / 2, y + boxH / 2, 0, 1, 1,
            sprite:getWidth() / 2, sprite:getHeight() / 2)
        return true
    end
    return false
end

-- Range circle, drawn by the game only for the hovered or selected tower
function TowerInstance:drawRange()
    if not self.range then return end
    local cx, cy = self:getCenter()
    love.graphics.setColor(0.2, 0.5, 0.8, 0.15)
    love.graphics.circle("fill", cx, cy, self.range)
    love.graphics.setColor(0.2, 0.5, 0.8, 0.5)
    love.graphics.circle("line", cx, cy, self.range)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw the tower
function TowerInstance:draw()
    -- Top-left corner of the tower's cell (drawing below is relative to it)
    local ts = self.tileSize or 32
    local x = (self.gridX - 1) * ts
    local y = (self.gridY - 1) * ts

    -- Draw tower sprite or fallback shape
    if self.painted then
        local cx, cy = self:getCenter()
        Tower.drawPainted(self.spriteImg, cx, cy, Tower.DRAW_WIDTH, 1, true)
    elseif self.spriteImg then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            self.spriteImg,
            x + ts / 2, y + ts / 2,
            0, 1, 1, 
            self.spriteImg:getWidth() / 2, 
            self.spriteImg:getHeight() / 2
        )
    else
        -- Draw fallback shape
        love.graphics.setColor(0.3, 0.6, 0.9, 1)
        love.graphics.rectangle("fill", x + 4, y + 4, 24, 24)
        love.graphics.setColor(0.1, 0.3, 0.5, 1)
        love.graphics.rectangle("line", x + 4, y + 4, 24, 24)
    end
    
    -- Draw tower level if greater than 1
    if self.level and self.level > 1 then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.circle("fill", x + 24, y + 8, 8)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(self.level, x + 21, y + 3)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
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