/*
    Command Wrapper

    Base file for misc command wrappers. See \..\Exports.ahk for more details
*/

/*
    Click

    https://www.autohotkey.com/docs/v2/lib/Click.htm

    @commandWrapper
*/
Click(options:="") {
    Click, %options%
}

/*
    Sleep

    @commandWrapper
*/
Sleep(ByRef millis) {
    Sleep, %millis%
}

/*
    Msgbox

    Messagebox wrapper

    Remarks
        - options must be percent expression forced. Double percent closure of a single variable wont work.
            https://www.autohotkey.com/board/topic/102138-problem-using-variable-within-message-box/
    @commandWrapper - v2 upgrade notes - v2 returns a value. See https://www.autohotkey.com/docs/v2/lib/MsgBox.htm#Result
*/
MsgBox(text:="", title:="", options:="") {
    if (title || options) {
        MsgBox, % options, % title, % text
    } else {
        MsgBox, % text
    }
}

/*
    TrayTip

    Remarks
        - This function uses ahk v2 synatax. Note the first param is text, not title.
    
    @commandWrapper
*/
TrayTip(text, title:="", options:= 1) {
    TrayTip, %title%, %text%, %seconds%, %options%
}

/*
    Hotkey

    https://www.autohotkey.com/docs/v2/lib/Hotkey.htm

    @commandWrapper
    @param keyName - ahk keySequence
    @param label - global function name, or functionRef object
    @param options - see above link

*/
Hotkey(keyName, label, options:="") {
    Hotkey, %keyName%, %label%, %options%
}

/*
    Run

    Remarks
        - We use v2 syntax with slight difference - run returns pid. OutputVarPid is stills set.
        - Runwait returns exit code to comply with v2 syntax, although it would be preferred to return the pid.

    @commandWrapper
    @return PID
*/
Run(target, workingDir:="", options:="", ByRef outputVarPID:="") {
    Run, %target%, %workingDir%, %options%, pid
    outputVarPID:= pid
    return pid
}

/*
    SetTimer

    Remarks
        - ahk v1 to v2 change, v1 must use Off, v2 use 0
    @commandWrapper
*/
SetTimer(function, period, priority:="") {
    period:= (period = 0) ? "Off" : period
    SetTimer, %function%, %period%, %priority%
}

/*
    KeyWait

    @CommandWrapper
*/
KeyWait(keyName, options:="") {
    KeyWait, %keyName%, %options%
}

/*
    FormatTime

    @commandWrapper
*/
FormatTime(YYYYMMDDHH24MISS:="", format:="") {
    YYYYMMDDHH24MISS:= (YYYYMMDDHH24MISS) ? YYYYMMDDHH24MISS : A_Now
    FormatTime, OutputVar, %YYYYMMDDHH24MISS%, %format%
    return outputVar
}

/*
    InputBox

    Wrapper for input box. We prefer a function arg for each option, so an additional wrapper has been implemented in Lib\ext\ui. This version is not preferred to be used directly, it is for future compatability with ahk v2.

    https://www.autohotkey.com/docs/v2/lib/InputBox.htm

    Remarks
        - We are not handling v1 "locale" option as v2 doesnt support it and we dont have a usecase for it.
        - v1 doesnt support custom Password character, so it will always be an asterisk.
        - result value is still set even in the case of timeout or cancel, so caller must check the result status. (Lib\ext\ui Wrapper function should do this)
        - Prompt may be hidden if height value is not large enough.

    @commandWrapper
    @param prompt Text inside input box
    @param title
    @param options Xn Yn Wn Hn T Password - T is timeout
*/
InputBox(prompt:="", title:="", options:="", default:="") {
    ;convert v2 to v1 args
    ops:= StrSplit(options, " ")

    hide:=
    x:=
    y:=
    w:=
    h:=
    for i, op in ops {
        if (InStr(op, "x") = 1) {
            x:= SubStr(op, 2)
        } else if (InStr(op, "y") = 1) {
            y:= SubStr(op, 2)
        } else if (InStr(op, "w") = 1) {
            w:= SubStr(op, 2)
        } else if (InStr(op, "h") = 1) {
            h:= SubStr(op, 2)
        } else if (InStr(op, "T") = 1) {
            t:= SubStr(op, 2)
        } else if (op = "Password") {
            hide:= "hide"
        }
    }
    InputBox, OutputVar, %title%, %prompt%, %hide%, %w%, %h%, %x%, %y%,,%t%, %default%
    result:=
    if (ErrorLevel = 1) {
        result:= "Cancel"
    } else if (ErrorLevel = 2) {
        result:= "Timeout"
    } else {
        result:= "OK"
    }
    v2ResultObj:= {value: outputVar, result: result}
    return v2ResultObj
}

/*
    MouseMove

    @commandWrapper
    @param coords - Arr[x,y]
*/
MouseMove(x, y, speed:="", relative:="") {
    MouseMove, %x%, %y%, %speed%, %relative%
}

/*
    MouseGetPos

    @commandWrapper
    @return arr - tuple of [x, y]
*/
MouseGetPos(ByRef x, ByRef y) {
    CoordMode, Mouse, Screen
    MouseGetPos, x, y
    return [x, y]
}

/*
    ImageSearch

    @commandWrapper
*/
ImageSearch(ByRef outputVarX, ByRef outputVarY, x1, y1, x2, y2, imageFile) {
    ImageSearch, outputVarX, outputVarY, %x1%, %y1%, %x2%, %y2%, %imageFile%
}

/*
	EnvGet

	@commandWrapper
*/
EnvGet(name) {
	EnvGet, val, %Name%
	return val
}

