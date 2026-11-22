-- Battle feedback: floating damage numbers, gold popups, death puffs and a
-- red edge flash when a life is lost. Anything can add an effect; the game
-- screen updates and draws them (in map coordinates, under the HUD).
--
--   Fx.damage(target, amount, crit)  number over an enemy (merged per enemy)
--   Fx.gold(x, y, amount)            "+10" in gold
--   Fx.puff(x, y, color)             a burst of motes where something died
--   Fx.lifeLost(x, y, n)             "-n" at the gate and a red screen edge
--   Fx.update(dt), Fx.draw(), Fx.drawScreen(w, h), Fx.clear()
--
-- Damage numbers for the same enemy within MERGE seconds add up into one
-- number, so ten towers on one zombie show one growing number, not ten.

local Fx = {}

Fx.MAX = 80          -- cap on live effects; the oldest go first
Fx.MERGE = 0.25      -- seconds a damage number keeps absorbing hits
Fx.LIFE = 0.8        -- seconds a number floats
Fx.enabled = true    -- false: record nothing (balance runs)

Fx.items = {}
Fx.flash = 0
Fx.counts = { damage = 0, gold = 0, puff = 0, life = 0 } -- read by tests

local function push(item)
    if #Fx.items >= Fx.MAX then table.remove(Fx.items, 1) end
    Fx.items[#Fx.items + 1] = item
end

function Fx.clear()
    Fx.items = {}
    Fx.flash = 0
end

function Fx.damage(target, amount, crit)
    if not Fx.enabled or not amount or amount < 1 then return end
    -- Add to this enemy's live number while it is fresh
    for i = #Fx.items, 1, -1 do
        local it = Fx.items[i]
        if it.kind == "damage" and it.target == target and it.t < Fx.MERGE then
            it.amount = it.amount + amount
            it.crit = it.crit or crit
            return
        end
    end
    Fx.counts.damage = Fx.counts.damage + 1
    push({ kind = "damage", target = target, x = target.x, y = target.y - 22, amount = amount, crit = crit, t = 0,
        dx = (love.math.random() - 0.5) * 14 })
end

function Fx.gold(x, y, amount)
    if not Fx.enabled or not amount or amount <= 0 then return end
    Fx.counts.gold = Fx.counts.gold + 1
    push({ kind = "gold", x = x, y = y - 8, amount = amount, t = 0 })
end

function Fx.puff(x, y, color)
    if not Fx.enabled then return end
    Fx.counts.puff = Fx.counts.puff + 1
    local motes = {}
    for i = 1, 8 do
        local a = (i / 8) * math.pi * 2 + love.math.random() * 0.6
        local v = 25 + love.math.random() * 30
        motes[i] = { vx = math.cos(a) * v, vy = math.sin(a) * v * 0.6 - 15 }
    end
    push({ kind = "puff", x = x, y = y, color = color or { 0.8, 0.8, 0.7 }, motes = motes, t = 0 })
end

function Fx.lifeLost(x, y, n)
    if not Fx.enabled then return end
    Fx.counts.life = Fx.counts.life + 1
    Fx.flash = 0.45
    push({ kind = "life", x = x, y = y - 20, amount = n or 1, t = 0 })
end

function Fx.update(dt)
    Fx.flash = math.max(0, Fx.flash - dt)
    for i = #Fx.items, 1, -1 do
        local it = Fx.items[i]
        it.t = it.t + dt
        if it.kind == "damage" and it.target and not it.target.dead and it.t < Fx.MERGE then
            it.x, it.y = it.target.x, it.target.y - 22 -- ride along while it can still grow
        end
        local life = (it.kind == "puff") and 0.5 or (it.kind == "life" and 1.2 or Fx.LIFE)
        if it.t >= life then table.remove(Fx.items, i) end
    end
end

local function outlined(text, x, y, color, alpha)
    local f = love.graphics.getFont()
    local w = f:getWidth(text)
    love.graphics.setColor(0, 0, 0, 0.7 * alpha)
    love.graphics.print(text, x - w / 2 + 1, y + 1)
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.print(text, x - w / 2, y)
end

-- In map coordinates (the game translates before calling)
function Fx.draw()
    for _, it in ipairs(Fx.items) do
        if it.kind == "puff" then
            local k = it.t / 0.5
            local c = it.color
            love.graphics.setColor(c[1], c[2], c[3], 0.7 * (1 - k))
            for _, m in ipairs(it.motes) do
                love.graphics.circle("fill", it.x + m.vx * it.t, it.y + m.vy * it.t + 20 * it.t * it.t, 3 * (1 - k) + 1)
            end
        else
            local life = it.kind == "life" and 1.2 or Fx.LIFE
            local k = it.t / life
            local alpha = k < 0.7 and 1 or (1 - (k - 0.7) / 0.3)
            local rise = it.t * (it.kind == "life" and 18 or 28)
            if it.kind == "damage" then
                local text = tostring(math.floor(it.amount + 0.5))
                outlined(it.crit and (text .. "!") or text, it.x + (it.dx or 0), it.y - rise,
                    it.crit and { 1, 0.85, 0.2 } or { 1, 1, 1 }, alpha)
            elseif it.kind == "gold" then
                outlined("+" .. it.amount, it.x, it.y - rise, { 1, 0.82, 0.3 }, alpha)
            elseif it.kind == "life" then
                outlined("-" .. it.amount, it.x, it.y - rise, { 1, 0.3, 0.25 }, alpha)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Red edge flash over the map area when a life is lost (screen coordinates)
function Fx.drawScreen(x, y, w, h)
    if Fx.flash <= 0 then return end
    local a = Fx.flash / 0.45 * 0.35
    love.graphics.setColor(0.9, 0.1, 0.1, a)
    local t = 18
    love.graphics.rectangle("fill", x, y, w, t)
    love.graphics.rectangle("fill", x, y + h - t, w, t)
    love.graphics.rectangle("fill", x, y, t, h)
    love.graphics.rectangle("fill", x + w - t, y, t, h)
    love.graphics.setColor(1, 1, 1, 1)
end

return Fx
