#Include %A_LineFile%\..\ArrayUtils.ahk
#Include %A_LineFile%\..\..\string\StringUtils.ahk

#Include %A_LineFile%\..\ArrayBase.ahk

/*
	Object.ahk

	root Class for ObjectBase, ObjectUtils, and misc object top level function
*/

/*
	AssertObjHasProperties

	Assert that input object has the following properties.
	@param obj
	@param props - array of props to match
	@param emptyValuesAllowed - if false, asserts that each key is present and each val != ""
	@throws error if object does not have any properties
*/
AssertObjHasProperties(obj, props, emptyValuesAllowed:=true) {
	keys:= []
	for key, val in obj {
		keys.push(key)
		if (!emptyValuesAllowed) {
			if (val = "") {
				throw "AssertObjectHasProperties  - " key " is blank"
			}
		}
	}
	for i, prop in props {
		if (!ArrContains(keys, prop)) {
			throw "AssertObjectHasProperties - prop " prop " not found on object"
		}
	}
	return true
}

ObjDefault(ByRef object) {
	return (IsObject(object)) ? object : {}
}

IsSingleItemPresent(props*) {
	val:= ""
	for i, prop in props {
		if (prop != "") {
			if (val) {
				return false
			}
			val:= prop
		}
	}
	return (val != "") ? true : false
}

/*
	CopyPropertiesStrict

	Copies properties from a source to target object, iff props is blank or source has all, non null properties.

	Currently we do not support object properties as it causes infinite loop without special handling of object backreferences. We support empty objects as a workaround: copy will happen if target object is empty

	@param skipBackreferenceName @HACK for propogating top level info on child element, skip the parent. This is most likely the name of the variable reference of array container that is copying to @param target.
*/
CopyPropertiesStrict(ByRef source, ByRef target, props:="", includeObjects:=true, skipBackreferenceName:="") {
	filterProps:= IsObject(props)
	if (filterProps) {
		AssertObjHasProperties(source, props, false)
	}
	target:= (IsObject(target)) ? target : {}
	for key, val in source {
		if (filterProps) {
			if (!ArrContains(props, key)) {
				continue
			}
		}
		if (key = skipBackreferenceName) {
			continue
		}
		if (IsObject(val)) {
			if (!includeObjects) {
				continue
			} else if (val.isEmpty()) {
				continue
			} else if (target[key].isEmpty()) {
				;do copy
			}else {
				;CopyPropertiesStrict(source[key], target[key], props, includeObjects)
				throw "CopyProperties does not support nested objects"
			}
		}
		target[key]:= val
	}
}

apply(ByRef to, from, force:=false) {
	if (!IsObject(from)) {
		return
	}
	for key, val in from {
		sourceVal:= to[key]
		if (sourceVal = "" || force) {
			to[key]:= val
		}
	}
	return to
}

;TODO export
class ObjectUtilClass {
	/*
		toCleanString

		;;https://github.com/cocobelgica/AutoHotkey-JSON/blob/master/Jxon.ahk
		;modified slightly so it doesnt blow the stack with cyclical references, removed json escaping

		Remarks
			- Object backlink is supported for custom class objects. Otherwise, max print depth msg will be shown.

		@param obj
		@param class custom class type (obj.__Class)
		@param indent - character to indent
		@param lvl - how many indents
		@param objectPrintDepth - how many nested objects before printing generic message

	*/
	toCleanString(obj, clazz, indent:="", lvl:=1, objectPrintDepth:=10) {
		static q := Chr(34)
		static ptrCache:= []

		if (lvl = 1) {
			ptrCache:= []
		}
		if IsObject(obj)
		{
			if (ptrCache[&obj] = 1 && clazz) {
				return "[Object backlink]"
			}
			ptrCache[&obj]:= 1
			static Type := Func("Type")
			if Type ? (Type.Call(obj) != "Object") : (ObjGetCapacity(obj) == "")
				throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))

			is_array := 0
			for k in obj
				is_array := k == A_Index
			until !is_array

			if (IsInteger(indent)) {
				if (indent < 0)
					throw Exception("Indent parameter must be a postive integer.", -1, indent)
				spaces := indent, indent := ""
				Loop, %spaces%
					indent .= " "
			}
			indt := ""
			Loop, % indent ? lvl : 0
				indt .= indent

