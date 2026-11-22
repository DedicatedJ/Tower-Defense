-- Levels: look-up, progression order, map building and the generated
-- ground for levels without a painted plate. Content is in data/levels.lua.
--
-- Roads are pixel paths (systems/path.lua); towers go anywhere inside a
-- level's build zones that is clear of the road, the HUD and other towers.

local Levels = require('data.levels')

local Level = {}

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

local Path = require('systems.path')

Level.TOWER_CLEARANCE = 18  -- a tower stands at least this far off the road edge
Level.TOWER_SPACING = 40    -- and at least this far from another tower
Level.HUD_MARGIN = 24       -- and this far outside the HUD boxes

-- Waypoints (40 px units, "portal" markers) to pieces of pixel points
function Level.pieces(waypoints)
    local u = Levels.unit
    local pieces, cur = {}, {}
    for _, wp in ipairs(waypoints) do
        if wp == "portal" then
            pieces[#pieces + 1] = cur
            cur = {}
        else
            cur[#cur + 1] = { wp[1] * u, wp[2] * u }
        end
    end
    pieces[#pieces + 1] = cur
    return pieces
end

-- HUD boxes as a list of {x, y, w, h}
function Level.hudBoxes()
    local list = {}
    for _, name in ipairs({ "status", "controls", "hero", "towers" }) do
        list[#list + 1] = Levels.hud[name]
    end
    return list
end

-- Build the playable map. Returns a table:
--   width, height   the map in pixels (the screen)
--   roadWidth       pixels
--   roads           one systems/path.lua Path per road, start to end
--   portals         list of {from = {x, y}, to = {x, y}}
--   zones           build zones as {x1, y1, x2, y2} in pixels
--   hud             HUD boxes {x, y, w, h}
function Level.build(level)
    local u = Levels.unit
    local built = {
        width = Levels.width, height = Levels.height,
        roadWidth = level.roadWidth or Levels.roadWidth,
        roads = {}, portals = {}, zones = {}, hud = Level.hudBoxes(),
    }
    for _, wps in ipairs(level.paths) do
        local road = Path.new(Level.pieces(wps), built.roadWidth)
        built.roads[#built.roads + 1] = road
        for _, p in ipairs(road:portals()) do built.portals[#built.portals + 1] = p end
    end
    for _, z in ipairs(level.zones or {}) do
        built.zones[#built.zones + 1] = { z[1] * u, z[2] * u, z[3] * u, z[4] * u }
    end
    return built
end

-- Nearest road center line to (x, y): distance, road index, distance along
-- that road, and the center-line point
function Level.nearestRoad(built, x, y)
    local bd, bi, bs, bx, by
    for i, road in ipairs(built.roads) do
        local s, d, cx, cy = road:nearest(x, y)
        if not bd or d < bd then bd, bi, bs, bx, by = d, i, s, cx, cy end
    end
    return bd, bi, bs, bx, by
end

-- On the road surface (margin widens or, negative, narrows it)
function Level.onRoad(built, x, y, margin)
    local d = Level.nearestRoad(built, x, y)
    return d ~= nil and d <= built.roadWidth / 2 + (margin or 0)
end

function Level.inHud(built, x, y, margin)
    margin = margin or 0
    for _, b in ipairs(built.hud) do
        if x >= b[1] - margin and x <= b[1] + b[3] + margin
            and y >= b[2] - margin and y <= b[2] + b[4] + margin then
            return true
        end
    end
    return false
end

function Level.inZone(built, x, y)
    for _, z in ipairs(built.zones) do
        if x >= z[1] and x <= z[3] and y >= z[2] and y <= z[4] then return true end
    end
    return false
end

-- Whether a tower can stand at (x, y). towers: placed towers (x, y).
-- Returns true, or false and the reason: "zone", "road", "hud", "tower"
function Level.canBuild(built, x, y, towers)
    if x < 0 or y < 0 or x > built.width or y > built.height then return false, "zone" end
    if not Level.inZone(built, x, y) then return false, "zone" end
    if Level.inHud(built, x, y, Level.HUD_MARGIN) then return false, "hud" end
    local d = Level.nearestRoad(built, x, y)
    if d and d < built.roadWidth / 2 + Level.TOWER_CLEARANCE then return false, "road" end
    for _, t in ipairs(towers or {}) do
        if (t.x - x) ^ 2 + (t.y - y) ^ 2 < Level.TOWER_SPACING ^ 2 then return false, "tower" end
    end
    return true
end

-- Walk grid for heroes and minions: 20 px cells on the road surface
function Level.nav(built)
    if not built.nav then
        built.nav = Path.Nav.new(function(x, y)
            return x > 0 and y > 0 and x < built.width and y < built.height
                and Level.onRoad(built, x, y, -6)
        end, built.width, built.height, 20)
    end
    return built.nav
end

-- Problems with a level's data, as a list of messages (empty if fine)
function Level.validate(level)
    local problems = {}
    local function bad(msg) problems[#problems + 1] = level.id .. ": " .. msg end
    if not (level.paths and #level.paths > 0) then bad("no paths"); return problems end
    for pi, wps in ipairs(level.paths) do
        for _, piece in ipairs(Level.pieces(wps)) do
            if #piece < 2 then bad("path " .. pi .. " has a piece with fewer than 2 points") end
        end
    end
    if #problems > 0 then return problems end
    local built = Level.build(level)
    local half = built.roadWidth / 2
    for ri, road in ipairs(built.roads) do
        local hudHit, outside = false, false
        for i = 1, #road.xs do
            local x, y = road.xs[i], road.ys[i]
            -- The road edge stays out of every HUD box
            for _, b in ipairs(built.hud) do
                local cx = math.max(b[1], math.min(x, b[1] + b[3]))
                local cy = math.max(b[2], math.min(y, b[2] + b[4]))
                if (cx - x) ^ 2 + (cy - y) ^ 2 < (half + 4) ^ 2 then hudHit = true end
            end
            -- Roads may run off the edge to enter or leave, no further
            if x < -half - 20 or y < -half - 20 or x > built.width + half + 20 or y > built.height + half + 20 then
                outside = true
            end
        end
        if hudHit then bad("road " .. ri .. " runs under the HUD") end
        if outside then bad("road " .. ri .. " goes too far off the map") end
    end
    if not (level.zones and #level.zones > 0) then bad("no build zones") end
    for zi, z in ipairs(built.zones) do
        local room = 0
        for x = z[1], z[3], 10 do
            for y = z[2], z[4], 10 do
                if Level.canBuild(built, x, y, {}) then room = room + 1 end
            end
        end
        if room < 20 then bad("zone " .. zi .. " has no room to build") end
    end
    if not Levels.palettes[level.palette or ""] then bad("unknown palette " .. tostring(level.palette)) end
    if not (level.startGold and level.lives and level.waves and level.waves.count) then
        bad("needs startGold, lives and waves.count")
    end
    return problems
end

------------------------------------------------------------------------
-- Drawing the ground
------------------------------------------------------------------------

local function shade(c, f, a) return { c[1] * f, c[2] * f, c[3] * f, a or 1 } end

-- Seeded from the level id, so a level always looks the same
local function rngFor(id)
    local seed = 7
    for i = 1, #id do seed = (seed * 31 + id:byte(i)) % 2147483647 end
    return love.math.newRandomGenerator(seed)
end

-- Generated ground: soft patches, speckles, the build zones a little
-- lighter, and stones scattered away from the road and the zones
local function drawGeneratedGround(built, pal, rng)
    local w, h = built.width, built.height
    love.graphics.clear(pal.ground[1], pal.ground[2], pal.ground[3], 1)
    for _ = 1, 260 do
        love.graphics.setColor(shade(pal.ground, 0.9 + rng:random() * 0.2, 0.5))
        love.graphics.circle("fill", rng:random() * w, rng:random() * h, 8 + rng:random() * 24)
    end
    for _ = 1, 1600 do
        love.graphics.setColor(shade(pal.speck, 0.85 + rng:random() * 0.3, 0.55))
        love.graphics.rectangle("fill", rng:random() * w, rng:random() * h, 1 + rng:random() * 2.5, 2 + rng:random() * 4)
    end
    for _, z in ipairs(built.zones) do
        love.graphics.setColor(shade(pal.speck, 1, 0.12))
        love.graphics.rectangle("fill", z[1], z[2], z[3] - z[1], z[4] - z[2], 14, 14)
    end
    for _ = 1, 70 do
        local x, y = rng:random() * w, rng:random() * h
        if not Level.inZone(built, x, y) and not Level.onRoad(built, x, y, 24) then
            local r = 6 + rng:random() * 14
            love.graphics.setColor(shade(pal.rock, 0.7))
            love.graphics.circle("fill", x + 2, y + 3, r * 1.05)
            love.graphics.setColor(shade(pal.rock, 0.9 + rng:random() * 0.2))
            love.graphics.circle("fill", x, y, r)
            love.graphics.setColor(shade(pal.rock, 1.25, 0.6))
            love.graphics.circle("fill", x - r * 0.3, y - r * 0.3, r * 0.35)
        end
    end
end

-- The roads: a darker edge, the surface, then wear marks and gate stones
local function drawRoads(built, pal, rng)
    local width = built.roadWidth
    local function stroke(lineWidth, color)
        love.graphics.setColor(color)
        love.graphics.setLineWidth(lineWidth)
        love.graphics.setLineJoin("none")
        for _, road in ipairs(built.roads) do
            for _, samples in ipairs(road.pieces) do
                local pts = {}
                for _, p in ipairs(samples) do
                    pts[#pts + 1] = p[1]
                    pts[#pts + 1] = p[2]
                end
                if #pts >= 4 then love.graphics.line(pts) end
                -- Round joins and caps
                for i = 1, #pts, 2 do love.graphics.circle("fill", pts[i], pts[i + 1], lineWidth / 2) end
            end
        end
    end
    stroke(width + 8, shade(pal.edge, 0.85))
    stroke(width, shade(pal.edge, 1))
    stroke(width - 10, shade(pal.road, 1))
    for _, road in ipairs(built.roads) do
        for s = 0, road:length(), 9 do
            local x, y, nx, ny = road:pointAt(s)
            local o = (rng:random() - 0.5) * (width - 18)
            love.graphics.setColor(shade(pal.road, 0.78 + rng:random() * 0.35, 0.7))
            love.graphics.circle("fill", x + nx * o, y + ny * o, 1 + rng:random() * 2)
        end
    end
    for _, road in ipairs(built.roads) do
        local x, y = road.xs[#road.xs], road.ys[#road.ys]
        if x > 0 and y > 0 and x < built.width and y < built.height then
            love.graphics.setColor(0.2, 0.15, 0.12, 0.85)
            love.graphics.rectangle("fill", x - 18, y - 18, 36, 36, 5)
            love.graphics.setColor(0.85, 0.75, 0.4, 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x - 18, y - 18, 36, 36, 5)
        end
    end
    love.graphics.setLineWidth(1)
end

-- Draw a level's ground into a new canvas at `scale` (1 = the screen):
-- the painted plate if given (stretched to the map), else generated ground,
-- then the roads from the level data on top
function Level.renderGround(level, built, scale, plateImage)
    scale = scale or 1
    local pal = Levels.palettes[level.palette] or Levels.palettes.meadow
    local canvas = love.graphics.newCanvas(math.floor(built.width * scale), math.floor(built.height * scale), { msaa = 4 })
    local rng = rngFor(level.id)
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    love.graphics.scale(scale, scale)
    if plateImage then
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(plateImage, 0, 0, 0, built.width / plateImage:getWidth(), built.height / plateImage:getHeight())
    else
        drawGeneratedGround(built, pal, rng)
    end
    drawRoads(built, pal, rng)
    love.graphics.pop()
    return canvas
end

-- Build zones while a tower is being placed: a soft fill and an outline
function Level.drawZones(built, time)
    local pulse = 0.5 + 0.5 * math.sin((time or 0) * 3)
    for _, z in ipairs(built.zones) do
        love.graphics.setColor(1, 1, 1, 0.08 + 0.04 * pulse)
        love.graphics.rectangle("fill", z[1], z[2], z[3] - z[1], z[4] - z[2], 10, 10)
        love.graphics.setColor(1, 0.95, 0.7, 0.45)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", z[1], z[2], z[3] - z[1], z[4] - z[2], 10, 10)
    end
    love.graphics.setLineWidth(1)
end

-- Portals glow on top of the ground (animated, so drawn every frame)
function Level.drawPortals(built, time)
    for _, p in ipairs(built.portals) do
        for i, c in ipairs({ p.from, p.to }) do
            local pulse = 0.5 + 0.5 * math.sin(time * 3 + i)
            local r = built.roadWidth / 2
            love.graphics.setColor(0.55, 0.3, 0.9, 0.35 + 0.25 * pulse)
            love.graphics.circle("fill", c[1], c[2], r * (0.9 + 0.15 * pulse))
            love.graphics.setColor(0.85, 0.7, 1, 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", c[1], c[2], r * 0.75)
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

-- The level's ground and roads at `scale`, over its plate if it has one
function Level.renderMap(level, built, scale)
    local plate, img = Level.platePath(level), nil
    if plate then
        local ok, loaded = pcall(require('utils.image').smooth, plate)
        if ok then img = loaded else print("WARNING: could not load map plate " .. plate) end
    end
    return Level.renderGround(level, built, scale, img)
end

-- A small picture of the level for the level select screen (16:9)
local thumbs = {}
function Level.thumbnail(level)
    if not thumbs[level.id] then
        thumbs[level.id] = Level.renderMap(level, Level.build(level), 0.25)
    end
    return thumbs[level.id]
end

return Level
