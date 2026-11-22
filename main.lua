local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'

-- Load states
local SplashState = require 'states.splash'
local MenuState = require 'states.menu'
local GameState = require 'states.game'
local PauseState = require 'states.pause'
local SettingsState = require 'states.settings'
local TutorialState = require 'states.tutorial'
local CreditsState = require 'states.credits'
local AchievementState = require 'states.achievement'
local FactionSelectState = require 'states.faction_select'
local HeroSelectState = require 'states.hero_select'
local LoadGameState = require 'states.load_game'

-- Load systems
local Save = require 'systems.save'
local UI = require 'systems.ui'
local Error = require 'utils.error'

-- Global game state
gameState = {
    resources = 100,
    lives = 3,
    currentWave = 0,
    totalWaves = 10,
    towers = {},
    enemies = {},
    projectiles = {},
    selectedTower = nil,
    hero = nil,
    selectedFaction = nil,
    settings = {
        musicVolume = 1.0,
        sfxVolume = 1.0,
        showTutorial = true,
        fullscreen = false
    }
}

-- Global sounds table
sounds = {
    music = {},
    sfx = {}
}

-- Global fonts
fonts = {
    main = nil,
    title = nil
}

function love.load()
    -- Initialize fonts from the fonts folder
    local success, error = pcall(function()
        fonts.main = love.graphics.newFont("fonts/main.ttf", 14)
        fonts.title = love.graphics.newFont("fonts/title.ttf", 32)
    end)
    
    if not success then
        print("Warning: Could not load custom fonts, using defaults instead. Error: " .. error)
        fonts.main = love.graphics.newFont(14)
        fonts.title = love.graphics.newFont(32)
    end
    
    -- Set default font
    love.graphics.setFont(fonts.main)
    
    -- Initialize random seed
    love.math.setRandomSeed(os.time())
    
    -- Settings first, so sounds start at the saved volumes
    Save.loadSettings(gameState.settings)
    if gameState.settings.fullscreen then love.window.setFullscreen(true) end

    -- Initialize sounds
    initSounds()
    
    -- Check for save directory
    love.filesystem.createDirectory("save")
    
    -- Check for last played game
    local lastProfile = Save.getCurrentProfile()
    
    -- Determine which state to show initially
    local initialState
    
    if lastProfile then
        -- Last profile found, go straight to menu to allow loading
        print("Found last played profile: " .. lastProfile.playerName)
        initialState = require('states.menu').new()
    else
        -- No profile found, show load game screen to create a new one
        print("No profiles found, showing load game screen")
        initialState = require('states.load_game').new()
    end
    
    -- Start with the determined initial screen
    Gamestate.switch(initialState)
end

-- Load sounds and music (systems/audio.lua) at the saved volumes
function initSounds()
    local Audio = require('systems.audio')
    Audio.init()
    Audio.setVolumes(gameState.settings.musicVolume, gameState.settings.sfxVolume)
end

function love.update(dt)
    -- Update current state
    if Gamestate.current() then
        Gamestate.current():update(dt)
    end
    
    -- Update error notifications
    Error.update(dt)
end

function love.draw()
    -- Draw current state
    if Gamestate.current() then
        Gamestate.current():draw()
    end
    
    -- Draw error notifications
    Error.draw()
end

function love.keypressed(key)
    -- Handle global key presses
    if key == "f11" then
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    end
    
    -- Handle state key presses
    if Gamestate.current() and Gamestate.current().keypressed then
        Gamestate.current():keypressed(key)
    end
end

function love.keyreleased(key)
    if Gamestate.current() and Gamestate.current().keyreleased then
        Gamestate.current():keyreleased(key)
    end
end

function love.mousepressed(x, y, button)
    if Gamestate.current() and Gamestate.current().mousepressed then
        Gamestate.current():mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if Gamestate.current() and Gamestate.current().mousereleased then
        Gamestate.current():mousereleased(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if Gamestate.current() and Gamestate.current().mousemoved then
        Gamestate.current():mousemoved(x, y, dx, dy)
    end
end

function love.wheelmoved(x, y)
    if Gamestate.current() and Gamestate.current().wheelmoved then
        Gamestate.current():wheelmoved(x, y)
    end
end

function love.textinput(text)
    if Gamestate.current() and Gamestate.current().textinput then
        Gamestate.current():textinput(text)
    end
end

function love.quit()
    -- Save settings before quitting
    Save.saveSettings(gameState.settings)
end

-- Global helpers kept for the screens that call them. Old sound names map
-- onto systems/audio.lua events; names with no event are ignored.
local OLD_SFX = { buttonClick = "click", towerPlace = "place", towerSell = "sell", enemyDeath = "enemy_die",
    playerDamage = "life_lost", heroAbility = "ability", waveStart = "wave_start", purchase = "purchase",
    levelUp = "level_up", upgrade = "upgrade" }

function playSound(soundType, soundName)
    local Audio = require('systems.audio')
    if soundType == 'music' then
        if Audio.MUSIC[soundName] then Audio.playMusic(soundName) end
    else
        Audio.play(OLD_SFX[soundName] or soundName)
    end
end

function stopSound(soundType, soundName)
    local Audio = require('systems.audio')
    if soundType == 'music' and Audio.currentMusic == soundName then Audio.stopMusic() end
end

function setVolume(soundType, volume)
    local Audio = require('systems.audio')
    if soundType == 'music' then
        gameState.settings.musicVolume = volume
        Audio.setVolumes(volume, nil)
    elseif soundType == 'sfx' then
        gameState.settings.sfxVolume = volume
        Audio.setVolumes(nil, volume)
    end
end
