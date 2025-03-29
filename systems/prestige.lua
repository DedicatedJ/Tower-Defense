local Prestige = {}

-- Prestige bonuses
local prestigeBonuses = {
    {
        level = 1,
        name = "Resource Boost",
        description = "+10% starting resources",
        effect = function(gameState)
            gameState.resources = math.floor(gameState.resources * 1.1)
        end
    },
    {
        level = 2,
        name = "Tower Discount",
        description = "-5% tower costs",
        effect = function(gameState)
            gameState.towerCostMultiplier = 0.95
        end
    },
    {
        level = 3,
        name = "Hero Experience",
        description = "+20% hero experience gain",
        effect = function(gameState)
            gameState.heroExperienceMultiplier = 1.2
        end
    },
    {
        level = 4,
        name = "Wave Rewards",
        description = "+15% wave completion rewards",
        effect = function(gameState)
            gameState.waveRewardMultiplier = 1.15
        end
    },
    {
        level = 5,
        name = "Prestige Points",
        description = "+25% prestige points gained",
        effect = function(gameState)
            gameState.prestigePointMultiplier = 1.25
        end
    }
}

function Prestige.calculatePrestigePoints(gameState)
    local points = 0
    points = points + (gameState.waveNumber * 100)
    points = points + (gameState.hero.level * 50)
    points = points + (gameState.resources * 0.1)
    points = points + (#gameState.towers * 25)
    
    return math.floor(points * (gameState.prestigePointMultiplier or 1))
end

function Prestige.prestige(gameState)
    local points = Prestige.calculatePrestigePoints(gameState)
    gameState.prestigeLevel = gameState.prestigeLevel + 1
    gameState.prestigePoints = (gameState.prestigePoints or 0) + points
    
    -- Apply prestige bonuses
    for _, bonus in ipairs(prestigeBonuses) do
        if gameState.prestigeLevel >= bonus.level then
            bonus.effect(gameState)
        end
    end
    
    -- Reset game state
    gameState.currentArea = 1
    gameState.currentMap = 1
    gameState.resources = 100
    gameState.lives = 3
    gameState.currentWave = 1
    gameState.towers = {}
    gameState.mapTowers = {}
    
    -- Keep hero but reset level
    gameState.hero.level = 1
    gameState.hero.experience = 0
    
    playSound('sfx', 'prestige')
    return points
end

function Prestige.getAvailableBonuses(gameState)
    local available = {}
    for _, bonus in ipairs(prestigeBonuses) do
        if gameState.prestigeLevel >= bonus.level then
            table.insert(available, bonus)
        end
    end
    return available
end

function Prestige.drawPrestigeMenu(x, y)
    love.graphics.setFont(fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Prestige Level: " .. gameState.prestigeLevel, x, y)
    
    love.graphics.setFont(fonts.main)
    love.graphics.print("Prestige Points: " .. (gameState.prestigePoints or 0), x, y + 40)
    
    -- Draw available bonuses
    local available = Prestige.getAvailableBonuses(gameState)
    for i, bonus in ipairs(available) do
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(bonus.name, x, y + 80 + (i-1) * 30)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print(bonus.description, x + 20, y + 100 + (i-1) * 30)
    end
end

return Prestige 