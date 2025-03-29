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
    self.selectedFaction = selectedFaction
    
    -- Initialize required systems
    self:initMap()
    self:initHero(selectedHero)
    self:initUI()
    
    -- Load tower data for the selected faction
    self:loadTowerData()
    
    -- Set up first wave
    self.wave = 0
    self.waveTimer = self.waveDelay
    
    -- Start background music
    playSound('music', 'gameplay')
end

function GameState:initMap()
    local success, result = Error.pcall(function()
        self.map = require('systems.map').new('map1')
    end)
    
    if not success then
        Error.show("Failed to load map: " .. tostring(result))
    end
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
    -- Create UI buttons
    self.buttons = {
        nextWave = {
            text = "Start Wave",
            x = love.graphics.getWidth() - 150,
            y = 20,
            width = 130,
            height = 40,
            hovered = false,
            action = function() self:startNextWave() end
        },
        pause = {
            text = "Pause",
            x = love.graphics.getWidth() - 150,
            y = 70,
            width = 130,
            height = 40,
            hovered = false,
            action = function() Gamestate.push(require('states.pause').new(self)) end
        }
    }
    
    -- Create tower buttons
    self.towerButtons = {}
    for i, tower in ipairs(self.towerData or {}) do
        table.insert(self.towerButtons, {
            text = tower.name,
            description = tower.description,
            cost = tower.cost,
            x = 20,
            y = 100 + (i-1) * 60,
            width = 120,
            height = 50,
            hovered = false,
            towerType = tower.id,
            action = function() self:selectTower(tower.id) end
        })
    end
end

function GameState:loadTowerData()
    local success, result = Error.pcall(function()
        local Tower = require('systems.tower')
        self.towerData = Tower.getTowersByFaction(self.selectedFaction)
    end)
    
    if not success then
        Error.show("Failed to load tower data: " .. tostring(result))
        self.towerData = {}
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
    -- Update error notifications
    Error.update(dt)
    
    -- Don't update game logic if game is over
    if self.gameOver then return end
    
    -- Update timers
    self.timer:update(dt)
    
    -- Update wave timer if wave is not in progress
    if not self.waveInProgress then
        self.waveTimer = math.max(0, self.waveTimer - dt)
        if self.waveTimer <= 0 then
            self:startNextWave()
        end
    end
    
    -- Update map
    if self.map and self.map.update then
        self.map:update(dt)
    end
    
    -- Update hero
    for _, hero in ipairs(self.heroes) do
        if hero.update then
            hero:update(dt, self)
        end
    end
    
    -- Update towers
    for _, tower in ipairs(self.towers) do
        if tower.update then
            tower:update(dt, self)
        end
    end
    
    -- Update enemies
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if enemy.update then
            enemy:update(dt, self)
        end
        
        -- Check if enemy reached the end
        if enemy.reachedEnd then
            self.lives = self.lives - enemy.damage
            table.remove(self.enemies, i)
            playSound('sfx', 'lifeLost')
            
            -- Check game over
            if self.lives <= 0 then
                self:gameOver(false)
            end
        elseif enemy.dead then
            self.resources = self.resources + enemy.reward
            table.remove(self.enemies, i)
        end
    end
    
    -- Update projectiles
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]
        if projectile.update then
            projectile:update(dt, self)
        end
        
        if projectile.destroyed then
            table.remove(self.projectiles, i)
        end
    end
    
    -- Check if wave is complete
    if self.waveInProgress and #self.enemies == 0 then
        self.waveInProgress = false
        self.waveTimer = self.waveDelay
        
        -- Award completion bonus
        local waveBonus = 50 + self.wave * 10
        self.resources = self.resources + waveBonus
        
        -- Check for victory conditions
        if self.wave >= 20 then
            self:gameOver(true)
        end
        
        -- Unlock achievement if appropriate
        local Achievement = require('systems.achievement')
        if Achievement and Achievement.unlock then
            if self.lives == 20 then  -- No lives lost
                Achievement.unlock("perfect_wave")
            end
            
            if self.wave >= 5 then
                Achievement.unlock("wave_survivor")
            end
            
            if self.resources >= 1000 then
                Achievement.unlock("resource_king")
            end
        end
        
        -- Auto-save after completing wave
        local Save = require('systems.save')
        if Save and Save.autoSave then
            Save.autoSave()
        end
    end
