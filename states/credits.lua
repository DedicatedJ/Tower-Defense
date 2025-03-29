local CreditsState = {}
CreditsState.__index = CreditsState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function CreditsState.new()
    local self = setmetatable({}, CreditsState)
    
    self.title = "Credits"
    self.credits = {
        { category = "Development", items = {
            "Lead Developer",
            "Game Designer",
            "UI Designer",
            "Level Designer"
        }},
        { category = "Art", items = {
            "Character Artist",
            "Environment Artist",
            "UI Artist",
            "Animation"
        }},
        { category = "Sound", items = {
            "Music Composer",
            "Sound Effects",
            "Voice Acting"
        }},
        { category = "Libraries", items = {
            "LÖVE Framework",
            "HUMP (Helper Utilities for Massive Progression)",
            "STI (Simple Tiled Implementation)",
            "Bump.lua",
            "Jumper"
        }},
        { category = "Special Thanks", items = {
            "The LÖVE Community",
            "Beta Testers",
            "Family and Friends"
        }}
    }
    self.scrollY = 0
    self.scrollSpeed = 50
    self.backButton = nil
    self.timer = Timer.new()
    
    return self
end

function CreditsState:init()
    -- Create back button
    local buttonWidth = 100
    local buttonHeight = 40
    self.backButton = {
        text = "Back",
        x = 20,
        y = love.graphics.getHeight() - 60,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false
    }
end

function CreditsState:enter()
    -- Initialize credits when entering the state
    self:loadCredits()
    self:createUI()
    
    -- Play credits music or continue menu music
    -- playSound('music', 'menu')
end

function CreditsState:update(dt)
    -- Handle scrolling animation
    self.scrollY = self.scrollY - self.scrollSpeed * dt
    
    -- Reset scrolling when reaching the end
    local totalHeight = #self.credits * 30 + 100
    if self.scrollY < -totalHeight then
        self.scrollY = love.graphics.getHeight()
    end
    
    -- Update timer
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function CreditsState:draw()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.title)
    local titleWidth = fonts.title:getWidth(self.title)
    love.graphics.print(self.title, love.graphics.getWidth() / 2 - titleWidth / 2, 50)
    
    -- Draw credits
    love.graphics.setFont(fonts.main)
    local y = 150 - self.scrollY
    local spacing = 30
    
    for _, section in ipairs(self.credits) do
        -- Draw category
        love.graphics.setColor(1, 0.8, 0.2, 1)
        local categoryWidth = fonts.main:getWidth(section.category)
        love.graphics.print(section.category, love.graphics.getWidth() / 2 - categoryWidth / 2, y)
        y = y + spacing
        
        -- Draw items
        love.graphics.setColor(1, 1, 1, 1)
        for _, item in ipairs(section.items) do
            local itemWidth = fonts.main:getWidth(item)
            love.graphics.print(item, love.graphics.getWidth() / 2 - itemWidth / 2, y)
            y = y + spacing
        end
        
        -- Add extra space between sections
        y = y + spacing
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
    local backText = self.backButton.text or "Back"  -- Ensure text exists
    local backWidth = fonts.main and fonts.main:getWidth(backText) or 40  -- Provide default width if font is nil
    love.graphics.print(backText, self.backButton.x + (self.backButton.width - backWidth) / 2, self.backButton.y + 10)
    
    -- Draw scroll instructions
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    local instructions = "Use mouse wheel to scroll"
    local instrWidth = fonts.main:getWidth(instructions)
    love.graphics.print(instructions, love.graphics.getWidth() / 2 - instrWidth / 2, love.graphics.getHeight() - 30)
    
    -- Draw error notifications
    Error.draw()
end

function CreditsState:mousepressed(x, y, button)
    if button == 1 then
        if self:isPointInButton(x, y, self.backButton) then
            playSound('sfx', 'buttonClick')
            Gamestate.pop()
        end
    end
end

function CreditsState:mousemoved(x, y, dx, dy)
    -- Update button hover state
    self.backButton.hovered = self:isPointInButton(x, y, self.backButton)
end

function CreditsState:wheelmoved(x, y)
    -- Scroll credits
    self.scrollY = self.scrollY - y * self.scrollSpeed
    
    -- Clamp scroll position
    local totalHeight = #self.credits * 30 * 5 -- Approximate total height
    self.scrollY = math.max(0, math.min(self.scrollY, totalHeight - 400))
end

function CreditsState:isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

function CreditsState:keypressed(key)
    if key == "escape" then
        playSound('sfx', 'buttonClick')
        Gamestate.pop()
    end
end

function CreditsState:loadCredits()
    -- Define credits content
    self.credits = {
        { title = "Game Design", names = {"John Doe", "Jane Smith"} },
        { title = "Programming", names = {"Alice Johnson", "Bob Williams"} },
        { title = "Art", names = {"Charlie Brown", "Diana Miller"} },
        { title = "Music & Sound", names = {"Eve Clark", "Frank Davis"} },
        { title = "Testing", names = {"Grace Wilson", "Henry Taylor"} },
        { title = "Special Thanks", names = {"LÖVE Community", "GitHub", "StackOverflow"} }
    }
end

function CreditsState:createUI()
    -- Create back button
    local buttonWidth = 100
    local buttonHeight = 40
    
    self.backButton = {
        text = "Back",
        x = love.graphics.getWidth() / 2 - buttonWidth / 2,
        y = love.graphics.getHeight() - 60,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false
    }
end

return CreditsState 