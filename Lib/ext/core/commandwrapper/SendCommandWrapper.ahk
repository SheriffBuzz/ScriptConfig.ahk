/*
    Send

    Send using default Send configured with SendMode.

    @commandWrapper
*/
Send(keySequence) {
    Send, %keySequence%
}

/*
    SendInput

    @commandWrapper
*/
SendInput(keySequence) {
    SendInput, %keySequence%
}

/*
    SendEvent

    @commandWrapper
*/
SendEvent(keySequence) {
    SendEvent, %keySequence%
}

/*
    ControlSend

    @commandWrapper
*/
ControlSend(control:="", keySequence:="", winTitle:="") {
    ControlSend, %control%, %keySequence%, %winTitle%
}
