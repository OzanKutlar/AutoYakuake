;===================== Licence GPLv3 ======================
;AutoYakuake - drop-down Windows Terminal for Windows
;Copyright (C) 2015 Fotios Zantalis (original ZQuake script)
;Copyright (C) 2024-2026 AutoYakuake contributors (rewrite)
;
;This program is free software: you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation, either version 3 of the License, or
;(at your option) any later version.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program.  If not, see <https://www.gnu.org/licenses/>.
;==========================================================

#NoEnv
CoordMode, Mouse, Screen
#SingleInstance Force
SetBatchLines, -1
SetWinDelay, 0

; Uncomment to hide the tray icon. Without it, the script can only be
; stopped from Task Manager, which skips restoring the hidden terminal.
; #NoTrayIcon

;===================== Configuration ======================
global SESSION_NAME     := "yakuake-dropdown"
global PROP_NAME        := "IsYakuakeDropdown"
global TERM_WINTITLE    := "ahk_class CASCADIA_HOSTING_WINDOW_CLASS ahk_exe WindowsTerminal.exe"
global SPAWN_TIMEOUT_MS := 4000
global ANIM_STEPS       := 8
global FRAME_DELAY_MS   := 6
global RAPID_TAP_MS     := 250    ; window to detect a follow-up tap (also the close delay)
global LONG_PRESS_MS    := 500    ; hold duration for full height
global HEIGHT_LEVELS    := [0.5, 0.75, 1.0]

;===================== Runtime State ======================
global g_TermHwnd       := 0
global g_HeightLevel    := 0      ; level currently on screen (0 = hidden)
global g_TargetLevel    := 0      ; level requested by taps / holds
global g_IsAnimating    := false
global g_IsClosing      := false
global g_KeyIsDown      := false  ; auto-repeat guard
global g_ActiveKey      := ""
global g_HoldFired      := false
global g_PressConsumed  := false  ; press already acted on (open / grow / hold)
global g_PressWasOnOpen := false  ; press started on an already-open window
global g_CloseArmed     := false  ; deferred close waiting for a possible 2nd tap
global g_ChainTick      := 0      ; release time of the last open/grow tap
;==========================================================

OnExit("CleanupOnExit")

; Pre-spawn the dedicated dropdown terminal (hidden) at startup
DetectHiddenWindows, On
if (!EnsureTerminal())
    MsgBox, 16, Error, Failed to launch or locate dedicated dropdown terminal at startup.
return ; end of auto-execute section

;===================== Hotkeys ======================
; To add a trigger key, add its down hotkey to the first block and a
; matching wildcard "up" hotkey to the second block.
; Examples (uncomment both lines of a pair to enable):
;   F1      - overrides Help in every application
;   Ctrl+"  - only for layouts where " is its own key (e.g. Turkish Q)
F12::
; F1::
; ^"::
    OnKeyDown()
return

; Wildcard key-up hotkeys: fire even if modifiers were released first
~*F12 up::
; ~*F1 up::
; ~*" up::
    OnKeyUp()
return

;===================== Key Event Handlers ======================
OnKeyDown()
{
    key := HotkeyBaseKey(A_ThisHotkey)
    if (IsAutoRepeat())
        return

    BeginPress(key)

    if (g_CloseArmed)
    {
        ; Second tap within the confirm window -> grow instead of closing
        CancelDeferredClose()
        g_PressConsumed := true
        RequestGrow()
        return
    }

    if (g_IsClosing)
    {
        ; Tap during slide-up -> reopen at the first level
        g_PressConsumed := true
        RequestLevel(1)
        return
    }

    if (IsChainActive())
    {
        ; Quick follow-up to an open/grow tap -> grow again
        g_PressConsumed := true
        RequestGrow()
        return
    }

    HandleFreshPress()
}

OnKeyUp()
{
    key := HotkeyBaseKey(A_ThisHotkey)
    if (!g_KeyIsDown || key != g_ActiveKey)
        return

    g_KeyIsDown := false
    SetTimer, HoldTimer, Off

    if (g_HoldFired)
        return
    if (g_PressConsumed)
    {
        g_ChainTick := A_TickCount
        return
    }
    if (g_PressWasOnOpen)
        ArmDeferredClose()
}

