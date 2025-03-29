local AchievementState = {}
AchievementState.__index = AchievementState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function AchievementState.new()
    local self = setmetatable({}, AchievementState)
    
    self.title = "Achievements"
    self.achievements = {}
    self.scrollY = 0
    self.maxScrollY = 0
    self.backButton = nil
    self.timer = Timer.new() -- Create timer instance for this state
    
    -- Load achievements data
    self:loadAchievements()
    
    return self
end

function AchievementState:init()
    -- Create back button
    self.backButton = {
        text = "Back",
        x = 20,
        y = love.graphics.getHeight() - 60,
        width = 100,
        height = 40,
        hovered = false
    }
    
    -- Load achievements
    self:loadAchievements()
end

function AchievementState:loadAchievements()
    -- In a real implementation, this would load from the Achievement system
    -- For now, use placeholder achievements
    self.achievements = {
        {
            id = "first_win",
            title = "First Victory",
            description = "Win your first game",
            icon = nil,
            unlocked = true,
            date = "2023-06-15"
        },
        {
            id = "tower_master",
            title = "Tower Master",
            description = "Build 50 towers in total",
            icon = nil,
            unlocked = true,
            date = "2023-06-20"
        },
        {
            id = "wave_survivor",
            title = "Wave Survivor",
            description = "Survive 20 waves in a single game",
            icon = nil,
            unlocked = true,
            date = "2023-07-01"
        },
        {
            id = "resource_king",
            title = "Resource King",
            description = "Accumulate 10,000 resources in a single game",
            icon = nil,
            unlocked = false,
            progress = 7500,
            maxProgress = 10000
        },
        {
            id = "hero_legend",
            title = "Hero Legend",
            description = "Level up your hero to level 10",
            icon = nil,
            unlocked = false,
            progress = 7,
            maxProgress = 10
        },
        {
            id = "faction_master",
            title = "Faction Master",
            description = "Win a game with each faction",
            icon = nil,
            unlocked = false,
            progress = 1,
            maxProgress = 3
        },
        {
            id = "perfect_defense",
            title = "Perfect Defense",
            description = "Complete a game without losing any lives",
            icon = nil,
            unlocked = false
        },
        {
            id = "speed_run",
            title = "Speed Run",
            description = "Win a game in under 10 minutes",
            icon = nil,
            unlocked = false
        },
        {
            id = "upgrade_expert",
            title = "Upgrade Expert",
            description = "Fully upgrade 20 towers",
            icon = nil,
            unlocked = false,
            progress = 12,
            maxProgress = 20
        },
        {
            id = "synergy_master",
            title = "Synergy Master",
            description = "Have 5 different tower types with synergy bonuses active at once",
            icon = nil,
            unlocked = false,
            progress = 3,
            maxProgress = 5
        }
    }
    
    -- Try to load achievement icons
    for _, achievement in ipairs(self.achievements) do
        local success, result = Error.pcall(function()
            achievement.icon = love.graphics.newImage("sprites/ui/achievements/" .. achievement.id .. ".png")
        end)
        
        if not success then
            achievement.icon = nil
        end
    end
end

function AchievementState:enter()
    -- Reset scroll position
    self.scrollY = 0
    
    -- Play sound effect
    playSound('sfx', 'buttonClick')
end

