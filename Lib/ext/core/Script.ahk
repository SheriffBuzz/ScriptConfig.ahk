/*
    Script

    This file should contain common functions for maintaining the lifecycle of a script: Reload, exit, check if admin, etc..

    @Deprecated move pkg to Lib\ext\core
*/

Reload() {
	Reload
}

/*
    ExitApp

    @BuiltInOverride
    
    Remarks
        - This method is an override and not a command wrapper, as it fully complies with both the v1 and v2 contracts.
*/
ExitApp(exitCode:=0, exitOnlyIfNotAdmin:=false, showTraytip:=false, thisFunc:="") {
    exitMsg:= "ExitingApp."
    if (exitOnlyIfNotAdmin && A_IsAdmin) {
        return
    }
    if (thisFunc) {
        existMsg.= "`nAt: " thisFunc
    }
    if (showTraytip) {
        if (exitOnlyIfNotAdmin) {
            exitMsg.= "`nScript must be run as Admin."
        }
        TrayTip(exitMsg, A_ScriptName)
    }
    logger.INFO(exitMsg)
	ExitApp
}

ExitAppIfNotAdmin(showTrayTip:=true, thisFunc:="") {
    ExitApp(,true, showTraytip, thisFunc)
}
