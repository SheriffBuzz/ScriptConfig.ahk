#Include %A_LineFile%\..\..\object\Exports.ahk

class LoggingUtilsClass {
    toPair(ByRef thiz, ByRef that) {
        return [this, that]
    }

    /*
        prettyPrintarr2D

        Return column aligned strings for logging. (each cell value is padded with whitespace to make all columns the same width)
    */
    prettyPrintArr2D(ByRef arr2d) {
        arr2d:= getPaddedArr2dByLargestColumn(arr2d, " ", false)
        return arr2dToString(arr2d, " ~ ", "`n", "`t")
    }
}
global LoggingUtils:= new LoggingUtilsClass() ;@Export LoggingUtils
