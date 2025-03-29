local LevelSelectState = {}
LevelSelectState.__index = LevelSelectState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function LevelSelectState.new()
    local self = setmetatable({}, LevelSelectState)
    
    -- UI properties
    self.buttons = {}
    self.background = nil
    self.selectedFaction = nil
    self.selectedHero = nil
    self.title = "Level Selection"
    self.levels = {}
    self.selectedLevel = nil
    
    -- Timer for animations
    self.timer = Timer.new()
    
    return self
end

function LevelSelectState:init(faction, hero)
    self.selectedFaction = faction
    self.selectedHero = hero
    
    -- Load background image
    local success, result = pcall(function()
        self.background = love.graphics.newImage("assets/backgrounds/level_select.jpg")
    end)
    
    if not success then
        -- Try loading a fallback background
        success, result = pcall(function()
            self.background = love.graphics.newImage("sprites/ui/backgrounds/faction_select.jpg")
        end)
        
        if not success then
            -- No need to throw an error, we'll use a fallback color background
            self.background = nil
            print("Using fallback color background for level select screen")
        end
    end
    
    -- Load available levels
    self:loadLevels()
    
    -- Create UI
    self:createUI()
    
    -- Play background music
    -- playSound('music', 'level_select')
end

function LevelSelectState:loadLevels()
    -- Load levels based on faction
    local Map = require('systems.map')
    
    -- First verify we have faction data
    if not self.selectedFaction then
        -- Create a default faction if none exists
        self.selectedFaction = {
            id = "default",
            name = "Default Faction",
            description = "Default faction for players"
        }
        Error.handle(Error.TYPES.GAME, "DEFAULT_FACTION", "Using default faction")
    end
    
    -- Check if faction has an id
    if not self.selectedFaction.id then
        -- Create a default id based on the name if available
        if self.selectedFaction.name then
            self.selectedFaction.id = string.lower(self.selectedFaction.name)
        else
            self.selectedFaction.id = "default"
        end
        print("Faction ID created: " .. self.selectedFaction.id)
    end
    
    -- Get map presets from the Map module
    local mapPresets = {}
    local factionId = string.lower(self.selectedFaction.id)
    
    -- Match faction ID (allow for more flexible matching)
    if factionId == "radiant" or factionId:find("radiant") or factionId:find("light") then
        mapPresets = {
            {
                id = "sunlit_meadows",
                name = "Sunlit Meadows",
                description = "Open fields with multiple paths",
                difficulty = 1,
                unlocked = true,
                image = "assets/levels/sunlit_meadows_thumb.jpg"
            },
            {
                id = "crystal_spires",
                name = "Crystal Spires",
                description = "Elevated platforms with bridges",
                difficulty = 2,
                unlocked = true,
                image = "assets/levels/crystal_spires_thumb.jpg"
            },
            {
                id = "celestial_citadel",
                name = "Celestial Citadel",
                description = "Circular, central defensive point",
                difficulty = 3,
                unlocked = false,
                image = "assets/levels/celestial_citadel_thumb.jpg"
            }
        }
    elseif factionId == "shadow" or factionId:find("shadow") or factionId:find("dark") then
        mapPresets = {
            {
                id = "haunted_forest",
                name = "Haunted Forest",
                description = "Winding paths with dense trees",
                difficulty = 1,
                unlocked = true,
                image = "assets/levels/haunted_forest_thumb.jpg"
            },
            {
                id = "obsidian_caves",
                name = "Obsidian Caves",
                description = "Narrow tunnels with limited tower spots",
                difficulty = 2,
                unlocked = true,
                image = "assets/levels/obsidian_caves_thumb.jpg"
            },
            {
                id = "necropolis",
                name = "Necropolis",
                description = "Maze-like with teleportation portals",
                difficulty = 3,
                unlocked = false,
                image = "assets/levels/necropolis_thumb.jpg"
            }
        }
    elseif factionId == "twilight" or factionId:find("twilight") or factionId:find("balance") then
        mapPresets = {
            {
                id = "misty_borderlands",
                name = "Misty Borderlands",
                description = "Shifting fog reveals/hides paths",
                difficulty = 1,
                unlocked = true,
                image = "assets/levels/misty_borderlands_thumb.jpg"
            },
            {
                id = "ethereal_ruins",
                name = "Ethereal Ruins",
                description = "Destructible environments change pathing",
                difficulty = 2,
                unlocked = true,
                image = "assets/levels/ethereal_ruins_thumb.jpg"
            },
            {
                id = "nexus_of_balance",
                name = "Nexus of Balance",
                description = "Dynamic, alternates light/dark zones",
                difficulty = 3,
                unlocked = false,
                image = "assets/levels/nexus_of_balance_thumb.jpg"
            }
        }
    else
        -- Default maps for any other faction or fallback
        mapPresets = {
            {
                id = "training_grounds",
                name = "Training Grounds",
                description = "Basic level for learning the game",
                difficulty = 1,
                unlocked = true,
                image = "assets/levels/training_grounds_thumb.jpg"
            },
            {
                id = "wilderness",
                name = "Wilderness",
                description = "Standard map with varied terrain",
                difficulty = 2,
                unlocked = true,
                image = "assets/levels/wilderness_thumb.jpg"
            },
            {
                id = "ancient_ruins",
                name = "Ancient Ruins",
                description = "Advanced map with complex paths",
                difficulty = 3,
                unlocked = false,
                image = "assets/levels/ancient_ruins_thumb.jpg"
            }
        }
    end
    
    -- Create fallback thumbnails directory if it doesn't exist
    if not love.filesystem.getInfo("assets/levels") then
        love.filesystem.createDirectory("assets/levels")
    end
    
    -- Load level thumbnails
    for _, level in ipairs(mapPresets) do
        -- Check if image path exists
        if level.image and love.filesystem.getInfo(level.image) then
            local success, result = Error.pcall(function()
                level.thumbnail = love.graphics.newImage(level.image)
            end)
            
            if not success then
                level.thumbnail = nil
            end
        else
            -- Try alternative paths
            local alternativePaths = {
                "sprites/levels/" .. level.id .. ".jpg",
                "sprites/levels/" .. level.id .. ".png",
                "sprites/ui/level_placeholder.png"
            }
            
            for _, path in ipairs(alternativePaths) do
                if love.filesystem.getInfo(path) then
                    local success, result = Error.pcall(function()
                        level.thumbnail = love.graphics.newImage(path)
                    end)
                    
                    if success then
                        break
                    end
                end
            end
        end
        
        table.insert(self.levels, level)
    end
    
    if #self.levels == 0 then
        Error.handle(Error.TYPES.GAME, "NO_LEVELS", "No levels found for faction: " .. tostring(self.selectedFaction.id))
    end
