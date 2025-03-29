local Wave = {}
Wave.__index = Wave

-- Dependencies
local Error = require 'utils.error'

-- Enemy types
local ENEMY_TYPES = {
    -- Ground enemies
    ground = {
        melee = {
            {
                id = "goblin",
                name = "Goblin",
                health = 100,
                speed = 1.5,
                damage = 10,
                armor = 0,
                magicResist = 0,
                reward = 10
            },
            {
                id = "orc",
                name = "Orc",
                health = 200,
                speed = 1.2,
                damage = 20,
                armor = 5,
                magicResist = 0,
                reward = 20
            },
            {
                id = "troll",
                name = "Troll",
                health = 300,
                speed = 0.8,
                damage = 30,
                armor = 10,
                magicResist = 5,
                reward = 30
            }
        },
        ranged = {
            {
                id = "archer",
                name = "Archer",
                health = 80,
                speed = 1.0,
                damage = 15,
                range = 150,
                armor = 0,
                magicResist = 0,
                reward = 15
            },
            {
                id = "crossbowman",
                name = "Crossbowman",
                health = 120,
                speed = 0.9,
                damage = 25,
                range = 200,
                armor = 3,
                magicResist = 0,
                reward = 25
            }
        },
        magic = {
            {
                id = "wizard",
                name = "Wizard",
                health = 90,
                speed = 1.1,
                damage = 20,
                range = 180,
                armor = 0,
                magicResist = 10,
                reward = 20
            },
            {
                id = "warlock",
                name = "Warlock",
                health = 150,
                speed = 0.9,
                damage = 35,
                range = 200,
                armor = 0,
                magicResist = 15,
                reward = 35
            }
        }
    },
    
    -- Air enemies
    air = {
        melee = {
            {
                id = "gargoyle",
                name = "Gargoyle",
                health = 150,
                speed = 2.0,
                damage = 15,
                armor = 5,
                magicResist = 5,
                reward = 25
            },
            {
                id = "wyvern",
                name = "Wyvern",
                health = 250,
                speed = 1.8,
                damage = 25,
                armor = 8,
                magicResist = 8,
                reward = 40
            }
        },
        ranged = {
            {
                id = "harpy",
                name = "Harpy",
                health = 100,
                speed = 2.2,
                damage = 12,
                range = 160,
                armor = 2,
                magicResist = 3,
                reward = 20
            }
        },
        magic = {
            {
                id = "phoenix",
                name = "Phoenix",
                health = 200,
                speed = 1.5,
                damage = 30,
                range = 180,
                armor = 0,
                magicResist = 20,
                reward = 35
            }
        }
    }
}

-- Elite modifiers
local ELITE_MODIFIERS = {
    {
        id = "double_projectiles",
        name = "Double Projectiles",
        description = "Takes double damage from projectiles",
        effect = function(enemy)
            enemy.damageMultiplier = 2
        end
    },
    {
        id = "vampiric",
        name = "Vampiric",
        description = "Heals for 20% of damage dealt",
        effect = function(enemy)
            enemy.lifeSteal = 0.2
        end
    },
    {
        id = "fast",
        name = "Fast",
        description = "50% increased movement speed",
        effect = function(enemy)
            enemy.speed = enemy.speed * 1.5
        end
    },
    {
        id = "tough",
        name = "Tough",
        description = "50% increased health",
        effect = function(enemy)
            enemy.health = enemy.health * 1.5
            enemy.maxHealth = enemy.maxHealth * 1.5
        end
    },
    {
        id = "resistant",
        name = "Resistant",
        description = "50% increased armor and magic resistance",
        effect = function(enemy)
            enemy.armor = enemy.armor * 1.5
            enemy.magicResist = enemy.magicResist * 1.5
        end
    }
}

-- Mini-boss mechanics
local MINI_BOSS_MECHANICS = {
    {
        id = "blood_pact",
        name = "Blood Pact",
        description = "Heals for 10% of max health when near minions",
        effect = function(enemy)
            enemy.healNearMinions = true
            enemy.healAmount = enemy.maxHealth * 0.1
        end
    },
    {
        id = "shockwave",
        name = "Shockwave",
        description = "Creates a shockwave that knocks back towers",
        effect = function(enemy)
            enemy.shockwave = true
            enemy.shockwaveDamage = enemy.damage * 0.5
            enemy.shockwaveRange = 100
        end
    },
    {
        id = "armor_plating",
        name = "Armor Plating",
        description = "Ignores first 50% of damage taken",
        effect = function(enemy)
            enemy.armorPlating = true
            enemy.armorPlatingAmount = 0.5
        end
    }
}