			lvl += 1, out := "" ; Make #Warn happy
			for k, v in obj
			{
				if IsObject(k) || (k == "")
					throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
				
				if !is_array
					out .= (q . k . q ) ;// key
						.  ( indent ? ": " : ":" ) ; token + padding
				
				if (v.__class && clazz.__class && v.__class = clazz) {
					out .= "[BackReference to " clazz "]" .  ( indent ? ",`n" . indt : "," ) ; token + indent
				} else if (lvl > objectPrintDepth) {
					out .= "[max print depth " objectPrintDepth "]" .  ( indent ? ",`n" . indt : "," ) ; token + indent
				} else {
					out .= this.toCleanString(v, v.__class, indent, lvl, objectPrintDepth) .  ( indent ? ",`n" . indt : ",") ; token + indent
				}
					
			}

			if (out != "")
			{
				out := Trim(out, ",`n" . indent)
				if (indent != "")
					out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
			}
			
			return is_array ? "[" . out . "]" : "{" . out . "}"
		}

		; Number
		else if (ObjGetCapacity([obj], 1) == "")
			return obj

		; String (null -> not supported by AHK)
		if (obj != "")
		{
			/*
			obj := StrReplace(obj,  "\",    "\\")
			, obj := StrReplace(obj,  "/",    "\/")
			, obj := StrReplace(obj,    q, "\" . q)
			, obj := StrReplace(obj, "`b",    "\b")
			, obj := StrReplace(obj, "`f",    "\f")
			, obj := StrReplace(obj, "`n",    "\n")
			, obj := StrReplace(obj, "`r",    "\r")
			, obj := StrReplace(obj, "`t",    "\t")
			*/
			

			static needle := (A_AhkVersion<"2" ? "O)" : "") . "[^\x20-\x7e]"
			while RegExMatch(obj, needle, m)
				obj := StrReplace(obj, m[0], Format("\u{:04X}", Ord(m[0])))
		}	
		return (obj = "true" || obj = "false" || obj = "null") ? obj : q . obj . q
	}

	/*
		propagateFieldsToArrProperty

		This function propogates properties from an object, onto each element of an iterable property.

		This is useful when you have an array structure where you want to populate defaults. It could be used in place of csv, where many columns have the same row.

		@param obj
		@param arrPropertyName - name of the property to propagate values to. Currently only single level is supported, in the future we may support array properties that are nested multiple levels
		@param includeObjects - boolean - if true, only includes object properties
	*/
	propagateFieldsToArrProperty(ByRef obj, arrPropertyName, includeObjects:=false) {
		arr:= obj[arrPropertyName]
		clone:= obj.clone()
		clone.delete(arrPropertyName)
		for i, element in arr {
			element.applyDefaults(clone)
		}

	}
}

/*
	ObjPropertyMaxValue

	get max value from a list of objects. Value should be numeric type.

	@param arr
	@return - empty if list is empty

	Remarks - not handling sufficently large numbers in negative direction
*/
ObjPropertyMaxValue(objArr, propertyName) {
	if (objArr.count() < 1) {
		return 
	}
	max:= -99999999999999999
	for i, obj in objArr {
		if (obj[propertyName] > max) {
			max:= obj[propertyName]
		}
	}
	return max
}

;@Deprecated
/*
	ObjHasAnyKey

	Test if object has any properties.
*/
ObjHasAnyKey(obj) {
	for key, val in obj {
		return true
	}
	return false
}


/*
	Misc functions
*/

IsBoolean(b) {
	return (b = "true" || b = "false")
}

IsEven(int) {
	return (Mod(int, 2) = 0)
}

IsOdd(int) {
	return (Mod(int, 2) = 1)
}

/*
	Coalesce

	Return first non empty string value in an array.

	Remarks
		- integer 0 is considered non empty/non null. This is intended for strings, not for detecting falsy values
		- argument is varargs. to Coalesce an array, use ArrayBase.coalesce()
		- @PSR This is not short circuiting. If performing inline calls, be careful of performance of those calls. This should be considered a syntatic sugar to avoid doing nested ternary.
	@param args
*/
Coalesce(args*) {
	for i, val in args {
		if (!(val = "")) {
			return val
		}
	}
}

