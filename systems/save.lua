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

-- Auto-save settings
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes
local AUTO_SAVE_BEFORE_WAVE = true
local AUTO_SAVE_ON_QUIT = true
local currentSlot = 1
local lastSaveTime = 0

-- Add global state variable for non-instanced access
-- The current profile, cached (loaded on first use). Not the global
-- `gameState` from main.lua, which holds the settings.
local profileCache = nil

function Save.new()
    local self = setmetatable({}, Save)
    
    self.currentSlot = 1
    self.autoSaveTimer = 0
    self.lastSaveTime = 0
    self.settings = {
        musicVolume = 1.0,
        sfxVolume = 1.0,
        fullscreen = false,
        showTutorial = true,
        autoSave = true,
        autoSaveInterval = AUTO_SAVE_INTERVAL
    }
    
    return self
end

function Save:update(dt)
    if not self.settings.autoSave then return end
    
    self.autoSaveTimer = self.autoSaveTimer + dt
    if self.autoSaveTimer >= self.settings.autoSaveInterval then
        self:autoSave()
        self.autoSaveTimer = 0
    end
end

function Save:saveGame(slot)
    if not slot then slot = self.currentSlot end
    
    local success, error = Error.pcall(function()
        local saveData = {
            timestamp = os.time(),
            profileCache = {
                resources = profileCache.resources,
                lives = profileCache.lives,
                currentWave = profileCache.currentWave,
                selectedFaction = profileCache.selectedFaction,
                selectedHero = profileCache.selectedHero,
                towers = {},
                enemies = {},
                projectiles = {},
                hero = profileCache.hero and profileCache.hero:serialize() or nil,
                map = profileCache.map and profileCache.map:serialize() or nil
            }
        }
        
        -- Serialize towers
        for _, tower in ipairs(profileCache.towers) do
            table.insert(saveData.gameState.towers, tower:serialize())
        end
        
        -- Serialize enemies
        for _, enemy in ipairs(profileCache.enemies) do
            table.insert(saveData.gameState.enemies, enemy:serialize())
        end
        
        -- Serialize projectiles
        for _, projectile in ipairs(profileCache.projectiles) do
            table.insert(saveData.gameState.projectiles, projectile:serialize())
        end
        
        -- Save to file
        local file = io.open(string.format("save/slot_%d.json", slot), "w")
        if file then
            file:write(json.encode(saveData))
            file:close()
            self.lastSaveTime = os.time()
            return true
        end
        return false
    end, Error.TYPES.SAVE, "SAVE_FAILED")
    
    if not success then
        Error.handle(Error.TYPES.SAVE, "SAVE_FAILED", error)
        return false
    end
    
    return true
end

function Save:loadGame(slot)
    if not slot then slot = self.currentSlot end
    
    local success, error = Error.pcall(function()
        local file = io.open(string.format("save/slot_%d.json", slot), "r")
        if not file then
            Error.handle(Error.TYPES.LOAD, "MISSING_FILE", slot)
            return false
        end
        
        local data = json.decode(file:read("*all"))
        file:close()
        
        if not data or not data.gameState then
            Error.handle(Error.TYPES.LOAD, "INVALID_DATA", slot)
            return false
        end
        
        -- Restore game state
        profileCache.resources = data.gameState.resources
        profileCache.lives = data.gameState.lives
        profileCache.currentWave = data.gameState.currentWave
        profileCache.selectedFaction = data.gameState.selectedFaction
        profileCache.selectedHero = data.gameState.selectedHero
        
        -- Restore hero
        if data.gameState.hero then
            profileCache.hero = Hero.deserialize(data.gameState.hero)
        end
        
        -- Restore map
        if data.gameState.map then
            profileCache.map = Map.deserialize(data.gameState.map)
        end
        
        -- Restore towers
        profileCache.towers = {}
        for _, towerData in ipairs(data.gameState.towers) do
            table.insert(profileCache.towers, Tower.deserialize(towerData))
        end
        
        -- Restore enemies
        profileCache.enemies = {}
        for _, enemyData in ipairs(data.gameState.enemies) do
            table.insert(profileCache.enemies, Enemy.deserialize(enemyData))
        end
        
        -- Restore projectiles
        profileCache.projectiles = {}
        for _, projectileData in ipairs(data.gameState.projectiles) do
            table.insert(profileCache.projectiles, Projectile.deserialize(projectileData))
        end
        
        self.lastSaveTime = data.timestamp
        return true
    end, Error.TYPES.LOAD, "LOAD_FAILED")
    
    if not success then
        Error.handle(Error.TYPES.LOAD, "LOAD_FAILED", error)
        return false
    end
    
    return true
