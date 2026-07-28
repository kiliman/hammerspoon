--- === FocusMode ===
---
--- Advanced window management for multi-monitor setups
--- Provides Focus Mode to move windows to center/primary screen and restore positions
--- Supports per-app saved positions for quick window recall
---
--- Download: N/A
--- License: MIT

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "FocusMode"
obj.version = "2.0.0"
obj.author = "Michael"
obj.homepage = "N/A"
obj.license = "MIT"

obj.logger = hs.logger.new('FocusMode', 'debug')

-- Table to store temporary positions for the focused window toggle (Focus Mode)
obj.storedPositions = {}

-- Table to store persistent per-app saved positions (keyed by app name)
obj.appPositions = {}

-- Hotkey references for cleanup
obj.hotkeyRefs = {}

--- FocusMode:init()
--- Method
--- Initializes the Spoon, loading saved app positions
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FocusMode object
function obj:init()
    local json = hs.settings.get("FocusModeAppPositions")
    self.appPositions = json and hs.json.decode(json) or {}
    self.logger.d("Loaded app positions:", hs.inspect(self.appPositions))
    return self
end

--- FocusMode:getCenterScreen()
--- Method
--- Returns the center/primary screen
function obj:getCenterScreen()
    local screen = hs.screen.primaryScreen()
    self.logger.d("Center screen ID:", screen:id(), "Name:", screen:name())
    return screen
end

--- FocusMode:logWindowFrame(label, win)
--- Method
--- Helper to log window dimensions with a label
function obj:logWindowFrame(label, win)
    local frame = win:frame()
    local screen = win:screen()
    self.logger.d(label .. ":", frame.w, "x", frame.h, "on screen", screen:name())
end

--- FocusMode:getScreenById(screenId)
--- Method
--- Finds a screen by its ID, with fallback to primary
function obj:getScreenById(screenId)
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:id() == screenId then
            return screen
        end
    end
    self.logger.e("Screen ID " .. tostring(screenId) .. " not found, using primary screen")
    return hs.screen.primaryScreen()
end

--- FocusMode:fitAndCenterWindow(win, screen, originalFrame)
--- Method
--- Fits and centers a window on a screen, resizing only if necessary
function obj:fitAndCenterWindow(win, screen, originalFrame)
    local winFrame = originalFrame or win:frame()
    local screenFrame = screen:frame()

    self.logger.d("Original window size:", winFrame.w, "x", winFrame.h)
    self.logger.d("Screen frame:", screenFrame.w, "x", screenFrame.h)

    local newW = math.min(winFrame.w, screenFrame.w)
    local newH = math.min(winFrame.h, screenFrame.h)

    local newX = screenFrame.x + (screenFrame.w - newW) / 2
    local newY = screenFrame.y + (screenFrame.h - newH) / 2

    win:setFrame({
        x = newX,
        y = newY,
        w = newW,
        h = newH
    })
end

--- FocusMode:applyPosition(win, position)
--- Method
--- Moves a window to a saved position
function obj:applyPosition(win, position)
    local screen = self:getScreenById(position.screenId)
    local frame = hs.geometry.new(position.x, position.y, position.w, position.h)
    win:moveToScreen(screen)
    win:setFrame(frame)
    self:logWindowFrame("Window after applyPosition", win)
end

--- FocusMode:focusMode()
--- Method
--- Toggles the focused window to/from center screen.
--- If the window has no temporary stored position when on the center screen,
--- falls back to the saved per-app position (if any).
function obj:focusMode()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window")
        return
    end

    local centerScreen = self:getCenterScreen()
    local isOnCenter = win:screen() == centerScreen
    local appName = win:application():name()
    local title = win:title()
    local key = appName .. " - " .. title

    if isOnCenter then
        local stored = self.storedPositions[key]
        if stored then
            self:applyPosition(win, stored)
            self.storedPositions[key] = nil
            hs.alert.show("Restored: " .. key)
        else
            -- Fallback to saved per-app position
            local saved = self.appPositions[appName]
            if saved then
                self:applyPosition(win, saved)
                hs.alert.show("Restored saved position: " .. appName)
            else
                hs.alert.show("No stored position")
            end
        end
    else
        -- Store current position before moving to center
        local currentScreen = win:screen()
        local currentFrame = win:frame()
        self:logWindowFrame("Storing original window", win)
        self.storedPositions[key] = {
            screenId = currentScreen:id(),
            x = currentFrame.x,
            y = currentFrame.y,
            w = currentFrame.w,
            h = currentFrame.h
        }

        win:moveToScreen(centerScreen)
        self:logWindowFrame("Window after moveToScreen", win)
        self:fitAndCenterWindow(win, centerScreen, currentFrame)
        hs.alert.show("Moved to center: " .. key)
    end
