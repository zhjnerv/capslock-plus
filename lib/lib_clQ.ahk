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

; 窗口外圈 = 四周 1px 亮色描边(crtRain)。
; 描边整体内缩 1px,确保 SetWindowRgn 圆角裁剪后四边完整可见;内容再内缩 1px 露出描边底色。
QBar_FramePadding() {
    return fixDpi(1)
}

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
            margin := fixDpi(15) + QBar_FramePadding() * 2
            editH := fixDpi(50)
            headerH := fixDpi(20)
            headerGap := fixDpi(8)
            compactH := margin*2 + headerH + headerGap + editH
            guiH := compactH

            QGui.Show("h" . guiH) ; Removed Center
            QBar_SetRoundedRegion(guiH)
            QBar_RefreshFrame(guiH)
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

    ; 窗口四周各留出 1px 用于绘制亮色描边,描边本身再内缩 1px。
    ; 内容统一向右下偏移 2px,Show 高度已包含该内边距,无需额外叠加。
    margin += QBar_FramePadding() * 2

    inputY := margin + headerH + headerGap
    listGap := fixDpi(12)
    
    QGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", "Qbar")
    QGuiHwnd := QGui.Hwnd

    ; Qbar 需要纯黑 + 亮色边框,禁用 applyModernStyle 的 Mica/暗色标题栏,
    ; 否则 DWM 会在窗口外圈再包一层灰/白色系统边框。
    ; 圆角通过 WinSetRegion 手动实现,见 initQGui 末尾。
    CLTheme_ApplyWindow(QGui, QGuiHwnd, false)
    
    global GuiHwnd, LV_show_Hwnd, editHwnd
    GuiHwnd := QGuiHwnd

    qbarFontName := CLTheme_Font("qbar")
    
    CLTheme_AddRainHeader(QGui, margin, margin, guiW - 2*margin, "QBAR STREAM")

    ; 输入框外壳负责形成黑绿舱体，也作为可拖动背景区域的一部分。
    QGui.SetFont(CLTheme_FontOptions(16, "accent"), qbarFontName)
    QBgText := CLTheme_AddPanel(QGui, margin, inputY, guiW - 2*margin, editH, "panelSoft")
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
    QLV := QGui.Add("ListView", "x" . margin . " y" . (inputY + editH + listGap) . " w" . (guiW - 2*margin) . " h" . listH . " " . CLTheme_ListOptions("+Count100 +NoSortHdr -Hdr -Multi -Border"), ["Type", "FileName", "ForSort"])
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
    ; guiH 已包含 1px 描边内边距,直接 Show 即可。
    compactH := margin*2 + headerH + headerGap + editH
    guiH := compactH
    QGui.Show("Hide w" . guiW . " h" . guiH)
    QBar_SetRoundedRegion(guiH)
    QBar_RefreshFrame(guiH)
}

; 用 WinSetRegion 给 Qbar 切圆角,避免 DWM 圆角带来的系统灰边。
; radius 按 DPI 缩放,Win11 风格约 8px。
QBar_SetRoundedRegion(guiH) {
    global QGuiHwnd, guiW
    if (!QGuiHwnd)
        return

    radius := fixDpi(8)
    ; CreateRoundRectRgn(x1,y1,x2,y2,w,h) -> HRGN
    hRgn := DllCall("gdi32\CreateRoundRectRgn", "int", 0, "int", 0, "int", guiW, "int", guiH, "int", radius, "int", radius, "ptr")
    if (hRgn) {
        DllCall("user32\SetWindowRgn", "ptr", QGuiHwnd, "ptr", hRgn, "int", 1)
        ; SetWindowRgn 接管 hRgn 所有权,不再 DeleteObject
    }
}

