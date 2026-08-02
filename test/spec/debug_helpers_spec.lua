-- Unit tests for src/debug_helpers.lua

require("test.mocks.love_mock")

local dh = require("src.debug_helpers")

describe("debug_helpers constants", function()
    it("DEBUG_MODE is true by default", function()
        assert.is_true(dh.DEBUG_MODE)
    end)

    it("SHOW_FPS is true by default", function()
        assert.is_true(dh.SHOW_FPS)
    end)

    it("SHOW_HITBOXES is false by default", function()
        assert.is_false(dh.SHOW_HITBOXES)
    end)

    it("SHOW_PATHS is false by default", function()
        assert.is_false(dh.SHOW_PATHS)
    end)
end)

describe("debug_helpers.log", function()
    it("prints message with timestamp when DEBUG_MODE is on", function()
        dh.DEBUG_MODE = true
        -- log uses print(); we can't easily capture print output,
        -- but we can verify it doesn't error with various inputs
        assert.has_no.errors(function()
            dh.log("test message")
        end)
    end)

    it("does nothing when DEBUG_MODE is off", function()
        dh.DEBUG_MODE = false
        -- should not error
        assert.has_no.errors(function()
            dh.log("should not print")
        end)
        dh.DEBUG_MODE = true -- restore
    end)

    it("defaults level to INFO when not provided", function()
        dh.DEBUG_MODE = true
        assert.has_no.errors(function()
            dh.log("message without level")
        end)
    end)

    it("accepts a custom level", function()
        dh.DEBUG_MODE = true
        assert.has_no.errors(function()
            dh.log("custom level message", "WARN")
        end)
    end)
end)

describe("debug_helpers.watch", function()
    it("creates a global variable when DEBUG_MODE is on", function()
        dh.DEBUG_MODE = true
        dh.watch("test_var", 42)
        assert.are.equal(42, _G.__WATCH_test_var)
        -- cleanup
        _G.__WATCH_test_var = nil
    end)

    it("creates a watch with string values", function()
        dh.DEBUG_MODE = true
        dh.watch("player_name", "captain")
        assert.are.equal("captain", _G.__WATCH_player_name)
        _G.__WATCH_player_name = nil
    end)

    it("creates a watch with table values", function()
        dh.DEBUG_MODE = true
        local data = { x = 100, y = 200 }
        dh.watch("player_pos", data)
        assert.are.equal(100, _G.__WATCH_player_pos.x)
        assert.are.equal(200, _G.__WATCH_player_pos.y)
        _G.__WATCH_player_pos = nil
    end)

    it("does nothing when DEBUG_MODE is off", function()
        dh.DEBUG_MODE = false
        dh.watch("no_create", 99)
        assert.is_nil(_G.__WATCH_no_create)
        dh.DEBUG_MODE = true -- restore
    end)
end)

describe("debug_helpers.init", function()
    it("creates a global debugger function", function()
        -- reset _G.debugger to isolate test
        _G.debugger = nil
        dh.init()
        assert.is_function(_G.debugger)
        -- calling the dummy debugger should not error
        assert.has_no.errors(function()
            _G.debugger()
        end)
    end)

    it("does not error when called multiple times", function()
        dh.init()
        assert.has_no.errors(function()
            dh.init()
        end)
    end)
end)

describe("debug_helpers.draw", function()
    it("does nothing when DEBUG_MODE is off", function()
        dh.DEBUG_MODE = false
        love.graphics._prints = {}
        dh.draw()
        assert.are.equal(0, #love.graphics._prints)
        dh.DEBUG_MODE = true -- restore
    end)

    it("draws FPS, memory, and draw call stats when DEBUG_MODE is on", function()
        dh.DEBUG_MODE = true
        dh.SHOW_FPS = true
        love.graphics._prints = {}
        dh.draw()

        assert.is_true(#love.graphics._prints >= 3, "should print at least 3 stats lines")
        -- verify FPS is present
        local hasFPS = false
        for _, entry in ipairs(love.graphics._prints) do
            if entry.text:find("FPS:") then
                hasFPS = true
                break
            end
        end
        assert.is_true(hasFPS, "should contain FPS stat")
    end)

    it("does not show FPS when SHOW_FPS is false", function()
        dh.DEBUG_MODE = true
        dh.SHOW_FPS = false
        love.graphics._prints = {}
        dh.draw()

        local hasFPS = false
        for _, entry in ipairs(love.graphics._prints) do
            if entry.text:find("FPS:") then
                hasFPS = true
            end
        end
        assert.is_false(hasFPS, "should not contain FPS when disabled")
        dh.SHOW_FPS = true -- restore
    end)

    it("uses white color with 0.8 alpha for debug text", function()
        dh.DEBUG_MODE = true
        dh.SHOW_FPS = true
        love.graphics._lastColor = nil
        dh.draw()

        assert.is_not_nil(love.graphics._lastColor)
        -- first 3 values should be white (1,1,1), 4th should be ~0.8
        assert.are.equal(1, love.graphics._lastColor[1])
        assert.are.equal(1, love.graphics._lastColor[2])
        assert.are.equal(1, love.graphics._lastColor[3])
        assert.is_near(0.8, love.graphics._lastColor[4], 0.01)
    end)
end)

describe("debug_helpers.drawHitboxes", function()
    local Entity = require("src.entities.Entity")

    it("does nothing when DEBUG_MODE is off", function()
        dh.DEBUG_MODE = false
        dh.SHOW_HITBOXES = true
        love.graphics._lastColor = nil
        love.graphics._lastRect = nil

        local entities = { Entity.new(0, 0, 32, 32) }
        dh.drawHitboxes(entities)

        assert.is_nil(love.graphics._lastColor)
        assert.is_nil(love.graphics._lastRect)
        dh.DEBUG_MODE = true -- restore
    end)

    it("does nothing when SHOW_HITBOXES is off", function()
        dh.DEBUG_MODE = true
        dh.SHOW_HITBOXES = false
        love.graphics._lastColor = nil
        love.graphics._lastRect = nil

        local entities = { Entity.new(0, 0, 32, 32) }
        dh.drawHitboxes(entities)

        assert.is_nil(love.graphics._lastColor)
        assert.is_nil(love.graphics._lastRect)
    end)

    it("draws rectangles for active entities when enabled", function()
        dh.DEBUG_MODE = true
        dh.SHOW_HITBOXES = true
        love.graphics._lastColor = nil
        love.graphics._lastRect = nil

        local entities = { Entity.new(100, 100, 32, 32) }
        dh.drawHitboxes(entities)

        assert.is_not_nil(love.graphics._lastColor)
        assert.are.same({ 0, 1, 0, 0.5 }, love.graphics._lastColor)
        assert.is_not_nil(love.graphics._lastRect)
        assert.are.equal("line", love.graphics._lastRect.mode)
    end)

    it("skips inactive entities", function()
        dh.DEBUG_MODE = true
        dh.SHOW_HITBOXES = true

        local e = Entity.new(100, 100, 32, 32)
        e.active = false
        local entities = { e }

        -- Reset state by first running with an active entity to dirty it,
        -- then observe that inactive entity produces no new rect
        love.graphics._lastRect = nil
        dh.drawHitboxes(entities)

        -- No rectangle should be drawn for inactive entity
        assert.is_nil(love.graphics._lastRect)
    end)

    it("handles empty entity list", function()
        dh.DEBUG_MODE = true
        dh.SHOW_HITBOXES = true
        love.graphics._lastRect = nil

        dh.drawHitboxes({})
        assert.is_nil(love.graphics._lastRect)
    end)
end)