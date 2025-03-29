local PauseState = {}
PauseState.__index = PauseState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'
local Save = require 'systems.save'

function PauseState.new(previousState)
    local self = setmetatable({}, PauseState)
    
    self.title = "Game Paused"
    self.buttons = {}
    self.previousState = previousState
    self.timer = Timer.new() -- Add timer instance
    self.background = nil
    
    -- Load background image
    local success, result = pcall(function()
        self.background = love.graphics.newImage("assets/backgrounds/pause.jpg")
    end)
    
    if not success then
        -- Try loading a fallback background or just use the game as background
        success, result = pcall(function()
            self.background = love.graphics.newImage("sprites/ui/backgrounds/pause_bg.jpg")
        end)
        
        if not success then
            -- No need to throw an error, we'll use the game as background
            self.background = nil
            print("Using game as background for pause screen")
        end
    end
    
    -- Initialize UI
    self:init()
    
    return self
end

function PauseState:init()
    -- Create UI elements
    self:createButtons()
end

function PauseState:createButtons()
    local buttonWidth = 200
    local buttonHeight = 50
    local spacing = 20
    local startY = love.graphics.getHeight() / 2 - 75
    
    -- Menu options
    local options = {
        {text = "Resume", action = function() self:resumeGame() end},
        {text = "Save Game", action = function() self:saveGame() end},
        {text = "Settings", action = function() self:openSettings() end},
        {text = "Return to Menu", action = function() self:returnToMenu() end}
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

function PauseState:enter(previous)
    -- Store the previous state so we can return to it
    self.previousState = previous
    
    -- Play sound effect
    playSound('sfx', 'buttonClick')
end

function PauseState:update(dt)
    -- Update timers
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
    
    -- Still update the game slightly in background (animations, etc.)
    if self.previousState and self.previousState.update then
        self.previousState:update(dt * 0.1) -- Slow down updates
    end
end

function PauseState:draw()
    -- Draw the game in the background (slightly darkened)
    if self.previousState and self.previousState.draw then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        self.previousState:draw()
    end
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw background image
    if self.background then
        love.graphics.setColor(1, 1, 1, 0.8)
        
        -- Calculate dimensions to center the image
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local imgWidth = self.background:getWidth()
        local imgHeight = self.background:getHeight()
        
        -- Scale to fit the screen while maintaining aspect ratio
        local scale = math.min(screenWidth / imgWidth, screenHeight / imgHeight)
        local scaledWidth = imgWidth * scale
        local scaledHeight = imgHeight * scale
        
        -- Center the image
        local x = (screenWidth - scaledWidth) / 2
        local y = (screenHeight - scaledHeight) / 2
        
        love.graphics.draw(self.background, x, y, 0, scale, scale)
    end
    
    -- Draw pause menu container
    love.graphics.setColor(0.1, 0.1, 0.2, 0.85)
    local menuWidth = 300
    local menuHeight = 400
    love.graphics.rectangle(
        "fill", 
        love.graphics.getWidth() / 2 - menuWidth / 2, 
        love.graphics.getHeight() / 2 - menuHeight / 2, 
        menuWidth, 
        menuHeight,
        10, 10
    )
    
    love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
    love.graphics.rectangle(
        "line", 
        love.graphics.getWidth() / 2 - menuWidth / 2, 
        love.graphics.getHeight() / 2 - menuHeight / 2, 
        menuWidth, 
        menuHeight,
        10, 10
    )
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.title)
    local titleWidth = fonts.title:getWidth(self.title)
    love.graphics.print(
        self.title, 
        love.graphics.getWidth() / 2 - titleWidth / 2, 
        love.graphics.getHeight() / 2 - menuHeight / 2 + 30
    )
    
    -- Draw buttons
    for _, button in ipairs(self.buttons) do
        -- Draw button background
        if button.hovered then
            love.graphics.setColor(0.4, 0.4, 0.6, 0.9)
        else
            love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
        end
        
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)
        
        -- Draw button border
        love.graphics.setColor(0.6, 0.6, 0.8, 0.8)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)
        
        -- Draw button text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fonts.main)
        local textWidth = fonts.main:getWidth(button.text)
        local textHeight = fonts.main:getHeight()
        love.graphics.print(
            button.text, 
            button.x + button.width / 2 - textWidth / 2, 
            button.y + button.height / 2 - textHeight / 2
        )
    end
    
    -- Draw pause instructions
    love.graphics.setColor(1, 1, 1, 0.8)
    local instructions = "Press ESC to resume"
    local instrWidth = fonts.main:getWidth(instructions)
    love.graphics.print(
        instructions, 
        love.graphics.getWidth() / 2 - instrWidth / 2, 
        love.graphics.getHeight() / 2 + menuHeight / 2 - 30
    )
    
    -- Draw error notifications
    Error.draw()
end

function PauseState:mousepressed(x, y, button)
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

function PauseState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    for _, button in ipairs(self.buttons) do
        button.hovered = self:isPointInButton(x, y, button)
    end
end

function PauseState:isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

-- Button actions
function PauseState:resumeGame()
    Gamestate.pop()
end

function PauseState:saveGame()
    -- Attempt to save the game
    local success, result = Error.pcall(function()
        if Save.saveGame then
            -- Save to current slot or prompt for slot selection
            local currentSlot = Save:getCurrentSlot() or 1
            Save:saveGame(currentSlot)
            
            -- Display success message
            Error.handle(Error.TYPES.SUCCESS, "GAME_SAVED", "Game saved successfully")
        else
            -- Mock saving for testing
            Error.handle(Error.TYPES.SYSTEM, "SYSTEM_INCOMPLETE", "Save system not fully implemented")
        end
    end)
    
    if not success then
        Error.handle(Error.TYPES.SYSTEM, "SAVE_ERROR", "Failed to save game: " .. tostring(result))
    end
end

function PauseState:openSettings()
    -- Push settings state
    local settingsState = require('states.settings').new()
    Gamestate.push(settingsState)
end

function PauseState:returnToMenu()
    -- Ask for confirmation
    if true then -- TODO: Add confirmation dialog
        -- Switch to menu state
        local menuState = require('states.menu').new()
        Gamestate.switch(menuState)
    end
end

function PauseState:keypressed(key)
    if key == "escape" then
        self:resumeGame()
    end
end

return PauseState 