local log = hs.logger.new('mymodule', 'debug')

-- Table to store temporary positions for the focused window toggle
local storedPositions = {}

-- Table to store persistent position slots (0-9)
local slotsJson = hs.settings.get("WindowPositionSlots")
local slots = slotsJson and hs.json.decode(slotsJson) or {}
log.d("slots", hs.inspect(slots))

-- Function to get the center screen dynamically (sorts by x-position, picks middle)
local function getCenterScreen()
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b)
        return a:frame().x < b:frame().x
    end)
    -- Assuming 3 screens: index 1 = left, 2 = center, 3 = right
    return screens[2] -- Adjust index if your setup has more/less screens or different order
end

-- Function to get screen by ID
local function getScreenById(screenId)
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:id() == screenId then
            return screen
        end
    end
    log.e("Screen ID " .. screenId .. " not found, using primary screen")
    return hs.screen.primaryScreen() -- Fallback if screen is disconnected
end

-- Function to find a stored slot position by app name and title (or just app name as fallback)
local function findPosition(win)
    local appName = win:application():name()
    local title = win:title()

    for i = 0, 9 do
        local position = slots[i]
        if position and position.appName == appName and position.title == title then
            return position
        end
    end

    for i = 0, 9 do
        local position = slots[i]
        if position and position.appName == appName then
            return position
        end
    end
    return nil
end

-- Function to restore a window to its original or slot position
local function restoreWindow(win, position)
    if position and position.screenId then
        local screen = getScreenById(position.screenId)
        local frame = hs.geometry.new(position.x, position.y, position.w, position.h)
        win:moveToScreen(screen)
        win:setFrame(frame)
        hs.alert.show("Restored: " .. win:application():name() .. " - " .. win:title())
    else
        log.d("Focused window not recently stored, looking in slots")
        local slotPosition = findPosition(win)
        if slotPosition and slotPosition ~= position then -- Guard against infinite recursion
            restoreWindow(win, slotPosition)
        else
            hs.alert.show("No stored position")
        end
    end
end

-- Function to find a window by app name and title (or just app name as fallback)
local function findWindow(appName, title)
    local windows = hs.window.allWindows()
    for _, win in ipairs(windows) do
        if win:application():name() == appName and win:title() == title then
            return win
        end
    end
    -- Fallback: Find by app name only if no exact match
    for _, win in ipairs(windows) do
        if win:application():name() == appName then
            return win
        end
    end
    return nil
end

-- Function to save a window position to a slot
local function saveToSlot(win, slot)
    if win then
        local appName = win:application():name()
        local title = win:title()
        local frame = win:frame()

        slots[slot] = {
            screenId = win:screen():id(),
            x = frame.x,
            y = frame.y,
            w = frame.w,
            h = frame.h,
            appName = appName,
            title = title
        }
        hs.settings.set("WindowPositionSlots", hs.json.encode(slots))
        hs.alert.show("Saved to slot " .. slot .. ": " .. appName .. " - " .. title)
    else
        hs.alert.show("No focused window to save")
    end
end

-- F13 toggle for the focused window
hs.hotkey.bind({}, "f13", function()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window")
        return
    end

    local centerScreen = getCenterScreen()
    local isOnCenter = win:screen() == centerScreen
    local appName = win:application():name()
    local title = win:title()
    local key = appName .. " - " .. title

    if isOnCenter then
        restoreWindow(win, storedPositions[key])
        storedPositions[key] = nil -- Clear after restore
    else
        -- Store current position
        local currentScreen = win:screen()
        local currentFrame = win:frame()
        storedPositions[key] = {
            screenId = currentScreen:id(),
            x = currentFrame.x,
            y = currentFrame.y,
            w = currentFrame.w,
            h = currentFrame.h
        }

        -- Move to center and maximize
        win:moveToScreen(centerScreen)
        win:maximize()
        hs.alert.show("Moved to center: " .. key)
    end
end)

-- Cmd + Alt + F13 modal for saving to slots (0-9)
local saveModal = hs.hotkey.modal.new({"cmd", "alt"}, "f13")
saveModal:bind({}, "escape", function()
    saveModal:exit()
end)
for i = 0, 9 do
    saveModal:bind({}, tostring(i), function()
        local win = hs.window.focusedWindow()
        saveToSlot(win, i) -- Map 0-9 keys to slots 0-9
        saveModal:exit()
    end)
end
saveModal:entered(function()
    hs.alert.show("Press a number key (0-9) to save position...")
end)
saveModal:exited(function()
end)

-- Cmd + F13 modal for toggling specific window (0-9)
local toggleModal = hs.hotkey.modal.new({"cmd"}, "f13")
toggleModal:bind({}, "escape", function()
    toggleModal:exit()
end)
for i = 0, 9 do
    toggleModal:bind({}, tostring(i), function()
        local position = slots[i]
        if not position then
            hs.alert.show("No window recorded in slot " .. i)
            toggleModal:exit()
            return
        end

        local targetWin = findWindow(position.appName, position.title)
        if not targetWin then
            hs.alert.show("No matching window found")
            toggleModal:exit()
            return
        end

        local centerScreen = getCenterScreen()
        local isOnCenter = targetWin:screen() == centerScreen
        local slot = i
        local appName = targetWin:application():name()
        local title = targetWin:title()

        if isOnCenter then
            restoreWindow(targetWin, slots[slot])
        else
            targetWin:moveToScreen(centerScreen)
            targetWin:maximize()
            targetWin:focus()
            hs.alert.show("Moved to center (slot " .. slot .. "): " .. appName .. " - " .. title)
        end
        toggleModal:exit()
    end)
end
toggleModal:entered(function()
    hs.alert.show("Press a number key (0-9) to toggle position...")
end)
toggleModal:exited(function()
end)
