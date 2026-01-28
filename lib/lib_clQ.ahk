; lib_clQ.ahk - V2 Refactor
; Q-Bar Search & Run Module

global QGui := ""
global QGuiHwnd := ""
global QEdit := ""
global QLV := ""
global QLV_Hwnd := ""
global needInitQ := 1
global iconsArray0 := {}

global starMenuObj := Map()
global ImageList0 := ""
global ImageList1 := ""
global doNothingWhenChanged := 0

CLq() {
    global QGui, QGuiHwnd, QEdit, QLV, QLV_Hwnd, needInitQ, guiW, editH, margin

    if (needInitQ) {
        initQGui()
        needInitQ := 0
    }

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
            QLV.Delete()
            
            ; Force specific height for compact look
            margin := fixDpi(15)
            editH := fixDpi(50)
            compactH := margin*2 + editH
            
            QGui.Show("h" . compactH . " Center")
        }
    }

    if (QGui) {
        if (WinExist("ahk_id " . QGuiHwnd))
            QGui.Show() ; Just activate if exists
        else
            QGui.Show("Center") ; Show logic
            
        QEdit.Focus()
    } else {
        initQGui() ; Safety fallback
    }
}

initQGui() {
    global QGui, QGuiHwnd, QEdit, QLV, QLV_Hwnd, CLSets, LVlistsType

    if (QGui)
        try QGui.Destroy()

    ; Dimensions (Modern & Clean)
    ; Dimensions (Modern & Clean)
    global guiW, editH, listH, margin
    guiW := fixDpi(650)
    editH := fixDpi(50)
    listH := fixDpi(350)
    margin := fixDpi(15)
    
    QGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", "Qbar")
    QGuiHwnd := QGui.Hwnd
    
    ; Apply Win11 Styles (Rounded Corners & Mica & Dark Mode)
    applyModernStyle(QGuiHwnd)

    QGui.BackColor := "010203" ; Chroma Key for Mica (Made transparent below)
    
    global GuiHwnd, LV_show_Hwnd, editHwnd
    GuiHwnd := QGuiHwnd

    ; Modern font selection
    fontName := "Segoe UI Variable Text" ; Win11 Standard
    
    ; --- Search Bar Composition ---
    ; 1. background container (Simulated by Text control)
    ; This provides the "Box" look with the specific color
    QGui.SetFont("s16", fontName)
    QGui.Add("Text", "x" . margin . " y" . margin . " w" . (guiW - 2*margin) . " h" . editH . " Background2D2D2D")
    
    ; 2. Actual Edit Input (Centered inside the background)
    ; Calculate vertical center: (50 - 30) / 2 = 10 padding top
    innerEditH := fixDpi(30)
    editPadY := (editH - innerEditH) / 2
    editPadX := fixDpi(10)
    
    QGui.SetFont("s16 cWhite", fontName)
    QEdit := QGui.Add("Edit", "x" . (margin + editPadX) . " y" . (margin + editPadY) . " w" . (guiW - 2*margin - 2*editPadX) . " h" . innerEditH . " -Multi -E0x200 Background2D2D2D cWhite vInputStr")
    QEdit.OnEvent("Change", doWhenChanged)
    editHwnd := QEdit.Hwnd

    ; ListView: Distinct background
    QGui.SetFont("s11 cE0E0E0", fontName)
    ; Increased gap between edit and list
    QLV := QGui.Add("ListView", "x" . margin . " y" . (margin + editH + 12) . " w" . (guiW - 2*margin) . " h" . listH . " +Count100 +NoSortHdr -Hdr -Multi Background2D2D2D cWhite", ["Type", "FileName", "ForSort"])
    QLV_Hwnd := QLV.Hwnd
    LV_show_Hwnd := QLV_Hwnd
    
    ; Activate Mica transparency
    WinSetTransColor("010203", QGuiHwnd)

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
    
    ; Initial Show (calculated compact height)
    compactH := margin*2 + editH
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
    global QLV, CLSets
    QLV.Delete()

    ; Add QRun items
    if (CLSets.Has("QRun")) {
        for key, val in CLSets["QRun"] {
            ; Icon handling TODO
            QLV.Add("Icon1", "Run", key, 0)
        }
    }

    ; Add QSearch items
    if (CLSets.Has("QSearch")) {
        for key, val in CLSets["QSearch"] {
            QLV.Add("Icon2", "Search", key, 0)
        }
    }

    ; Add QWeb items
    if (CLSets.Has("QWeb")) {
        for key, val in CLSets["QWeb"] {
            QLV.Add("Icon3", "Web", key, 0)
        }
    }
}

