local Enemy = {
    types = {}
}

-- Dependencies
local Error = require 'utils.error'
local Timer = require 'libs.hump.timer'
local Jumper = require 'libs.jumper'

-- Enemy class
local EnemyInstance = {}
EnemyInstance.__index = EnemyInstance

-- Initialize the enemy data
function Enemy.init()
    Enemy.types = {
        -- Basic enemies
        grunt = {
            id = "grunt",
            name = "Grunt",
            description = "Basic enemy with balanced stats",
            health = 100,
            speed = 50,
            damage = 1,
            reward = 10,
            radius = 15,
            sprite = "grunt"
        },
        
        runner = {
            id = "runner",
            name = "Runner",
            description = "Fast enemy with low health",
            health = 60,
            speed = 80,
            damage = 1,
            reward = 8,
            radius = 12,
            sprite = "runner"
        },
        
        tank = {
            id = "tank",
            name = "Tank",
            description = "Slow enemy with high health",
            health = 300,
            speed = 30,
            damage = 2,
            reward = 15,
            radius = 20,
            sprite = "tank"
        },
        
        -- Special enemies
        healer = {
            id = "healer",
            name = "Healer",
            description = "Heals nearby enemies",
            health = 120,
            speed = 40,
            damage = 1,
            reward = 20,
            radius = 15,
            sprite = "healer",
            special = {
                healRadius = 80,
                healAmount = 10,
                healInterval = 2
            }
        },
        
        spawner = {
            id = "spawner",
            name = "Spawner",
            description = "Spawns small enemies when damaged",
            health = 200,
            speed = 35,
            damage = 1,
            reward = 25,
            radius = 20,
            sprite = "spawner",
            special = {
                spawnType = "minion",
                spawnCount = 2,
                spawnThreshold = 50  -- Spawn when health drops by this amount
            }
        },
        
        shielder = {
            id = "shielder",
            name = "Shielder",
            description = "Provides damage reduction to nearby enemies",
            health = 150,
            speed = 45,
            damage = 1,
            reward = 20,
            radius = 18,
            sprite = "shielder",
            special = {
                shieldRadius = 70,
                shieldAmount = 0.5  -- 50% damage reduction
            }
        },
        
        flyer = {
            id = "flyer",
            name = "Flyer",
            description = "Can fly over obstacles",
            health = 80,
            speed = 60,
            damage = 1,
            reward = 15,
            radius = 15,
            sprite = "flyer",
            flying = true
        },
        
        -- Boss enemies
        boss_warrior = {
            id = "boss_warrior",
            name = "War Chief",
            description = "Powerful warrior with high health and damage",
            health = 1000,
            speed = 30,
            damage = 5,
            reward = 100,
            radius = 30,
            sprite = "boss_warrior",
            boss = true
        },
        
        boss_mage = {
            id = "boss_mage",
            name = "Archmage",
            description = "Teleports and deals area damage",
            health = 700,
            speed = 35,
            damage = 3,
            reward = 100,
            radius = 25,
            sprite = "boss_mage",
            boss = true,
            special = {
                teleportInterval = 5,
                teleportRange = 100,
                aoeDamage = 30,
                aoeRadius = 100
            }
        },
        
        boss_summoner = {
            id = "boss_summoner",
            name = "Master Summoner",
            description = "Summons allies and heals them",
            health = 800,
            speed = 25,
            damage = 3,
            reward = 100,
            radius = 25,
            sprite = "boss_summoner",
            boss = true,
            special = {
                summonType = "minion",
                summonCount = 3,
                summonInterval = 8,
                healRadius = 120,
                healAmount = 20,
                healInterval = 5
            }
        },
        
        -- Minion (not directly spawned in waves, only by other enemies)
        minion = {
            id = "minion",
            name = "Minion",
            description = "Small weak enemy",
            health = 30,
            speed = 60,
            damage = 1,
            reward = 3,
            radius = 10,
            sprite = "minion"
        }
    }
    
    -- Load enemy sprites
    Enemy.sprites = {}
    local success, result = Error.pcall(function()
        for id, _ in pairs(Enemy.types) do
            Enemy.sprites[id] = love.graphics.newImage("sprites/enemies/" .. id .. ".png")
        end
    end)
    
    if not success then
        Error.show("Failed to load enemy sprites: " .. tostring(result))
    end
