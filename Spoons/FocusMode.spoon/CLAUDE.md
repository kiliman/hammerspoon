# FocusMode Spoon

## Overview
Hammerspoon Spoon for advanced window management on multi-monitor setups (designed for 2 portrait side monitors + 1 landscape center/primary monitor). Provides "Focus Mode" to quickly move windows to the center screen and restore them, plus per-app saved positions for quick recall.

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
    focusMode  = {{}, "f13"},
    saveApp    = {{"cmd", "shift"}, "f13"},
    restoreApp = {{"cmd"}, "f13"},
    -- forgetApp = {{"cmd", "alt"}, "f13"},  -- optional
})
spoon.FocusMode:start()
```

## Key Features

### 1. Focus Mode (Default: F13)
- **Move to center**: Pressing the hotkey moves the active window to the center/primary screen and fits/centers it
- **Restore position**: Pressing the hotkey again restores the window to its original screen and position
- Uses temporary in-memory storage (`storedPositions`) keyed by `"AppName - WindowTitle"`
- If no temporary stored position exists when on the center screen, falls back to the saved per-app position (if any)

### 2. Save App Position (Default: Cmd+Shift+F13)
- Saves the focused window's current position, keyed by application name
- Only **one entry per app** — re-saving overwrites the previous entry
- Persistent via `hs.settings` (survives Hammerspoon restart)
- Stores: screen ID, position (x, y), size (w, h), and title (for reference only)

### 3. Restore App Position (Default: Cmd+F13)
- Restores the focused window to its saved position
- Loose match: uses **app name only** (ignores window title), so apps that change their title based on the active document/tab still match correctly

### 4. Forget App Position (Optional)
- Removes the saved position for the focused window's app

## Public API

### Methods

#### `spoon.FocusMode:init()`
Initializes the Spoon and loads saved per-app positions from persistent storage.

#### `spoon.FocusMode:start()`
Starts the Spoon (no background tasks; provided for Spoon lifecycle compliance).

#### `spoon.FocusMode:stop()`
Stops the Spoon and cleans up all hotkey bindings.

#### `spoon.FocusMode:focusMode()`
Toggles the focused window to/from the center screen.

#### `spoon.FocusMode:saveAppPosition()`
Saves the focused window's position keyed by app name. Overwrites any previous entry for that app.

#### `spoon.FocusMode:restoreAppPosition()`
Restores the focused window to its saved app position (matched by app name only).

#### `spoon.FocusMode:forgetAppPosition()`
Removes the saved position for the focused window's app.

#### `spoon.FocusMode:bindHotkeys(mapping)`
Binds hotkeys for the Spoon actions.

**Parameters:**
- `mapping` — table with any of:
  - `focusMode`  — Toggle focused window to/from center (e.g., `{{}, "f13"}`)
  - `saveApp`    — Save focused window's position by app name (e.g., `{{"cmd", "shift"}, "f13"}`)
  - `restoreApp` — Restore focused window to saved app position (e.g., `{{"cmd"}, "f13"}`)
  - `forgetApp`  — Forget saved position for focused app (optional)

## Internal Methods

### `getCenterScreen()`
Returns the center/primary screen using `hs.screen.primaryScreen()`.

### `getScreenById(screenId)`
Finds screen by its ID, with fallback to primary screen if disconnected.

### `applyPosition(win, position)`
Moves a window to the screen and frame described by a saved position.

### `fitAndCenterWindow(win, screen, originalFrame)`
Fits a window to the screen (resizing only if it doesn't fit) and centers it.

## Storage
- **Temporary positions**: `obj.storedPositions` (runtime only, for Focus Mode toggle), keyed by `"AppName - WindowTitle"`
- **Persistent app positions**: `hs.settings` key `FocusModeAppPositions` (JSON-encoded), keyed by app name

## Default Hotkeys
- **F13** — Toggle focused window to/from center screen
- **Cmd+Shift+F13** — Save focused window's position (per app)
- **Cmd+F13** — Restore focused window to its saved app position

## Migration Notes (v2.0)
- The numbered slot system (0-9) was removed in favor of per-app persistent positions.
- Settings key changed from `WindowPositionSlots` to `FocusModeAppPositions`. Old data is **not** migrated.
- Removed methods: `saveWindowSlot(slot)`, `toggleWindowSlot(slot)`, `findPosition(win)`, `findWindow(appName, title)`, `restoreWindow(win, position)`.
- Removed hotkey bindings: `saveSlot`, `toggleSlot`. Replaced by `saveApp`, `restoreApp`.

## Naming Conventions
- **Spoon name**: PascalCase (`FocusMode`)
- **Method names**: camelCase (`focusMode`, `saveAppPosition`, `restoreAppPosition`)
- **Module logger**: Uses Spoon name (`FocusMode`)
