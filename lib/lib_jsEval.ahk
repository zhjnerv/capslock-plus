
; lib_jsEval.ahk - V2 Refactor

global jsEvalObj := ""

jsEval_init() {
    global jsEvalObj
    
    FixIE(11)
    
    try {
        jsEvalObj := ComObject("HTMLfile")
    } catch Error as e {
        MsgBox("AHK Init Error: " . e.Message)
        jsEvalObj := ""
        return
    }

    ;---load javascript---

    ;build-in script
    buildInScript := "
    (
    <script>
    var funcArr=['abs','acos','asin','atan','atan2','ceil','cos','exp','floor','log','max','min','pow','random','round','sin','sqrt','tan'];
    var consArr=['E','LN2','LN10','LOG2E','LOG10E','PI','SQRT1_2','SQRT2'];
    for(var i=0,len=funcArr.length;i<len;i++){
        window[funcArr[i]]=Math[funcArr[i]];
    }
    for(var i=0,len=consArr.length;i<len;i++){
        window[consArr[i]]=Math[consArr[i]];
        window[consArr[i].toLowerCase()]=Math[consArr[i]];
    }
    function fixFloatCalcRudely(num){
        if(typeof num == 'number'){
            var str=num.toString(),
                match=str.match(/\.(\d*?)(9|0)\2{5,}(\d{1,5})$/);
            if(match != null){
                return num.toFixed(match[1].length)-0;
            }
        }
        return num;
    }
    </script>
    )"
    
    try {
        jsEvalObj.write(buildInScript)
    } catch Error as e {
        MsgBox("JS Write Error: " . e.Message)
    }
}

eval(exp)
{
    global jsEvalObj
    if (!IsObject(jsEvalObj))
        return "ERROR_NO_ENGINE"
        
    exp := escapeString(exp)
    
    try {
        ; Use try-catch inside JS to capture runtime errors
        script := "<body><script>(function(){var t=document.body;t.innerText='';try{var r=eval('" . exp . "');t.innerText=r;}catch(e){t.innerText='JSERR:'+e.message;}})()</script></body>"
        jsEvalObj.write(script)
        result := jsEvalObj.body.innerText
        
        if (SubStr(result, 1, 6) == "JSERR:") {
             MsgBox("JS Error for '" . exp . "': " . SubStr(result, 7))
             return "ERROR"
        }
        
        return result
    } catch Error as e {
        MsgBox("AHK Eval Failed: " . e.Message)
        return "ERROR"
    }
}

escapeString(string){
    ; Escape backslashes first to avoid double escaping
    string := StrReplace(string, "\", "\\")
    string := StrReplace(string, "'", "\'")
    string := StrReplace(string, "`"", "\`"")
    string := StrReplace(string, "`n", "\n")
    string := StrReplace(string, "`r", "\r")
    return string
}

strSelected2Script(selText){
    regex := "i)\R[ \t]*?\..+\(.*\)\s*$"
    matchFuncPos := RegExMatch(selText, regex, &funcMatch)

    if(matchFuncPos)
    {
        selText := SubStr(selText, 1, matchFuncPos)
        selText := escapeString(selText)
        selText := "'" . selText . "'" . RegExReplace(funcMatch[0], "(^\s*)|(\s*$)")
    }
    return selText
}

FixIE(Version:=0, ExeName:="")
{
    Key := "Software\Microsoft\Internet Explorer" . "\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
    Versions := Map(7,7000, 8,8888, 9,9999, 10,10001, 11,11001)
    
    if Versions.Has(Version)
        Version := Versions[Version]

    if !ExeName
    {
        if A_IsCompiled
            ExeName := A_ScriptName
        else
            SplitPath(A_AhkPath, &ExeName)
    }
    
    try {
        PreviousValue := RegRead("HKCU\" . Key, ExeName)
    } catch {
        PreviousValue := ""
    }

    if (Version == "") {
        try RegDelete("HKCU\" . Key, ExeName)
    }
    else if(PreviousValue != Version) {
        try RegWrite(Version, "REG_DWORD", "HKCU\" . Key, ExeName)
    }
        
    return PreviousValue
}