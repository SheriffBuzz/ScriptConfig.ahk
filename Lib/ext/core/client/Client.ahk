/*
    Client.ahk

    Core functions for Creating Client Scripts. Here "Client" is a user defined identifier that desribes a top level script that is outside of Lib directory. It is used to distinguish top level scripts and the lib classes they wrap, ie "FileCopy" and "FileCopyClient".
*/

global A__TopLevelScript:= false
global A__AddExitHotkey:= false

/*
    IsClientScript

    Reserved future use
*/
IsClientScript(bool:=false) {
}

/*
    IsTopLevelScript

    Reserved future use
*/
IsTopLevelScript(bool:=false) {
}

IsPersistent(bool:=false) {

}

/*
    IsAddExitHotkey

    Set prop for if ScriptConfig can add a hotkey configured in scriptconfig.json with prop "ExitAppHotkey" to exit the script.

    @TODO convert top level scripts from :: hotkey syntax to hotkey add fn. From there we can set ExitAppHotkey (Goal is to add the exit app hotkey only to scripts that already define hotkeys that make them effectively persistent, while avoiding adding a hotkey that wasnt originally effectively persistent)
*/
IsAddExitHotkey(bool:=false) {
    A__AddExitHotkey:= bool
    if (A__AddExitHotkey) { ;try to set on scriptconfig as this fn may be called after scriptconfig is imported
        scriptConfig.setExitAppHotkey()
    }
}
