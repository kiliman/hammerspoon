--- === ChromeTabSwitcher ===
---
--- Show a searchable list of all Chrome tabs across all windows
--- Navigate with arrow keys, numbers (1-9, 0), or click to focus a tab
---
--- Download: N/A
--- License: MIT

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ChromeTabSwitcher"
obj.version = "1.0.0"
obj.author = "Michael Carter"
obj.homepage = "https://github.com/kiliman/hammerspoon"
obj.license = "MIT"

obj.logger = hs.logger.new('ChromeTabSwitcher', 'debug')

-- Chooser instance
obj.chooser = nil

-- Hotkey references for cleanup
obj.hotkeyRefs = {}

--- ChromeTabSwitcher:init()
--- Method
--- Initializes the Spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ChromeTabSwitcher object
function obj:init()
    self.logger.d("Initializing ChromeTabSwitcher")

    -- Create chooser
    self.chooser = hs.chooser.new(function(choice)
        if choice then
            self:selectTab(choice)
        end
    end)

    -- Configure chooser
    self.chooser:placeholderText("Select a Chrome tab...")
    self.chooser:searchSubText(true)
    self.chooser:rows(15)

    return self
end

--- ChromeTabSwitcher:selectTab(choice)
--- Method
--- Activates the selected tab in its window
---
--- Parameters:
---  * choice - The chooser choice containing the tab info
---
--- Returns:
---  * None
function obj:selectTab(choice)
    if not choice then
        return
    end

    local windowIndex = choice.windowIndex
    local tabIndex = choice.tabIndex

    self.logger.d("Selecting tab:", choice.text, "Window:", windowIndex, "Tab:", tabIndex)

    -- AppleScript to activate the specific tab and window
    local script = string.format([[
        tell application "Google Chrome"
            set active tab index of window %d to %d
            set index of window %d to 1
            activate
        end tell
    ]], windowIndex, tabIndex, windowIndex)

    hs.osascript.applescript(script)
end

--- ChromeTabSwitcher:getAllChromeTabs()
--- Method
--- Gets all tabs from all Chrome windows using AppleScript
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of choices for hs.chooser
function obj:getAllChromeTabs()
    -- Get Chrome windows via Hammerspoon to get real window titles (with profiles)
    local chromeApps = hs.application.applicationsForBundleID("com.google.Chrome")
    local windowProfiles = {}  -- Map AppleScript window index to profile name

    if chromeApps and #chromeApps > 0 then
        local windowIndex = 1
        for _, app in ipairs(chromeApps) do
            local windows = app:allWindows()
            for _, win in ipairs(windows) do
                local title = win:title()
                if title then
                    -- Extract profile from window title (format: "Tab Title - Profile Name")
                    local profile = title:match(" %- ([^%-]+)$")
                    windowProfiles[windowIndex] = profile or ""
                    self.logger.d(string.format("Window %d: title='%s', profile='%s'", windowIndex, title, profile or "none"))
                end
                windowIndex = windowIndex + 1
            end
        end
    end

    -- Get all tabs from AppleScript
    local script = [[
        set output to ""
        tell application "Google Chrome"
            repeat with w from 1 to count of windows
                repeat with t from 1 to count of tabs of window w
                    set tabTitle to title of tab t of window w
                    set tabURL to URL of tab t of window w
                    set output to output & tabTitle & "|" & tabURL & "|" & w & "|" & t & "\n"
                end repeat
            end repeat
        end tell
        return output
    ]]

    local ok, result = hs.osascript.applescript(script)

    if not ok then
        self.logger.e("Failed to get Chrome tabs:", result)
        return {}
    end

    -- Parse the result
    local choices = {}
    for line in result:gmatch("[^\n]+") do
        local title, url, windowIndex, tabIndex = line:match("^(.+)|(.+)|(%d+)|(%d+)$")
        if title and url then
            -- Extract domain from URL
            local domain = url:match("^%w+://([^/]+)") or url

            -- Get profile from windowProfiles map
            local profile = windowProfiles[tonumber(windowIndex)] or ""

            -- Build subtext with profile
            local subText = domain
            if profile and profile ~= "" then
                subText = profile .. " • " .. domain
            end

            table.insert(choices, {
                text = title,
                subText = subText,
                url = url,
                profile = profile,
                windowIndex = tonumber(windowIndex),
                tabIndex = tonumber(tabIndex),
                index = #choices + 1
            })
        end
    end

    self.logger.d("Found", #choices, "Chrome tabs")

    return choices
end

--- ChromeTabSwitcher:show()
--- Method
--- Shows the tab list for all Chrome windows
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:show()
    -- Check if Chrome is running
    local chrome = hs.application.get("Google Chrome")
    if not chrome then
        hs.alert.show("Google Chrome is not running")
        return
    end

    local choices = self:getAllChromeTabs()

    if #choices == 0 then
        hs.alert.show("No Chrome tabs found")
        return
    end

    -- Set choices and show
    self.chooser:choices(choices)
    self.chooser:show()
end

--- ChromeTabSwitcher:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for the Spoon
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * show - Show the tab list (e.g., {{"cmd", "ctrl"}, "t"})
---
--- Returns:
---  * The ChromeTabSwitcher object
function obj:bindHotkeys(mapping)
    if mapping["show"] then
        local mod, key = table.unpack(mapping["show"])
        self.hotkeyRefs.show = hs.hotkey.bind(mod, key, function()
            self:show()
        end)
    end

    return self
end

--- ChromeTabSwitcher:start()
--- Method
--- Starts the Spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ChromeTabSwitcher object
function obj:start()
    self.logger.i("ChromeTabSwitcher started")
    return self
end

--- ChromeTabSwitcher:stop()
--- Method
--- Stops the Spoon and cleans up hotkeys
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ChromeTabSwitcher object
function obj:stop()
    for _, ref in pairs(self.hotkeyRefs) do
        if ref.delete then
            ref:delete()
        end
    end
    self.hotkeyRefs = {}

    if self.chooser then
        self.chooser:hide()
    end

    self.logger.i("ChromeTabSwitcher stopped")
    return self
end

return obj
