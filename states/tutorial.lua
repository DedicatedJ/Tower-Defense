local TutorialState = {}
TutorialState.__index = TutorialState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function TutorialState.new()
    local self = setmetatable({}, TutorialState)
    
    self.title = "How to Play"
    self.currentPage = 1
    self.pages = {
        {
            title = "Welcome to Tower Defense",
            content = "This tutorial will guide you through the basics of playing Tower Defense. Use arrow keys or buttons below to navigate.",
            image = nil
        },
        {
            title = "Select Your Faction",
            content = "Each faction has unique towers and abilities. Choose the one that fits your playstyle: Radiant, Shadow, or Twilight.",
            image = nil
        },
        {
            title = "Choose Your Hero",
            content = "Heroes provide special abilities and bonuses. Each faction has different heroes with unique skills.",
            image = nil
        },
        {
            title = "Building Towers",
            content = "Click on tower spots (highlighted in green) to build towers. Different towers have different ranges, damage types, and abilities.",
            image = nil
        },
        {
            title = "Upgrade Towers",
            content = "Click on an existing tower to select it, then press the upgrade button to make it stronger. Upgrades cost resources.",
            image = nil
        },
        {
            title = "Enemy Waves",
            content = "Enemies come in waves. Each wave gets progressively harder. Defeat all enemies to complete a wave.",
            image = nil
        },
        {
            title = "Hero Abilities",
            content = "Your hero has special abilities that can turn the tide of battle. Use them wisely as they have cooldowns.",
            image = nil
        },
        {
            title = "Resources",
            content = "Defeat enemies to earn resources. Use resources to build and upgrade towers or activate special abilities.",
            image = nil
        },
        {
            title = "Ready to Play!",
            content = "You're now ready to defend your territory! Good luck and have fun!",
            image = nil
        }
    }
    
    self.currentStep = 1
    self.totalSteps = 5
    self.tutorialText = {}
    self.buttons = {}
    self.images = {}
    self.timer = Timer.new() -- Create timer instance for this state
    
    -- Initialize tutorial content
    self:initTutorial()
    
    return self
end

function TutorialState:init()
    -- Load tutorial images
    self:loadImages()
    
    -- Create navigation buttons
    self:createButtons()
end

function TutorialState:loadImages()
    -- Attempt to load tutorial images
    for i, page in ipairs(self.pages) do
        local success, result = Error.pcall(function()
            page.image = love.graphics.newImage("sprites/ui/tutorial/tutorial_" .. i .. ".png")
        end)
        
        if not success then
            page.image = nil
        end
    end
end

function TutorialState:createButtons()
    local buttonWidth = 120
    local buttonHeight = 40
    local buttonY = love.graphics.getHeight() - 60
    
    -- Previous button
    self.prevButton = {
        text = "Previous",
        x = love.graphics.getWidth() / 2 - buttonWidth - 20,
        y = buttonY,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false
    }
    
    -- Next button
    self.nextButton = {
        text = "Next",
        x = love.graphics.getWidth() / 2 + 20,
        y = buttonY,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false
    }
    
    -- Back to menu button
    self.backButton = {
        text = "Back",
        x = 20,
        y = 20,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false
    }
end

function TutorialState:enter()
    -- Reset to first page
    self.currentPage = 1
    
    -- Play sound effect
    playSound('sfx', 'buttonClick')
end

