# ChromeProfileSwitcher Spoon

Quick switcher for Chrome profiles with intelligent cycling.

## Problem It Solves

Chrome's built-in profile switching (`Cmd+~`) cycles through ALL Chrome windows across ALL profiles, making it slow and frustrating when you have multiple profiles (work, personal, etc.) with multiple windows each.

This Spoon lets you assign a hotkey to each profile. Press the hotkey once to switch to that profile's first window, press it again to cycle through other windows in the same profile.

## Features

- **Direct profile targeting** - Jump straight to a specific profile
- **Intelligent cycling** - Cycle through windows within the same profile
- **Auto-launch** - Launch Chrome with the profile if no windows exist
- **Accessibility-aware** - Warns instead of launching a stray window when Chrome is unreachable over accessibility
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
    {{"cmd"}, "pad1"}     -- Hotkey: Cmd+Pad1
)

spoon.ChromeProfileSwitcher:addProfile(
    "Michael (beehiiv.com)",
    "Profile 1",
    {{"cmd"}, "pad2"}     -- Hotkey: Cmd+Pad2
)
```

Load `AccessibilityHealth` before this Spoon to get the stale-accessibility guard. Without it, the Spoon still works but cannot tell an unreachable Chrome apart from a profile with no windows.

### Finding Your Profile Information

**Profile Name:** Look at any Chrome window title. It ends with ` - Google Chrome - <Profile Name>`. A profile signed in to a Google account shows `<first name> (<profile name>)`, such as `Michael (Kiliman)`. A profile whose name matches the account name shows just the name, such as `Claudia`.

**Profile Directory:** Open `chrome://version` in that profile and read **Profile Path**. The directory is its last component, such as `Default` or `Profile 7`.

macOS blocks both the shell and Hammerspoon from reading `~/Library/Application Support/Google/Chrome/`, so you cannot list profiles from disk. You can see which directories are loaded with `lsof -p "$(pgrep -x 'Google Chrome')" | grep -oE 'Chrome/(Default|Profile [0-9]+)/' | sort -u`, but that does not give you their names.

**Verifying a mapping:** run the Spoon's launch command for a directory Chrome has already loaded, and read the profile name in the new window's title:

```bash
open -na 'Google Chrome' --args --profile-directory='Profile 7'
```

Only do this for a directory that is already loaded. Chrome treats an unknown directory as a request to **create a new profile**.

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

1. **Chrome is not running** → Launch Chrome with that profile
2. **Chrome is running but unreachable over accessibility** → Alert naming the fix (quit and relaunch Hammerspoon), and **do not** launch anything
3. **Chrome is running with no windows in that profile** → Launch a window for that profile
4. **A different profile, or another app, is active** → Switch to first window of target profile
5. **Target profile is already active** → Cycle to next window within that profile

Case 2 exists because an unreachable Chrome reports zero windows, which used to fall through to case 3 and spawn a stray window instead of switching.

### Window Detection

The Spoon matches windows by their title suffix. Current Chrome titles look like `<tab title> - Google Chrome - <Profile Name>`. `titleMatchesProfile()` also accepts `... - <Profile Name> - Google Chrome` and a whitespace- and case-insensitive match on the last segment, to cope with older formats.

## Examples

### Multiple Profiles with Different Hotkeys

```lua
spoon.ChromeProfileSwitcher:init()
    :addProfile("Personal", "Default", {{"cmd"}, "pad1"})
    :addProfile("Work", "Profile 1", {{"cmd"}, "pad2"})
    :addProfile("Client", "Profile 2", {{"cmd"}, "pad3"})
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

**Pressing the hotkey opens a new window instead of switching?**
- Check the Hammerspoon console. If it says Chrome is unreachable over accessibility, quit and relaunch Hammerspoon (see `Spoons/AccessibilityHealth.spoon/CLAUDE.md`)
- Otherwise the profile name does not match the window titles; see below

**Windows not being detected?**
- Check that your profile name exactly matches what appears in Chrome window titles
- Profile names are case-sensitive
- Make sure there are no extra spaces

**Chrome not launching?**
- Verify the profile directory name with `chrome://version` (see Finding Your Profile Information)
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
