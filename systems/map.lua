local sti = require 'libs.sti.sti'
local bump = require 'libs.bump.bump'
local jumper = require 'libs.jumper.jumper'
local Error = require 'utils.error'

local Map = {}
Map.__index = Map

-- Map presets
local MAP_PRESETS = {
    radiant = {
        sunlit_meadows = {
            name = "Sunlit Meadows",
            description = "Open fields with multiple paths",
            difficulty = 1,
            features = {
                multiple_paths = true,
                elevated_ground = false,
                teleporters = false,
                destructibles = false,
                dynamic_zones = false
            },
            paths = {
                {x = 0, y = 300, width = 100, height = 200},
                {x = 200, y = 300, width = 100, height = 200},
                {x = 400, y = 300, width = 100, height = 200}
            },
            tower_spots = {
                {x = 50, y = 100},
                {x = 150, y = 100},
                {x = 250, y = 100},
                {x = 350, y = 100},
                {x = 450, y = 100},
                {x = 50, y = 500},
                {x = 150, y = 500},
                {x = 250, y = 500},
                {x = 350, y = 500},
                {x = 450, y = 500}
            }
        },
        crystal_spires = {
            name = "Crystal Spires",
            description = "Elevated platforms with bridges",
            difficulty = 2,
            features = {
                multiple_paths = true,
                elevated_ground = true,
                teleporters = false,
                destructibles = false,
                dynamic_zones = false
            },
            platforms = {
                {x = 0, y = 200, width = 100, height = 20},
                {x = 200, y = 300, width = 100, height = 20},
                {x = 400, y = 200, width = 100, height = 20}
            },
            bridges = {
                {x = 100, y = 200, width = 100, height = 10},
                {x = 300, y = 300, width = 100, height = 10}
            },
            tower_spots = {
                {x = 50, y = 150},
                {x = 150, y = 250},
                {x = 250, y = 150},
                {x = 350, y = 250},
                {x = 450, y = 150}
            }
        },
        celestial_citadel = {
            name = "Celestial Citadel",
            description = "Circular, central defensive point",
            difficulty = 3,
            features = {
                multiple_paths = false,
                elevated_ground = true,
                teleporters = true,
                destructibles = false,
                dynamic_zones = true
            },
            center = {x = 300, y = 300, radius = 100},
            teleporters = {
                {x = 0, y = 300, target = {x = 600, y = 300}},
                {x = 600, y = 300, target = {x = 0, y = 300}}
            },
            tower_spots = {
                {x = 200, y = 200},
                {x = 400, y = 200},
                {x = 200, y = 400},
                {x = 400, y = 400}
            }
        }
    },
    shadow = {
        haunted_forest = {
            name = "Haunted Forest",
            description = "Winding paths with dense trees",
            difficulty = 1,
            features = {
                multiple_paths = true,
                elevated_ground = false,
                teleporters = false,
                destructibles = true,
                dynamic_zones = false
            },
            paths = {
                {x = 0, y = 300, width = 100, height = 200},
                {x = 200, y = 300, width = 100, height = 200},
                {x = 400, y = 300, width = 100, height = 200}
            },
            trees = {
                {x = 100, y = 100, health = 100},
                {x = 300, y = 100, health = 100},
                {x = 500, y = 100, health = 100}
            },
            tower_spots = {
                {x = 50, y = 100},
                {x = 150, y = 100},
                {x = 250, y = 100},
                {x = 350, y = 100},
                {x = 450, y = 100},
                {x = 50, y = 500},
                {x = 150, y = 500},
                {x = 250, y = 500},
                {x = 350, y = 500},
                {x = 450, y = 500}
            }
        },
        obsidian_caves = {
            name = "Obsidian Caves",
            description = "Narrow tunnels with limited tower spots",
            difficulty = 2,
            features = {
                multiple_paths = true,
                elevated_ground = false,
                teleporters = false,
                destructibles = false,
                dynamic_zones = true
            },
            tunnels = {
                {x = 0, y = 300, width = 50, height = 200},
                {x = 200, y = 300, width = 50, height = 200},
                {x = 400, y = 300, width = 50, height = 200}
            },
            tower_spots = {
                {x = 100, y = 200},
                {x = 300, y = 200},
                {x = 500, y = 200},
                {x = 100, y = 400},
                {x = 300, y = 400},
                {x = 500, y = 400}
            }
        },
        necropolis = {
            name = "Necropolis",
            description = "Maze-like with teleportation portals",
            difficulty = 3,
            features = {
                multiple_paths = true,
                elevated_ground = false,
                teleporters = true,
                destructibles = false,
                dynamic_zones = true
            },
            paths = {
                {x = 0, y = 300, width = 100, height = 200},
                {x = 200, y = 300, width = 100, height = 200},
                {x = 400, y = 300, width = 100, height = 200}
            },
            teleporters = {
                {x = 0, y = 300, target = {x = 600, y = 300}},
                {x = 600, y = 300, target = {x = 0, y = 300}},
                {x = 300, y = 0, target = {x = 300, y = 600}},
                {x = 300, y = 600, target = {x = 300, y = 0}}
            },
            tower_spots = {
                {x = 50, y = 100},
                {x = 150, y = 100},
                {x = 250, y = 100},
                {x = 350, y = 100},
                {x = 450, y = 100},
                {x = 50, y = 500},
                {x = 150, y = 500},
                {x = 250, y = 500},
                {x = 350, y = 500},
                {x = 450, y = 500}
            }
        }
    },
    twilight = {
        misty_borderlands = {
            name = "Misty Borderlands",
            description = "Shifting fog reveals/hides paths",
            difficulty = 1,
            features = {
                multiple_paths = true,
                elevated_ground = false,
                teleporters = false,
                destructibles = false,
                dynamic_zones = true
            },
            paths = {
                {x = 0, y = 300, width = 100, height = 200},
                {x = 200, y = 300, width = 100, height = 200},
                {x = 400, y = 300, width = 100, height = 200}
            },
            fog_zones = {
                {x = 0, y = 0, width = 300, height = 300},
                {x = 300, y = 300, width = 300, height = 300}
            },
            tower_spots = {
                {x = 50, y = 100},
                {x = 150, y = 100},
                {x = 250, y = 100},
                {x = 350, y = 100},
                {x = 450, y = 100},
                {x = 50, y = 500},
                {x = 150, y = 500},
                {x = 250, y = 500},
                {x = 350, y = 500},
                {x = 450, y = 500}
            }
        },
        ethereal_ruins = {
            name = "Ethereal Ruins",
            description = "Destructible environments change pathing",
            difficulty = 2,
            features = {
                multiple_paths = true,
                elevated_ground = false,
                teleporters = false,
                destructibles = true,
                dynamic_zones = true
            },
            paths = {
                {x = 0, y = 300, width = 100, height = 200},
                {x = 200, y = 300, width = 100, height = 200},
                {x = 400, y = 300, width = 100, height = 200}
            },
            destructibles = {
                {x = 100, y = 100, health = 100, type = "wall"},
                {x = 300, y = 100, health = 100, type = "wall"},
                {x = 500, y = 100, health = 100, type = "wall"}
            },
            tower_spots = {
                {x = 50, y = 100},
                {x = 150, y = 100},
                {x = 250, y = 100},
                {x = 350, y = 100},
                {x = 450, y = 100},
                {x = 50, y = 500},
                {x = 150, y = 500},
                {x = 250, y = 500},
                {x = 350, y = 500},
                {x = 450, y = 500}
            }
        },
        nexus_of_balance = {
            name = "Nexus of Balance",
            description = "Dynamic, alternates light/dark zones",
            difficulty = 3,
            features = {
                multiple_paths = true,
                elevated_ground = true,
                teleporters = true,
                destructibles = false,
                dynamic_zones = true
            },
            paths = {
                {x = 0, y = 300, width = 100, height = 200},
                {x = 200, y = 300, width = 100, height = 200},
                {x = 400, y = 300, width = 100, height = 200}
            },
            platforms = {
                {x = 0, y = 200, width = 100, height = 20},
                {x = 200, y = 300, width = 100, height = 20},
                {x = 400, y = 200, width = 100, height = 20}
            },
            light_zones = {
                {x = 0, y = 0, width = 300, height = 300},
                {x = 300, y = 300, width = 300, height = 300}
            },
            dark_zones = {
                {x = 300, y = 0, width = 300, height = 300},
                {x = 0, y = 300, width = 300, height = 300}
            },
            tower_spots = {
                {x = 50, y = 150},
                {x = 150, y = 250},
                {x = 250, y = 150},
                {x = 350, y = 250},
                {x = 450, y = 150}
            }
        }
    }
}

