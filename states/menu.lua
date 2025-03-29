local MenuState = {}
MenuState.__index = MenuState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function MenuState.new()
    local self = setmetatable({}, MenuState)
    
    self.title = "Tower Defense"
    self.buttons = {}
    self.background = nil
    self.timer = Timer.new() -- Create timer instance for this state
    
    return self
end

function MenuState:init()
    -- Load background image
    local success, result = Error.pcall(function()
        -- Try to load menu.jpg first
        if love.filesystem.getInfo("sprites/ui/backgrounds/menu.jpg") then
            self.background = love.graphics.newImage("sprites/ui/backgrounds/menu.jpg")
        else
            self.background = love.graphics.newImage("sprites/ui/menu_background.png")
        end
    end)
    
    if not success then
        self.background = nil
    end
    
    -- Create menu buttons
    self:createButtons()
end

function MenuState:createButtons()
    local buttonWidth = 200
    local buttonHeight = 50
    local spacing = 20
    local startY = love.graphics.getHeight() / 2 - (5 * buttonHeight + 4 * spacing) / 2
    
    -- Menu options
    local options = {
        {text = "New Game", action = function() self:newGame() end},
        {text = "Load Game", action = function() self:loadGame() end},
        {text = "Settings", action = function() self:openSettings() end},
        {text = "Credits", action = function() self:showCredits() end},
        {text = "Quit", action = function() self:quitGame() end}
    }
    
    for i, option in ipairs(options) do
        local y = startY + (i - 1) * (buttonHeight + spacing)
        
        self.buttons[i] = {
            text = option.text,
            x = love.graphics.getWidth() / 2 - buttonWidth / 2,
            y = y,
            width = buttonWidth,
            height = buttonHeight,
            action = option.action,
            hovered = false
        }
    end
end

function MenuState:enter()
    -- Play menu music
    playSound('music', 'menu')
end

function MenuState:leave()
    -- Stop menu music
    stopSound('music', 'menu')
end

function MenuState:update(dt)
    -- Update timers
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function MenuState:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1, 1)
    
    if self.background then
        love.graphics.draw(self.background, 0, 0, 0, 
            love.graphics.getWidth() / self.background:getWidth(),
            love.graphics.getHeight() / self.background:getHeight())
    else
        -- Fallback background
        love.graphics.setColor(0.1, 0.1, 0.2, 1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- Draw title with much larger font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.title)
    local titleWidth = fonts.title:getWidth(self.title)
    -- Scale the title text up by 1.8 instead of 1.3
    love.graphics.print(self.title, love.graphics.getWidth() / 2 - (titleWidth * 1.8) / 2, 60, 0, 1.8, 1.8)
    
    -- Draw version
    love.graphics.setFont(fonts.main)
    local version = "v0.1.0"
    love.graphics.print(version, 10, love.graphics.getHeight() - 30)
    
    -- Draw buttons
    for _, button in ipairs(self.buttons) do
        -- Draw button background with rounded corners (10px radius)
        if button.hovered then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Draw button border with rounded corners
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Draw button text
        love.graphics.setColor(1, 1, 1, 1)
        local textWidth = fonts.main:getWidth(button.text)
        local textHeight = fonts.main:getHeight()
        love.graphics.print(
            button.text, 
            button.x + button.width / 2 - textWidth / 2, 
            button.y + button.height / 2 - textHeight / 2
        )
    end
    
    -- Draw error notifications
    Error.draw()
end

function MenuState:mousepressed(x, y, button)
    if button == 1 then
        for _, button in ipairs(self.buttons) do
            if self:isPointInButton(x, y, button) then
                -- Play click sound
                playSound('sfx', 'buttonClick')
                
                -- Execute button action
                button.action()
            end
        end
    end
end

function MenuState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    for _, button in ipairs(self.buttons) do
        button.hovered = self:isPointInButton(x, y, button)
    end
end

function MenuState:isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

-- Button actions
function MenuState:newGame()
    local factionSelectState = require('states.faction_select').new()
    Gamestate.switch(factionSelectState)
end

function MenuState:loadGame()
    local loadGameState = require('states.load_game').new()
    Gamestate.push(loadGameState)
end

function MenuState:openSettings()
    local settingsState = require('states.settings').new()
    Gamestate.push(settingsState)
end

function MenuState:showCredits()
    local creditsState = require('states.credits').new()
    Gamestate.push(creditsState)
end

function MenuState:quitGame()
    love.event.quit()
end

function MenuState:keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

return MenuState 