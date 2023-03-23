;@TODO This is an inversion, we should port ObjectBase and String Utils to core. (or at least an import to it)
#Include %A_LineFile%\..\..\object\Object.ahk

/*
    BuiltInFunctionResult

    This class encapsulates a return value and optional status code. This is used for wrapping ahk v2 functions that do not return a value. A Previously in v1 we created a function to wrap a v1 command, including additional overrides. However, this would break on upgrade to v2, so we have instead kept our command wrapper functions as close as possible to v2 equivalent and provide a wrapper class to add the extended functionality or return value.

    Goals:
        - Where possible, we prefer functions to return a value instead of returning state to the caller via ByRef params. This is a convenience to mimic languages like java that cannot mutate non object variables ByRef.
        - providing something that returns a value is more flexible for adding additional functionality. If we want to increase the number of variables to return to the caller, we can pass it back via the return value in an object container, including values that arent specified as ByRef params.
        - Provide isError and getDisplayValue methods that can customize if the result of a built in function. We might get an ErrorLevel but it might not be an error per se (empty input or timeout). Base class handles most of the work, all that needs to be done in the overridden method is translating an ErrorLevel to boolean (is it an error) and a display value.
    
    This class has two main props:
        value: the value that would normally be returned by a function return value, but isnt for the ahk v2 function it is wrapping (ie. Image Search doesnt return a value, it only sets input args ByRef).
        result: string message or ErrorLevel.
*/
class BuiltInFunctionResultClass extends ObjectBase {
    /*
        Constructor

        @param value - standard value that would be returned by a function, if the v2 function would return anything. (most likely it is returning a result to the caller with ByRef params)
        @param result - ErrorLevel if function supports it, or custom defined status code. If custom defined status code, you must override isError and getFailureReason methods.
        @param source - Wrapper class obj instance that wraps the v2 function
    */
    __New(value, result, source, isEmptyIsError:=false, isThrowError:=true, isErrorTraytip:=true) {
        this.value:= value
        this.result:= result
        this.source:= source
        this.isEmptyIsError:= isEmptyIsError
        this.isThrowError:= isThrowError
        this.errorTrayTip:= isErrorTraytip
    }

    /*
        getValue

        Get result value as string or custom return type, throwing error if needed.

        @return value - string
    */
    getValue() {
        isError:= this.isError()
        if (isError) {
            failureReason:= this.getFailureReason()
            className:= this.source.getClassName()
            failureMsg:= FormatString("{1} failed: [{2}]", className, failureReason)
            this.WARN(failureMsg)
            if (this.isErrorTrayTip) {
                TrayTip(failureMsg, className)
            }
            if (this.isThrowError) {
                throw failureMsg
            }
        }
        return this.value
    }

    /*
        getResult

        @return result prop ["OK", "Timeout", "Cancel"]
    */
    getResult() {
        return this.result
    }

    /*
        isError

        Default impl returns true iff this.result > 0. (ErrorLevel is set)
    */
    isError() {
        result:= this.getResult()
        return (result && result > 0)
    }
    
    /*
        getFailureReason

        Get display error reason (Note that this may be different that the result prop from the return of the Built in function Call)
    */
    getFailureReason() {
        return this.getResult()
    }
}
