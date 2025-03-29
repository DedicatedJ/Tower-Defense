local Achievement = {}
Achievement.__index = Achievement

-- Achievement definitions
local ACHIEVEMENTS = {
    {
        id = "first_tower",
        title = "First Tower",
        description = "Place your first tower",
        icon = "sprites/ui/achievements/first_tower.png",
        reward = 100,
        condition = function(gameState)
            return #gameState.towers > 0
        end
    },
    {
        id = "tower_master",
        title = "Tower Master",
        description = "Place 10 towers",
        icon = "sprites/ui/achievements/tower_master.png",
        reward = 500,
        condition = function(gameState)
            return #gameState.towers >= 10
        end
    },
    {
        id = "wave_survivor",
        title = "Wave Survivor",
        description = "Complete 5 waves",
        icon = "sprites/ui/achievements/wave_survivor.png",
        reward = 300,
        condition = function(gameState)
            return gameState.currentWave > 5
        end
    },
    {
        id = "hero_legend",
        title = "Hero Legend",
        description = "Level up your hero to level 10",
        icon = "sprites/ui/achievements/hero_legend.png",
        reward = 1000,
        condition = function(gameState)
            return gameState.hero and gameState.hero.level >= 10
        end
    },
    {
        id = "resource_king",
        title = "Resource King",
        description = "Accumulate 1000 resources",
        icon = "sprites/ui/achievements/resource_king.png",
        reward = 400,
        condition = function(gameState)
            return gameState.resources >= 1000
        end
    },
    {
        id = "perfect_wave",
        title = "Perfect Wave",
        description = "Complete a wave without losing any lives",
        icon = "sprites/ui/achievements/perfect_wave.png",
        reward = 600,
        condition = function(gameState)
            return gameState.lives == gameState.maxLives and gameState.waveCompleted
        end
    },
    {
        id = "tower_synergy",
        title = "Tower Synergy",
        description = "Create a tower synergy",
        icon = "sprites/ui/achievements/tower_synergy.png",
        reward = 800,
        condition = function(gameState)
            for _, tower in ipairs(gameState.towers) do
                if next(tower.synergies) then
                    return true
                end
            end
            return false
        end
    },
    {
        id = "faction_master",
        title = "Faction Master",
        description = "Complete a game with each faction",
        icon = "sprites/ui/achievements/faction_master.png",
        reward = 2000,
        condition = function(gameState)
            local completedFactions = gameState.saveData.completedFactions or {}
            return #completedFactions >= 3
        end
    }
}

function Achievement.new()
    local self = setmetatable({}, Achievement)
    
    self.achievements = {}
    self.notifications = {}
    self.notificationDuration = 5
    self.notificationTimer = 0
    
    -- Initialize achievements
    for _, achievement in ipairs(ACHIEVEMENTS) do
        self.achievements[achievement.id] = {
            data = achievement,
            unlocked = false,
            progress = 0
        }
    end
    
    return self
end

function Achievement:update(dt)
    -- Update notifications
    for i = #self.notifications, 1, -1 do
        local notification = self.notifications[i]
        notification.timer = notification.timer + dt
        if notification.timer >= self.notificationDuration then
            table.remove(self.notifications, i)
        end
    end
    
    -- Check for new achievements
    self:checkAchievements()
end

function Achievement:checkAchievements()
    for id, achievement in pairs(self.achievements) do
        if not achievement.unlocked and achievement.data.condition(gameState) then
            self:unlockAchievement(id)
        end
    end
end

function Achievement:unlockAchievement(id)
    local achievement = self.achievements[id]
    if not achievement or achievement.unlocked then return end
    
    achievement.unlocked = true
    
    -- Add notification
    table.insert(self.notifications, {
        achievement = achievement.data,
        timer = 0
    })
    
    -- Add reward
    gameState.resources = gameState.resources + achievement.data.reward
    
    -- Save achievement progress
    self:saveProgress()
    
    -- Play achievement sound
    playSound('sfx', 'achievement')
end

function Achievement:draw()
    -- Draw notifications
    for i, notification in ipairs(self.notifications) do
        local alpha = 1 - (notification.timer / self.notificationDuration)
        self:drawNotification(notification.achievement, i, alpha)
    end
end

function Achievement:drawNotification(achievement, index, alpha)
    local x = 20
    local y = 20 + (index - 1) * 80
    local width = 300
    local height = 70
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.8 * alpha)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw border
    love.graphics.setColor(1, 0.8, 0, alpha)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw icon
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(achievement.icon, x + 10, y + 10, 0, 0.5, 0.5)
    
    -- Draw text
    love.graphics.setFont(fonts.main)
    love.graphics.print(achievement.title, x + 60, y + 10)
    love.graphics.print(achievement.description, x + 60, y + 30)
    love.graphics.print("Reward: " .. achievement.reward, x + 60, y + 50)
end

function Achievement:saveProgress()
    local saveData = {
        achievements = {}
    }
    
    for id, achievement in pairs(self.achievements) do
        saveData.achievements[id] = {
            unlocked = achievement.unlocked,
            progress = achievement.progress
        }
    end
    
    -- Save to file
    local file = io.open("save/achievements.json", "w")
    if file then
        file:write(json.encode(saveData))
        file:close()
    end
end

function Achievement:loadProgress()
    local file = io.open("save/achievements.json", "r")
    if file then
        local data = json.decode(file:read("*all"))
        file:close()
        
        if data.achievements then
            for id, achievementData in pairs(data.achievements) do
                if self.achievements[id] then
                    self.achievements[id].unlocked = achievementData.unlocked
                    self.achievements[id].progress = achievementData.progress
                end
            end
        end
    end
end

return Achievement 