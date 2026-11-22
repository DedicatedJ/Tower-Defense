-- Load required libraries
local Timer = require("libs.hump.timer")
local Utils = require("utils")
local Error = require("utils.error")
local Animations = require("systems.animations")
local Effects = require("systems.effects")

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

-- Color of the motes when an enemy dies (systems/fx.lua)
Enemy.PUFF_COLORS = {
    default = { 0.8, 0.8, 0.7 }, zombie = { 0.55, 0.7, 0.35 }, skeleton = { 0.9, 0.88, 0.8 },
    orc = { 0.6, 0.35, 0.25 }, necromancer = { 0.6, 0.35, 0.8 }, dragon = { 1, 0.55, 0.2 },
}

-- Status dots drawn over enemies, in this order
Enemy.STATUS_MARKERS = {
    { "burn", { 1, 0.5, 0.1 } }, { "poison", { 0.4, 0.9, 0.3 } }, { "drain", { 0.7, 0.3, 0.9 } },
    { "slow", { 0.3, 0.7, 1 } }, { "freeze", { 0.7, 0.9, 1 } }, { "root", { 0.5, 0.35, 0.2 } },
    { "stun", { 1, 0.95, 0.3 } }, { "mark", { 1, 0.2, 0.2 } }, { "armorShred", { 0.8, 0.8, 0.8 } },
    { "chain", { 0.5, 0.5, 0.6 } },
}

