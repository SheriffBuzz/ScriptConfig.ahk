#Include %A_LineFile%\..\ArrayUtils.ahk
#Include %A_LineFile%\..\ObjectBase.ahk
#Include %A_LineFile%\..\HashSet.ahk

/*
	ArrayBase

	<a href=https://www.autohotkey.com/board/topic/83081-ahk-l-customizing-object-and-array target="_blank">Customizing-object-and-array</a>

	Base class for Array that will be used as base for native ahk arrays. By setting base inside the Array() method, we can set the base.

	Using a custom base class allows us to add additional methods to native arrays.

	Subclasses of ArrayBase, but adding instance properties is not allowed. It interferes with build in functions like maxIndex and count. Adding methods is ok.
		- IMPORTANT: methods that return an array type should use new %clazz% instead of [], so concrete class type is preserved for classes that extend ArrayBase.

	Remarks
		- THIS FILE MUST BE INCLUDED. ScriptConfig includes Array.ahk and Object.ahk. Lib classes may include this file or ScriptConfig.ahk directly, but may also be excluded from library classes iff the top level script includes ScriptConfig.
        - Arrays returned from Ahk built in functions aren't guaranteed to return an ArrayBase. Example is StrSplit. Existing libraries should have any arraybase methods from an array returned by str split, but new ones going forward that need arraybase methods need to create a new array with ref:= [] then do ref.addAll(StrSplit(...)). Or shorter, [].addAll(StrSplit(...))
*/
class ArrayBase extends ObjectBase {
	__New(base) {
		this.base:= IsObject(base) ? base : []
	}

	/*
		isArray

		Function that can be used to distinguish ArraysBase from Object base. This is an an enhancement of the ahk build in IsObject() which cannot distinguish our user defined ObjectBase and ArrayBase types.

		@See ObjectBase IsArray() and ArrayUtils IsArray(). Global method is preferred as it also checks if the item is a primative.
	*/
	isArray() {
		return true
	}
	/*
		slice

		Remarks
			- since AHK is 1 indexed, we start with idx 1. Likewise, END IDX IS INCLUSIVE!!!
			- use limit when endIdx is computed and may resolve to zero. When using this method, passing zero as endIdx may not always result in zero elements.
	*/
	slice(start:=1, end:=0) {
		sub:= []
		if (end > this.maxIndex() || end < 1) {
			end:= this.maxIndex()
		}
		while (start <= end) {
			sub.push(this[start])
			start:= start + 1
		}
		return sub
	}

	/*
		limit

		Take first n elements in array.

		Similar to java streams limit. Similar to javascript slice.
	*/
	limit(n) {
		filtered:= []
		i:= 1
		while (i <= n) {
			filtered.push(this[i])
			i++
		}
		return filtered
	}

	/*
		splice

		Splice fn modeled after js splice. This is a mutating operation.
	*/
	splice(startIdx:= 1, deleteCount:= 0, newItems*) {
		while (deleteCount > 0) {
			this.removeAt(startIdx + 1)
			deleteCount--
		}
		insertIdx:= startIdx + 1
		for i, newItem in newItems {
			this.insertAt(insertIdx, newItem)
			insertIdx++
		}
		return this
	}

	/*
		contains

		Contains method based on logical equality
		@return int: int - idx of found element, 0 if not found
	*/
	contains(ByRef value) {
		;TODO use equals method for objects
		for i, el in this {
			if (IsObject(value)) {
				if(el.equals(value)) {
					return i
				}
			} else if (el = value) {
				return i
			}
		}
		return 0
	}

	containsAll(ByRef propsArr) {
		for i, value in propsArr {
			if (!this.contains(value)) {
				return false
			}
		}
		return true
	}

	/*
		toObject

		@return object type:ObjectBase Lookup Map
	*/
	toObject(columnNameByColumnIdx) {
		obj:= {}
		;setCapacity?
		for columnIdx, columnName in columnNameByColumnIdx {
			obj[columnName]:= this[columnIdx]
		}
		return obj
	}

	toHashSet() {
		set:= new HashSet()
		set.addAll(this)
		return set
	}

