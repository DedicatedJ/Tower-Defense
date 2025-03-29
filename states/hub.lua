local HubState = {}
HubState.__index = HubState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function HubState.new()
    local self = setmetatable({}, HubState)
    
    -- UI properties
    self.buttons = {}
    self.background = nil
    self.selectedFaction = nil
    self.selectedHero = nil
    self.title = "Game Hub"
    
    -- Timer for animations
    self.timer = Timer.new()
    
    return self
end

function HubState:init(faction, hero)
    self.selectedFaction = faction
    self.selectedHero = hero
    
    -- Load background image
    local success, result = pcall(function()
        self.background = love.graphics.newImage("assets/backgrounds/hub_background.jpg")
    end)
    
    if not success then
        -- Try loading a fallback background
        success, result = pcall(function()
            self.background = love.graphics.newImage("sprites/ui/backgrounds/faction_select.jpg")
        end)
        
        if not success then
            -- No need to throw an error, we'll use a fallback color background
            self.background = nil
            print("Using fallback color background for hub screen")
        end
    end
    
    -- Create UI
    self:createUI()
    
    -- Play background music
    -- playSound('music', 'hub')
end

function HubState:createUI()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Main menu buttons
    local buttonWidth = 200
    local buttonHeight = 60
    local buttonSpacing = 20
    local startY = screenHeight / 2 - 100
    
    -- Level selection button
    table.insert(self.buttons, {
        text = "Level Selection",
        x = screenWidth / 2 - buttonWidth / 2,
        y = startY,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false,
        action = function() self:goToLevelSelect() end
    })
    
    -- Tower upgrade button
    table.insert(self.buttons, {
        text = "Tower Upgrades",
        x = screenWidth / 2 - buttonWidth / 2,
        y = startY + buttonHeight + buttonSpacing,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false,
        action = function() self:goToTowerUpgrades() end
    })
    
    -- Shop button
    table.insert(self.buttons, {
        text = "Shop",
        x = screenWidth / 2 - buttonWidth / 2,
        y = startY + (buttonHeight + buttonSpacing) * 2,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false,
        action = function() self:goToShop() end
    })
    
    -- Back button
    table.insert(self.buttons, {
        text = "Back to Menu",
        x = screenWidth / 2 - buttonWidth / 2,
        y = startY + (buttonHeight + buttonSpacing) * 3,
        width = buttonWidth,
        height = buttonHeight,
        hovered = false,
        action = function() self:goBack() end
    })
    
    -- Hero info display
    self.heroInfoDisplay = {
        x = 20,
        y = 20,
        width = 300,
        height = 200
    }
    
    -- Faction info display
    self.factionInfoDisplay = {
        x = screenWidth - 320,
        y = 20,
        width = 300,
        height = 200
    }
end

function HubState:goToLevelSelect()
    local LevelSelectState = require('states.level_select')
    if LevelSelectState then
        local levelSelect = LevelSelectState.new()
        
        -- Ensure faction data is valid before passing it
        if not self.selectedFaction then
            -- Create a default faction if none exists
            self.selectedFaction = {
                id = "default",
                name = "Default Faction",
                description = "Default faction for players"
            }
            Error.handle(Error.TYPES.GAME, "DEFAULT_FACTION", "Using default faction")
        elseif not self.selectedFaction.id then
            -- Set ID based on name if available
            if self.selectedFaction.name then
                self.selectedFaction.id = string.lower(self.selectedFaction.name)
            else
                self.selectedFaction.id = "default"
            end
            Error.handle(Error.TYPES.GAME, "INCOMPLETE_FACTION", "Faction data incomplete, using name as ID")
        end
        
        -- Do the same check for hero data
        if not self.selectedHero then
            self.selectedHero = {
                id = "default_hero",
                name = "Default Hero",
                description = "A basic hero"
            }
        end
        
        -- Now pass the validated data
        levelSelect:init(self.selectedFaction, self.selectedHero)
        Gamestate.switch(levelSelect)
    else
        -- Fallback if level select state doesn't exist yet
        Error.handle(Error.TYPES.GAME, "MISSING_FEATURE", "Level Select")
    end
end

function HubState:goToTowerUpgrades()
    local TowerUpgradeState = require('states.tower_upgrade')
    if TowerUpgradeState then
        local towerUpgrade = TowerUpgradeState.new()
        towerUpgrade:init(self.selectedFaction, self.selectedHero)
        Gamestate.switch(towerUpgrade)
    else
        -- Fallback if tower upgrade state doesn't exist yet
        Error.handle(Error.TYPES.GAME, "MISSING_FEATURE", "Tower Upgrades")
    end
