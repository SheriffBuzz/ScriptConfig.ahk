;@TODO push these down to Lib\ext\core\commandWrapper. There should be no dependency risk as all command wrappers now implement only the command translation, we have extracted extra functionality out of the commandwrappers into their own functions or classes (see fileOperationsClass for an example)
#Include %A_LineFile%\..\Run.ahk
#Include %A_LineFile%\..\Send.ahk
#Include %A_LineFile%\..\Hotkey.ahk
#Include %A_LineFile%\..\Script.ahk
#Include %A_LineFile%\..\ExpandEnvironmentVariables.ahk
#Include %A_LineFile%\..\Function.ahk
