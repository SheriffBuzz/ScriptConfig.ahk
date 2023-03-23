#Include %A_LineFile%\..\..\object\Object.ahk
#Include %A_LineFile%\..\..\string\Exports.ahk

/*
    Date

    Abstract representation of a date. Each component is stored as a separate prop, to make parsing to and from different formats easier.
*/
class DateClass extends ObjectBase {
    __New() {
        /* ;Template, use FromAhkTimestamp
        this.year:=
        this.month:=
        this.day:=
        this.hour:= ;24 hr
        this.minutes:=
        this.seconds:=
        this.milliseconds:=
        this.ahkTimestamp:= ;YYYYMMDDHHMISS
        */
    }

    /*
        CompareTo 
        
        Remarks
            - precision is to the nearest second.
            - not handling locales. All dates are assumes to be in the same locale.
                - initial impl if checking file modified times. This wont work for other applications
    */
    CompareTo(that) {
        if (this.year > that.year) {
            return 1
        } else if (this.year < that.year) {
            return -1
        } else if (this.month > that.month) {
            return 1
        } else if (this.month < that.month) {
            return -1
        } else if (this.day > that.day) {
            return 1
        } else if (this.day < that.day) {
            return -1
        } else if (this.hour > that.hour) {
            return 1
        } else if (this.hour < that.hour) {
            return -1
        } else if (this.minutes > that.minutes) {
            return 1
        } else if (this.minutes < that.minutes) {
            return -1
        } else if (this.seconds > that.seconds) {
            return 1
        } else if (this.seconds < that.seconds) {
            return -1
        } else {
            return 0
        }
    }

    greaterThan(that) {
        return this.compareTo(that) > 0
    }

    lessThan(that) {
        return this.compareTo(that) < 0
    }

    getEpochSeconds() {

    }
    FromAhkTimestamp(YYYYMMDDHHMISS) {
        date:= new DateClass()
        date.year:= 0 + SubStr(YYYYMMDDHHMISS, 1, 4)
        date.month:= 0 + SubStr(YYYYMMDDHHMISS, 5, 2)
        date.day:= 0 + SubStr(YYYYMMDDHHMISS, 7, 2)
        date.hour:= 0 + SubStr(YYYYMMDDHHMISS, 9, 2)
        date.minutes:= 0 + SubStr(YYYYMMDDHHMISS, 11, 2)
        date.seconds:= 0 + SubStr(YYYYMMDDHHMISS, 13, 2)
        return date
    }

    StartOfDay() {
        date:= DateClass.FromAhkTimestamp(A_Now)
        date.hour:= 0
        date.minutes:= 0
        date.seconds:= 0
        return date
    }

    ToAhkTimeStamp() {
        return StrGetPadByTotalLength(this.year, 4, 0) this.year StrGetPadByTotalLength(this.month, 2, 0) this.month StrGetPadByTotalLength(this.day, 4, 0) this.day StrGetPadByTotalLength(this.hour, 4, 0) this.hour StrGetPadByTotalLength(this.minutes, 4, 0) this.minutes StrGetPadByTotalLength(this.seconds, 4, 0) this.seconds
    }

    ToIso8601Timestamp() {
        
    }
}
