#Include %A_LineFile%\..\ioc\Autowire.ahk
#Include *i %A_LineFile%\..\ext\logging\Logger.ahk
#Include *i %A_LineFile%\..\ext\logging\PSRLogger.ahk

/*
    ScriptConfig.ahk

    Script config is a class that sets up our environment for running a script. There are additional comments for some coding conventions for classes that use scriptconfig.

	@version v1.34.4

	@Export {"filePath": "docs\\ScriptConfig.md"}
	@Export {"filePath": "docs\\AnnotationReference.md"}
	@See docs\Lib\ScriptConfig.md
*/

#Include %A_LineFile%\..\ext\core\Exports.ahk

;Override Native Object and Arrays
#Include %A_LineFile%\..\ext\object\Object.ahk
#Include %A_LineFile%\..\ext\object\Array.ahk

;Script Config dependencies
#Include %A_LineFile%\..\ext\io\FileUtil.ahk
#Include %A_LineFile%\..\ext\string\StringUtils.ahk


/*
	ScriptConfigAware

	ScriptConfig should contain a mimimal set of dependencies. We have expanded to its dependencies for useful stuff (fileUtil) but this introduces a problem for nested dependencies that require ScriptConfig be injected into it.

	Solution:
		Instead of components using script config in their constructors, they can implement the "onScriptConfig" method which will be called when the script config instance is ready.

		onScriptConfigSignature: param ScriptConfig

		Call ScriptConfigClass.registerObject(objRef) to register an object as scriptConfigAware.
*/
global ScriptConfig:= new ScriptConfigClass().get()

/*
	ScriptConfig

	Script Config configures script options from an external json file

	<a href="../../ScriptConfig.md" target="_self">ScriptConfig.md</a>

	@ScriptConfigExport workingDirectory - Working directory to set A_WorkingDir. Relative to ScriptConfig.json file, not A_ScriptConfig. (If no script config in A_ScriptDir, we check parent dir. So final working dir is relative to ScriptConfig.json location). All io packages support relative paths relative to working directory.
	@ScriptConfigExport suppressErrorMessages - boolean
	@ScriptConfigExport trayTipsEnabled - boolean
	@ScriptConfigExport enableLogger - enable default logger stored in "logger" global variable
	@ScriptConfigExport logLevel - log level For LoggerClass object
	@ScriptConfigExport stagingArea - folder that can be used for temp operations. @Deprecated use GeneratedContent
	@ScriptConfigExport exitAppHotkey - hotkey to exit app. This can be used by top level scripts that might be run for a specific purpose, not meant to be a long running script with a gui. It may define a few hotkeys. We can define a hotkey that all scripts can add, so we can kill all these temporary scripts at once with the same hotkey, as long as they include script config.
*/
class ScriptConfigClass extends ObjectBase {
    static scriptLocalSeq:= 1 ;private. This is used for unique id's.
    static scriptConfigAwareReferences:= [] ;TODO this may not work when static, if we have multiple scriptConfigs, ie ExportScriptDependenciesClient

	/*
		RegisterObject

		Add @param objectRef to scriptConfigAwareRefs. Listener methods will be called on the requested object, such as "onScriptConfig".

		Remarks
			- We have set this as an instance method and not a top level fn so classes that might not include script config won't throw an error.
			- If we use scriptConfigAwareReferences then we will need some way to add it to the references without invoking the listener twice (in this method, and inside scriptconfig.get method)
	*/
	RegisterObject(ByRef objectRef) {
		if (IsObject(scriptConfig)) {
			objectRef["onScriptConfig"](scriptConfig)
		} else {
			ScriptConfigClass.scriptConfigAwareReferences.push(objectRef)
		}
	}

	/*
		Constructor

		@param scriptConfigPath default A_ScriptDir\ScriptConfig.json
			- Passing a file path is not recommended, but is allowed for scripts like AhkScriptAnalyzer that need to resolve the true working directory without being the active script. The working directory may be different then ScriptConfig.json's folder path, as the prop "workingDirectory" can be set in the json to ..\ for a parent directory.
		@param shouldSetWorkingDir flag to allow disable of setting working directory, for mocked ScriptConfig objects (AhkScriptAnalyzer). This prop should be removed after setWorkingDirectory method is called.
	*/
	__New(scriptConfigPath:="", shouldSetWorkingDir:= true) {
		this.scriptConfigPath:= (scriptConfigPath) ? scriptConfigPath : fileUtil.findFileInPathHierarchy(A_ScriptDir, "ScriptConfig.json")
		this.shouldSetWorkingDir:= shouldSetWorkingDir ; note this prop is hard deleted in setWorkingDirectory method
	}
	
