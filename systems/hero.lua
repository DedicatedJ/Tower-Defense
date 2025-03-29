local Hero = {
    types = {}
}

-- Dependencies
local Error = require 'utils.error'
local Timer = require 'libs.hump.timer'

-- Hero class
local HeroInstance = {}
HeroInstance.__index = HeroInstance

-- Initialize the hero data
function Hero.init()
    Hero.types = {
        -- Human faction heroes
        knight = {
            id = "knight",
            name = "Knight",
            description = "Heavily armored fighter with powerful melee attacks",
            faction = "human",
            health = 200,
            damage = 40,
            range = 60,
            attackSpeed = 1.5,
            moveSpeed = 100,
            abilities = {
                {
                    id = "shield_bash",
                    name = "Shield Bash",
                    description = "Stun enemies in a cone in front of you",
                    cooldown = 10,
                    icon = "shield_bash"
                },
                {
                    id = "rally",
                    name = "Rally",
                    description = "Increase damage of nearby towers by 30% for 10 seconds",
                    cooldown = 30,
                    icon = "rally"
                },
                {
                    id = "charge",
                    name = "Charge",
                    description = "Dash forward, damaging all enemies in your path",
                    cooldown = 15,
                    icon = "charge"
                }
            }
        },
        mage = {
            id = "mage",
            name = "Battle Mage",
            description = "Magic user with powerful area damage spells",
            faction = "human",
            health = 120,
            damage = 60,
            range = 200,
            attackSpeed = 2.0,
            moveSpeed = 90,
            abilities = {
                {
                    id = "fireball",
                    name = "Fireball",
                    description = "Launch a fireball that deals area damage",
                    cooldown = 8,
                    icon = "fireball"
                },
                {
                    id = "ice_nova",
                    name = "Ice Nova",
                    description = "Freeze enemies around you, slowing them by 50% for 5 seconds",
                    cooldown = 20,
                    icon = "ice_nova"
                },
                {
                    id = "teleport",
                    name = "Teleport",
                    description = "Instantly teleport to a different location",
                    cooldown = 25,
                    icon = "teleport"
                }
            }
        },
        
        -- Elf faction heroes
        ranger = {
            id = "ranger",
            name = "Ranger",
            description = "Long-range archer with high damage and evasion",
            faction = "elf",
            health = 140,
            damage = 50,
            range = 250,
            attackSpeed = 1.0,
            moveSpeed = 120,
            abilities = {
                {
                    id = "multishot",
                    name = "Multishot",
                    description = "Fire arrows at the 3 closest enemies",
                    cooldown = 12,
                    icon = "multishot"
                },
                {
                    id = "trap",
                    name = "Trap",
                    description = "Place a trap that slows and damages enemies",
                    cooldown = 15,
                    icon = "trap"
                },
                {
                    id = "nature_blessing",
                    name = "Nature's Blessing",
                    description = "Increase tower attack speed by 25% for 10 seconds",
                    cooldown = 30,
                    icon = "nature_blessing"
                }
            }
        },
        druid = {
            id = "druid",
            name = "Druid",
            description = "Nature magic user who can summon allies",
            faction = "elf",
            health = 160,
            damage = 30,
            range = 150,
            attackSpeed = 1.8,
            moveSpeed = 100,
            abilities = {
                {
                    id = "entangle",
                    name = "Entangle",
                    description = "Root enemies in an area, preventing movement for 3 seconds",
                    cooldown = 15,
                    icon = "entangle"
                },
                {
                    id = "summon_treants",
                    name = "Summon Treants",
                    description = "Summon 3 treants to fight for you",
                    cooldown = 40,
                    icon = "summon_treants"
                },
                {
                    id = "healing_circle",
                    name = "Healing Circle",
                    description = "Create a circle that heals summoned units and increases tower damage",
                    cooldown = 25,
                    icon = "healing_circle"
                }
            }
        },
        
        -- Dwarf faction heroes
        engineer = {
            id = "engineer",
            name = "Engineer",
            description = "Tower specialist who can build and upgrade structures",
            faction = "dwarf",
            health = 180,
            damage = 35,
            range = 100,
            attackSpeed = 1.3,
            moveSpeed = 80,
            abilities = {
                {
                    id = "turret",
                    name = "Deploy Turret",
                    description = "Deploy a temporary turret that attacks enemies",
                    cooldown = 20,
                    icon = "turret"
                },
                {
                    id = "overcharge",
                    name = "Overcharge",
                    description = "Overcharge a tower, doubling its attack speed for 5 seconds",
                    cooldown = 30,
                    icon = "overcharge"
                },
                {
                    id = "repair",
                    name = "Repair",
                    description = "Instantly complete tower construction and refill tower ammo",
                    cooldown = 45,
                    icon = "repair"
                }
            }
        },
        berserker = {
            id = "berserker",
            name = "Berserker",
            description = "Melee fighter who gains power as health decreases",
            faction = "dwarf",
            health = 220,
            damage = 45,
            range = 70,
            attackSpeed = 1.0,
            moveSpeed = 110,
            abilities = {
                {
                    id = "battle_cry",
                    name = "Battle Cry",
                    description = "Increase your damage by 50% for 8 seconds",
                    cooldown = 25,
                    icon = "battle_cry"
                },
                {
                    id = "whirlwind",
                    name = "Whirlwind",
                    description = "Spin in a circle, dealing damage to all nearby enemies",
                    cooldown = 15,
                    icon = "whirlwind"
                },
                {
                    id = "last_stand",
                    name = "Last Stand",
                    description = "Become invulnerable for 5 seconds when health drops below 30%",
                    cooldown = 60,
                    icon = "last_stand"
                }
            }
        }
    }
    
    -- Load hero sprites
    Hero.sprites = {}
    local success, result = Error.pcall(function()
        for id, _ in pairs(Hero.types) do
            Hero.sprites[id] = love.graphics.newImage("sprites/heroes/" .. id .. ".png")
        end
    end)
    
    if not success then
        Error.show("Failed to load hero sprites: " .. tostring(result))
    end
    
    -- Load ability icons
    Hero.abilityIcons = {}
    success, result = Error.pcall(function()
        for id, hero in pairs(Hero.types) do
            for _, ability in ipairs(hero.abilities) do
                Hero.abilityIcons[ability.icon] = love.graphics.newImage("sprites/abilities/" .. ability.icon .. ".png")
            end
        end
    end)
    
    if not success then
        Error.show("Failed to load ability icons: " .. tostring(result))
    end
