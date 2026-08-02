-- Unit tests for src/ui/inventory.lua

require("test.mocks.love_mock")

local Inventory = require("src.ui.inventory")
local Item = require("src.entities.items.item")

describe("Inventory.new", function()
    it("creates an inventory with default empty slots", function()
        local inv = Inventory.new("nonexistent.png")
        assert.is_false(inv:isOpen())
        assert.is_table(inv.slots)
        assert.are.equal(16, #inv.slots)
        for i = 1, 16 do
            assert.is_nil(inv.slots[i].item)
        end
    end)

    it("returns a table with Inventory methods", function()
        local inv = Inventory.new("nonexistent.png")
        assert.is_function(inv.toggle)
        assert.is_function(inv.isOpen)
        assert.is_function(inv.addItem)
        assert.is_function(inv.removeItem)
        assert.is_function(inv.dropItem)
        assert.is_function(inv.update)
        assert.is_function(inv.draw)
        assert.is_function(inv.mousepressed)
        assert.is_function(inv.mousemoved)
        assert.is_function(inv.mousereleased)
    end)

    it("each instance is independent", function()
        local a = Inventory.new("nonexistent.png")
        local b = Inventory.new("nonexistent.png")
        a:addItem(Item.new("X", "assets/images/items/padle.png", "desc"))
        assert.is_not_nil(a.slots[1].item)
        assert.is_nil(b.slots[1].item)
    end)
end)

describe("Inventory:toggle / isOpen", function()
    it("starts closed", function()
        local inv = Inventory.new("nonexistent.png")
        assert.is_false(inv:isOpen())
    end)

    it("opens after toggle", function()
        local inv = Inventory.new("nonexistent.png")
        inv:toggle()
        assert.is_true(inv:isOpen())
    end)

    it("closes after second toggle", function()
        local inv = Inventory.new("nonexistent.png")
        inv:toggle()
        inv:toggle()
        assert.is_false(inv:isOpen())
    end)

    it("cancels any drag on close", function()
        local inv = Inventory.new("nonexistent.png")
        inv:addItem(Item.new("X", "assets/images/items/padle.png", "desc"))
        inv:toggle()
        -- simulate starting a drag on slot 1
        inv:mousepressed(100, 100, 1) -- this sets _dragging
        -- the actual coords won't match a slot in the default state without draw being called
        -- so we'll test toggle cancels drag explicitly
        inv._dragging = { slotIndex = 1, item = inv.slots[1].item }
        inv:toggle()
        assert.is_nil(inv._dragging)
    end)
end)

describe("Inventory:addItem", function()
    local inv

    before_each(function()
        inv = Inventory.new("nonexistent.png")
    end)

    it("adds item to first empty slot and returns true", function()
        local item = Item.new("Padel", "assets/images/items/padle.png", "desc")
        local ok = inv:addItem(item)
        assert.is_true(ok)
        assert.are.equal(item, inv.slots[1].item)
    end)

    it("fills slots sequentially", function()
        local a = Item.new("A", "assets/images/items/padle.png", "a")
        local b = Item.new("B", "assets/images/items/padle.png", "b")
        inv:addItem(a)
        inv:addItem(b)
        assert.are.equal(a, inv.slots[1].item)
        assert.are.equal(b, inv.slots[2].item)
    end)

    it("returns false and sets full message timer when inventory is full", function()
        for i = 1, 16 do
            inv:addItem(Item.new("Item" .. i, "assets/images/items/padle.png", "desc"))
        end
        local ok = inv:addItem(Item.new("Extra", "assets/images/items/padle.png", "extra"))
        assert.is_false(ok)
        assert.are.equal(2.0, inv._fullMessageTimer)
    end)
end)

describe("Inventory:removeItem", function()
    local inv, item

    before_each(function()
        inv = Inventory.new("nonexistent.png")
        item = Item.new("Padel", "assets/images/items/padle.png", "desc")
        inv:addItem(item)
    end)

    it("removes and returns the item from a filled slot", function()
        local removed = inv:removeItem(1)
        assert.are.equal(item, removed)
        assert.is_nil(inv.slots[1].item)
    end)

    it("returns nil for an empty slot", function()
        local removed = inv:removeItem(2)
        assert.is_nil(removed)
    end)

    it("returns nil for invalid slot index", function()
        local removed = inv:removeItem(99)
        assert.is_nil(removed)
    end)
end)

describe("Inventory:dropItem", function()
    it("removes and returns the item (alias for removeItem)", function()
        local inv = Inventory.new("nonexistent.png")
        local item = Item.new("Padel", "assets/images/items/padle.png", "desc")
        inv:addItem(item)
        local dropped = inv:dropItem(1)
        assert.are.equal(item, dropped)
        assert.is_nil(inv.slots[1].item)
    end)
end)

describe("Inventory:_slotScreenPos", function()
    it("computes slot positions correctly", function()
        local inv = Inventory.new("nonexistent.png")
        -- force a panel position for testing
        inv._panelX = 100
        inv._panelY = 50

        -- Slot 1: col=0, row=0
        local x1, y1 = inv:_slotScreenPos(1)
        -- PANEL_PADDING=16, so x = 100 + 16 + 0 = 116
        assert.are.equal(116, x1)
        assert.are.equal(66, y1)

        -- Slot 5: col=0, row=1 (since 0-indexed col: (5-1)%4=0, row: floor((5-1)/4)=1)
        local x5, y5 = inv:_slotScreenPos(5)
        -- SLOT_SIZE=48, SLOT_PADDING=8, so y = 50 + 16 + 1*(48+8) = 122
        assert.are.equal(116, x5)
        assert.are.equal(122, y5)
    end)
end)

describe("Inventory:_slotAtScreen", function()
    it("returns slot index for position inside a slot", function()
        local inv = Inventory.new("nonexistent.png")
        inv._panelX = 100
        inv._panelY = 50

        -- Slot 1: top-left at (116, 66), size 48
        local idx = inv:_slotAtScreen(140, 90)
        assert.are.equal(1, idx)
    end)

    it("returns nil for position outside panel", function()
        local inv = Inventory.new("nonexistent.png")
        inv._panelX = 100
        inv._panelY = 50

        local idx = inv:_slotAtScreen(0, 0)
        assert.is_nil(idx)
    end)
end)

describe("Inventory:mousepressed / mousereleased drag", function()
    local inv, item

    before_each(function()
        inv = Inventory.new("nonexistent.png")
        item = Item.new("Padel", "assets/images/items/padle.png", "desc")
        inv:addItem(item)
        inv:toggle()
        -- force panel position to known values
        inv._panelX = 100
        inv._panelY = 50
    end)

    it("closes inventory on close button click", function()
        -- close button is at px + PANEL_W - CLOSE_BTN_MARGIN - CLOSE_BTN_SIZE
        -- PANEL_W = 4*48 + 3*8 + 16*2 = 192 + 24 + 32 = 248
        -- close x = 100 + 248 - 8 - 16 = 324
        inv:mousepressed(330, 58, 1)
        assert.is_false(inv:isOpen())
    end)

    it("starts drag on slot with item", function()
        -- slot 1: (116, 66) to (164, 114). Click at center (140, 90)
        inv:mousepressed(140, 90, 1)
        assert.is_not_nil(inv._dragging)
        assert.are.equal(1, inv._dragging.slotIndex)
        assert.are.equal(item, inv._dragging.item)
    end)

    it("does not start drag on empty slot", function()
        inv:mousepressed(140 + 56, 90, 1) -- slot 2 (empty)
        assert.is_nil(inv._dragging)
    end)

    it("drops item on slot X button", function()
        -- slot 1: (116, 66), X button: bx = 116+48-2-12=150, by = 66+2=68, size=12
        -- click center of X button: (156, 74)
        inv._hoverSlot = 1
        local result = inv:mousepressed(156, 74, 1)
        assert.is_not_nil(result)
        assert.are.equal(item, result)
        assert.is_nil(inv.slots[1].item)
    end)

    it("swaps items on drag to different slot", function()
        local item2 = Item.new("Shield", "assets/images/items/padle.png", "shield")
        inv:addItem(item2) -- occupies slot 2

        -- start drag on slot 1
        inv:mousepressed(140, 90, 1)
        -- release on slot 2 center: x = 116 + 56 + 24 = 196 y: 66 + 24 = 90
        inv:mousereleased(196, 90, 1)

        assert.are.equal(item, inv.slots[2].item)
        assert.are.equal(item2, inv.slots[1].item)
    end)

    it("does nothing on drag to same slot", function()
        inv:mousepressed(140, 90, 1)
        inv:mousereleased(140, 90, 1)

        assert.are.equal(item, inv.slots[1].item)
        assert.is_nil(inv._dragging)
    end)
end)

describe("Inventory:update", function()
    it("decrements full message timer", function()
        local inv = Inventory.new("nonexistent.png")
        inv._fullMessageTimer = 2.0
        inv:update(0.5)
        assert.are.equal(1.5, inv._fullMessageTimer)
    end)

    it("clamps full message timer to 0", function()
        local inv = Inventory.new("nonexistent.png")
        inv._fullMessageTimer = 0.1
        inv:update(0.5)
        assert.are.equal(0, inv._fullMessageTimer)
    end)

    it("does nothing when timer is 0", function()
        local inv = Inventory.new("nonexistent.png")
        inv._fullMessageTimer = 0
        inv:update(0.5)
        assert.are.equal(0, inv._fullMessageTimer)
    end)
end)

describe("Inventory:draw", function()
    local inv

    before_each(function()
        inv = Inventory.new("nonexistent.png")
        love.graphics._draws = {}
        love.graphics._circles = {}
        love.graphics._prints = {}
        love.graphics._printfCalls = {}
        love.graphics._lines = {}
    end)

    it("does nothing when inventory is closed", function()
        love.graphics._lastRect = nil
        inv:draw()
        assert.is_nil(love.graphics._lastRect)
    end)

    it("draws panel background when open", function()
        inv:toggle()
        love.graphics._rects = {}
        inv:draw()
        local hasFill = false
        for _, r in ipairs(love.graphics._rects) do
            if r.mode == "fill" then hasFill = true end
        end
        assert.is_true(hasFill, "panel should draw a filled rectangle background")
    end)

    it("calls draw on all items when open", function()
        inv:addItem(Item.new("A", "assets/images/items/padle.png", "a"))
        inv:addItem(Item.new("B", "assets/images/items/padle.png", "b"))
        inv:toggle()
        love.graphics._draws = {}
        inv:draw()
        -- Draw calls: 1 for background image + 1 per item icon = 3 total
        -- The background mock image also has getWidth/getHeight, so count all draws with a drawable
        local totalDraws = 0
        for _, d in ipairs(love.graphics._draws) do
            if d.drawable then
                totalDraws = totalDraws + 1
            end
        end
        assert.are.equal(3, totalDraws)
    end)

    it("draws 'INVENTORY FULL!' message when timer is active", function()
        inv:toggle()
        inv._fullMessageTimer = 1.5
        love.graphics._lastRect = nil
        inv:draw()
        -- should have printed "INVENTORY FULL!"
        local hasFullMsg = false
        for _, p in ipairs(love.graphics._prints) do
            if p.text and p.text:find("INVENTORY") then
                hasFullMsg = true
            end
        end
        assert.is_true(hasFullMsg)
    end)
end)