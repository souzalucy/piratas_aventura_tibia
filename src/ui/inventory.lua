-- Inventory UI module — interactive inventory panel with drag-and-drop
local Inventory = {}
Inventory.__index = Inventory

local Item = require("src.entities.items.item")
local debug_helpers = require("src.debug_helpers")

-- Layout constants
local COLS = 4
local ROWS = 4
local SLOT_SIZE = 48
local SLOT_PADDING = 8
local PANEL_PADDING = 16
local PANEL_W = COLS * SLOT_SIZE + (COLS - 1) * SLOT_PADDING + PANEL_PADDING * 2
local PANEL_H = ROWS * SLOT_SIZE + (ROWS - 1) * SLOT_PADDING + PANEL_PADDING * 2

-- Close button (top-right of panel)
local CLOSE_BTN_SIZE = 16
local CLOSE_BTN_MARGIN = 8

-- Per-slot X button (for dropping)
local DROP_X_SIZE = 12
local DROP_X_OFFSET = 2

-- Full-inventory message duration
local FULL_MSG_DURATION = 2.0


--- Create a new Inventory
--- @param backgroundPath string path to inventory background PNG (not used yet; drawn procedurally)
--- @param config table (optional) override layout constants { cols, rows, slotSize, slotPadding }
function Inventory.new(backgroundPath, config)
    local self = setmetatable({}, Inventory)

    -- Layout overrides (not used currently, but allows future customization)
    config = config or {}

    -- Load background (if the file exists)
    local ok, bg = pcall(love.graphics.newImage, backgroundPath)
    if ok then
        self.background = bg
    else
        debug_helpers.log("Inventory: background PNG not found, using procedural background", "WARN")
        self.background = nil
    end

    -- Create 16 slots
    self.slots = {}
    for i = 1, COLS * ROWS do
        self.slots[i] = { item = nil }
    end

    self._isOpen = false

    -- Drag state
    self._dragging = nil -- { slotIndex, item, grabOffsetX, grabOffsetY }

    -- Hover state
    self._hoverSlot = nil -- slot index or nil

    -- Full message timer
    self._fullMessageTimer = 0

    -- Cache screen center for positioning
    self._panelX = 0
    self._panelY = 0

    debug_helpers.log(string.format("Inventory created: %dx%d slots, panel %dx%d", COLS, ROWS, PANEL_W, PANEL_H),
        "DEBUG")

    return self
end

--- Toggle inventory open/close
function Inventory:toggle()
    self._isOpen = not self._isOpen
    self._dragging = nil -- cancel any drag on close
    self._hoverSlot = nil
    debug_helpers.log(string.format("Inventory %s", self._isOpen and "opened" or "closed"), "DEBUG")
end

--- Check if inventory is open
function Inventory:isOpen()
    return self._isOpen
end

--- Add an item to the first empty slot. Returns true on success, false if full.
--- @param item Item
--- @return boolean
function Inventory:addItem(item)
    for i = 1, #self.slots do
        if self.slots[i].item == nil then
            self.slots[i].item = item
            debug_helpers.log(string.format("Inventory: '%s' added to slot %d", item.name, i), "DEBUG")
            return true
        end
    end

    -- Inventory full
    debug_helpers.log("Inventory: full — cannot add item", "WARN")
    self._fullMessageTimer = FULL_MSG_DURATION
    return false
end

--- Remove the item from a slot and return it (or nil if empty)
--- @param slotIndex number 1-based
--- @return Item|nil
function Inventory:removeItem(slotIndex)
    local slot = self.slots[slotIndex]
    if not slot or not slot.item then return nil end

    local item = slot.item
    slot.item = nil
    debug_helpers.log(string.format("Inventory: '%s' removed from slot %d", item.name, slotIndex), "DEBUG")
    return item
end

--- Drop an item from a slot (for the per-slot X button)
--- @param slotIndex number
--- @return Item|nil the dropped item, or nil
function Inventory:dropItem(slotIndex)
    return self:removeItem(slotIndex)
end

--- Compute the screen position of the top-left corner of a slot
--- @param slotIndex number 1-based
--- @return number x, number y
function Inventory:_slotScreenPos(slotIndex)
    local col = (slotIndex - 1) % COLS
    local row = math.floor((slotIndex - 1) / COLS)

    local sx = self._panelX + PANEL_PADDING + col * (SLOT_SIZE + SLOT_PADDING)
    local sy = self._panelY + PANEL_PADDING + row * (SLOT_SIZE + SLOT_PADDING)
    return sx, sy
end