doWhenChanged(*) {
    global doNothingWhenChanged, QEdit, QLV, CLSets, starMenuObj
    if (doNothingWhenChanged)
        return
        
    searchText := QEdit.Value
    
    margin := fixDpi(15)
    editH := fixDpi(50)
    maxListH := fixDpi(350)
    guiW := fixDpi(650)
    compactH := margin*2 + editH
    
    if (searchText == "") {
        ; Search cleared -> Switch to Compact Mode
        QLV.Visible := false
        QLV.Delete()
        QGui.Show("h" . compactH . " NoActivate")
        return
    }
    
    ; Perform Search / Filtering
    QLV.Opt("-Redraw")
    QLV.Delete()
    
    ; Filter QRun
    if (CLSets.Has("QRun")) {
        for key, val in CLSets["QRun"] {
            if InStr(key, searchText)
                QLV.Add("Icon1", "Run", key, 0)
        }
    }
    
    ; Filter QSearch
    if (CLSets.Has("QSearch")) {
        for key, val in CLSets["QSearch"] {
             if InStr(key, searchText)
                QLV.Add("Icon2", "Search", key, 0)
        }
    }
    
    ; Filter StarMenu
    for name, itemObj in starMenuObj {
        if InStr(name, searchText) {
            ; itemObj is {path: fullPath, icon: iconIdx}
            iconOption := "Icon" . itemObj.icon
            QLV.Add(iconOption, "App", name, 0)
        }
    }
    
    ; Handle "Command Parameter" format
    if InStr(searchText, " ") {
        parts := StrSplit(searchText, " ")
        cmd := parts[1]
        if (CLSets["QSearch"].Has(cmd)) {
             QLV.Insert(1, "Icon2", "Search", searchText, 0)
        }
    }
    
    ; Post-Search Logic: Check count and resize
    itemCount := QLV.GetCount()
    
    if (itemCount == 0) {
        ; No matches -> consistent with Compact Mode
        QLV.Visible := false
        QGui.Show("h" . compactH . " NoActivate")
    } else {
        ; Matches found -> Calculate dynamic height
        ; Row height estimation: s11 font + small icon ~ 28px
        rowH := fixDpi(28) 
        reqH := itemCount * rowH + fixDpi(8) ; slight buffer
        
        finalListH := Min(reqH, maxListH)
        
        ; Resize ListView first
        ; AHK v2 GuiControl.Move(X, Y, W, H) - trailing commas are not valid if strict
        ; The error says "Too many parameters", likely because I used `,,,(W), (H)` 
        ; but Move only accepts 4 optional params? No, Move([X, Y, W, H, Draw]). 
        ; Actually, parameters are passed individually, not as blank commas unless explicitly skipping.
        ; Let's be explicit to avoid "Too many parameters" if some overload is weird.
        ; Actually, the issue might be `margin` or `guiW` interpretation or just syntax.
        ; Wait, QLV.Move(,, W, H) is correct for v2.
        ; Ah, the comma syntax in v2 function calls: Move(X, Y, W, H). 
        ; If I skip X and Y, it should be Move(,, W, H).
        ; Let's try explicit implementation or just check docs.
        ; Docs: Move([X, Y, W, H, Draw])
        ; Error "Too many parameters" implies I passed more than 5? 
        ; QLV.Move(,,,(guiW - 2*margin), finalListH) -> is parsed as (unset, unset, unset, W, H). 3 unsets + 2 args = 5 args.
        ; Wait, Comma 1: X (unset)
        ; Comma 2: Y (unset)
        ; Comma 3: W (unset)
        ; Comma 4: Arg 4? 
        ; Correct usage: Ctrl.Move([x, y, w, h, draw])
        ; My call: QLV.Move(, , , Width, Height) -> X=skip, Y=skip, W=skip, H=Width, Draw=Height. 
        ; That is wrong logic.
        ; I want to skip X and Y, set W and H.
        ; QLV.Move(,, guiW-2*margin, finalListH) 
        ; X(skip), Y(skip), W(set), H(set)
        
        QLV.Move(,, guiW - 2*margin, finalListH)
        QLV.Visible := true
        
        ; Resize Window
        fullH := margin + editH + 12 + finalListH + margin
        QGui.Show("h" . fullH . " NoActivate")
        
        ; Select first item
        QLV.Modify(1, "Focus Select")
    }

    QLV.Opt("+Redraw")
}

