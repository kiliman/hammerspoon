--- === FocusMode ===
---
--- Advanced window management for multi-monitor setups
--- Provides Focus Mode to move windows to center/primary screen and restore positions
--- Supports persistent position slots for quick window recall
---
--- Download: N/A
--- License: MIT

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "FocusMode"
obj.version = "1.0.0"
obj.author = "Michael"
obj.homepage = "N/A"
obj.license = "MIT"

obj.logger = hs.logger.new('FocusMode', 'debug')

-- Table to store temporary positions for the focused window toggle
obj.storedPositions = {}

-- Table to store persistent position slots (0-9)
obj.slots = {}

-- Hotkey references for cleanup
obj.hotkeyRefs = {}

--- FocusMode:init()
--- Method
--- Initializes the Spoon, loading saved position slots
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FocusMode object
function obj:init()
    local slotsJson = hs.settings.get("WindowPositionSlots")
    self.slots = slotsJson and hs.json.decode(slotsJson) or {}
    self.logger.d("Loaded slots:", hs.inspect(self.slots))
    return self
end

--- FocusMode:getCenterScreen()
--- Method
--- Returns the center/primary screen
---
--- Parameters:
---  * None
---
--- Returns:
---  * The primary screen object
function obj:getCenterScreen()
    local screen = hs.screen.primaryScreen()
    self.logger.d("Center screen ID:", screen:id(), "Name:", screen:name())
    return screen
end

--- FocusMode:logWindowFrame(label, win)
--- Method
--- Helper to log window dimensions with a label
---
--- Parameters:
---  * label - Description of what's being logged
---  * win - The window to log
---
--- Returns:
---  * None
function obj:logWindowFrame(label, win)
    local frame = win:frame()
    local screen = win:screen()
    self.logger.d(label .. ":", frame.w, "x", frame.h, "on screen", screen:name())
end

--- FocusMode:getScreenById(screenId)
--- Method
--- Finds a screen by its ID
---
--- Parameters:
---  * screenId - The screen ID to find
---
--- Returns:
---  * The screen object, or primary screen if not found
function obj:getScreenById(screenId)
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:id() == screenId then
            return screen
        end
    end
    self.logger.e("Screen ID " .. screenId .. " not found, using primary screen")
    return hs.screen.primaryScreen()
end

--- FocusMode:findPosition(win)
--- Method
--- Searches slots for a saved position matching the window
---
--- Parameters:
---  * win - The window to find a position for
---
--- Returns:
---  * The saved position or nil if not found
function obj:findPosition(win)
    local appName = win:application():name()
    local title = win:title()

    -- Try exact match first (app name + title)
    for i = 0, 9 do
        local position = self.slots[i]
        if position and position.appName == appName and position.title == title then
            return position
        end
    end

    -- Fallback to app name only
    for i = 0, 9 do
        local position = self.slots[i]
        if position and position.appName == appName then
            return position
        end
    end
    return nil
end

--- FocusMode:restoreWindow(win, position)
--- Method
--- Restores a window to its saved position
---
--- Parameters:
---  * win - The window to restore
---  * position - The position data to restore to
---
--- Returns:
---  * None
function obj:restoreWindow(win, position)
    if position and position.screenId then
        self.logger.d("Restoring to saved position:", position.w, "x", position.h)
        local screen = self:getScreenById(position.screenId)
        local frame = hs.geometry.new(position.x, position.y, position.w, position.h)
        win:moveToScreen(screen)
        win:setFrame(frame)
        self:logWindowFrame("Window after restore", win)
        hs.alert.show("Restored: " .. win:application():name() .. " - " .. win:title())
    else
        self.logger.d("Focused window not recently stored, looking in slots")
        local slotPosition = self:findPosition(win)
        if slotPosition and slotPosition ~= position then
            self:restoreWindow(win, slotPosition)
        else
            hs.alert.show("No stored position")
        end
    end
end

--- FocusMode:findWindow(appName, title)
--- Method
--- Finds a window by app name and title
---
--- Parameters:
---  * appName - The application name
---  * title - The window title
---
--- Returns:
---  * The window object or nil if not found
function obj:findWindow(appName, title)
    local windows = hs.window.allWindows()

    -- Try exact match first
    for _, win in ipairs(windows) do
        if win:application():name() == appName and win:title() == title then
            return win
        end
    end

    -- Fallback: Find by app name only
    for _, win in ipairs(windows) do
        if win:application():name() == appName then
            return win
        end
    end
    return nil
end