end

-- Create a new enemy instance
function Enemy.create(enemyType, startPosition)
    local enemyData = Enemy.types[enemyType]
    if not enemyData then
        Error.show("Invalid enemy type: " .. tostring(enemyType))
        return nil
    end
    
    local enemy = setmetatable({}, EnemyInstance)
    
    -- Copy enemy data
    for k, v in pairs(enemyData) do
        enemy[k] = v
    end
    
    -- Instance-specific properties
    enemy.x = startPosition.x
    enemy.y = startPosition.y
    enemy.path = {}
    enemy.currentPathIndex = 1
    enemy.dead = false
    enemy.reachedEnd = false
    enemy.currentHealth = enemy.health
    enemy.maxHealth = enemy.health
    enemy.baseSpeed = enemy.speed  -- Store original speed for slow effects
    enemy.slowed = false
    enemy.slowEffect = 0
    enemy.slowDuration = 0
    enemy.dotEffects = {}  -- Damage over time effects
    enemy.shielded = false
    enemy.shieldAmount = 0
    enemy.lastHealTime = 0
    enemy.lastSummonTime = 0
    enemy.lastSpawnHealth = enemy.health
    enemy.lastTeleportTime = 0
    enemy.timer = Timer.new()
    
    -- For special abilities that need updating
    if enemy.special then
        if enemy.special.healInterval then
            enemy.lastHealTime = love.timer.getTime()
        end
        if enemy.special.summonInterval then
            enemy.lastSummonTime = love.timer.getTime()
        end
        if enemy.special.teleportInterval then
            enemy.lastTeleportTime = love.timer.getTime()
        end
    end
    
    return enemy
end

-- Enemy instance methods

-- Set the path for the enemy to follow
function EnemyInstance:setPath(path)
    self.path = path
    self.currentPathIndex = 1
end

-- Take damage
function EnemyInstance:takeDamage(amount)
    -- Apply shield effect if shielded
    if self.shielded and self.shieldAmount > 0 then
        amount = amount * (1 - self.shieldAmount)
    end
    
    local previousHealth = self.currentHealth
    self.currentHealth = math.max(0, self.currentHealth - amount)
    
    -- Check for spawning ability
    if self.special and self.special.spawnType and self.special.spawnThreshold then
        local healthLost = previousHealth - self.currentHealth
        local healthSinceLastSpawn = self.lastSpawnHealth - self.currentHealth
        
        if healthSinceLastSpawn >= self.special.spawnThreshold then
            self.lastSpawnHealth = self.currentHealth
            self:spawnMinions()
        end
    end
    
    -- Check if dead
    if self.currentHealth <= 0 then
        self.dead = true
        
        -- Play death sound based on enemy type
        if self.boss then
            playSound('sfx', 'bossDeath')
        else
            playSound('sfx', 'enemyDeath')
        end
        
        -- Spawn death effect
        self:spawnDeathEffect()
    end
end

