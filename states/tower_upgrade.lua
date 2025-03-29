local TowerUpgradeState = {}
TowerUpgradeState.__index = TowerUpgradeState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function TowerUpgradeState.new()
    local self = setmetatable({}, TowerUpgradeState)
    
    -- UI properties
    self.buttons = {}
    self.background = nil
    self.selectedFaction = nil
    self.selectedHero = nil
    self.title = "Tower Upgrades"
    self.towers = {}
    self.selectedTower = nil
    self.resources = 1000 -- Placeholder for player's resources
    
    -- Timer for animations
    self.timer = Timer.new()
    
    return self
end

function TowerUpgradeState:init(faction, hero)
    self.selectedFaction = faction
    self.selectedHero = hero
    
    -- Load background image
    local success, result = Error.pcall(function()
        self.background = love.graphics.newImage("assets/backgrounds/tower_upgrade.jpg")
    end)
    
    if not success then
        Error.handle(Error.TYPES.RESOURCE, "IMAGE_MISSING", "assets/backgrounds/tower_upgrade.jpg")
    end
    
    -- Load available towers
    self:loadTowers()
    
    -- Create UI
    self:createUI()
    
    -- Play background music
    -- playSound('music', 'tower_upgrade')
end

function TowerUpgradeState:loadTowers()
    -- Load towers based on faction
    local Tower = require('systems.tower')
    if not Tower or not self.selectedFaction then
        Error.handle(Error.TYPES.GAME, "MISSING_FACTION", "Cannot load towers")
        return
    end
    
    -- Get tower types from the Tower module
    local towerTypes = {}
    
    if Tower.getTowersByFaction then
        towerTypes = Tower.getTowersByFaction(self.selectedFaction.id)
    else
        -- Fallback tower definitions
        if self.selectedFaction.id == "radiant" then
            towerTypes = {
                {
                    id = "archer",
                    name = "Archer Tower",
                    description = "Basic ranged tower",
                    damage = 10,
                    range = 150,
                    attackSpeed = 1.0,
                    cost = 100,
                    upgradeLevel = 1,
                    maxLevel = 3,
                    upgrades = {
                        {
                            level = 2,
                            name = "Enhanced Arrows",
                            damage = 15,
                            range = 170,
                            attackSpeed = 1.2,
                            cost = 150
                        },
                        {
                            level = 3,
                            name = "Sharpshooter",
                            damage = 25,
                            range = 200,
                            attackSpeed = 1.5,
                            cost = 250
                        }
                    }
                },
                {
                    id = "mage",
                    name = "Mage Tower",
                    description = "Magical damage tower",
                    damage = 15,
                    range = 120,
                    attackSpeed = 0.8,
                    cost = 150,
                    upgradeLevel = 1,
                    maxLevel = 3,
                    upgrades = {
                        {
                            level = 2,
                            name = "Arcane Focus",
                            damage = 25,
                            range = 140,
                            attackSpeed = 0.9,
                            cost = 200
                        },
                        {
                            level = 3,
                            name = "Elemental Mastery",
                            damage = 40,
                            range = 160,
                            attackSpeed = 1.0,
                            cost = 300
                        }
                    }
                }
            }
        elseif self.selectedFaction.id == "shadow" then
            towerTypes = {
                {
                    id = "necromancer",
                    name = "Necromancer Tower",
                    description = "Summons skeletons to fight",
                    damage = 8,
                    range = 130,
                    attackSpeed = 0.7,
                    cost = 120,
                    upgradeLevel = 1,
                    maxLevel = 3,
                    upgrades = {
                        {
                            level = 2,
                            name = "Bone Legion",
                            damage = 12,
                            range = 150,
                            attackSpeed = 0.8,
                            cost = 180
                        },
                        {
                            level = 3,
                            name = "Death Lord",
                            damage = 20,
                            range = 180,
                            attackSpeed = 0.9,
                            cost = 270
                        }
                    }
                },
                {
                    id = "shadow_archer",
                    name = "Shadow Archer",
                    description = "Ranged tower with poison damage",
                    damage = 12,
                    range = 160,
                    attackSpeed = 1.0,
                    cost = 130,
                    upgradeLevel = 1,
                    maxLevel = 3,
                    upgrades = {
                        {
                            level = 2,
                            name = "Venom Tips",
                            damage = 17,
                            range = 180,
                            attackSpeed = 1.1,
                            cost = 190
                        },
                        {
                            level = 3,
                            name = "Plague Bearer",
                            damage = 28,
                            range = 210,
                            attackSpeed = 1.3,
                            cost = 280
                        }
                    }
                }
            }
        elseif self.selectedFaction.id == "twilight" then
            towerTypes = {
                {
                    id = "balance_mage",
                    name = "Balance Mage",
                    description = "Deals both physical and magical damage",
                    damage = 12,
                    range = 140,
                    attackSpeed = 0.9,
                    cost = 140,
                    upgradeLevel = 1,
                    maxLevel = 3,
                    upgrades = {
                        {
                            level = 2,
                            name = "Duality Focus",
                            damage = 18,
                            range = 160,
                            attackSpeed = 1.0,
                            cost = 210
                        },
                        {
                            level = 3,
                            name = "Twilight Master",
                            damage = 30,
                            range = 190,
                            attackSpeed = 1.2,
                            cost = 320
                        }
                    }
                },
                {
                    id = "time_mage",
                    name = "Time Mage",
                    description = "Slows enemies in its range",
                    damage = 8,
                    range = 120,
                    attackSpeed = 0.7,
                    cost = 160,
                    upgradeLevel = 1,
                    maxLevel = 3,
                    upgrades = {
                        {
                            level = 2,
                            name = "Chronos Touch",
                            damage = 12,
                            range = 140,
                            attackSpeed = 0.8,
                            cost = 240
                        },
                        {
                            level = 3,
                            name = "Temporal Anchor",
                            damage = 20,
                            range = 170,
                            attackSpeed = 0.9,
                            cost = 350
                        }
                    }
                }
            }
        end
    end
    
    -- Load tower icons
    for _, tower in ipairs(towerTypes) do
        local iconPath = "assets/towers/" .. tower.id .. ".png"
        
        -- Load tower image if available
        if love.filesystem.getInfo(iconPath) then
            local success, result = Error.pcall(function()
                tower.icon = love.graphics.newImage(iconPath)
            end)
            
            if not success then
                tower.icon = nil
            end
        end
        
        table.insert(self.towers, tower)
    end