HandleFreshPress()
{
    hwnd := EnsureTerminal()
    if (!hwnd)
    {
        g_PressConsumed := true
        ShowTerminalError()
        return
    }

    state := GetWindowState(hwnd)
    if (state.isOpenHere)
    {
        ; Decide on release: tap -> deferred close, hold -> full height
        if (g_HeightLevel == 0)
        {
            ; Visible but untracked (e.g. after a reload) -> adopt it
            g_HeightLevel := 1
            g_TargetLevel := 1
        }
        g_PressWasOnOpen := true
        return
    }

    ; Hidden or on another monitor -> open immediately on key-down
    g_PressConsumed := true
    if (!g_IsAnimating)
        g_HeightLevel := 0
    RequestLevel(1)
}

;===================== Press Helpers ======================
HotkeyBaseKey(hotkeyName)
{
    return RegExReplace(hotkeyName, "i)^[~*$!^+#<>]+|\s+up$")
}

IsAutoRepeat()
{
    if (!g_KeyIsDown)
        return false
    if (GetKeyState(g_ActiveKey, "P"))
        return true
    ; Key-up was missed -> recover instead of ignoring presses forever
    g_KeyIsDown := false
    return false
}

BeginPress(key)
{
    g_KeyIsDown      := true
    g_ActiveKey      := key
    g_HoldFired      := false
    g_PressConsumed  := false
    g_PressWasOnOpen := false
    SetTimer, HoldTimer, % -LONG_PRESS_MS
}

IsChainActive()
{
    if (g_TargetLevel < 1)
        return false
    return (A_TickCount - g_ChainTick) <= RAPID_TAP_MS
}

;===================== Timers ======================
HoldTimer()
{
    if (!g_KeyIsDown)
        return
    g_HoldFired := true
    g_PressConsumed := true
    CancelDeferredClose()
    RequestLevel(HEIGHT_LEVELS.Length())
}

ArmDeferredClose()
{
    g_CloseArmed := true
    SetTimer, DeferredCloseTimer, % -RAPID_TAP_MS
}

CancelDeferredClose()
{
    g_CloseArmed := false
    SetTimer, DeferredCloseTimer, Off
}

DeferredCloseTimer()
{
    if (!g_CloseArmed)
        return
    g_CloseArmed := false
    RequestLevel(0)
}

;===================== Level Requests ======================
RequestLevel(level)
{
    maxLevel := HEIGHT_LEVELS.Length()
    if (level < 0)
        level := 0
    if (level > maxLevel)
        level := maxLevel
    g_TargetLevel := level
    SetTimer, AnimatorTick, -1
}

RequestGrow()
{
    fromLevel := (g_TargetLevel > 0) ? g_TargetLevel : 1
    RequestLevel(fromLevel + 1)
}

;===================== Animator ======================
AnimatorTick()
{
    if (g_IsAnimating)
        return

    hwnd := EnsureTerminal()
    if (!hwnd)
    {
        ShowTerminalError()
        return
    }

    g_IsAnimating := true
    try
    {
        maxSteps := HEIGHT_LEVELS.Length() + 2
        Loop, %maxSteps%
        {
            if (!AnimateOneStep(hwnd))
                break
        }
    }
    catch e
    {
        g_TargetLevel := g_HeightLevel
        MsgBox, 16, Error, % "Dropdown animation failed:`n" . e.Message
    }
    finally
    {
        g_IsAnimating := false
    }

    ; Requests may still be pending if the bounded loop ran out
    if (g_TargetLevel != g_HeightLevel)
        SetTimer, AnimatorTick, -1
}

AnimateOneStep(hwnd)
{
    target := g_TargetLevel
    if (target == g_HeightLevel)
        return false

    if (target == 0)
        SlideOut(hwnd)
    else if (g_HeightLevel == 0)
        SlideInAtLevel(hwnd, target)
    else
        ResizeToLevel(hwnd, target)

    g_HeightLevel := target
    return true
}

;===================== Window Operations ======================
GetWindowState(hwnd)
{
    display := checkDisplay(hwnd, 1)

    DetectHiddenWindows, Off
    isVisible := WinExist("ahk_id " . hwnd) ? true : false
    DetectHiddenWindows, On

    onMon := (display.oldPos.x >= display.workAreaLeft && display.oldPos.x < display.workAreaRight)
    return {isVisible: isVisible, isOpenHere: (isVisible && onMon)}
}

