#Include %A_LineFile%\..\FileUtil.ahk
#Include %A_LineFile%\..\FileAttributeUtil.ahk
#Include %A_LineFile%\..\FileWriter.ahk
#Include %A_LineFile%\..\GeneratedContent.ahk

/*
    FileOperations

    Class to wrap File/folder operations. Add Enhanced functionality beyond native/commandWrapper functions. This class is focused on actions that modify files or folders on disk

    @v2upgrade - this class based approach abstracts away the v2 File operation functions. Previously in v1 were were using a function to wrap a v1 command, but this would break in v2 as you cant cleanly override a function you need to call its command. (ie for runwait you can use run and some more complex logic, but eg. for file copy there is no other command to provide the native functionality, outside dll call)
*/
class FileOperationsClass {
    /*
        copyFile

        Function Wrapper for FileCopy command

        Remarks
            - when working with file copying, keep in mind modified, created dates may not be preserved. If you need to preserve file metadata, include it in the file name.

        @param sourcePattern
        @param targetPattern - if blank, use sourcePattern + @param destNameAddition
        @param overwrite
        @param destNameAddition - if destination is not set, we can customize the path name. It must be supported by FileCopy itself, as if caller passed source + some addition, it would be added after the extention would would be incorrect. (ie. C:\path\FileName.exeCopy is wrong)
        @param isFolderInheritFileModifiedTime - only update the containing folder to be as new as the latest modified file. Otherwise now. By default Windows updates a folder when a file is created, deleted, etc. but not modified.
        @return targetPattern
    */
    copyFile(sourcePattern, targetPattern:="", overwrite:=false, destNameAddition:="Copy", isFileModifiedNow:=false, isFolderInheritFileModifiedTime:=true) {
        sourcePattern:= ExpandEnvironmentVariables(sourcePattern)
        targetPattern:= ExpandEnvironmentVariables(targetPattern)
        if (!targetPattern) {
            targetPattern:= fileUtil.appendValueToFileName(sourcePattern, destNameAddition)
        }
        containingFolder:= fileUtil.createContainingFolder(targetPattern)
        if (FileExist(targetPattern) && !overwrite) {
            return targetPattern
        }
        FileCopy(sourcePattern, targetPattern, overwrite)
        if (fileModifiedNow) {
            fileAttributeUtil.setModifiedNow(targetPattern)
        }

        if (isFolderInheritFileModifiedTime) {
            sourceFolderModifiedTime:= fileAttributeUtil.getModifiedTime(fileUtil.getFolderPath(sourcePattern))
            fileModifiedTime:= fileAttributeUtil.getModifiedTime(targetPattern)

            newModifiedTime:= (sourceFolderModifiedTime.lessThan(fileModifiedTime)) ? fileModifiedTime : sourceFolderModifiedTime
            fileAttributeUtil.setModifiedTime(newModifiedTime)
        }
        return targetPattern
    }

    /*
        copyFilesByName

        Copy files from a source directory to target directory, specifying an array of file names. This is a syntatic sugar to pluck out specific files for copy, while only having to specify the names instead of a full file path.

        Usecase
            - Copy small amount of files from a known root directory, by name
    */
    copyFilesByName(sourceFolderPath, targetFolderPath, fileNamesWithExt, overwrite:=false) {
        for i, fileNameWithExt in fileNamesWithExt {
            sourceFilePath:= sourceFolderPath "\" fileNameWithExt
            targetFilePath:= targetFolderPath "\" fileNameWithExt
            this.copyFile(sourceFilePath, targetFilePath, overwrite)
        }
    }

    /*
        copyFolder
    */
    copyFolder(sourcePattern, targetPattern:="", overwrite:=false, destNameAddition:="Copy") {
        sourcePattern:= ExpandEnvironmentVariables(sourcePattern)
        if (!targetPattern) {
            targetPattern:= fileUtil.appendValueToFileName(sourcePattern, destNameAddition)
        }
        DirCopy(sourcePattern, targetPattern, overWrite)
        return targetPattern
    }

    /*
        copyFileOrFolder

        Remarks
            - This function assumes the caller isnt passing a source file and target folder, and vice versa. TODO.
    */
    copyFileOrFolder(sourcePattern, targetPattern:="", overwrite:=false, destNameAddition:="Copy", isFileModifiedNow:=false) {
        return (fileUtil.isFile(sourcePattern)) ? this.copyFile(sourcePattern, targetPattern, overwrite, destNameAddition, isFileModifiedNow) : this.copyFolder(sourcePattern, targetPattern, overwrite, destNameAddition)
    }