--- Get the slot index under a screen position (or nil)
--- @param mx number screen mouse X
--- @param my number screen mouse Y
--- @return number|nil slotIndex
function Inventory:_slotAtScreen(mx, my)
    for i = 1, #self.slots do
        local sx, sy = self:_slotScreenPos(i)
        if mx >= sx and mx <= sx + SLOT_SIZE and my >= sy and my <= sy + SLOT_SIZE then
            return i
        end
    end
    return nil
end

--- Check if mouse is over the panel's close X button
function Inventory:_isOverCloseButton(mx, my)
    local cx = self._panelX + PANEL_W - CLOSE_BTN_MARGIN - CLOSE_BTN_SIZE
    local cy = self._panelY + CLOSE_BTN_MARGIN
    return mx >= cx and mx <= cx + CLOSE_BTN_SIZE and my >= cy and my <= cy + CLOSE_BTN_SIZE
end

--- Check if mouse is over a slot's drop X button
function Inventory:_isOverSlotXButton(slotIndex, mx, my)
    local sx, sy = self:_slotScreenPos(slotIndex)
    local bx = sx + SLOT_SIZE - DROP_X_OFFSET - DROP_X_SIZE
    local by = sy + DROP_X_OFFSET
    return mx >= bx and mx <= bx + DROP_X_SIZE and my >= by and my <= by + DROP_X_SIZE
end