end

--- FocusMode:saveAppPosition()
--- Method
--- Saves the focused window's current position, keyed by its application name.
--- Overwrites any previous saved position for that app.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:saveAppPosition()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window to save")
        return
    end

    local appName = win:application():name()
    local title = win:title()
    local frame = win:frame()

    self.appPositions[appName] = {
        screenId = win:screen():id(),
        x = frame.x,
        y = frame.y,
        w = frame.w,
        h = frame.h,
        title = title  -- stored for reference/debug only; not used for matching
    }
    hs.settings.set("FocusModeAppPositions", hs.json.encode(self.appPositions))
    self.logger.d("Saved position for", appName, ":", hs.inspect(self.appPositions[appName]))
    hs.alert.show("Saved position: " .. appName)
end

--- FocusMode:restoreAppPosition()
--- Method
--- Restores the focused window to the saved position for its application.
--- Matches by application name (loose — ignores window title).
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:restoreAppPosition()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window")
        return
    end

    local appName = win:application():name()
    local saved = self.appPositions[appName]
    if not saved then
        hs.alert.show("No saved position for: " .. appName)
        return
    end

    self:applyPosition(win, saved)
    hs.alert.show("Restored: " .. appName)
end

--- FocusMode:forgetAppPosition()
--- Method
--- Removes the saved position for the focused window's application.
function obj:forgetAppPosition()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window")
        return
    end

    local appName = win:application():name()
    if self.appPositions[appName] then
        self.appPositions[appName] = nil
        hs.settings.set("FocusModeAppPositions", hs.json.encode(self.appPositions))
        hs.alert.show("Forgot position: " .. appName)
    else
        hs.alert.show("No saved position for: " .. appName)
    end
end

--- FocusMode:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for the Spoon
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * focusMode - Toggle focused window to/from center (e.g., {{}, "f13"})
---   * saveApp - Save focused window's position by app name (e.g., {{"cmd","shift"}, "f13"})
---   * restoreApp - Restore focused window to saved app position (e.g., {{"cmd"}, "f13"})
---   * forgetApp - (optional) Forget saved position for focused app
---
--- Returns:
---  * The FocusMode object
function obj:bindHotkeys(mapping)
    if mapping["focusMode"] then
        local mod, key = table.unpack(mapping["focusMode"])
        self.hotkeyRefs.focusMode = hs.hotkey.bind(mod, key, function()
            self:focusMode()
        end)
    end

    if mapping["saveApp"] then
        local mod, key = table.unpack(mapping["saveApp"])
        self.hotkeyRefs.saveApp = hs.hotkey.bind(mod, key, function()
            self:saveAppPosition()
        end)
    end

    if mapping["restoreApp"] then
        local mod, key = table.unpack(mapping["restoreApp"])
        self.hotkeyRefs.restoreApp = hs.hotkey.bind(mod, key, function()
            self:restoreAppPosition()
        end)
    end

    if mapping["forgetApp"] then
        local mod, key = table.unpack(mapping["forgetApp"])
        self.hotkeyRefs.forgetApp = hs.hotkey.bind(mod, key, function()
            self:forgetAppPosition()
        end)
    end

    return self
end

--- FocusMode:start()
--- Method
--- Starts the Spoon (currently no background tasks)
function obj:start()
    self.logger.i("FocusMode started")
    return self
end

--- FocusMode:stop()
--- Method
--- Stops the Spoon and cleans up hotkeys
function obj:stop()
    for _, ref in pairs(self.hotkeyRefs) do
        if ref.delete then
            ref:delete()
        end
    end
    self.hotkeyRefs = {}
    self.logger.i("FocusMode stopped")
    return self
end

return obj
