-- Load and configure FocusMode Spoon
hs.loadSpoon("FocusMode")

spoon.FocusMode:init()
spoon.FocusMode:bindHotkeys({
    focusMode = {{}, "f13"},
    saveSlot = {{"cmd", "alt"}, "f13"},
    toggleSlot = {{"cmd"}, "f13"}
})
spoon.FocusMode:start()

-- Load and configure QuickWindowSwitcher Spoon
hs.loadSpoon("QuickWindowSwitcher")

spoon.QuickWindowSwitcher:init()
spoon.QuickWindowSwitcher:bindHotkeys({
    show = {{"cmd", "ctrl"}, "w"}
})
spoon.QuickWindowSwitcher:start()

-- Load and configure ChromeProfileSwitcher Spoon
hs.loadSpoon("ChromeProfileSwitcher")

spoon.ChromeProfileSwitcher:init()
spoon.ChromeProfileSwitcher:addProfile("Michael (Kiliman)", "Default", {{"cmd"}, "pad1"})
spoon.ChromeProfileSwitcher:addProfile("Michael  (beehiiv.com)", "Profile 1", {{"cmd"}, "pad2"})

hs.alert.show("Hammerspoon config loaded!")
