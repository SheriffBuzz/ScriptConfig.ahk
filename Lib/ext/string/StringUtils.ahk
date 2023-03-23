#Include %A_LineFile%\..\StringCombiner.ahk

/*
	StringUtils

	@Class - This annotation is reserved future use. It should be used to create a javadoc page for the top level functions within the immediate script file, even though the functions are top level and not in a class.

	Contains common string functions. Functions are kept at the global scope as they are widely used and can be considered an extension of the language.

	Remarks
		- All string functions are 1 indexed, to conform with ahk syntax. The end index is StrLen(str) not StrLen(str - 1).
		- StrSplit does not respect Array prototypes. If a method returns the result of a StrSplit operation, check if the ArrayBase class exists and return an array that uses the prototype. See StrGetLines for an example.

	
*/

/*
	CharAt
*/
CharAt(ByRef str, idx) {
	return SubStr(str, idx, 1)
}

/*
	StrGetLines

	Standard method to get lines from a string, ignoring `r
	TODO replace refs
*/
StrGetLines(str) {
	if (ArrayBase) {
		arr:= StrSplit(str, "`n", "`r")
		arr.base:= ArrayBase
		return arr
	}
	return StrSplit(str, "`n", "`r")
}

StrCountLines(str) {
	count:= StrGetLines(str).count()
	return (count) ? count : 0
}

/*
	StrGetLineAtIdx
	
	Given an input string, get the line of the Idx. This could include text before and after the idx if the idx is in the middle of the line.

	Usecase:
		- very large string, that the caller may not want to split into lines. This could be json, xml, or csv that is too big or too performance costly to read into an array of lines directly. Caller passes an idx in the string, this could be from the result of an InStr operation

	Remarks
		- If the idx char is a newline or return character, return empty
		- Currently we only support lines, but it could be enhanced to support a custom delimiter like a comma, or a multi character phrase
*/
StrGetLineAtIdx(ByRef str, idx) {
	char:= CharAt(str, idx)
	if (char = "`n" || char = "`r") {
		return ""
	}
	boundaryChar:= "`n"

	beforeBoundaryIdx:= StrGetLineBoundaryStartIdx(str, idx, boundaryChar)
	afterBoundaryIdx:= StrGetLineBoundaryEndIdx(str, idx, boundaryChar)

	beforeFileBoundaryAdjustment:= (beforeBoundaryIdx = 1) ? 0 : 1
	afterFileBoundaryAdjustment:= (afterBoundaryIdx = StrLen(str)) ? 0 : 1
	return SubStrByIndecies(str, beforeBoundaryIdx + beforeFileBoundaryAdjustment, afterBoundaryIdx - afterFileBoundaryAdjustment) ;TODO if we support other chars besides \n then consider function arg to include the boundary pattern or not
}

/*
	StrGetLineBoundaryStartIdx

	Get the start boundary idx of the line in a string, given an arbitrary idx on the line.

	Usage:
		This can be used to get the starting position for SubStr for a line, given an arbitrary idx of that line in a very large string.

	Remarks
		- To get the content before the idx, InStr and StringGetPos cant work "backwards" from an arbitrary idx in a string, only from the end. get a substring so our idx is the end of the str.
	
	@return boundaryIdx. start of line is BoundaryIdx + 1
*/
StrGetLineBoundaryStartIdx(ByRef str, ByRef idx, boundaryChar:="`n") {
	beforeSubStr:= SubStrByIndecies(str, 1, idx)
	beforeBoundaryIdx:= InStr(beforeSubStr, boundaryChar,, 0)
	return (beforeBoundaryIdx) ? beforeBoundaryIdx : 1 ;start of string / on first line
}

/*
	StrGetLineBoundaryEndIdx

	Get end boundary idx of line in a string, given arbitrary idx on the line.

	@return boundaryIdx. end of line is BoundaryIdx - 1
*/
StrGetLineBoundaryEndIdx(ByRef str, idx, boundaryChar:="`n") {
	afterBoundaryIdx:= InStr(str, boundaryChar,, idx)
	if (CharAt(str, afterBoundaryIdx) = "`r") {
		afterBoundaryIdx--
	}
	return (afterBoundaryIdx) ? afterBoundaryIdx : StrLen(str) ;end of string / on last line
}

/*
	StrStartsWith

	Check if a string starts with a substring. This is an alternate to using a regex.

	@param str
	@param charSeq
*/
StrStartsWith(ByRef str, charSeq) {
	return (InStr(str, charSeq) = 1)
}

