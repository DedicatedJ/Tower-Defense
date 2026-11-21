-- Levels: look-up, progression order, map building and the generated
-- ground for levels without a painted plate. Content is in data/levels.lua.
--
-- Grid cell values:
--   0 road (enemies walk, the hero can stand)
--   1 open ground (towers can be built)
--   2 tower
--   3 rock (nothing can be built)

local Levels = require('data.levels')

local Level = {}

Level.ROAD, Level.OPEN, Level.TOWER, Level.ROCK = 0, 1, 2, 3

Level.byId = {}
for _, l in ipairs(Levels.list) do Level.byId[l.id] = l end

function Level.get(id) return Level.byId[id] end

-- A faction's levels in play order
function Level.forFaction(factionId)
    local out = {}
    for _, l in ipairs(Levels.list) do
        if l.faction == factionId then out[#out + 1] = l end
    end
    table.sort(out, function(a, b) return a.order < b.order end)
    return out
end

-- The level after this one for the same faction, or nil
function Level.nextOf(id)
    local l = Level.byId[id]
    if not l then return nil end
    for _, o in ipairs(Level.forFaction(l.faction)) do
        if o.order == l.order + 1 then return o end
    end
end

-- First level of the faction (or of the game)
function Level.first(factionId)
    return Level.forFaction(factionId)[1] or Levels.list[1]
end

------------------------------------------------------------------------
-- Map building
------------------------------------------------------------------------

-- Expand waypoints into an ordered list of cells {x=, y=}. A "portal"
-- marker makes the next cell a jump; the jump is listed in `portals`.
-- Returns cells, portals, or nil and an error message.
function Level.expandPath(waypoints)
    local cells, portals = {}, {}
    local prev, jump = nil, false
    for i, wp in ipairs(waypoints) do
        if wp == "portal" then
            jump = true
        else
            local x, y = wp[1], wp[2]
            if not prev or jump then
                if jump then portals[#portals + 1] = { from = prev, to = { x = x, y = y } } end
                cells[#cells + 1] = { x = x, y = y }
                jump = false
            else
                if x ~= prev.x and y ~= prev.y then
                    return nil, string.format("waypoint %d (%d,%d) is not in line with (%d,%d)", i, x, y, prev.x, prev.y)
                end
                local dx = x > prev.x and 1 or (x < prev.x and -1 or 0)
                local dy = y > prev.y and 1 or (y < prev.y and -1 or 0)
                local cx, cy = prev.x, prev.y
                while cx ~= x or cy ~= y do
                    cx, cy = cx + dx, cy + dy
                    cells[#cells + 1] = { x = cx, y = cy }
                end
            end
            prev = cells[#cells]
        end
    end
    return cells, portals
end

-- Build the playable map. Returns a table:
--   cols, rows, grid[y][x]
--   paths       list of cell lists, one per road, start to end
--   roadCells   every road cell once as {gx, gy}; path 1 first, in order
--   portals     list of {from = cell, to = cell}
function Level.build(level)
    local cols, rows = Levels.cols, Levels.rows
    local grid = {}
    for y = 1, rows do
        grid[y] = {}
        for x = 1, cols do grid[y][x] = Level.OPEN end
    end
    for _, r in ipairs(level.rocks or {}) do
        for y = math.max(1, r[2]), math.min(rows, r[4]) do
            for x = math.max(1, r[1]), math.min(cols, r[3]) do grid[y][x] = Level.ROCK end
        end
    end

    local built = { cols = cols, rows = rows, grid = grid, paths = {}, roadCells = {}, portals = {} }
    local seen = {}
    for _, wps in ipairs(level.paths) do
        local cells, portals = Level.expandPath(wps)
        assert(cells, level.id .. ": " .. tostring(portals))
        built.paths[#built.paths + 1] = cells
        for _, p in ipairs(portals) do built.portals[#built.portals + 1] = p end
        for _, c in ipairs(cells) do
            if grid[c.y] and grid[c.y][c.x] then grid[c.y][c.x] = Level.ROAD end
            local key = c.x .. "," .. c.y
            if not seen[key] then
                seen[key] = true
                built.roadCells[#built.roadCells + 1] = { c.x, c.y }
            end
        end
    end
    return built
end

-- Problems with a level's data, as a list of messages (empty if fine)
function Level.validate(level)
    local problems = {}
    local function bad(msg) problems[#problems + 1] = level.id .. ": " .. msg end
    if not (level.paths and #level.paths > 0) then bad("no paths"); return problems end
    local rock = {}
    for _, r in ipairs(level.rocks or {}) do
        for y = r[2], r[4] do for x = r[1], r[3] do rock[x .. "," .. y] = true end end
    end
    for pi, wps in ipairs(level.paths) do
        local cells, err = Level.expandPath(wps)
        if not cells then
            bad("path " .. pi .. ": " .. err)
        else
            for _, c in ipairs(cells) do
                if c.x < 1 or c.y < 1 or c.x > Levels.cols or c.y > Levels.rows then
                    bad(string.format("path %d leaves the map at (%d,%d)", pi, c.x, c.y))
                end
                if rock[c.x .. "," .. c.y] then bad(string.format("rock on the road at (%d,%d)", c.x, c.y)) end
            end
            -- A road that touches itself sideways lets enemies cut corners
            local index = {}
            for i, c in ipairs(cells) do
                local key = c.x .. "," .. c.y
                if index[key] then bad(string.format("path %d crosses itself at (%d,%d)", pi, c.x, c.y)) end
                index[key] = i
            end
        end
    end
    if not Levels.palettes[level.palette or ""] then bad("unknown palette " .. tostring(level.palette)) end
    if not (level.startGold and level.lives and level.waves and level.waves.count) then
        bad("needs startGold, lives and waves.count")
    end
    return problems
end

------------------------------------------------------------------------
-- Generated ground
------------------------------------------------------------------------

local function shade(c, f, a) return { c[1] * f, c[2] * f, c[3] * f, a or 1 } end

-- Seeded from the level id, so a level always looks the same
local function rngFor(id)
    local seed = 7
    for i = 1, #id do seed = (seed * 31 + id:byte(i)) % 2147483647 end
    return love.math.newRandomGenerator(seed)
end

-- Draw the ground of a level into a new canvas, `cell` pixels per cell
function Level.renderGround(level, built, cell)
    local pal = Levels.palettes[level.palette] or Levels.palettes.meadow
    local w, h = built.cols * cell, built.rows * cell
    local canvas = love.graphics.newCanvas(w, h, { msaa = 4 })
    local rng = rngFor(level.id)
    local s = cell / 32

    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    love.graphics.clear(pal.ground[1], pal.ground[2], pal.ground[3], 1)

    -- Ground texture: soft patches, then speckles and tufts
    for _ = 1, built.cols * built.rows / 3 do
        local f = 0.9 + rng:random() * 0.2
        love.graphics.setColor(shade(pal.ground, f, 0.5))
        love.graphics.circle("fill", rng:random() * w, rng:random() * h, (6 + rng:random() * 18) * s)
    end
    for _ = 1, built.cols * built.rows * 2 do
        love.graphics.setColor(shade(pal.speck, 0.85 + rng:random() * 0.3, 0.55))
        local x, y = rng:random() * w, rng:random() * h
        love.graphics.rectangle("fill", x, y, (1 + rng:random() * 2) * s, (2 + rng:random() * 3) * s)
    end

    -- Rocks: rounded clusters filling their cells
    for y = 1, built.rows do
        for x = 1, built.cols do
            if built.grid[y][x] == Level.ROCK then
                local cx, cy = (x - 0.5) * cell, (y - 0.5) * cell
                love.graphics.setColor(shade(pal.rock, 0.7))
                love.graphics.circle("fill", cx + 2 * s, cy + 3 * s, cell * 0.62)
                love.graphics.setColor(shade(pal.rock, 0.9 + rng:random() * 0.2))
                love.graphics.circle("fill", cx, cy, cell * 0.58)
                love.graphics.setColor(shade(pal.rock, 1.25, 0.6))
                love.graphics.circle("fill", cx - cell * 0.15, cy - cell * 0.18, cell * 0.2)
            end
        end
    end

    -- Road: a darker edge, then the surface, drawn as rounded strokes along
    -- each path so corners are soft
    local function strokeRoad(width, color)
        love.graphics.setColor(color)
        love.graphics.setLineWidth(width)
        love.graphics.setLineJoin("bevel")
        for _, cells in ipairs(built.paths) do
            local pts = {}
            local function flush()
                if #pts >= 4 then love.graphics.line(pts) end
                for i = 1, #pts, 2 do love.graphics.circle("fill", pts[i], pts[i + 1], width / 2) end
                pts = {}
            end
            local prev
            for _, c in ipairs(cells) do
                if prev and math.abs(prev.x - c.x) + math.abs(prev.y - c.y) > 1 then flush() end
                pts[#pts + 1] = (c.x - 0.5) * cell
                pts[#pts + 1] = (c.y - 0.5) * cell
                prev = c
            end
            flush()
        end
    end
    strokeRoad(cell * 1.08, shade(pal.edge, 1))
    strokeRoad(cell * 0.86, shade(pal.road, 1))
    -- Road wear: pebbles and ruts
    for _, c in ipairs(built.roadCells) do
        for _ = 1, 3 do
            love.graphics.setColor(shade(pal.road, 0.8 + rng:random() * 0.35, 0.7))
            love.graphics.circle("fill", (c[1] - 0.5 + (rng:random() - 0.5) * 0.7) * cell,
                (c[2] - 0.5 + (rng:random() - 0.5) * 0.7) * cell, (1 + rng:random() * 1.5) * s)
        end
    end

    -- Start and end markers: a dark gate stone at each road end
    for _, cells in ipairs(built.paths) do
        local last = cells[#cells]
        love.graphics.setColor(0.2, 0.15, 0.12, 0.8)
        love.graphics.rectangle("fill", (last.x - 1) * cell + 3 * s, (last.y - 1) * cell + 3 * s, cell - 6 * s, cell - 6 * s, 4 * s)
        love.graphics.setColor(0.85, 0.75, 0.4, 0.9)
        love.graphics.setLineWidth(2 * s)
        love.graphics.rectangle("line", (last.x - 1) * cell + 3 * s, (last.y - 1) * cell + 3 * s, cell - 6 * s, cell - 6 * s, 4 * s)
    end

    love.graphics.pop()
    return canvas
end

-- Portals glow on top of the ground (animated, so drawn every frame)
function Level.drawPortals(built, cell, time)
    for _, p in ipairs(built.portals) do
        for i, c in ipairs({ p.from, p.to }) do
            local cx, cy = (c.x - 0.5) * cell, (c.y - 0.5) * cell
            local pulse = 0.5 + 0.5 * math.sin(time * 3 + i)
            love.graphics.setColor(0.55, 0.3, 0.9, 0.35 + 0.25 * pulse)
            love.graphics.circle("fill", cx, cy, cell * (0.55 + 0.1 * pulse))
            love.graphics.setColor(0.85, 0.7, 1, 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", cx, cy, cell * 0.45)
        end
    end
    love.graphics.setLineWidth(1)
end

-- Painted ground plate for a level: its `plate` field, or
-- sprites/maps/<id>.png when that file exists. nil means generate one.
function Level.platePath(level)
    local p = level.plate or ("sprites/maps/" .. level.id .. ".png")
    if love.filesystem.getInfo(p) then return p end
end

-- A small picture of the level for the level select screen
local thumbs = {}
function Level.thumbnail(level)
    if not thumbs[level.id] then
        local built = Level.build(level)
        local canvas = Level.renderGround(level, built, 10)
        local plate = Level.platePath(level)
        if plate then
            local ok, img = pcall(love.graphics.newImage, plate)
            if ok then
                local c = love.graphics.newCanvas(canvas:getWidth(), canvas:getHeight())
                love.graphics.push("all")
                love.graphics.setCanvas(c)
                love.graphics.origin()
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(img, 0, 0, 0, c:getWidth() / img:getWidth(), c:getHeight() / img:getHeight())
                love.graphics.pop()
                canvas = c
            end
        end
        thumbs[level.id] = canvas
    end
    return thumbs[level.id]
end

return Level
