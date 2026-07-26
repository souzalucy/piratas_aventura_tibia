-- Main entry point for the Love2D game
-- This file initializes the game and sets up the Love2D callbacks

-- Enable debugging with Local Lua Debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

-- Import modules
local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")
local camera = require("libraries/camera")
local sti = require("libraries/sti")
local wf = require("libraries/windfield")
local FoW = require("src.fog_of_war")
local Player = require("src/entities/player")


-- Game state variables
local game = {
    background_color = { 0.1, 0.1, 0.2 },
    entities = {},
    player = nil,
    -- create camera
    cam = camera(),
    -- world creation
    world = wf.newWorld(0, 0),
    -- create the map
    map = sti("maps/map.lua"),
    walls = {}, -- wall colliders — physics only, no update/drawable
    vw = 200,
    vh = 200,
    viewRadius = 150,
    visibility = {}
}

-- Get the map dimensions
local mapW = game.map.width * game.map.tilewidth
local mapH = game.map.height * game.map.tileheight

-- Grid size for the map
local gridColumns = game.map.width
local gridRows    = game.map.height

-- cam limits
local vw, vh = game.vw, game.vh

-- Genral local variables
local showColliders = false

-- Called once when the game starts
function love.load()
    -- Initialize debug helpers
    debug_helpers.init()
    debug_helpers.log("Game starting", "INFO")

    -- Set default font
    love.graphics.setNewFont(16)

    -- For pixel art games, disable filtering for crisp pixels
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create the player at a starting position
    local playerLayer = game.map.layers["player"]
    local spawnX, spawnY = 400, 200 -- fallback
    if playerLayer and playerLayer.objects and #playerLayer.objects > 0 then
        local spawnObj = playerLayer.objects[1]
        spawnX = spawnObj.x
        spawnY = spawnObj.y
    end
    game.player = Player.new(game.world, spawnX, spawnY)
    debug_helpers.log("Player created")

    debug_helpers.log(string.format("Map loaded: %dx%d tiles (%dx%d px)", game.map.width, game.map.height, mapW, mapH))

    -- Walls: physics only
    if game.map.layers["walls"] then
        for _, obj in pairs(game.map.layers["walls"].objects) do
            local wall = game.world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType("static")
            table.insert(game.walls, wall) -- store reference, not for update/draw loops
        end
        debug_helpers.log(string.format("Created %d wall colliders", #game.walls))
    end

    -- Initialize visibility grid (fog of war)
    -- 0 = unexplored, 1 = explored (out of sight), 2 = currently visible
    game.visibility = FoW.init(gridColumns, gridRows)
    debug_helpers.log(string.format("Fog of War grid initialized: %dx%d", gridColumns, gridRows))
end

-- Called every frame to update game state
-- dt is the time elapsed since the last update in seconds
function love.update(dt)

    -- reads keyboards for Player movement
    game.player:handleInput()

    -- Player physics + clamp
    game.player:applyMovement(dt, mapW, mapH)

    -- Update camera to follow player
    game.cam:lookAt(game.player.x, game.player.y)

    -- Update the physics world
    game.world:update(dt)

    -- Update the fog of war visibility based on player position and view radius
    FoW.update(game.visibility, game.player.x, game.player.y, game.viewRadius, game.map.tilewidth, game.map.tileheight, gridColumns, gridRows)

    -- Update player animations
    game.player:updateAnimation(dt)

    -- Clamp camera to map boundaries
    utils.clampCamera(game.cam, mapW, mapH, vw, vh)

    -- Update debug watches
    debug_helpers.watch("player_pos", { x = game.player.x, y = game.player.y })
    debug_helpers.watch("entity_count", #game.entities)
end

-- Called every frame to render the game
function love.draw()
    -- Set background color
    love.graphics.setBackgroundColor(game.background_color)

    -- Draw instructions
    --love.graphics.setColor(utils.colors.white)
    love.graphics.print("Use arrow keys or WASD to move", 10, 10)
    love.graphics.print("Press Escape to quit", 10, 30)
    love.graphics.print("Press F1 to toggle hitboxes", 10, 50)

    -- Use actual screen center for viewport positioning
    local screenW, screenH = love.graphics.getDimensions()

    -- Camera transform — full screen, no scissor clipping
    game.cam:attach(0, 0, screenW, screenH, true)

    -- Draw the game world
    game.map:drawLayer(game.map.layers["ground"])
    game.map:drawLayer(game.map.layers["trees"])

    -- Draw the player
    game.player:draw()

    -- Fog of War overlay: render over every tile on the map
    -- Cell 0 (unexplored) = opaque black
    -- Cell 1 (explored, out of sight) = dimmed
    -- Cell 2 (visible) = nothing drawn — tile shows through
    FoW.draw(game.visibility, game.map.tilewidth, game.map.tileheight, gridColumns, gridRows)

    love.graphics.setColor(1, 1, 1, 1)

    if showColliders then
        game.world:draw()
    end

    game.cam:detach()

    -- Draw debug information
    debug_helpers.draw()
end

-- Called when a key is pressed
function love.keypressed(key)
    -- Quit the game when Escape is pressed
    if key == "escape" then
        debug_helpers.log("Quit game triggered", "INFO")
        love.event.quit()
    end

    -- Toggle collider visibility
    if key == "f1" then
        showColliders = not showColliders
        debug_helpers.log(string.format("Hitbox display: %s", showColliders and "ON" or "OFF"), "DEBUG")
    end

    -- Example of using the debugger function
    if key == "f9" then
        debug_helpers.log("Manual breakpoint triggered", "DEBUG")
        debugger() -- This will pause execution if the debugger is active
    end
end
