local GameState = {}
GameState.__index = GameState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function GameState.new()
    local self = setmetatable({}, GameState)
    
    -- Game properties
    self.map = nil
    self.heroes = {}
    self.towers = {}
    self.enemies = {}
    self.projectiles = {}
    self.resources = 200
    self.lives = 20
    self.wave = 0
    self.waveInProgress = false
    self.currentHero = nil
    self.selectedFaction = nil
    self.selectedTower = nil
    self.placingTower = false
    self.gameOver = false
    self.victory = false
    
    -- UI properties
    self.buttons = {}
    self.tooltip = nil
    self.waveTimer = 0
    self.waveDelay = 30
    
    -- Timer for game events
    self.timer = Timer.new()
    
    return self
end

function GameState:init(selectedFaction, selectedHero)
    self.map = nil
    self.grid = nil
    self.tileSize = 32
    self.selectedFaction = selectedFaction or "human"
    self.selectedHero = selectedHero
    self.resources = 200
    self.lives = 20
    self.wave = 0
    self.maxWaves = 10
    self.waveInProgress = false
    self.gameOver = false
    self.towers = {}
    self.enemies = {}
    self.projectiles = {}
    self.effects = {} -- Add effects array
    self.selectedTower = nil
    self.towerPreview = nil
    self.towerData = {}
    self.enemySpawnTimer = 0
    self.enemySpawnDelay = 1.5
    self.waveEnemies = {}
    self.tooltip = nil
    self.errorMessages = {}
    
    -- Set default fonts if global fonts are not available
    if not gFonts then
        self.fonts = {
            small = love.graphics.newFont(12),
            medium = love.graphics.newFont(18),
            large = love.graphics.newFont(24),
            title = love.graphics.newFont(36)
        }
    else
        self.fonts = gFonts
    end
    
    -- Load map
    self:loadMap("level1")
    
    -- Load tower data
    self:loadTowerData()
    
    -- Initialize UI
    self:initUI()
    
    -- Initialize enemy system
    require("systems.enemy").init()
    
    -- Initialize tower system
    require("systems.tower").init()
end

function GameState:initMap()
    local success, result = Error.pcall(function()
        local Map = require('systems.map')
        self.map = Map.new('map1')
        
        -- Add fallback rendering if map fails to load properly
        if not self.map or not self.map.map then
            -- Create a default grid-based map
            self:createDefaultMap()
        end
    end)
    
    if not success then
        Error.handle(Error.TYPES.SYSTEM, "MAP_LOAD_FAILED", tostring(result))
        -- Create a default map as fallback
        self:createDefaultMap()
    end
end

function GameState:createDefaultMap()
    print("Creating default map as fallback")
    self.useDefaultMap = true
    self.defaultMapData = {
        gridSize = 32,
        width = 30,
        height = 20,
        towerSpots = {
            {x = 160, y = 96, width = 32, height = 32},
            {x = 160, y = 352, width = 32, height = 32},
            {x = 768, y = 96, width = 32, height = 32},
            {x = 768, y = 352, width = 32, height = 32}
        },
        waypoints = {
            {x = 0, y = 224, order = 1},
            {x = 464, y = 224, order = 2},
            {x = 960, y = 224, order = 3}
        },
        spawnPoints = {
            {x = 0, y = 224, type = "default"}
        },
        exitPoints = {
            {x = 960, y = 224}
        },
        pathArea = {
            x = 224, y = 192, width = 512, height = 64
        }
    }
    
    -- Add methods to default map
    self.map = {
        draw = function()
            self:drawDefaultMap()
        end,
        update = function(_, dt)
            -- Nothing to update in default map
        end,
        worldToGrid = function(_, x, y)
            return math.floor(x / self.defaultMapData.gridSize) + 1, 
                   math.floor(y / self.defaultMapData.gridSize) + 1
        end,
        gridToWorld = function(_, gridX, gridY)
            return (gridX - 0.5) * self.defaultMapData.gridSize, 
                   (gridY - 0.5) * self.defaultMapData.gridSize
        end,
        canPlaceTower = function(_, gridX, gridY)
            local worldX = (gridX - 0.5) * self.defaultMapData.gridSize
            local worldY = (gridY - 0.5) * self.defaultMapData.gridSize
            
            -- Check if position is on a tower spot
            for _, spot in ipairs(self.defaultMapData.towerSpots) do
                if worldX >= spot.x and worldX < spot.x + spot.width and
                   worldY >= spot.y and worldY < spot.y + spot.height then
                    return true
                end
            end
            
            -- Check if not on path
            local path = self.defaultMapData.pathArea
            if worldX >= path.x and worldX < path.x + path.width and
               worldY >= path.y and worldY < path.y + path.height then
                return false
            end
            
            return false
        end,
        getSpawnPoint = function(_, type)
            for _, point in ipairs(self.defaultMapData.spawnPoints) do
                if point.type == type then
                    return point.x, point.y
                end
            end
            return self.defaultMapData.spawnPoints[1].x, self.defaultMapData.spawnPoints[1].y
        end,
        getExitPoint = function(_)
            return self.defaultMapData.exitPoints[1].x, self.defaultMapData.exitPoints[1].y
        end,
        getWaypoints = function(_)
            return self.defaultMapData.waypoints
        end,
        findPath = function(_, startX, startY, endX, endY)
            -- Simple direct path through waypoints
            local path = {}
            for _, waypoint in ipairs(self.defaultMapData.waypoints) do
                table.insert(path, {x = waypoint.x, y = waypoint.y})
            end
            return path
        end
    }
