#Include %A_LineFile%\..\Constants.ahk
#Include %A_LineFile%\..\..\string\Exports.ahk
#Include %A_LineFile%\..\..\Object\Array.ahk
#Include %A_LineFile%\..\..\Object\HashSet.ahk
#Include %A_LineFile%\..\FileOperations.ahk

/*
    FileUtil.ahk

    Utility functions when working with file and folder paths. Methods are designed to work with environment variables.

    Remarks
        - Filepaths are assumed to have backslashes only, not forward slashes.
        - PSR - Loop, Read, Files is relatively slow. Prefer to cache data that can be computed statically.

    @See Lib\ext\io\FileInfo for working with files in more advanced workflows. FileInfo encapsulates many file related properties, but may be inefficient without proper tuning. It also requires files to exist in the file system. FileUtil may be operating using static path analysis.
*/
class FileUtilClass extends ObjectBase {
    __New() {
        ;cache for functions that operate on static data. (We cant cache fileInfo as it may have changed, but we can cache path and folder segments given a static path)
        this.folderSegmentsCache:= {} ;@Cache 2x performance. Skips Loop, Read, Files on this.isFolder subcall
        ;pathSegmentsCache:= {} ;negligible or worse. 
        this.folderSegmentsCache.SetCapacity(1000)
    }
    
    /*
        isFile/Folder - detect if path is a a file or folder. SplitPath alone does not handle edge case where folder path ends in an extension, like C:\Program Files\Autohotkey\thisisafolder.txt
    */
    isFile(path) {
        path:= ExpandEnvironmentVariables(path)
        isFile:= false
        Loop, Files, %path%, % "F"
        {
            isFile:= true
            break
        }
        return isFile
    }

    /*
        isError

        @return error msg if file not found.

        remarks - we can use FileExist() here because we dont care if it is a file or folder.
    */
    isError(path) {
        path:= ExpandEnvironmentVariables(path)
        if (!FileExist(path)) {
            msg:= "FileNotFound: " path
            return this.DEBUG(msg)
        }
        return
    }

    /*
        isFile/Folder - detect if path is a a file or folder. SplitPath alone does not handle edge case where folder path ends in an extension, like C:\Program Files\Autohotkey\thisisafolder.txt

        Remarks
            - this method identifies the structure of the path, not if it exists or not

        @TODO parameterize if the file needs to exist of filesystem or not. Our existing refs may not need to check file system or are working with paths that dont exist yet, so for now we arent changing anything as
    */
    isFolder(path) {
        path:= ExpandEnvironmentVariables(path)
        if (!InStr(path, ".")) { ;PSR Speedup
            return true
        }
        isFolder:= false
        Loop, Files, %path%, % "D"
        {
            isFolder:= true
            break
        }
        return isFolder
    }

    /*
        isFolderEmpty

        Remarks
            - initial impl considers files only, not sub folders
    */
    isFolderEmpty(folderPath) {
        return (this.getFilePathsFromContainingFolder(folderPath, true,,1).count() < 1)
    }
    
    isAbsolutePath(path, isExpandEnvironmentVariables:=true) {
        if (isExpandEnvironmentVariables) {
            path:= ExpandEnvironmentVariables(path)
        }
        rootSegment:= this.getRootPathSegment(path)
        if (InStr(rootSegment, ":")) {
            return true
        }
    }

