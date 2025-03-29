local Level = {}
Level.__index = Level

-- Area definitions
local AREAS = {
    radiant = {
        name = "Radiant Realm",
        description = "Sunlit lands of divine power",
        color = {1, 1, 0.5},
        maps = {
            sunlitMeadows = {
                name = "Sunlit Meadows",
                description = "Open fields with multiple paths",
                difficulty = 1,
                features = {
                    "multiple_paths",
                    "open_terrain",
                    "high_ground"
                }
            },
            crystalSpires = {
                name = "Crystal Spires",
                description = "Elevated platforms and bridges",
                difficulty = 2,
                features = {
                    "elevated_platforms",
                    "bridges",
                    "crystal_terrain"
                }
            },
            celestialCitadel = {
                name = "Celestial Citadel",
                description = "Circular fortress with central defense point",
                difficulty = 3,
                features = {
                    "circular_layout",
                    "central_defense",
                    "holy_ground"
                }
            }
        }
    },
    shadow = {
        name = "Shadow Lands",
        description = "Dark realm of forbidden magic",
        color = {0.2, 0.2, 0.3},
        maps = {
            hauntedForest = {
                name = "Haunted Forest",
                description = "Winding paths through dense trees",
                difficulty = 1,
                features = {
                    "winding_paths",
                    "dense_cover",
                    "dark_terrain"
                }
            },
            obsidianCaves = {
                name = "Obsidian Caves",
                description = "Narrow tunnels with limited tower spots",
                difficulty = 2,
                features = {
                    "narrow_tunnels",
                    "limited_spots",
                    "cave_terrain"
                }
            },
            necropolis = {
                name = "Necropolis",
                description = "Maze-like city with teleportation portals",
                difficulty = 3,
                features = {
                    "maze_layout",
                    "teleporters",
                    "undead_terrain"
                }
            }
        }
    },
    twilight = {
        name = "Twilight Frontier",
        description = "Mystical border between light and dark",
        color = {0.5, 0.3, 0.8},
        maps = {
            mistyBorderlands = {
                name = "Misty Borderlands",
                description = "Shifting fog reveals and hides paths",
                difficulty = 1,
                features = {
                    "shifting_fog",
                    "hidden_paths",
                    "border_terrain"
                }
            },
            etherealRuins = {
                name = "Ethereal Ruins",
                description = "Destructible environments with changing paths",
                difficulty = 2,
                features = {
                    "destructible",
                    "changing_paths",
                    "ruin_terrain"
                }
            },
            nexusOfBalance = {
                name = "Nexus of Balance",
                description = "Dynamic map alternating light and dark zones",
                difficulty = 3,
                features = {
                    "dynamic_zones",
                    "light_dark_cycle",
                    "nexus_terrain"
                }
            }
        }
    }
}

-- Secret challenges
local SECRET_CHALLENGES = {
    noLivesLost = {
        name = "Perfect Defense",
        description = "Complete the level without losing any lives",
        reward = {
            type = "cosmetic",
            name = "Golden Tower Skin"
        }
    },
    speedRun = {
        name = "Lightning Fast",
        description = "Kill the Mini-Boss in 20 seconds",
        reward = {
            type = "powerup",
            name = "Damage Boost",
            effect = {
                damage = 1.05 -- +5% global damage
            }
        }
    },
    resourceMaster = {
        name = "Resource Master",
        description = "Complete the level with at least 500 resources remaining",
        reward = {
            type = "cosmetic",
            name = "Resource Aura"
        }
    }
}

function Level.new(areaId, mapId)
    local self = setmetatable({}, Level)
    
    self.areaId = areaId
    self.mapId = mapId
    self.area = AREAS[areaId]
    self.map = self.area.maps[mapId]
    self.difficulty = self.map.difficulty
    self.features = self.map.features
    self.completed = false
    self.secretChallenges = {}
    self.rewards = {}
    
    -- Load map using STI
    self.mapData = sti.new("maps/" .. areaId .. "/" .. mapId .. ".lua")
    
    -- Initialize map-specific features
    self:initializeFeatures()
    
    return self
