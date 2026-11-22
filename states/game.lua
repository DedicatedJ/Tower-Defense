local GameState = {}
GameState.__index = GameState

-- The map is drawn this many pixels below the top of the window
GameState.MAP_OFFSET_Y = 40

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function GameState.new()
    local self = setmetatable({}, GameState)
    
    -- Game properties
    self.map = nil
    self.towers = {}
    self.enemies = {}
    self.projectiles = {}
    self.resources = 200
    self.lives = 20
    self.wave = 0
    self.waveInProgress = false
    self.selectedFaction = nil
    self.selectedTower = nil
    self.placingTower = false
    -- Not `gameOver`: an instance field with that name would shadow the
    -- GameState:gameOver() method and make every call to it crash.
    self.isGameOver = false
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

-- HUMP calls init() with no arguments the first time a state is switched to.
-- Callers that have real data call setup(...) before switching; init() only
-- fills in defaults when that didn't happen.
function GameState:init()
    if not self.isSetUp then
        self:setup()
    end
end

function GameState:setup(selectedFaction, selectedHero, levelId)
    self.isSetUp = true
    self.map = nil
    self.grid = nil
    self.tileSize = 32
    -- Canonical faction and hero records (data/factions.lua), whatever
    -- shape the caller passed (table, saved id or nothing)
    local Selection = require('utils.selection')
    self.factionData, self.heroData = Selection.canonical(selectedFaction, selectedHero)
    self.selectedFaction = self.factionData.id
    self.selectedHero = self.heroData.id
    -- The level: its map, waves, starting gold and lives (data/levels.lua).
    -- Without one, the faction's first level.
    local Level = require('systems.level')
    self.level = Level.get(levelId) or Level.first(self.factionData.id)
    self.levelId = self.level.id
    self.waves = require('systems.wave').plan(self.level)
    self.resources = self.level.startGold
    self.lives = self.level.lives
    self.startLives = self.level.lives
    self.wave = 0
    self.maxWaves = #self.waves
    self.waveInProgress = false
    -- Not `gameOver`: an instance field with that name would shadow the
    -- GameState:gameOver() method and make every call to it crash.
    self.isGameOver = false
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
    
    self.units = {}          -- allied units: the hero and minions
    self.hero = nil
    self.focusTower = nil    -- placed tower whose upgrade panel is open
    self.goldEarned = 0      -- gold from kills this game (for the profile)

    -- Load map
    self:loadMap(self.level)

    -- Faction bonus, hero passive and shop items
    self:computeMods()
    self.resources = self.resources + self.shop.startGold
    self.lives = self.lives + self.shop.startLives
    self.startLives = self.lives
    self.freezeCharge = self.shop.freezeDuration

    -- Load tower data
    self:loadTowerData()

    -- Initialize UI
    self:initUI()

    -- Initialize enemy system
    require("systems.enemy").init()

    -- Initialize tower system
    require("systems.tower").init()

    -- The hero takes the field
    self:spawnHero()
end

-- Multipliers from the faction bonus, the hero's passive and shop items.
--   mods       read by units (systems/unit.lua)
--   towerMods  passed to every tower (systems/tower.lua)
function GameState:computeMods()
    local Save = require('systems.save')
    local ShopItems = require('data.shop_items')
    local b = self.factionData.bonus or {}
    local p = self.heroData.passive or {}
    local ok, purchases = pcall(Save.getPurchases)
    self.shop = ShopItems.modsFor(ok and purchases or {}, true)
    if #self.shop.used > 0 then pcall(Save.useConsumables, self.shop.used) end

    self.mods = {
        abilityDurationMult = 1 + (b.abilityDuration or 0),
        heroHealingMult = 1 + (b.heroHealing or 0),
        minionHealthMult = 1 + (b.minionHealth or 0),
        minionDurationMult = (p.kind == "minionDuration") and p.mult or 1,
        allyArmorMult = (p.kind == "allyArmor") and p.mult or 1,
    }
    self.towerMods = {
        damageMult = (1 + (b.towerDamage or 0)) * self.shop.towerDamage,
        poisonMult = 1 + (b.poisonDamage or 0),
        hybridMult = (1 + (b.hybridDamage or 0)) * ((p.kind == "towerHybridDamage") and p.mult or 1),
        rangeMult = self.shop.towerRange,
        fireRateMult = self.shop.towerFireRate,
        towerStat = {},
    }
    if p.kind == "towerStat" then
        table.insert(self.towerMods.towerStat, { tower = p.tower, stat = p.stat, mult = p.mult, set = p.set })
    end
    self.heroStatMods = {
        damage = self.shop.heroDamage, health = self.shop.heroHealth, speed = self.shop.heroSpeed,
    }
end

------------------------------------------------------------------------
-- Map helpers used by units and towers (map coordinates, not screen)
------------------------------------------------------------------------
function GameState:isRoad(gx, gy)
    return self.grid and self.grid[gy] and self.grid[gy][gx] == 0 or false
end

function GameState:cellCenter(gx, gy)
    return (gx - 0.5) * self.tileSize, (gy - 0.5) * self.tileSize
end

-- Road cell nearest to a point
function GameState:nearestRoadCell(x, y)
    local best, bestD
    for _, c in ipairs(self.roadPath or {}) do
        local cx, cy = self:cellCenter(c[1], c[2])
        local d = (cx - x) ^ 2 + (cy - y) ^ 2
        if not bestD or d < bestD then best, bestD = c, d end
    end
    if best then return best[1], best[2] end
