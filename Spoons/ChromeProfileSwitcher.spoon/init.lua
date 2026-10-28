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

-- Reports an app Hammerspoon cannot reach over accessibility, which otherwise
-- looks identical to the app genuinely having no windows. Optional dependency,
-- so the Spoon still works standalone.
local function warnIfAccessibilityStale(app)
    if spoon and spoon.AccessibilityHealth then
        return spoon.AccessibilityHealth:warnIfStale(app)
    end

    return false
end

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
                local matches, reason = self:titleMatchesProfile(title, profileName)
                self.logger.i(string.format("  Window[%d]: '%s' | Matches: %s | Rule: %s", win:id() or -1, title, tostring(matches), reason))

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
        -- Chrome is running, so an empty list can also mean Hammerspoon cannot
        -- read Chrome's windows at all. Launching another window would not fix
        -- that, and it hides the real problem behind a stray window.
        for _, app in ipairs(chromeApps) do
            if warnIfAccessibilityStale(app) then
                self.logger.w("Chrome is unreachable over accessibility, not launching")
                return
            end
        end

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
        local frontMatches = false
        local frontReason = "missing-title"
        if frontTitle then
            frontMatches, frontReason = self:titleMatchesProfile(frontTitle, profileName)
            self.logger.i(string.format("Front window[%d] title='%s' | matches=%s | rule=%s", frontmostWindow:id() or -1, frontTitle, tostring(frontMatches), frontReason))
        end

        if frontTitle and frontMatches then
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
        local targetId = targetWindow:id() or -1
        targetWindow:raise()
        targetWindow:focus()

        -- Some scripted focus transitions don't always emit windowFocused reliably.
        -- Trigger FlashOnFocus explicitly for the resulting focused window.
        hs.timer.doAfter(0.08, function()
            local focused = hs.window.focusedWindow()
            local focusedId = focused and focused:id() or -1
            self.logger.i(string.format("Post-focus check target=%d focused=%d", targetId, focusedId))

            if spoon and spoon.FlashOnFocus then
                if spoon.FlashOnFocus.flashWindow and focused and focused:id() == targetId then
                    spoon.FlashOnFocus:flashWindow(focused)
                    self.logger.i("Triggered FlashOnFocus:flashWindow")
                elseif spoon.FlashOnFocus.flash then
                    spoon.FlashOnFocus:flash()
                    self.logger.i("Triggered FlashOnFocus:flash fallback")
                end
            end
        end)
    end
end

--- ChromeProfileSwitcher:titleMatchesProfile(title, profileName)
--- Method
--- Determines whether a Chrome window title matches a profile name
---
--- Parameters:
---  * title - Window title
---  * profileName - Profile display name
---
--- Returns:
---  * matches (boolean), reason (string)
function obj:titleMatchesProfile(title, profileName)
    if not title or not profileName then
        return false, "missing-title-or-profile"
    end

    local escapedProfile = self:escapePattern(profileName)
    local exactSuffixPattern = " %- " .. escapedProfile .. "$"
    if title:find(exactSuffixPattern) then
        return true, "exact-suffix-profile"
    end

    -- Some Chrome versions include app/product text after profile.
    local beforeChromePattern = " %- " .. escapedProfile .. " %- Google Chrome$"
    if title:find(beforeChromePattern) then
        return true, "profile-before-google-chrome"
    end

    -- Fallback: split title by " - " and only consider trailing profile positions.
    local segments = {}
    local searchPos = 1
    while true do
        local delimStart, delimEnd = title:find(" - ", searchPos, true)
        local segment
        if delimStart then
            segment = title:sub(searchPos, delimStart - 1)
            searchPos = delimEnd + 1
        else
            segment = title:sub(searchPos)
        end

        local trimmed = segment:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then
            table.insert(segments, trimmed)
        end

        if not delimStart then
            break
        end
    end

    local normalizedProfile = self:normalizeProfileToken(profileName)

    -- Common Chrome format: "... - Google Chrome - <Profile>"
    local lastIdx = #segments
    if lastIdx >= 1 and self:normalizeProfileToken(segments[lastIdx]) == normalizedProfile then
        return true, "last-segment-profile-normalized"
    end

    -- Alternate format observed in some contexts: "... - <Profile> - Google Chrome"
    if lastIdx >= 2 and
        self:normalizeProfileToken(segments[lastIdx - 1]) == normalizedProfile and
        self:normalizeProfileToken(segments[lastIdx]) == "google chrome" then
        return true, "profile-before-google-chrome-normalized"
    end

    return false, "no-match"
end

--- ChromeProfileSwitcher:normalizeProfileToken(str)
--- Method
--- Normalizes profile/title tokens for robust matching
---
--- Parameters:
---  * str - Token string to normalize
---
--- Returns:
---  * Normalized string
function obj:normalizeProfileToken(str)
    return str:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " "):lower()
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
