# Hammerspoon Configuration

Custom Hammerspoon setup for multi-monitor window management.

## Structure

- `init.lua` - Loads and configures Spoons
- `Spoons/` - Individual Spoon packages with their own documentation

## Spoons

### FocusMode
Advanced window management for multi-monitor setups.

**See:** `Spoons/FocusMode.spoon/CLAUDE.md` for full documentation and API details.

**Quick start:**
- `F13` - Toggle focused window to/from center screen
- `Cmd+Alt+F13` then `0-9` - Save window position to slot
- `Cmd+F13` then `0-9` - Toggle slot window to/from center

### QuickWindowSwitcher
Quick window switcher for the current application.

**See:** `Spoons/QuickWindowSwitcher.spoon/CLAUDE.md` for full documentation and API details.

**Quick start:**
- `Cmd+Ctrl+W` - Show list of windows for current app
- Press `1-9` or `0` to select a window instantly
- Use arrow keys + Enter, or click to select

### ChromeProfileSwitcher
Quick switcher for Chrome profiles with intelligent cycling.

**See:** `Spoons/ChromeProfileSwitcher.spoon/CLAUDE.md` for full documentation and API details.

**Quick start:**
- `Cmd+Pad1` - Switch to/cycle through Michael (Kiliman) profile windows
- `Cmd+Pad2` - Switch to/cycle through Michael (beehiiv.com) profile windows
- Press once to switch to profile, press again to cycle windows within profile