--- Draw the close X button on the panel
function Inventory:_drawCloseButton()
    local cx = self._panelX + PANEL_W - CLOSE_BTN_MARGIN - CLOSE_BTN_SIZE
    local cy = self._panelY + CLOSE_BTN_MARGIN

    -- Highlight if hovered
    local mx, my = love.mouse.getPosition()
    local hovered = self:_isOverCloseButton(mx, my)

    if hovered then
        love.graphics.setColor(0.9, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", cx - 1, cy - 1, CLOSE_BTN_SIZE + 2, CLOSE_BTN_SIZE + 2, 3, 3)
    end

    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(cx, cy, cx + CLOSE_BTN_SIZE, cy + CLOSE_BTN_SIZE)
    love.graphics.line(cx + CLOSE_BTN_SIZE, cy, cx, cy + CLOSE_BTN_SIZE)
    love.graphics.setLineWidth(1)
end

--- Draw the per-slot drop X button
function Inventory:_drawSlotXButton(slotIndex)
    local sx, sy = self:_slotScreenPos(slotIndex)
    local bx = sx + SLOT_SIZE - DROP_X_OFFSET - DROP_X_SIZE
    local by = sy + DROP_X_OFFSET

    local mx, my = love.mouse.getPosition()
    local hovered = self:_isOverSlotXButton(slotIndex, mx, my)

    -- Background circle
    if hovered then
        love.graphics.setColor(1, 0.2, 0.2, 0.9)
    else
        love.graphics.setColor(0.7, 0.2, 0.2, 0.7)
    end
    love.graphics.circle("fill", bx + DROP_X_SIZE / 2, by + DROP_X_SIZE / 2, DROP_X_SIZE / 2)

    -- X mark
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(bx + 3, by + 3, bx + DROP_X_SIZE - 3, by + DROP_X_SIZE - 3)
    love.graphics.line(bx + DROP_X_SIZE - 3, by + 3, bx + 3, by + DROP_X_SIZE - 3)
    love.graphics.setLineWidth(1)
end

--- Handle mouse press
--- @param mx number screen X
--- @param my number screen Y
--- @param button number 1=left, 2=right
--- @return Item|nil droppedItem — if user clicked a slot's X button, returns the item for main.lua to spawn
function Inventory:mousepressed(mx, my, button)
    if button ~= 1 then return nil end -- only left-click

    -- Close button?
    if self:_isOverCloseButton(mx, my) then
        self:toggle()
        return nil
    end

    -- Slot X (drop) button?
    if self._hoverSlot then
        local slot = self.slots[self._hoverSlot]
        if slot.item and self:_isOverSlotXButton(self._hoverSlot, mx, my) then
            local dropped = self:dropItem(self._hoverSlot)
            self._hoverSlot = nil
            return dropped -- main.lua will spawn it at player feet
        end
    end

    -- Slot click → start drag?
    local slotIndex = self:_slotAtScreen(mx, my)
    if slotIndex and self.slots[slotIndex].item then
        local sx, sy = self:_slotScreenPos(slotIndex)
        self._dragging = {
            slotIndex = slotIndex,
            item = self.slots[slotIndex].item,
            grabOffsetX = mx - (sx + SLOT_SIZE / 2),
            grabOffsetY = my - (sy + SLOT_SIZE / 2),
        }
        debug_helpers.log(string.format("Inventory: started dragging slot %d", slotIndex), "DEBUG")
    end

    return nil
end

--- Handle mouse move
function Inventory:mousemoved(mx, my)
    self._hoverSlot = self:_slotAtScreen(mx, my)
end

--- Handle mouse release (drop dragged item into target slot)
function Inventory:mousereleased(mx, my, button)
    if button ~= 1 or not self._dragging then return end

    local targetSlot = self:_slotAtScreen(mx, my)

    if targetSlot then
        local sourceSlot = self._dragging.slotIndex

        if targetSlot == sourceSlot then
            -- Dropped on same slot → cancel
            debug_helpers.log("Inventory: drag cancelled (same slot)", "DEBUG")
        else
            -- Swap items between source and target
            local sourceItem = sourceSlot and self.slots[sourceSlot] and self.slots[sourceSlot].item
            local targetItem = self.slots[targetSlot].item

            debug_helpers.log(string.format("Inventory: swapping slot %d <-> %d", sourceSlot, targetSlot), "DEBUG")

            self.slots[sourceSlot].item = targetItem
            self.slots[targetSlot].item = sourceItem
        end
    end

    self._dragging = nil
end

--- Draw the inventory panel
function Inventory:draw()
    if not self._isOpen then return end

    local screenW, screenH = love.graphics.getDimensions()

    -- Center the panel
    self._panelX = math.floor((screenW - PANEL_W) / 2)
    self._panelY = math.floor((screenH - PANEL_H) / 2)

    local px, py = self._panelX, self._panelY

    -- Draw panel background
    if self.background then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.background, px, py)
    else
        -- Procedural background: dark panel with border
        love.graphics.setColor(0.05, 0.05, 0.08, 0.95)
        love.graphics.rectangle("fill", px, py, PANEL_W, PANEL_H, 8, 8)
        love.graphics.setColor(0.5, 0.35, 0.15, 1) -- gold-brown border
        love.graphics.rectangle("line", px, py, PANEL_W, PANEL_H, 8, 8)
    end

    -- Title
    love.graphics.setColor(1, 0.85, 0.4, 1)
    love.graphics.print("INVENTORY", px + PANEL_PADDING, py + 4)

    -- Draw close X button
    self:_drawCloseButton()

    -- Draw slots
    for i = 1, #self.slots do
        local sx, sy = self:_slotScreenPos(i)

        -- Slot background
        if i == self._hoverSlot and not self._dragging then
            love.graphics.setColor(0.3, 0.3, 0.2, 0.6)
        else
            love.graphics.setColor(0.1, 0.1, 0.12, 0.5)
        end
        love.graphics.rectangle("fill", sx, sy, SLOT_SIZE, SLOT_SIZE, 4, 4)
        love.graphics.setColor(0.3, 0.25, 0.15, 0.8)
        love.graphics.rectangle("line", sx, sy, SLOT_SIZE, SLOT_SIZE, 4, 4)

        -- Slot item (skip if currently dragging this slot)
        local slot = self.slots[i]
        if slot.item then
            if not self._dragging or self._dragging.slotIndex ~= i then
                slot.item:draw(sx + SLOT_SIZE / 2, sy + SLOT_SIZE / 2, 0.85)
            end

            -- Draw drop X button if hovering over this slot and not currently dragging
            if i == self._hoverSlot and not self._dragging then
                self:_drawSlotXButton(i)
            end
        end
    end

    -- Draw dragged item following mouse
    if self._dragging then
        local mx, my = love.mouse.getPosition()
        local d = self._dragging
        d.item:draw(mx - d.grabOffsetX, my - d.grabOffsetY, 0.85)
    end

    -- Draw "Inventory Full!" message
    if self._fullMessageTimer > 0 then
        local alpha = math.min(1, self._fullMessageTimer)
        love.graphics.setColor(1, 0.3, 0.3, alpha)
        local font = love.graphics.getFont()
        local text = "INVENTORY FULL!"
        local tw = font:getWidth(text)
        local th = font:getHeight()
        love.graphics.print(text, px + (PANEL_W - tw) / 2, py + PANEL_H + 8)
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.setColor(1, 1, 1, 1) -- reset
end

--- Update timers (called from love.update)
--- @param dt number
function Inventory:update(dt)
    if self._fullMessageTimer > 0 then
        self._fullMessageTimer = self._fullMessageTimer - dt
        if self._fullMessageTimer < 0 then
            self._fullMessageTimer = 0
        end
    end
end

return Inventory