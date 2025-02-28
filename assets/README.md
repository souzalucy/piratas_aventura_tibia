# Assets Directory

This directory contains all the game assets such as:

- **Images**: Sprites, backgrounds, UI elements
- **Sounds**: Music, sound effects
- **Fonts**: Custom fonts for text rendering
- **Shaders**: GLSL shader files for special effects

## Recommended Structure

```
assets/
├── images/
│   ├── sprites/
│   ├── backgrounds/
│   └── ui/
├── sounds/
│   ├── music/
│   └── sfx/
├── fonts/
└── shaders/
```

## Usage Guidelines

1. Keep filenames lowercase and use underscores for spaces
2. Use appropriate file formats:
   - PNG for sprites and UI elements (with transparency)
   - JPG for backgrounds (without transparency)
   - OGG for audio files (good compression, open format)
   - TTF or OTF for fonts
   - GLSL for shaders
3. Include attribution information for third-party assets in a separate credits.txt file
4. Consider optimizing assets for performance:
   - Compress images appropriately
   - Use sprite sheets for related images
   - Keep audio files at appropriate quality levels

## Loading Assets

In Love2D, assets are typically loaded in the `love.load()` function:

```lua
function love.load()
    -- Load images
    sprites = {
        player = love.graphics.newImage("assets/images/sprites/player.png"),
        enemy = love.graphics.newImage("assets/images/sprites/enemy.png")
    }
    
    -- Load sounds
    sounds = {
        music = love.audio.newSource("assets/sounds/music/theme.ogg", "stream"),
        jump = love.audio.newSource("assets/sounds/sfx/jump.ogg", "static")
    }
    
    -- Load fonts
    fonts = {
        small = love.graphics.newFont("assets/fonts/main.ttf", 12),
        medium = love.graphics.newFont("assets/fonts/main.ttf", 24),
        large = love.graphics.newFont("assets/fonts/main.ttf", 36)
    }
    
    -- Load shaders
    shaders = {
        blur = love.graphics.newShader("assets/shaders/blur.glsl")
    }
end
``` 
