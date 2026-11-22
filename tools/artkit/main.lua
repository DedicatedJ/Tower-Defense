-- Draws the layout guides attached as image 1 when generating art.
-- Run from the repo root:  lovec tools/artkit <absolute repo root>
--
-- Guide rules (see art/README.md): plain grays only, no marker colors,
-- no grid lines. The model copies whatever it sees, so draw nothing that
-- could be mistaken for content.

local OUT -- absolute or repo-relative output folder, from the command line

local GRAY = {
    bg     = {0.95, 0.95, 0.95},
    light  = {0.80, 0.80, 0.80},
    mid    = {0.55, 0.55, 0.55},
    far    = {0.43, 0.43, 0.43}, -- far-side limbs in side views
    dark   = {0.35, 0.35, 0.35}, -- back of the head
    face   = {0.66, 0.66, 0.66},
    road   = {0.48, 0.48, 0.48},
    ground = {0.78, 0.78, 0.78},
}

local function save(canvas, name)
    love.graphics.setCanvas()
    local data = canvas:newImageData()
    local png = data:encode("png"):getString()
    local path = OUT .. "/" .. name
    local f = assert(io.open(path, "wb"))
    f:write(png)
    f:close()
    print(string.format("wrote %s (%dx%d)", path, data:getWidth(), data:getHeight()))
end

local function limb(x1, y1, x2, y2, w)
    love.graphics.setLineWidth(w)
    love.graphics.line(x1, y1, x2, y2)
    love.graphics.circle("fill", x1, y1, w / 2)
    love.graphics.circle("fill", x2, y2, w / 2)
end

------------------------------------------------------------------------
-- Walk sheet: 4 rows (toward, right, left, away) x 3 columns
-- (left foot forward, standing, right foot forward).
-- Proportions follow "readable at small size": big head, compact body.
------------------------------------------------------------------------
local function mannequin(cx, baseY, facing, step)
    -- step: -1 left foot forward, 0 standing, 1 right foot forward
    local headR = 56
    local legLen = 120
    local torsoH = 140
    local hipY = baseY - legLen
    local shoulderY = hipY - torsoH
    local headY = shoulderY - headR + 6
    local limbW = 30

    if facing == "right" or facing == "left" then
        local dir = facing == "right" and 1 or -1
        -- Character's left side is the near side when facing left
        -- (screen), far side when facing right.
        local stride = 52 * step
        local swing = 40 * step
        -- far limbs first (darker), near limbs last
        local leftFootX = cx + dir * stride
        local rightFootX = cx - dir * stride
        local leftHandX = cx - dir * swing
        local rightHandX = cx + dir * swing
        local nearIsLeft = (facing == "left")

        local function leg(footX, near)
            love.graphics.setColor(near and GRAY.mid or GRAY.far)
            limb(cx, hipY, footX, baseY - 10, limbW)
            -- foot points the way the figure faces
            limb(footX, baseY - 10, footX + dir * 26, baseY - 10, 22)
        end
        local function arm(handX, near)
            love.graphics.setColor(near and GRAY.mid or GRAY.far)
            limb(cx, shoulderY + 14, handX, hipY - 6, 24)
        end

        leg(nearIsLeft and rightFootX or leftFootX, false)
        arm(nearIsLeft and rightHandX or leftHandX, false)

        love.graphics.setColor(GRAY.mid)
        love.graphics.rectangle("fill", cx - 34, shoulderY, 68, torsoH + 10, 24, 24)
        love.graphics.circle("fill", cx, headY, headR)
        -- nose bump shows the facing
        love.graphics.circle("fill", cx + dir * (headR - 4), headY + 8, 12)
        -- back of the head is darker
        love.graphics.setColor(GRAY.dark)
        love.graphics.arc("fill", cx, headY, headR, math.pi / 2 + (dir > 0 and 0 or math.pi) ,
            math.pi * 1.5 + (dir > 0 and 0 or math.pi))

        leg(nearIsLeft and leftFootX or rightFootX, true)
        arm(nearIsLeft and leftHandX or rightHandX, true)
        return
    end

    -- toward / away
    local toward = facing == "toward"
    -- Screen side of the character's left foot
    local leftSide = toward and 1 or -1
    local hipW = 26
    local function footY(isLeft)
        if step == 0 then return baseY - 10 end
        local forward = (isLeft and step == -1) or (not isLeft and step == 1)
        -- toward the camera the forward foot sits lower on screen,
        -- walking away it sits higher
        if forward then return baseY - 10 + (toward and 8 or -14) end
        return baseY - 10 - (toward and 22 or 4)
    end
    local function legFor(isLeft)
        local side = isLeft and leftSide or -leftSide
        local fx = cx + side * hipW
        local fy = footY(isLeft)
        love.graphics.setColor(GRAY.mid)
        limb(cx + side * hipW, hipY, fx, fy, limbW)
        limb(fx - 12, fy, fx + 12, fy, 24)
    end
    local function armFor(isLeft)
        local side = isLeft and leftSide or -leftSide
        -- arm swings opposite to the leg
        local lift = 0
        if step ~= 0 then
            local legForward = (isLeft and step == -1) or (not isLeft and step == 1)
            lift = legForward and 14 or -14
        end
        love.graphics.setColor(GRAY.mid)
        limb(cx + side * 52, shoulderY + 16, cx + side * 60, hipY - 4 + lift, 24)
    end

    legFor(true); legFor(false)
    armFor(true); armFor(false)
    love.graphics.setColor(GRAY.mid)
    love.graphics.rectangle("fill", cx - 50, shoulderY, 100, torsoH + 10, 26, 26)
    if toward then
        love.graphics.circle("fill", cx, headY, headR)
        love.graphics.setColor(GRAY.face)
        love.graphics.ellipse("fill", cx, headY + 10, headR * 0.62, headR * 0.7)
    else
        love.graphics.setColor(GRAY.dark)
        love.graphics.circle("fill", cx, headY, headR)
    end
