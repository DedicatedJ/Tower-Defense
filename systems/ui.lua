local UI_ASSETS = require 'systems.ui_assets'

local UI = {}
UI.__index = UI

-- UI element definitions
local UI_ELEMENTS = {
    {
        id = "tower_menu",
        type = "panel",
        x = 700,
        y = 100,
        width = 200,
        height = 400,
        visible = true,
        children = {
            {
                id = "tower_list",
                type = "list",
                x = 10,
                y = 10,
                width = 180,
                height = 300,
                items = {
                    {id = "arrow_tower", name = "Arrow Tower", cost = 100, icon = "sprites/towers/ranged/arrow.png"},
                    {id = "cannon_tower", name = "Cannon Tower", cost = 200, icon = "sprites/towers/ranged/cannon.png"},
                    {id = "magic_tower", name = "Magic Tower", cost = 150, icon = "sprites/towers/magic/magic.png"}
                }
            },
            {
                id = "start_wave",
                type = "button",
                x = 10,
                y = 320,
                width = 180,
                height = 40,
                text = "Start Wave",
                shortcut = "SPACE"
            }
        }
    },
    {
        id = "tower_info",
        type = "panel",
        x = 700,
        y = 100,
        width = 200,
        height = 200,
        visible = false,
        children = {
            {
                id = "tower_name",
                type = "text",
                x = 10,
                y = 10,
                text = ""
            },
            {
                id = "tower_stats",
                type = "text",
                x = 10,
                y = 40,
                text = ""
            },
            {
                id = "upgrade_buttons",
                type = "container",
                x = 10,
                y = 100,
                width = 180,
                height = 80,
                children = {}
            }
        }
    },
    {
        id = "hero_abilities",
        type = "panel",
        x = 10,
        y = 10,
        width = 200,
        height = 100,
        visible = true,
        children = {
            {
                id = "ability_1",
                type = "button",
                x = 10,
                y = 10,
                width = 40,
                height = 40,
                shortcut = "Q"
            },
            {
                id = "ability_2",
                type = "button",
                x = 60,
                y = 10,
                width = 40,
                height = 40,
                shortcut = "W"
            },
            {
                id = "ability_3",
                type = "button",
                x = 110,
                y = 10,
                width = 40,
                height = 40,
                shortcut = "E"
            }
        }
    },
    {
        id = "resource_display",
        type = "panel",
        x = 10,
        y = 120,
        width = 200,
        height = 40,
        visible = true,
        children = {
            {
                id = "resources",
                type = "text",
                x = 10,
                y = 10,
                text = "Resources: 100"
            },
            {
                id = "lives",
                type = "text",
                x = 100,
                y = 10,
                text = "Lives: 3"
            }
        }
    }
}

-- Keyboard shortcuts
local SHORTCUTS = {
    ["SPACE"] = function(ui)
        if ui:getElement("start_wave"):isEnabled() then
            ui:startWave()
        end
    end,
    ["Q"] = function(ui)
        ui:useAbility(1)
    end,
    ["W"] = function(ui)
        ui:useAbility(2)
    end,
    ["E"] = function(ui)
        ui:useAbility(3)
    end,
    ["ESC"] = function(ui)
        ui:showPauseMenu()
    end
}

-- Mouse state
local MOUSE_STATE = {
    x = 0,
    y = 0,
    isDown = false,
    button = nil,
    dragStart = {x = 0, y = 0},
    isDragging = false,
    dragThreshold = 5, -- pixels to move before considering it a drag
    lastClickTime = 0,
    doubleClickTime = 0.3 -- seconds
}

function UI.new()
    local self = setmetatable({}, UI)
    
    self.elements = {}
    self.tooltips = {}
    self.contextMenus = {}
    self.selectedTower = nil
    self.hoveredElement = nil
    self.notifications = {}
    self.notificationDuration = 3
    self.notificationTimer = 0
    self.draggedElement = nil
    self.mouseState = table.copy(MOUSE_STATE)
    
    -- Initialize UI elements
    self:initializeElements()
    
    return self
end

function UI:initializeElements()
    for _, element in ipairs(UI_ELEMENTS) do
        self.elements[element.id] = self:createElement(element)
    end
end

function UI:createElement(data)
    local element = {
        id = data.id,
        type = data.type,
        x = data.x,
        y = data.y,
        width = data.width,
        height = data.height,
        visible = data.visible,
        children = {},
        enabled = true,
        tooltip = data.tooltip,
        shortcut = data.shortcut,
        draggable = data.draggable,
        dragOffset = {x = 0, y = 0},
        isDragging = false
    }
    
    -- Create children
    if data.children then
        for _, childData in ipairs(data.children) do
            table.insert(element.children, self:createElement(childData))
        end
    end
    
    return element
