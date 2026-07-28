# ClipboardNumberConverter Spoon

Watches the clipboard and automatically converts consecutive number words into digits.

## Problem It Solves

Speech-to-text tools often transcribe digit sequences as words ("one two three four") instead of numbers ("1234"). This Spoon watches the clipboard and automatically converts sequences of 2+ consecutive number words into their digit equivalents, while leaving single number words alone.

## Features

- **Automatic conversion** - Watches clipboard in real-time via `hs.pasteboard.watcher`
- **Smart detection** - Only converts sequences of 2+ number words (configurable)
- **Preserves single words** - "I have one thing" stays unchanged
- **Toggle on/off** - Hotkey to disable when not needed
- **Safe homophones** - Only matches unambiguous number words (won't convert "to" or "for")

## Configuration

### Basic Setup

```lua
hs.loadSpoon("ClipboardNumberConverter")

spoon.ClipboardNumberConverter:init()
spoon.ClipboardNumberConverter:start()
```

### With Toggle Hotkey

```lua
hs.loadSpoon("ClipboardNumberConverter")

spoon.ClipboardNumberConverter:init()
spoon.ClipboardNumberConverter:bindHotkeys({
    toggle = {{"cmd", "alt"}, "n"}
})
spoon.ClipboardNumberConverter:start()
```

### Custom Minimum Sequence Length

```lua
-- Only convert sequences of 3+ number words (default is 2)
spoon.ClipboardNumberConverter.minSequenceLength = 3
```

## Conversion Examples

| Input | Output | Why |
|-------|--------|-----|
| `the code is one two three four` | `the code is 1234` | 4 consecutive number words |
| `dial five five five one two three four` | `dial 5551234` | 7 consecutive number words |
| `I have one thing to do` | unchanged | single number word |
| `room three oh four` | `room 304` | 3 consecutive number words |
| `zero eight zero zero` | `0800` | 4 consecutive number words |
| `one two buckle my shoe three four` | `12 buckle my shoe 34` | two separate sequences |

## Supported Number Words

`zero`, `oh`, `one`, `two`, `three`, `four`, `five`, `six`, `seven`, `eight`, `nine`

**Note:** Homophones like "to", "too", "for" are intentionally excluded to avoid false positives.

## API

### Methods

#### `init()`
Initializes the Spoon. Call before `start()`.

#### `start()`
Starts the clipboard watcher. Conversions happen automatically.

#### `stop()`
Stops the clipboard watcher.

#### `toggle()`
Toggles conversion on/off. Shows an alert with current state.

#### `bindHotkeys(mapping)`
Binds hotkeys. Supported keys:
- `toggle` - Toggle conversion on/off

### Variables

#### `enabled` (boolean, default `true`)
Whether conversion is currently active.

#### `minSequenceLength` (number, default `2`)
Minimum consecutive number words needed to trigger conversion.

## Troubleshooting

**Not converting?**
- Check that the Spoon is started (`spoon.ClipboardNumberConverter:start()`)
- Make sure `enabled` is `true`
- Open Hammerspoon Console - the Spoon logs all conversions

**Converting things it shouldn't?**
- Increase `minSequenceLength` to require longer sequences
- Use `toggle()` or the hotkey to temporarily disable

**Re-triggering loop?**
- The Spoon has built-in protection against re-triggering when it writes back to the clipboard
