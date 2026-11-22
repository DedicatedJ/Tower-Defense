-- Allied units: heroes and minions. Units stand on the road, block ground
-- enemies (an enemy held by a unit stops and fights it) and fight back.
-- Heroes level up, cast abilities and respawn; minions expire or die.
--
-- The game state passed to update() must provide:
--   enemies, units, towers                     lists
--   effects                                    list of visual effects
--   mods                                       multipliers (see states/game.lua)
--   spawnMinion(def, x, y, count)              add minions
--   nearestRoadCell(x, y) -> gx, gy            road cell closest to a point
--   cellCenter(gx, gy) -> x, y
--   isRoad(gx, gy) -> bool

local Effects = require("systems.effects")
local Audio = require("systems.audio")
local Fx = require("systems.fx")
local Enemy = require("systems.enemy")

local Unit = {}
Unit.__index = Unit

Unit.MELEE_ENGAGE = 70     -- melee units step out this far from their spot to block
Unit.RANGED_BLOCK = 26     -- ranged units block only enemies that walk into them
Unit.MELEE_REACH = 20      -- melee attack reach
Unit.RESPAWN_TIME = 10
Unit.XP_PER_LEVEL = 200
Unit.MAX_LEVEL = 10
Unit.LEVEL_BONUS = 0.10    -- +10% health and damage per level
Unit.XP_RADIUS = 300
Unit.FOOT_OFFSET = 10      -- same ground line as enemies
Unit.HERO_HEIGHT = 44      -- drawn height of a hero walk sheet figure (a little over a zombie)

Unit.ROLE_COLORS = {
    tank = { 0.95, 0.8, 0.3 }, healer = { 1, 1, 0.6 }, dps = { 1, 0.45, 0.3 },
    summoner = { 0.6, 1, 0.6 }, cc = { 0.75, 0.5, 1 }, support = { 0.5, 0.85, 1 },
}

