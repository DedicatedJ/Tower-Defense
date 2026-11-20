-- Effect engine. Every ability, tower hit and passive in data/factions.lua
-- is a list of effects; this module applies them and runs the timed ones
-- as statuses on enemies, units and towers.
--
-- Targets must provide:
--   statuses               table (created here if missing)
--   takeDamage(amount, source, opts) -> damage actually dealt
--   heal(amount)           (units; enemies ignore heals)
--
-- Effect types
--   damage {amount, lifesteal?}       instant damage; lifesteal heals the caster
--   heal {amount}                     instant heal
--   selfDamage {amount}               the caster pays health (Dark Ritual)
--   burn | poison | drain {dps, duration}
--                                     damage over time; drain also heals the caster
--   slow {amount, duration}           speed x (1 - amount); strongest slow wins
--   root {duration}                   cannot move (can still attack)
--   stun | freeze {duration}          cannot move or attack (freeze tints blue)
--   mark {mult, duration}             takes mult x damage
--   armorShred {amount, duration}     armor lowered by amount
--   chain {share, duration}           applied to a group: direct damage to one
--                                     member is shared (x share) with the others
--   damageReduction {amount, duration}  takes (1 - amount) x damage
--   invulnerable {duration}           takes no damage
--   reflect {amount, duration}        attackers take amount x the damage dealt
--   damageBoost {amount, duration}    deals (1 + amount) x damage
--   haste {amount, duration}          moves and attacks (1 + amount) x faster
--   healingBoost {amount, duration}   heals received x (1 + amount)
--   lifesteal {amount, duration}      heals for amount x damage dealt
-- Handled by the caster (systems/unit.lua): summon, teleport, toggle, alternate.

local Effects = {}

local TIMED = {
    burn = true, poison = true, drain = true, slow = true, root = true, stun = true, freeze = true,
    mark = true, armorShred = true, damageReduction = true, invulnerable = true, reflect = true,
    damageBoost = true, haste = true, healingBoost = true, lifesteal = true,
}

local function statuses(e)
    e.statuses = e.statuses or {}
    return e.statuses
end

-- ctx (all optional):
--   source       what applied it (unit, tower); damage is credited to it
--   caster       unit that heals from drain / lifesteal
--   damageMult   multiplier on instant damage
--   healMult     multiplier on heals
--   dotMult      { burn = x, poison = x, drain = x }
--   durationMult multiplier on all durations
function Effects.apply(target, effect, ctx)
    ctx = ctx or {}
    local t = effect.type
    if not target or target.dead or target.removed then return end
    local dur = (effect.duration or 0) * (ctx.durationMult or 1)

    if t == "damage" then
        local dealt = target:takeDamage(effect.amount * (ctx.damageMult or 1), ctx.source) or 0
        if effect.lifesteal and ctx.caster and ctx.caster.heal then
            ctx.caster:heal(dealt * effect.lifesteal)
        end
    elseif t == "heal" then
        if target.heal then target:heal(effect.amount * (ctx.healMult or 1)) end
    elseif t == "burn" or t == "poison" or t == "drain" then
        local dps = effect.dps * ((ctx.dotMult and ctx.dotMult[t]) or 1)
        local s = statuses(target)
        local cur = s[t]
        -- Refresh: keep the stronger tick, the longer duration
        s[t] = {
            dps = math.max(dps, cur and cur.dps or 0),
            remaining = math.max(dur, cur and cur.remaining or 0),
            source = ctx.source,
            caster = ctx.caster,
        }
    elseif t == "slow" then
        local s = statuses(target)
        local cur = s.slow
        s.slow = {
            amount = math.max(effect.amount, cur and cur.amount or 0),
            remaining = math.max(dur, cur and cur.remaining or 0),
        }
    elseif t == "mark" then
        statuses(target).mark = { mult = effect.mult or 1.5, remaining = dur }
    elseif TIMED[t] then
        local s = statuses(target)
        local cur = s[t]
        s[t] = {
            amount = math.max(effect.amount or 0, cur and cur.amount or 0),
            remaining = math.max(dur, cur and cur.remaining or 0),
        }
    elseif t == "selfDamage" then
        if ctx.caster then ctx.caster:takeDamage(effect.amount, nil, { ignoreArmor = true }) end
    end
end

-- Apply a chain to a whole group of enemies
function Effects.chain(targets, effect, ctx)
    local group = { members = {}, share = effect.share or 0.5 }
    for _, t in ipairs(targets) do
        if not t.dead then group.members[#group.members + 1] = t end
    end
    if #group.members < 2 then return end
    local dur = (effect.duration or 0) * ((ctx and ctx.durationMult) or 1)
    for _, t in ipairs(group.members) do
        statuses(t).chain = { group = group, remaining = dur }
    end
end

-- Damage to a chained enemy is shared with the rest of its chain
function Effects.shareChainDamage(target, amount, source)
    local c = target.statuses and target.statuses.chain
    if not c then return end
    for _, other in ipairs(c.group.members) do
        if other ~= target and not other.dead and other.statuses and other.statuses.chain
            and other.statuses.chain.group == c.group then
            other:takeDamage(amount * c.group.share, source, { shared = true })
        end
    end
end

-- Tick statuses: damage over time and expiry
function Effects.update(e, dt)
    local s = e.statuses
    if not s then return end
    for name, st in pairs(s) do
        if st.dps and not e.dead then
            local dealt = e:takeDamage(st.dps * dt, st.source, { dot = true }) or 0
            if name == "drain" and st.caster and not st.caster.dead and st.caster.heal then
                st.caster:heal(dealt)
            end
        end
        if st.remaining then
            st.remaining = st.remaining - dt
            if st.remaining <= 0 then s[name] = nil end
        end
    end
end

function Effects.clear(e)
    e.statuses = {}
end

function Effects.has(e, name)
    return e.statuses ~= nil and e.statuses[name] ~= nil
end

local function amount(e, name)
    local st = e.statuses and e.statuses[name]
    return st and (st.amount or 0) or 0
end

-- Movement speed multiplier
function Effects.speedMult(e)
    local s = e.statuses
    if not s then return 1 end
    if s.root or s.stun or s.freeze then return 0 end
    return (1 - amount(e, "slow")) * (1 + amount(e, "haste"))
end

function Effects.canAttack(e)
    local s = e.statuses
    return not (s and (s.stun or s.freeze))
end

-- Multiplier on damage this entity receives (before armor)
function Effects.damageTakenMult(e)
    local s = e.statuses
    if not s then return 1 end
    if s.invulnerable then return 0 end
    local m = 1
    if s.mark then m = m * s.mark.mult end
    if s.damageReduction then m = m * (1 - s.damageReduction.amount) end
    return m
end

function Effects.armorShred(e) return amount(e, "armorShred") end
function Effects.damageDealtMult(e) return 1 + amount(e, "damageBoost") end
function Effects.attackRateMult(e) return 1 + amount(e, "haste") end
function Effects.healingMult(e) return 1 + amount(e, "healingBoost") end
function Effects.lifesteal(e) return amount(e, "lifesteal") end
function Effects.reflect(e) return amount(e, "reflect") end

return Effects
