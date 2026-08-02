-- Unit tests for src/entities/items/init.lua (WorldItems)

require("test.mocks.love_mock")

local WorldItems = require("src.entities.items.init")
local Item = require("src.entities.items.item")

describe("WorldItems.new", function()
    it("creates an empty WorldItems container", function()
        local wi = WorldItems.new()
        assert.is_table(wi.items)
        assert.are.equal(0, #wi.items)
    end)

    it("each instance is independent", function()
        local a = WorldItems.new()
        local b = WorldItems.new()
        b:spawnAt(Item.new("X", "assets/images/items/padle.png", "desc"), 10, 20)
        assert.are.equal(0, #a.items)
        assert.are.equal(1, #b.items)
    end)

    it("returns a table with WorldItems methods", function()
        local wi = WorldItems.new()
        assert.is_function(wi.loadFromMap)
        assert.is_function(wi.spawnAt)
        assert.is_function(wi.findNearby)
        assert.is_function(wi.remove)
        assert.is_function(wi.draw)
        assert.is_function(wi.clearPrompts)
    end)
end)

describe("WorldItems:spawnAt", function()
    local wi

    before_each(function()
        wi = WorldItems.new()
    end)

    it("adds an item entry at the given position", function()
        local item = Item.new("Padel", "assets/images/items/padle.png", "desc")
        wi:spawnAt(item, 128, 256)
        assert.are.equal(1, #wi.items)
        local entry = wi.items[1]
        assert.are.equal(item, entry.item)
        assert.are.equal(128, entry.x)
        assert.are.equal(256, entry.y)
        assert.is_false(entry._showPrompt)
    end)
end)

describe("WorldItems:findNearby", function()
    local wi, item1, item2

    before_each(function()
        wi = WorldItems.new()
        item1 = Item.new("A", "assets/images/items/padle.png", "first")
        item2 = Item.new("B", "assets/images/items/padle.png", "second")
        wi:spawnAt(item1, 100, 100)
        wi:spawnAt(item2, 500, 500)
    end)

    it("returns the closest item within radius", function()
        local found = wi:findNearby(105, 105, 20)
        assert.is_not_nil(found)
        assert.are.equal(item1, found.item)
    end)

    it("returns nil when nothing is within radius", function()
        local found = wi:findNearby(0, 0, 10)
        assert.is_nil(found)
    end)

    it("returns the closest when multiple are in range", function()
        -- place both closer together
        wi.items = {}
        local a = Item.new("A", "assets/images/items/padle.png", "a")
        local b = Item.new("B", "assets/images/items/padle.png", "b")
        wi:spawnAt(a, 100, 100)
        wi:spawnAt(b, 110, 100)

        local found = wi:findNearby(0, 0, 500)
        assert.is_not_nil(found)
        -- item at (100,100) is closer to (0,0) than (110,100)
        assert.are.equal(a, found.item)
    end)

    it("does not return items exactly at radius+epsilon boundary", function()
        -- item at (100, 100), radius=30, distance from (70,100) = 30 exactly => should be included
        local found = wi:findNearby(70, 100, 30)
        assert.is_not_nil(found)
        -- distance from (69,100) to (100,100) = 31 > 30 => should be nil
        found = wi:findNearby(69, 100, 30)
        assert.is_nil(found)
    end)
end)

describe("WorldItems:remove", function()
    local wi, entry

    before_each(function()
        wi = WorldItems.new()
        wi:spawnAt(Item.new("A", "assets/images/items/padle.png", "a"), 100, 100)
        wi:spawnAt(Item.new("B", "assets/images/items/padle.png", "b"), 200, 200)
        entry = wi.items[1]
    end)

    it("removes an entry by reference", function()
        wi:remove(entry)
        assert.are.equal(1, #wi.items)
        assert.are.equal("B", wi.items[1].item.name)
    end)

    it("does nothing when entry is not found", function()
        wi:remove({ item = Item.new("C", "assets/images/items/padle.png"), x = 0, y = 0 })
        assert.are.equal(2, #wi.items)
    end)
end)

describe("WorldItems:clearPrompts", function()
    it("sets _showPrompt to false on all entries", function()
        local wi = WorldItems.new()
        wi:spawnAt(Item.new("A", "assets/images/items/padle.png", "a"), 100, 100)
        wi:spawnAt(Item.new("B", "assets/images/items/padle.png", "b"), 200, 200)
        wi.items[1]._showPrompt = true
        wi.items[2]._showPrompt = true

        wi:clearPrompts()
        assert.is_false(wi.items[1]._showPrompt)
        assert.is_false(wi.items[2]._showPrompt)
    end)

    it("handles empty items list", function()
        local wi = WorldItems.new()
        assert.has_no.errors(function()
            wi:clearPrompts()
        end)
    end)
end)

describe("WorldItems:draw", function()
    it("calls draw on each item", function()
        local wi = WorldItems.new()
        local item1 = Item.new("A", "assets/images/items/padle.png", "a")
        local item2 = Item.new("B", "assets/images/items/padle.png", "b")
        wi:spawnAt(item1, 100, 100)
        wi:spawnAt(item2, 200, 200)

        love.graphics._draws = {}
        wi:draw()

        -- each item:draw calls love.graphics.draw once (when icon exists)
        assert.are.equal(2, #love.graphics._draws)
    end)

    it("handles empty items list", function()
        local wi = WorldItems.new()
        assert.has_no.errors(function()
            wi:draw()
        end)
    end)
end)

describe("WorldItems:loadFromMap", function()
    it("does nothing when map is nil", function()
        local wi = WorldItems.new()
        assert.has_no.errors(function()
            wi:loadFromMap(nil)
        end)
        assert.are.equal(0, #wi.items)
    end)

    it("does nothing when map has no layers", function()
        local wi = WorldItems.new()
        assert.has_no.errors(function()
            wi:loadFromMap({})
        end)
        assert.are.equal(0, #wi.items)
    end)

    it("parses item layers and spawns items for known GIDs", function()
        local wi = WorldItems.new()
        local map = {
            tilewidth = 32,
            tileheight = 32,
            layers = {
                {
                    name = "item1_padel",
                    type = "tilelayer",
                    data = {
                        [3] = { -- row 3
                            [2] = { gid = 9 }, -- col 2, row 3
                        },
                        [5] = { -- row 5
                            [4] = { gid = 9 }, -- col 4, row 5
                        },
                    },
                    width = 10,
                    height = 10,
                },
            },
        }

        wi:loadFromMap(map)
        assert.are.equal(2, #wi.items)

        -- first item at col=2, row=3 => worldX = (2-1)*32 + 16 = 48
        assert.are.equal(48, wi.items[1].x)
        assert.are.equal(80, wi.items[1].y) -- (3-1)*32 + 16 = 80
        assert.are.equal("Padel", wi.items[1].item.name)

        -- second item at col=4, row=5 => worldX = (4-1)*32 + 16 = 112
        assert.are.equal(112, wi.items[2].x)
        assert.are.equal(144, wi.items[2].y) -- (5-1)*32 + 16 = 144
    end)

    it("skips layers not starting with 'item'", function()
        local wi = WorldItems.new()
        local map = {
            tilewidth = 32,
            tileheight = 32,
            layers = {
                {
                    name = "ground",
                    type = "tilelayer",
                    data = {
                        [1] = { [1] = { gid = 9 } },
                    },
                    width = 1,
                    height = 1,
                },
            },
        }

        wi:loadFromMap(map)
        assert.are.equal(0, #wi.items)
    end)

    it("skips non-tilelayer layers", function()
        local wi = WorldItems.new()
        local map = {
            tilewidth = 32,
            tileheight = 32,
            layers = {
                {
                    name = "item_objectgroup",
                    type = "objectgroup",
                    data = {
                        [1] = { [1] = { gid = 9 } },
                    },
                    width = 1,
                    height = 1,
                },
            },
        }

        wi:loadFromMap(map)
        assert.are.equal(0, #wi.items)
    end)

    it("logs unknown GIDs without crashing", function()
        local wi = WorldItems.new()
        local map = {
            tilewidth = 32,
            tileheight = 32,
            layers = {
                {
                    name = "item_unknown",
                    type = "tilelayer",
                    data = {
                        [1] = { [1] = { gid = 999 } },
                    },
                    width = 1,
                    height = 1,
                },
            },
        }

        assert.has_no.errors(function()
            wi:loadFromMap(map)
        end)
        assert.are.equal(0, #wi.items)
    end)

    it("handles nil row data", function()
        local wi = WorldItems.new()
        local map = {
            tilewidth = 32,
            tileheight = 32,
            layers = {
                {
                    name = "item_sparse",
                    type = "tilelayer",
                    data = {
                        [1] = { [1] = { gid = 9 } },
                        [2] = nil, -- nil row
                    },
                    width = 1,
                    height = 2,
                },
            },
        }

        assert.has_no.errors(function()
            wi:loadFromMap(map)
        end)
        assert.are.equal(1, #wi.items)
    end)
end)