	get() {
        try {
            jsonStr:= this.readConfig()
            if (!jsonStr) {
                return
	        }
            defaultCfg:= this.load(jsonStr,,, ObjectBase, ArrayBase) ;Pass our ObjectBase and ArrayBase
            this.setWorkingDirectory(defaultCfg)
			this.setStagingArea(defaultCfg)
			this.setLoggers(defaultCfg)
            this.setDefaultCfg(defaultCfg)
			this.setExitAppHotkey(defaultCfg)
			this.pid:= DllCall("GetCurrentProcessId")
			if (defaultCfg.priority) {
				ProcessSetPriority(defaultCfg.priority)
				this.DEBUG("Process Priority changed to {1}", defaultCfg.priority)
			}
			if (defaultCfg.listLines) {
				ListLines((defaultCfg.listLines = "On")) ;@v2upgrade
			}
			this.onScriptConfig()
            return this
        } catch e {
            MsgBox("ScriptConfig invalid: " e.message)
            exitapp
        }
    }

	/*
		onExit

		Stub method for onExit callback. This may be triggered if "ExitAppHotkey" prop is set.

		This method is reserved for future enhancements for additional functionality to trigger on exit.
	*/
	onExit() {
		ExitApp
	}

    readConfig() {
        this.scriptConfigPath:= Trim(this.scriptConfigPath)
		if (!FileExist(this.scriptConfigPath)) {
			throw "Unable to resolve ScriptConfig.json: " path
		}
        ;TODO expand environment variables
        cfgStr:= FileRead(this.scriptConfigPath)
        return cfgStr
    }

