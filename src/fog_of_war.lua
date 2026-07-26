local FoW = {}

function FoW.init(gridCols, gridRows)
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
    for col = 1, gridCols do
        local colData = visibility[col]
        for row = 1, gridRows do
            if colData[row] == 2 then colData[row] = 1 end
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
    for col = minCol, maxCol do
        local colData = visibility[col]
        local tileCenterX = (col - 0.5) * tileW
        for row = minRow, maxRow do
            local tileCenterY = (row - 0.5) * tileH
            local dx = tileCenterX - px
            local dy = tileCenterY - py
            if math.sqrt(dx * dx + dy * dy) <= viewRadius then
                colData[row] = 2
            end
        end
    end
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
