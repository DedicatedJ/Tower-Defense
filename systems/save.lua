local Save = {}
Save.__index = Save

-- Import dependencies
local Error = require 'utils.error'
local json = require 'utils.json'

-- Save slot definitions
local SAVE_SLOTS = {
    {id = 1, name = "Slot 1"},
    {id = 2, name = "Slot 2"},
    {id = 3, name = "Slot 3"},
    {id = 4, name = "Slot 4"},
    {id = 5, name = "Slot 5"}
}

local currentSlot = 1
local lastSaveTime = 0

-- Add global state variable for non-instanced access
-- The current profile, cached (loaded on first use). Not the global
-- `gameState` from main.lua, which holds the settings.
local profileCache = nil

-- Settings live in <save folder>/settings.json. Both take the settings
-- table (the global gameState.settings): load fills in the saved values it already
-- has keys for, save writes all of it. Return true on success.
local SETTINGS_FILE = "settings.json"

function Save.saveSettings(settings)
    if type(settings) ~= "table" or settings == Save then settings = _G.gameState and _G.gameState.settings end
    if not settings then return false end
    local ok, err = pcall(function()
        assert(love.filesystem.write(SETTINGS_FILE, json.encode(settings)))
    end)
    if not ok then print("WARNING: could not save settings: " .. tostring(err)) end
    return ok
end

function Save.loadSettings(settings)
    if type(settings) ~= "table" or settings == Save then settings = _G.gameState and _G.gameState.settings end
    if not settings or not love.filesystem.getInfo(SETTINGS_FILE) then return false end
    local ok, data = pcall(function() return json.decode(love.filesystem.read(SETTINGS_FILE)) end)
    if not ok or type(data) ~= "table" then
        print("WARNING: settings file unreadable, using defaults")
        return false
    end
    for k, v in pairs(data) do
        if settings[k] ~= nil and type(v) == type(settings[k]) then settings[k] = v end
    end
    return true
end

function Save:getSettings()
    return _G.gameState and _G.gameState.settings
end

function Save:setSetting(key, value)
    local settings = _G.gameState and _G.gameState.settings
    if settings and settings[key] ~= nil then
        settings[key] = value
        Save.saveSettings(settings)
        return true
    end
    return false
end

-- Save player profile (including faction/hero selections and progress)
function Save.saveProfile(profile, slot)
    if not slot then slot = currentSlot end
    
    local filePath = string.format("save/profile_%d.json", slot)
    
    local success, error = Error.pcall(function()
        -- Create minimal profile if not provided
        if not profile then
            profile = {
                playerName = "Player" .. slot,
                selectedFaction = "default",
                selectedHero = "default_hero",
                currentLevel = 1,
                completedLevels = {},
                towerUpgrades = {},
                resources = 200,
                timestamp = os.time()
            }
        end
        
        -- Ensure the save directory exists
        love.filesystem.createDirectory("save")
        
        -- Save to file using LÖVE's filesystem for better cross-platform support
        if love.filesystem.getInfo("save") then
            profile.timestamp = os.time() -- "last played" on the profile screen
            local success = love.filesystem.write(filePath, json.encode(profile))
            if success then
                lastSaveTime = os.time()
                print("Profile saved to " .. filePath)
                return true
            end
        else
            Error.handle(Error.TYPES.SAVE, "DIRECTORY_MISSING", "save")
            return false
        end
    end, Error.TYPES.SAVE, "PROFILE_SAVE_FAILED")
    
    if not success then
        Error.handle(Error.TYPES.SAVE, "PROFILE_SAVE_FAILED", error)
        return false
    end
    
    return true
end

-- Load player profile (including faction/hero selections and progress)
function Save.loadProfile(slot)
    if not slot then slot = currentSlot end
    
    local filePath = string.format("save/profile_%d.json", slot)

    -- No profile yet is normal (new player, empty slot): no error notice
    if not love.filesystem.getInfo(filePath) then
        return nil
    end
    
    local success, result = Error.pcall(function()
        
        local content = love.filesystem.read(filePath)
        if not content then
            Error.handle(Error.TYPES.LOAD, "PROFILE_READ_FAILED", slot)
            return nil
        end
        
        local profile = json.decode(content)
        if not profile then
            Error.handle(Error.TYPES.LOAD, "PROFILE_DECODE_FAILED", slot)
            return nil
        end
        
        -- Reading a slot does not make it the current profile; callers that
        -- want that (currentProfile, getCurrentProfile) cache it themselves
        
        return profile
    end, Error.TYPES.LOAD, "PROFILE_LOAD_FAILED")
    
    if not success or not result then
        Error.handle(Error.TYPES.LOAD, "PROFILE_LOAD_FAILED", slot)
        return nil
    end
    
    return result