end

-- Get all heroes for a specific faction
function Hero.getHeroesByFaction(faction)
    local heroes = {}
    
    for id, hero in pairs(Hero.types) do
        if hero.faction == faction then
            table.insert(heroes, hero)
        end
    end
    
    return heroes
end

-- Create a new hero instance
function Hero.create(heroType, faction)
    local heroData
    
    -- Find the hero by type
    for id, data in pairs(Hero.types) do
        if id == heroType and data.faction == faction then
            heroData = data
            break
        end
    end
    
    if not heroData then
        Error.show("Invalid hero type or faction mismatch: " .. tostring(heroType))
        return nil
    end
    
    local hero = setmetatable({}, HeroInstance)
    
    -- Copy hero data
    for k, v in pairs(heroData) do
        hero[k] = v
    end
    
    -- Instance-specific properties
    hero.x = 0
    hero.y = 0
    hero.currentHealth = hero.health
    hero.maxHealth = hero.health
    hero.level = 1
    hero.experience = 0
    hero.experienceToNextLevel = 100
    hero.targetX = 0
    hero.targetY = 0
    hero.isMoving = false
    hero.direction = "right"
    hero.abilities = {}
    hero.timer = Timer.new()
    hero.state = "idle"  -- idle, moving, attacking, casting
    hero.targetEnemy = nil
    
    -- Initialize abilities
    for i, abilityData in ipairs(heroData.abilities) do
        table.insert(hero.abilities, {
            id = abilityData.id,
            name = abilityData.name,
            description = abilityData.description,
            cooldown = abilityData.cooldown,
            currentCooldown = 0,
            ready = true,
            icon = Hero.abilityIcons[abilityData.icon]
        })
    end
    
    return hero
