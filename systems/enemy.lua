-- Load required libraries
local Timer = require("libs.hump.timer")
local Utils = require("utils")
local Error = require("utils.error")
local Animations = require("systems.animations")

-- Use local pathfinding instead of Jumper library which may be missing
local Pathfinder = {}

function Pathfinder.new(grid, walkable)
    local pf = {}
    pf.grid = grid
    pf.walkable = walkable or 0
    
    -- Breadth-first search pathfinding
    function pf:getPath(startX, startY, endX, endY)
        -- Create a queue for BFS
        local queue = {{x = startX, y = startY}}
        local visited = {}
        local parent = {}
        local key = startX .. "," .. startY
        visited[key] = true
        
        while #queue > 0 do
            local current = table.remove(queue, 1)
            local currKey = current.x .. "," .. current.y
            
            -- If we reached the end, reconstruct the path
            if current.x == endX and current.y == endY then
                local path = {}
                local curr = currKey
                while curr do
                    local x, y = curr:match("(%d+),(%d+)")
                    table.insert(path, 1, {x = tonumber(x), y = tonumber(y)})
                    curr = parent[curr]
                end
                return path
            end
            
            -- Check neighbors (up, right, down, left)
            local directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
            for _, dir in ipairs(directions) do
                local nx, ny = current.x + dir[1], current.y + dir[2]
                local nkey = nx .. "," .. ny
                
                -- Check if neighbor is valid and walkable
                if nx >= 1 and ny >= 1 and nx <= #self.grid[1] and ny <= #self.grid and 
                   self.grid[ny][nx] == self.walkable and not visited[nkey] then
                    table.insert(queue, {x = nx, y = ny})
                    visited[nkey] = true
                    parent[nkey] = currKey
                end
            end
        end
        
        -- No path found
        return {}
    end
    
    return pf
end

-- Enemy system
local Enemy = {
    initialized = false,
    types = {},
    sprites = {},
    pathfinder = nil
}

-- Walk sheet playback (sheet layout: art/README.md and tools/artcut)
Enemy.FACING_ROW = { down = 1, right = 2, left = 3, up = 4 }
Enemy.WALK_CYCLE = { 1, 2, 3, 2 }      -- left foot, standing, right foot, standing
Enemy.FRAME_TIME = 0.16                 -- seconds per frame at ANIM_BASE_SPEED
Enemy.ANIM_BASE_SPEED = 40              -- px/s the frame time was tuned for
Enemy.FOOT_OFFSET = 10                  -- feet sit this far below the cell center
Enemy.HOVER_HEIGHT = 22                 -- flyers' body center above their ground point
-- On-map figure height in pixels, per enemy type (scale is data, per asset)
Enemy.DRAW_HEIGHT = { default = 40, zombie = 40, skeleton = 40, orc = 46, necromancer = 44, dragon = 56 }

