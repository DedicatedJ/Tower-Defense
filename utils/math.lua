local Math = {}

function Math.dist(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function Math.lerp(a, b, t)
    return a + t * (b - a)
end

function Math.clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

function Math.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

return Math 