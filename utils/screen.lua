-- Fixed-size virtual screen. Every screen is laid out for 1024 x 768;
-- this draws each frame into a canvas of that size and scales it to fit the
-- window (fullscreen, resized, or a 16:9 monitor), with bars where the shapes
-- differ. The mouse is mapped back to virtual coordinates.
--
--   Screen.install()   once at load: makes love.graphics.getWidth/Height/
--                      Dimensions report the virtual size and love.mouse
--                      getPosition/getX/getY/setPosition use virtual coords
--   Screen.begin()     at the start of love.draw
--   Screen.finish()    at the end of love.draw
--   Screen.toVirtual(x, y)  window pixel -> virtual (for event callbacks)
--
-- At exactly 1024 x 768 the mapping is the identity.

local Screen = { W = 1024, H = 768, scale = 1, ox = 0, oy = 0 }

local raw = {}

function Screen.update()
    local w, h = raw.getDimensions()
    local s = math.min(w / Screen.W, h / Screen.H)
    Screen.scale = s
    Screen.ox = math.floor((w - Screen.W * s) / 2 + 0.5)
    Screen.oy = math.floor((h - Screen.H * s) / 2 + 0.5)
end

function Screen.toVirtual(x, y)
    return (x - Screen.ox) / Screen.scale, (y - Screen.oy) / Screen.scale
end

function Screen.toWindow(x, y)
    return Screen.ox + x * Screen.scale, Screen.oy + y * Screen.scale
end

function Screen.install()
    if Screen.installed then return end
    Screen.installed = true
    raw.getWidth, raw.getHeight, raw.getDimensions =
        love.graphics.getWidth, love.graphics.getHeight, love.graphics.getDimensions
    raw.getPosition, raw.setPosition = love.mouse.getPosition, love.mouse.setPosition

    Screen.canvas = love.graphics.newCanvas(Screen.W, Screen.H)
    Screen.canvas:setFilter("linear", "linear")
    Screen.update()

    love.graphics.getWidth = function() return Screen.W end
    love.graphics.getHeight = function() return Screen.H end
    love.graphics.getDimensions = function() return Screen.W, Screen.H end
    love.mouse.getPosition = function() return Screen.toVirtual(raw.getPosition()) end
    love.mouse.getX = function() return (Screen.toVirtual(raw.getPosition())) end
    love.mouse.getY = function() local _, y = Screen.toVirtual(raw.getPosition()); return y end
    love.mouse.setPosition = function(x, y) raw.setPosition(Screen.toWindow(x, y)) end
end

function Screen.begin()
    Screen.update()
    love.graphics.setCanvas(Screen.canvas)
    love.graphics.clear(0, 0, 0, 1)
end

function Screen.finish()
    love.graphics.setCanvas()
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(Screen.canvas, Screen.ox, Screen.oy, 0, Screen.scale, Screen.scale)
    love.graphics.setBlendMode("alpha")
end

return Screen