-- Combat stats used when allied units block an enemy. armor is the
-- fraction of damage blocked. nature decides light/dark weakness (light
-- hurts undead more, dark hurts the living more). Flying enemies cannot
-- be blocked. summon: raises a weaker copy of `type` every `interval`
-- seconds (the game spawns it; see states/game.lua).
Enemy.COMBAT = {
    zombie      = { armor = 0.0, attackDamage = 8,  attackRate = 1.0, nature = "undead" },
    skeleton    = { armor = 0.2, attackDamage = 10, attackRate = 1.0, nature = "undead" },
    orc         = { armor = 0.1, attackDamage = 18, attackRate = 0.8, nature = "living" },
    necromancer = { armor = 0.0, attackDamage = 12, attackRate = 1.0, nature = "undead",
                    summon = { type = "skeleton", interval = 6, healthMult = 0.5, value = 3 } },
    dragon      = { armor = 0.2, attackDamage = 0,  attackRate = 1.0, nature = "living", flying = true, boss = true },
}

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
    Enemy.sheets = Enemy.sheets or {}
    for id, enemy in pairs(Enemy.types) do
        if enemy.spriteSheet then Enemy.loadSheet(id, enemy.spriteSheet) end
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
    local prevCanvas = love.graphics.getCanvas() -- restored below (the frame may be drawing into one)
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
    love.graphics.setCanvas(prevCanvas)
    
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

    -- Combat stats (see Enemy.COMBAT). blocker is the allied unit holding
    -- this enemy in place; while blocked it stops and fights that unit.
    local combat = Enemy.COMBAT[type] or {}
    enemy.armor = combat.armor or 0
    enemy.attackDamage = combat.attackDamage or 5
    enemy.attackRate = combat.attackRate or 1
    enemy.flying = combat.flying or false
    enemy.nature = combat.nature or "living"
    enemy.boss = combat.boss or false
    enemy.summon = combat.summon
    enemy.summonTimer = combat.summon and combat.summon.interval or nil
    enemy.blocker = nil
    enemy.attackCooldown = 0
    enemy.lunge = 0
    enemy.statuses = {}

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

        -- Statuses: damage over time and expiry (may kill)
        Effects.update(self, dt)
        if self.dead then return end
        self.currentSpeed = self.speed * Effects.speedMult(self)
        self.lunge = math.max(0, self.lunge - dt * 4)

        -- Necromancer: ask the game to raise a minion (not while stunned)
        if self.summon and Effects.canAttack(self) then
            self.summonTimer = self.summonTimer - dt
            if self.summonTimer <= 0 then
                self.summonTimer = self.summon.interval
                self.summonRequest = true
            end
        end

        -- Held by an allied unit: stand and fight it
        local b = self.blocker
        if b and (b.dead or b.removed or b.released) then
            self.blocker = nil
            b = nil
        end
        if b then
            self:fight(b, dt)
            return
        end

        -- Update current animation
        self:updateAnimation(dt)

        -- Movement logic
        if self.state == "walking" then
            self:move(dt)
        end
    end

    -- Attack the unit blocking us
    enemy.fight = function(self, unit, dt)
        local dx, dy = unit.x - self.x, unit.y - self.y
        if math.abs(dx) > math.abs(dy) then
            self.direction = dx > 0 and "right" or "left"
        else
            self.direction = dy > 0 and "down" or "up"
        end
        self.attackCooldown = self.attackCooldown - dt
        if self.attackCooldown <= 0 and Effects.canAttack(self) then
            self.attackCooldown = 1 / self.attackRate
            self.lunge = 1
            local dealt = unit:takeDamage(self.attackDamage, self) or 0
            -- Holy Shield: some of it comes back
            local refl = Effects.reflect(unit)
            if refl > 0 and dealt > 0 then
                self:takeDamage(dealt * refl, unit, { ignoreArmor = true })
            end
        end
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

        -- A gap of more than a cell is a portal: step straight through
        if distance > self.gridSize * 1.5 then
            self.x, self.y = targetX, targetY
            self.portalFlash = 0.4
            distance = 0
        end
        
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

    -- How far along the road this enemy is (for "furthest enemy" targeting)
    enemy.progress = function(self)
        return self.currentPathIndex
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
    
    -- Take damage. opts: dot (damage over time), shared (from a chain),
    -- ignoreArmor. Returns the damage actually dealt.
    enemy.takeDamage = function(self, amount, source, opts)
        if self.state == "dead" or amount <= 0 then return 0 end
        opts = opts or {}

        local dmg = amount * Effects.damageTakenMult(self)
        if not opts.ignoreArmor then
            local armor = math.max(0, self.armor - Effects.armorShred(self))
            dmg = dmg * (1 - math.min(0.9, armor))
        end
        dmg = math.min(dmg, self.health)
        self.health = self.health - dmg
        if source then
            self.lastHitBy = source
            -- Credit the tower or unit (end screen stats); burns and other
            -- damage over time count for whoever applied them
            source.damageDealt = (source.damageDealt or 0) + dmg
        end

        -- Soul Shackles: direct hits are shared along the chain
        if not opts.dot and not opts.shared then
            Effects.shareChainDamage(self, dmg, source)
        end

        if self.health <= 0 then
            self:die()
        end
        return dmg
    end

    -- Enemies are never healed
    enemy.heal = function(self, amount) end
    
    -- Die
    enemy.die = function(self)
        require('systems.fx').puff(self.x, self.y - 10, Enemy.PUFF_COLORS[self.type] or Enemy.PUFF_COLORS.default)
        self.state = "dead"
        self.dead = true
        self.justDied = true -- read once by the game (XP, conversion)
        self.currentAnimation = "die"
        self.blocker = nil
        Effects.clear(self)

        -- Clear all timers
        self.timer:clear()
        self.timers = {}

        -- Remove from the game after the death animation
        self.timers.death = self.timer:after(1, function()
            self.removed = true
        end)
    end

    -- Older names some callers still use
    enemy.applySlow = function(self, amount, duration)
        Effects.apply(self, { type = "slow", amount = amount, duration = duration })
    end
    enemy.applyDot = function(self, damage, duration)
        Effects.apply(self, { type = "burn", dps = damage, duration = duration })
    end
    
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
            -- Short lunge toward the unit we are fighting
            if self.blocker and self.lunge > 0 then
                local dx, dy = self.blocker.x - self.x, self.blocker.y - self.y
                local d = math.sqrt(dx * dx + dy * dy)
                if d > 0 then
                    footX = footX + dx / d * 5 * self.lunge
                    footY = footY + dy / d * 5 * self.lunge
                end
            end

            -- Shadow drawn in code on the ground, falling down-right like the
            -- towers'. A flyer's shadow is smaller and fainter.
            love.graphics.setColor(0, 0, 0, (flying and 0.18 or 0.3) * alpha)
            love.graphics.ellipse("fill", footX + 2, groundY, h * (flying and 0.22 or 0.28),
                h * (flying and 0.07 or 0.09))

            local row = Enemy.FACING_ROW[self.direction] or 1
            local col = 2 -- standing frame when dead or fighting
            if not self.dead and not self.blocker then
                local step = math.floor((self.animTime or 0) / Enemy.FRAME_TIME) % #Enemy.WALK_CYCLE
                col = Enemy.WALK_CYCLE[step + 1]
            end
            if self.statuses and self.statuses.freeze then
                love.graphics.setColor(0.6, 0.8, 1, alpha)
            else
                love.graphics.setColor(1, 1, 1, alpha)
            end
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

        -- Status markers: a row of dots above the health bar
        local mx = barX + 2
        for _, m in ipairs(Enemy.STATUS_MARKERS) do
            if self.statuses and self.statuses[m[1]] then
                love.graphics.setColor(m[2][1], m[2][2], m[2][3], 0.9)
                love.graphics.circle("fill", mx, barY - 5, 2.5)
                mx = mx + 6
            end
        end

        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    return enemy
