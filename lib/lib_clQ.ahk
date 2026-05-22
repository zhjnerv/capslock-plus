; lib_clQ.ahk - V2 Refactor
; Q-Bar Search & Run Module

global QGui := ""
global QGuiHwnd := ""
global QEdit := ""
global QLV := ""
global QLV_Hwnd := ""
global needInitQ := 1
global iconsArray0 := {}
global QBgTextHwnd := ""

global starMenuObj := Map()
global ImageList0 := ""
global ImageList1 := ""
global doNothingWhenChanged := 0
global QSelectedRow := 0

CLq() {
    global QGui, QGuiHwnd, QEdit, QLV, QLV_Hwnd, needInitQ, guiW, editH, margin, QSelectedRow

    if (needInitQ) {
        initQGui()
        needInitQ := 0
    }

    selText := Explorer_GetSelection()
    if (selText == "")
        selText := getSelText()

    ; Determine initial mode based on selection
    if (selText != "") {
        if (QGui) {
             QEdit.Value := selText
             doWhenChanged() ; Trigger update to populate and resize
        }
    } else {
        ; Reset to compact mode
        if (QGui) {
            QEdit.Value := ""
            QLV.Visible := false
            QSelectedRow := 0
            QLV.Delete()
            
            ; Force specific height for compact look
            margin := fixDpi(15)
            editH := fixDpi(50)
            headerH := fixDpi(20)
            headerGap := fixDpi(8)
            compactH := margin*2 + headerH + headerGap + editH
            
            QGui.Show("h" . compactH) ; Removed Center
        }
    }

    if (QGui) {
        if (WinExist("ahk_id " . QGuiHwnd))
            QGui.Show() ; Just activate if exists
        else
            QGui.Show() ; Removed Center
            
        QEdit.Focus()
        SendMessage(0xB1, 0, 0, QEdit.Hwnd) ; Set caret to start (EM_SETSEL 0,0)
    } else {
        initQGui() ; Safety fallback
    }
}

