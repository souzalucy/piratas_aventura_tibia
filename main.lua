-- Main entry point for the Love2D game
-- This file initializes the game and sets up the Love2D callbacks

-- Enable debugging with Local Lua Debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

-- Import modules
local utils = require("src.utils")
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

    -- Initialize visibility grid (fog of war)
    -- 0 = unexplored, 1 = explored (out of sight), 2 = currently visible
    for col = 1, gridColumns do
        game.visibility[col] = {}
        for row = 1, gridRows do
            game.visibility[col][row] = 0
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
        vx, vy = utils.normalizeVector(vx, vy, game.player.speed)
    end

    game.player.collider:setLinearVelocity(vx, vy)

    -- animation logic
    if isMoving == false then
        game.player.animations:gotoFrame(1)
    end

    -- Camera follows the player
    game.cam:lookAt(game.player.x, game.player.y)
    -- World update
    game.world:update(dt)
    game.player.x = game.player.collider:getX()
    game.player.y = game.player.collider:getY()

    -- Clamp player to map boundaries (16 = half the 32px collider size)
    game.player.x = math.max(16, math.min(game.player.x, mapW - 16))
    game.player.y = math.max(16, math.min(game.player.y, mapH - 16))
    game.player.collider:setX(game.player.x)
    game.player.collider:setY(game.player.y)

    -- Fog of War: recompute visibility grid
    local tileW, tileH = game.map.tilewidth, game.map.tileheight
    local viewRadiusTiles = math.ceil(game.viewRadius / tileW)

    -- Demote all currently-visible cells to explored
    for col = 1, gridColumns do
        local colData = game.visibility[col]
        for row = 1, gridRows do
            if colData[row] == 2 then
                colData[row] = 1
            end
        end
    end

    -- Mark tiles within viewRadius as visible
    local playerCol = math.floor(game.player.x / tileW) + 1
    local playerRow = math.floor(game.player.y / tileH) + 1
    local minCol = math.max(1, playerCol - viewRadiusTiles)
    local maxCol = math.min(gridColumns, playerCol + viewRadiusTiles)
    local minRow = math.max(1, playerRow - viewRadiusTiles)
    local maxRow = math.min(gridRows, playerRow + viewRadiusTiles)
    local px, py = game.player.x, game.player.y

    for col = minCol, maxCol do
        local colData = game.visibility[col]
        local tileCenterX = (col - 0.5) * tileW
        for row = minRow, maxRow do
            local tileCenterY = (row - 0.5) * tileH
            local dx = tileCenterX - px
            local dy = tileCenterY - py
            if math.sqrt(dx * dx + dy * dy) <= game.viewRadius then
                colData[row] = 2
            end
        end
    end

    game.player.animations:update(dt)

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
    game.player.animations:draw(game.player.spriteSheet, game.player.x, game.player.y, nil, nil, nil, 48, 48)

    -- Fog of War overlay: render over every tile on the map
    -- Cell 0 (unexplored) = opaque black
    -- Cell 1 (explored, out of sight) = dimmed
    -- Cell 2 (visible) = nothing drawn — tile shows through
    local tileW, tileH = game.map.tilewidth, game.map.tileheight
    for col = 1, gridColumns do
        local colData = game.visibility[col]
        local worldX = (col - 1) * tileW
        for row = 1, gridRows do
            local cell = colData[row]
            if cell == 0 then
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.rectangle("fill", worldX, (row - 1) * tileH, tileW, tileH)
            elseif cell == 1 then
                love.graphics.setColor(0, 0, 0, 0.6)
                love.graphics.rectangle("fill", worldX, (row - 1) * tileH, tileW, tileH)
            end
        end
    end
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