end

function GameState:drawDefaultMap()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, 
        self.defaultMapData.width * self.defaultMapData.gridSize, 
        self.defaultMapData.height * self.defaultMapData.gridSize)
    
    -- Draw grass border
    love.graphics.setColor(0.2, 0.5, 0.2, 1)
    love.graphics.rectangle("fill", 
        32, 32, 
        (self.defaultMapData.width - 2) * self.defaultMapData.gridSize, 
        (self.defaultMapData.height - 2) * self.defaultMapData.gridSize)
    
    -- Draw path
    love.graphics.setColor(0.6, 0.5, 0.3, 1)
    local path = self.defaultMapData.pathArea
    love.graphics.rectangle("fill", path.x, path.y, path.width, path.height)
    
    -- Draw tower spots
    love.graphics.setColor(0.3, 0.3, 0.6, 1)
    for _, spot in ipairs(self.defaultMapData.towerSpots) do
        love.graphics.rectangle("fill", spot.x, spot.y, spot.width, spot.height)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function GameState:initHero(selectedHero)
    local success, result = Error.pcall(function()
        local Hero = require('systems.hero')
        self.currentHero = Hero.create(selectedHero, self.selectedFaction)
        table.insert(self.heroes, self.currentHero)
    end)
    
    if not success then
        Error.show("Failed to create hero: " .. tostring(result))
    end
end

