-- Unit tests for src/entities/items/item.lua

require("test.mocks.love_mock")

local Item = require("src.entities.items.item")

describe("Item.new", function()
    it("creates an item with all fields set", function()
        local item = Item.new("Padel", "assets/images/items/padle.png", "A wooden paddle.")
        assert.are.equal("Padel", item.name)
        assert.are.equal("A wooden paddle.", item.description)
        assert.are.equal(1, item.quantity)
        assert.is_false(item.stackable)
        assert.is_not_nil(item.icon)
    end)

    it("defaults description to empty string", function()
        local item = Item.new("Test", "assets/images/items/padle.png")
        assert.are.equal("", item.description)
    end)

    it("defaults quantity to 1", function()
        local item = Item.new("Test", "assets/images/items/padle.png", "desc")
        assert.are.equal(1, item.quantity)
    end)

    it("accepts a custom quantity", function()
        local item = Item.new("Test", "assets/images/items/padle.png", "desc", 5)
        assert.are.equal(5, item.quantity)
    end)

    it("loads icon image from path", function()
        local item = Item.new("IconTest", "assets/images/items/padle.png")
        assert.is_not_nil(item.icon)
        assert.are.equal(64, item.icon:getWidth())
        assert.are.equal(64, item.icon:getHeight())
    end)

    it("sets icon to nil when image loading fails", function()
        -- pcalling love.graphics.newImage will succeed since mock always succeeds.
        -- To test the failure path, we temporarily break newImage.
        local origNewImage = love.graphics.newImage
        love.graphics.newImage = function(path) error("image not found") end

        local item = Item.new("MissingIcon", "nonexistent.png")
        assert.is_nil(item.icon)

        love.graphics.newImage = origNewImage
    end)

    it("each instance is independent", function()
        local a = Item.new("A", "assets/images/items/padle.png", "first")
        local b = Item.new("B", "assets/images/items/padle.png", "second", 10)
        a.quantity = 3
        assert.are.equal(3, a.quantity)
        assert.are.equal(10, b.quantity)
    end)

    it("returns a table with Item.__index as metatable", function()
        local item = Item.new("M", "assets/images/items/padle.png")
        assert.is_function(item.use)
        assert.is_function(item.draw)
    end)
end)

describe("Item:use", function()
    it("returns false by default (no effect)", function()
        local item = Item.new("FakePotion", "assets/images/items/padle.png", "A potion.")
        local player = { name = "test_player" }
        local consumed = item:use(player)
        assert.is_false(consumed)
    end)
end)

describe("Item:draw with icon", function()
    local item

    before_each(function()
        love.graphics._draws = {}
        love.graphics._circles = {}
        love.graphics._prints = {}
        love.graphics._printfCalls = {}
        love.graphics._lastColor = nil
        item = Item.new("Padel", "assets/images/items/padle.png", "A wooden paddle.")
    end)

    it("draws the icon at the given position scaled to size", function()
        item:draw(100, 100, 1)
        assert.are.equal(1, #love.graphics._draws)
        local d = love.graphics._draws[1]
        assert.are.equal(item.icon, d.drawable)
        -- default size = 32 * 1 = 32, so x = 100 - 16 = 84
        assert.is_near(84, d.x, 1)
        assert.is_near(84, d.y, 1)
    end)

    it("respects custom scale", function()
        item:draw(100, 100, 2)
        local d = love.graphics._draws[1]
        -- size = 32 * 2 = 64, x = 100 - 32 = 68
        assert.is_near(68, d.x, 1)
        assert.is_near(68, d.y, 1)
    end)

    it("does not draw quantity badge when quantity is 1", function()
        item:draw(100, 100)
        -- no circles drawn for badge
        local badgeCircles = 0
        for _, c in ipairs(love.graphics._circles) do
            if c.mode == "fill" and c.radius == 8 then
                badgeCircles = badgeCircles + 1
            end
        end
        assert.are.equal(0, badgeCircles)
    end)

    it("draws quantity badge when quantity > 1", function()
        item.quantity = 3
        item:draw(100, 100, 1)
        local badgeCircles = 0
        for _, c in ipairs(love.graphics._circles) do
            if c.mode == "fill" and c.radius == 8 then
                badgeCircles = badgeCircles + 1
            end
        end
        assert.are.equal(1, badgeCircles)
    end)
end)

describe("Item:draw without icon", function()
    local item

    before_each(function()
        love.graphics._draws = {}
        love.graphics._circles = {}
        love.graphics._prints = {}
        love.graphics._printfCalls = {}
        love.graphics._lastColor = nil
        love.graphics._lastRect = nil

        -- force icon to nil
        local origNewImage = love.graphics.newImage
        love.graphics.newImage = function(path) error("image not found") end
        item = Item.new("NoIcon", "nonexistent.png", "No icon.")
        love.graphics.newImage = origNewImage
    end)

    it("draws a sparkle dot in world view (scale >= 1)", function()
        item:draw(200, 150, 1.5)
        -- should have drawn a small yellow circle
        local sparkleCircles = 0
        for _, c in ipairs(love.graphics._circles) do
            if c.mode == "fill" and c.radius == 3 then
                sparkleCircles = sparkleCircles + 1
            end
        end
        assert.are.equal(1, sparkleCircles)
    end)

    it("draws a colored square with initial letter in inventory view (scale < 1)", function()
        item:draw(200, 150, 0.85)
        -- should have drawn a rectangle (fill) and a rectangle (line) and text
        love.graphics._rects = {}
        item:draw(200, 150, 0.85)
        local hasFill = false
        local hasLine = false
        for _, r in ipairs(love.graphics._rects) do
            if r.mode == "fill" then hasFill = true end
            if r.mode == "line" then hasLine = true end
        end
        assert.is_true(hasFill, "should draw a filled rectangle")
        assert.is_true(hasLine, "should draw a line rectangle")
        -- Also should have printf with the first letter
        local hasLetter = false
        for _, p in ipairs(love.graphics._printfCalls) do
            if p.text == "N" then
                hasLetter = true
            end
        end
        assert.is_true(hasLetter, "should draw initial letter 'N'")
    end)
end)