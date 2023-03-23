/*
    ScriptConfig.ahk

    Run AHK Scripts with Json config. Increase reliability when running scripts from multiple locations or machines.
	
	Script config is a class that sets up our environment for running a script. There are additional comments for some coding conventions for classes that use scriptconfig.

	@version v1.36.2

	Preface:
		ScriptConfig dependencies should not explicitly import ScriptConfig.ahk. This will break the import chain and cause the ScriptConfig object to be initialized before the objects of the classes that ScriptConfig depends on.
	
	Features:
		- ScriptConfig.json
			- ScriptConfig.json is a file that resides in the script directory of the working script.
			- It solves problems related to A_WorkingDir when scripts are not run in the same folder.
			- Provide consistent working directory for compiled and uncompiled scripts.
			- Instead of setting working directory based on relative path from a script, it is done once in ScriptConfig.json and applies to all scripts in that folder, without needing to recompile code. This makes it easier to support compiled exe's that may be in multiple levels of nesting in \bin or elsewhere.
			- Avoid hardcoding environment properties into scripts, such as program paths and hotkeys
		
		- Lib\ext\core
			- Core imports. This package contains default directives and command wrappers that give us access to v2 equivalent functions in v1.
				- Command wrapper list is not exhaustive, but contains many common commands. We intend to upgrade to v2, so it only needs to have the commands we are currently using in v1.

		- Logging
			- Autowire a logger
				- A logger name "logger" is autowired and defined on the global scope, given the property "workingDirectory" is defined in ScriptConfig.json at the root object, and Lib\ext\Logging\Logger.ahk is included before script config.
				- We do not current autowire logger unless Logger.ahk is included. This is because logger defines OnExit hooks to write logs to files which may be undesireable. It may be parameterized into ScriptConfig.json and supported without an import in the future.
				- "enableLogger" can be set in ScriptConfig.json. boolean.
				- "logLevel" can be set in ScriptConfig.json. See Logger.ahk for more details on log levels
	 	
		- ApplicationContext - ScriptConfig can act as an ioc container for stateful components
			- When ScriptConfig.ahk is included, Autowire.ahk is also included. Classes can use Autowire.bean("beanName") to indicate they require some object to be defined on the global scope. In the top level script, you can call Autowire.validate() to assert that all beans have been instantiated. This is the current way of simulating the bean functionality of an ioc container.
			- Autowiring objects allow library functions to be stateless.
				- Example: Code that calls and processes sql. A "sql processor" doesnt want to have to maintain state on how the sql was retrieved. it can autowire a sqlService that does the jdbc/api call to execute the sql. The top level script can define the "bean" as an object on the global scope. This keeps the library functions unaware of implementation details when all they need is a common interface method that the bean classes implement.
			- Autowire.ahk can be called on its own, but placing it in ScriptConfig reduces imports and leaves a well defined place for mocking additional ioc concepts in the future.
		
		- Native Object and Array overrides
			- Override Object and Array, giving them a base class, ObjectBase and ArrayBase, respectively.
			- We can extend these classes to add additional methods, while keeping native methods.
			- Syntactic sugar for calling methods on object initializers [] and {}. ie. [1, 2, 3].equals([1, 2, 3])
			- Out of the box support for standard Object methods like equals and toString in a familiar syntax
			- Putting this in ScriptConfig allows most \Lib classes to omit an explicit import of Lib\ext\Object\Object.ahk and Lib\ext\Object\Array.ahk. It is up to the caller to include these scripts directly, but in most cases none of the scripts in \Lib are designed to be standalone. If they have some need to be standalone, they should be wrapped in an additional top level script outside of the lib directory that includes ScriptConfig.
				- AHK_L does not throw a syntax error if you call a method on a class object where the class was never included. (At least with #Warn off) Lib classes can call these methods without fear of syntax errors, at the downside of unexpected and silently failing behavior if the proper class was not included.
		
		- General Remarks and code conventions
			- any variable that ends in a plural (s) is assumed to be an Array. ie. filePaths
			- Classes, methods, and functions should have multiline comments, if any. The name of the class or function should be the first line of the comment, on a line by itself.
			- Classes should be postfixed with "Class". Since objects cannot define functions like in Javascript, we use classes. Since variables in ahk are not case sensitive, we cant have a class with uppercase and instances with lower camel case. 
				- We prefer to have our functions in objects, to avoid scope issues with duplicate functions at the global scope. This leads to using super global instance objects that act as a service class (only methods, ideally stateless)
				- Example export: global fileUtil:= new FileUtilClass() ;@Export fileUtil
					- We use @Export {nameofvariable} as a convention. This can be used by a script like AhkScriptAnalyzer that can read annotations. Currently it has no special meaning but it provides easy access via text editor search.
			- All methods parameters and variables should be in milliseconds, unless explicitly specified otherwise.
			- A_ThisFunc is not super useful because if we want to do something inside a utils function, the caller has to pass A_ThisFunc as a parameter (Ahk doesnt maintain a callstack except in debug mode). If you need to pass A_ThisFunc, the accepting function or method should declare the parameter "thisFunc" as a convention.
			- Methods that have a filePath and fileContent parameter should be in the order filePath, fileContent. (Saving to files or clipboard, etc.)
			- Imports go at very top of file, followed by 1 blank line, a class level block comment, then a class definition with no extra blank line. Add blank line after comment if there are no classes and only functions. End of file always ends in a blank line.
			- All top level scripts should explicitly import Lib\ext\Core\Exports.ahk or Lib\ScriptConfig.ahk. It may not be required if other imports it declares import core, but it is not guaranteed.
			- Global functions should be capital case. Instance methods of a class should be lower camel case, except methods intended to be called via class ref. (similar to static method)
			- Variables for File operations should use "source" and "target" as a prefix, following the type of path they are.
			- File paths should always use backslashes instead of forwardslashes. Some libs handle forward slashes when taking user input, but use backslashes in code where possible.
			- Top level scripts that use A_Args to take command line args should assign the values to variables with a descriptive name, before passing them to a method call. This makes it more clear when viewing the top level script what each arg is, instead of having to dig into the method it calls.
			- Top level Scripts may Explicitly call ExitApp or Lib\ext\Script\ExitApp(). It is not required but recommended, and may avoid some regressions during development that would cause a script to not exit cleanly.
			- use A__ (double underscore) as a prefix for user-defined global variables. Global variables should be used sparingly, ideally for custom user defined configs that mimic built in variables but are not built ins. 

		- StagingArea for IO operations
			- Staging area is a folder path that can be used as a scratchpad for file operations. Anything in the staging area should be considered volatile and could be removed for any reason, by ahk code or manually by the user.

			Usecase:
				- Heavy IO intesive operations to be done on a separate drive for performance reasons, to avoid excessive disk writes, or avoid using disk space on a full drive. The user could have a separate sdd drive that is not their C: drive that is faster, or could be using a mounted RAM Disk.
				- Staging area should support "Coalesce" functionality. We might prefer a certain drive but it may not be mounted all the time, so we can provide a fallback.

			Usage:
				- "StagingArea" prop in ScriptConfig, can pass either string or Array.
				- "createStagingAreaIfMounted" prop will create the staging area if not exists.
					- This is good for ram disk or other volitile media.
			Good staging area examples: Ramdisk, %USERPROFILE%\Downloads\ahkstaging
	
	Pitfalls:
		- Using SetWorkingDir should be avoided as scripts may cache relative filepaths in memory. These filepaths would be invalid if SetWorkingDir is used. WorkingDirectory is a required prop in ScriptConfig, SetWorkingDir will be done once on ScriptConfig creation.
*/