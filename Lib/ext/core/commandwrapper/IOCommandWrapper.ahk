/*
    FileCopy

    Function Wrapper for FileCopy command

    @see FileOperationsClass.copyFile
    @commandWrapper
*/
FileCopy(sourcePattern, targetPattern:="", overWrite:=false) {
    FileCopy, %sourcePattern%, %targetPattern%, %overwrite%
}

/*
    DirCopy

    @commandWrapper - v1 is FileCopyDir, v2 command is DirCopy.
    @see fileOperationsClass.copyFolder
    @return - empty. we prefer to return targetPattern but v2 does not do this.
*/
DirCopy(sourcePattern, targetPattern:="", overwrite:=false) {
    FileCopyDir, %sourcePattern%, %targetPattern%, %overWrite%
    return targetPattern
}

/*
    DirCreate

    @commandWrapper
*/
DirCreate(dirName) {
    FileCreateDir, %dirName%
}

/*
    FileMove

    @commandWrapper
    @return success:boolean
*/
FileMove(sourcePath, targetPath, overwrite:=false) {
    FileMove, %sourcepath%, %targetPath%, %overwrite%
}

/*
    FileDelete
    
    @param filePattern
    @commandWrapper
*/
FileDelete(filePattern) {
    FileDelete, %filePattern%
}

/*
    DirDelete

    @commandWrapper
*/
DirDelete(folderPath, recurse:=false) {
    FileRemoveDir, %folderPath%, %recurse%
}

/*
    FileAppend

    @commandWrapper
    @return options - IGNORED. v1 only has "Encoding" which we are not using
*/
FileAppend(text:="", fileName:="", options:="") {
    FileAppend, %text%, %fileName%
}

/*
    FileRead

    @commandWrapper
    @v2upgrade options param is not used in v1
*/
FileRead(fileName, options:="") {
    FileRead, fileContent, %fileName%
    return fileContent
}
/*
    FileGetSize

    @commandWrapper
*/
FileGetSize(filePath, units:="") {
    FileGetSize, size, %filePath%, %units%
    return size
}

/*
    FileSetTime

    @commandWrapper
*/
FileSetTime(timestamp:="", fileOrFolderPath:="", whichTime:="", mode:="") {
    if (!fileOrFolderPath) {
        throw "FileSetTime: 2nd arg fileOrFolderPath is required."
    }
    isOperateOnFolders:= (InStr(mode, "F"))
    isRecurse:= (InStr(mode, "R"))
    FileSetTime, %timestamp%, %fileOrFolderPath%, %whichTime%, %isOperateOnFolders%, %isRecurse%
}

/*
    FileGetTime

    M = Modification time
    C = Creation time
    A = Last access time

    @commandWrapper
*/
FileGetTime(filePath, whichTime) {
    FileGetTime, now, %filePath%, %whichTime%
    return now
}

/*
    DirSelect

    Remarks
        - FolderBroswerDialog is preferred

    @commandWrapper
*/
DirSelect(startingFolder:="", options:="", prompt:="") {
   FileSelectFolder, out, %startingFolder%, %options%, %prompt%
   return out
}

/*
    FileSelect

    @commandWrapper
*/
FileSelect(options:="", fileOrFolderPath:="", title:="", filter:="") {
    FileSelectFile, out, %options%, %fileOrFolderPath%, %title%, %filter%
    return out
}

/*
    SplitPath

    Remarks
        - SplitPath doesnt handle folders with a trailing path segment that has a . in it. (treats it as a file). Use FileUtil.getFolderSegments, FileUtil.getPathSegments, FileUtil.isFile, FileUtil.isFolder methods. (Although these require files to exist on the file system)
    
    @commandWrapper
*/
SplitPath(inputPath, ByRef fileName:="", ByRef dir:="", ByRef rawExtension:="", ByRef fileNameNoExt:="", ByRef drive:="") {
    SplitPath, inputPath, fileName, dir, rawExtension, fileNameNoExt, drive
}

/*
    FileCreateShortcut

    @commandWrapper
*/
FileCreateShortcut(target, linkFile, workingDir:="", args:="", description:="", iconFile:="", shortcutKey:="", iconNumber:="", runState:="") {
    FileCreateShortcut, %target%, %linkFile%, %workingDir%, %args%, %description%, %iconFile%, %shortcutKey%, %iconNumber%, %runState%
}

/*
    FileGetAttrib

    @commandWrapper
*/
FileGetAttrib(filePath) {
    FileGetAttrib, out, %filePath%
    return out
}
