-- Roads in pixels. A road is a center line (a polyline whose corners are
-- rounded into arcs, so its sideways direction turns smoothly) with a
-- width. Enemies walk it by distance travelled, each at its own sideways
-- offset, so a wide road carries several abreast.
--
--   Path.new(pieces, width)   pieces: lists of {x, y} points in pixels; a
--                             new piece starts after a portal (enemies
--                             vanish at the end of one piece and reappear
--                             at the start of the next, with no distance
--                             between)
--   path:length()
--   path:pointAt(s)           x, y, nx, ny, dx, dy: position s pixels along,
--                             the unit normal (to the left of travel) and the
--                             unit direction of travel
--   path:nearest(x, y)        s, distance from the center line, cx, cy (the
--                             nearest center-line point)
--
--   Path.Nav.new(isWalkable, w, h, cell)   a walk grid over a w x h area
--   nav:route(x1, y1, x2, y2)              list of {x, y} points from the
--                                          first point to the second, or nil

local Path = {}
Path.__index = Path

Path.CORNER = 0.75   -- corner radius as a fraction of the road width
Path.STEP = 6        -- arc sampling, pixels

local sqrt, atan2, cos, sin, abs = math.sqrt, math.atan2, math.cos, math.sin, math.abs

local function norm(x, y)
    local l = sqrt(x * x + y * y)
    if l == 0 then return 0, 0, 0 end
    return x / l, y / l, l
end