end

-- Making autoSave a module function instead of an instance method
function Save.autoSave()
    if not profileCache or profileCache.gameOver then return end
    
    -- We don't need to do anything in autoSave yet since we don't have a proper game state
    -- This is just a stub to prevent errors when called from game.lua
    print("Auto-save would happen here if we had game data")
    
    -- When properly implemented, it would do something like:
    -- if Save.saveGame(currentSlot) then
    --     -- Show auto-save notification if needed
    -- end
end

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

function Save:getSaveInfo(slot)
    local file = io.open(string.format("save/slot_%d.json", slot), "r")
    if not file then return nil end
    
    local data = json.decode(file:read("*all"))
    file:close()
    
    return {
        slot = slot,
        timestamp = data.timestamp,
        faction = data.gameState.selectedFaction,
        wave = data.gameState.currentWave,
        resources = data.gameState.resources,
        lives = data.gameState.lives
    }
end

function Save:getAllSaveInfo()
    local saves = {}
    for _, slot in ipairs(SAVE_SLOTS) do
        local info = self:getSaveInfo(slot.id)
        if info then
            table.insert(saves, info)
        end
    end
    return saves
end

function Save:deleteSave(slot)
    local success, error = Error.pcall(function()
        os.remove(string.format("save/slot_%d.json", slot))
        return true
    end, Error.TYPES.SAVE, "DELETE_FAILED")
    
    if not success then
        Error.handle(Error.TYPES.SAVE, "DELETE_FAILED", error)
        return false
    end
    
    return true
end

function Save:setCurrentSlot(slot)
    if slot >= 1 and slot <= #SAVE_SLOTS then
        self.currentSlot = slot
        return true
    end
    return false
end

-- Module version of setCurrentSlot
function Save.setCurrentSlot(slot)
    if type(slot) ~= "number" then
        print("Error: Invalid slot type, expected number but got " .. type(slot))
        return false
    end
    
    if slot >= 1 and slot <= #SAVE_SLOTS then
        currentSlot = slot
        print("Set current slot to " .. slot)
        return true
    end
    
    print("Error: Slot " .. slot .. " is out of range (1-" .. #SAVE_SLOTS .. ")")
    return false
end

function Save:getCurrentSlot()
    return self.currentSlot
end

function Save:getLastSaveTime()
    return self.lastSaveTime
end

function Save:getSaveSlots()
    return SAVE_SLOTS
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

-- Making saveGame a module function as well
function Save.saveGame(slot)
    if not slot then slot = currentSlot end
    
    -- Simple static implementation
    -- This is just a stub but would prevent errors if called
    print("Static saveGame called for slot " .. slot)
    lastSaveTime = os.time()
    return true
end

-- Add the saveGameState function that's being called from game.lua
function Save.saveGameState(data)
    -- Ensure save directory exists
    love.filesystem.createDirectory("save")
    
    -- If we don't have a proper profileCache yet, create a simple one
    if not profileCache then
        profileCache = {
            playerName = "Player1",
            selectedFaction = data.faction or "default",
            selectedHero = data.hero or "default_hero",
            currentLevel = 1,
            completedLevels = {},
            towerUpgrades = {},
            resources = data.resources or 0,
            lives = data.lives or 0,
            currentWave = data.wave or 1,
            victory = data.victory or false,
            timestamp = os.time()
        }
    else
        -- Update existing profileCache with new data
        profileCache.selectedFaction = data.faction or profileCache.selectedFaction
        profileCache.selectedHero = data.hero or profileCache.selectedHero
        profileCache.resources = data.resources or profileCache.resources
        profileCache.lives = data.lives or profileCache.lives
        profileCache.currentWave = data.wave or profileCache.currentWave
        profileCache.victory = data.victory or profileCache.victory
        profileCache.timestamp = os.time()
    end
    
    -- Save the current profile
    Save.saveProfile(profileCache, currentSlot)
    
    return true
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