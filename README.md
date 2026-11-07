# AutoYakuake

A Yakuake/Quake-style drop-down terminal for Windows, built on **Windows Terminal** and **AutoHotkey**.
> Yakuake-like convenience for the times you are using Windows.

AutoYakuake started as a fork of ZQuake, which was built on Console2. The current version is a rewrite around Windows Terminal.

---

## Features

- **Dedicated drop-down window**: runs its own named Windows Terminal window (`wt -w yakuake-dropdown`) and tags it, so your other terminal windows are never touched.
- **Follows your mouse**: opens on the monitor under the cursor. Pressing the hotkey while the terminal is open on another monitor moves it to the current one.
- **Taskbar-aware sizing**: fills the full width of the monitor's work area and never covers the taskbar.
- **Three height levels**: 50%, 75% and 100% of the work area.
- **Smooth animations** for sliding down, sliding up and resizing.
- **Instant first drop**: the terminal is pre-launched hidden when the script starts.
- **Clean exit**: on exit, the terminal is shown again and no longer stays always-on-top.

---

## Requirements

- Windows 10 or 11
- **AutoHotkey v1.1**, not v2. The AutoHotkey site offers v2 by default, so pick v1.1 on the [download page](https://www.autohotkey.com/download/).
- **Windows Terminal**, a reasonably recent version, from the [Microsoft Store](https://aka.ms/terminal) or [GitHub](https://github.com/microsoft/terminal).

---

## Installation

1. Install AutoHotkey v1.1 and Windows Terminal.
2. Download `AutoYakuake_source.ahk`.
3. Start it in one of two ways:
   - **Run directly**: double-click the `.ahk` file.
   - **Compile**: use AutoHotkey's *Convert .ahk to .exe* (Ahk2Exe) to build a standalone executable.
4. **Optional autostart**: press `Win+R`, type `shell:startup`, and put a shortcut to the script or executable in that folder.

---

## Hotkeys

The default trigger key is **F12**.

| Action | Result |
|---|---|
| Tap while hidden | Slides down at 50% height |
| Tap while open | Slides up after 250 ms, in case a second tap follows |
| Double-tap | Grows one level (50% → 75% → 100%) |
| Hold for 0.5 s | Jumps to full height |
| Tap while sliding up | Reopens at 50% |
| Tap while open on another monitor | Moves to the monitor under the cursor |

Quick follow-up taps keep growing the window. For example, a triple-tap from hidden opens straight at 100%.

### Changing the trigger key

Edit the **Hotkeys** section of the script. Each key needs two lines:

- a down hotkey in the first block, for example `F1::`
- a matching wildcard up hotkey in the second block, for example `~*F1 up::`

Commented-out examples for `F1` and `Ctrl+"` are already in the script. `Ctrl+"` only makes sense on keyboard layouts where `"` has its own key.

---

## Configuration

These constants are at the top of the script:

| Setting | Default | Meaning |
|---|---|---|
| `HEIGHT_LEVELS` | `[0.5, 0.75, 1.0]` | Height steps, as fractions of the work area |
| `ANIM_STEPS` | `8` | Frames per animation |
| `FRAME_DELAY_MS` | `6` | Delay between frames |
| `RAPID_TAP_MS` | `250` | Window for detecting a follow-up tap; also the close delay |
| `LONG_PRESS_MS` | `500` | Hold time for full height |
| `SPAWN_TIMEOUT_MS` | `4000` | How long to wait for Windows Terminal to start |

---

## Exiting

Right-click the tray icon and choose **Exit**. This shows the hidden terminal again.

If you uncomment `#NoTrayIcon` in the script, you'll have to stop AutoHotkey from Task Manager. Doing so skips the cleanup step, so the drop-down terminal stays hidden; end its `WindowsTerminal.exe` process too if needed.

---

## Notes

- If Windows Terminal's launch mode is set to maximized or fullscreen, the script restores the drop-down window automatically so it can be sized.
- The drop-down window is always-on-top while it's open.

---

## Version
[3.0.0]

---

## License
**GPLv3 or later**. See [LICENSE](LICENSE).
> Originally based on ZQuake, Copyright (C) 2015 Fotios Zantalis.
