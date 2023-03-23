#Include %A_LineFile%\..\..\date\Exports.ahk

/*
    FileAttributeUtil

    Methods of this class accept and return Lib\ext\date\DateClass objects.
*/
class FileAttributeUtilClass {
    setTime(timestamp:="", path:="", whichTime:="", isOperateOnFolders:=false, isRecurse:=false) {
        path:= ExpandEnvironmentVariables(path)

        if (IsObject(timestamp)) { ;Lib\ext\date\DateClass
            timestamp:= timestamp.getAhkTimestamp()
        }

        ;conform to v2 syntax.
        mode:= "F"
        if (isOperateOnFolders) {
            mode.= "D"
        }
        if (isRecurse) {
            mode.= "R"
        }
        FileSetTime(timestamp, path, whichTime, mode)
    }

    getTime(path, whichTime:="") {
        path:= ExpandEnvironmentVariables(path)
        ahkTimestamp:= FileGetTime(path, whichTime)
        return DateClass.FromAhkTimestamp(ahkTimestamp)
    }

    setModifiedTime(timestamp, path, isOperateOnFolders:=false, recurse:=false) {
        this.setTime(timestamp, path, "M", isOperateOnFolders, isRecurse)
    }
    
    setModifiedNow(path, isOperateOnFolders:=false, recurse:=false) {
        this.setTime(,path, "M", isOperateOnFolders, recurse)
    }

    setCreatedNow(path, isOperateOnFolders:=false, recurse:=false) {
        this.setTime(,path, "C", isOperateOnFolders, recurse)
    }

    setLastAccessedNow(path, isOperateOnFolders:=false, recurse:=false) {
        this.setTime(,path, "A", isOperateOnFolders, recurse)
    }

    getModifiedTime(path) {
        return this.getTime(path, "M")
    }

    getCreationTime(path) {
        return this.getTime(path, "C")
    }

    getLastAccessTime(path) {
        return this.getTime(path, "A")
    }
}
global fileAttributeUtil:= new FileAttributeUtilClass() ;@Export fileAttributesUtil
