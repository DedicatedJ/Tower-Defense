local SettingsState = {}
SettingsState.__index = SettingsState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'
local Save = require 'systems.save'

function SettingsState.new()
    local self = setmetatable({}, SettingsState)
    
    self.title = "Settings"
    self.settings = {}
    self.sliders = {}
    self.toggles = {}
    self.buttons = {}
    self.backButton = nil
    self.timer = Timer.new() -- Create timer instance for this state
    
    -- Create settings UI elements
    self:createUI()
    
    return self
end

function SettingsState:init()
    -- Create UI elements
    self:createUI()
end

function SettingsState:createUI()
    -- Title
    self.titleText = {
        text = self.title,
        x = love.graphics.getWidth() / 2 - 100,
        y = 50,
        font = fonts.title
    }
    
    -- Copy settings from gameState
    self.settings = {
        musicVolume = gameState.settings.musicVolume,
        sfxVolume = gameState.settings.sfxVolume,
        showTutorial = gameState.settings.showTutorial,
        fullscreen = gameState.settings.fullscreen,
    }
    
    -- Volume sliders
    local sliderWidth = 400
    local sliderHeight = 20
    local startY = 150
    local spacing = 60
    
    -- Music volume slider
    self.sliders.music = {
        label = "Music Volume",
        x = love.graphics.getWidth() / 2 - sliderWidth / 2,
        y = startY,
        width = sliderWidth,
        height = sliderHeight,
        value = self.settings.musicVolume,
        min = 0,
        max = 1,
        dragging = false
    }
    
    -- SFX volume slider
    self.sliders.sfx = {
        label = "SFX Volume",
        x = love.graphics.getWidth() / 2 - sliderWidth / 2,
        y = startY + spacing,
        width = sliderWidth,
        height = sliderHeight,
        value = self.settings.sfxVolume,
        min = 0,
        max = 1,
        dragging = false
    }
    
    -- Toggle buttons
    local toggleWidth = 30
    local toggleHeight = 30
    local toggleStartY = startY + spacing * 2
    
    -- Tutorial toggle
    self.toggles.tutorial = {
        label = "Show Tutorial",
        x = love.graphics.getWidth() / 2 - sliderWidth / 2,
        y = toggleStartY,
        width = toggleWidth,
        height = toggleHeight,
        value = self.settings.showTutorial
    }
    
    -- Fullscreen toggle
    self.toggles.fullscreen = {
        label = "Fullscreen",
        x = love.graphics.getWidth() / 2 - sliderWidth / 2,
        y = toggleStartY + spacing,
        width = toggleWidth,
        height = toggleHeight,
        value = self.settings.fullscreen
    }
    
    -- Action buttons
    local buttonWidth = 150
    local buttonHeight = 50
    local buttonY = love.graphics.getHeight() - 100
    
    -- Save button
    self.buttons.save = {
        text = "Save",
        x = love.graphics.getWidth() / 2 - buttonWidth - 20,
        y = buttonY,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false
    }
    
    -- Cancel button
    self.buttons.cancel = {
        text = "Cancel",
        x = love.graphics.getWidth() / 2 + 20,
        y = buttonY,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false
    }
end

function SettingsState:enter()
    -- Refresh settings
    self:createUI()
end

function SettingsState:update(dt)
    -- Update timer
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function SettingsState:draw()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.titleText.font)
    love.graphics.print(self.titleText.text, self.titleText.x, self.titleText.y)
    
    -- Draw sliders
    love.graphics.setFont(fonts.main)
    
    for _, slider in pairs(self.sliders) do
        -- Draw slider label
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(slider.label, slider.x, slider.y - 25)
        
        -- Draw slider background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", slider.x, slider.y, slider.width, slider.height)
        
        -- Draw slider fill
        love.graphics.setColor(0.4, 0.4, 0.8, 0.8)
        local fillWidth = slider.width * slider.value
        love.graphics.rectangle("fill", slider.x, slider.y, fillWidth, slider.height)
        
        -- Draw slider handle
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        local handleX = slider.x + fillWidth - 5
        love.graphics.rectangle("fill", handleX, slider.y - 5, 10, slider.height + 10)
        
        -- Draw value percentage
        love.graphics.print(math.floor(slider.value * 100) .. "%", slider.x + slider.width + 10, slider.y)
    end
    
    -- Draw toggles
    for _, toggle in pairs(self.toggles) do
        -- Draw toggle label
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(toggle.label, toggle.x + toggle.width + 10, toggle.y + 5)
        
        -- Draw toggle background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", toggle.x, toggle.y, toggle.width, toggle.height)
        
        -- Draw toggle state
        if toggle.value then
            love.graphics.setColor(0.4, 0.8, 0.4, 0.8)
            love.graphics.rectangle("fill", toggle.x + 2, toggle.y + 2, toggle.width - 4, toggle.height - 4)
        end
        
        -- Draw toggle border
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.rectangle("line", toggle.x, toggle.y, toggle.width, toggle.height)
    end
    
    -- Draw buttons
    for _, button in pairs(self.buttons) do
        -- Draw button background
        if button.hovered then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        
        -- Draw button border
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        
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

