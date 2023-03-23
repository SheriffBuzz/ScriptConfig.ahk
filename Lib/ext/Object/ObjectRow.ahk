#Include %A_LineFile%\..\Object.ahk

/*
    ObjectRow

    Custom Array-like object that stores a metadata header row for constant time access to columns via column name. This can be used to support data that is ordered, without the caller needing to know the internal column order to modify data values.

    This class is based off CsvRow concept, but is not limited to csv.
*/
class ObjectRowClass extends ObjectBase {
    /*
        Constructor

        Remarks
            - We require both columnNameByColumnIdx and columnIdxByColumnName to avoid duplicating data that can be calculated statically. In the case of csv processing, we have 1 header row and could have 100's or 1000's of data rows. All the rows should reference the same header metadata objects in memory.
    */
    __New(ByRef columnNameByColumnIdx, ByRef columnIdxByColumnName, data:="") {
        this.data:= IsArray(data) ? data.toObject(columnNameByColumnIdx): ObjDefault(data)
        this.columnNameByColumnIdx:= columnNameByColumnIdx
        this.columnIdxByColumnName:= columnIdxByColumnName
    }

    clone() {
        clazz:= this.__Class
        return new %clazz%(this.columnNameByColumnIdx, this.columnIdxByColumnName, this.data.clone())
    }

    count() {
        return this.data.count()
    }

    get(columnName) {
        return this.data[columnName]
    }

    getByIdx(columnIdx) {
        return this.data[this.columnNameByColumnIdx[columnIdx]]
    }

    set(columnName, value, overwrite:=true) {
        if (!overwrite && !(this.data[columnName] = "")) {
            return
        }
        this.data[columnName]:= value
    }

    setByIdx(columnIdx, value) {
        this.data[this.columnNameByColumnIdx[columnIdx]]:= value
    }

    getColumnIdx(columnName) {
        return this.columnIdxByColumnName[columnName]
    }

    getColumnName(columnIdx) {
        return this.columnNameByColumnIdx[columnIdx]
    }

    /*
        getShortDiplayValue

        Get short name.

        Usecase: get display value built from multiple elements, especially for hierarchical data where display value could be a combination of multiple rows. ie. "OrderNo/OrderLineNo". We need a short name for display purposes, as we might not want to unnecessarily extend a text view of rows that are padded to the longest column value.
    */
    getShortDiplayValue() {
        this.abstractMethod(A_ThisFunc)
    }

    /*
        toArray

        convert row to an array, in correct order according to columnNameByColumnIdx
    */
    toArray() {
        arr:= []
        for columnIdx, columnName in this.columnNameByColumnIdx {
            arr.push(this.get(columnName))
        }
        return arr
    }
}

class CsvRowClass extends ObjectRowClass {
    getAroundCellDelimiter() {
        return """"
    }
    
    escapeCsvCell(cell, columnSeparator, aroundCellDelimiter, escapedAroundCellDelimiter) {
        hasAroundCellDelimiter:= (InStr(cell, aroundCellDelimiter))
        quoteEscaped:= (hasAroundCellDelimiter) ? StrReplace(cell, aroundCellDelimiter, escapedAroundCellDelimiter) : cell
        if (hasAroundCellDelimiter || (InStr(cell, columnSeparator))) {
            quoteEscaped:= aroundCellDelimiter quoteEscaped aroundCellDelimiter
        }
        return quoteEscaped
    }

    /*
        convert csvRow into properly escaped string.
    */
    toCsv(ByRef columnSeparator:="`,", isValidCsvEscaping:=true) {
        csvRowString:= ""
        columnCount:= this.columnNameByColumnIdx.count()
        q:= Chr(34)
        aroundCellDelimiter:= this.getAroundCellDelimiter()
        escapedAroundCellDelimiter:= aroundCellDelimiter aroundCellDelimiter

        for columnIdx, columnName in this.columnNameByColumnIdx { ;we are now allowing rows with less than number of columns, so get proper cell at the column idx. This is needed for csv but not to json due to contract of key ordering
            cell:= this.data[columnName]
            if (isValidCsvEscaping) {
                csvRowString.= this.escapeCsvCell(cell, columnSeparator, aroundCellDelimiter, escapedAroundCellDelimiter)
            } else {
                csvRowString.= cell
            }
            if (columnIdx < columnCount) {
                csvRowString.= columnSeparator
            }
        }
        return csvRowString
    }
}

;TODO export class
;#Include SqlUtils
class SqlRowClass extends CsvRowClass {
    getAroundCellDelimiter() {
        return "'"
    }
    
    escapeCsvCell(cell, columnSeparator:=",", aroundCellDelimiter:="'", escapedAroundCellDelimiter:="''") {
        hasAroundCellDelimiter:= (InStr(cell, aroundCellDelimiter))
        quoteEscaped:= (hasAroundCellDelimiter) ? StrReplace(cell, aroundCellDelimiter, escapedAroundCellDelimiter) : cell
        if (hasAroundCellDelimiter || InStr(cell, " ") || (!sqlUtils.isSqlLiteral(cell))) {
            quoteEscaped:= aroundCellDelimiter quoteEscaped aroundCellDelimiter
        }
        return quoteEscaped
    }

    getEscapedRow() {
        newRow:= new SqlRowClass(this.columnNameByColumnIdx, this.columnIdxByColumnName)
        for columnIdx, columnName in this.columnNameByColumnIdx {
            newRow.set(columnName, this.escapeCsvCell(this.get(columnName)))
        }
        return newRow
    }
}
