/*
	StrUpper

	@commandWrapper
*/
StrUpper(string) {
	StringUpper, string, string
	return string
}

/*
	StrLower

	@commandWrapper
*/
StrLower(string) {
	StringLower, string, string
	return string
}

/*
    StrTitle

    Remarks
        - StrTitle is a v2 function, not in v1. v1 implements this by extra param for strupper/lower
        - inputVar (2nd arg) is the name of a variable. this is a legacy ahk function that doesnt support expressions.
*/
StrTitle(string) {
    StringLower, string, string, T
    return string
}
