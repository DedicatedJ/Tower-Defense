-- Towers. Stats, behaviors and upgrades come from data/factions.lua; this
-- module gives them life: targeting, homing projectiles, on-hit effects,
-- healing pulses, summoning, draining, hybrid light/dark damage, elemental
-- shots, rage, upgrades and selling.
--
-- The game state passed to update() must provide:
--   enemies, units, effects, projectiles      lists
--   towerMods                                  multipliers (states/game.lua)
--   spawnMinion(def, x, y, count) -> units    add minions
--   nearestRoadPoint(x, y, r) -> x, y         road center point within r of a
--                                              point (nil if none)

local Factions = require 'data.factions'
local Effects = require 'systems.effects'
local Audio = require 'systems.audio'
local Fx = require 'systems.fx'

local Tower = {}

local TowerInstance = {}
TowerInstance.__index = TowerInstance

Tower.SELL_REFUND = 0.7
Tower.PROJECTILE_SPEED = 320
Tower.MARK_DURATION = 3
Tower.UNDEAD_LIGHT_BONUS = 1.25 -- light hurts undead more
Tower.LIVING_DARK_BONUS = 1.25  -- dark hurts the living more

local FACTION_COLORS = {
    radiant = { 0.95, 0.8, 0.4 },
    shadow = { 0.55, 0.35, 0.8 },
    twilight = { 0.45, 0.65, 0.95 },
}

local PROJECTILE_COLORS = {
    holy = { 1, 0.9, 0.4 }, fire = { 1, 0.5, 0.15 }, bolt = { 0.85, 0.85, 0.9 },
    poison = { 0.45, 0.95, 0.3 }, void = { 0.65, 0.3, 0.95 }, soul = { 0.4, 1, 0.8 },
    hybrid = { 0.95, 0.85, 1 }, frost = { 0.6, 0.85, 1 },
}

------------------------------------------------------------------------
-- Setup
------------------------------------------------------------------------
function Tower.init()
    if Tower.initialized then return end

    -- Index every tower by id, and each faction's towers in data order
    Tower.byId = {}
    Tower.byFaction = {}
    for fid, faction in pairs(Factions) do
        Tower.byFaction[fid] = {}
        for _, t in ipairs(faction.towers) do
            Tower.byId[t.id] = t
            table.insert(Tower.byFaction[fid], t)
        end
    end

    -- Generated placeholder sprites for every tower
    Tower.sprites = {}
    for id, t in pairs(Tower.byId) do
        Tower.sprites[id] = Tower.createDefaultSprite(t)
    end

    -- Painted sprites (see art/README.md), loaded once and shared by every
    -- instance. Towers without a file keep the placeholder.
    Tower.images = {}
    local loaded = {}
    for id, t in pairs(Tower.byId) do
        local path = Tower.spritePath(t)
        if path then
            if not loaded[path] then
                local ok, img = pcall(require('utils.image').smooth, path)
                if ok then
                    loaded[path] = img
                else
                    print("WARNING: Failed to load tower sprite: " .. path)
                end
            end
            Tower.images[id] = loaded[path]
        end
    end

    Tower.projectileSprites = {}
    for kind, color in pairs(PROJECTILE_COLORS) do
        Tower.projectileSprites[kind] = Tower.createDefaultProjectileSprite(color)
    end

    Tower.initialized = true
end

-- The painted sprite for a tower: its own sprites/towers/<id>.png when that
-- file exists (art batch 2), else the stand-in named in data/factions.lua,
-- else nil (a generated placeholder is drawn)
function Tower.spritePath(t)
    local own = "sprites/towers/" .. t.id .. ".png"
    if love.filesystem.getInfo(own) then return own end
    if type(t.sprite) == "string" and love.filesystem.getInfo(t.sprite) then return t.sprite end
end

-- Placeholder tower drawn in code, tinted by faction
function Tower.createDefaultSprite(tower)
    local size = 32
    local canvas = love.graphics.newCanvas(size, size)
    local color = FACTION_COLORS[tower.faction] or { 0.5, 0.5, 0.5 }
    local accent = PROJECTILE_COLORS[tower.projectileType] or { 1, 1, 1 }
    local prevCanvas = love.graphics.getCanvas() -- restored below (the frame may be drawing into one)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(color[1] * 0.55, color[2] * 0.55, color[3] * 0.55)
    love.graphics.rectangle("fill", 4, 10, 24, 20, 3, 3)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", 8, 2, 16, 14, 2, 2)
    love.graphics.setColor(accent)
    love.graphics.circle("fill", 16, 9, 4)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", 4, 10, 24, 20, 3, 3)
    love.graphics.rectangle("line", 8, 2, 16, 14, 2, 2)
    love.graphics.setCanvas(prevCanvas)
    love.graphics.setColor(1, 1, 1, 1)
    return canvas