function GameState:initUI()
    -- Create UI layout
    self.ui = {}
    
    -- Resources display
    self.ui.resources = {
        x = 10,
        y = 10,
        width = 150,
        height = 30,
        draw = function()
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.ui.resources.x, self.ui.resources.y, self.ui.resources.width, self.ui.resources.height)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.medium)
            love.graphics.print("Gold: " .. self.resources, self.ui.resources.x + 10, self.ui.resources.y + 5)
        end
    }
    
    -- Lives display
    self.ui.lives = {
        x = 170,
        y = 10,
        width = 150,
        height = 30,
        draw = function()
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.ui.lives.x, self.ui.lives.y, self.ui.lives.width, self.ui.lives.height)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.medium)
            love.graphics.print("Lives: " .. self.lives, self.ui.lives.x + 10, self.ui.lives.y + 5)
        end
    }
    
    -- Wave display
    self.ui.wave = {
        x = 330,
        y = 10,
        width = 240,
        height = 30,
        draw = function()
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.ui.wave.x, self.ui.wave.y, self.ui.wave.width, self.ui.wave.height)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.medium)
            
            local text
            if self.waveInProgress then
                text = "Wave " .. self.wave .. " in progress"
            else
                text = "Wave " .. self.wave .. "/" .. self.maxWaves
            end
            
            love.graphics.print(text, self.ui.wave.x + 10, self.ui.wave.y + 5)
        end
    }
    
    -- Start wave button
    self.ui.startWave = {
        x = 580,
        y = 10,
        width = 110,
        height = 30,
        enabled = true,
        draw = function()
            if not self.waveInProgress and self.wave < self.maxWaves then
                local hover = self:isMouseOver(self.ui.startWave)
                
                if hover then
                    love.graphics.setColor(0.4, 0.7, 0.4, 0.9)
                else
                    love.graphics.setColor(0.2, 0.5, 0.2, 0.8)
                end
                
                love.graphics.rectangle("fill", self.ui.startWave.x, self.ui.startWave.y, self.ui.startWave.width, self.ui.startWave.height)
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", self.ui.startWave.x, self.ui.startWave.y, self.ui.startWave.width, self.ui.startWave.height)
                
                love.graphics.setFont(self.fonts.medium)
                local text = "Start Wave"
                local textW = self.fonts.medium:getWidth(text)
                love.graphics.print(text, self.ui.startWave.x + self.ui.startWave.width/2 - textW/2, self.ui.startWave.y + 5)
            else
                love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
                love.graphics.rectangle("fill", self.ui.startWave.x, self.ui.startWave.y, self.ui.startWave.width, self.ui.startWave.height)
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                love.graphics.rectangle("line", self.ui.startWave.x, self.ui.startWave.y, self.ui.startWave.width, self.ui.startWave.height)
                
                love.graphics.setFont(self.fonts.medium)
                local text = "In Progress"
                local textW = self.fonts.medium:getWidth(text)
                love.graphics.print(text, self.ui.startWave.x + self.ui.startWave.width/2 - textW/2, self.ui.startWave.y + 5)
            end
        end,
        onClick = function()
            if not self.waveInProgress and self.wave < self.maxWaves then
                self:startNextWave()
            end
        end
    }
    
    -- Tower panel
    self.ui.towerPanel = {
        x = 600,
        y = 50,
        width = 190,
        height = 500,
        draw = function()
            -- Draw panel background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.ui.towerPanel.x, self.ui.towerPanel.y, self.ui.towerPanel.width, self.ui.towerPanel.height)
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("line", self.ui.towerPanel.x, self.ui.towerPanel.y, self.ui.towerPanel.width, self.ui.towerPanel.height)
            
            -- Draw header
            love.graphics.setColor(0.4, 0.4, 0.6, 1)
            love.graphics.rectangle("fill", self.ui.towerPanel.x, self.ui.towerPanel.y, self.ui.towerPanel.width, 30)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.medium)
            local title = "Towers"
            local titleW = self.fonts.medium:getWidth(title)
            love.graphics.print(title, self.ui.towerPanel.x + self.ui.towerPanel.width/2 - titleW/2, self.ui.towerPanel.y + 5)
            
            -- Draw tower buttons
            local y = self.ui.towerPanel.y + 40
            
            -- Create a button for each tower type
            for id, tower in pairs(self.towerData) do
                local hover = self:isMouseOver({
                    x = self.ui.towerPanel.x + 10,
                    y = y,
                    width = self.ui.towerPanel.width - 20,
                    height = 60
                })
                
                local selected = self.selectedTower == id
                
                -- Draw button background
                if selected then
                    love.graphics.setColor(0.4, 0.6, 0.4, 1)
                elseif hover then
                    love.graphics.setColor(0.3, 0.5, 0.3, 0.9)
                else
                    love.graphics.setColor(0.2, 0.3, 0.4, 0.8)
                end
                
                love.graphics.rectangle("fill", self.ui.towerPanel.x + 10, y, self.ui.towerPanel.width - 20, 60)
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
                love.graphics.rectangle("line", self.ui.towerPanel.x + 10, y, self.ui.towerPanel.width - 20, 60)
                
                -- Draw tower icon
                love.graphics.setColor(1, 1, 1)
                local sprite = require("systems.tower").sprites[id]
                if sprite then
                    love.graphics.draw(sprite, self.ui.towerPanel.x + 25, y + 15)
                else
                    -- Fallback to a colored rectangle
                    love.graphics.setColor(0.5, 0.5, 0.7)
                    love.graphics.rectangle("fill", self.ui.towerPanel.x + 20, y + 10, 32, 32)
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.rectangle("line", self.ui.towerPanel.x + 20, y + 10, 32, 32)
                    love.graphics.setColor(1, 1, 1)
                end
                
                -- Draw tower info
                love.graphics.setFont(self.fonts.small)
                love.graphics.print(tower.name, self.ui.towerPanel.x + 60, y + 12)
                love.graphics.print("Cost: " .. tower.cost, self.ui.towerPanel.x + 60, y + 30)
                
                -- Check if affordable
                if tower.cost > self.resources then
                    love.graphics.setColor(1, 0, 0, 0.7)
                    love.graphics.rectangle("fill", self.ui.towerPanel.x + 10, y, self.ui.towerPanel.width - 20, 60)
                end
                
                -- Set tooltip on hover
                if hover then
                    self.tooltip = {
                        x = love.mouse.getX() + 15,
                        y = love.mouse.getY(),
                        width = 250,
                        title = tower.name,
                        description = tower.description,
                        stats = {
                            { name = "Damage", value = tower.damage },
                            { name = "Range", value = tower.range },
                            { name = "Speed", value = "1 shot / " .. tower.attackSpeed .. "s" }
                        }
                    }
                end
                
                -- Assign button click handler
                if self:isMouseClicked() and hover then
                    if tower.cost <= self.resources then
                        if self.selectedTower == id then
                            self.selectedTower = nil
                            self.towerPreview = nil
                        else
                            self.selectedTower = id
                            self.towerPreview = {
                                type = id,
                                gridX = 0,
                                gridY = 0,
                                x = 0,
                                y = 0,
                                range = tower.range,
                                canPlace = false
                            }
                        end
                    else
                        self:showError("Not enough resources!")
                    end
                end
                
                y = y + 70
            end
        end
    }
    
    -- Update function for UI
    self.ui.update = function(_, dt)
        -- Nothing to update in the UI currently
    end
    
    -- Draw function for UI
    self.ui.draw = function()
        -- Draw all UI elements
        self.ui.resources.draw()
        self.ui.lives.draw()
        self.ui.wave.draw()
        self.ui.startWave.draw()
        self.ui.towerPanel.draw()
    end
