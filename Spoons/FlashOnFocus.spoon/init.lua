local spoon = {}
spoon.name = "FlashOnFocus"
spoon.version = "2.0"
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
    self.flashGeneration = 0
    self.holdTimer = nil
    self.fadeTimer = nil
    self.drawRetryTimer = nil

    self.watcher = hs.window.filter.new(nil):subscribe(hs.window.filter.windowFocused, function()
        self:flash()
    end):subscribe(hs.window.filter.windowDestroyed, function(w)
        if w == self.currentWindow then
            self:cleanupNow()
        end
    end):subscribe({hs.window.filter.windowMoved, hs.window.filter.windowResized}, function(w)
        -- Only redraw if this is our current flashing window and we're still holding
        if w == self.currentWindow and self.isHolding and self.currentFrame then
            self:drawBorder()
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

    self:drawBorder()
    if not self.currentFrame then
        self.drawRetryTimer = timer.doAfter(0.05, function()
            if generation ~= self.flashGeneration then
                return
            end
            self:drawBorder()
        end)
    end

    -- End hold period: stop tracking moves and start fade
    self.holdTimer = timer.doAfter(self.duration, function()
        if generation ~= self.flashGeneration then
            return
        end
        self.isHolding = false
        self:startFade(generation)
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
    frame.x = frame.x - 10
    frame.y = frame.y - 10
    frame.w = frame.w + 20
    frame.h = frame.h + 20

    self.currentFrame = drawing.rectangle(frame):setStrokeWidth(self.frameWidth):setStrokeColor(self.frameColor)
        :setFill(false):setLevel(hs.drawing.windowLevels.popUpMenu):show()
end

function spoon:startFade(generation)
    if not self.currentFrame then
        return
    end

    local currentAlpha = self.frameColor.alpha
    local steps = 25
    local stepTime = self.fadeOutSeconds / steps
    local stepAlpha = currentAlpha / steps

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

        currentAlpha = currentAlpha - stepAlpha
        if currentAlpha <= 0 then
            self:cleanupNow()
            return
        end

        self.currentFrame:setStrokeColor({
            red = 0,
            green = 1,
            blue = 0,
            alpha = currentAlpha
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

    if self.currentFrame then
        self.currentFrame:delete()
        self.currentFrame = nil
    end
    self.currentWindow = nil
    self.isHolding = false
end

function spoon:stop()
    self:cleanupNow()
    if self.watcher then
        self.watcher:stop()
    end
end

return spoon