end

function GameState:startNextWave()
    if self.waveInProgress or self.gameOver then return end
    
    self.wave = self.wave + 1
    self.waveInProgress = true
    
    -- Spawn enemies for this wave
    self:spawnWaveEnemies()
    
    -- Play sound effect
    playSound('sfx', 'waveStart')
    
    -- Update next wave button
    self.buttons.nextWave.text = "Wave " .. self.wave .. " in progress"
end

function GameState:spawnWaveEnemies()
    local success, result = Error.pcall(function()
        local Wave = require('systems.wave')
        local enemies = Wave.generateWave(self.wave, self.selectedFaction)
        
        -- Schedule enemy spawning
        local spawnDelay = 0
        for _, enemyData in ipairs(enemies) do
            self.timer:after(spawnDelay, function()
                local Enemy = require('systems.enemy')
                local enemy = Enemy.create(enemyData.type, self.map:getEnemyStartPosition())
                enemy.health = enemyData.health
                enemy.speed = enemyData.speed
                enemy.damage = enemyData.damage
                enemy.reward = enemyData.reward
                table.insert(self.enemies, enemy)
            end)
            spawnDelay = spawnDelay + enemyData.spawnDelay
        end
    end)
    
    if not success then
        Error.show("Failed to spawn wave: " .. tostring(result))
    end
end

function GameState:selectTower(towerType)
    if self.resources < self:getTowerCost(towerType) then
        Error.show("Not enough resources!")
        playSound('sfx', 'error')
        return
    end
    
    self.selectedTower = towerType
    self.placingTower = true
    
    -- Play sound effect
    playSound('sfx', 'towerSelect')
end

function GameState:getTowerCost(towerType)
    for _, tower in ipairs(self.towerData or {}) do
        if tower.id == towerType then
            return tower.cost
        end
    end
    return 0
end

function GameState:placeTower(x, y)
    if not self.placingTower or not self.selectedTower then return end
    
    local success, result = Error.pcall(function()
        local gridX, gridY = self.map:worldToGrid(x, y)
        
        -- Check if tower can be placed here
        if not self.map:canPlaceTower(gridX, gridY) then
            Error.show("Cannot place tower here!")
            return false
        end
        
        -- Check if there's already a tower here
        for _, tower in ipairs(self.towers) do
            if tower.gridX == gridX and tower.gridY == gridY then
                Error.show("Tower already exists here!")
                return false
            end
        end
        
        -- Place the tower
        local Tower = require('systems.tower')
        local newTower = Tower.create(self.selectedTower, gridX, gridY)
        table.insert(self.towers, newTower)
        
        -- Update map
        self.map:placeTower(gridX, gridY)
        
        -- Deduct resources
        self.resources = self.resources - self:getTowerCost(self.selectedTower)
        
        -- Play sound effect
        playSound('sfx', 'towerPlace')
        
        return true
    end)
    
    if not success then
        Error.show("Failed to place tower: " .. tostring(result))
        return false
    end
    
    return result
end

function GameState:gameOver(victory)
    self.gameOver = true
    self.victory = victory
    
    -- Stop gameplay music and play appropriate music
    stopSound('music', 'gameplay')
    playSound('music', victory and 'victory' or 'gameOver')
    
    -- Unlock achievements
    local Achievement = require('systems.achievement')
    if Achievement and Achievement.unlock then
        if victory then
            Achievement.unlock("first_win")
            
            local factionAchievements = {
                human = "faction_human",
                elf = "faction_elf",
                dwarf = "faction_dwarf"
            }
            
            if factionAchievements[self.selectedFaction] then
                Achievement.unlock(factionAchievements[self.selectedFaction])
            end
        end
    end
    
    -- Save game state
    local Save = require('systems.save')
    if Save and Save.saveGame then
        Save.saveGame()
    end
    
    -- Display game over dialog after a delay
    self.timer:after(3, function()
        local dialog = {
            title = victory and "Victory!" or "Game Over",
            message = victory 
                and "Congratulations! You've completed all waves!" 
                or "You have been defeated!",
            buttons = {
                {
                    text = "Main Menu",
                    action = function()
                        local MenuState = require('states.menu')
                        Gamestate.switch(MenuState.new())
                    end
                },
                {
                    text = "Try Again",
                    action = function()
                        -- Create a new game state properly
                        local newGame = GameState.new()
                        -- Initialize it
                        newGame:init(self.selectedFaction, self.currentHero.type)
                        -- Then switch to it
                        Gamestate.switch(newGame)
                    end
                }
            }
        }
        
        -- TODO: Show dialog when UI dialog system is implemented
    end)