-- Update enemy logic
function EnemyInstance:update(dt, gameState)
    -- Update timer
    self.timer:update(dt)
    
    -- Don't update if dead
    if self.dead or self.reachedEnd then return end
    
    -- Update DoT effects
    for i = #self.dotEffects, 1, -1 do
        local dot = self.dotEffects[i]
        dot.duration = dot.duration - dt
        dot.tickTimer = dot.tickTimer - dt
        
        if dot.tickTimer <= 0 then
            self:takeDamage(dot.damagePerTick)
            dot.tickTimer = dot.tickInterval
        end
        
        if dot.duration <= 0 then
            table.remove(self.dotEffects, i)
        end
    end
    
    -- Update slow effect
    if self.slowed then
        self.slowDuration = self.slowDuration - dt
        if self.slowDuration <= 0 then
            self.slowed = false
            self.speed = self.baseSpeed
        end
    end
    
    -- Move along path
    if #self.path > 0 and self.currentPathIndex <= #self.path then
        local targetPoint = self.path[self.currentPathIndex]
        local targetX, targetY = targetPoint.x, targetPoint.y
        
        -- Calculate direction and distance
        local dx, dy = targetX - self.x, targetY - self.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance < 5 then
            -- Reached current waypoint, move to next
            self.currentPathIndex = self.currentPathIndex + 1
            
            -- Check if reached end
            if self.currentPathIndex > #self.path then
                self.reachedEnd = true
                return
            end
        else
            -- Move towards target
            local moveDistance = self.speed * dt
            local moveX = (dx / distance) * moveDistance
            local moveY = (dy / distance) * moveDistance
            
            self.x = self.x + moveX
            self.y = self.y + moveY
        end
    end
    
    -- Special abilities
    if self.special then
        -- Healer ability
        if self.special.healRadius and self.special.healAmount and self.special.healInterval then
            local currentTime = love.timer.getTime()
            if currentTime - self.lastHealTime >= self.special.healInterval then
                self:healNearbyEnemies(gameState)
                self.lastHealTime = currentTime
            end
        end
        
        -- Shielder ability
        if self.special.shieldRadius and self.special.shieldAmount then
            self:shieldNearbyEnemies(gameState)
        end
        
        -- Summoner ability
        if self.special.summonInterval and self.special.summonType and self.special.summonCount then
            local currentTime = love.timer.getTime()
            if currentTime - self.lastSummonTime >= self.special.summonInterval then
                self:summonMinions(gameState)
                self.lastSummonTime = currentTime
            end
        end
        
        -- Teleport ability
        if self.special.teleportInterval and self.special.teleportRange then
            local currentTime = love.timer.getTime()
            if currentTime - self.lastTeleportTime >= self.special.teleportInterval then
                self:teleport(gameState)
                self.lastTeleportTime = currentTime
            end
        end
    end
end

-- Draw the enemy
function EnemyInstance:draw()
    -- Don't draw if dead
    if self.dead or self.reachedEnd then return end
    
    -- Draw enemy sprite
    love.graphics.setColor(1, 1, 1, 1)
    local sprite = Enemy.sprites[self.id]
    
    if sprite then
        local scale = (self.radius * 2) / sprite:getWidth()
        love.graphics.draw(sprite, self.x, self.y, 0, scale, scale, 
                         sprite:getWidth() / 2, sprite:getHeight() / 2)
    else
        -- Fallback if sprite is missing
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
    
    -- Draw health bar
    local healthPercentage = self.currentHealth / self.maxHealth
    local healthBarWidth = self.radius * 2
    local healthBarHeight = 5
    
    -- Background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", self.x - healthBarWidth / 2, self.y - self.radius - 10, 
                          healthBarWidth, healthBarHeight)
    
    -- Health
    if healthPercentage > 0.6 then
        love.graphics.setColor(0, 1, 0, 0.8)  -- Green
    elseif healthPercentage > 0.3 then
        love.graphics.setColor(1, 1, 0, 0.8)  -- Yellow
    else
        love.graphics.setColor(1, 0, 0, 0.8)  -- Red
    end
    
    love.graphics.rectangle("fill", self.x - healthBarWidth / 2, self.y - self.radius - 10, 
                          healthBarWidth * healthPercentage, healthBarHeight)
    
    -- Draw status effects
    local statusX = self.x + self.radius + 5
    local statusY = self.y - self.radius
    
    -- Slow effect
    if self.slowed then
        love.graphics.setColor(0, 0.7, 1, 0.8)
        love.graphics.circle("fill", statusX, statusY, 5)
        statusY = statusY + 12
    end
    
    -- DoT effect
    if #self.dotEffects > 0 then
        love.graphics.setColor(0.7, 0, 0.7, 0.8)
        love.graphics.circle("fill", statusX, statusY, 5)
        statusY = statusY + 12
    end
    
    -- Shield effect
    if self.shielded then
        love.graphics.setColor(0.7, 0.7, 1, 0.5)
        love.graphics.circle("line", self.x, self.y, self.radius + 3)
    end
    
    -- Draw boss indicator
    if self.boss then
        love.graphics.setColor(1, 0.5, 0, 0.8)
        love.graphics.polygon("fill", 
            self.x, self.y - self.radius - 20,
            self.x - 8, self.y - self.radius - 12,
            self.x + 8, self.y - self.radius - 12)
    end
end

-- Apply damage over time effect
function EnemyInstance:applyDot(damage, duration)
    table.insert(self.dotEffects, {
        damagePerTick = damage / 5,  -- 5 ticks over the duration
        duration = duration,
        tickInterval = duration / 5,
        tickTimer = duration / 5
    })