initQGui() {
    global QGui, QGuiHwnd, QEdit, QLV, QLV_Hwnd, CLSets, LVlistsType, QBgTextHwnd

    if (QGui)
        try QGui.Destroy()

    ; Matrix 主题尺寸：顶部字幕雨条独立占位，避免压住输入框。
    global guiW, editH, listH, margin
    guiW := fixDpi(650)
    editH := fixDpi(50)
    listH := fixDpi(350)
    margin := fixDpi(15)
    headerH := fixDpi(20)
    headerGap := fixDpi(8)
    inputY := margin + headerH + headerGap
    listGap := fixDpi(12)
    
    QGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", "Qbar")
    QGuiHwnd := QGui.Hwnd
    
    CLTheme_ApplyWindow(QGui, QGuiHwnd)
    
    global GuiHwnd, LV_show_Hwnd, editHwnd
    GuiHwnd := QGuiHwnd

    qbarFontName := CLTheme_Font("qbar")
    
    CLTheme_AddRainHeader(QGui, margin, margin, guiW - 2*margin, "QBAR STREAM")

    ; 输入框外壳负责形成黑绿舱体，也作为可拖动背景区域的一部分。
    QGui.SetFont(CLTheme_FontOptions(16, "accent"), qbarFontName)
    QBgText := CLTheme_AddPanel(QGui, margin, inputY, guiW - 2*margin, editH, "panel")
    QBgTextHwnd := QBgText.Hwnd
    
    ; 实际输入框居中放置，保持 IME 和 Enter 行为使用原生 Edit。
    innerEditH := fixDpi(30)
    editPadY := (editH - innerEditH) / 2
    editPadX := fixDpi(10)
    
    QGui.SetFont(CLTheme_FontOptions(16, "accent"), qbarFontName)
    QEdit := QGui.Add("Edit", "x" . (margin + editPadX) . " y" . (inputY + editPadY) . " w" . (guiW - 2*margin - 2*editPadX) . " h" . innerEditH . " " . CLTheme_EditOptions("-Multi") . " vInputStr")
    QEdit.OnEvent("Change", doWhenChanged)
    editHwnd := QEdit.Hwnd
    CLTheme_ApplyNativeControlTheme(QEdit)

    ; 原生 ListView 负责结果交互，主题只控制可用的背景和文字颜色。
    QGui.SetFont(CLTheme_FontOptions(11, "text"), qbarFontName)
    QLV := QGui.Add("ListView", "x" . margin . " y" . (inputY + editH + listGap) . " w" . (guiW - 2*margin) . " h" . listH . " " . CLTheme_ListOptions("+Count100 +NoSortHdr -Hdr -Multi"), ["Type", "FileName", "ForSort"])
    QLV_Hwnd := QLV.Hwnd
    LV_show_Hwnd := QLV_Hwnd
    CLTheme_ApplyNativeControlTheme(QLV)
    QLV.OnEvent("Click", QBar_ListClick)
    QLV.OnEvent("DoubleClick", QBar_ListDoubleClick)
    
    ; Activate Mica transparency
    ; WinSetTransColor("010203", QGuiHwnd) ; Disabled to make margins clickable

    ; Remove borders via extended styling if needed, or rely on Background color blending.
    ; LVS_EX_DOUBLEBUFFER (0x10000) for smoother drawing? 
    ; QLV.Opt("+E0x10000") ; Optional optimization

    ; Setup Columns
    QLV.ModifyCol(1, 0) ; Hide Type
    QLV.ModifyCol(2, guiW - 2*margin - 24) ; Main (Account for scrollbar slightly)
    QLV.ModifyCol(3, 0) ; Sort key

    initImageList()
    
    ; Initial state: List Hidden (Compact Mode)
    QLV.Visible := false
    
    ; Initial scan of Star Menu (can be slow, maybe do once)
    SetTimer(scanStarMenu, -100)
    
    ; Hotkeys for QBar navigation
    HotIfWinActive("ahk_id " . QGuiHwnd)
    Hotkey("Up", QBar_Up)
    Hotkey("Down", QBar_Down)
    Hotkey("Esc", QBar_Close)
    HotIf
    
    ; Use Default Button for Enter (Fixes IME Conflict)
    ; When user presses Enter:
    ; 1. If IME is open, IME consumes Enter.
    ; 2. If IME is closed, Enter triggers this default button.
    QGui.Add("Button", "x0 y0 w0 h0 Default Hidden").OnEvent("Click", QBar_Enter)

    QGui.OnEvent("Close", QGuiClose)

    ; Allow dragging window by clicking background
    OnMessage(0x0084, QBar_WM_NCHITTEST)
    
    ; Initial Show (calculated compact height)
    compactH := margin*2 + headerH + headerGap + editH
    QGui.Show("Hide w" . guiW . " h" . compactH)
}

initImageList() {
    global QLV, ImageList0
    ImageList0 := IL_Create(100)
    QLV.SetImageList(ImageList0, 1)
    
    IL_Add(ImageList0, "shell32.dll", 1) ; 1: Generic
    IL_Add(ImageList0, "shell32.dll", 23) ; 2: Search
    IL_Add(ImageList0, "shell32.dll", 14) ; 3: Web
}

QBar_ResultLabel(key, selected := false) {
    return (selected ? ">> " : "   ") . key
}

QBar_IsActive() {
    global QGuiHwnd
    return (QGuiHwnd && WinActive("ahk_id " . QGuiHwnd))
}

QBar_AddResult(iconOption, itemType, key) {
    global QLV
    QLV.Add(iconOption, itemType, QBar_ResultLabel(key), key)
}

QBar_InsertResult(row, iconOption, itemType, key) {
    global QLV
    QLV.Insert(row, iconOption, itemType, QBar_ResultLabel(key), key)
}

QBar_RowKey(row) {
    global QLV
    if (row <= 0 || row > QLV.GetCount())
        return ""

    key := QLV.GetText(row, 3)
    if (key != "")
        return key

    return RegExReplace(QLV.GetText(row, 2), "^(>>| {3})\s*", "")
}