end

-- Road cell nearest to a point, but only within radius r
function GameState:nearestRoadCellWithin(x, y, r)
    local gx, gy = self:nearestRoadCell(x, y)
    if not gx then return nil end
    local cx, cy = self:cellCenter(gx, gy)
    if (cx - x) ^ 2 + (cy - y) ^ 2 <= r * r then return gx, gy end
end

------------------------------------------------------------------------
-- Units
------------------------------------------------------------------------
function GameState:spawnHero()
    local Unit = require('systems.unit')
    local Save = require('systems.save')
    local ok, progress = pcall(Save.getHeroProgress, self.heroData.id)
    if not ok then progress = { level = 1, xp = 0 } end
    -- Start a little past the middle of the road
    local road = self.paths[1]
    local cell = road[math.max(1, math.floor(#road * 0.6))]
    local x, y = self:cellCenter(cell.x, cell.y)
    self.hero = Unit.newHero(self.heroData, self.factionData, x, y, {
        level = progress.level, xp = progress.xp, statMods = self.heroStatMods,
    })
    self.hero.game = self
    table.insert(self.units, self.hero)
end

-- Add minions at a spot on the road. Returns the new units.
function GameState:spawnMinion(def, x, y, count)
    local Unit = require('systems.unit')
    local made = {}
    for i = 1, count or 1 do
        local jitter = (i - 1) * 10 - ((count or 1) - 1) * 5
        local m = Unit.newMinion(def, x + jitter, y, {
            healthMult = self.mods.minionHealthMult, durationMult = self.mods.minionDurationMult,
        })
        m.game = self
        table.insert(self.units, m)
        table.insert(made, m)
    end
    self.minionsSpawned = (self.minionsSpawned or 0) + #made
    return made
end

-- XP for the hero and Soul Forge conversion when an enemy dies
function GameState:onEnemyDeath(enemy)
    require('systems.audio').play("enemy_die")
    local Unit = require('systems.unit')
    local h = self.hero
    if h and not h.dead then
        local dx, dy = h.x - enemy.x, h.y - enemy.y
        if dx * dx + dy * dy <= Unit.XP_RADIUS * Unit.XP_RADIUS then
            h:gainXp(enemy.boss and 50 or 5)
        end
    end
    for _, t in ipairs(self.towers) do
        if t.convertChance then
            local tx, ty = t:getCenter()
            if (tx - enemy.x) ^ 2 + (ty - enemy.y) ^ 2 <= t.range * t.range
                and love.math.random() < t.convertChance and not enemy.flying then
                local def = {}
                for k, v in pairs(t.convertMinion) do def[k] = v end
                def.sheet = enemy.type
                local gx, gy = self:nearestRoadCell(enemy.x, enemy.y)
                local mx, my = enemy.x, enemy.y
                if gx then mx, my = self:cellCenter(gx, gy) end
                self:spawnMinion(def, mx, my, 1)
                t.converted = (t.converted or 0) + 1
                break
            end
        end
    end
end

function GameState:initUI()
    -- Create UI layout
    self.ui = {}
    
    -- HUD lives in a column to the right of the map so it never covers
    -- map cells (the map is #grid[1] tiles wide).
    local panelX = #self.grid[1] * self.tileSize + 8
    local panelW = 190
    
    -- Resources display
    self.ui.resources = {
        x = panelX,
        y = 10,
        width = panelW,
        height = 30,
        draw = function()
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.ui.resources.x, self.ui.resources.y, self.ui.resources.width, self.ui.resources.height)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.medium)
            love.graphics.print("Gold: " .. math.floor(self.resources), self.ui.resources.x + 10, self.ui.resources.y + 5)
            -- Wave clear bonus, shown for a moment
            if self.waveBonusFlash and self.waveBonusFlash > 0 then
                love.graphics.setColor(1, 0.85, 0.3, math.min(1, self.waveBonusFlash))
                love.graphics.setFont(self.fonts.small)
                local t = "+" .. self.lastWaveBonus .. " wave bonus"
                love.graphics.print(t, self.ui.resources.x + self.ui.resources.width - self.fonts.small:getWidth(t) - 8,
                    self.ui.resources.y + 9)
            end
        end
    }
    
    -- Lives display
    self.ui.lives = {
        x = panelX,
        y = 45,
        width = panelW,
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
        x = panelX,
        y = 80,
        width = panelW,
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
    -- Game speed (1x / 2x / 3x), right of Start Wave; Tab cycles it too
    self.ui.speed = { x = panelX + panelW - 44, y = 115, width = 44, height = 30 }
    self.ui.startWave = {
        x = panelX,
        y = 115,
        width = panelW - 50,
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
        x = panelX,
        y = 155,
        width = panelW,
        height = 260,
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
            
            -- Draw tower buttons (clicks are handled in GameState:mousepressed)
            for _, button in ipairs(self:getTowerButtons()) do
                local id, tower, y = button.id, button.tower, button.y
                local hover = self:isMouseOver(button)

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
                
                -- Draw tower icon (painted sprite if there is one)
                love.graphics.setColor(1, 1, 1)
                if not require("systems.tower").drawIcon(id, self.ui.towerPanel.x + 14, y + 6, 40, 48) then
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
                            { name = "Speed", value = string.format("%.1f shots / s", tower.fireRate or 0) }
                        }
                    }
                end
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
        self:drawSpeedButton()
        self.ui.towerPanel.draw()
        self:drawHeroPanel()
    end

    -- Hero panel under the tower panel
    self.ui.heroPanel = { x = panelX, y = 425, width = panelW, height = 150 }
end

-- The selected faction's towers, keyed by id (data/factions.lua)
function GameState:loadTowerData()
    local Tower = require("systems.tower")
    if not Tower.initialized then
        Tower.init()
    end
    self.towerData = Tower.getSet(self.selectedFaction)
end

------------------------------------------------------------------------
-- Hero panel (right column) and tower panel (strip under the map)
------------------------------------------------------------------------
function GameState:getAbilityButtons()
    local p = self.ui.heroPanel
    local buttons = {}
    local w, gap = 56, 6
    for i = 1, 3 do
        buttons[i] = { index = i, key = ({ "Q", "W", "E" })[i],
            x = p.x + 4 + (i - 1) * (w + gap), y = p.y + 98, width = w, height = 46 }
    end
    return buttons
end

local function bar(x, y, w, h, frac, color)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", x, y, w * math.max(0, math.min(1, frac)), h)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("line", x, y, w, h)
end

function GameState:drawHeroPanel()
    local h = self.hero
    local p = self.ui.heroPanel
    if not h or not p then return end
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", p.x, p.y, p.width, p.height)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("line", p.x, p.y, p.width, p.height)

    -- Portrait
    local px, py, r = p.x + 26, p.y + 28, 20
    love.graphics.setColor(0.1, 0.1, 0.12, 1)
    love.graphics.circle("fill", px, py, r + 2)
    if h.portraitImage then
        local s = (r * 2) / h.portraitImage:getWidth()
        love.graphics.setColor(1, 1, 1, h.dead and 0.4 or 1)
        love.graphics.draw(h.portraitImage, px, py, 0, s, s,
            h.portraitImage:getWidth() / 2, h.portraitImage:getHeight() / 2)
    end
    if h.selected then
        love.graphics.setColor(1, 0.9, 0.3, 1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", px, py, r + 2)
        love.graphics.setLineWidth(1)
    end

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(h.name, p.x + 52, p.y + 6)
    love.graphics.setColor(1, 0.85, 0.3, 1)
    love.graphics.print("Level " .. h.level .. "  " .. h.role, p.x + 52, p.y + 22)
    if h.dead then
        love.graphics.setColor(1, 0.5, 0.5, 1)
        love.graphics.print("Respawn in " .. math.ceil(h.respawnTimer or 0) .. " s", p.x + 52, p.y + 38)
    else
        bar(p.x + 52, p.y + 40, p.width - 60, 7, h.health / h.maxHealth, { 0.3, 0.9, 0.4 })
    end
    local xpFrac = h.level >= 10 and 1 or h.xp / 200
    bar(p.x + 52, p.y + 52, p.width - 60, 4, xpFrac, { 1, 0.8, 0.3 })
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Passive: " .. (h.passive and h.passive.name or "-"), p.x + 6, p.y + 62)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print("Click hero, then the road to move", p.x + 6, p.y + 78)

    -- Ability buttons
    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(self:getAbilityButtons()) do
        local slot = h.abilities[b.index]
        if slot then
            local ready = slot.cooldown <= 0 and not h.dead
            love.graphics.setColor(ready and 0.25 or 0.15, ready and 0.3 or 0.15, ready and 0.45 or 0.2, 0.95)
            love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 4, 4)
            if slot.cooldown > 0 then
                local frac = slot.cooldown / slot.data.cooldown
                love.graphics.setColor(0, 0, 0, 0.55)
                love.graphics.rectangle("fill", b.x, b.y, b.width, b.height * frac, 4, 4)
            end
            if slot.flash > 0 then
                love.graphics.setColor(1, 0.9, 0.4, slot.flash / 0.3)
                love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 4, 4)
            end
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.rectangle("line", b.x, b.y, b.width, b.height, 4, 4)
            love.graphics.setColor(1, 0.85, 0.3, 1)
            love.graphics.print(b.key, b.x + 4, b.y + 2)
            love.graphics.setColor(1, 1, 1, 1)
            -- First word of the name, trimmed to fit on one line
            local short = slot.data.name:match("^(%S+)") or slot.data.name
            local font = love.graphics.getFont()
            while #short > 1 and font:getWidth(short) > b.width - 6 do short = short:sub(1, -2) end
            love.graphics.printf(short, b.x, b.y + 18, b.width, "center")
            if slot.cooldown > 0 then
                love.graphics.printf(tostring(math.ceil(slot.cooldown)), b.x, b.y + 31, b.width, "center")
            end
            if self:pointInRect(mx, my, b) then
                self.tooltip = { x = mx - 260, y = my - 90, width = 250,
                    title = slot.data.name .. " (" .. b.key .. ")",
                    description = slot.data.description .. "\nCooldown " .. slot.data.cooldown .. " s",
                    stats = {} }
            end
        end
    end
end

-- Buttons for the placed tower that is selected (strip under the map)
function GameState:getFocusButtons()
    local t = self.focusTower
    if not t then return {} end
    local y = GameState.MAP_OFFSET_Y + #self.grid * self.tileSize + 8
    local buttons = {}
    for i, up in ipairs(t.data.upgrades) do
        buttons[#buttons + 1] = { kind = "upgrade", index = i, upgrade = up,
            x = 250 + (i - 1) * 215, y = y, width = 205, height = 64 }
    end
    buttons[#buttons + 1] = { kind = "sell", x = 680, y = y, width = 80, height = 64 }
    return buttons
end

function GameState:drawFocusPanel()
    local t = self.focusTower
    if not t then return end
    local y = GameState.MAP_OFFSET_Y + #self.grid * self.tileSize + 4
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, y, #self.grid[1] * self.tileSize, 76)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.setColor(1, 0.9, 0.5, 1)
    love.graphics.print(t.name, 10, y + 6)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.85, 0.85, 0.85, 1)
    love.graphics.printf(t.description, 10, y + 30, 230)
    for _, b in ipairs(self:getFocusButtons()) do
        if b.kind == "upgrade" then
            local bought = t.bought[b.index]
            local afford = self.resources >= b.upgrade.cost
            if bought then love.graphics.setColor(0.2, 0.4, 0.25, 0.95)
            elseif afford then love.graphics.setColor(0.2, 0.3, 0.45, 0.95)
            else love.graphics.setColor(0.3, 0.15, 0.15, 0.95) end
            love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 4, 4)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.rectangle("line", b.x, b.y, b.width, b.height, 4, 4)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(b.upgrade.name, b.x + 6, b.y + 4)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.printf(b.upgrade.description, b.x + 6, b.y + 20, b.width - 12)
            love.graphics.setColor(1, 0.85, 0.3, 1)
            love.graphics.print(bought and "Bought" or ("Cost: " .. b.upgrade.cost), b.x + 6, b.y + 48)
        else
            love.graphics.setColor(0.35, 0.25, 0.1, 0.95)
            love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 4, 4)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.rectangle("line", b.x, b.y, b.width, b.height, 4, 4)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("Sell", b.x, b.y + 12, b.width, "center")
            love.graphics.setColor(1, 0.85, 0.3, 1)
            love.graphics.printf("+" .. t:sellValue(), b.x, b.y + 34, b.width, "center")
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function GameState:towerAt(gx, gy)
    for _, t in ipairs(self.towers) do
        if t.gridX == gx and t.gridY == gy then return t end
    end