end

-- Get all profiles (for the profile selection screen)
function Save.getAllProfiles()
    local profiles = {}
    
    for i = 1, #SAVE_SLOTS do
        local profile = Save.loadProfile(i)
        if profile then
            profile.slot = i
            table.insert(profiles, profile)
        end
    end
    
    return profiles
end

-- Get current profile
function Save.getCurrentProfile()
    if not profileCache then
        profileCache = Save.loadProfile(currentSlot)
    end
    
    return profileCache
end

-- Update faction selection in current profile
function Save.updateFactionSelection(factionId)
    if not profileCache then
        profileCache = Save.loadProfile(currentSlot) or {
            playerName = "Player1",
            selectedFaction = factionId,
            currentLevel = 1,
            completedLevels = {},
            towerUpgrades = {},
            resources = 200,
            timestamp = os.time()
        }
    else
        profileCache.selectedFaction = factionId
    end
    
    -- Debug info
    print("Saving faction selection: " .. (factionId or "nil"))
    
    Save.saveProfile(profileCache, currentSlot)
    return true
end

-- Update hero selection in current profile
function Save.updateHeroSelection(heroId)
    if not profileCache then
        profileCache = Save.loadProfile(currentSlot) or {
            playerName = "Player1",
            selectedHero = heroId,
            currentLevel = 1,
            completedLevels = {},
            towerUpgrades = {},
            resources = 200,
            timestamp = os.time()
        }
    else
        profileCache.selectedHero = heroId
    end
    
    -- Debug info
    print("Saving hero selection: " .. (heroId or "nil"))

    Save.saveProfile(profileCache, currentSlot)
    return true
end

------------------------------------------------------------------------
-- Profile progress: hero levels, shop gold and purchases. Each helper
-- works on the current profile (loading or creating it) and saves it.
--   heroes    = { [heroId] = { level = n, xp = n } }
--   gold      = shop currency earned in games
--   purchases = { [itemId] = count }
------------------------------------------------------------------------
local function currentProfile()
    if not profileCache then
        -- Only load a profile that exists: loadProfile shows an error
        -- notice for a missing file, which is normal for a new player
        local path = string.format("save/profile_%d.json", currentSlot)
        if love.filesystem.getInfo(path) then profileCache = Save.loadProfile(currentSlot) end
        profileCache = profileCache or {
            playerName = "Player" .. currentSlot,
            currentLevel = 1,
            completedLevels = {},
            towerUpgrades = {},
            timestamp = os.time()
        }
    end
    profileCache.heroes = profileCache.heroes or {}
    profileCache.levels = profileCache.levels or {}
    profileCache.purchases = profileCache.purchases or {}
    profileCache.gold = profileCache.gold or 0
    return profileCache
end

function Save.getHeroProgress(heroId)
    local h = currentProfile().heroes[heroId]
    return { level = (h and h.level) or 1, xp = (h and h.xp) or 0 }
end

function Save.updateHeroProgress(heroId, level, xp)
    if not heroId then return false end
    local p = currentProfile()
    p.heroes[heroId] = { level = level, xp = xp }
    return Save.saveProfile(p, currentSlot)
end

function Save.getGold()
    return currentProfile().gold
end

function Save.addGold(amount)
    local p = currentProfile()
    p.gold = math.max(0, p.gold + math.floor(amount))
    return Save.saveProfile(p, currentSlot)
end

function Save.getPurchases()
    return currentProfile().purchases
end

-- Spend gold on an item. Permanent items can be bought once.
-- Returns true on success, or false and a reason.
function Save.buyItem(itemId, cost, consumable)
    local p = currentProfile()
    local owned = p.purchases[itemId] or 0
    if not consumable and owned > 0 then return false, "already owned" end
    if p.gold < cost then return false, "not enough gold" end
    p.gold = p.gold - cost
    p.purchases[itemId] = owned + 1
    Save.saveProfile(p, currentSlot)
    return true
