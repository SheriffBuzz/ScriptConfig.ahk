#Include %A_LineFile%\..\..\core\Exports.ahk

#Include %A_LineFile%\..\ArrayUtils.ahk
#Include %A_LineFile%\..\..\string\StringUtils.ahk
#Include %A_LineFile%\..\ArrayBase.ahk

/*
	ObjectBase

	https://www.autohotkey.com/board/topic/83081-ahk-l-customizing-object-and-array/

	BaseObject to override the native ahk object. We add additional methods that can be used even when declarations use {} to initialize an object.

	Remarks
		- THIS FILE MUST BE INCLUDED. ScriptConfig includes Array.ahk and Object.ahk. Lib classes may include this file or ScriptConfig.ahk directly, but may also be excluded from library classes iff the top level script includes ScriptConfig.
*/
class ObjectBase {
	/*
		isArray

		Function that can be used to distinguish ArraysBase from Object base. This is an an enhancement of the ahk build in IsObject() which cannot distinguish our user defined ObjectBase and ArrayBase types.

		@See ArrayBase IsArray() and ArrayUtils IsArray(). Global method is preferred as it also checks if the item is a primative.
	*/
	isArray() {
		return false
	}

	/*
		equals - base equals method.

		TODO compare custom class types. for now, we compare logical structure of key value pairs only.

		Remarks
			-  THIS METHOD COMPARES LOGICAL EQUALITY. Compare this to Java where Object.equals() compares references, but it is designed to be overriden and compare logical equivalence. Since we may not be overriding object in many cases, it is nice to have equals compare logical equivalence.
	*/
	equals(that) {
		for i, el in this {
			thatEl:= that[i]
			if (IsObject(el)) {
				if(!IsObject(that) || !el.equals(that)) {
					return false
				}
			} else {
				if (!(el = thatEl)) {
					return false
				}
			}
		}
		return true
	}

	/*
		toString

		To string method that can handle cyclic references.

		@return string If overriding toString, you must keep a contract that the object has no circular references.

		Remarks
			- Using maxPrintDepth of the toCleanString method, but this may need to be parameterized further if needed
	*/
	toString() {
		return objectUtil.toCleanString(this, this.__Class)
	}

	/*
		getClass

		Return concrete class name of custom object.

		@param includePostfix: boolean. default true. Determine if "Class" should be kept. By convention, we name all our classes with "Class" as postfix, but it may be useful for logging or display purposes to omit it.
	*/
	getClass(includePostfix:=true) {
		return (incluePostfix) ? this.__Class : StrGetBeforeLastIndexOf(this.__Class, "class")
	}

	/*
		getClassName

		@Deprecated use getSimpleClassName()
	*/
	getClassName() {
		return this.getClass(false)
	}

	/*
		getSimpleClassName

		Return Simple class name. Omit Class postfix.

		@PSR
	*/
	getSimpleClassName() {
		return classUtil.getSimpleClassName(this.__Class)
	}

	/*
        applyDefaults - apply properties from another object on the current model. If prop already exists on accepting object, properties are not applied.
        @param defaults

		Remarks
			- This method can be used for deserialization if using objectReader or objectTransformer, by overriding the method. This is necessary if any serialized object contains custom class types as instance members.
    */
    applyDefaults(ByRef defaults) {
        if (!IsObject(defaults)) {
            return
        }
        for key, val in defaults {
            sourceVal:= this[key]
            if (sourceVal = "") {
                this[key]:= val
            }
        }
		return this
    }

	/*
		apply - apply properties from another object on the current model. Always applies properties regardless of accepting object's prop values.
	*/
	apply(ByRef defaults) {
        if (!IsObject(defaults)) {
            return
        }
        for key, val in defaults {
            this[key]:= val
        }
    }

	/*
		applyNonEmpty

		Apply properties, iff they are non emtpy. This is different than applyDefaults as the target object property will get overwritten even if it is present, as long as the source prop is non empty.
	*/
	applyNonEmpty(ByRef defaults) {
        if (!IsObject(defaults)) {
            return
        }
        for key, val in defaults {
			if (val == "") {
				continue
			}
            this[key]:= val
        }
	}

	/*
		assertRequiredFields

		For all @param requiredFields, assert that all fields are non empty. 
	*/
	assertRequiredFields(requiredFields, thisFunc:="") {
		missingFields:= []
		nonEmptyValueKeyList:= this.nonEmptyValueKeyList()
		for i, requiredField in requiredFields {
			if (!nonEmptyValueKeyList.contains(requiredField)) {
				missingFields.push(requiredField)
			}
		}
		if (missingFields.count() > 0) {
			throw this.WARN("Assert Required fields: The following keys have an empty value, but are required. {1} at {2}", missingFields)
		}
	}

	/*
		emptyValueKeyList

		For each prop in object, return list of keys that have non empty values.
	*/
	emptyValueKeyList() {
		keys:= []
		for key, val in this {
			if (val = "") {
				keys.push(key)
			}
		}
		return keys
	}

