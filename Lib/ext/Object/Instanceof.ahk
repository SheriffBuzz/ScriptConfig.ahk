/*
    Instanceof.ahk

    Determine if a class is an instance of another superclass custom type.
*/
InstanceOf(thiz, ByRef that) {
    while (thiz.__Class) {
        thizClass:= thiz.__Class
        thatClass:= (that.base.__Class) ? that.base.__Class : that.__Class
        if (thizClass = thatClass) {
            return true
        }
        thiz:= thiz.base
    }
}
