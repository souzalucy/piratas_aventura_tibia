-- Mock love global for unit testing modules that depend on Löve2D APIs.
-- Import this in spec/init.lua before any source modules are loaded.

local love = {}

-- graphics mock
love.graphics = {}
function love.graphics.newImage(path)
    local img = {
        path = path,
        width = 64,
        height = 64,
        getWidth = function(self) return self.width end,
        getHeight = function(self) return self.height end,
    }
    return img
end

function love.graphics.setColor(r, g, b, a)
    -- Handle the case where setColor is called with a table as the first argument
    -- (e.g., setColor({1, 1, 1, 1}))
    if type(r) == "table" then
        love.graphics._lastColor = { r[1] or 1, r[2] or 1, r[3] or 1, r[4] or 1 }
    else
        love.graphics._lastColor = { r, g, b, a }
    end
end
function love.graphics.push() end
function love.graphics.pop() end
function love.graphics.translate(x, y) end
function love.graphics.rotate(a) end
function love.graphics.scale(sx, sy) end
function love.graphics.rectangle(mode, x, y, w, h)
    love.graphics._lastRect = { mode = mode, x = x, y = y, w = w, h = h }
end
function love.graphics.print(text, x, y)
    table.insert(love.graphics._prints, { text = text, x = x, y = y })
end
love.graphics._prints = {}
love.graphics._lastColor = nil
love.graphics._lastRect = nil

function love.graphics.setNewFont(size) end
function love.graphics.setDefaultFilter(min, mag) end
function love.graphics.setBackgroundColor(r, g, b) end
function love.graphics.getWidth()
    return 800
end
function love.graphics.getHeight()
    return 600
end
function love.graphics.getDimensions()
    return 800, 600
end
function love.graphics.getStats()
    return { drawcalls = 0 }
end

-- keyboard mock
love.keyboard = {}
love.keyboard._down = {}
function love.keyboard.isDown(key)
    return love.keyboard._down[key] or false
end
function love.keyboard._simulateDown(key)
    love.keyboard._down[key] = true
end
function love.keyboard._simulateUp(key)
    love.keyboard._down[key] = nil
end
function love.keyboard._reset()
    love.keyboard._down = {}
end

-- timer mock
love.timer = {}
function love.timer.getFPS()
    return 60
end

-- event mock
love.event = {}
function love.event.quit() end

-- system mock (for os detections etc)
love.system = {}

_G.love = love

return love