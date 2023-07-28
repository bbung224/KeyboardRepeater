#SingleInstance force
#Persistent
#include Lib\AutoHotInterception.ahk

IniPath := A_ScriptFullPath . ".ini"

key_list := []
marginX := 10
marginY := 10
idW := 30
rowH := 35

AHI := new AutoHotInterception()
DeviceList := AHI.GetDeviceList()

Gui, Add, Text, x10 y10, Enter Key List:
Gui, Add, Edit, x10 y30 w200 h30 vKeyList, 1 2 3 4 5 6 7 8 ``
Loop 10 {
    i := A_Index
    d := DeviceList[i]
    if (!IsObject(d)) {
        continue
    }
    rowY := (marginY * 3) + ((A_Index -1) * rowH) + 90
    Gui, Add, Radio, % " vRadioButton" i " hwndhwnd x10"  " y" rowY " w" idW, % d.handle
    fn := Func("RadioChanged").Bind(d.id)
    GuiControl, +g, % hwnd, % fn
    lowest := UpdateLowest(hwnd)
    maxWidths := UpdateWidth(hwnd)
}

lowest += 2 * MarginY
totalWidths := idW + maxWidths

Gui, Add, Button, x10 y70 w100 h30 gStartButton, Start
Gui, Add, Button, x120 y70 w100 h30 gStopButton, Stop
GuiControl, Disable, Start
GuiControl, Disable, Stop

Gui +LastFound
Gui, Show, % "w" (marginX * 3) + totalWidths + 100 " h" marginY + lowest, My Gui

Load()
return

StartButton:
    GuiControl, Enable, Stop
    GuiControl, Disable, Start
    GuiControl, Disable, KeyList
    Loop 10 {
        i := A_Index
        if (!IsObject(DeviceList[i])) {
            continue
        }
        GuiControl, Disable, RadioButton%i%
    }

    Gui, Submit, NoHide
    Save()
	Loop, Parse, KeyList, %A_Space%
	{
		key_list[A_Index] := A_LoopField
	}
    AHI.SubscribeKeyboard(dev.id, true, Func("OnKeyInput").Bind(dev.id))
    Return

StopButton:
    GuiControl, Disable, Stop
    GuiControl, Enable, Start
    GuiControl, Enable, KeyList
    Loop 10 {
        i := A_Index
        if (!IsObject(DeviceList[i])) {
            continue
        }
        GuiControl, Enable, % "RadioButton" i
    }
    Save()
    key_list := []
    AHI.UnsubscribeKeyboard(dev.id)
    Return

OnKeyInput(id, code, state) {
    global key_list, AHI, dev
  	scanCode := Format("{:x}", code)
	keyName := GetKeyName("SC" scanCode)
    processed := 0
    if (keyName = "LShift") {
        AHI.SendKeyEvent(dev.id, code, state)
        processed := 1
    } else if (keyName = "LAlt") {
        AHI.SendKeyEvent(dev.id, code, state)
        processed := 1
    } else if (keyName = "LControl") {
        AHI.SendKeyEvent(dev.id, code, state)
        processed := 1
    } else if (keyName = "Shift") {
        return
    }
    if (state = 1) { ; 키를 눌렀을때
        for index, key in key_list {
            if (keyName = key) {
                AHI.SendKeyEvent(dev.id, code, 1)
                AHI.SendKeyEvent(dev.id, code, 0)
                processed := 1
                break
            }
        }
        OutputDebug, %scanCode% %keyName% %flags%`n
    }
    if (processed = 0) {
        AHI.SendKeyEvent(dev.id, code, state)
    }
}

GuiClose:
    Save()
    ExitApp


Save() {
    global IniPath
    global KeyList
    Gui, Submit, NoHide

    IniWrite, %KeyList%, %IniPath%, default, KeyList
}

Load() {
    global IniPath
    global KeyList
    Gui, Submit, NoHide

    if (FileExist(IniPath)) {
        IniRead, KeyList, %IniPath%, default, KeyList, %A_Space%
        GuiControl, Text, KeyList, %KeyList%
    }
}

UpdateLowest(hwnd){
	static max := 0
	GuiControlGet, cp, pos, % hwnd
	pos := cpY + cpH
	if (pos > max){
		max := pos
	}
	return max
}

UpdateWidth(hwnd, reset := 0){
	static max := 0
	if (reset){
		max := 0
		return
	}
	GuiControlGet, cp, pos, % hwnd
	if (cpW > max){
		max := cpW
	}
	return max
}

RadioChanged(id, hwnd) {
    global AHI, dev, DeviceList
    GuiControlGet, state, , % hwnd
    if (state) {
        dev := DeviceList[id]
    }
    GuiControl, Enable, Start
}
