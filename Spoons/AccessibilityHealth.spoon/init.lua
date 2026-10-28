--- === AccessibilityHealth ===
---
--- Detects stale Accessibility (AX) connections in the running Hammerspoon process.
---
--- A major macOS upgrade resets Hammerspoon's Accessibility permission. If
--- Hammerspoon starts up without it, macOS answers "the accessibility API is
--- disabled" for every application that is already running, and Hammerspoon
--- caches that answer per application for the rest of its lifetime. Those apps
--- then report zero windows forever, while apps launched later work normally --
--- so window management silently half-works and looks like a config bug.
---
--- Quitting and relaunching Hammerspoon clears the cache. Reloading the config
--- does not, because the cache lives in the process, not in the Lua state.
---
--- Download: N/A
--- License: MIT

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AccessibilityHealth"
obj.version = "1.0.0"
obj.author = "Michael Carter"
obj.homepage = "https://github.com/kiliman/hammerspoon"
obj.license = "MIT"

obj.logger = hs.logger.new('AccessibilityHealth')

--- AccessibilityHealth.startupDelay
--- Variable
--- Seconds to wait after `start()` before running the automatic self-check.
--- The delay gives apps restored at login time a chance to finish launching.
obj.startupDelay = 8

--- AccessibilityHealth.maxNamesShown
--- Variable
--- Maximum number of app names to list in a notification before summarizing
--- the remainder as "+N more".
obj.maxNamesShown = 8

--- AccessibilityHealth.remedy
--- Variable
--- The one action that actually clears a stale cache.
obj.remedy = "Quit and relaunch Hammerspoon"

obj.hotkeyRefs = {}
obj.startupTimer = nil

--- AccessibilityHealth:init()
--- Method
--- Initializes the Spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The AccessibilityHealth object
function obj:init()
    self.logger.d("Initializing AccessibilityHealth")
    return self
end

--- AccessibilityHealth:isStale(app)
--- Method
--- Checks whether an application is running but unreachable over accessibility
---
--- Parameters:
---  * app - An `hs.application` object
---
--- Returns:
---  * true if the app is running but Hammerspoon cannot read its AX tree
function obj:isStale(app)
    if not app then
        return false
    end

    local pid = app:pid()
    if not pid or pid <= 0 then
        return false
    end

    -- Pass the hs.application object rather than a bare pid: resolving from a
    -- pid fails outright for processes with no NSRunningApplication.
    local ok, ax = pcall(hs.axuielement.applicationElement, app)
    if not ok or not ax then
        return true
    end

    -- A reachable application element always answers AXRole with "AXApplication".
    return ax:attributeValue("AXRole") == nil
end

--- AccessibilityHealth:scan()
--- Method
--- Finds every regular GUI application Hammerspoon cannot reach
---
--- Parameters:
---  * None
---
--- Returns:
---  * Array of `{ app = hs.application, pid = number, name = string }`,
---    sorted by pid, empty when everything is healthy
function obj:scan()
    local stale = {}

    for _, app in ipairs(hs.application.runningApplications()) do
        local pid = app:pid() or -1
        -- kind() == 1 is a regular, user-facing app. Skip agents and daemons,
        -- which legitimately expose no AX tree and would be false positives.
        if pid > 0 and app:kind() == 1 and self:isStale(app) then
            table.insert(stale, { app = app, pid = pid, name = app:name() or "?" })
        end
    end

    table.sort(stale, function(a, b) return a.pid < b.pid end)

    return stale
end

--- AccessibilityHealth:report(quiet)
--- Method
--- Scans for unreachable applications and reports the result
---
--- Parameters:
---  * quiet - Optional boolean. When true, stay silent if everything is healthy
---    and only speak up when there is a problem.
---
--- Returns:
---  * The array returned by `scan()`
function obj:report(quiet)
    local stale = self:scan()

    if #stale == 0 then
        self.logger.i("Accessibility is healthy for all GUI applications")
        if not quiet then
            hs.alert.show("Accessibility OK for all apps", 2)
        end
        return stale
    end

    local names = {}
    for _, entry in ipairs(stale) do
        self.logger.w(string.format("Stale accessibility: %s (pid %d)", entry.name, entry.pid))
        if #names < self.maxNamesShown then
            table.insert(names, entry.name)
        end
    end

    local listed = table.concat(names, ", ")
    local hidden = #stale - #names
    if hidden > 0 then
        listed = string.format("%s, +%d more", listed, hidden)
    end

    local summary = string.format("%d app%s unreachable: %s",
        #stale, #stale == 1 and "" or "s", listed)

    hs.notify.new({
        title = "Hammerspoon accessibility is stale",
        informativeText = string.format("%s. %s.", summary, self.remedy),
        withdrawAfter = 0
    }):send()

    hs.alert.show(string.format("%s\n%s", self.remedy, summary), 6)

    return stale
end

--- AccessibilityHealth:warnStale(app)
--- Method
--- Tells the user an application is unreachable, and what to do about it
---
--- Parameters:
---  * app - An `hs.application` object, or nil
---
--- Returns:
---  * The AccessibilityHealth object
function obj:warnStale(app)
    local name = (app and app:name()) or "That app"

    self.logger.w(string.format("%s is unreachable over accessibility", name))
    hs.alert.show(string.format("%s is unreachable over accessibility\n%s",
        name, self.remedy), 4)

    return self
end

--- AccessibilityHealth:warnIfStale(app)
--- Method
--- Warns about an unreachable application, if it is in fact unreachable. This
--- is the single call other Spoons use to tell a genuine "no windows" result
--- apart from a stale accessibility cache.
---
--- Parameters:
---  * app - An `hs.application` object
---
--- Returns:
---  * true if the app was stale and a warning was shown, false otherwise
function obj:warnIfStale(app)
    if self:isStale(app) then
        self:warnStale(app)
        return true
    end

    return false
end

--- AccessibilityHealth:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for the Spoon
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for:
---   * report - Run a scan and show the result
---
--- Returns:
---  * The AccessibilityHealth object
function obj:bindHotkeys(mapping)
    if mapping["report"] then
        local mods, key = table.unpack(mapping["report"])
        self.hotkeyRefs.report = hs.hotkey.bind(mods, key, function()
            self:report(false)
        end)
    end

    return self
end

--- AccessibilityHealth:start()
--- Method
--- Schedules the automatic startup self-check, which notifies only when it
--- finds a problem
---
--- Parameters:
---  * None
---
--- Returns:
---  * The AccessibilityHealth object
function obj:start()
    if self.startupTimer then
        self.startupTimer:stop()
    end

    self.startupTimer = hs.timer.doAfter(self.startupDelay, function()
        self:report(true)
    end)

    return self
end

--- AccessibilityHealth:stop()
--- Method
--- Cancels the startup self-check and releases hotkeys
---
--- Parameters:
---  * None
---
--- Returns:
---  * The AccessibilityHealth object
function obj:stop()
    if self.startupTimer then
        self.startupTimer:stop()
        self.startupTimer = nil
    end

    for _, ref in pairs(self.hotkeyRefs) do
        ref:delete()
    end
    self.hotkeyRefs = {}

    return self
end

return obj