function SettingsState:mousepressed(x, y, button)
    if button == 1 then
        -- Check sliders
        for _, slider in pairs(self.sliders) do
            if self:isPointInRect(x, y, slider.x, slider.y, slider.width, slider.height) then
                slider.dragging = true
                local value = (x - slider.x) / slider.width
                slider.value = math.max(slider.min, math.min(slider.max, value))
                
                -- Play test sound for volume sliders
                if slider == self.sliders.music then
                    setVolume('music', slider.value)
                    playSound('music', 'menu')
                elseif slider == self.sliders.sfx then
                    setVolume('sfx', slider.value)
                    playSound('sfx', 'buttonClick')
                end
            end
        end
        
        -- Check toggles
        for _, toggle in pairs(self.toggles) do
            if self:isPointInRect(x, y, toggle.x, toggle.y, toggle.width, toggle.height) then
                toggle.value = not toggle.value
                
                -- Apply fullscreen toggle immediately
                if toggle == self.toggles.fullscreen then
                    love.window.setFullscreen(toggle.value)
                end
                
                playSound('sfx', 'buttonClick')
            end
        end
        
        -- Check buttons
        for name, button in pairs(self.buttons) do
            if self:isPointInRect(x, y, button.x, button.y, button.width, button.height) then
                playSound('sfx', 'buttonClick')
                
                if name == "save" then
                    self:saveSettings()
                elseif name == "cancel" then
                    self:cancel()
                end
            end
        end
    end
end

function SettingsState:mousereleased(x, y, button)
    if button == 1 then
        -- Release all sliders
        for _, slider in pairs(self.sliders) do
            slider.dragging = false
        end
    end
end

function SettingsState:mousemoved(x, y, dx, dy)
    -- Update dragging sliders
    for _, slider in pairs(self.sliders) do
        if slider.dragging then
            local value = (x - slider.x) / slider.width
            slider.value = math.max(slider.min, math.min(slider.max, value))
            
            -- Update volume while dragging
            if slider == self.sliders.music then
                setVolume('music', slider.value)
            elseif slider == self.sliders.sfx then
                setVolume('sfx', slider.value)
            end
        end
    end
    
    -- Update button hover states
    for _, button in pairs(self.buttons) do
        button.hovered = self:isPointInRect(x, y, button.x, button.y, button.width, button.height)
    end
end

function SettingsState:isPointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

function SettingsState:saveSettings()
    -- Save settings to gameState
    gameState.settings.musicVolume = self.settings.musicVolume
    gameState.settings.sfxVolume = self.settings.sfxVolume
    gameState.settings.showTutorial = self.settings.showTutorial
    gameState.settings.fullscreen = self.settings.fullscreen
    
    -- Update actual settings from UI
    gameState.settings.musicVolume = self.sliders.music.value
    gameState.settings.sfxVolume = self.sliders.sfx.value
    gameState.settings.showTutorial = self.toggles.tutorial.value
    gameState.settings.fullscreen = self.toggles.fullscreen.value
    
    -- Save settings to disk
    Save:saveSettings()
    
    -- Return to previous state
    Gamestate.pop()
end

function SettingsState:cancel()
    -- Return to previous state without saving
    Gamestate.pop()
    
    -- Restore previous volume settings
    setVolume('music', gameState.settings.musicVolume)
    setVolume('sfx', gameState.settings.sfxVolume)
    
    -- Restore fullscreen setting
    love.window.setFullscreen(gameState.settings.fullscreen)
end

function SettingsState:keypressed(key)
    if key == "escape" then
        self:cancel()
    elseif key == "return" then
        self:saveSettings()
    end
end

return SettingsState 