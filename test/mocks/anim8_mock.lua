-- Mock for libraries/anim8.lua

local anim8 = {}

function anim8.newGrid(frameWidth, frameHeight, imageWidth, imageHeight)
    local grid = {
        frameWidth = frameWidth,
        frameHeight = frameHeight,
        imageWidth = imageWidth,
        imageHeight = imageHeight,
    }
    -- grid() callable: returns frames
    setmetatable(grid, {
        __call = function(self, cols, row)
            -- returns a list of frames; for tests just return a dummy table
            return { cols = cols, row = row }
        end
    })
    return grid
end

function anim8.newAnimation(frames, duration)
    local anim = {
        frames = frames,
        duration = duration,
    }
    anim._currentFrame = 1
    anim._elapsed = 0

    function anim:update(dt)
        anim._elapsed = anim._elapsed + dt
    end

    function anim:gotoFrame(n)
        anim._currentFrame = n
    end

    function anim:draw(spriteSheet, x, y, rotation, sx, sy, ox, oy)
        -- no-op for tests
    end

    return anim
end

return anim8