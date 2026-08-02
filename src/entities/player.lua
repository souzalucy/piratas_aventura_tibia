-- Player module — handles creation, input, movement, animation, and rendering
local Player = {}

local anim8 = require("libraries/anim8")
local utils = require("src/utils")
local debug_helpers = require("src/debug_helpers")

-- Sprite frame size (32x48 from the 96x192 combined sheet: 3 cols × 4 rows)
local FRAME_W, FRAME_H = 32, 48
-- Draw offset so the sprite centers on the collider (collider is 32px)
local DRAW_OFFSET_X = 16
local DRAW_OFFSET_Y = 32
-- Half the collider size for boundary clamping
local HALF_COLLIDER = 16


function Player.new(world, x, y)
    local self = setmetatable({}, { __index = Player })

    debug_helpers.log(string.format("Player.new() at (%d, %d)", x, y), "DEBUG")

    -- Position
    self.x = x
    self.y = y
    self.speed = 50

    -- Physics collider (32x32, offset by 4 from sprite edges)
    self.collider = world:newBSGRectangleCollider(x, y, 32, 32, 4)
    self.collider:setFixedRotation(true)

    -- Internal movement state
    self._vx = 0
    self._vy = 0
    self._isMoving = false

    -- === Sprite sheet (single combined 96x192: 3 cols × 4 rows) ===
    -- Row 1 = down, row 2 = up, row 3 = left, row 4 = right
    self.spriteSheet = love.graphics.newImage("assets/images/sprites/player/hernandez_cortez.png")

    -- === Animation grid ===
    self.grid = anim8.newGrid(FRAME_W, FRAME_H,
        self.spriteSheet:getWidth(), self.spriteSheet:getHeight())

    -- === Animations ===
    -- 3 frames per direction (cols 1-3), each direction on its own row
    self.animation = {}
    self.animation.Down  = anim8.newAnimation(self.grid('1-3', 1), 0.1)
    self.animation.Up    = anim8.newAnimation(self.grid('1-3', 2), 0.1)
    self.animation.Left  = anim8.newAnimation(self.grid('1-3', 4), 0.1)
    self.animation.Right = anim8.newAnimation(self.grid('1-3', 3), 0.1)

    -- Current active animation (default: facing down, idle)
    self.animations = self.animation.Down

    -- Track previous direction to avoid log spam
    self._lastDirection = nil

    return self
end


function Player:handleInput()
    -- Resets
    self._vx = 0
    self._vy = 0
    self._isMoving = false

    local newDirection = nil

    -- Lines 119-150 of main.lua — 4 directional checks
    if love.keyboard.isDown("right") then
        self._vx = self.speed
        self.animations = self.animation.Right
        self._isMoving = true
        newDirection = "right"
    end
    if love.keyboard.isDown("left") then
        self._vx = -self.speed
        self.animations = self.animation.Left
        self._isMoving = true
        newDirection = "left"
    end
    if love.keyboard.isDown("up") then
        self._vy = -self.speed
        self.animations = self.animation.Up
        self._isMoving = true
        newDirection = "up"
    end
    if love.keyboard.isDown("down") then
        self._vy = self.speed
        self.animations = self.animation.Down
        self._isMoving = true
        newDirection = "down"
    end

    if newDirection ~= self._lastDirection then
        debug_helpers.log(string.format("Player direction changed: %s", newDirection or "idle"), "DEBUG")
        self._lastDirection = newDirection
    end
end


function Player:applyMovement(dt, mapW, mapH)
    -- Normalize diagonal movement
    -- Lines 149-151 of main.lua
    local vx, vy = utils.normalizeVector(self._vx, self._vy, self.speed)

    -- Apply velocity to physics collider
    -- Line 153 of main.lua
    self.collider:setLinearVelocity(vx, vy)

    -- Idle animation: freeze on frame 1
    -- Line 156-158 of main.lua
    if not self._isMoving then
        self.animations:gotoFrame(1)
    end

    -- Camera lookAt is NOT here — it stays in main.lua (separation of concerns)

    -- Sync position from physics world
    -- Lines 163-165 of main.lua
    self.x = self.collider:getX()
    self.y = self.collider:getY()

    -- Clamp to map boundaries
    -- Lines 168-171 of main.lua
    local clampedX = utils.clamp(self.x, HALF_COLLIDER, mapW - HALF_COLLIDER)
    local clampedY = utils.clamp(self.y, HALF_COLLIDER, mapH - HALF_COLLIDER)
    if self.x ~= clampedX or self.y ~= clampedY then
        debug_helpers.log(string.format("Player clamped to map boundary at (%d, %d)", clampedX, clampedY), "DEBUG")
    end
    self.x = clampedX
    self.y = clampedY
    self.collider:setX(self.x)
    self.collider:setY(self.y)
end


function Player:updateAnimation(dt)
    -- Line 176 of main.lua
    self.animations:update(dt)
end


function Player:draw()
    -- Line 206 of main.lua
    -- Params: spriteSheet, x, y, rotation, sx, sy, ox, oy
    -- ox=16, oy=48 centers the 32x48 sprite on the 32px collider
    self.animations:draw(self.spriteSheet, self.x, self.y, nil, nil, nil,
        DRAW_OFFSET_X, DRAW_OFFSET_Y)
end


return Player