end

function Tower.createDefaultProjectileSprite(color)
    local canvas = love.graphics.newCanvas(16, 16)
    local prevCanvas = love.graphics.getCanvas() -- restored below (the frame may be drawing into one)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(color)
    love.graphics.circle("fill", 8, 8, 4)
    love.graphics.setColor(color[1], color[2], color[3], 0.4)
    love.graphics.circle("fill", 8, 8, 7)
    love.graphics.setCanvas(prevCanvas)
    love.graphics.setColor(1, 1, 1, 1)
    return canvas
end

-- A faction's towers, in data order (tower upgrade screen)
function Tower.getTowersByFaction(factionId)
    if not Tower.initialized then Tower.init() end
    return Tower.byFaction[factionId] or {}
end

-- A faction's towers keyed by id (game tower panel)
function Tower.getSet(factionId)
    local set = {}
    for _, t in ipairs(Tower.getTowersByFaction(factionId)) do set[t.id] = t end
    return set
end

------------------------------------------------------------------------
-- Instances
------------------------------------------------------------------------
-- Flatten a tower's data into the instance fields behaviors and
-- upgrades work on.
local function flatten(inst, d)
    inst.damage = d.damage
    inst.fireRate = d.fireRate
    inst.range = d.range
    inst.critChance = d.critChance or 0
    inst.critMult = d.critMult or 2
    if d.heal then
        inst.healAmount = d.heal.amount
        inst.healInterval = d.heal.interval
        inst.healTimer = d.heal.interval
    end
    for _, e in ipairs(d.onHit or {}) do
        if e.type == "burn" then inst.burnDps, inst.burnDuration = e.dps, e.duration end
        if e.type == "poison" then inst.poisonDps, inst.poisonDuration = e.dps, e.duration end
    end
    if d.summon then
        inst.summonInterval = d.summon.interval
        inst.summonMax = d.summon.max
        inst.summonMinion = d.summon.minion
        inst.summonTimer = 2 -- first minion shortly after building
        inst.minions = {}
    end
    if d.convert then
        inst.convertChance = d.convert.chance
        inst.convertMinion = d.convert.minion
    end
    if d.drain then inst.drainPercent = d.drain.percent end
    if d.hybrid then
        inst.lightDamage = d.hybrid.light
        inst.darkDamage = d.hybrid.dark
    end
    if d.elemental then
        inst.elemBurnDps = d.elemental.burnDps
        inst.elemBurnDuration = d.elemental.burnDuration
        inst.freezeDuration = d.elemental.freezeDuration
        inst.elemIndex = 0
    end
end

local function applyMod(inst, mod)
    if mod.set ~= nil then
        inst[mod.stat] = mod.set
    elseif mod.mult then
        inst[mod.stat] = (inst[mod.stat] or 0) * mod.mult
    elseif mod.add then
        inst[mod.stat] = (inst[mod.stat] or 0) + mod.add
    end
end

-- A tower standing at (x, y), the middle of its base in screen pixels.
-- ctx: towerMods from the game (faction bonus, hero passive, shop items)
function Tower.create(towerId, x, y, ctx)
    if not Tower.initialized then Tower.init() end
    local d = Tower.byId[towerId]
    if not d then
        print("ERROR: Invalid tower type: " .. tostring(towerId))
        return nil
    end
    ctx = ctx or {}

    local inst = setmetatable({}, TowerInstance)
    inst.id = d.id
    inst.data = d
    inst.name = d.name
    inst.description = d.description
    inst.faction = d.faction
    inst.projectileType = d.projectileType
    inst.cost = d.cost
    inst.spent = d.cost
    inst.x, inst.y = x, y
    inst.statuses = {}
    inst.fireCooldown = 0
    inst.target = nil
    inst.bought = {}
    inst.mods = ctx
    flatten(inst, d)

    -- Hero passives that change one tower type's stats
    for _, m in ipairs(ctx.towerStat or {}) do
        if m.tower == d.id then applyMod(inst, m) end
    end
    -- Shop items
    inst.range = inst.range * (ctx.rangeMult or 1)
    inst.fireRate = inst.fireRate * (ctx.fireRateMult or 1)

    inst.painted = Tower.images[d.id] ~= nil
    inst.spriteImg = Tower.images[d.id] or Tower.sprites[d.id]
    return inst
