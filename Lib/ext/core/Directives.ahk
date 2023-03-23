/*
    Directives

    Remarks
        - for v1, v2 Command wrappers should already be loaded. This file should use v2 commands.
*/

;@v1start
#Requires Autohotkey >=v1.1.36.00
SetBatchLines, -1
#NoEnv
#MaxMem 1024
#KeyHistory 0
#Warn All, Off
global A__ByRefOperator:= "ByRef"
;@v1end

;@v2start
/*
#Requires Autohotkey >=v2.0.0
#Warn VarUnset, Off
A__ByRefOperator:= "&"
*/
;@v2End

#SingleInstance force
ListLines(true)
CoordMode("Mouse", "Screen")
SendModeInput()
SetTitleMatchMode(2)
ProcessSetPriority("H")
DetectHiddenWindows(true)
