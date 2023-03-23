/*
    @TODO this function was exported from Lib\ext\windows\EnvironmentVarables.ahk. Remove refs to that import.
    
    ExpandEnvironmentVariables - expand env varaibles (without using EnvGet, as #NoEnv may be enabled)

	https://learn.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-expandenvironmentstringsa

	Remarks
		- InStr(path, "%") short circuit is SLOWER!!
		- This function expands transitive environment variables (ie an environment varable contains additional environment variables)
*/
;@v1start
ExpandEnvironmentVariables(ByRef lpSrc) {
	VarSetCapacity(lpDst, 2000) 
	DllCall("ExpandEnvironmentStrings", "str", lpSrc, "str", lpDst, "UInt", 1999, "Cdecl int")
	return lpDst
}
;@v1end
;@v2Start
/*
ExpandEnvironmentVariables(lpSrc) {
	lpDst:= unset
	VarSetStrCapacity(&lpDst, 2000) 
	DllCall("ExpandEnvironmentStrings", "str", lpSrc, "str", lpDst, "UInt", 1999, "Cdecl int") 
	return lpDst
}
*/
;@v2end
