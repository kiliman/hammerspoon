--- === QuickSpaceSwitcher ===
---
--- Searchable chooser + direct hotkeys for Spaces (multi-display aware)
--- Uses screen under mouse pointer
---
--- License: MIT
local obj = {}
obj.__index = obj

obj.name = "QuickSpaceSwitcher"
obj.version = "1.2.0"
obj.author = "Michael Carter (with love from Claudia 💕)"
obj.homepage = "https://github.com/kiliman/hammerspoon"
obj.license = "MIT"

obj.logger = hs.logger.new('QuickSpaceSwitcher', 'debug')

obj.chooser = nil
obj.hotkeyRefs = {}

function obj:init()
    self.logger.d("Initializing QuickSpaceSwitcher")
    self.chooser = hs.chooser.new(function(choice)
        if choice then
            self:jumpToSpace(choice)
        end
    end)

    self.chooser:placeholderText("Search spaces (type name or number)...")
    self.chooser:searchSubText(true)
    self.chooser:rows(12)
    self.chooser:width(60)

    return self
end

-- Get the screen under the mouse (or fallback)
function obj:currentMouseScreen()
    -- local screen = hs.mouse.getCurrentScreen()
    local screen = hs.screen.mainScreen()
    if not screen then
        screen = hs.screen.mainScreen()
    end
    return screen
end

function obj:jumpToSpace(choice)
    if choice and choice.spaceID then
        hs.spaces.gotoSpace(choice.spaceID)
        self.logger.d("Jumped to space:", choice.text)
    end
end

function obj:show()
    local screen = self.currentMouseScreen()
    hs.alert.show("Spaces for: " .. screen:name(), 1.0) -- brief feedback

    local choices = {}
    local spaceIDs = hs.spaces.spacesForScreen(screen) or {}
    local mcNames = hs.spaces.missionControlSpaceNames()[screen:getUUID()] or {}

    for i, spaceID in ipairs(spaceIDs) do
        local spaceType = hs.spaces.spaceType(spaceID) or "unknown"
        local name = mcNames[spaceID] or ("Space " .. i)
        local displayText = string.format("%d: %s (%s)", i, name, spaceType)

        table.insert(choices, {
            text = displayText,
            subText = "ID: " .. spaceID .. " • " .. screen:name(),
            spaceID = spaceID,
            index = i
        })
    end

    self.chooser:choices(choices)
    self.chooser:show()
end

function obj:goToNthSpace(n)
    local screen = self.currentMouseScreen()
    local spaceIDs = hs.spaces.spacesForScreen(screen) or {}
    if spaceIDs[n] then
        hs.spaces.gotoSpace(spaceIDs[n])
        self.logger.d("Direct jump to space index", n, "on", screen:name())
    else
        hs.alert.show("Space " .. n .. " not found on " .. screen:name())
    end
end

function obj:bindHotkeys(mapping)
    for _, ref in pairs(self.hotkeyRefs or {}) do
        ref:delete()
    end
    self.hotkeyRefs = {}

    if mapping.show then
        self.hotkeyRefs.show = hs.hotkey.bind(mapping.show[1], mapping.show[2], function()
            self:show()
        end)
    end

    if mapping.direct then
        for i = 1, 9 do
            local key = tostring(i)
            if mapping.direct[key] then
                local mod, k = table.unpack(mapping.direct[key])
                self.hotkeyRefs["direct" .. i] = hs.hotkey.bind(mod, k, function()
                    self:goToNthSpace(i)
                end)
            end
        end
    end
end

return obj