end

function GameState:setFocusTower(t)
    if self.focusTower then self.focusTower.selected = false end
    self.focusTower = t
    if t then t.selected = true end
end

function GameState:sellTower(t)
    require('systems.audio').play("sell")
    self.resources = self.resources + t:sellValue()
    for i, other in ipairs(self.towers) do
        if other == t then table.remove(self.towers, i) break end
    end
    self.grid[t.gridY][t.gridX] = 1
    if self.focusTower == t then self:setFocusTower(nil) end
end

function GameState:clearSelection()
    self.selectedTower = nil
    self.towerPreview = nil
    if self.hero then self.hero.selected = false end
    self:setFocusTower(nil)
end

-- Tower panel buttons in a fixed order (pairs() order is unspecified),
-- shared by draw and mousepressed so both agree on what is where.
function GameState:getTowerButtons()
    local ids = {}
    for id in pairs(self.towerData) do
        table.insert(ids, id)
    end
    table.sort(ids, function(a, b)
        local ca, cb = self.towerData[a].cost, self.towerData[b].cost
        if ca ~= cb then return ca < cb end
        return a < b
    end)

    local panel = self.ui.towerPanel
    local buttons = {}
    for i, id in ipairs(ids) do
        table.insert(buttons, {
            id = id,
            tower = self.towerData[id],
            x = panel.x + 10,
            y = panel.y + 40 + (i - 1) * 70,
            width = panel.width - 20,
            height = 60
        })
    end
    return buttons
