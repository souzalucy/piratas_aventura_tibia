-- Unit tests for src/entities/npc.lua
-- Uses package.preload to inject mocks for anim8 and windfield.

require("test.mocks.love_mock")

-- Inject mocks before requiring NPC
package.preload["libraries/anim8"] = function()
    return require("test.mocks.anim8_mock")
end
package.preload["libraries/windfield"] = function()
    return require("test.mocks.windfield_mock")
end

local wf = require("libraries/windfield")
local NPC = require("src.entities.npc")

local SPRITE_PREFIX = "assets/images/sprites/npc/npc_rato_piratas"

describe("NPC.new", function()
    local world

    before_each(function()
        world = wf.newWorld(0, 0)
    end)

    it("creates an NPC at the given position", function()
        local npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
        assert.are.equal(400, npc.x)
        assert.are.equal(200, npc.y)
    end)

    it("sets speed to 30 by default", function()
        local npc = NPC.new(world, 100, 100, SPRITE_PREFIX)
        assert.are.equal(30, npc.speed)
    end)

    it("creates a physics collider", function()
        local npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
        assert.is_not_nil(npc.collider)
        assert.is_function(npc.collider.getX)
        assert.is_function(npc.collider.getY)
        assert.is_function(npc.collider.setLinearVelocity)
        assert.is_function(npc.collider.setFixedRotation)
    end)

    it("starts in IDLE state with nil targets", function()
        local npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
        assert.are.equal("idle", npc.state)
        assert.is_nil(npc._targetX)
        assert.is_nil(npc._targetY)
        assert.are.equal(0, npc._vx)
        assert.are.equal(0, npc._vy)
    end)

    it("creates 4 directional sprite sheets", function()
        local npc = NPC.new(world, 100, 100, SPRITE_PREFIX)
        assert.is_not_nil(npc.spriteSheetDown)
        assert.is_not_nil(npc.spriteSheetUp)
        assert.is_not_nil(npc.spriteSheetLeft)
        assert.is_not_nil(npc.spriteSheetRight)
    end)

    it("creates 4 directional animations", function()
        local npc = NPC.new(world, 100, 100, SPRITE_PREFIX)
        assert.is_not_nil(npc.animation.Down)
        assert.is_not_nil(npc.animation.Up)
        assert.is_not_nil(npc.animation.Left)
        assert.is_not_nil(npc.animation.Right)
    end)

    it("defaults to empty dialogue and not in dialogue", function()
        local npc = NPC.new(world, 100, 100, SPRITE_PREFIX)
        assert.are.same({}, npc.dialogue)
        assert.is_false(npc._inDialogue)
        assert.are.equal(0, npc._currentDialogueId)
    end)
end)

describe("NPC:walkTo", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("sets target coordinates and state to WALKING", function()
        npc:walkTo(500, 300)
        assert.are.equal(500, npc._targetX)
        assert.are.equal(300, npc._targetY)
        assert.are.equal("walking", npc.state)
    end)
end)

describe("NPC:update", function()
    local world, npc
    local mapW, mapH = 800, 600

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("freezes movement during dialogue", function()
        npc._inDialogue = true
        npc.collider:setLinearVelocity(10, 10)
        npc:update(0.016, mapW, mapH)
        assert.are.equal(0, npc._vx)
        assert.are.equal(0, npc._vy)
    end)

    it("syncs position from collider", function()
        npc.collider:setX(410)
        npc.collider:setY(210)
        npc:update(0.016, mapW, mapH)
        assert.are.equal(410, npc.x)
        assert.are.equal(210, npc.y)
    end)

    it("moves toward target when walking", function()
        npc:walkTo(500, 200)
        npc:update(0.016, mapW, mapH)
        -- vx should be positive (moving right toward 500)
        assert.is_true(npc._vx > 0, "NPC should move right toward target")
        assert.are.near(0, npc._vy, 1)
    end)

    it("stops and enters IDLE on arrival close to target", function()
        -- Place NPC very close to target (dist < 2 means < 2px)
        npc.x = 499
        npc.y = 200
        npc.collider:setX(499)
        npc.collider:setY(200)
        npc:walkTo(500, 200)
        npc:update(0.016, mapW, mapH)
        assert.are.equal("idle", npc.state)
        assert.is_nil(npc._targetX)
        assert.is_nil(npc._targetY)
    end)

    it("clamps to map boundaries and enters IDLE", function()
        npc.x = 0
        npc.y = 200
        npc.collider:setX(0)
        npc.collider:setY(200)
        npc._vx = -50
        npc.collider:setLinearVelocity(-50, 0)
        npc:walkTo(-100, 200)
        npc:update(0.016, mapW, mapH)
        -- should be clamped to at least HALF_COLLIDER (16)
        assert.is_true(npc.x >= 16, "NPC should be clamped inside left boundary")
        assert.are.equal("idle", npc.state)
    end)

    it("goes to frame 1 when idle", function()
        npc.state = "idle"
        npc._targetX = nil
        npc._targetY = nil
        npc:update(0.016, mapW, mapH)
        assert.are.equal(0, npc._vx)
        assert.are.equal(0, npc._vy)
        assert.are.equal(1, npc.animations._currentFrame)
    end)
end)

describe("NPC:canInteract", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("returns true when player is within default distance (64px)", function()
        assert.is_true(npc:canInteract(440, 220))
    end)

    it("returns false when player is too far", function()
        assert.is_false(npc:canInteract(600, 500))
    end)

    it("returns true with custom distance", function()
        -- NPC at (400,200), player at (500,300) → dist ≈ 141.4 < 300
        assert.is_true(npc:canInteract(500, 300, 300))
    end)

    it("returns false with custom distance when still too far", function()
        assert.is_false(npc:canInteract(600, 500, 100))
    end)

    it("returns true when player at exact same position", function()
        assert.is_true(npc:canInteract(400, 200))
    end)
end)

