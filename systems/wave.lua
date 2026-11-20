-- Wave planning. Builds every wave of a level up front from a difficulty
-- curve, seeded from the level id, so a level plays the same every time
-- (and balance runs are repeatable).
--
-- Wave n of N on a level of difficulty d:
--   budget      points of enemies:  (BASE + d) * (1 + GROWTH * n)
--   healthMult  enemy health:       (1 + (HEALTH_BASE + HEALTH_PER_D * d) * (n - 1)
--                                        + HEALTH_CURVE * d * (n - 1)^2) * length
--               the squared term keeps late waves ahead of a maxed defense;
--               where length = sqrt(average road cells / ROAD_NORM): a longer
--               road gives towers more time to shoot, so enemies get tougher
--   types       zombie from wave 1, skeleton from 3, orc from 4,
--               necromancer from 40% of the way through
--   boss        a dragon ends the last wave; difficulty 2+ also has one
--               halfway
--   spacing     enemies come in groups of GROUP; the gap inside a group
--               shrinks as waves go on
--   bonus       gold for clearing the wave: BONUS + BONUS_PER_WAVE * n
-- A level can override any of these in its `waves` table, and set
-- `toughness` there to scale all its enemy health (default 1).

local Wave = {}

Wave.COST = { zombie = 1, skeleton = 1.2, orc = 2.5, necromancer = 5, dragon = 12 }
Wave.WEIGHT = { zombie = 4, skeleton = 3, orc = 2, necromancer = 1 }
Wave.ORDER = { "zombie", "skeleton", "orc", "necromancer" }

Wave.DEFAULTS = {
    BASE = 6, GROWTH = 0.35,
    HEALTH_BASE = 0.10, HEALTH_PER_D = 0.08, HEALTH_CURVE = 0.008, ROAD_NORM = 60,
    GROUP = 6, GAP_START = 1.3, GAP_MIN = 0.45, GAP_STEP = 0.05, GROUP_PAUSE = 2.5,
    BONUS = 20, BONUS_PER_WAVE = 4,
}

local function rngFor(id, n)
    local seed = 17 + n * 7919
    for i = 1, #id do seed = (seed * 31 + id:byte(i)) % 2147483647 end
    return love.math.newRandomGenerator(seed)
end

local function opt(level, key)
    local w = level.waves or {}
    if w[key] ~= nil then return w[key] end
    return Wave.DEFAULTS[key]
end

-- Which enemy types can appear in wave n of count
function Wave.unlocked(n, count)
    local t = { "zombie" }
    if n >= 3 then t[#t + 1] = "skeleton" end
    if n >= 4 then t[#t + 1] = "orc" end
    if n >= math.ceil(count * 0.4) then t[#t + 1] = "necromancer" end
    return t
end

function Wave.isBossWave(n, count, difficulty)
    return n == count or (difficulty >= 2 and n == math.ceil(count / 2))
end

-- Road length adjustment (see the header)
function Wave.lengthFactor(level)
    local total = 0
    for _, wps in ipairs(level.paths) do
        local prev, jump = nil, false
        for _, wp in ipairs(wps) do
            if wp == "portal" then jump = true
            else
                if prev and not jump then total = total + math.abs(wp[1] - prev[1]) + math.abs(wp[2] - prev[2]) end
                total = total + ((not prev or jump) and 1 or 0)
                prev, jump = wp, false
            end
        end
    end
    return math.sqrt((total / #level.paths) / opt(level, "ROAD_NORM"))
end

-- Plan of one wave:
--   { n, healthMult, bonus, entries = { {type, path, delay}, ... } }
-- delay is the time to wait before spawning that entry.
function Wave.build(level, n)
    local count = level.waves.count
    local d = level.difficulty or 1
    local paths = #level.paths
    local rng = rngFor(level.id, n)

    local budget = (opt(level, "BASE") + d) * (1 + opt(level, "GROWTH") * n)
    local types = Wave.unlocked(n, count)
    local total = 0
    for _, t in ipairs(types) do total = total + Wave.WEIGHT[t] end

    local list = {}
    while budget >= Wave.COST.zombie do
        local r = rng:random() * total
        local pick = types[1]
        for _, t in ipairs(types) do
            r = r - Wave.WEIGHT[t]
            if r <= 0 then pick = t; break end
        end
        if Wave.COST[pick] > budget then pick = "zombie" end
        list[#list + 1] = pick
        budget = budget - Wave.COST[pick]
    end
    -- Weaker enemies lead, tougher ones follow
    local rank = {}
    for i, t in ipairs(Wave.ORDER) do rank[t] = i end
    table.sort(list, function(a, b) return rank[a] < rank[b] end)
    if Wave.isBossWave(n, count, d) then list[#list + 1] = "dragon" end

    local group = opt(level, "GROUP")
    local gap = math.max(opt(level, "GAP_MIN"), opt(level, "GAP_START") - opt(level, "GAP_STEP") * n)
    local entries = {}
    for i, t in ipairs(list) do
        local g = math.floor((i - 1) / group)
        local delay = (i == 1) and 0.5 or ((i - 1) % group == 0 and opt(level, "GROUP_PAUSE") or gap)
        if t == "dragon" then delay = opt(level, "GROUP_PAUSE") end
        entries[#entries + 1] = { type = t, path = (g % paths) + 1, delay = delay }
    end

    return {
        n = n,
        entries = entries,
        healthMult = (1 + (opt(level, "HEALTH_BASE") + opt(level, "HEALTH_PER_D") * d) * (n - 1)
            + opt(level, "HEALTH_CURVE") * d * (n - 1) ^ 2) * Wave.lengthFactor(level)
            * ((level.waves and level.waves.toughness) or 1),
        bonus = opt(level, "BONUS") + opt(level, "BONUS_PER_WAVE") * n,
    }
end

-- Every wave of a level
function Wave.plan(level)
    local waves = {}
    for n = 1, level.waves.count do waves[n] = Wave.build(level, n) end
    return waves
end

-- "8 Zombie, 3 Orc, 1 Dragon" for the HUD
function Wave.summary(w)
    local counts, order = {}, {}
    for _, e in ipairs(w.entries) do
        if not counts[e.type] then order[#order + 1] = e.type end
        counts[e.type] = (counts[e.type] or 0) + 1
    end
    local parts = {}
    for _, t in ipairs(order) do
        parts[#parts + 1] = counts[t] .. " " .. t:sub(1, 1):upper() .. t:sub(2)
    end
    return table.concat(parts, ", ")
end

return Wave