-- Create a new map instance
function Map.new(mapName)
    local self = setmetatable({}, Map)
    
    self.name = mapName
    self.map = nil
    self.world = bump.newWorld()
    self.grid = nil
    self.pathfinder = nil
    self.towerSpots = {}
    self.waypoints = {}
    self.spawnPoints = {}
    self.exitPoints = {}
    self.gridSize = 32  -- Default grid size
    
    -- Attempt to load the map
    self:load()
    
    return self
end

-- Load the map data from a Tiled file
function Map:load()
    local success, result = Error.pcall(function()
        -- Load the map with STI, but disable image loading to avoid crashes
        local mapPath = ""
        
        -- First try with maps/ prefix
        if love.filesystem.getInfo("maps/" .. self.name .. ".lua") then
            mapPath = "maps/" .. self.name .. ".lua"
        else
            -- Try without maps/ prefix
            mapPath = self.name .. ".lua"
        end
        
        -- Load map without attempting to load images (set last param to false)
        self.map = sti(mapPath, {"bump"})
        
        -- Initialize bump world
        self.map:bump_init(self.world)
        
        -- Get grid size from map properties if available
        if self.map.properties and self.map.properties.gridSize then
            self.gridSize = self.map.properties.gridSize
        end
        
        -- Load map layers and objects
        self:loadLayers()
        
        -- Initialize pathfinding grid
        self:initPathfinding()
    end)
    
    if not success then
        Error.handle(Error.TYPES.SYSTEM, "RESOURCE_MISSING", "Map: " .. self.name)
        return false
    end
    
    return true
