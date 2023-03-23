#Include %A_LineFile%\..\..\date\Exports.ahk
#Include %A_LineFile%\..\..\io\FileWriter.ahk
#Include %A_LineFile%\..\..\io\FileUtil.ahk
#Include %A_LineFile%\..\..\io\FileOperations.ahk
#Include %A_LineFile%\..\..\object\HashSet.ahk

/*
    GeneratedContent

    Generated Content keeps track of generated resources by scripts that can either be archived or deleted based on Policy in ScriptConfig. It defines a pattern to generate unique file names based off of an input pattern that may not be unique.

    Usecase:
        Workflows that generate large .bat or .ps1 scripts, when the arguments reach the max cmd argument path length. These scripts may be kept for debugging purposes. They may also be deleted immediately, on script exit, or on a "keep n latest" basis.

    Remarks
        -  All classes that use generated content are responsible for consuming the generated data before they are deleted. Usually this means within the lifecycle of the currently executing script.
            - If using github project, the default path \generatedcontent is ignored with .gitignore file.
        - SetWorkingDir command should be avoided once ScriptConfig.ahk runs, as we allow relative file paths.
    
    @ScriptConfigExport GeneratedContent - Generated Content
    @ScriptConfigAware
*/
class GeneratedContentManagerClass extends ObjectBase {
    onScriptConfig(ScriptConfig) {
        this.generatedContentFolderPath:= ExpandEnvironmentVariables(ArrUnbox([ScriptConfig.GeneratedContent.GeneratedContentPath, "generatedcontent"]).coalesce())
        this.generatedContentArchivePolicy:= Coalesce(ScriptConfig.GeneratedContent.GeneratedContentArchivePolicy, GeneratedContentArchivePolicyEnum.ARCHIVE)
        
        if (!FileExist(this.generatedContentFolderPath)) {
            DirCreate(this.generatedContentFolderPath)
        }
        this.geneneratedContentsForDelete:= []

        this.pidDisplayValue:= StrPadLeft(ScriptConfig.pid, 6, "0")
        
        ;Create OnExit callback to delete files if policy is delete.
        OnExit(ObjBindMethod(this, "onExit"))
        ;Create scriptconfig prop for "keep the last n number of files"
    }

    /*
        createFile

        Create file with a suitable name

        Format: FileNameNoExt yyyy-MM-dd HHmmss_{ScriptPID}-{ScriptLocalMonotonicSeq}
            - Note that ScriptLocalMonotonicSeq does not reset based on date time.

        @param fileNameWithExt - can be a relative path. Note that this is not the final path, caller should use @return filePath
        @param fileContent - string data to write to file
        @param contentPolicy: GeneratedContentArchivePolicyEnum
            - If "Delete" is passed, file will be deleted on script exit.
            - For immediate deletion, use GeneratedContentClass.dispose method
        @return generatedContentClass
    */
    createFile(fileNameWithExt, fileContent:="", contentPolicy:="", createUniqueFileName:=true) {
        targetFilePath:= this.getTargetFilePathFromFileName(fileNameWithExt)
        fileWriter.write(targetFilePath, fileContent)
        generatedContent:= new GeneratedContentClass(targetFilePath, fileContent)
        this.markGeneratedContentForDeleteIfNeeded(generatedContent, contentPolicy)
        return generatedContent
    }

    /*
        copyFile

        Create generated content file via filecopy of an existing file.

        @TODO copy file name options. For now we use relative path, with path root converted into a folder segment
    */
    copyFile(sourceFilePath, contentPolicy:="", createUniqueFileName:=false) {
        sourceFilePath:= ExpandEnvironmentVariables(sourceFilePath)
        if (!FileExist(sourceFilePath)) {
            throw this.WARN("Copy file sourceFilePath doesnt exist. Gave: {1}", sourceFilePath)
        }
        targetFilePath:= this.getTargetFilePathFromSourceFilePath(sourceFilePath, createUniqueFileName)
        fileOps.copyFile(sourceFilePath, targetFilePath, true)
        generatedContent:= new GeneratedContentClass(targetFilePath, fileContent)
        this.markGeneratedContentForDeleteIfNeeded(generatedContent, contentPolicy)
        return generatedContent
    }

    markGeneratedContentForDeleteIfNeeded(generatedContent, contentPolicy) {
        contentPolicy:= Coalesce(contentPolicy, this.generatedContentArchivePolicy)
        if (contentPolicy = GeneratedContentArchivePolicyEnum.DELETE) {
            this.geneneratedContentsForDelete.push(generatedContent)
        }
    }

    getTargetFilePathFromFileName(fileNameWithExt, createUniqueFileName:=true) {
        fileName:= (createUniqueFileName) ? fileUtil.getUniqueFileName(fileNameWithExt) : fileNameWithExt
        targetFilePath:= this.generatedContentFolderPath "\" fileName
        return targetFilePath
    }

    getTargetFilePathFromSourceFilePath(sourceFilePath, createUniqueFileName:=false) {
        sourceFilePath:= ExpandEnvironmentVariables(sourceFilePath)
        targetFilePath:= this.generatedContentFolderPath "\" fileUtil.relativePath(StrReplace(sourceFilePath, ":", ""))
        return targetFilePath
    }

    /*
        createFolder

        See fileUtil.getUniqueRelativeFolderPath for more details on args
    */
    createFolder(relativePath, uniqueIdIsAppend:=true, createUniqueFolderName:=true) {
        relativeFolderPath:= (createUniqueFolderName) ? fileUtil.getUniqueRelativeFolderPath(relativePath, uniqueIdIsAppend) : relativePath
        folderPath:= this.generatedContentFolderPath "\" relativeFolderPath
        fileUtil.createContainingFolder(folderPath)
        generatedContent:= new GeneratedContentClass(folderPath)
        return generatedContent
    }

    onExit() {
        if (this.generatedContentArchivePolicy = GeneratedContentArchivePolicyEnum.DELETE) {
            for i, generatedContent in this.geneneratedContentsForDelete {
                generatedContent.dispose()
            }
        }
    }
}

/*
    GeneratedContentPath
    
    TODO generated content was not built with folders in mind, but should be able to support them. avoid using Existing refs to "filePath", in favor of "path". Will replace existing refs.
*/
class GeneratedContentClass {
    __New(path, fileContent:="", type:="") {
        ;@Deprecated
        this.filePath:= path

        this.fileContent:= fileContent
        this.path:= path
    }

    /*
        dispose

        @TODO this should support files and folders. Workaround is provided.
    */
    dispose() {
        if (fileUtil.isFile(this.filePath)) {
            fileOps.deleteFile(this.filePath)
        }
    }

    /*
        Reserved Future use
    */
    FromFile(filePath, fileContent) {

    }

    FromFolder(folderPath) {

    }
}
global generatedContentManager:= new GeneratedContentManagerClass() ;@Export generatedContentManager
ScriptConfigClass.RegisterObject(generatedContentManager)

global GeneratedContentArchivePolicyEnum:= {DELETE: "DELETE", ARCHIVE: "ARCHIVE"}