end

function HubState:goToShop()
    local ShopState = require('states.shop')
    if ShopState then
        local shop = ShopState.new()
        shop:init(self.selectedFaction, self.selectedHero)
        Gamestate.switch(shop)
    else
        -- Fallback if shop state doesn't exist yet
        Error.handle(Error.TYPES.GAME, "MISSING_FEATURE", "Shop")
    end
end

function HubState:goBack()
    local MenuState = require('states.menu')
    Gamestate.switch(MenuState.new())
end

function HubState:enter()
    -- Animation or transition effect when entering this state
    self.timer:clear()
    
    -- Fade in effect
    self.fadeAlpha = 1
    self.timer:tween(0.5, self, {fadeAlpha = 0}, 'out-quad')
end

function HubState:update(dt)
    -- Update timer for animations
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function HubState:draw()
    -- Check if fonts are defined, use fallbacks if not
    if not fonts.subTitle then
        fonts.subTitle = fonts.main or love.graphics.newFont(18)
    end
    if not fonts.small then
        fonts.small = fonts.main or love.graphics.newFont(12)
    end
    
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
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.title)
    local titleWidth = fonts.title:getWidth(self.title)
    love.graphics.print(self.title, love.graphics.getWidth() / 2 - titleWidth / 2, 50)
    
    -- Draw faction and hero info
    self:drawFactionInfo()
    self:drawHeroInfo()
    
    -- Draw buttons
    for _, button in ipairs(self.buttons) do
        -- Button background
        if button.hovered then
            love.graphics.setColor(0.4, 0.4, 0.6, 0.9)
        else
            love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
        end
        
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Button border
        love.graphics.setColor(0.6, 0.6, 0.8, 0.8)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Button text
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
    
    -- Draw fade overlay
    if self.fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- Draw error notifications
    Error.draw()
end

function HubState:drawFactionInfo()
    if not self.selectedFaction then return end
    
    local info = self.factionInfoDisplay
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", info.x, info.y, info.width, info.height, 10, 10)
    
    -- Border
    love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
    love.graphics.rectangle("line", info.x, info.y, info.width, info.height, 10, 10)
    
    -- Faction info
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.subTitle)
    love.graphics.print("Faction", info.x + 10, info.y + 10)
    
    love.graphics.setFont(fonts.main)
    love.graphics.print(self.selectedFaction.name, info.x + 10, info.y + 50)
    
    -- Description
    local description = self.selectedFaction.description or ""
    local wrappedText = self:wrapText(description, info.width - 20)
    love.graphics.print(wrappedText, info.x + 10, info.y + 80)
end

function HubState:drawHeroInfo()
    if not self.selectedHero then return end
    
    local info = self.heroInfoDisplay
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", info.x, info.y, info.width, info.height, 10, 10)
    
    -- Border
    love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
    love.graphics.rectangle("line", info.x, info.y, info.width, info.height, 10, 10)
    
    -- Hero info
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.subTitle)
    love.graphics.print("Hero", info.x + 10, info.y + 10)
    
    love.graphics.setFont(fonts.main)
    love.graphics.print(self.selectedHero.name, info.x + 10, info.y + 50)
    
    -- Description
    local description = self.selectedHero.description or ""
    local wrappedText = self:wrapText(description, info.width - 20)
    love.graphics.print(wrappedText, info.x + 10, info.y + 80)
end

function HubState:wrapText(text, width)
    if not text then return "" end
    
    local wrappedText = ""
    local spaceWidth = fonts.main:getWidth(" ")
    local line = ""
    local lineWidth = 0
    
    for word in text:gmatch("%S+") do
        local wordWidth = fonts.main:getWidth(word)
        
        if lineWidth + wordWidth + spaceWidth <= width or lineWidth == 0 then
            if lineWidth > 0 then
                line = line .. " "
                lineWidth = lineWidth + spaceWidth
            end
            line = line .. word
            lineWidth = lineWidth + wordWidth
        else
            wrappedText = wrappedText .. line .. "\n"
            line = word
            lineWidth = wordWidth
        end
    end
    
    wrappedText = wrappedText .. line
    return wrappedText
end

function HubState:mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(self.buttons) do
            if self:isPointInButton(x, y, btn) then
                if btn.action then btn.action() end
                return
            end
        end
    end
end

function HubState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    for _, btn in ipairs(self.buttons) do
        btn.hovered = self:isPointInButton(x, y, btn)
    end
end

function HubState:isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and 
           y >= button.y and y <= button.y + button.height
end

function HubState:keypressed(key)
    if key == "escape" then
        self:goBack()
    end
end

return HubState 