	/*
		setWorkingDirectory

		Set working directory, relative to ScriptConfig.json workingDirectory prop.

		Working directory will be set relative to ScriptConfig.json, not initial working directory. We allow ScriptConfig.json to be in a parent directory, so the relativeness of the workingDirectory prop must be relative to the ScriptConfig.json file it comes from.
	*/
    setWorkingDirectory(ByRef defaultCfg) {
        workingDirectory:= defaultCfg.workingDirectory
        defaultCfg.delete("workingDirectory")
		
		if (!this.shouldSetWorkingDir) {
			workingDirectory:= fileUtil.getFolderPath(this.scriptConfigPath)
		} else if (InStr(workingDirectory, "\..") = 1) {
			workingDirectory:= this.scriptConfigPath workingDirectory "\.." ;add extra layer up because scriptconfigpath is a file
		} else if ((InStr(workingDirectory, "\.") = 1)) {
			workingDirectory:= StrGetBeforeLastIndexOf(this.scriptConfigPath, "\")
		}

		if (workingDirectory && !FileExist(workingDirectory)) {
			throw "Unable to resolve workingdirectory: " workingDirectory
		}
		
		if (this.shouldSetWorkingDir) {
			SetWorkingDir(workingDirectory)
		}
		this.delete("shouldSetWorkingDir")
        this.workingDirectory:= A_WorkingDir ;resolves relative path if A_ScriptDir was used
    }

	/*
		setStagingArea

		See Top Level comment for more details

		Remarks
			- User should use getStagingArea method so we can throw an error if no stagingArea was given in the ScriptConfig json.
	*/
	setStagingArea(defaultCfg) {
		if (!defaultCfg.stagingArea) {
			return
		}
		stagingAreas:= ArrDefault(defaultCfg.stagingArea)
		defaultCfg.delete("stagingArea")
		createStagingAreaIfMounted:= defaultCfg.delete("createStagingAreaIfMounted")

		for i, stagingArea in stagingAreas {
			stagingArea:= ExpandEnvironmentVariables(stagingArea)
			if (FileExist(stagingArea)) {
				this.stagingArea:= stagingArea
				break
			}
			if (createStagingAreaIfMounted) {
				stagingArea:= StrReplace(stagingArea, "/", "\")
				if (FileExist(StrSplit(stagingArea, "\")[1])) {
					DirCreate(stagingArea)
					this.stagingArea:= stagingArea
					break
				}
			}
		}
	}

	/*
		getStagingArea

		Get the staging area path. See the method setStagingArea for more details.

		@param errorOnMissing - should we throw an error if staging area is missing. By default is true.
	*/
	getStagingArea(errorOnMissing:=true) {
		stagingArea:= this.stagingArea
		if (!stagingArea) {
			msg:= "GetStagingArea is missing from ScriptConfig.json or does not list any valid paths. Check that all drives are mounted properly."
			if (errorOnMissing) {
				throw msg
			}
			logger.WARN(msg)
		}
		return stagingArea
	}
	/*
		setLoggers
		@param defaultCfg
			defaultCfg.enableLogger: boolean should log be autowired into "loggger" ref at global scope
			defaultCfg.enablePSR: boolean should log be autowired into "loggger" ref at global scope
	*/
	setLoggers(ByRef defaultCfg) {
		if (!(defaultCfg.enableLogger != "" && !defaultCfg.enableLogger)) { ;check 0 value explicitly for backwards compatability reasons, if no prop enableLogger is defined then enable the log.
			if (IsObject(LoggerClass)) {
				logger:= new LoggerClass(this.workingDirectory) ;logger is already declared super global in Logger.ahk
				if (defaultCfg.logLevel) {
					logger.setLogLevel(defaultCfg.logLevel)
					;TODO add config in json for subdirectory within logs folder
				}
			}
		}
		

		if (!(defaultCfg.enablePSR != "" && !defaultCfg.enablePSR)) { ;check 0 value explicitly for backwards compatability reasons, if no prop enableLogger is defined then enable the log.
			if (IsObject(PSRLoggerClass)) {
				psrLogger:= new PSRLoggerClass(this.workingDirectory) ;logger is already declared super global in Logger.ahk
			}
		}

		
	}

	/*
		setExitAppHotkey

		Remarks
			- This makes the script Effectively persistent. Top level scripts should explicitly terminate with ExitApp if required.
	*/
	setExitAppHotkey(defaultCfg:="") {
		exitAppHotkey:= (this.exitAppHotkey) ? this.exitAppHotkey : defaultCfg.exitAppHotkey
		if (A__AddExitHotkey && exitAppHotkey) {
			HotkeyOn(exitAppHotkey, ObjBindMethod(this, "onExit"))
		}
	}

    setDefaultCfg(ByRef defaultCfg) {
        for key, value in defaultCfg {
            this[key]:= value
        }
    }

	onScriptConfig() {
		for i, obj in ScriptConfigClass.scriptConfigAwareReferences {
			obj["onScriptConfig"](this)
		}
	}

	/*
		getUniqueId

		Create ID that is unique to Currently executing script.
		
		Format: {ScriptPID padded to 6 chars}-{ScriptLocalMonotonicIncreasingSeq}

        Remarks:
			- pass @param dateTimeStamp:=true or see getDateTimeUniqueId for even more unique protection. If it is not passed, then it is possible the uniqueid is not unique when Windows Process ID's are recycled. This is unlikely, but using the dateTimeStamp is recommended, especially for file names.
			- We cant enforce the scriptLocalSeq from being modified, but its up to the developer to not break the contract.
	*/
	getUniqueId(dateTimeStamp:=false) {
        Critical
        uniqueId:= ScriptConfig.scriptLocalSeq++
        Critical("Off")

		if (dateTimeStamp) {
			if (!IsObject(dateFormat)) {
				throw A_ThisFunc " with @param dateTimeStamp:=true requires a DateFormatClass instance stored in the global variable 'dateFormat'"
			}
			date:= dateFormat.nowFileName()
			uniqueId:= date "_" uniqueId
		}
		return uniqueId
	}

	getDateTimeUniqueId() {
		return this.getUniqueId(true)
	}

	/*
		getMapEntry

		Convenience method to get an entry from script config

		@param propName - name of prop on root of script config
		@param propKey - subkey of ScriptConfig[propName]
		@param callerDisplayValue - can be used to customize error message.
		@param isExpandEnvironmentVariables iterate 1st children for non object keys and expand them. Useful if mapEntry stores only file paths
	*/
	getMapEntry(propName, propKey, strict:=true, callerDisplayValue:="", isExpandEnvironmentVariables:=true) {
		mapObj:= this[propName]
		if (!IsObject(mapObj)) {
				throw """" propName """ object is not set on script config json."
		}
		mapEntry:= mapObj[propKey]
		if (!mapEntry && strict) {	
			throw "GetKey failed for key: " propKey ((callerDisplayValue) ? " at: " callerDisplayValue : "")
		}
		if (isExpandEnvironmentVariables) {
			if (IsObject(mapEntry)) {
				for mapEntryPropName, mapEntryPropValue in mapEntry {
					if (IsObject(mapEntryPropValue)) {
						continue
					}
					mapEntry[mapEntryPropName]:= ExpandEnvironmentVariables(mapEntryPropValue)
				}
			} else {
				mapEntry:= ExpandEnvironmentVariables(mapEntry)
			}
			
		}
		return mapEntry
	}
	/*
		@deprecated - use jxon? Now we have exportscriptdependencies it is ok to have some dependencies for script config because we can easily export the nested dependencies.

		Utils section, these are minimal set of lib functions to avoid cyclic dependency.
		@param args[1] = objectbase, args[2] = arraybase
	*/

    load(ByRef src, ByRef isNullAsString:=0, ByRef isBooleanAsString:=0, args*) {
		static q := Chr(34)
		key := "", is_key := false
		stack := [ tree := [] ]
		is_arr := { (tree): 1 }
		next := q . "{[01234567890-tfn"
		pos := 0
		while ( (ch := SubStr(src, ++pos, 1)) != "" ){
			if InStr(" `t`n`r", ch)
				continue
			if !InStr(next, ch, true) {
				ln := ObjLength(StrSplit(SubStr(src, 1, pos), "`n"))
				col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

				msg := Format("{}: line {} col {} (char {})"
				,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
				: (next == "'")     ? "Unterminated string starting at"
				: (next == "\")     ? "Invalid \escape"
				: (next == ":")     ? "Expecting ':' delimiter"
				: (next == q)       ? "Expecting object key enclosed in double quotes"
				: (next == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
				: (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
				: (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
				: [ "Expecting JSON value(string, number, [true, false, null], object or array)"
					, ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
				, ln, col, pos)

				throw Exception(msg, -1, ch)
			}
			is_array := is_arr[obj := stack[1]]
			if i := InStr("{[", ch) {
				val := (proto := args[i]) ? new proto : {}
				is_array? ObjPush(obj, val) : obj[key] := val
				ObjInsertAt(stack, 1, val)
				
				is_arr[val] := !(is_key := ch == "{")
				next := q . (is_key ? "}" : "{[]0123456789-tfn")
			} else if InStr("}]", ch) {
				ObjRemoveAt(stack, 1)
				next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
			} else if InStr(",:", ch) {
				is_key := (!is_array && ch == ",")
				next := is_key ? q : q . "{[0123456789-tfn"
			}

			else {
				if (ch == q) {
					i := pos
					while i := InStr(src, q,, i+1) {
						val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
						static end := A_AhkVersion<"2" ? 0 : -1
						if (SubStr(val, end) != "\")
							break
					}
					if !i ? (pos--, next := "'") : 0
						continue
					pos := i ; update pos
					val := StrReplace(val,    "\/",  "/")
					, val := StrReplace(val, "\" . q,    q)
					, val := StrReplace(val,    "\b", "`b")
					, val := StrReplace(val,    "\f", "`f")
					, val := StrReplace(val,    "\n", "`n")
					, val := StrReplace(val,    "\r", "`r")
					, val := StrReplace(val,    "\t", "`t")

					i := 0
					while i := InStr(val, "\",, i+1) {
						if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
							continue 2

						; \uXXXX - JSON unicode escape sequence
						xxxx := Abs("0x" . SubStr(val, i+2, 4))
						if (A_IsUnicode || xxxx < 0x100)
							val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
					}
					if is_key {
						key := val, next := ":"
						continue
					}
				}
				else { ; number | true | false | null 
					val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
					static number := "number", integer := "integer"
					if val is %number%
					{
						if val is %integer%
							val += 0
					}
					else if (val == "true") {
						val:= (isBooleanAsString) ? "true" : 1
					} else if (val == "false") {
						val:= (isBooleanAsString) ? "false" : 0
					} else if (val == "null") {
						val:= (isNullAsString) ? "null" : ""
					}
					else if (pos--, next := "#")
						continue
					pos += i-1
				}			
				is_array? ObjPush(obj, val) : obj[key] := val
				next := obj==tree ? "" : is_array ? ",]" : ",}"
			}
		}
		return tree[1]
	}

	/*
		ExpandEnvironmentVariables - expand env varaibles (without using EnvGet, as #NoEnv may be enabled)
		https://www.autohotkey.com/board/topic/9516-function-expand-paths-with-environement-variables/

		Remarks - InStr(path, "%") short circuit is SLOWER!!
	*/
	expandEnvironmentVariables(ByRef path) {
		VarSetCapacity(dest, 2000) 
		DllCall("ExpandEnvironmentStrings", "str", path, "str", dest, int, 1999, "Cdecl int") 
		return dest
	}
}
