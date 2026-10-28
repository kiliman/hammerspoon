# Hammerspoon Configuration

Custom Hammerspoon setup for multi-monitor window management.

## Structure

- `init.lua` - Loads and configures Spoons
- `Spoons/` - Individual Spoon packages with their own documentation

## Spoons

### AccessibilityHealth
Detects stale Accessibility (AX) connections in the running Hammerspoon process — the failure mode where apps that were already running when Hammerspoon started report zero windows forever, while apps launched later work fine.

**See:** `Spoons/AccessibilityHealth.spoon/CLAUDE.md` for the full write-up.

**Quick start:**
- `Cmd+Alt+Ctrl+A` - Scan every GUI app and report what Hammerspoon cannot reach
- Runs a quiet self-check 8s after launch, notifying only on a problem
- **The fix is always: quit and relaunch Hammerspoon.** A config reload does not clear it
- Load this Spoon first — the window-management Spoons use it to report the real cause instead of "no windows found"

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
