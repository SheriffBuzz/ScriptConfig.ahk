#Include %A_LineFile%\..\Globals.ahk
#Include %A_LineFile%\..\BaseExports.ahk
;@v1start
#Include *i %A_LineFile%\..\commandWrapper\Exports.ahk
;@v1end
#Include %A_LineFile%\..\Directives.ahk

#Include %A_LineFile%\..\BuiltInFunctionResult.ahk
#Include %A_LineFile%\..\client\Client.ahk


/*
    Lib\Ext\Core

    Core functions, v2 function Command wrappers, Directives
    
    This package contains commandWrappers and other core functions. A command wrapper is a user defined function that has the signature of the ahk v2 equivalent for a given v1 command. We currently do not plan to move to v2, but using command wrappers will simplify the transition if we ever decide to. In v2 we can just delete the command wrapper functions and the native functions will work. We use the commandWrapper annotation on each function to make these functions easily searchable in an IDE.

    Using functions over commands is also preferred as it is more similar to modern programing languages.

    All top level scripts should at a minimum import this file, although importing ScriptConfig.ahk is preferred, for additional out of the box benefits like workingDirectory and json configs.
*/
