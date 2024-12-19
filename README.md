# AutoYakuake

AutoYakuake is a Drop-down console window with Windows Terminal integration for Windows.  
> Yakuake-like convenience for the times you are using Windows.

AutoYakuake is a fork of ZQuake, updated to use the modern **Windows Terminal** instead of OpenSSH and Console2.

---

### Key Features
- **Windows Terminal Integration**: Replaces Console2 with the versatile Windows Terminal.
- **AutoHotkey**: A scripting language for desktop automation, enabling the drop-down functionality.
- **Simplified Setup**: Automatically centers and configures Windows Terminal on launch.

---

## How To Use

1. **Install AutoHotkey** (v1).  
   Download it from the [AutoHotkey website](https://www.autohotkey.com/).
2. **Run the Script Directly** or **Compile the `AutoYakuake_source.ahk` script**:  
   - **Option 1: Run directly**: You can run the `.ahk` script without compiling it by double-clicking the file. Ensure AutoHotkey is installed.
   - **Option 2: Compile**: Use the "Convert .ahk to .exe" utility provided by AutoHotkey to create an executable.
3. **Install Windows Terminal**.  
   Download it from the [Microsoft Store](https://aka.ms/terminal) or the [Windows Terminal GitHub page](https://github.com/microsoft/terminal).
4. Copy the `.ahk` script or the compiled `AutoYakuake.exe` to a preferred location.
5. Place a shortcut to `AutoYakuake.exe` (or the `.ahk` script) in your startup folder to launch on boot.  

---

## Example Directory Setup
```
-rwxr-xr-x 1 AutoYakuake.ahk  
-rw-r--r-- 1 AutoYakuake_source.ahk  
```

---

## Usage - Hot Keys
- **F12**: Trigger AutoYakuake (Drop-down, Move-up).

---

### Notes
- **Run Without Compiling**: The script can be run directly using AutoHotkey without compiling it to an executable.
- **Auto Start**: Place the `AutoYakuake.exe` or `.ahk` shortcut in the Windows startup folder to launch automatically.  

---

## Version
[2.0.0]

---

## License
**GPLv3**  
> Copyright (C) 2016  Zantalis Fotios

--- 