-- Rato Teste NPC — extends base NPC with wandering and dialogue
local NPC = require("src.entities.npc")
local RatoTeste = setmetatable({}, { __index = NPC })
RatoTeste.__index = RatoTeste

local utils = require("src.utils")
local HALF_COLLIDER = 16

local debug_helpers = require("src.debug_helpers")

-- Constants
local WANDER_RADIUS = 320   -- 10 tiles × 32px
local WANDER_PAUSE_MIN = 2  -- seconds
local WANDER_PAUSE_MAX = 4  -- seconds

-- Sprite path prefix for this NPC
local SPRITE_PREFIX = "assets/images/sprites/npc/npc_rato_piratas"

function RatoTeste.new(world, x, y)
    -- Call base NPC constructor (which sets up collider, sprites, animations)
    local self = NPC.new(world, x, y, SPRITE_PREFIX)

    -- Override metatable so RatoTeste methods take priority over NPC
    setmetatable(self, RatoTeste)

    self.dialogue = {
        {
            text = "Ahoy, matey! Are ye lost?",
            choices = {
                { key = "y", text = "[Y] Yes", next = 2 },
                { key = "n", text = "[N] No",  next = 3 },
            }
        },
        {
            text = "You're aboard the mighty Pirate Ship, docked at Tortuga Harbor. The captain's quarters be to the north, and the cargo hold below deck. Watch yer step, sailor!"
        },
        {
            text = "Good day to you then! Safe travels, and may the winds be at yer back!"
        }
    }
    -- Wandering state
    self.originX = x
    self.originY = y
    self._wanderTimer = 0       -- countdown until next walk
    self._wanderWaitDuration = RatoTeste._randomPause()

    debug_helpers.log(string.format("RatoTeste spawned at (%d, %d)", x, y), "DEBUG")

    return self
end

function RatoTeste:update(dt, mapW, mapH, playerX, playerY)
    -- Call base NPC update first (handles walk-to movement + velocity + stuck/rude/wobble)
    NPC.update(self, dt, mapW, mapH, playerX, playerY)

    -- Only wander when idle (not already walking to a target)
    if self.state ~= "idle" then return end

    self._wanderTimer = self._wanderTimer + dt

    if self._wanderTimer >= self._wanderWaitDuration then
        -- Pick a new random destination within radius of origin
        local angle = love.math.random() * math.pi * 2
        local distance = love.math.random() * WANDER_RADIUS
        -- Clamp wander target within map bounds too
        local targetX = utils.clamp(
            self.originX + math.cos(angle) * distance,
            HALF_COLLIDER, mapW - HALF_COLLIDER)
        local targetY = utils.clamp(
            self.originY + math.sin(angle) * distance,
            HALF_COLLIDER, mapH - HALF_COLLIDER)

        debug_helpers.log(string.format("RatoTeste wandering to (%d, %d)", targetX, targetY), "DEBUG")
        self:walkTo(targetX, targetY)

        -- Reset pause timer for after arrival
        self._wanderTimer = 0
        self._wanderWaitDuration = RatoTeste._randomPause()
    end
end

--- Private: random pause duration between 2-4 seconds
function RatoTeste._randomPause()
    return WANDER_PAUSE_MIN + love.math.random() * (WANDER_PAUSE_MAX - WANDER_PAUSE_MIN)
end

return RatoTeste