SlideInAtLevel(hwnd, level)
{
    d := checkDisplay(hwnd, level)
    WinHide, ahk_id %hwnd%
    WinMove, ahk_id %hwnd%,, d.x, d.y - d.height, d.width, d.height
    WinSet, AlwaysOnTop, On, ahk_id %hwnd%
    WinShow, ahk_id %hwnd%
    WinActivate, ahk_id %hwnd%
    MOVEDOWN(hwnd, d.x, d.y, d.width, d.height)
}

SlideOut(hwnd)
{
    WinGetPos, winX, winY, winW, winH, ahk_id %hwnd%
    if (winH != "" && winH > 0)
    {
        g_IsClosing := true
        try
        {
            MOVEUP(hwnd, winX, winY, winW, winH)
        }
        finally
        {
            g_IsClosing := false
        }
    }
    WinHide, ahk_id %hwnd%
    WinActivate, ahk_class Shell_TrayWnd
}

ResizeToLevel(hwnd, level)
{
    d := checkDisplay(hwnd, level)
    WinGetPos, , , , curH, ahk_id %hwnd%
    if (curH = "" || curH <= 0)
        curH := d.height
    GROW_ANIM(hwnd, d.x, d.y, d.width, curH, d.height)
    WinActivate, ahk_id %hwnd%
}

ShowTerminalError()
{
    MsgBox, 16, Error, Failed to launch or locate dedicated dropdown terminal.
}

;===================== Terminal Management ======================
EnsureTerminal()
{
    DetectHiddenWindows, On

    ; Check if tracked HWND is still alive
    if (g_TermHwnd && DllCall("IsWindow", "Ptr", g_TermHwnd))
        return g_TermHwnd

    ; Search for existing tagged dropdown terminal
    existingHwnd := FindDropdownHwnd()
    if (existingHwnd)
    {
        g_TermHwnd := existingHwnd
        return g_TermHwnd
    }

    ; Spawn a dedicated terminal instance
    g_TermHwnd := SpawnDedicatedTerminal()
    return g_TermHwnd
}

FindDropdownHwnd()
{
    ; Only real terminal windows - never WT's hidden helper windows
    WinGet, idList, List, %TERM_WINTITLE%
    Loop, %idList%
    {
        thisHwnd := idList%A_Index%
        isTagged := DllCall("GetProp", "Ptr", thisHwnd, "Str", PROP_NAME, "Ptr")
        if (isTagged == 1)
            return thisHwnd
    }
    return 0
}

TagDropdownHwnd(hwnd)
{
    if (hwnd && DllCall("IsWindow", "Ptr", hwnd))
    {
        DllCall("SetProp", "Ptr", hwnd, "Str", PROP_NAME, "Ptr", 1)
    }
}

SnapshotTerminalIds()
{
    snap := {}
    WinGet, idList, List, %TERM_WINTITLE%
    Loop, %idList%
    {
        thisHwnd := idList%A_Index%
        snap[thisHwnd] := 1
    }
    return snap
}

SpawnDedicatedTerminal()
{
    snapBefore := SnapshotTerminalIds()

    if (!LaunchTerminalProcess())
        return 0

    newHwnd := WaitForNewTerminal(snapBefore)
    if (!newHwnd)
        return 0

    PrepareDropdownWindow(newHwnd)
    return newHwnd
}

LaunchTerminalProcess()
{
    ; Launch isolated named session
    launchCmd := "wt.exe -w " . SESSION_NAME
    try {
        Run, %launchCmd%
    } catch e {
        MsgBox, 16, Error, % "Failed to run: " . launchCmd . "`n`n" . e.Message . " " . e.Extra
        return false
    }
    return true
}

; Bounded poll: returns a NEW real terminal window only once WT has shown it (fully initialized)
WaitForNewTerminal(snapBefore)
{
    maxAttempts := SPAWN_TIMEOUT_MS // 100
    Loop, %maxAttempts%
    {
        Sleep, 100
        WinGet, idList, List, %TERM_WINTITLE%
        Loop, %idList%
        {
            thisHwnd := idList%A_Index%
            if (snapBefore.HasKey(thisHwnd))
                continue
            WinGet, style, Style, ahk_id %thisHwnd%
            if (style & 0x10000000) ; WS_VISIBLE
                return thisHwnd
        }
    }
    return 0
}