end

function TowerUpgradeState:createUI()
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
    
    -- Tower list (left side)
    self.towerList = {
        x = 50,
        y = 150,
        width = 300,
        height = screenHeight - 250,
        towers = self.towers,
        scrollOffset = 0,
        maxScroll = math.max(0, #self.towers * 90 - (screenHeight - 250)),
        selectedIndex = nil
    }
    
    -- Tower details (right side)
    self.towerDetails = {
        x = screenWidth - 450,
        y = 150,
        width = 400,
        height = screenHeight - 250
    }
    
    -- Upgrade button
    table.insert(self.buttons, {
        text = "Upgrade Tower",
        x = screenWidth - 300,
        y = screenHeight - 80,
        width = 250,
        height = 40,
        hovered = false,
        enabled = false,
        action = function() self:upgradeTower() end
    })
end

function TowerUpgradeState:goBack()
    local hubState = require('states.hub').new()
    hubState:init(self.selectedFaction, self.selectedHero)
    Gamestate.switch(hubState)
end

function TowerUpgradeState:selectTower(index)
    self.towerList.selectedIndex = index
    self.selectedTower = self.towers[index]
    
    -- Update upgrade button
    for _, button in ipairs(self.buttons) do
        if button.text == "Upgrade Tower" then
            -- Check if can be upgraded
            local canUpgrade = self.selectedTower and 
                              self.selectedTower.upgradeLevel < self.selectedTower.maxLevel and
                              self.resources >= self:getUpgradeCost()
            button.enabled = canUpgrade
        end
    end
end

function TowerUpgradeState:getUpgradeCost()
    if not self.selectedTower or 
       self.selectedTower.upgradeLevel >= self.selectedTower.maxLevel then
        return 0
    end
    
    local nextUpgrade = self.selectedTower.upgrades[self.selectedTower.upgradeLevel]
    if nextUpgrade then
        return nextUpgrade.cost
    end
    
    return 0
end

function TowerUpgradeState:upgradeTower()
    if not self.selectedTower or 
       self.selectedTower.upgradeLevel >= self.selectedTower.maxLevel then
        return
    end
    
    local upgradeCost = self:getUpgradeCost()
    if self.resources < upgradeCost then
        Error.handle(Error.TYPES.GAME, "INSUFFICIENT_RESOURCES", "Not enough resources to upgrade")
        return
    end
    
    -- Perform the upgrade
    local nextLevel = self.selectedTower.upgradeLevel + 1
    local upgrade = self.selectedTower.upgrades[self.selectedTower.upgradeLevel]
    
    if upgrade then
        -- Update stats
        self.selectedTower.upgradeLevel = nextLevel
        self.selectedTower.damage = upgrade.damage
        self.selectedTower.range = upgrade.range
        self.selectedTower.attackSpeed = upgrade.attackSpeed
        
        -- Deduct resources
        self.resources = self.resources - upgradeCost
        
        -- Update button state
        for _, button in ipairs(self.buttons) do
            if button.text == "Upgrade Tower" then
                button.enabled = nextLevel < self.selectedTower.maxLevel and
                                self.resources >= self:getUpgradeCost()
            end
        end
        
        -- Play upgrade sound
        -- playSound('sfx', 'upgrade')
        
        -- Show upgrade animation
        self:playUpgradeAnimation()
    end
end

function TowerUpgradeState:playUpgradeAnimation()
    -- Animation parameters
    self.upgradeAnimation = {
        active = true,
        scale = 1.0,
        alpha = 1.0,
        rotation = 0
    }
    
    -- Scale up animation
    self.timer:tween(0.3, self.upgradeAnimation, {scale = 1.5}, 'out-quad', function()
        -- Scale down animation
        self.timer:tween(0.2, self.upgradeAnimation, {scale = 1.0}, 'in-out-quad')
    end)
    
    -- Rotate animation
    self.timer:tween(0.5, self.upgradeAnimation, {rotation = math.pi * 2}, 'linear')
    
    -- Fade out animation
    self.timer:after(0.4, function()
        self.timer:tween(0.3, self.upgradeAnimation, {alpha = 0}, 'in-quad', function()
            self.upgradeAnimation.active = false
        end)
    end)
end

function TowerUpgradeState:enter()
    -- Animation or transition effect when entering this state
    self.timer:clear()
    
    -- Fade in effect
    self.fadeAlpha = 1
    self.timer:tween(0.5, self, {fadeAlpha = 0}, 'out-quad')
    
    -- Select first tower by default
    if #self.towers > 0 then
        self:selectTower(1)
    end
end

function TowerUpgradeState:update(dt)
    -- Update timer for animations
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function TowerUpgradeState:draw()
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
        local factionText = self.selectedFaction.name .. " Towers"
        local factionWidth = fonts.subTitle:getWidth(factionText)
        love.graphics.print(factionText, love.graphics.getWidth() / 2 - factionWidth / 2, 100)
    end
    
    -- Draw resources
    love.graphics.setFont(fonts.main)
    love.graphics.setColor(1, 0.8, 0.2, 1)
    love.graphics.print("Resources: " .. self.resources, 50, 120)
    
    -- Draw tower list
    self:drawTowerList()
    
    -- Draw tower details
    self:drawTowerDetails()
    
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
    
    -- Draw upgrade animation if active
    if self.upgradeAnimation and self.upgradeAnimation.active then
        self:drawUpgradeAnimation()
    end
    
    -- Draw fade overlay
    if self.fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- Draw error notifications
    Error.draw()
end

function TowerUpgradeState:drawTowerList()
    local list = self.towerList
    
    -- Draw list background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", list.x, list.y, list.width, list.height, 10, 10)
    
    -- Draw list border
    love.graphics.setColor(0.4, 0.4, 0.6, 0.6)
    love.graphics.rectangle("line", list.x, list.y, list.width, list.height, 10, 10)
    
    -- Draw list title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.subTitle)
    love.graphics.print("Available Towers", list.x + 20, list.y + 10)
    
    -- Set up clipping region for tower entries
    love.graphics.setScissor(list.x, list.y + 50, list.width, list.height - 50)
    
    -- Draw tower entries
    love.graphics.setFont(fonts.main)
    for i, tower in ipairs(list.towers) do
        local y = list.y + 50 + (i-1) * 90 - list.scrollOffset
        
        -- Skip if outside visible area
        if y + 80 >= list.y + 50 and y <= list.y + list.height then
            -- Entry background
            if i == list.selectedIndex then
                love.graphics.setColor(0.3, 0.3, 0.5, 0.9)
            else
                love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
            end
            love.graphics.rectangle("fill", list.x + 10, y, list.width - 20, 80, 8, 8)
            
            -- Entry border
            if i == list.selectedIndex then
                love.graphics.setColor(0.7, 0.7, 0.9, 0.9)
            else
                love.graphics.setColor(0.4, 0.4, 0.6, 0.6)
            end
            love.graphics.rectangle("line", list.x + 10, y, list.width - 20, 80, 8, 8)
            
            -- Tower icon
            love.graphics.setColor(1, 1, 1, 1)
            if tower.icon then
                love.graphics.draw(tower.icon, list.x + 30, y + 10, 0, 0.6, 0.6)
            else
                -- Placeholder icon
                love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
                love.graphics.rectangle("fill", list.x + 20, y + 10, 60, 60)
            end
            
            -- Tower name
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(tower.name, list.x + 100, y + 15)
            
            -- Tower level
            love.graphics.setColor(1, 0.8, 0.2, 1)
            love.graphics.print("Level " .. tower.upgradeLevel .. "/" .. tower.maxLevel, list.x + 100, y + 45)
        end
    end
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw scroll indicators if needed
    if list.maxScroll > 0 then
        if list.scrollOffset > 0 then
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.polygon("fill", 
                list.x + list.width / 2, list.y + 35,
                list.x + list.width / 2 - 10, list.y + 45,
                list.x + list.width / 2 + 10, list.y + 45
            )
        end
        
        if list.scrollOffset < list.maxScroll then
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.polygon("fill",
                list.x + list.width / 2, list.y + list.height - 35,
                list.x + list.width / 2 - 10, list.y + list.height - 45,
                list.x + list.width / 2 + 10, list.y + list.height - 45
            )
        end
    end