end

function GameState:pointInRect(px, py, r)
    return px >= r.x and px <= r.x + r.width and
           py >= r.y and py <= r.y + r.height
end

function GameState:selectTowerType(id)
    local tower = self.towerData[id]
    if not tower then return end

    if self.selectedTower == id then
        self.selectedTower = nil
        self.towerPreview = nil
    elseif tower.cost > self.resources then
        self:showError("Not enough resources!")
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
end

function GameState:mousepressed(x, y, button)
    if self.isGameOver then
        if button == 1 then
            for _, b in ipairs(self:getEndButtons()) do
                if self:pointInRect(x, y, b) then self:endAction(b); return end
            end
        end
        return
    end

    -- Right click cancels whatever is selected
    if button == 2 then
        self:clearSelection()
        return
    end

    if button ~= 1 then return end

    -- Start wave button
    if self:pointInRect(x, y, self.ui.startWave) then
        self.ui.startWave.onClick()
        return
    end
    if self:pointInRect(x, y, self.ui.speed) then
        self:cycleSpeed()
        return
    end

    -- Hero ability buttons
    for _, b in ipairs(self:getAbilityButtons()) do
        if self:pointInRect(x, y, b) then
            if self.hero then self.hero:castAbility(b.index, self, true) end
            return
        end
    end

    -- Tower panel buttons
    for _, b in ipairs(self:getTowerButtons()) do
        if self:pointInRect(x, y, b) then
            if self.hero then self.hero.selected = false end
            self:setFocusTower(nil)
            self:selectTowerType(b.id)
            return
        end
    end

    -- Upgrade / sell strip for the selected tower
    for _, b in ipairs(self:getFocusButtons()) do
        if self:pointInRect(x, y, b) then
            local t = self.focusTower
            if b.kind == "sell" then
                self:sellTower(t)
            elseif t.bought[b.index] then
                self:showError("Already bought")
            elseif self.resources < b.upgrade.cost then
                self:showError("Not enough resources!")
            else
                self.resources = self.resources - t:buyUpgrade(b.index)
                require('systems.audio').play("upgrade")
            end
            return
        end
    end

    -- Ignore other clicks on the side panel or below the map
    if x >= self.ui.towerPanel.x then return end
    local mapY = y - GameState.MAP_OFFSET_Y
    if mapY < 0 or mapY >= #self.grid * self.tileSize then return end
    local gridX, gridY = self:pixelToGrid(x, y)

    -- Place the selected tower type on the map
    if self.selectedTower then
        if self:placeTower(gridX, gridY, self.selectedTower) then
            -- Keep the tower selected for repeat placement while affordable
            local data = self.towerData[self.selectedTower]
            if data.cost > self.resources then
                self.selectedTower = nil
                self.towerPreview = nil
            end
        else
            self:showError("Can't build there")
        end
        return
    end

    local hero = self.hero
    -- Click the hero to select it
    if hero and hero:isUnder(x, mapY) then
        self:setFocusTower(nil)
        hero.selected = not hero.selected
        return
    end

    -- Hero selected: click the road to send it there
    if hero and hero.selected then
        if self:isRoad(gridX, gridY) then
            if hero:commandMove(gridX, gridY, self) then
                hero.selected = false
            else
                self:showError("The hero can't get there")
            end
        else
            self:showError("Heroes move along the road")
        end
        return
    end

    -- Click a tower to open its upgrades
    local t = self:towerAt(gridX, gridY)
    if t then
        self:setFocusTower(t ~= self.focusTower and t or nil)
        return
    end
    self:clearSelection()