end

-- Hero instance methods

-- Update hero logic
function HeroInstance:update(dt, gameState)
    -- Update timer
    self.timer:update(dt)
    
    -- Update ability cooldowns
    for _, ability in ipairs(self.abilities) do
        if not ability.ready then
            ability.currentCooldown = ability.currentCooldown - dt
            if ability.currentCooldown <= 0 then
                ability.ready = true
                ability.currentCooldown = 0
                
                -- Play sound effect
                playSound('sfx', 'abilitReady')
            end
        end
    end
    
    -- Handle hero movement
    if self.isMoving and self.state ~= "casting" then
        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance < 5 then
            -- Reached destination
            self.isMoving = false
            self.state = "idle"
        else
            -- Move towards target
            local moveDistance = self.moveSpeed * dt
            local moveX = (dx / distance) * moveDistance
            local moveY = (dy / distance) * moveDistance
            
            self.x = self.x + moveX
            self.y = self.y + moveY
            
            -- Update direction
            if math.abs(dx) > math.abs(dy) then
                self.direction = dx > 0 and "right" or "left"
            else
                self.direction = dy > 0 and "down" or "up"
            end
            
            self.state = "moving"
        end
    end
    
    -- Auto-attack nearby enemies if not moving or casting
    if not self.isMoving and self.state ~= "casting" then
        -- Find the closest enemy within range
        local closestEnemy = nil
        local closestDistance = self.range
        
        for _, enemy in ipairs(gameState.enemies) do
            if not enemy.dead and not enemy.reachedEnd then
                local dx = enemy.x - self.x
                local dy = enemy.y - self.y
                local distance = math.sqrt(dx*dx + dy*dy)
                
                if distance < closestDistance then
                    closestEnemy = enemy
                    closestDistance = distance
                end
            end
        end
        
        -- If we found an enemy, attack it
        if closestEnemy then
            self.targetEnemy = closestEnemy
            self:attack(gameState)
        else
            self.targetEnemy = nil
        end
    end
    
    -- Gain experience from nearby enemy deaths
    for _, enemy in ipairs(gameState.enemies) do
        if enemy.dead and not enemy.experienceGiven and
           math.sqrt((self.x - enemy.x)^2 + (self.y - enemy.y)^2) < 300 then
            local expGain = 5
            if enemy.boss then
                expGain = 50
            end
            
            self:gainExperience(expGain)
            enemy.experienceGiven = true
        end
    end
end

-- Move to a target position
function HeroInstance:moveTo(x, y)
    self.targetX = x
    self.targetY = y
    self.isMoving = true
    
    -- Clear target enemy when moving
    self.targetEnemy = nil
    
    return true
end

