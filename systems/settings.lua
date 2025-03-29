local Settings = {}
Settings.__index = Settings

-- Default settings
local DEFAULT_SETTINGS = {
    audio = {
        masterVolume = 1.0,
        musicVolume = 0.8,
        sfxVolume = 0.8,
        ambientVolume = 0.6
    },
    graphics = {
        quality = "high", -- low, medium, high
        particles = true,
        weatherEffects = true,
        screenShake = true
    },
    gameplay = {
        waveBreakStyle = "auto", -- auto, manual, none
        towerRangeIndicator = true,
        enemyHealthBars = true,
        tooltips = true
    },
    controls = {
        mouseSensitivity = 1.0,
        invertY = false,
        quickSelectKeys = true
    }
}

function Settings.new()
    local self = setmetatable({}, Settings)
    
    self.settings = {}
    self:loadSettings()
    
    return self
end

function Settings:loadSettings()
    -- Try to load settings from file
    local success, data = pcall(function()
        return love.filesystem.read("settings.json")
    end)
    
    if success and data then
        self.settings = json.decode(data)
    else
        -- Use default settings
        self.settings = DEFAULT_SETTINGS
    end
    
    -- Apply settings
    self:applySettings()
end

function Settings:saveSettings()
    -- Save settings to file
    local success, err = pcall(function()
        return love.filesystem.write("settings.json", json.encode(self.settings))
    end)
    
    if not success then
        print("Failed to save settings:", err)
    end
end

function Settings:applySettings()
    -- Apply audio settings
    love.audio.setVolume(self.settings.audio.masterVolume)
    
    -- Apply graphics settings
    if self.settings.graphics.quality == "low" then
        -- Disable expensive effects
        self.settings.graphics.particles = false
        self.settings.graphics.weatherEffects = false
    end
    
    -- Apply gameplay settings
    if self.settings.gameplay.waveBreakStyle == "none" then
        -- Disable wave breaks
        gameState.waveBreakEnabled = false
    else
        gameState.waveBreakEnabled = true
    end
end

function Settings:getSetting(category, setting)
    return self.settings[category][setting]
end

function Settings:setSetting(category, setting, value)
    self.settings[category][setting] = value
    self:applySettings()
    self:saveSettings()
end

