Menu, Tray, NoStandard 

Menu, tray, icon, active.ico, , 1

Menu, Tray, Add, About, DisplayAbout

Menu, Tray, Add, Pause, SuspendScript

Menu, Tray, Add, Exit, EndScript

Menu, Tray, Default, About 

#If IsDesktopUnderMouse()
~LButton::
	LButton_presses++
	if (LButton_presses=2)
		if (!IsObject(GetDesktopIconUnderMouse()) or DesktopIconsIsShow=0)
			DesktopIconsIsShow:=HideOrShowDesktopIcons()
	SetTimer, KeyLButton, -300
return

KeyLButton:
	LButton_presses := 0
return

IsDesktopUnderMouse()
{
	MouseGetPos, , , OutputVarWin
	WinGetClass, OutputVarClass, % "ahk_id" OutputVarWin
	if (OutputVarClass="WorkerW" or OutputVarClass="Progman")
		return, 1
	else
		return, 0
}

HideOrShowDesktopIcons()
{
	ControlGet, OutputVarHwnd, Hwnd,, SysListView321, ahk_class WorkerW
	if (OutputVarHwnd="")
      ControlGet, OutputVarHwnd, Hwnd,, SysListView321, ahk_class Progman

	if (DllCall("IsWindowVisible", UInt, OutputVarHwnd))
	{
		WinHide, ahk_id %OutputVarHwnd%
		return, 0
	}
	else
	{
		WinShow, ahk_id %OutputVarHwnd%
		return, 1
	}
}
#If

GetDesktopIconUnderMouse() {
	static MEM_COMMIT := 0x1000, MEM_RELEASE := 0x8000, PAGE_ReadWRITE := 0x04
		, PROCESS_VM_OPERATION := 0x0008, PROCESS_VM_READ := 0x0010
		, LVM_GETITEMCOUNT := 0x1004, LVM_GETITEMRECT := 0x100E

	Icon := ""
	MouseGetPos, x, y, hwnd
	if not (hwnd = WinExist("ahk_class Progman") || hwnd = WinExist("ahk_class WorkerW"))
		return
	ControlGet, hwnd, HWND, , SysListView321
	if not WinExist("ahk_id" hwnd)
		return
	WinGet, pid, PID
	if (hProcess := DllCall("OpenProcess" , "UInt", Process_VM_OPERATION|Process_VM_Read, "Int",  false, "UInt", pid)) {
		VarSetCapacity(iCoord, 16)
		SendMessage, %LVM_GETITEMCOUNT%, 0, 0
		loop, %ErrorLevel% {
			pItemCoord := DllCall("VirtualAllocEx", "Ptr", hProcess, "Ptr", 0, "UInt", 16, "UInt", MEM_COMMIT, "UInt", PAGE_ReadWRITE)
			SendMessage, %LVM_GETITEMRECT%, % A_Index-1, %pItemCoord%
			DllCall("ReadProcessMemory", "Ptr", hProcess, "Ptr", pItemCoord, "Ptr", &iCoord, "UInt", 16, "UInt", 0)
			DllCall("VirtualFreeEx", "Ptr", hProcess, "Ptr", pItemCoord, "UInt", 0, "UInt", MEM_RELEASE)
			left   := NumGet(iCoord,  0, "Int")
			top    := NumGet(iCoord,  4, "Int")
			Right  := NumGet(iCoord,  8, "Int")
			bottom := NumGet(iCoord, 12, "Int")
			if (left < x and x < Right and top < y and y < bottom) {
				ControlGet, list, List
				RegExMatch(StrSplit(list, "`n")[A_Index], "O)(.*)\t(.*)\t(.*)\t(.*)", Match)
				Icon := {left:left, top:top, Right:Right, bottom:bottom
					, name:Match[1], size:Match[2], type:Match[3]
				; Delete extraneous date characters (https://goo.gl/pMw6AM):
				; - Unicode LTR (Left-to-Right) mark (0x200E = 8206)
				; - Unicode RTL (Right-to-Left) mark (0x200F = 8207)
					, date:RegExReplace(Match[4], A_IsUnicode ? "[\x{200E}-\x{200F}]" : "\?")}
				break
			}
		}
		DllCall("CloseHandle", "Ptr", hProcess)
	}
	return Icon
}

DisplayAbout:
	Gui, Add, Picture,w80 h80 Center, active.ico
	Gui, font,bold
	Gui, Add, Text, Center x20, Desktop Icon Toggle by Hexandcube
	Gui, font,
	Gui, Add, Text,, hexandcube@hexandcube.tk
	Gui, Add, Text,, https://hexandcube.tk
	Gui, Add, Text,, Version 1.1
	Gui, Add, Text,, Desktop Icon by Icons8
	Gui, Show, w300 h240 center, About
	return
Return

SuspendScript:
	Suspend ,Toggle
	IF (A_IsSuspended) {
		Menu, Tray, Rename, Pause, Unpause
		Menu, tray, icon, suspended.ico, , 1
	}
	Else {
		Menu, Tray, Rename, Unpause, Pause
		Menu, tray, icon, active.ico, , 1
	}	
Return

EndScript:

  ExitApp 

Return