end

function GameState:keypressed(key)
    if self.isGameOver then return end
    local slots = { q = 1, w = 2, e = 3 }
    if slots[key] and self.hero then
        self.hero:castAbility(slots[key], self, true)
    elseif key == "f" and self.freezeCharge then
        -- Freeze Potion from the shop: once per game
        local Effects = require('systems.effects')
        for _, e in ipairs(self.enemies) do
            if not e.dead then Effects.apply(e, { type = "freeze", duration = self.freezeCharge }) end
        end
        self.freezeCharge = nil
    elseif key == "escape" then
        -- Esc first drops whatever is selected; with nothing selected it pauses
        if self:hasSelection() then self:clearSelection() else self:pause() end
    elseif key == "p" then
        self:pause()
    elseif key == "tab" then
        self:cycleSpeed()
    end
end

function GameState:hasSelection()
    return self.selectedTower ~= nil or self.towerPreview ~= nil or self.focusTower ~= nil
        or (self.hero ~= nil and self.hero.selected == true)
end

function GameState:pause()
    if self.isGameOver then return end
    local Pause = require('states.pause')
    Gamestate.push(Pause.new(self))
end

GameState.SPEEDS = { 1, 2, 3 }

function GameState:cycleSpeed()
    local cur = self.speed or 1
    local nextSpeed = 1
    for i, v in ipairs(GameState.SPEEDS) do
        if v == cur then nextSpeed = GameState.SPEEDS[i % #GameState.SPEEDS + 1] end
    end
    self.speed = nextSpeed
end

function GameState:drawSpeedButton()
    local b = self.ui.speed
    local hover = self:isMouseOver(b)
    local fast = (self.speed or 1) > 1
    love.graphics.setColor(fast and { 0.55, 0.4, 0.15, 0.95 } or (hover and { 0.3, 0.3, 0.45, 0.95 } or { 0.2, 0.2, 0.3, 0.85 }))
    love.graphics.rectangle("fill", b.x, b.y, b.width, b.height)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.rectangle("line", b.x, b.y, b.width, b.height)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf((self.speed or 1) .. "x", b.x, b.y + 5, b.width, "center")
end

function GameState:enter(previous, faction, hero)
    if faction and hero then
        self:setup(faction, hero)
    end
    require('systems.audio').playMusic("game")
    
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

-- One frame: the simulation runs `speed` steps of dt, so 2x and 3x are
-- exactly the same game, just faster
function GameState:update(dt)
    for _ = 1, (self.speed or 1) do
        if self.isGameOver then return end
        self:step(dt)
    end
end

function GameState:step(dt)
    if self.isGameOver then return end
    
    -- Update error messages
    self:updateErrorMessages(dt)
    
    -- Update UI
    self.ui:update(dt)
    if self.waveBonusFlash then self.waveBonusFlash = self.waveBonusFlash - dt end
    self.mapTime = (self.mapTime or 0) + dt
    
    -- Update towers
    -- Towers get the whole game state (towers, enemies, projectiles, effects)
    for _, tower in ipairs(self.towers) do
        tower:update(dt, self)
    end

    -- Update allied units (hero and minions)
    for i = #self.units, 1, -1 do
        local u = self.units[i]
        u:update(dt, self)
        if u.removed then table.remove(self.units, i) end
    end

    -- Update enemies
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        enemy:update(dt)

        if enemy.summonRequest then
            enemy.summonRequest = false
            if not enemy.dead then self:raiseMinion(enemy) end
        end

        -- Killed this frame (by anything): XP and Soul Forge conversion
        if enemy.justDied then
            enemy.justDied = false
            self:onEnemyDeath(enemy)
        end

        -- Check if enemy reached the end
        if enemy.state == "attacking" then
            self.lives = self.lives - enemy.damage
            require('systems.audio').play("life_lost")
            table.remove(self.enemies, i)
            
            -- Check game over condition
            if self.lives <= 0 then
                self:gameOver(false)
                return
            end
        elseif enemy.removed then
            -- Enemy was killed, add resources
            self.resources = self.resources + enemy.value
            self.goldEarned = self.goldEarned + enemy.value
            table.remove(self.enemies, i)
        end
    end
    
    -- Update projectiles
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]
        projectile:update(dt, self)

        if projectile.destroyed then
            table.remove(self.projectiles, i)
        end
    end

    -- Update effects
    for i = #self.effects, 1, -1 do
        local effect = self.effects[i]
        local finished = effect:update(dt)

        if finished or effect.done then
            table.remove(self.effects, i)
        end
    end
    
    -- Handle wave logic
    if self.waveInProgress then
        -- Spawn enemies, each after its planned delay
        if #self.waveEnemies > 0 then
            self.enemySpawnTimer = self.enemySpawnTimer + dt
            while #self.waveEnemies > 0 and self.enemySpawnTimer >= self.waveEnemies[1].delay do
                self.enemySpawnTimer = self.enemySpawnTimer - self.waveEnemies[1].delay
                self:spawnEnemy()
            end
        end

        -- Wave cleared: bonus gold, or victory after the last one
        if #self.waveEnemies == 0 and #self.enemies == 0 then
            self.waveInProgress = false
            local bonus = self.waves[self.wave].bonus
            self.resources = self.resources + bonus
            self.lastWaveBonus = bonus
            self.waveBonusFlash = 2.5

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
        self.towerPreview.x = (gridX - 1) * self.tileSize
        self.towerPreview.y = (gridY - 1) * self.tileSize
        self.towerPreview.canPlace = self:canPlaceTower(gridX, gridY)
    end
