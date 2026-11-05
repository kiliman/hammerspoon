# QuickWindowSwitcher Spoon

## Overview
Hammerspoon Spoon for quickly switching between windows of the current application. Shows a searchable list, like right-clicking the dock icon but driven from the keyboard.

## Features

- **Quick Window List** - Shows all windows for the currently focused application
- **Search** - Type to filter windows by title
- **Arrow Key Navigation** - Use up/down arrows + Enter to select
- **Click Support** - Click any window in the list to focus it
- **Single-window shortcut** - With only one window, focuses it without showing the list
- **Smart Filtering** - Only shows visible, standard windows
- **Accessibility-aware** - Reports a stale accessibility connection instead of "no windows"

## Installation

The Spoon is loaded in the main `init.lua`:

```lua
hs.loadSpoon("QuickWindowSwitcher")
spoon.QuickWindowSwitcher:init()
spoon.QuickWindowSwitcher:bindHotkeys({
    show = {{"cmd", "alt"}, "down"}
})
spoon.QuickWindowSwitcher:start()
```

Load `AccessibilityHealth` before it to get the stale-accessibility message. Without it, the Spoon still works and falls back to the plain "no windows" alert.

## Usage

1. Press **Cmd+Alt+Down** (or your configured hotkey) while focused on any app
2. A list appears showing all windows for that app
3. Select a window:
   - **Type** - Filter by window title (numbers included)
   - **Arrow keys** (↑/↓) + **Enter** - Navigate and select
   - **Click** - Mouse selection
4. **Escape** cancels the selection

### Examples

**IDE with multiple project windows:**
- Press **Cmd+Alt+Down** in VS Code
- Type part of a project name to filter
- Press **Enter** to select the first match

**Terminal with multiple sessions:**
- Press **Cmd+Alt+Down** in Ghostty
- Use arrow keys to browse windows
- Press **Enter** to select

## Public API

### Methods

#### `spoon.QuickWindowSwitcher:init()`
Initializes the Spoon and creates the chooser interface.

#### `spoon.QuickWindowSwitcher:start()`
Starts the Spoon (mainly for Spoon lifecycle compliance).

#### `spoon.QuickWindowSwitcher:stop()`
Stops the Spoon and cleans up hotkey bindings.

#### `spoon.QuickWindowSwitcher:show()`
Shows the window list for the current application. Can be called programmatically or bound to a hotkey.

**Behavior:**
- No windows found, and the frontmost app is unreachable over accessibility → alert naming the app and the fix: quit and relaunch Hammerspoon
- No windows found otherwise → "No windows found for current application"
- One window → focuses it immediately
- Several windows → shows the chooser

#### `spoon.QuickWindowSwitcher:bindHotkeys(mapping)`
Binds hotkeys for the Spoon actions.

**Parameters:**
- `mapping` - Table containing hotkey mappings:
  - `show` - Show window list (e.g., `{{"cmd", "alt"}, "down"}`)

## Internal Methods

### `getWindowsForCurrentApp()`
Gets all visible, standard windows for the application owning the focused window.

**Returns:**
- Table of choices formatted for `hs.chooser`

### `selectWindow(choice)`
Focuses and raises the selected window.

**Parameters:**
- `choice` - The chooser choice containing the window reference

## Keyboard Shortcuts

### In the Window List

| Key | Action |
|-----|--------|
| **Type** | Search/filter by window title |
| **↑/↓** | Navigate up/down |
| **Enter** | Select highlighted window |
| **Cmd+1** – **Cmd+9** | Select a row directly (built into `hs.chooser`) |
| **Escape** | Cancel and close list |
| **Click** | Select window by clicking |

Plain number keys are deliberately **not** shortcuts: they once selected rows, but that made it impossible to search for a window title containing a digit.

## Configuration

### Changing the Hotkey

Edit `init.lua` and modify the `bindHotkeys()` call:

```lua
spoon.QuickWindowSwitcher:bindHotkeys({
    show = {{"cmd", "ctrl"}, "w"}  -- Change to Cmd+Ctrl+W
})
```

### Number of Visible Rows

The chooser shows up to 10 rows. To change this, edit `self.chooser:rows(10)` in the Spoon's `init()` method.

## Technical Details

- Uses `hs.chooser` for the list interface
- Filters out minimized, hidden, and non-standard windows
- Finds the app through the focused window, which needs a working accessibility connection
- When that comes back empty, checks `hs.application.frontmostApplication()` instead, which does not depend on accessibility, to tell a stale connection apart from an app with no windows

## Troubleshooting

### "<App> is unreachable over accessibility"
Hammerspoon's accessibility connection to that app is stale. Quit and relaunch Hammerspoon; reloading the config is not enough. See `Spoons/AccessibilityHealth.spoon/CLAUDE.md`.

### "No windows found for current application"
- Make sure the app has visible windows (not minimized)
- Check that windows are standard (not utility windows, dialogs, etc.)

### Hotkey conflict
- Check for conflicts with other apps or Hammerspoon Spoons
- Change the hotkey in `init.lua` if needed

## Limitations

- Requires the app to have focus before showing the list
- Only shows standard, visible windows (by design)
