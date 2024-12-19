;=====================Licence GPLv2======================
;Copyright (C) 2015 Fotios Zantalis
;
;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
;========================================================


CoordMode, Mouse, Screen
#SingleInstance Force
;=====================Set Variables======================
PathToConsole = "wt"
;========================================================

;Speed up drop down animation (default value is 100)
SetWinDelay, 1

;Hide tray icon
#NoTrayIcon

;Copy paste functionality with the mouse scroller
copy_paste_button = MButton
open := 0
;========================================================
goto trigger
; F12 Key to trigger ahk_exe WindowsTerminal.exe
F12::
trigger:
DetectHiddenWindows, on
IfWinExist ahk_exe WindowsTerminal.exe
{
	positions := checkDisplay()
	If(open)
	{
		open := 0
		; IfWinNotActive ahk_exe WindowsTerminal.exe
		If(positions.oldPos.x != positions.newPos.x)
		{
			open := 2
		}
		MOVEUP(positions.oldPos)
		WinHide ahk_exe WindowsTerminal.exe
		WinActivate ahk_class Shell_TrayWnd
		if(open == 2){
			open := 0
			goto trigger
		}
	}
	else
	{
		open := 1
		WinShow ahk_exe WindowsTerminal.exe
		WinActivate ahk_exe WindowsTerminal.exe
		MOVEDOWN(positions.newPos)
	}
}
else
{	
	open := true
	Run %PathToConsole%
	WinWait, ahk_exe WindowsTerminal.exe
	sleep 200
	SysGet, ScreenHeight, 79  ; Get screen height

	NewWidth := 1680
	NewHeight := ScreenHeight // 2  ; Set height to 1/4th of the screen height
	NewX := (1920 - 1680) / 2  ; Position at the top-left of the screen
	NewY := 0  ; Position at the top of the screen

	WinMove, ahk_exe WindowsTerminal.exe, , NewX, NewY, NewWidth, NewHeight
	WinSet, AlwaysOnTop , On, ahk_exe WindowsTerminal.exe
}
DetectHiddenWindows, off
return
;========================================================

checkDisplay()
{
	returnVal := {}
	MouseGetPos, MouseX, MouseY
	SysGet, MonitorCount, MonitorCount

	MonitorNum := ""
	Loop, %MonitorCount%
	{
		SysGet, Monitor, Monitor, %A_Index%

		if (MouseX >= MonitorLeft and MouseX <= MonitorRight and MouseY >= MonitorTop and MouseY <= MonitorBottom)
		{
			MonitorNum := A_Index
			break
		}
	}

	if (MonitorNum = "")
	{
		MsgBox, Error: Could not determine the monitor containing the mouse.
		Return
	}

	WinGet, TerminalWinID, ID, ahk_exe WindowsTerminal.exe
	if (!TerminalWinID)
	{
		MsgBox, Error: WindowsTerminal.exe window not found.
		Return
	}
	
	WinGetPos, WinX, WinY, WinWidth, WinHeight, ahk_exe WindowsTerminal.exe	
	SysGet, TargetMonitor, Monitor, %MonitorNum%


	NewX := TargetMonitorLeft + ((1920 - 1680) / 2)
	NewY := 0
	
	returnVal.newPos := {x:NewX, y:NewY}
	returnVal.oldPos := {x:WinX, y:WinY}
	return returnVal
}


; RCtrl::Reload
; Launch_App2::Suspend
; RShift::ExitApp


;Animation Presets
MOVEDOWN(position){
	WinMove, position.x , -500
	WinMove, position.x , -450
	WinMove, position.x , -400
	WinMove, position.x , -350
	WinMove, position.x , -300
	WinMove, position.x , -250 
	WinMove, position.x , -200 
	WinMove, position.x , -150 
	WinMove, position.x , -100 
	WinMove, position.x , -050 
	WinMove, position.x , -000 
}

MOVEUP(position){
	WinMove, position.x , -000 
	WinMove, position.x , -050 
	WinMove, position.x , -100 
	WinMove, position.x , -150 
	WinMove, position.x , -200 
	WinMove, position.x , -250 
	WinMove, position.x , -300 
	WinMove, position.x , -350 
	WinMove, position.x , -400 
	WinMove, position.x , -450 
	WinMove, position.x , -500 
}