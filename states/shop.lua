local ShopState = {}
ShopState.__index = ShopState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function ShopState.new()
    local self = setmetatable({}, ShopState)
    
    -- UI properties
    self.buttons = {}
    self.background = nil
    self.selectedFaction = nil
    self.selectedHero = nil
    self.title = "Shop"
    self.items = {}
    self.selectedItem = nil
    self.categories = {"Heroes", "Towers", "Consumables"}
    self.selectedCategory = "Heroes"
    self.resources = 1000 -- Placeholder for player's resources
    
    -- Timer for animations
    self.timer = Timer.new()
    
    return self
end

function ShopState:init(faction, hero)
    self.selectedFaction = faction
    self.selectedHero = hero
    
    -- Load background image
    local success, result = pcall(function()
        self.background = love.graphics.newImage("assets/backgrounds/shop.jpg")
    end)
    
    if not success then
        -- Try loading a fallback background
        success, result = pcall(function()
            self.background = love.graphics.newImage("sprites/ui/backgrounds/faction_select.jpg")
        end)
        
        if not success then
            -- No need to throw an error, we'll use a fallback color background
            self.background = nil
            print("Using fallback color background for shop screen")
        end
    end
    
    -- Load available items
    self:loadItems()
    
    -- Create UI
    self:createUI()
    
    -- Play background music
    -- playSound('music', 'shop')
end

function ShopState:loadItems()
    -- Hero items
    local heroItems = {
        {
            id = "heroic_sword",
            name = "Heroic Sword",
            description = "Increases hero damage by 15%",
            cost = 200,
            category = "Heroes",
            icon = "hero_sword.png",
            effect = "damage_boost",
            effectValue = 0.15
        },
        {
            id = "heavy_armor",
            name = "Heavy Armor",
            description = "Increases hero health by 20%",
            cost = 250,
            category = "Heroes",
            icon = "hero_armor.png",
            effect = "health_boost",
            effectValue = 0.2
        },
        {
            id = "swiftness_boots",
            name = "Swiftness Boots",
            description = "Increases hero movement speed by 10%",
            cost = 180,
            category = "Heroes",
            icon = "hero_boots.png",
            effect = "speed_boost",
            effectValue = 0.1
        }
    }
    
    -- Tower items
    local towerItems = {
        {
            id = "tower_crystal",
            name = "Focus Crystal",
            description = "Increases all tower range by 5%",
            cost = 300,
            category = "Towers",
            icon = "tower_crystal.png",
            effect = "range_boost",
            effectValue = 0.05
        },
        {
            id = "power_core",
            name = "Power Core",
            description = "Increases all tower damage by 10%",
            cost = 350,
            category = "Towers",
            icon = "tower_core.png",
            effect = "damage_boost",
            effectValue = 0.1
        },
        {
            id = "agility_shard",
            name = "Agility Shard",
            description = "Increases all tower attack speed by 8%",
            cost = 320,
            category = "Towers",
            icon = "tower_shard.png",
            effect = "speed_boost",
            effectValue = 0.08
        }
    }
    
    -- Consumable items
    local consumableItems = {
        {
            id = "repair_kit",
            name = "Repair Kit",
            description = "Restores 5 lives during a game",
            cost = 150,
            category = "Consumables",
            icon = "consumable_repair.png",
            effect = "restore_lives",
            effectValue = 5,
            usableInGame = true
        },
        {
            id = "gold_potion",
            name = "Gold Potion",
            description = "Grants 100 bonus resources at the start of a game",
            cost = 200,
            category = "Consumables",
            icon = "consumable_gold.png",
            effect = "bonus_resources",
            effectValue = 100,
            usableInGame = false
        },
        {
            id = "freeze_potion",
            name = "Freeze Potion",
            description = "Freezes all enemies for 3 seconds",
            cost = 250,
            category = "Consumables",
            icon = "consumable_freeze.png",
            effect = "freeze_enemies",
            effectValue = 3,
            usableInGame = true
        }
    }
    
    -- Combine all items
    self.items = {}
    for _, item in ipairs(heroItems) do table.insert(self.items, item) end
    for _, item in ipairs(towerItems) do table.insert(self.items, item) end
    for _, item in ipairs(consumableItems) do table.insert(self.items, item) end
    
    -- Load item icons
    for _, item in ipairs(self.items) do
        local iconPath = "assets/items/" .. item.icon
        
        -- Load item image if available
        if love.filesystem.getInfo(iconPath) then
            local success, result = Error.pcall(function()
                item.iconImage = love.graphics.newImage(iconPath)
            end)
            
            if not success then
                item.iconImage = nil
            end
        end
        
        -- Set owned status (placeholder - would come from player data)
        item.owned = false
    end