/*
	EnvSet
	
	@commandWrapper
*/
EnvSet(envVar, value) {
	EnvSet, %envVar%, %value%
	if (ErrorLevel) {
		throw "Error on EnvSet for key:" envVar ", value:" value
	}
}

/*
    CoordMode

    @commandWrapper
*/
CoordMode(targetType, relativeTo:="") {
    CoordMode, %targetType%, %relativeTo%
}

/*
    WinSetTransparent

    @commandWrapper
*/
WinSetTransparent(n, winTitle:="A") {
    WinSet, Transparent, %n%, %winTitle%
}

/*
    WinGetTransparent

    @commandWrapper
*/
WinGetTransparent(winTitle:="A") {
    WinGet, Transparent, %winTitle%
}

/*
    SetTitleMatchMode

    @commandWrapper
*/
SetTitleMatchMode(matchModeSpeed) {
    SetTitleMatchMode, %matchModeSpeed%
}

/*
    ProcessSetPriority

    @commandWrapper
*/
ProcessSetPriority(level, PIDorName:="") {
    if (PIDorName) {
        Process, Priority, %PIDorName%, %level%
    } else {
        Process, Priority,, %level%
    }
}

/*
    ProcessClose

    @commandWrapper
*/
ProcessClose(PIDorName) {
    Process, Close, %PIDorName%
}

/*
    IsInteger

    @commandWrapper
*/
IsInteger(nr){ 
	If nr is integer
		return true
	else
		return false
}

/*
    IsNumber

    @commandWrapper
*/
IsNumber(str) {
   Static number := "number"
   If str Is number
      Return 1
   Return 0
}

/*
    SendMode

    @commandWrapper
*/
SendMode(mode:="Input") {
    SendMode, %mode%
}

/*
    ListLines

    @commandWrapper
    @param mode boolean
*/
ListLines(mode) {
    ListLines, %mode%
}

/*
    DetectHiddenWindows

    @commandWrapper
*/
DetectHiddenWindows(mode) {
    DetectHiddenWindows, %mode%
}

/*
    Critical

    Remarks
        - We may need to test if the method call causes a thread to be interrupted when we dont want it to. However, the blocks between critical on/off should be not interrupted.
            - use "Critical" for now as opposed to this fn for turning on critical. It is ahk v1 and v2 compliant.
    @commandWrapper
*/
Critical(OnOffNumeric) {
    Critical, %OnOffNumeric%
}

/*
    VarSetStrCapacity

    @commandWrapper
*/
VarSetStrCapacity(ByRef targetVar, requestedCapacity:="") {
    return VarSetCapacity(targetVar, requestedCapacity)
}

/*
    SendMessage

    @commandWrapper
*/
SendMessage(msg, wParam:="", lParam:="", control:="", winTitle:="", winText:="", excludeTitle:="", excludeText:="", timeout:="") {
    SendMessage, %msg%, %wParam%, %lParam%, %control%, %winTitle%, %winText%, %excludeText%, %timeout%
}

/*
    PostMessage

    @commandWrapper
*/
PostMessage(msg, wParam:="", lParam:="", control:="", winTitle:="", winText:="", excludeTitle:="", excludeText:="") {
    PostMessage, %msg%, %wParam%, %lParam%, %control%, %winTitle%, %winText%, %excludeText%
}

/*
    SetKeyDelay

    @commandWrapper
*/
SetKeyDelay(delay:="", pressDuration:="") {
    SetKeyDelay, %delay%, %pressDuration%
}

/*
    ControlGetHwnd

    @commandWrapper
*/
ControlGetHwnd(control:="", winTitle:="") {
    ControlGet, out, Hwnd,, %control%, %winTitle%
    return out
}

/*
    ControlGetChecked

    @commandWrapper
*/
ControlGetChecked(control:="", winTitle:="") {
    ControlGet, out, Checked,, %control%, %winTitle%
    return (out)
}

/*
    ControlGetChoice

    @commandWrapper
*/
ControlGetChoice(control:="", winTitle:="") {
    ControlGet, out, Choice,, %control%, %winTitle%
    return (out)
}

/*
    ControlGetText

    Remarks
        - Control is marked as required, but it can be omitted if winTitle is given.
            https://www.autohotkey.com/docs/v2/lib/Control.htm#Parameter

    @param control - can be hwnd
    @commandWrapper
*/
ControlGetText(control:="", winTitle:="") {
    ControlGetText, out, %control%, %winTitle%
    return out
}

/*
    ControlSetText

    @commandWrapper
*/
ControlSetText(newText, control:="", winTitle:="") {
    ControlSetText,%control%, %newText%, %winTitle%
}

/*
    ControlChooseIndex

    @commandWrapper
*/
ControlChooseIndex(n, control:="") {
    GuiControl, Choose, %control%, %n%
}

/*
    ControlSetEnabled

    Remarks
        - -1 not supported yet (toggle)
    @commandWrapper
*/
ControlSetEnabled(value, control:="", winTitle:="") {
    if (value = true) {
        Control, Enable,, %control%, %winTitle%
    } else if (value = false) {
        Control, Disable,, %control%, %winTitle%
    } else if (value = -1) {
        throw "ControlSetEnabled -1 not implemented"
    }
}

/*
    IniRead

    @commandWrapper
*/
IniRead(filePath, section, key, defaultValue:="") {
    IniRead, OutputVar, %filePath%, %section%, %key%, %defaultValue%
    return OutputVar
}

/*
    IniWrite

    @commandWrapper
*/
IniWrite(value, filePath, section, key) {
    IniWrite, %value%, %filePath%, %section%, %key%
}

/*
    SetWorkingDir

    @commandWrapper
*/
SetWorkingDir(dirName) {
    SetWorkingDir, %dirName%
}

/*
    GuiControl

    @TODO
*/