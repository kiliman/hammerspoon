# FocusMode Spoon

## Overview
Hammerspoon Spoon for advanced window management on multi-monitor setups (designed for 2 portrait side monitors + 1 landscape center/primary monitor). Provides "Focus Mode" to quickly move windows to the center screen and restore them, plus persistent position slots.

## Structure
- **Spoon**: `Spoons/FocusMode.spoon/init.lua` - Main Spoon implementation
- **Config**: `init.lua` - Loads and configures the Spoon with hotkey bindings
- **Convention**: Follows standard Hammerspoon Spoon conventions (PascalCase name, proper API methods)

## Installation
The Spoon is loaded in the main `init.lua`:

```lua
hs.loadSpoon("FocusMode")
spoon.FocusMode:init()
spoon.FocusMode:bindHotkeys({
    focusMode = {{}, "f13"},
    saveSlot = {{"cmd", "alt"}, "f13"},
    toggleSlot = {{"cmd"}, "f13"}
})
spoon.FocusMode:start()
```

## Key Features

### 1. Focus Mode (Default: F13)
- **Move to center**: Pressing the hotkey moves the active window to the center/primary screen and maximizes it
- **Restore position**: Pressing the hotkey again restores the window to its original screen and position
- Uses temporary storage (`storedPositions`) keyed by "AppName - WindowTitle"
- Automatically detects if window is on center screen using `getCenterScreen()`

### 2. Position Slots (Default: Cmd+Alt+F13 → 0-9)
- Save current window position to numbered slots (0-9)
- Persistent storage using `hs.settings` (survives Hammerspoon restart)
- Stores: screen ID, position (x,y), size (w,h), app name, and window title
- Matches by exact title first, falls back to app name only

### 3. Quick Toggle to Slots (Default: Cmd+F13 → 0-9)
- Recalls and toggles windows from saved slots
- If window is on center screen → restores to saved slot position
- If window is elsewhere → moves to center and maximizes
- Automatically finds and focuses the window if not currently focused

## Public API

### Methods

#### `spoon.FocusMode:init()`
Initializes the Spoon and loads saved position slots from persistent storage.

#### `spoon.FocusMode:start()`
Starts the Spoon (currently no background tasks, mainly for Spoon lifecycle compliance).

#### `spoon.FocusMode:stop()`
Stops the Spoon and cleans up all hotkey bindings.

#### `spoon.FocusMode:focusMode()`
Toggles the focused window to/from the center screen. Can be called programmatically or bound to a hotkey.

#### `spoon.FocusMode:saveWindowSlot(slot)`
Saves the focused window's position to the specified slot (0-9).

**Parameters:**
- `slot` - Number from 0-9

#### `spoon.FocusMode:toggleWindowSlot(slot)`
Toggles the window saved in the specified slot to/from the center screen.

**Parameters:**
- `slot` - Number from 0-9

#### `spoon.FocusMode:bindHotkeys(mapping)`
Binds hotkeys for the Spoon actions.

**Parameters:**
- `mapping` - Table containing hotkey mappings:
  - `focusMode` - Toggle focused window (e.g., `{{}, "f13"}`)
  - `saveSlot` - Enter save slot modal (e.g., `{{"cmd", "alt"}, "f13"}`)
  - `toggleSlot` - Enter toggle slot modal (e.g., `{{"cmd"}, "f13"}`)

**Example:**
```lua
spoon.FocusMode:bindHotkeys({
    focusMode = {{}, "f13"},
    saveSlot = {{"cmd", "alt"}, "f13"},
    toggleSlot = {{"cmd"}, "f13"}
})
```

## Internal Methods

### `getCenterScreen()`
Returns the center/primary screen using `hs.screen.primaryScreen()`. Includes debug logging.

### `getScreenById(screenId)`
Finds screen by its ID, with fallback to primary screen if disconnected.

### `findPosition(win)`
Searches slots for saved position matching window (by app name + title, or just app name).

### `restoreWindow(win, position)`
Moves window to saved position/screen, with automatic slot lookup if no temporary position exists.

### `findWindow(appName, title)`
Finds window by app name and title (or just app name as fallback).

## Storage
- **Temporary positions**: `obj.storedPositions` table (runtime only, for Focus Mode toggle)
- **Persistent slots**: `hs.settings` key "WindowPositionSlots" (JSON-encoded)
- **Slots**: `obj.slots` table, synchronized with persistent storage

## Default Hotkeys
- **F13**: Toggle focused window to/from center screen
- **Cmd+Alt+F13**: Enter save mode, then press 0-9 to save current window position
- **Cmd+F13**: Enter toggle mode, then press 0-9 to toggle slot window to/from center
- **Escape**: Exit modal modes

## Customization
To change hotkeys, modify the `bindHotkeys()` call in `init.lua`:

```lua
spoon.FocusMode:bindHotkeys({
    focusMode = {{"cmd", "shift"}, "f"},  -- Change to Cmd+Shift+F
    saveSlot = {{"cmd", "alt"}, "s"},     -- Change to Cmd+Alt+S
    toggleSlot = {{"cmd"}, "t"}           -- Change to Cmd+T
})
```

## Naming Conventions
- **Spoon name**: PascalCase (`FocusMode`)
- **Method names**: camelCase (`focusMode`, `saveWindowSlot`, `toggleWindowSlot`)
- **Module logger**: Uses Spoon name (`FocusMode`)
- **Lua convention**: Methods use camelCase, following Hammerspoon Spoon standards