-- Boss mechanics
local BOSS_MECHANICS = {
    {
        id = "phase_shift",
        name = "Phase Shift",
        description = "Increases attack speed by 50% at 50% health",
        effect = function(enemy)
            enemy.phaseShift = true
            enemy.phaseShiftThreshold = 0.5
            enemy.phaseShiftBonus = 0.5
        end
    },
    {
        id = "soul_harvest",
        name = "Soul Harvest",
        description = "Spawns wraiths when enemies die nearby",
        effect = function(enemy)
            enemy.soulHarvest = true
            enemy.wraithSpawnChance = 0.3
        end
    },
    {
        id = "oblivion_aura",
        name = "Oblivion Aura",
        description = "Reduces tower range by 30%",
        effect = function(enemy)
            enemy.oblivionAura = true
            enemy.auraRange = 200
            enemy.auraEffect = 0.7
        end
    },
    {
        id = "elemental_cycle",
        name = "Elemental Cycle",
        description = "Rotates between different resistances",
        effect = function(enemy)
            enemy.elementalCycle = true
            enemy.cycleInterval = 5
            enemy.cycleTimer = 0
            enemy.cycleTypes = {
                {armor = 20, magicResist = 0},
                {armor = 0, magicResist = 20},
                {armor = 10, magicResist = 10}
            }
            enemy.currentCycle = 1
        end
    }
}

-- Wave definitions by difficulty
local waveDefs = {
    -- Early waves (1-5)
    early = {
        enemies = {"grunt", "runner"},
        bossWaves = {},
        enemyCount = {min = 5, max = 15},
        spawnDelay = {min = 1.0, max = 2.0},
        specialEnemyChance = 0.0
    },
    
    -- Mid-game waves (6-10)
    mid = {
        enemies = {"grunt", "runner", "tank"},
        bossWaves = {},
        enemyCount = {min = 10, max = 20},
        spawnDelay = {min = 0.8, max = 1.5},
        specialEnemyChance = 0.1,
        specialEnemies = {"healer"}
    },
    
    -- Late-game waves (11-15)
    late = {
        enemies = {"grunt", "runner", "tank", "flyer"},
        bossWaves = {15},
        enemyCount = {min = 15, max = 25},
        spawnDelay = {min = 0.6, max = 1.2},
        specialEnemyChance = 0.2,
        specialEnemies = {"healer", "shielder", "spawner"}
    },
    
    -- End-game waves (16-20)
    end_game = {
        enemies = {"grunt", "runner", "tank", "flyer"},
        bossWaves = {20},
        enemyCount = {min = 20, max = 30},
        spawnDelay = {min = 0.5, max = 1.0},
        specialEnemyChance = 0.3,
        specialEnemies = {"healer", "shielder", "spawner"}
    }
}

-- Faction-specific bosses
local factionBosses = {
    human = {"boss_warrior", "boss_mage", "boss_summoner"},
    elf = {"boss_mage", "boss_summoner", "boss_warrior"},
    dwarf = {"boss_warrior", "boss_summoner", "boss_mage"}
}

-- Wave difficulty scaling factors by wave number
local function getWaveDifficulty(waveNumber)
    if waveNumber <= 5 then
        return "early"
    elseif waveNumber <= 10 then
        return "mid"
    elseif waveNumber <= 15 then
        return "late"
    else
        return "end_game"
    end
end

-- Generate stats for an enemy based on wave number and type
local function generateEnemyStats(enemyType, waveNumber)
    local Enemy = require('systems.enemy')
    if not Enemy.types or not Enemy.types[enemyType] then
        Error.show("Invalid enemy type: " .. tostring(enemyType))
        return nil
    end
    
    local baseStats = Enemy.types[enemyType]
    
    -- Scale stats based on wave number
    local scaleFactor = 1 + (waveNumber - 1) * 0.1  -- 10% increase per wave
    
    -- Boss waves get a bigger boost
    local difficultyType = getWaveDifficulty(waveNumber)
    local waveDef = waveDefs[difficultyType]
    local isBossWave = false
    
    for _, bossWave in ipairs(waveDef.bossWaves) do
        if bossWave == waveNumber then
            isBossWave = true
            break
        end
    end
    
    if isBossWave then
        scaleFactor = scaleFactor * 1.5
    end
    
    -- Ensure bosses are always strong
    if enemyType:sub(1, 5) == "boss_" then
        scaleFactor = scaleFactor * 1.5
    end
    
    -- Generate stats
    return {
        type = enemyType,
        health = math.floor(baseStats.health * scaleFactor),
        speed = baseStats.speed,  -- Speed doesn't scale to keep game balanced
        damage = math.floor(baseStats.damage * scaleFactor),
        reward = math.floor(baseStats.reward * math.sqrt(scaleFactor)),  -- Reward scales slower
        spawnDelay = 0  -- Will be set later
    }
