; lib_clTab.ahk - V2 Refactor

; #include lib_jsEval.ahk ; Included in CapsLock+.ahk now

clCalculate(inputStr, &result, autoMatch:=0, isScratch:=0)
{
    if(autoMatch){
        strRegEx := "\S*$"
        calStr := ""
        foundPos := RegExMatch(inputStr, "(``)(.*)", &calStr)

        if(!foundPos) {
            foundPos := RegExMatch(inputStr, strRegEx, &calStr)
            if (foundPos)
                calStr := calStr[0] ; Get match text
        }
        else {
            calStr := LTrim(calStr[2], "``") ; Group 2
        }

        if(foundPos){
            inputStr := SubStr(inputStr, 1, foundPos-1)
        }else{
            return inputStr
        }

    }else{
        calStr := inputStr
        inputStr := ""
    }

    eqSign := ""
    eqSignPos := RegExMatch(calStr, " ?= ?$", &eqSign)
    if(eqSignPos)
        calStr2 := SubStr(calStr, 1, eqSignPos-1)
    else
        calStr2 := calStr

    ; Fix float calc
    if(isScratch)
        result := eval("fixFloatCalcRudely(" . calStr2 . ")")
    else if(IsSet(CLSets) && CLSets["Global"].Has("javascriptOriginalReturn") && CLSets["Global"]["javascriptOriginalReturn"])
        result := eval(calStr2)
    else
        result := eval("fixFloatCalcRudely(" . calStr2 . ")")

    if(result == "")
        result := "?"

    if(isScratch){
        if(eqSignPos){
            inputStr .= calStr2 . eqSign[0] . result
        }else{
            inputStr .= calStr2 . "=" . result
        }
    }else if(eqSignPos){
        inputStr .= calStr2 . eqSign[0] . result
    }else{
        inputStr .= result
    }

    return inputStr
}

tabAction()
{
    ClipboardOld := ClipboardAll()
    selText := getSelText()

    calResult := ""

    if(selText)
    {
        selText := strSelected2Script(selText)

        A_Clipboard := clCalculate(selText, &calResult)
    }
    else
    {
        A_Clipboard := ""
        SendInput("+{Home}")
        Sleep(10) ; make sure text is selecting
        SendInput("^{c}")
        if ClipWait(0.1)
        {
            if(!CLhotString()) ; Defined in lib_settings.ahk
            {
                A_Clipboard := clCalculate(A_Clipboard, &calResult, 1)
            }
        }
    }
    SendInput("^{v}")
    Sleep(200)
    A_Clipboard := ClipboardOld
    return calResult
}
