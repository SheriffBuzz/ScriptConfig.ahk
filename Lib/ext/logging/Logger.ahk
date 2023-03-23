#Include %A_LineFile%\..\..\io\FileUtil.ahk
#Include %A_LineFile%\..\..\io\FileOperations.ahk

#Include %A_LineFile%\..\..\date\Exports.ahk
#Include %A_LineFile%\..\..\object\Object.ahk

/*
	LoggerClass

	Class for debugging ahk program. If using ScriptConfig.ahk/ScriptConfig.json in your project, you can define a property "workingDirectory" and "logLevel" at the root of the json to set up the log level. The following imports should be used in this order:

	#Include %A_LineFile%\..\<pathtoworkingdirectory>\Lib\ext\logging\Logger.ahk
	#Include %A_LineFile%\..\<pathtoworkingdirectory>\Lib\ScriptConfig.ahk

	Doing the above will create a new LoggerClass instance and configure it with the working directory specified by the script config, stored in the super gloabl object "logger".
		- ObjectBase
			For custom objects, it is preferred to extend ObjectBase and use this.LOG() and its variants instead of the logger reference. This adds the custom class name to the log statement, in a manner similar to log4j.

	The logger uses an in memory buffer instead of calling FileAppend on every log call, to avoid any performance issues. It uses the OnExit hook to flush the buffer when the script exits. While the logs may not get printed if the script is forcibly closed or computer loses power, a rolling log is not necessary for most scripts (compared to something like an application server). Future refinements could be made to flush the buffer periodically using SetTimer.

	@param workingDirectory

	Remarks
		- varsetcapacity isnt yet implemented nor is flushing the buffer when it gets too big.
		- directory \log should be created in workingDirectory already, FileCreateDir is not called, TODO
		- Using a logger object instead of global functions allows top level scripts to reuse components that have log statements even though no logger instance defined at the top level, without throwing function not defined errors. However, this may not work if you change the #Warn mode for UseUnsetGlobal. ;https://www.autohotkey.com/docs/commands/_Warn.htm
*/
class LoggerClass extends ObjectBase {
	static DEBUG_LEVEL:= 4
	static INFO_LEVEL:= 3
	static WARN_LEVEL:= 2
	static FATAL_LEVEL:= 1
	static OFF_LEVEL:= 0
	static logNameByLevel:= {LoggerClass.OFF_LEVEL: "  OFF", LoggerClass.WARN_LEVEL: " WARN", LoggerClass.INFO_LEVEL: " INFO", LoggerClass.DEBUG_LEVEL: "DEBUG", LoggerClass.FATAL_LEVEL: "FATAL"} ;Remarks - this is used for display purposed only - for convenience we have hardcoded a leading whitespace pad, as to not computed it on every call.
	
	/*
		Constructor

		Logger Constructor for creating a logger.

		A logger can be configured with a working directory. It will then output logs to /logs folder.
		Other options may customize the file name and the tray menu item name for flushing the log while a script is still running.

		@param workingDirectory
		@param fileName
		@param trayMenuItemName
	*/
	__New(workingDirectory, fileName:="serverlog.txt", trayMenuItemName:="") {
		this.workingDirectory:= workingDirectory
		this.loggingDirectory:= this.workingDirectory "\log"
		this.buffer:= ""
		this.logLevel:= "2"
		this.fileName:= fileName
		this.filePath:= this.loggingDirectory "\" this.fileName
		this.objectPrintDepth:= 15
		this.maxClassNameSize:= 22 ;we pad the class name with whitespace so they are right aligned.
		
		trayMenuItemName:= (trayMenuItemName) ? trayMenuItemName : this.getClassName()
		loggerMenuRef:= new Menu()
		loggerMenuRef.add(trayMenuItemName " flush", ObjBindMethod(this, "flushBuffer"))

		this.shouldPrintObjects:= true
		this.preserveLogsCount:= 4
		OnExit(ObjBindMethod(this, "onExitCallback"))
		this.preserveLogs(this.preserveLogsCount)
		VarSetStrCapacity(this.buffer, 10240000)
	}