end

function ShopState:createUI()
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
    
    -- Category tabs
    local tabWidth = 150
    local tabHeight = 40
    local totalTabsWidth = #self.categories * tabWidth
    local startX = (screenWidth - totalTabsWidth) / 2
    
    for i, category in ipairs(self.categories) do
        table.insert(self.buttons, {
            text = category,
            x = startX + (i-1) * tabWidth,
            y = 110,
            width = tabWidth,
            height = tabHeight,
            hovered = false,
            category = category,
            action = function() self:selectCategory(category) end
        })
    end
    
    -- Purchase button
    table.insert(self.buttons, {
        text = "Purchase",
        x = screenWidth - 150,
        y = screenHeight - 80,
        width = 120,
        height = 40,
        hovered = false,
        enabled = false,
        action = function() self:purchaseItem() end
    })
    
    -- Item grid
    self.itemGrid = {
        x = 50,
        y = 170,
        width = screenWidth - 100,
        height = screenHeight - 260,
        columns = 3,
        spacing = 20,
        items = {},
        scrollOffset = 0,
        maxScroll = 0
    }
    
    -- Calculate item dimensions
    local availableWidth = self.itemGrid.width - (self.itemGrid.columns - 1) * self.itemGrid.spacing
    self.itemGrid.itemWidth = availableWidth / self.itemGrid.columns
    self.itemGrid.itemHeight = 150
    
    -- Update the item grid for the current category
    self:updateItemGrid()
end