QBar_SetSelected(row) {
    global QLV, QEdit, QSelectedRow

    itemCount := QLV.GetCount()
    if (itemCount == 0) {
        QSelectedRow := 0
        return
    }

    row := Max(1, Min(row, itemCount))

    ; 原生 ListView 在暗色主题下选中态不稳定，额外用文本前缀给出确定标识。
    if (QSelectedRow >= 1 && QSelectedRow <= itemCount && QSelectedRow != row) {
        oldKey := QBar_RowKey(QSelectedRow)
        if (oldKey != "")
            QLV.Modify(QSelectedRow, "Col2", QBar_ResultLabel(oldKey))
    }

    key := QBar_RowKey(row)
    if (key != "")
        QLV.Modify(row, "Col2", QBar_ResultLabel(key, true))

    QLV.Modify(row, "Vis")
    QSelectedRow := row
    try QEdit.Focus()
}

QBar_MoveSelection(offset) {
    global QLV, QSelectedRow

    itemCount := QLV.GetCount()
    if (itemCount == 0)
        return

    row := QSelectedRow
    if (row < 1 || row > itemCount) {
        row := QLV.GetNext(0, "F")
        if (row == 0)
            row := 1
    }

    QBar_SetSelected(row + offset)
}

QBar_ListClick(ctrl, row, *) {
    if (row > 0)
        QBar_SetSelected(row)
}

QBar_ListDoubleClick(ctrl, row, *) {
    if (row <= 0)
        return

    QBar_SetSelected(row)
    QBar_Enter()
}

scanStarMenu() {
    global starMenuObj, QLV, ImageList0
    
    dirs := [A_StartMenu . "\*", A_StartMenuCommon . "\*"]
    
    ; Ensure ImageList is ready (Initialized in Init)
    
    for pattern in dirs {
        Loop Files, pattern, "R" {
            if (InStr(A_LoopFileAttrib, "D"))
                continue
            if (A_LoopFileExt != "lnk")
                continue
            if (RegExMatch(A_LoopFileName, "i)ini|卸载|uninstall"))
                continue
                
            name := RegExReplace(A_LoopFileName, "i)\.lnk$")
            if !starMenuObj.Has(name) {
                fullPath := A_LoopFileFullPath
                
                ; Retrieve Icon
                ; Use IL_Add to extract icon from file
                ; IL_Add(ImageListID, Filename, IconNumber, ResizeNonIcon?)
                ; Returns the index of the added icon
                
                try {
                    iconIdx := IL_Add(ImageList0, fullPath, 1) 
                    ; 1 means first icon? Or pass 0? Usually 1 is safe for exe/lnk.
                    ; AHK v2 IL_Add: Filename, IconNumber
                    
                    if (iconIdx == 0) ; Failed
                        iconIdx := 1 ; Fallback to generic shell icon
                } catch {
                     iconIdx := 1
                }
                
                ; Store path and icon index
                starMenuObj[name] := {path: fullPath, icon: iconIdx}
            }
        }
    }
}

populateListView() {
    global QLV, CLSets, QSelectedRow
    QSelectedRow := 0
    QLV.Delete()

    ; Add QRun items
    if (CLSets.Has("QRun")) {
        for key, val in CLSets["QRun"] {
            ; Icon handling TODO
            QBar_AddResult("Icon1", "Run", key)
        }
    }

    ; Add QSearch items
    if (CLSets.Has("QSearch")) {
        for key, val in CLSets["QSearch"] {
            QBar_AddResult("Icon2", "Search", key)
        }
    }

    ; Add QWeb items
    if (CLSets.Has("QWeb")) {
        for key, val in CLSets["QWeb"] {
            QBar_AddResult("Icon3", "Web", key)
        }
    }
}

