
/*
	ForEach - runs consumer function on object or array

	@Deprecated
	@param iterableSource - If iterableSource is Ahk "Object", then FuncRef is BiConsumer<K,V>. If "Array", then Consumer<V>.
	@param thiz. - object the scope inside the function will be bound to.
		- Special handling - user can pass string "this" to refer to the current object

	Remarks - object is only guaranteed to be non-array its keys are non integer (string "1" is a string)
*/
ForEach(ByRef iterableSource, functionName, ByRef thiz:="", args*) {
	funcRef:= (IsObject(thiz)) ? ObjBindMethod(thiz, functionName) : Func(functionName)

	if (iterableSource.MaxIndex() > 0) {
		for i, val in iterableSource {
			if (thiz = "this") {
				funcRef:= ObjBindMethod(val, functionName)
			}
			funcRef.call(val, args*)
		}
	} else {
		for key, val in iterableSource {
			funcRef.call(key, val, args*)
		}
	}
}
