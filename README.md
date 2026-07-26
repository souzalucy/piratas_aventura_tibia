# Pirate Adventure in a Furry World

A 2D top-down RPG adventure game built with [LÖVE](https://love2d.org/) 11.5.

## Overview

Explore a tile-based world with pixel art sprites, physics-based movement, and a dynamic fog of war system that reveals the map as you travel.

## Features

- **Pixel Art Character**: 4-directional animated sprites (up/down/left/right) with 9-frame walk cycles
- **Physics-Based Movement**: Diagonal normalization, map boundary clamping via windfield colliders
- **Fog of War**: Tiles transition from unexplored → explored → visible based on player proximity
- **Smooth Camera**: Follows the player with boundary clamping
- **Tile Map**: Ground and tree layers rendered via STI

## Project Structure

```
├── assets/              # Game assets (images, sprites, backgrounds)
│   └── images/
│       ├── backgrounds/ # Map tiles (ground, trees)
│       └── sprites/     # Player directional sprites
├── src/                 # Game source code
│   ├── player.lua       # Player entity (input, movement, animation)
│   ├── fog_of_war.lua   # Fog of war visibility system
│   ├── Entity.lua       # Base entity class
│   ├── utils.lua        # Math and camera utilities
│   └── debug_helpers.lua # Debug logging, watches, overlay
├── libraries/           # Third-party libraries
│   ├── anim8.lua        # Sprite animation
│   ├── camera.lua       # Camera system
│   ├── sti/             # Simple Tiled Implementation (map loader)
│   └── windfield/       # Physics wrapper
├── maps/                # Tile maps (.tmx + .lua export)
├── test/                # Unit tests (busted)
│   ├── mocks/           # Mock Löve2D modules
│   └── spec/            # Test specifications
├── scripts/             # Build scripts
│   └── make.sh          # macOS .love + .app build
├── conf.lua             # LÖVE configuration
└── main.lua             # Game entry point
```

## Getting Started

### Prerequisites

- [LÖVE 11.5](https://love2d.org/)

### Running

```bash
love .
```

Or drag the project folder onto the LÖVE application icon.

### Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move character |
| Escape | Quit |
| F1 | Toggle hitbox/collider display |
| F9 | Trigger debugger breakpoint |

## Building

### macOS

```bash
./scripts/make.sh
```

Creates a `.love` file and a distributable macOS `.app` bundle in `dist/`.

### Other Platforms

Zip the project contents into a `.love` file and follow the [Love2D distribution guide](https://love2d.org/wiki/Game_Distribution).

## Development

### Code Quality

| Tool | Config | Purpose |
|------|--------|---------|
| StyLua | `stylua.toml` | Lua code formatter |
| Luacheck | `.luacheckrc` | Static analysis / linting |
| EditorConfig | `.editorconfig` | Consistent editor settings |

### Running Tests

```bash
busted
```

Tests live under `test/spec/` and use mocked Löve2D modules from `test/mocks/`.

## License

MIT. See [LICENSE](LICENSE) for details.