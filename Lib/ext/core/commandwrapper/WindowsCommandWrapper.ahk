/*
    WinGetTitle

    This function can be used to get the visible window title, given a winTitle input that may be an ahk_class, ahk_pid, etc.

    @commandWrapper
*/
WinGetTitle(winTitle) {
    WinGetTitle, out, %winTitle%
    return out
}

/*
    WinWaitActive

    @commandWrapper
*/
WinWaitActive(winTitle:="A", winText:="", maxWaitSeconds:="") {
	WinWaitActive, %winTitle%, %winText%,%maxWaitSeconds%
}

/*
    WinActivate

    @commandWrapper
*/
WinActivate(ByRef winTitle) {
	WinActivate, %winTitle%
}

/*
    WinWait

    @commandWrapper
*/
WinWait(winTitle:="A", winText:="", timeout:="") {
	WinWait, %winTitle%, %winText%, %timeout%
}

/*
    WinMinimize

    @commandWrapper
*/
WinMinimize(winTitle) {
	WinMinimize, % winTitle
}

/*
    WinHide

    @commandWrapper
*/
WinHide(winTitle) {
    WinHide, %winTitle%
}

/*
    WinShow

    @commandWrapper
*/
WinShow(winTitle) {
    WinShow, %winTitle%
}

/*
    WinGet

    Remarks
        - WinGet is not in ahk v2, see link for fn's.
        
        https://www.autohotkey.com/docs/v2/lib/Win.htm

    @commandWrapper
*/
WinGet(subCommand:="", winTitle:="A") {
    WinGet, outputVar, %subCommand%, %winTitle%
    return outputVar
}

/*
    WinSet

    @commandWrapper
*/
WinSet(subCommand, value, winTitle) {
    WinSet, %subCommand%, %value%, %winTitle%
}

/*
    WinMove

    Remarks - ahkv2 parameter order is different than v1. we are using v2.

    @commandWrapper
*/
WinMove(x, y, width:="", height:="", winTitle:="A") {
    WinMove, %winTitle%,, %x%, %y%, %width%, %height%
}

/*
    WinGetPos

    @commandWrapper
    @return empty
*/
WinGetPos(ByRef outX:="", ByRef outY:="", ByRef outWidth:="", ByRef outHeight:="", winTitle:="A") {
    SetTitleMatchMode(2) ;@HACK
    WinGetPos, outX, outY, outWidth, outHeight, %winTitle%
    /*
    ;This is not part of impl, this is an extension that was removed. Keeping for now as we might want to extend this, but it wont be under a command wrapper.
    x2:= x + w
    y2:= y + h
    return [x1, y1, x2, y2]
    */
}