end

-- Apply slow effect
function EnemyInstance:applySlow(amount, duration)
    -- Apply the stronger slow effect
    if not self.slowed or amount > self.slowEffect then
        self.slowed = true
        self.slowEffect = amount
        self.slowDuration = duration
        self.speed = self.baseSpeed * (1 - amount)
    -- Extend duration if same effect strength
    elseif amount == self.slowEffect and duration > self.slowDuration then
        self.slowDuration = duration
    end
end

-- Healer ability
function EnemyInstance:healNearbyEnemies(gameState)
    if not self.special or not self.special.healRadius or not self.special.healAmount then
        return
    end
    
    -- Visual effect
    self:spawnHealEffect()
    
    -- Play sound
    playSound('sfx', 'heal')
    
    -- Heal nearby enemies
    for _, enemy in ipairs(gameState.enemies) do
        if enemy ~= self and not enemy.dead and not enemy.reachedEnd then
            local dx, dy = enemy.x - self.x, enemy.y - self.y
            local distance = math.sqrt(dx*dx + dy*dy)
            
            if distance <= self.special.healRadius then
                enemy.currentHealth = math.min(enemy.maxHealth, enemy.currentHealth + self.special.healAmount)
                
                -- Visual heal effect on target
                self:spawnHealParticles(enemy.x, enemy.y)
            end
        end
    end
end

-- Shielder ability
function EnemyInstance:shieldNearbyEnemies(gameState)
    if not self.special or not self.special.shieldRadius or not self.special.shieldAmount then
        return
    end
    
    -- Shield self
    self.shielded = true
    self.shieldAmount = self.special.shieldAmount
    
    -- Shield nearby enemies
    for _, enemy in ipairs(gameState.enemies) do
        if enemy ~= self and not enemy.dead and not enemy.reachedEnd then
            local dx, dy = enemy.x - self.x, enemy.y - self.y
            local distance = math.sqrt(dx*dx + dy*dy)
            
            if distance <= self.special.shieldRadius then
                enemy.shielded = true
                enemy.shieldAmount = self.special.shieldAmount
            end
        end
    end
end

-- Spawner ability (when damaged)
function EnemyInstance:spawnMinions()
    if not self.special or not self.special.spawnType or not self.special.spawnCount then
        return
    end
    
    local gameState = _G.gameState
    if not gameState then return end
    
    -- Play sound
    playSound('sfx', 'summon')
    
    -- Spawn visual effect
    self:spawnSummonEffect()
    
    -- Spawn minions
    for i = 1, self.special.spawnCount do
        -- Calculate spawn position (slightly offset from the spawner)
        local angle = math.random() * 2 * math.pi
        local distance = self.radius + 10
        local spawnX = self.x + math.cos(angle) * distance
        local spawnY = self.y + math.sin(angle) * distance
        
        local minion = Enemy.create(self.special.spawnType, {x = spawnX, y = spawnY})
        
        -- Copy current path but start from current position
        if self.path and #self.path > 0 then
            local newPath = {}
            local inserted = false
            
            -- Find closest path point
            local closestDist = math.huge
            local closestIndex = 1
            
            for i, point in ipairs(self.path) do
                local dx, dy = point.x - spawnX, point.y - spawnY
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < closestDist then
                    closestDist = dist
                    closestIndex = i
                end
            end
            
            -- Create new path starting from closest point
            for i = closestIndex, #self.path do
                table.insert(newPath, self.path[i])
            end
            
            minion:setPath(newPath)
        end
        
        -- Add to game state
        table.insert(gameState.enemies, minion)
    end
end