; 生成四分之一圆角的离散像素点。
; 这里用外轮廓点而不是整块填充,避免四角出现明显的绿色方块。
QBar_FrameCornerPoints(radius) {
    points := []
    pointMap := Map()
    cornerRadius := Max(radius - 1, 1)

    ; 同时按 x / y 两个方向取样,补齐离散化后的缺口,让圆角弧线更连续。
    Loop cornerRadius + 1 {
        offset := A_Index - 1
        key := ""

        y := Round(cornerRadius - Sqrt(Max(0, cornerRadius * cornerRadius - (offset - cornerRadius) * (offset - cornerRadius))))
        key := offset . "," . y
        if (!pointMap.Has(key)) {
            pointMap[key] := true
            points.Push([offset, y])
        }

        x := Round(cornerRadius - Sqrt(Max(0, cornerRadius * cornerRadius - (offset - cornerRadius) * (offset - cornerRadius))))
        key := x . "," . offset
        if (!pointMap.Has(key)) {
            pointMap[key] := true
            points.Push([x, offset])
        }
    }

    return points
}

; 在 QGui 内部四周绘制 1px 亮色边框(crtRain, #94F98F)。
; 横线内缩 radius,竖线通长,四角用离散圆弧点连接,避免出现实心角块。
QBar_RefreshFrame(guiH) {
    global QGui, guiW
    static frameCtrls := []

    if (!QGui)
        return

    for ctrl in frameCtrls {
        try ctrl.Destroy()
    }
    frameCtrls := []

    ; 使用最亮的 rain-bright 作为外框,确保在黑色桌面背景上可辨识。
    frameColor := CLTheme_Color("crtRain")
    borderPad := fixDpi(1)
    radius := fixDpi(8)
    cornerPoints := QBar_FrameCornerPoints(radius)
    verticalInset := 0

    ; 竖线不能从最顶/最底开始画,要从圆角弧“最后一行仍贴着侧边”的位置开始接直线。
    ; 取最小 offsetY 会让直线接得太早,左右两边都会在圆角附近略微出头。
    for point in cornerPoints {
        offsetX := point[1]
        offsetY := point[2]
        if (offsetX = 0 && offsetY > verticalInset)
            verticalInset := offsetY
    }
    if (verticalInset <= 0)
        verticalInset := radius - 1

    ; 横线:两端各内缩 radius,避开圆角弧。
    ; 上边框在 y=borderPad, 下边框对称落在 guiH-2*borderPad。
    frameCtrls.Push(QGui.Add("Text", "x" . radius . " y" . borderPad . " w" . (guiW - 2*radius) . " h" . borderPad . " Background" . frameColor))
    frameCtrls.Push(QGui.Add("Text", "x" . radius . " y" . (guiH - 2*borderPad) . " w" . (guiW - 2*radius) . " h" . borderPad . " Background" . frameColor))

    ; 竖线:按圆角弧的切点裁短,避免上下超出圆角。
    frameCtrls.Push(QGui.Add("Text", "x" . borderPad . " y" . (borderPad + verticalInset) . " w" . borderPad . " h" . (guiH - 2*(borderPad + verticalInset)) . " Background" . frameColor))
    frameCtrls.Push(QGui.Add("Text", "x" . (guiW - 2*borderPad) . " y" . (borderPad + verticalInset) . " w" . borderPad . " h" . (guiH - 2*(borderPad + verticalInset)) . " Background" . frameColor))

    ; 四角圆弧:按半径生成 1px 点阵,分别镜像到四个角。
    for point in cornerPoints {
        offsetX := point[1]
        offsetY := point[2]

        frameCtrls.Push(QGui.Add("Text", "x" . (borderPad + offsetX) . " y" . (borderPad + offsetY) . " w1 h1 Background" . frameColor))
        frameCtrls.Push(QGui.Add("Text", "x" . ((guiW - 2*borderPad) - offsetX) . " y" . (borderPad + offsetY) . " w1 h1 Background" . frameColor))
        frameCtrls.Push(QGui.Add("Text", "x" . (borderPad + offsetX) . " y" . ((guiH - 2*borderPad) - offsetY) . " w1 h1 Background" . frameColor))
        frameCtrls.Push(QGui.Add("Text", "x" . ((guiW - 2*borderPad) - offsetX) . " y" . ((guiH - 2*borderPad) - offsetY) . " w1 h1 Background" . frameColor))
    }
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
    ; 原生 ListView 无法按行改色,改用更显眼的前缀字符让选中行从暗色背景里跳出来。
    ; ▶ 的辨识度比 >> 高,且与 MATRIX-DESIGN 的"光标"语义一致。
    return (selected ? "▶ " : "   ") . key
}

QBar_IsActive() {
    global QGuiHwnd
    return (QGuiHwnd && WinActive("ahk_id " . QGuiHwnd))
}

QBar_GetEditSelection() {
    global QEdit
    fallbackPos := (QEdit ? StrLen(QEdit.Value) : 0)

    if (!QEdit)
        return {start: fallbackPos, finish: fallbackPos}

    try {
        startBuf := Buffer(4, 0)
        finishBuf := Buffer(4, 0)
        SendMessage(0xB0, startBuf.Ptr, finishBuf.Ptr, QEdit.Hwnd) ; EM_GETSEL
        return {start: NumGet(startBuf, 0, "UInt"), finish: NumGet(finishBuf, 0, "UInt")}
    } catch {
        return {start: fallbackPos, finish: fallbackPos}
    }
}

QBar_SetEditSelection(sel) {
    global QEdit
    if (!QEdit)
        return

    textLen := StrLen(QEdit.Value)
    startPos := Max(0, Min(sel.start, textLen))
    finishPos := Max(0, Min(sel.finish, textLen))

    try SendMessage(0xB1, startPos, finishPos, QEdit.Hwnd) ; EM_SETSEL
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

    ; 防御性剥离:除了选中前缀,还要兼容历史版本中误传入 Modify 的 "Vis" 残留。
    text := QLV.GetText(row, 2)
    if (text == "Vis")
        return ""
    return RegExReplace(text, "^(▶|>>| {3})\s*", "")
}

QBar_SetSelected(row) {
    global QLV, QEdit, QSelectedRow

    itemCount := QLV.GetCount()
    if (itemCount == 0) {
        QSelectedRow := 0
        return
    }

    row := Max(1, Min(row, itemCount))
    editSelection := QBar_GetEditSelection()

    ; 原生 ListView 在暗色主题下选中态不稳定，额外用文本前缀给出确定标识。
    if (QSelectedRow >= 1 && QSelectedRow <= itemCount && QSelectedRow != row) {
        oldKey := QBar_RowKey(QSelectedRow)
        if (oldKey != "")
            QLV.Modify(QSelectedRow, "Col2", QBar_ResultLabel(oldKey))
    }

    key := QBar_RowKey(row)
    if (key != "")
        QLV.Modify(row, "Col2", QBar_ResultLabel(key, true))

    QLV.Modify(row, "Select", "Focus")
    QSelectedRow := row
    try QEdit.Focus()
    ; Focus() 会让原生单行 Edit 重新选中全文；恢复输入位置，避免继续输入参数时覆盖命令。
    QBar_SetEditSelection(editSelection)
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

    ; 补充 Microsoft Store / UWP 应用：它们通常不在传统开始菜单 .lnk 目录里，
    ; 只能从 shell:AppsFolder 拿到 AppUserModelID，再用 shell:AppsFolder\ID 启动。
    scanAppsFolder()
}

; 扫描 shell:AppsFolder，补齐商店应用（如 ChatGPT）及部分系统工具。
; 已在开始菜单 .lnk 中出现的同名项优先保留（图标通常更好）。
scanAppsFolder() {
    global starMenuObj

    try {
        shellApp := ComObject("Shell.Application")
        appsFolder := shellApp.NameSpace("shell:AppsFolder")
        if (!appsFolder)
            return

        for item in appsFolder.Items {
            try {
                name := item.Name
            } catch {
                continue
            }
            if (name = "" || starMenuObj.Has(name))
                continue
            if (RegExMatch(name, "i)卸载|uninstall"))
                continue

            try {
                appId := item.Path
            } catch {
                continue
            }
            if (appId = "")
                continue

            ; AppUserModelID 难以稳定抽图标，复用 ImageList 通用图标（index 1）。
            starMenuObj[name] := {path: "shell:AppsFolder\" . appId, icon: 1}
        }
    } catch {
        ; COM / 权限异常时静默跳过，不影响已有 .lnk 索引
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

    ; 内容区尺寸:注意 margin 已叠加 QBar_FramePadding()*2,与 initQGui 保持一致。
    margin := fixDpi(15) + QBar_FramePadding() * 2
    editH := fixDpi(50)
    headerH := fixDpi(20)
    headerGap := fixDpi(8)
    listGap := fixDpi(12)
    maxListH := fixDpi(350)
    guiW := fixDpi(650)
    compactH := margin*2 + headerH + headerGap + editH
    compactGuiH := compactH

    if (searchText == "") {
        ; Search cleared -> Switch to Compact Mode
        QLV.Visible := false
        QSelectedRow := 0
        QLV.Delete()
        QGui.Show("h" . compactGuiH . " NoActivate")
        QBar_SetRoundedRegion(compactGuiH)
        QBar_RefreshFrame(compactGuiH)
        return
    }
    
    ; Perform Search / Filtering
    QLV.Opt("-Redraw")
    QSelectedRow := 0
    QLV.Delete()

    ; 键名完全等于输入时，优先显示，避免较早配置的包含匹配抢占首项。
    if (CLSets.Has("QRun")) {
        for key, val in CLSets["QRun"] {
            if (key = searchText)
                QBar_AddResult("Icon1", "Run", key)
        }
    }

    if (CLSets.Has("QSearch")) {
        for key, val in CLSets["QSearch"] {
            if (key = searchText)
                QBar_AddResult("Icon2", "Search", key)
        }
    }

    for name, itemObj in starMenuObj {
        if (name = searchText) {
            iconOption := "Icon" . itemObj.icon
            QBar_AddResult(iconOption, "App", name)
        }
    }
    
    ; Filter QRun
    if (CLSets.Has("QRun")) {
        for key, val in CLSets["QRun"] {
            if (key != searchText && InStr(key, searchText))
                QBar_AddResult("Icon1", "Run", key)
        }
    }
    
    ; Filter QSearch
    if (CLSets.Has("QSearch")) {
        for key, val in CLSets["QSearch"] {
             if (key != searchText && InStr(key, searchText))
                QBar_AddResult("Icon2", "Search", key)
        }
    }
    
    ; Filter StarMenu
    for name, itemObj in starMenuObj {
        if (name != searchText && InStr(name, searchText)) {
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
        QGui.Show("h" . compactGuiH . " NoActivate")
        QBar_SetRoundedRegion(compactGuiH)
        QBar_RefreshFrame(compactGuiH)
    } else {
        ; Matches found -> Calculate dynamic height
        ; Row height estimation: s11 font + small icon ~ 28px
        rowH := fixDpi(28)
        reqH := itemCount * rowH + fixDpi(8) ; slight buffer

        finalListH := Min(reqH, maxListH)

        QLV.Move(,, guiW - 2*margin, finalListH)
        QLV.Visible := true

        ; Resize Window
        fullContentH := margin + headerH + headerGap + editH + listGap + finalListH + margin
        fullGuiH := fullContentH
        QGui.Show("h" . fullGuiH . " NoActivate")
        QBar_SetRoundedRegion(fullGuiH)
        QBar_RefreshFrame(fullGuiH)

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