end

-- Load layers and objects from the map
function Map:loadLayers()
    -- Process each layer in the map
    for _, layer in ipairs(self.map.layers) do
        if layer.type == "objectgroup" then
            self:processObjectLayer(layer)
        end
    end
end

-- Process an object layer from the map
function Map:processObjectLayer(layer)
    if layer.name == "TowerSpots" then
        -- Process tower placement spots
        for _, obj in ipairs(layer.objects) do
            table.insert(self.towerSpots, {
                x = obj.x,
                y = obj.y,
                width = obj.width,
                height = obj.height,
                properties = obj.properties or {}
            })
        end
    elseif layer.name == "Waypoints" then
        -- Process waypoints for enemy pathing
        for _, obj in ipairs(layer.objects) do
            table.insert(self.waypoints, {
                x = obj.x,
                y = obj.y,
                next = obj.properties and obj.properties.next
            })
        end
        
        -- Sort waypoints by their 'order' property if it exists
        table.sort(self.waypoints, function(a, b)
            return (a.properties and a.properties.order or 0) < 
                   (b.properties and b.properties.order or 0)
        end)
    elseif layer.name == "SpawnPoints" then
        -- Process enemy spawn points
        for _, obj in ipairs(layer.objects) do
            table.insert(self.spawnPoints, {
                x = obj.x,
                y = obj.y,
                type = obj.properties and obj.properties.type or "default"
            })
        end
    elseif layer.name == "ExitPoints" then
        -- Process exit points (where enemies escape)
        for _, obj in ipairs(layer.objects) do
            table.insert(self.exitPoints, {
                x = obj.x,
                y = obj.y
            })
        end
    elseif layer.name == "Collisions" then
        -- Process collision objects
        for _, obj in ipairs(layer.objects) do
            self.world:add(obj, obj.x, obj.y, obj.width, obj.height)
        end
    end
end

-- Initialize pathfinding grid
function Map:initPathfinding()
    -- Create a grid for the pathfinder
    local mapWidth = math.ceil(self.map.width * self.map.tilewidth / self.gridSize)
    local mapHeight = math.ceil(self.map.height * self.map.tileheight / self.gridSize)
    
    self.grid = {}
    for y = 1, mapHeight do
        self.grid[y] = {}
        for x = 1, mapWidth do
            -- Default to walkable
            self.grid[y][x] = 0
        end
    end
    
    -- Mark non-walkable areas from collision layer
    for _, layer in ipairs(self.map.layers) do
        if layer.name == "Collisions" then
            for _, obj in ipairs(layer.objects) do
                local startX = math.floor(obj.x / self.gridSize) + 1
                local startY = math.floor(obj.y / self.gridSize) + 1
                local endX = math.ceil((obj.x + obj.width) / self.gridSize)
                local endY = math.ceil((obj.y + obj.height) / self.gridSize)
                
                for y = startY, endY do
                    for x = startX, endX do
                        if self.grid[y] and self.grid[y][x] then
                            self.grid[y][x] = 1  -- Mark as non-walkable
                        end
                    end
                end
            end
        end
    end
    
    -- Initialize Jumper pathfinder
    local Grid = jumper.grid(self.grid)
    self.pathfinder = jumper.pathFinder(Grid, "ASTAR", true)
    self.pathfinder:setMode("ORTHOGONAL")
end

-- Update the map
function Map:update(dt)
    if self.map then
        self.map:update(dt)
    end
end

-- Draw the map
function Map:draw()
    if self.map then
        -- Draw map layers
        self.map:draw()
        
        -- Draw debug information if in debug mode
        if gameState.settings.debug then
            self:drawDebug()
        end
    end
