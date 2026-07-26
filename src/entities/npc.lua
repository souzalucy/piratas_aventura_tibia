-- NPC base module — shared functions for all NPCs (talk, walk, trade, sell, buy, etc.)
local NPC = {}
NPC.__index = NPC

local anim8 = require("libraries/anim8")
local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")

-- Constants (same as Player for consistency)
local FRAME_W, FRAME_H = 64, 64 -- sprite frame size
local DRAW_OFFSET = 48          -- centers 64px sprite on 32px collider
local HALF_COLLIDER = 16

-- States
local STATE = { IDLE = "idle", WALKING = "walking" }


function NPC.new(world, x, y, sprite_prefix)
    local self = setmetatable({}, NPC)

    -- Position
    self.x = x
    self.y = y
    self.speed = 30 -- slower than player (50)

    -- Physics collider (same setup as Player)
    self.collider = world:newBSGRectangleCollider(x, y, 32, 32, 4)
    self.collider:setFixedRotation(true)

    -- Movement state
    self._vx              = 0
    self._vy              = 0
    self._isMoving        = false
    self.state            = STATE.IDLE
    self._targetX         = nil -- walk destination
    self._targetY         = nil

    -- === Sprite sheets (4 directional) ===
    -- sprite_prefix e.g. "assets/images/sprites/npc/npc_rato_piratas"
    self.spriteSheetDown  = love.graphics.newImage(sprite_prefix .. "_down.png")
    self.spriteSheetUp    = love.graphics.newImage(sprite_prefix .. "_top.png")
    self.spriteSheetLeft  = love.graphics.newImage(sprite_prefix .. "_left.png")
    self.spriteSheetRight = love.graphics.newImage(sprite_prefix .. "_right.png")

    -- === Animation grids ===
    self.gridDown         = anim8.newGrid(FRAME_W, FRAME_H,
        self.spriteSheetDown:getWidth(), self.spriteSheetDown:getHeight())
    self.gridUp           = anim8.newGrid(FRAME_W, FRAME_H,
        self.spriteSheetUp:getWidth(), self.spriteSheetUp:getHeight())
    self.gridLeft         = anim8.newGrid(FRAME_W, FRAME_H,
        self.spriteSheetLeft:getWidth(), self.spriteSheetLeft:getHeight())
    self.gridRight        = anim8.newGrid(FRAME_W, FRAME_H,
        self.spriteSheetRight:getWidth(), self.spriteSheetRight:getHeight())

    -- === Animations ===
    self.animation        = {}
    self.animation.Down   = anim8.newAnimation(self.gridDown('1-9', 1), 0.1)
    self.animation.Up     = anim8.newAnimation(self.gridUp('1-9', 1), 0.1)
    self.animation.Left   = anim8.newAnimation(self.gridLeft('1-9', 1), 0.1)
    self.animation.Right  = anim8.newAnimation(self.gridRight('1-9', 1), 0.1)

    -- Default facing: down, idle
    self.spriteSheet      = self.spriteSheetDown
    self.animations       = self.animation.Down

    return self
end

--- Set a walk destination. NPC will move toward it each update.
function NPC:walkTo(targetX, targetY)
    self._targetX = targetX
    self._targetY = targetY
    self.state = STATE.WALKING
end

function NPC:update(dt)
    -- Sync position from physics
    self.x = self.collider:getX()
    self.y = self.collider:getY()

    if self.state == STATE.WALKING and self._targetX and self._targetY then
        local dx = self._targetX - self.x
        local dy = self._targetY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < 2 then
            -- Arrived
            self._vx = 0
            self._vy = 0
            self.state = STATE.IDLE
            self._targetX = nil
            self._targetY = nil
        else
            self._vx = (dx / dist) * self.speed
            self._vy = (dy / dist) * self.speed

            -- Set animation direction based on dominant axis
            if math.abs(dx) >= math.abs(dy) then
                if dx > 0 then
                    self.animations = self.animation.Right
                    self.spriteSheet = self.spriteSheetRight
                else
                    self.animations = self.animation.Left
                    self.spriteSheet = self.spriteSheetLeft
                end
            else
                if dy > 0 then
                    self.animations = self.animation.Down
                    self.spriteSheet = self.spriteSheetDown
                else
                    self.animations = self.animation.Up
                    self.spriteSheet = self.spriteSheetUp
                end
            end
        end
    else
        -- Idle: freeze on frame 1
        self._vx = 0
        self._vy = 0
        self.animations:gotoFrame(1)
    end

    -- Apply velocity to collider
    self.collider:setLinearVelocity(self._vx, self._vy)
end