CoalesceStrict(thisFunc, args*) {
	first:= Coalesce(args*)
	if (first = "") {
		throw "CoalesceStrict - no item produced. At: " thisFunc
	}
	return first
}

/*
	CoalesceFalsy

	Same as coalesce method but falsy values are consider empty/null. This is a separate method to avoid erroneous missing default parameter, if one were added for isFalsy

	Remarks
		- Objects are considered non empty. Future enhancement may include detecting if it is an ObjectBase with no props.
*/
CoalesceFalsy(args*) {
	for i, val in args {
		if (val) {
			return val
		}
	}
}

/*
	nvl

	If value is empty, change it to default value.
*/
nvl(value, default) {
	if (value = "") {
		value:= default
	}
	return value
}

/*
	RegexMatchAll

	Match all of a single subpattern. To get all subpatterns within a single match, use RegexMatchAllSubpatterns
	Remarks
	we should use a match object, then count matches. This version will not return if an empty string match is produced.
	;https://www.autohotkey.com/docs/v1/lib/RegExMatch.htm#MatchObject
*/
RegexMatchAll(str, regex) {
	matchedSubpatterns:= []
	pos:= 1
	While (Pos := RegExMatch(str,regex,m,Pos+StrLen(m))) {
   		if(m) {
			matchedSubpatterns.push(m)
		}
	}
	return matchedSubpatterns
}

/*
	RegexMatchSubPattern

	Convenience method to do regex match and return a singular capturing subpattern. RegexMatch() stores each subpattern match in a pseudo array, which adds another step to assign a local variable then return var1.
*/
RegexMatchSubPattern(str, regex, subpatternIdx:=1) {
	RegexMatch(str, regex, match)
	varName:= "match" subpatternIdx
	subPatternValue:= %varName%
	return subPatternValue
}


/*
	RegexMatchAllSubPatterns

	@Deprecated
	@return Arr<SubPattern matches> ie [$1, $2, $3...]
*/
RegexMatchAllSubPatterns(str, regex) {
	pos:= 1
	While (Pos := RegExMatch(str,regex,m,Pos+StrLen(m))) {
		matchedSubPatterns:= []
		while (subPattern:= m%A_Index%) {
			matchedSubpatterns.push(m%A_Index%)
		}
	}
	return matchedSubpatterns
}

/*
	FormatString

	Alternative to Format() That supports objects by putting them in a json-like form (unescaped). It also supports cyclic object references, max print depth for objects. This function is intended to be used for display purposes only. FormatString is not a formal serialization of ahk objects. See fileWriter.write or Jxon classes for serialization.
	
	;https://www.autohotkey.com/docs/v1/lib/Format.htm

	Forked from LoggerClass with slight differences.

	Remarks
		- if obj implements toString, is is assumed it wont have any circular references.

	@global FORMATSTRING_PRINT_DEPTH - this is static for now but could be exported to scriptconfig as needed

*/
global FORMATSTRING_PRINT_DEPTH:= 5
FormatString(ByRef str, args*) {
	for i, obj in args {
		if (IsObject(obj)) {
			if (obj.toString) {
				obj:= obj.toString()
			} else {
				try {
					obj:= objectUtil.toCleanString(obj, obj.__class,,,FORMAT_STRING_PRINT_DEPTH)
				}
			}
			
		}
		str:= StrReplace(str, "{" i "}", obj)
	}
	return str
}

/*
    ObjectCacheClass

    @cache
*/
class ObjectCacheClass extends ObjectBase {
    register(obj, aliases*) {
        for i, alias in aliases {
            existing:= this[alias]
            if (existing) {
                throw this.FATAL("MacroAlreadyExists: {1}", alias)
            }
            this[alias]:= obj
        }
    }

    /*
        get

        @param strict default:true -supports object values in cache only.
    */
    get(alias, strict:=true) {
        obj:= this[alias]
        if (strict && !IsObject(obj)) {
            throw this.WARN("Object doesnt exist in cache. Key: {1}", alias)
        }
        return obj
    }
}

global objectUtil:= new ObjectUtilClass() ;@Export objectUtil

/*
	ClassFromClassName

	Remarks
		- This can only be used for classes currently loaded by the script. If the classes arent loaded, use ClassInfo class.
	@hack this should go somewhere else?
*/
ClassFromClassName(className) {
	try {
		clazz:= %className%
	}
	return clazz
}
