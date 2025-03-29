local SplashState = {}
SplashState.__index = SplashState

local Timer = require 'libs.hump.timer'
local Gamestate = require 'libs.hump.gamestate'
local Error = require 'utils.error'

function SplashState.new()
    local self = setmetatable({}, SplashState)
    
    self.duration = 3  -- Duration in seconds to display splash
    self.fadeInTime = 0.5
    self.fadeOutTime = 0.5
    self.alpha = 0
    self.logo = nil
    self.logoScale = 1
    self.timer = Timer.new() -- Create a timer instance for this state
    
    return self
end

function SplashState:init()
    -- Initialize resources needed for the splash screen
    self:loadResources()
end

function SplashState:loadResources()
    -- Load the logo image
    local success, result = Error.pcall(function()
        -- Check if we have a splash.jpg in backgrounds folder
        if love.filesystem.getInfo("sprites/ui/backgrounds/splash.jpg") then
            self.logo = love.graphics.newImage("sprites/ui/backgrounds/splash.jpg")
        else
            -- Fallback to game_logo.png if available
            self.logo = love.graphics.newImage("sprites/ui/game_logo.png")
        end
    end)
    
    if not success then
        -- Use a text-based logo if image fails to load
        self.logo = nil
    end
end

function SplashState:enter()
    -- Reset timer values
    self.alpha = 0
    self.logoScale = 0.8
    
    -- Clear any existing timers
    self.timer:clear()
    
    -- Fade in
    self.timer:tween(self.fadeInTime, self, {alpha = 1}, 'linear')
    self.timer:tween(self.fadeInTime, self, {logoScale = 1}, 'out-elastic')
    
    -- Set timer for transition to menu state
    self.timer:after(self.duration, function()
        -- Fade out
        self.timer:tween(self.fadeOutTime, self, {alpha = 0}, 'linear', function()
            local menuState = require('states.menu').new()
            Gamestate.switch(menuState)
        end)
    end)
    
    -- Play splash sound
    if sounds and sounds.sfx and sounds.sfx.buttonClick then
        playSound('sfx', 'buttonClick')
    end
end

function SplashState:update(dt)
    -- Update timers
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function SplashState:draw()
    -- Clear the screen
    love.graphics.clear(0, 0, 0)
    
    -- Draw the logo
    love.graphics.setColor(1, 1, 1, self.alpha)
    
    if self.logo then
        -- Draw the logo image
        local x = love.graphics.getWidth() / 2 - (self.logo:getWidth() * self.logoScale) / 2
        local y = love.graphics.getHeight() / 2 - (self.logo:getHeight() * self.logoScale) / 2
        love.graphics.draw(self.logo, x, y, 0, self.logoScale, self.logoScale)
    else
        -- Draw text-based logo as fallback
        love.graphics.setFont(fonts.title)
        local text = "Tower Defense"
        local x = love.graphics.getWidth() / 2 - fonts.title:getWidth(text) / 2
        local y = love.graphics.getHeight() / 2 - fonts.title:getHeight() / 2
        love.graphics.print(text, x, y)
    end
    
    -- Draw error notifications
    Error.draw()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function SplashState:keypressed(key)
    -- Skip splash screen on any key press
    if key == "escape" or key == "return" or key == "space" then
        -- Clear existing timers
        self.timer:clear()
        
        -- Transition to menu immediately
        local menuState = require('states.menu').new()
        Gamestate.switch(menuState)
    end
end

function SplashState:mousepressed(x, y, button)
    -- Skip splash screen on any mouse press
    if button == 1 then
        -- Clear existing timers
        self.timer:clear()
        
        -- Transition to menu immediately
        local menuState = require('states.menu').new()
        Gamestate.switch(menuState)
    end
end

return SplashState 