function ShopState:updateItemGrid()
    -- Filter items by category
    self.itemGrid.items = {}
    for _, item in ipairs(self.items) do
        if item.category == self.selectedCategory then
            table.insert(self.itemGrid.items, item)
        end
    end
    
    -- Calculate max scroll
    local rows = math.ceil(#self.itemGrid.items / self.itemGrid.columns)
    local contentHeight = rows * (self.itemGrid.itemHeight + self.itemGrid.spacing) - self.itemGrid.spacing
    self.itemGrid.maxScroll = math.max(0, contentHeight - self.itemGrid.height)
    
    -- Reset scroll position
    self.itemGrid.scrollOffset = 0
    
    -- Reset selected item
    self.selectedItem = nil
    
    -- Update purchase button
    for _, button in ipairs(self.buttons) do
        if button.text == "Purchase" then
            button.enabled = false
        end
    end
end

function ShopState:goBack()
    local hubState = require('states.hub').new()
    hubState:init(self.selectedFaction, self.selectedHero)
    Gamestate.switch(hubState)
end

function ShopState:selectCategory(category)
    if self.selectedCategory ~= category then
        self.selectedCategory = category
        self:updateItemGrid()
    end
end

function ShopState:selectItem(item)
    self.selectedItem = item
    
    -- Update purchase button
    for _, button in ipairs(self.buttons) do
        if button.text == "Purchase" then
            -- Enable if not owned and have enough resources
            button.enabled = not item.owned and self.resources >= item.cost
        end
    end
end

function ShopState:purchaseItem()
    if not self.selectedItem or self.selectedItem.owned or self.resources < self.selectedItem.cost then
        return
    end
    
    -- Deduct resources
    self.resources = self.resources - self.selectedItem.cost
    
    -- Mark as owned
    self.selectedItem.owned = true
    
    -- Update purchase button
    for _, button in ipairs(self.buttons) do
        if button.text == "Purchase" then
            button.enabled = false
        end
    end
    
    -- Play purchase sound
    -- playSound('sfx', 'purchase')
    
    -- Show purchase animation
    self:playPurchaseAnimation()
    
    -- TODO: Actually apply the item effects to the player's data
end

function ShopState:playPurchaseAnimation()
    -- Animation parameters
    self.purchaseAnimation = {
        active = true,
        alpha = 1.0,
        scale = 1.0,
        y = 0
    }
    
    -- Animate the purchase effect
    self.timer:tween(0.3, self.purchaseAnimation, {scale = 1.5}, 'out-quad', function()
        self.timer:tween(0.2, self.purchaseAnimation, {scale = 1.0}, 'in-out-quad')
    end)
    
    self.timer:tween(0.8, self.purchaseAnimation, {y = -50}, 'out-quad')
    
    self.timer:after(0.5, function()
        self.timer:tween(0.3, self.purchaseAnimation, {alpha = 0}, 'in-quad', function()
            self.purchaseAnimation.active = false
        end)
    end)
end

function ShopState:enter()
    -- Animation or transition effect when entering this state
    self.timer:clear()
    
    -- Fade in effect
    self.fadeAlpha = 1
    self.timer:tween(0.5, self, {fadeAlpha = 0}, 'out-quad')
    
    -- Select first category by default
    self:selectCategory(self.categories[1])
end

function ShopState:update(dt)
    -- Update timer for animations
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function ShopState:draw()
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
    
    -- Draw resources
    love.graphics.setFont(fonts.main)
    love.graphics.setColor(1, 0.8, 0.2, 1)
    local resourceText = "Resources: " .. self.resources
    local resourceWidth = fonts.main:getWidth(resourceText)
    love.graphics.print(resourceText, love.graphics.getWidth() - resourceWidth - 20, 20)
    
    -- Draw category tabs
    for _, button in ipairs(self.buttons) do
        if button.category then
            -- Tab background
            if button.category == self.selectedCategory then
                love.graphics.setColor(0.3, 0.3, 0.5, 0.9)
            elseif button.hovered then
                love.graphics.setColor(0.25, 0.25, 0.4, 0.8)
            else
                love.graphics.setColor(0.15, 0.15, 0.3, 0.8)
            end
            
            love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10, 0, 0)
            
            -- Tab border
            if button.category == self.selectedCategory then
                love.graphics.setColor(0.7, 0.7, 0.9, 0.9)
            else
                love.graphics.setColor(0.4, 0.4, 0.6, 0.6)
            end
            love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10, 0, 0)
            
            -- Tab text
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(fonts.main)
            local textWidth = fonts.main:getWidth(button.text)
            love.graphics.print(
                button.text, 
                button.x + button.width / 2 - textWidth / 2, 
                button.y + button.height / 2 - fonts.main:getHeight() / 2
            )
        end
    end
    
    -- Draw item grid
    self:drawItemGrid()
    
    -- Draw regular buttons (not tabs)
    for _, button in ipairs(self.buttons) do
        if not button.category then
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
    end
    
    -- Draw purchase animation if active
    if self.purchaseAnimation and self.purchaseAnimation.active and self.selectedItem then
        self:drawPurchaseAnimation()
    end
    
    -- Draw fade overlay
    if self.fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- Draw error notifications
    Error.draw()
end