    /*
        isDriveMounted

        Detects if drive is mounted for a particular file path. This can be used to validate that a drive is mounted for copy operations where the destination path may not exist yet, and is created by the operation, but will fail if the drive is not mounted.

        @return drive segment, ie. C:
        remarks
            - the drive must have a drive letter associated with it.
            - we are only supporting absolute paths. (Environment variables are ok if they resolve to a full path)
    */
    isDriveMounted(path) {
        path:= ExpandEnvironmentVariables(path)
        rootSegment:= this.getRootPathSegment(path)
        if (InStr(rootSegment, ":")) {
            if (FileExist(rootSegment)) { ;use FileExist instead of this.isFolder because drive root is not reliable for Loop, Read, Files with switch "D"
                return rootSegment
            }
        }
        if (FileExist(A_WorkingDir "\" path)) {
            return this.getRootPathSegment(A_WorkingDir)
        }
        
    }

    /*
        waitForDriveMounted

        @TODO extract this wait timeout strategy into generic timer function, that accepts a funcref
        @return isDriveMounted within timeout
    */
    waitForDriveMounted(filePath, maxTimeoutMillis:=99999999999, timeoutDurationMillis:=50) {
        currentTime:= 0
        while (currentTime < maxTimeoutMillis) {
            if (this.isDriveMounted(filePath)) {
                return true
            }
            Sleep(timeoutDurationMillis)
            currentTime+= timeoutDurationMillis
        }
        return false
    }

    getRootPathSegment(path) {
        path:= ExpandEnvironmentVariables(path)
        return StrSplit(path, "\")[1]
    }

    /*
        getAbsolutePath

        Remarks
            - We are only accounting for paths that have mounted drive root. Not sure but i think this is invalid for network path mappings.
    */
    getAbsolutePath(path) {
        path:= ExpandEnvironmentVariables(path)
        root:= this.getRootPathSegment(path)
        if (InStr(root, ":")) {
            return path
        }
        return A_WorkingDir "\" path
    }

    normalizePathSeparators(path) {
        return StrReplace(path, "/", "\")
    }

    /*
        assertPathExists

        @return filePath, expanded if expandedFilePath:=true
    */
    assertPathExists(filePath, isExpandEnvironmentVariables:=true) {
        fileExists:= this.pathExists(filePath, isExpandEnvironmentVariables)
        if (!fileExists) {
            throw "AssertPathExists: " filePath 
        }
        return filePath
    }

    pathExists(path, isExpandEnvironmentVariables:=true) {
        if (isExpandEnvironmentVariables) {
            path:= expandEnvironmentVariables(path)
        }
        return FileExist(path)
    }

    /*
        filterValidPaths

        Filter all file paths that currently exist, at time of script run

        @param filePaths: Arr
    */
    filterValidPaths(paths) {
        filteredPaths:= []
        for i, path in paths {
            if (this.pathExists(path)) {
                filteredPaths.push(path)
            }
        }
        return filteredPaths
    }

    /*
        assertFilePathsSameFolder

        assert all file paths are in the same folder. throw error if any 2 file paths have a different folder.

        Remarks
            - Currently not expanding paths.
            - We are using Loop,Files for every input file path, this may be slow.
                - each inner loop should only run once, we are using this to get the A_LoopFileDir built in instead of parsing a path using SplitPath or StrSplit.

        @return folderPath, empty if no paths passed.
    */
    assertFilePathsSameFolder(filePaths) {
        folderPath:=
        for i, filePath in filePaths {
            Loop, Files, %filePath%, % "F"
            {
                if (!folderPath) {
                    folderPath:= A_LoopFileDir
                    continue
                }
                if (A_LoopFileDir != folderPath) {
                    throw "AssertFilePathsSameFolder: " A_LoopFileDir " != " folderPath
                }
            }
        }
        return folderPath
    }

    /*
        assertFilePathsSameExtension

        Remarks
            - This method uses fileUtil.getExtension and thereby Loop, Files, which may be inefficient

        @return extension
    */
    assertFilePathsSameExtension(filePaths) {
        extension:=
        for i, filePath in filePaths {
            if (!extension) {
                extension:= this.getExtension(filePath)
                continue
            }
            if (extension != this.getExtension(filePath)) {
                throw "assertFilePathsSameExtension: " extension " != " this.getExtension(filePath)
            }
        }
        return FullFileExtension(extension)
    }

    /*
        assertIsFileNameWithExt

        Assert file name has an extension. This is a stopgap to prevent files from being created without extensions, when file name may come from user input.

        Remarks
            - Do not use this method if you are expecting a specific fileName or ext, as it only asserts a filename has an extension, not what the extension is.
            - Using naive logic for checking is extension, just the existence of a single period char. Not checking registry for extensions as we may be creating a file with no filetype associated with it.
            - Support file names with multiple periods in it
                - It becomes ambigous if last segment after last period is ext or not. Assume that it is. Current usecase does not produce
                filenames with periods in them.

        @param fileName
        @param defaultFileExtension - default file extension to add IFF fileName has no periods. Not handling ambigous case where file name has periods in it besides the extension.
        @param strict - should we throw error if fileName has no extension. otherwise, use defaultFileExtension.
        @param isEndInPeriodIsError - throw error if last char ends in a period, even if strict is off. This should be enabled when the user wants to prevent the default file extension from being used, especially in the case of concatting path segments where an extension might end up empty.
        @return existing fileName or updated file name if default Extension was added.
    */
    assertIsFileNameWithExt(fileName, defaultFileExtension:=".txt", strict:=false, isEndInPeriodIsError:=true) {
        periodCount:= StrCountMatches(fileName, ".")
        lastChar:= SubStrRight(fileName, 1)
        if (strict && (periodCount < 1 || lastChar = ".")) {
            throw A_ThisFunc " invalid FileNameWithExt: " fileName
        }
        if (isEndInPeriodIsError && lastChar = ".") {
            throw A_ThisFunc " invalid FileNameWithExt: " fileName " passed a value ending in period. Did you mean to input an extension? The default fallback extension will not be used."
        }
        if (periodCount = 0) {
            fileName.= (lastChar = ".") ? RawFileExtension(defaultFileExtension) : FullFileExtension(defaultFileExtension)
        }
        return fileName
    }
    
    isNoDuplicateFileNames(filePaths) {
        set:= new HashSet()
        for i, filePath in filePaths {
            if (set.contains(filePath)) {
                return false
            }
            set.add(filePath)
        }
        return true
    }
    /*
        getFilePathsFromContainingFolder

        @PSR consider using taskperformer or create c++ dll that can do this as we seem to be cpu bound, especially with multiple exclude patterns
    */
    getFilePathsFromContainingFolder(folderPath, recurse:=false, extension:="", limit:="", excludePatterns:="") {
        folderPath:= ExpandEnvironmentVariables(folderPath) "\*"
        if (extension) {
            folderPath.= extension
        }
        filePaths:= []
        mode:= "F"
        if (recurse) {
            mode.= "R"
        }
        Loop, Files, %folderPath%, %mode%
        {
            if (limit != "" && (A_Index > limit)) {
                break
            }
            filePaths.push(A_LoopFileFullPath)
        }
        if (excludePatterns) {
            filePaths:= this.filterFilePathsByExcludePattern(filePaths, excludePatterns)
        }
        return filePaths
    }

    findFirstFile(folderPath, recurse:=false, extension:="") {
        return this.getFilePathsFromContainingFolder(folderPath, recurse, extension, 1)[1]
    }

    folderHasAnyFiles(folderPath, recurse:= true, extension:="") {
        return (this.findFirstFile(folderPath, recurse, extension) != "")
    }

    /*
        getFolderPathsFromFilepaths

        @return folderPaths type:ArrayBase<folderPath>
    */
    getFolderPathsFromFilepaths(filePaths) {
        folderPaths:= new HashSet()
        for i, filePath in filePaths {
            folderPath:= this.getFolderPathFromFilePath(filePath)
            folderPaths.add(folderPath)
        }
        return folderPaths.toArray()
    }

    /*
        getFolderPathsFromContainingFolder

        @param folderPath
        @param recurse:=false
        @param isSortNumericPrefix - sort based on numeric value and not lexicographical ordering. If numbers are not padded, then the file paths wont be integer order. eg. 10 will come before 1.
    */
    getFolderPathsFromContainingFolder(folderPath, recurse:=false, isSortFolderNameNumericPrefix:=false) {
        folderPath:= ExpandEnvironmentVariables(folderPath) "\*"
        folderPaths:= []
        ops:= "D"
        if (recurse) {
            ops.= "R"
        }
        Loop, Files, %folderPath%, %ops%
        {
            folderPaths.push(A_LoopFileFullPath)
        }
        if (isSortFolderNameNumericPrefix) {
            folderPaths:= this.sortFolderNameNumericPrefix(folderPaths)
        }
        return folderPaths
    }

    /*
        getFolderNamesFromContainingFolder
    */
    getFolderNamesFromContainingFolder(folderPath, recurse:=false, isSortFolderNameNumericPrefix:=false) {
        folderPaths:= this.getFolderPathsFromContainingFolder(folderPath, recurse, isSortFolderNameNumericPrefix)
        folderNames:= []
        for i, folderPath in folderPaths {
            folderNames.push(this.getFolderName(folderPath))
        }
        return folderNames
    }

    /*
        sortFolderNameNumericPrefix

        @param folderPaths
    */
    sortFolderNameNumericPrefix(folderPaths) {
        sorted:= []
        mapByPrefix:= []
        for i, str in folderPaths {
            folderName:= fileUtil.getFolderSegments(str).peek()
            prefix:= StrGetNumericPrefix(folderName)
            if (!IsObject(mapByPrefix[prefix])) {
                mapByPrefix[prefix]:= []
            }
            mapByPrefix[prefix].push(str)
        }
        for prefix, list in mapByPrefix {
            for j, str in list {
                sorted.push(str)
            }
        }
        return sorted
    }

    /*
        sortFilePathNumericPostfix

        @param filePaths
        @param mode - is the numeric postfix being sourced from the fileNameNoExt, or extension. allowed values ["fileNameNoExt", "extension"]
    */
    sortFilePathNumericPostfix(filePaths, mode:="fileNameNoExt") {
        sorted:= []
        mapByPostfix:= []
        for i, filePath in filePaths {
            postfixSource:= ""
            if (mode = "fileNameNoExt") {
                postfixSource:= this.getFileNameNoExt(filePath)
            } else if (mode = "extension") {
                postfixSource:= this.getExtension(filePath, true)
            } else {
                throw this.WARN("SortFilepathNumericPostfix: invalid mode. Gave: " mode)
            }
            postfix:= StrGetNumericPostfix(postfixSource)
            if (!IsObject(mapByPostfix[postfix])) {
                mapByPostfix[postfix]:= []
            }
            mapByPostfix[postfix].push(filePath)
        }
        for postfix, list in mapByPostfix {
            for j, filePath in list {
                sorted.push(filePath)
            }
        }
        return sorted
    }

    /*
        getFolderSegments

        Get parent folder segments. If input path is a folder, start at the current folder. If file, use the containing folder
        
        @return arr[] of path segments (folder), *Top Down* path of C:\Users\Bob\Pictures\2022 would return ["C:", "Users", "Bob", "Pictures", "2022"]

        Remarks - environment variables are expanded in the output.
    */
    getFolderSegments(path) {
        if (this.folderSegmentsCache[path]) {
            return this.folderSegmentsCache[path]
        }
        path:= ExpandEnvironmentVariables(path)
        folderPath:= this.getFolderPath(path)
        segments:= []
        segments.addAll(StrSplit(folderPath, "\"))
        this.folderSegmentsCache[path]:= segments
        return segments
    }

    /*
        getParent

        Remarks
            - Only supported for file paths that exist (as we use fileUtil.isFolder)
    */
    getParent(folderPath) {
        folderSegments:= this.getFolderSegments(folderPath)
        folderSegments.pop()
        return folderSegments.join("\")
    }

    /*
        getFolderName

        Get last folder path segment
    */
    getFolderName(fileOrFolderPath) {
        folderSegments:= this.getFolderSegments(fileOrFolderPath)
        if (folderSegments.count() > 0) {
            return folderSegments.peek()
        }
    }

    /*
        getFilePath

        Identity function that can throw an error on passing an invalid path (not exists on filesystem). This function is usually redundant but can be used as a target for CopyPathComponent script.
    */
    getFilePath(filePath, strict:=true) {
        if (!this.isFile(filePath)) {
            ;return ;TODO come up with solution for paths that dont exist. we should be operating on static path syntax.
        }
        return filePath
    }
    
    getFileName(filePath) {
        if (!this.isFile(filePath)) {
            ;return ;TODO come up with solution for paths that dont exist. we should be operating on static path syntax.
        }
        return this.getPathSegments(filePath).peek()
    }

    getFileNameNoExt(filePath, strict:=true) {
        if (strict) { ;@PSR needed.
            return StrGetBeforeLastIndexOf(this.getFileName(filePath), ".")
        }
        ;Old method, not reliable. Keeping in case we know ahead of time if file names have periods. May be some performance gains to be had.
        return StrSplit(this.getFileName(filePath), ".")[1]
    }

    /*
        getPathSegments

        Get all path segments. if path is a folder, this method returns the same as getFolderSegments. If file, it includes folder segments + fileNameWithExt
        
        @return arr[] of path segments, *Top Down*

        Remarks - environment variables are expanded in the output.
    */
    getPathSegments(path) {
        path:= ExpandEnvironmentVariables(path)
        segments:= []
        segments.addAll(StrSplit(path, "\"))
        return segments
    }

    getLeadingPathSegment(path) {
        path:= ExpandEnvironmentVariables(path)
        segments:= StrSplit(path, "\")
        return segments[1]
    }

    /*
        getFolderPaths

        @TODO rename
        Get folder paths from root drive to current folder.

        @param path - file or folder. if file, use containing folder. If folder, start at current folder
        @param topDownSort - sort order. by default sort is from root to folder, but you can pass false to sort from folder to root.
        @param relativeMode type:Boolean controls if we add an empty string representing the A_WorkingDir relative filePath
        @return hierarchy - arr[]
    */
    getFolderPaths(path, topDownSort:=true, relativeMode:=false) {
        path:= ExpandEnvironmentVariables(path)

        folderPath:= this.getFolderPath(path)

        split:= StrSplit(folderPath, "\")
		hierarchy:= []
		while (split.count() > 0) {
            if (topDownSort) {
                hierarchy.insertAt(1, CombineArray(split, "\")) ;inefficent array insert, but max path size should not be sufficiently large
            } else {
                hierarchy.push(CombineArray(split, "\"))
            }
			split.pop()
		}
        if (relativeMode && !this.isAbsolutePath(path)) {
            insertIdx:= (topDownSort) ? 1 : hierarchy.MaxIndex() + 1
            hierarchy.insertAt(insertIdx, "")
        }
		return hierarchy
    }

    /*
        getFolderPathAfterPrefix

        Combination of StrGetAfterFirstIndexOf() plus removing leading slash from the remaining path segment. We need to handle the edge case of the path = prefix
        @return subPath, where subPath does not have a leading slash
    */
    getFolderPathAfterPrefix(path, prefix) {
        if (path = prefix) {
            return ""
        }
        return StrGetAfterFirstIndexOf(path, prefix "\")
    }
    isPathDescendant(testPath, ancestor) {

    }

    /*
        appendValueToFileName

        Append a value to fileName portion. This abstracts the need to split the path and inject before the extension.

        Remarks - folders are supported.
        
        @param path
        @param postfix
        @param prefix
    */
    appendValueToFileName(path, postfix:="", prefix:="") {
        SplitPath(path,, dir, extension, nameNoExt)
        return dir "\" prefix nameNoExt postfix ((extension) ? "." extension : "")
    }

    /*
        getFolderPath
        
        Get folder or containing folder. If path is file, gets containing folder. if path is folder, return itself.

        Remarks
            - output path will be expanded
            - split path is unreliable - use isFolder which accurately detects if a leaf folder ends in ".txt" or a valid extension
    */
    getFolderPath(path) {
        if (this.isFolder(path)) {
            return path
        }
        path:= ExpandEnvironmentVariables(path)
        SplitPath(path,, dir)
        return dir
    }

    /*
        getFolderPathFromFilePath

        Performant method of getFolderPath that skips check for isFolder. Use only when knowing all input paths are file paths.

        This method is recommended when performance is required, or processing a large amount of files.

        @PSR observed a 30x speedup with 250 file paths (short relative paths). 0.5ms vs 17ms. This is expected as we skip a Loop, Read, Files construct which is known to be slow.

        @param filePath
    */
    getFolderPathFromFilePath(filePath) {
        filePath:= ExpandEnvironmentVariables(filePath)
        SplitPath(filePath,, dir)
        return dir
    }

    /*
        getExtension

        @param filePath
        @param strict - should we use loopfiles or StrSplit. Strict mode requires file to be a valid file. Default to true as existing workflows are dependent on this method not returning an extension for a folder path whos last path segment ends in a extension.
        @return extension - reutrns raw file extension. See StringUtils Full/RawFileExtension methods if caller may be passing both.

        Remarks
            - We use file loop as SplitPath() is invalid for folders, if the last folder path segment ends in an extension.
            - We do not validate extension. See ext\registry for methods to validate if the file extension is valid and registered in your OS.
    */
    getExtension(filePath, strict:=true, isFullFileExtension:=false) {
        if (!strict) {
            extension:= StrSplit(filePath, ".").pop()
            if (!extension) {
                return ""
            }
            return (isFullFileExtension) ? FullFileExtension(extension) : extension
        }
        filePath:= ExpandEnvironmentVariables(filePath)
        isFile:= false
        Loop, Files, %filePath%, % "F"
        {
            return (isFullFileExtension) ? ("." A_LoopFileExt) : A_LoopFileExt
        }
    }

    /*
		creates parent folders for a file, if necessary. File move will fail if directory does not exist already, so create folders when needed

        Remarks
            - this is designed for filePaths, but will work to create a folder, although it will create the input folder and not a folder's containing folder.
        
        @return containingFolderPath
	*/
	createContainingFolder(filePath) {
		containingFolder:= this.getFolderPath(filePath)
		if (!FileExist(containingFolder)) {
            logger.DEBUG("[FileUtil] ~ createContainingFolder ~ " containingFolder)
			DirCreate(containingFolder)
		}
        return containingFolder
	}

    /*
        ExpandAhkVariables

        Similar to ExpandEnvironmentVariables for path expansion. Expand items between percents, that start with "A_"
    */
    expandAhkBuiltInVariables(path) {
        while (InStr(path, "%")) {
            variable:= StrExtractBetween(path, "%", "%", false, true)
            if (variable && InStr(variable, "A_") = 1) {
                value:= %variable%
                if (InStr(value, "%")) {
                    throw "ExpandAhkBuiltInVariables Failsafe. Built in variable had % sign which would cause infinite regression with naive algorithm."
                }
                path:= StrReplace(path, "%" variable "%", value,,1)
            } else {
                throw "ExpandAhkBuiltInVariables - only ahk built ins are supported."
            }
        }
        return path
    }

    /*
        ExpandPath

        Enhanced method that expands environment variables, but also Ahk built ins. This allows us to pass paths relative to our working directory within script config, irrespective of where the script config file is defined. (You could use relative paths, but it would only work if the ahk scripts are inside the autohotkey directory, and the same level of nesting. This would be unreliable.

        Remarks: EnvironmentVariables given a preference over ahk built ins.
    */
    expandPath(path) {
        path:= ExpandEnvironmentVariables(path)
        path:= this.expandAhkBuiltInVariables(path)
        return path
    }

    /*
        getDestinationForWrite

        This method sets the source and destination for a write action that accepts a filepath and writes to a file path.

        @param source - path
        @param destination - path
        @param inplace - default false
        @param destinationNameAddtion - default Copy
        @return destination

        It handles the following cases:
            Source and Destination are known
            Destination is missing
                Inplace? Write to source file
                Else - Copy file
                    Copy file to same directory with default filename, or pass destinationNameAddtion for postfix on filename
    */
    getDestinationForWrite(ByRef source, ByRef destination:="", inPlace:=false, destinationNameAddition:="Copy") {
        source:= ExpandEnvironmentVariables(source)
        destination:= ExpandEnvironmentVariables(destination)
        if (!destination) {
            destination:= (inPlace) ? source : fileOps.copyFile(source,,true, destinationNameAddition)
        }
        return destination
    }

    /*
        insert or replace extension in filepath. Caller can pass a file path segment without a valid file path.
        @param filePath - full or partial file path, with or without .ext
        @param ext - extension, with or without leading period.
    */
    replaceExtension(filePath, extension) {
        pathSegments:= this.getPathSegments(filePath)
        lastSegment:= pathSegments[pathSegments.MaxIndex()]
        if (InStr(lastSegment, ".")) {
            return StrSplit(filePath, ".",,2)[1] FullFileExtension(extension)
        }
        return filePath
    }

    replaceFileNameNoExt(filePath, fileNameNoExt) {
        pathSegments:= this.getPathSegments(filePath)
        lastSegment:= pathSegments.peek()
        fileNameSplit:= StrSplit(lastSegment, ".")
        extension:=fileNameSplit[2]
        folderPath:= this.getFolderPath(filePath)
        return folderPath "\" fileNameNoExt "." extension
    }

    /*
        relativePath

        Assert path is relative path. This is done by stripping off any leading slashes.

        Usecase:
            concat paths, where the leading path segment may be empty. This might occur if you are referencing A_WorkingDir or any logical path hierarchy root.

        Remarks
            - This method is safe to call on absolute file paths that start with a drive letter. The absolute path is returned.
                - This can be used to get a relative or absolute file path when the leading path segment could be empty string (A_WorkingDir) OR something that starts with a drive letter.
            - This method might be inefficent due to the caller concat'ing the result with another slash
            - This method does not validate that the path is actually a relative path. (ie. it starts with a drive letter)
    */
    relativePath(path) {
        char:= CharAt(path, 1)
        if (char = "\" || char = "/") {
            return SubStr(path, 2)
        }
        return path
    }

    /*
        relativePathFromWorkspaceRoot

        Get relative path after @param workspaceRoot.

        Example:
            WorkspaceRoot: "C:\toolkit\Autohotkey"
            FilePath: "C:\toolkit\Autohotkey\Lib\ext\io\FileUtil.ahk"
            @return filePath "Lib\ext\io\FileUtil.ahk"
    */
    relativePathFromWorkspaceRoot(workspaceRoot, filePath) {
        return fileUtil.relativePath(StrGetAfterFirstIndexOf(filePath, workspaceRoot))
    }

    /*
        replaceWorkspaceRoot

        Update file paths in a workspace/hierarchy to a new one. Each new path will have the targetWorkspaceRoot + relativePathFromWorkspace relative to the sourceWorkspaceRoot.

        @param strict - should we throw an error if any sourceFilePath is not a subpath of sourceWorkspaceRoot
        @param isExpandEnvironmentVariables(default:=False) for @PSR concerns, workspace may be potentially large. If source input files are retrieved from fileUtil.getFilePathsInContainingFolder() then they will already be expanded anyways.
    */
    replaceWorkspaceRoot(sourceFilePaths, sourceWorkspaceRoot, targetWorkspaceRoot, strict:=true, isExpandEnvironmentVariables:=false) {
        if (isExpandEnvironmentVariables) {
            sourceWorkspaceRoot:= ExpandEnvironmentVariables(sourceWorkspaceRoot)
            targetWorkspaceRoot:= ExpandEnvironmentVariables(targetWorkspaceRoot)
        }
        targetFilePaths:= []
        for i, filePath in sourceFilePaths {
            if (isExpandEnvironmentVariables) {
                filePath:= ExpandEnvironmentVariables(filePath)
            }
            if (!StrStartsWith(filePath, sourceWorkspaceRoot)) {
                if (strict) {
                    throw this.WARN("ReplaceWorkspaceRoot: Source file path {1} is not under {2}", filePath, sourceWorkspaceRoot)
                }
                continue
            }
            relativePath:= this.relativePathFromWorkspaceRoot(sourceWorkspaceRoot, filePath)
            targetFilePath:= this.relativePath(targetWorkspaceRoot "\" relativePath)
            targetFilePaths.push(targetFilePath)
        }
        return targetFilePaths
    }
    /*
        getOptionalFolderSegmentWithLeadingSeparator

        Get a partial path segment, when concatentating a variable that may produce an empty path segment. This avoids appending an extra path separator causing an invalid path, like below:
            ahk code:
                targetFolderName:= "" ;target folder name may be blank or a string value
                "C:\apps" "\" targetFolderName
            
            if targetFolderName is blank, you get "C:\apps\\" which is invalid.

        Usecase:
            - hierarchical path structure, where the root node may have no additional path segment.
    */
    getOptionalFolderSegmentWithLeadingSeparator(folderPathSegment) {
        return (folderPathSegment = "") ? "" : "\" folderPathSegment
    }

    /*
        getOptionalFolderSegmentWithTrailingSeparator

        This method is similar to getOptionalFolderSegmentWithLeadingSeparator. This should be used when the "root" is known. It answers the query "I know I am the root but dont known if there are any sub folders". Compare to leading separator which answers "I know I am in a sub folder but dont know if I am the root"
    */
    getOptionalFolderSegmentWithTrailingSeparator(folderPathSegment) {
        return (folderPathSegment = "") ? "" : folderPathSegment "\"
    }

    getOptionalLeadingSeparator(folderPathSegment) {
        return (folderPathSegment = "") ? "" : "\"
    }

    /*
        GetWorkspacePath

        Get a workspacePath from a current path. The workspace path will be an ancestor path of the current path, if it exists.

        Goals:
            - Transform a path into a workspace path, without knowing the exact name of the workspace segment. We pass a regex value instead. This is ideal for workspaces that have a slightly different name or version number, but contain the same sub directory structure.

        Remarks: we use simple substring match, not leading common subsequence
            - This may not work with workspaces with partial path segments that contain the regex, that are deeper in the path hierarchy than the workspace.
    */
    getWorkspacePath(currentPath, workspaceRegex, workspaceContainingFolder) {
        if (!workspaceRegex) {
            return workspaceContainingFolder
        }
        currentPathFolderSegments:= this.getFolderSegments(currentPath)

        workspacePath:= ""

        while (currentPathFolderSegments.count() > 0) {
            pathSegment:= currentPathFolderSegments.Pop()
            if (InStr(pathSegment, workspaceRegex)) {
                parentPath:= CombineArray(currentPathFolderSegments, "\")
                if (workspaceContainingFolder) {
                    if (workspaceContainingFolder = parentPath) {
                        workspacePath:= parentPath "\" pathSegment
                    }
                } else {
                    continue
                }
                workspacePath:= parentPath "\" pathSegment
                return workspacePath
            }
        }
        return workspacePath
    }

    /*
        FindFileInPathHierarchy

        For a given path, search the current folder paths for a filename, bottom up. This could be used to locate a property file in a parent directory, if it is not in the current directory.
    */
    findFileInPathHierarchy(path, fileName) {
        folderPaths:= this.getFolderPaths(path, false, true) 
        for i, path in folderPaths {
            candidatePath:= fileUtil.getOptionalFolderSegmentWithTrailingSeparator(path) fileName
            if (FileExist(candidatePath)) {
                return candidatePath
            }
        }
    }

    /*
        injectTrailingFolderSegment

        Inject a trailing folder segment. This is useful for exploding files into multiple files based off the original file, where each new file can be put in a separate folder, adjacent to the original file.

        Works for files or folders.
    */
    injectTrailingFolderSegment(path, relativePathSegment) {
        pathSegments:= this.getPathSegments(path)
        
        relativePathSegment:= this.relativePath(relativePathSegment) ;assert no leading slash
        folderPath:= this.getFolderPath(path)
        if (relativePathSegment) {
            folderPath.= "\" relativePathSegment
        }
        newPath:= folderPath
        if (this.isFile(path)) {
            newPath.= "\" pathSegments[pathSegments.MaxIndex()]
        }
        return newPath
    }

    stripTrailingFolderSegment(fileOrFolderPath) {
        pathSegments:= this.getPathSegments(fileOrFolderPath)
        folderSegments:= this.getFolderSegments(fileOrFolderPath)
        folderSegments:= folderSegments.clone()
        folderSegments.pop()
        
        newPath:= CombineArray(folderSegments, "\")
        if (this.isFile(fileOrFolderPath)) {
            newPath.= "\" pathSegments[pathSegments.MaxIndex()]
        }
        return newPath
    }

    getFileNameNoExtNumericPostfix(filePath) {
        fileNameNoExt:= this.getFileNameNoExt(filePath)
        numericPostfix:= StrGetNumericPostfix(fileNameNoExt)
        return numericPostfix
    }

    /*
        getUniqueFileName

        Get suitable unique name

        Format: FileNameNoExt yyyy-MM-dd HHmmss_{ScriptPID}-{ScriptConfig ScriptLocalMonotonicSeq}
            - Note that ScriptLocalMonotonicSeq does not reset based on date time.
    */
    getUniqueFileName(fileNameWithExt) {
        if (!IsObject(scriptConfig)) {
            throw A_ThisFunc " depends on ScriptConfig to get ScriptLocal Unique ID"
        }
        uniqueId:= scriptConfig.getDateTimeUniqueId()
        
        splitFileName:= StrSplit(fileNameWithExt, ".")
        fullFileExtension:= "." splitFileName.pop()
        fileNameNoExt:= CombineArray(splitFileName, ".")
        fileName:= fileNameNoExt " " uniqueId fullFileExtension ;this could be a relative path if fileNameWithExt is passed with leading relative path.
        return fileName
    }

    /*
        getUniqueRelativeFolderPath
        
        @param relativePath
        @param uniqueIdIsAppend - should we append unique id to the relative path, or add it as an extra path segment.
            eg relative path is "shellscripts\powershell"
                should it be shellscripts\powershell 2023-01-01 <- uniqueIdIsAppend:=true
                or,          shellscripts\powershell\203-01-01 <- uniqueIdIsAppend:=false
    */
    getUniqueRelativeFolderPath(relativeFolderPath, uniqueIdIsAppend:=true) {
        if (!IsObject(scriptConfig)) {
            throw A_ThisFunc " depends on ScriptConfig to get ScriptLocal Unique ID"
        }
        uniqueId:= scriptConfig.getDateTimeUniqueId()

        ;user may have passed empty string, if they are working with some root workspace + relative path and they are referencing files that are in the workspace root.
        if (!relativeFolderPath) {
            return uniqueId
        }
        joinCharSequence:= (uniqueIdIsAppend) ? " " : "\"
        relativeFolderPath:= relativeFolderPath joinCharSequence uniqueId
        relativeFolderPath:= this.relativePath(relativeFolderPath)
        return relativeFolderPath
    }

    /*
        getExplorerSelectVerb

        Get explorer verb, for opening a folder in explorer, or opening a file and selecting it in its containing folder.

        Remarks
            - "/select," arg for files must have the comma otherwise it will not work (It will open window to user's documents folder)

        @param path
        @param strict - validate drive mounted, file exists
        @param isExpandEnvironmentVariables:default true. Explorer needs environment variables to be expanded if running directly via Run(path). This is recommended. Send false if you would like to keep environment variables, caller is responsible for expanding them.
            - cmd and registry/context menu can expand variables. Leaving it up to the caller to leave them unexpanded if you want to save it that form in a context menu.
        @return explorer verb
            Folders: explorer "C:\apps\folder"
            Files  : explorer /select, "C:\apps\folder\file.txt"
    */
    getExplorerSelectVerb(path, strict:=true, isExpandEnvironmentVariables:=true) {
        expanded:= ExpandEnvironmentVariables(path)
        if (strict) {
            if (!FileExist(expanded)) {
                throw this.WARN("GetExplorerSelectVerb: file does not exist")
            }
        }

        if(!strict) {
            throw this.WARN("GetExplorerSelectVerb: strict mode is required, until fileUtil.isFile strict param is implemented. Current implementation requires file to exist, to properly assert path is a file due to SplitPath returning an incorrect file path if the last folder path segment of a folder ends in a valid extension.")
        }

        path:= (isExpandEnvironmentVariables) ? expanded : path
        isFile:= this.isFile(path)
        explorerVerb:= (isFile) ? "explorer /select," : "explorer"
        explorerVerb.= " """ path """"
        return explorerVerb
    }

    openPathInExplorer(path) {
        path:= ExpandEnvironmentVariables(path)
        if (!FileExist(path)) {
            return
        }
        explorerSelectVerb:= this.getExplorerSelectVerb(path)
        pid:= Run(explorerSelectVerb)
        return pid
    }

    /*
        getFilesPathsModifiedAfterDate

        Get files modified after date from containing folder. Combine with fileOps.copyPathsInHierarchyToFolder() to export 
        @param folderPath
        @param date
        @param recurse default:=true
        @param extension
        @param limit
        @param excludePatterns - relative path patterns from folderPath to exclude
    */
    getFilesPathsModifiedAfterDate(folderPath, date, recurse:=true, extension:="", limit:="", excludePatterns:="") {
        filePaths:= this.getFilePathsFromContainingFolder(folderPath, recurse, extension, limit, excludePatterns)
        filteredFilePaths:= this.filterFilePathsModifiedAfterDate(filePaths, date)
        return filteredFilepaths
    }

    filterFilePathsByExcludePattern(filePaths, excludePatterns:="") {
        excludePatterns:= ArrDefault(excludePatterns)
        if (excludePatterns.count() < 1) {
            return filePaths
        }
        filteredFilePaths:= []
        for i, filePath in filePaths {
            matched:= false
            for j, excludePattern in excludePatterns {
                if (StrStartsWith(filePath, excludePattern)) {
                    matched:= true
                    break
                }
            }
            if (!matched) {
                filteredFilePaths.push(filePath)
            }
        }
        return filteredFilePaths
    }
    filterFilePathsModifiedAfterDate(filePaths, date) {
        filteredFilePaths:= []
        for i, filePath in filePaths {
            modifiedDate:= fileAttributeUtil.getModifiedTime(filePath)
            if (modifiedDate.greaterThan(date)) {
                filteredFilePaths.push(filePath)
            }
        }
        return filteredFilepaths
    }

    getExcludePatternsFromRelativePath(containingFolder, relativeExcludePatterns) {
        excludePatterns:= []
        for i, relativeExcludePattern in relativeExcludePatterns {
            excludePatterns.push(containingFolder "\" relativeExcludePattern)
        }
        return excludePatterns
    }

    /*
        partitionFilesByFolderPath

        Get File paths by folder path. Underlying methods use Loop, Read, Files - so the files must exist on the file system.
        @return filePathsByFolderPath Object{folderPath,[filepaths]}
    */
    partitionFilesByFolderPath(containingFolderPath, limit:="") {
        folderPaths:= this.getFolderPathsFromContainingFolder(containingFolderPath)
        filePathsByFolderPath:= {}
        for i, folderPath in folderPaths {
            filePaths:= this.getFilePathsFromContainingFolder(folderPath, false,, limit)
            filePathsByFolderPath[folderPath]:= filePaths
        }
        return filePathsByFolderPath
    }

    /*
        getAdjacentFile

        Get adjacent file of @paramFileOrFolderPath.

        @param fileOrFolderPath
        @param fileName - fileNameWithExt
        @param isFolderContainingFolder - default true. If true, then giving a folder path will search for the file within the folder path instead of adjacent to it. Usecase - locate a property file that is within a folder or adjacent to file, for some action that accepts file or folder paths (ie rclone)
        @return filePath
    */
    getAdjacentFile(fileOrFolderPath, fileName, isFolderContainingFolder:=true) {
        fileOrFolderPath:= ExpandEnvironmentVariables(fileOrFolderPath)
        isFolder:= this.isFolder(fileOrFolderPath)
        folderPath:= this.getFolderPath(fileOrFolderPath)
        if (isFolder && !isFolderContainingFolder) {
            folderPath:= this.stripTrailingFolderSegment(folderPath)
        }
        return folderPath "\" fileName
    }

    /*
        convertPathToFileSegment

        Convert a path to a file segment. Parameters for including x number of ancestor paths from root, or by total length.

        Usecase:
            - Supply a sufficient folder name for generated content based on some source folderPath, where the folderName may be generic and we want to give more info.

        Implementation notes:
            - slashes will be converted to underscores.

        @param maxPathSegments - By default, use only the first path segment (folder or fileName). Pass as sufficiently large number or empty to specify unlimited path segments.
        @param trimUserLocationPrefixes
    */
    convertPathToFileSegment(path, maxPathSegments:= 1, maxPathLength:= 255, trimUserLocationPrefixes:=true) {
        path:= this.trimUserLocationPrefixes(path)

        pathSegments:= fileUtil.getPathSegments(path)
        pathToSegmentConverters.shortenJavaPackage(path, pathSegments)

        pathSegmentReplaceChar:= "~"
        path:= StrReplace(path, "\", pathSegmentReplaceChar)
    }

    /*
        trimUserLocationPrefixes

         Files in user home will be limited so the full path isnt shown. ie. if a file is in C:\users\user1\Downloads\reports, the path segment would return Downloads\reports assuming maxPathLength/maxPathSegments is configured to allow it.
            - Supports %USERPROFILE%, %ProgramFiles%, %ProgramFiles(x86)%

        @TODO @PSR - add param for cache so we avoid repeated lookups of environment variables
    */
    trimUserLocationPrefixes(path) {
        prefixes:=[]
        envNames:= ["USERPROFILE", "PROGRAMFILES", "PROGRAMFILES(x86)"]
        prefixes.addAll(environment.getEnvironmentVariablesByNames(envNames))

        path:= StrGetAfterFirstIndexOfAny(path, prefixes)
        path:= this.relativePath(path)
        return path
    }

    /*
        getPathSegmentIdx

        @param searchStr - search entire path segment, not regex.
    */
    getPathSegmentIdx(pathSegments, searchStr) {
        return pathSegments.contains(searchStr) ;using arraybase contains for now, could be expanded to search partial segment match.
    }

    /*
        locateFolder

        Locate folder based on multiple search locations, and resolution strategies.

        @TODO use FolderBrowerDialog if none found. Add a button to ButtonInputBox to prompt a dialog if multiple found (Add to end of list)
        
        @param testContainingFolderPaths str or array of containingFolderPaths.
        @param matchStrategy - See StringUtils StrMatchesByStrategy fn
        @return folderPath
    */
    locateFolder(testContainingFolderPaths, testPattern, matchStrategy:="InStr") {
        testContainingFolderPaths:= ArrDefault(testContainingFolderPaths)
        testFolderPaths:= []
        folderPathMatches:= []
        for i, testContainingFolderPath in testContainingFolderPaths {
            testFolderPaths.addAll(this.getFolderPathsFromContainingFolder(testContainingFolderPath, false))
        }
        for i, testFolderPath in testFolderPaths {
            folderName:= this.getFolderName(testFolderPath)
            if (StrMatchesByStrategy(folderName, testPattern, matchStrategy)) {
                folderPathMatches.push(testFolderPath)
            }
        }
        if (folderPathMatches.count() < 2) {
            return folderPathMatches[1]
        }
        if (!ButtonInputBoxClass) {
            throw this.WARN("locateFolder: Produced more than 2 paths but ButtonInputBoxClass is not added to classpath.")
        }
        buttonInputBox:= new ButtonInputBoxClass("LocateFolder" StrReplace(testPattern, " ", "")) ;@TODO add to a gui display label to support special chars
        for i, folderPathMatch in folderPathMatches {
            buttonInputBox.addButton(folderPathMatch, this.trimUserLocationPrefixes(folderPathMatch))
        }
        selectedPath:= buttonInputBox.getChoice()
        return selectedPath
    }

    isFileReadOnly(filePath) {
        attrib:= FileGetAttrib(filePath)
        return (InStr(attrib, "R"))
    }

    /*
        isFileImage

        @return isFileImage type:boolean is file an image, based on common image formats (not exhaustive)
    */
    isFileImage(filePath) {
        extension:= this.getExtension(filePath)
        return (["png", "jpg", "bmp", "jpeg"].contains(extension))
    }
}

class PathToSegmentConverterClass extends ObjectBase {
    __New() {
        this.converters:= [] ;list of fn's that will attempt to 
    }
    registerConverterFunction(boundFunc, priority:="") {

    }
}
class PathToSegmentConverterLibraryClass extends ObjectBase {
    trimUserLocationPrefixes(path, pathSegments) {
        
    }

    shortenJavaPackage(ByRef path, ByRef pathSegments) {
        comIdx:= fileUtil.getPathSegmentIdx(pathSegments, "com")
        if (!comIdx) {
            return path
        }
        startIdx:= comIdx
        endIdx:= comIdx + 3
        if (InStr(pathSegments[comIdx - 1], "-src")) {
            startIdx-= 1
        }
        newName:= "..java.."
        pathSegments:= pathSegments.splice(startIdx - 1, endIdx - startIdx, newName)
        path:= pathSegments.join("\")
    }

    
}
global pathToSegmentConverters:= new PathToSegmentConverterLibraryClass() ;@Export pathToSegmentConverters
class PathToSegmentConverterCacheClass extends ObjectBase {
    __New() {
        environmentVariableCache:= 
    }
}

global fileUtil:= new FileUtilClass() ;@Export fileUtil

FileGetKiloBytes(filePath) {
    return FileGetSize(filePath, "K")
}

/*
    FileGetMegaBytes

    Remarks
        - size is rounded down to nearest Unit.
*/
FileGetMegaBytes(filePath) {
    return FileGetSize(filePath, "M")
}