end

function TowerUpgradeState:drawTowerDetails()
    local details = self.towerDetails
    
    -- Draw details background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", details.x, details.y, details.width, details.height, 10, 10)
    
    -- Draw details border
    love.graphics.setColor(0.4, 0.4, 0.6, 0.6)
    love.graphics.rectangle("line", details.x, details.y, details.width, details.height, 10, 10)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.subTitle)
    love.graphics.print("Tower Details", details.x + 20, details.y + 10)
    
    -- If no tower selected
    if not self.selectedTower then
        love.graphics.setFont(fonts.main)
        love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
        love.graphics.printf("Select a tower to view details", details.x + 50, details.y + details.height / 2 - 20, details.width - 100, "center")
        return
    end
    
    local tower = self.selectedTower
    
    -- Tower icon
    love.graphics.setColor(1, 1, 1, 1)
    if tower.icon then
        love.graphics.draw(tower.icon, details.x + 50, details.y + 60, 0, 1, 1)
    else
        -- Placeholder icon
        love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
        love.graphics.rectangle("fill", details.x + 30, details.y + 60, 100, 100)
    end
    
    -- Tower name and level
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.subTitle)
    love.graphics.print(tower.name, details.x + 150, details.y + 60)
    
    love.graphics.setFont(fonts.main)
    love.graphics.setColor(1, 0.8, 0.2, 1)
    love.graphics.print("Level " .. tower.upgradeLevel .. "/" .. tower.maxLevel, details.x + 150, details.y + 90)
    
    -- Tower description
    love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
    love.graphics.setFont(fonts.small)
    love.graphics.printf(tower.description, details.x + 150, details.y + 115, details.width - 180, "left")
    
    -- Tower stats
    love.graphics.setFont(fonts.main)
    
    local statY = details.y + 180
    local statSpacing = 30
    
    -- Current stats
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Current Stats:", details.x + 30, statY)
    
    love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
    love.graphics.print("Damage: " .. tower.damage, details.x + 50, statY + statSpacing)
    love.graphics.print("Range: " .. tower.range, details.x + 50, statY + statSpacing * 2)
    love.graphics.print("Attack Speed: " .. tower.attackSpeed, details.x + 50, statY + statSpacing * 3)
    
    -- Next level stats (if upgradeable)
    if tower.upgradeLevel < tower.maxLevel then
        local nextUpgrade = tower.upgrades[tower.upgradeLevel]
        
        if nextUpgrade then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("Next Level: " .. nextUpgrade.name, details.x + 230, statY)
            
            -- Damage comparison
            local damageChange = nextUpgrade.damage - tower.damage
            local damageColor = damageChange > 0 and {0.2, 1, 0.2, 0.9} or {1, 0.2, 0.2, 0.9}
            love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
            love.graphics.print("Damage: " .. nextUpgrade.damage, details.x + 250, statY + statSpacing)
            if damageChange ~= 0 then
                love.graphics.setColor(damageColor)
                love.graphics.print(damageChange > 0 and "+" .. damageChange or damageChange, details.x + 350, statY + statSpacing)
            end
            
            -- Range comparison
            local rangeChange = nextUpgrade.range - tower.range
            local rangeColor = rangeChange > 0 and {0.2, 1, 0.2, 0.9} or {1, 0.2, 0.2, 0.9}
            love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
            love.graphics.print("Range: " .. nextUpgrade.range, details.x + 250, statY + statSpacing * 2)
            if rangeChange ~= 0 then
                love.graphics.setColor(rangeColor)
                love.graphics.print(rangeChange > 0 and "+" .. rangeChange or rangeChange, details.x + 350, statY + statSpacing * 2)
            end
            
            -- Attack Speed comparison
            local speedChange = nextUpgrade.attackSpeed - tower.attackSpeed
            local speedColor = speedChange > 0 and {0.2, 1, 0.2, 0.9} or {1, 0.2, 0.2, 0.9}
            love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
            love.graphics.print("Attack Speed: " .. nextUpgrade.attackSpeed, details.x + 250, statY + statSpacing * 3)
            if speedChange ~= 0 then
                love.graphics.setColor(speedColor)
                love.graphics.print(speedChange > 0 and "+" .. string.format("%.1f", speedChange) or string.format("%.1f", speedChange), details.x + 350, statY + statSpacing * 3)
            end
            
            -- Upgrade cost
            love.graphics.setColor(1, 0.8, 0.2, 1)
            love.graphics.print("Upgrade Cost: " .. nextUpgrade.cost, details.x + 30, statY + statSpacing * 5)
            
            -- Insufficient resources warning
            if self.resources < nextUpgrade.cost then
                love.graphics.setColor(1, 0.3, 0.3, 1)
                love.graphics.print("Insufficient resources!", details.x + 200, statY + statSpacing * 5)
            end
        end
    else
        -- Max level reached
        love.graphics.setColor(1, 0.8, 0.2, 1)
        love.graphics.print("Maximum level reached!", details.x + 230, statY)
    end
