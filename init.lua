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

hs.alert.show("Hammerspoon config loaded!")