	/*
		sortByUniqueId

		Sort array by uniqueId field.

		Sort by uniqueId. Sorting by uniqueId allows us to skip the implementation of a sorting algorithm and instead use a hashset. We currently do not have an array sort algorithm, in most cases it is ok to use ahk's native object key ordering for sorting.

		@param uniqueIdPropName Restriction - must not contain any invalid object key characters such as `r or `n
		@param inplace type:boolean If true, sort will be done in place. Even so, this method uses a naive algorithm that creates and entire array copy (it is not space efficient).
		@param strict should we assert that array size is the same before and after sort. This will throw an error if @param uniqueIdPropKey name does not uniquely identify every array element.
		@TODO consider strict mode also validating if uniqueId contains invalid object key characters
	*/
	sortByUniqueId(uniqueIdPropName:="", inPlace:= true, strict:=true) {
		sortedArray:= new HashMap().putAllObjects(uniqueIdPropName, this).values()
		if (strict && this.count() != sortedArray.count()) {
			throw this.WARN("{1}: Sort is invalid. Using simple hashSet algorithm, not all array entries are uniquely identifiable by @param uniqueIdPropName. This will return less results in the returned array. Expected size: {2} actual: {3} Duplicate unqiueIds: {4}", A_ThisFunc, this.count(), sortedArray.count(), arrayUtils.findDuplicateUniqueIds(this, uniqueIdPropName))
		}
		if (inPlace) {
			this:= sortedArray
			return this
		}
		return sortedArray
	}

	/*
		Sort
		
		Sort using ahk natural object key ordering (lexicographical, not compatible with objects)

		@PSR this method uses a hashset to sort keys.
	*/
	sort(inPlace:= true) {
		set:== new HashSet()
		set.addAll(this)
		sortedArray:= set.toArray()
		if (inPlace) {
			this:= sortedArray
			return this
		}
		return sortedArray
	}