-- Attack the current target
function HeroInstance:attack(gameState)
    if not self.targetEnemy or self.state == "attacking" then return end
    
    self.state = "attacking"
    
    -- Face the enemy
    local dx = self.targetEnemy.x - self.x
    local dy = self.targetEnemy.y - self.y
    
    if math.abs(dx) > math.abs(dy) then
        self.direction = dx > 0 and "right" or "left"
    else
        self.direction = dy > 0 and "down" or "up"
    end
    
    -- Create a projectile or apply damage directly depending on hero type
    if self.range > 80 then  -- Ranged hero
        local angle = math.atan2(dy, dx)
        
        -- Create projectile
        local projectile = {
            x = self.x,
            y = self.y,
            targetX = self.targetEnemy.x,
            targetY = self.targetEnemy.y,
            angle = angle,
            speed = 300,
            damage = self.damage,
            source = self,
            target = self.targetEnemy,
            destroyed = false,
            
            update = function(self, dt, gameState)
                -- Move projectile
                self.x = self.x + math.cos(self.angle) * self.speed * dt
                self.y = self.y + math.sin(self.angle) * self.speed * dt
                
                -- Check if projectile is out of bounds
                if self.x < 0 or self.x > love.graphics.getWidth() or
                   self.y < 0 or self.y > love.graphics.getHeight() then
                    self.destroyed = true
                    return
                end
                
                -- Check for collision with target
                if not self.target.dead and not self.target.reachedEnd then
                    local dist = math.sqrt((self.x - self.target.x)^2 + (self.y - self.target.y)^2)
                    if dist < self.target.radius then
                        -- Hit enemy
                        self.target:takeDamage(self.damage)
                        self.destroyed = true
                    end
                else
                    -- Target already dead or reached end
                    self.destroyed = true
                end
            end,
            
            draw = function(self)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.circle("fill", self.x, self.y, 5)
            end
        }
        
        -- Add projectile to game state
        table.insert(gameState.projectiles, projectile)
        
        -- Play sound effect
        if self.id == "ranger" then
            playSound('sfx', 'bowShot')
        elseif self.id == "mage" or self.id == "druid" then
            playSound('sfx', 'magicCast')
        else
            playSound('sfx', 'heroAttack')
        end
    else  -- Melee hero
        -- Apply damage directly
        self.targetEnemy:takeDamage(self.damage)
        
        -- Play sound effect
        playSound('sfx', 'meleeHit')
    end
    
    -- Reset state after attack animation
    self.timer:after(1 / self.attackSpeed, function()
        if self.state == "attacking" then
            self.state = "idle"
        end
    end)
end

-- Use an ability
function HeroInstance:useAbility(abilityIndex, gameState)
    local ability = self.abilities[abilityIndex]
    if not ability or not ability.ready then return false end
    
    -- Set ability on cooldown
    ability.ready = false
    ability.currentCooldown = ability.cooldown
    
    -- Play sound effect
    playSound('sfx', 'abilityCast')
    
    -- Set casting state
    self.state = "casting"
    
    -- Execute ability based on ID
    local abilityHandlers = {
        -- Knight abilities
        shield_bash = function()
            -- Stun enemies in a cone in front of the hero
            local coneAngle = math.pi / 3  -- 60 degrees
            local coneRange = 100
            
            -- Determine cone direction based on hero direction
            local baseAngle = 0
            if self.direction == "right" then
                baseAngle = 0
            elseif self.direction == "down" then
                baseAngle = math.pi / 2
            elseif self.direction == "left" then
                baseAngle = math.pi
            elseif self.direction == "up" then
                baseAngle = 3 * math.pi / 2
            end
            
            -- Check enemies in cone
            for _, enemy in ipairs(gameState.enemies) do
                if not enemy.dead and not enemy.reachedEnd then
                    local dx = enemy.x - self.x
                    local dy = enemy.y - self.y
                    local distance = math.sqrt(dx*dx + dy*dy)
                    local angle = math.atan2(dy, dx)
                    
                    -- Normalize angle difference
                    local angleDiff = math.abs((angle - baseAngle + math.pi) % (2 * math.pi) - math.pi)
                    
                    if distance <= coneRange and angleDiff <= coneAngle / 2 then
                        -- Stun enemy (implement stun effect on enemies)
                        enemy:applySlow(1.0, 3.0)  -- 100% slow = stun
                        enemy:takeDamage(self.damage * 1.5)
                    end
                end
            end
            
            -- Visual effect
            self:spawnConeEffect(baseAngle, coneAngle, coneRange)
            
            -- Return to idle after animation
            self.timer:after(0.5, function()
                self.state = "idle"
            end)
            
            return true
        end,
        
        rally = function()
            -- Increase nearby tower damage
            local buffRange = 200
            local buffDuration = 10
            
            -- Visual effect
            self:spawnAuraEffect(buffRange)
            
            -- Buff nearby towers
            for _, tower in ipairs(gameState.towers) do
                local towerX, towerY = gameState.map:gridToWorld(tower.gridX, tower.gridY)
                towerX = towerX + gameState.map.tileSize / 2
                towerY = towerY + gameState.map.tileSize / 2
                
                local dx = towerX - self.x
                local dy = towerY - self.y
                local distance = math.sqrt(dx*dx + dy*dy)
                
                if distance <= buffRange then
                    -- Apply buff
                    tower.buffs["hero_rally"] = {
                        source = "hero",
                        damageMod = 1.3,  -- 30% damage increase
                        duration = buffDuration
                    }
                end
            end
            
            -- Return to idle after animation
            self.timer:after(1.0, function()
                self.state = "idle"
            end)
            
            return true
        end,
        
        -- Other ability implementations would go here
    }
    
    -- Call the appropriate handler
    if abilityHandlers[ability.id] then
        return abilityHandlers[ability.id]()
    else
        -- Default implementation for abilities without handlers
        Error.show("Ability not implemented: " .. ability.id)
        
        -- Return to idle after a short delay
        self.timer:after(0.5, function()
            self.state = "idle"
        end)
        
        return false
    end