end

function GameState:draw()
    -- Draw map
    if self.map and self.map.draw then
        self.map:draw()
    end
    
    -- Draw grid (for debugging)
    --self:drawGrid()
    
    -- Draw towers
    for _, tower in ipairs(self.towers) do
        if tower.draw then
            tower:draw()
        end
    end
    
    -- Draw enemies
    for _, enemy in ipairs(self.enemies) do
        if enemy.draw then
            enemy:draw()
        end
    end
    
    -- Draw heroes
    for _, hero in ipairs(self.heroes) do
        if hero.draw then
            hero:draw()
        end
    end
    
    -- Draw projectiles
    for _, projectile in ipairs(self.projectiles) do
        if projectile.draw then
            projectile:draw()
        end
    end
    
    -- Draw tower placement preview
    if self.placingTower and self.selectedTower then
        local x, y = love.mouse.getPosition()
        local gridX, gridY = self.map:worldToGrid(x, y)
        local worldX, worldY = self.map:gridToWorld(gridX, gridY)
        
        -- Draw preview based on placement validity
        local canPlace = self.map:canPlaceTower(gridX, gridY)
        for _, tower in ipairs(self.towers) do
            if tower.gridX == gridX and tower.gridY == gridY then
                canPlace = false
                break
            end
        end
        
        love.graphics.setColor(canPlace and {0, 1, 0, 0.5} or {1, 0, 0, 0.5})
        love.graphics.rectangle("fill", worldX, worldY, self.map.tileSize, self.map.tileSize)
        love.graphics.setColor(1, 1, 1, 0.8)
        
        -- Draw tower preview
        local Tower = require('systems.tower')
        if Tower and Tower.drawPreview then
            Tower.drawPreview(self.selectedTower, worldX, worldY)
        end
    end
    
    -- Draw UI
    self:drawUI()
    
    -- Draw error notifications
    Error.draw()
    
    -- Draw game over screen
    if self.gameOver then
        self:drawGameOver()
    end
end

