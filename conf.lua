function love.conf(t)
    t.title = "A Pirate Adventure in a Furry Word" -- TODO: Change this to your own title
    t.version = "11.5" -- The LÖVE version this game was made formally

    -- Window settings
    t.window.width = 800
    t.window.minwidth = 800
    t.window.height = 600
    t.window.minheight = 600
    t.window.resizable = true
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"

    -- Disable unused modules to save memory
    t.modules.joystick = false
    t.modules.physics = true
    t.modules.video = false

    -- Enable console output for debugging
    t.console = true
end
