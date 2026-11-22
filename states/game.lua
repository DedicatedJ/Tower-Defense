local GameState = {}
GameState.__index = GameState

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
    self.stats = { kills = 0, built = 0, spent = 0, leaks = {} } -- for the end screen
    require('systems.fx').clear() -- numbers and puffs from the last game
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

    -- First-time hints (Settings > Show Tutorial)
    self:startHints()
end

------------------------------------------------------------------------
-- First-time hints: on a faction's first level, until it has been won,
-- with "Show Tutorial" on. Each hint stays up until its action is done
-- (or, for the optional ones, until enough time has passed).
------------------------------------------------------------------------
GameState.HINTS = {
    { text = "Pick a tower at the bottom right (or press 1), then click inside a marked zone.",
      done = function(g) return #g.towers > 0 end },
    { text = "Press Start Wave (or Space) when you are ready.",
      done = function(g) return g.wave > 0 end },
    { text = "Click your hero, then a spot on the road, to send them where the fight is.",
      done = function(g, t) return g.heroMoved or t > 25 end },
    { text = "Abilities fire on their own. Press Q, W or E to cast one early.",
      done = function(g, t) return g.manualCasts or t > 20 end },
    { text = "Click a tower you built to buy its upgrades or sell it.",
      done = function(g, t) return g.focusTower ~= nil or t > 25 end },
}

function GameState:startHints()
    self.hintIndex, self.hintTime = nil, 0
    local settings = gameState and gameState.settings
    if settings and settings.showTutorial == false then return end
    if self.level.order ~= 1 then return end
    local ok, result = pcall(require('systems.save').getLevelResult, self.levelId)
    if ok and result then return end
    self.hintIndex = 1
end

function GameState:updateHints(dt)
    local h = self.hintIndex and GameState.HINTS[self.hintIndex]
    if not h then return end
    self.hintTime = self.hintTime + dt
    if h.done(self, self.hintTime) then
        self.hintIndex = self.hintIndex + 1
        self.hintTime = 0
        if self.hintIndex > #GameState.HINTS then self.hintIndex = nil end
    end
end

function GameState:drawHint()
    local h = self.hintIndex and GameState.HINTS[self.hintIndex]
    if not h or self.isGameOver then return end
    local W = love.graphics.getWidth()
    local font = self.fonts.small
    local w = math.min(W - 40, font:getWidth(h.text) + 40)
    -- Under the status pill at the top
    local s = self.ui.status
    local x, y = W / 2 - w / 2, s.y + s.height + 8
    love.graphics.setColor(0.08, 0.08, 0.12, 0.85)
    love.graphics.rectangle("fill", x, y, w, font:getHeight() + 14, 6, 6)
    love.graphics.setColor(1, 0.85, 0.4, 0.9)
    love.graphics.rectangle("line", x, y, w, font:getHeight() + 14, 6, 6)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(h.text, x, y + 7, w, "center")
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
-- Map helpers used by units and towers (screen pixels; the map fills the
-- screen)
------------------------------------------------------------------------
function GameState:onRoad(x, y)
    return self.built ~= nil and require('systems.level').onRoad(self.built, x, y)
end

-- Road center point nearest to (x, y); with r, only if within r
function GameState:nearestRoadPoint(x, y, r)
    local d, _, _, cx, cy = require('systems.level').nearestRoad(self.built, x, y)
    if not d or (r and d > r) then return nil end
    return cx, cy
end

-- A way along the road from one point to another (list of {x, y}), or nil
function GameState:route(x1, y1, x2, y2)
    return require('systems.level').nav(self.built):route(x1, y1, x2, y2)
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
    local road = self.roads[1]
    local x, y = road:pointAt(road:length() * 0.6)
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
    if not enemy.raised then self.stats.kills = self.stats.kills + 1 end
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
                local mx, my = self:nearestRoadPoint(enemy.x, enemy.y)
                self:spawnMinion(def, mx or enemy.x, my or enemy.y, 1)
                t.converted = (t.converted or 0) + 1
                break
            end
        end
    end
end

function GameState:initUI()
    -- The map fills the screen; the HUD floats over it in the boxes listed
    -- in data/levels.lua (Levels.hud), which level roads keep clear of.
    local Levels = require('data.levels')
    local hud = Levels.hud
    local function box(b) return { x = b[1], y = b[2], width = b[3], height = b[4] } end
    self.ui = {
        status = box(hud.status),
        controls = box(hud.controls),
        heroPanel = box(hud.hero),
        towerPanel = box(hud.towers),
    }
    local c = self.ui.controls
    self.ui.pauseButton = { x = c.x, y = c.y, width = 44, height = c.height }
    self.ui.speed = { x = c.x + 52, y = c.y, width = 44, height = c.height }
    self.ui.startWave = { x = c.x + 104, y = c.y, width = c.width - 104, height = c.height,
        onClick = function() self:startNextWave() end }
    self.ui.update = function() end
    self.ui.draw = function()
        self:drawStatus()
        self:drawControls()
        self:drawTowerButtons()
        self:drawHeroPanel()
    end
end

-- Rounded dark panel used by every HUD box
local function panel(x, y, w, h, alpha)
    love.graphics.setColor(0.06, 0.07, 0.1, alpha or 0.82)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0.85, 0.75, 0.45, 0.55)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    love.graphics.setLineWidth(1)
