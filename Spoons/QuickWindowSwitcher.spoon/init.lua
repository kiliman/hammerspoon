--- === QuickWindowSwitcher ===
---
--- Show a searchable list of all windows for the current application
--- Navigate with arrow keys, numbers (1-9, 0), or click to focus a window
---
--- Download: N/A
--- License: MIT
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "QuickWindowSwitcher"
obj.version = "1.0.0"
obj.author = "Michael Carter"
obj.homepage = "https://github.com/kiliman/hammerspoon"
obj.license = "MIT"

obj.logger = hs.logger.new('QuickWindowSwitcher', 'debug')

-- Chooser instance
obj.chooser = nil

-- Hotkey references for cleanup
obj.hotkeyRefs = {}

-- Reports an app Hammerspoon cannot reach over accessibility, which otherwise
-- looks identical to the app genuinely having no windows. Optional dependency,
-- so the Spoon still works standalone.
local function warnIfAccessibilityStale(app)
    if spoon and spoon.AccessibilityHealth then
        return spoon.AccessibilityHealth:warnIfStale(app)
    end

    return false
end

--- QuickWindowSwitcher:init()
--- Method
--- Initializes the Spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The QuickWindowSwitcher object
function obj:init()
    self.logger.d("Initializing QuickWindowSwitcher")

    -- Create chooser
    self.chooser = hs.chooser.new(function(choice)
        if choice then
            self:selectWindow(choice)
        end
    end)

    -- Configure chooser
    self.chooser:placeholderText("Select a window...")
    self.chooser:searchSubText(true)
    self.chooser:rows(10)

    return self
end

--- QuickWindowSwitcher:selectWindow(choice)
--- Method
--- Focuses and raises the selected window
---
--- Parameters:
---  * choice - The chooser choice containing the window
---
--- Returns:
---  * None
function obj:selectWindow(choice)
    if choice and choice.window then
        choice.window:focus()
        choice.window:raise()
        self.logger.d("Focused window:", choice.text)
    end
end

--- QuickWindowSwitcher:getWindowsForCurrentApp()
--- Method
--- Gets all windows for the currently focused application
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of choices for hs.chooser
function obj:getWindowsForCurrentApp()
    local focusedWindow = hs.window.focusedWindow()
    if not focusedWindow then
        return {}
    end

    local app = focusedWindow:application()
    if not app then
        return {}
    end

    local appName = app:name()
    local windows = app:allWindows()

    self.logger.d("Found", #windows, "windows for", appName)

    local choices = {}
    for i, win in ipairs(windows) do
        -- Only include standard windows (not hidden, minimized, etc.)
        if win:isStandard() and win:isVisible() then
            local title = win:title()
            -- Show window title, or "Untitled" if empty
            local displayTitle = (title and title ~= "") and title or "Untitled"

            table.insert(choices, {
                text = displayTitle,
                subText = appName,
                window = win,
                index = #choices + 1
            })
        end
    end

    self.logger.d("Created", #choices, "choices")

    return choices
end

--- QuickWindowSwitcher:show()
--- Method
--- Shows the window list for the current application
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:show()
    local choices = self:getWindowsForCurrentApp()

    if #choices == 0 then
        -- An unreachable app yields no windows and no focused window, so fall
        -- back to frontmostApplication(), which does not depend on the AX API.
        if not warnIfAccessibilityStale(hs.application.frontmostApplication()) then
            hs.alert.show("No windows found for current application")
        end
        return
    end

    if #choices == 1 then
        -- Only one window, just focus it
        self:selectWindow(choices[1])
        return
    end

    -- Set choices and show
    self.chooser:choices(choices)
    self.chooser:show()
end

--- QuickWindowSwitcher:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for the Spoon
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * show - Show the window list (e.g., {{"cmd", "ctrl"}, "w"})
---
--- Returns:
---  * The QuickWindowSwitcher object
function obj:bindHotkeys(mapping)
    if mapping["show"] then
        local mod, key = table.unpack(mapping["show"])
        self.hotkeyRefs.show = hs.hotkey.bind(mod, key, function()
            self:show()
        end)
    end

    return self
end

--- QuickWindowSwitcher:start()
--- Method
--- Starts the Spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The QuickWindowSwitcher object
function obj:start()
    self.logger.i("QuickWindowSwitcher started")
    return self
end

--- QuickWindowSwitcher:stop()
--- Method
--- Stops the Spoon and cleans up hotkeys
---
--- Parameters:
---  * None
---
--- Returns:
---  * The QuickWindowSwitcher object
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

    self.logger.i("QuickWindowSwitcher stopped")
    return self
end

return obj
