;@v1start
/*
    A__Quote

    Global variable for quote. These may be replaced with inlined quote literals once v2 upgrade is fully complete (to avoid additional concat). For now, this increases compatability for existing v1 code.
*/
global A__Quote:= """"
;@v1end
;@v2start
/*
A__Quote:= '"'
*/
;@v2end