    /*
        copyPathsInHierarchyToFolder

        Copies all files under the same source workspace/hierarchy to an arbitrary target folder. The input of this function are files paths, whose only restriction is that they are under the source workspace root.

        Usecase:
            Selectively copy specific files out of a folder hierarchy to new location, without copying entire folders. We may need this for distributing a subset of files, without including certain other folders that may be private or unused.

        @TODO param to update the folder modified time to Max(SubDirectory File modified date). It is inconvenient to have folder modified time to be "now"

        Remarks
            - This method is intended for files, but also supports folders.
        
        Example:
            Source workspaceRoot:
                C:\toolkit\Autohotkey (note this directory has lots of files in addition to sourceFilePaths)

            SourceFilePaths:
                C:\toolkit\Autohotkey\ScriptConfig.json
                C:\toolkit\Autohotkey\Lib\ScriptConfig.ahk
                C:\toolkit\Autohotkey\Lib\ext\string\Exports.ahk

            TargetFolderPath:
                %USERPROFILE%\Downloads\ahkspecificfeature2

            Result:
                %USERPROFILE%\Downloads\ahkspecificfeature2\ScriptConfig.json
                %USERPROFILE%\Downloads\ahkspecificfeature2\Lib\ScriptConfig.ahk
                %USERPROFILE%\Downloads\ahkspecificfeature2\Lib\ext\string\Exports.ahk
    */
    copyPathsInHierarchyToFolder(sourceWorkspaceRoot, sourceFilePaths, targetFolderPath, updateFileModifiedTime:=false, isFileModifiedNow:=true) {
        fileUtil.createContainingFolder(targetFolderPath)
        for i, sourceFilePath in sourceFilePaths {
            pathFromWorkspaceRoot:= fileUtil.relativePathFromWorkspaceRoot(sourceWorkspaceRoot, sourceFilePath)
            targetFilePath:= targetFolderPath "\" pathFromWorkspaceRoot
            this.copyFileOrFolder(sourceFilePath, targetFilePath, true,, isFileModifiedNow)
        }
    }

    /*
        copyPathsInHierarchyFromTemplate

        Copy paths in a hierarchy. Instead of getting source files from a list of input files to the method, the file paths are sourced from a "template" hierarchy (folder), already in the file system.

        Usecase:
            - Copy a small amount of statically known files in a large hierarchy. Use an external template folder that stores what files should be copied. The actual files contents to copy come from the source hierarchy, not the template.
                - Each hierarchy may be a new version of a project. We update the latest files within the latest version of the project. The template can hint "which" files to copy, while they can come from the latest version, without having to recopy the latest to the template.

        Remarks
            - no files are copied out of templateHierarchyRoot. It is only used to lookup a file within the source hierarchy (more formally, the file path from the hierarchy root matches, including file extension)
            - you can update the template location by calling this method with targetHierachyRoot = templateHierarchyRoot.

        Future Enhancement:
            Option for leaf folders that are empty to do a folder copy of all sub files/folders. Maybe allow a special file that contains json info that specifies which sub paths should be copied, possibly via extension include/excludes, regex, etc.. This could extract more complex logic out of ahk code.

        @param sourceHierarchyRoot
        @param templateHierarchyRoot
        @param templateHierarchyRoot
    */
    copyPathsInHierarchyFromTemplate(sourceHierarchyRoot, targetHierarchyRoot, templateHierarchyRoot, updateFileModifiedTime:=false, isFileModifiedNow:=true) {
        templateFilePaths:= fileUtil.getFilePathsFromContainingFolder(templateHierarchyRoot, true)
        sourceFilePaths:= fileUtil.replaceWorkspaceRoot(templateFilePaths, templateHierarchyRoot, sourceHierarchyRoot)
        this.copyPathsInHierarchyToFolder(sourceHierarchyRoot, sourceFilePaths, targetHierarchyRoot, updateFileModifiedTime, isFileModifiedNow)
    }

    /*
        moveFile

        Enhancement of FileMove, with additional logging and return value.

        @param ovewrite - default true. this is an override of FileMove. FileMove is default false.
        @return success:boolean
    */
    moveFile(sourcePath, targetPath, overwrite:=true) {
        sourcepath:= ExpandEnvironmentVariables(sourcePath)
        targetPath:= ExpandEnvironmentVariables(targetPath)
        if (!FileExist(sourcepath)) {
            logger.WARN("[{1}] Move failed for {1} to {2}: invalid source path.", sourcepath, targetPath)
            return false
        }
        FileMove(sourcepath, targetPath, overwrite)
        return (ErrorLevel) ? false : true
    }