end

function LevelSelectState:createUI()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Back button
    table.insert(self.buttons, {
        text = "Back",
        x = 20,
        y = screenHeight - 80,
        width = 120,
        height = 40,
        hovered = false,
        action = function() self:goBack() end
    })
    
    -- Start button (will be enabled when a level is selected)
    table.insert(self.buttons, {
        text = "Start Level",
        x = screenWidth - 180,
        y = screenHeight - 80,
        width = 160,
        height = 40,
        hovered = false,
        enabled = false,
        action = function()
            if self.selectedLevel and self.selectedLevel.unlocked then
                self:startLevel()
            end
        end
    })
    
    -- Level cards
    self.levelCards = {}
    local cardWidth = 220
    local cardHeight = 300
    local spacing = 40
    local totalWidth = (#self.levels * cardWidth) + ((#self.levels - 1) * spacing)
    local startX = (screenWidth - totalWidth) / 2
    
    for i, level in ipairs(self.levels) do
        table.insert(self.levelCards, {
            level = level,
            x = startX + (i-1) * (cardWidth + spacing),
            y = screenHeight / 2 - cardHeight / 2,
            width = cardWidth,
            height = cardHeight,
            hovered = false
        })
    end
end

function LevelSelectState:goBack()
    local hubState = require('states.hub').new()
    hubState:init(self.selectedFaction, self.selectedHero)
    Gamestate.switch(hubState)
end

function LevelSelectState:startLevel()
    if not self.selectedLevel then return end
    
    -- Create and switch to game state with the selected level
    local gameState = require('states.game').new()
    gameState:init(self.selectedFaction, self.selectedHero, self.selectedLevel.id)
    Gamestate.switch(gameState)
end

function LevelSelectState:selectLevel(level)
    self.selectedLevel = level
    
    -- Enable start button if level is unlocked
    for _, button in ipairs(self.buttons) do
        if button.text == "Start Level" then
            button.enabled = level.unlocked
        end
    end
end

function LevelSelectState:enter()
    -- Animation or transition effect when entering this state
    self.timer:clear()
    
    -- Fade in effect
    self.fadeAlpha = 1
    self.timer:tween(0.5, self, {fadeAlpha = 0}, 'out-quad')
    
    -- Animate level cards
    for i, card in ipairs(self.levelCards) do
        card.yOffset = -100
        self.timer:tween(0.4 + i * 0.1, card, {yOffset = 0}, 'out-back')
    end
end

function LevelSelectState:update(dt)
    -- Update timer for animations
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function LevelSelectState:draw()
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
    
    -- Draw faction name
    if self.selectedFaction then
        love.graphics.setFont(fonts.subTitle)
        local factionText = self.selectedFaction.name .. " Territories"
        local factionWidth = fonts.subTitle:getWidth(factionText)
        love.graphics.print(factionText, love.graphics.getWidth() / 2 - factionWidth / 2, 120)
    end
    
    -- Draw level cards
    for _, card in ipairs(self.levelCards) do
        self:drawLevelCard(card)
    end
    
    -- Draw buttons
    for _, button in ipairs(self.buttons) do
        -- Button background
        if button.enabled == false then
            love.graphics.setColor(0.2, 0.2, 0.2, 0.5)  -- Disabled button
        elseif button.hovered then
            love.graphics.setColor(0.4, 0.4, 0.6, 0.9)  -- Hovered button
        else
            love.graphics.setColor(0.2, 0.2, 0.4, 0.8)  -- Normal button
        end
        
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Button border
        if button.enabled == false then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        else
            love.graphics.setColor(0.6, 0.6, 0.8, 0.8)
        end
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Button text
        if button.enabled == false then
            love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
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

function LevelSelectState:drawLevelCard(card)
    local yOffset = card.yOffset or 0
    local x, y = card.x, card.y + yOffset
    local level = card.level
    
    -- Card background
    if level == self.selectedLevel then
        love.graphics.setColor(0.3, 0.3, 0.5, 0.9)  -- Selected card
    elseif card.hovered then
        love.graphics.setColor(0.25, 0.25, 0.4, 0.8)  -- Hovered card
    else
        love.graphics.setColor(0.15, 0.15, 0.3, 0.8)  -- Normal card
    end
    
    love.graphics.rectangle("fill", x, y, card.width, card.height, 10, 10)
    
    -- Card border
    if level == self.selectedLevel then
        love.graphics.setColor(0.8, 0.8, 1, 0.9)
    else
        love.graphics.setColor(0.4, 0.4, 0.6, 0.6)
    end
    love.graphics.rectangle("line", x, y, card.width, card.height, 10, 10)
    
    -- Level thumbnail
    if level.thumbnail then
        love.graphics.setColor(1, 1, 1, 1)
        local scale = card.width / level.thumbnail:getWidth()
        local thumbHeight = level.thumbnail:getHeight() * scale
        love.graphics.draw(level.thumbnail, x, y, 0, scale, scale)
    else
        -- Placeholder for missing thumbnail
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
        love.graphics.rectangle("fill", x, y, card.width, card.width * 0.6)
    end
    
    -- Level name
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.subTitle)
    local nameY = y + card.width * 0.6 + 10
    love.graphics.printf(level.name, x + 10, nameY, card.width - 20, "center")
    
    -- Level description
    love.graphics.setFont(fonts.small)
    local descY = nameY + fonts.subTitle:getHeight() + 5
    love.graphics.printf(level.description, x + 10, descY, card.width - 20, "center")
    
    -- Difficulty stars
    local starSize = 15
    local totalStarWidth = level.difficulty * starSize + (level.difficulty - 1) * 5
    local starX = x + card.width / 2 - totalStarWidth / 2
    local starY = y + card.height - 30
    
    love.graphics.setColor(1, 0.8, 0, 1)
    for i = 1, level.difficulty do
        love.graphics.rectangle("fill", starX + (i-1) * (starSize + 5), starY, starSize, starSize)
    end
    
    -- Locked indicator
    if not level.unlocked then
        -- Semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", x, y, card.width, card.height, 10, 10)
        
        -- Lock icon
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setFont(fonts.title)
        love.graphics.printf("🔒", x, y + card.height / 2 - fonts.title:getHeight() / 2, card.width, "center")
        
        -- Locked text
        love.graphics.setFont(fonts.main)
        love.graphics.printf("Complete previous level to unlock", x + 20, y + card.height / 2 + 40, card.width - 40, "center")
    end
