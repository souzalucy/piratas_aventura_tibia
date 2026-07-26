-- Unit tests for src/Entity.lua
-- Requires the love mock to be loaded first (via .busted config)

-- debug_helpers is loaded by Entity, so love must be mocked
require("test.mocks.love_mock")

local Entity = require("src.Entity")

describe("Entity.new", function()
    it("creates an entity with default values when no args given", function()
        local e = Entity.new()
        assert.are.equal(0, e.x)
        assert.are.equal(0, e.y)
        assert.are.equal(32, e.width)
        assert.are.equal(32, e.height)
        assert.are.equal(0, e.vx)
        assert.are.equal(0, e.vy)
        assert.are.equal(0, e.rotation)
        assert.are.equal(1, e.scale)
        assert.are.same({ 1, 1, 1, 1 }, e.color)
        assert.is_true(e.active)
    end)

    it("creates an entity with given position and dimensions", function()
        local e = Entity.new(100, 200, 16, 48)
        assert.are.equal(100, e.x)
        assert.are.equal(200, e.y)
        assert.are.equal(16, e.width)
        assert.are.equal(48, e.height)
    end)

    it("each entity is independent", function()
        local a = Entity.new(0, 0, 32, 32)
        local b = Entity.new(100, 200, 64, 64)
        a.x = 50
        assert.are.equal(50, a.x)
        assert.are.equal(100, b.x)
        assert.are.equal(32, a.width)
        assert.are.equal(64, b.width)
    end)

    it("returns a table with Entity.__index as metatable", function()
        local e = Entity.new()
        assert.are.equal("table", type(e))
        -- should inherit methods
        assert.is_function(e.update)
        assert.is_function(e.draw)
        assert.is_function(e.collidesWith)
        assert.is_function(e.setVelocity)
        assert.is_function(e.setPosition)
        assert.is_function(e.extend)
    end)
end)

describe("Entity:update", function()
    it("moves entity by velocity * dt", function()
        local e = Entity.new(0, 0, 32, 32)
        e.vx = 100
        e.vy = 50
        e:update(0.5)
        assert.are.equal(50, e.x)
        assert.are.equal(25, e.y)
    end)

    it("does not move inactive entity", function()
        local e = Entity.new(0, 0, 32, 32)
        e.vx = 100
        e.vy = 50
        e.active = false
        e:update(0.5)
        assert.are.equal(0, e.x)
        assert.are.equal(0, e.y)
    end)

    it("handles negative velocities", function()
        local e = Entity.new(100, 200, 32, 32)
        e.vx = -50
        e.vy = -25
        e:update(2)
        assert.are.equal(0, e.x)
        assert.are.equal(150, e.y)
    end)

    it("handles zero dt", function()
        local e = Entity.new(10, 20, 32, 32)
        e.vx = 100
        e.vy = 50
        e:update(0)
        assert.are.equal(10, e.x)
        assert.are.equal(20, e.y)
    end)
end)

describe("Entity:setVelocity", function()
    it("sets both velocity components", function()
        local e = Entity.new()
        e:setVelocity(50, 100)
        assert.are.equal(50, e.vx)
        assert.are.equal(100, e.vy)
    end)

    it("defaults missing vy to 0", function()
        local e = Entity.new()
        e.vx = 99
        e.vy = 99
        e:setVelocity(50, nil)
        assert.are.equal(50, e.vx)
        assert.are.equal(0, e.vy)
    end)

    it("defaults missing vx to 0", function()
        local e = Entity.new()
        e.vx = 99
        e.vy = 99
        e:setVelocity(nil, 50)
        assert.are.equal(0, e.vx)
        assert.are.equal(50, e.vy)
    end)
end)

describe("Entity:setPosition", function()
    it("sets both position components", function()
        local e = Entity.new()
        e:setPosition(200, 300)
        assert.are.equal(200, e.x)
        assert.are.equal(300, e.y)
    end)

    it("defaults missing x to current x", function()
        local e = Entity.new(50, 50)
        e:setPosition(nil, 100)
        assert.are.equal(50, e.x)
        assert.are.equal(100, e.y)
    end)

    it("defaults missing y to current y", function()
        local e = Entity.new(50, 50)
        e:setPosition(100, nil)
        assert.are.equal(100, e.x)
        assert.are.equal(50, e.y)
    end)
end)