-- One piece: corner points to a dense list of samples with rounded corners
local function samplePiece(pts, radius)
    local out = {}
    local function add(x, y)
        local last = out[#out]
        if not last or abs(last[1] - x) > 1e-6 or abs(last[2] - y) > 1e-6 then
            out[#out + 1] = { x, y }
        end
    end
    local n = #pts
    if n == 0 then return out end
    add(pts[1][1], pts[1][2])
    if n == 1 then return out end
    -- How much of each segment a corner may use: half of it, so two corners
    -- on one segment never overlap
    local segLen = {}
    for i = 1, n - 1 do
        local _, _, l = norm(pts[i + 1][1] - pts[i][1], pts[i + 1][2] - pts[i][2])
        segLen[i] = l
    end
    for i = 2, n - 1 do
        local a, b, c = pts[i - 1], pts[i], pts[i + 1]
        local u1x, u1y = norm(b[1] - a[1], b[2] - a[2])
        local u2x, u2y = norm(c[1] - b[1], c[2] - b[2])
        local cross = u1x * u2y - u1y * u2x
        local dot = u1x * u2x + u1y * u2y
        local theta = atan2(abs(cross), dot) -- turn angle, 0..pi
        if theta < 1e-3 then
            add(b[1], b[2])
        else
            local t = radius * math.tan(theta / 2)
            local tmax = math.min(segLen[i - 1], segLen[i]) / 2
            if t > tmax then t = tmax end
            local r = t / math.tan(theta / 2)
            local p1x, p1y = b[1] - u1x * t, b[2] - u1y * t
            local p2x, p2y = b[1] + u2x * t, b[2] + u2y * t
            -- Center of the arc: to the inside of the turn from p1
            local nx, ny
            if cross > 0 then nx, ny = -u1y, u1x else nx, ny = u1y, -u1x end
            local cx, cy = p1x + nx * r, p1y + ny * r
            local a0 = atan2(p1y - cy, p1x - cx)
            local a1 = atan2(p2y - cy, p2x - cx)
            local sweep = a1 - a0
            if cross > 0 then
                while sweep < 0 do sweep = sweep + 2 * math.pi end
            else
                while sweep > 0 do sweep = sweep - 2 * math.pi end
            end
            local steps = math.max(2, math.ceil(abs(sweep) * r / Path.STEP))
            add(p1x, p1y)
            for k = 1, steps - 1 do
                local ang = a0 + sweep * k / steps
                add(cx + cos(ang) * r, cy + sin(ang) * r)
            end
            add(p2x, p2y)
        end
    end
    add(pts[n][1], pts[n][2])
    return out
end

function Path.new(pieces, width)
    local self = setmetatable({ width = width, xs = {}, ys = {}, ss = {}, breaks = {}, pieces = {} }, Path)
    local radius = width * Path.CORNER
    local s = 0
    for pi, piece in ipairs(pieces) do
        local samples = samplePiece(piece, radius)
        self.pieces[pi] = samples
        for k, p in ipairs(samples) do
            local i = #self.xs + 1
            if k > 1 then
                local px, py = self.xs[i - 1], self.ys[i - 1]
                s = s + sqrt((p[1] - px) ^ 2 + (p[2] - py) ^ 2)
            elseif i > 1 then
                -- A portal: the next piece starts at the same distance
                self.breaks[i - 1] = true
            end
            self.xs[i], self.ys[i], self.ss[i] = p[1], p[2], s
        end
    end
    self.total = s
    return self
end

function Path:length() return self.total end

-- Index i with ss[i] <= s < ss[i+1] on a real segment (not a portal jump)
function Path:segmentAt(s)
    local ss, n = self.ss, #self.ss
    if s <= 0 then
        local i = 1
        while i < n - 1 and (self.breaks[i] or ss[i + 1] == ss[i]) do i = i + 1 end
        return i
    end
    local lo, hi = 1, n - 1
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if ss[mid] <= s then lo = mid else hi = mid - 1 end
    end
    local i = lo
    -- Step past portal jumps and zero-length joins
    while i < n - 1 and (self.breaks[i] or ss[i + 1] <= ss[i]) do i = i + 1 end
    while i > 1 and (self.breaks[i] or ss[i + 1] <= ss[i]) do i = i - 1 end
    return i
end

function Path:pointAt(s)
    local n = #self.xs
    if n == 1 then return self.xs[1], self.ys[1], 0, -1, 1, 0 end
    if s > self.total then s = self.total end
    local i = self:segmentAt(s)
    local x1, y1, x2, y2 = self.xs[i], self.ys[i], self.xs[i + 1], self.ys[i + 1]
    local dx, dy, l = norm(x2 - x1, y2 - y1)
    local f = l > 0 and math.max(0, math.min(1, (s - self.ss[i]) / l)) or 0
    return x1 + (x2 - x1) * f, y1 + (y2 - y1) * f, dy, -dx, dx, dy
end

-- Which piece (1-based) distance s falls in
function Path:pieceAt(s)
    local i = self:segmentAt(s)
    local piece = 1
    for b in pairs(self.breaks) do
        if b <= i then piece = piece + 1 end
    end
    return piece
end

function Path:nearest(x, y)
    local bestD2, bestS, bx, by
    local xs, ys, ss = self.xs, self.ys, self.ss
    for i = 1, #xs - 1 do
        if not self.breaks[i] then
            local x1, y1 = xs[i], ys[i]
            local vx, vy = xs[i + 1] - x1, ys[i + 1] - y1
            local l2 = vx * vx + vy * vy
            local f = 0
            if l2 > 0 then f = math.max(0, math.min(1, ((x - x1) * vx + (y - y1) * vy) / l2)) end
            local px, py = x1 + vx * f, y1 + vy * f
            local d2 = (x - px) ^ 2 + (y - py) ^ 2
            if not bestD2 or d2 < bestD2 then
                bestD2, bx, by = d2, px, py
                bestS = ss[i] + (ss[i + 1] - ss[i]) * f
            end
        end
    end
    if not bestD2 then return 0, sqrt((x - xs[1]) ^ 2 + (y - ys[1]) ^ 2), xs[1], ys[1] end
    return bestS, sqrt(bestD2), bx, by
end

-- Portal jumps as {from = {x, y}, to = {x, y}}
function Path:portals()
    local out = {}
    for i in pairs(self.breaks) do
        out[#out + 1] = { from = { self.xs[i], self.ys[i] }, to = { self.xs[i + 1], self.ys[i + 1] } }
    end
    return out
end

------------------------------------------------------------------------
-- Walk grid: breadth-first search over small cells, then the route is
-- straightened (a point is skipped when the straight line past it stays
-- on walkable cells)
------------------------------------------------------------------------
local Nav = {}
Nav.__index = Nav
Path.Nav = Nav

function Nav.new(isWalkable, w, h, cell)
    local self = setmetatable({ cell = cell, cols = math.ceil(w / cell), rows = math.ceil(h / cell), ok = {} }, Nav)
    for gy = 1, self.rows do
        local row = {}
        for gx = 1, self.cols do
            row[gx] = isWalkable((gx - 0.5) * cell, (gy - 0.5) * cell) and true or false
        end
        self.ok[gy] = row
    end
    return self
end

function Nav:cellOf(x, y)
    return math.floor(x / self.cell) + 1, math.floor(y / self.cell) + 1
end

function Nav:walkable(gx, gy)
    local row = self.ok[gy]
    return row and row[gx] or false
end

-- Nearest walkable cell to a cell (small spiral search)
function Nav:snap(gx, gy)
    if self:walkable(gx, gy) then return gx, gy end
    for r = 1, 6 do
        local best, bd
        for dy = -r, r do
            for dx = -r, r do
                if self:walkable(gx + dx, gy + dy) then
                    local d = dx * dx + dy * dy
                    if not bd or d < bd then best, bd = { gx + dx, gy + dy }, d end
                end
            end
        end
        if best then return best[1], best[2] end
    end
end

-- Whether the straight line between two points stays on walkable cells
function Nav:clear(x1, y1, x2, y2)
    local d = sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    local steps = math.max(1, math.ceil(d / (self.cell / 2)))
    for k = 0, steps do
        local f = k / steps
        if not self:walkable(self:cellOf(x1 + (x2 - x1) * f, y1 + (y2 - y1) * f)) then return false end
    end
    return true
end

function Nav:route(x1, y1, x2, y2)
    local sx, sy = self:snap(self:cellOf(x1, y1))
    local tx, ty = self:snap(self:cellOf(x2, y2))
    if not sx or not tx then return nil end
    local cols = self.cols
    local function key(gx, gy) return (gy - 1) * cols + gx end
    local start, goal = key(sx, sy), key(tx, ty)
    local parent = { [start] = 0 }
    local queue, head = { start }, 1
    local found = start == goal
    while head <= #queue and not found do
        local k = queue[head]
        head = head + 1
        local gx, gy = (k - 1) % cols + 1, math.floor((k - 1) / cols) + 1
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
            local nx, ny = gx + d[1], gy + d[2]
            -- Diagonal steps only where both side cells are open (no corner cutting)
            if self:walkable(nx, ny) and (d[1] == 0 or d[2] == 0
                or (self:walkable(gx + d[1], gy) and self:walkable(gx, gy + d[2]))) then
                local nk = key(nx, ny)
                if not parent[nk] then
                    parent[nk] = k
                    queue[#queue + 1] = nk
                    if nk == goal then found = true; break end
                end
            end
        end
    end
    if not found then return nil end
    local cells = {}
    local k = goal
    while k ~= 0 do
        table.insert(cells, 1, k)
        k = parent[k]
    end
    local pts = { { x1, y1 } }
    for i = 2, #cells - 1 do
        local c = cells[i]
        pts[#pts + 1] = { ((c - 1) % cols + 0.5) * self.cell, (math.floor((c - 1) / cols) + 0.5) * self.cell }
    end
    pts[#pts + 1] = { x2, y2 }
    -- Straighten
    local out = { pts[1] }
    local i = 1
    while i < #pts do
        local j = #pts
        while j > i + 1 and not self:clear(pts[i][1], pts[i][2], pts[j][1], pts[j][2]) do j = j - 1 end
        out[#out + 1] = pts[j]
        i = j
    end
    return out
end

return Path