end

function LevelSelectState:mousepressed(x, y, button)
    if button == 1 then
        -- Check level cards
        for _, card in ipairs(self.levelCards) do
            if self:isPointInRect(x, y, card.x, card.y + (card.yOffset or 0), card.width, card.height) then
                self:selectLevel(card.level)
                return
            end
        end
        
        -- Check UI buttons
        for _, btn in ipairs(self.buttons) do
            if self:isPointInRect(x, y, btn.x, btn.y, btn.width, btn.height) then
                if btn.action and (btn.enabled ~= false) then
                    btn.action()
                end
                return
            end
        end
    end
end

function LevelSelectState:mousemoved(x, y, dx, dy)
    -- Update level card hover states
    for _, card in ipairs(self.levelCards) do
        card.hovered = self:isPointInRect(x, y, card.x, card.y + (card.yOffset or 0), card.width, card.height)
    end
    
    -- Update button hover states
    for _, btn in ipairs(self.buttons) do
        btn.hovered = self:isPointInRect(x, y, btn.x, btn.y, btn.width, btn.height)
    end
end

function LevelSelectState:isPointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

function LevelSelectState:keypressed(key)
    if key == "escape" then
        self:goBack()
    elseif key == "left" then
        -- Navigate left in level selection
        if self.selectedLevel then
            local currentIndex = nil
            for i, level in ipairs(self.levels) do
                if level == self.selectedLevel then
                    currentIndex = i
                    break
                end
            end
            
            if currentIndex and currentIndex > 1 then
                self:selectLevel(self.levels[currentIndex - 1])
            end
        elseif #self.levels > 0 then
            self:selectLevel(self.levels[1])
        end
    elseif key == "right" then
        -- Navigate right in level selection
        if self.selectedLevel then
            local currentIndex = nil
            for i, level in ipairs(self.levels) do
                if level == self.selectedLevel then
                    currentIndex = i
                    break
                end
            end
            
            if currentIndex and currentIndex < #self.levels then
                self:selectLevel(self.levels[currentIndex + 1])
            end
        elseif #self.levels > 0 then
            self:selectLevel(self.levels[1])
        end
    elseif key == "return" or key == "space" then
        -- Start selected level if unlocked
        if self.selectedLevel and self.selectedLevel.unlocked then
            self:startLevel()
        end
    end
end

return LevelSelectState 