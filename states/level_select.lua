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

-- HUMP calls init() with no arguments the first time a state is switched to.
-- Callers that have real data call setup(...) before switching; init() only
-- fills in defaults when that didn't happen.
function LevelSelectState:init()
    if not self.isSetUp then
        self:setup()
    end
end

function LevelSelectState:setup(faction, hero)
    self.isSetUp = true
    -- Saved profiles pass ids, the selection screens pass tables
    local Selection = require("utils.selection")
    self.selectedFaction = Selection.resolveFaction(faction)
    self.selectedHero = Selection.resolveHero(self.selectedFaction, hero)
    
    -- Load background image
    local success, result = pcall(function()
        self.background = love.graphics.newImage("assets/backgrounds/level_select.png")
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
    -- The faction's levels from data/levels.lua. The first is always open;
    -- each later one opens when the one before it has been won.
    local Level = require('systems.level')
    local Save = require('systems.save')
    local list = Level.forFaction(self.selectedFaction.id)
    self.levels = {}
    local prevWon = true
    for _, data in ipairs(list) do
        local ok, result = pcall(Save.getLevelResult, data.id)
        local stars = ok and result and result.stars or 0
        local okThumb, thumb = pcall(Level.thumbnail, data)
        self.levels[#self.levels + 1] = {
            id = data.id,
            name = data.name,
            description = data.description,
            difficulty = data.difficulty,
            waves = data.waves.count,
            unlocked = prevWon,
            stars = stars,
            thumbnail = okThumb and thumb or nil,
        }
        prevWon = stars > 0
    end
    if #self.levels == 0 then
        Error.handle(Error.TYPES.GAME, "NO_LEVELS", "No levels found for faction: " .. tostring(self.selectedFaction.id))
    end
    -- Start on the furthest open level
    for i = #self.levels, 1, -1 do
        if self.levels[i].unlocked then self.selectedLevel = self.levels[i]; break end
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
        enabled = self.selectedLevel ~= nil and self.selectedLevel.unlocked,
        action = function()
            if self.selectedLevel and self.selectedLevel.unlocked then
                self:startLevel()
            end
        end
    })
    
    -- Level cards
    self.levelCards = {}
    local cardWidth = 280 -- room for a 16:9 map thumbnail
    local cardHeight = 340
    local spacing = 40
    local totalWidth = (#self.levels * cardWidth) + ((#self.levels - 1) * spacing)
    local startX = (screenWidth - totalWidth) / 2
    
    for i, level in ipairs(self.levels) do
        table.insert(self.levelCards, {
            level = level,
            index = i,
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
    hubState:setup(self.selectedFaction, self.selectedHero)
    Gamestate.switch(hubState)
end

function LevelSelectState:startLevel()
    if not self.selectedLevel then return end
    
    -- Create and switch to game state with the selected level
    local gameState = require('states.game').new()
    gameState:setup(self.selectedFaction, self.selectedHero, self.selectedLevel.id)
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
    require('systems.audio').playMusic("menu")
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
        require('utils.image').drawCover(self.background)
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
        -- Fit inside the picture box above the name
        local boxW, boxH = card.width - 16, card.width * 0.6 - 8
        local scale = math.min(boxW / level.thumbnail:getWidth(), boxH / level.thumbnail:getHeight())
        local tw, th = level.thumbnail:getWidth() * scale, level.thumbnail:getHeight() * scale
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(level.thumbnail, x + (card.width - tw) / 2, y + 8 + (boxH - th) / 2, 0, scale, scale)
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
    
    -- Difficulty and length
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.8, 0.8, 0.9, 1)
    local diffNames = { "Easy", "Medium", "Hard" }
    love.graphics.printf((diffNames[level.difficulty] or "") .. "  |  " .. (level.waves or "?") .. " waves",
        x, y + card.height - 58, card.width, "center")

    -- Stars earned (best result)
    local starY = y + card.height - 26
    for i = 1, 3 do
        local cx = x + card.width / 2 + (i - 2) * 28
        local pts = {}
        for k = 0, 9 do
            local r = (k % 2 == 0) and 11 or 5
            local a = -math.pi / 2 + k * math.pi / 5
            pts[#pts + 1] = cx + math.cos(a) * r
            pts[#pts + 1] = starY + math.sin(a) * r
        end
        if i <= (level.stars or 0) then
            love.graphics.setColor(1, 0.82, 0.2, 1)
        else
            love.graphics.setColor(0.35, 0.35, 0.4, 0.9)
        end
        for _, tri in ipairs(love.math.triangulate(pts)) do love.graphics.polygon("fill", tri) end
    end

    -- Locked indicator: the map stays visible, the text is covered
    if not level.unlocked then
        local picH = card.width * 0.6
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", x, y, card.width, picH, 10, 10)
        love.graphics.setColor(0.07, 0.07, 0.14, 1)
        love.graphics.rectangle("fill", x, y + picH, card.width, card.height - picH, 10, 10)

        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setFont(fonts.subTitle)
        love.graphics.printf("Locked", x, y + picH + 18, card.width, "center")
        love.graphics.setColor(0.75, 0.75, 0.85, 0.9)
        love.graphics.setFont(fonts.small)
        love.graphics.printf("Win " .. (self.levels[(card.index or 2) - 1] and self.levels[(card.index or 2) - 1].name or "the previous level")
            .. " to unlock", x + 16, y + picH + 18 + fonts.subTitle:getHeight() + 10, card.width - 32, "center")
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