end

function TowerUpgradeState:drawUpgradeAnimation()
    if not self.selectedTower or not self.upgradeAnimation then return end
    
    love.graphics.push()
    
    -- Get tower position in details panel
    local details = self.towerDetails
    local centerX = details.x + 80
    local centerY = details.y + 110
    
    -- Set color with alpha from animation
    love.graphics.setColor(1, 0.8, 0.2, self.upgradeAnimation.alpha)
    
    -- Draw at center with rotation and scale
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(self.upgradeAnimation.rotation)
    love.graphics.scale(self.upgradeAnimation.scale)
    
    -- Draw upgrade effect (a star shape)
    local size = 50
    for i = 1, 5 do
        local angle = (i - 1) * math.pi * 2 / 5 - math.pi / 2
        local nextAngle = angle + math.pi * 2 / 10
        
        local outerX = math.cos(angle) * size
        local outerY = math.sin(angle) * size
        
        local innerX = math.cos(nextAngle) * (size * 0.4)
        local innerY = math.sin(nextAngle) * (size * 0.4)
        
        love.graphics.polygon("fill", 
            0, 0,
            outerX, outerY,
            innerX, innerY
        )
    end
    
    love.graphics.pop()
end

function TowerUpgradeState:mousepressed(x, y, button)
    if button == 1 then
        -- Check tower list entries
        local list = self.towerList
        if x >= list.x and x <= list.x + list.width and
           y >= list.y + 50 and y <= list.y + list.height then
            -- Calculate which tower was clicked
            local clickedIndex = nil
            for i, tower in ipairs(list.towers) do
                local towerY = list.y + 50 + (i-1) * 90 - list.scrollOffset
                if y >= towerY and y <= towerY + 80 then
                    clickedIndex = i
                    break
                end
            end
            
            if clickedIndex then
                self:selectTower(clickedIndex)
                return
            end
        end
        
        -- Check scroll indicators
        if list.maxScroll > 0 and x >= list.x and x <= list.x + list.width then
            -- Up arrow
            if y >= list.y + 30 and y <= list.y + 50 and list.scrollOffset > 0 then
                list.scrollOffset = math.max(0, list.scrollOffset - 90)
                return
            end
            
            -- Down arrow
            if y >= list.y + list.height - 50 and y <= list.y + list.height - 30 and
               list.scrollOffset < list.maxScroll then
                list.scrollOffset = math.min(list.maxScroll, list.scrollOffset + 90)
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

