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
    
    -- Initialize sounds
    initSounds()
    
    -- Load settings
    Save:loadSettings()
    
    -- Create the splash state instance
    local splashState = require('states.splash').new()
    
    -- Start with splash screen
    Gamestate.switch(splashState)
end

-- Initialize all game sounds
function initSounds()
    -- Helper function to safely load a sound or create a placeholder if not found
    local function safeAudioLoad(path, sourceType)
        local success, result = pcall(love.audio.newSource, path, sourceType)
        if success then
            return result
        else
            print("Warning: Could not load sound " .. path .. ", using placeholder instead.")
            -- Create a silent placeholder sound
            local placeholder = love.audio.newSource(love.sound.newSoundData(1024, 44100, 16, 1), "static")
            return placeholder
        end
    end
    
    -- Music
    sounds.music.menu = safeAudioLoad("sounds/music/menu.mp3", "stream")
    sounds.music.game = safeAudioLoad("sounds/music/game.mp3", "stream")
    sounds.music.victory = safeAudioLoad("sounds/music/victory.mp3", "stream")
    sounds.music.defeat = safeAudioLoad("sounds/music/defeat.mp3", "stream")
    
    -- SFX
    sounds.sfx.buttonClick = safeAudioLoad("sounds/sfx/button_click.wav", "static")
    sounds.sfx.towerPlace = safeAudioLoad("sounds/sfx/tower_place.wav", "static")
    sounds.sfx.towerSell = safeAudioLoad("sounds/sfx/tower_sell.wav", "static")
    sounds.sfx.towerUpgrade = safeAudioLoad("sounds/sfx/tower_upgrade.wav", "static")
    sounds.sfx.enemyHit = safeAudioLoad("sounds/sfx/enemy_hit.wav", "static")
    sounds.sfx.enemyDie = safeAudioLoad("sounds/sfx/enemy_die.wav", "static")
    sounds.sfx.waveStart = safeAudioLoad("sounds/sfx/wave_start.wav", "static")
    sounds.sfx.gameOver = safeAudioLoad("sounds/sfx/game_over.wav", "static")
    sounds.sfx.victory = safeAudioLoad("sounds/sfx/victory.wav", "static")
    sounds.sfx.heroAbility = safeAudioLoad("sounds/sfx/hero_ability.wav", "static")
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
    Save:saveSettings()
end

-- Global helper functions
function playSound(soundType, soundName)
    if sounds[soundType] and sounds[soundType][soundName] then
        local volume = soundType == 'music' and gameState.settings.musicVolume or gameState.settings.sfxVolume
        sounds[soundType][soundName]:setVolume(volume)
        sounds[soundType][soundName]:play()
    end
end

function stopSound(soundType, soundName)
    if sounds[soundType] and sounds[soundType][soundName] then
        sounds[soundType][soundName]:stop()
    end
end

function setVolume(soundType, volume)
    if soundType == 'music' then
        gameState.settings.musicVolume = volume
        for _, sound in pairs(sounds.music) do
            sound:setVolume(volume)
        end
    elseif soundType == 'sfx' then
        gameState.settings.sfxVolume = volume
        for _, sound in pairs(sounds.sfx) do
            sound:setVolume(volume)
        end
    end
end 