end

function Level:initializeFeatures()
    -- Initialize map-specific features
    for _, feature in ipairs(self.features) do
        if feature == "multiple_paths" then
            self:setupMultiplePaths()
        elseif feature == "elevated_platforms" then
            self:setupElevatedPlatforms()
        elseif feature == "teleporters" then
            self:setupTeleporters()
        elseif feature == "shifting_fog" then
            self:setupShiftingFog()
        elseif feature == "destructible" then
            self:setupDestructible()
        elseif feature == "dynamic_zones" then
            self:setupDynamicZones()
        end
    end
end

function Level:setupMultiplePaths()
    -- Find all possible paths in the map
    self.paths = {}
    local pathLayer = self.mapData.layers["paths"]
    if pathLayer then
        for _, object in ipairs(pathLayer.objects) do
            table.insert(self.paths, {
                points = object.polygon,
                type = object.properties.type
            })
        end
    end
end

function Level:setupElevatedPlatforms()
    -- Set up elevated platforms and their effects
    self.platforms = {}
    local platformLayer = self.mapData.layers["platforms"]
    if platformLayer then
        for _, object in ipairs(platformLayer.objects) do
            table.insert(self.platforms, {
                x = object.x,
                y = object.y,
                width = object.width,
                height = object.height,
                height = object.properties.height
            })
        end
    end
end

function Level:setupTeleporters()
    -- Set up teleportation portals
    self.teleporters = {}
    local teleporterLayer = self.mapData.layers["teleporters"]
    if teleporterLayer then
        for _, object in ipairs(teleporterLayer.objects) do
            table.insert(self.teleporters, {
                x = object.x,
                y = object.y,
                target = object.properties.target,
                cooldown = 0
            })
        end
    end
end

function Level:setupShiftingFog()
    -- Initialize fog system
    self.fog = {
        opacity = 0.5,
        shiftTimer = 0,
        shiftInterval = 5,
        currentZone = 1
    }
end

function Level:setupDestructible()
    -- Set up destructible objects
    self.destructibles = {}
    local destructibleLayer = self.mapData.layers["destructibles"]
    if destructibleLayer then
        for _, object in ipairs(destructibleLayer.objects) do
            table.insert(self.destructibles, {
                x = object.x,
                y = object.y,
                width = object.width,
                height = object.height,
                health = object.properties.health,
                destroyed = false
            })
        end
    end
end

function Level:setupDynamicZones()
    -- Initialize light/dark zone system
    self.zones = {
        light = {},
        dark = {}
    }
    local zoneLayer = self.mapData.layers["zones"]
    if zoneLayer then
        for _, object in ipairs(zoneLayer.objects) do
            table.insert(self.zones[object.properties.type], {
                x = object.x,
                y = object.y,
                width = object.width,
                height = object.height
            })
        end
    end
end

function Level:update(dt)
    -- Update map-specific features
    if self.features["shifting_fog"] then
        self:updateFog(dt)
    end
    
    if self.features["destructible"] then
        self:updateDestructibles(dt)
    end
    
    if self.features["dynamic_zones"] then
        self:updateZones(dt)
    end
    
    -- Update teleporters
    for _, teleporter in ipairs(self.teleporters) do
        if teleporter.cooldown > 0 then
            teleporter.cooldown = teleporter.cooldown - dt
        end
    end
end

function Level:updateFog(dt)
    self.fog.shiftTimer = self.fog.shiftTimer + dt
    if self.fog.shiftTimer >= self.fog.shiftInterval then
        self.fog.shiftTimer = 0
        self.fog.currentZone = self.fog.currentZone % #self.zones + 1
    end
end

