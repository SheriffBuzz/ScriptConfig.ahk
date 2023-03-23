
/*
    Hotkey

    Functions for wrapping Hotkey command, that can turn a hotkey on or off, or toggle it.

    Remarks
        - Permanent Hotkeys should only be added via a top level script. Outside a top level script, code should only add hotkeys that are intended to be turned off shortly.
        - Hotkeys are only ideal for hacking something together or simple scripts. More complex scripts should trigger top level functions or methods of an object instance using a label or ObjBindMethod. You could also use the streamdeck-ahk-client project to invoke functions via a stream deck.
            - Using hotkeys is not ideal because they might interfere with other program's default hotkeys. They also are less reliable when trying to develop code that may run on different computers, where different users may have different programs set up that might have conflicting hotkeys.

    Future enhancement: integrate into hotkeycache
*/

HotkeyOn(keyName, label) {
    Hotkey(keyName, label, "On")
}

HotkeyOff(keyName, label) {
    Hotkey(keyName, label, "Off")
}

HotkeyToggle(keyName, label) {
    Hotkey(keyName, label, "Toggle")
}