function GameState:drawUI()
    -- Draw resources and lives
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.main)
    
    -- Resources
    love.graphics.print("Resources: " .. self.resources, 20, 20)
    
    -- Lives
    love.graphics.print("Lives: " .. self.lives, 20, 50)
    
    -- Wave info
    local waveText = "Wave: " .. self.wave
    if not self.waveInProgress and not self.gameOver then
        waveText = waveText .. " (Next wave in " .. math.ceil(self.waveTimer) .. "s)"
    end
    love.graphics.print(waveText, 20, 80)
    
    -- Draw buttons
    for _, button in pairs(self.buttons) do
        love.graphics.setColor(button.hovered and {0.4, 0.4, 0.4, 0.8} or {0.2, 0.2, 0.2, 0.8})
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        
        love.graphics.setColor(1, 1, 1, 1)
        local textX = button.x + button.width / 2 - fonts.main:getWidth(button.text) / 2
        local textY = button.y + button.height / 2 - fonts.main:getHeight() / 2
        love.graphics.print(button.text, textX, textY)
    end
    
    -- Draw tower buttons
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 10, 150, 140, #self.towerButtons * 60 + 20)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.rectangle("line", 10, 150, 140, #self.towerButtons * 60 + 20)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Towers", 60, 160)
    
    for i, button in ipairs(self.towerButtons) do
        -- Determine if the player can afford this tower
        local canAfford = self.resources >= button.cost
        
        -- Button background
        if button.hovered then
            love.graphics.setColor(0.4, 0.4, 0.4, 0.8)
        elseif not canAfford then
            love.graphics.setColor(0.3, 0.2, 0.2, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        
        -- Button border
        love.graphics.setColor(canAfford and {0.7, 0.7, 0.7, 0.8} or {0.5, 0.3, 0.3, 0.8})
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        
        -- Button text
        love.graphics.setColor(canAfford and {1, 1, 1, 1} or {0.7, 0.5, 0.5, 1})
        love.graphics.print(button.text, button.x + 10, button.y + 10)
        love.graphics.print(button.cost, button.x + 10, button.y + 30)
        
        -- Draw tooltip if hovered
        if button.hovered then
            self:drawTooltip(button.description, love.mouse.getX(), love.mouse.getY())
        end
    end
    
    -- Draw hero abilities
    if self.currentHero and self.currentHero.abilities then
        local startX = love.graphics.getWidth() / 2 - (#self.currentHero.abilities * 55) / 2
        local y = love.graphics.getHeight() - 70
        
        for i, ability in ipairs(self.currentHero.abilities) do
            local x = startX + (i - 1) * 60
            
            -- Background
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", x, y, 50, 50)
            
            -- Border
            if ability.ready then
                love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
            else
                love.graphics.setColor(0.4, 0.4, 0.4, 0.8)
            end
            love.graphics.rectangle("line", x, y, 50, 50)
            
            -- Icon
            love.graphics.setColor(1, 1, 1, ability.ready and 1 or 0.5)
            if ability.icon then
                love.graphics.draw(ability.icon, x + 5, y + 5, 0, 0.4, 0.4)
            else
                love.graphics.rectangle("fill", x + 10, y + 10, 30, 30)
            end
            
            -- Cooldown text
            if not ability.ready and ability.cooldown > 0 then
                love.graphics.setColor(1, 1, 1, 1)
                local cooldownText = tostring(math.ceil(ability.cooldown))
                love.graphics.print(cooldownText, x + 25 - fonts.main:getWidth(cooldownText) / 2, y + 25 - fonts.main:getHeight() / 2)
            end
            
            -- Key binding
            love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
            local keyBinding = "Q W E R"
            local keyChar = keyBinding:sub(i*2-1, i*2-1)
            local keyWidth = fonts.small:getWidth(keyChar)
            love.graphics.setFont(fonts.small)
            love.graphics.print(keyChar, x + 50 - keyWidth - 3, y + 3)
            love.graphics.setFont(fonts.main)
        end
    end
    
    -- Draw current status (wave progress, etc.)
    if self.waveInProgress then
        local waveProgressText = "Wave " .. self.wave .. " in progress - Enemies: " .. #self.enemies
        local textWidth = fonts.main:getWidth(waveProgressText)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(waveProgressText, love.graphics.getWidth() / 2 - textWidth / 2, love.graphics.getHeight() - 30)
    end
end

function GameState:drawTooltip(text, x, y)
    if not text then return end
    
    love.graphics.setFont(fonts.small)
    local width = fonts.small:getWidth(text) + 20
    local height = fonts.small:getHeight() + 10
    
    -- Adjust position to keep tooltip on screen
    if x + width > love.graphics.getWidth() then
        x = love.graphics.getWidth() - width
    end
    if y + height > love.graphics.getHeight() then
        y = y - height
    end
    
    -- Draw tooltip background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw tooltip border
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw tooltip text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, x + 10, y + 5)
    
    -- Reset font
    love.graphics.setFont(fonts.main)
end

function GameState:drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    local title = self.victory and "Victory!" or "Game Over"
    love.graphics.setFont(fonts.title)
    love.graphics.setColor(1, 1, 1, 1)
    local titleWidth = fonts.title:getWidth(title)
    love.graphics.print(title, love.graphics.getWidth() / 2 - titleWidth / 2, love.graphics.getHeight() / 2 - 100)
    
    local message = self.victory 
        and "Congratulations! You've completed all waves!" 
        or "You have been defeated!"
    
    love.graphics.setFont(fonts.main)
    local messageWidth = fonts.main:getWidth(message)
    love.graphics.print(message, love.graphics.getWidth() / 2 - messageWidth / 2, love.graphics.getHeight() / 2 - 40)
    
    -- Stats
    local stats = {
        "Waves Completed: " .. self.wave,
        "Resources Collected: " .. self.resources,
        "Towers Built: " .. #self.towers
    }
    
    for i, stat in ipairs(stats) do
        local statWidth = fonts.main:getWidth(stat)
        love.graphics.print(stat, love.graphics.getWidth() / 2 - statWidth / 2, love.graphics.getHeight() / 2 + (i-1) * 30)
    end
end

function GameState:drawGrid()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
    
    for x = 0, self.map.width - 1 do
        for y = 0, self.map.height - 1 do
            local worldX, worldY = self.map:gridToWorld(x, y)
            love.graphics.rectangle("line", worldX, worldY, self.map.tileSize, self.map.tileSize)
        end
    end
end

function GameState:mousepressed(x, y, button)
    if button == 1 then
        -- Check UI buttons
        for _, btn in pairs(self.buttons) do
            if x >= btn.x and x <= btn.x + btn.width and 
               y >= btn.y and y <= btn.y + btn.height then
                if btn.action then btn.action() end
                return
            end
        end
        
        -- Check tower buttons
        for _, btn in ipairs(self.towerButtons) do
            if x >= btn.x and x <= btn.x + btn.width and 
               y >= btn.y and y <= btn.y + btn.height then
                if btn.action and self.resources >= btn.cost then
                    btn.action()
                else
                    playSound('sfx', 'error')
                end
                return
            end
        end
        
        -- Place tower if in placement mode
        if self.placingTower and self.selectedTower then
            if self:placeTower(x, y) then
                if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
                    -- Keep placement mode active if shift is held
                else
                    self.placingTower = false
                    self.selectedTower = nil
                end
            end
            return
        end
        
        -- Select tower for upgrade/info
        for _, tower in ipairs(self.towers) do
            if tower.gridX and tower.gridY then
                local worldX, worldY = self.map:gridToWorld(tower.gridX, tower.gridY)
                if x >= worldX and x <= worldX + self.map.tileSize and 
                   y >= worldY and y <= worldY + self.map.tileSize then
                    -- TODO: Show tower info/upgrade panel
                    return
                end
            end
        end
    elseif button == 2 then
        -- Cancel tower placement
        if self.placingTower then
            self.placingTower = false
            self.selectedTower = nil
            playSound('sfx', 'cancel')
        end
    end
end

function GameState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    for _, btn in pairs(self.buttons) do
        btn.hovered = x >= btn.x and x <= btn.x + btn.width and 
                      y >= btn.y and y <= btn.y + btn.height
    end
    
    for _, btn in ipairs(self.towerButtons) do
        btn.hovered = x >= btn.x and x <= btn.x + btn.width and 
                      y >= btn.y and y <= btn.y + btn.height
    end
end

function GameState:keypressed(key)
    -- Game controls
    if key == "escape" then
        if self.placingTower then
            self.placingTower = false
            self.selectedTower = nil
            playSound('sfx', 'cancel')
        else
            Gamestate.push(require('states.pause').new(self))
        end
    elseif key == "space" and not self.waveInProgress and not self.gameOver then
        self:startNextWave()
    end
    
    -- Hero abilities
    if self.currentHero and self.currentHero.abilities then
        local abilityKeys = {"q", "w", "e", "r"}
        for i, k in ipairs(abilityKeys) do
            if key == k and self.currentHero.abilities[i] and self.currentHero.abilities[i].ready then
                self.currentHero:useAbility(i, self)
                break
            end
        end
    end
    
    -- Tower selection hotkeys (1-9)
    local num = tonumber(key)
    if num and num >= 1 and num <= 9 and num <= #self.towerButtons then
        local tower = self.towerButtons[num]
        if tower and self.resources >= tower.cost then
            tower.action()
        else
            playSound('sfx', 'error')
        end
    end
end

function GameState:pauseGame()
    local pauseState = require('states.pause').new(self)
    Gamestate.push(pauseState)
end

local function createMainButton(text, x, y, width, height, action)
    return {
        text = text,
        x = x,
        y = y, 
        width = width,
        height = height,
        action = action,
        hovered = false
    }
end

function GameState:createUI()
    -- Create pause button
    local pauseButton = createMainButton(
        "Pause",
        love.graphics.getWidth() - 80, 10,
        70, 30,
        function()
            local pauseState = require('states.pause').new(self)
            Gamestate.push(pauseState)
        end
    )
end

return GameState 