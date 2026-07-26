-- Utility functions for the game
local utils = {}

-- Calculate distance between two points
function utils.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- Check if a point is inside a circle
function utils.pointInCircle(px, py, cx, cy, radius)
    return utils.distance(px, py, cx, cy) <= radius
end

-- Clamp a value between min and max
function utils.clamp(value, min, max)
    return math.max(min, math.min(value, max))
end

-- Linear interpolation between two values
function utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Normalize vector for diagonal movement
function utils.normalizeVector(vx, vy, speed)
    if vx == 0 and vy == 0 then return 0, 0 end
    local length = math.sqrt(vx * vx + vy * vy)
    return (vx / length) * speed, (vy / length) * speed
end

-- Clamp camera position to stay within map boundaries
function utils.clampCamera(cam, mapW, mapH, vw, vh)
    local halfVW, halfVH = vw / 2, vh / 2
    if cam.x < halfVW then cam.x = halfVW end
    if cam.y < halfVH then cam.y = halfVH end
    if vw < mapW and cam.x > mapW - halfVW then cam.x = mapW - halfVW end
    if vh < mapH and cam.y > mapH - halfVH then cam.y = mapH - halfVH end
end

--- Get objects from a named object layer
-- Returns a table of {x, y, width, height, properties} for each object
function utils.getObjectPositions(map, layerName)
    local layer = map.layers[layerName]
    if not layer or not layer.objects then return {} end
    local objects = {}
    for _, obj in ipairs(layer.objects) do
        table.insert(objects, { x = obj.x, y = obj.y, width = obj.width, height = obj.height, properties = obj.properties })
    end
    return objects
end

-- Color utilities
utils.colors = {
    -- Basic colors
    white = { 1, 1, 1 },
    black = { 0, 0, 0 },
    red = { 1, 0, 0 },
    green = { 0, 1, 0 },
    blue = { 0, 0, 1 },
    yellow = { 1, 1, 0 },
    cyan = { 0, 1, 1 },
    magenta = { 1, 0, 1 },

    -- Create a color with alpha
    withAlpha = function(color, alpha)
        return { color[1], color[2], color[3], alpha }
    end,

    -- Blend two colors
    blend = function(color1, color2, factor)
        return {
            utils.lerp(color1[1], color2[1], factor),
            utils.lerp(color1[2], color2[2], factor),
            utils.lerp(color1[3], color2[3], factor),
            utils.lerp(color1[4] or 1, color2[4] or 1, factor)
        }
    end
}

-- Return the module
return utils