end

-- Lives, gold and wave in the pill at the top
function GameState:drawStatus()
    local s = self.ui.status
    panel(s.x, s.y, s.width, s.height)
    local font = self.fonts.medium
    love.graphics.setFont(font)
    local cy = s.y + s.height / 2
    local ty = cy - font:getHeight() / 2
    -- Lives: a red heart (two circles and a triangle)
    local x = s.x + 22
    love.graphics.setColor(0.9, 0.25, 0.3, 1)
    love.graphics.circle("fill", x - 4, cy - 3, 5)
    love.graphics.circle("fill", x + 4, cy - 3, 5)
    love.graphics.polygon("fill", x - 9, cy - 1, x + 9, cy - 1, x, cy + 9)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(self.lives), x + 16, ty)
    -- Gold: a coin
    x = s.x + 118
    love.graphics.setColor(0.95, 0.75, 0.2, 1)
    love.graphics.circle("fill", x, cy, 8)
    love.graphics.setColor(0.7, 0.5, 0.1, 1)
    love.graphics.circle("line", x, cy, 5)
    love.graphics.setColor(1, 1, 1, 1)
    local gold = tostring(math.floor(self.resources))
    love.graphics.print(gold, x + 14, ty)
    -- Wave clear bonus, shown for a moment right after the amount
    if self.waveBonusFlash and self.waveBonusFlash > 0 then
        love.graphics.setColor(1, 0.85, 0.3, math.min(1, self.waveBonusFlash))
        love.graphics.setFont(self.fonts.small)
        local t = "+" .. self.lastWaveBonus .. (self.bonusLabel == "early call" and " early" or "")
        love.graphics.print(t, x + 20 + font:getWidth(gold), cy - self.fonts.small:getHeight() / 2)
        love.graphics.setFont(font)
    end
    -- Wave
    love.graphics.setColor(0.95, 0.9, 0.75, 1)
    local wave = "Wave " .. self.wave .. "/" .. self.maxWaves
    love.graphics.print(wave, s.x + s.width - 16 - font:getWidth(wave), ty)
    love.graphics.setColor(1, 1, 1, 1)
end

local function button(b, fill, hover, label, font)
    local c = hover and { fill[1] * 1.25, fill[2] * 1.25, fill[3] * 1.25, fill[4] or 0.95 } or fill
    love.graphics.setColor(c)
    love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 6, 6)
    love.graphics.setColor(0.85, 0.75, 0.45, 0.7)
    love.graphics.rectangle("line", b.x, b.y, b.width, b.height, 6, 6)
    if label then
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(label, b.x, b.y + b.height / 2 - font:getHeight() / 2, b.width, "center")
    end
end

-- Pause, speed and Start Wave at the top right; the next wave's make-up
-- shows while the mouse is over them
function GameState:drawControls()
    local p, sp, sw = self.ui.pauseButton, self.ui.speed, self.ui.startWave
    local font = self.fonts.medium
    -- Pause: two bars
    button(p, { 0.12, 0.14, 0.2, 0.9 }, self:isMouseOver(p))
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", p.x + 15, p.y + 13, 5, p.height - 26, 1)
    love.graphics.rectangle("fill", p.x + 24, p.y + 13, 5, p.height - 26, 1)
    -- Speed
    local fast = (self.speed or 1) > 1
    button(sp, fast and { 0.55, 0.4, 0.15, 0.95 } or { 0.12, 0.14, 0.2, 0.9 }, self:isMouseOver(sp),
        (self.speed or 1) .. "x", font)
    -- Start Wave / call early / in progress
    local early = self:canCallEarly()
    if (not self.waveInProgress and self.wave < self.maxWaves) or early then
        local fill = early and { 0.6, 0.42, 0.1, 0.95 } or { 0.2, 0.45, 0.22, 0.95 }
        button(sw, fill, self:isMouseOver(sw), early and ("Early +" .. self:earlyBonus()) or "Start Wave", font)
    else
        button(sw, { 0.15, 0.15, 0.18, 0.8 }, false, self.wave >= self.maxWaves and "Final wave" or "In Progress", font)
    end
    if self:isMouseOver(self.ui.controls) or self:isMouseOver(self.ui.status) then self:drawWaveInfo() end
