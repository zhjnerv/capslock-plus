; ===============================================
; lib_functions.ahk - V2 Refactor
; ===============================================

getSelText_testVersion()
{
    ClipboardOld := ClipboardAll()
    A_Clipboard := ""
    SendInput("+{Left}^{c}+{Right}")
    if ClipWait(0.1)
    {
        selText := A_Clipboard
        A_Clipboard := ClipboardOld
        if(Ord(selText)!=13 && StrLen(selText)>1)
        {
            return SubStr(selText, 2)
        }
        else
        {
            return ""
        }
    }
    A_Clipboard := ClipboardOld
    return ""
}


getSelText()
{
    ClipboardOld := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{insert}") ; or ^c
    if ClipWait(0.1)
    {
        selText := A_Clipboard
        A_Clipboard := ClipboardOld
        if (selText == "")
             return ""

        lastChar := SubStr(selText, -1)
        if(Ord(lastChar)!=10) ;如果最后一个字符是换行符，就认为是在IDE那复制了整行，不要这个结果
        {
            return selText
        }
    }
    A_Clipboard := ClipboardOld
    return ""
}

; UTF8encode Refactor using Buffer
UTF8encode(str) 
{
    if (str == "")
        return ""
    
    ; V2 has no SetFormat. Use Format()
    
    try {
        ; Calculate size
        if (str == "")
            return ""
            
        ; StrPut returns byte count including null.
        ; Convert to UTF-8
        buf := Buffer(StrPut(str, "UTF-8"))
        len := StrPut(str, buf, "UTF-8") - 1 ; Exclude null terminator
        
        returnStr := ""
        Loop len
        {
            byteVal := NumGet(buf, A_Index - 1, "UChar")
            hexStr := Format("{:02X}", byteVal)
            returnStr .= "%" . hexStr
        }
        return returnStr
    } catch {
        return ""
    }
}

URLencode(str) 
{
    if (str == "")
        return ""
    
    static encodeMap := Map(
        "!", "%21", "#", "%23", "$", "%24", "&", "%26", "'", "%27", "(", "%28", ")", "%29", "*", "%2A", "+", "%2B", ",", "%2C",
        ":", "%3A", ";", "%3B", "=", "%3D", "?", "%3F", "@", "%40", "[", "%5B", "]", "%5D",
        " ", "%20", "<", "%3C", ">", "%3E", "{", "%7B", "}", "%7D", "|", "%7C", "\", "%5C", "^", "%5E", "~", "%7E", "``", "%60", '"', "%22"
    )
    
    result := ""
    
    Loop Parse, str
    {
        char := A_LoopField
        if (encodeMap.Has(char)) {
            result .= encodeMap[char]
        } else if (char == "`n") {
            result .= "%0A"
        } else if (char == "`r") {
            result .= "%0D"
        } else if (char == "`t") {
            result .= "%09"
        } else {
            result .= char
        }
    }
    return result
}

FullURLencode(str)
{
    if (str == "")
        return ""
    
    result := ""
    Loop Parse, str
    {
        char := A_LoopField
        asciiVal := Ord(char)
        
        if ((asciiVal >= 48 && asciiVal <= 57)     ; 0-9
            || (asciiVal >= 65 && asciiVal <= 90)  ; A-Z
            || (asciiVal >= 97 && asciiVal <= 122) ; a-z
            || char == "-" || char == "_" || char == "." || char == "~") {
            result .= char
        } else if (asciiVal <= 127) {
            result .= "%" . Format("{:02X}", asciiVal)
        } else {
            result .= UTF8encode(char)
        }
    }
    return result
}

checkStrType(str, fuzzy:=0)
{
    if(!FileExist(str))
    {
        if(RegExMatch(str, 'iS)^((https?:\/\/)|www\.)([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?|(https?:\/\/)?([\da-z\.-]+)\.(com|net|org)(\W[\/\w \.-]*)*\/?$'))
            return "web"
    }
    if(RegExMatch(str, 'i)^ftp://'))
        return "ftp"
    else
    {
        if(fuzzy)
            return "fileOrFolder"
        if(RegExMatch(str, 'iS)^[a-z]:\\.+\..+$'))
            return "file"
        if(RegExMatch(str, 'iS)^[a-z]:\\[^.]*$'))
            return "folder"
    }
    return "unknown"
}

