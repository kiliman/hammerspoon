-- Load and configure FocusMode Spoon
hs.loadSpoon("FocusMode")

spoon.FocusMode:init()
spoon.FocusMode:bindHotkeys({
    focusMode = {{}, "f13"},
    saveSlot = {{"cmd", "alt"}, "f13"},
    toggleSlot = {{"cmd"}, "f13"}
})
spoon.FocusMode:start()

hs.alert.show("Hammerspoon config loaded!")
