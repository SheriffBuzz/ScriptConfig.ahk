;@v1start
#Include %A_LineFile%\..\commandwrapper\Exports.ahk
;@v1end

/*
    RunWait.ahk

    Threadsafe implementation of RunWait. RunWait blocks ahk threads, so provide alternative using sleep.
    @v2upgrade We plan to override the function in v2.
    @BuiltInOverride
*/
RunWait(path, waitDuration:=1000) {
    pid:= Run(path) ;TODO use executor service. currently it is not working state so just do run + pause if needed
    Critical("Off")
    winTitle:= "ahk_pid " pid
    timeoutSeconds:= 5
    WinWait(winTitle,, timeoutSeconds) ;After the Run command retrieves a PID, any windows to be created by the process might not exist yet. To wait for at least one window to be created, use WinWait ahk_pid %OutputVarPID%. ;https://www.autohotkey.com/docs/commands/Run.htm
    Sleep(1)
    while (WinExist(winTitle)) {
        Sleep(waitDuration)
    }
}