--- Set a walk destination. NPC will move toward it each update.
function NPC:walkTo(targetX, targetY)
    self._targetX = targetX
    self._targetY = targetY
    self.state = STATE.WALKING
end

function NPC:update(dt, mapW, mapH)
    -- Sync position from physics
    self.x = self.collider:getX()
    self.y = self.collider:getY()

     -- Walk-to movement
    if self.state == STATE.WALKING and self._targetX and self._targetY then
        local dx = self._targetX - self.x
        local dy = self._targetY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < 2 then
            -- Arrived
            self._vx = 0
            self._vy = 0
            self.state = STATE.IDLE
            self._targetX = nil
            self._targetY = nil
        else
            self._vx = (dx / dist) * self.speed
            self._vy = (dy / dist) * self.speed

            -- Set animation direction based on dominant axis
            if math.abs(dx) >= math.abs(dy) then
                if dx > 0 then
                    self.animations = self.animation.Right
                    self.spriteSheet = self.spriteSheetRight
                else
                    self.animations = self.animation.Left
                    self.spriteSheet = self.spriteSheetLeft
                end
            else
                if dy > 0 then
                    self.animations = self.animation.Down
                    self.spriteSheet = self.spriteSheetDown
                else
                    self.animations = self.animation.Up
                    self.spriteSheet = self.spriteSheetUp
                end
            end
        end
    else
        -- Idle: freeze on frame 1
        self._vx = 0
        self._vy = 0
        self.animations:gotoFrame(1)
    end

    -- Apply velocity to collider
    self.collider:setLinearVelocity(self._vx, self._vy)

    -- Clamp to map boundaries
    local clampedX = utils.clamp(self.x, HALF_COLLIDER, mapW - HALF_COLLIDER)
    local clampedY = utils.clamp(self.y, HALF_COLLIDER, mapH - HALF_COLLIDER)
    if self.x ~= clampedX or self.y ~= clampedY then
        self.x = clampedX
        self.y = clampedY
        self.collider:setX(self.x)
        self.collider:setY(self.y)
        -- Stop walking if we hit a wall
        self.state = STATE.IDLE
        self._targetX = nil
        self._targetY = nil
    end
end

--- Check if player is within interaction range (distance in pixels, default 64 = 2 tiles)
function NPC:canInteract(playerX, playerY, distance)
    distance = distance or 64
    local dx = self.x - playerX
    local dy = self.y - playerY
    return math.sqrt(dx * dx + dy * dy) <= distance
end

function NPC:updateAnimation(dt)
    self.animations:update(dt)
end

function NPC:draw()
    self.animations:draw(self.spriteSheet, self.x, self.y, nil, nil, nil,
        DRAW_OFFSET, DRAW_OFFSET)
end

function NPC:drawInteractionHint()
    local bubbleX = self.x
    local bubbleY = self.y - 40
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.circle("fill", bubbleX, bubbleY, 12)
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.circle("line", bubbleX, bubbleY, 12)
    love.graphics.printf("E", bubbleX - 10, bubbleY - 10, 20, "center")
    love.graphics.setColor(r, g, b, a)
end

-- Face towards a target position (sets sprite direction, freezes on frame 1)
function NPC:faceTowards(targetX, targetY)
    local dx = targetX - self.x
    local dy = targetY - self.y

    if math.abs(dx) >= math.abs(dy) then
        if dx > 0 then
            self.animations = self.animation.Right
            self.spriteSheet = self.spriteSheetRight
        else
            self.animations = self.animation.Left
            self.spriteSheet = self.spriteSheetLeft
        end
    else
        if dy > 0 then
            self.animations = self.animation.Down
            self.spriteSheet = self.spriteSheetDown
        else
            self.animations = self.animation.Up
            self.spriteSheet = self.spriteSheetUp
        end
    end
    self.animations:gotoFrame(1)
end

--- Display dialogue when player interacts. Override in specific NPC.
function NPC:talk(playerX, playerY)
    -- Stop any walking
    self.state = STATE.IDLE
    self._targetX = nil
    self._targetY = nil
    self._vx = 0
    self._vy = 0

    -- Turn to face the player
    if playerX and playerY then
        self:faceTowards(playerX, playerY)
    end

    debug_helpers.log("NPC:talk() — no dialogue defined", "DEBUG")
end

function NPC:trade()
    debug_helpers.log("NPC:trade() — not implemented", "DEBUG")
end

function NPC:sell()
    debug_helpers.log("NPC:sell() — not implemented", "DEBUG")
end

function NPC:buy()
    debug_helpers.log("NPC:buy() — not implemented", "DEBUG")
end

return NPC
