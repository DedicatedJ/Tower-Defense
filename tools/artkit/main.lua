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
-- Map blockout for level 1, from the path in states/game.lua loadMap().
-- 24 x 18 cells at 80 px = 1920 x 1440 (4:3). Mid gray is the road.
------------------------------------------------------------------------
local LEVEL1_PATH = {
    {1, 1}, {2, 1}, {3, 1}, {4, 1}, {5, 1}, {6, 1}, {7, 1}, {8, 1},
    {8, 2}, {8, 3}, {8, 4}, {8, 5}, {8, 6}, {8, 7}, {8, 8},
    {9, 8}, {10, 8}, {11, 8}, {12, 8}, {13, 8}, {14, 8},
    {14, 7}, {14, 6}, {14, 5}, {14, 4}, {14, 3},
    {15, 3}, {16, 3}, {17, 3}, {18, 3},
    {18, 4}, {18, 5}, {18, 6}, {18, 7}, {18, 8}, {18, 9}, {18, 10}, {18, 11}, {18, 12},
    {17, 12}, {16, 12}, {15, 12}, {14, 12}, {13, 12}, {12, 12}, {11, 12}, {10, 12}, {9, 12},
    {8, 12}, {7, 12}, {6, 12}, {5, 12}, {4, 12},
    {4, 13}, {4, 14}, {4, 15}, {4, 16}, {4, 17},
    {5, 17}, {6, 17}, {7, 17}, {8, 17}, {9, 17}, {10, 17}, {11, 17}, {12, 17}, {13, 17},
    {14, 17}, {15, 17}, {16, 17}, {17, 17}, {18, 17}
}

local function mapBlockout()
    local cell = 80
    local canvas = love.graphics.newCanvas(24 * cell, 18 * cell)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(GRAY.ground)
    love.graphics.setColor(GRAY.road)
    for _, p in ipairs(LEVEL1_PATH) do
        love.graphics.rectangle("fill", (p[1] - 1) * cell, (p[2] - 1) * cell, cell, cell)
    end
    -- Run the road off the left edge so it clearly enters the map there
    love.graphics.rectangle("fill", 0, 0, cell, cell)
    save(canvas, "map_level1_blockout.png")
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
    mapBlockout()
    boxSheet(4, 2, "icon_sheet_8_guide.png")
    buildPrompts(root)
    love.event.quit(0)
end
