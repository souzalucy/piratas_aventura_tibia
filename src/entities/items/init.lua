-- WorldItems manager — tracks items placed in the game world
-- Handles loading from Tiled map layers and spawning/dropping items
local WorldItems = {}

local Item = require("src.entities.items.item")
local debug_helpers = require("src.debug_helpers")

-- Map tile GID → item definition table
-- When you add items to the map in Tiled, map their GID to item properties here
local ITEM_DEFS = {
    [9] = {
        name = "Padel",
        iconPath = "assets/images/items/padle.png",
        description = "A wooden paddle for navigating shallow waters."
    },
}

--- Create a new WorldItems container
function WorldItems.new()
    local self = setmetatable({}, { __index = WorldItems })
    self.items = {} -- array of { item=Item, x=number, y=number, _showPrompt=bool }
    return self
end

--- Parse all item layers from the Tiled map and spawn items
--- Layer names must start with "item" (e.g., "item1_padel")
--- @param map table the STI map object
function WorldItems:loadFromMap(map)
    if not map or not map.layers then
        debug_helpers.log("WorldItems:loadFromMap() — no map layers found", "WARN")
        return
    end

    local spawnedCount = 0
    local tileW = map.tilewidth or 32
    local tileH = map.tileheight or 32

    for _, layer in ipairs(map.layers) do
        if layer.name and layer.name:match("^item") and layer.type == "tilelayer" and layer.data then
            debug_helpers.log(string.format("WorldItems: parsing item layer '%s'", layer.name), "DEBUG")
            -- STI transforms layer.data into a 2D grid: data[y][x] = tile_table_or_nil
            for row = 1, layer.height do
                local rowData = layer.data[row]
                if rowData then
                    for col = 1, layer.width do
                        local tile = rowData[col]
                        if tile and tile.gid and tile.gid > 0 then
                            local gid = tile.gid
                            local def = ITEM_DEFS[gid]
                            if def then
                                -- Center the item on the tile (col/row are 1-based in STI's 2D grid)
                                local worldX = (col - 1) * tileW + tileW / 2
                                local worldY = (row - 1) * tileH + tileH / 2
                                local item = Item.new(def.name, def.iconPath, def.description)
                                self:_spawnRaw(item, worldX, worldY)
                                spawnedCount = spawnedCount + 1
                            else
                                debug_helpers.log(
                                    string.format("WorldItems: unknown GID %d in layer '%s' at (%d,%d) — no ITEM_DEFS entry",
                                        gid, layer.name, col - 1, row - 1),
                                    "WARN")
                            end
                        end
                    end
                end
            end
        end
    end

    debug_helpers.log(string.format("WorldItems: spawned %d items from map layers", spawnedCount), "INFO")
end

--- Place an item at a specific world position (internal, no log spam)
function WorldItems:_spawnRaw(item, x, y)
    table.insert(self.items, {
        item = item,
        x = x,
        y = y,
        _showPrompt = false,
    })
end

--- Spawn an item at a specific world position (e.g., when dropped from inventory)
--- @param item Item
--- @param x number world X coordinate
--- @param y number world Y coordinate
function WorldItems:spawnAt(item, x, y)
    debug_helpers.log(string.format("WorldItems:spawnAt() — '%s' at (%d, %d)", item.name, x or 0, y or 0), "DEBUG")
    self:_spawnRaw(item, x, y)
end

--- Find the closest item within a given radius of a point
--- @param x number world X
--- @param y number world Y
--- @param radius number max distance in pixels
--- @return table|nil the world item entry (with .item, .x, .y), or nil if none found
function WorldItems:findNearby(x, y, radius)
    local closest = nil
    local closestDist = radius + 1

    for _, entry in ipairs(self.items) do
        local dx = entry.x - x
        local dy = entry.y - y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= radius and dist < closestDist then
            closest = entry
            closestDist = dist
        end
    end

    return closest
end

--- Remove an item from the world
--- @param entry table the world item entry (as returned by findNearby or iterating self.items)
function WorldItems:remove(entry)
    for i, e in ipairs(self.items) do
        if e == entry then
            debug_helpers.log(string.format("WorldItems:remove() — '%s'", entry.item.name), "DEBUG")
            table.remove(self.items, i)
            return
        end
    end
end

--- Draw all world items (called in love.draw, in world space, after cam:attach)
--- Fog of war check is done in main.lua before calling this
function WorldItems:draw()
    for _, entry in ipairs(self.items) do
        entry.item:draw(entry.x, entry.y)
    end
end

--- Hide all pickup prompts (called before re-evaluating proximity)
function WorldItems:clearPrompts()
    for _, entry in ipairs(self.items) do
        entry._showPrompt = false
    end
end

return WorldItems