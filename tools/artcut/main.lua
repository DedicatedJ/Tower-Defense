-- Cuts generated art into runtime sprites. Run from the repo root.
--
--   lovec tools/artcut info  <in.png>
--       Size, transparency report and bounding box of solid pixels.
--   lovec tools/artcut tower <in.png> <out.png> <width> [alphaFloor]
--       Clear pixels below alphaFloor (default 200, removes soft glow and
--       shadow), trim to the solid shape, scale to <width> px wide.
--
-- Paths may be absolute or relative to the repo root (pass the root's
-- absolute path as the working directory; see art/README.md).
-- Stops with a plain message on bad input instead of writing garbage.

local function fail(msg)
    print("ERROR: " .. msg)
    love.event.quit(1)
    error("stop", 0)
end

local function readImageData(path)
    local f = io.open(path, "rb")
    if not f then fail("cannot open " .. path) end
    local bytes = f:read("*a")
    f:close()
    local ok, data = pcall(love.image.newImageData, love.filesystem.newFileData(bytes, path))
    if not ok then fail("not an image: " .. path .. " (" .. tostring(data) .. ")") end
    return data
end

local function writePng(imageData, path)
    local f = io.open(path, "wb")
    if not f then fail("cannot write " .. path) end
    f:write(imageData:encode("png"):getString())
    f:close()
    print(string.format("wrote %s (%dx%d)", path, imageData:getWidth(), imageData:getHeight()))
end

-- Alpha histogram, corner samples and bounding box of pixels >= floor
local function analyse(data, floor)
    local w, h = data:getDimensions()
    local buckets = {0, 0, 0, 0, 0} -- 0, 1-99, 100-199, 200-254, 255
    local minX, minY, maxX, maxY = w, h, -1, -1
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local _, _, _, a = data:getPixel(x, y)
            local a8 = math.floor(a * 255 + 0.5)
            if a8 == 0 then buckets[1] = buckets[1] + 1
            elseif a8 < 100 then buckets[2] = buckets[2] + 1
            elseif a8 < 200 then buckets[3] = buckets[3] + 1
            elseif a8 < 255 then buckets[4] = buckets[4] + 1
            else buckets[5] = buckets[5] + 1 end
            if a8 >= floor then
                if x < minX then minX = x end
                if x > maxX then maxX = x end
                if y < minY then minY = y end
                if y > maxY then maxY = y end
            end
        end
    end
    return {
        w = w, h = h, buckets = buckets, total = w * h,
        minX = minX, minY = minY, maxX = maxX, maxY = maxY,
    }
end

local function report(path, data, floor)
    local r = analyse(data, floor)
    local function pct(n) return string.format("%.1f%%", n * 100 / r.total) end
    print(string.format("%s: %dx%d", path, r.w, r.h))
    print(string.format("alpha 0: %s | 1-99: %s | 100-199: %s | 200-254: %s | 255: %s",
        pct(r.buckets[1]), pct(r.buckets[2]), pct(r.buckets[3]), pct(r.buckets[4]), pct(r.buckets[5])))
    for _, c in ipairs({{0, 0}, {r.w - 1, 0}, {0, r.h - 1}, {r.w - 1, r.h - 1}}) do
        local cr, cg, cb, ca = data:getPixel(c[1], c[2])
        print(string.format("corner %d,%d rgba %d %d %d %d", c[1], c[2],
            cr * 255, cg * 255, cb * 255, ca * 255))
    end
    if r.maxX >= 0 then
        print(string.format("solid (alpha >= %d) bbox: x %d-%d, y %d-%d (%dx%d)", floor,
            r.minX, r.maxX, r.minY, r.maxY, r.maxX - r.minX + 1, r.maxY - r.minY + 1))
    end
    return r
end

-- Downscale with mipmaps so a 2K source shrinks without aliasing
local function scaled(data, outW, outH)
    local img = love.graphics.newImage(data, { mipmaps = true })
    img:setFilter("linear", "linear")
    img:setMipmapFilter("linear")
    local canvas = love.graphics.newCanvas(outW, outH)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, 0, 0, 0, outW / data:getWidth(), outH / data:getHeight())
    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()
    return canvas:newImageData()