PrepareDropdownWindow(hwnd)
{
    TagDropdownHwnd(hwnd)
    ; Un-maximize in case WT launchMode is maximized/fullscreen, otherwise WinMove sizing is ignored
    WinRestore, ahk_id %hwnd%
    WinSet, AlwaysOnTop, On, ahk_id %hwnd%
    ; WT may re-show its window once more while finishing init -> re-hide over ~300ms (bounded)
    Loop, 5
    {
        WinHide, ahk_id %hwnd%
        Sleep, 60
    }
}

;===================== Display & Geometry ======================
checkDisplay(hwnd, level := 1)
{
    if (level < 1)
        level := 1
    if (level > HEIGHT_LEVELS.Length())
        level := HEIGHT_LEVELS.Length()

    MouseGetPos, MouseX, MouseY
    SysGet, MonitorCount, MonitorCount

    MonitorNum := 1
    Loop, %MonitorCount%
    {
        SysGet, Mon, Monitor, %A_Index%
        if (MouseX >= MonLeft && MouseX <= MonRight && MouseY >= MonTop && MouseY <= MonBottom)
        {
            MonitorNum := A_Index
            break
        }
    }

    SysGet, WorkArea, MonitorWorkArea, %MonitorNum%

    workAreaH := WorkAreaBottom - WorkAreaTop
    targetRatio := HEIGHT_LEVELS[level]

    targetWidth  := WorkAreaRight - WorkAreaLeft
    targetHeight := Round(workAreaH * targetRatio)
    targetX      := WorkAreaLeft
    targetY      := WorkAreaTop

    WinGetPos, WinX, WinY, WinW, WinH, ahk_id %hwnd%

    res := {}
    res.monitorNum     := MonitorNum
    res.workAreaLeft   := WorkAreaLeft
    res.workAreaRight  := WorkAreaRight
    res.workAreaTop    := WorkAreaTop
    res.workAreaBottom := WorkAreaBottom
    res.workAreaHeight := workAreaH
    res.x              := targetX
    res.y              := targetY
    res.width          := targetWidth
    res.height         := targetHeight
    res.oldPos         := {x: WinX, y: WinY, w: WinW, h: WinH}
    return res
}

;===================== Animations ======================
MOVEDOWN(hwnd, x, targetY, width, height)
{
    startY := targetY - height
    stepSize := height / ANIM_STEPS
    Loop, %ANIM_STEPS%
    {
        curY := Round(startY + (A_Index * stepSize))
        WinMove, ahk_id %hwnd%,, x, curY, width, height
        FrameDelay()
    }
    WinMove, ahk_id %hwnd%,, x, targetY, width, height
}

MOVEUP(hwnd, x, currentY, width, height)
{
    stepSize := height / ANIM_STEPS
    Loop, %ANIM_STEPS%
    {
        curY := Round(currentY - (A_Index * stepSize))
        WinMove, ahk_id %hwnd%,, x, curY, width, height
        FrameDelay()
    }
    WinMove, ahk_id %hwnd%,, x, currentY - height, width, height
}

GROW_ANIM(hwnd, x, y, width, fromHeight, toHeight)
{
    stepSize := (toHeight - fromHeight) / ANIM_STEPS
    Loop, %ANIM_STEPS%
    {
        curH := Round(fromHeight + (A_Index * stepSize))
        WinMove, ahk_id %hwnd%,, x, y, width, curH
        FrameDelay()
    }
    WinMove, ahk_id %hwnd%,, x, y, width, toHeight
}

FrameDelay()
{
    if (FRAME_DELAY_MS > 0)
        DllCall("Sleep", "UInt", FRAME_DELAY_MS)
}

;===================== Cleanup ======================
CleanupOnExit(ExitReason, ExitCode)
{
    DetectHiddenWindows, On
    if (g_TermHwnd && DllCall("IsWindow", "Ptr", g_TermHwnd))
    {
        WinShow, ahk_id %g_TermHwnd%
        WinSet, AlwaysOnTop, Off, ahk_id %g_TermHwnd%
    }
}
