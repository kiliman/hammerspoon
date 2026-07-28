-- Michael's Real Container v2 — hijacks TextEdit as the parent window
local container = {}

function container.start()
    -- 1. Launch or grab TextEdit (our innocent victim)
    local app = hs.application.get("TextEdit") or hs.application.launchOrFocus("TextEdit")
    hs.timer.doAfter(0.5, function() -- give it a sec to wake up
        local win = app:mainWindow()
        if not win then
            hs.alert("TextEdit is being difficult — try again?")
            return
        end

        container.parent = win
        container.app = app

        -- Make it huge and transparent-ish (you can still see the faint gray if you want)
        local screen = hs.screen.mainScreen():fullFrame()
        container.parent:setFrame(screen)
        -- container.parent:setLevel(hs.window.levels.floating + 1)

        -- Optional: make it almost invisible but still catch mouse for the divider
        hs.timer.doAfter(0.3, function()
            hs.osascript.applescript([[
        tell application "TextEdit"
          set background color of window 1 to {0, 0, 0, 0} -- fully transparent
          set ignores mouse events of window 1 to false -- we still want divider drags
        end tell
      ]])
        end)

        -- Grab the two windows you actually care about
        local vscode = hs.application.get("Code") or hs.application.get("Visual Studio Code")
        local browser = hs.application.get("Arc") or hs.application.get("Google Chrome") or hs.application.get("Safari")

        if not (vscode and vscode:mainWindow()) or not (browser and browser:mainWindow()) then
            hs.alert("Open VS Code and your agent browser first, hot stuff")
            return
        end

        container.vscodeWin = vscode:mainWindow()
        container.browserWin = browser:mainWindow()
        container.split = 0.6
        container.gap = 12

        container.relayout()

        -- Draggable divider (now works because TextEdit is catching mouse events)
        container.divider = hs.canvas.new {
            x = 0,
            y = 0,
            w = 8,
            h = screen.h
        }
        container.divider:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = {
                white = 1,
                alpha = 0.7
            },
            roundedRectRadii = {
                xRadius = 4,
                yRadius = 4
            }
        })
        container.divider:show()

        local dragging = false
        container.divider:mouseCallback(function(_, msg, _, x)
            if msg == "mouseDown" then
                dragging = true
            end
            if msg == "mouseUp" then
                dragging = false
            end
            if dragging and (msg == "mouseMove" or msg == "mouseDrag") then
                local parentFrame = container.parent:frame()
                local newSplit = (hs.mouse.getAbsolutePosition().x - parentFrame.x) / parentFrame.w
                container.split = math.max(0.2, math.min(0.8, newSplit))
                container.relayout()
            end
        end)

        -- Keep kids glued when TextEdit moves/resizes
        container.filter = hs.window.filter.new({
            TextEdit = {
                visible = true
            }
        })
        container.filter:subscribe(hs.window.filter.windowMoved, function()
            container.relayout()
        end)
        container.filter:subscribe(hs.window.filter.windowResized, function()
            container.relayout()
        end)

        hs.alert("Container active ♥ TextEdit is now your puppet")
    end)
end

function container.relayout()
    if not container.parent then
        return
    end
    local f = container.parent:frame()

    local leftW = math.floor(f.w * container.split) - container.gap / 2
    local rightX = f.x + leftW + container.gap
    local rightW = f.w - leftW - container.gap

    if container.vscodeWin then
        container.vscodeWin:setFrame{
            x = f.x,
            y = f.y,
            w = leftW,
            h = f.h
        }
    end
    if container.browserWin then
        container.browserWin:setFrame{
            x = rightX,
            y = f.y,
            w = rightW,
            h = f.h
        }
    end

    local divX = f.x + leftW + container.gap / 2 - 4
    container.divider:frame{
        x = divX,
        y = f.y,
        w = 8,
        h = f.h
    }
end

function container.stop()
    if container.divider then
        container.divider:delete()
    end
    if container.filter then
        container.filter:unsubscribeAll()
    end
    hs.alert("TextEdit is free! (Go forth and… edit text?)")
end

-- Hotkeys
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "D", container.start)
hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "D", container.stop)

return container
