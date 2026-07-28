--- === ClipboardNumberConverter ===
---
--- Intercepts paste (Cmd+V) and converts consecutive number words to digits
--- before the paste lands. Also watches the clipboard for background conversion.
---
--- Single number words are left alone; sequences of 2+ are concatenated.
---
--- Example: "the code is one two three four" → "the code is 1234"
---          "I have one thing" → unchanged (single number word)
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ClipboardNumberConverter"
obj.version = "2.0"
obj.author = "Michael & Claudia 💙"
obj.license = "MIT"

obj.logger = hs.logger.new('ClipNumConv')
obj.logger.setLogLevel('info')

--- ClipboardNumberConverter.enabled
--- Variable
--- Whether conversion is active (default true)
obj.enabled = true

--- ClipboardNumberConverter.minSequenceLength
--- Variable
--- Minimum consecutive number words to trigger conversion (default 2)
obj.minSequenceLength = 2

-- Only the unambiguous number words
local safeNumberWords = {
    zero = "0", oh = "0",
    one = "1",
    two = "2",
    three = "3",
    four = "4",
    five = "5",
    six = "6",
    seven = "7",
    eight = "8",
    nine = "9",
}

--- convertNumberWords(text)
--- Function
--- Finds sequences of 2+ consecutive number words and replaces them with digits.
---
--- Parameters:
---  * text - The string to process
---
--- Returns:
---  * The converted string, and a boolean indicating if any changes were made
local function convertNumberWords(text)
    if not text or #text == 0 then
        return text, false
    end

    local changed = false
    local result = {}
    local i = 1
    local len = #text

    while i <= len do
        -- Skip non-word characters, preserving them
        if not text:sub(i, i):match("[%a]") then
            table.insert(result, text:sub(i, i))
            i = i + 1
        else
            -- Extract a word
            local wordStart = i
            while i <= len and text:sub(i, i):match("[%a']") do
                i = i + 1
            end
            local word = text:sub(wordStart, i - 1)
            local lowerWord = word:lower()

            -- Check if this is a number word
            if safeNumberWords[lowerWord] then
                -- Look ahead for more consecutive number words
                local sequence = { { word = word, digit = safeNumberWords[lowerWord] } }
                local lookahead = i

                while lookahead <= len do
                    -- Skip whitespace between words
                    local spaceStart = lookahead
                    while lookahead <= len and text:sub(lookahead, lookahead):match("[ \t]") do
                        lookahead = lookahead + 1
                    end

                    -- Must have had some whitespace and next char must be a letter
                    if lookahead == spaceStart or lookahead > len or not text:sub(lookahead, lookahead):match("[%a]") then
                        break
                    end

                    -- Extract next word
                    local nextWordStart = lookahead
                    while lookahead <= len and text:sub(lookahead, lookahead):match("[%a']") do
                        lookahead = lookahead + 1
                    end
                    local nextWord = text:sub(nextWordStart, lookahead - 1)
                    local nextLower = nextWord:lower()

                    if safeNumberWords[nextLower] then
                        table.insert(sequence, { word = nextWord, digit = safeNumberWords[nextLower] })
                    else
                        break
                    end
                end

                if #sequence >= obj.minSequenceLength then
                    -- Convert the sequence to digits
                    local digits = {}
                    for _, entry in ipairs(sequence) do
                        table.insert(digits, entry.digit)
                    end
                    table.insert(result, table.concat(digits))
                    -- Advance past the full sequence
                    local skip = i
                    for idx = 2, #sequence do
                        -- Skip whitespace
                        while skip <= len and text:sub(skip, skip):match("[ \t]") do
                            skip = skip + 1
                        end
                        -- Skip word
                        while skip <= len and text:sub(skip, skip):match("[%a']") do
                            skip = skip + 1
                        end
                    end
                    i = skip
                    changed = true
                else
                    -- Single number word, keep as-is
                    table.insert(result, word)
                end
            else
                -- Not a number word, keep as-is
                table.insert(result, word)
            end
        end
    end

    return table.concat(result), changed
end

-- Expose for testing
obj._convertNumberWords = convertNumberWords

--- ClipboardNumberConverter:init()
--- Method
--- Initializes the Spoon
function obj:init()
    self.pasteTap = nil
    self.pasteWatcher = nil
    return self
end

--- ClipboardNumberConverter:start()
--- Method
--- Starts intercepting paste events to convert clipboard before paste lands.
--- Also keeps a clipboard watcher for background conversion (e.g., clipboard managers).
function obj:start()
    -- PRIMARY: Eventtap intercepts Cmd+V BEFORE it reaches the app.
    -- We convert the clipboard contents, then let the keystroke pass through.
    self.pasteTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        if not self.enabled then
            return false -- pass through
        end

        local flags = event:getFlags()
        local keyCode = event:getKeyCode()

        -- Cmd+V = keyCode 9, check for cmd flag (allow shift+cmd+v too)
        if flags.cmd and not flags.ctrl and not flags.alt and keyCode == 9 then
            local contents = hs.pasteboard.getContents()
            if contents and type(contents) == "string" then
                local converted, didChange = convertNumberWords(contents)
                if didChange then
                    self.logger.i("Paste intercept: converted clipboard before paste")
                    self.logger.i("  From: '" .. contents .. "'")
                    self.logger.i("  To:   '" .. converted .. "'")
                    hs.pasteboard.setContents(converted)
                end
            end
        end

        return false -- always let the keystroke pass through
    end)
    self.pasteTap:start()

    -- SECONDARY: Clipboard watcher for background conversion.
    -- Handles cases where text is copied but not immediately pasted.
    local _isWriting = false
    self.pasteWatcher = hs.pasteboard.watcher.new(function(contents)
        if _isWriting or not self.enabled then
            return
        end

        if not contents or type(contents) ~= "string" then
            return
        end

        local converted, didChange = convertNumberWords(contents)
        if didChange then
            self.logger.i("Watcher: converted clipboard in background")
            _isWriting = true
            hs.pasteboard.setContents(converted)
            hs.timer.doAfter(0.1, function()
                _isWriting = false
            end)
        end
    end)

    self.logger.i("ClipboardNumberConverter started (eventtap + watcher)")
    return self
end

--- ClipboardNumberConverter:stop()
--- Method
--- Stops all watchers and interceptors
function obj:stop()
    if self.pasteTap then
        self.pasteTap:stop()
        self.pasteTap = nil
    end
    if self.pasteWatcher then
        self.pasteWatcher:stop()
        self.pasteWatcher = nil
    end
    self.logger.i("ClipboardNumberConverter stopped")
    return self
end

--- ClipboardNumberConverter:toggle()
--- Method
--- Toggles conversion on/off
function obj:toggle()
    self.enabled = not self.enabled
    local state = self.enabled and "enabled" or "disabled"
    hs.alert.show("Number conversion " .. state)
    self.logger.i("ClipboardNumberConverter " .. state)
    return self
end

--- ClipboardNumberConverter:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for the Spoon
---
--- Parameters:
---  * mapping - A table with the following keys:
---    * toggle - Toggle conversion on/off
function obj:bindHotkeys(mapping)
    if mapping.toggle then
        hs.hotkey.bind(mapping.toggle[1], mapping.toggle[2], function()
            self:toggle()
        end)
    end
    return self
end

return obj
