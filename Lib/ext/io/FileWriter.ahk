#Include %A_LineFile%\..\FileUtil.ahk
#Include %A_LineFile%\..\FileOperations.ahk

/*
    FileWriter.ahk

    Class for writing data to files.

    Remarks
        - logging is supported. use global "logger" reference to log files. See Logger.ahk in lib\ext\logging for more details
*/
class FileWriterClass extends ObjectBase {
    /*
        write

        Write to file, creating the containing folder, if necessary. The previous file contents will be overwritten

        @param fileContent - string content, or ObjectBase. if object, use toString() method.
        @param useCache type:Boolean should we use read cache. Skips write if file contents are same. Good for workflows that are publishing content where only a few paths may actually be changed. Remarks - this is not an evicting cache, so not recommended for persistent scripts without awareness of memory footprint. May be slower for large files. PSR results: up to 1.5x worse performance for cache miss, 5.5x better if hit. The caller should consider carefully if the files are already in systemfileCache (windows not ahk). Also tested is FileGetSize, which is very slow. guessing it cant use windows systemFileCache properly.
    */
    write(path, fileContent:="", overwrite:=true, useCache:=false) {
        path:= ExpandEnvironmentVariables(path)
        if (useCache) { ;@PSR compare bytes/str len before str equals?? it is slightly slower if files are different so maybe that could minimize the cache miss
            if (fileReadCache[path] = fileContent) {
                return
            }
            actualFileContent:= FileRead(path)
            fileReadCache[path] = actualFileContent
            if (actualFileContent = fileContent) {
                return
            }
        }
        fileUtil.createContainingFolder(path)
        if (FileExist(path)) {
            if (!overwrite) {
                this.INFO("write ~ file not writen because file exists and overwrite is off. {1}", path)
                return
            }
            fileOps.deleteFile(path)
        }
        fileContentStr:= (IsObject(fileContent)) ? fileContent.toString() : fileContent
        FileAppend(fileContentStr, path)
        this.INFO("write ~ " path)
    }

    append(path, str) {

    }
    
}

global fileWriter:= new FileWriterClass() ;@Export fileWriter
