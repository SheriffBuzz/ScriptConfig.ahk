#Include %A_LineFile%\..\CommandWrapper.ahk
#Include %A_LineFile%\..\WindowsCommandWrapper.ahk
#Include %A_LineFile%\..\IOCommandWrapper.ahk
#Include %A_LineFile%\..\StringCommandWrapper.ahk
#Include %A_LineFile%\..\SendCommandWrapper.ahk
#Include %A_LineFile%\..\MenuCommandWrapper.ahk
#Include %A_LineFile%\..\ComObjectCommandWrapper.ahk

/*
    Exports

    Wrapper functions of v1 commands for using v2 functions in v1
    
    Functions in this package should be marked with commandWrapper annotation and follow the ahk v2 function equivalent syntax. If any functions provide any enhanced functionality, they do not belong in this package. Any function in this folder should be considered a candidate for deletion on upgrade to ahk v2.

    Goals:
        - Provide v2 equivalent functions natively in v1, without the need for explicit imports.
        - Write all new code as v2 compliant code, while still developing on v1.

    File name convention: {Lib\ext packageName}CommandWrapper.ahk
        - The file name should have the package, so we can search in workspace for the name of the package (as opposed to all having same name or not including package name)

    Remarks
        - \..\BaseExports.ahk should be considered a dependency although it shouldnt need to be explicitly exported.
        - Include Lib\ext\core\Exports.ahk, Do not include this file directly.
*/