end

-- Level name and what the next wave brings, under the controls
function GameState:drawWaveInfo()
    local c = self.ui.controls
    local font = self.fonts.small
    local w = 300
    local x, y = c.x + c.width - w, c.y + c.height + 6
    local lines = { self.level.name }
    local nextWave = self.waves[self.wave + 1]
    if nextWave and not self.isGameOver then
        local label = self.waveInProgress and "After this: " or "Next: "
        lines[#lines + 1] = label .. require('systems.wave').summary(nextWave)
    elseif self.wave >= self.maxWaves then
        lines[#lines + 1] = "Final wave"
    end
    local text = table.concat(lines, "\n")
    local _, wrapped = font:getWrap(text, w - 16)
    local h = #wrapped * font:getHeight() + 12
    panel(x, y, w, h, 0.9)
    love.graphics.setFont(font)
    love.graphics.setColor(0.95, 0.9, 0.75, 1)
    love.graphics.printf(text, x + 8, y + 6, w - 16)
    love.graphics.setColor(1, 1, 1, 1)
end

-- The selected faction's towers, keyed by id (data/factions.lua)
function GameState:loadTowerData()
    local Tower = require("systems.tower")
    if not Tower.initialized then
        Tower.init()
    end
    self.towerData = Tower.getSet(self.selectedFaction)
end

-- Tower buttons in a fixed order (pairs() order is unspecified), shared by
-- draw and mousepressed so both agree on what is where. Bottom right.
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
    local p = self.ui.towerPanel
    local gap = 9
    local w = (p.width - gap * (#ids - 1)) / math.max(1, #ids)
    local buttons = {}
    for i, id in ipairs(ids) do
        buttons[#buttons + 1] = { id = id, tower = self.towerData[id],
            x = p.x + (i - 1) * (w + gap), y = p.y, width = w, height = p.height }
    end
    return buttons
end

function GameState:drawTowerButtons()
    local font = self.fonts.small
    for hotkey, b in ipairs(self:getTowerButtons()) do
        local tower = b.tower
        local hover = self:isMouseOver(b)
        local selected = self.selectedTower == b.id
        local afford = tower.cost <= self.resources
        local fill = selected and { 0.3, 0.45, 0.28, 0.95 } or { 0.06, 0.07, 0.1, 0.85 }
        button(b, fill, hover)
        if selected then
            love.graphics.setColor(1, 0.9, 0.4, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", b.x, b.y, b.width, b.height, 6, 6)
            love.graphics.setLineWidth(1)
        end
        love.graphics.setColor(1, 1, 1, afford and 1 or 0.45)
        if not require("systems.tower").drawIcon(b.id, b.x + b.width / 2 - 22, b.y + 4, 44, 52) then
            love.graphics.setColor(0.5, 0.5, 0.7, afford and 1 or 0.45)
            love.graphics.rectangle("fill", b.x + b.width / 2 - 16, b.y + 14, 32, 32)
        end
        love.graphics.setFont(font)
        love.graphics.setColor(1, 0.85, 0.4, 0.95)
        love.graphics.print(tostring(hotkey), b.x + 6, b.y + 4)
        love.graphics.setColor(afford and { 1, 0.85, 0.3, 1 } or { 1, 0.4, 0.35, 1 })
        love.graphics.printf(tostring(tower.cost), b.x, b.y + b.height - font:getHeight() - 5, b.width, "center")
        if hover then
            self.tooltip = {
                x = love.mouse.getX() - 260, y = b.y - 200, width = 250,
                title = tower.name, description = tower.description,
                stats = {
                    { name = "Cost", value = tower.cost },
                    { name = "Damage", value = tower.damage },
                    { name = "Range", value = tower.range },
                    { name = "Speed", value = string.format("%.1f shots / s", tower.fireRate or 0) },
                },
            }
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

------------------------------------------------------------------------
-- Hero card (bottom left) and the card of a placed tower
------------------------------------------------------------------------
function GameState:getAbilityButtons()
    local p = self.ui.heroPanel
    local buttons = {}
    local x0, w, gap = p.x + 76, 64, 6
    for i = 1, 3 do
        buttons[i] = { index = i, key = ({ "Q", "W", "E" })[i],
            x = x0 + (i - 1) * (w + gap), y = p.y + 44, width = w, height = p.height - 50 }
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
    panel(p.x, p.y, p.width, p.height)
    local mx, my = love.mouse.getPosition()

    -- Portrait
    local px, py, r = p.x + 38, p.y + p.height / 2, 30
    love.graphics.setColor(0.1, 0.1, 0.12, 1)
    love.graphics.circle("fill", px, py, r + 2)
    if h.portraitImage then
        local s = (r * 2) / h.portraitImage:getWidth()
        love.graphics.setColor(1, 1, 1, h.dead and 0.4 or 1)
        love.graphics.draw(h.portraitImage, px, py, 0, s, s,
            h.portraitImage:getWidth() / 2, h.portraitImage:getHeight() / 2)
    end
    love.graphics.setColor(h.selected and { 1, 0.9, 0.3, 1 } or { 0.85, 0.75, 0.45, 0.7 })
    love.graphics.setLineWidth(h.selected and 3 or 1.5)
    love.graphics.circle("line", px, py, r + 2)
    love.graphics.setLineWidth(1)
    -- Level badge
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.06, 0.07, 0.1, 0.95)
    love.graphics.circle("fill", px + 22, py + 22, 10)
    love.graphics.setColor(1, 0.85, 0.3, 1)
    love.graphics.printf(tostring(h.level), px + 12, py + 22 - self.fonts.small:getHeight() / 2, 20, "center")
    if (mx - px) ^ 2 + (my - py) ^ 2 <= r * r then
        self.tooltip = { x = mx + 12, y = my - 170, width = 260, title = h.name,
            description = "Level " .. h.level .. " " .. h.role .. "\nPassive: " .. (h.passive and h.passive.name or "-")
                .. "\nClick the hero, then a spot on the road, to move them.",
            stats = {} }
    end

    -- Name, then health (or respawn) and XP bars
    local x0, w = p.x + 76, p.width - 84
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(h.name, x0, p.y + 6)
    if h.dead then
        love.graphics.setColor(1, 0.5, 0.5, 1)
        love.graphics.print("Respawn in " .. math.ceil(h.respawnTimer or 0) .. " s", x0, p.y + 24)
    else
        bar(x0, p.y + 26, w, 7, h.health / h.maxHealth, { 0.3, 0.9, 0.4 })
    end
    local xpFrac = h.level >= 10 and 1 or h.xp / 200
    bar(x0, p.y + 36, w, 4, xpFrac, { 1, 0.8, 0.3 })

    -- Ability buttons
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
            love.graphics.print(b.key, b.x + 4, b.y + 1)
            love.graphics.setColor(1, 1, 1, 1)
            -- First word of the name, trimmed to fit on one line
            local short = slot.data.name:match("^(%S+)") or slot.data.name
            local font = love.graphics.getFont()
            while #short > 1 and font:getWidth(short) > b.width - 6 do short = short:sub(1, -2) end
            if slot.cooldown > 0 then
                love.graphics.printf(tostring(math.ceil(slot.cooldown)), b.x, b.y + 15, b.width, "center")
            else
                love.graphics.printf(short, b.x, b.y + 15, b.width, "center")
            end
            if self:pointInRect(mx, my, b) then
                self.tooltip = { x = mx + 12, y = my - 140, width = 250,
                    title = slot.data.name .. " (" .. b.key .. ")",
                    description = slot.data.description .. "\nCooldown " .. slot.data.cooldown .. " s",
                    stats = {} }
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Card for the placed tower that is selected: next to the tower, kept on
-- screen. Two upgrades side by side, Sell under them.
GameState.CARD_W, GameState.CARD_H = 300, 150

function GameState:focusCardRect()
    local t = self.focusTower
    if not t then return nil end
    local W, H = love.graphics.getWidth(), love.graphics.getHeight()
    local w, h = GameState.CARD_W, GameState.CARD_H
    local x = t.x + 40
    if x + w > W - 6 then x = t.x - 40 - w end
    local y = math.max(6, math.min(H - h - 6, t.y - 20 - h / 2))
    return { x = x, y = y, width = w, height = h }
end

function GameState:getFocusButtons()
    local c = self:focusCardRect()
    if not c then return {} end
    local buttons = {}
    for i, up in ipairs(self.focusTower.data.upgrades) do
        buttons[#buttons + 1] = { kind = "upgrade", index = i, upgrade = up,
            x = c.x + 6 + (i - 1) * 147, y = c.y + 30, width = 141, height = 74 }
    end
    buttons[#buttons + 1] = { kind = "sell", x = c.x + 6, y = c.y + 110, width = c.width - 12, height = 34 }
    return buttons
end

function GameState:drawFocusPanel()
    local t = self.focusTower
    local c = self:focusCardRect()
    if not c then return end
    panel(c.x, c.y, c.width, c.height, 0.92)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.setColor(1, 0.9, 0.5, 1)
    love.graphics.print(t.name, c.x + 8, c.y + 5)
    love.graphics.setFont(self.fonts.small)
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
            love.graphics.print(b.upgrade.name, b.x + 5, b.y + 3)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.printf(b.upgrade.description, b.x + 5, b.y + 19, b.width - 10)
            love.graphics.setColor(1, 0.85, 0.3, 1)
            love.graphics.print(bought and "Bought" or ("Cost: " .. b.upgrade.cost), b.x + 5, b.y + b.height - 17)
        else
            love.graphics.setColor(0.35, 0.25, 0.1, 0.95)
            love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 4, 4)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.rectangle("line", b.x, b.y, b.width, b.height, 4, 4)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("Sell  +" .. t:sellValue(), b.x, b.y + b.height / 2 - self.fonts.small:getHeight() / 2,
                b.width, "center")
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- The placed tower at a screen point: its base or the body above it
function GameState:towerAt(x, y)
    local best, bestD
    for _, t in ipairs(self.towers) do
        if math.abs(x - t.x) <= 24 and y >= t.y - 60 and y <= t.y + 16 then
            local d = math.abs(x - t.x) + math.abs(y - (t.y - 20))
            if not bestD or d < bestD then best, bestD = t, d end
        end
    end
    return best
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
    if self.focusTower == t then self:setFocusTower(nil) end
end

function GameState:clearSelection()
    self.selectedTower = nil
    self.towerPreview = nil
    if self.hero then self.hero.selected = false end
    self:setFocusTower(nil)
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
        self.towerPreview = { type = id, x = 0, y = 0, range = tower.range, canPlace = false }
    end
end

-- Why a spot can't take a tower, for the message
GameState.BUILD_ERRORS = {
    zone = "Build inside a marked zone",
    road = "Too close to the road",
    tower = "Too close to another tower",
    hud = "Can't build there",
}

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

    -- The selected tower's card (it floats over the map)
    local card = self:focusCardRect()
    if card and self:pointInRect(x, y, card) then
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
                    local cost = t:buyUpgrade(b.index)
                    self.resources = self.resources - cost
                    self.stats.spent = self.stats.spent + cost
                    require('systems.audio').play("upgrade")
                end
                return
            end
        end
        return
    end

    -- HUD
    if self:pointInRect(x, y, self.ui.startWave) then
        self.ui.startWave.onClick()
        return
    end
    if self:pointInRect(x, y, self.ui.speed) then
        self:cycleSpeed()
        return
    end
    if self:pointInRect(x, y, self.ui.pauseButton) then
        self:pause()
        return
    end
    for _, b in ipairs(self:getAbilityButtons()) do
        if self:pointInRect(x, y, b) then
            if self.hero and self.hero:castAbility(b.index, self, true) then self.manualCasts = true end
            return
        end
    end
    for _, b in ipairs(self:getTowerButtons()) do
        if self:pointInRect(x, y, b) then
            if self.hero then self.hero.selected = false end
            self:setFocusTower(nil)
            self:selectTowerType(b.id)
            return
        end
    end
    -- The hero's portrait selects the hero too
    local hp = self.ui.heroPanel
    if self.hero and (x - (hp.x + 38)) ^ 2 + (y - (hp.y + hp.height / 2)) ^ 2 <= 32 * 32 then
        self:setFocusTower(nil)
        self.selectedTower, self.towerPreview = nil, nil
        self.hero.selected = not self.hero.selected
        return
    end
    for _, key in ipairs({ "status", "controls", "heroPanel", "towerPanel" }) do
        if self:pointInRect(x, y, self.ui[key]) then return end
    end

    -- Place the selected tower type on the map
    if self.selectedTower then
        local ok, reason = self:placeTower(x, y, self.selectedTower)
        if ok then
            -- Keep the tower selected for repeat placement while affordable
            local data = self.towerData[self.selectedTower]
            if data.cost > self.resources then
                self.selectedTower = nil
                self.towerPreview = nil
            end
        else
            self:showError(GameState.BUILD_ERRORS[reason] or "Can't build there")
        end
        return
    end

    local hero = self.hero
    -- Click the hero to select it
    if hero and hero:isUnder(x, y) then
        self:setFocusTower(nil)
        hero.selected = not hero.selected
        return
    end

    -- Hero selected: click the road to send it there
    if hero and hero.selected then
        if self:onRoad(x, y) then
            if hero:commandMove(x, y, self) then
                self.heroMoved = true
                hero.selected = false
            else
                self:showError("The hero can't get there")
            end
        else
            self:showError("Heroes move along the road")
        end
        return
    end

    -- Click a tower to open its card
    local t = self:towerAt(x, y)
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
        if self.hero:castAbility(slots[key], self, true) then self.manualCasts = true end
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
    elseif key == "space" then
        self:startNextWave()
    elseif key == "1" or key == "2" or key == "3" then
        local b = self:getTowerButtons()[tonumber(key)]
        if b then self:selectTowerType(b.id) end
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

function GameState:enter(previous, faction, hero)
    if faction and hero then
        self:setup(faction, hero)
    end
    require('systems.audio').playMusic("game")
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
    require('systems.fx').update(dt)
    self:updateHints(dt)
    
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
            self.stats.leaks[self.wave] = (self.stats.leaks[self.wave] or 0) + enemy.damage
            require('systems.fx').lifeLost(self.endX, self.endY, enemy.damage)
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
            require('systems.fx').gold(enemy.x, enemy.y, enemy.value)
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
            -- Every wave out on the field pays its clear bonus now
            local bonus = self.pendingBonus or self.waves[self.wave].bonus
            self.pendingBonus = 0
            self.resources = self.resources + bonus
            self.lastWaveBonus, self.bonusLabel = bonus, "wave bonus"
            self.waveBonusFlash = 2.5

            if self.wave >= self.maxWaves then
                self:gameOver(true)
            end
        end
    end
    
    -- Update tower preview
    if self.towerPreview then
        local mouseX, mouseY = love.mouse.getPosition()
        self.towerPreview.x, self.towerPreview.y = mouseX, mouseY
        self.towerPreview.canPlace = self:canPlaceTower(mouseX, mouseY)
    end
end

-- The next wave can be called early once the current one has finished
-- arriving (its spawn queue is empty), while its enemies are still out
function GameState:canCallEarly()
    return self.waveInProgress and #self.waveEnemies == 0 and self.wave < self.maxWaves and not self.isGameOver
end

-- Gold for calling the next wave early: more for later waves
function GameState:earlyBonus()
    return 15 + 3 * (self.wave + 1)
end

-- Start the next wave, or call it early (see canCallEarly). Waves can
-- overlap; each wave's clear bonus is paid when the field is next clear.
function GameState:startNextWave()
    if self.wave >= self.maxWaves or self.isGameOver then return end
    local earlyGold
    if self.waveInProgress then
        if not self:canCallEarly() then return end
        earlyGold = self:earlyBonus() -- the amount the button showed
    end

    self.wave = self.wave + 1
    require('systems.audio').play("wave_start")
    self.waveInProgress = true

    -- Copy the planned spawns (each keeps its wave's health); the plan
    -- stays intact for the HUD
    local plan = self.waves[self.wave]
    self.waveEnemies = self.waveEnemies or {}
    if #self.waveEnemies == 0 then self.enemySpawnTimer = 0 end
    for _, e in ipairs(plan.entries) do
        self.waveEnemies[#self.waveEnemies + 1] = { type = e.type, path = e.path, delay = e.delay, healthMult = plan.healthMult }
    end
    self.waveHealthMult = plan.healthMult
    self.pendingBonus = (self.pendingBonus or 0) + plan.bonus

    if earlyGold then
        self.resources = self.resources + earlyGold
        self.earlyCalls = (self.earlyCalls or 0) + 1
        self.lastWaveBonus, self.bonusLabel, self.waveBonusFlash = earlyGold, "early call", 2.5
    end
end

-- Create one enemy on road `pathIndex` and add it to the game
function GameState:addEnemy(enemyType, pathIndex, healthMult)
    local Enemy = require("systems.enemy")
    local road = self.roads[pathIndex] or self.roads[1]
    local enemy = Enemy.create(enemyType, road)
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
        self:addEnemy(entry.type, entry.path, entry.healthMult or self.waveHealthMult)
    end
end

-- A necromancer raises a weaker skeleton where it stands
function GameState:raiseMinion(caster)
    local s = caster.summon
    local e = self:addEnemy(s.type, 1, (self.waveHealthMult or 1) * s.healthMult)
    if not e then return end
    -- Same road and spot, a little to one side
    local Enemy = require("systems.enemy")
    local size = Enemy.SIZES[e.size]
    local maxOffset = math.max(0, caster.road.width / 2 - size.radius - Enemy.LANE_MARGIN)
    e.road, e.piece = caster.road, caster.piece
    e.offset = math.max(-maxOffset, math.min(maxOffset, caster.offset + (love.math.random() - 0.5) * 24))
    e:placeAt(caster.distance)
    e.value = s.value
    e.raised = true
    self.raisedCount = (self.raisedCount or 0) + 1
end

function GameState:draw()
    -- The map fills the screen; the HUD, tooltip and overlays float over it
    local Level = require('systems.level')
    if self.mapImage then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.mapImage, 0, 0)
    end
    if self.built and #self.built.portals > 0 then
        Level.drawPortals(self.built, self.mapTime or 0)
    end
    -- Build zones only while placing a tower, so they never sit over the art
    if self.towerPreview then
        Level.drawZones(self.built, self.mapTime or 0)
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
        drawables[#drawables + 1] = { y = enemy.y + 8, obj = enemy }
    end
    for _, u in ipairs(self.units) do
        drawables[#drawables + 1] = { y = u.y + 8, obj = u }
    end
    table.sort(drawables, function(a, b) return a.y < b.y end)
    for _, d in ipairs(drawables) do
        d.obj:draw()
    end

    local mx, my = love.mouse.getPosition()
    -- Range of the selected tower, or the tower under the mouse
    if self.focusTower then
        self.focusTower:drawRange()
    elseif not self.towerPreview then
        local t = self:towerAt(mx, my)
        if t then t:drawRange() end
    end

    -- Hero selected: a ring where it would go when the mouse is on the road
    if self.hero and self.hero.selected then
        if self:onRoad(mx, my) then
            love.graphics.setColor(1, 0.9, 0.3, 0.85)
            love.graphics.setLineWidth(2)
            love.graphics.ellipse("line", mx, my + 6, 16, 7)
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
    love.graphics.setFont(self.fonts.small)
    require('systems.fx').draw()

    -- Tower being placed: its footprint (green where it can stand), a ghost
    -- of the tower and its range
    local pv = self.towerPreview
    if pv then
        if pv.canPlace then
            love.graphics.setColor(0.3, 1, 0.4, 0.45)
        else
            love.graphics.setColor(1, 0.25, 0.2, 0.45)
        end
        love.graphics.ellipse("fill", pv.x, pv.y, 22, 10)
        local Tower = require("systems.tower")
        local img = Tower.images and Tower.images[pv.type]
        if img then
            Tower.drawPainted(img, pv.x, pv.y, Tower.DRAW_WIDTH, pv.canPlace and 0.65 or 0.35, false)
        end
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("line", pv.x, pv.y, pv.range)
    end

    -- Red edge flash when a life is lost
    require('systems.fx').drawScreen(0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw UI
    self.ui:draw()
    self:drawFocusPanel()
    self:drawHint()
    if self.freezeCharge then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(0.6, 0.85, 1, 1)
        love.graphics.print("F: Freeze Potion ready", self.ui.heroPanel.x + 4,
            self.ui.heroPanel.y - self.fonts.small:getHeight() - 4)
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
    local y = love.graphics.getHeight() / 2 + 110
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
    love.graphics.printf(self.victory and "VICTORY!" or "DEFEAT", 0, sh / 2 - 200, sw, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf(self.level.name, 0, sh / 2 - 150, sw, "center")

    -- Stars
    if self.victory then
        local stars = self.stars or 1
        for i = 1, 3 do
            local cx, cy = sw / 2 + (i - 2) * 46, sh / 2 - 100
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

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(self.fonts.small)
    local s = self.summary or self:gameSummary()
    local lines = {
        string.format("Waves %d / %d     Lives %d / %d     +%d shop gold", self.wave, self.maxWaves,
            math.max(0, self.lives), self.startLives, self.shopGoldAwarded or 0),
        string.format("Enemies slain %d     Towers built %d     Gold spent %d%s", s.kills, s.built, s.spent,
            s.earlyCalls > 0 and string.format("     Early calls %d", s.earlyCalls) or ""),
        s.topTower and string.format("Top tower: %s, %d damage", s.topTower, s.topDamage) or "No tower dealt damage",
    }
    if self.hero then
        lines[#lines + 1] = string.format("%s dealt %d damage and is level %d", self.hero.name, s.heroDamage, self.hero.level)
    end
    for _, a in ipairs(self.newAchievements or {}) do
        lines[#lines + 1] = "Achievement unlocked: " .. a.name
    end
    if #s.leaks == 0 then
        lines[#lines + 1] = "No lives lost"
    else
        local parts = {}
        for _, l in ipairs(s.leaks) do parts[#parts + 1] = string.format("wave %d (-%d)", l.wave, l.lives) end
        lines[#lines + 1] = "Lives lost on " .. table.concat(parts, ", ")
    end
    local text = table.concat(lines, "\n")
    local _, wrapped = self.fonts.small:getWrap(text, 660)
    love.graphics.setColor(0.06, 0.06, 0.1, 0.85)
    love.graphics.rectangle("fill", sw / 2 - 345, sh / 2 - 72, 690, #wrapped * self.fonts.small:getHeight() + 24, 8, 8)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.printf(text, sw / 2 - 330, sh / 2 - 60, 660, "center")

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

-- Build a tower of `type` standing at (x, y). Returns true, or false and
-- why not ("zone", "road", "tower", "hud", "gold", "type")
function GameState:placeTower(x, y, type)
    local ok, reason = self:canPlaceTower(x, y)
    if not ok then return false, reason end

    local towerData = self.towerData[type]
    if not towerData then
        self:showError("Invalid tower type: " .. tostring(type))
        return false, "type"
    end
    if self.resources < towerData.cost then
        self:showError("Not enough resources!")
        return false, "gold"
    end

    require('systems.audio').play("place")
    self.stats.built = self.stats.built + 1
    self.stats.spent = self.stats.spent + towerData.cost
    self.resources = self.resources - towerData.cost

    local Tower = require("systems.tower")
    local tower = Tower.create(type, x, y, self.towerMods)
    table.insert(self.towers, tower)
    return true
end

-- Whether a tower can stand at (x, y): inside a build zone, clear of the
-- road, the HUD and other towers. Returns true, or false and the reason.
function GameState:canPlaceTower(x, y)
    return require('systems.level').canBuild(self.built, x, y, self.towers)
end

function GameState:loadMap(level)
    local Level = require('systems.level')
    local built = Level.build(level)
    self.built = built
    self.roads = built.roads          -- one systems/path.lua Path per road
    -- Where lives are lost: the end of the first road, kept on screen
    local r1 = built.roads[1]
    self.endX = math.max(20, math.min(built.width - 20, r1.xs[#r1.xs]))
    self.endY = math.max(20, math.min(built.height - 20, r1.ys[#r1.ys]))

    -- Ground (painted plate or generated) with the roads drawn on top from
    -- the level data, so the roads always match where enemies walk
    self.mapImage = Level.renderMap(level, built, 1)
end

function GameState:gameOver(victory)
    self.isGameOver = true
    self.victory = victory
    local Audio = require('systems.audio')
    Audio.stopMusic()
    Audio.play(victory and "victory" or "defeat")
    
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

    self.summary = self:gameSummary()

    -- Totals and achievements for the profile
    local types = {}
    for _, t in ipairs(self.towers) do types[t.id] = true end
    local typeCount = 0
    for _ in pairs(types) do typeCount = typeCount + 1 end
    local ok, new = pcall(Save.recordGame, {
        victory = victory,
        livesLost = self.startLives - math.max(0, self.lives),
        towersBuilt = self.stats.built,
        wavesCleared = victory and self.wave or math.max(0, self.wave - 1),
        shopGold = self.shopGoldAwarded,
        towerTypes = typeCount,
        factionTowerCount = #self.factionData.towers,
    })
    self.newAchievements = ok and new or {}
end

-- Numbers for the end screen
function GameState:gameSummary()
    local s = self.stats or {}
    local top
    for _, t in ipairs(self.towers) do
        if (t.damageDealt or 0) > 0 and (not top or t.damageDealt > top.damageDealt) then top = t end
    end
    local leaks = {}
    for w = 1, self.maxWaves do
        if s.leaks and s.leaks[w] then leaks[#leaks + 1] = { wave = w, lives = s.leaks[w] } end
    end
    return {
        kills = s.kills or 0,
        built = s.built or 0,
        spent = s.spent or 0,
        topTower = top and top.name, topDamage = top and math.floor(top.damageDealt),
        heroDamage = self.hero and math.floor(self.hero.damageDealt or 0) or 0,
        leaks = leaks,
        earlyCalls = self.earlyCalls or 0,
    }
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
    local y = self.ui and (self.ui.status.y + self.ui.status.height + 44) or 100
    
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