end

local function walkSheet()
    local cell = 512
    local canvas = love.graphics.newCanvas(cell * 3, cell * 4)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(GRAY.bg)
    love.graphics.setLineStyle("smooth")
    local rows = {"toward", "right", "left", "away"}
    local steps = {-1, 0, 1}
    for r, facing in ipairs(rows) do
        for c, step in ipairs(steps) do
            local cx = (c - 0.5) * cell
            local baseY = (r - 1) * cell + 470
            mannequin(cx, baseY, facing, step)
        end
    end
    save(canvas, "walk_sheet_guide.png")
end

------------------------------------------------------------------------
-- Map blockouts, one per level, built from data/levels.lua by the game's
-- own systems/level.lua. 24 x 18 cells at 80 px = 1920 x 1440 (4:3).
-- Mid gray is the road, near black is rock, light gray is open ground.
------------------------------------------------------------------------
local function blockoutName(level)
    return level.id == "sunlit_meadows" and "map_level1_blockout.png" or ("map_" .. level.id .. "_blockout.png")
end

-- Plain words for how a level's roads run, so a painting can be checked by
-- eye: where each road enters and leaves, how many right-angle turns it has,
-- where roads join, and where a portal breaks the road.
local NUM = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
    "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen" }

local function describeRoads(level, Level, cols, rows)
    local function third(v, n, lo, hi)
        if v <= n / 3 then return "near the " .. lo elseif v > n * 2 / 3 then return "near the " .. hi end
        return "in the middle"
    end
    local function where(c)
        if c.x == 1 then return "the left edge " .. third(c.y, rows, "top", "bottom") end
        if c.x == cols then return "the right edge " .. third(c.y, rows, "top", "bottom") end
        if c.y == 1 then return "the top edge " .. third(c.x, cols, "left", "right") end
        if c.y == rows then return "the bottom edge " .. third(c.x, cols, "left", "right") end
        local v, h = third(c.y, rows, "top", "bottom"), third(c.x, cols, "left", "right")
        if v == "in the middle" and h == "in the middle" then return "the center of the map" end
        return "a point inside the map, " .. v .. " and " .. h:gsub("^near the ", "toward the ")
    end
    local function onEdge(c) return c.x == 1 or c.y == 1 or c.x == cols or c.y == rows end
    local function turns(cells)
        local n = 0
        for i = 2, #cells - 1 do
            local a, b, c = cells[i - 1], cells[i], cells[i + 1]
            local adj1 = math.abs(a.x - b.x) + math.abs(a.y - b.y) == 1
            local adj2 = math.abs(b.x - c.x) + math.abs(b.y - c.y) == 1
            if adj1 and adj2 and (b.x - a.x ~= c.x - b.x or b.y - a.y ~= c.y - b.y) then n = n + 1 end
        end
        return n
    end

    local parts = {}
    local first = Level.expandPath(level.paths[1])
    local _, portals = Level.expandPath(level.paths[1])
    local last = first[#first]
    local ending = onEdge(last) and ("leaves at " .. where(last)) or ("ends at " .. where(last))
    parts[1] = string.format("%s road enters at %s, has exactly %s right-angle turns in all and %s.",
        #level.paths > 1 and "The first" or "There is one road. It", where(first[1]),
        NUM[turns(first)] or tostring(turns(first)), ending)
    parts[1] = parts[1]:gsub("^There is one road%. It road", "There is one road. It")
    for _, p in ipairs(portals) do
        parts[#parts + 1] = string.format("Part way along, the road stops at %s, and starts again at %s; there " ..
            "is no road between those two points. Leave both of those ends as plain road ends; the game " ..
            "draws a portal on them.", where(p.from), where(p.to))
    end
    if #level.paths > 1 then
        local onFirst = {}
        for _, c in ipairs(first) do onFirst[c.x .. "," .. c.y] = true end
        for i = 2, #level.paths do
            local cells = Level.expandPath(level.paths[i])
            local joinAt
            for _, c in ipairs(cells) do
                if onFirst[c.x .. "," .. c.y] then joinAt = c; break end
            end
            local lead = {}
            for _, c in ipairs(cells) do
                lead[#lead + 1] = c
                if c == joinAt then break end
            end
            parts[#parts + 1] = string.format("A second road enters at %s, makes %s right-angle turns and " ..
                "joins the first road at %s; from there they are one road.", where(cells[1]),
                NUM[turns(lead)] or tostring(turns(lead)), where(joinAt))
        end
        parts[1] = "There are " .. NUM[#level.paths] .. " roads. " .. parts[1]
    end
    return table.concat(parts, " ")
end

local function mapBlockouts(root)
    package.path = root .. "/?.lua;" .. package.path
    local Levels = require('data.levels')
    local Level = require('systems.level')
    local cell = 80
    for _, level in ipairs(Levels.list) do
        local built = Level.build(level)
        local canvas = love.graphics.newCanvas(built.cols * cell, built.rows * cell)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(GRAY.ground)
        for y = 1, built.rows do
            for x = 1, built.cols do
                local v = built.grid[y][x]
                if v == Level.ROAD or v == Level.ROCK then
                    love.graphics.setColor(v == Level.ROAD and GRAY.road or { 0.18, 0.18, 0.18 })
                    love.graphics.rectangle("fill", (x - 1) * cell, (y - 1) * cell, cell, cell)
                end
            end
        end
        save(canvas, blockoutName(level))
    end
end

------------------------------------------------------------------------
-- Object sheet: 8 empty boxes in 2 rows of 4 (achievement icons).
------------------------------------------------------------------------
local function boxSheet(cols, rows, name)
    local box, gap = 380, 120
    local w = cols * box + (cols + 1) * gap
    local h = rows * box + (rows + 1) * gap
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(GRAY.bg)
    love.graphics.setColor(GRAY.light)
    for r = 1, rows do
        for c = 1, cols do
            love.graphics.rectangle("fill", gap + (c - 1) * (box + gap), gap + (r - 1) * (box + gap), box, box, 24, 24)
        end
    end
    save(canvas, name)
end

------------------------------------------------------------------------
-- Prompt pack: art/prompts.md built from art/assets.lua
------------------------------------------------------------------------
local function buildPrompts(root)
    local A = dofile(root .. "/art/assets.lua")
    local out = {}
    local function w(s) out[#out + 1] = s or "" end
    local function styled(p) return p .. "\n\nStyle: " .. A.style end

    local function entry(id, group, attach, prompt, extra)
        local s = A.settings[group]
        local ext = group == "sfx" and "wav or mp3" or "png"
        w("### " .. id)
        w("")
        w("- Save as: `art/incoming/" .. id .. "_v1." .. (group == "sfx" and "wav" or "png") ..
          "` (next try `_v2`; never overwrite). Format: " .. ext .. ".")
        if group == "sfx" then
            w("- Model: " .. s.model .. ". Duration: " .. extra .. " s.")
        else
            w("- Model: " .. s.model .. ". Aspect " .. s.aspect .. ". Background: " .. s.background .. ".")
            w("- Draft: " .. s.draft .. ". Final: " .. s.final .. ".")
        end
        w("- Attach: " .. (attach or "nothing"))
        w("")
        w("```text")
        w(prompt)
        w("```")
        w("")
    end

    w("# Art prompt pack")
    w("")
    w("Generated from `art/assets.lua` by `tools/artkit`. Do not edit by hand: change the data and rebuild.")
    w("Workflow, file naming and the accept checklist are in `art/README.md`.")
    w("")
    w("Every image prompt below already ends with the style block:")
    w("")
    w("```text")
    w(A.style)
    w("```")
    w("")

    local masterTower, masterEnemy
    for _, t in ipairs(A.towers) do if t.master then masterTower = t end end
    for _, e in ipairs(A.enemies) do if e.master then masterEnemy = e end end

    local function towerPrompt(t)
        local p = string.format(A.towerTemplate, t.name, t.desc)
        if not t.master then p = A.towerRedo .. p end
        return styled(p)
    end
    local function enemyPrompt(e)
        if e.master then
            return styled(string.format(A.sheetMaster, e.name, e.name, e.name, e.character, e.gear))
        end
        return styled(string.format(A.sheetRedo, e.name, e.character, e.gear, e.notCarried))
    end

    w("## 1. Set the look first")
    w("")
    w("Run these three, pick one of each, and send them to me before anything else. Everything after redraws from them.")
    w("")
    entry(masterTower.id, "tower", nil, towerPrompt(masterTower))
    entry(masterEnemy.id, "sheet", "image 1 = `art/guides/walk_sheet_guide.png`", enemyPrompt(masterEnemy))
    entry(A.map.id, "map", "image 1 = `" .. A.map.guide .. "`", styled(A.map.prompt))

    w("## 2. Other towers")
    w("")
    for _, t in ipairs(A.towers) do
        if not t.master then
            entry(t.id, "tower", "image 1 = the approved `" .. masterTower.id .. "` final", towerPrompt(t))
        end
    end

    w("## 3. Other enemies")
    w("")
    for _, e in ipairs(A.enemies) do
        if not e.master then
            entry(e.id, "sheet", "image 1 = the approved `" .. masterEnemy.id .. "` sheet", enemyPrompt(e))
        end
    end

    w("## 4. Screen backdrops")
    w("")
    for _, b in ipairs(A.backdrops) do
        entry(b.id, "backdrop", nil, styled(string.format(A.backdropTemplate, b.scene)))
    end

    w("## 5. Level thumbnails")
    w("")
    for _, t in ipairs(A.thumbs) do
        entry(t.id, "thumb", nil, styled(string.format(A.thumbTemplate, t.scene)))
    end

    w("## 6. Achievement icons")
    w("")
    local list = {}
    -- No numerals in the prompt: they can come back as lettering
    for _, it in ipairs(A.icons.items) do list[#list + 1] = it[2] end
    entry(A.icons.id, "icons", "image 1 = `" .. A.icons.guide .. "`",
        styled(string.format(A.icons.prompt, table.concat(list, "; "))))

    w("## 7. Sound effects")
    w("")
    for _, s in ipairs(A.sfx) do
        entry(s.id, "sfx", nil, s.prompt, s.dur)
    end

    if A.cTowers then
        w("## 8. Faction towers (Model C)")
        w("")
        w("Attach the approved `tower_archer` final as image 1. Cut each with `tools/artcut tower`, then point")
        w("that tower's `sprite` in `data/factions.lua` at the new file.")
        w("")
        for _, t in ipairs(A.cTowers) do
            -- Faction towers have their own colors; say so, or the style line's
            -- "grey stone and warm wood with gold trim" pulls them back to it
            local p = A.towerRedo .. string.format(A.towerTemplate, t.name, t.desc) ..
                " Use the colors and materials described here for the tower above the base, even where they " ..
                "differ from the rest of the set; only the base stays grey stone."
            entry(t.id, "tower", "image 1 = the approved `tower_archer` final", styled(p))
        end

        w("## 9. Hero walk sheets (Model C)")
        w("")
        w("Attach the approved `enemy_zombie` sheet as image 1. Cut each with `tools/artcut sheet` (feet anchor).")
        w("")
        for _, h in ipairs(A.cHeroes) do
            entry(h.id, "sheet", "image 1 = the approved `enemy_zombie` sheet",
                styled(string.format(A.sheetRedo, h.name, h.character, h.gear, h.notCarried)))
        end

        w("## 10. Missing hero portraits")
        w("")
        w("Attach an existing portrait (for example `assets/hero images/radiant order/Galahad/Sir Galahad.jpg`)")
        w("as image 1. Opaque, 4:3. Each goes to its `file` in `art/assets.lua` (A.portraits).")
        w("")
        for _, p in ipairs(A.portraits) do
            entry(p.id, "backdrop", "image 1 = an existing hero portrait", string.format(A.portraitTemplate, p.desc, p.bg))
        end
    end

    -- Maps for every level that has no painted plate yet
    local Levels = require('data.levels')
    local todo = {}
    for _, level in ipairs(Levels.list) do
        local file = level.plate or ("sprites/maps/" .. level.id .. ".png")
        local f = io.open(root .. "/" .. file, "rb")
        if f then f:close() else todo[#todo + 1] = level end
    end
    if #todo > 0 then
        w("## 11. Level maps")
        w("")
        w("Attach the level's gray layout from `art/guides/` as image 1. Cut each with `tools/artcut mapfix`")
        w("(24 x 18 cells) and save it as `sprites/maps/<level id>.png`; the game picks it up from there.")
        w("Until then the game draws a generated ground for the level.")
        w("")
        local Level = require('systems.level')
        for _, level in ipairs(todo) do
            local m = A.levelMaps[level.id]
            assert(m, "art/assets.lua A.levelMaps has no entry for " .. level.id)
            local rocks = A.noRocks
            if level.rocks then
                assert(m.rock, "art/assets.lua A.levelMaps." .. level.id .. " needs a rock material")
                rocks = "The near-black areas are " .. m.rock .. ", where nothing can be built: fill each " ..
                    "one edge to edge and keep it inside its black area."
            end
            local prompt = string.format(A.levelMapTemplate, describeRoads(level, Level, Levels.cols, Levels.rows),
                m.ground, m.road, rocks)
            entry("map_" .. level.id, "map", "image 1 = `art/guides/" .. blockoutName(level) .. "`",
                prompt .. "\n\nStyle: " .. A.mapStyle)
        end
    end

    local path = root .. "/art/prompts.md"
    local f = assert(io.open(path, "wb"))
    f:write(table.concat(out, "\n"))
    f:close()
    print("wrote " .. path)
end

-- Usage: lovec tools/artkit <repo root>
function love.load(args)
    local root = args[1] or "."
    OUT = root .. "/art/guides"
    walkSheet()
    mapBlockouts(root)
    boxSheet(4, 2, "icon_sheet_8_guide.png")
    buildPrompts(root)
    love.event.quit(0)
end