; DPI Fix logic
fixDpi(num)
{
    t := Ceil(num/96*A_ScreenDPI)
    if(A_ScreenDPI>96 && A_ScreenDPI<=120)  ;125%
        t+=1
    if(A_ScreenDPI>120 && A_ScreenDPI<=144) ;150
        t+=1
    if(A_ScreenDPI>144 && A_ScreenDPI<=192) ;200%
        t+=2
    if(A_ScreenDPI>192 && A_ScreenDPI<=240) ;250
        t+=3
    if(A_ScreenDPI>240 && A_ScreenDPI<=288) ;300%
        t+=4
    if(A_ScreenDPI>288) 
        t+=6
    return t
}

setSettings(sec,key,val)
{
    IniWrite(val, "CapsLock+settings.ini", sec, key)
}

showMsg(msg, t:=2000)
{
    ToolTip(msg)
    t := -t
    SetTimer(clearToolTip, t)
}

clearToolTip() {
    ToolTip()
}

extractSetStr(str, &runStr:="", &ifAdmin:=false, &param:="")
{
    str := Trim(str, " `t")
    runStr := ""
    ifAdmin := false
    param := ""
    
    str0Match := ""
	if(!RegExMatch(str, "^%(\w+)%", &str0Match))
		RegExMatch(str, '(?<=(?:\x27|\x22))%(\w+)%', &str0Match)
        
	if(str0Match)
	{
		try {
            _t := EnvGet(str0Match[1])
		    str := StrReplace(str, str0Match[0], _t)
        }
	}
	
    if(FileExist(str) || RegExMatch(str, '^ftp://'))
	{
		runStr := str
        return str
	}

	strMatch := ""
	RegExMatch(str, '^(\x27|\x22)(.*)\1$', &strMatch)
    if (strMatch && (FileExist(strMatch[2]) || RegExMatch(str, '^ftp://')))
	{
		runStr := str
		return strMatch[2]
    }
	
    ; RegExMatch result is object.
	if (RegExMatch(str, '(\x27|\x22)(.*)\1', &strMatch))
	{
        if (FileExist(strMatch[2]))
        {
            runStr := strMatch[0] ; Full match quoted
            ; Check admin
            strArr := StrSplit(str, strMatch[0])
            arr1 := Trim(strArr[1])
            arr2 := (strArr.Length > 1) ? Trim(strArr[2]) : ""
            
            if(RegExMatch(arr1, 'i)^\*RunAs$'))
            {
                ifAdmin := true
                runStr := "*RunAs " . runStr
            }
            
            if(arr2 != "")
            {
                param := arr2
                runStr := runStr . " " . arr2
            }
            return strMatch[2]
        }
    }
	return ""
}

alert(str)
{
    MsgBox(str)
}

set2Run(str)
{
	runStr := ""
	extractSetStr(str, &runStr)
	return runStr
}

foolGui(switchVal:=1){
	if !switchVal
	{
        try {
		    Gui("foolgui:Destroy") 
            ; V2 Named Guis: MyGui := Gui() ... MyGui.Destroy()
            ; Legacy names not supported directly.
            ; Use Global variable to store GUI object.
        }
        global MyFoolGui
        if IsSet(MyFoolGui) && MyFoolGui
             MyFoolGui.Destroy()
		return
	}

    global MyFoolGui := Gui("-Caption +E0x80000 +LastFound +OwnDialogs +Owner")
	MyFoolGui.Show("NA")
    ; WinActivate("foolgui") ; Title is empty by default? Set title in Gui().
    ; But we didn't set title.
}

clipSaver(clipX)
{
    global sClipboardAll, cClipboardAll, caClipboardAll
    if(WinActive("ahk_exe EXCEL.EXE"))
    {
        foolgui() ; creates gui
        if(clipX=="s")
            sClipboardAll := ClipboardAll()
        else if(clipX=="c")
            cClipboardAll := ClipboardAll()
        else 
            caClipboardAll := ClipboardAll()
        foolgui(0)
    }
    else
    {
        if(clipX=="s")
            sClipboardAll := ClipboardAll()
        else if(clipX=="c")
            cClipboardAll := ClipboardAll()
        else 
            caClipboardAll := ClipboardAll()
    }
}