	/*
		toUniqueIdMap

		return map from key name to object, given a unique id key name.

		Usecase:
			Sql rowId to object row

		@deprecated for rename
		@param uniqueIdPropertyName - name of property that uniquely identifies an object within the current arr<object>
			- param can be the name of a method. funcRef<Supplier> that produces a uniqueId
	*/
	toUniqueIdMap(uniqueIdPropertyName) {
		uniqueIdMap:= {}
		
		for i, element in this {
			if (IsObject(element[uniqueIdPropertyName])) { ;func
				uniqueIdValue:= element[uniqueIdPropertyName]()
			} else {
				uniqueIdValue:= element[uniqueIdPropertyName]
			}
			uniqueIdMap[uniqueIdValue]:= element
		}
		return uniqueIdMap
	}
	/*
		toCsvRowString

		create csv string. only supports string (non object) types.
	*/
	toCsvRowString(columnSeparator:="`,", aroundCellDelimiter:="""", isValidCsvEscaping:=true) {
		csvRowString:= ""
		escapedAroundCellDelimiter:= aroundCellDelimiter aroundCellDelimiter
		columnCount:= this.count()
		for j, columnName in this {
			if (isValidCsvEscaping) {
				hasQuotes:= (InStr(columnName, aroundCellDelimiter))
				quoteEscaped:= (hasQuotes) ? StrReplace(columnName, aroundCellDelimiter, escapedAroundCellDelimiter) : columnName
				if (hasQuotes || (InStr(columnName, "`,"))) {
					quoteEscaped:= aroundCellDelimiter quoteEscaped aroundCellDelimiter
				}
				csvRowString.= quoteEscaped
			} else {
				csvRowString.= columnName
			}
			
			if (j < columnCount) {
				csvRowString.= columnSeparator
			}
		}
		return csvRowString
	}

	getValueByIdxMap() {
		valueByIdx:= []
		for idx, element in this {
			valueByIdx[idx]:= element
		}
		return valueByIdx
	}

	/*
		getValueByUniqueIdMap

		Get map by uniqueId, given list of objects.

		Remarks
			- UniqueId must map to a non object value, without newlines
		
		@param uniqueIdMapper - method name for array of custom class objects, otherwise a funcRef Func<T,String>
	*/
	getValueByUniqueIdMap(uniqueIdMapper) {
		valueByUniqueId:= {}
		for idx, element in this {
			uniqueId:= (element[uniqueIdMapper]) ? element[uniqueIdMapper]() : uniqueIdMapper.call(element)
			valueByUniqueId[uniqueId]:= element
		}
		return valueByUniqueId
	}

	/*
		Remarks

		This method is invalid for values that have newlines, or are objects.
	*/
	getIdxByValueMap() {
		idxByValue:= []
		for idx, element in this {
			idxByValue[element]:= idx
		}
		return idxByValue
	}

	/*
		addAll

		@Param arr - array
		@Return this - convenience to chain methods
	*/
	addAll(ByRef arr) {
		for i, val in arr {
			this.push(val)
		}
		return this
	}

	/*
		addMixed

		Add items to an array. Can pass a single item, or an array. If array, then array's contents are added (Only a single layer of array items are unpacked, this does not flatten a nested hierarchy of Arrays)
	*/
	addMixed(ByRef singleItemOrArr) {
		if (IsArray(singleItemOrArr)) {
			this.addAll(singleItemOrArr)
		} else {
			this.push(singleItemOrArr)
		}
	}

	addIf(val) {
		if (val = "") {
			return this
		}
		this.push(val)
		return this
	}

	/*
		addIfAbsent

		Add element to array, if absent.

		This method supports objects that implement an equals method. Otherwise the method may throw a stack overflow if the object has any object backlinks. (See ObjectBase.contains for more)

		If you are calling this method frequently, consider using a HashSet. This method may be more performant for adding a small amount of elements to an array, but HashSet will be faster for a lot of add operations.
	*/
	addIfAbsent(val) {
		if (!this.contains(val)) {
			this.push(val)
		}
		return this
	}

	/*
		peek

		return last element of an array, without popping it.`
	*/
	peek() {
		return this[this.MaxIndex()]
	}

	/*
		popIfEmpty

		Pop last element from array if it is empty.
	*/
	popIfEmpty() {
		if (this.peek() = "") {
			this.pop()
		}
	}
	

	/*
		Coalesce

		return first non empty value. To pass a varargs, see Coalesce() global function

		Remarks
			- @PSR This is not short circuiting. If performing inline calls, be careful of performance of those calls. This should be considered a syntatic sugar to avoid doing nested ternary.
	*/
	coalesce() {
		for i, element in this {
			if (!(element = "")) {
				return element
			}
		}
	}
	
	/*
		allMatch

		Return true if all elements are equal. Intitial impl handles strings (non object) only
	*/
	allMatch() {
		if (this.count() < 2) {
			return true
		}
		match:=
		for i, element in this {
			if (i = 1) {
				match:= element
				continue
			}
			if (!(element = match)) {
				return false
			}
		}
		return true
	}

	/*
		filter elements by regex pattern. for Non object data only.
	*/
	match(regex) {
		filtered:= []
		for i, element in this {
			if (RegExMatch(element, regex)) {
				filtered.push(element)
			}
		}
	}

	/*
		filter elements by regex pattern. for Non object data only.
	*/
	filterOut(regex) {
		filtered:= []
		for i, element in this {
			if (!RegExMatch(element, regex)) {
				filtered.push(element)
			}
		}
		return filtered
	}

	filterByPropName(propName, searchValue) {
		filtered:= []
		for i, element in this {
			elementValue:= element[propName]
			if (IsObject(elementValue)) {
				if (elementValue.equals(searchValue)) {
					filtered.push(element)
				}
			} else {
				if (elementValue = searchValue) {
					filtered.push(element)
				}
			}
		}
		return filtered
	}

	/*
		reverse

		Limitations - only support dense arrays. They array indecies will be reset, so indicies are no longer valid for sparse arrays.
	*/
	reverse() {
		reverse:= []
		maxIdx:= arr.MaxIndex()
		if (maxIdx < 1) {
			return []
		}
		for i, el in this {
			reverse.push(this[maxIdx - i + 1])
		}
		return reverse
	}

	/*
		map

		Mapper function for object types.
		@param functionNameOrRef. If string, it will call an instance method of the input element's class. Otherwise, it must be a funcRef, by calling Func() or ObjBindMethod()

		to retrieve an object's property use the strip method. This method only calls an instance method of a class.

		Remarks
			- You must pass a function reference for functionNameOrRef if any element in the array is a non-object type.
			- only single class type for all array elements is supported, or if each class has the requested method in the case of inheritance
	*/
	map(functionNameOrRef, args*) {
		resultContainer:= []
		isRef:= IsObject(functionNameOrRef)
		for i, element in this {
			if i is not number ;skip props from subclasses
				continue
			if (!IsObject(element) && !isRef) {
				throw "Map: If you pass a string for functionNameOrRef, every element must be an object (calls an instance method on the input element)"
			}
			if (isRef) {
				result:= functionNameOrRef.call(element, args*)
			} else {
				result:= (isRef) ? functionNameOrRef.call(element, args*) : element[functionNameOrRef](args*)
			}
			resultContainer.push(result)
		}
		return resultContainer
	}

	/*
		flatMap

		flatmap a list of objects, that have some prop that is an array.

		@param propName - Name of prop that is an array type
	*/
	flatMap(propName) {
		container:= []
		for i, element in this {
			container.addAll(element[propName])
		}
		return container
	}
	
	/*
		Strip

		Collect each element's value for the given @param propName. prop name is the name of an instance property on a class object. to map via an instance method name, use the map function.
	*/
	strip(propName) {
		acc:= []
		for i, element in this {
			acc.push(element[propName])
		}
		return acc
	}

	/*
		partiton

		This function partitions an array into a Defaulting HashMap, by partition key

		Remarks: This method supports subtypes of arraybase.

		@param propertyNameOrKeymapper
			- if string, then:
				if object has a function with that name, call it, accepting the element
				else take the value of the property - element[propertyNameOrKeyMapper]
			- if object, then keymapper. KeyMapper is func<T,Key> for Element T
		@clazz - custom class type for partition supplier.
		@return partitionMap: ObjectBase<T extends ArrayBase>
	*/
	partition(ByRef propertyNameOrKeyMapper, allowEmptyElement:=true) {
		partitions:= {}
		isRef:= IsObject(propertyNameOrKeyMapper) ;remarks - this doesnt work for instance methods. TODO refactor. workaround below.
		for i, element in this {
			if (!allowEmptyElement && element = "") {
				throw this.WARN("Parititon: Passed allowEmptyElement=false and element was empty, at idx {1}", i)
			}
			if (element && !IsObject(element) && !isRef) {
				throw "Partition: If you pass a string for functionNameOrRef, every element must be an object (calls an instance method on the input element)"
			}

			if (isRef) {
				key:= propertyNameOrKeyMapper.call(element)
			} else if (IsObject(element[propertyNameOrKeymapper])) { ;instancemethod
				key:= element[propertyNameOrKeyMapper](element)
			} else {
				key:= element[propertyNameOrKeyMapper]
			}

			if (key = "") {
				this.WARN("Partition ~ key is empty")
			}

			if (!IsObject(partitions[key])) {
				clazz:= this.__Class
				partitions[key]:= new %clazz%
			}
			partitions[key].push(element)
		}
		return partitions
	}

	/*
		dense

		Convert sparse array into dense array.

		A sparse array is one that has keys with delete() method invoked, or created then assigned values using arr[idx]:= n syntax.

		Remarks
			- indecies are altered.
	*/
	dense() {
		newArr:= []
		for i, element in this {
			newArr.push(element)
		}
		return newArr
	}
	/*
		nonEmpty

		returns collection of all elements in the array are non empty. For ahk, empty is only "". This is not the same as "falsy".
	*/
	nonEmpty() {
		nonEmpty:= []
		for i, element in this {
			if (element != "") {
				nonEmpty.push(element)
			}
		}
		return nonEmpty
	}

	/*
		StrReplace replace each element in array with static pattern
	*/
	strReplace(oldPattern, newPattern) {
		for i, element in this {
			this[i]:= StrReplace(element, oldPattern, newPattern)
		}
	}

	/*
		indexOfObjectProperty

		given array of objects, get index of first one that has property with matching value
	*/
	indexOfObjectProperty(propNameOnObject, value) {
		for i, element in this {
			if (IsObject(element) && element[propNameOnObject] = value) {
				return i
			}
		}
		return ""
	}

	/*
		indexOf

		index of non obj value

		@return idx - idx if found, otherwise 0
	*/
	indexOf(str) {
		for i, element in this {
			if (element = str) {
				return i
			}
		}
		return 0
	}

	applyEach(defaults) {
		for i, element in this {
			element.apply(defaults)
		}
	}

	/*
		join array elements with append. Initial implementation uses no combiner token. Future implementation will use CombineStrings function to support combiner, around token char, etc..

		@TODO include a version for ahk method calls where we want to join by ", " except when empty, we want to omit the space.
	*/
	join(combiner:="", aroundChar:="", ByRef escapeChar:="") {
		return CombineArray(this, combiner, aroundChar, escapeChar, true)
	}

	/*
		applyPrototypeForElements

		@param clazz - class object (not string)
	*/
	applyPrototypeForElements(clazz) {
		for i, element in this {
			element.base:= clazz
		}
	}
}

;@v1start
/*
	Array Prototype

	Do not name the parameter args, otherwise it may break..
*/
Array(params*) {
	params.base:= ArrayBase
	return params
}
;@v1end
;@v2start
;Array.prototype:= ArrayBase
;@v2end