end

function TowerInstance:getCenter()
    return self.x, self.y
end

------------------------------------------------------------------------
-- Upgrades and selling
------------------------------------------------------------------------
function TowerInstance:upgradeData(i) return self.data.upgrades[i] end

function TowerInstance:canBuyUpgrade(i, gold)
    local up = self.data.upgrades[i]
    return up and not self.bought[i] and gold >= up.cost
end

-- Buy upgrade i (each once). Returns its cost, or nil.
function TowerInstance:buyUpgrade(i)
    local up = self.data.upgrades[i]
    if not up or self.bought[i] then return nil end
    for _, m in ipairs(up.mods) do applyMod(self, m) end
    self.bought[i] = true
    self.spent = self.spent + up.cost
    self.upgradeFlash = 0.6
    return up.cost
end

function TowerInstance:sellValue()
    return math.floor(self.spent * Tower.SELL_REFUND)
end

-- Kept for older callers
function TowerInstance:upgrade(i) return self:buyUpgrade(i) ~= nil end

------------------------------------------------------------------------
-- Damage
------------------------------------------------------------------------
function TowerInstance:isHybrid() return self.lightDamage ~= nil end

function TowerInstance:raging()
    return self.rageMult and self.rageTimer and (self.rageTimer % (self.rageInterval + self.rageDuration)) >= self.rageInterval
end