function Level:updateDestructibles(dt)
    for _, destructible in ipairs(self.destructibles) do
        if not destructible.destroyed then
            -- Check for collisions with projectiles
            for _, projectile in ipairs(gameState.projectiles) do
                if self:checkCollision(projectile, destructible) then
                    destructible.health = destructible.health - projectile.damage
                    if destructible.health <= 0 then
                        destructible.destroyed = true
                        self:onDestructibleDestroyed(destructible)
                    end
                end
            end
        end
    end
end

function Level:updateZones(dt)
    -- Update light/dark zone effects
    for _, tower in ipairs(gameState.towers) do
        local inLight = self:isInZone(tower, "light")
        local inDark = self:isInZone(tower, "dark")
        
        if inLight and tower.faction == "radiant" then
            tower.stats.damage = tower.stats.damage * 1.1
        elseif inDark and tower.faction == "shadow" then
            tower.stats.damage = tower.stats.damage * 1.1
        end
    end
end

function Level:checkCollision(obj1, obj2)
    return obj1.x < obj2.x + obj2.width and
           obj1.x + obj1.width > obj2.x and
           obj1.y < obj2.y + obj2.height and
           obj1.y + obj1.height > obj2.y
end

function Level:isInZone(obj, zoneType)
    for _, zone in ipairs(self.zones[zoneType]) do
        if obj.x >= zone.x and obj.x <= zone.x + zone.width and
           obj.y >= zone.y and obj.y <= zone.y + zone.height then
            return true
        end
    end
    return false
end

function Level:onDestructibleDestroyed(destructible)
    -- Update pathing when destructible is destroyed
    self:updatePaths()
end

function Level:updatePaths()
    -- Recalculate paths based on destroyed objects
    self:setupMultiplePaths()
end

function Level:checkSecretChallenges()
    -- Check for secret challenge completion
    if not self.secretChallenges.noLivesLost and gameState.lives == gameState.maxLives then
        self:completeSecretChallenge("noLivesLost")
    end
    
    if not self.secretChallenges.speedRun and gameState.miniBossKillTime <= 20 then
        self:completeSecretChallenge("speedRun")
    end
    
    if not self.secretChallenges.resourceMaster and gameState.resources >= 500 then
        self:completeSecretChallenge("resourceMaster")
    end
end

function Level:completeSecretChallenge(challengeId)
    self.secretChallenges[challengeId] = true
    local challenge = SECRET_CHALLENGES[challengeId]
    
    -- Apply reward
    if challenge.reward.type == "cosmetic" then
        table.insert(gameState.cosmetics, challenge.reward.name)
    elseif challenge.reward.type == "powerup" then
        gameState:applyPowerup(challenge.reward.effect)
    end
    
    -- Show notification
    gameState:showNotification("Secret Challenge Completed: " .. challenge.name)
end

function Level:draw()
    -- Draw map layers
    self.mapData:draw()
    
    -- Draw map-specific features
    if self.features["shifting_fog"] then
        self:drawFog()
    end
    
    if self.features["destructible"] then
        self:drawDestructibles()
    end
    
    if self.features["dynamic_zones"] then
        self:drawZones()
    end
    
    -- Draw teleporters
    for _, teleporter in ipairs(self.teleporters) do
        love.graphics.setColor(0.5, 0, 0.5, 0.5)
        love.graphics.circle("fill", teleporter.x, teleporter.y, 20)
    end
end

function Level:drawFog()
    love.graphics.setColor(0.5, 0.5, 0.5, self.fog.opacity)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function Level:drawDestructibles()
    for _, destructible in ipairs(self.destructibles) do
        if not destructible.destroyed then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.rectangle("fill", destructible.x, destructible.y, destructible.width, destructible.height)
        end
    end
end

function Level:drawZones()
    for zoneType, zones in pairs(self.zones) do
        for _, zone in ipairs(zones) do
            if zoneType == "light" then
                love.graphics.setColor(1, 1, 0, 0.1)
            else
                love.graphics.setColor(0, 0, 0, 0.1)
            end
            love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height)
        end
    end
end

return Level 