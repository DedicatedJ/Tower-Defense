-- Profiles screen ("Load Game"). One row per save slot. A profile holds
-- the faction and hero, hero levels, shop gold and items, and level stars
-- (systems/save.lua); there is no mid-level save.
--   Play    make the slot current and go to the hub (or pick a faction)
--   New     start a fresh profile in an empty slot
--   Delete  remove a profile; asks once more before it does

local LoadGameState = {}
LoadGameState.__index = LoadGameState

local Gamestate = require 'libs.hump.gamestate'
local Error = require 'utils.error'
local Save = require 'systems.save'

local ROW_W, ROW_H, ROW_GAP, TOP = 640, 84, 14, 140

function LoadGameState.new()
    local self = setmetatable({}, LoadGameState)
    self.title = "Profiles"
    self.message = nil       -- shown under the title (e.g. "all slots are full")
    self.confirmDelete = nil -- slot waiting for a second Delete click
    self:refresh()
    return self
end

function LoadGameState:init() end

function LoadGameState:enter()
    self:refresh()
end

-- Rebuild rows and their buttons from what is on disk
function LoadGameState:refresh()
    local sw = love.graphics.getWidth()
    self.rows = {}
    for slot = 1, Save.SLOT_COUNT do
        local x = sw / 2 - ROW_W / 2
        local y = TOP + (slot - 1) * (ROW_H + ROW_GAP)
        local row = { slot = slot, summary = Save.slotSummary(slot), x = x, y = y, width = ROW_W, height = ROW_H }
        local bx = x + ROW_W - 12
        row.buttons = {}
        local function add(label, action, w)
            w = w or 96
            bx = bx - w
            table.insert(row.buttons, 1, { text = label, action = action, x = bx, y = y + ROW_H / 2 - 18, width = w, height = 36 })
            bx = bx - 8
        end
        if row.summary then
            add(self.confirmDelete == slot and "Sure?" or "Delete", "delete", 80)
            add("Play", "play")
        else
            add("New Game", "new", 120)
        end
        self.rows[slot] = row
    end
    self.backButton = { text = "Back", x = 20, y = love.graphics.getHeight() - 60, width = 110, height = 40 }
end

local function lastPlayed(ts)
    if not ts then return "" end
    return "Last played " .. os.date("%Y-%m-%d %H:%M", ts)
end

function LoadGameState:update(dt)
    Error.update(dt)
end

function LoadGameState:drawButton(b, danger)
    local mx, my = love.mouse.getPosition()
    local hover = self:isPointInButton(mx, my, b)
    if danger then
        love.graphics.setColor(hover and { 0.65, 0.2, 0.2, 0.95 } or { 0.45, 0.15, 0.15, 0.9 })
    else
        love.graphics.setColor(hover and { 0.35, 0.45, 0.7, 0.95 } or { 0.2, 0.25, 0.45, 0.9 })
    end
    love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 6, 6)
    love.graphics.setColor(0.75, 0.8, 1, 0.8)
    love.graphics.rectangle("line", b.x, b.y, b.width, b.height, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    local f = love.graphics.getFont()
    love.graphics.printf(b.text, b.x, b.y + b.height / 2 - f:getHeight() / 2, b.width, "center")
end

function LoadGameState:draw()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0.08, 0.08, 0.14, 1)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.title)
    love.graphics.printf(self.title, 0, 45, sw, "center")
    love.graphics.setFont(fonts.main)
    if self.message then
        love.graphics.setColor(1, 0.85, 0.4, 1)
        love.graphics.printf(self.message, 0, 100, sw, "center")
    end

    for _, row in ipairs(self.rows) do
        local current = row.summary and row.slot == Save.currentSlotNumber()
        love.graphics.setColor(current and { 0.2, 0.22, 0.36, 0.95 } or { 0.14, 0.14, 0.22, 0.9 })
        love.graphics.rectangle("fill", row.x, row.y, row.width, row.height, 8, 8)
        love.graphics.setColor(current and { 0.9, 0.8, 0.4, 0.9 } or { 0.4, 0.4, 0.6, 0.7 })
        love.graphics.rectangle("line", row.x, row.y, row.width, row.height, 8, 8)

        local tx = row.x + 16
        love.graphics.setColor(0.7, 0.7, 0.8, 1)
        love.graphics.print("Slot " .. row.slot, tx, row.y + 10)
        local s = row.summary
        if s then
            love.graphics.setColor(1, 1, 1, 1)
            local who = s.faction and (s.faction .. (s.hero and (", " .. s.hero) or "")) or "No faction chosen yet"
            love.graphics.print(who, tx, row.y + 30)
            love.graphics.setColor(0.85, 0.8, 0.6, 1)
            love.graphics.print(string.format("%d %s won, %d stars, %d gold", s.wins, s.wins == 1 and "level" or "levels",
                s.stars, s.gold), tx, row.y + 50)
            love.graphics.setColor(0.6, 0.6, 0.7, 1)
            -- right-aligned, ending just left of the buttons
            local right = row.buttons[1].x - 16
            love.graphics.printf(lastPlayed(s.timestamp), row.x, row.y + 50, right - row.x, "right")
        else
            love.graphics.setColor(0.55, 0.55, 0.65, 1)
            love.graphics.print("Empty", tx, row.y + 34)
        end
        for _, b in ipairs(row.buttons) do self:drawButton(b, b.action == "delete") end
    end

    self:drawButton(self.backButton)
    Error.draw()
end

function LoadGameState:isPointInButton(x, y, b)
    return x >= b.x and x <= b.x + b.width and y >= b.y and y <= b.y + b.height
end

-- Go to the hub with this profile, or to faction select if it has none yet
function LoadGameState:play(slot)
    Save.useSlot(slot)
    local p = Save.getCurrentProfile()
    if p and p.selectedFaction and p.selectedHero then
        local hub = require('states.hub').new()
        hub:setup(p.selectedFaction, p.selectedHero)
        Gamestate.switch(hub)
    else
        Gamestate.switch(require('states.faction_select').new())
    end
end

function LoadGameState:createNewGame(slot)
    if not Save.newProfile(slot) then
        self.message = "Could not create a profile in slot " .. slot
        return
    end
    Gamestate.switch(require('states.faction_select').new())
end

function LoadGameState:press(row, b)
    playSound('sfx', 'buttonClick')
    if b.action == "play" then
        self:play(row.slot)
    elseif b.action == "new" then
        self:createNewGame(row.slot)
    elseif b.action == "delete" then
        if self.confirmDelete == row.slot then
            Save.deleteProfile(row.slot)
            self.confirmDelete = nil
            self.message = "Slot " .. row.slot .. " deleted"
        else
            self.confirmDelete = row.slot
            self.message = "Click Sure? to delete slot " .. row.slot .. " for good"
        end
        self:refresh()
    end
end

function LoadGameState:back()
    playSound('sfx', 'buttonClick')
    Gamestate.switch(require('states.menu').new())
end

function LoadGameState:mousepressed(x, y, button)
    if button ~= 1 then return end
    if self:isPointInButton(x, y, self.backButton) then return self:back() end
    for _, row in ipairs(self.rows) do
        for _, b in ipairs(row.buttons) do
            if self:isPointInButton(x, y, b) then return self:press(row, b) end
        end
    end
    -- A click anywhere else cancels a pending delete
    if self.confirmDelete then
        self.confirmDelete = nil
        self.message = nil
        self:refresh()
    end
end

function LoadGameState:keypressed(key)
    if key == "escape" then self:back() end
end

return LoadGameState
