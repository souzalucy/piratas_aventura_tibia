-- Main entry point for the Love2D game
-- This file initializes the game and sets up the Love2D callbacks

-- Enable debugging with Local Lua Debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

-- Import modules
--local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")
local anim8 = require("libraries/anim8")
local camera = require("libraries/camera")
local sti = require("libraries/sti")
local wf = require("libraries/windfield")

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
    walls = {} -- wall colliders — physics only, no update/drawable
}

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

    -- Create player entity
    game.player = {}
    game.player.x = 400
    game.player.y = 200

    game.player.collider = game.world:newBSGRectangleCollider(400, 200, 32, 32, 4)
    game.player.collider:setFixedRotation(true)
    game.player.speed = 50

    game.player.spriteSheetDown = love.graphics.newImage("assets/images/sprites/down.png")
    game.player.spriteSheetUp = love.graphics.newImage("assets/images/sprites/up.png")
    game.player.spriteSheetLeft = love.graphics.newImage("assets/images/sprites/left.png")
    game.player.spriteSheetRight = love.graphics.newImage("assets/images/sprites/right.png")

    game.player.gridDown = anim8.newGrid(64, 64, game.player.spriteSheetDown:getWidth(),
        game.player.spriteSheetDown:getHeight())
    game.player.gridUp = anim8.newGrid(64, 64, game.player.spriteSheetUp:getWidth(),
        game.player.spriteSheetUp:getHeight())
    game.player.gridLeft = anim8.newGrid(64, 64, game.player.spriteSheetLeft:getWidth(),
        game.player.spriteSheetLeft:getHeight())
    game.player.gridRight = anim8.newGrid(64, 64, game.player.spriteSheetRight:getWidth(),
        game.player.spriteSheetRight:getHeight())

    game.player.animation = {}
    game.player.animation.Down = anim8.newAnimation(game.player.gridDown('1-9', 1), 0.1)
    game.player.animation.Up = anim8.newAnimation(game.player.gridUp('1-9', 1), 0.1)
    game.player.animation.Left = anim8.newAnimation(game.player.gridLeft('1-9', 1), 0.1)
    game.player.animation.Right = anim8.newAnimation(game.player.gridRight('1-9', 1), 0.1)

    game.player.spriteSheet = game.player.spriteSheetDown
    game.player.animations = game.player.animation.Down
    debug_helpers.log("Player created")

    -- Walls: physics only
    if game.map.layers["walls"] then
        for _, obj in pairs(game.map.layers["walls"].objects) do
            local wall = game.world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType("static")
            table.insert(game.walls, wall) -- store reference, not for update/draw loops
        end
    end
end

-- Called every frame to update game state
-- dt is the time elapsed since the last update in seconds
function love.update(dt)
    -- Update the physics world
    local isMoving = false

    local vx = 0
    local vy = 0

    -- Handle keyboard input for player movement
    if love.keyboard.isDown("right") then
        vx = game.player.speed
        game.player.animations = game.player.animation.Right
        game.player.spriteSheet = game.player.spriteSheetRight
        isMoving = true
    end

    if love.keyboard.isDown("left") then
        vx = -game.player.speed
        game.player.animations = game.player.animation.Left
        game.player.spriteSheet = game.player.spriteSheetLeft
        isMoving = true
    end

    if love.keyboard.isDown("up") then
        vy = -game.player.speed
        game.player.animations = game.player.animation.Up
        game.player.spriteSheet = game.player.spriteSheetUp
        isMoving = true
    end

    if love.keyboard.isDown("down") then
        vy = game.player.speed
        game.player.animations = game.player.animation.Down
        game.player.spriteSheet = game.player.spriteSheetDown
        isMoving = true
    end

    -- Normalize diagonal movement
    if vx ~= 0 and vy ~= 0 then
        local length = math.sqrt(vx * vx + vy * vy)
        vx = vx / length * game.player.speed
        vy = vy / length * game.player.speed
    end

    game.player.collider:setLinearVelocity(vx, vy)

    -- animation logic
    if isMoving == false then
        game.player.animations:gotoFrame(1)
    end

    -- World update
    game.world:update(dt)
    game.player.x = game.player.collider:getX()
    game.player.y = game.player.collider:getY()

    game.player.animations:update(dt)

    -- Camera follows the player
    game.cam:lookAt(game.player.x, game.player.y)

    -- Get the map dimensions
    local mapW = game.map.width * game.map.tilewidth
    local mapH = game.map.height * game.map.tileheight

    -- Get the window dimensions
    local w, h = love.graphics.getDimensions()
    local halfW = math.min(w, mapW) / 2
    local halfH = math.min(h, mapH) / 2

    -- cam limit to left boarder
    if game.cam.x < halfW then
        game.cam.x = halfW
    end

    -- cam limit to top boarder
    if game.cam.y < halfH then
        game.cam.y = halfH
    end

    -- cam limit to right boarder
    if w < mapW and game.cam.x > mapW - halfW then
        game.cam.x = mapW - halfW
    end

    -- cam limit to bottom boarder
    if h < mapH and game.cam.y > mapH - halfH then
        game.cam.y = mapH - halfH
    end

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

    game.cam:attach()
    game.map:drawLayer(game.map.layers["ground"])
    game.map:drawLayer(game.map.layers["trees"])
    game.player.animations:draw(game.player.spriteSheet, game.player.x, game.player.y, nil, nil, nil, 48, 48)

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
        love.event.quit()
    end

    -- uncomment to see colliders
    if key == "f1" then
        showColliders = not showColliders
    end

    -- Example of using the debugger function
    if key == "f9" then
        debug_helpers.log("Manual breakpoint triggered", "DEBUG")
        debugger() -- This will pause execution if the debugger is active
    end
end