function AchievementState:update(dt)
    -- Update timer
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function AchievementState:draw()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.title)
    local titleWidth = fonts.title:getWidth(self.title)
    love.graphics.print(self.title, love.graphics.getWidth() / 2 - titleWidth / 2, 50)
    
    -- Draw achievements
    love.graphics.setFont(fonts.main)
    
    local achievementWidth = 700
    local achievementHeight = 100
    local spacing = 20
    local startY = 120 - self.scrollY
    
    local totalHeight = #self.achievements * (achievementHeight + spacing)
    local visibleHeight = love.graphics.getHeight() - 180
    
    -- Draw scrollbar if needed
    if totalHeight > visibleHeight then
        -- Scrollbar background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill", 
            love.graphics.getWidth() - 20, 
            120, 
            10, 
            visibleHeight)
        
        -- Scrollbar handle
        local handleHeight = visibleHeight * (visibleHeight / totalHeight)
        local handleY = 120 + (self.scrollY / totalHeight) * visibleHeight
        
        love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
        love.graphics.rectangle("fill", 
            love.graphics.getWidth() - 20, 
            handleY, 
            10, 
            handleHeight)
    end
    
    -- Draw each achievement
    for i, achievement in ipairs(self.achievements) do
        local y = startY + (i - 1) * (achievementHeight + spacing)
        
        -- Only draw visible achievements (simple culling)
        if y + achievementHeight > 120 and y < love.graphics.getHeight() - 60 then
            -- Achievement background
            if achievement.unlocked then
                love.graphics.setColor(0.3, 0.3, 0.4, 0.8)
            else
                love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
            end
            
            love.graphics.rectangle("fill", 
                love.graphics.getWidth() / 2 - achievementWidth / 2, 
                y, 
                achievementWidth, 
                achievementHeight)
            
            -- Achievement border
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.rectangle("line", 
                love.graphics.getWidth() / 2 - achievementWidth / 2, 
                y, 
                achievementWidth, 
                achievementHeight)
            
            -- Achievement icon
            if achievement.icon then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(achievement.icon, 
                    love.graphics.getWidth() / 2 - achievementWidth / 2 + 20, 
                    y + 10, 
                    0, 0.7, 0.7)
            else
                -- Placeholder icon
                if achievement.unlocked then
                    love.graphics.setColor(0.8, 0.8, 0.2, 1)
                else
                    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                end
                
                love.graphics.rectangle("fill", 
                    love.graphics.getWidth() / 2 - achievementWidth / 2 + 20, 
                    y + 20, 
                    60, 
                    60)
                
                love.graphics.setColor(0, 0, 0, 0.3)
                love.graphics.rectangle("line", 
                    love.graphics.getWidth() / 2 - achievementWidth / 2 + 20, 
                    y + 20, 
                    60, 
                    60)
            end
            
            -- Achievement title
            if achievement.unlocked then
                love.graphics.setColor(1, 0.8, 0.2, 1)
            else
                love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
            end
            
            love.graphics.print(achievement.title, 
                love.graphics.getWidth() / 2 - achievementWidth / 2 + 100, 
                y + 20)
            
            -- Achievement description
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(achievement.description, 
                love.graphics.getWidth() / 2 - achievementWidth / 2 + 100, 
                y + 50)
            
            -- Achievement progress or date
            if achievement.unlocked then
                love.graphics.setColor(0.5, 1, 0.5, 1)
                love.graphics.print("Unlocked" .. (achievement.date and " on " .. achievement.date or ""), 
                    love.graphics.getWidth() / 2 - achievementWidth / 2 + 100, 
                    y + 70)
            elseif achievement.progress and achievement.maxProgress then
                -- Draw progress bar
                love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
                love.graphics.rectangle("fill", 
                    love.graphics.getWidth() / 2 - achievementWidth / 2 + 100, 
                    y + 75, 
                    300, 
                    10)
                
                local progressWidth = (achievement.progress / achievement.maxProgress) * 300
                love.graphics.setColor(0.3, 0.7, 0.3, 0.8)
                love.graphics.rectangle("fill", 
                    love.graphics.getWidth() / 2 - achievementWidth / 2 + 100, 
                    y + 75, 
                    progressWidth, 
                    10)
                
                -- Progress text
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
                local progressText = achievement.progress .. " / " .. achievement.maxProgress
                love.graphics.print(progressText, 
                    love.graphics.getWidth() / 2 - achievementWidth / 2 + 410, 
                    y + 70)
            else
                love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
                love.graphics.print("Locked", 
                    love.graphics.getWidth() / 2 - achievementWidth / 2 + 100, 
                    y + 70)
            end
        end
    end
    
    -- Draw back button
    if self.backButton.hovered then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    end
    love.graphics.rectangle("fill", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height)
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.backButton.text, self.backButton.x + 30, self.backButton.y + 10)
    
    -- Draw achievement stats
    local unlocked = 0
    for _, achievement in ipairs(self.achievements) do
        if achievement.unlocked then
            unlocked = unlocked + 1
        end
    end
    
    local statsText = string.format("Unlocked: %d / %d (%.1f%%)", 
        unlocked, 
        #self.achievements, 
        (unlocked / #self.achievements) * 100)
    
    love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
    local statsWidth = fonts.main:getWidth(statsText)
    love.graphics.print(statsText, 
        love.graphics.getWidth() / 2 - statsWidth / 2, 
        love.graphics.getHeight() - 30)
    
    -- Draw scroll instructions
    love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
    local instructions = "Use mouse wheel to scroll"
    local instrWidth = fonts.main:getWidth(instructions)
    love.graphics.print(instructions, 
        20, 
        100)
        
    -- Draw error notifications
    Error.draw()
end

function AchievementState:mousepressed(x, y, button)
    if button == 1 then
        if self:isPointInButton(x, y, self.backButton) then
            playSound('sfx', 'buttonClick')
            Gamestate.pop()
        end
    end
end

function AchievementState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    self.backButton.hovered = self:isPointInButton(x, y, self.backButton)
end

function AchievementState:wheelmoved(x, y)
    -- Scroll achievements
    self.scrollY = self.scrollY - y * self.scrollSpeed
    
    -- Clamp scroll position
    local achievementHeight = 100
    local spacing = 20
    local totalHeight = #self.achievements * (achievementHeight + spacing)
    local visibleHeight = love.graphics.getHeight() - 180
    
    self.scrollY = math.max(0, math.min(self.scrollY, math.max(0, totalHeight - visibleHeight)))
end

function AchievementState:isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

function AchievementState:keypressed(key)
    if key == "escape" then
        playSound('sfx', 'buttonClick')
        Gamestate.pop()
    end
end

return AchievementState 