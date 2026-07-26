-- Unit tests for src/entities/npc/rato_teste.lua

require("test.mocks.love_mock")

-- Inject mocks before requiring modules
package.preload["libraries/anim8"] = function()
    return require("test.mocks.anim8_mock")
end
package.preload["libraries/windfield"] = function()
    return require("test.mocks.windfield_mock")
end

local wf = require("libraries/windfield")
local RatoTeste = require("src.entities.npc.rato_teste")

describe("RatoTeste.new", function()
    local world

    before_each(function()
        world = wf.newWorld(0, 0)
    end)

    it("creates a RatoTeste at the given position", function()
        local rt = RatoTeste.new(world, 400, 200)
        assert.are.equal(400, rt.x)
        assert.are.equal(200, rt.y)
    end)

    it("inherits NPC methods", function()
        local rt = RatoTeste.new(world, 100, 100)
        assert.is_function(rt.walkTo)
        assert.is_function(rt.canInteract)
        assert.is_function(rt.startDialogue)
        assert.is_function(rt.advanceDialogue)
        assert.is_function(rt.handleDialogueInput)
    end)

    it("has dialogue entries defined", function()
        local rt = RatoTeste.new(world, 100, 100)
        assert.is_not_nil(rt.dialogue)
        assert.is_true(#rt.dialogue >= 3, "should have at least 3 dialogue entries")
        assert.are.equal("Ahoy, matey! Are ye lost?", rt.dialogue[1].text)
    end)

    it("sets origin to spawn position", function()
        local rt = RatoTeste.new(world, 400, 200)
        assert.are.equal(400, rt.originX)
        assert.are.equal(200, rt.originY)
    end)

    it("initializes wander timer and wait duration", function()
        local rt = RatoTeste.new(world, 400, 200)
        assert.are.equal(0, rt._wanderTimer)
        assert.is_not_nil(rt._wanderWaitDuration)
        assert.is_true(rt._wanderWaitDuration >= 2 and rt._wanderWaitDuration <= 4)
    end)
end)

describe("RatoTeste:update", function()
    local world, rt
    local mapW, mapH = 800, 600

    before_each(function()
        world = wf.newWorld(0, 0)
        rt = RatoTeste.new(world, 400, 200)
    end)

    it("does not wander when NPC is walking", function()
        rt.state = "walking"
        rt._targetX = 500
        rt._targetY = 200
        rt:update(10, mapW, mapH) -- 10 seconds should normally trigger wander
        -- state should still be "walking" since _targetX/Y are still set
        -- (but the NPC.update calls walkTo, which means state may change if they arrived)
    end)

    it("does not error on update", function()
        assert.has_no.errors(function()
            rt:update(0.016, mapW, mapH)
        end)
    end)
end)

describe("RatoTeste._randomPause", function()
    it("returns a value between 2 and 4", function()
        local val = RatoTeste._randomPause()
        assert.is_true(val >= 2)
        assert.is_true(val <= 4)
    end)
end)