end

function UI:update(dt)
    -- Update mouse position
    self.mouseState.x, self.mouseState.y = love.mouse.getPosition()
    
    -- Update notifications
    for i = #self.notifications, 1, -1 do
        local notification = self.notifications[i]
        notification.timer = notification.timer + dt
        if notification.timer >= self.notificationDuration then
            table.remove(self.notifications, i)
        end
    end
    
    -- Update tooltips
    self.hoveredElement = self:getElementAt(self.mouseState.x, self.mouseState.y)
    
    if self.hoveredElement and self.hoveredElement.tooltip then
        self:showTooltip(self.hoveredElement.tooltip, self.mouseState.x, self.mouseState.y)
    else
        self:hideTooltip()
    end
    
    -- Update dragging
    if self.mouseState.isDown and not self.mouseState.isDragging then
        local dx = self.mouseState.x - self.mouseState.dragStart.x
        local dy = self.mouseState.y - self.mouseState.dragStart.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > self.mouseState.dragThreshold then
            self.mouseState.isDragging = true
            self:startDragging()
        end
    end
end

function UI:draw()
    -- Draw UI elements
    for _, element in pairs(self.elements) do
        if element.visible then
            self:drawElement(element)
        end
    end
    
    -- Draw tooltips
    for _, tooltip in ipairs(self.tooltips) do
        self:drawTooltip(tooltip)
    end
    
    -- Draw context menus
    for _, menu in ipairs(self.contextMenus) do
        self:drawContextMenu(menu)
    end
    
    -- Draw notifications
    for i, notification in ipairs(self.notifications) do
        self:drawNotification(notification, i)
    end
end

function UI:drawElement(element)
    -- Draw element background
    if element.isDragging then
        love.graphics.setColor(0, 0, 0, 0.6)
    else
        love.graphics.setColor(0, 0, 0, 0.8)
    end
    love.graphics.rectangle("fill", element.x, element.y, element.width, element.height)
    
    -- Draw element border
    if element == self.hoveredElement or element.isDragging then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 0.5)
    end
    love.graphics.rectangle("line", element.x, element.y, element.width, element.height)
    
    -- Draw element content based on type
    if element.type == "button" then
        self:drawButton(element)
    elseif element.type == "text" then
        self:drawText(element)
    elseif element.type == "list" then
        self:drawList(element)
    end
    
    -- Draw children
    for _, child in ipairs(element.children) do
        self:drawElement(child)
    end
end

function UI:drawButton(element)
    -- Draw button background
    if element == self.hoveredElement then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    end
    love.graphics.rectangle("fill", element.x, element.y, element.width, element.height)
    
    -- Draw button text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.main)
    local textWidth = fonts.main:getWidth(element.text)
    love.graphics.print(element.text,
        element.x + (element.width - textWidth) / 2,
        element.y + (element.height - fonts.main:getHeight()) / 2)
    
    -- Draw shortcut if available
    if element.shortcut then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(element.shortcut,
            element.x + element.width - 40,
            element.y + (element.height - fonts.main:getHeight()) / 2)
    end
end

function UI:drawText(element)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.main)
    love.graphics.print(element.text, element.x, element.y)
end

function UI:drawList(element)
    -- Draw list items
    for i, item in ipairs(element.items) do
        local y = element.y + (i - 1) * 30
        
        -- Draw item background
        if item == self.hoveredElement then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        love.graphics.rectangle("fill", element.x, y, element.width, 30)
        
        -- Draw item icon
        if item.icon then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(item.icon, element.x + 5, y + 5, 0, 0.5, 0.5)
        end
        
        -- Draw item text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(item.name, element.x + 30, y + 5)
        love.graphics.print("Cost: " .. item.cost, element.x + 30, y + 20)
    end
end

function UI:drawTooltip(tooltip)
    -- Draw tooltip background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", tooltip.x, tooltip.y, tooltip.width, tooltip.height)
    
    -- Draw tooltip text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.main)
    love.graphics.print(tooltip.text, tooltip.x + 5, tooltip.y + 5)
end

