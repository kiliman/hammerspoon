--- === ChromeProfileSwitcher ===
---
--- Quick switcher for Chrome profiles with cycle support
---
--- Download: [https://github.com/yourusername/ChromeProfileSwitcher]
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ChromeProfileSwitcher"
obj.version = "1.0"
obj.author = "Michael"
obj.homepage = "https://github.com/yourusername/ChromeProfileSwitcher"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('ChromeProfileSwitcher')
obj.logger.setLogLevel('info')
obj.profiles = {}

--- ChromeProfileSwitcher:init()
--- Method
--- Initializes the Spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ChromeProfileSwitcher object
function obj:init()
    self.logger.i("Initializing ChromeProfileSwitcher")
    return self
end

--- ChromeProfileSwitcher:addProfile(profileName, profileDir, hotkey)
--- Method
--- Adds a Chrome profile with a hotkey binding
---
--- Parameters:
---  * profileName - The display name of the profile (e.g., "Michael (Kiliman)")
---  * profileDir - The profile directory name (e.g., "Default", "Profile 1")
---  * hotkey - Table with {mods, key} for the hotkey binding
---
--- Returns:
---  * The ChromeProfileSwitcher object
---
--- Example:
--- ```
--- spoon.ChromeProfileSwitcher:addProfile("Michael (Kiliman)", "Default", {{"cmd", "ctrl"}, "1"})
--- ```
function obj:addProfile(profileName, profileDir, hotkey)
    self.logger.i(string.format("Adding profile: %s (%s) with hotkey %s", profileName, profileDir, hs.inspect(hotkey)))

    table.insert(self.profiles, {
        name = profileName,
        dir = profileDir,
        hotkey = hotkey
    })

    -- Bind the hotkey
    if hotkey then
        hs.hotkey.bind(hotkey[1], hotkey[2], function()
            self:switchToProfile(profileName, profileDir)
        end)
    end

    return self
end

--- ChromeProfileSwitcher:switchToProfile(profileName, profileDir)
--- Method
--- Switches to the specified Chrome profile
---
--- Parameters:
---  * profileName - The display name of the profile
---  * profileDir - The profile directory name
---
--- Returns:
---  * None
function obj:switchToProfile(profileName, profileDir)
    self.logger.i(string.format("Switching to profile: %s (%s)", profileName, profileDir))

    -- Get all Chrome instances
    local chromeApps = hs.application.applicationsForBundleID("com.google.Chrome")

    if not chromeApps or #chromeApps == 0 then
        self.logger.i("No Chrome instances found, launching with profile")
        self:launchChromeWithProfile(profileDir)
        return
    end

    -- Collect all windows matching the profile
    local matchingWindows = {}
    local pattern = " %- " .. self:escapePattern(profileName) .. "$"

    self.logger.i(string.format("Looking for profile: '%s'", profileName))
    self.logger.i(string.format("Match pattern: '%s'", pattern))
    self.logger.i("=== All Chrome Windows ===")

    for _, app in ipairs(chromeApps) do
        local windows = app:allWindows()
        for _, win in ipairs(windows) do
            local title = win:title()
            if title then
                local matches = title:find(pattern) ~= nil
                self.logger.i(string.format("  Window: '%s' | Matches: %s", title, tostring(matches)))

                -- Chrome window titles end with " - ProfileName"
                if matches then
                    table.insert(matchingWindows, win)
                end
            end
        end
    end

    self.logger.i("=== End Windows List ===")

    -- Sort windows by ID for consistent ordering
    table.sort(matchingWindows, function(a, b)
        return a:id() < b:id()
    end)

    self.logger.i(string.format("Found %d matching windows", #matchingWindows))

    if #matchingWindows == 0 then
        self.logger.i("No matching windows found, launching with profile")
        self:launchChromeWithProfile(profileDir)
        return
    end

    -- Determine which window to focus
    local targetWindow = nil
    local frontmostApp = hs.application.frontmostApplication()
    local frontmostWindow = hs.window.focusedWindow()

    -- Check if current frontmost window is Chrome with our target profile
    if frontmostApp and frontmostApp:bundleID() == "com.google.Chrome" and frontmostWindow then
        local frontTitle = frontmostWindow:title()
        if frontTitle and frontTitle:find(" %- " .. self:escapePattern(profileName) .. "$") then
            -- Current window matches target profile, cycle to next
            self.logger.i("Current window matches target profile, cycling to next")

            local currentIndex = nil
            for i, win in ipairs(matchingWindows) do
                if win:id() == frontmostWindow:id() then
                    currentIndex = i
                    break
                end
            end

            if currentIndex then
                local nextIndex = currentIndex + 1
                if nextIndex > #matchingWindows then
                    nextIndex = 1
                end
                targetWindow = matchingWindows[nextIndex]
                self.logger.i(string.format("Cycling from window %d to %d", currentIndex, nextIndex))
            else
                -- Somehow didn't find current window in list, just use first
                targetWindow = matchingWindows[1]
            end
        else
            -- Current window is different profile or not Chrome, switch to first
            self.logger.i("Current window is different profile, switching to first")
            targetWindow = matchingWindows[1]
        end
    else
        -- Chrome is not frontmost, switch to first matching window
        self.logger.i("Chrome not frontmost, switching to first matching window")
        targetWindow = matchingWindows[1]
    end

    -- Focus the target window
    if targetWindow then
        self.logger.i(string.format("Focusing window: %s", targetWindow:title()))
        targetWindow:focus()
    end
end

--- ChromeProfileSwitcher:launchChromeWithProfile(profileDir)
--- Method
--- Launches Chrome with the specified profile directory
---
--- Parameters:
---  * profileDir - The profile directory name
---
--- Returns:
---  * None
function obj:launchChromeWithProfile(profileDir)
    self.logger.i(string.format("Launching Chrome with profile: %s", profileDir))

    local command = string.format("open -na 'Google Chrome' --args --profile-directory='%s'", profileDir)
    local output, status = hs.execute(command)

    if status then
        self.logger.i("Successfully launched Chrome")
    else
        self.logger.e(string.format("Failed to launch Chrome: %s", output))
        hs.notify.new({
            title = "ChromeProfileSwitcher",
            informativeText = string.format("Failed to launch Chrome with profile: %s", profileDir)
        }):send()
    end
end

--- ChromeProfileSwitcher:escapePattern(str)
--- Method
--- Escapes special characters in a string for pattern matching
---
--- Parameters:
---  * str - The string to escape
---
--- Returns:
---  * The escaped string
function obj:escapePattern(str)
    -- Escape special Lua pattern characters
    return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

return obj