end

function GameState:loadTowerData()
    local Tower = require("systems.tower")
    local faction = self.selectedFaction or "human"
    
    -- Initialize tower system if needed
    if not Tower.initialized then
        Tower.init()
    end
    
    -- Get towers for selected faction
    if faction == "human" then
        self.towerData = Tower.HUMAN
    elseif faction == "elf" then
        self.towerData = Tower.ELF
    elseif faction == "dwarf" then
        self.towerData = Tower.DWARF
    else
        self:showError("Invalid faction selected: " .. tostring(faction))
        self.towerData = Tower.HUMAN  -- Fallback to human
    end
end

function GameState:enter(previous, faction, hero)
    if faction and hero then
        self:init(faction, hero)
    end
    
    -- Initialize auto-save
    local success, result = Error.pcall(function()
        local Save = require('systems.save')
        if Save and Save.autoSave then
            Save.autoSave()
        end
    end)
    
    if not success then
        Error.show("Auto-save initialization failed: " .. tostring(result))
    end
end

function GameState:update(dt)
    if self.gameOver then return end
    
    -- Update error messages
    self:updateErrorMessages(dt)
    
    -- Update UI
    self.ui:update(dt)
    
    -- Update towers
    for _, tower in ipairs(self.towers) do
        tower:update(dt, self.enemies)
    end
    
    -- Update enemies
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        enemy:update(dt)
        
        -- Check if enemy reached the end
        if enemy.state == "attacking" then
            self.lives = self.lives - enemy.damage
            table.remove(self.enemies, i)
            
            -- Check game over condition
            if self.lives <= 0 then
                self:gameOver(false)
                return
            end
        elseif enemy.removed then
            -- Enemy was killed, add resources
            self.resources = self.resources + enemy.value
            table.remove(self.enemies, i)
        end
    end
    
    -- Update projectiles
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]
        local result = projectile:update(dt, self.enemies)
        
        if result.hit or result.expired then
            table.remove(self.projectiles, i)
        end
    end
    
    -- Update effects
    for i = #self.effects, 1, -1 do
        local effect = self.effects[i]
        effect:update(dt)
        
        if effect.done then
            table.remove(self.effects, i)
        end
    end
    
    -- Handle wave logic
    if self.waveInProgress then
        -- Spawn enemies
        if #self.waveEnemies > 0 then
            self.enemySpawnTimer = self.enemySpawnTimer + dt
            
            if self.enemySpawnTimer >= self.enemySpawnDelay then
                self:spawnEnemy()
                self.enemySpawnTimer = 0
            end
        end
        
        -- Check if wave is complete
        if #self.waveEnemies == 0 and #self.enemies == 0 then
            self.waveInProgress = false
            
            -- Check if all waves complete
            if self.wave >= self.maxWaves then
                self:gameOver(true)
            end
        end
    end
    
    -- Update tower preview
    if self.towerPreview then
        local mouseX, mouseY = love.mouse.getPosition()
        local gridX, gridY = self:pixelToGrid(mouseX, mouseY)
        
        self.towerPreview.gridX = gridX
        self.towerPreview.gridY = gridY
        self.towerPreview.x = gridX * self.tileSize
        self.towerPreview.y = gridY * self.tileSize
        self.towerPreview.canPlace = self:canPlaceTower(gridX, gridY)
    end
