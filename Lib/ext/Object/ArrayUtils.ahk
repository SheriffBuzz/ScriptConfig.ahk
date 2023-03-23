#Include %A_LineFile%\..\..\string\StringUtils.ahk
#Include %A_LineFile%\..\MapList.ahk

/*
    ArrayUtils.ahk
*/
class ArrayUtilsClass {
    contains(thiz, that) {

    }

	/*
		disjunctiveUnion

		Find elements present in one set but not both
	*/
	disjunctiveUnion(thiz, that) {
		disjunctiveUnion:= []
		for i, element in that {
			if (!thiz.contains(element)) {
				disjunctiveUnion.push(element)
			}
		}
		return disjunctiveUnion
	}

	/*
		findDuplicateUniqueIds

		@return uniqueIds List of unique ids that have duplicates
	*/
	findDuplicateUniqueIds(objArr, uniqueIdName) {
		lookupMap:= new MapList().addAll(uniqueIdName, objArr)
		duplicateUniqueIds:= []
		for uniqueId, arr in lookupMap {
			if (arr.count() > 1) {
				duplicateUniqueIds.push(uniqueId)
			}
		}
		return duplicateUniqueIds
	}
}
global arrayUtils:= new ArrayUtilsClass()

DeepCopyArr(ByRef arr) {
    arrCopy:= []
    for i, val in arr {
        arrCopy[i]:=arr[i]
    }
    return arrCopy
}

/*
	rankArrHighToLow

	Given an input array of integers, rank each element by its value, from high to low.

	@param input - array of integers
	@return rankedArr - associative array with keys being elements from original array and values being a ranking 1 - N. If the key has the highest rank, value will be 1. If lowest rank, it will be input.Length().
*/
rankArrHighToLow(ByRef input) {
    arr:= []
    idxProcessed:= []

    for i, outer in input {
        max:= -999999
        idx:= 0
        for j, intVal in input {
            if (intVal > max && !idxProcessed[j]) {
                idx:= j
                max:= intVal
            }
        }
        arr[i]:= idx
        idxProcessed[idx]:= 1
    }
    return arr
}

/*
	GetPaddedArr2dByLargestColumn

	Slightly modified version of Grid.getPaddedGridByLargestColumn to work without header
*/
GetPaddedArr2dByLargestColumn(arr2d, char:=" ", leadingPad:=true) {
	columnIdxToCellLengthMap:= []

	for j, columnName in arr2d[1] {
		cellLength:= columnIdxToCellLengthMap[j]
		if (cellLength < 1 || cellLength = "") {
			cellLength:= 0
		}
		for i, row in arr2d {
			cell:= row[j]
			if (StrLen(cell) > cellLength) {
				cellLength:= StrLen(cell)
			}
		}
		columnIdxToCellLengthMap[j]:= cellLength
	}
	
	updatedData:=[]
	updatedHeader:= []
	for i, row in arr2d {
		updatedData[i]:=[]
		curColumn:= 1
		for j, cell in row {
			columnLength:= columnIdxToCellLengthMap[j]
			len:= StrLen(cell)
			diff:= columnLength - len
			updatedCell:= (diff) ? ((leadingPad) ? StrGetPad(char, diff) cell : cell StrGetPad(char, diff)) : cell
			updatedData[i][curColumn]:= updatedCell
			curColumn:= curColumn + 1
		}
	}
	return updatedData
}

Arr2dToString(arr2d, columnCombiner, rowCombiner, rowPrefix) {
	rows:= []
	for i, row in arr2d {
		rowStr:= CombineArray(row, columnCombiner)
		rowStr:= (rowPrefix) ? rowPrefix RowStr : rowStr
		rows.push(rowStr)
	}
	return (CombineArray(rows, rowCombiner))
}

/*
	ArrContains

	@return foundIdx
*/
ArrContains(ByRef arr, str) {
	for i, val in arr {
		if (val = str) {
			return i
		}
	}
}