-- Summoner ability (periodic)
function EnemyInstance:summonMinions(gameState)
    if not self.special or not self.special.summonType or not self.special.summonCount then
        return
    end
    
    -- Play sound
    playSound('sfx', 'summon')
    
    -- Spawn visual effect
    self:spawnSummonEffect()
    
    -- Spawn minions
    for i = 1, self.special.summonCount do
        -- Calculate spawn position (slightly offset from the summoner)
        local angle = math.random() * 2 * math.pi
        local distance = self.radius + 10
        local spawnX = self.x + math.cos(angle) * distance
        local spawnY = self.y + math.sin(angle) * distance
        
        local minion = Enemy.create(self.special.summonType, {x = spawnX, y = spawnY})
        
        -- Copy current path but start from current position
        if self.path and #self.path > 0 then
            local newPath = {}
            local inserted = false
            
            -- Find closest path point
            local closestDist = math.huge
            local closestIndex = 1
            
            for i, point in ipairs(self.path) do
                local dx, dy = point.x - spawnX, point.y - spawnY
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < closestDist then
                    closestDist = dist
                    closestIndex = i
                end
            end
            
            -- Create new path starting from closest point
            for i = closestIndex, #self.path do
                table.insert(newPath, self.path[i])
            end
            
            minion:setPath(newPath)
        end
        
        -- Add to game state
        table.insert(gameState.enemies, minion)
    end
end

-- Teleport ability
function EnemyInstance:teleport(gameState)
    if not self.special or not self.special.teleportRange then
        return
    end
    
    -- Spawn visual effect at current position
    self:spawnTeleportEffect()
    
    -- Play sound
    playSound('sfx', 'teleport')
    
    -- Calculate new position
    local angle = math.random() * 2 * math.pi
    local distance = math.random(50, self.special.teleportRange)
    local newX = self.x + math.cos(angle) * distance
    local newY = self.y + math.sin(angle) * distance
    
    -- Enforce map boundaries
    if gameState.map then
        newX = math.max(self.radius, math.min(gameState.map.width * gameState.map.tileSize - self.radius, newX))
        newY = math.max(self.radius, math.min(gameState.map.height * gameState.map.tileSize - self.radius, newY))
    end
    
    -- Update position
    self.x = newX
    self.y = newY
    
    -- Spawn arrival effect
    self:spawnTeleportEffect()
    
    -- Deal AOE damage if applicable
    if self.special.aoeDamage and self.special.aoeRadius then
        for _, tower in ipairs(gameState.towers) do
            if tower.x and tower.y then
                local dx, dy = tower.x - self.x, tower.y - self.y
                local distance = math.sqrt(dx*dx + dy*dy)
                
                if distance <= self.special.aoeRadius then
                    -- TODO: Implement tower damage if needed
                    -- tower:takeDamage(self.special.aoeDamage)
                end
            end
        end
        
        -- Visual effect for AOE
        self:spawnAoeEffect()
    end
    
    -- Update path if needed
    if self.path and #self.path > 0 then
        -- Find closest path point
        local closestDist = math.huge
        local closestIndex = 1
        
        for i, point in ipairs(self.path) do
            local dx, dy = point.x - self.x, point.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist < closestDist then
                closestDist = dist
                closestIndex = i
            end
        end
        
        self.currentPathIndex = closestIndex
    end
end

-- Visual effects

-- Spawn death effect
function EnemyInstance:spawnDeathEffect()
    local gameState = _G.gameState
    if not gameState or not gameState.effects then return end
    
    local effect = {
        x = self.x,
        y = self.y,
        radius = self.radius,
        alpha = 1,
        duration = 0.5,
        currentTime = 0,
        boss = self.boss,
        
        update = function(self, dt)
            self.currentTime = self.currentTime + dt
            self.alpha = 1 - (self.currentTime / self.duration)
            
            if self.currentTime >= self.duration then
                return true -- Done
            end
            return false
        end,
        
        draw = function(self)
            if self.boss then
                love.graphics.setColor(1, 0.5, 0, self.alpha * 0.8)
            else
                love.graphics.setColor(0.8, 0.1, 0.1, self.alpha * 0.8)
            end
            
            love.graphics.circle("fill", self.x, self.y, self.radius * (1 + self.currentTime / self.duration))
            
            love.graphics.setColor(1, 1, 1, self.alpha)
            love.graphics.circle("line", self.x, self.y, self.radius * (1 + self.currentTime / self.duration))
        end
    }
    
    table.insert(gameState.effects, effect)
end

