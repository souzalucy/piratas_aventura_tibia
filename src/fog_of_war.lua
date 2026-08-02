local FoW = {}
local debug_helpers = require("src.debug_helpers")

-- Track FoW state per visibility grid to avoid per-frame log spam
local fowState = setmetatable({}, { __mode = "k" })

function FoW.init(gridCols, gridRows)
    debug_helpers.log(string.format("FoW.init() grid %dx%d", gridCols, gridRows), "DEBUG")
    local visibility = {}
    for col = 1, gridCols do
        visibility[col] = {}
        for row = 1, gridRows do
            visibility[col][row] = 0
        end
    end
    return visibility
end

function FoW.update(visibility, px, py, viewRadius, tileW, tileH, gridCols, gridRows)
    -- demote visible → explored
    local demotedCount = 0
    for col = 1, gridCols do
        local colData = visibility[col]
        for row = 1, gridRows do
            if colData[row] == 2 then
                colData[row] = 1
                demotedCount = demotedCount + 1
            end
        end
    end
    -- mark new visible tiles
    local viewRadiusTiles = math.ceil(viewRadius / tileW)
    local playerCol = math.floor(px / tileW) + 1
    local playerRow = math.floor(py / tileH) + 1
    local minCol = math.max(1, playerCol - viewRadiusTiles)
    local maxCol = math.min(gridCols, playerCol + viewRadiusTiles)
    local minRow = math.max(1, playerRow - viewRadiusTiles)
    local maxRow = math.min(gridRows, playerRow + viewRadiusTiles)
    local visibleCount = 0
    for col = minCol, maxCol do
        local colData = visibility[col]
        local tileCenterX = (col - 0.5) * tileW
        for row = minRow, maxRow do
            local tileCenterY = (row - 0.5) * tileH
            local dx = tileCenterX - px
            local dy = tileCenterY - py
            if math.sqrt(dx * dx + dy * dy) <= viewRadius then
                colData[row] = 2
                visibleCount = visibleCount + 1
            end
        end
    end

    -- Log only when tile counts change (player moved to a new area)
    local prev = fowState[visibility]
    if not prev or prev.demoted ~= demotedCount or prev.visible ~= visibleCount then
        debug_helpers.log(string.format("FoW.update: %d demoted, %d visible", demotedCount, visibleCount), "DEBUG")
        fowState[visibility] = { demoted = demotedCount, visible = visibleCount }
    end
end

--- Query visibility state (0=unexplored, 1=explored, 2=visible) at world position
function FoW.getState(visibility, worldX, worldY, tileW, tileH, gridCols, gridRows)
    local col = math.floor(worldX / tileW) + 1
    local row = math.floor(worldY / tileH) + 1
    if col < 1 or col > gridCols or row < 1 or row > gridRows then
        return nil
    end
    return visibility[col][row]
end

function FoW.draw(visibility, tileW, tileH, gridCols, gridRows)
    for col = 1, gridCols do
        local colData = visibility[col]
        local worldX = (col - 1) * tileW
        for row = 1, gridRows do
            local cell = colData[row]
            if cell == 0 then
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.rectangle("fill", worldX, (row - 1) * tileH, tileW, tileH)
            elseif cell == 1 then
                love.graphics.setColor(0, 0, 0, 0.6)
                love.graphics.rectangle("fill", worldX, (row - 1) * tileH, tileW, tileH)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return FoW