function UI:drawContextMenu(menu)
    -- Draw menu background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", menu.x, menu.y, menu.width, menu.height)
    
    -- Draw menu items
    for i, item in ipairs(menu.items) do
        local y = menu.y + (i - 1) * 30
        
        -- Draw item background
        if item == self.hoveredElement then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        love.graphics.rectangle("fill", menu.x, y, menu.width, 30)
        
        -- Draw item text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(item.text, menu.x + 5, y + 5)
    end
end

function UI:drawNotification(notification, index)
    local alpha = 1 - (notification.timer / self.notificationDuration)
    local x = 20
    local y = 20 + (index - 1) * 30
    
    -- Draw notification background
    love.graphics.setColor(0, 0, 0, 0.8 * alpha)
    love.graphics.rectangle("fill", x, y, 300, 25)
    
    -- Draw notification text
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(notification.text, x + 5, y + 5)
end

function UI:showTooltip(text, x, y)
    -- Remove existing tooltips
    self:hideTooltip()
    
    -- Create new tooltip
    local tooltip = {
        text = text,
        x = x + 20,
        y = y + 20,
        width = fonts.main:getWidth(text) + 10,
        height = fonts.main:getHeight() + 10
    }
    
    -- Adjust position if tooltip would go off screen
    if tooltip.x + tooltip.width > love.graphics.getWidth() then
        tooltip.x = x - tooltip.width - 20
    end
    if tooltip.y + tooltip.height > love.graphics.getHeight() then
        tooltip.y = y - tooltip.height - 20
    end
    
    table.insert(self.tooltips, tooltip)
end

function UI:hideTooltip()
    self.tooltips = {}
end

function UI:showContextMenu(x, y, items)
    -- Remove existing context menus
    self:closeContextMenus()
    
    -- Create new context menu
    local menu = {
        x = x,
        y = y,
        width = 150,
        height = #items * 30,
        items = items
    }
    
    -- Adjust position if menu would go off screen
    if menu.x + menu.width > love.graphics.getWidth() then
        menu.x = x - menu.width
    end
    if menu.y + menu.height > love.graphics.getHeight() then
        menu.y = y - menu.height
    end
    
    table.insert(self.contextMenus, menu)
end

function UI:closeContextMenus()
    self.contextMenus = {}
end

function UI:showNotification(text)
    table.insert(self.notifications, {
        text = text,
        timer = 0
    })
end

function UI:getElementAt(x, y)
    -- Check UI elements
    for _, element in pairs(self.elements) do
        if element.visible and self:isPointInElement(x, y, element) then
            -- Check children
            for _, child in ipairs(element.children) do
                if self:isPointInElement(x, y, child) then
                    return child
                end
            end
            return element
        end
    end
    
    -- Check context menus
    for _, menu in ipairs(self.contextMenus) do
        if self:isPointInElement(x, y, menu) then
            for _, item in ipairs(menu.items) do
                if self:isPointInElement(x, y, item) then
                    return item
                end
            end
            return menu
        end
    end
    
    return nil
end

function UI:isPointInElement(x, y, element)
    return x >= element.x and x <= element.x + element.width and
           y >= element.y and y <= element.y + element.height
end

function UI:getElement(id)
    return self.elements[id]
end

function UI:mousepressed(x, y, button, istouch, presses)
    self.mouseState.isDown = true
    self.mouseState.button = button
    self.mouseState.dragStart = {x = x, y = y}
    self.mouseState.isDragging = false
    
    -- Handle double click
    if presses == 2 then
        self:handleDoubleClick(x, y, button)
        return
    end
    
    if button == 1 then -- Left click
        local element = self:getElementAt(x, y)
        if element then
            if element.type == "button" then
                self:handleButtonClick(element)
            elseif element.type == "list" then
                self:handleListItemClick(element, x, y)
            elseif element.type == "tower" then
                self:handleTowerClick(element)
            end
        end
        
        -- Close context menus if clicking outside
        if not element or element.type ~= "context_menu" then
            self:closeContextMenus()
        end
    elseif button == 2 then -- Right click
        local element = self:getElementAt(x, y)
        if element and element.type == "tower" then
            self:showTowerContextMenu(element, x, y)
        end
    end
end

function UI:mousereleased(x, y, button, istouch, presses)
    self.mouseState.isDown = false
    self.mouseState.button = nil
    
    if self.mouseState.isDragging then
        self:endDragging(x, y)
    end
end

function UI:mousemoved(x, y, dx, dy, istouch)
    if self.mouseState.isDragging and self.draggedElement then
        self:updateDragging(x, y)
    end
end

function UI:startDragging()
    local element = self:getElementAt(self.mouseState.x, self.mouseState.y)
    if element and element.draggable then
        self.draggedElement = element
        element.isDragging = true
    end
