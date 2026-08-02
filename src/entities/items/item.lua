-- Item class — represents a single item in the game
local Item = {}
Item.__index = Item

local debug_helpers = require("src.debug_helpers")

--- Create a new Item
--- @param name string
--- @param iconPath string path to the item's icon PNG
--- @param description string
--- @param quantity number (optional, default 1)
function Item.new(name, iconPath, description, quantity)
    local self = setmetatable({}, Item)

    self.name = name
    self.description = description or ""
    self.quantity = quantity or 1
    self.stackable = false -- override per item type if needed

    -- Load icon image
    -- If the file doesn't exist, love will throw an error during loading,
    -- but we wrap in pcall so we can fall back to a placeholder.
    local ok, img = pcall(love.graphics.newImage, iconPath)
    if ok then
        self.icon = img
    else
        debug_helpers.log(string.format("Item '%s': icon '%s' not found, using placeholder", name, iconPath), "WARN")
        self.icon = nil
    end

    debug_helpers.log(string.format("Item created: %s (qty: %d)", name, self.quantity), "DEBUG")

    return self
end

--- Use the item (called when right-clicked in inventory or via hotkey)
--- Override this per item type. Returns true if item was consumed.
function Item:use(player)
    debug_helpers.log(string.format("Item:use() — %s used (no effect defined)", self.name), "DEBUG")
    return false
end

--- Draw the item's icon at a given screen position
--- @param x number center X
--- @param y number center Y
--- @param scale number (optional)
function Item:draw(x, y, scale)
    scale = scale or 1
    local size = 32 * scale

    if self.icon then
        local iw, ih = self.icon:getWidth(), self.icon:getHeight()
        local sx = size / iw
        local sy = size / ih
        love.graphics.draw(self.icon, x - size / 2, y - size / 2, 0, sx, sy)
    else
        -- No icon: draw a small sparkle dot so the item isn't invisible in-world
        -- In the inventory, slots still show the item name initial
        local r, g, b, a = love.graphics.getColor()
        if scale >= 1 then
            -- World view: tiny sparkle
            love.graphics.setColor(1, 1, 0, 0.8)
            love.graphics.circle("fill", x, y, 3)
            love.graphics.setColor(r, g, b, a)
        else
            -- Inventory view: small colored square with initial letter
            local invSize = 24
            love.graphics.setColor(0.25, 0.25, 0.4, 1)
            love.graphics.rectangle("fill", x - invSize / 2, y - invSize / 2, invSize, invSize, 3, 3)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", x - invSize / 2, y - invSize / 2, invSize, invSize, 3, 3)
            love.graphics.printf(self.name:sub(1, 1), x - invSize / 2, y - invSize / 4, invSize, "center")
            love.graphics.setColor(r, g, b, a)
        end
    end

    -- Draw quantity badge if > 1
    if self.quantity > 1 then
        love.graphics.setColor(0.9, 0.2, 0.2, 1)
        love.graphics.circle("fill", x + size / 2 - 6, y - size / 2 + 6, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(tostring(self.quantity), x + size / 2 - 10, y - size / 2 + 1)
    end
end

return Item