/*
	Array Filter

	Returns a new array containing elements where filterVals contains arr[i]

	Equivalent to source.stream().filter(val -> filterVals.contains(val)).collect(Collectors.toList()) in java

	Remarks - only works for array types
*/
ArrayFilter(ByRef arr, ByRef filterVals) {
	filtered:= []
	for i, val in arr {
		if (ArrContains(filterVals, val)) {
			filtered.push(val)
		}
	}
	return filtered
}

/*
	ArrRemoveDuplicates - remove duplicates using "hashset"
	@param arr.
	@return modified unique arr
*/
ArrRemoveDuplicates(ByRef arr) {
	set:=[]
	for i, val in arr {
		set[val]:= 1
	}
	unique:= []
	for i, val in arr {
		if (set[val] = 1) {
			set[val]:= 0
			unique.push(val)
		}
	}
	return unique
}


/*
	ArrMapByPropertyName
	
	Map a collection into a collection of some property. Since we cant pass anonymous functions, it is restricted to property name instead of a mapper function.
	Similar java syntax: collection.stream().map(order -> order::getOrderId).collect(Collectors.toList())
*/
ArrMapByPropertyName(ByRef arr, prop) {
	container:= []
	for i, obj in arr {
		container.push(obj[prop])
	}
	return container
}

/*
	ArrFromStringOrArr

	Takes variable and coerces to array. If IsObject(), return input, otherwise return line separated value
*/
ArrFromStringOrArr(ByRef obj, delimiter:="`n") {
	if (IsObject(obj)) {
		return obj
	}
	if (!obj) {
		return []
	}
	return StrSplit(obj, delimiter, "`r")
}

/*
	ArrRTrim

	Trim array for empty string value
*/
ArrRTrim(arr) {
	i:= arr.MaxIndex()
	while (i > 0) {
		if (arr[i] = "") {
			arr.RemoveAt(i)
		}
	}
	return arr
}

/*
	ArrMerge
	merge arbitrary number of iterable sources into new collection view.
*/
ArrMerge(args*) {
	merge:= []
	for i, iterable in args {
		merge.addAll(iterable)
	}
	return merge
}

/*
	ArrDefault

	Asserts element is an array. if not an array, wrap the element in an array.
	
	This can be used to accept array or string arguments to function parameters. If the caller passes an array, the array will be used. if they pass a simple string, it will be wrapped in an array.
	
	@param isEmptyIsElement - Determines if empty value should be considered an array with 1 element (empty string) or an array with 0 elements. For function parameters, it is most likely that you want an empty array, as an empty value indicates a blank optional parameter.
*/
ArrDefault(ByRef element, isEmptyIsElement:=false) {
	if (IsArray(element)) {
		return element
	} else if (element) {
		return [element]
	} else if (isEmptyIsElement) {
		return [""]
	}else {
		return []
	}
}

/*
	ArrUnbox

	Unbox a container, given a mixed list of primatives or single dimension arrays.

	Remarks
		- We use IsObject() instead of checking __Class prop, to support classes that extend array base. If we implement a propper instanceof function, we may be able to throw an error or handle user passing objects.
*/
ArrUnbox(args) {
	container:=  []
	for i, val in args {
		if (IsArray(val)) {
			container.addAll(val)
		} else {
			container.push(val)
		}
	}
	return container
}

/*
	IsArray

	Function that can be used to distinguish ArraysBase from Object base. This is an an enhancement of the ahk build in IsObject() which cannot distinguish our user defined ObjectBase and ArrayBase types.

	Remarks
		- This function supports any class that extends ArrayBase.
		- IsArray is a reserved property, it should not be overridden.
	
	@param element
	@param emptyAllowed - allow empty value. This can be useful for validating default parameters
*/
IsArray(ByRef element, emptyAllowed:=false) {
	if (emptyAllowed && element = "") {
		return true
	}
	return IsObject(element) && element.isArray()
}