describe("NPC:faceTowards", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("faces right when target is to the right", function()
        npc:faceTowards(500, 200)
        assert.are.equal(npc.spriteSheetRight, npc.spriteSheet)
    end)

    it("faces left when target is to the left", function()
        npc:faceTowards(300, 200)
        assert.are.equal(npc.spriteSheetLeft, npc.spriteSheet)
    end)

    it("faces down when target is below", function()
        npc:faceTowards(400, 300)
        assert.are.equal(npc.spriteSheetDown, npc.spriteSheet)
    end)

    it("faces up when target is above", function()
        npc:faceTowards(400, 100)
        assert.are.equal(npc.spriteSheetUp, npc.spriteSheet)
    end)

    it("freezes on frame 1 after facing", function()
        npc.animations._currentFrame = 5
        npc:faceTowards(500, 200)
        assert.are.equal(1, npc.animations._currentFrame)
    end)
end)

describe("NPC dialogue system", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
        npc.dialogue = {
            { text = "Hello!" },
            { text = "How are you?" },
            { text = "Goodbye!", choices = { { key = "y", text = "[Y] Yes", next = 1 }, { key = "n", text = "[N] No", next = 1 } } },
        }
    end)

    describe("startDialogue", function()
        it("sets _inDialogue true and starts at entry 1", function()
            npc:startDialogue(400, 100)
            assert.is_true(npc._inDialogue)
            assert.are.equal(1, npc._currentDialogueId)
        end)

        it("does nothing when dialogue is empty", function()
            npc.dialogue = {}
            npc:startDialogue(400, 100)
            assert.is_false(npc._inDialogue)
        end)
    end)

    describe("advanceDialogue", function()
        it("advances to next entry when no choices", function()
            npc._inDialogue = true
            npc._currentDialogueId = 1
            npc:advanceDialogue()
            assert.are.equal(2, npc._currentDialogueId)
        end)

        it("does not advance when entry has choices", function()
            npc._inDialogue = true
            npc._currentDialogueId = 3
            npc:advanceDialogue()
            assert.are.equal(3, npc._currentDialogueId, "should not advance past choices entry")
        end)

        it("ends dialogue after last entry", function()
            npc._inDialogue = true
            npc._currentDialogueId = 2
            npc:advanceDialogue()
            assert.are.equal(3, npc._currentDialogueId)
            npc:advanceDialogue() -- entry 3 has choices, can't advance with E
            npc._currentDialogueId = 4  -- simulate being past end
            npc:advanceDialogue()
            assert.is_false(npc._inDialogue, "dialogue should end after last entry")
        end)

        it("does nothing when not in dialogue", function()
            npc._inDialogue = false
            npc._currentDialogueId = 1
            npc:advanceDialogue()
            assert.are.equal(1, npc._currentDialogueId)
        end)
    end)

    describe("handleDialogueInput", function()
        it("returns true and advances for valid choice key", function()
            npc._inDialogue = true
            npc._currentDialogueId = 3
            local result = npc:handleDialogueInput("y")
            assert.is_true(result)
            assert.are.equal(1, npc._currentDialogueId)
        end)

        it("returns false for invalid choice key", function()
            npc._inDialogue = true
            npc._currentDialogueId = 3
            local result = npc:handleDialogueInput("x")
            assert.is_false(result)
            assert.are.equal(3, npc._currentDialogueId) -- unchanged
        end)

        it("returns false when not in dialogue", function()
            npc._inDialogue = false
            local result = npc:handleDialogueInput("y")
            assert.is_false(result)
        end)

        it("returns false when entry has no choices", function()
            npc._inDialogue = true
            npc._currentDialogueId = 1
            local result = npc:handleDialogueInput("y")
            assert.is_false(result)
        end)
    end)

    describe("_endDialogue", function()
        it("resets dialogue state", function()
            npc._inDialogue = true
            npc._currentDialogueId = 2
            npc:_endDialogue()
            assert.is_false(npc._inDialogue)
            assert.are.equal(0, npc._currentDialogueId)
        end)
    end)
end)

describe("NPC:draw", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("does not error when drawing", function()
        assert.has_no.errors(function()
            npc:draw()
        end)
    end)
end)

describe("NPC:drawInteractionHint", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("does not error when drawing", function()
        assert.has_no.errors(function()
            npc:drawInteractionHint()
        end)
    end)
end)

describe("NPC:drawUI", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("does not error when not in dialogue and not near player", function()
        assert.has_no.errors(function()
            npc:drawUI(100, 100)
        end)
    end)

    it("draws interaction hint when player is near", function()
        npc.x = 400
        npc.y = 200
        -- Player is close (420, 210 is within 64 px of 400, 200)
        assert.has_no.errors(function()
            npc:drawUI(420, 210)
        end)
    end)
end)

describe("NPC:updateAnimation", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("calls update on the active animation with dt", function()
        local elapsed = npc.animations._elapsed
        npc:updateAnimation(0.016)
        assert.is_true(npc.animations._elapsed > elapsed)
    end)
end)

describe("NPC stub methods", function()
    local world, npc

    before_each(function()
        world = wf.newWorld(0, 0)
        npc = NPC.new(world, 400, 200, SPRITE_PREFIX)
    end)

    it("NPC:trade() does not error", function()
        assert.has_no.errors(function()
            npc:trade()
        end)
    end)

    it("NPC:sell() does not error", function()
        assert.has_no.errors(function()
            npc:sell()
        end)
    end)

    it("NPC:buy() does not error", function()
        assert.has_no.errors(function()
            npc:buy()
        end)
    end)
end)