end

-- Add a static function for generating waves that doesn't require an instance
function Wave.generateWave(waveNumber, faction)
    -- Simple implementation to prevent errors
    local enemies = {}
    local waveSize = math.floor(5 + waveNumber * 1.5)
    
    -- Add regular enemies with minimal details needed
    for i = 1, waveSize do
        local enemy = {
            type = "grunt",  -- Basic enemy type
            health = 50 + (waveNumber * 10),
            speed = 50,
            damage = 1,
            reward = 10 + waveNumber,
            spawnDelay = 1.0
        }
        table.insert(enemies, enemy)
    end
    
    return enemies
end

-- Get information about upcoming waves
function Wave.getWaveInfo(currentWave, maxWaves)
    local info = {}
    
    for i = currentWave + 1, math.min(currentWave + 3, maxWaves) do
        local difficultyType = getWaveDifficulty(i)
        local waveDef = waveDefs[difficultyType]
        
        -- Check if this is a boss wave
        local isBossWave = false
        for _, bossWave in ipairs(waveDef.bossWaves) do
            if bossWave == i then
                isBossWave = true
                break
            end
        end
        
        local waveInfo = {
            number = i,
            enemyCount = {
                min = isBossWave and math.floor(waveDef.enemyCount.min / 2) or waveDef.enemyCount.min,
                max = isBossWave and math.floor(waveDef.enemyCount.min / 2) or waveDef.enemyCount.max
            },
            hasBoss = isBossWave,
            specialEnemies = waveDef.specialEnemyChance > 0
        }
        
        table.insert(info, waveInfo)
    end
    
    return info
end

-- Get total number of waves
function Wave.getTotalWaves()
    return 20
end

-- Get recommended difficulty based on player's progress
function Wave.getRecommendedDifficulty(playerStats)
    if not playerStats then return "normal" end
    
    local maxWaveReached = playerStats.maxWaveReached or 0
    local totalVictories = playerStats.totalVictories or 0
    
    if maxWaveReached >= 20 and totalVictories >= 3 then
        return "hard"
    elseif maxWaveReached >= 10 and totalVictories >= 1 then
        return "normal"
    else
        return "easy"
    end
end

-- Apply difficulty modifier to wave (easy = 0.8, normal = 1.0, hard = 1.3)
function Wave.applyDifficultyModifier(wave, difficulty)
    local difficultyModifiers = {
        easy = 0.8,
        normal = 1.0,
        hard = 1.3
    }
    
    local modifier = difficultyModifiers[difficulty] or 1.0
    
    for _, enemy in ipairs(wave) do
        enemy.health = math.floor(enemy.health * modifier)
        enemy.damage = math.floor(enemy.damage * modifier)
        enemy.reward = math.floor(enemy.reward * (1 + (1 - modifier) * 0.5))  -- Easier difficulties give slightly more resources
    end
    
    return wave
end

function Wave.new()
    local self = setmetatable({}, Wave)
    
    self.currentWave = 0
    self.enemies = {}
    self.spawnTimer = 0
    self.spawnInterval = 1
    self.waveInProgress = false
    self.bossWave = false
    
    return self
end

function Wave:startWave()
    self.currentWave = self.currentWave + 1
    self.enemies = self:generateWave()
    self.spawnTimer = 0
    self.waveInProgress = true
    self.bossWave = self.currentWave % 10 == 0
    
    gameState:showNotification("Wave " .. self.currentWave .. " started!")
end

function Wave:generateWave()
    local enemies = {}
    local waveSize = math.floor(5 + self.currentWave * 1.5)
    
    -- Add regular enemies
    for i = 1, waveSize do
        local enemy = self:generateEnemy()
        table.insert(enemies, enemy)
    end
    
    -- Add mini-boss every 5 waves
    if self.currentWave % 5 == 0 then
        local miniBoss = self:generateMiniBoss()
        table.insert(enemies, miniBoss)
    end
    
    -- Add boss every 10 waves
    if self.bossWave then
        local boss = self:generateBoss()
        table.insert(enemies, boss)
    end
    
    return enemies