end

function GameState:startNextWave()
    if self.waveInProgress then return end
    
    self.wave = self.wave + 1
    self.waveInProgress = true
    
    -- Generate wave enemies
    self.waveEnemies = self:generateWaveEnemies(self.wave)
    self.enemySpawnTimer = 0
end

function GameState:generateWaveEnemies(waveNumber)
    local waveEnemies = {}
    local baseCount = 5 + math.floor(waveNumber * 1.5)
    local types = {"zombie", "skeleton", "orc"}
    
    -- Add special enemies for later waves
    if waveNumber >= 5 then
        table.insert(types, "necromancer")
    end
    
    if waveNumber >= 8 then
        table.insert(types, "dragon")
    end
    
    -- Add enemies to wave
    for i = 1, baseCount do
        -- Distribute enemy types based on wave number
        local typeIndex
        if i == baseCount and waveNumber >= 8 then
            -- Boss enemy at the end
            typeIndex = #types
        else
            typeIndex = math.min(math.ceil(i / 3), #types)
        end
        
        table.insert(waveEnemies, types[typeIndex])
    end
    
    return waveEnemies
end

function GameState:spawnEnemy()
    if #self.waveEnemies == 0 then return end
    
    -- Get enemy type from queue
    local enemyType = table.remove(self.waveEnemies, 1)
    
    -- Find path from start to end
    local path = require("systems.enemy").findPath(self.startX, self.startY, self.endX, self.endY)
    
    -- Create enemy
    local enemy = require("systems.enemy").create(enemyType, path, self.tileSize)
    
    -- Add enemy to game
    if enemy then
        table.insert(self.enemies, enemy)
    end
end

function GameState:draw()
    -- Draw map
    if self.map then
        love.graphics.setColor(1, 1, 1)
        -- Draw the background
        love.graphics.setColor(0.3, 0.7, 0.3)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        
        -- Draw the path
        love.graphics.setColor(0.8, 0.7, 0.5)
        for y = 1, #self.grid do
            for x = 1, #self.grid[1] do
                if self.grid[y][x] == 0 then
                    love.graphics.rectangle("fill", (x-1) * self.tileSize, (y-1) * self.tileSize, self.tileSize, self.tileSize)
                end
            end
        end
        
        -- Draw tower placement tiles
        love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
        for y = 1, #self.grid do
            for x = 1, #self.grid[1] do
                if self.grid[y][x] == 1 then
                    love.graphics.rectangle("fill", (x-1) * self.tileSize, (y-1) * self.tileSize, self.tileSize, self.tileSize)
                end
            end
        end
        
        -- Draw tower placement grid
        love.graphics.setColor(0.5, 0.5, 0.5, 0.2)
        for y = 1, #self.grid do
            for x = 1, #self.grid[1] do
                love.graphics.rectangle("line", (x-1) * self.tileSize, (y-1) * self.tileSize, self.tileSize, self.tileSize)
            end
        end
    end
    
    -- Draw towers
    for _, tower in ipairs(self.towers) do
        tower:draw()
    end
    
    -- Draw enemies
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    
    -- Draw projectiles
    for _, projectile in ipairs(self.projectiles) do
        projectile:draw()
    end
    
    -- Draw effects
    for _, effect in ipairs(self.effects) do
        effect:draw()
    end
    
    -- Draw tower preview
    if self.towerPreview then
        if self.towerPreview.canPlace then
            love.graphics.setColor(0, 1, 0, 0.5)
        else
            love.graphics.setColor(1, 0, 0, 0.5)
        end
        
        love.graphics.rectangle("fill", self.towerPreview.x, self.towerPreview.y, self.tileSize, self.tileSize)
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("line", self.towerPreview.x + self.tileSize/2, self.towerPreview.y + self.tileSize/2, self.towerPreview.range)
    end
    
    -- Draw UI
    self.ui:draw()
    
    -- Draw tooltip
    if self.tooltip then
        self:drawTooltip()
    end
    
    -- Draw error messages
    self:drawErrorMessages()
    
    -- Draw game over overlay
    if self.gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.title)
        local text = self.victory and "VICTORY!" or "GAME OVER"
        local textW = self.fonts.title:getWidth(text)
        love.graphics.print(text, love.graphics.getWidth()/2 - textW/2, love.graphics.getHeight()/2 - 50)
    end
