# QuickWindowSwitcher Spoon

## Overview
Hammerspoon Spoon for quickly switching between windows of the current application. Shows a searchable list similar to right-clicking the dock icon, but with enhanced keyboard navigation.

## Features

- **Quick Window List** - Shows all windows for the currently focused application
- **Number Key Selection** - Press 1-9 or 0 to instantly select a window
- **Arrow Key Navigation** - Use up/down arrows + Enter to select
- **Click Support** - Click any window in the list to focus it
- **Search** - Type to filter windows by title
- **Smart Filtering** - Only shows visible, standard windows

## Installation

The Spoon is loaded in the main `init.lua`:

```lua
hs.loadSpoon("QuickWindowSwitcher")
spoon.QuickWindowSwitcher:init()
spoon.QuickWindowSwitcher:bindHotkeys({
    show = {{"cmd", "ctrl"}, "w"}
})
spoon.QuickWindowSwitcher:start()
```

## Usage

### Basic Workflow

1. Press **Cmd+Ctrl+W** (or your configured hotkey) while focused on any app
2. A list appears showing all windows for that app
3. Select a window using:
   - **Number keys** (1-9, 0 for 10th window) - Instant selection
   - **Arrow keys** (↑/↓) + **Enter** - Navigate and select
   - **Click** - Mouse selection
   - **Type** - Search/filter by window title
4. **Escape** cancels the selection

### Examples

**Browser with multiple tabs/windows:**
- Press **Cmd+Ctrl+W** in Chrome
- See all Chrome windows numbered 1-10
- Press **3** to jump to the third window

**IDE with multiple project windows:**
- Press **Cmd+Ctrl+W** in VSCode
- Type part of a project name to filter
- Press **Enter** to select the first match

**Terminal with multiple sessions:**
- Press **Cmd+Ctrl+W** in iTerm
- Use arrow keys to browse sessions
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
- If no windows found, shows an alert
- If only one window exists, focuses it immediately
- If multiple windows exist, shows the chooser

#### `spoon.QuickWindowSwitcher:bindHotkeys(mapping)`
Binds hotkeys for the Spoon actions.

**Parameters:**
- `mapping` - Table containing hotkey mappings:
  - `show` - Show window list (e.g., `{{"cmd", "ctrl"}, "w"}`)

**Example:**
```lua
spoon.QuickWindowSwitcher:bindHotkeys({
    show = {{"cmd", "ctrl"}, "w"}  -- Cmd+Ctrl+W
})
```

## Internal Methods

### `getWindowsForCurrentApp()`
Gets all visible, standard windows for the currently focused application.

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
| **1-9** | Select window 1-9 instantly |
| **0** | Select 10th window instantly |
| **↑/↓** | Navigate up/down |
| **Enter** | Select highlighted window |
| **Escape** | Cancel and close list |
| **Type** | Search/filter by window title |
| **Click** | Select window by clicking |

## Configuration

### Changing the Hotkey

Edit `init.lua` and modify the `bindHotkeys()` call:

```lua
spoon.QuickWindowSwitcher:bindHotkeys({
    show = {{"cmd", "shift"}, "w"}  -- Change to Cmd+Shift+W
})
```

### Number of Visible Rows

By default, the chooser shows up to 10 rows. To change this, modify the Spoon's `init()` method:

```lua
self.chooser:rows(15)  -- Show 15 rows instead of 10
```

## Technical Details

- Uses `hs.chooser` for the list interface
- Filters out minimized, hidden, and non-standard windows
- Numbers are shown for first 10 windows only
- Window selection via `queryChangedCallback` for instant number key response
- Automatically clears search query after number key selection

## Troubleshooting

### No windows shown
- Make sure the app has visible windows (not minimized)
- Check that windows are standard (not utility windows, dialogs, etc.)

### Number keys not working
- Make sure you're pressing a single digit (1-9, 0)
- The chooser should be focused (visible on screen)

### Hotkey conflict
- Check for conflicts with other apps or Hammerspoon Spoons
- Change the hotkey in `init.lua` if needed

## Limitations

- Only shows first 10 windows with number key support
- Requires app to have focus before showing list
- Only shows standard, visible windows (by design)
