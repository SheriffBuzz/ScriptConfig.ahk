/*
    Win32

    Wrapper for win32 api functions, either supported via ahk or dll call.
*/
class Win32Class extends ObjectBase {

    /*
        SendMessage

        Wrapper for SendMessage

        Simple wrapper for sending text content, with default timeout. To access full params, use SendMessage() native v2 function or v1 command wrapper.
        
        https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessage
    */
    sendMessage(content, scriptName) {
        SetTitleMatchMode(2)
        DetectHiddenWindows(true)
        VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)
        sizeInBytes:= (StrLen(content) + 1) * (A_IsUnicode ? 2 : 1)
        NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)
        NumPut(&content, CopyDataStruct, 2*A_PtrSize)
        mode:= 1
        SendMessage(WM_COPYDATA, mode, &CopyDataStruct,,scriptName,,,, 1000000)
        if (ErrorLevel = "FAIL") { ;if script name is wrong, it will fail immediately. If it is correct, wait some sufficiently long timeout because the script could be blocking on a messageBox and not return right away, and would inadvertently show the below error even though the script was called successfully
            MsgBox("Unable to call persistent script with title:`n`n" scriptName "`n`nPlease ensure the script is running.")
        }
    }

}
global win32:= new Win32Class() ;@Export win32