end

local function cutTower(inPath, outPath, width, floor)
    local data = readImageData(inPath)
    local r = report(inPath, data, floor)
    if r.buckets[1] == 0 then
        fail("no transparent pixels: the background is baked in. Regenerate with a transparent " ..
             "background or run Higgsfield's background remover first.")
    end
    if r.maxX < 0 then fail("no pixels at or above alpha " .. floor) end

    -- Clear everything under the floor (glow, soft shadow, specks) and make
    -- the rest fully opaque: GPT Image output tops out just under 255, which
    -- would leave the sprite faintly see-through. Edges soften again when
    -- the image is scaled down.
    data:mapPixel(function(_, _, cr, cg, cb, a)
        if a * 255 < floor then return 0, 0, 0, 0 end
        return cr, cg, cb, 1
    end)

    -- Touching the frame edge usually means the model cropped the object
    local edge = {}
    if r.minX == 0 then edge[#edge + 1] = "left" end
    if r.minY == 0 then edge[#edge + 1] = "top" end
    if r.maxX == r.w - 1 then edge[#edge + 1] = "right" end
    if r.maxY == r.h - 1 then edge[#edge + 1] = "bottom" end
    if #edge > 0 then
        local touching = 0
        local y = r.maxY
        for x = 0, r.w - 1 do
            local _, _, _, a = data:getPixel(x, y)
            if a > 0 then touching = touching + 1 end
        end
        print(string.format("WARNING: solid pixels touch the %s edge (%d px on the bottom row). " ..
            "The object may be cropped.", table.concat(edge, ", "), touching))
    end

    local bw, bh = r.maxX - r.minX + 1, r.maxY - r.minY + 1
    local trimmed = love.image.newImageData(bw, bh)
    trimmed:paste(data, 0, 0, r.minX, r.minY, bw, bh)

    -- Premultiply before scaling so edges do not pick up dark fringes
    trimmed:mapPixel(function(_, _, cr, cg, cb, a) return cr * a, cg * a, cb * a, a end)
    local outW = width
    local outH = math.floor(bh * width / bw + 0.5)
    local out = scaled(trimmed, outW, outH)
    -- Back to straight alpha for the PNG
    out:mapPixel(function(_, _, cr, cg, cb, a)
        if a == 0 then return 0, 0, 0, 0 end
        return cr / a, cg / a, cb / a, a
    end)
    writePng(out, outPath)
end

------------------------------------------------------------------------
-- Backdrops and thumbnails: opaque images, cropped to the target aspect
-- around the center (cover), then scaled.
--   lovec tools/artcut backdrop <in.png> <out.png> <width> <height>
------------------------------------------------------------------------
local function cutBackdrop(inPath, outPath, outW, outH)
    local data = readImageData(inPath)
    local w, h = data:getDimensions()
    print(string.format("%s: %dx%d", inPath, w, h))
    local target = outW / outH
    local cw, ch = w, h
    if w / h > target then cw = math.floor(h * target + 0.5) else ch = math.floor(w / target + 0.5) end
    local cropped = love.image.newImageData(cw, ch)
    cropped:paste(data, 0, 0, math.floor((w - cw) / 2), math.floor((h - ch) / 2), cw, ch)
    if cw ~= w or ch ~= h then
        print(string.format("cropped to %dx%d to match %d:%d", cw, ch, outW, outH))
    end
    -- Opaque: force alpha to 1 so the scaler's blending cannot darken edges
    cropped:mapPixel(function(_, _, r, g, b) return r, g, b, 1 end)
    writePng(scaled(cropped, outW, outH), outPath)
end

------------------------------------------------------------------------
-- Map check: does the painted road sit on the road cells of the blockout?
--   lovec tools/artcut mapcheck <map.png> <blockout.png> <cols> <rows>
-- The map is center-cropped to the blockout's aspect (as the backdrop cut
-- does), split into cols x rows cells, and each cell's middle 60% is
-- classified as earth (brown: red above green, well above blue) or not.
-- Blockout cells darker than mid gray are road. Prints a grid:
--   #  road cell, painted earth      x  road cell, not earth (road missing)
--   .  ground cell, not earth        !  ground cell, painted earth (road misplaced)
------------------------------------------------------------------------
local function mapCheck(mapPath, blockPath, cols, rows)
    local m = readImageData(mapPath)
    local b = readImageData(blockPath)
    local w, h = m:getDimensions()
    local bw, bh = b:getDimensions()
    local target = bw / bh
    local cw, ch = w, h
    if w / h > target then cw = math.floor(h * target + 0.5) else ch = math.floor(w / target + 0.5) end
    local ox, oy = math.floor((w - cw) / 2), math.floor((h - ch) / 2)

    local counts = { hit = 0, miss = 0, stray = 0, ok = 0 }
    local lines = {}
    for gy = 0, rows - 1 do
        local line = {}
        for gx = 0, cols - 1 do
            local br = b:getPixel(math.floor((gx + 0.5) * bw / cols), math.floor((gy + 0.5) * bh / rows))
            local isRoad = br < 0.6
            local x0 = ox + (gx + 0.2) * cw / cols
            local x1 = ox + (gx + 0.8) * cw / cols
            local y0 = oy + (gy + 0.2) * ch / rows
            local y1 = oy + (gy + 0.8) * ch / rows
            local sr, sg, sb, n = 0, 0, 0, 0
            for y = math.floor(y0), math.floor(y1), 3 do
                for x = math.floor(x0), math.floor(x1), 3 do
                    local r, g, bb = m:getPixel(x, y)
                    sr, sg, sb, n = sr + r, sg + g, sb + bb, n + 1
                end
            end
            sr, sg, sb = sr / n, sg / n, sb / n
            -- Earth is clearly redder than green; warm sunlit grass is not
            local earth = (sr - sg) > 0.06 and (sr - sb) > 0.15
            local c
            if isRoad and earth then c = "#"; counts.hit = counts.hit + 1
            elseif isRoad then c = "x"; counts.miss = counts.miss + 1
            elseif earth then c = "!"; counts.stray = counts.stray + 1
            else c = "."; counts.ok = counts.ok + 1 end
            line[#line + 1] = c
        end
        lines[#lines + 1] = table.concat(line)
    end
    print(string.format("%s vs %s (%d x %d cells)", mapPath, blockPath, cols, rows))
    for _, l in ipairs(lines) do print("  " .. l) end
    local roadCells = counts.hit + counts.miss
    print(string.format("road cells painted as road: %d/%d (%.0f%%); ground cells painted as road: %d",
        counts.hit, roadCells, counts.hit * 100 / math.max(1, roadCells), counts.stray))
end

local ffi = require("ffi")

------------------------------------------------------------------------
-- Map fix: line the painted road up with the blockout's grid.
--   lovec tools/artcut mapfix <map.png> <blockout.png> <out.png> <outW> <outH> [cols] [rows]
-- Measures where each straight road run is painted (center of its earth
-- pixels), then stretches the image piecewise in x and in y so every run's
-- center lands on its cell center. Run 'mapcheck' on the result. Stops if
-- any run is more than one cell off, which means it is a different road
-- and needs a new painting, not a nudge.
------------------------------------------------------------------------
local function mapFix(mapPath, blockPath, outPath, outW, outH, cols, rows)
    local m = readImageData(mapPath)
    local b = readImageData(blockPath)
    local w, h = m:getDimensions()
    local bw, bh = b:getDimensions()
    local target = bw / bh
    local cw, ch = w, h
    if w / h > target then cw = math.floor(h * target + 0.5) else ch = math.floor(w / target + 0.5) end
    local src = love.image.newImageData(cw, ch)
    src:paste(m, 0, 0, math.floor((w - cw) / 2), math.floor((h - ch) / 2), cw, ch)
    local sp = ffi.cast("uint8_t*", src:getFFIPointer())
    local cellW, cellH = cw / cols, ch / rows

    local road = {}
    for gy = 0, rows - 1 do
        road[gy] = {}
        for gx = 0, cols - 1 do
            local v = b:getPixel(math.floor((gx + 0.5) * bw / cols), math.floor((gy + 0.5) * bh / rows))
            road[gy][gx] = v < 0.6
        end
    end
    local function isRoad(gx, gy) return road[gy] and road[gy][gx] or false end
    local function earthAt(x, y)
        local i = (y * cw + x) * 4
        local r, g, bb = sp[i], sp[i + 1], sp[i + 2]
        return (r - g) > 15 and (r - bb) > 38 -- same test as mapcheck, in 0-255
    end

    -- Measure straight runs: vertical runs give x knots, horizontal give y
    local function measure(vertical)
        local knots = {}
        local outer = vertical and cols or rows
        for line = 0, outer - 1 do
            local cells = {}
            for k = 0, (vertical and rows or cols) - 1 do
                local gx, gy = vertical and line or k, vertical and k or line
                -- (an explicit if: "c and A or B" falls through to B when A is false)
                local straight
                if vertical then
                    straight = isRoad(gx, gy) and isRoad(gx, gy - 1) and isRoad(gx, gy + 1)
                        and not isRoad(gx - 1, gy) and not isRoad(gx + 1, gy)
                else
                    straight = isRoad(gx, gy) and isRoad(gx - 1, gy) and isRoad(gx + 1, gy)
                        and not isRoad(gx, gy - 1) and not isRoad(gx, gy + 1)
                end
                if straight then cells[#cells + 1] = k end
            end
            if #cells >= 2 then
                local sum, n = 0, 0
                local size = vertical and cellW or cellH
                local lo = math.max(0, math.floor((line - 1.5) * size))
                local hi = math.min((vertical and cw or ch) - 1, math.floor((line + 2.5) * size))
                for _, k in ipairs(cells) do
                    local along = vertical and cellH or cellW
                    for a = math.floor((k + 0.3) * along), math.floor((k + 0.7) * along), 2 do
                        for p = lo, hi do
                            local x, y = vertical and p or a, vertical and a or p
                            if earthAt(x, y) then sum = sum + p; n = n + 1 end
                        end
                    end
                end
                if n > 0 then
                    local expected = (line + 0.5) * size
                    local painted = sum / n
                    local shift = (painted - expected) / size
                    print(string.format("%s run %s %d: painted center %.0f, grid center %.0f (%+.2f cells)",
                        vertical and "vertical" or "horizontal", vertical and "column" or "row",
                        line + 1, painted, expected, shift))
                    if math.abs(shift) > 1 then
                        fail("a road run is more than one cell off; this map needs a new painting")
                    end
                    knots[#knots + 1] = { expected = expected, painted = painted }
                end
            end
        end
        return knots
    end
    local xKnots, yKnots = measure(true), measure(false)

    -- Piecewise-linear map from output position to source position
    local function mapper(knots, size)
        table.sort(knots, function(a, c) return a.expected < c.expected end)
        local pts = { { expected = 0, painted = 0 } }
        for _, k in ipairs(knots) do pts[#pts + 1] = k end
        pts[#pts + 1] = { expected = size - 1, painted = size - 1 }
        for i = 2, #pts do
            if pts[i].painted <= pts[i - 1].painted then fail("road runs measured out of order; check by eye") end
        end
        local lut = ffi.new("float[?]", size)
        local seg = 1
        for o = 0, size - 1 do
            while seg < #pts - 1 and o > pts[seg + 1].expected do seg = seg + 1 end
            local a, c = pts[seg], pts[seg + 1]
            local t = (o - a.expected) / (c.expected - a.expected)
            lut[o] = a.painted + t * (c.painted - a.painted)
        end
        return lut
    end
    local fx, fy = mapper(xKnots, cw), mapper(yKnots, ch)

    -- Bilinear resample into the warped image
    local out = love.image.newImageData(cw, ch)
    local op = ffi.cast("uint8_t*", out:getFFIPointer())
    for y = 0, ch - 1 do
        local sy = math.max(0, math.min(ch - 1.001, fy[y]))
        local y0 = math.floor(sy); local ty = sy - y0
        for x = 0, cw - 1 do
            local sx = math.max(0, math.min(cw - 1.001, fx[x]))
            local x0 = math.floor(sx); local tx = sx - x0
            local i00 = (y0 * cw + x0) * 4
            local i10, i01, i11 = i00 + 4, i00 + cw * 4, i00 + cw * 4 + 4
            local o = (y * cw + x) * 4
            for ch_ = 0, 2 do
                local top = sp[i00 + ch_] + (sp[i10 + ch_] - sp[i00 + ch_]) * tx
                local bot = sp[i01 + ch_] + (sp[i11 + ch_] - sp[i01 + ch_]) * tx
                op[o + ch_] = top + (bot - top) * ty + 0.5
            end
            op[o + 3] = 255
        end
    end
    writePng(scaled(out, outW, outH), outPath)
end

------------------------------------------------------------------------
-- Walk sheets: find figures by shape, not by grid cell.
------------------------------------------------------------------------

-- Label connected solid pixels (alpha >= floor, 4-connected).
-- Returns labels (int32 per pixel, 0 = empty) and a list of components.
local function components(data, floor)
    local w, h = data:getDimensions()
    if data:getFormat() ~= "rgba8" then fail("expected an 8-bit RGBA image, got " .. data:getFormat()) end
    local px = ffi.cast("uint8_t*", data:getFFIPointer())
    local n = w * h
    local labels = ffi.new("int32_t[?]", n)
    local stack = ffi.new("int32_t[?]", n)
    local comps = {}
    for start = 0, n - 1 do
        if labels[start] == 0 and px[start * 4 + 3] >= floor then
            local id = #comps + 1
            local c = { id = id, area = 0, minX = w, minY = h, maxX = -1, maxY = -1 }
            local top = 0
            stack[0] = start
            labels[start] = id
            while top >= 0 do
                local i = stack[top]
                top = top - 1
                local x, y = i % w, (i - i % w) / w
                c.area = c.area + 1
                if x < c.minX then c.minX = x end
                if x > c.maxX then c.maxX = x end
                if y < c.minY then c.minY = y end
                if y > c.maxY then c.maxY = y end
                local function visit(j)
                    if labels[j] == 0 and px[j * 4 + 3] >= floor then
                        labels[j] = id
                        top = top + 1
                        stack[top] = j
                    end
                end
                if x > 0 then visit(i - 1) end
                if x < w - 1 then visit(i + 1) end
                if y > 0 then visit(i - w) end
                if y < h - 1 then visit(i + w) end
            end
            comps[id] = c
        end
    end
    return labels, comps, px
end

local function bboxGap(a, b)
    local dx = math.max(0, math.max(a.minX, b.minX) - math.min(a.maxX, b.maxX))
    local dy = math.max(0, math.max(a.minY, b.minY) - math.min(a.maxY, b.maxY))
    return math.sqrt(dx * dx + dy * dy)
end

------------------------------------------------------------------------
-- Round icons on a sheet (medallions), one PNG per icon.
--   lovec tools/artcut icons <in.png> <outDir> <size> <rows> <cols> <name1,name2,...>
-- If the sheet has no real transparency (a checkerboard or plain light
-- background painted in), the light, colorless background is keyed out
-- first. Each icon is found by shape, cropped square around its disc and
-- masked to a clean circle so no background survives on the rim.
------------------------------------------------------------------------
local function cutIcons(inPath, outDir, size, rows, cols, names)
    local data = readImageData(inPath)
    local r = report(inPath, data, 200)
    local expected = rows * cols
    if #names ~= expected then fail(string.format("%d names for %d icons", #names, expected)) end
    if r.buckets[1] == 0 then
        -- Key out light, colorless pixels (checkerboard or paper white)
        local keyed = 0
        data:mapPixel(function(_, _, cr, cg, cb, a)
            local mx, mn = math.max(cr, cg, cb), math.min(cr, cg, cb)
            if mx > 0.78 and (mx - mn) < 0.07 then keyed = keyed + 1; return cr, cg, cb, 0 end
            return cr, cg, cb, 1
        end)
        print(string.format("no transparency: keyed out %.1f%% light gray background",
            keyed * 100 / (r.w * r.h)))
    end
    local labels, comps = components(data, 200)
    table.sort(comps, function(a, b) return a.area > b.area end)
    if #comps < expected then fail(string.format("found %d shapes, expected %d icons", #comps, expected)) end
    local ref = comps[math.ceil(expected / 2)].area
    local icons = {}
    for _, c in ipairs(comps) do if c.area >= ref * 0.5 then icons[#icons + 1] = c end end
    if #icons ~= expected then
        fail(string.format("found %d icon-sized shapes, expected %d. Check the sheet by eye.", #icons, expected))
    end
    for _, c in ipairs(icons) do c.cx = (c.minX + c.maxX) / 2; c.cy = (c.minY + c.maxY) / 2 end
    table.sort(icons, function(a, b) return a.cy < b.cy end)
    local ordered = {}
    for ri = 1, rows do
        local row = {}
        for ci = 1, cols do row[ci] = icons[(ri - 1) * cols + ci] end
        table.sort(row, function(a, b) return a.cx < b.cx end)
        for _, c in ipairs(row) do ordered[#ordered + 1] = c end
    end
    for i, c in ipairs(ordered) do
        local side = math.max(c.maxX - c.minX, c.maxY - c.minY) + 1
        local x0 = math.floor(c.cx - side / 2 + 0.5)
        local y0 = math.floor(c.cy - side / 2 + 0.5)
        local crop = love.image.newImageData(side, side)
        crop:paste(data, 0, 0, x0, y0, side, side)
        -- Circular mask with a 1.5 px soft edge, premultiplied for scaling
        local rad = side / 2 - 1
        crop:mapPixel(function(x, y, cr, cg, cb)
            local d = math.sqrt((x + 0.5 - side / 2) ^ 2 + (y + 0.5 - side / 2) ^ 2)
            local a = math.max(0, math.min(1, (rad - d) / 1.5 + 0.5))
            return cr * a, cg * a, cb * a, a
        end)
        local out = scaled(crop, size, size)
        out:mapPixel(function(_, _, cr, cg, cb, a)
            if a == 0 then return 0, 0, 0, 0 end
            return cr / a, cg / a, cb / a, a
        end)
        writePng(out, outDir .. "/" .. names[i] .. ".png")
    end
end

-- lovec tools/artcut sheet <in.png> <out.png> <out.lua> <figureHeight> [alphaFloor] [rows] [cols] [feet|mass]
local function cutSheet(inPath, outPng, outMeta, figureH, floor, rows, cols, anchor)
    anchor = anchor or "feet"
    local data = readImageData(inPath)
    local r = report(inPath, data, floor)
    if r.buckets[1] == 0 then
        fail("no transparent pixels: the background is baked in. Regenerate with a transparent " ..
             "background or run Higgsfield's background remover first.")
    end
    local W, H = r.w, r.h
    local expected = rows * cols
    local labels, comps, px = components(data, floor)

    -- Figures: the big shapes. Everything else joins a figure or is a speck.
    table.sort(comps, function(a, b) return a.area > b.area end)
    if #comps < expected then
        fail(string.format("found %d shapes, expected %d figures", #comps, expected))
    end
    local refArea = comps[math.ceil(expected / 2)].area
    local figures, others = {}, {}
    for _, c in ipairs(comps) do
        if c.area >= refArea * 0.25 then figures[#figures + 1] = c else others[#others + 1] = c end
    end
    if #figures ~= expected then
        fail(string.format("found %d figure-sized shapes, expected %d. Check the sheet by eye.",
            #figures, expected))
    end

    -- owner[label] = figure index (by the figure's original label id)
    local owner = {}
    for fi, f in ipairs(figures) do f.parts = { f.id }; owner[f.id] = fi end
    local joined, dropped = 0, 0
    for _, c in ipairs(others) do
        local best, bestGap
        for fi, f in ipairs(figures) do
            local g = bboxGap(c, f)
            if not bestGap or g < bestGap then best, bestGap = fi, g end
        end
        local f = figures[best]
        if c.area >= f.area * 0.0015 and bestGap <= W * 0.03 then
            owner[c.id] = best
            f.parts[#f.parts + 1] = c.id
            f.minX = math.min(f.minX, c.minX); f.maxX = math.max(f.maxX, c.maxX)
            f.minY = math.min(f.minY, c.minY); f.maxY = math.max(f.maxY, c.maxY)
            joined = joined + 1
        else
            dropped = dropped + 1
        end
    end
    print(string.format("figures %d, fragments joined %d, specks dropped %d", #figures, joined, dropped))

    -- Grid order: sort by center y into rows, then by x within a row
    for _, f in ipairs(figures) do f.cy = (f.minY + f.maxY) / 2; f.cx = (f.minX + f.maxX) / 2 end
    table.sort(figures, function(a, b) return a.cy < b.cy end)
    local grid = {}
    for ri = 1, rows do
        local row = {}
        for ci = 1, cols do row[ci] = figures[(ri - 1) * cols + ci] end
        table.sort(row, function(a, b) return a.cx < b.cx end)
        -- A row's figures must overlap vertically, or the sort mixed rows
        for ci = 2, cols do
            if row[ci].minY > row[1].maxY or row[1].minY > row[ci].maxY then
                fail("row " .. ri .. " does not line up; the figures are not in a clean grid")
            end
        end
        grid[ri] = row
    end

    -- Per figure anchor point, the spot that stays still from frame to frame.
    --   feet: x = head center (mean x of the top 18%), y = lowest pixel.
    --         Walkers: the body does not shake as arms swing, feet share a line.
    --   mass: x, y = centroid of all the figure's pixels. Flyers: the lowest
    --         pixel is a wing or tail tip that moves every frame, and with
    --         wings raised the top 18% is wing tips, not the head.
    for _, row in ipairs(grid) do
        for _, f in ipairs(row) do
            f.partSet = {}
            for _, id in ipairs(f.parts) do f.partSet[id] = true end
            f.height = f.maxY - f.minY + 1
            if anchor == "mass" then
                local sx, sy, count = 0, 0, 0
                for y = f.minY, f.maxY do
                    for x = f.minX, f.maxX do
                        if f.partSet[labels[y * W + x]] then sx = sx + x; sy = sy + y; count = count + 1 end
                    end
                end
                f.anchorX, f.anchorY = sx / count, sy / count
            else
                local headBottom = f.minY + math.floor((f.maxY - f.minY) * 0.18)
                local sum, count = 0, 0
                for y = f.minY, headBottom do
                    for x = f.minX, f.maxX do
                        if f.partSet[labels[y * W + x]] then sum = sum + x; count = count + 1 end
                    end
                end
                f.anchorX = count > 0 and sum / count or f.cx
                f.anchorY = f.maxY + 1
            end
        end
    end

    -- Common frame: every figure's anchor at the same spot in its frame
    local halfW, up, down, maxH = 0, 0, 0, 0
    for _, row in ipairs(grid) do
        for _, f in ipairs(row) do
            halfW = math.max(halfW, f.anchorX - f.minX, f.maxX + 1 - f.anchorX)
            up = math.max(up, f.anchorY - f.minY)
            down = math.max(down, f.maxY + 1 - f.anchorY)
            maxH = math.max(maxH, f.height)
        end
    end
    local pad = math.ceil(maxH * 0.04)
    local fw = math.ceil(halfW * 2) + pad * 2
    local fh = math.ceil(up + down) + pad * 2
    local anchorInFrameY = pad + up
    local sheet = love.image.newImageData(fw * cols, fh * rows)
    for ri, row in ipairs(grid) do
        for ci, f in ipairs(row) do
            local ox = (ci - 1) * fw + math.floor(fw / 2 - f.anchorX + 0.5)
            local oy = (ri - 1) * fh + math.floor(anchorInFrameY - f.anchorY + 0.5)
            for y = f.minY, f.maxY do
                for x = f.minX, f.maxX do
                    local i = y * W + x
                    if f.partSet[labels[i]] then
                        local o = i * 4
                        sheet:setPixel(ox + x, oy + y, px[o] / 255, px[o + 1] / 255, px[o + 2] / 255, 1)
                    end
                end
            end
        end
    end

    -- Height report per row (standing frame) and overall spread
    local hmin, hmax = math.huge, 0
    for ri, row in ipairs(grid) do
        local hs = {}
        for ci, f in ipairs(row) do
            hs[#hs + 1] = f.height
            hmin = math.min(hmin, f.height); hmax = math.max(hmax, f.height)
        end
        print(string.format("row %d heights: %s", ri, table.concat(hs, ", ")))
    end
    print(string.format("height spread across all frames: %.1f%%", (hmax - hmin) * 100 / hmax))

    -- Scale so the tallest figure is figureH pixels
    local s = figureH / maxH
    local outFw, outFh = math.floor(fw * s + 0.5), math.floor(fh * s + 0.5)
    sheet:mapPixel(function(_, _, cr, cg, cb, a) return cr * a, cg * a, cb * a, a end)
    local out = scaled(sheet, outFw * cols, outFh * rows)
    out:mapPixel(function(_, _, cr, cg, cb, a)
        if a == 0 then return 0, 0, 0, 0 end
        return cr / a, cg / a, cb / a, a
    end)
    writePng(out, outPng)

    local meta = string.format(
        "-- Generated by tools/artcut from %s. Do not edit; re-run the cutter.\n" ..
        "return {\n    frameW = %d,\n    frameH = %d,\n    cols = %d,\n    rows = %d,\n" ..
        "    -- anchor: \"feet\" (feet baseline, head center line) or \"mass\" (body centroid)\n" ..
        "    anchor = %q,\n" ..
        "    -- anchor point inside each frame, and the highest figure top, in pixels\n" ..
        "    footX = %d,\n    footY = %d,\n    topY = %d,\n    figureH = %d,\n" ..
        "    rowFacing = { \"toward\", \"right\", \"left\", \"away\" },\n}\n",
        inPath:match("[^/\\]+$"), outFw, outFh, cols, rows, anchor,
        math.floor(outFw / 2 + 0.5), math.floor(anchorInFrameY * s + 0.5),
        math.floor(pad * s + 0.5), figureH)
    local f = io.open(outMeta, "wb")
    if not f then fail("cannot write " .. outMeta) end
    f:write(meta)
    f:close()
    print("wrote " .. outMeta)
end

function love.load(args)
    local cmd = args[1]
    local ok, err = pcall(function()
        if cmd == "info" then
            report(args[2], readImageData(args[2]), tonumber(args[3]) or 200)
        elseif cmd == "tower" then
            cutTower(args[2], args[3], tonumber(args[4]) or 96, tonumber(args[5]) or 200)
        elseif cmd == "icons" then
            local names = {}
            for n in (args[7] or ""):gmatch("[^,]+") do names[#names + 1] = n end
            cutIcons(args[2], args[3], tonumber(args[4]) or 128, tonumber(args[5]) or 2,
                tonumber(args[6]) or 4, names)
        elseif cmd == "mapfix" then
            mapFix(args[2], args[3], args[4], tonumber(args[5]) or 1536, tonumber(args[6]) or 1152,
                tonumber(args[7]) or 24, tonumber(args[8]) or 18)
        elseif cmd == "mapcheck" then
            mapCheck(args[2], args[3], tonumber(args[4]) or 24, tonumber(args[5]) or 18)
        elseif cmd == "backdrop" then
            cutBackdrop(args[2], args[3], tonumber(args[4]) or 1280, tonumber(args[5]) or 960)
        elseif cmd == "sheet" then
            local anchor = args[9] or "feet"
            if anchor ~= "feet" and anchor ~= "mass" then fail("anchor must be feet or mass") end
            cutSheet(args[2], args[3], args[4], tonumber(args[5]) or 96, tonumber(args[6]) or 200,
                tonumber(args[7]) or 4, tonumber(args[8]) or 3, anchor)
        else
            fail("usage: info <in> | tower <in> <out> <width> [alphaFloor]" ..
                 " | backdrop <in> <out.png> <w> <h> | sheet <in> <out.png> <out.lua> <figureHeight> [alphaFloor] [rows] [cols] [feet|mass]")
        end
    end)
    if not ok and err ~= "stop" then print("ERROR: " .. tostring(err)) love.event.quit(1) return end
    love.event.quit(0)
end