; runFunc Refactor for V2
; Params are strictly parsed.
runFunc(str){
    str := Trim(str)
    ; Simple call: funcName
    if(!RegExMatch(str, '\)$'))
    {
        %str%()
        return
    }
    
    match := ""
    if(RegExMatch(str, '(\w+)\((.*)\)$', &match))
    {
        funcName := match[1]
        argsStr := match[2]
        
        try {
            if (argsStr == "") {
                %funcName%()
                return
            }
            
            params := []
            Loop Parse, argsStr, "CSV"
            {
                val := A_LoopField
                if IsInteger(val)
                    val := Integer(val)
                else if IsFloat(val)
                    val := Float(val)
                params.Push(val)
            }
            
            ; Dynamic call with params array
            %funcName%(params*)
        }
    }
}

SystemCursor(OnOff:=1)   
{
    static AndMask, XorMask, CurrentCursorType, h_cursor, c0
    ; Initialization logic needs careful porting or use built-in BlockInput check?
    ; Using a cleaner modern approach or stick to DllCall?
    ; Stick to DllCall for custom cursor hiding.
    
    ; Note: VarSetCapacity -> Buffer
    if (OnOff == "Init" or OnOff == "I" or !IsSet(CurrentCursorType))       
    {
        CurrentCursorType := "h" 
        h_cursor := Buffer(4444, 1) ; Arbitrary size?
        AndMask := Buffer(32*4, 0xFF)
        XorMask := Buffer(32*4, 0)
        
        system_cursors := "32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650"
        cursors := StrSplit(system_cursors, ",")
        c0 := cursors.Length
        
        ; Using Maps for static storage equivalents of c%Index%
        static cursor_handles := Map()
        
        Loop c0
        {
            id := cursors[A_Index]
            h_cur := DllCall("LoadCursor", "Ptr",0, "Ptr", id, "Ptr")
            
            h_copy := DllCall("CopyImage", "Ptr", h_cur, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0, "Ptr")
            cursor_handles["h" . A_Index] := h_copy
            
            b_cursor := DllCall("CreateCursor", "Ptr", 0, "Int", 0, "Int", 0, 
                "Int", 32, "Int", 32, "Ptr", AndMask, "Ptr", XorMask, "Ptr")
            cursor_handles["b" . A_Index] := b_cursor
            
            cursor_handles["c" . A_Index] := id
        }
    }
    
    if (OnOff == 0 or OnOff == "Off" or (CurrentCursorType == "h" and (OnOff < 0 or OnOff == "Toggle" or OnOff == "T")))
        CurrentCursorType := "b"
    else
        CurrentCursorType := "h"
        
    Loop c0
    {
        h_img := cursor_handles[CurrentCursorType . A_Index]
        id := cursor_handles["c" . A_Index]
        DllCall("SetSystemCursor", "Ptr", h_img, "UInt", id)
    }
}

applyModernStyle(hwnd) {
    ; OS Version check for Windows 11 (Build 22000+)
    try {
        isWin11 := VerCompare(A_OSVersion, "10.0.22000") >= 0
        
        if isWin11 {
            ; 1. Rounded Corners (DWMWA_WINDOW_CORNER_PREFERENCE = 33)
            ; DWA_WCP_ROUND = 2
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 33, "int*", 2, "uint", 4)
            
            ; 2. Immersive Dark Mode (DWMWA_USE_IMMERSIVE_DARK_MODE = 20)
            ; ESSENTIAL for dark shadow and correct system menus
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 20, "int*", 1, "uint", 4)

            ; 3. Mica Backdrop (DWMWA_SYSTEMBACKDROP_TYPE = 38)
            ; DWMSBT_MAINWINDOW (Mica) = 2
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 38, "int*", 2, "uint", 4)
            
            ; 4. Caption Color (Transparent) to allow Mica to extend to top if used
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 35, "int*", 0xFFFFFFFE, "uint", 4)
        }
    }
    
    ; 3. Draw Shadow (for -Caption windows)
    margins := Buffer(16, 0)
    NumPut("int", 1, margins, 0)
    NumPut("int", 1, margins, 4)
    NumPut("int", 1, margins, 8)
    NumPut("int", 1, margins, 12)
    DllCall("dwmapi\DwmExtendFrameIntoClientArea", "ptr", hwnd, "ptr", margins)
}