/*
	modified substring to make it more like other languages. In ahk, SubStr() only accepts start index and length.
	since ahk is 1 based, making @param end inclusive
*/
SubStrByIndecies(ByRef str, ByRef start, ByRef end) {
	length:= end - start + 1
	return SubStr(str, start, length) 
}

/*
	StrTrimRight

	implementation of StringTrimRight using SubStr instead of depricated StringTrimRight.

	@param str
	@Param numChars
*/
StrTrimRight(ByRef str, numChars) {
	return SubStr(str, 1, StrLen(str) - numChars)
}

/*
	SubStrRight

	Get @param numchars rightmost characters in a string.
*/
SubStrRight(str, numChars) {
	return SubStr(str, 1 + StrLen(str) - numChars)
}

/*
	StrTrimNumericPostfix

	Usecase: get name component of a filename that has frame number postfixes
*/
StrTrimNumericPostfix(ByRef str) {
	RegExMatch(str, "([A-z_]*)\d?", match)
	return match1
}

StrGetNumericPostfix(ByRef str) {
	RegExMatch(str, "\d*$", match)
	return 0 + match
}

StrGetNumericPrefix(ByRef str) {
	RegExMatch(str, "^\d*", match)
	return match
}

StrGetBefore(ByRef str, charSeq) {
	idx:= InStr(str, charSeq)
	if (!idx) {
		return str
	}
	return SubStr(str, 1, idx - 1)
}

/*
	StrGetBeforeLastIndexOf
	
	Get all text before the last index of a char sequence. More formally, Substring(1, indexOf(charseq) - 1)
*/
StrGetBeforeLastIndexOf(ByRef str, charSeq) {
	lastIdx:= InStr(str, charSeq,,0)
	if (!lastIdx) {
		return str
	}
	return SubStr(str, 1, lastIdx - 1)
}

StrLastIndexOf(ByRef str, ByRef charSeq) {
	return InStr(str, charSeq,,0,1)
}

StrGetAfterFirstIndexOf(ByRef str, charSeq) {
	foundIdx:= InStr(str, charSeq)
	firstIdx:= (foundIdx > 0) ? foundIdx + StrLen(charSeq) : 1
	return SubStr(str, firstIdx)
}

StrGetAfterFirstIndexOfAny(ByRef str, charSeqs) {
	foundIdx:= -1
	for i, charSeq in charSeqs {
		foundIdx:= InStr(str, charSeq)
		if (foundIdx > 0) {
			break
		}
	}
	if (foundIdx <= 0) {
		return str
	}
	firstIdx:= foundIdx + StrLen(charSeq)
	return SubStr(str, firstIdx)
}

StrGetAfterLastIndexOf(ByRef str, charSeq) {
	foundIdx:= StrLastIndexOf(str, charSeq)
	firstIdx:= (foundIdx > 0) ? foundIdx + StrLen(charSeq) : 1
	return SubStr(str, firstIdx)
}

/*
	StrExtractBetween

	returns the content of a string between a prefix and suffix.
	This method is used when you want some content in the middle of the string, independent of prefix/suffix strings of indetermined size.
	
	
	Examples - Strip out the content between parentheses in a sql insert
			Insert into ORDERS (Col1, Col2) values
			('abc', def)
			,('ghj', 'jki')
	Passing (text, "(", ")") will strip out the content inside parentheses independent of whats before and after the parentheses.

	@param str
	@param prefix - character that everything up to and including will be discarded
	@param suffix - *last* occurence of a character, which everything including and after will be discarded
	@Param includeEnds - should we include the prefix/suffix in the result
	@param greedy - determine if the suffix should be the next one in the string, or the last. by default, look for the last occurrence.
	@return str - if prefix and suffix not found, return original string
*/
StrExtractBetween(ByRef str, prefix, suffix, includeEnds:=false, greedy:=false) {
	prefixIdx:= InStr(str, prefix)
	if (!prefixIdx) {
		return str
	}
	if (greedy) {
			suffixIdx:= InStr(str, suffix,,prefixIdx + 1) ; search from the end of the string, backwards (lastIndexOf in java)
	} else {
		suffixIdx:= InStr(str, suffix,,0) ; search from the end of the string, backwards (lastIndexOf in java)
	}
	if (!includeEnds) {
		if (prefixIdx) {
			prefixIdx:= prefixIdx + (StrLen(prefix))
		}
		if (suffixIdx) {
			suffixIdx:= suffixIdx - 1
		}
	}
	if (prefixIdx && suffixIdx) {
		return SubStr(str, prefixIdx, suffixIdx - prefixIdx + 1) ; last param is length not end index
	} else {
		return str
	}
}