-- Spawn heal effect
function EnemyInstance:spawnHealEffect()
    local gameState = _G.gameState
    if not gameState or not gameState.effects then return end
    
    local effect = {
        x = self.x,
        y = self.y,
        radius = 5,
        maxRadius = self.special and self.special.healRadius or 50,
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
            love.graphics.setColor(0, 1, 0, 0.5 * (1 - self.currentTime / self.duration))
            love.graphics.circle("fill", self.x, self.y, self.radius)
            
            love.graphics.setColor(0.5, 1, 0.5, 0.7 * (1 - self.currentTime / self.duration))
            love.graphics.circle("line", self.x, self.y, self.radius)
        end
    }
    
    table.insert(gameState.effects, effect)
end

-- Spawn heal particles on healed enemies
function EnemyInstance:spawnHealParticles(x, y)
    local gameState = _G.gameState
    if not gameState or not gameState.effects then return end
    
    for i = 1, 5 do
        local effect = {
            x = x,
            y = y,
            size = 5,
            speed = math.random(20, 50),
            angle = math.random() * 2 * math.pi,
            duration = 0.7,
            currentTime = 0,
            
            update = function(self, dt)
                self.currentTime = self.currentTime + dt
                self.x = self.x + math.cos(self.angle) * self.speed * dt
                self.y = self.y + math.sin(self.angle) * self.speed * dt
                
                if self.currentTime >= self.duration then
                    return true -- Done
                end
                return false
            end,
            
            draw = function(self)
                love.graphics.setColor(0, 1, 0, 1 - self.currentTime / self.duration)
                love.graphics.circle("fill", self.x, self.y, self.size * (1 - self.currentTime / self.duration))
            end
        }
        
        table.insert(gameState.effects, effect)
    end
end

-- Spawn summon effect
function EnemyInstance:spawnSummonEffect()
    local gameState = _G.gameState
    if not gameState or not gameState.effects then return end
    
    local effect = {
        x = self.x,
        y = self.y,
        radius = 0,
        maxRadius = 30,
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
            love.graphics.setColor(0.7, 0, 0.7, 0.5 * (1 - self.currentTime / self.duration))
            love.graphics.circle("fill", self.x, self.y, self.radius)
            
            love.graphics.setColor(1, 0.5, 1, 0.7 * (1 - self.currentTime / self.duration))
            love.graphics.circle("line", self.x, self.y, self.radius)
        end
    }
    
    table.insert(gameState.effects, effect)
end

-- Spawn teleport effect
function EnemyInstance:spawnTeleportEffect()
    local gameState = _G.gameState
    if not gameState or not gameState.effects then return end
    
    local effect = {
        x = self.x,
        y = self.y,
        radius = self.radius,
        duration = 0.5,
        currentTime = 0,
        
        update = function(self, dt)
            self.currentTime = self.currentTime + dt
            
            if self.currentTime >= self.duration then
                return true -- Done
            end
            return false
        end,
        
        draw = function(self)
            local progress = self.currentTime / self.duration
            
            love.graphics.setColor(0.5, 0.5, 1, 1 - progress)
            
            -- Draw a magical circle
            for i = 1, 8 do
                local angle = i * math.pi / 4 + progress * math.pi
                local x = self.x + math.cos(angle) * self.radius * (1 + progress)
                local y = self.y + math.sin(angle) * self.radius * (1 + progress)
                
                love.graphics.circle("fill", x, y, 3 * (1 - progress))
            end
            
            -- Draw center circle
            love.graphics.setColor(0.7, 0.7, 1, 0.7 * (1 - progress))
            love.graphics.circle("fill", self.x, self.y, self.radius * (1 - progress))
        end
    }
    
    table.insert(gameState.effects, effect)
end

-- Spawn AOE effect
function EnemyInstance:spawnAoeEffect()
    local gameState = _G.gameState
    if not gameState or not gameState.effects or not self.special then return end
    
    local effect = {
        x = self.x,
        y = self.y,
        radius = 5,
        maxRadius = self.special.aoeRadius or 100,
        duration = 0.7,
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
            love.graphics.setColor(1, 0.3, 0.1, 0.5 * (1 - self.currentTime / self.duration))
            love.graphics.circle("fill", self.x, self.y, self.radius)
            
            love.graphics.setColor(1, 0.5, 0.2, 0.7 * (1 - self.currentTime / self.duration))
            love.graphics.circle("line", self.x, self.y, self.radius)
        end
    }
    
    table.insert(gameState.effects, effect)
end

-- Return the module
return Enemy 