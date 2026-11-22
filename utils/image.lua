-- Images that scale down smoothly. Mipmaps where the GPU allows them;
-- WebGL 1 (the browser build) cannot mipmap a texture whose sides are not
-- powers of two, so those get plain linear filtering instead of failing.
--
--   Image.smooth(src)   src: a file path or ImageData. Errors like
--                       love.graphics.newImage when the file cannot load.

local Image = {}

local function isPowerOfTwo(n)
    local p = 1
    while p < n do p = p * 2 end
    return p == n
end

-- Whether a w x h texture can have mipmaps on this GPU
function Image.canMipmap(w, h)
    local supported = love.graphics.getSupported()
    if supported.fullnpot then return true end
    return isPowerOfTwo(w) and isPowerOfTwo(h)
end

function Image.smooth(src)
    if not love.graphics.getSupported().fullnpot then
        local data = type(src) == "string" and love.image.newImageData(src) or src
        if not Image.canMipmap(data:getDimensions()) then
            local img = love.graphics.newImage(data)
            img:setFilter("linear", "linear")
            return img
        end
        src = data
    end
    local img = love.graphics.newImage(src, { mipmaps = true })
    img:setFilter("linear", "linear")
    img:setMipmapFilter("linear")
    return img
end

return Image
