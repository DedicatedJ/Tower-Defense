local Weather = {}
Weather.__index = Weather

-- Weather states
local WEATHER_STATES = {
    normal = {
        name = "Normal",
        duration = 60,
        effect = function()
            -- No effect
        end
    },
    rain = {
        name = "Rain",
        duration = 60,
        effect = function()
            -- Slow projectiles by 10%
            for _, projectile in ipairs(gameState.projectiles) do
                projectile.speed = projectile.baseSpeed * 0.9
            end
        end
    },
    sunny = {
        name = "Sunny",
        duration = 60,
        effect = function()
            -- Boost Radiant Order towers by 10%
            for _, tower in ipairs(gameState.towers) do
                if tower.faction == "radiant" then
                    tower.stats.damage = tower.stats.damage * 1.1
                end
            end
        end
    },
    foggy = {
        name = "Foggy",
        duration = 60,
        effect = function()
            -- Reduce tower range by 10%, enhance Twilight Balance slow effects
            for _, tower in ipairs(gameState.towers) do
                tower.stats.range = tower.stats.range * 0.9
                if tower.faction == "twilight" then
                    if tower.stats.slow then
                        tower.stats.slow.amount = tower.stats.slow.amount * 1.05
                    end
                end
            end
        end
    },
    storm = {
        name = "Storm",
        duration = 60,
        effect = function()
            -- Boost lightning damage, slow tower attack speed
            for _, tower in ipairs(gameState.towers) do
                if tower.stats.lightning then
                    tower.stats.damage = tower.stats.damage * 1.15
                end
                tower.stats.attackSpeed = tower.stats.attackSpeed * 0.95
            end
        end
    }
}

-- Environmental hazards
local ENVIRONMENTAL_HAZARDS = {
    thunderstorm = {
        name = "Thunderstorm",
        duration = 45,
        warning = 10,
        effect = function()
            -- Slow tower attack speed by 25%
            for _, tower in ipairs(gameState.towers) do
                tower.stats.attackSpeed = tower.stats.attackSpeed * 0.75
            end
        end
    },
    meteorShower = {
        name = "Meteor Shower",
        duration = 30,
        warning = 10,
        effect = function()
            -- Damage enemies and towers
            for _, enemy in ipairs(gameState.enemies) do
                if math.random() < 0.75 then -- 75% chance to hit enemies
                    enemy:takeDamage({amount = 50, type = "physical"})
                end
            end
            for _, tower in ipairs(gameState.towers) do
                if math.random() < 0.25 then -- 25% chance to hit towers
                    tower.health = tower.health - 25
                end
            end
        end
    },
    mistOfConfusion = {
        name = "Mist of Confusion",
        duration = 40,
        warning = 10,
        effect = function()
            -- 25% chance for towers to target wrong enemy
            for _, tower in ipairs(gameState.towers) do
                if math.random() < 0.25 then
                    local enemies = gameState.enemies
                    local randomEnemy = enemies[math.random(#enemies)]
                    tower.target = randomEnemy
                end
            end
        end
    },
    solarFlare = {
        name = "Solar Flare",
        duration = 50,
        warning = 10,
        effect = function()
            -- Increase enemy speed and tower damage
            for _, enemy in ipairs(gameState.enemies) do
                enemy.stats.speed = enemy.stats.speed * 1.2
            end
            for _, tower in ipairs(gameState.towers) do
                tower.stats.damage = tower.stats.damage * 1.15
            end
        end
    },
    earthquake = {
        name = "Earthquake",
        duration = 35,
        warning = 10,
        effect = function()
            -- 10% tower miss chance, slow ground enemies
            for _, tower in ipairs(gameState.towers) do
                tower.stats.missChance = 0.1
            end
            for _, enemy in ipairs(gameState.enemies) do
                if not enemy.stats.air then
                    enemy.stats.speed = enemy.stats.speed * 0.85
                end
            end
        end
    },
    arcaneSurge = {
        name = "Arcane Surge",
        duration = 60,
        warning = 10,
        effect = function()
            -- Amplify magical effects
            for _, tower in ipairs(gameState.towers) do
                if tower.stats.magic then
                    tower.stats.damage = tower.stats.damage * 1.5
                end
            end
        end
    }
}

function Weather.new()
    local self = setmetatable({}, Weather)
    
    self.currentWeather = "normal"
    self.weatherTimer = 0
    self.hazardTimer = 0
    self.hazardWarning = 0
    self.activeHazard = nil
    
    return self
end

function Weather:update(dt)
    -- Update weather cycle
    self.weatherTimer = self.weatherTimer + dt
    if self.weatherTimer >= WEATHER_STATES[self.currentWeather].duration then
        self:changeWeather()
    end
    
    -- Update hazard
    if self.activeHazard then
        self.hazardTimer = self.hazardTimer + dt
        if self.hazardTimer >= self.activeHazard.duration then
            self:endHazard()
        end
    end
    
    -- Apply weather effects
    WEATHER_STATES[self.currentWeather].effect()
    
    -- Apply hazard effects if active
    if self.activeHazard then
        self.activeHazard.effect()
    end
end

function Weather:changeWeather()
    local weathers = {}
    for name, _ in pairs(WEATHER_STATES) do
        if name ~= self.currentWeather then
            table.insert(weathers, name)
        end
    end
    
    local newWeather = weathers[math.random(#weathers)]
    self.currentWeather = newWeather
    self.weatherTimer = 0
    
    -- Check for hazard
    if math.random() < 0.3 then -- 30% chance for hazard every 3 waves
        self:startHazard()
    end
end

function Weather:startHazard()
    local hazards = {}
    for name, hazard in pairs(ENVIRONMENTAL_HAZARDS) do
        table.insert(hazards, hazard)
    end
    
    local hazard = hazards[math.random(#hazards)]
    self.activeHazard = hazard
    self.hazardTimer = 0
    self.hazardWarning = hazard.warning
    
    -- Show warning
    gameState:showNotification(hazard.name .. " incoming in " .. hazard.warning .. " seconds!")
end

function Weather:endHazard()
    if self.activeHazard then
        gameState:showNotification(self.activeHazard.name .. " has ended!")
        self.activeHazard = nil
        self.hazardTimer = 0
        self.hazardWarning = 0
    end
end

function Weather:draw()
    -- Draw weather effects
    if self.currentWeather == "rain" then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    elseif self.currentWeather == "foggy" then
        love.graphics.setColor(0.7, 0.7, 0.7, 0.2)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    elseif self.currentWeather == "storm" then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- Draw hazard warning
    if self.activeHazard and self.hazardWarning > 0 then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 40)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.activeHazard.name .. " incoming in " .. math.ceil(self.hazardWarning) .. " seconds!",
            0, 10, love.graphics.getWidth(), "center")
    end
end

return Weather 