    /*
        deleteFile

        FileDelete wrapper that accepts either a filePattern or an Array of filePatterns.
        
        @param filePatternOrArr - wildcard pattern, or array of file patterns.
    */
    deleteFile(filePatternOrArr) {
        if (IsObject(filePatternOrArr)) {
            for i, filePattern in filePatternOrArr {
                FileDelete(filePattern)
            }
        } else {
            FileDelete(filePatternOrArr)
        }
    }

    /*
        deleteFolder

        @param deleteEmptyOnly - reserved future use. @PSR.
    */
    deleteFolder(folderPath, recurse:=false, deleteEmptyOnly:=false) {
        folderPath:= ExpandEnvironmentVariables(folderPath)
        if (deleteEmptyOnly && !fileUtil.isFolderEmpty(folderPath)) {
            if (logger.isDebugEnabled()) {
                this.DEBUG("Delete folder: Skipping non-empty folder {1}", folderPath)
            }
            return
        }
        if (!FileExist(folderPath)) {
            return
        }
        DirDelete(folderPath, recurse)
    }

    /*
        createFile

        Create file using filewriter. This adds a circular dependency on this file to filewriter, but it is more clear to use fileOps for creating a file than writer.
    */
    createFile(filePath, overwrite:=false) {
        fileWriter.write(filePath,, false)
    }

    /*
        CreateShortcut

        Create a shortcut (.lnk file).

        @param iconLocation - only supporting ico and first ico in exe or dll. Icon number is supported by FileCreateShortcut but we arent implementing it for now
        @param description - used for tooltips

        https://www.autohotkey.com/docs/v2/lib/FileCreateShortcut.htm
    */
    createShortcut(shortcutFilePath, applicationFilePath, iconLocation:="", description:="") {
        shortcutFilePath:= ExpandEnvironmentVariables(shortcutFilePath)
        shortcutExtension:= fileUtil.getExtension(shortcutFilePath, false)
        if (FullFileExtension(shortcutExtension) != FullFileExtension(".lnk")) {
            TrayTip(this.DEBUG("Create shortcut: invalid lnk file: {1}", shortcutFilePath))
            return
        }
        applicationFilePath:= fileUtil.assertPathExists(applicationFilePath)
        iconLocation:= (iconLocation) ? iconLocation : applicationFilePath

        FileCreateShortcut(applicationFilePath, shortcutFilePath,,, description, iconLocation)
    }

    /*
        unpackFolder

        Unpack files from a folder.

        @param depth - reserved future use
        @param useGeneratedContent - boolean. If true, instead copy files to a generated content path instead of doing a file move. This could be used to get a consolidated view of files in a hierarchy (use copyPathsInHierachy Methods if need to preserve hierarchy)
        @TODO set default max file count and folder size limits before prompting a dialog asking for confirmation. (We dont want to hang the system or do an accidental unpack of large directory)
    */
    unpackFolder(containingFolderPath, depth:="", deleteSubdirectories:=false, allowDuplicateFileNames:=false, useGeneratedContent:=false) {
        if (!fileUtil.pathExists(containingFolderPath)) {
            return
        }
        filePaths:= fileUtil.getFilePathsFromContainingFolder(containingFolderPath, true)
        if (!allowDuplicateFileNames && !fileUtil.isNoDuplicateFileNames(filePaths)) {
            throw this.WARN("unpackFolder: Duplicate file names found.")
        }

        containingFolderName:= fileUtil.getFolderName(containingFolderPath)
        targetFolderPath:= containingFolderPath
        if (useGeneratedContent) {
            targetFolderPath:= generatedContentManager.createFolder(containingFolderName).path
        }

        sourceFolderPaths:= fileUtil.getFolderPathsFromContainingFolder(containingFolderPath, true)

        for i, sourceFilePath in filePaths {
            sourceFileName:= fileUtil.getFileName(sourceFilePath)
            targetFilePath:= targetFolderPath "\" sourceFileName
            if (useGeneratedContent) {
                this.copyFile(sourceFilePath, targetFilePath)
            } else {
                this.moveFile(sourceFilePath, targetFilePath)
            }
        }

        ;we will need to enhance this when we support depth param
        if (deleteSubdirectories) {
            for i, sourceFolderPath in sourceFolderPaths {
                this.deleteFolder(sourceFolderPath, true, true)
            }
        }
    }
}
global fileOps:= new FileOperationsClass() ;@Export fileOps