end

function GameState:placeTower(gridX, gridY, type)
    -- Check if tower can be placed
    if not self:canPlaceTower(gridX, gridY) then
        return false
    end
    
    -- Get tower data
    local towerData = self.towerData[type]
    if not towerData then
        self:showError("Invalid tower type: " .. tostring(type))
        return false
    end
    
    -- Check if we have enough resources
    if self.resources < towerData.cost then
        self:showError("Not enough resources!")
        return false
    end
    
    -- Deduct resources
    self.resources = self.resources - towerData.cost
    
    -- Create tower
    local Tower = require("systems.tower")
    local tower = Tower.create(type, gridX, gridY, self.tileSize)
    
    -- Add tower to the game
    table.insert(self.towers, tower)
    
    -- Update grid to mark as occupied
    self.grid[gridY][gridX] = 2
    
    return true
end

function GameState:canPlaceTower(gridX, gridY)
    -- Check if coordinates are within grid bounds
    if gridX < 1 or gridY < 1 or gridX > #self.grid[1] or gridY > #self.grid then
        return false
    end
    
    -- Check if the grid cell is a tower placement cell and not occupied
    return self.grid[gridY][gridX] == 1
end

function GameState:pixelToGrid(pixelX, pixelY)
    local gridX = math.floor(pixelX / self.tileSize) + 1
    local gridY = math.floor(pixelY / self.tileSize) + 1
    return gridX, gridY
end

function GameState:loadMap(mapName)
    -- For now, create a sample map
    local gridWidth = 24
    local gridHeight = 18
    
    -- Initialize grid with all cells set to 1 (tower placement)
    self.grid = {}
    for y = 1, gridHeight do
        self.grid[y] = {}
        for x = 1, gridWidth do
            self.grid[y][x] = 1 -- Default to tower placement
        end
    end
    
    -- Define the path (0 = path, 1 = tower placement, 2 = occupied)
    local path = {
        {1, 1}, {2, 1}, {3, 1}, {4, 1}, {5, 1}, {6, 1}, {7, 1}, {8, 1},
        {8, 2}, {8, 3}, {8, 4}, {8, 5}, {8, 6}, {8, 7}, {8, 8},
        {9, 8}, {10, 8}, {11, 8}, {12, 8}, {13, 8}, {14, 8},
        {14, 7}, {14, 6}, {14, 5}, {14, 4}, {14, 3},
        {15, 3}, {16, 3}, {17, 3}, {18, 3},
        {18, 4}, {18, 5}, {18, 6}, {18, 7}, {18, 8}, {18, 9}, {18, 10}, {18, 11}, {18, 12},
        {17, 12}, {16, 12}, {15, 12}, {14, 12}, {13, 12}, {12, 12}, {11, 12}, {10, 12}, {9, 12}, {8, 12}, {7, 12}, {6, 12}, {5, 12}, {4, 12},
        {4, 13}, {4, 14}, {4, 15}, {4, 16}, {4, 17},
        {5, 17}, {6, 17}, {7, 17}, {8, 17}, {9, 17}, {10, 17}, {11, 17}, {12, 17}, {13, 17}, {14, 17}, {15, 17}, {16, 17}, {17, 17}, {18, 17}
    }
    
    -- Mark path cells in the grid
    for _, point in ipairs(path) do
        self.grid[point[2]][point[1]] = 0 -- Path
    end
    
    -- Set start and end points
    self.startX, self.startY = 1, 1
    self.endX, self.endY = 18, 17
    
    -- Set up enemy pathfinder
    require("systems.enemy").setPathfinder(self.grid, 0)
