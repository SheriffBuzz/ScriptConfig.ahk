/*
	CombineStrings

	Combiner method that parses a single string based on some delimiter and combines using a combiner string.

	@param text
	@param combiner - string to combine text. @default `, Must escape the combiner string if it is an AHK special char.
	@param delimiter - delimiter to combine on. @default `n
	@param aroundChar - wraps each token on both ends before combining
	@param escapeChar - escape char for each token, applied before any aroundChar is added
*/
CombineStrings(text, combiner:="`,", delimiter:="`n", aroundChar:="", escapeChar:="", skipEmpty:=false) {
	accumulator:= ""
	token:= ""
	Loop, parse, text, %delimiter%, `r
	{
		if (A_LoopField || !skipEmpty) {
			token:= A_LoopField
			if (escapeChar) {
				token:= StrReplace(A_LoopField, escapeChar, escapeChar escapeChar)
			}
			if (aroundChar) {
				token:= TokenizeAround(token, aroundChar)
			}
			accumulator.= token combiner
		}
	}
	return SubStr(accumulator, 1, StrLen(accumulator) - (StrLen(combiner)))
}

/*
	CombineArray

	remarks
		- if cell value is null, skip the element. invalid for csv. See combineArrayAdvanced

	@psr substr vs checking maxIdx for very large arrays.
	@psr varsetcapacity psr
	@param arr
	@param combiner default:"`,"
	@param aroundChar default:""
	@param escapeChar default:""
	@param matchAroundBrackets - if around char is [ or {, should the Trailing around character be changed to ] or }
	@return string
*/
CombineArray(ByRef arr, ByRef combiner:="`,", ByRef aroundChar:="", ByRef escapeChar:="", matchAroundBrackets:=false, skipEmpty:=false) {
	token:= ""
	accumulator:= ""
	for key, val in arr {
		if (!(val = "") || !skipEmpty) { ;TODO check code for if (variable) definition, it doesnt handle string literal zero like other languages
			token:= val
			if (escapeChar) {
				token:= StrReplace(val, escapeChar, escapeChar escapeChar)
			}
			if (aroundChar) {
				token:= TokenizeAround(token, aroundChar, matchAroundBrackets)
			}
			accumulator.= token combiner
		}
	}
	return SubStr(accumulator, 1, StrLen(accumulator) - (StrLen(combiner)))
}

/*
	CombineArrayAdvanced - optimized version of combine array that reduces array/str copying, where input strings are large. Reuse an accumulator between calls.
		-trim down extra params, this is intended for csv/json where the separator is comma and any aroundChars are added by the caller
	@param ByRef arr
	@param ByRef combiner
	@param rowLength - pass in row length for sparce arrays. By default, uses maxIndex but will be invalid if the array is sparce
	@param ByRef accumulator - pass in the accumulator. Ideally you would send an empty string but this gives you the option to use VarSetCapacity beforehand
	@return accumulator. accumulator is passed ByRef so can also just use passed reference instead of the return value
*/
CombineArrayAdvanced(ByRef arr, ByRef combiner:="`,", ByRef accumulator:="", ByRef rowLength:="") {
	if (!rowLength) {
		rowLength:= arr.MaxIndex()
	}
	idx:= 1
	for key, val in arr {
		if (idx >= rowLength) { ;keep track of idx and see if we have reached the last idx. cant use key as it may be sparce array. avoids substr call to trim off the last trailing separator
			accumulator.= val
		} else {
			accumulator.= val combiner
		}
		idx:= idx + 1
	}
	return accumulator
}

/*
	CombineArrayByBinaryPartition

	Combine Array into strings, using an array of column indexes in the first set, otherwise 2nd set. then, combine each partition into one.

	Remarks - idx values of arr must be natural number sequence, not associative/non-numeric keys
		Usecase is to pluck out certain columns based on a boolean expression per column, and push those to the end (want to keep sql rows that have null values, but push them to the end of an insert statement, etc..)

	@deprecated use Grid.partitionByFunction
	@param partitionMap - map from idx to 0 or 1 if it belongs in first or 2nd set
*/
CombineArrayByBinaryPartition(ByRef arr, ByRef partitionMap, combiner:= "`,", aroundChar:="", escapeChar:="") {
	accumulator1:= ""
	accumulator2:= ""
	token:= ""
	for idx, val in arr {
		if (val) {
			token:= val
			if (escapeChar) {
				token:= StrReplace(val, escapeChar, escapeChar escapeChar)
			}
			if (aroundChar) {
				token:= TokenizeAround(token, aroundChar)
			}
			if (partitionMap[idx] = true) {
				accumulator1.= token combiner
			} else {
				accumulator2.= token combiner
			}
		}
	}
	partition1:= SubStr(accumulator1, 1, StrLen(accumulator1) - (StrLen(combiner)))
	partition2:= SubStr(accumulator2, 1, StrLen(accumulator2) - (StrLen(combiner)))
	return partition1 combiner partition2
}


/*
	TokenizeAround

	@param text - Input text
	@param wrapper - String to wrap the input in on both sides. by default is '
	@return str - new String with the input wrapped in the wrapper character.
*/
TokenizeAround(text, wrapper:="'", matchAroundBrackets:=false) {
	if (matchAroundBrackets) {
		if (wrapper = "[") {
			return wrapper text "]"
		} else if (wrapper = "{") {
			return wrapper text "}"
		}
	}
	return wrapper text wrapper
}

/*
	TokenizeBefore
*/
TokenizeBefore(text, wrapper:="'") {
	return wrapper text
}

/*
	TokenizeAfter
*/
TokenizeAfter(text, wrapper:="'") {
	return text wrapper
}

/*
	CommarateStrSingleQuotes

	Combine newline separated strings with commas. Each token is surrounded in single quotes.
*/
CommarateStrSingleQuotes(str) {
	return CombineStrings(str,,,"'")
}

/*
	CommarateStrDoubleQuotes

	Combine newline separated strings with commas. Each token is surrounded in double quotes.
*/
CommarateStrDoubleQuotes(str) {
	return CombineStrings(str,,,"""")
}

/*
	CommarateSqlSingleQuotes

	Combine newline separated strings.

	This method also escapes sql by replacing a single quote with 2 single quotes.
*/
CommarateSqlSingleQuotes(str) {
	return CombineStrings(str,,,"'","'")
}