describe("Entity:collidesWith", function()
    it("detects collision with overlapping entities", function()
        local a = Entity.new(0, 0, 32, 32)
        local b = Entity.new(10, 10, 32, 32)
        assert.is_true(a:collidesWith(b))
        assert.is_true(b:collidesWith(a))
    end)

    it("returns false for non-overlapping entities", function()
        local a = Entity.new(0, 0, 32, 32)
        local b = Entity.new(100, 100, 32, 32)
        assert.is_false(a:collidesWith(b))
    end)

    it("does not collide with edge-to-edge touching entities (strict AABB)", function()
        local a = Entity.new(0, 0, 32, 32)
        local b = Entity.new(32, 0, 32, 32)
        -- a right edge at 16, b left edge at 16 → 16 < 16 is false, no collision
        assert.is_false(a:collidesWith(b))
    end)

    it("does not collide with corner-to-corner touching entities (strict AABB)", function()
        local a = Entity.new(0, 0, 32, 32)
        local b = Entity.new(32, 32, 32, 32)
        assert.is_false(a:collidesWith(b))
    end)

    it("returns false if either entity is inactive", function()
        local a = Entity.new(0, 0, 32, 32)
        local b = Entity.new(10, 10, 32, 32)
        a.active = false
        assert.is_false(a:collidesWith(b))
        a.active = true
        b.active = false
        assert.is_false(a:collidesWith(b))
    end)

    it("returns false if both entities are inactive", function()
        local a = Entity.new(0, 0, 32, 32)
        local b = Entity.new(10, 10, 32, 32)
        a.active = false
        b.active = false
        assert.is_false(a:collidesWith(b))
    end)

    it("handles entities with non-default center origins", function()
        local a = Entity.new(100, 100, 50, 50)
        local b = Entity.new(130, 130, 40, 40)
        -- a: (75..125, 75..125), b: (110..150, 110..150) -> overlap
        assert.is_true(a:collidesWith(b))
    end)
end)

describe("Entity:draw", function()
    it("sets color and draws a rectangle for active entity", function()
        love.graphics._lastColor = nil
        love.graphics._lastRect = nil

        local e = Entity.new(100, 200, 32, 32)
        e:draw()

        -- Entity:draw calls setColor(self.color) where self.color is {1,1,1,1}
        -- our mock handles table args correctly
        assert.is_not_nil(love.graphics._lastColor)
        assert.are.equal(1, love.graphics._lastColor[1])
        assert.are.equal(1, love.graphics._lastColor[2])
        assert.are.equal(1, love.graphics._lastColor[3])
        assert.are.equal(1, love.graphics._lastColor[4])
        assert.is_not_nil(love.graphics._lastRect)
        assert.are.equal("fill", love.graphics._lastRect.mode)
    end)

    it("does not draw inactive entity", function()
        love.graphics._lastColor = nil
        love.graphics._lastRect = nil

        local e = Entity.new(100, 200, 32, 32)
        e.active = false
        e:draw()

        -- setColor and rectangle should NOT have been called (they'll be nil
        -- since nothing resets them)
        assert.is_nil(love.graphics._lastColor)
        assert.is_nil(love.graphics._lastRect)
    end)
end)

describe("Entity:extend", function()
    it("returns a new class inheriting from Entity", function()
        local SubEntity = Entity:extend()
        assert.is_table(SubEntity)
        assert.is_function(SubEntity.new)
    end)

    it("instances of subclass inherit Entity methods", function()
        local SubEntity = Entity:extend()
        local instance = SubEntity.new(10, 20, 32, 32)
        assert.are.equal(10, instance.x)
        assert.are.equal(20, instance.y)
        assert.is_function(instance.update)
        assert.is_function(instance.collidesWith)
    end)

    it("subclass can override methods without affecting Entity", function()
        local SubEntity = Entity:extend()
        local original = Entity.new
        function SubEntity:new(x, y)
            local inst = Entity.new(self, x, y)
            inst.custom = true
            return inst
        end
        -- Entity.new should still work normally
        local e = Entity.new(10, 20)
        assert.is_nil(e.custom)
    end)
end)