function TowerUpgradeState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    for _, btn in ipairs(self.buttons) do
        btn.hovered = self:isPointInRect(x, y, btn.x, btn.y, btn.width, btn.height)
    end
    
    -- Handle mouse wheel for scrolling
    function TowerUpgradeState:wheelmoved(x, y)
        if y ~= 0 and self.towerList.maxScroll > 0 then
            -- Check if mouse is over the tower list
            local mx, my = love.mouse.getPosition()
            if mx >= self.towerList.x and mx <= self.towerList.x + self.towerList.width and
               my >= self.towerList.y and my <= self.towerList.y + self.towerList.height then
                -- Scroll up or down
                self.towerList.scrollOffset = math.max(0, math.min(
                    self.towerList.maxScroll,
                    self.towerList.scrollOffset - y * 30
                ))
            end
        end
    end
end

function TowerUpgradeState:isPointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

function TowerUpgradeState:keypressed(key)
    if key == "escape" then
        self:goBack()
    elseif key == "up" then
        -- Navigate up in tower list
        if self.towerList.selectedIndex and self.towerList.selectedIndex > 1 then
            self:selectTower(self.towerList.selectedIndex - 1)
            
            -- Adjust scroll if needed
            local towerY = self.towerList.y + 50 + (self.towerList.selectedIndex - 1) * 90 - self.towerList.scrollOffset
            if towerY < self.towerList.y + 50 then
                self.towerList.scrollOffset = (self.towerList.selectedIndex - 1) * 90
            end
        end
    elseif key == "down" then
        -- Navigate down in tower list
        if self.towerList.selectedIndex and self.towerList.selectedIndex < #self.towers then
            self:selectTower(self.towerList.selectedIndex + 1)
            
            -- Adjust scroll if needed
            local towerY = self.towerList.y + 50 + (self.towerList.selectedIndex - 1) * 90 - self.towerList.scrollOffset
            if towerY + 80 > self.towerList.y + self.towerList.height then
                self.towerList.scrollOffset = (self.towerList.selectedIndex - 1) * 90 - (self.towerList.height - 130)
            end
        end
    elseif key == "return" or key == "space" then
        -- Upgrade selected tower
        local upgradeBtn = nil
        for _, btn in ipairs(self.buttons) do
            if btn.text == "Upgrade Tower" then
                upgradeBtn = btn
                break
            end
        end
        
        if upgradeBtn and upgradeBtn.enabled ~= false then
            self:upgradeTower()
        end
    end
end

return TowerUpgradeState 