	/*
		preseveLogs

		Keep preserveLogsCount number of old logs
	*/
	preserveLogs(remaining) {
		if (FileExist(this.filePath)) {
			splitPath:= StrSplit(this.filePath, ".")
			arr:= []
			while (true) {
				if (remaining <= 0) {
					break
				}
				arr.push(splitPath[1] remaining "." splitPath[2])
				remaining:= remaining - 1
			}
			arr.push(this.filePath)
			for i, path in arr {
				if (i = 1) {
					continue
				}
				if (FileExist(arr[i])) {
					fileOps.moveFile(arr[i], arr[i - 1], true)
				}
			}

			path:= this.filePath
			olderPath:= fileUtil.appendValueToFileName(path, this.preserveLogsCount - remaining + 1)
			if (FileExist(olderPath)) {
				this.preserveLogs(remaining - 1)
			} else {
				previous:= fileUtil.appendValueToFileName(path, remaining - 2) ;HACK
				fileOps.moveFile(previous, olderPath)
			}
		}
	}

	onExitCallback() {
		this.flushBuffer()
	}

	flushBuffer() {
		if (this.buffer) {
			this.LogToFile(this.buffer)
			this.buffer:=
			;VarSetCapacity??
		}
	}

	LogToBuffer(text) {
		this.buffer.= text "`n"
		if (this.flushAlways) {
			this.flushBuffer()
		}
	}

	LogToFile(text) {
		if (this.loggingDirectory) {
			FileAppend(text "`n", this.filePath)
		}
	}

	isDebugEnabled() {
		return (this.loglevel >= LoggerClass.DEBUG_LEVEL)
	}

	/*
		LOG

		Remarks - currently debug level is only for msgbox warnings, everything gets logged.

		@param level
		@param msg
		@param args - args to inject into the string. This is a syntatic sugar to make calls to this function prettier.
			- Example LOG(1, "Submitted order {1} with {2} lines.", orderNo, lines.count())
			- Replacements in the msg should be one-indexed.
	*/
	LOG(level, msg, args*) {
		if (this.logLevel >= level && level > 0) {
			msg:= this.formatString(msg, args*)
			if (level <= LoggerClass.FATAL_LEVEL) {
				MsgBox(msg)
			}
			
			msg:= dateFormat.now() " " this.getLogLevelDisplay(level) " " msg
			this.logToBuffer(msg)
		}
		return msg
	}

	WARN(msg, args*) {
		return this.LOG(LoggerClass.WARN_LEVEL, msg, args*)
	}

	INFO(msg, args*) {
		return this.LOG(LoggerClass.INFO_LEVEL, msg, args*)
	}
	DEBUG(msg, args*) {
		return this.LOG(LoggerClass.DEBUG_LEVEL, msg, args*)
	}
	FATAL(msg, args*) {
		return this.LOG(LoggerClass.FATAL_LEVEL, msg, args*)
	}

	setLogLevel(var:="") {
		if (IsNumber(var)) {
			this.logLevel:= var
		} else if (var = "Debug") {
			this.logLevel:= LoggerClass.DEBUG_LEVEL
		}else if (var = "Info") {
			this.logLevel:= LoggerClass.INFO_LEVEL
		}else if (var = "Warn") {
			this.logLevel:= LoggerClass.WARN_LEVEL
		} else if (var = "FATAL") {
			this.logLevel:= LoggerClass.FATAL_LEVEL
		} else {
			this.logLevel:= LoggerClass.OFF_LEVEL
		}
	}

	getLogLevelDisplay(level) {
		return LoggerClass.logNameByLevel[level]
	}

	/*
		formatString.

		@param str
		@param args - args to inject into the string. This is a syntatic sugar to make calls to this function prettier.
			- Example LOG(1, "Submitted order {1} with {2} lines.", orderNo, lines.count())
			- Replacements in the msg should be one-indexed.

		Remarks
			- This function should eventually be pushed down to ext string, currently leaving it here because it depends on objectutil. Could lead to circular dependency.
			- if logging is not enabled, you must use "LoggerClass.FormatString" instead of "logger.formatString"
			- if obj implements toString, is is assumed it wont have any circular references.
	*/
	formatString(ByRef str, ByRef args*) {
		for i, obj in args {
			if (IsObject(obj) && this.shouldPrintObjects) {
				if (obj.toString) {
					obj:= obj.toString()
				} else {
					if (this.logLevel > LoggerClass.INFO_LEVEL) {
						try {
							obj:= objectUtil.toCleanString(obj, obj.__class,,,this.objectPrintDepth)
						}
					} else {
						obj:= "[Object - Enable DebugLogging for json]"
					}
				}
			}
			str:= StrReplace(str, "{" i "}", obj)
		}
		return str
	}
}
global logger:= logger ;declare or redeclare logger as super global so when it is instantiated, we dont need to mark it global in our methods. (Dont instantiate it now as it needs script config info (working directory, log level)). it may already be created if scriptconfig.ahk runs first (There may be a bug with calling a static method on a class object, that code is running before its direct import file codes are running)