# Hammerspoon Multi-Monitor Window Management

> Effortlessly manage windows across multiple monitors with keyboard shortcuts

If you're working with multiple monitors, you know the pain of constantly dragging windows around. This [Hammerspoon](https://www.hammerspoon.org/) configuration makes it easy to move and organize windows with just a few keystrokes.

## What Does It Do?

### Focus Mode - Your New Best Friend

Press **F13** and instantly move any window to your main monitor, perfectly centered. Press **F13** again on the center screen to send it back where it came from. No dragging, no resizing, no fuss.

> **Key insight:** F13 always acts on the current window. If it's on your center screen, it restores to its last position (or saved slot if you have one). If it's anywhere else, it moves to center.

Perfect for:

- 🎯 Bringing a Slack message to your main screen when you need to focus on it
- 📧 Quickly checking email on your primary monitor
- 🎵 Moving Spotify to the center when you want to browse playlists
- 📝 Pulling reference docs to your main screen while coding

### Window Slots - Remember Your Favorites

Have apps you always want in the same spot? Save up to 10 window positions and recall them instantly.

**Example:** Save your terminal window to slot 1. Now whenever you need it, just press **Cmd+F13** → **1** and it jumps to your center screen. When you're done, press **F13** (not Cmd+F13!) to send it back to its saved position.

## Getting Started

### Installation

1. [Download Hammerspoon](https://www.hammerspoon.org/) (it's free!)
2. Clone or download this configuration:
   ```bash
   git clone https://github.com/kiliman/hammerspoon-config.git ~/.hammerspoon
   ```
3. Open Hammerspoon and reload the config
4. You're done! 🎉

### Quick Start Guide

**Try it out:**

1. Click on any window
2. Press **F13**
3. Watch it jump to your center screen!
4. Press **F13** again to send it back

**Save a favorite position:**

1. Position a window exactly where you want it
2. Press **Cmd+Alt+F13** then **1** (or any number 0-9)
3. Now you can recall it anytime with **Cmd+F13** → **1**

## Keyboard Shortcuts

| Shortcut                  | What It Does                                |
| ------------------------- | ------------------------------------------- |
| **F13**                   | Toggle current window to/from center screen |
| **Cmd+Alt+F13** → **0-9** | Save current window position to a slot      |
| **Cmd+F13** → **0-9**     | Recall saved window to center screen        |
| **Escape**                | Cancel if you're in save/recall mode        |

> [!NOTE]
> **Note:** Once any window is on the center screen (whether moved with F13 or recalled with Cmd+F13), pressing **F13** will restore it to its last position or saved slot.

> **Don't have an F13 key?** You can change the shortcuts - see the [configuration guide](CLAUDE.md).

## Why Hammerspoon?

[Hammerspoon](https://www.hammerspoon.org/) is a powerful macOS automation tool that lets you control your Mac with Lua scripts. Think of it as a Swiss Army knife for keyboard shortcuts and window management.

This configuration is built as a "Spoon" (Hammerspoon's term for a plugin), making it easy to share and customize.

## Need Help?

- **Technical docs:** Check out [CLAUDE.md](CLAUDE.md) for the full technical reference
- **Customization:** See the [FocusMode documentation](Spoons/FocusMode.spoon/CLAUDE.md) for all the options
- **Issues:** [Open an issue](../../issues) if something's not working right

## License

MIT License - use it, share it, modify it!

## Credits

Created by Michael Carter ([@kiliman](https://github.com/kiliman))

Built with 💕 and a lot of help from [Claude Code](https://claude.com/claude-code)