end

-- Best result on a level: { stars = 1..3 } or nil if never won
function Save.getLevelResult(levelId)
    return currentProfile().levels[levelId]
end

-- Record a win; keeps the best star count
function Save.recordLevelResult(levelId, stars)
    if not levelId then return false end
    local p = currentProfile()
    local old = p.levels[levelId]
    if not old or (old.stars or 0) < stars then
        p.levels[levelId] = { stars = stars }
    end
    return Save.saveProfile(p, currentSlot)
end

-- Add a finished game to the current profile's totals and unlock what it
-- earned (systems/achievements.lua). Returns the newly unlocked ones.
function Save.recordGame(result)
    local p = currentProfile()
    local new = require('systems.achievements').recordGame(p, result)
    Save.saveProfile(p, currentSlot)
    return new
end

-- Use up one of each listed consumable
function Save.useConsumables(ids)
    local p = currentProfile()
    for _, id in ipairs(ids or {}) do
        local n = (p.purchases[id] or 0) - 1
        p.purchases[id] = n > 0 and n or nil
    end
    return Save.saveProfile(p, currentSlot)
end

------------------------------------------------------------------------
-- Profile slots (the Load Game screen). A profile is everything a player
-- keeps: faction and hero, hero levels, shop gold and items, level stars.
-- The slot last used is remembered in save/last_slot.txt for Continue.
------------------------------------------------------------------------
Save.SLOT_COUNT = #SAVE_SLOTS
local LAST_SLOT_FILE = "save/last_slot.txt"

local function profilePath(slot) return string.format("save/profile_%d.json", slot) end

-- Make `slot` the current profile and remember it for the next launch
function Save.useSlot(slot)
    if type(slot) ~= "number" or slot < 1 or slot > Save.SLOT_COUNT then return false end
    currentSlot = slot
    profileCache = nil -- forget the cached profile of the previous slot
    love.filesystem.createDirectory("save")
    love.filesystem.write(LAST_SLOT_FILE, tostring(slot))
    return true
end

function Save.currentSlotNumber() return currentSlot end

-- At launch: go back to the slot used last time. Returns it, or nil.
function Save.restoreLastSlot()
    local n = tonumber(love.filesystem.getInfo(LAST_SLOT_FILE) and love.filesystem.read(LAST_SLOT_FILE) or "")
    if n and n >= 1 and n <= Save.SLOT_COUNT then
        currentSlot = n
        profileCache = nil
        return n
    end
end

function Save.slotUsed(slot) return love.filesystem.getInfo(profilePath(slot)) ~= nil end

function Save.firstEmptySlot()
    for i = 1, Save.SLOT_COUNT do
        if not Save.slotUsed(i) then return i end
    end
end

-- Start a fresh profile in `slot` and make it current
function Save.newProfile(slot)
    local profile = { playerName = "Player" .. slot, heroes = {}, levels = {}, purchases = {}, gold = 0 }
    if not Save.saveProfile(profile, slot) then return false end
    Save.useSlot(slot)
    profileCache = profile
    return true
end

function Save.deleteProfile(slot)
    love.filesystem.remove(profilePath(slot))
    if slot == currentSlot then profileCache = nil end
    return not Save.slotUsed(slot)
end

-- What the profile screen shows for a slot: nil when empty, else
-- { slot, faction, hero, stars, wins, gold, timestamp } (names, not ids)
function Save.slotSummary(slot)
    local p = Save.slotUsed(slot) and Save.loadProfile(slot)
    if not p then return nil end
    local Selection = require('utils.selection')
    local s = { slot = slot, stars = 0, wins = 0, gold = p.gold or 0, timestamp = p.timestamp }
    if p.selectedFaction then
        local f, h = Selection.canonical(p.selectedFaction, p.selectedHero)
        s.faction = f and f.name
        s.hero = p.selectedHero and h and h.name or nil
    end
    for _, r in pairs(p.levels or {}) do
        s.stars = s.stars + (r.stars or 0)
        s.wins = s.wins + 1
    end
    return s
end

return Save 