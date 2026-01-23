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
    global QGui, QGuiHwnd, QEdit, QLV, QLV_Hwnd, needInitQ

    if (needInitQ) {
        initQGui()
        needInitQ := 0
    }

    selText := getSelText()

    if (QGui && WinExist("ahk_id " . QGuiHwnd)) {
        if (selText != "")
            QEdit.Value := selText

        QGui.Show()
        QEdit.Focus()
        return
    }

    ; Re-show logic if hidden/destroyed?
    ; In V2, we usually keep Gui object.

    if (QGui) {
        if (selText != "")
            QEdit.Value := selText
        QGui.Show()
        QEdit.Focus()
    } else {
        initQGui() ; Recurse/Retry
    }
}

initQGui() {
    global QGui, QGuiHwnd, QEdit, QLV, QLV_Hwnd, CLSets, LVlistsType

    if (QGui)
        try QGui.Destroy()

    QGui := Gui("-Caption -Disabled +MinimizeBox +MaximizeBox -OwnDialogs +SysMenu +AlwaysOnTop +ToolWindow", "Qbar")
    QGuiHwnd := QGui.Hwnd

    QGui.BackColor := "333333" ; Dark theme default
    
    global GuiHwnd, LV_show_Hwnd, editHwnd ; Update shared globals
    GuiHwnd := QGuiHwnd

    QGui.SetFont("s12 cWhite", "Microsoft YaHei UI")

    ; Layout Parameters
    guiW := 400
    editH := 30
    listH := 200

    QEdit := QGui.Add("Edit", "x10 y10 w" . (guiW-20) . " h" . editH . " -Multi vInputStr BackgroundWhite cBlack")
    QEdit.OnEvent("Change", doWhenChanged)
    editHwnd := QEdit.Hwnd

    QLV := QGui.Add("ListView", "x10 y" . (10 + editH + 5) . " w" . (guiW-20) . " h" . listH . " +Count100 +NoSortHdr -Hdr -Multi Background333333 cWhite", ["Type", "FileName", "ForSort"])
    QLV_Hwnd := QLV.Hwnd
    LV_show_Hwnd := QLV_Hwnd

    ; Setup Columns
    QLV.ModifyCol(1, 0) ; Hide Type
    QLV.ModifyCol(2, guiW-30) ; Main
    QLV.ModifyCol(3, 0) ; Sort key

    initImageList()
    
    ; Populate List
    populateListView()
    
    ; Initial scan of Star Menu (can be slow, maybe do once)
    SetTimer(scanStarMenu, -100)
    
    ; Hotkeys for QBar navigation
    HotIfWinActive("ahk_id " . QGuiHwnd)
    Hotkey("Up", QBar_Up)
    Hotkey("Down", QBar_Down)
    Hotkey("Esc", QBar_Close)
    Hotkey("Enter", QBar_Enter)
    HotIf

    QGui.OnEvent("Close", QGuiClose)
    QGui.OnEvent("Close", QGuiClose)
    ; Initial size setting without showing
    QGui.Show("Hide w" . guiW . " h" . (editH + listH + 20))
    ; CapsLock+ logic says: init then show when called.
    ; But for now, let's just create it.

    ; Hide list initially if empty?
    ; QLV.Visible := false
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
                starMenuObj[name] := A_LoopFileFullPath
                ; For now, use generic icon or try to get one?
                ; Getting icons for all lnks is slow. 
                ; Let's just add to LV if we want it all here, or add only when searched?
                ; V1 added all to LV.
                 try QLV.Add("Icon1", "App", name, 0)
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
    if (searchText == "") {
        populateListView()
        return
    }
    
    ; Simple filtering
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
    for name, path in starMenuObj {
        if InStr(name, searchText)
            QLV.Add("Icon1", "App", name, 0)
    }
    
    ; Handle "Command Parameter" format
    ; If searchText contains space, check first word
    if InStr(searchText, " ") {
        parts := StrSplit(searchText, " ")
        cmd := parts[1]
        if (CLSets["QSearch"].Has(cmd)) {
             QLV.Insert(1, "Icon2", "Search", searchText, 0)
             QLV.Modify(1, "Focus Select")
        }
    } else {
        ; Select first item
        if (QLV.GetCount() > 0)
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
    global QGui, QLV, QEdit, CLSets

    row := QLV.GetNext(0, "F")
    if (row == 0)
        row := 1 ; Default to first if none focused

    key := QLV.GetText(row, 2)
    type := QLV.GetText(row, 1) ; Hidden col

    inputVal := QEdit.Value

    ; Execute Logic
    if (CLSets["QRun"].Has(key)) {
        item := CLSets["QRun"][key]
        path := item["setValue"]
        try Run(path)
    } else if (CLSets["QWeb"].Has(key)) {
        item := CLSets["QWeb"][key]
        url := item["setValue"]
        ; Replace %s ?
        finalUrl := StrReplace(url, "%s", inputVal) ; Simplistic
        try Run(finalUrl)
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