function ShopState:drawItemGrid()
    local grid = self.itemGrid
    
    -- Draw grid background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", grid.x, grid.y, grid.width, grid.height, 10, 10)
    
    -- Draw grid border
    love.graphics.setColor(0.4, 0.4, 0.6, 0.6)
    love.graphics.rectangle("line", grid.x, grid.y, grid.width, grid.height, 10, 10)
    
    -- Set up clipping region for items
    love.graphics.setScissor(grid.x, grid.y, grid.width, grid.height)
    
    -- Draw items
    for i, item in ipairs(grid.items) do
        local column = (i - 1) % grid.columns + 1
        local row = math.ceil(i / grid.columns)
        
        local x = grid.x + (column - 1) * (grid.itemWidth + grid.spacing)
        local y = grid.y + (row - 1) * (grid.itemHeight + grid.spacing) - grid.scrollOffset
        
        -- Skip if outside visible area
        if y + grid.itemHeight >= grid.y and y <= grid.y + grid.height then
            -- Item background
            if item == self.selectedItem then
                love.graphics.setColor(0.3, 0.3, 0.5, 0.9)
            elseif item.owned then
                love.graphics.setColor(0.2, 0.3, 0.2, 0.7)
            else
                love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            end
            love.graphics.rectangle("fill", x, y, grid.itemWidth, grid.itemHeight, 8, 8)
            
            -- Item border
            if item == self.selectedItem then
                love.graphics.setColor(0.7, 0.7, 0.9, 0.9)
            elseif item.owned then
                love.graphics.setColor(0.4, 0.7, 0.4, 0.7)
            else
                love.graphics.setColor(0.4, 0.4, 0.6, 0.6)
            end
            love.graphics.rectangle("line", x, y, grid.itemWidth, grid.itemHeight, 8, 8)
            
            -- Item icon
            local iconSize = 50
            local iconX = x + 20
            local iconY = y + 20
            
            love.graphics.setColor(1, 1, 1, 1)
            if item.iconImage then
                love.graphics.draw(item.iconImage, iconX, iconY, 0, iconSize / item.iconImage:getWidth(), iconSize / item.iconImage:getHeight())
            else
                -- Placeholder icon
                love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
                love.graphics.rectangle("fill", iconX, iconY, iconSize, iconSize)
            end
            
            -- Item name
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(fonts.main)
            love.graphics.printf(item.name, x + iconSize + 30, y + 20, grid.itemWidth - iconSize - 40, "left")
            
            -- Item description
            love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
            love.graphics.setFont(fonts.small)
            love.graphics.printf(item.description, x + iconSize + 30, y + 50, grid.itemWidth - iconSize - 40, "left")
            
            -- Item cost or owned status
            love.graphics.setFont(fonts.main)
            if item.owned then
                love.graphics.setColor(0.2, 0.8, 0.2, 1)
                love.graphics.print("Owned", x + 20, y + grid.itemHeight - 30)
            else
                love.graphics.setColor(1, 0.8, 0.2, 1)
                love.graphics.print("Cost: " .. item.cost, x + 20, y + grid.itemHeight - 30)
                
                -- Insufficient resources warning
                if self.resources < item.cost then
                    love.graphics.setColor(1, 0.3, 0.3, 0.7)
                    love.graphics.setFont(fonts.small)
                    love.graphics.print("Cannot afford", x + 100, y + grid.itemHeight - 30)
                end
            end
        end
    end
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw scroll indicators if needed
    if grid.maxScroll > 0 then
        if grid.scrollOffset > 0 then
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.polygon("fill", 
                grid.x + grid.width / 2, grid.y + 15,
                grid.x + grid.width / 2 - 10, grid.y + 5,
                grid.x + grid.width / 2 + 10, grid.y + 5
            )
        end
        
        if grid.scrollOffset < grid.maxScroll then
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.polygon("fill",
                grid.x + grid.width / 2, grid.y + grid.height - 15,
                grid.x + grid.width / 2 - 10, grid.y + grid.height - 5,
                grid.x + grid.width / 2 + 10, grid.y + grid.height - 5
            )
        end
    end
end

function ShopState:drawPurchaseAnimation()
    if not self.selectedItem or not self.purchaseAnimation then return end
    
    love.graphics.push()
    
    -- Find the position of the selected item
    local item = self.selectedItem
    local grid = self.itemGrid
    local itemIndex = 0
    
    for i, gridItem in ipairs(grid.items) do
        if gridItem == item then
            itemIndex = i
            break
        end
    end
    
    if itemIndex > 0 then
        local column = (itemIndex - 1) % grid.columns + 1
        local row = math.ceil(itemIndex / grid.columns)
        
        local x = grid.x + (column - 1) * (grid.itemWidth + grid.spacing) + grid.itemWidth / 2
        local y = grid.y + (row - 1) * (grid.itemHeight + grid.spacing) - grid.scrollOffset + grid.itemHeight / 2
        
        -- Set color with alpha from animation
        love.graphics.setColor(0.2, 1, 0.2, self.purchaseAnimation.alpha)
        
        -- Draw at center with scale and y offset
        love.graphics.translate(x, y + self.purchaseAnimation.y)
        love.graphics.scale(self.purchaseAnimation.scale)
        
        -- Draw purchase effect (a checkmark)
        love.graphics.setLineWidth(5)
        love.graphics.line(-20, 0, -5, 15, 20, -10)
        love.graphics.setLineWidth(1)
        
        -- Draw "Purchased!" text
        love.graphics.setFont(fonts.main)
        local textWidth = fonts.main:getWidth("Purchased!")
        love.graphics.print("Purchased!", -textWidth / 2, 20)
    end
    
    love.graphics.pop()
