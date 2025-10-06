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

### Quick Window Switcher - Find That Window Fast

Got a bunch of Chrome windows or terminal sessions open? Press **Cmd+Ctrl+W** to see them all in a nice list. Press a number (1-9, 0), use arrow keys, or click to switch instantly.

Perfect for:

- 🌐 Jumping between multiple browser windows
- 💻 Switching terminal sessions
- 📝 Finding the right editor window
- 💬 Locating that Slack workspace you need

**Example:** You have 5 Chrome windows open. Press **Cmd+Ctrl+W**, see them numbered 1-5, press **3** to jump to window 3. Done!

### Chrome Profile Switcher - Stop Fighting With Cmd+~

Using multiple Chrome profiles (work, personal, client accounts)? Chrome's built-in `Cmd+~` cycles through **all** windows across **all** profiles, making it slow and annoying when you have many windows open.

This gives each profile its own hotkey. Press it once to jump to that profile. Press it again to cycle through windows within the same profile only.

Perfect for:

- 🏢 Quickly jumping between work and personal Chrome profiles
- 🔄 Cycling through multiple windows within the same profile
- 🚀 Auto-launching Chrome with the right profile if no windows exist
- 🎯 Direct access instead of hunting through all Chrome windows

**Example:** You have your personal profile with 3 windows and work profile with 5 windows. Press **Cmd+Pad1** to jump to personal profile (window 1). Press **Cmd+Pad1** again to go to personal window 2. Press **Cmd+Pad2** to instantly jump to your work profile instead.

## Getting Started

### Installation

1. [Download Hammerspoon](https://www.hammerspoon.org/) (it's free!)
2. Clone or download this configuration:
   ```bash
   git clone https://github.com/kiliman/hammerspoon.git ~/.hammerspoon
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

### FocusMode

| Shortcut                  | What It Does                                |
| ------------------------- | ------------------------------------------- |
| **F13**                   | Toggle current window to/from center screen |
| **Cmd+Alt+F13** → **0-9** | Save current window position to a slot      |
| **Cmd+F13** → **0-9**     | Recall saved window to center screen        |
| **Escape**                | Cancel if you're in save/recall mode        |

> [!NOTE]
> **Note:** Once any window is on the center screen (whether moved with F13 or recalled with Cmd+F13), pressing **F13** will restore it to its last position or saved slot.

### Quick Window Switcher

| Shortcut          | What It Does                                     |
| ----------------- | ------------------------------------------------ |
| **Cmd+Ctrl+W**    | Show list of windows for current application    |
| **1-9, 0**        | Select window instantly (in the list)            |
| **↑/↓ + Enter**   | Navigate and select window (in the list)         |
| **Click**         | Select window by clicking (in the list)          |
| **Escape**        | Close the window list                            |

### Chrome Profile Switcher

| Shortcut       | What It Does                                       |
| -------------- | -------------------------------------------------- |
| **Cmd+Pad1**   | Switch to/cycle Michael (Kiliman) profile windows |
| **Cmd+Pad2**   | Switch to/cycle Michael (beehiiv.com) profile windows |

> **Don't have an F13 key?** You can change the shortcuts - see the [configuration guide](CLAUDE.md).

## Why Hammerspoon?

[Hammerspoon](https://www.hammerspoon.org/) is a powerful macOS automation tool that lets you control your Mac with Lua scripts. Think of it as a Swiss Army knife for keyboard shortcuts and window management.

This configuration is built as a "Spoon" (Hammerspoon's term for a plugin), making it easy to share and customize.

## Need Help?

- **Technical docs:** Check out [CLAUDE.md](CLAUDE.md) for the full technical reference
- **Customization:**
  - [FocusMode documentation](Spoons/FocusMode.spoon/CLAUDE.md) for window management options
  - [QuickWindowSwitcher documentation](Spoons/QuickWindowSwitcher.spoon/CLAUDE.md) for window switcher options
  - [ChromeProfileSwitcher documentation](Spoons/ChromeProfileSwitcher.spoon/CLAUDE.md) for profile configuration
- **Issues:** [Open an issue](../../issues) if something's not working right

## License

MIT License - use it, share it, modify it!

## Credits

Created by Michael Carter ([@kiliman](https://github.com/kiliman))

Built with 💕 and a lot of help from [Claude Code](https://claude.com/claude-code)
