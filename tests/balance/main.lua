-- Balance read-out (run with tests/run.sh balance).
-- Plays every level with its own faction's first hero and a simple greedy
-- player: it starts with the level's real gold, builds where a tower
-- covers the most road, upgrades once it has 2 + wave towers, spends gold
-- every second (during waves too), and starts each wave as soon as the
-- last one ends. It never casts abilities early or moves the hero.
-- Prints one line per level.
--
-- It checks the curve, not a pass/fail target for players: an easy level
-- should be won with lives to spare, a hard one should strain this player.
-- Exit code 1 if an easy level is lost (the curve is broken), else 0.

love.filesystem.setIdentity("tower-defense-balance")

local function log(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    print("[BALANCE] " .. table.concat(parts, " "))
    io.stdout:flush()
end

function love.errorhandler(msg)
    log("CRASH", tostring(msg))
    log(debug.traceback("", 2))
    io.stdout:flush()
    os.exit(2)
end

love.filesystem.createDirectory("save")
for i = 1, 5 do love.filesystem.remove("save/profile_" .. i .. ".json") end

love.filesystem.load("game_main.lua")()

-- Count sounds but make none
require('systems.audio').enabled = false
require('systems.fx').enabled = false

local Gamestate = require 'libs.hump.gamestate'
local Levels = require('data.levels')
local Factions = require('data.factions')
local gameLoad, gameUpdate, gameDraw = love.load, love.update, love.draw
local DT = 1 / 60
local ONLY = os.getenv("BALANCE_LEVEL") -- run one level by id
if ONLY == "" then ONLY = nil end

-- How much road lies within `range` of a point: samples every 20 px along
-- each road, counting a stretch once per road that uses it (a merge point
-- is worth more)
local function coverage(g, cx, cy, range)
    local n = 0
    for _, road in ipairs(g.roads) do
        for d = 0, road:length(), 20 do
            local x, y = road:pointAt(d)
            if (x - cx) ^ 2 + (y - cy) ^ 2 <= range * range then n = n + 1 end
        end
    end
    return n
end

-- The free spot (on a 20 px grid inside the build zones) covering the most road
local function bestSpot(g, range)
    local best, bestN
    for _, z in ipairs(g.built.zones) do
        for x = z[1], z[3], 20 do
            for y = z[2], z[4], 20 do
                if g:canPlaceTower(x, y) then
                    local n = coverage(g, x, y, range)
                    if not bestN or n > bestN then best, bestN = { x, y }, n end
                end
            end
        end
    end
    return best
end

-- Spend gold like a steady player: aim for (2 + wave) towers, opening
-- with the cheapest and then rotating through all three; save for the
-- next tower until there are that many, then buy upgrades, cheapest first
local function spend(g, towers)
    for _ = 1, 40 do
        local target = math.min(14, 2 + g.wave)
        local nextTower = #g.towers < 2 and towers[1] or towers[(#g.towers % #towers) + 1]
        if #g.towers < target then
            if g.resources < nextTower.cost then return end
            local spot = bestSpot(g, nextTower.range)
            if not spot or not g:placeTower(spot[1], spot[2], nextTower.id) then return end
        else
            local up, ut, ui
            for _, t in ipairs(g.towers) do
                for i = 1, 2 do
                    local u = t.data.upgrades[i]
                    if not t.bought[i] and (not up or u.cost < up.cost) then up, ut, ui = u, t, i end
                end
            end
            if not up or g.resources < up.cost then return end
            g.resources = g.resources - ut:buyUpgrade(ui)
        end
    end
end

local function playLevel(level)
    local faction = Factions[level.faction]
    local GameState = require('states.game')
    love.math.setRandomSeed(1)
    -- A hero at the level a player would have by then: 1, 3, 5
    local Save = require('systems.save')
    Save.updateHeroProgress(faction.heroes[1].id, 1 + 2 * (level.difficulty - 1), 0)
    local g = GameState.new()
    g:setup(level.faction, faction.heroes[1].id, level.id)
    Gamestate.switch(g)
    coroutine.yield()

    local towers = {}
    for _, t in ipairs(faction.towers) do towers[#towers + 1] = t end
    table.sort(towers, function(a, b) return a.cost < b.cost end)

    local perWave = {}
    local steps = 0
    while not g.isGameOver do
        if not g.waveInProgress then
            spend(g, towers)
            local before = g.lives
            g:startNextWave()
            perWave[#perWave + 1] = { before = before }
        end
        gameUpdate(DT)
        steps = steps + 1
        if steps % 60 == 0 and not g.isGameOver then spend(g, towers) end -- builds during waves too
        if steps % 300 == 0 then coroutine.yield() end
        if steps > 60 * 60 * 30 then break end -- 30 minutes of game time
        if not g.waveInProgress and perWave[#perWave] then perWave[#perWave].after = g.lives end
    end

    local lost = {}
    for i, w in ipairs(perWave) do
        local d = w.before - (w.after or g.lives)
        if d > 0 then lost[#lost + 1] = "w" .. i .. ":-" .. d end
    end
    local result = g.victory and ("WIN " .. GameState.starsFor(g.lives, g.startLives) .. "*") or "LOSS"
    local ups = 0
    for _, t in ipairs(g.towers) do for i = 1, 2 do if t.bought[i] then ups = ups + 1 end end end
    log(string.format("%-18s %-8s d%d  %-6s waves %2d/%2d  lives %2d/%2d  towers %2d ups %2d  gold %4d  hero Lv%-2d leaks %s",
        level.id, level.faction, level.difficulty, result, g.wave, g.maxWaves, math.max(0, g.lives),
        g.startLives, #g.towers, ups, math.floor(g.resources), g.hero and g.hero.level or 0,
        #lost > 0 and table.concat(lost, " ") or "none"))
    return g.victory, level.difficulty
end

local brokenEasy = 0
local function run()
    for _, level in ipairs(Levels.list) do
        if not ONLY or ONLY == level.id then
            local won, d = playLevel(level)
            if d == 1 and not won then brokenEasy = brokenEasy + 1 end
        end
    end
end

local script
function love.load(args)
    gameLoad(args)
    script = coroutine.create(run)
end

function love.update(dt)
    local ok, err = coroutine.resume(script)
    if not ok then
        log("CRASH", tostring(err))
        log(debug.traceback(script))
        os.exit(2)
    end
    if coroutine.status(script) == "dead" then
        log(string.format("DONE easyLosses=%d", brokenEasy))
        os.exit(brokenEasy == 0 and 0 or 1)
    end
end

function love.draw()
    gameDraw()
end
