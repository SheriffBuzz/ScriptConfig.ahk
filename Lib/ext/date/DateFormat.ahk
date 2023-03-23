/*
    DateFormat.ahk
*/
class DateFormatClass {
    static loggerFormat:= "yyyy-MM-dd HH:mm:ss"
    now(loggerFormat:="") {
        loggerFormat:= (loggerFormat) ? loggerFormat : DateFormatClass.loggerFormat
        now:= FormatTime(, loggerFormat)
        return now "." A_MSec
    }

    nowFileName() {
        static fmt:= "yyyy-MM-dd HHmmss"
        loggerFormat:= (loggerFormat) ? loggerFormat : DateFormatClass.loggerFormat
        now:= FormatTime(, loggerFormat)
        return StrReplace(now, ":", "")
    }
}

global dateFormat:= new DateFormatClass() ;@Export dateFormat
