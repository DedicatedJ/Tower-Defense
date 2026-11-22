-- Achievement tracking. The list is data/achievements.lua; progress lives
-- in the profile (systems/save.lua):
--   profile.stats        = { towersBuilt, wavesCleared, shopGold, games }
--   profile.achievements = { [id] = unlock time (os.time) }
--
--   Achievements.recordGame(profile, result) -> list of newly unlocked
--   Achievements.status(profile)             -> rows for the screen
-- result (from the game screen): { victory, livesLost, towersBuilt,
--   wavesCleared, shopGold, towerTypes, factionTowerCount }

local List = require('data.achievements')
local Levels = require('data.levels')

local Achievements = { list = List }

local function stats(profile)
    profile.stats = profile.stats or {}
    local s = profile.stats
    s.towersBuilt = s.towersBuilt or 0
    s.wavesCleared = s.wavesCleared or 0
    s.shopGold = s.shopGold or 0
    s.games = s.games or 0
    return s
end

local function bestHeroLevel(profile)
    local best = 1
    for _, h in pairs(profile.heroes or {}) do best = math.max(best, h.level or 1) end
    return best
end

-- Most levels won in any one faction (and how many that faction has)
local function bestFaction(profile)
    local best, size = 0, 3
    local won = profile.levels or {}
    local per = {}
    for _, l in ipairs(Levels.list) do
        per[l.faction] = per[l.faction] or { won = 0, total = 0 }
        per[l.faction].total = per[l.faction].total + 1
        if won[l.id] then per[l.faction].won = per[l.faction].won + 1 end
    end
    for _, f in pairs(per) do
        if f.won > best then best, size = f.won, f.total end
    end
    return best, size
end

-- Progress toward an achievement: current, goal (nil for one-shot ones)
local function progress(a, profile)
    local s = stats(profile)
    if a.check == "total" then return math.min(s[a.counter] or 0, a.goal), a.goal end
    if a.check == "heroLevel" then return math.min(bestHeroLevel(profile), a.goal), a.goal end
    if a.check == "faction" then
        local won, size = bestFaction(profile)
        return math.min(won, size), size
    end
end

local function earned(a, profile, result)
    local cur, goal = progress(a, profile)
    if goal then return cur >= goal end
    if not (result and result.victory) then return false end
    if a.check == "flawless" then return (result.livesLost or 0) == 0 end
    if a.check == "allTowers" then return (result.towerTypes or 0) >= (result.factionTowerCount or 3) end
    return false
end

-- Add a finished game to the profile's counters and unlock what it earned.
-- Returns the achievements unlocked by this game (data rows).
function Achievements.recordGame(profile, result)
    local s = stats(profile)
    s.towersBuilt = s.towersBuilt + (result.towersBuilt or 0)
    s.wavesCleared = s.wavesCleared + (result.wavesCleared or 0)
    s.shopGold = s.shopGold + (result.shopGold or 0)
    s.games = s.games + 1
    profile.achievements = profile.achievements or {}
    local new = {}
    for _, a in ipairs(List) do
        if not profile.achievements[a.id] and earned(a, profile, result) then
            profile.achievements[a.id] = os.time()
            new[#new + 1] = a
        end
    end
    return new
end

-- Rows for the achievements screen, in list order
function Achievements.status(profile)
    profile = profile or {}
    local rows = {}
    for _, a in ipairs(List) do
        local when = profile.achievements and profile.achievements[a.id]
        local cur, goal = progress(a, profile)
        rows[#rows + 1] = {
            id = a.id, title = a.name, description = a.description,
            unlocked = when ~= nil, date = when and os.date("%Y-%m-%d", when) or nil,
            progress = (not when) and goal and cur or nil, maxProgress = (not when) and goal or nil,
        }
    end
    return rows
end

return Achievements