Explorer_GetSelection() {
    hwnd := WinExist("A")
    if !hwnd
        return ""
        
    processName := ""
    try {
        processName := WinGetProcessName(hwnd)
        class := WinGetClass(hwnd)
    } catch {
        return ""
    }
    
    if (processName != "explorer.exe")
        return ""
        
    res := ""
    if (class ~= "Progman|WorkerW") {
        ; Desktop handled via ControlGet on SysListView321? 
        ; V2 lacks direct ControlGet List command. 
        ; Attempting default Clipboard fallback or skipping Desktop specific logic for now 
        ; unless using raw SendMessage.
        return "" 
    } else if (class ~= "(Cabinet|Explore)WClass") {
        try {
            for window in ComObject("Shell.Application").Windows {
                try {
                    if (window.hwnd == hwnd) {
                        sel := window.Document.SelectedItems
                        for item in sel
                            res .= item.path . "`n"
                        break
                    }
                }
            }
        }
    }
    
    return Trim(res, "`n")
}

getActiveDirectoryPath() {
    hwnd := WinExist("A")
    if !hwnd
        return ""

    processName := ""
    class := ""
    try {
        processName := WinGetProcessName(hwnd)
        class := WinGetClass(hwnd)
    } catch {
        return ""
    }

    if (processName != "explorer.exe")
    {
        if (RegExMatch(processName, "i)^TotalCMD(64)?\.exe$"))
            return getTotalCommanderDirectory(hwnd)
        return ""
    }

    for window in ComObject("Shell.Application").Windows {
        try {
            if (window.hwnd != hwnd)
                continue

            selectedPath := ""
            try {
                sel := window.Document.SelectedItems
                for item in sel {
                    selectedPath := item.Path
                    break
                }
            }

            if (selectedPath != "")
                return pathToDirectory(selectedPath)

            currentPath := ""
            try currentPath := window.Document.Folder.Self.Path
            if (currentPath != "")
                return pathToDirectory(currentPath)
        }
    }

    if (class ~= "Progman|WorkerW")
        return A_Desktop

    return ""
}

getTotalCommanderDirectory(hwnd) {
    pathControls := []

    try {
        for ctrlHwnd in WinGetControlsHwnd("ahk_id " . hwnd) {
            ctrlText := getWindowTextByHwnd(ctrlHwnd)
            ctrlText := Trim(ctrlText)
            if (ctrlText == "")
                continue

            dirPath := normalizeTcPath(ctrlText)
            if (dirPath == "")
                continue

            ctrlX := 0
            ctrlY := 0
            ctrlW := 0
            ctrlH := 0
            try WinGetPos(&ctrlX, &ctrlY, &ctrlW, &ctrlH, "ahk_id " . ctrlHwnd)

            pathControls.Push({
                hwnd: ctrlHwnd,
                dir: dirPath,
                centerX: ctrlX + ctrlW / 2
            })
        }
    } catch {
        return ""
    }

    if (pathControls.Length = 0) {
        fallbackDir := getTotalCommanderDirectoryFromWindowText(hwnd)
        if (fallbackDir != "")
            return fallbackDir
        return ""
    }

    if (pathControls.Length = 1)
        return pathControls[1].dir

    focusHwnd := 0
    try {
        focusClassNN := ControlGetFocus("ahk_id " . hwnd)
        if (focusClassNN != "")
            focusHwnd := ControlGetHwnd(focusClassNN, "ahk_id " . hwnd)
    }

    if (!focusHwnd)
        return pathControls[pathControls.Length].dir

    focusX := 0
    focusY := 0
    focusW := 0
    focusH := 0
    try WinGetPos(&focusX, &focusY, &focusW, &focusH, "ahk_id " . focusHwnd)

    if (focusW = 0 && focusH = 0)
        return pathControls[pathControls.Length].dir

    focusCenterX := focusX + focusW / 2
    bestDir := pathControls[1].dir
    bestDistance := Abs(pathControls[1].centerX - focusCenterX)

    for item in pathControls {
        distance := Abs(item.centerX - focusCenterX)
        if (distance < bestDistance) {
            bestDistance := distance
            bestDir := item.dir
        }
    }

    return bestDir
}