end

function GameState:gameOver(victory)
    self.gameOver = true
    self.victory = victory
    
    -- Play sound effect
    if victory then
        -- Play victory sound
        -- self.sounds.victory:play()
    else
        -- Play defeat sound
        -- self.sounds.defeat:play()
    end
    
    -- Unlock achievements
    if victory then
        -- Unlock achievement for completing the game
        -- Achievement.unlock("complete_game")
    end
    
    -- Save game state
    require("systems.save").saveGameState({
        victory = victory,
        wave = self.wave,
        resources = self.resources,
        lives = self.lives,
        towerCount = #self.towers,
        faction = self.selectedFaction,
        hero = self.selectedHero
    })
    
    -- Show game over dialog
    local text = victory and "Victory! You have successfully defended your base!" or
                  "Game Over! Your base has been destroyed!"
    
    -- TODO: Replace with proper dialog
    print(text)
end

function GameState:isMouseOver(element)
    local mx, my = love.mouse.getPosition()
    return mx >= element.x and mx <= element.x + element.width and
           my >= element.y and my <= element.y + element.height
end

function GameState:isMouseClicked()
    return love.mouse.isDown(1)
end

function GameState:drawTooltip()
    if not self.tooltip then return end
    
    local tooltip = self.tooltip
    local padding = 10
    local width = tooltip.width or 200
    local height = 120 + (#tooltip.stats or 0) * 20
    
    -- Adjust position if off screen
    local x = tooltip.x
    local y = tooltip.y
    if x + width > love.graphics.getWidth() then
        x = love.graphics.getWidth() - width - padding
    end
    if y + height > love.graphics.getHeight() then
        y = love.graphics.getHeight() - height - padding
    end
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.print(tooltip.title, x + padding, y + padding)
    
    -- Draw description
    love.graphics.setFont(self.fonts.small)
    love.graphics.printf(tooltip.description, x + padding, y + padding + 30, width - padding * 2)
    
    -- Draw stats
    if tooltip.stats then
        local statsY = y + padding + 70
        for _, stat in ipairs(tooltip.stats) do
            love.graphics.print(stat.name .. ": " .. stat.value, x + padding, statsY)
            statsY = statsY + 20
        end
    end
    
    -- Reset tooltip
    self.tooltip = nil
end

function GameState:showError(message)
    table.insert(self.errorMessages, {
        message = message,
        timer = 3 -- Show for 3 seconds
    })
end

function GameState:updateErrorMessages(dt)
    for i = #self.errorMessages, 1, -1 do
        local error = self.errorMessages[i]
        error.timer = error.timer - dt
        
        if error.timer <= 0 then
            table.remove(self.errorMessages, i)
        end
    end
end

function GameState:drawErrorMessages()
    local y = 50
    
    love.graphics.setFont(self.fonts.small)
    
    for _, error in ipairs(self.errorMessages) do
        local alpha = math.min(1, error.timer)
        love.graphics.setColor(1, 0, 0, alpha)
        
        local textW = self.fonts.small:getWidth(error.message)
        love.graphics.print(error.message, love.graphics.getWidth()/2 - textW/2, y)
        
        y = y + 25
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

return GameState 