end

function Wave:generateEnemy()
    local enemy = {}
    
    -- Choose enemy type
    local type = math.random() < 0.7 and "ground" or "air"
    local category = self:chooseCategory()
    local baseEnemy = self:chooseEnemy(type, category)
    
    -- Copy base stats
    for k, v in pairs(baseEnemy) do
        enemy[k] = v
    end
    
    -- Apply scaling
    self:scaleEnemy(enemy)
    
    -- Add elite modifier (20% chance)
    if math.random() < 0.2 then
        self:addEliteModifier(enemy)
    end
    
    return enemy
end

function Wave:generateMiniBoss()
    local enemy = self:generateEnemy()
    
    -- Increase stats
    enemy.health = enemy.health * 3
    enemy.maxHealth = enemy.maxHealth * 3
    enemy.damage = enemy.damage * 2
    enemy.reward = enemy.reward * 3
    
    -- Add mini-boss mechanic
    local mechanic = MINI_BOSS_MECHANICS[math.random(#MINI_BOSS_MECHANICS)]
    mechanic.effect(enemy)
    
    enemy.isMiniBoss = true
    enemy.name = "Mini-Boss " .. enemy.name
    
    return enemy
end

function Wave:generateBoss()
    local enemy = self:generateEnemy()
    
    -- Increase stats
    enemy.health = enemy.health * 5
    enemy.maxHealth = enemy.maxHealth * 5
    enemy.damage = enemy.damage * 3
    enemy.reward = enemy.reward * 5
    
    -- Add boss mechanics
    local mechanic1 = BOSS_MECHANICS[math.random(#BOSS_MECHANICS)]
    local mechanic2 = BOSS_MECHANICS[math.random(#BOSS_MECHANICS)]
    mechanic1.effect(enemy)
    mechanic2.effect(enemy)
    
    enemy.isBoss = true
    enemy.name = "Boss " .. enemy.name
    
    return enemy
end

function Wave:chooseCategory()
    local categories = {"melee", "ranged", "magic"}
    return categories[math.random(#categories)]
end

function Wave:chooseEnemy(type, category)
    local enemies = ENEMY_TYPES[type][category]
    return enemies[math.random(#enemies)]
end

function Wave:scaleEnemy(enemy)
    local waveMultiplier = 1 + (self.currentWave - 1) * 0.1
    
    enemy.health = enemy.health * waveMultiplier
    enemy.maxHealth = enemy.maxHealth * waveMultiplier
    enemy.damage = enemy.damage * waveMultiplier
    enemy.reward = enemy.reward * waveMultiplier
end

function Wave:addEliteModifier(enemy)
    local modifier = ELITE_MODIFIERS[math.random(#ELITE_MODIFIERS)]
    modifier.effect(enemy)
    enemy.isElite = true
    enemy.name = "Elite " .. enemy.name
end

function Wave:update(dt)
    if not self.waveInProgress then return end
    
    -- Update spawn timer
    self.spawnTimer = self.spawnTimer + dt
    
    -- Spawn enemies
    if self.spawnTimer >= self.spawnInterval and #self.enemies > 0 then
        local enemy = table.remove(self.enemies)
        gameState:spawnEnemy(enemy)
        self.spawnTimer = 0
    end
    
    -- Check wave completion
    if #self.enemies == 0 and gameState:getEnemyCount() == 0 then
        self:completeWave()
    end
end

function Wave:completeWave()
    self.waveInProgress = false
    
    -- Calculate rewards
    local baseReward = 100 * self.currentWave
    local bonusReward = self.bossWave and 500 or 0
    local totalReward = baseReward + bonusReward
    
    -- Apply rewards
    gameState.resources = gameState.resources + totalReward
    gameState:showNotification("Wave " .. self.currentWave .. " completed! +" .. totalReward .. " resources")
    
    -- Check for game completion
    if self.currentWave >= 30 then
        gameState:showVictory()
    end
end

function Wave:draw()
    -- Draw wave info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Wave: " .. self.currentWave, 10, 10)
    love.graphics.print("Enemies remaining: " .. (#self.enemies + gameState:getEnemyCount()), 10, 30)
    
    if self.bossWave then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("BOSS WAVE!", 10, 50)
    end
end

return Wave 