end

function ShopState:mousepressed(x, y, button)
    if button == 1 then
        -- Check category tabs
        for _, btn in ipairs(self.buttons) do
            if btn.category and self:isPointInRect(x, y, btn.x, btn.y, btn.width, btn.height) then
                self:selectCategory(btn.category)
                return
            end
        end
        
        -- Check item grid
        local grid = self.itemGrid
        if self:isPointInRect(x, y, grid.x, grid.y, grid.width, grid.height) then
            -- Calculate which item was clicked
            for i, item in ipairs(grid.items) do
                local column = (i - 1) % grid.columns + 1
                local row = math.ceil(i / grid.columns)
                
                local itemX = grid.x + (column - 1) * (grid.itemWidth + grid.spacing)
                local itemY = grid.y + (row - 1) * (grid.itemHeight + grid.spacing) - grid.scrollOffset
                
                if self:isPointInRect(x, y, itemX, itemY, grid.itemWidth, grid.itemHeight) then
                    self:selectItem(item)
                    return
                end
            end
        end
        
        -- Check scroll indicators
        if grid.maxScroll > 0 and x >= grid.x and x <= grid.x + grid.width then
            -- Up arrow
            if y >= grid.y and y <= grid.y + 20 and grid.scrollOffset > 0 then
                grid.scrollOffset = math.max(0, grid.scrollOffset - (grid.itemHeight + grid.spacing))
                return
            end
            
            -- Down arrow
            if y >= grid.y + grid.height - 20 and y <= grid.y + grid.height and
               grid.scrollOffset < grid.maxScroll then
                grid.scrollOffset = math.min(grid.maxScroll, grid.scrollOffset + (grid.itemHeight + grid.spacing))
                return
            end
        end
        
        -- Check action buttons (not tabs)
        for _, btn in ipairs(self.buttons) do
            if not btn.category and self:isPointInRect(x, y, btn.x, btn.y, btn.width, btn.height) then
                if btn.action and (btn.enabled ~= false) then
                    btn.action()
                end
                return
            end
        end
    end
end

function ShopState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    for _, btn in ipairs(self.buttons) do
        btn.hovered = self:isPointInRect(x, y, btn.x, btn.y, btn.width, btn.height)
    end
end

function ShopState:wheelmoved(x, y)
    if y ~= 0 and self.itemGrid.maxScroll > 0 then
        -- Check if mouse is over the item grid
        local mx, my = love.mouse.getPosition()
        if self:isPointInRect(mx, my, self.itemGrid.x, self.itemGrid.y, self.itemGrid.width, self.itemGrid.height) then
            -- Scroll up or down
            self.itemGrid.scrollOffset = math.max(0, math.min(
                self.itemGrid.maxScroll,
                self.itemGrid.scrollOffset - y * 30
            ))
        end
    end
end

function ShopState:isPointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

function ShopState:keypressed(key)
    if key == "escape" then
        self:goBack()
    elseif key == "left" or key == "right" then
        -- Navigate between categories
        local currentIndex = 1
        for i, category in ipairs(self.categories) do
            if category == self.selectedCategory then
                currentIndex = i
                break
            end
        end
        
        if key == "left" and currentIndex > 1 then
            self:selectCategory(self.categories[currentIndex - 1])
        elseif key == "right" and currentIndex < #self.categories then
            self:selectCategory(self.categories[currentIndex + 1])
        end
    elseif key == "return" or key == "space" then
        -- Purchase selected item
        local purchaseBtn = nil
        for _, btn in ipairs(self.buttons) do
            if btn.text == "Purchase" then
                purchaseBtn = btn
                break
            end
        end
        
        if purchaseBtn and purchaseBtn.enabled ~= false then
            self:purchaseItem()
        end
    end
end

return ShopState 