normalizeTcPath(pathText) {
    pathText := Trim(pathText)
    if (pathText == "")
        return ""

    if (DirExist(pathText))
        return pathText

    pathMatch := ""
    if (RegExMatch(pathText, "i)((?:[a-z]:\\|\\\\)[^`r`n]*?)(?=[\\/]\*\.\*$)", &pathMatch))
        return pathToDirectory(pathMatch[1])

    return ""
}

getTotalCommanderDirectoryFromWindowText(hwnd) {
    allText := ""
    try allText := WinGetText("ahk_id " . hwnd)
    if (allText = "")
        return ""

    lastDir := ""
    Loop Parse, allText, "`n", "`r" {
        dirPath := normalizeTcPath(A_LoopField)
        if (dirPath != "")
            lastDir := dirPath
    }

    return lastDir
}

getWindowTextByHwnd(hwnd) {
    if (!hwnd)
        return ""

    textLen := DllCall("user32\GetWindowTextLengthW", "ptr", hwnd, "int")
    if (textLen <= 0)
        return ""

    buf := Buffer((textLen + 1) * 2, 0)
    copied := DllCall("user32\GetWindowTextW", "ptr", hwnd, "ptr", buf, "int", textLen + 1, "int")
    if (copied <= 0)
        return ""

    return StrGet(buf, copied, "UTF-16")
}

pathToDirectory(path) {
    path := Trim(path, " `t`"`r`n")
    if (path == "")
        return ""

    if DirExist(path)
        return path

    if FileExist(path) {
        SplitPath(path, , &dirPath)
        return dirPath
    }

    return ""
}

openTerminalAtActiveDirectory() {
    targetDir := getActiveDirectoryPath()
    if (targetDir == "") {
        showMsg("No folder context", 1200)
        return false
    }

    existingTerminalWindows := getTerminalWindowMap()

    try {
        terminalPid := 0
        Run("wt.exe -d `"" . targetDir . "`"", , , &terminalPid)
        activateLaunchedTerminalWindow(terminalPid, existingTerminalWindows)
        return true
    } catch {
    }

    try {
        escapedDir := StrReplace(targetDir, "'", "''")
        terminalPid := 0
        Run("powershell.exe -NoExit -Command `"Set-Location -LiteralPath ''" . escapedDir . "''`"", , , &terminalPid)
        activateLaunchedTerminalWindow(terminalPid, existingTerminalWindows)
        return true
    } catch {
    }

    showMsg("Terminal launch failed", 1500)
    return false
}

getTerminalWindowMap() {
    windows := Map()

    for hwnd in WinGetList("ahk_exe WindowsTerminal.exe")
        windows[String(hwnd)] := true

    for hwnd in WinGetList("ahk_exe powershell.exe")
        windows[String(hwnd)] := true

    for hwnd in WinGetList("ahk_class ConsoleWindowClass")
        windows[String(hwnd)] := true

    return windows
}

activateLaunchedTerminalWindow(terminalPid, existingWindows) {
    Loop 20 {
        Sleep(100)

        if (terminalPid) {
            hwnd := WinExist("ahk_pid " . terminalPid)
            if (hwnd) {
                try WinActivate("ahk_id " . hwnd)
                return true
            }
        }

        currentWindows := getTerminalWindowMap()
        for hwndText, _ in currentWindows {
            if (existingWindows.Has(hwndText))
                continue

            hwnd := Integer(hwndText)
            try WinActivate("ahk_id " . hwnd)
            return true
        }
    }

    return false
}