doWhenChanged(*) {
    global doNothingWhenChanged, QGui, QEdit, QLV, CLSets, starMenuObj, QSelectedRow
    if (doNothingWhenChanged)
        return
        
    searchText := QEdit.Value
    
    margin := fixDpi(15)
    editH := fixDpi(50)
    headerH := fixDpi(20)
    headerGap := fixDpi(8)
    listGap := fixDpi(12)
    maxListH := fixDpi(350)
    guiW := fixDpi(650)
    compactH := margin*2 + headerH + headerGap + editH
    
    if (searchText == "") {
        ; Search cleared -> Switch to Compact Mode
        QLV.Visible := false
        QSelectedRow := 0
        QLV.Delete()
        QGui.Show("h" . compactH . " NoActivate")
        return
    }
    
    ; Perform Search / Filtering
    QLV.Opt("-Redraw")
    QSelectedRow := 0
    QLV.Delete()
    
    ; Filter QRun
    if (CLSets.Has("QRun")) {
        for key, val in CLSets["QRun"] {
            if InStr(key, searchText)
                QBar_AddResult("Icon1", "Run", key)
        }
    }
    
    ; Filter QSearch
    if (CLSets.Has("QSearch")) {
        for key, val in CLSets["QSearch"] {
             if InStr(key, searchText)
                QBar_AddResult("Icon2", "Search", key)
        }
    }
    
    ; Filter StarMenu
    for name, itemObj in starMenuObj {
        if InStr(name, searchText) {
            ; itemObj is {path: fullPath, icon: iconIdx}
            iconOption := "Icon" . itemObj.icon
            QBar_AddResult(iconOption, "App", name)
        }
    }
    
    ; Handle "Command Parameter" format
    if InStr(searchText, " ") {
        parts := StrSplit(searchText, " ")
        cmd := parts[1]
        if (CLSets.Has("QSearch") && CLSets["QSearch"].Has(cmd)) {
             QBar_InsertResult(1, "Icon2", "Search", searchText)
        } else if (CLSets.Has("QRun") && CLSets["QRun"].Has(cmd)) {
            ; Also allow QRun checks to populate list (or just ensure it's not empty so Enter works on it?)
            ; The filtered list might be empty because "PS file" does not contain "PS " (exact string search) 
            ; But "PS" key is "PS". 
            ; Wait, QRun filter above uses `if InStr(key, searchText)`. 
            ; If key="PS", searchText="PS file", InStr("PS", "PS file") is FALSE.
            ; So we need to explicitly re-add or allow matching if searchText starts with key.
             QBar_InsertResult(1, "Icon1", "Run", cmd) ; Insert the CMD so it can be selected? Or insert the whole text?
             ; If we insert whole text "PS file", then QRun execution logic needs to handle that Key is "PS file" which is NOT in CLSets["QRun"].
             ; Better to insert "PS" (the valid key) or ensure standard QRun logic handles it.
             ; The loop below in QBar_Enter -> "Execute Selected Item" checks `if (CLSets["QRun"].Has(key))`.
             ; So we MUST insert the KEY "PS" into the list, not the full string.
        }
    }
    
    ; Post-Search Logic: Check count and resize
    itemCount := QLV.GetCount()
    
    if (itemCount == 0) {
        ; No matches -> consistent with Compact Mode
        QLV.Visible := false
        QSelectedRow := 0
        QGui.Show("h" . compactH . " NoActivate")
    } else {
        ; Matches found -> Calculate dynamic height
        ; Row height estimation: s11 font + small icon ~ 28px
        rowH := fixDpi(28) 
        reqH := itemCount * rowH + fixDpi(8) ; slight buffer
        
        finalListH := Min(reqH, maxListH)
        
        QLV.Move(,, guiW - 2*margin, finalListH)
        QLV.Visible := true
        
        ; Resize Window
        fullH := margin + headerH + headerGap + editH + listGap + finalListH + margin
        QGui.Show("h" . fullH . " NoActivate")
        
        ; Select first item
        QBar_SetSelected(1)
    }

    QLV.Opt("+Redraw")
}

QBar_Up(*) {
    QBar_MoveSelection(-1)
}

QBar_Down(*) {
    QBar_MoveSelection(1)
}

QBar_Enter(*) {
    global QGui, QLV, QEdit, CLSets, starMenuObj, QSelectedRow

    row := QSelectedRow
    if (row <= 0 || row > QLV.GetCount())
        row := QLV.GetNext(0, "F")
    
    inputVal := QEdit.Value
    if (inputVal == "")
        return

    ; --- 1. Execute Selected Item ---
    if (row > 0) {
        key := QBar_RowKey(row)
        executed := false
        
        ; QRun
        if (CLSets.Has("QRun") && CLSets["QRun"].Has(key)) {
            item := CLSets["QRun"][key]
            path := item["setValue"]
            
            ; Check for params in inputVal
            param := ""
            if RegExMatch(inputVal, "i)^\s*\Q" . key . "\E\s+(.*)$", &m) {
                param := m[1]
            }
            
            if (param != "") {
                try Run(path . " " . param)
            } else {
                try Run(path)
            }
                
            executed := true
        } 
        ; QWeb
        else if (CLSets.Has("QWeb") && CLSets["QWeb"].Has(key)) {
            item := CLSets["QWeb"][key]
            url := item["setValue"]
            
            ; Parse param from inputVal
            param := ""
            if RegExMatch(inputVal, "i)^\s*\Q" . key . "\E\s+(.*)$", &m) {
                param := m[1]
            } else if (inputVal = key) {
                param := ""
            } else {
                param := inputVal 
            }
            param := Trim(param)

            finalUrl := StrReplace(url, "%s", param)
            finalUrl := StrReplace(finalUrl, "{q}", param)
            try Run(finalUrl)
            executed := true
        } 
        ; Start Menu
        else if (starMenuObj.Has(key)) {
            try Run(starMenuObj[key].path)
            executed := true
        } 
        ; QSearch (Logic for "Command Parameter")
        else if (CLSets.Has("QSearch")) {
             if RegexMatch(key, "^\s*(\S+)\s+(.*)$", &m) {
                 cmd := m[1]
                 param := m[2]
             } else {
                 cmd := key
                 param := ""
             }
             param := Trim(param)
             
             if (CLSets["QSearch"].Has(cmd)) {
                 item := CLSets["QSearch"][cmd]
                 url := item["setValue"]
                 finalUrl := StrReplace(url, "%s", param)
                 finalUrl := StrReplace(finalUrl, "{q}", param)
                 try Run(finalUrl)
                 executed := true
             }
        }
        
        if (!executed) {
            try Run(key) ; Fallback for raw commands
        }
    } 
    ; --- 2. Fallback: No Selection -> Default Web Search or Direct QSearch/QRun ---
    else {
        isCustomCmd := false
        
        if RegexMatch(inputVal, "^\s*(\S+)\s+(.*)$", &m) {
             cmd := m[1]
             param := m[2]
        } else {
             cmd := inputVal
             param := ""
        }
        param := Trim(param)

        ; Check QSearch
        if (CLSets.Has("QSearch") && CLSets["QSearch"].Has(cmd)) {
             item := CLSets["QSearch"][cmd]
             url := item["setValue"]
             finalUrl := StrReplace(url, "%s", param)
             finalUrl := StrReplace(finalUrl, "{q}", param)
             try Run(finalUrl)
             isCustomCmd := true
        }
        ; Check QRun (Added fallback)
        else if (CLSets.Has("QRun") && CLSets["QRun"].Has(cmd)) {
            item := CLSets["QRun"][cmd]
            path := item["setValue"]
            if (param != "") {
                try Run(path . " " . param)
            } else {
                try Run(path)
            }
            isCustomCmd := true
        }

        if (!isCustomCmd) {
            if RegExMatch(inputVal, "^(https?://|www\.)")
                target := inputVal
            else
                target := "https://www.google.com/search?q=" . inputVal
            
            try Run(target)
        }
    }


    QGui.Hide()
}

QBar_Close(*) {
    global QGui
    QGui.Hide()
}

QGuiClose(*) {
    global QGui
    QGui.Hide()
}

listViewIconGet(path) {
    ; Placeholder for extracting icon index
    return 1
}

QBar_WM_NCHITTEST(wParam, lParam, msg, hwnd) {
    global QGuiHwnd, editHwnd, QLV_Hwnd
    if (hwnd == QGuiHwnd) {
        targetHwnd := DllCall("User32.dll\WindowFromPoint", "int64", lParam, "ptr")
        if (targetHwnd == editHwnd || targetHwnd == QLV_Hwnd)
            return
        return 2 ; HTCAPTION
    }
}


