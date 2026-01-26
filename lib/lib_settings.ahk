/*
提出settings.ini的设置信息
*/

settingsInit() {
    global settingsModifyTime
    global CLSets := Map() ;保存Capslock+settings.ini的各种设置
    CLSets.CaseSense := "Off"
    CLSets["length"] := Map() ;保存settings.ini中每个字段的关键词数量
    global setsChanges := Map() ;保存哪些设置经过改变
    
    ;set.ini 里面所有字段名，有更新必须修改这里，否则会无法获取
    global iniSections := ["Global","QSearch","QRun","QWeb","TabHotString","QStyle","TTranslate","AI","Keys", "Obsidian"] 
    
    try {
        settingsModifyTime := FileGetTime("CapsLock+settings.ini")
    } catch {
        settingsModifyTime := ""
    }

    ;init CapsLock+settingsDemo.ini and CapsLock+settings.ini
    if !FileExist("CapsLock+settingsDemo.ini")
    {       
        FileAppend(lang_settingsDemoFileContent_1, "CapsLock+settingsDemo.ini", "UTF-16")
        FileAppend(lang_settingsDemoFileContent_2, "CapsLock+settingsDemo.ini", "UTF-16")
        FileSetAttrib("+R", "CapsLock+settingsDemo.ini")
    }
    else
    {
        setDemoModifyTime := FileGetTime("CapsLock+settingsDemo.ini")
        if DirExist("language")
        {
            thisScriptModifyTime := FileGetTime("language")
        }
        else
        {
            thisScriptModifyTime := FileGetTime(A_ScriptFullPath)
        }
        
        diff := DateDiff(thisScriptModifyTime, setDemoModifyTime, "Seconds")
        if(diff > 0) ;如果主程序文件比较新，那就是更新过，那就覆盖一遍
        {
            FileSetAttrib("-R", "CapsLock+settingsDemo.ini")
            FileDelete("CapsLock+settingsDemo.ini")
            FileAppend(lang_settingsDemoFileContent_1, "CapsLock+settingsDemo.ini", "UTF-16")
            FileAppend(lang_settingsDemoFileContent_2, "CapsLock+settingsDemo.ini", "UTF-16")
            FileSetAttrib("+R", "CapsLock+settingsDemo.ini")
        }
    }

    if !FileExist("CapsLock+settings.ini")
    {   
        FileAppend(lang_settingsFileContent, "CapsLock+settings.ini", "UTF-16")
    }

    ; Clean up large strings to save memory
    global lang_settingsDemoFileContent_1 := ""
    global lang_settingsDemoFileContent_2 := ""
    global lang_settingsFileContent := ""

    for index, sectionValue in iniSections
    {
        setsChanges[sectionValue] := Map()
        setsChanges[sectionValue]["deleted"] := Map()
        setsChanges[sectionValue]["modified"] := Map()
        setsChanges[sectionValue]["appended"] := Map()
        settingsSectionInit(sectionValue)
    }

    keysInit()
    SetTimer(globalSettings, 1) ; Negative period not supported for run-once exactly same way, but 1ms is fine or use negative
    SetTimer(globalSettings, -1)
    SetTimer(setShortcutKey, -1)
    SetTimer(hotStringInit, -1)
    SetTimer(monitorSettingsFile, 500)
}

;监控设置文件的修改，并作出改动
monitorSettingsFile() {
    global settingsModifyTime
    
    try {
        latestModifyTime := FileGetTime("CapsLock+settings.ini")
    } catch {
        return
    }

    if(latestModifyTime != settingsModifyTime)
    {
        settingsModifyTime := latestModifyTime
        
        isChange := Map()
        for index, sectionValue in iniSections
        {
            isChange[sectionValue] := settingsSectionInit(sectionValue)
        }

        if(isChange.Has("Keys") && isChange["Keys"])
        {
            SetTimer(keysInit, -1)
        }
        
        if(isChange.Has("Global") && isChange["Global"])
        {
            for key1, val1 in setsChanges["Global"]
            {
                ; setsChanges structure is specific, verify strict usage
                ; Assuming setsChanges["Global"] is a Map of changes?
                ; Actually setsChanges[section] has .modified, .appended etc.
                ; The loop in v1 was `for key1 in setsChanges.Global` which looped over keys of the object
                ; setsChanges.Global has "deleted", "modified", "appended"
                
                ; We need to check inside modified/appended
                checkChange := false
                if (setsChanges["Global"]["modified"].Has("autostart") || setsChanges["Global"]["appended"].Has("autostart"))
                    SetTimer(globalSettings, -1)
                
                if (setsChanges["Global"]["modified"].Has("loadScript") || setsChanges["Global"]["appended"].Has("loadScript"))
                     SetTimer(jsEval_init, -1)
            }
        }

        if(isChange.Has("TabHotString") && isChange["TabHotString"])
        {
            SetTimer(hotStringInit, -1)
        }
        
        if(isChange.Has("TTranslate") && isChange["TTranslate"])
        {
            SetTimer(youdaoApiInit, -1)
        }

        if(isChange.Has("QStyle") && isChange["QStyle"])
        {
            global needInitQ := 1
            ; CLq() ; TODO: Enable when Q lib is migrated
            return 
        }

        if(isChange.Has("QSearch") && isChange["QSearch"])
        {
            ; SetTimer(QListIconInit, -1) ; TODO
        }

        if((isChange.Has("QWeb") && isChange["QWeb"]) || (isChange.Has("QRun") && isChange["QRun"]))
        {
            ; SetTimer(QListIconInit, -1) ; TODO
            SetTimer(hotStringInit, -1)
        }
    }
}

