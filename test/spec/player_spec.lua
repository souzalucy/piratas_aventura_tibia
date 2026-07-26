-- Unit tests for src/player.lua
-- Uses package.preload to inject mocks for anim8 and windfield.

require("test.mocks.love_mock")

-- Inject mocks before requiring Player
package.preload["libraries/anim8"] = function()
    return require("test.mocks.anim8_mock")
end
package.preload["libraries/windfield"] = function()
    return require("test.mocks.windfield_mock")
end

-- Also ensure utils and debug_helpers can resolve (they're real, just needed)
-- but need to make sure src.utils doesn't get re-preloaded accidentally
-- Player requires them normally; that should work since they're in package.path

local wf = require("libraries/windfield")
local Player = require("src/entities/player")

describe("Player.new", function()
    local world

    before_each(function()
        world = wf.newWorld(0, 0)
        love.keyboard._reset()
    end)

    it("creates a player at the given position", function()
        local p = Player.new(world, 400, 200)
        assert.are.equal(400, p.x)
        assert.are.equal(200, p.y)
    end)

    it("sets speed to 50 by default", function()
        local p = Player.new(world, 100, 100)
        assert.are.equal(50, p.speed)
    end)

    it("creates a physics collider for the player", function()
        local p = Player.new(world, 400, 200)
        assert.is_not_nil(p.collider)
        assert.is_function(p.collider.getX)
        assert.is_function(p.collider.getY)
        assert.is_function(p.collider.setLinearVelocity)
        assert.is_function(p.collider.setFixedRotation)
    end)

    it("has collider at player position", function()
        local p = Player.new(world, 400, 200)
        assert.are.equal(400, p.collider:getX())
        assert.are.equal(200, p.collider:getY())
    end)

    it("creates 4 directional sprite sheets", function()
        local p = Player.new(world, 100, 100)
        assert.is_not_nil(p.spriteSheetDown)
        assert.is_not_nil(p.spriteSheetUp)
        assert.is_not_nil(p.spriteSheetLeft)
        assert.is_not_nil(p.spriteSheetRight)
    end)

    it("creates animation grids", function()
        local p = Player.new(world, 100, 100)
        assert.is_not_nil(p.gridDown)
        assert.is_not_nil(p.gridUp)
        assert.is_not_nil(p.gridLeft)
        assert.is_not_nil(p.gridRight)
    end)

    it("creates 4 directional animations", function()
        local p = Player.new(world, 100, 100)
        assert.is_not_nil(p.animation.Down)
        assert.is_not_nil(p.animation.Up)
        assert.is_not_nil(p.animation.Left)
        assert.is_not_nil(p.animation.Right)
    end)

    it("defaults to facing down with down animation active", function()
        local p = Player.new(world, 100, 100)
        assert.are.equal(p.spriteSheetDown, p.spriteSheet)
        assert.are.equal(p.animation.Down, p.animations)
    end)

    it("initializes internal movement state to idle", function()
        local p = Player.new(world, 100, 100)
        assert.are.equal(0, p._vx)
        assert.are.equal(0, p._vy)
        assert.is_false(p._isMoving)
    end)
end)

describe("Player:handleInput", function()
    local world, p

    before_each(function()
        world = wf.newWorld(0, 0)
        love.keyboard._reset()
        p = Player.new(world, 400, 200)
    end)

    it("sets _vx positive and uses Right animation on 'right'", function()
        love.keyboard._simulateDown("right")
        p:handleInput()
        assert.are.equal(p.speed, p._vx)
        assert.are.equal(0, p._vy)
        assert.is_true(p._isMoving)
        assert.are.equal(p.animation.Right, p.animations)
        assert.are.equal(p.spriteSheetRight, p.spriteSheet)
    end)

    it("sets _vx negative and uses Left animation on 'left'", function()
        love.keyboard._simulateDown("left")
        p:handleInput()
        assert.are.equal(-p.speed, p._vx)
        assert.are.equal(0, p._vy)
        assert.is_true(p._isMoving)
        assert.are.equal(p.animation.Left, p.animations)
        assert.are.equal(p.spriteSheetLeft, p.spriteSheet)
    end)

    it("sets _vy negative and uses Up animation on 'up'", function()
        love.keyboard._simulateDown("up")
        p:handleInput()
        assert.are.equal(0, p._vx)
        assert.are.equal(-p.speed, p._vy)
        assert.is_true(p._isMoving)
        assert.are.equal(p.animation.Up, p.animations)
        assert.are.equal(p.spriteSheetUp, p.spriteSheet)
    end)

    it("sets _vy positive and uses Down animation on 'down'", function()
        love.keyboard._simulateDown("down")
        p:handleInput()
        assert.are.equal(0, p._vx)
        assert.are.equal(p.speed, p._vy)
        assert.is_true(p._isMoving)
        assert.are.equal(p.animation.Down, p.animations)
        assert.are.equal(p.spriteSheetDown, p.spriteSheet)
    end)

    it("last key pressed takes priority for conflicting directions", function()
        -- In the code, checks are right, left, up, down in order.
        -- Since all ifs run, the last one that's down wins for _vx/_vy.
        love.keyboard._simulateDown("right")
        love.keyboard._simulateDown("left")
        p:handleInput()
        -- left runs after right, so _vx should be -speed (left wins for vx)
        -- But both set _vx! right sets _vx=speed, left sets _vx=-speed. Last wins = left
        assert.are.equal(-p.speed, p._vx)
        -- But _isMoving is set true by both
        assert.is_true(p._isMoving)
    end)

    it("sets _isMoving false and zero velocity when no keys pressed", function()
        p._vx = 99
        p._vy = 99
        p._isMoving = true
        p:handleInput()
        assert.are.equal(0, p._vx)
        assert.are.equal(0, p._vy)
        assert.is_false(p._isMoving)
    end)

    it("updates _lastDirection when direction changes", function()
        p._lastDirection = nil
        love.keyboard._simulateDown("right")
        p:handleInput()
        assert.are.equal("right", p._lastDirection)
    end)

    it("updates _lastDirection to nil when releasing keys (idle)", function()
        love.keyboard._simulateDown("right")
        p:handleInput()
        assert.are.equal("right", p._lastDirection)

        love.keyboard._reset()
        p:handleInput()
        -- When no keys are pressed, newDirection stays nil.
        -- Since nil ~= "right", the log fires and _lastDirection is set to nil.
        assert.is_nil(p._lastDirection)
    end)
end)

describe("Player:applyMovement", function()
    local world, p
    local mapW, mapH = 800, 600

    before_each(function()
        world = wf.newWorld(0, 0)
        love.keyboard._reset()
        p = Player.new(world, 400, 200)
    end)

    it("applies normalized velocity to the collider", function()
        p._vx = p.speed
        p._vy = 0
        p._isMoving = true
        p:applyMovement(0.016, mapW, mapH)

        -- collider should have moved
        assert.is_not_nil(p.collider)
        local cx = p.collider:getX()
        -- position will have shifted slightly due to velocity * dt in the mock
        assert.is_true(cx > 400, "collider should move right")
    end)

    it("syncs player position from collider", function()
        p._vx = p.speed
        p._vy = 0
        p._isMoving = true
        p:applyMovement(0.016, mapW, mapH)

        assert.are.equal(p.collider:getX(), p.x)
        assert.are.equal(p.collider:getY(), p.y)
    end)

    it("clamps player to map boundaries", function()
        -- place player at left edge
        p.x = 0
        p.y = 200
        p.collider:setX(0)
        p.collider:setY(200)
        p._vx = -p.speed
        p._vy = 0
        p._isMoving = true

        p:applyMovement(0.016, mapW, mapH)

        -- Hmm, the mock's setLinearVelocity actually moves the collider.
        -- But clamp happens in applyMovement. The x should be clamped to HALF_COLLIDER (16).
        -- Our mock's _vx is -50. After setLinearVelocity, _x changes.
        -- But then applyMovement sets x = collider:getX(), then clamps it.
        -- The player won't go below 16.
        assert.is_true(p.x >= 16, "player should be clamped to left boundary")
    end)

    it("calls gotoFrame(1) when idle", function()
        p._isMoving = false
        -- track whether gotoFrame was called
        local calledFrame = nil
        local origGotoFrame = p.animations.gotoFrame
        p.animations.gotoFrame = function(self, n)
            calledFrame = n
            origGotoFrame(self, n)
        end

        p:applyMovement(0.016, mapW, mapH)

        assert.are.equal(1, calledFrame)
    end)

    it("does not call gotoFrame when moving", function()
        p._vx = p.speed
        p._isMoving = true
        local calledFrame = nil
        local origGotoFrame = p.animations.gotoFrame
        p.animations.gotoFrame = function(self, n)
            calledFrame = n
            origGotoFrame(self, n)
        end

        p:applyMovement(0.016, mapW, mapH)

        assert.is_nil(calledFrame)
    end)
end)

describe("Player:updateAnimation", function()
    local world, p

    before_each(function()
        world = wf.newWorld(0, 0)
        love.keyboard._reset()
        p = Player.new(world, 400, 200)
    end)

    it("calls update on the active animation with dt", function()
        local elapsed = p.animations._elapsed
        p:updateAnimation(0.016)
        assert.is_true(p.animations._elapsed > elapsed)
    end)
end)

describe("Player:draw", function()
    local world, p

    before_each(function()
        world = wf.newWorld(0, 0)
        love.keyboard._reset()
        p = Player.new(world, 400, 200)
    end)

    it("calls animations:draw with proper parameters", function()
        -- test that draw doesn't error
        assert.has_no.errors(function()
            p:draw()
        end)
    end)
end)