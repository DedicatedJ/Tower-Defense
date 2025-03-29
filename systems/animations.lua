-- Animation system for managing sprite animations
local Timer = require("libs.hump.timer")

local Animations = {}

-- Create a new animation from a spritesheet
-- Parameters:
-- spritesheet: The image containing all animation frames
-- frameWidth: Width of each frame
-- frameHeight: Height of each frame
-- frames: Table of frame indices to use
-- speed: Time between frames in seconds
-- loop: Whether the animation should loop (default: true)
function Animations.newAnimation(spritesheet, frameWidth, frameHeight, frames, speed, loop)
    local anim = {
        spritesheet = spritesheet,
        frameWidth = frameWidth,
        frameHeight = frameHeight,
        frames = frames or {},
        speed = speed or 0.1,
        timer = 0,
        currentFrame = 1,
        loop = loop ~= false, -- Default to true if not specified
        paused = false,
        finished = false,
        quads = {}
    }
    
    -- Create quads for each frame
    for i, frameIndex in ipairs(frames) do
        local row = math.floor((frameIndex-1) / math.floor(spritesheet:getWidth() / frameWidth))
        local col = (frameIndex-1) % math.floor(spritesheet:getWidth() / frameWidth)
        
        anim.quads[i] = love.graphics.newQuad(
            col * frameWidth, row * frameHeight,
            frameWidth, frameHeight,
            spritesheet:getDimensions()
        )
    end
    
    -- Update the animation
    anim.update = function(self, dt)
        if self.paused or self.finished then return end
        
        self.timer = self.timer + dt
        
        if self.timer >= self.speed then
            self.timer = self.timer - self.speed
            self.currentFrame = self.currentFrame + 1
            
            if self.currentFrame > #self.frames then
                if self.loop then
                    self.currentFrame = 1
                else
                    self.currentFrame = #self.frames
                    self.finished = true
                end
            end
        end
    end
    
    -- Draw the current frame
    anim.draw = function(self, x, y, r, sx, sy, ox, oy)
        if #self.quads == 0 then return end
        
        love.graphics.draw(
            self.spritesheet,
            self.quads[self.currentFrame],
            x, y, r or 0, sx or 1, sy or 1, 
            ox or 0, oy or 0
        )
    end
    
    -- Pause the animation
    anim.pause = function(self)
        self.paused = true
    end
    
    -- Resume the animation
    anim.resume = function(self)
        self.paused = false
    end
    
    -- Reset the animation to the first frame
    anim.reset = function(self)
        self.currentFrame = 1
        self.timer = 0
        self.finished = false
    end
    
    -- Check if the animation has finished (only relevant if loop=false)
    anim.isFinished = function(self)
        return self.finished
    end
    
    -- Set the animation to a specific frame
    anim.setFrame = function(self, frameNumber)
        self.currentFrame = math.min(math.max(1, frameNumber), #self.frames)
    end
    
    return anim
end

-- Create a placeholder animation when sprites are missing
function Animations.createPlaceholderAnimation(color, size, frameCount)
    size = size or 32
    frameCount = frameCount or 4
    color = color or {1, 0, 1} -- Default to magenta for visibility
    
    -- Create a canvas for the placeholder
    local canvas = love.graphics.newCanvas(size * frameCount, size)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Draw different frames
    for i = 1, frameCount do
        local x = (i-1) * size
        -- Frame background
        love.graphics.setColor(color[1], color[2], color[3], 0.8)
        love.graphics.rectangle("fill", x, 0, size, size)
        
        -- Frame border
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", x, 0, size, size)
        
        -- Animation indicator (a rotating line)
        local angle = (i-1) * (math.pi / 2)
        local cx, cy = x + size/2, size/2
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(
            cx, cy,
            cx + math.cos(angle) * (size/3),
            cy + math.sin(angle) * (size/3)
        )
    end
    
    love.graphics.setCanvas()
    
    -- Create frames table
    local frames = {}
    for i = 1, frameCount do
        frames[i] = i
    end
    
    -- Create the animation
    return Animations.newAnimation(canvas, size, size, frames, 0.2, true)
end

-- Parse a spritesheet and create animations from it
function Animations.parseFromSpritesheet(spritesheetPath, frameWidth, frameHeight, animations)
    local results = {}
    local success, spritesheet
    
    -- Try to load the spritesheet
    success, spritesheet = pcall(love.graphics.newImage, spritesheetPath)
    
    -- If failed, create placeholder animations
    if not success then
        for name, animData in pairs(animations) do
            results[name] = Animations.createPlaceholderAnimation(
                animData.color or {1, 0, 1},
                frameWidth,
                #animData.frames
            )
        end
        return results
    end
    
    -- Create animations from the sheet
    for name, animData in pairs(animations) do
        results[name] = Animations.newAnimation(
            spritesheet,
            frameWidth,
            frameHeight,
            animData.frames,
            animData.speed,
            animData.loop
        )
    end
    
    return results
end

return Animations 