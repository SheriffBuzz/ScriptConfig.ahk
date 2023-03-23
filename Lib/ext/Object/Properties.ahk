#Include %A_LineFile%\..\ObjectBase.ahk

/*
    Properties

    Generic container object to store properties. properties can be accessed via ahk accessor syntax or by passing the full property key, delimited by the accessor operator (period)

    This class is intended for properties stored in .ini or .properties files.

    Usecase:
        - .ini or .properties files
        - localization and internationalization.

    Remarks
        - Nodes in the object tree are stored as ObjectBase.
        - The last "leaf" subcomponent of the property key is stored as a string.
        - Only the top level object is a PropertiesClass, the rest are ObjectBase. May be changed if we need to support properties hierarchy
	
	TODO support keys that can store a prop and a separate nested child hierarchy.
		ie.
		meta.field.order="abc"
		meta.field.order.subcomp="subcomp val"
*/
class PropertiesClass extends ObjectBase {
    /*
        get

        @param accessorPattern: String, delimited by accessor operator (period).
            -ie. "meta.field.order.orderNo"

        Remarks
            - values can also be retrieved directly using the ahk accessor operator. This method is for sending the full key (string)
    */
    get(accessorPattern) {
        splitAccessorPattern:= StrSplit(accessorPattern, ".")
		currentObjRef:= this
		leafProp:= splitAccessorPattern.pop()
		for i, comp in splitAccessorPattern {
			currentObjRef:= currentObjRef[comp]
		}
		return currentObjRef[leafProp]
    }

    /*
		addKeyValueMapping

		Add fields to an object using a key value mapping, where key can include components separated by the accessor operator (period). This is the main parsing loop for ini and configuration files.

		TODO export this method to objectbase or objectutils. TODO overwrite param

		@param accessorPattern - key in ini or properties file, containing only alphanumeric or period.
		@param value
	*/
	addKeyValueMapping(accessorPattern, value) {
		splitAccessorPattern:= StrSplit(accessorPattern, ".")
		currentObjRef:= this
		leafProp:= splitAccessorPattern.pop()
		for i, comp in splitAccessorPattern {
			if (!currentObjRef[comp]) {
				currentObjRef[comp]:= {}
			}
			currentObjRef:= currentObjRef[comp]
		}
		currentObjRef[leafProp]:= value
	}

	fromLines(lines) {
		properties:= new PropertiesClass()
		for i, line in lines {
			firstChar:= CharAt(line, 1)
			if (!line || firstChar = "#" || firstChar = "[") {
				continue
			}
			splitLine:= StrSplit(line, "=",,2)
			if (splitLine.count() = 2) {
				properties.addKeyValueMapping(splitLine[1], splitLine[2])
			}
		}
		return properties
	}

	toString() {
		lines:= []
		for key, val in this {
			lines.push(key "=" val)
		}
		return CombineArray(lines, "`n")
	}
}