-- Initialize enemy types and sprites
function Enemy.init()
    if Enemy.initialized then return end
    
    -- Define enemy types
    Enemy.types = {
        zombie = {
            id = "zombie",
            name = "Zombie",
            health = 100,
            speed = 40,
            damage = 1,
            value = 10,
            spriteSheet = "sprites/enemies/zombie.png",
            animations = {
                walk = {
                    frames = {1, 2, 3, 4},
                    speed = 0.2
                },
                attack = {
                    frames = {5, 6, 7, 8},
                    speed = 0.15
                },
                die = {
                    frames = {9, 10, 11, 12},
                    speed = 0.2
                }
            }
        },
        skeleton = {
            id = "skeleton",
            name = "Skeleton",
            health = 80,
            speed = 60,
            damage = 1,
            value = 15,
            spriteSheet = "sprites/enemies/skeleton.png",
            animations = {
                walk = {
                    frames = {1, 2, 3, 4},
                    speed = 0.15
                },
                attack = {
                    frames = {5, 6, 7, 8},
                    speed = 0.1
                },
                die = {
                    frames = {9, 10, 11, 12},
                    speed = 0.18
                }
            }
        },
        orc = {
            id = "orc",
            name = "Orc",
            health = 150,
            speed = 30,
            damage = 2,
            value = 20,
            spriteSheet = "sprites/enemies/orc.png",
            animations = {
                walk = {
                    frames = {1, 2, 3, 4},
                    speed = 0.25
                },
                attack = {
                    frames = {5, 6, 7, 8},
                    speed = 0.2
                },
                die = {
                    frames = {9, 10, 11, 12},
                    speed = 0.22
                }
            }
        },
        necromancer = {
            id = "necromancer",
            name = "Necromancer",
            health = 200,
            speed = 25,
            damage = 3,
            value = 30,
            spriteSheet = "sprites/enemies/necromancer.png",
            animations = {
                walk = {
                    frames = {1, 2, 3, 4},
                    speed = 0.3
                },
                attack = {
                    frames = {5, 6, 7, 8},
                    speed = 0.25
                },
                die = {
                    frames = {9, 10, 11, 12},
                    speed = 0.3
                }
            }
        },
        dragon = {
            id = "dragon",
            name = "Dragon",
            health = 500,
            speed = 20,
            damage = 5,
            value = 100,
            spriteSheet = "sprites/enemies/dragon.png",
            animations = {
                walk = {
                    frames = {1, 2, 3, 4},
                    speed = 0.4
                },
                attack = {
                    frames = {5, 6, 7, 8},
                    speed = 0.3
                },
                die = {
                    frames = {9, 10, 11, 12},
                    speed = 0.35
                }
            }
        }
    }
    
    -- Create default enemy sprites
    for id, enemy in pairs(Enemy.types) do
        Enemy.sprites[id] = Enemy.createDefaultSprite(enemy)
    end

    -- Painted walk sheets cut by tools/artcut: a PNG plus a .lua file with
    -- the frame layout next to it. Types without one keep the default.
    Enemy.sheets = {}
    for id, enemy in pairs(Enemy.types) do
        local png = enemy.spriteSheet
        local metaPath = png and (png:gsub("%.png$", ".lua"))
        if png and love.filesystem.getInfo(png) and love.filesystem.getInfo(metaPath) then
            local okMeta, meta = pcall(function() return love.filesystem.load(metaPath)() end)
            local okImg, img = pcall(love.graphics.newImage, png, { mipmaps = true })
            if okMeta and okImg and type(meta) == "table" then
                img:setFilter("linear", "linear")
                img:setMipmapFilter("linear")
                local iw, ih = img:getDimensions()
                local quads = {}
                for r = 1, meta.rows do
                    quads[r] = {}
                    for c = 1, meta.cols do
                        quads[r][c] = love.graphics.newQuad((c - 1) * meta.frameW, (r - 1) * meta.frameH,
                            meta.frameW, meta.frameH, iw, ih)
                    end
                end
                Enemy.sheets[id] = { image = img, quads = quads, meta = meta }
            else
                print("WARNING: could not load walk sheet for " .. id)
            end
        end
    end

    Enemy.initialized = true
end

-- Create a default sprite for an enemy
function Enemy.createDefaultSprite(enemy)
    -- Create a new canvas for the enemy sprite
    local size = 32
    local canvas = love.graphics.newCanvas(size, size)
    
    -- Set color based on enemy type
    local color = {0.5, 0.5, 0.5} -- Default gray
    if enemy.id == "zombie" then
        color = {0.2, 0.7, 0.2} -- Green for zombie
    elseif enemy.id == "skeleton" then
        color = {0.8, 0.8, 0.8} -- White for skeleton
    elseif enemy.id == "orc" then
        color = {0.7, 0.2, 0.2} -- Red for orc
    elseif enemy.id == "necromancer" then
        color = {0.5, 0.1, 0.5} -- Purple for necromancer
    elseif enemy.id == "dragon" then
        color = {0.8, 0.4, 0.1} -- Orange for dragon
    end
    
    -- Draw to canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Body
    love.graphics.setColor(color)
    love.graphics.circle("fill", size/2, size/2, size/3)
    
    -- Eyes
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", size/2 - 5, size/2 - 2, 2)
    love.graphics.circle("fill", size/2 + 5, size/2 - 2, 2)
    
    -- Outline
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", size/2, size/2, size/3)
    
    -- Reset canvas
    love.graphics.setCanvas()
    
    return canvas
