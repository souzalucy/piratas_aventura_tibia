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
local Player = require("src.entities.player")
local Npc = require("src.entities.npc.rato_teste")
local Inventory = require("src.ui.inventory")
local WorldItems = require("src.entities.items")
local Item = require("src.entities.items.item")


-- Game state variables
local game          = {
    background_color = { 0.1, 0.1, 0.2 },
    entities = {},
    player = nil,
    npc = nil,
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
    visibility = {},
    inventory = nil,
    worldItems = nil,
}

-- Get the map dimensions
local mapW          = game.map.width * game.map.tilewidth
local mapH          = game.map.height * game.map.tileheight

-- Grid size for the map
local gridColumns   = game.map.width
local gridRows      = game.map.height

-- cam limits
local vw, vh        = game.vw, game.vh

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
    -- Get spawn position from map's "player" object layer
    local playerSpawnPoints = utils.getObjectPositions(game.map, "player")
    local playerSpawnX, playerSpawnY = playerSpawnPoints[1] and playerSpawnPoints[1].x or 400,
        playerSpawnPoints[1] and playerSpawnPoints[1].y or 200
    game.player = Player.new(game.world, playerSpawnX, playerSpawnY)
    debug_helpers.log("Player created")

    -- Get spawn position from map's "npc" object layer
    local npcSpawnPoints = utils.getObjectPositions(game.map, "npc")
    local npcSpawnX, npcSpawnY = npcSpawnPoints[1] and npcSpawnPoints[1].x or 400,
        npcSpawnPoints[1] and npcSpawnPoints[1].y or 200
    game.npc = Npc.new(game.world, npcSpawnX, npcSpawnY)
    debug_helpers.log("NPC created")

    debug_helpers.log(string.format("Map loaded: %dx%d tiles (%dx%d px)", game.map.width, game.map.height, mapW, mapH))

    -- Walls: physics only
    if game.map.layers["walls"] then
        for _, obj in pairs(game.map.layers["walls"].objects) do
            if obj.width > 0 and obj.height > 0 then
                local wall = game.world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                wall:setType("static")
                table.insert(game.walls, wall) -- store reference, not for update/draw loops
            end
        end
        debug_helpers.log(string.format("Created %d wall colliders", #game.walls))
    end

    -- Initialize visibility grid (fog of war)
    -- 0 = unexplored, 1 = explored (out of sight), 2 = currently visible
    game.visibility = FoW.init(gridColumns, gridRows)
    debug_helpers.log(string.format("Fog of War grid initialized: %dx%d", gridColumns, gridRows))

    -- Initialize inventory (PNG background not required — procedural fallback)
    game.inventory = Inventory.new("assets/images/ui/inventory_background.png")

    -- Initialize world items manager and load items from Tiled map item layers
    game.worldItems = WorldItems.new()
    game.worldItems:loadFromMap(game.map)
end

-- Called every frame to update game state
-- dt is the time elapsed since the last update in seconds
function love.update(dt)
    -- reads keyboards for Player movement
    game.player:handleInput()

    -- Player physics + clamp
    game.player:applyMovement(dt, mapW, mapH)

    -- Update NPC
    game.npc:update(dt, mapW, mapH, game.player.x, game.player.y)
    game.npc:updateAnimation(dt)

    -- Update camera to follow player
    game.cam:lookAt(game.player.x, game.player.y)

    -- Update the physics world
    game.world:update(dt)

    -- Update inventory timers (e.g., "Inventory Full!" message fade)
    game.inventory:update(dt)

    -- Update the fog of war visibility based on player position and view radius
    FoW.update(game.visibility, game.player.x, game.player.y, game.viewRadius, game.map.tilewidth, game.map.tileheight,
        gridColumns, gridRows)

    -- Check nearby world items for pickup prompt
    game.worldItems:clearPrompts()
    local nearbyItem = game.worldItems:findNearby(game.player.x, game.player.y, 64)
    if nearbyItem then
        nearbyItem._showPrompt = true
    end

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
    game.map:drawLayer(game.map.layers["decoration"])
    game.map:drawLayer(game.map.layers["trees_base"])

    -- Draw the player
    game.player:draw()

    -- Draw world items (replaces the old item1_padel tile layer)
    for _, entry in ipairs(game.worldItems.items) do
        local itemState = FoW.getState(game.visibility, entry.x, entry.y,
            game.map.tilewidth, game.map.tileheight, gridColumns, gridRows)
        if itemState == 2 then
            entry.item:draw(entry.x, entry.y)
        end
    end

    -- Draw the NPC — only when the tile under it is visible (state 2)
    local npcState = FoW.getState(game.visibility, game.npc.x, game.npc.y,
        game.map.tilewidth, game.map.tileheight, gridColumns, gridRows)
    if npcState == 2 then
        game.npc:draw()
    end

    game.map:drawLayer(game.map.layers["trees_upper"])
    
    -- Fog of War overlay: render over every tile on the map
    -- Cell 0 (unexplored) = opaque black
    -- Cell 1 (explored, out of sight) = dimmed
    -- Cell 2 (visible) = nothing drawn — tile shows through
    FoW.draw(game.visibility, game.map.tilewidth, game.map.tileheight, gridColumns, gridRows)

    love.graphics.setColor(1, 1, 1, 1)

    -- UI layer (rendered AFTER fog, always visible)
    game.npc:drawUI(game.player.x, game.player.y)

    if showColliders then
        game.world:draw()
    end

    -- Draw pickup prompts for world items near the player (only when inventory is closed)
    if not game.inventory:isOpen() then
        for _, entry in ipairs(game.worldItems.items) do
            if entry._showPrompt then
                local font = love.graphics.getFont()
                local text = "[F] Pick up"
                local textW = font:getWidth(text)
                local textH = font:getHeight()
                local padX, padY = 8, 4
                local bubbleW, bubbleH = textW + padX * 2, textH + padY * 2
                local bubbleX = entry.x - bubbleW / 2
                local bubbleY = entry.y - 28 - bubbleH

                local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(0.05, 0.05, 0.08, 0.85)
                love.graphics.rectangle("fill", bubbleX, bubbleY, bubbleW, bubbleH, 4, 4)
                love.graphics.setColor(1, 0.85, 0.4, 1)
                love.graphics.print(text, bubbleX + padX, bubbleY + padY)
                love.graphics.setColor(r, g, b, a)
            end
        end
    end

    -- Draw "E" interaction hint above the NPC when player is within 2 tiles
    if not game.npc._inDialogue and game.npc:canInteract(game.player.x, game.player.y) then
        game.npc:drawInteractionHint()
    end

    game.cam:detach()

    -- Inventory UI (drawn in screen space, on top of everything)
    game.inventory:draw()

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

    if key == "e" then
        if game.npc._inDialogue then
            -- In dialogue: advance or handle choice
            debug_helpers.log("Key 'e' pressed — advancing dialogue", "DEBUG")
            game.npc:advanceDialogue()
        elseif game.npc:canInteract(game.player.x, game.player.y) then
            debug_helpers.log("Key 'e' pressed — starting dialogue with NPC", "DEBUG")
            game.npc:startDialogue(game.player.x, game.player.y)
        end
    end

    if key == "y" or key == "n" then
        if game.npc:handleDialogueInput(key) then
            debug_helpers.log(string.format("Key '%s' — dialogue choice handled", key), "DEBUG")
        end
    end

    -- Inventory toggle
    if key == "tab" then
        game.inventory:toggle()
    end

    -- Pick up nearby item
    if key == "f" and not game.inventory:isOpen() then
        local nearby = game.worldItems:findNearby(game.player.x, game.player.y, 64)
        if nearby then
            local added = game.inventory:addItem(nearby.item)
            if added then
                game.worldItems:remove(nearby)
            end
        end
    end
end

-- Called when the mouse is pressed
function love.mousepressed(x, y, button, istouch, presses)
    if game.inventory:isOpen() then
        local droppedItem = game.inventory:mousepressed(x, y, button)
        if droppedItem then
            -- Drop item at player's feet
            game.worldItems:spawnAt(droppedItem, game.player.x, game.player.y)
        end
    end
end

-- Called when the mouse moves
function love.mousemoved(x, y, dx, dy, istouch)
    if game.inventory:isOpen() then
        game.inventory:mousemoved(x, y)
    end
end

-- Called when the mouse is released
function love.mousereleased(x, y, button, istouch, presses)
    if game.inventory:isOpen() then
        game.inventory:mousereleased(x, y, button)
    end
end
