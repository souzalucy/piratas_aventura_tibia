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

    -- Dialogue state
    self.dialogue = {}
    self._inDialogue = false
    self._currentDialogueId = 0

    debug_helpers.log(string.format("NPC created at (%d, %d) with prefix '%s'", x, y, sprite_prefix), "DEBUG")

    return self
end

--- Set a walk destination. NPC will move toward it each update.
function NPC:walkTo(targetX, targetY)
    debug_helpers.log(string.format("NPC walking to (%d, %d)", targetX, targetY), "DEBUG")
    self._targetX = targetX
    self._targetY = targetY
    self.state = STATE.WALKING
end

function NPC:update(dt, mapW, mapH)
    -- Freeze all movement during dialogue
    if self._inDialogue then
        self._vx = 0
        self._vy = 0
        self.collider:setLinearVelocity(0, 0)
        self.animations:gotoFrame(1)
        return
    end

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
            debug_helpers.log(string.format("NPC arrived at (%d, %d), entering idle", self.x, self.y), "DEBUG")
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
        debug_helpers.log(string.format("NPC clamped to (%d, %d), stopping walk", clampedX, clampedY), "DEBUG")
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

function NPC:drawUI(playerX, playerY)
    -- Dialogue bubble (always on top of fog)
    if self._inDialogue then
        local entry = self.dialogue[self._currentDialogueId]
        if entry then
            self:_drawDialogueBubble(entry.text, entry.choices)
        end
    end

    -- "E" interaction hint
    if not self._inDialogue and playerX and playerY and self:canInteract(playerX, playerY) then
        self:drawInteractionHint()
    end
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

function NPC:_drawDialogueBubble(text, choices)
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight() + 2
    local maxWidth = 200

    -- Build display text: main text + choice hints
    local displayText = text
    if choices then
        displayText = displayText .. "\n"
        for _, c in ipairs(choices) do
            displayText = displayText .. "\n  " .. c.text
        end
    else
        displayText = displayText .. "\n\n  [E] Continue"
    end

    local _, wrappedLines = font:getWrap(displayText, maxWidth)
    local boxHeight = #wrappedLines * lineHeight + 16
    local boxWidth = maxWidth + 16
    local bx = self.x - boxWidth / 2
    local by = self.y - 60 - boxHeight

    -- Bubble background
    love.graphics.setColor(0.05, 0.05, 0.08, 0.9)
    love.graphics.rectangle("fill", bx, by, boxWidth, boxHeight, 6, 6)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.9)
    love.graphics.rectangle("line", bx, by, boxWidth, boxHeight, 6, 6)

    -- Tail
    love.graphics.setColor(0.05, 0.05, 0.08, 0.9)
    love.graphics.polygon("fill", self.x - 6, self.y - 48, self.x + 6, self.y - 48, self.x, self.y - 40)

    -- Text (white, wrapped)
    love.graphics.setColor(1, 1, 1, 1)
    for i, line in ipairs(wrappedLines) do
        love.graphics.print(line, bx + 8, by + 4 + (i - 1) * lineHeight)
    end
    love.graphics.setColor(1, 1, 1, 1)
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

    if not self._showDialogue then
        -- First press: start dialogue
        self._dialogueIndex = 1
        self._showDialogue = true
    else
        -- Subsequent presses: advance or close
        if self._dialogueIndex < #self.dialogue then
            self._dialogueIndex = self._dialogueIndex + 1
        else
            self._showDialogue = false
            self._dialogueIndex = 0
            return  -- don't reset timer
        end
    end
    self._dialogueTimer = 0
end

function NPC:startDialogue(playerX, playerY)
    if #self.dialogue == 0 then
        debug_helpers.log("NPC: no dialogue defined", "DEBUG")
        return
    end
    self._inDialogue = true
    self._currentDialogueId = 1
    self:faceTowards(playerX, playerY)
    debug_helpers.log(string.format("NPC: dialogue started, entry 1/%d", #self.dialogue), "DEBUG")
end

function NPC:advanceDialogue()
    if not self._inDialogue then return end

    local entry = self.dialogue[self._currentDialogueId]
    if not entry then
        self:_endDialogue()
        return
    end

    -- If current entry has choices, "E" does NOT advance — wait for Y/N
    if entry.choices then return end

    -- No choices: advance to next or close
    debug_helpers.log(string.format("NPC: advancing dialogue %d -> %d", self._currentDialogueId, self._currentDialogueId + 1), "DEBUG")
    self._currentDialogueId = self._currentDialogueId + 1
    if self._currentDialogueId > #self.dialogue then
        self:_endDialogue()
    end
end

function NPC:handleDialogueInput(key)
    if not self._inDialogue then return false end

    local entry = self.dialogue[self._currentDialogueId]
    if not entry or not entry.choices then return false end

    for _, choice in ipairs(entry.choices) do
        if key == choice.key then
            debug_helpers.log(string.format("NPC: dialogue choice '%s' -> entry %d", key, choice.next), "DEBUG")
            self._currentDialogueId = choice.next
            return true
        end
    end
    return false
end

function NPC:_endDialogue()
    debug_helpers.log("NPC: dialogue ended", "DEBUG")
    self._inDialogue = false
    self._currentDialogueId = 0
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
