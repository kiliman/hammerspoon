# Hammerspoon Configuration

Custom Hammerspoon setup for multi-monitor window management.

## Structure

- `init.lua` - Loads and configures Spoons, and enables the `hs` CLI (`require("hs.ipc")`)
- `Spoons/` - Individual Spoon packages, most with their own `CLAUDE.md`
- `tmp/` - Scratch scripts and notes (gitignored)

## Hotkeys at a Glance

| Hotkey | Spoon | Action |
|---|---|---|
| `F13` | FocusMode | Toggle focused window to/from center screen |
| `Cmd+Shift+F13` | FocusMode | Save focused window's position for its app |
| `Cmd+F13` | FocusMode | Restore focused window to its app's saved position |
| `Cmd+Alt+Down` | QuickWindowSwitcher | Search the current app's windows |
| `Cmd+Pad1` – `Cmd+Pad4` | ChromeProfileSwitcher | Switch to / cycle a Chrome profile's windows |
| `Cmd+Ctrl+T` | ChromeTabSwitcher | Search all Chrome tabs across windows |
| `Ctrl+Pad0` | QuickSpaceSwitcher | Search Spaces on the current screen |
| `Ctrl+Pad1` – `Ctrl+Pad4` | QuickSpaceSwitcher | Jump straight to Space 1–4 |
| `Cmd+Alt+Ctrl+A` | AccessibilityHealth | Scan for apps Hammerspoon cannot reach |

## Spoons

Listed in load order. AccessibilityHealth loads first because the window-management Spoons depend on it.

### AccessibilityHealth
Detects stale Accessibility (AX) connections in the running Hammerspoon process: apps that were already running when Hammerspoon started report zero windows forever, while apps launched later work fine.

**See:** `Spoons/AccessibilityHealth.spoon/CLAUDE.md` for the full write-up.

- `Cmd+Alt+Ctrl+A` - Scan every GUI app and report what Hammerspoon cannot reach
- Runs a quiet self-check 8s after launch, notifying only on a problem
- **The fix is always: quit and relaunch Hammerspoon.** A config reload does not clear it
- Launch order does not matter: apps opened before Hammerspoon are fine, so "Reopen windows when logging back in" is safe

### FocusMode
Window management for multi-monitor setups: moves windows to and from the center screen, and remembers one position per app.

**See:** `Spoons/FocusMode.spoon/CLAUDE.md` for full documentation and API details.

- `F13` - Toggle focused window to/from center screen
- `Cmd+Shift+F13` - Save the focused window's position for its app
- `Cmd+F13` - Restore the focused window to its app's saved position
- `forgetApp` exists as an optional binding but is not bound

### QuickWindowSwitcher
Searchable list of the current application's windows.

**See:** `Spoons/QuickWindowSwitcher.spoon/CLAUDE.md` for full documentation and API details.

- `Cmd+Alt+Down` - Show the current app's windows
- Type to filter, then arrow keys + Enter, or click
- A single window is focused immediately, with no list

### ChromeProfileSwitcher
One hotkey per Chrome profile, with cycling within a profile.

**See:** `Spoons/ChromeProfileSwitcher.spoon/CLAUDE.md` for full documentation and API details.

| Hotkey | Profile name (window title) | Profile directory |
|---|---|---|
| `Cmd+Pad1` | `Michael (Kiliman)` | `Default` |
| `Cmd+Pad2` | `Michael (beehiiv.com)` | `Profile 1` |
| `Cmd+Pad3` | `Claudia` | `Profile 7` |
| `Cmd+Pad4` | `Michael (Michael 3VOtech)` | `Profile 8` |

Mapping verified 2026-11-05 by launching each directory and reading the profile name Chrome put in the window title. There is at least one more profile, `Claudia (Claudia 3votech.com)`, which is not bound.

- Press once to switch to the profile, again to cycle its windows
- Launches the profile only when it truly has no windows, never when Chrome is unreachable over accessibility

### ChromeTabSwitcher
Searchable list of every tab in every Chrome window, labeled with its profile.

**See:** `Spoons/ChromeTabSwitcher.spoon/CLAUDE.md` for full documentation and API details.

- `Cmd+Ctrl+T` - Show all Chrome tabs
- Type to filter by title, domain, or profile

### ClipboardNumberConverter
Converts sequences of spoken number words on the clipboard to digits ("one two three four" → "1234"). **Currently disabled**: its block in `init.lua` is commented out, including its `Cmd+Alt+N` toggle.

**See:** `Spoons/ClipboardNumberConverter.spoon/CLAUDE.md`.

### FlashOnFocus
Draws a green border around a window when it gains focus, then fades it out. It follows the window if it moves during the flash. Other Spoons call `spoon.FlashOnFocus:flashWindow(win)` after a scripted focus change, since those do not always fire a focus event.

- No hotkeys
- Configured in `init.lua` with `duration` (seconds before the fade). Also settable: `frameWidth`, `frameColor`, `fadeOutSeconds`

### QuickSpaceSwitcher
Searchable list of Spaces, plus direct jumps, on the screen holding the focused window (`hs.screen.mainScreen()`).

- `Ctrl+Pad0` - Show the Spaces chooser
- `Ctrl+Pad1` – `Ctrl+Pad4` - Jump to Space 1–4

### AudioPriority
Gives the default **input** device a priority list, which macOS lacks: Yeti X, then the CalDigit TS4 dock, then the MacBook Pro microphone, then BlackHole. Devices on no list (Cam Link 4K) are never picked automatically. No hotkey.

- Acts only when a device connects or disconnects (`hs.audiodevice.watcher` event `dev#`), after a 1.5s settle so a dock's devices can all appear. It ignores the default changing, so a manual switch sticks until the next plug/unplug.
- Recording an emulator through BlackHole (see the `driving-test-devices` skill): switch to BlackHole by hand, then put it back with `hs -c 'spoon.AudioPriority:apply()'`.
- Edit the order with `spoon.AudioPriority.inputPriority` (plain substrings of device names, best first). It owns the global `hs.audiodevice.watcher` callback, so no other Spoon can set one.

### Container
Experimental and **not loaded**: uses a full-screen TextEdit window as a parent container for other windows.

## Troubleshooting

**A Spoon says an app is "unreachable over accessibility"** — quit and relaunch Hammerspoon. See AccessibilityHealth above.

**Checking the live config from a shell** — `hs -c '<lua>'` runs Lua inside Hammerspoon, for example `hs -c 'hs.reload()'`.

**Chrome's profile data is unreadable** — macOS blocks both the shell and Hammerspoon from reading `~/Library/Application Support/Google/Chrome/`. To find a profile's directory, open `chrome://version` in that profile and read **Profile Path**.