end

-- Gain experience
function HeroInstance:gainExperience(amount)
    self.experience = self.experience + amount
    
    -- Level up if enough experience
    if self.experience >= self.experienceToNextLevel then
        self:levelUp()
    end
end

-- Level up
function HeroInstance:levelUp()
    self.level = self.level + 1
    self.experience = self.experience - self.experienceToNextLevel
    
    -- Increase experience required for next level
    self.experienceToNextLevel = math.floor(self.experienceToNextLevel * 1.5)
    
    -- Increase stats
    self.maxHealth = math.floor(self.maxHealth * 1.2)
    self.currentHealth = self.maxHealth
    self.damage = math.floor(self.damage * 1.15)
    
    -- Play level up effect
    self:spawnLevelUpEffect()
    
    -- Play sound
    playSound('sfx', 'levelUp')
    
    -- Check for achievement
    if self.level >= 10 then
        local Achievement = require('systems.achievement')
        if Achievement and Achievement.unlock then
            Achievement.unlock("hero_legend")
        end
    end
    
    -- Check for further level up
    if self.experience >= self.experienceToNextLevel then
        self:levelUp()
    end
end

-- Draw the hero
function HeroInstance:draw()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw hero sprite
    local sprite = Hero.sprites[self.id]
    if sprite then
        love.graphics.draw(sprite, self.x, self.y, 0, 1, 1, sprite:getWidth() / 2, sprite:getHeight() / 2)
    else
        -- Fallback if sprite is missing
        love.graphics.circle("fill", self.x, self.y, 20)
    end
    
    -- Draw health bar
    local healthBarWidth = 40
    local healthBarHeight = 5
    local healthPercentage = self.currentHealth / self.maxHealth
    
    -- Background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", self.x - healthBarWidth / 2, self.y - 35, healthBarWidth, healthBarHeight)
    
    -- Health
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle("fill", self.x - healthBarWidth / 2, self.y - 35, healthBarWidth * healthPercentage, healthBarHeight)
    
    -- Draw level
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.circle("fill", self.x - 20, self.y - 20, 10)
    
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setFont(fonts.small)
    love.graphics.print(tostring(self.level), self.x - 24, self.y - 25)
    love.graphics.setFont(fonts.main)
    
    -- Draw state indicator (for debugging)
    --[[
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(self.state, self.x - 20, self.y + 30)
    --]]
end

-- Visual effects