QBar_Up(*) {
    global QLV
    if QLV.Focused
        Send("{Up}")
    else {
        QLV.Focus()
        Send("{Up}")
    }
}

QBar_Down(*) {
    global QLV
    if QLV.Focused
        Send("{Down}")
    else {
        QLV.Focus()
        Send("{Down}")
    }
}

QBar_Enter(*) {
    global QGui, QLV, QEdit, CLSets, starMenuObj

    row := QLV.GetNext(0, "F")
    
    inputVal := QEdit.Value
    if (inputVal == "")
        return

    ; --- 1. Execute Selected Item ---
    if (row > 0) {
        key := QLV.GetText(row, 2)
        executed := false
        
        ; QRun
        if (CLSets.Has("QRun") && CLSets["QRun"].Has(key)) {
            item := CLSets["QRun"][key]
            path := item["setValue"]
            try Run(path)
            executed := true
        } 
        ; QWeb
        else if (CLSets.Has("QWeb") && CLSets["QWeb"].Has(key)) {
            item := CLSets["QWeb"][key]
            url := item["setValue"]
            
            ; Parse param from inputVal (Command + Param) based on the Key
            ; If inputVal starts with Key, strip it.
            ; RegEx: ^\s*\Qkey\E\s+(.*)$
            param := ""
            if RegExMatch(inputVal, "i)^\s*\Q" . key . "\E\s+(.*)$", &m) {
                param := m[1]
            } else if (inputVal = key) {
                param := ""
            } else {
                ; If inputVal doesn't start with key (e.g. partial match selected?), use whole input?
                ; Or maybe inputVal IS the param if logic differs?
                ; Assuming standard usage: user typed "wiki foo", selected "wiki".
                param := inputVal ; Fallback, but likely won't happen if key matches. 
                ; Actually if I type "wiki" and select it, param is empty.
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
             ; Regex to parse: Cmd + Whitespace + Param
             ; matches "cmd   param" -> cmd="cmd", param="param"
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
    ; --- 2. Fallback: No Selection -> Default Web Search or Direct QSearch ---
    else {
        isQSearch := false
        if (CLSets.Has("QSearch")) {
             if RegexMatch(inputVal, "^\s*(\S+)\s+(.*)$", &m) {
                 cmd := m[1]
                 param := m[2]
             } else {
                 cmd := inputVal
                 param := ""
             }
             param := Trim(param)
             
             if (CLSets["QSearch"].Has(cmd)) {
                 item := CLSets["QSearch"][cmd]
                 url := item["setValue"]
                 finalUrl := StrReplace(url, "%s", param)
                 finalUrl := StrReplace(finalUrl, "{q}", param)
                 try Run(finalUrl)
                 isQSearch := true
             }
        }


        if (!isQSearch) {
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
    QGui.Hide()
}

listViewIconGet(path) {
    ; Placeholder for extracting icon index
    return 1
}