getShortSetKey(str)
{
    return RegExReplace(str, '\s*<.*>$')
}

settingsSectionInit(sectionValue)
{
    isChange := 0 
    try {
        settingsKeys := IniRead("CapsLock+settings.ini", sectionValue)
    } catch {
        settingsKeys := ""
    }
    
    ; Remove comments
    settingsKeys := RegExReplace(settingsKeys, 'm`n)=.*$')
    keyArr := StrSplit(settingsKeys, "`n")
    
    ; Remove empty lines
    cleanKeyArr := []
    for _, k in keyArr {
        if (Trim(k) != "")
            cleanKeyArr.Push(Trim(k))
    }
    keyArr := cleanKeyArr

    if (!CLSets["length"].Has(sectionValue)) ; Not initialized
    {
        CLSets[sectionValue] := Map()
        CLSets[sectionValue].CaseSense := "Off"
        _clsetsSec := CLSets[sectionValue]
        CLSets["length"][sectionValue] := 0
        
        for key, keyValue in keyArr
        {
            try {
                setValue := IniRead("CapsLock+settings.ini", sectionValue, keyValue)
            } catch {
                continue
            }

            if (sectionValue = "QSearch" || sectionValue = "QRun" || sectionValue = "QWeb")
            {
                shortKey := getShortSetKey(keyValue)
                _clsetsSec[shortKey] := Map()
                _t := _clsetsSec[shortKey]
                _t["fullKey"] := keyValue
                _t["setValue"] := setValue
            }
            else if(sectionValue = "Keys")
            {
                if(SubStr(setValue, 1, 8) = "keyFunc_")
                    _clsetsSec[keyValue] := setValue
            }
            else
            {
                _clsetsSec[keyValue] := setValue
            }
            CLSets["length"][sectionValue]++
        }
    }
    else    ; Not first init
    {
        _clsetsSec := CLSets[sectionValue]
        if (sectionValue = "QSearch" || sectionValue = "QRun" || sectionValue = "QWeb")
        {
            ; Check strictly per V2 iteration logic
            for key, value in _clsetsSec
            {
                _fullKey := value["fullKey"]
                try {
                    valNew := IniRead("CapsLock+settings.ini", sectionValue, _fullKey)
                } catch {
                    valNew := "" ; Default to empty strings for "deleted" check
                }
                
                ; IniRead throws if key missing, so catch block handles deletion detection effectively if using defaults?
                ; Actually AHK v2 IniRead throws Error if key not found. 
                ; Let's use Try-Catch. If it catches, it means key is missing (deleted).

                isDeleted := false
                try {
                     valNew := IniRead("CapsLock+settings.ini", sectionValue, _fullKey)
                } catch {
                     isDeleted := true
                }

                if(isDeleted)
                {
                    setsChanges[sectionValue]["deleted"][_fullKey] := value ; Store object or key? V1 code `insert(_fullKey)`
                    isChange := 1
                }
                else
                {
                    if(value["setValue"] != valNew)
                    {
                        shortKey := getShortSetKey(key) ; Key here is shortKey already? No, key in loop is correct.
                        _t := _clsetsSec[key] ; key is shortKey
                        _t["fullKey"] := _fullKey
                        _t["setValue"] := valNew
                        setsChanges[sectionValue]["modified"][key] := valNew
                        isChange := 1
                    }
                }
            }

            for key, value in setsChanges[sectionValue]["deleted"]
            {
                _clsetsSec.Delete(getShortSetKey(key)) ; Remove by Key? Wait, deleted stores _fullKey.
                ; _clsetsSec is Map where key is shortKey. 
                ; In the loop above: `for key, value in _clsetsSec`. `key` is shortKey. 
                ; V1 code: `setsChanges[sectionValue].deleted.insert(_fullKey)`
                ; V1 cleanup: `for key, value in ...deleted ... _clsetsSec.remove(value)` 
                ; So we need to remove by shortKey.
                
                _clsetsSec.Delete(getShortSetKey(key))
                CLSets["length"][sectionValue]--
            }
            
            ; Check for new keys
            for _, value in keyArr ; value is fullKey
            {
                shortKey := getShortSetKey(value)
                if(!_clsetsSec.Has(shortKey)) ; New
                {
                    try {
                        valNew := IniRead("CapsLock+settings.ini", sectionValue, value)
                        _clsetsSec[shortKey] := Map()
                        _t := _clsetsSec[shortKey]
                        _t["fullKey"] := value
                        _t["setValue"] := valNew
                        CLSets["length"][sectionValue]++
                        setsChanges[sectionValue]["appended"][value] := valNew
                        isChange := 1
                    }
                }
            }
        }
        else ; Normal sections
        {
            for key, value in _clsetsSec
            {
                isDeleted := false
                try {
                    valNew := IniRead("CapsLock+settings.ini", sectionValue, key)
                } catch {
                    isDeleted := true
                }

                if(isDeleted)
                {
                    setsChanges[sectionValue]["deleted"][key] := key
                    isChange := 1
                }
                else
                {
                    if(value != valNew)
                    {
                        _clsetsSec[key] := valNew
                        setsChanges[sectionValue]["modified"][key] := valNew
                        isChange := 1
                    }
                }
            }

            for key, value in setsChanges[sectionValue]["deleted"]
            {
                _clsetsSec.Delete(value)
                CLSets["length"][sectionValue]--
            }
            
            for _, value in keyArr
            {
                if(!_clsetsSec.Has(value))
                {
                    try {
                        valNew := IniRead("CapsLock+settings.ini", sectionValue, value)
                        _clsetsSec[value] := valNew
                        CLSets["length"][sectionValue]++
                        setsChanges[sectionValue]["appended"][value] := valNew
                        isChange := 1
                    }
                }
            }
        }
    }
    return isChange
}


