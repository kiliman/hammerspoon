# Hammerspoon Window Management Script

## Overview
Advanced window management system for a 3-monitor setup (2 portrait side monitors + 1 landscape center/primary monitor). Provides "Focus Mode" to quickly move windows to the center screen and restore them, plus persistent position slots.

## Key Features

### 1. Focus Mode (F13)
- **Move to center**: Pressing F13 moves the active window to the center/primary screen and maximizes it
- **Restore position**: Pressing F13 again restores the window to its original screen and position
- Uses temporary storage (`storedPositions` table) keyed by "AppName - WindowTitle"
- Automatically detects if window is on center screen using `getCenterScreen()`

### 2. Position Slots (Cmd+Alt+F13 → 0-9)
- Save current window position to numbered slots (0-9)
- Persistent storage using `hs.settings` (survives Hammerspoon restart)
- Stores: screen ID, position (x,y), size (w,h), app name, and window title
- Matches by exact title first, falls back to app name only

### 3. Quick Toggle to Slots (Cmd+F13 → 0-9)
- Recalls and toggles windows from saved slots
- If window is on center screen → restores to saved slot position
- If window is elsewhere → moves to center and maximizes
- Automatically finds and focuses the window if not currently focused

## Functions

### `getCenterScreen()`
**CURRENT ISSUE**: Sorts screens by x-coordinate and returns `screens[2]`, which can be unreliable
**RECOMMENDED FIX**: Use `hs.screen.primaryScreen()` since center monitor is the primary monitor

### `getScreenById(screenId)`
Finds screen by its ID, with fallback to primary screen if disconnected

### `findPosition(win)`
Searches slots for saved position matching window (by app name + title, or just app name)

### `restoreWindow(win, position)`
Moves window to saved position/screen, with automatic slot lookup if no temporary position exists

### `saveToSlot(win, slot)`
Saves window position to persistent slot (0-9)

### `findWindow(appName, title)`
Finds window by app name and title (or just app name as fallback)

## Storage
- **Temporary positions**: `storedPositions` table (runtime only, for F13 toggle)
- **Persistent slots**: `hs.settings` key "WindowPositionSlots" (JSON-encoded)

## Hotkeys
- **F13**: Toggle focused window to/from center screen
- **Cmd+Alt+F13**: Enter save mode, then press 0-9 to save current window position
- **Cmd+F13**: Enter toggle mode, then press 0-9 to toggle slot window to/from center
- **Escape**: Exit modal modes

## Known Issues
1. `getCenterScreen()` relies on x-coordinate sorting which can fail if display configuration changes
   - **Solution**: Replace with `return hs.screen.primaryScreen()` for reliability