end

function UI:updateDragging(x, y)
    if self.draggedElement then
        -- Update element position
        self.draggedElement.x = x - self.draggedElement.dragOffset.x
        self.draggedElement.y = y - self.draggedElement.dragOffset.y
        
        -- Keep element within screen bounds
        self.draggedElement.x = math.max(0, math.min(x, love.graphics.getWidth() - self.draggedElement.width))
        self.draggedElement.y = math.max(0, math.min(y, love.graphics.getHeight() - self.draggedElement.height))
    end
end

function UI:endDragging(x, y)
    if self.draggedElement then
        self.draggedElement.isDragging = false
        self.draggedElement = nil
    end
end

function UI:handleDoubleClick(x, y, button)
    local element = self:getElementAt(x, y)
    if element and element.type == "tower" then
        self:showTowerInfo(element.id)
    end
end

function UI:handleTowerClick(tower)
    if self.selectedTower == tower.id then
        -- Deselect if clicking the same tower
        self.selectedTower = nil
        self:getElement("tower_info").visible = false
    else
        -- Select new tower
        self:selectTower(tower.id)
    end
end

function UI:handleButtonClick(element)
    if element.id == "start_wave" then
        self:startWave()
    elseif element.id:match("^ability_%d+$") then
        local abilityIndex = tonumber(element.id:match("%d+"))
        self:useAbility(abilityIndex)
    end
end

function UI:handleListItemClick(element, x, y)
    local itemIndex = math.floor((y - element.y) / 30) + 1
    if itemIndex >= 1 and itemIndex <= #element.items then
        local item = element.items[itemIndex]
        if gameState.resources >= item.cost then
            self:selectTower(item.id)
        else
            self:showNotification("Not enough resources!")
        end
    end
end

function UI:showTowerContextMenu(tower, x, y)
    local items = {
        {text = "Upgrade", action = function() self:showTowerUpgradeMenu(tower) end},
        {text = "Sell", action = function() self:sellTower(tower) end},
        {text = "Info", action = function() self:showTowerInfo(tower) end}
    }
    self:showContextMenu(x, y, items)
end

function UI:selectTower(towerId)
    self.selectedTower = towerId
    self:showTowerInfo(towerId)
end

function UI:showTowerInfo(towerId)
    local tower = gameState:getTowerById(towerId)
    if not tower then return end
    
    local infoPanel = self:getElement("tower_info")
    infoPanel.visible = true
    
    local nameText = self:getElement("tower_name")
    nameText.text = tower.name
    
    local statsText = self:getElement("tower_stats")
    statsText.text = string.format(
        "Damage: %d\nRange: %d\nAttack Speed: %.1f",
        tower.damage,
        tower.range,
        tower.attackSpeed
    )
    
    -- Update upgrade buttons
    local upgradeContainer = self:getElement("upgrade_buttons")
    upgradeContainer.children = {}
    
    for i, upgrade in ipairs(tower.upgradePaths) do
        table.insert(upgradeContainer.children, {
            type = "button",
            x = 10 + (i - 1) * 90,
            y = 0,
            width = 80,
            height = 40,
            text = upgrade.name,
            cost = upgrade.cost,
            action = function() self:upgradeTower(tower, i) end
        })
    end
end

function UI:upgradeTower(tower, upgradeIndex)
    if gameState.resources >= tower.upgradePaths[upgradeIndex].cost then
        if tower:upgrade(upgradeIndex) then
            gameState.resources = gameState.resources - tower.upgradePaths[upgradeIndex].cost
            self:showNotification("Tower upgraded!")
        end
    else
        self:showNotification("Not enough resources!")
    end
end

function UI:sellTower(tower)
    local sellValue = math.floor(tower.cost * 0.7)
    gameState.resources = gameState.resources + sellValue
    gameState:removeTower(tower)
    self:showNotification("Tower sold for " .. sellValue .. " resources!")
end

function UI:startWave()
    if gameState:canStartWave() then
        gameState:startWave()
        self:showNotification("Wave " .. gameState.currentWave .. " started!")
    else
        self:showNotification("Cannot start wave yet!")
    end
end

function UI:useAbility(abilityIndex)
    if gameState.hero and gameState.hero:canUseAbility(abilityIndex) then
        gameState.hero:useAbility(abilityIndex)
    else
        self:showNotification("Ability not ready!")
    end
end

function UI:showPauseMenu()
    Gamestate.push(require('states.pause'))
end

return UI 