globalSettings() {
    ;----------auto start-------------
    autostartLnk := A_StartupCommon . "\CapsLock+.lnk"
    
    if (CLSets["Global"].Has("autostart") && CLSets["Global"]["autostart"] == "1") ; Strict string comparison or conversion
    {
        if FileExist(autostartLnk)
        {
            try {
                FileGetShortcut(autostartLnk, &lnkTarget)
                if(lnkTarget != A_ScriptFullPath)
                    FileCreateShortcut(A_ScriptFullPath, autostartLnk, A_WorkingDir)
            }
        }
        else
        {
            FileCreateShortcut(A_ScriptFullPath, autostartLnk, A_WorkingDir)
        }
    }
    else
    {
        if FileExist(autostartLnk)
        {
            FileDelete(autostartLnk)
        }
    }

    if(CLSets["Global"].Has("allowClipboard") && CLSets["Global"]["allowClipboard"] != "0")
        CLSets["Global"]["allowClipboard"] := 1
}

; 支持ctrl+alt+Capslock启动capslock+
setShortcutKey() {
    startMenuLnk := A_ProgramsCommon . "\CapsLock+.lnk"
    if FileExist(startMenuLnk)
    {
        try {
            FileGetShortcut(startMenuLnk, &lnkTarget)
            if(lnkTarget != A_ScriptFullPath)
                FileCreateShortcut(A_ScriptFullPath, startMenuLnk, A_WorkingDir, , , , "Capslock")
        }
    }
    else
    {
        FileCreateShortcut(A_ScriptFullPath, startMenuLnk, A_WorkingDir, , , , "Capslock")
    }
}

hotStringInit() {
    global regexHotString := "iS)("
    
    if (CLSets.Has("TabHotString")) {
        for key, value in CLSets["TabHotString"]
            regexHotString .= "\Q" . key . "\E" . "|"
    }
    
    if (CLSets.Has("QRun")) {
        for key, value in CLSets["QRun"]
            regexHotString .= "\Q" . key . "\E" . "|"
    }

    if (CLSets.Has("QWeb")) {
        for key, value in CLSets["QWeb"]
            regexHotString .= "\Q" . key . "\E" . "|"
    }
    
    regexHotString .= ")$"
}

CLhotString()
{
    global regexHotString
    matchKey := ""
    RegExMatch(A_Clipboard, regexHotString, &matchKey) ; V2 RegExMatch uses VarRef for OutputVar
    ; matchKey is an Object in v2 (MatchObject)
    
    if(matchKey)
    {
        mKey := matchKey[0] ; Full match
        
        if(CLSets["TabHotString"].Has(mKey))
        {
            temp := RegExReplace(A_Clipboard, "\Q" . mKey . "\E$", CLSets["TabHotString"][mKey])
            temp := StrReplace(temp, "\n", "`n", false) ; All=false? No, CaseSense
            ; StrReplace(InputVar, SearchText [, ReplaceText, CaseSense, &OutputVarCount, Limit])
            ; V1: StringReplace, OutputVar, InputVar, SearchText, ReplaceText [, All]
            ; V2: StrReplace(Haystack, Needle [, ReplaceText, CaseSense, &OutputVarCount, Limit])
            ; So: StrReplace(temp, "\n", "`n") replaces ALL by default.
            
            temp := StrReplace(temp, "\n", "`n")
            temp := StrReplace(temp, "\`n", "\n")
            A_Clipboard := temp
        }
        else if(CLSets["QRun"].Has(mKey)) ; IsObject check in V1 not needed if we ensure strict structure
        {
            A_Clipboard := RegExReplace(A_Clipboard, "\Q" . mKey . "\E$", CLSets["QRun"][mKey]["setValue"])
        }
        else if(CLSets["QWeb"].Has(mKey))
        {
             A_Clipboard := RegExReplace(A_Clipboard, "\Q" . mKey . "\E$", CLSets["QWeb"][mKey]["setValue"])
        }
        
        return mKey
    }
    return ""
}