end

-- Draw debug visualization
function Map:drawDebug()
    -- Draw tower spots
    love.graphics.setColor(0, 1, 0, 0.3)
    for _, spot in ipairs(self.towerSpots) do
        love.graphics.rectangle("fill", spot.x, spot.y, spot.width, spot.height)
    end
    
    -- Draw waypoints
    love.graphics.setColor(1, 1, 0, 0.8)
    for i, point in ipairs(self.waypoints) do
        love.graphics.circle("fill", point.x, point.y, 5)
        love.graphics.print(i, point.x + 5, point.y + 5)
    end
    
    -- Draw spawn points
    love.graphics.setColor(0, 0, 1, 0.8)
    for _, point in ipairs(self.spawnPoints) do
        love.graphics.circle("fill", point.x, point.y, 7)
    end
    
    -- Draw exit points
    love.graphics.setColor(1, 0, 0, 0.8)
    for _, point in ipairs(self.exitPoints) do
        love.graphics.circle("fill", point.x, point.y, 7)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Find a path between two points
function Map:findPath(startX, startY, endX, endY)
    if not self.pathfinder then
        return nil
    end
    
    -- Convert coordinates to grid positions
    local startGridX = math.floor(startX / self.gridSize) + 1
    local startGridY = math.floor(startY / self.gridSize) + 1
    local endGridX = math.floor(endX / self.gridSize) + 1
    local endGridY = math.floor(endY / self.gridSize) + 1
    
    -- Find path
    local path = self.pathfinder:getPath(startGridX, startGridY, endGridX, endGridY)
    
    -- Convert path back to world coordinates
    if path then
        local worldPath = {}
        for node, count in path:nodes() do
            table.insert(worldPath, {
                x = (node:getX() - 0.5) * self.gridSize,
                y = (node:getY() - 0.5) * self.gridSize
            })
        end
        return worldPath
    end
    
    return nil
end

-- Check if a tower can be placed at a position
function Map:canPlaceTower(x, y, width, height)
    -- Check if position is on a tower spot
    for _, spot in ipairs(self.towerSpots) do
        if x >= spot.x and x + width <= spot.x + spot.width and
           y >= spot.y and y + height <= spot.y + spot.height then
            return true
        end
    end
    
    return false
end

-- Update the pathfinding grid when a tower is placed or removed
function Map:updatePathing()
    -- Re-initialize the pathfinding grid with the current state
    self:initPathfinding()
    
    -- Add towers as obstacles
    for _, tower in ipairs(gameState.towers) do
        local gridX = math.floor(tower.x / self.gridSize) + 1
        local gridY = math.floor(tower.y / self.gridSize) + 1
        local width = math.ceil(tower.width / self.gridSize)
        local height = math.ceil(tower.height / self.gridSize)
        
        for y = gridY, gridY + height - 1 do
            for x = gridX, gridX + width - 1 do
                if self.grid[y] and self.grid[y][x] then
                    self.grid[y][x] = 1  -- Mark as obstacle
                end
            end
        end
    end
    
    -- Reinitialize the pathfinder with the updated grid
    local Grid = jumper.grid(self.grid)
    self.pathfinder = jumper.pathFinder(Grid, "ASTAR", true)
    self.pathfinder:setMode("ORTHOGONAL")
end

-- Get the spawn point for a specific type
function Map:getSpawnPoint(type)
    type = type or "default"
    
    for _, point in ipairs(self.spawnPoints) do
        if point.type == type then
            return point.x, point.y
        end
    end
    
    -- Return the first spawn point if no matching type
    if #self.spawnPoints > 0 then
        return self.spawnPoints[1].x, self.spawnPoints[1].y
    end
    
    -- Default position if no spawn points
    return 0, 0
end

-- Get the first exit point
function Map:getExitPoint()
    if #self.exitPoints > 0 then
        return self.exitPoints[1].x, self.exitPoints[1].y
    end
    
    -- Default position if no exit points
    return self.map.width * self.map.tilewidth, self.map.height * self.map.tileheight
end

-- Get an array of waypoints for enemy pathing
function Map:getWaypoints()
    return self.waypoints
end

-- Get tower spots
function Map:getTowerSpots()
    return self.towerSpots
end

-- Convert world coordinates to grid coordinates
function Map:worldToGrid(x, y)
    return math.floor(x / self.gridSize) + 1, math.floor(y / self.gridSize) + 1
end

-- Convert grid coordinates to world coordinates
function Map:gridToWorld(gridX, gridY)
    return (gridX - 0.5) * self.gridSize, (gridY - 0.5) * self.gridSize
end

return Map 