local Save = {}
Save.__index = Save

-- Import dependencies
local Error = require 'utils.error'
local json = require 'libs.json'

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
local gameState = nil

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
            gameState = {
                resources = gameState.resources,
                lives = gameState.lives,
                currentWave = gameState.currentWave,
                selectedFaction = gameState.selectedFaction,
                selectedHero = gameState.selectedHero,
                towers = {},
                enemies = {},
                projectiles = {},
                hero = gameState.hero and gameState.hero:serialize() or nil,
                map = gameState.map and gameState.map:serialize() or nil
            }
        }
        
        -- Serialize towers
        for _, tower in ipairs(gameState.towers) do
            table.insert(saveData.gameState.towers, tower:serialize())
        end
        
        -- Serialize enemies
        for _, enemy in ipairs(gameState.enemies) do
            table.insert(saveData.gameState.enemies, enemy:serialize())
        end
        
        -- Serialize projectiles
        for _, projectile in ipairs(gameState.projectiles) do
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
        gameState.resources = data.gameState.resources
        gameState.lives = data.gameState.lives
        gameState.currentWave = data.gameState.currentWave
        gameState.selectedFaction = data.gameState.selectedFaction
        gameState.selectedHero = data.gameState.selectedHero
        
        -- Restore hero
        if data.gameState.hero then
            gameState.hero = Hero.deserialize(data.gameState.hero)
        end
        
        -- Restore map
        if data.gameState.map then
            gameState.map = Map.deserialize(data.gameState.map)
        end
        
        -- Restore towers
        gameState.towers = {}
        for _, towerData in ipairs(data.gameState.towers) do
            table.insert(gameState.towers, Tower.deserialize(towerData))
        end
        
        -- Restore enemies
        gameState.enemies = {}
        for _, enemyData in ipairs(data.gameState.enemies) do
            table.insert(gameState.enemies, Enemy.deserialize(enemyData))
        end
        
        -- Restore projectiles
        gameState.projectiles = {}
        for _, projectileData in ipairs(data.gameState.projectiles) do
            table.insert(gameState.projectiles, Projectile.deserialize(projectileData))
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
    if not gameState or gameState.gameOver then return end
    
    -- We don't need to do anything in autoSave yet since we don't have a proper game state
    -- This is just a stub to prevent errors when called from game.lua
    print("Auto-save would happen here if we had game data")
    
    -- When properly implemented, it would do something like:
    -- if Save.saveGame(currentSlot) then
    --     -- Show auto-save notification if needed
    -- end
end

function Save:saveSettings()
    local success, error = Error.pcall(function()
        local file = io.open("save/settings.json", "w")
        if file then
            file:write(json.encode(self.settings))
            file:close()
            return true
        end
        return false
    end, Error.TYPES.SAVE, "SETTINGS_SAVE_FAILED")
    
    if not success then
        Error.handle(Error.TYPES.SAVE, "SETTINGS_SAVE_FAILED", error)
        return false
    end
    
    return true
end

function Save:loadSettings()
    local success, error = Error.pcall(function()
        local file = io.open("save/settings.json", "r")
        if file then
            local data = json.decode(file:read("*all"))
            file:close()
            
            -- Merge with default settings
            if data then
                for k, v in pairs(data) do
                    if self.settings[k] ~= nil then
                        self.settings[k] = v
                    end
                end
            end
            
            return true
        end
        return false
    end, Error.TYPES.LOAD, "SETTINGS_LOAD_FAILED")
    
    if not success then
        Error.handle(Error.TYPES.LOAD, "SETTINGS_LOAD_FAILED", error)
        return false
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
    return self.settings
end

function Save:setSetting(key, value)
    if self.settings[key] ~= nil then
        self.settings[key] = value
        self:saveSettings()
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
    
    -- If we don't have a proper gameState yet, create a simple one
    if not gameState then
        gameState = {
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
        -- Update existing gameState with new data
        gameState.selectedFaction = data.faction or gameState.selectedFaction
        gameState.selectedHero = data.hero or gameState.selectedHero
        gameState.resources = data.resources or gameState.resources
        gameState.lives = data.lives or gameState.lives
        gameState.currentWave = data.wave or gameState.currentWave
        gameState.victory = data.victory or gameState.victory
        gameState.timestamp = os.time()
    end
    
    -- Save the current profile
    Save.saveProfile(gameState, currentSlot)
    
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
    
    local success, result = Error.pcall(function()
        if not love.filesystem.getInfo(filePath) then
            Error.handle(Error.TYPES.LOAD, "PROFILE_MISSING", slot)
            return nil
        end
        
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
        
        -- Store in global gameState for non-instanced access
        gameState = profile
        
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
    if not gameState then
        gameState = Save.loadProfile(currentSlot)
    end
    
    return gameState
end

-- Update faction selection in current profile
function Save.updateFactionSelection(factionId)
    if not gameState then
        gameState = Save.loadProfile(currentSlot) or {
            playerName = "Player1",
            selectedFaction = factionId,
            currentLevel = 1,
            completedLevels = {},
            towerUpgrades = {},
            resources = 200,
            timestamp = os.time()
        }
    else
        gameState.selectedFaction = factionId
    end
    
    -- Debug info
    print("Saving faction selection: " .. (factionId or "nil"))
    
    Save.saveProfile(gameState, currentSlot)
    return true
end

-- Update hero selection in current profile
function Save.updateHeroSelection(heroId)
    if not gameState then
        gameState = Save.loadProfile(currentSlot) or {
            playerName = "Player1",
            selectedHero = heroId,
            currentLevel = 1,
            completedLevels = {},
            towerUpgrades = {},
            resources = 200,
            timestamp = os.time()
        }
    else
        gameState.selectedHero = heroId
    end
    
    -- Debug info
    print("Saving hero selection: " .. (heroId or "nil"))
    
    Save.saveProfile(gameState, currentSlot)
    return true
end

return Save 