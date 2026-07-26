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
function love.graphics.circle(mode, x, y, radius)
    table.insert(love.graphics._circles, { mode = mode, x = x, y = y, radius = radius })
end
function love.graphics.printf(text, x, y, limit, align)
    table.insert(love.graphics._printfCalls, { text = text, x = x, y = y, limit = limit, align = align })
end
function love.graphics.polygon(mode, x1, y1, x2, y2, x3, y3)
    table.insert(love.graphics._polygons, { mode = mode, x1 = x1, y1 = y1, x2 = x2, y2 = y2, x3 = x3, y3 = y3 })
end
love.graphics._circles = {}
love.graphics._printfCalls = {}
love.graphics._polygons = {}
function love.graphics.getFont()
    return {
        getHeight = function() return 14 end,
        getWrap = function(_, text, maxWidth) return maxWidth, { text } end,
    }
end
function love.graphics.getColor()
    return 1, 1, 1, 1
end
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

-- math mock
love.math = {}
function love.math.random()
    return 0.5
end
love.math._randomValues = {}
function love.math._setRandomSequence(values)
    love.math._randomValues = values
    love.math._randomIndex = 1
end
-- Override random to support a deterministic sequence when set
local _originalRandom = love.math.random
function love.math.random()
    if #love.math._randomValues > 0 then
        local idx = love.math._randomIndex
        if love.math._randomValues[idx] ~= nil then
            love.math._randomIndex = idx + 1
            return love.math._randomValues[idx]
        end
    end
    return _originalRandom()
end

-- event mock
love.event = {}
function love.event.quit() end

-- system mock (for os detections etc)
love.system = {}

_G.love = love

return love