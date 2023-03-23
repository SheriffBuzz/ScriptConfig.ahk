/*
    Func

    Wrapper for v1 func. in v2, just use the function ref.

    @v2upgrade convert Func() refs. in v1 we will convert existing v1 refs to this function, then 
*/
FuncRef(fnName) {
    ref:= Func(fnName)
    return ref
}
