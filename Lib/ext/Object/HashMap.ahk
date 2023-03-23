#Include %A_LineFile%\..\ObjectBase.ahk

/*
    HashMap

    Class to enhance ObjectBase for map operations

    Using ObjectBase as a hashmap is fine in most cases, but in some cases (like sorting by unique id of an object) this isnt reliable if the algorithm uses a method of object base. In this case, the method will get overriden by assigning to the uniqueid key. (note this class does not extend objectbase)
*/
class HashMap {
    __New() {
        this.lookupTable:= {}
    }

    put(key, entry) {
        this.lookupTable[key]:= entry
    }

    /*
        putAllObjects

        @PSR
    */
    putAllObjects(uniqueIdPropName, ByRef objArr) {
        for i, obj in objArr {
            this.put(obj[uniqueIdPropName], obj)
        }
        return this
    }

    /*
        values

        Return all values in the map

        Remarks
            - We cant use interal ObjectBase structure.values() as we could have a prop called values that would override the method. So this method is just a copy of ObjectBase.values
    */
    values() {
        vals:= []
        for i, element in this.lookupTable {
			vals.push(element)
        }
		return vals
    }
}
