--- AudioPriority: keep the default input on the best microphone that's plugged in.
---
--- macOS makes whatever device was chosen last the default and has no priority
--- list. This Spoon gives it one: when a device connects or disconnects, the
--- default input moves to the first available device in `inputPriority`.
---
--- It reacts only to devices coming and going (the "dev#" event), never to the
--- default changing, so a deliberate manual switch (BlackHole for recording an
--- emulator) sticks until the next plug/unplug or an explicit :apply().
local obj = {}
obj.__index = obj

obj.name = "AudioPriority"
obj.version = "1.0"
obj.author = "Claudia 💙"
obj.license = "MIT"

--- Substrings matched (plain, case-sensitive) against device names, best first.
--- Devices matching none of them (Cam Link 4K) are never chosen automatically.
obj.inputPriority = {
    "Yeti",
    "CalDigit TS4 Audio",
    "MacBook Pro Microphone",
    "BlackHole",
}

--- Seconds to wait after a device change: a dock connecting fires several events
--- and its devices don't all show up at once.
obj.settleSeconds = 1.5

obj.log = hs.logger.new("AudioPriority", "info")

local function rank(self, device)
    local name = device:name() or ""
    for i, pattern in ipairs(self.inputPriority) do
        if name:find(pattern, 1, true) then
            return i
        end
    end
    return nil
end

--- The best available input device, or nil if none matches the list.
function obj:bestInput()
    local best, bestRank = nil, math.huge
    for _, device in ipairs(hs.audiodevice.allInputDevices()) do
        local r = rank(self, device)
        if r and r < bestRank then
            best, bestRank = device, r
        end
    end
    return best
end

--- Move the default input to the best available device. Returns its name.
function obj:apply()
    local best = self:bestInput()
    if not best then
        self.log.w("no input device matches inputPriority")
        return nil
    end
    local current = hs.audiodevice.defaultInputDevice()
    if current and current:uid() == best:uid() then
        return best:name()
    end
    if best:setDefaultInputDevice() then
        self.log.i("default input -> " .. best:name())
        hs.alert.show("🎙 " .. best:name(), 1.5)
    else
        self.log.e("could not set default input to " .. best:name())
    end
    return best:name()
end

function obj:start()
    hs.audiodevice.watcher.setCallback(function(event)
        if event ~= "dev#" then
            return
        end
        if self.timer then
            self.timer:stop()
        end
        self.timer = hs.timer.doAfter(self.settleSeconds, function()
            self:apply()
        end)
    end)
    hs.audiodevice.watcher.start()
    self:apply()
    return self
end

function obj:stop()
    hs.audiodevice.watcher.stop()
    if self.timer then
        self.timer:stop()
    end
    return self
end

return obj