end

-- Level name and what the next wave brings, under the hero panel
function GameState:drawWaveInfo()
    local hp = self.ui.heroPanel
    local x, y, w = hp.x, hp.y + hp.height + 24, hp.width
    local font = self.fonts.small
    love.graphics.setFont(font)
    local lines = { self.level.name }
    local nextWave = self.waves[self.wave + 1]
    if nextWave and not self.isGameOver then
        local label = self.waveInProgress and "After this: " or "Next: "
        lines[#lines + 1] = label .. require('systems.wave').summary(nextWave)
    elseif self.wave >= self.maxWaves then
        lines[#lines + 1] = "Final wave"
    end
    local text = table.concat(lines, "\n")
    local _, wrapped = font:getWrap(text, w - 12)
    local h = #wrapped * font:getHeight() + 10
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setColor(0.95, 0.9, 0.75, 1)
    love.graphics.printf(text, x + 6, y + 5, w - 12)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameState:startNextWave()
    if self.waveInProgress or self.wave >= self.maxWaves then return end

    self.wave = self.wave + 1
    require('systems.audio').play("wave_start")
    self.waveInProgress = true

    -- Copy the planned spawns; the plan stays intact for the HUD
    local plan = self.waves[self.wave]
    self.waveEnemies = {}
    for i, e in ipairs(plan.entries) do self.waveEnemies[i] = e end
    self.waveHealthMult = plan.healthMult
    self.enemySpawnTimer = 0
end

-- Create one enemy on road `pathIndex` and add it to the game
function GameState:addEnemy(enemyType, pathIndex, healthMult)
    local Enemy = require("systems.enemy")
    local path = self.paths[pathIndex] or self.paths[1]
    local enemy = Enemy.create(enemyType, path, self.tileSize)
    if not enemy then return nil end
    local mult = healthMult or 1
    enemy.health = enemy.health * mult
    enemy.maxHealth = enemy.maxHealth * mult
    table.insert(self.enemies, enemy)
    return enemy
end

function GameState:spawnEnemy()
    local entry = table.remove(self.waveEnemies, 1)
    if entry then
        self:addEnemy(entry.type, entry.path, self.waveHealthMult)
    end
end

-- A necromancer raises a weaker skeleton where it stands
function GameState:raiseMinion(caster)
    local s = caster.summon
    local e = self:addEnemy(s.type, 1, (self.waveHealthMult or 1) * s.healthMult)
    if not e then return end
    e.path = caster.path
    e.currentPathIndex = caster.currentPathIndex
    e.x, e.y = caster.x, caster.y
    e.gridX, e.gridY = caster.gridX, caster.gridY
    e.value = s.value
    e.raised = true
    self.raisedCount = (self.raisedCount or 0) + 1
end

function GameState:draw()
    -- Everything on the map is drawn in map coordinates, shifted down so
    -- figures on the top row of the road (and flyers above it) stay on screen.
    -- The HUD, tooltip and overlays below are drawn in screen coordinates.
    love.graphics.push()
    love.graphics.translate(0, GameState.MAP_OFFSET_Y)

    -- Draw map
    local mapW, mapH = 0, 0
    if self.grid then
        mapW, mapH = #self.grid[1] * self.tileSize, #self.grid * self.tileSize
    end
    if self.grid and self.mapImage then
        -- Painted plate, scaled to the grid
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.mapImage, 0, 0, 0,
            mapW / self.mapImage:getWidth(), mapH / self.mapImage:getHeight())
        if self.built and #self.built.portals > 0 then
            require('systems.level').drawPortals(self.built, self.tileSize, self.mapTime or 0)
        end

        -- Build grid only while placing a tower, so it never sits over the art
        if self.towerPreview then
            love.graphics.setColor(1, 1, 1, 0.12)
            for y = 1, #self.grid do
                for x = 1, #self.grid[1] do
                    if self.grid[y][x] == 1 then
                        love.graphics.rectangle("line", (x-1) * self.tileSize, (y-1) * self.tileSize, self.tileSize, self.tileSize)
                    end
                end
            end
        end
    elseif self.grid then
        love.graphics.setColor(1, 1, 1)
        -- Draw the background
        love.graphics.setColor(0.3, 0.7, 0.3)
        love.graphics.rectangle("fill", 0, 0, mapW, mapH)

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
    
    -- Draw towers and enemies together, back to front by where they touch
    -- the ground, so a tall tower covers whatever stands behind it and
    -- anything in front of it covers the tower.
    local drawables = {}
    for _, tower in ipairs(self.towers) do
        local _, baseY = tower:getCenter()
        drawables[#drawables + 1] = { y = baseY, obj = tower }
    end
    for _, enemy in ipairs(self.enemies) do
        drawables[#drawables + 1] = { y = enemy.y + (enemy.height or 32) / 4, obj = enemy }
    end
    for _, u in ipairs(self.units) do
        drawables[#drawables + 1] = { y = u.y + 8, obj = u }
    end
    table.sort(drawables, function(a, b) return a.y < b.y end)
    for _, d in ipairs(drawables) do
        d.obj:draw()
    end

    -- Range of the selected tower, or the tower under the mouse
    if self.focusTower then
        self.focusTower:drawRange()
    elseif not self.towerPreview then
        local gx, gy = self:pixelToGrid(love.mouse.getPosition())
        local t = self:towerAt(gx, gy)
        if t then t:drawRange() end
    end

    -- Hero selected: outline the road cell under the mouse as the move target
    if self.hero and self.hero.selected then
        local gx, gy = self:pixelToGrid(love.mouse.getPosition())
        if self:isRoad(gx, gy) then
            love.graphics.setColor(1, 0.9, 0.3, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", (gx - 1) * self.tileSize + 2, (gy - 1) * self.tileSize + 2,
                self.tileSize - 4, self.tileSize - 4, 4, 4)
            love.graphics.setLineWidth(1)
        end
        love.graphics.setColor(1, 0.9, 0.3, 0.35)
        love.graphics.circle("line", self.hero.x, self.hero.y, self.hero.range)
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

        -- Ghost of the painted tower where it would stand
        local Tower = require("systems.tower")
        local img = Tower.images and Tower.images[self.towerPreview.type]
        if img then
            Tower.drawPainted(img, self.towerPreview.x + self.tileSize / 2,
                self.towerPreview.y + self.tileSize / 2, Tower.DRAW_WIDTH, 0.6, false)
        end

        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("line", self.towerPreview.x + self.tileSize/2, self.towerPreview.y + self.tileSize/2, self.towerPreview.range)
    end

    love.graphics.pop()

    -- Draw UI
    self.ui:draw()
    self:drawFocusPanel()
    self:drawWaveInfo()
    if self.freezeCharge then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(0.6, 0.85, 1, 1)
        love.graphics.print("F: Freeze Potion ready", self.ui.heroPanel.x, self.ui.heroPanel.y + self.ui.heroPanel.height + 6)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Draw tooltip
    if self.tooltip then
        self:drawTooltip()
    end
    
    -- Draw error messages
    self:drawErrorMessages()
    
    if self.isGameOver then self:drawEndScreen() end
end

-- Stars for a win: 3 if at most 10% of lives were lost, 2 if at most half
function GameState.starsFor(lives, startLives)
    local f = lives / math.max(1, startLives)
    if f >= 0.9 then return 3 elseif f >= 0.5 then return 2 else return 1 end
end

-- Buttons on the end screen: { label, action, x, y, width, height }
function GameState:getEndButtons()
    local Level = require('systems.level')
    local list = {}
    local nextLevel = Level.nextOf(self.levelId)
    if self.victory and nextLevel then
        list[#list + 1] = { label = "Next Level", action = "next", level = nextLevel.id }
    end
    list[#list + 1] = { label = self.victory and "Replay" or "Retry", action = "retry" }
    list[#list + 1] = { label = "Level Select", action = "levels" }
    local w, h, gap = 170, 44, 16
    local total = #list * w + (#list - 1) * gap
    local x0 = love.graphics.getWidth() / 2 - total / 2
    local y = love.graphics.getHeight() / 2 + 90
    for i, b in ipairs(list) do
        b.x, b.y, b.width, b.height = x0 + (i - 1) * (w + gap), y, w, h
    end
    return list
end

function GameState:endAction(b)
    if b.action == "levels" then
        local ls = require('states.level_select').new()
        ls:setup(self.factionData, self.heroData)
        Gamestate.switch(ls)
    else
        local g = GameState.new()
        g:setup(self.factionData, self.heroData, b.action == "next" and b.level or self.levelId)
        Gamestate.switch(g)
    end
end

function GameState:drawEndScreen()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setColor(self.victory and { 1, 0.85, 0.35 } or { 0.9, 0.35, 0.3 })
    love.graphics.setFont(self.fonts.title)
    love.graphics.printf(self.victory and "VICTORY!" or "DEFEAT", 0, sh / 2 - 130, sw, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf(self.level.name, 0, sh / 2 - 80, sw, "center")

    -- Stars
    if self.victory then
        local stars = self.stars or 1
        for i = 1, 3 do
            local cx, cy = sw / 2 + (i - 2) * 46, sh / 2 - 30
            local pts = {}
            for k = 0, 9 do
                local r = (k % 2 == 0) and 18 or 8
                local a = -math.pi / 2 + k * math.pi / 5
                pts[#pts + 1] = cx + math.cos(a) * r
                pts[#pts + 1] = cy + math.sin(a) * r
            end
            love.graphics.setColor(i <= stars and { 1, 0.82, 0.2 } or { 0.3, 0.3, 0.3 })
            for _, tri in ipairs(love.math.triangulate(pts)) do love.graphics.polygon("fill", tri) end
        end
    end

    love.graphics.setColor(0.85, 0.85, 0.85)
    love.graphics.setFont(self.fonts.small)
    local lines = {
        string.format("Waves %d / %d     Lives %d / %d", self.wave, self.maxWaves, math.max(0, self.lives), self.startLives),
        string.format("+%d shop gold", self.shopGoldAwarded or 0),
    }
    if self.hero then
        lines[#lines + 1] = string.format("%s is level %d", self.hero.name, self.hero.level)
    end
    love.graphics.printf(table.concat(lines, "\n"), 0, sh / 2 + 5, sw, "center")

    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(self:getEndButtons()) do
        local hover = self:pointInRect(mx, my, b)
        love.graphics.setColor(hover and { 0.35, 0.45, 0.7, 0.95 } or { 0.2, 0.25, 0.45, 0.9 })
        love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 8, 8)
        love.graphics.setColor(0.75, 0.8, 1, 0.9)
        love.graphics.rectangle("line", b.x, b.y, b.width, b.height, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.medium)
        love.graphics.printf(b.label, b.x, b.y + b.height / 2 - self.fonts.medium:getHeight() / 2, b.width, "center")
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
    
    require('systems.audio').play("place")

    -- Deduct resources
    self.resources = self.resources - towerData.cost
    
    -- Create tower
    local Tower = require("systems.tower")
    local tower = Tower.create(type, gridX, gridY, self.tileSize, self.towerMods)
    
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

-- Screen pixel to grid cell; the map is drawn MAP_OFFSET_Y pixels down
function GameState:pixelToGrid(pixelX, pixelY)
    local gridX = math.floor(pixelX / self.tileSize) + 1
    local gridY = math.floor((pixelY - GameState.MAP_OFFSET_Y) / self.tileSize) + 1
    return gridX, gridY
end

function GameState:loadMap(level)
    local Level = require('systems.level')
    local built = Level.build(level)
    self.built = built
    self.grid = built.grid
    self.paths = built.paths          -- one cell list per road, start to end
    self.roadPath = built.roadCells   -- every road cell as {gx, gy}; road 1 first, in order
    self.startX, self.startY = built.paths[1][1].x, built.paths[1][1].y
    local last = built.paths[1][#built.paths[1]]
    self.endX, self.endY = last.x, last.y

    -- The hero walks road cells (BFS in systems/enemy.lua)
    require("systems.enemy").setPathfinder(self.grid, Level.ROAD)

    -- Painted ground plate if the level has one (art/README.md), else a
    -- ground generated from the level data. The road cells stay the source
    -- of truth; a plate is cut and warped to match them (tools/artcut mapfix).
    self.mapImage = nil
    local plate = Level.platePath(level)
    if plate then
        local ok, img = pcall(love.graphics.newImage, plate, { mipmaps = true })
        if ok then
            img:setFilter("linear", "linear")
            img:setMipmapFilter("linear")
            self.mapImage = img
        else
            print("WARNING: could not load map plate " .. plate)
        end
    end
    if not self.mapImage then
        self.mapImage = Level.renderGround(level, built, self.tileSize)
    end
end

function GameState:gameOver(victory)
    self.isGameOver = true
    self.victory = victory
    local Audio = require('systems.audio')
    Audio.stopMusic()
    Audio.play(victory and "victory" or "defeat")
    
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
    
    -- Hero progress and shop gold carry over to the next game
    local Save = require("systems.save")
    if self.hero then
        pcall(Save.updateHeroProgress, self.hero.id, self.hero.level, self.hero.xp)
    end
    self.shopGoldAwarded = math.floor(self.goldEarned / 5) + (victory and 100 or 0)
    pcall(Save.addGold, self.shopGoldAwarded)
    if victory then
        self.stars = GameState.starsFor(self.lives, self.startLives)
        pcall(Save.recordLevelResult, self.levelId, self.stars)
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