-- Damage of one shot against this target (before the enemy's armor)
function TowerInstance:shotDamage(target)
    local mods = self.mods
    local dmg
    if self:isHybrid() then
        local undead = target.nature == "undead"
        local light, dark = self.lightDamage, self.darkDamage
        if self.hybridSmart then
            dmg = (light + dark) * Tower.UNDEAD_LIGHT_BONUS -- all of it in the type it is weak to
        else
            dmg = light * (undead and Tower.UNDEAD_LIGHT_BONUS or 1)
                + dark * (undead and 1 or Tower.LIVING_DARK_BONUS)
        end
        dmg = dmg * (mods.hybridMult or 1)
    else
        dmg = self.damage
    end
    dmg = dmg * (mods.damageMult or 1) * Effects.damageDealtMult(self)
    if self:raging() then dmg = dmg * self.rageMult end
    if self.elementalBonus and target.statuses and (target.statuses.burn or target.statuses.freeze) then
        dmg = dmg * (1 + self.elementalBonus)
    end
    local crit = false
    if self.critChance > 0 and love.math.random() < self.critChance then
        dmg = dmg * self.critMult
        crit = true
    end
    return dmg, crit
end

function TowerInstance:onHit(target)
    if target.dead then return end
    local dmg, crit = self:shotDamage(target)
    Fx.damage(target, target:takeDamage(dmg, self), crit)
    self.hits = (self.hits or 0) + 1
    if crit then self.crits = (self.crits or 0) + 1 end
    if target.dead then return end
    local mods = self.mods
    local ctx = { source = self, dotMult = { poison = mods.poisonMult or 1 } }
    if self.burnDps then
        Effects.apply(target, { type = "burn", dps = self.burnDps, duration = self.burnDuration }, ctx)
    end
    if self.poisonDps then
        Effects.apply(target, { type = "poison", dps = self.poisonDps, duration = self.poisonDuration }, ctx)
    end
    if self.markMult then
        Effects.apply(target, { type = "mark", mult = self.markMult, duration = Tower.MARK_DURATION }, ctx)
    end
    if self.elemBurnDps then
        local burn = { type = "burn", dps = self.elemBurnDps, duration = self.elemBurnDuration }
        local freeze = { type = "freeze", duration = self.freezeDuration }
        if self.fusion then
            Effects.apply(target, burn, ctx)
            Effects.apply(target, freeze, ctx)
        else
            self.elemIndex = (self.elemIndex % 2) + 1
            Effects.apply(target, self.elemIndex == 1 and burn or freeze, ctx)
        end
    end
end

------------------------------------------------------------------------
-- Update
------------------------------------------------------------------------
local function alive(e) return e and not e.dead and not e.removed and not e.reachedEnd end

local function dist(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function pulse(game, x, y, r, color)
    table.insert(game.effects, {
        t = 0, done = false,
        update = function(fx, dt) fx.t = fx.t + dt; if fx.t > 0.4 then fx.done = true end; return fx.done end,
        draw = function(fx)
            local k = fx.t / 0.4
            love.graphics.setColor(color[1], color[2], color[3], 0.35 * (1 - k))
            love.graphics.circle("line", x, y, r * (0.3 + 0.7 * k))
        end,
    })
end

function TowerInstance:update(dt, game)
    Effects.update(self, dt)
    if self.upgradeFlash then self.upgradeFlash = math.max(0, self.upgradeFlash - dt) end
    local x, y = self:getCenter()

    -- Holy Bastion: heal allied units in range
    if self.healAmount then
        self.healTimer = self.healTimer - dt
        if self.healTimer <= 0 then
            self.healTimer = self.healInterval
            local healed = false
            for _, u in ipairs(game.units) do
                if not u.dead and u.health < u.maxHealth and dist(x, y, u.x, u.y) <= self.range then
                    u:heal(self.healAmount)
                    healed = true
                    self.healed = (self.healed or 0) + self.healAmount
                end
            end
            if healed then pulse(game, x, y, self.range, { 1, 0.95, 0.5 }) end
        end
    end

    -- Oblivion Engine: raise a minion on the road in range
    if self.summonInterval then
        local live = {}
        for _, m in ipairs(self.minions) do
            if not m.dead and not m.removed then live[#live + 1] = m end
        end
        self.minions = live
        self.summonTimer = self.summonTimer - dt
        if self.summonTimer <= 0 then
            self.summonTimer = self.summonInterval
            if #self.minions < self.summonMax then
                local mx, my = game:nearestRoadPoint(x, y, self.range)
                if mx then
                    for _, m in ipairs(game:spawnMinion(self.summonMinion, mx, my, 1)) do
                        table.insert(self.minions, m)
                    end
                    self.summoned = (self.summoned or 0) + 1
                end
            end
        end
    end

    -- Soul Forge upgrade: damage aura
    if self.auraDps then
        for _, e in ipairs(game.enemies) do
            if alive(e) and dist(x, y, e.x, e.y) <= self.auraRange then
                e:takeDamage(self.auraDps * dt, self, { dot = true })
            end
        end
    end

    -- Elemental Nexus upgrade: rage cycle
    if self.rageMult then self.rageTimer = (self.rageTimer or 0) + dt end

    -- Pick a target: the enemy furthest along the road in range
    if not alive(self.target) or dist(x, y, self.target.x, self.target.y) > self.range then
        self.target = nil
        local best
        for _, e in ipairs(game.enemies) do
            if alive(e) and dist(x, y, e.x, e.y) <= self.range then
                if not best or e:progress() > best:progress() then best = e end
            end
        end
        self.target = best
    end

    -- Eclipse Monolith: drain a share of max health per second
    if self.drainPercent then
        if self.drainArea then
            for _, e in ipairs(game.enemies) do
                if alive(e) and dist(x, y, e.x, e.y) <= self.drainArea then
                    e:takeDamage(e.maxHealth * self.drainPercent * dt, self, { dot = true })
                end
            end
        elseif self.target then
            self.target:takeDamage(self.target.maxHealth * self.drainPercent * dt, self, { dot = true })
        end
    end

    -- Fire
    self.fireCooldown = self.fireCooldown - dt * Effects.attackRateMult(self)
    if self.target and self.fireCooldown <= 0 then
        self.fireCooldown = 1 / self.fireRate
        self:fire(game, x, y)
    end
end

function TowerInstance:fire(game, x, y)
    Audio.shot(self.projectileType)
    local tower = self
    local target = self.target
    local sprite = Tower.projectileSprites[self.projectileType]
    table.insert(game.projectiles, {
        x = x, y = y - 14, target = target, destroyed = false,
        speed = Tower.PROJECTILE_SPEED,
        update = function(p, dt)
            if target.dead or target.removed then
                p.destroyed = true
                return
            end
            local tx, ty = target.x, target.y - 6
            local d = dist(p.x, p.y, tx, ty)
            local step = p.speed * dt
            if d <= math.max(step, target.radius or 12) then
                tower:onHit(target)
                Audio.play("enemy_hit")
                p.destroyed = true
                return
            end
            p.x = p.x + (tx - p.x) / d * step
            p.y = p.y + (ty - p.y) / d * step
        end,
        draw = function(p)
            love.graphics.setColor(1, 1, 1, 1)
            if sprite then
                love.graphics.draw(sprite, p.x, p.y, 0, 1, 1, 8, 8)
            else
                love.graphics.circle("fill", p.x, p.y, 4)
            end
        end,
    })
end

------------------------------------------------------------------------
-- Drawing
------------------------------------------------------------------------
Tower.DRAW_WIDTH = 44

-- Draw a painted tower image standing on the cell centered at (cx, cy).
-- Painted towers sit on a diamond base that spans the image width; in this
-- three-quarter view the diamond is half as tall as it is wide, so its
-- center is a quarter of the width above the bottom edge. That point goes
-- on the cell center. No per-asset numbers needed.
function Tower.drawPainted(img, cx, cy, drawWidth, alpha, shadow)
    local w, h = img:getDimensions()
    local s = drawWidth / w
    if shadow then
        love.graphics.setColor(0, 0, 0, 0.28 * (alpha or 1))
        love.graphics.ellipse("fill", cx + drawWidth * 0.08, cy + drawWidth * 0.06,
            drawWidth * 0.46, drawWidth * 0.22)
    end
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(img, cx, cy, 0, s, s, w / 2, h - w / 4)
end

-- Draw a tower type as an icon fitted inside a box (UI panels)
function Tower.drawIcon(id, x, y, boxW, boxH)
    if not Tower.initialized then Tower.init() end
    local img = Tower.images[id]
    if img then
        local w, h = img:getDimensions()
        local s = math.min(boxW / w, boxH / h)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, x + boxW / 2, y + boxH / 2, 0, s, s, w / 2, h / 2)
        return true
    end
    local sprite = Tower.sprites[id]
    if sprite then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, x + boxW / 2, y + boxH / 2, 0, 1, 1,
            sprite:getWidth() / 2, sprite:getHeight() / 2)
        return true
    end
    return false
end

-- Range circle for the hovered or selected tower
function TowerInstance:drawRange()
    local cx, cy = self:getCenter()
    love.graphics.setColor(0.2, 0.5, 0.8, 0.15)
    love.graphics.circle("fill", cx, cy, self.range)
    love.graphics.setColor(0.2, 0.5, 0.8, 0.5)
    love.graphics.circle("line", cx, cy, self.range)
    if self.drainArea then
        love.graphics.setColor(0.6, 0.3, 0.9, 0.4)
        love.graphics.circle("line", cx, cy, self.drainArea)
    end
    if self.auraRange then
        love.graphics.setColor(0.4, 1, 0.7, 0.4)
        love.graphics.circle("line", cx, cy, self.auraRange)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function TowerInstance:draw()
    local cx, cy = self:getCenter()
    if self.selected then
        love.graphics.setColor(1, 0.9, 0.3, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.ellipse("line", cx, cy + 2, 20, 9)
        love.graphics.setLineWidth(1)
    end
    if self:raging() or (self.statuses and (self.statuses.damageBoost or self.statuses.haste)) then
        love.graphics.setColor(1, 0.5, 0.2, 0.35)
        love.graphics.ellipse("fill", cx, cy + 2, 20, 9)
    end

    if self.painted then
        Tower.drawPainted(self.spriteImg, cx, cy, Tower.DRAW_WIDTH, 1, true)
    else
        love.graphics.setColor(0, 0, 0, 0.28)
        love.graphics.ellipse("fill", cx + 3, cy + 6, 16, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.spriteImg, cx, cy - 6, 0, 1, 1,
            self.spriteImg:getWidth() / 2, self.spriteImg:getHeight() / 2)
    end

    -- One gold pip per upgrade bought
    local n = 0
    for i = 1, #self.data.upgrades do if self.bought[i] then n = n + 1 end end
    for i = 1, n do
        love.graphics.setColor(1, 0.85, 0.3, 1)
        love.graphics.circle("fill", cx - 6 + (i - 1) * 8, cy + 12, 3)
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.circle("line", cx - 6 + (i - 1) * 8, cy + 12, 3)
    end
    if self.upgradeFlash and self.upgradeFlash > 0 then
        love.graphics.setColor(1, 0.9, 0.4, self.upgradeFlash)
        love.graphics.circle("line", cx, cy - 10, 26 - self.upgradeFlash * 10)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Tower
