# AccessibilityHealth Spoon

Detects stale Accessibility (AX) connections in the running Hammerspoon process.

## Problem It Solves

A major macOS upgrade resets Hammerspoon's Accessibility permission. If Hammerspoon starts up *without* that permission, macOS answers **"the accessibility API is disabled"** for every application that is already running, and Hammerspoon caches that answer per application for the rest of its lifetime.

The result is a failure mode that looks nothing like a permissions problem:

- Apps that were running when Hammerspoon started report **zero windows, forever**
- Apps launched *later* work perfectly
- So window management silently half-works, and looks like a config bug

This was first hit after the macOS 27 upgrade (2026-10-27). Hammerspoon started 22 seconds after a login-restore burst of 25 apps, and every one of those apps — Ghostty, Finder, Safari, Chrome, iTerm2 — was unreachable for over a day. Meanwhile Slack and Teams, launched the next day, were fine.

The symptoms were a `ChromeProfileSwitcher` hotkey spawning a stray window instead of switching, and `QuickWindowSwitcher` reporting `No windows found for current application` in Ghostty.

## The Fix

**Quit and relaunch Hammerspoon.** That clears the cache for every app at once — the apps themselves do not need restarting.

Reloading the config is **not** enough: the cache lives in the process, not in the Lua state.

Launch order is *not* the cause, and does not need managing. An app launched while Hammerspoon is not running still gets a working connection, as long as Hammerspoon is trusted when it next starts. Verified by launching Calculator with Hammerspoon quit — its AX tree was readable immediately after Hammerspoon came back up.

## Configuration

```lua
hs.loadSpoon("AccessibilityHealth")

spoon.AccessibilityHealth:init()
spoon.AccessibilityHealth:bindHotkeys({
    report = {{"cmd", "alt", "ctrl"}, "a"}
})
spoon.AccessibilityHealth:start()
```

Load it **before** any Spoon that enumerates windows, so those Spoons can use it.

### Settings

| Variable | Default | Purpose |
|---|---|---|
| `startupDelay` | `8` | Seconds after `start()` before the automatic self-check, so login-restored apps can finish launching |
| `maxNamesShown` | `8` | App names listed in a notification before the rest collapse to `+N more` |
| `remedy` | `"Quit and relaunch Hammerspoon"` | The hint shown to the user |

## Behavior

### On startup

`start()` schedules a self-check that runs once, `startupDelay` seconds later. It is **quiet on success** — it only notifies when it finds a problem, so a healthy launch stays silent. After the next OS upgrade, the breakage announces itself instead of waiting to be discovered.

### On demand

Press the `report` hotkey (`Cmd+Alt+Ctrl+A`) any time to scan and see the result, healthy or not.

### In other Spoons

`warnIfStale(app)` replaces a misleading "no windows" message with the real cause, and lets the caller skip a pointless action:

```lua
-- ChromeProfileSwitcher: don't launch a stray window if Chrome is unreachable
for _, app in ipairs(chromeApps) do
    if warnIfAccessibilityStale(app) then
        return
    end
end
```

Consumers wrap it so the dependency stays optional and the Spoon still works standalone:

```lua
local function warnIfAccessibilityStale(app)
    if spoon and spoon.AccessibilityHealth then
        return spoon.AccessibilityHealth:warnIfStale(app)
    end

    return false
end
```

## API

### `isStale(app)`

Whether an app is running but unreachable over accessibility.

**Parameters:** `app` — an `hs.application` object (`nil` is safe)

**Returns:** `true` if running but its AX tree cannot be read

Detection reads `AXRole` from the app's accessibility element. A reachable app always answers `"AXApplication"`; a stale one answers `nil`. The `hs.application` object is passed rather than a bare pid, because resolving an element from a pid fails outright for processes with no `NSRunningApplication`.

### `scan()`

**Returns:** array of `{ app, pid, name }` for every unreachable regular GUI app, sorted by pid; empty when healthy

Only `kind() == 1` (regular, user-facing) apps are considered. Agents and daemons legitimately expose no AX tree and would be false positives.

### `report(quiet)`

Scans and reports. Sends a notification plus an alert when apps are unreachable.

**Parameters:** `quiet` — when `true`, stay silent if everything is healthy

**Returns:** the array from `scan()`

### `warnStale(app)`

Shows the "unreachable / relaunch Hammerspoon" alert for an app.

### `warnIfStale(app)`

Calls `warnStale(app)` only if the app is actually stale.

**Returns:** `true` if a warning was shown — callers use this to abort

### `bindHotkeys(mapping)` / `start()` / `stop()`

Standard Spoon lifecycle. `mapping.report` runs a scan and shows the result.

## Troubleshooting

**The startup check never fires** — `start()` must be called; `init()` alone only sets the Spoon up.

**An app is reported stale but seems fine** — confirm by hand:

```lua
local app = hs.application.get("Ghostty")
hs.axuielement.applicationElement(app):attributeValue("AXRole")
-- "AXApplication" = healthy, nil = stale
```

**Everything is reported stale** — Hammerspoon has probably lost its Accessibility permission entirely. Check System Settings › Privacy & Security › Accessibility, then relaunch Hammerspoon. `hs.accessibilityState()` returns the current trust state.