/*
	StrTrimTrailingNewline

	Trims trailing \r\n off a string
	Handle cases \n, \r, \r\n
*/
StrTrimTrailingNewline(str) {
	len:= StrLen(str)
	count:= 0
	if (CharAt(str, len -1) = "`r") {
		count:= count + 1
	}
	last:= CharAt(str, len)
	if (last = "`n" || last = "`r") {
		count:= count + 1
	}
	if (count) {
		str:= StrTrimRight(str, 2)
	}
	return str
}

/*
	StrRepeat

	Repeat a charSequence n times
*/
StrRepeat(charSeq, n) {
	str:= ""
	i:= 1
	while (i <= n) {
		str.= charSeq
		i++
	}
	return str
}

/*
	StrPadCache

	Cache of padded Strings, by character. Used to avoid creating the same string when padding a set of data that have similar lengths, but need to be padded to an exact length.

	DataStructure: Object[padChar->[]] where each element in the padByChar array contains a string of length i of that character

	StrPadCache:= {
		" ": [" ", "  ", "   "],
		",": [",", ",,", ",,,"]
	}
*/
global StrPadCache:={}

StrPadRight(str, totalLength, padChar:="-", cutoff:=false) {
	padStr:= StrGetPadByTotalLength(str, totalLength, padChar)
	return str . padStr
}

StrPadLeft(str, totalLength, padChar:="-", cutoff:=false) {
	if (cutoff && StrLen(str) > totalLength) {
		return SubStrRight(str, totalLength)
	}
	padStr:= StrGetPadByTotalLength(str, totalLength, padChar)
	return padStr . str
}

/*
	StrGetPadByTotalLength
*/
StrGetPadByTotalLength(ByRef str, totalLength, padChar:="-") {
	padLength:= totalLength - StrLen(str)
	if (padLength = 0) {
		return ""
	}
	return StrGetPad(padChar, padLength)
}

/*
	StrGetPad

	Get padded string using StrPadCache.
*/
StrGetPad(ByRef padChar, ByRef padLength) {
	cacheByChar:= StrPadCache[padChar]
	if (!cacheByChar) {
		cacheByChar:= []
	}
	if (cacheByChar[padLength]) {
		return cacheByChar[padLength]
	} else {
		lastIdx:= cacheByChar.MaxIndex()
		if (!lastIdx) {
			lastIdx:= 0
		}
		while (lastIdx <= padLength) {
			current:= cacheByChar[lastIdx] . padChar
			lastIdx:= lastIdx + 1
			cacheByChar[lastIdx]:= current
		}
		return cacheByChar[padLength]
	}
}

/*
	StrReplaceSpecialWithLiteral

	replace \t\n with ahk string literals `t`n. remove `r. useful for one off case where you need formatted sql in ahk code (not recommended for large sql blocks, store in file instead)
*/
StrReplaceSpecialWithLiteral(ByRef str) {
	str:= StrReplace(str, "`t", "``t")
	str:= StrReplace(str, "`n", "``n")
	str:= StrReplace(str, "`r", "")
	return str
}

StrRemoveNewlineAndTabs(ByRef str) {
	str:= StrReplace(str, "`r`n")
	str:= StrReplace(str, "`t")
	return str
}

StrReplaceTabsWithSpaces(ByRef str) {
	return StrReplace(str, "`t", " ")
}

StrRemoveNewline(ByRef str) {
	return StrReplace(str, "`r`n")
}

/*
	JavaEscapedToUnicode

	;https://www.autohotkey.com/board/topic/63263-unicode-escaped-string-convert-u00/
*/
JavaEscapedToUnicode(ByRef str) {
    i := 1
    while j := RegExMatch(str, "\\u[A-Fa-f0-9]{1,4}", m, i)
        e .= SubStr(str, i, j-i) Chr("0x" SubStr(m, 3)), i := j + StrLen(m)
    return e . SubStr(str, i)
}

StrCountMatches(ByRef haystack, needle) {
	StrReplace(haystack, needle, needle, count)
	return count
}

/*
	StrMatchesByStrategy

	@param strategy ["InStr", "Regex", "Prefix", "Postfix"]
*/
StrMatchesByStrategy(str, testPattern, strategy:= "InStr") {
	if (strategy = "InStr") {
		return InStr(str, testPattern)
	} else if (strategy = "Prefix") {
		return StrStartsWith(str, testPattern)
	} else {
		throw "StrMatchesByStrategy: Strategy " strategy " not implemented."
	}
}