-- Spawn a circular aura effect
function HeroInstance:spawnAuraEffect(radius)
    local gameState = _G.gameState
    if not gameState or not gameState.effects then return end
    
    local effect = {
        x = self.x,
        y = self.y,
        radius = 0,
        maxRadius = radius,
        duration = 1.0,
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
            love.graphics.setColor(0.8, 0.8, 0, 0.3 * (1 - self.currentTime / self.duration))
            love.graphics.circle("fill", self.x, self.y, self.radius)
            
            love.graphics.setColor(1, 1, 0, 0.5 * (1 - self.currentTime / self.duration))
            love.graphics.circle("line", self.x, self.y, self.radius)
        end
    }
    
    table.insert(gameState.effects, effect)
end

-- Spawn a cone attack effect
function HeroInstance:spawnConeEffect(angle, coneAngle, range)
    local gameState = _G.gameState
    if not gameState or not gameState.effects then return end
    
    local effect = {
        x = self.x,
        y = self.y,
        angle = angle,
        coneAngle = coneAngle,
        range = range,
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
            love.graphics.setColor(0.8, 0.8, 1, 0.5 * (1 - progress))
            
            -- Draw cone
            local segments = 20
            local startAngle = self.angle - self.coneAngle / 2
            local endAngle = self.angle + self.coneAngle / 2
            local angleStep = (endAngle - startAngle) / segments
            
            love.graphics.polygon("fill", 
                self.x, self.y,
                self.x + math.cos(startAngle) * self.range, self.y + math.sin(startAngle) * self.range,
                self.x + math.cos(startAngle + angleStep) * self.range, self.y + math.sin(startAngle + angleStep) * self.range,
                self.x + math.cos(startAngle + 2 * angleStep) * self.range, self.y + math.sin(startAngle + 2 * angleStep) * self.range,
                self.x + math.cos(startAngle + 3 * angleStep) * self.range, self.y + math.sin(startAngle + 3 * angleStep) * self.range,
                self.x + math.cos(startAngle + 4 * angleStep) * self.range, self.y + math.sin(startAngle + 4 * angleStep) * self.range,
                self.x + math.cos(startAngle + 5 * angleStep) * self.range, self.y + math.sin(startAngle + 5 * angleStep) * self.range,
                self.x + math.cos(startAngle + 6 * angleStep) * self.range, self.y + math.sin(startAngle + 6 * angleStep) * self.range,
                self.x + math.cos(startAngle + 7 * angleStep) * self.range, self.y + math.sin(startAngle + 7 * angleStep) * self.range,
                self.x + math.cos(startAngle + 8 * angleStep) * self.range, self.y + math.sin(startAngle + 8 * angleStep) * self.range,
                self.x + math.cos(startAngle + 9 * angleStep) * self.range, self.y + math.sin(startAngle + 9 * angleStep) * self.range,
                self.x + math.cos(startAngle + 10 * angleStep) * self.range, self.y + math.sin(startAngle + 10 * angleStep) * self.range
            )
        end
    }
    
    table.insert(gameState.effects, effect)
end

-- Spawn level up effect
function HeroInstance:spawnLevelUpEffect()
    local gameState = _G.gameState
    if not gameState or not gameState.effects then return end
    
    local effect = {
        x = self.x,
        y = self.y,
        radius = 20,
        duration = 1.0,
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
            
            -- Outer circle
            love.graphics.setColor(1, 1, 0, 0.7 * (1 - progress))
            love.graphics.circle("line", self.x, self.y, self.radius + progress * 30)
            
            -- Inner circle
            love.graphics.setColor(1, 0.8, 0, 0.5 * (1 - progress))
            love.graphics.circle("fill", self.x, self.y, self.radius * (1 - progress/2))
            
            -- Level up text
            love.graphics.setColor(1, 1, 1, 1 - progress)
            love.graphics.setFont(fonts.main)
            local text = "Level " .. self.level
            local textWidth = fonts.main:getWidth(text)
            love.graphics.print(text, self.x - textWidth / 2, self.y - 50 - progress * 20)
        end
    }
    
    table.insert(gameState.effects, effect)
end

-- Return the module
return Hero 