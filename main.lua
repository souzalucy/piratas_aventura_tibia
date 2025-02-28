-- Main entry point for the Love2D game
-- This file initializes the game and sets up the Love2D callbacks

-- Enable debugging with Local Lua Debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

-- Import modules
local Entity = require("src.Entity")
local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")

-- Game state variables
local game = {
    -- Game settings
    background_color = { 0.1, 0.1, 0.2 },
    entities = {},
    player = nil
}

-- Called once when the game starts
function love.load()
    -- Initialize debug helpers
    debug_helpers.init()
    debug_helpers.log("Game starting", "INFO")

    -- Set window title (can also be set in conf.lua)
    love.window.setTitle("Love2D Cursor Template")

    -- Set default font
    love.graphics.setNewFont(16)

    -- For pixel art games, disable filtering for crisp pixels
    -- love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create player entity
    game.player = Entity.new(400, 300, 40, 40)
    game.player.color = utils.colors.blue
    game.player.speed = 200
    table.insert(game.entities, game.player)
    debug_helpers.log("Player entity created")

    -- Create some random entities
    for i = 1, 5 do
        local entity = Entity.new(
            love.math.random(100, 700),
            love.math.random(100, 500),
            love.math.random(20, 60),
            love.math.random(20, 60)
        )
        entity.color = utils.colors.withAlpha(
            { love.math.random(), love.math.random(), love.math.random() },
            0.8
        )
        entity:setVelocity(
            love.math.random(-50, 50),
            love.math.random(-50, 50)
        )
        table.insert(game.entities, entity)
    end
    debug_helpers.log("Created " .. #game.entities - 1 .. " random entities")
end

-- Called every frame to update game state
-- dt is the time elapsed since the last update in seconds
function love.update(dt)
    -- Handle keyboard input for player movement
    local dx, dy = 0, 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = dx - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = dx + 1
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        dy = dy - 1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        dy = dy + 1
    end

    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx = dx / length
        dy = dy / length
    end

    -- Set player velocity
    game.player:setVelocity(dx * game.player.speed, dy * game.player.speed)

    -- Update all entities
    for _, entity in ipairs(game.entities) do
        entity:update(dt)

        -- Bounce entities off screen edges
        if entity ~= game.player then
            if entity.x - entity.width / 2 < 0 or entity.x + entity.width / 2 > love.graphics.getWidth() then
                entity.vx = -entity.vx
            end
            if entity.y - entity.height / 2 < 0 or entity.y + entity.height / 2 > love.graphics.getHeight() then
                entity.vy = -entity.vy
            end
        end
    end

    -- Keep player within screen bounds
    game.player.x = utils.clamp(game.player.x, game.player.width / 2, love.graphics.getWidth() - game.player.width / 2)
    game.player.y = utils.clamp(game.player.y, game.player.height / 2, love.graphics.getHeight() - game.player.height / 2)

    -- Check for collisions with player
    for i, entity in ipairs(game.entities) do
        if entity ~= game.player and game.player:collidesWith(entity) then
            -- Change color on collision
            entity.color = utils.colors.blend(entity.color, utils.colors.red, 0.1)

            -- Rotate on collision
            entity.rotation = entity.rotation + dt * 2

            -- Log collision in debug mode
            debug_helpers.log("Collision detected with entity " .. i, "DEBUG")
        end
    end

    -- Update debug watches
    debug_helpers.watch("player_pos", { x = game.player.x, y = game.player.y })
    debug_helpers.watch("entity_count", #game.entities)
end

-- Called every frame to render the game
function love.draw()
    -- Set background color
    love.graphics.setBackgroundColor(game.background_color)

    -- Draw all entities
    for _, entity in ipairs(game.entities) do
        entity:draw()
    end

    -- Draw hitboxes in debug mode
    debug_helpers.drawHitboxes(game.entities)

    -- Draw instructions
    love.graphics.setColor(utils.colors.white)
    love.graphics.print("Use arrow keys or WASD to move", 10, 10)
    love.graphics.print("Press Escape to quit", 10, 30)
    love.graphics.print("Press F1 to toggle hitboxes", 10, 50)

    -- Draw debug information
    debug_helpers.draw()
end

-- Called when a key is pressed
function love.keypressed(key)
    -- Quit the game when Escape is pressed
    if key == "escape" then
        love.event.quit()
    end

    -- Toggle debug features
    if key == "f1" then
        debug_helpers.SHOW_HITBOXES = not debug_helpers.SHOW_HITBOXES
        debug_helpers.log("Hitboxes " .. (debug_helpers.SHOW_HITBOXES and "enabled" or "disabled"))
    end

    -- Example of using the debugger function
    if key == "f9" then
        debug_helpers.log("Manual breakpoint triggered", "DEBUG")
        debugger() -- This will pause execution if the debugger is active
    end
end
