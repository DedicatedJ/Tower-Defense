local UIEnhancements = {}
UIEnhancements.__index = UIEnhancements

function UIEnhancements.new()
    local self = setmetatable({}, UIEnhancements)
    
    self.minimap = {
        scale = 0.2,
        position = {x = 10, y = 10},
        size = {width = 200, height = 200},
        visible = true
    }
    
    self.dragAndDrop = {
        active = false,
        tower = nil,
        preview = nil
    }
    
    self.quickSelect = {
        keys = {
            ["1"] = "arrow_tower",
            ["2"] = "cannon_tower",
            ["3"] = "magic_tower",
            ["4"] = "holy_tower",
            ["5"] = "necromancer_tower",
            ["6"] = "balance_tower"
        }
    }
    
    self.cursor = {
        type = "default",
        position = {x = 0, y = 0},
        validPlacement = false
    }
    
    self.tooltips = {
        active = false,
        text = "",
        position = {x = 0, y = 0},
        delay = 0.5,
        timer = 0
    }
    
    return self
end

function UIEnhancements:update(dt)
    -- Update cursor position
    self.cursor.position.x, self.cursor.position.y = love.mouse.getPosition()
    
    -- Update tooltip timer
    if self.tooltips.active then
        self.tooltips.timer = self.tooltips.timer + dt
    end
    
    -- Update drag and drop preview
    if self.dragAndDrop.active then
        self:updateTowerPreview()
    end
    
    -- Update minimap
    self:updateMinimap()
end

function UIEnhancements:draw()
    -- Draw minimap
    if self.minimap.visible then
        self:drawMinimap()
    end
    
    -- Draw drag and drop preview
    if self.dragAndDrop.active then
        self:drawTowerPreview()
    end
    
    -- Draw cursor
    self:drawCursor()
    
    -- Draw tooltip
    if self.tooltips.active and self.tooltips.timer >= self.tooltips.delay then
        self:drawTooltip()
    end
end

function UIEnhancements:drawMinimap()
    local m = self.minimap
    
    -- Draw minimap background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", m.position.x, m.position.y, m.size.width, m.size.height)
    
    -- Draw map
    love.graphics.setColor(1, 1, 1)
    gameState.map:draw(m.position.x, m.position.y, m.scale)
    
    -- Draw towers
    love.graphics.setColor(0, 1, 0)
    for _, tower in ipairs(gameState.towers) do
        local x = m.position.x + tower.x * m.scale
        local y = m.position.y + tower.y * m.scale
        love.graphics.circle("fill", x, y, 2)
    end
    
    -- Draw enemies
    love.graphics.setColor(1, 0, 0)
    for _, enemy in ipairs(gameState.enemies) do
        local x = m.position.x + enemy.x * m.scale
        local y = m.position.y + enemy.y * m.scale
        love.graphics.circle("fill", x, y, 1)
    end
    
    -- Draw hero
    love.graphics.setColor(0, 0, 1)
    local hero = gameState.hero
    local x = m.position.x + hero.x * m.scale
    local y = m.position.y + hero.y * m.scale
    love.graphics.circle("fill", x, y, 2)
end

function UIEnhancements:updateTowerPreview()
    if not self.dragAndDrop.tower then return end
    
    local x, y = love.mouse.getPosition()
    local spot = gameState.map:getTowerSpotAt(x, y)
    
    if spot then
        self.dragAndDrop.preview = {
            x = spot.x,
            y = spot.y,
            valid = gameState:canPlaceTower(spot)
        }
    else
        self.dragAndDrop.preview = nil
    end
end

function UIEnhancements:drawTowerPreview()
    if not self.dragAndDrop.preview then return end
    
    local p = self.dragAndDrop.preview
    local color = p.valid and {0, 1, 0, 0.5} or {1, 0, 0, 0.5}
    
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle("fill", p.x - 16, p.y - 16, 32, 32)
end

function UIEnhancements:drawCursor()
    local c = self.cursor
    
    -- Draw cursor based on type
    if c.type == "tower_placement" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", c.position.x, c.position.y, 16)
    elseif c.type == "tower_upgrade" then
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("line", c.position.x, c.position.y, 16)
    elseif c.type == "ability_target" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("line", c.position.x, c.position.y, 32)
    end
end

function UIEnhancements:drawTooltip()
    local t = self.tooltips
    
    -- Draw tooltip background
    love.graphics.setColor(0, 0, 0, 0.8)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(t.text)
    local textHeight = font:getHeight()
    local padding = 5
    
    love.graphics.rectangle("fill", 
        t.position.x, 
        t.position.y, 
        textWidth + padding * 2, 
        textHeight + padding * 2
    )
    
    -- Draw tooltip text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(t.text, t.position.x + padding, t.position.y + padding)
end

function UIEnhancements:startDragAndDrop(tower)
    self.dragAndDrop.active = true
    self.dragAndDrop.tower = tower
    self.cursor.type = "tower_placement"
end

function UIEnhancements:endDragAndDrop()
    if not self.dragAndDrop.active then return end
    
    local x, y = love.mouse.getPosition()
    local spot = gameState.map:getTowerSpotAt(x, y)
    
    if spot and self.dragAndDrop.preview and self.dragAndDrop.preview.valid then
        gameState:placeTower(self.dragAndDrop.tower, spot)
    end
    
    self.dragAndDrop.active = false
    self.dragAndDrop.tower = nil
    self.dragAndDrop.preview = nil
    self.cursor.type = "default"
end

function UIEnhancements:showTooltip(text, x, y)
    self.tooltips.text = text
    self.tooltips.position.x = x
    self.tooltips.position.y = y
    self.tooltips.active = true
    self.tooltips.timer = 0
end

function UIEnhancements:hideTooltip()
    self.tooltips.active = false
end

function UIEnhancements:mousepressed(x, y, button)
    if button == 1 then -- Left click
        if self.dragAndDrop.active then
            self:endDragAndDrop()
        end
    end
end

function UIEnhancements:mousereleased(x, y, button)
    if button == 1 then -- Left click
        if self.dragAndDrop.active then
            self:endDragAndDrop()
        end
    end
end

function UIEnhancements:keypressed(key)
    -- Handle quick select keys
    if self.quickSelect.keys[key] then
        local towerType = self.quickSelect.keys[key]
        if gameState:canAffordTower(towerType) then
            self:startDragAndDrop(towerType)
        end
    end
end

function UIEnhancements:updateCursorType()
    local x, y = love.mouse.getPosition()
    
    -- Check for tower placement
    if gameState.selectedTower then
        self.cursor.type = "tower_placement"
    -- Check for tower upgrade
    elseif gameState:getTowerAt(x, y) then
        self.cursor.type = "tower_upgrade"
    -- Check for ability target
    elseif gameState.selectedAbility then
        self.cursor.type = "ability_target"
    else
        self.cursor.type = "default"
    end
end

return UIEnhancements 