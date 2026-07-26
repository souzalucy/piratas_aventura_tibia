# Love2D Cursor Template

A streamlined project template for developing games with the [LÖVE](https://love2d.org/) (Love2D) game engine using [Cursor](https://cursor.sh/) as your IDE.

## Overview

This template provides a clean, organized starting point for Love2D game development with built-in linting, formatting, and build tools. It's designed to help you focus on game creation while maintaining code quality and following best practices.

## Features

- **Pre-configured Project Structure**: Organized directories for source code, assets, and distribution
- **Code Quality Tools**: Integrated linting and formatting with Lua Language Server, Luacheck, and StyLua
- **Build Scripts**: Ready-to-use scripts for packaging your game for distribution
- **VSCode/Cursor Integration**: Pre-configured settings for an optimal development experience

## Project Structure

```
love2d-cursor-template/
├── assets/            # Game assets (images, sounds, fonts, etc.)
├── src/               # Source code files
├── dist/              # Distribution files (generated during build)
├── scripts/           # Build and utility scripts
├── conf.lua           # Love2D configuration
├── main.lua           # Game entry point
├── .luacheckrc        # Luacheck configuration
├── .editorconfig      # Editor configuration
└── stylua.toml        # StyLua formatter configuration
```

## Getting Started

1. **Clone this repository**:
   ```bash
   git clone https://github.com/yourusername/love2d-cursor-template.git your-game-name
   cd your-game-name
   ```

2. **Install Love2D**:
   Download and install from [love2d.org](https://love2d.org/)

3. **Open in Cursor**:
   Launch Cursor and open the project folder

4. **Install recommended extensions**:
   - [Lua Language Server](https://marketplace.cursorapi.com/items?itemName=sumneko.lua) - Provides intelligent code completion, diagnostics, and more
   - [Local Lua Debugger](https://marketplace.cursorapi.com/items?itemName=tomblind.local-lua-debugger-vscode) - Debug your Love2D games with breakpoints and variable inspection
   - [Love Launcher](https://marketplace.cursorapi.com/items?itemName=JanW.love-launcher) - Launch your Love2D game directly from Cursor with ALT+L
   - [vscode-luacheck](https://marketplace.cursorapi.com/items?itemName=dwenegar.vscode-luacheck) - Static analyzer for Lua code
   - [EditorConfig](https://marketplace.cursorapi.com/items?itemName=EditorConfig.EditorConfig) - Maintain consistent coding styles across editors

5. **Start coding**:
   - Edit `conf.lua` to set your game's title and other settings
   - Create your game logic in `main.lua` and the `src/` directory
   - Add your assets to the `assets/` directory

## Recommended Extensions

### Lua Language Server (sumneko.lua)
The most popular extension for Lua language support with nearly a million installs. It provides:
- Support for Lua 5.4, 5.3, 5.2, 5.1, and LuaJIT
- Over 20 supported annotations for documenting your code
- Dynamic type checking
- Go to definition and find references
- Diagnostics and warnings
- Syntax checking
- Element renaming
- Hover information and autocompletion

### Local Lua Debugger (tomblind.local-lua-debugger-vscode)
A simple Lua debugger with no additional dependencies:
- Debug Lua using stand-alone interpreter or a custom executable
- Supports Lua versions 5.1, 5.2, 5.3, and LuaJIT
- Basic debugging features (stepping, inspecting, breakpoints)
- Conditional breakpoints
- Debug coroutines as separate threads

To use with Love2D, add this configuration to your `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Love",
      "type": "lua-local",
      "request": "launch",
      "program": {
        "command": "love"
      },
      "args": [
        "${workspaceFolder}"
      ],
      "scriptRoots": [
        "${workspaceFolder}"
      ]
    }
  ]
}
```

### Love Launcher (JanW.love-launcher)
A simple extension that allows you to launch your Love2D game with a keyboard shortcut:
- Press ALT+L to launch your Love2D project
- Configure the path to your Love2D executable in settings

### vscode-luacheck (dwenegar.vscode-luacheck)
Integrates the Luacheck static analyzer into Cursor:
- Detects various issues in your code
- Checks for unused variables and functions
- Identifies potential bugs
- Works with the included `.luacheckrc` configuration file

### EditorConfig (EditorConfig.EditorConfig)
Helps maintain consistent coding styles across different editors:
- Enforces consistent indentation, line endings, and more
- Works with the included `.editorconfig` file
- Ensures code style consistency across your team

## Building Your Game

### macOS

Run the included build script:

```bash
./scripts/make.sh
```

This will:
- Create a `.love` file containing your game
- Package it as a macOS application
- Create a distributable ZIP file in the `dist/` directory

### Other Platforms

For Windows and Linux distribution, you can:
1. Create a `.love` file by zipping your project files
2. Follow the distribution guidelines on the [Love2D wiki](https://love2d.org/wiki/Game_Distribution)

## Debugging Your Game

With the Local Lua Debugger extension, you can:
1. Set breakpoints in your code by clicking in the gutter next to line numbers
2. Press F5 to start debugging
3. Use the debug controls to step through code, inspect variables, and more
4. Add watches for specific variables
5. View the call stack and loaded scripts

To enable debugging in your Love2D game, add this code at the beginning of your `main.lua`:

```lua
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end
```

## Development Guidelines

- Organize your code into modules in the `src/` directory
- Keep game assets in the `assets/` directory
- Use the linting tools to maintain code quality
- Follow Love2D best practices for performance and organization

## License

This template is provided under the MIT License. See the LICENSE file for details.

## Resources

- [Love2D Documentation](https://love2d.org/wiki/Main_Page)
- [Love2D Forums](https://love2d.org/forums/)
- [Cursor Documentation](https://cursor.sh/docs) 
