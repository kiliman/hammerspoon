# ChromeTabSwitcher Spoon

## Overview
Hammerspoon Spoon for quickly switching between Chrome tabs across all windows. Shows a searchable list of all open tabs, each labeled with its Chrome profile.

## Features

- **All Tabs List** - Shows all Chrome tabs from all windows in one searchable list
- **Arrow Key Navigation** - Use up/down arrows + Enter to select
- **Click Support** - Click any tab in the list to focus it
- **Search** - Type to filter tabs by title, domain, or profile
- **Profile + Domain Display** - Shows `Profile • domain` as subtext for each tab

## Installation

Add to your `init.lua`:

```lua
hs.loadSpoon("ChromeTabSwitcher")
spoon.ChromeTabSwitcher:init()
spoon.ChromeTabSwitcher:bindHotkeys({
    show = {{"cmd", "ctrl"}, "t"}
})
spoon.ChromeTabSwitcher:start()
```

## Usage

### Basic Workflow

1. Press **Cmd+Ctrl+T** (or your configured hotkey)
2. A list appears showing all Chrome tabs from all windows
3. Select a tab using:
   - **Arrow keys** (↑/↓) + **Enter** - Navigate and select
   - **Click** - Mouse selection
   - **Type** - Search/filter by tab title, domain, or profile
4. **Escape** cancels the selection

### Examples

**Find a specific tab by name:**
- Press **Cmd+Ctrl+T**
- Type "github" to filter
- Press **Enter** to select the first match

**Find a tab in one profile:**
- Press **Cmd+Ctrl+T**
- Type "beehiiv" to narrow to tabs in the `Michael (beehiiv.com)` profile

**Search by domain:**
- Press **Cmd+Ctrl+T**
- Type "reddit.com" to find all Reddit tabs
- Use arrow keys to browse and Enter to select

## Public API

### Methods

#### `spoon.ChromeTabSwitcher:init()`
Initializes the Spoon and creates the chooser interface.

#### `spoon.ChromeTabSwitcher:start()`
Starts the Spoon (mainly for Spoon lifecycle compliance).

#### `spoon.ChromeTabSwitcher:stop()`
Stops the Spoon and cleans up hotkey bindings.

#### `spoon.ChromeTabSwitcher:show()`
Shows the tab list for all Chrome windows. Can be called programmatically or bound to a hotkey.

**Behavior:**
- If Chrome is not running, shows an alert
- If no tabs found, shows an alert
- Otherwise, displays the chooser with all tabs

#### `spoon.ChromeTabSwitcher:bindHotkeys(mapping)`
Binds hotkeys for the Spoon actions.

**Parameters:**
- `mapping` - Table containing hotkey mappings:
  - `show` - Show tab list (e.g., `{{"cmd", "ctrl"}, "t"}`)

**Example:**
```lua
spoon.ChromeTabSwitcher:bindHotkeys({
    show = {{"cmd", "ctrl"}, "t"}  -- Cmd+Ctrl+T
})
```

## Internal Methods

### `getAllChromeTabs()`
Uses AppleScript to fetch all tabs from all Chrome windows.

**Returns:**
- Table of choices formatted for `hs.chooser`, each containing:
  - `text` - Tab title
  - `subText` - `Profile • domain`, or just the domain when the profile is unknown
  - `profile` - Profile name taken from the window title
  - `url` - Full URL
  - `windowIndex` - Chrome window index
  - `tabIndex` - Tab index within window

### `selectTab(choice)`
Activates the selected tab in its window using AppleScript.

**Parameters:**
- `choice` - The chooser choice containing tab information

**Implementation:**
- Sets the active tab index for the window
- Brings the window to the front
- Activates Chrome

## Keyboard Shortcuts

### In the Tab List

| Key | Action |
|-----|--------|
| **↑/↓** | Navigate up/down |
| **Enter** | Select highlighted tab |
| **Cmd+1** – **Cmd+9** | Select a row directly (built into `hs.chooser`) |
| **Escape** | Cancel and close list |
| **Type** | Search/filter by title, domain, or profile |
| **Click** | Select tab by clicking |

## Configuration

### Changing the Hotkey

Edit `init.lua` and modify the `bindHotkeys()` call:

```lua
spoon.ChromeTabSwitcher:bindHotkeys({
    show = {{"cmd", "shift"}, "t"}  -- Change to Cmd+Shift+T
})
```

### Number of Visible Rows

By default, the chooser shows up to 15 rows. To change this, modify the Spoon's `init()` method in `Spoons/ChromeTabSwitcher.spoon/init.lua`:

```lua
self.chooser:rows(20)  -- Show 20 rows instead of 15
```

## Technical Details

- Uses `hs.osascript.applescript()` to communicate with Chrome
- Tab data is fetched fresh each time the chooser is shown
- Tab activation is done via AppleScript commands to Chrome
- Search covers the title and the subtext (profile and domain)
- Profiles come from Hammerspoon window titles (`... - Google Chrome - <Profile>`), matched to AppleScript windows by position. Both list windows front-to-back, so the positions line up

## AppleScript Integration

The Spoon uses two AppleScript commands:

**Fetching tabs:**
```applescript
tell application "Google Chrome"
    repeat with w from 1 to count of windows
        repeat with t from 1 to count of tabs of window w
            -- Get title, URL, window index, tab index
        end repeat
    end repeat
end tell
```

**Activating a tab:**
```applescript
tell application "Google Chrome"
    set active tab index of window X to Y
    set index of window X to 1
    activate
end tell
```

## Troubleshooting

### No tabs shown
- Make sure Google Chrome is running
- Check that Chrome has open tabs
- Verify AppleScript permissions for Hammerspoon

### AppleScript errors
- Go to System Settings → Privacy & Security → Automation
- Ensure Hammerspoon has permission to control Google Chrome

### Hotkey conflict
- Check for conflicts with other apps or Hammerspoon Spoons
- Change the hotkey in `init.lua` if needed

### Slow performance
- Large numbers of tabs (100+) may take a moment to fetch
- Consider closing tabs you don't need
- The search filter is instant once loaded

## Limitations

- Only works with Google Chrome (not Chromium, Brave, etc.)
- Requires AppleScript automation permissions
- Profile labels need a working accessibility connection; when it is stale, tabs still list but without profiles (see `Spoons/AccessibilityHealth.spoon/CLAUDE.md`)
- Tab order may not match visual order in Chrome

## Future Enhancements

Potential improvements:
- Support for other Chromium-based browsers
- Show tab favicons
- Group tabs by window
- Integration with ChromeProfileSwitcher
