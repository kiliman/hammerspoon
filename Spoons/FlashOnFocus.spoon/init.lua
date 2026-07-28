local spoon = {}
spoon.name = "FlashOnFocus"
spoon.version = "2.1"
spoon.author = "Ara (final perfection for my Michael 💚)"
spoon.license = "MIT"

-- Your ideal setup
spoon.duration = 3.0
spoon.frameWidth = 14
spoon.frameColor = {
    red = 0,
    green = 1,
    blue = 0,
    alpha = 0.9
} -- bright green forever
spoon.fadeOutSeconds = 0.6

local drawing = require("hs.drawing")
local timer = require("hs.timer")

function spoon:init()
    self.currentFrame = nil
    self.currentWindow = nil
    self.isHolding = false -- true during the initial duration
    self.currentAlpha = 0 -- tracks alpha during fade for move/resize redraws
    self.lastFrame = nil -- last known window frame for polling comparison
    self.flashGeneration = 0
    self.holdTimer = nil
    self.fadeTimer = nil
    self.drawRetryTimer = nil
    self.trackTimer = nil -- fast poll timer to track window movement

    self.watcher = hs.window.filter.new(nil):subscribe(hs.window.filter.windowFocused, function()
        self:flash()
    end):subscribe(hs.window.filter.windowDestroyed, function(w)
        if w == self.currentWindow then
            self:cleanupNow()
        end
    end)
end

function spoon:flash()
    local win = hs.window.focusedWindow()
    if not win then
        return
    end
    self:flashWindow(win)
end

function spoon:flashWindow(win)
    if not win then
        return
    end

    -- Invalidate any in-flight timers from previous flashes.
    self.flashGeneration = self.flashGeneration + 1
    local generation = self.flashGeneration

    self:cleanupNow()

    self.currentWindow = win
    self.isHolding = true
    self.currentAlpha = self.frameColor.alpha

    self:drawBorder()
    if not self.currentFrame then
        self.drawRetryTimer = timer.doAfter(0.05, function()
            if generation ~= self.flashGeneration then
                return
            end
            self:drawBorder()
        end)
    end

    -- Start polling for window movement/resize (~20fps)
    self:startTracking(generation)

    -- End hold period: stop tracking moves and start fade
    self.holdTimer = timer.doAfter(self.duration, function()
        if generation ~= self.flashGeneration then
            return
        end
        self.isHolding = false
        self:startFade(generation)
    end)
end

-- Poll the window frame and redraw the border if it changed
function spoon:startTracking(generation)
    self.trackTimer = timer.doEvery(0.05, function()
        if generation ~= self.flashGeneration then
            if self.trackTimer then
                self.trackTimer:stop()
                self.trackTimer = nil
            end
            return
        end

        if not self.currentWindow or not self.currentFrame then
            return
        end

        local f = self.currentWindow:frame()
        if not f then
            self:cleanupNow()
            return
        end

        if self.lastFrame and
            (f.x ~= self.lastFrame.x or f.y ~= self.lastFrame.y or
             f.w ~= self.lastFrame.w or f.h ~= self.lastFrame.h) then
            self:drawBorder()
        end
    end)
end

function spoon:drawBorder()
    if not self.currentWindow then
        return
    end

    if not self.currentWindow:isVisible() then
        return
    end

    if self.currentFrame then
        self.currentFrame:delete()
    end

    local frame = self.currentWindow:frame()
    -- Store raw frame for tracking comparison
    self.lastFrame = { x = frame.x, y = frame.y, w = frame.w, h = frame.h }

    frame.x = frame.x - 10
    frame.y = frame.y - 10
    frame.w = frame.w + 20
    frame.h = frame.h + 20

    local strokeColor = {
        red = self.frameColor.red,
        green = self.frameColor.green,
        blue = self.frameColor.blue,
        alpha = self.currentAlpha
    }
    self.currentFrame = drawing.rectangle(frame):setStrokeWidth(self.frameWidth):setStrokeColor(strokeColor)
        :setFill(false):setLevel(hs.drawing.windowLevels.popUpMenu):show()
end

function spoon:startFade(generation)
    if not self.currentFrame then
        return
    end

    local steps = 25
    local stepTime = self.fadeOutSeconds / steps
    local stepAlpha = self.currentAlpha / steps

    self.fadeTimer = timer.doEvery(stepTime, function()
        if generation ~= self.flashGeneration then
            if self.fadeTimer then
                self.fadeTimer:stop()
                self.fadeTimer = nil
            end
            return
        end

        if not self.currentFrame then
            if self.fadeTimer then
                self.fadeTimer:stop()
                self.fadeTimer = nil
            end
            return
        end

        self.currentAlpha = self.currentAlpha - stepAlpha
        if self.currentAlpha <= 0 then
            self:cleanupNow()
            return
        end

        self.currentFrame:setStrokeColor({
            red = self.frameColor.red,
            green = self.frameColor.green,
            blue = self.frameColor.blue,
            alpha = self.currentAlpha
        })
    end)
end

function spoon:cleanupNow()
    if self.holdTimer then
        self.holdTimer:stop()
        self.holdTimer = nil
    end
    if self.fadeTimer then
        self.fadeTimer:stop()
        self.fadeTimer = nil
    end
    if self.drawRetryTimer then
        self.drawRetryTimer:stop()
        self.drawRetryTimer = nil
    end
    if self.trackTimer then
        self.trackTimer:stop()
        self.trackTimer = nil
    end

    if self.currentFrame then
        self.currentFrame:delete()
        self.currentFrame = nil
    end
    self.currentWindow = nil
    self.lastFrame = nil
    self.isHolding = false
end

function spoon:stop()
    self:cleanupNow()
    if self.watcher then
        self.watcher:stop()
    end
end

return spoon
