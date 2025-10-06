# ChromeProfileSwitcher Spoon

Quick switcher for Chrome profiles with intelligent cycling.

## Problem It Solves

Chrome's built-in profile switching (`Cmd+~`) cycles through ALL Chrome windows across ALL profiles, making it slow and frustrating when you have multiple profiles (work, personal, etc.) with multiple windows each.

This Spoon lets you assign a hotkey to each profile. Press the hotkey once to switch to that profile's first window, press it again to cycle through other windows in the same profile.

## Features

- **Direct profile targeting** - Jump straight to a specific profile
- **Intelligent cycling** - Cycle through windows within the same profile
- **Auto-launch** - Launch Chrome with the profile if no windows exist
- **Consistent ordering** - Windows are sorted by ID for predictable cycling

## Configuration

### Basic Setup

```lua
hs.loadSpoon("ChromeProfileSwitcher")

spoon.ChromeProfileSwitcher:init()

-- Add your profiles
spoon.ChromeProfileSwitcher:addProfile(
    "Michael (Kiliman)",  -- Profile name as shown in window title
    "Default",            -- Profile directory name
    {{"cmd", "ctrl"}, "1"} -- Hotkey: Cmd+Ctrl+1
)

spoon.ChromeProfileSwitcher:addProfile(
    "Work",
    "Profile 1",
    {{"cmd", "ctrl"}, "2"} -- Hotkey: Cmd+Ctrl+2
)
```

### Finding Your Profile Information

**Profile Name:** Look at any Chrome window title - it ends with ` - ProfileName`

**Profile Directory:**
```bash
# On macOS:
ls ~/Library/Application\ Support/Google/Chrome/
# Look for "Default" and "Profile 1", "Profile 2", etc.
```

Or check `chrome://version` in your browser - look for "Profile Path"

## API

### Methods

#### `addProfile(profileName, profileDir, hotkey)`

Adds a Chrome profile with a hotkey binding.

**Parameters:**
- `profileName` (string) - Display name of the profile (as seen in window titles)
- `profileDir` (string) - Profile directory name (e.g., "Default", "Profile 1")
- `hotkey` (table) - Hotkey binding as `{{modifiers}, key}`

**Returns:** The ChromeProfileSwitcher object (for chaining)

#### `switchToProfile(profileName, profileDir)`

Programmatically switch to a specific profile.

**Parameters:**
- `profileName` (string) - Display name of the profile
- `profileDir` (string) - Profile directory name

**Returns:** None

## Behavior

### When you press the hotkey:

1. **No Chrome windows exist** → Launch Chrome with that profile
2. **Chrome is open, different profile is active** → Switch to first window of target profile
3. **Target profile is already active** → Cycle to next window within that profile

### Window Detection

The Spoon matches windows by looking for ` - ProfileName` at the end of the window title. This is Chrome's standard format.

## Examples

### Multiple Profiles with Different Hotkeys

```lua
spoon.ChromeProfileSwitcher:init()
    :addProfile("Personal", "Default", {{"cmd", "ctrl"}, "1"})
    :addProfile("Work", "Profile 1", {{"cmd", "ctrl"}, "2"})
    :addProfile("Client", "Profile 2", {{"cmd", "ctrl"}, "3"})
```

### Without Hotkeys (Programmatic Use)

```lua
-- Add profiles without hotkeys
spoon.ChromeProfileSwitcher:init()
    :addProfile("Personal", "Default", nil)

-- Switch programmatically later
spoon.ChromeProfileSwitcher:switchToProfile("Personal", "Default")
```

## Troubleshooting

**Windows not being detected?**
- Check that your profile name exactly matches what appears in Chrome window titles
- Profile names are case-sensitive
- Make sure there are no extra spaces

**Chrome not launching?**
- Verify the profile directory name is correct
- Check `~/Library/Application Support/Google/Chrome/` for available profiles
- Look at Hammerspoon console for error messages

**Logging:**
- Open Hammerspoon Console to see debug logs
- The Spoon logs all window detection and switching actions

## Migration from AppleScript

If you're migrating from an AppleScript solution:

**Before:**
```applescript
on run argv
    set profileName to item 1 of argv
    set profileDir to item 2 of argv
    -- 200+ lines of AppleScript...
end run
```

**After:**
```lua
spoon.ChromeProfileSwitcher:addProfile("Michael (Kiliman)", "Default", {{"cmd", "ctrl"}, "1"})
```

That's it! The Lua version is cleaner, faster, and easier to maintain.