function TutorialState:update(dt)
    -- Update timer
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function TutorialState:draw()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw current page
    local page = self.pages[self.currentPage]
    
    -- Draw page title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.title)
    local titleWidth = fonts.title:getWidth(page.title)
    love.graphics.print(page.title, love.graphics.getWidth() / 2 - titleWidth / 2, 50)
    
    -- Draw page image
    if page.image then
        love.graphics.setColor(1, 1, 1, 1)
        local imgWidth = page.image:getWidth()
        local imgHeight = page.image:getHeight()
        local scale = math.min(600 / imgWidth, 300 / imgHeight)
        
        love.graphics.draw(
            page.image, 
            love.graphics.getWidth() / 2 - (imgWidth * scale) / 2,
            love.graphics.getHeight() / 2 - (imgHeight * scale) / 2,
            0, scale, scale
        )
    end
    
    -- Draw page content
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.main)
    
    -- Word wrap the content for display
    local contentWidth = love.graphics.getWidth() - 200
    local contentY = 400
    local lineHeight = fonts.main:getHeight() * 1.5
    
    -- Simple word wrapping
    local words = {}
    for word in page.content:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local line = ""
    local lines = {}
    
    for _, word in ipairs(words) do
        local testLine = line .. " " .. word
        if line == "" then
            testLine = word
        end
        
        if fonts.main:getWidth(testLine) <= contentWidth then
            line = testLine
        else
            table.insert(lines, line)
            line = word
        end
    end
    
    if line ~= "" then
        table.insert(lines, line)
    end
    
    for i, wrappedLine in ipairs(lines) do
        local lineWidth = fonts.main:getWidth(wrappedLine)
        love.graphics.print(
            wrappedLine,
            love.graphics.getWidth() / 2 - lineWidth / 2,
            contentY + (i - 1) * lineHeight
        )
    end
    
    -- Draw page indicator
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    local pageText = self.currentPage .. " / " .. #self.pages
    local pageTextWidth = fonts.main:getWidth(pageText)
    love.graphics.print(pageText, love.graphics.getWidth() / 2 - pageTextWidth / 2, love.graphics.getHeight() - 100)
    
    -- Draw navigation buttons
    self:drawButton(self.prevButton, self.currentPage > 1)
    self:drawButton(self.nextButton, self.currentPage < #self.pages)
    self:drawButton(self.backButton, true)
    
    -- Draw error notifications
    Error.draw()
end

function TutorialState:drawButton(button, enabled)
    if not enabled then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.4)
    elseif button.hovered then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    end
    
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
    
    love.graphics.setColor(1, 1, 1, enabled and 0.5 or 0.2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
    
    love.graphics.setColor(1, 1, 1, enabled and 1 or 0.3)
    local textWidth = fonts.main:getWidth(button.text)
    local textHeight = fonts.main:getHeight()
    love.graphics.print(
        button.text, 
        button.x + button.width / 2 - textWidth / 2, 
        button.y + button.height / 2 - textHeight / 2
    )
end

function TutorialState:mousepressed(x, y, button)
    if button == 1 then
        -- Previous button
        if self.currentPage > 1 and self:isPointInButton(x, y, self.prevButton) then
            self.currentPage = self.currentPage - 1
            playSound('sfx', 'buttonClick')
        end
        
        -- Next button
        if self.currentPage < #self.pages and self:isPointInButton(x, y, self.nextButton) then
            self.currentPage = self.currentPage + 1
            playSound('sfx', 'buttonClick')
        end
        
        -- Back button
        if self:isPointInButton(x, y, self.backButton) then
            playSound('sfx', 'buttonClick')
            Gamestate.pop()
        end
    end
end

function TutorialState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    self.prevButton.hovered = self:isPointInButton(x, y, self.prevButton) and self.currentPage > 1
    self.nextButton.hovered = self:isPointInButton(x, y, self.nextButton) and self.currentPage < #self.pages
    self.backButton.hovered = self:isPointInButton(x, y, self.backButton)
end

function TutorialState:isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

function TutorialState:keypressed(key)
    if key == "escape" then
        playSound('sfx', 'buttonClick')
        Gamestate.pop()
    elseif key == "left" or key == "a" then
        if self.currentPage > 1 then
            self.currentPage = self.currentPage - 1
            playSound('sfx', 'buttonClick')
        end
    elseif key == "right" or key == "d" then
        if self.currentPage < #self.pages then
            self.currentPage = self.currentPage + 1
            playSound('sfx', 'buttonClick')
        end
    end
end

return TutorialState 