StrFilterLinesByStrategy(lines, testPattern, strategy:="InStr") {
	filtered:= []
	for i, line in lines {
		if (StrMatchesByStrategy(line, testPattern, strategy)) {
			filtered.push(line)
		}
	}
	return filtered
}

/*
	StrIsQuoted
	@param str
	@param strict - should quotes be disallowed in the middle of the string
*/
StrIsQuoted(str, strict:=false) {
	if (strict) {
		if (StrCountMatches(str, """") != 2) {
			return false
		}
	}
	return (SubStr(str, 1, 1) = """") && (SubStr(str, 0, 1) = """")
}

/*
	StrTrimSuffix

	Trim trailing suffix. Compared to StrGetBeforeLastIndexOf, this method only checks matches at the very end of the string. text before matches in the middle of the string wont be returned.
*/
StrTrimSuffix(str, suffix) {
	suffixLength:= StrLen(suffix)
	strLength:= StrLen(str)
	startIdx:= strLength - suffixLength + 1
	if (InStr(SubStr(str, startIdx), suffix) = 1) {
		return SubStr(str, 1, startIdx - 1)
	}
	return str
}

/*
	StrAppendIfMissing

	Appends a char sequence to the end of an array, if is does not end in that.
	Handles suffix of any length.
*/
StrAppendIfMissing(str, suffix) {
	suffixLength:= StrLen(suffix)
	strLength:= StrLen(str)
	startIdx:= strLength - suffixLength + 1
	return (SubStr(str, startIdx) = suffix) ? str : str suffix
}

/*
	StrEndsWith

	@v2upgrade in v2 occurence can be negative, but not in v1. This fn will break if the suffix appears earlier in the string.
*/
StrEndsWith(str, suffix) {
	return (InStr(str, suffix) = (StrLen(str) - StrLen(suffix) + 1)) ? true : false
}

/*
	StrEndsWithChar

	Test if string ends with a particular character

	Remarks
		- This is a workaround to StrEndsWith. In v1 it is safer if you only need to test one character
*/
StrEndsWithChar(str, char) {
	return (CharAt(str, StrLen(str)) = char)
}

/*
	RawFileExtention

	Given a file extension that may or may not have leading period, return only the contents without period
*/
RawFileExtension(extension) {
	return StrReplace(extension, ".", "")
}

/*
	FullFileExtension

	Given a file extension that may or may not have leading period, return .{ext}
*/
FullFileExtension(extension) {
	return (InStr(extension, ".")) ? extension : "." extension
}

/*
	StrSplitNumericSuffix

	Split String with numeric suffix into 2 compontents

	return Arr[comp1, numericComp]
*/
StrSplitNumericSuffix(str) {
	result:= RegExMatch(str, "(.*?)(\d*)$", out)
	return [out1, out2]
}

/*
	StrFilterJavaSingleLineComments

	jxon doesnt support comments out of the box, this is a workaround. It may be intergrated at jxon at some point, pending @PSR impact

	Filter // only, multi line comments not supported
*/
StrFilterJavaSingleLineComments(str) {
	lines:= StrGetLines(str)
	comment:= "//"
	filteredLines:= []
	for i, line in lines {
		if (InStr(line, comment) = 1) {
			continue
		}
		filteredLines.push(line)
	}
	return CombineArray(filteredLines, "`n")
}

/*
	StrToBoolean

	Convert @param str to boolean. Accepts "true", "false", "0", "1". if any other string is given, including empty string, it will return that string. In that case, the returned value will act as "falsy" and not boolean.
*/
StrToBoolean(str) {
	if (str = "true") {
		return true
	} else if (str = "false") {
		return false
	} else {
		return str
	}
}

/*
	BooleanDefaultTrue

	Get boolean value of @param str. If str is empty (not numeric zero) then default to true.
*/
BooleanDefaultTrue(str) {
	if ((str = 1) || (str = "true")) {
		return true
	} else if ((str = 0) || (str = "false")) {
		return false
	} else {
		return true ;Empty string case
	}
}

/*
	BooleanDefaultFalse

	Get boolean value of @param str. If str is empty (not numeric zero) then default to false.
*/
BooleanDefaultFalse(str) {
	if ((str = 1) || (str = "true")) {
		return true
	} else if ((str = 0) || (str = "false")) {
		return false
	} else {
		return false ;Empty string case
	}
}