end

-- Draw one frame of an enemy type's walk sheet standing at (x, groundY).
-- Used for minions (raised enemies and summoned skeletons). Returns the
-- screen y of the figure's top, or nil if that type has no sheet.
function Enemy.drawFigure(sheetType, x, groundY, direction, animTime, moving, tint, alpha, drawHeight)
    local sheet = Enemy.sheets and Enemy.sheets[sheetType]
    if not sheet then return nil end
    local meta = sheet.meta
    local h = drawHeight or Enemy.DRAW_HEIGHT[sheetType] or Enemy.DRAW_HEIGHT.default
    local s = h / meta.figureH
    local flying = meta.anchor == "mass"
    local footY = flying and (groundY - Enemy.HOVER_HEIGHT) or groundY
    love.graphics.setColor(0, 0, 0, 0.3 * (alpha or 1))
    love.graphics.ellipse("fill", x + 2, groundY, h * 0.26, h * 0.08)
    local row = Enemy.FACING_ROW[direction] or 1
    local col = 2
    if moving then
        local step = math.floor((animTime or 0) / Enemy.FRAME_TIME) % #Enemy.WALK_CYCLE
        col = Enemy.WALK_CYCLE[step + 1]
    end
    tint = tint or { 1, 1, 1 }
    love.graphics.setColor(tint[1], tint[2], tint[3], alpha or 1)
    love.graphics.draw(sheet.image, sheet.quads[row][col], x, footY, 0, s, s, meta.footX, meta.footY)
    love.graphics.setColor(1, 1, 1, 1)
    return footY - (meta.footY - (meta.topY or 0)) * s
end

-- Load a walk sheet (PNG plus its .lua frame layout from tools/artcut sheet)
-- under `key`, for Enemy.drawFigure. Returns the sheet, or nil when the
-- files are not there. Heroes use this too ("hero_<id>").
function Enemy.loadSheet(key, png)
    Enemy.sheets = Enemy.sheets or {}
    if Enemy.sheets[key] then return Enemy.sheets[key] end
    local metaPath = png:gsub("%.png$", ".lua")
    if not (love.filesystem.getInfo(png) and love.filesystem.getInfo(metaPath)) then return nil end
    local okMeta, meta = pcall(function() return love.filesystem.load(metaPath)() end)
    local okImg, img = pcall(require('utils.image').smooth, png)
    if not (okMeta and okImg and type(meta) == "table") then
        print("WARNING: could not load walk sheet " .. png)
        return nil
    end
    local iw, ih = img:getDimensions()
    local quads = {}
    for r = 1, meta.rows do
        quads[r] = {}
        for c = 1, meta.cols do
            quads[r][c] = love.graphics.newQuad((c - 1) * meta.frameW, (r - 1) * meta.frameH,
                meta.frameW, meta.frameH, iw, ih)
        end
    end
    Enemy.sheets[key] = { image = img, quads = quads, meta = meta }
    return Enemy.sheets[key]
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