end

-- Create enemy instance
function Enemy.create(type, path, gridSize)
    -- Initialize enemy system if not done already
    if not Enemy.initialized then
        Enemy.init()
    end
    
    -- Find enemy template
    local template = Enemy.types[type]
    if not template then
        Error.show("Enemy type '" .. type .. "' not found")
        return nil
    end

    if not path or #path == 0 then
        Error.show("No path found for enemy '" .. type .. "'")
        return nil
    end

    -- Positions are pixel centers. Grid cell (gx, gy) is 1-based and spans
    -- (gx-1)*gridSize .. gx*gridSize, so its center is (gx-0.5)*gridSize.
    local function cellCenter(cell)
        return (cell.x - 0.5) * gridSize, (cell.y - 0.5) * gridSize
    end
    local startX, startY = cellCenter(path[1])

    -- Create enemy instance
    local enemy = {
        id = Utils.generateID("enemy"),
        type = type,
        name = template.name,
        x = startX,
        y = startY,
        width = 32,
        height = 32,
        radius = 12, -- hit radius used by projectiles
        health = template.health,
        maxHealth = template.health,
        speed = template.speed,
        damage = template.damage,
        value = template.value,
        path = path,
        currentPathIndex = 1,
        targetX = startX,
        targetY = startY,
        gridX = path[1].x,
        gridY = path[1].y,
        gridSize = gridSize,
        state = "walking", -- walking, attacking, dead
        dead = false,       -- read by towers/projectiles
        reachedEnd = false, -- read by towers/projectiles
        direction = "right", -- left, right, up, down
        effects = {}, -- slowed, poisoned, etc.
        timer = Timer.new(), -- per-enemy timer instance (never the HUMP default)
        timers = {}          -- handles into self.timer
    }
    
    -- Create animations
    enemy.animations = {}
    enemy.currentAnimation = "walk"
    
    -- Functions
    
    -- Update enemy logic
    enemy.update = function(self, dt)
        -- Timers must keep running while dead: the death timer sets `removed`
        self.timer:update(dt)

        -- Skip the rest if dead (the death fade reads deadTime)
        if self.state == "dead" then
            self.deadTime = (self.deadTime or 0) + dt
            return
        end

        -- Apply effects
        self:applyEffects(dt)
        
        -- Update current animation
        self:updateAnimation(dt)
        
        -- Movement logic
        if self.state == "walking" then
            self:move(dt)
        end
    end
    
    -- Apply status effects
    enemy.applyEffects = function(self, dt)
        local currentSpeed = self.speed
        
        -- Apply slow effect
        if self.effects.slowed then
            currentSpeed = currentSpeed * (1 - self.effects.slowed.amount)
        end
        
        -- Apply damage over time
        if self.effects.dot then
            self.effects.dot.tick = self.effects.dot.tick - dt
            if self.effects.dot.tick <= 0 then
                self:takeDamage(self.effects.dot.damage)
                -- takeDamage may have killed us, which clears effects
                if self.effects.dot then
                    self.effects.dot.tick = self.effects.dot.interval
                end
            end
        end
        
        -- Update current speed
        self.currentSpeed = currentSpeed
    end
    
    -- Move enemy along path
    enemy.move = function(self, dt)
        local speed = self.currentSpeed or self.speed
        local targetX = (self.path[self.currentPathIndex].x - 0.5) * self.gridSize
        local targetY = (self.path[self.currentPathIndex].y - 0.5) * self.gridSize
        
        -- Calculate direction to target
        local dx = targetX - self.x
        local dy = targetY - self.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        -- Update direction for animation
        if math.abs(dx) > math.abs(dy) then
            if dx > 0 then self.direction = "right" else self.direction = "left" end
        else
            if dy > 0 then self.direction = "down" else self.direction = "up" end
        end
        
        -- Move if not at target
        if distance > 2 then
            local moveX = dx / distance * speed * dt
            local moveY = dy / distance * speed * dt
            
            -- Check if we would overshoot
            if math.abs(moveX) > math.abs(dx) then moveX = dx end
            if math.abs(moveY) > math.abs(dy) then moveY = dy end
            
            self.x = self.x + moveX
            self.y = self.y + moveY
        else
            -- Reached waypoint, go to next one
            self.x = targetX
            self.y = targetY
            self.gridX = self.path[self.currentPathIndex].x
            self.gridY = self.path[self.currentPathIndex].y
            
            if self.currentPathIndex < #self.path then
                self.currentPathIndex = self.currentPathIndex + 1
            else
                -- Reached end of path
                self.state = "attacking"
                self.reachedEnd = true
                self.currentAnimation = "attack"
            end
        end
    end
    
    -- Update animation
    enemy.updateAnimation = function(self, dt)
        -- Walk cycle clock. Steps speed up and slow down with movement
        -- speed, so a slowed enemy also walks slower.
        local speed = self.currentSpeed or self.speed
        self.animTime = (self.animTime or 0) + dt * speed / Enemy.ANIM_BASE_SPEED
        if self.animation then
            self.animation:update(dt)
        end
    end
    
    -- Take damage
    enemy.takeDamage = function(self, amount)
        if self.state == "dead" then return end
        
        self.health = self.health - amount
        
        -- Create floating damage text
        -- This would be implemented in the game state
        
        if self.health <= 0 then
            self:die()
        end
    end
    
    -- Die
    enemy.die = function(self)
        self.state = "dead"
        self.dead = true
        self.currentAnimation = "die"
        self.effects = {}

        -- Clear all timers (slow/dot expiry no longer matters)
        self.timer:clear()
        self.timers = {}

        -- Remove from the game after the death animation
        self.timers.death = self.timer:after(1, function()
            self.removed = true
        end)
    end
    
    -- Apply slow effect
    enemy.applySlowEffect = function(self, amount, duration)
        self.effects.slowed = {
            amount = amount,
            duration = duration
        }
        
        -- Clear existing slow timer
        if self.timers.slowTimer then
            self.timer:cancel(self.timers.slowTimer)
        end

        -- Set timer to remove slow effect
        self.timers.slowTimer = self.timer:after(duration, function()
            self.effects.slowed = nil
        end)
    end
    
    -- Apply damage over time effect
    enemy.applyDotEffect = function(self, damage, duration, interval)
        self.effects.dot = {
            damage = damage,
            duration = duration,
            interval = interval or 1,
            tick = interval or 1
        }
        
        -- Clear existing dot timer
        if self.timers.dotTimer then
            self.timer:cancel(self.timers.dotTimer)
        end

        -- Set timer to remove dot effect
        self.timers.dotTimer = self.timer:after(duration, function()
            self.effects.dot = nil
        end)
    end

    -- Names used by systems/tower.lua projectiles
    enemy.applySlow = enemy.applySlowEffect
    enemy.applyDot = enemy.applyDotEffect
    
    -- Draw enemy
    enemy.draw = function(self)
        -- Skip if flagged for removal
        if self.removed then return end

        -- self.x/self.y are the center; drawing below works from the top-left
        local left, top = self.x - self.width/2, self.y - self.height/2
        local barWidth = self.width - 4
        local barX, barY = left + 2, top - 8

        local sheet = Enemy.sheets and Enemy.sheets[self.type]
        if sheet then
            -- Painted walk sheet: feet stand a little below the cell center
            local meta = sheet.meta
            local h = Enemy.DRAW_HEIGHT[self.type] or Enemy.DRAW_HEIGHT.default
            local s = h / meta.figureH
            local groundY = self.y + Enemy.FOOT_OFFSET
            local flying = meta.anchor == "mass"
            -- Walkers: the anchor is the feet, on the ground. Flyers: the
            -- anchor is the body center, held above the ground.
            local footX = self.x
            local footY = flying and (groundY - Enemy.HOVER_HEIGHT) or groundY
            local alpha = 1
            if self.dead then alpha = math.max(0, 1 - (self.deadTime or 0)) end

            -- Shadow drawn in code on the ground, falling down-right like the
            -- towers'. A flyer's shadow is smaller and fainter.
            love.graphics.setColor(0, 0, 0, (flying and 0.18 or 0.3) * alpha)
            love.graphics.ellipse("fill", footX + 2, groundY, h * (flying and 0.22 or 0.28),
                h * (flying and 0.07 or 0.09))

            local row = Enemy.FACING_ROW[self.direction] or 1
            local col = 2 -- standing frame when dead
            if not self.dead then
                local step = math.floor((self.animTime or 0) / Enemy.FRAME_TIME) % #Enemy.WALK_CYCLE
                col = Enemy.WALK_CYCLE[step + 1]
            end
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(sheet.image, sheet.quads[row][col], footX, footY, 0, s, s,
                meta.footX, meta.footY)

            -- Health bar just above the highest point any frame reaches
            local topY = meta.topY or 0
            barX, barY = self.x - barWidth / 2, footY - (meta.footY - topY) * s - 6
            if self.dead then
                love.graphics.setColor(1, 1, 1, 1)
                return
            end
        else
            -- Draw shadow
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.ellipse("fill", left + self.width/2, top + self.height - 5, self.width/2 - 2, 6)

            -- Draw enemy
            love.graphics.setColor(1, 1, 1, 1)

            -- Use sprite if available, otherwise use default
            local sprite = Enemy.sprites[self.type]
            if sprite then
                love.graphics.draw(sprite, left, top)
            else
                -- Fallback: draw a colored circle
                love.graphics.setColor(1, 0, 0)
                love.graphics.circle("fill", left + self.width/2, top + self.height/2, self.width/3)
                love.graphics.setColor(0, 0, 0)
                love.graphics.circle("line", left + self.width/2, top + self.height/2, self.width/3)
            end
        end

        -- Draw health bar
        local healthPercentage = math.max(0, self.health / self.maxHealth)
        local barHeight = 4

        -- Background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

        -- Health
        love.graphics.setColor(1 - healthPercentage, healthPercentage, 0, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthPercentage, barHeight)

        -- Border
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight)

        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)

        -- Status markers above the health bar
        local effectY = barY - 6
        if self.effects.slowed then
            love.graphics.setColor(0, 0.7, 1, 0.8)
            love.graphics.circle("fill", barX + barWidth - 4, effectY, 3)
            effectY = effectY - 6
        end
        if self.effects.dot then
            love.graphics.setColor(0.7, 0.2, 0, 0.8)
            love.graphics.circle("fill", barX + barWidth - 4, effectY, 3)
        end

        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    return enemy
end

-- Set up pathfinder for the grid map
function Enemy.setPathfinder(grid, walkable)
    Enemy.pathfinder = Pathfinder.new(grid, walkable)
end

-- Find path from start to end
function Enemy.findPath(startX, startY, endX, endY)
    if not Enemy.pathfinder then
        Error.show("Pathfinder not initialized")
        return {}
    end
    
    return Enemy.pathfinder:getPath(startX, startY, endX, endY)
end

return Enemy 