function Settings:createSettingsUI()
    local panel = loveframes.Create("panel")
    panel:SetName("Settings")
    panel:SetSize(400, 500)
    panel:Center()
    
    -- Audio Settings
    local audioLabel = loveframes.Create("text", panel)
    audioLabel:SetText("Audio Settings")
    audioLabel:SetPos(10, 30)
    
    -- Master Volume
    local masterVolume = loveframes.Create("slider", panel)
    masterVolume:SetPos(10, 60)
    masterVolume:SetWidth(380)
    masterVolume:SetMin(0)
    masterVolume:SetMax(1)
    masterVolume:SetValue(self.settings.audio.masterVolume)
    masterVolume.OnValueChanged = function(object, value)
        self:setSetting("audio", "masterVolume", value)
    end
    
    local masterLabel = loveframes.Create("text", panel)
    masterLabel:SetText("Master Volume")
    masterLabel:SetPos(10, 85)
    
    -- Music Volume
    local musicVolume = loveframes.Create("slider", panel)
    musicVolume:SetPos(10, 110)
    musicVolume:SetWidth(380)
    musicVolume:SetMin(0)
    musicVolume:SetMax(1)
    musicVolume:SetValue(self.settings.audio.musicVolume)
    musicVolume.OnValueChanged = function(object, value)
        self:setSetting("audio", "musicVolume", value)
    end
    
    local musicLabel = loveframes.Create("text", panel)
    musicLabel:SetText("Music Volume")
    musicLabel:SetPos(10, 135)
    
    -- Graphics Settings
    local graphicsLabel = loveframes.Create("text", panel)
    graphicsLabel:SetText("Graphics Settings")
    graphicsLabel:SetPos(10, 170)
    
    -- Quality
    local quality = loveframes.Create("multichoice", panel)
    quality:SetPos(10, 200)
    quality:SetWidth(380)
    quality:SetChoice(self.settings.graphics.quality)
    quality:AddChoice("Low")
    quality:AddChoice("Medium")
    quality:AddChoice("High")
    quality.OnChoiceSelected = function(object, choice)
        self:setSetting("graphics", "quality", choice:lower())
    end
    
    -- Particles
    local particles = loveframes.Create("checkbox", panel)
    particles:SetPos(10, 240)
    particles:SetText("Enable Particles")
    particles:SetChecked(self.settings.graphics.particles)
    particles.OnChanged = function(object, checked)
        self:setSetting("graphics", "particles", checked)
    end
    
    -- Weather Effects
    local weather = loveframes.Create("checkbox", panel)
    weather:SetPos(10, 270)
    weather:SetText("Enable Weather Effects")
    weather:SetChecked(self.settings.graphics.weatherEffects)
    weather.OnChanged = function(object, checked)
        self:setSetting("graphics", "weatherEffects", checked)
    end
    
    -- Gameplay Settings
    local gameplayLabel = loveframes.Create("text", panel)
    gameplayLabel:SetText("Gameplay Settings")
    gameplayLabel:SetPos(10, 310)
    
    -- Wave Break Style
    local waveBreak = loveframes.Create("multichoice", panel)
    waveBreak:SetPos(10, 340)
    waveBreak:SetWidth(380)
    waveBreak:SetChoice(self.settings.gameplay.waveBreakStyle)
    waveBreak:AddChoice("Auto")
    waveBreak:AddChoice("Manual")
    waveBreak:AddChoice("None")
    waveBreak.OnChoiceSelected = function(object, choice)
        self:setSetting("gameplay", "waveBreakStyle", choice:lower())
    end
    
    -- Tower Range Indicator
    local rangeIndicator = loveframes.Create("checkbox", panel)
    rangeIndicator:SetPos(10, 380)
    rangeIndicator:SetText("Show Tower Range")
    rangeIndicator:SetChecked(self.settings.gameplay.towerRangeIndicator)
    rangeIndicator.OnChanged = function(object, checked)
        self:setSetting("gameplay", "towerRangeIndicator", checked)
    end
    
    -- Enemy Health Bars
    local healthBars = loveframes.Create("checkbox", panel)
    healthBars:SetPos(10, 410)
    healthBars:SetText("Show Enemy Health Bars")
    healthBars:SetChecked(self.settings.gameplay.enemyHealthBars)
    healthBars.OnChanged = function(object, checked)
        self:setSetting("gameplay", "enemyHealthBars", checked)
    end
    
    -- Close Button
    local closeButton = loveframes.Create("button", panel)
    closeButton:SetPos(150, 450)
    closeButton:SetSize(100, 30)
    closeButton:SetText("Close")
    closeButton.OnClick = function(object, x, y)
        panel:Remove()
    end
    
    return panel
end

function Settings:draw()
    -- Draw settings UI if active
    if self.settingsPanel then
        self.settingsPanel:draw()
    end
end

function Settings:update(dt)
    -- Update settings UI if active
    if self.settingsPanel then
        self.settingsPanel:update(dt)
    end
end

function Settings:mousepressed(x, y, button)
    -- Handle settings UI input if active
    if self.settingsPanel then
        self.settingsPanel:mousepressed(x, y, button)
    end
end

function Settings:mousereleased(x, y, button)
    -- Handle settings UI input if active
    if self.settingsPanel then
        self.settingsPanel:mousereleased(x, y, button)
    end
end

function Settings:keypressed(key)
    -- Handle settings UI input if active
    if self.settingsPanel then
        self.settingsPanel:keypressed(key)
    end
end

function Settings:keyreleased(key)
    -- Handle settings UI input if active
    if self.settingsPanel then
        self.settingsPanel:keyreleased(key)
    end
end

return Settings 