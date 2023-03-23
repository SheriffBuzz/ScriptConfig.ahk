/*
	HashSet
	
	Implementation of set data structure

	Remarks
		- only non-object values are supported, due to lack of hash function/equals - 11/24/22 TODO we can now support this with ObjectBase.contains
		- Naming convention - HashSet - if you name a ref the same name as the class, reassigning the ref overrides the class definition ()
			- AHK isnt case sensitive for function names so cant name classes upper and object lower
			- https://www.autohotkey.com/boards/viewtopic.php?t=37011
*/
class HashSet {
	__New(ByRef items:="") {
		this.uniqueMap:=[]
		if (IsObject(items)) {
			this.addAll(items)
		}
	}
	
	contains(key) {
		return (this.uniqueMap[key] = true)
	}

	add(key, allowNull:=false) {
		if (!allowNull && key == "") {
			return false
		}
		this.uniqueMap[key]:= true
		return true
	}

	addAll(keys, allowNull:=false) {
		for i, key in keys {
			this.add(key, allowNull)
		}
		return this
	}

	/*
		remarks - while set guarentees no ordering of keys, they will be implicitly ordered by AHK natural ordering
	*/
	toArray() {
		arr:= []
		for val, flag in this.uniqueMap {
			arr.push(val)
		}
		return arr
	}

	;TODO enumerator object. for now can use toArray()

	count() {
		return this.uniqueMap.count()
	}
}

/*
	Set implementation that can store object references, using a hash function.

	Internal structure is [hash -> obj]

	Remarks - hash function is Function<Obj,String>. If this function is an instance method of a class, use the parameter obj and not this reference as this object is used by multiple instances of a class. (should be effectively static)
*/
class ObjectHashSet {
	__New(hashFunction, ByRef items:="") {
		this.hashMapping:= {}
		this.hashFunction:= hashFunction
		if (IsObject(items)) {
			this.addAll(items)
		}
	}
	
	contains(obj) {
		return this.hashMapping[this.hashFunction(obj)] != ""
	}

	add(obj) {
		if (!IsObject(obj)) {
			return
		}
		if (this.contains(obj)) { ;todo remove duplicate hashFunction call
			return false
		}
		hash:= this.hashFunction(obj)
		this.hashMapping[hash]:= obj
		return true
	}

	addAll(arr) {
		for i, obj in arr {
			this.add(obj)
		}
	}

	/*
		remarks - while set guarentees no ordering of keys, they will be implicitly ordered by AHK natural ordering
	*/
	toArray() {
		arr:= []
		for hash, val in this.hashMapping {
			arr.push(val)
		}
		return arr
	}
}
