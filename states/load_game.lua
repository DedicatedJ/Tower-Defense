local LoadGameState = {}
LoadGameState.__index = LoadGameState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'
local Save = require 'systems.save'

function LoadGameState.new()
    local self = setmetatable({}, LoadGameState)
    
    self.title = "Load Game"
    self.saveSlots = {}
    self.buttons = {}
    self.backButton = nil
    self.selectedSlot = nil
    self.timer = Timer.new() -- Create timer instance for this state
    
    -- Create UI
    self:createUI()
    
    return self
end

function LoadGameState:init()
    -- Create UI elements
    self:createUI()
end

function LoadGameState:createUI()
    -- Title
    self.titleText = {
        text = self.title,
        x = love.graphics.getWidth() / 2 - 100,
        y = 50,
        font = fonts.title
    }
    
    -- Initialize save slots
    self:refreshSaveSlots()
    
    -- Create save slot buttons
    local buttonWidth = 500
    local buttonHeight = 80
    local spacing = 20
    local startY = 150
    
    for i, slot in ipairs(self.saveSlots) do
        local y = startY + (i - 1) * (buttonHeight + spacing)
        
        self.buttons[i] = {
            slot = slot,
            x = love.graphics.getWidth() / 2 - buttonWidth / 2,
            y = y,
            width = buttonWidth,
            height = buttonHeight,
            hovered = false
        }
    end
    
    -- Create back button
    self.backButton = {
        text = "Back",
        x = 20,
        y = love.graphics.getHeight() - 60,
        width = 100,
        height = 40,
        hovered = false
    }
end

function LoadGameState:refreshSaveSlots()
    -- Get save info from Save system
    if Save.getAllSaveInfo then
        self.saveSlots = Save:getAllSaveInfo()
    else
        -- Default data if Save system is not fully implemented
        self.saveSlots = {
            {
                id = 1,
                name = "Save Slot 1",
                empty = true,
                date = "",
                data = {}
            },
            {
                id = 2,
                name = "Save Slot 2",
                empty = true,
                date = "",
                data = {}
            },
            {
                id = 3,
                name = "Save Slot 3",
                empty = true,
                date = "",
                data = {}
            }
        }
    end
end

function LoadGameState:enter()
    -- Refresh save slots and UI
    self:refreshSaveSlots()
    self:createUI()
    
    -- Play sound effect
    playSound('sfx', 'buttonClick')
end

function LoadGameState:update(dt)
    -- Update timer
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function LoadGameState:draw()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.titleText.font)
    love.graphics.print(self.titleText.text, self.titleText.x, self.titleText.y)
    
    -- Draw save slots
    for _, button in ipairs(self.buttons) do
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
        
        -- Draw slot info
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fonts.main)
        
        if button.slot.empty then
            local text = "Empty Slot"
            local textWidth = fonts.main:getWidth(text)
            love.graphics.print(
                text,
                button.x + button.width / 2 - textWidth / 2,
                button.y + button.height / 2 - fonts.main:getHeight() / 2
            )
        else
            -- Slot name
            love.graphics.print(button.slot.name, button.x + 20, button.y + 15)
            
            -- Slot details (faction, progress, date)
            local details = ""
            if button.slot.data.selectedFaction then
                details = "Faction: " .. (button.slot.data.selectedFaction.name or "Unknown")
            end
            
            if button.slot.data.currentWave then
                details = details .. " | Wave: " .. button.slot.data.currentWave
            end
            
            love.graphics.print(details, button.x + 20, button.y + 40)
            
            -- Save date
            if button.slot.date then
                local dateText = "Saved: " .. button.slot.date
                local dateWidth = fonts.main:getWidth(dateText)
                love.graphics.print(dateText, button.x + button.width - dateWidth - 20, button.y + 15)
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
    
    -- If no save files exist, show message
    if #self.saveSlots == 0 then
        love.graphics.setColor(1, 1, 1, 1)
        local text = "No save files found"
        local textWidth = fonts.main:getWidth(text)
        love.graphics.print(
            text,
            love.graphics.getWidth() / 2 - textWidth / 2,
            love.graphics.getHeight() / 2 - fonts.main:getHeight() / 2
        )
    end
    
    -- Draw error notifications
    Error.draw()
end

function LoadGameState:mousepressed(x, y, button)
    if button == 1 then
        -- Check save slot buttons
        for _, btn in ipairs(self.buttons) do
            if self:isPointInButton(x, y, btn) then
                -- Only load if slot is not empty
                if not btn.slot.empty then
                    self.selectedSlot = btn.slot
                    self:loadGame(btn.slot)
                else
                    playSound('sfx', 'buttonClick')
                    Error.handle(Error.TYPES.GAME, "INVALID_SELECTION", "This save slot is empty")
                end
            end
        end
        
        -- Check back button
        if self:isPointInButton(x, y, self.backButton) then
            playSound('sfx', 'buttonClick')
            Gamestate.pop()
        end
    end
end

function LoadGameState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    for _, button in ipairs(self.buttons) do
        button.hovered = self:isPointInButton(x, y, button)
    end
    
    self.backButton.hovered = self:isPointInButton(x, y, self.backButton)
end

function LoadGameState:isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

function LoadGameState:loadGame(slot)
    local saveInfo = Save:getSaveInfo(slot)
    
    if not saveInfo then
        Error.handle(Error.TYPES.LOAD, "MISSING_FILE", "Save slot " .. slot .. " is empty")
        return
    end
    
    local success = Save:loadGame(slot)
    
    if success then
        -- Create and initialize game state with loaded data
        local gameState = require('states.game').new()
        -- Initialize with data from save
        if gameState.loadFromSave then
            gameState:loadFromSave(saveInfo)
        end
        Gamestate.switch(gameState)
    else
        Error.handle(Error.TYPES.LOAD, "LOAD_FAILED", "Failed to load game from slot " .. slot)
    end
end

function LoadGameState:keypressed(key)
    if key == "escape" then
        playSound('sfx', 'buttonClick')
        Gamestate.pop()
    end
end

return LoadGameState 