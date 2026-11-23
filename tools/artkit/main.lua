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
-- Map blockouts, one per level, from data/levels.lua through the game's
-- own systems/level.lua, at twice the 1280 x 720 map (2560 x 1440, 16:9).
-- Three grays, one job each: dark = scenery (nothing stands there),
-- mid = the roads with their rounded bends, exactly as the game lays them
-- out, light = build plots (the level's zones).
------------------------------------------------------------------------
local BLOCKOUT_SCALE = 2
local TONE = { scenery = 0.30, road = 0.56, plot = 0.86 }

local function blockoutName(level) return "map_" .. level.id .. "_blockout.png" end

local NUM = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
    "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen" }

-- Plain words for how a level's roads run, from its waypoints (40 px units
-- on a cols x rows map), so a painting can be checked by eye: where each
-- road enters and leaves, how many bends it has, where roads join, and
-- where a portal breaks the road.
local function describeRoads(level, cols, rows)
    local function third(v, n, lo, mid, hi)
        if v < n / 3 then return lo elseif v > n * 2 / 3 then return hi end
        return mid
    end
    local function onEdge(p) return p[1] < 0 or p[2] < 0 or p[1] > cols or p[2] > rows end
    local function where(p)
        local x, y = p[1], p[2]
        if x < 0 then return "the left edge " .. third(y, rows, "near the top", "in the middle", "near the bottom") end
        if x > cols then return "the right edge " .. third(y, rows, "near the top", "in the middle", "near the bottom") end
        if y < 0 then return "the top edge " .. third(x, cols, "near the left", "in the middle", "near the right") end
        if y > rows then return "the bottom edge " .. third(x, cols, "near the left", "in the middle", "near the right") end
        local v = third(y, rows, "near the top", "halfway down", "near the bottom")
        local h = third(x, cols, "toward the left", "in the middle", "toward the right")
        if v == "halfway down" and h == "in the middle" then return "the center of the map" end
        return "a point inside the map, " .. v .. " and " .. h
    end
    local function pieces(wps)
        local out, cur = {}, {}
        for _, wp in ipairs(wps) do
            if wp == "portal" then out[#out + 1] = cur; cur = {} else cur[#cur + 1] = wp end
        end
        out[#out + 1] = cur
        return out
    end
    local function bends(n)
        if n == 1 then return "once" elseif n == 2 then return "twice" end
        return (NUM[n] or tostring(n)) .. " times"
    end

    local parts = {}
    local first = pieces(level.paths[1])
    local start, finish = first[1][1], first[#first][#first[#first]]
    local n = 0
    for _, p in ipairs(first) do n = n + math.max(0, #p - 2) end
    local ending = onEdge(finish) and ("leaves at " .. where(finish))
        or ("ends at " .. where(finish) .. ". Leave that rounded end plain: the game marks the goal on it")
    parts[1] = string.format("%s enters at %s, bends %s and %s.",
        #level.paths > 1 and "The first road" or "There is one road. It", where(start), bends(n), ending)
    for i = 1, #first - 1 do
        local a, b = first[i][#first[i]], first[i + 1][1]
        parts[#parts + 1] = string.format("Part way along, the road stops at %s, and starts again at %s; " ..
            "there is no road between those two points. Paint each of those two road ends as a round dais " ..
            "of dark carved stone as wide as the road: the game draws a portal on each.", where(a), where(b))
    end
    for pi = 2, #level.paths do
        local pts = level.paths[pi]
        local joinAt
        for j = 2, #pts do
            for _, q in ipairs(level.paths[1]) do
                if q ~= "portal" and q[1] == pts[j][1] and q[2] == pts[j][2] then joinAt = j; break end
            end
            if joinAt then break end
        end
        assert(joinAt, level.id .. ": road " .. pi .. " never joins the first road")
        parts[#parts + 1] = string.format("A %s road enters at %s, bends %s and joins the first road at %s; " ..
            "from there they are one road.", pi == 2 and "second" or "third", where(pts[1]),
            bends(joinAt - 2), where(pts[joinAt]))
    end
    if #level.paths > 1 then parts[1] = "There are " .. NUM[#level.paths] .. " roads. " .. parts[1] end
    return table.concat(parts, " ")
end

local function mapBlockouts(Levels, Level)
    local s = BLOCKOUT_SCALE
    for _, level in ipairs(Levels.list) do
        local built = Level.build(level)
        local canvas = love.graphics.newCanvas(built.width * s, built.height * s)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(TONE.scenery, TONE.scenery, TONE.scenery)
        love.graphics.setColor(TONE.plot, TONE.plot, TONE.plot)
        for _, z in ipairs(built.zones) do
            love.graphics.rectangle("fill", z[1] * s, z[2] * s, (z[3] - z[1]) * s, (z[4] - z[2]) * s)
        end
        -- Roads last: a plot never covers the road
        local width = built.roadWidth * s
        love.graphics.setColor(TONE.road, TONE.road, TONE.road)
        love.graphics.setLineWidth(width)
        love.graphics.setLineJoin("none")
        for _, road in ipairs(built.roads) do
            for _, samples in ipairs(road.pieces) do
                local pts = {}
                for _, p in ipairs(samples) do
                    pts[#pts + 1] = p[1] * s
                    pts[#pts + 1] = p[2] * s
                end
                if #pts >= 4 then love.graphics.line(pts) end
                for i = 1, #pts, 2 do love.graphics.circle("fill", pts[i], pts[i + 1], width / 2, 48) end
            end
        end
        love.graphics.setLineWidth(1)
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

    local function entry(id, group, attach, prompt, extra, version)
        local s = A.settings[group]
        local ext = group == "sfx" and "wav or mp3" or "png"
        local v = version or 1
        w("### " .. id)
        w("")
        w("- Save as: `art/incoming/" .. id .. "_v" .. v .. "." .. (group == "sfx" and "wav" or "png") ..
          "` (next try `_v" .. (v + 1) .. "`; never overwrite). Format: " .. ext .. ".")
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
    w("Run these two, pick one of each, and send them to me before anything else. Everything after redraws from them.")
    w("The map look is set by the first map in section 11.")
    w("")
    entry(masterTower.id, "tower", nil, towerPrompt(masterTower))
    entry(masterEnemy.id, "sheet", "image 1 = `art/guides/walk_sheet_guide.png`", enemyPrompt(masterEnemy))

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
        w("Attach the approved `tower_archer` final as image 1. Cut each with `tools/artcut tower` to")
        w("`sprites/towers/<tower id>.png`; the game uses it in place of the stand-in sprite automatically.")
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
        w("Attach the approved `enemy_zombie` sheet as image 1. Cut each with `tools/artcut sheet` (feet anchor)")
        w("to `sprites/heroes/<hero id>.png` and `.lua`; the hero is drawn from it automatically.")
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

    -- Level maps: every level, the master first. A new try gets the next
    -- free version number (older 16:9 paintings already use _v1).
    local Levels = require('data.levels')
    local function nextVersion(id)
        local v = 1
        while true do
            local f = io.open(root .. "/art/incoming/" .. id .. "_v" .. v .. ".png", "rb")
            if not f then return v end
            f:close()
            v = v + 1
        end
    end
    local order = {}
    for _, level in ipairs(Levels.list) do
        if level.id == A.mapMaster then table.insert(order, 1, level) else order[#order + 1] = level end
    end
    w("## 11. Level maps")
    w("")
    w(A.mapIntro)
    w("")
    for _, level in ipairs(order) do
        local m = A.levelMaps[level.id]
        assert(m, "art/assets.lua A.levelMaps has no entry for " .. level.id)
        local master = level.id == A.mapMaster
        local p = A.mapScene .. "\n\n"
        if not master then p = p .. A.mapRedo .. "\n\n" end
        p = p .. "Place: " .. m.place .. "\n\n" ..
            string.format(A.mapBody, describeRoads(level, Levels.cols, Levels.rows), m.road, m.plot, m.scenery) ..
            "\n\n" .. A.mapView .. "\n\nStyle: " .. A.mapStyle
        local attach = "image 1 = `art/guides/" .. blockoutName(level) .. "`"
        if not master then attach = attach .. "; image 2 = the approved `map_" .. A.mapMaster .. "` final" end
        local id = "map_" .. level.id
        entry(id, "map", attach, p, nil, nextVersion(id))
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
    package.path = root .. "/?.lua;" .. package.path
    walkSheet()
    mapBlockouts(require('data.levels'), require('systems.level'))
    boxSheet(4, 2, "icon_sheet_8_guide.png")
    buildPrompts(root)
    love.event.quit(0)
end
