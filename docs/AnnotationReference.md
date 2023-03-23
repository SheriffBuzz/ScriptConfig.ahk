# AnnotationReference
This file contains annotations used throughout the project. These annotations may be parsed with AhkScriptAnalyzer, or they may be purely decorative to make it easier to find certain things with a text search of the project.

## General

### @Deprecated
Deprecated code. Code may be removed in the future.

### @HACK
A hack is code that may be a quick fix for a problem that may incur later techincal debt or problems due to unsupported language constructs.

### @TODO
TODO documentation for this annotation

### @PSR
Performance, Scalability, Reliability. This annotation indicates that further performance testing may be needed, or it may outline why a certain implementation was done.

## V2 Upgrades
Our current project is in v1, but we are preparing to upgrade to v2. The following annotations are related to the upgrade process.

### @v2upgrade
Generic remarks for v2 upgrade. May include instructions to do manually once we have upgraded to v2.

### @commandWrapper
User defined v1 function that has the same name and signature of a v2 equivalent function. These allow us to use v2 function syntax in existing v1 code. On upgrade to v2, these functions should be removed.

### @v1start
Start of v1 section. Any code in a v1 section will be removed by AhkV2Converter.ahk. Note: This annotation must be proceeded by the single line comment and must start at the beginning of a  line without preceeding spaces.

Code in a v1 section should be code that will be removed entirely, or cannot be easily upgraded automatically. Some version incompatible changes like ByRef -> & can be converted automatically with AhkV2Converter.ahk.

### @v1end
End of v1 section.

### @v2start
Start of v2 section. Any code in a v2 section will be uncommented by AhkV2Converter.ahk. Note: This annotation must be proceeded by the single line comment and must start at the beginning of a  line without preceeding spaces. Code in a v2 section should be enclosed in a multi line comment.

### @v2end
End of v2 section.


## Method Level Annotations
### @param
Param indicates parameters to function or method. In our project we allow param to be used for none, some, or all parameters. If only some are given, it may to be outline important functionality. Annotating every param may be superfluous, especially if params are descriptively named.

### @return
Return value to function or method. It may declare a datatype or details of the structure if the return value is a native object or array.

### @Override
Method is overriding a method in a base class.

### @async
Method is called asynchronously.

### @BuiltInOverride
Function is an override of an AHK built in function. This is separate from @commandWrapper, as commandWrappers will go away on upgrade to v2 but built in overrides will be retained.

### @Since
Give info on when method was implemented.

### @see
See another method. May outline a function or class method to refer to.

## Variable Level Annotations
### @Export
Use Export after an object initializaton to indicate an object will live at the global scope. Most of the classes that are exported are service classes that contain stateless methods, or methods that depend on a minimal set of constructor injections like ScriptConfig. Using classes is an important pattern in our code to avoid name conflicts of functions at the global scope, and to keep function names consise. 

## IOC
Inversion of Control. Concepts are modeled after Spring framework in Java.

### @Autowired
Indicates that a dependency will be injected into the given object (or it may be set on a global variable). This allows us to create stateless components without statically coupled dependencies.

### @ScriptConfigAware
Indicates that a class and its @Export reference will be ScriptConfig aware. This means the object state is dependent on ScriptConfig (usually the working directory prop) and should implement the onScriptConfig method to ensure ScriptConfig is instantiated before the object sets stateful information in instance variables.

## Top Level Scripts
Top level scripts are those that are invoked directly. They have #Include's but nothing #Includes them, except for occasionally other top level scripts.
  * A top level script may include another top level script when we want to bind A_Args to static values. We can create an extension of one top level script that supplies A_Args to the other. This may be preferred to avoid duplicate code.

### @CommandLineClient
Indicates the script will be invoked from the command line, and may accept A_Args.

### @ContextMenuClient
Indicates the script will be invoked from a context menu, *and* the first param will be a file or folder path. When using the context menu, %1 refers to the file or folder path. Even if the script doesnt use the path, it should use this convention to avoid ambiguity. %V can also be used to pass the file or folder path.

### @A_Args
Indicates a top level script accepts command line arguments. This should be included in the script/class level comment. A_Args is an Array, so each annotation should be A_Args[1], A_Args[2], etc...

## Export Script
Annotations used by ExportScriptDependenciesClient.ahk and other scripts that use AhkScriptAnalyzer.ahk.

### @ExportExe
Indicates that a script should be compiled to workingDirectory\bin when the script is exported. This annotation can be used in multiple places. As long as an object is included in the script and declared with this annotation, it will be exported. This may be useful if there are multiple top level versions of a script, eg. binding variables to static values instead of command line args.

### @ScriptConfigExport
Indicates a prop in ScriptConfig.json should be exported by an export script. This can be used to export a minimum set of script config properties. This is useful for filtering out script config from other modules when exporting a script.