local function dist(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

------------------------------------------------------------------------
-- Portraits: cropped to the face and masked to a circle once, cached
------------------------------------------------------------------------
local portraitCache = {}
function Unit.portrait(path)
    if not path or not love.filesystem.getInfo(path) then return nil end
    if portraitCache[path] ~= nil then return portraitCache[path] or nil end
    local ok, img = pcall(function()
        local src = love.image.newImageData(path)
        local w, h = src:getDimensions()
        local side = math.floor(math.min(w, h) * 0.6)
        local x0 = math.floor((w - side) / 2)
        local y0 = math.floor(h * 0.04)
        local face = love.image.newImageData(side, side)
        face:paste(src, 0, 0, x0, y0, side, side)
        local r = side / 2
        face:mapPixel(function(x, y, cr, cg, cb)
            local d = math.sqrt((x + 0.5 - r) ^ 2 + (y + 0.5 - r) ^ 2)
            return cr, cg, cb, math.max(0, math.min(1, r - d))
        end)
        return require('utils.image').smooth(face)
    end)
    portraitCache[path] = ok and img or false
    if not ok then print("WARNING: could not load portrait " .. path) end
    return ok and img or nil
end

------------------------------------------------------------------------
-- Construction
------------------------------------------------------------------------
local function baseUnit(x, y)
    return setmetatable({
        x = x, y = y, holdX = x, holdY = y,
        statuses = {}, blocking = {},
        attackCooldown = 0, animTime = 0, direction = "down",
        dead = false, removed = false,
        lunge = 0,
    }, Unit)
end

-- opts: level, xp, statMods {health, damage, speed} multipliers
function Unit.newHero(heroData, factionData, x, y, opts)
    opts = opts or {}
    local u = baseUnit(x, y)
    u.kind = "hero"
    u.id = heroData.id
    u.name = heroData.name
    u.role = heroData.role
    u.data = heroData
    u.faction = factionData.id
    u.base = heroData.stats
    u.statMods = opts.statMods or {}
    u.level = math.max(1, math.min(Unit.MAX_LEVEL, opts.level or 1))
    u.xp = opts.xp or 0
    u.passive = heroData.passive
    u.portraitImage = Unit.portrait(heroData.portrait)
    -- Walk sheet (art batch 2): sprites/heroes/<id>.png plus its .lua
    if Enemy.loadSheet("hero_" .. heroData.id, "sprites/heroes/" .. heroData.id .. ".png") then
        u.sheetKey = "hero_" .. heroData.id
    end
    u.abilities = {}
    for i, ab in ipairs(heroData.abilities) do
        u.abilities[i] = { data = ab, cooldown = 0, flash = 0, altIndex = 0 }
    end
    u.mode = nil -- Dusk Shift toggle state
    u:recomputeStats()
    u.health = u.maxHealth
    return u
end

-- def: {sheet, tint, health, damage, attackRate, speed, armor, duration}
-- opts: healthMult, durationMult
function Unit.newMinion(def, x, y, opts)
    opts = opts or {}
    local u = baseUnit(x, y)
    u.kind = "minion"
    u.sheet = def.sheet
    u.tint = def.tint
    u.maxHealth = def.health * (opts.healthMult or 1)
    u.health = u.maxHealth
    u.damage = def.damage
    u.attackRate = def.attackRate or 1
    u.range = Unit.MELEE_REACH
    u.speed = def.speed or 50
    u.armor = def.armor or 0
    u.blockCount = 1
    u.melee = true
    u.remaining = def.duration and def.duration * (opts.durationMult or 1) or nil
    u.drawHeight = 34
    return u
end

function Unit:recomputeStats()
    local lv = 1 + Unit.LEVEL_BONUS * (self.level - 1)
    local ratio = self.maxHealth and (self.health / self.maxHealth) or 1
    self.maxHealth = self.base.health * lv * (self.statMods.health or 1)
    self.health = self.maxHealth * ratio
    self.damage = self.base.damage * lv * (self.statMods.damage or 1)
    self.attackRate = self.base.attackRate
    self.range = self.base.range
    self.speed = self.base.speed * (self.statMods.speed or 1)
    self.armor = self.base.armor
    self.blockCount = self.base.blockCount or 1
    self.melee = self.base.range <= 60
end

------------------------------------------------------------------------
-- Health
------------------------------------------------------------------------
function Unit:takeDamage(amount, source, opts)
    if self.dead or amount <= 0 then return 0 end
    opts = opts or {}
    local dmg = amount * Effects.damageTakenMult(self)
    if not opts.ignoreArmor then
        local armor = self.armor * ((self.game and self.game.mods.allyArmorMult) or 1)
        dmg = dmg * (1 - math.min(0.9, armor))
    end
    dmg = math.min(dmg, self.health)
    self.health = self.health - dmg
    self.hitFlash = 0.15
    if self.health <= 0 then self:die() end
    return dmg
end

function Unit:heal(amount)
    if self.dead or amount <= 0 then return end
    self.health = math.min(self.maxHealth, self.health + amount * Effects.healingMult(self))
end

function Unit:release()
    for _, e in ipairs(self.blocking) do
        if e.blocker == self then e.blocker = nil end
    end
    self.blocking = {}
end

function Unit:die()
    self.dead = true
    self:release()
    Effects.clear(self)
    if self.kind == "hero" then
        self.respawnTimer = Unit.RESPAWN_TIME
        self.path = nil
    end
end

function Unit:respawn()
    self.dead = false
    self.health = self.maxHealth
    self.x, self.y = self.holdX, self.holdY
    self.respawnTimer = nil
    self.attackCooldown = 0
end

------------------------------------------------------------------------
-- Leveling
------------------------------------------------------------------------
function Unit:gainXp(n)
    if self.kind ~= "hero" or self.level >= Unit.MAX_LEVEL then return end
    self.xp = self.xp + n
    while self.xp >= Unit.XP_PER_LEVEL and self.level < Unit.MAX_LEVEL do
        self.xp = self.xp - Unit.XP_PER_LEVEL
        self.level = self.level + 1
        self:recomputeStats()
        self.levelFlash = 1.5
        Audio.play("level_up")
    end
    if self.level >= Unit.MAX_LEVEL then self.xp = 0 end
end

------------------------------------------------------------------------
-- Movement along the road
------------------------------------------------------------------------
-- Walk along road cells to (gx, gy) and hold there. Returns false if the
-- target is not a road cell or cannot be reached.
function Unit:commandMove(gx, gy, game)
    if self.dead or not game:isRoad(gx, gy) then return false end
    local sx, sy = game:nearestRoadCell(self.x, self.y)
    if not sx then return false end
    local cells = Enemy.findPath(sx, sy, gx, gy)
    if not cells or #cells == 0 then return false end
    self.path = {}
    for _, c in ipairs(cells) do
        local px, py = game:cellCenter(c.x, c.y)
        self.path[#self.path + 1] = { x = px, y = py }
    end
    self.pathIndex = 1
    self:release()
    self.holdX, self.holdY = game:cellCenter(gx, gy)
    return true
end

function Unit:stepToward(tx, ty, dt)
    local d = dist(self.x, self.y, tx, ty)
    if d < 1 then return true end
    local sp = self.speed * Effects.speedMult(self) * dt
    local dx, dy = tx - self.x, ty - self.y
    if math.abs(dx) > math.abs(dy) then
        self.direction = dx > 0 and "right" or "left"
    else
        self.direction = dy > 0 and "down" or "up"
    end
    if sp >= d then
        self.x, self.y = tx, ty
        return true
    end
    self.x = self.x + dx / d * sp
    self.y = self.y + dy / d * sp
    self.animTime = self.animTime + dt
    self.moving = true
    return false
end

------------------------------------------------------------------------
-- Combat
------------------------------------------------------------------------
local function enemyAlive(e)
    return e and not e.dead and not e.removed and not e.reachedEnd
end

function Unit:critMult()
    local p = self.passive
    if p and p.kind == "heroCrit" and love.math.random() < p.chance then
        return p.mult or 2
    end
    return 1
end

function Unit:lifestealFraction()
    local f = Effects.lifesteal(self)
    if self.passive and self.passive.kind == "heroLifesteal" then f = f + self.passive.amount end
    if self.modeLifesteal then f = f + self.modeLifesteal end
    return f
end

function Unit:attack(target, game)
    local dmg = self.damage * Effects.damageDealtMult(self) * (1 + (self.modeDamageBoost or 0)) * self:critMult()
    local dealt = target:takeDamage(dmg, self) or 0
    Fx.damage(target, dealt)
    local ls = self:lifestealFraction()
    if ls > 0 and dealt > 0 then self:heal(dealt * ls) end
    self.lunge = 1
    if not self.melee and game.effects then
        -- Ranged attack: a brief tracer from the unit to the target
        local sx, sy, tx, ty = self.x, self.y - 14, target.x, target.y - 6
        local color = (self.kind == "hero" and Unit.ROLE_COLORS[self.role]) or { 1, 1, 1 }
        table.insert(game.effects, {
            t = 0, done = false,
            update = function(fx, dt) fx.t = fx.t + dt; if fx.t > 0.12 then fx.done = true end; return fx.done end,
            draw = function(fx)
                love.graphics.setColor(color[1], color[2], color[3], 1 - fx.t / 0.12)
                love.graphics.setLineWidth(2)
                love.graphics.line(sx, sy, tx, ty)
                love.graphics.setLineWidth(1)
            end,
        })
    end
end

-- Pick up enemies to block and choose what to hit
function Unit:engage(game)
    -- Drop enemies we no longer hold
    local kept = {}
    for _, e in ipairs(self.blocking) do
        if enemyAlive(e) and e.blocker == self then kept[#kept + 1] = e end
    end
    self.blocking = kept

    -- Block more if we have room
    if #self.blocking < self.blockCount then
        local best, bestD
        local reach = self.melee and Unit.MELEE_ENGAGE or Unit.RANGED_BLOCK
        local ox, oy = self.holdX, self.holdY
        if not self.melee then ox, oy = self.x, self.y end
        for _, e in ipairs(game.enemies) do
            if enemyAlive(e) and not e.flying and not e.blocker then
                local d = dist(ox, oy, e.x, e.y)
                if d <= reach and (not bestD or d < bestD) then best, bestD = e, d end
            end
        end
        if best then
            best.blocker = self
            self.blocking[#self.blocking + 1] = best
        end
    end

    -- Target: an enemy we hold first; ranged units also shoot anything in range
    local target = self.blocking[1]
    if not target and not self.melee then
        local bestD
        for _, e in ipairs(game.enemies) do
            if enemyAlive(e) then
                local d = dist(self.x, self.y, e.x, e.y)
                if d <= self.range and (not bestD or d < bestD) then target, bestD = e, d end
            end
        end
    end
    return target
end

function Unit:update(dt, game)
    self.game = game
    self.moving = false
    self.lunge = math.max(0, self.lunge - dt * 4)
    if self.hitFlash then self.hitFlash = math.max(0, self.hitFlash - dt) end
    if self.levelFlash then self.levelFlash = math.max(0, self.levelFlash - dt) end

    if self.dead then
        if self.kind == "hero" then
            self.respawnTimer = self.respawnTimer - dt
            if self.respawnTimer <= 0 then self:respawn() end
        else
            self.removed = true
        end
        return
    end

    Effects.update(self, dt)
    if self.dead then return end

    if self.remaining then
        self.remaining = self.remaining - dt
        if self.remaining <= 0 then
            self:die()
            self.removed = true
            return
        end
    end

    if self.kind == "hero" then self:updateAbilities(dt, game) end
    if self.dead then return end

    -- Ordered to move: walk the road, no fighting on the way
    if self.path then
        local p = self.path[self.pathIndex]
        if self:stepToward(p.x, p.y, dt) then
            self.pathIndex = self.pathIndex + 1
            if self.pathIndex > #self.path then self.path = nil end
        end
        return
    end

    local target = self:engage(game)
    if target then
        local d = dist(self.x, self.y, target.x, target.y)
        if self.melee and d > Unit.MELEE_REACH then
            self:stepToward(target.x, target.y, dt)
        else
            local dx, dy = target.x - self.x, target.y - self.y
            if math.abs(dx) > math.abs(dy) then
                self.direction = dx > 0 and "right" or "left"
            else
                self.direction = dy > 0 and "down" or "up"
            end
            self.attackCooldown = self.attackCooldown - dt
            if self.attackCooldown <= 0 and Effects.canAttack(self) then
                self.attackCooldown = 1 / (self.attackRate * Effects.attackRateMult(self))
                self:attack(target, game)
            end
        end
    else
        -- Nothing to fight: return to our spot
        self:stepToward(self.holdX, self.holdY, dt)
    end
end

------------------------------------------------------------------------
-- Abilities
------------------------------------------------------------------------
local function enemiesNear(game, x, y, radius, limit)
    local list = {}
    for _, e in ipairs(game.enemies) do
        if enemyAlive(e) then
            local d = dist(x, y, e.x, e.y)
            if d <= radius then list[#list + 1] = { e = e, d = d } end
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local out = {}
    for i, it in ipairs(list) do
        if limit and i > limit then break end
        out[#out + 1] = it.e
    end
    return out
end

local function alliesNear(game, x, y, radius)
    local out = {}
    for _, u in ipairs(game.units) do
        if not u.dead and dist(x, y, u.x, u.y) <= radius then out[#out + 1] = u end
    end
    return out
end

local function towersNear(game, x, y, radius)
    local out = {}
    for _, t in ipairs(game.towers) do
        local tx, ty = t:getCenter()
        if dist(x, y, tx, ty) <= radius then out[#out + 1] = t end
    end
    return out
end

-- Which targets an ability would hit right now
function Unit:abilityTargets(ab, game)
    local r = ab.radius or 150
    local t = ab.target
    local set = { enemies = {}, allies = {}, towers = {} }
    if t == "enemies" or t == "area" or t == "point" then
        set.enemies = enemiesNear(game, self.x, self.y, r, ab.maxTargets)
    elseif t == "enemy" then
        local best
        for _, e in ipairs(enemiesNear(game, self.x, self.y, math.max(self.range, 150))) do
            if not best or e.health > best.health then best = e end
        end
        if best then set.enemies = { best } end
    end
    if t == "allies" or t == "area" then set.allies = alliesNear(game, self.x, self.y, r) end
    if t == "self" then set.allies = { self } end
    if t == "towers" or ab.includeTowers then set.towers = towersNear(game, self.x, self.y, r) end
    return set
end

local function needsEnemies(ab)
    return ab.target == "enemies" or ab.target == "enemy" or ab.target == "point"
end

-- Is now a good moment to cast this automatically?
function Unit:shouldAutoCast(ab, set, game)
    if ab.auto == false then return false end
    if needsEnemies(ab) then return #set.enemies > 0 end
    local fighting = #enemiesNear(game, self.x, self.y, math.max(self.range, 60) + 60) > 0
    if ab.target == "area" then
        if #set.enemies > 0 then return true end
        for _, u in ipairs(set.allies) do
            if u.health < u.maxHealth * 0.6 then return true end
        end
        return false
    end
    if ab.target == "allies" then
        if fighting then return true end
        for _, u in ipairs(set.allies) do
            if u.health < u.maxHealth * 0.6 then return true end
        end
        return false
    end
    return fighting
end

function Unit:effectContext(game)
    local mods = game.mods or {}
    local burn = 1
    if self.passive and self.passive.kind == "heroBurn" then burn = self.passive.mult end
    return {
        source = self, caster = self,
        damageMult = Effects.damageDealtMult(self) * (1 + (self.modeDamageBoost or 0)),
        healMult = mods.heroHealingMult or 1,
        durationMult = mods.abilityDurationMult or 1,
        dotMult = { burn = burn },
    }
end

local BOOST_TYPES = { damageBoost = true, haste = true }

function Unit:applyEffect(e, set, ab, ctx, game)
    local t = e.type
    if t == "summon" then
        local gx, gy = game:nearestRoadCell(self.x, self.y)
        local x, y = self.x, self.y
        if gx then x, y = game:cellCenter(gx, gy) end
        game:spawnMinion(e.minion, x, y, e.count or 1)
    elseif t == "teleport" then
        local best
        for _, en in ipairs(set.enemies) do
            if not en.flying and (not best or en:progress() > best:progress()) then best = en end
        end
        if best then
            self:release()
            self.path = nil
            self.x, self.y = best.x, best.y
            local gx, gy = game:nearestRoadCell(best.x, best.y)
            if gx then self.holdX, self.holdY = game:cellCenter(gx, gy) end
        end
    elseif t == "toggle" then
        local modes = e.modes
        self.mode = ((self.mode or 0) % #modes) + 1
        local m = modes[self.mode]
        self.modeDamageBoost = m.damageBoost
        self.modeLifesteal = m.lifesteal
    elseif t == "alternate" then
        -- Which option is next is per hero, not stored in the shared data
        self.altIndex = self.altIndex or {}
        local idx = ((self.altIndex[ab] or 0) % #e.options) + 1
        self.altIndex[ab] = idx
        for _, sub in ipairs(e.options[idx]) do
            for _, en in ipairs(set.enemies) do Effects.apply(en, sub, ctx) end
        end
    elseif t == "chain" then
        Effects.chain(set.enemies, e, ctx)
    elseif t == "selfDamage" then
        Effects.apply(self, e, ctx)
    else
        local on = e.on
        if not on then
            if ab.target == "allies" or ab.target == "self" then on = "ally"
            elseif ab.target == "towers" then on = "tower"
            else on = "enemy" end
        end
        local list = on == "enemy" and set.enemies or on == "ally" and set.allies or set.towers
        for _, target in ipairs(list) do Effects.apply(target, e, ctx) end
        -- "Allies and towers" buffs also reach towers in the area
        if on == "ally" and ab.includeTowers and BOOST_TYPES[t] then
            for _, tw in ipairs(set.towers) do Effects.apply(tw, e, ctx) end
        end
    end
end

-- Cast ability i. manual = player pressed Q/W/E. Returns true if cast.
function Unit:castAbility(i, game, manual)
    local slot = self.abilities[i]
    if not slot or self.dead or slot.cooldown > 0 then return false end
    local ab = slot.data
    local set = self:abilityTargets(ab, game)
    if needsEnemies(ab) and #set.enemies == 0 then return false end
    if not manual and not self:shouldAutoCast(ab, set, game) then return false end

    local ctx = self:effectContext(game)
    for _, e in ipairs(ab.effects) do self:applyEffect(e, set, ab, ctx, game) end
    slot.cooldown = ab.cooldown
    slot.flash = 0.3
    Audio.play("ability")
    slot.casts = (slot.casts or 0) + 1

    if game.effects then
        local x, y, r = self.x, self.y, ab.radius or 60
        local c = Unit.ROLE_COLORS[self.role] or { 1, 1, 1 }
        table.insert(game.effects, {
            t = 0, done = false,
            update = function(fx, dt) fx.t = fx.t + dt; if fx.t > 0.35 then fx.done = true end; return fx.done end,
            draw = function(fx)
                local k = fx.t / 0.35
                love.graphics.setColor(c[1], c[2], c[3], 0.5 * (1 - k))
                love.graphics.setLineWidth(3)
                love.graphics.circle("line", x, y, r * (0.4 + 0.6 * k))
                love.graphics.setLineWidth(1)
            end,
        })
    end
    return true
end

function Unit:updateAbilities(dt, game)
    for i, slot in ipairs(self.abilities) do
        slot.cooldown = math.max(0, slot.cooldown - dt)
        slot.flash = math.max(0, slot.flash - dt)
        if slot.cooldown <= 0 and not self.path then
            self:castAbility(i, game, false)
        end
    end
end

------------------------------------------------------------------------
-- Drawing
------------------------------------------------------------------------
function Unit:isUnder(px, py)
    return not self.dead and dist(px, py, self.x, self.y - 10) <= 18
end

function Unit:drawBar(x, y, w, frac, color)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.85)
    love.graphics.rectangle("fill", x, y, w, 4)
    love.graphics.setColor(color[1], color[2], color[3], 0.95)
    love.graphics.rectangle("fill", x, y, w * math.max(0, math.min(1, frac)), 4)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("line", x, y, w, 4)
end

function Unit:draw()
    if self.removed then return end
    local groundY = self.y + Unit.FOOT_OFFSET
    local x, y = self.x, self.y
    if self.lunge > 0 and self.blocking[1] then
        local e = self.blocking[1]
        local dx, dy = e.x - x, e.y - y
        local d = math.sqrt(dx * dx + dy * dy)
        if d > 0 then x, y = x + dx / d * 4 * self.lunge, y + dy / d * 4 * self.lunge end
    end

    if self.kind == "minion" then
        local alpha = 1
        if self.remaining and self.remaining < 2 then alpha = math.max(0.2, self.remaining / 2) end
        local top = Enemy.drawFigure(self.sheet, x, groundY, self.direction, self.animTime, self.moving,
            self.tint, alpha, self.drawHeight)
        if not top then
            love.graphics.setColor(0.4, 0.9, 0.5, alpha)
            love.graphics.circle("fill", x, y - 6, 8)
            top = y - 16
        end
        self:drawBar(x - 12, top - 6, 24, self.health / self.maxHealth, { 0.4, 0.9, 1 })
        return
    end

    local c = Unit.ROLE_COLORS[self.role] or { 1, 1, 1 }
    local alpha = self.dead and 0.35 or 1

    -- Hero with a walk sheet: the figure, a role-colored ring at its feet
    if self.sheetKey then
        if self.selected then
            love.graphics.setColor(1, 0.9, 0.3, 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.ellipse("line", x, groundY, 16, 6)
        end
        love.graphics.setColor(c[1], c[2], c[3], 0.8 * alpha)
        love.graphics.setLineWidth(self.hitFlash and self.hitFlash > 0 and 3 or 1.5)
        love.graphics.ellipse("line", x, groundY, 12, 4)
        love.graphics.setLineWidth(1)
        local tint = (self.hitFlash and self.hitFlash > 0) and { 1, 0.6, 0.6 } or nil
        local top = Enemy.drawFigure(self.sheetKey, x, groundY, self.direction, self.animTime, self.moving,
            tint, alpha, Unit.HERO_HEIGHT) or (groundY - Unit.HERO_HEIGHT)
        if self.dead then
            love.graphics.setColor(1, 1, 1, 0.9)
            local txt = tostring(math.ceil(self.respawnTimer or 0))
            love.graphics.print(txt, x - love.graphics.getFont():getWidth(txt) / 2, top - 14)
            love.graphics.setColor(1, 1, 1, 1)
            return
        end
        self:drawBar(x - 14, top - 8, 28, self.health / self.maxHealth, { 0.3, 0.95, 0.4 })
        love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
        love.graphics.circle("fill", x + 17, top - 5, 6)
        love.graphics.setColor(1, 0.85, 0.3, 1)
        local lv = tostring(self.level)
        love.graphics.print(lv, x + 17 - love.graphics.getFont():getWidth(lv) / 2, top - 12)
        if self.levelFlash and self.levelFlash > 0 then
            love.graphics.setColor(1, 0.9, 0.3, self.levelFlash / 1.5)
            love.graphics.circle("line", x, groundY - Unit.HERO_HEIGHT / 2, 18 + (1.5 - self.levelFlash) * 10)
        end
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Hero without a sheet: a portrait token standing on the road
    love.graphics.setColor(0, 0, 0, 0.3 * alpha)
    love.graphics.ellipse("fill", x + 2, groundY, 12, 4)
    if self.selected then
        love.graphics.setColor(1, 0.9, 0.3, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.ellipse("line", x, groundY, 16, 6)
        love.graphics.setLineWidth(1)
    end
    local cy = groundY - 16
    local r = 13
    love.graphics.setColor(0.08, 0.08, 0.1, alpha)
    love.graphics.circle("fill", x, cy, r + 2)
    if self.portraitImage then
        local s = (r * 2) / self.portraitImage:getWidth()
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(self.portraitImage, x, cy, 0, s, s,
            self.portraitImage:getWidth() / 2, self.portraitImage:getHeight() / 2)
    else
        love.graphics.setColor(c[1] * 0.6, c[2] * 0.6, c[3] * 0.6, alpha)
        love.graphics.circle("fill", x, cy, r)
        love.graphics.setColor(1, 1, 1, alpha)
        local font = love.graphics.getFont()
        local letter = self.name:sub(1, 1)
        love.graphics.print(letter, x - font:getWidth(letter) / 2, cy - font:getHeight() / 2)
    end
    local ring = c
    if self.hitFlash and self.hitFlash > 0 then ring = { 1, 0.3, 0.3 } end
    love.graphics.setColor(ring[1], ring[2], ring[3], alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, cy, r + 1)
    love.graphics.setLineWidth(1)

    if self.dead then
        love.graphics.setColor(1, 1, 1, 0.9)
        local txt = tostring(math.ceil(self.respawnTimer or 0))
        love.graphics.print(txt, x - love.graphics.getFont():getWidth(txt) / 2, cy - 7)
        return
    end
    self:drawBar(x - 14, cy - r - 9, 28, self.health / self.maxHealth, { 0.3, 0.95, 0.4 })
    -- Level badge
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.circle("fill", x + r, cy + r - 2, 6)
    love.graphics.setColor(1, 0.85, 0.3, 1)
    local lv = tostring(self.level)
    love.graphics.print(lv, x + r - love.graphics.getFont():getWidth(lv) / 2, cy + r - 9)
    if self.levelFlash and self.levelFlash > 0 then
        love.graphics.setColor(1, 0.9, 0.3, self.levelFlash / 1.5)
        love.graphics.circle("line", x, cy, r + 6 + (1.5 - self.levelFlash) * 10)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Unit
