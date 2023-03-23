/*
    ComObject

    Wraps v1 ComObjectCreate method -> v2 ComObject class
        - note that ComObjQuery is v2 compliant

    @commandWrapper
*/
ComObject(CLSID, IID:="") {
    ;Passing blank param for IID causes error
    if (IID) {
        return ComObjCreate(CLSID, IID)
    }
    return ComObjCreate(CLSID)
}