--- FocusMode:fitAndCenterWindow(win, screen, originalFrame)
--- Method
--- Fits and centers a window on a screen, resizing only if necessary
---
--- Parameters:
---  * win - The window to fit and center
---  * screen - The screen to fit the window on
---  * originalFrame - (optional) The original frame to use for dimensions (before moveToScreen)
---
--- Returns:
---  * None
function obj:fitAndCenterWindow(win, screen, originalFrame)
    -- Use provided original frame, or get current frame if not provided
    local winFrame = originalFrame or win:frame()
    local screenFrame = screen:frame()

    self.logger.d("Original window size:", winFrame.w, "x", winFrame.h)
    self.logger.d("Screen frame:", screenFrame.w, "x", screenFrame.h)

    -- Only resize if window doesn't fit
    local newW = math.min(winFrame.w, screenFrame.w)
    local newH = math.min(winFrame.h, screenFrame.h)

    self.logger.d("New window size:", newW, "x", newH)

    -- Center the window on the screen
    local newX = screenFrame.x + (screenFrame.w - newW) / 2
    local newY = screenFrame.y + (screenFrame.h - newH) / 2

    self.logger.d("New position:", newX, ",", newY)

    win:setFrame({
        x = newX,
        y = newY,
        w = newW,
        h = newH
    })
end

--- FocusMode:saveWindowSlot(slot)
--- Method
--- Saves the focused window position to a slot
---
--- Parameters:
---  * slot - The slot number (0-9) to save to
---
--- Returns:
---  * None
function obj:saveWindowSlot(slot)
    local win = hs.window.focusedWindow()
    if win then
        local appName = win:application():name()
        local title = win:title()
        local frame = win:frame()

        self.slots[slot] = {
            screenId = win:screen():id(),
            x = frame.x,
            y = frame.y,
            w = frame.w,
            h = frame.h,
            appName = appName,
            title = title
        }
        hs.settings.set("WindowPositionSlots", hs.json.encode(self.slots))
        hs.alert.show("Saved to slot " .. slot .. ": " .. appName .. " - " .. title)
    else
        hs.alert.show("No focused window to save")
    end
end

--- FocusMode:focusMode()
--- Method
--- Toggles the focused window to/from center screen
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
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
        self:restoreWindow(win, self.storedPositions[key])
        self.storedPositions[key] = nil
    else
        -- Store current position (BEFORE moveToScreen changes it)
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

        -- Move to center and fit (using original frame dimensions)
        win:moveToScreen(centerScreen)
        self:logWindowFrame("Window after moveToScreen", win)
        self:fitAndCenterWindow(win, centerScreen, currentFrame)
        hs.alert.show("Moved to center: " .. key)
    end
end

--- FocusMode:toggleWindowSlot(slot)
--- Method
--- Toggles a window from a slot to/from center screen
---
--- Parameters:
---  * slot - The slot number (0-9) to toggle
---
--- Returns:
---  * None
function obj:toggleWindowSlot(slot)
    local position = self.slots[slot]
    if not position then
        hs.alert.show("No window recorded in slot " .. slot)
        return
    end

    local targetWin = self:findWindow(position.appName, position.title)
    if not targetWin then
        hs.alert.show("No matching window found")
        return
    end

    local centerScreen = self:getCenterScreen()
    local isOnCenter = targetWin:screen() == centerScreen
    local appName = targetWin:application():name()
    local title = targetWin:title()

    if isOnCenter then
        self:restoreWindow(targetWin, self.slots[slot])
    else
        -- Capture frame BEFORE moveToScreen changes it
        local originalFrame = targetWin:frame()
        targetWin:moveToScreen(centerScreen)
        self:fitAndCenterWindow(targetWin, centerScreen, originalFrame)
        targetWin:focus()
        hs.alert.show("Moved to center (slot " .. slot .. "): " .. appName .. " - " .. title)
    end
end

--- FocusMode:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for the Spoon
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * focusMode - Toggle focused window to/from center (e.g., {{}, "f13"})
---   * saveSlot - Enter save slot modal (e.g., {{"cmd", "alt"}, "f13"})
---   * toggleSlot - Enter toggle slot modal (e.g., {{"cmd"}, "f13"})
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

    if mapping["saveSlot"] then
        local mod, key = table.unpack(mapping["saveSlot"])
        local saveModal = hs.hotkey.modal.new(mod, key)

        saveModal:bind({}, "escape", function()
            saveModal:exit()
        end)

        for i = 0, 9 do
            saveModal:bind({}, tostring(i), function()
                self:saveWindowSlot(i)
                saveModal:exit()
            end)
        end

        function saveModal:entered()
            hs.alert.show("Press a number key (0-9) to save position...")
        end

        self.hotkeyRefs.saveSlot = saveModal
    end

    if mapping["toggleSlot"] then
        local mod, key = table.unpack(mapping["toggleSlot"])
        local toggleModal = hs.hotkey.modal.new(mod, key)

        toggleModal:bind({}, "escape", function()
            toggleModal:exit()
        end)

        for i = 0, 9 do
            toggleModal:bind({}, tostring(i), function()
                self:toggleWindowSlot(i)
                toggleModal:exit()
            end)
        end

        function toggleModal:entered()
            hs.alert.show("Press a number key (0-9) to toggle position...")
        end

        self.hotkeyRefs.toggleSlot = toggleModal
    end

    return self
end

--- FocusMode:start()
--- Method
--- Starts the Spoon (currently no background tasks)
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FocusMode object
function obj:start()
    self.logger.i("FocusMode started")
    return self
end

--- FocusMode:stop()
--- Method
--- Stops the Spoon and cleans up hotkeys
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FocusMode object
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
