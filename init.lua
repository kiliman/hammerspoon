-- enable CLI support
require("hs.ipc")

-- Load and configure FocusMode Spoon
hs.loadSpoon("FocusMode")

spoon.FocusMode:init()
spoon.FocusMode:bindHotkeys({
    focusMode = {{}, "f13"},
    saveApp = {{"cmd", "shift"}, "f13"},
    restoreApp = {{"cmd"}, "f13"}
})
spoon.FocusMode:start()

-- Load and configure QuickWindowSwitcher Spoon
hs.loadSpoon("QuickWindowSwitcher")

spoon.QuickWindowSwitcher:init()
spoon.QuickWindowSwitcher:bindHotkeys({
    show = {{"cmd", "alt"}, "down"}
})
spoon.QuickWindowSwitcher:start()

-- Load and configure ChromeProfileSwitcher Spoon
hs.loadSpoon("ChromeProfileSwitcher")

spoon.ChromeProfileSwitcher:init()
spoon.ChromeProfileSwitcher:addProfile("Michael (Kiliman)", "Default", {{"cmd"}, "pad1"})
spoon.ChromeProfileSwitcher:addProfile("Michael (beehiiv.com)", "Profile 1", {{"cmd"}, "pad2"})
spoon.ChromeProfileSwitcher:addProfile("Claudia", "Profile 7", {{"cmd"}, "pad3"})
spoon.ChromeProfileSwitcher:addProfile("Michael (Michael 3VOtech)", "Profile 8", {{"cmd"}, "pad4"})

-- Load and configure ChromeTabSwitcher Spoon
hs.loadSpoon("ChromeTabSwitcher")

spoon.ChromeTabSwitcher:init()
spoon.ChromeTabSwitcher:bindHotkeys({
    show = {{"cmd", "ctrl"}, "t"}
})
spoon.ChromeTabSwitcher:start()

-- -- Load and configure ClipboardNumberConverter Spoon
-- hs.loadSpoon("ClipboardNumberConverter")

-- spoon.ClipboardNumberConverter:init()
-- spoon.ClipboardNumberConverter:bindHotkeys({
--     toggle = {{"cmd", "alt"}, "n"}
-- })
-- spoon.ClipboardNumberConverter:start()

hs.loadSpoon("FlashOnFocus")

spoon.FlashOnFocus.duration = 2.0 -- your preferred seconds
spoon.FlashOnFocus.overlayAlpha = 0.7 -- tweak dim strength
spoon.FlashOnFocus:init()

local QuickSpaceSwitcher = hs.loadSpoon("QuickSpaceSwitcher")
QuickSpaceSwitcher:init()
QuickSpaceSwitcher:bindHotkeys({
    show = {{"ctrl"}, "pad0"},
    direct = {
        ["1"] = {{"ctrl"}, "pad1"},
        ["2"] = {{"ctrl"}, "pad2"},
        ["3"] = {{"ctrl"}, "pad3"},
        ["4"] = {{"ctrl"}, "pad4"}
    }
})

hs.alert.show("Hammerspoon config loaded!")
