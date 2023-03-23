#Include %A_LineFile%\..\..\string\Exports.ahk
#Include %A_LineFile%\..\..\object\Object.ahk

/*
    ClassUtil
*/
class ClassUtilClass extends ObjectBase {
    /*
		getSimpleClassName

		Return Simple class name. Omit Class postfix.

        This method can be used by calling ObjectBase.getSimpleClassName for class objects. This is prefered when classes are loaded. For scripts that use AhkScriptAnalyzer/ClassInfo, the class object is not guaranteed to be loaded, so this method can be used, passing the className string.

		@PSR
	*/
	getSimpleClassName(className) {
		simpleClassName:= StrGetBeforeLastIndexOf(className, "class")
		simpleClassName:= StrGetBeforeLastIndexOf(simpleClassName, "Base")
		return simpleClassName
	}
}
global classUtil:= new ClassUtilClass() ;@Export classUtil