	/*
		nonEmptyValueKeyList

		For each prop in object, return list of keys that have non empty values.
	*/
	nonEmptyValueKeyList() {
		keys:= []
		for key, val in this {
			if (val != "") {
				keys.push(key)
			}
		}
		return keys
	}

	/*
		add

		@PSR todo
	*/
	add(key, value) {
		this[key]:= value
	}
	/*
		serialize - called by object writer/reader. used to serialize and revive custom class objects from json.
	*/
	serialize() {
		this.className:= this.__Class
	}
	
	/*
		deserialize - called by object writer/reader. used to serialize and revive custom class objects from json.

		This method is reserved future use, for now override applyDefaults for using with objectReader/objecttransformer.
	*/
	/*
	deserialize(plainObject) {
		;this.delete("className") ;this is a template. this should be added but is not added to base for now as this is considered experimental
	}
	*/

	/*
		LOGGING SECTION

		ObjectBase has logging methods that match Logger.ahk methods. We can use these to add the custom class name to the log statement. This is preferred for logging inside custom class objects.
	*/
	WARN(msg, args*) {
		return this.LOG(msg, "WARN", args*)
	}
	INFO(msg, args*) {
		return this.LOG(msg, "INFO", args*)
	}
	DEBUG(msg, args*) {
		return this.LOG(msg, "DEBUG", args*)
	}
	FATAL(msg, args*) {
		return this.LOG(msg, "FATAL", args*)
	}
	LOG(msg, logLevel, args*) {
		logRef:= (this.logger) ? this.logger : logger
		if (!logRef) {
			return FormatString(msg, args*)
		}
		;TODO push this down to logger, as this is computed regardless of log level.
		msg:= ("[" StrPadLeft(this.getClassName(), logger.maxClassNameSize, " ", true) "] " msg)
		msg:= logRef[logLevel](msg, args*)
		return msg
	}

	/*
		keys

		@return arr of keys, lexicographically ordered
	*/
	keys() {
		keys:= []
		for i, element in this {
			keys.push(i)
		}
		return keys
	}

	/*
		values
		
		get values in an array. key information is lost an replaced with array indecies.

		@return values type:ArrayBase
	*/
	values() {
		vals:= []
		for i, element in this {
			vals.push(element)
		}
		return vals
	}

	/*
		flatMapArrayValues

		Given a structure Obj<key, Arr<T>>, return Arr<T>
	*/
	flatMapArrayValues() {
		container:= []
		for i, arr in this {
			for j, arrElement in arr {
				container.push(arrElement)
			}
		}
		return container
	}

	isEmpty() {
		for key, element in this {
			return false
		}
		return true
	}

	/*
		hasProperty that handles empty string. Not performant for objects with large number of keys
	*/
	hasProperty(prop) {
		for key, element in this {
			if (key = prop) {
				return true
			}
		}
		return false
	}

	/*
		simplehashcode. produces concat of string's values. not optimized for key size. currently hash objects address only.
		skipProps*
	*/
	hashCode(skipProps*) {
		hash:=""
		for key, el in this { ;assume logical ordering of object keys
			if (ArrContains(skipProps, key)) {
				continue
			}
			;hash.= (IsObject(el)) ? el.hashCode() : el
			hash.= el
		}
		return hash
	}

    trayTip(msg) {
        TrayTip(msg, this.getClassName())
    }
	
	/*
		processStringPropertyMacros

		replace all all props that have a string value with Lib\ext\datatransform\macro replacement, using standard global ref "macroProcessor".

		Remarks
			- If macroprocessor is not included, processing will be skipped with a warning. ObjectBase does not include a macroprocessor.
	*/
	processStringPropertyMacros(macroContext:="") {
		if (!IsObject(macroProcessor)) {
			this.FATAL("processStringPropertyMacros: no global variable with name 'macroprocessor' found. Macros will not be processed.")
		}
		for key, element in this {
			if (IsObject(element)) {
				continue
			}
			this[key]:= macroProcessor.process(element, macroContext)
		}
	}

	/*
		AbstractMethod

		This method throws an error, with a descriptive message. An overriding class must implement the method that calls this method.
	*/
	abstractMethod(thisFunc) {
		msg:= this.WARN("{1} is abstract but is not overriden in concrete type: {2}. Extend this class and implement the method.", thisFunc, this.getClassName())
		throw msg
	}

	/*
		largestValueByProcedingKey

		For numeric indecies, return the key is the largest without equaling or exceeding the @param key.
	*/
	lastIndexBeforeKey(searchKey) {
		keyIdx:=
		for key, el in this {
			if (key < searchKey) {
				keyIdx:= key
			} else {
				break
			}
		}
		return keyIdx
	}
}

;@v1start
/*
	Object Constructor

	;@Override
	;@HACK using object syntax passes the key and values in tuples.
	;Do not name the parameter args, otherwise it may break..
*/
Object(params*) {
    obj := new ObjectBase
    ; For each pair of parameters, store a key-value pair.
    Loop % params.MaxIndex()//2
        obj[params[A_Index*2-1]] := params[A_Index*2]
    return obj
}
;@v1end
;@v2start
;Object.prototype:= ObjectBase
;@v2end