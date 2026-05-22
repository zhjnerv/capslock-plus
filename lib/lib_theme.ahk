; lib_theme.ahk - Matrix 风格主题
; 只集中管理视觉样式，不承载业务逻辑。

CLTheme_Color(name) {
    static colors := Map(
        "window", "000500",
        "surface", "020A03",
        "panel", "061206",
        "panelSoft", "071807",
        "field", "031005",
        "fieldHot", "08220D",
        "crtSurface", "031806",
        "crtRain", "78FF9C",
        "crtRainDim", "2FE66A",
        "crtTitle", "B7FF5A",
        "button", "0B5F2A",
        "buttonHover", "137A39",
        "text", "C8FFD2",
        "textStrong", "E8FFEE",
        "muted", "37A85D",
        "accent", "00FF66",
        "accentSoft", "57FF8F",
        "shadow", "001A08",
        "transparentKey", "010203"
    )

    return colors.Has(name) ? colors[name] : colors["text"]
}

CLTheme_Font(role := "ui") {
    if (role = "mono")
        return "Cascadia Mono"
    if (role = "qbar")
        return CLTheme_FirstAvailableFont(["Noto Sans SC", "DengXian", "Microsoft YaHei UI"])
    return CLTheme_Font("qbar")
}

CLTheme_FirstAvailableFont(fontNames) {
    for fontName in fontNames {
        if (CLTheme_FontInstalled(fontName))
            return fontName
    }
    return fontNames[fontNames.Length]
}

CLTheme_FontInstalled(fontName) {
    static fontRegistryNames := Map(
        "Noto Sans SC", ["Noto Sans SC (TrueType)", "Noto Sans CJK SC (TrueType)"],
        "DengXian", ["DengXian (TrueType)", "DengXian Light (TrueType)"],
        "Microsoft YaHei UI", ["Microsoft YaHei & Microsoft YaHei UI (TrueType)"]
    )

    if (!fontRegistryNames.Has(fontName))
        return true

    registryKeys := [
        "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",
        "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    ]

    for keyPath in registryKeys {
        for valueName in fontRegistryNames[fontName] {
            try {
                if (RegRead(keyPath, valueName) != "")
                    return true
            }
        }
    }

    return false
}

CLTheme_FontOptions(size := 11, colorName := "text", extra := "") {
    options := "s" . size . " c" . CLTheme_Color(colorName)
    if (extra != "")
        options .= " " . extra
    return options
}

CLTheme_Dpi(value) {
    try {
        return fixDpi(value)
    } catch {
        return value
    }
}

CLTheme_ApplyWindow(guiObj, hwnd := "", useModernStyle := true) {
    if (useModernStyle && hwnd != "") {
        try applyModernStyle(hwnd)
    }
    guiObj.BackColor := CLTheme_Color("window")
}

CLTheme_ApplyNativeControlTheme(ctrlOrHwnd) {
    hwnd := IsObject(ctrlOrHwnd) ? ctrlOrHwnd.Hwnd : ctrlOrHwnd
    if (!hwnd)
        return

    ; 使用系统暗色 Explorer 主题，让原生 Edit/ListView 滚动条避免露出白色轨道。
    result := DllCall("uxtheme\SetWindowTheme", "ptr", hwnd, "str", "DarkMode_Explorer", "ptr", 0, "int")
    if (result != 0)
        DllCall("uxtheme\SetWindowTheme", "ptr", hwnd, "str", "Explorer", "ptr", 0, "int")
    DllCall("RedrawWindow", "ptr", hwnd, "ptr", 0, "ptr", 0, "uint", 0x401)
}

global CLTheme_RainHeaders := []
global CLTheme_RainTick := 0

CLTheme_RainSegment(seed := 0, side := "left") {
    static cells := ["010010", "101101", "001011", "111001", "000111", "110100", "011010", "100101"]
    segment := ""

    Loop 3 {
        index := Mod(seed + A_Index + (side = "right" ? 3 : 0) - 1, cells.Length) + 1
        if (side = "right")
            segment .= (A_Index = 1 ? "" : "  ") . cells[index]
        else
            segment .= cells[index] . (A_Index = 3 ? "" : "  ")
    }

    return segment
}

class CLTheme_RainHeader {
    __New(bgCtrl, leftCtrl, titleCtrl, rightCtrl, label, x, y, w, h) {
        this.bgCtrl := bgCtrl
        this.leftCtrl := leftCtrl
        this.titleCtrl := titleCtrl
        this.rightCtrl := rightCtrl
        this.label := label
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.Layout()
    }

    Move(x?, y?, w?, h?) {
        if IsSet(x)
            this.x := x
        if IsSet(y)
            this.y := y
        if IsSet(w)
            this.w := w
        if IsSet(h)
            this.h := h
        this.Layout()
    }

    Layout() {
        titleW := Min(Max(CLTheme_Dpi(StrLen(this.label) * 8 + 36), CLTheme_Dpi(96)), Max(CLTheme_Dpi(90), this.w * 0.48))
        sideW := Max(1, (this.w - titleW) / 2)
        titleX := this.x + sideW
        rightX := titleX + titleW

        this.bgCtrl.Move(this.x, this.y, this.w, this.h)
        this.leftCtrl.Move(this.x, this.y, sideW, this.h)
        this.titleCtrl.Move(titleX, this.y, titleW, this.h)
        this.rightCtrl.Move(rightX, this.y, sideW, this.h)
    }

    Update(seed) {
        this.leftCtrl.Value := CLTheme_RainSegment(seed, "left")
        this.rightCtrl.Value := CLTheme_RainSegment(seed + 5, "right")

        ; 轻微错相闪烁，模拟老式 CRT 文字亮度波动，但标题保持稳定高亮。
        rainColor := CLTheme_Color(Mod(seed, 4) = 0 ? "crtRain" : "crtRainDim")
        this.leftCtrl.Opt("c" . rainColor)
        this.rightCtrl.Opt("c" . rainColor)
    }
}

CLTheme_AddRainHeader(guiObj, x, y, w, label := "CAPSLOCK+ MATRIX") {
    headerH := CLTheme_Dpi(20)
    bgColor := CLTheme_Color("crtSurface")

    bgCtrl := guiObj.Add("Text", "x" . x . " y" . y . " w" . w . " h" . headerH . " Background" . bgColor)

    guiObj.SetFont(CLTheme_FontOptions(8, "crtRainDim"), CLTheme_Font("mono"))
    leftCtrl := guiObj.Add("Text", "x" . x . " y" . y . " w1 h" . headerH . " Right 0x200 Background" . bgColor, CLTheme_RainSegment(0, "left"))
    rightCtrl := guiObj.Add("Text", "x" . x . " y" . y . " w1 h" . headerH . " Left 0x200 Background" . bgColor, CLTheme_RainSegment(5, "right"))

    guiObj.SetFont(CLTheme_FontOptions(8, "crtTitle"), CLTheme_Font("mono"))
    titleCtrl := guiObj.Add("Text", "x" . x . " y" . y . " w1 h" . headerH . " Center 0x200 Background" . bgColor, label)

    header := CLTheme_RainHeader(bgCtrl, leftCtrl, titleCtrl, rightCtrl, label, x, y, w, headerH)
    CLTheme_RegisterRainHeader(header)
    return header
}

CLTheme_RegisterRainHeader(header) {
    global CLTheme_RainHeaders
    CLTheme_RainHeaders.Push(header)
    SetTimer(CLTheme_UpdateRainHeaders, 180)
}

CLTheme_UpdateRainHeaders(*) {
    global CLTheme_RainHeaders, CLTheme_RainTick
    CLTheme_RainTick += 1

    index := CLTheme_RainHeaders.Length
    while (index >= 1) {
        header := CLTheme_RainHeaders[index]
        try {
            header.Update(CLTheme_RainTick + index)
        } catch {
            CLTheme_RainHeaders.RemoveAt(index)
        }
        index -= 1
    }

    if (CLTheme_RainHeaders.Length == 0)
        SetTimer(CLTheme_UpdateRainHeaders, 0)
}

CLTheme_AddPanel(guiObj, x, y, w, h, colorName := "panel") {
    return guiObj.Add(
        "Text",
        "x" . x . " y" . y . " w" . w . " h" . h . " Background" . CLTheme_Color(colorName)
    )
}

CLTheme_EditOptions(baseOptions := "") {
    return Trim(baseOptions . " -E0x200 c" . CLTheme_Color("text") . " Background" . CLTheme_Color("field"))
}

CLTheme_ListOptions(baseOptions := "") {
    return Trim(baseOptions . " Background" . CLTheme_Color("field") . " c" . CLTheme_Color("text"))
}

CLTheme_AddTextButton(guiObj, x, y, w, h, label, callback) {
    guiObj.SetFont(CLTheme_FontOptions(10, "textStrong", "w600"), CLTheme_Font("ui"))
    ctrl := guiObj.Add(
        "Text",
        "x" . x . " y" . y . " w" . w . " h" . h . " Center 0x200 Border Background" . CLTheme_Color("button"),
        label
    )
    ctrl.OnEvent("Click", callback)
    return ctrl
}

CLTheme_SelectableLabel(label, selected := false) {
    return (selected ? ">> " : "   ") . label
}

CLTheme_AddSelectableText(guiObj, x, y, w, h, label, selected, callback) {
    guiObj.SetFont(CLTheme_FontOptions(10, selected ? "accent" : "text"), CLTheme_Font("ui"))
    ctrl := guiObj.Add(
        "Text",
        "x" . x . " y" . y . " w" . w . " h" . h . " 0x200 Background" . CLTheme_Color(selected ? "fieldHot" : "panel"),
        CLTheme_SelectableLabel(label, selected)
    )
    ctrl.OnEvent("Click", callback)
    return ctrl
}

CLTheme_SetSelectableText(ctrl, label, selected) {
    ctrl.Value := CLTheme_SelectableLabel(label, selected)
    try ctrl.Opt("c" . CLTheme_Color(selected ? "accent" : "text") . " Background" . CLTheme_Color(selected ? "fieldHot" : "panel"))
}

global CLTheme_ToastGui := ""
global CLTheme_MessageGui := ""
global CLTheme_MessageDone := false
global CLTheme_InputGui := ""
global CLTheme_InputDone := false
global CLTheme_InputResult := "Cancel"
global CLTheme_InputValue := ""

CLTheme_ShowToast(message, duration := 2000) {
    global CLTheme_ToastGui

    if (CLTheme_ToastGui)
        try CLTheme_ToastGui.Destroy()

    margin := CLTheme_Dpi(10)
    w := CLTheme_Dpi(320)
    h := CLTheme_Dpi(70)
    x := A_ScreenWidth - w - CLTheme_Dpi(32)
    y := A_ScreenHeight - h - CLTheme_Dpi(78)

    CLTheme_ToastGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", "CapsLock+ Toast")
    CLTheme_ApplyWindow(CLTheme_ToastGui, CLTheme_ToastGui.Hwnd, false)
    CLTheme_AddRainHeader(CLTheme_ToastGui, margin, margin, w - 2*margin, "SIGNAL")
    CLTheme_ToastGui.SetFont(CLTheme_FontOptions(10, "textStrong"), CLTheme_Font("ui"))
    CLTheme_ToastGui.Add("Text", "x" . margin . " y" . (margin + CLTheme_Dpi(28)) . " w" . (w - 2*margin) . " h" . CLTheme_Dpi(28) . " Center 0x200 Background" . CLTheme_Color("panel"), message)
    CLTheme_ToastGui.Show("x" . x . " y" . y . " w" . w . " h" . h . " NA")
    WinSetTransparent(238, CLTheme_ToastGui)

    SetTimer(CLTheme_HideToast, -Abs(duration))
}

CLTheme_HideToast(*) {
    global CLTheme_ToastGui
    if (CLTheme_ToastGui) {
        try CLTheme_ToastGui.Destroy()
        CLTheme_ToastGui := ""
    }
}

CLTheme_ShowMessage(message, title := "CapsLock+", timeout := 0) {
    global CLTheme_MessageGui, CLTheme_MessageDone

    if (CLTheme_MessageGui)
        try CLTheme_MessageGui.Destroy()

    CLTheme_MessageDone := false
    margin := CLTheme_Dpi(14)
    w := CLTheme_Dpi(460)
    bodyH := CLTheme_Dpi(160)
    headerH := CLTheme_Dpi(20)
    gap := CLTheme_Dpi(8)
    buttonH := CLTheme_Dpi(30)
    h := margin*3 + headerH + gap + bodyH + buttonH

    CLTheme_MessageGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", title)
    hwnd := CLTheme_MessageGui.Hwnd
    CLTheme_ApplyWindow(CLTheme_MessageGui, hwnd)
    CLTheme_AddRainHeader(CLTheme_MessageGui, margin, margin, w - 2*margin, title)
    CLTheme_MessageGui.Add("Button", "x0 y0 w0 h0 Default Hidden", "OK").OnEvent("Click", CLTheme_CloseMessage)

    bodyY := margin + headerH + gap
    CLTheme_AddPanel(CLTheme_MessageGui, margin, bodyY, w - 2*margin, bodyH, "panel")
    CLTheme_MessageGui.SetFont(CLTheme_FontOptions(10, "text"), CLTheme_Font("ui"))
    messageEdit := CLTheme_MessageGui.Add("Edit", "x" . (margin+5) . " y" . (bodyY+5) . " w" . (w - 2*margin - 10) . " h" . (bodyH - 10) . " ReadOnly " . CLTheme_EditOptions("-WantReturn"), message)
    CLTheme_ApplyNativeControlTheme(messageEdit)

    btnY := bodyY + bodyH + margin
    CLTheme_AddTextButton(CLTheme_MessageGui, w - margin - CLTheme_Dpi(86), btnY, CLTheme_Dpi(86), buttonH, "确定", CLTheme_CloseMessage)
    CLTheme_MessageGui.OnEvent("Escape", CLTheme_CloseMessage)
    CLTheme_MessageGui.OnEvent("Close", CLTheme_CloseMessage)
    CLTheme_MessageGui.Show("Center w" . w . " h" . h)

    if (timeout > 0)
        SetTimer(CLTheme_CloseMessage, -Abs(timeout))

    while (!CLTheme_MessageDone && WinExist("ahk_id " . hwnd))
        Sleep(50)
}

CLTheme_CloseMessage(*) {
    global CLTheme_MessageGui, CLTheme_MessageDone
    CLTheme_MessageDone := true
    if (CLTheme_MessageGui) {
        try CLTheme_MessageGui.Destroy()
        CLTheme_MessageGui := ""
    }
}

CLTheme_InputBox(prompt := "", title := "Input", options := "", defaultValue := "") {
    global CLTheme_InputGui, CLTheme_InputDone, CLTheme_InputResult, CLTheme_InputValue

    if (CLTheme_InputGui)
        try CLTheme_InputGui.Destroy()

    w := CLTheme_Dpi(360)
    editH := CLTheme_Dpi(130)
    if RegExMatch(options, "i)w(\d+)", &wMatch)
        w := CLTheme_Dpi(Integer(wMatch[1]))
    if RegExMatch(options, "i)h(\d+)", &hMatch)
        editH := Max(CLTheme_Dpi(90), CLTheme_Dpi(Integer(hMatch[1]) - 70))

    CLTheme_InputDone := false
    CLTheme_InputResult := "Cancel"
    CLTheme_InputValue := defaultValue

    margin := CLTheme_Dpi(14)
    headerH := CLTheme_Dpi(20)
    gap := CLTheme_Dpi(8)
    buttonH := CLTheme_Dpi(30)
    promptH := (prompt != "" && prompt != defaultValue) ? CLTheme_Dpi(34) : 0
    bodyY := margin + headerH + gap + promptH
    h := margin*3 + headerH + gap + promptH + editH + buttonH

    CLTheme_InputGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", title)
    hwnd := CLTheme_InputGui.Hwnd
    CLTheme_ApplyWindow(CLTheme_InputGui, hwnd)
    CLTheme_AddRainHeader(CLTheme_InputGui, margin, margin, w - 2*margin, title)
    CLTheme_InputGui.Add("Button", "x0 y0 w0 h0 Default Hidden", "OK").OnEvent("Click", CLTheme_InputOK)

    if (promptH > 0) {
        CLTheme_InputGui.SetFont(CLTheme_FontOptions(9, "muted"), CLTheme_Font("ui"))
        CLTheme_InputGui.Add("Text", "x" . margin . " y" . (margin + headerH + gap) . " w" . (w - 2*margin) . " h" . promptH . " Background" . CLTheme_Color("window"), prompt)
    }

    CLTheme_AddPanel(CLTheme_InputGui, margin, bodyY, w - 2*margin, editH, "panel")
    CLTheme_InputGui.SetFont(CLTheme_FontOptions(10, "text"), CLTheme_Font("ui"))
    inputEdit := CLTheme_InputGui.Add("Edit", "x" . (margin+5) . " y" . (bodyY+5) . " w" . (w - 2*margin - 10) . " h" . (editH - 10) . " " . CLTheme_EditOptions("vMatrixInput -WantReturn"), defaultValue)
    CLTheme_ApplyNativeControlTheme(inputEdit)

    btnY := bodyY + editH + margin
    CLTheme_AddTextButton(CLTheme_InputGui, w - margin - CLTheme_Dpi(182), btnY, CLTheme_Dpi(86), buttonH, "确定", CLTheme_InputOK)
    CLTheme_AddTextButton(CLTheme_InputGui, w - margin - CLTheme_Dpi(86), btnY, CLTheme_Dpi(86), buttonH, "取消", CLTheme_InputCancel)
    CLTheme_InputGui.OnEvent("Escape", CLTheme_InputCancel)
    CLTheme_InputGui.OnEvent("Close", CLTheme_InputCancel)
    CLTheme_InputGui.Show("Center w" . w . " h" . h)

    while (!CLTheme_InputDone && WinExist("ahk_id " . hwnd))
        Sleep(50)

    return {Result: CLTheme_InputResult, Value: CLTheme_InputValue}
}

CLTheme_InputOK(*) {
    global CLTheme_InputGui, CLTheme_InputDone, CLTheme_InputResult, CLTheme_InputValue
    if (CLTheme_InputGui) {
        saved := CLTheme_InputGui.Submit(false)
        CLTheme_InputValue := saved.MatrixInput
        try CLTheme_InputGui.Destroy()
        CLTheme_InputGui := ""
    }
    CLTheme_InputResult := "OK"
    CLTheme_InputDone := true
}

CLTheme_InputCancel(*) {
    global CLTheme_InputGui, CLTheme_InputDone, CLTheme_InputResult
    CLTheme_InputResult := "Cancel"
    CLTheme_InputDone := true
    if (CLTheme_InputGui) {
        try CLTheme_InputGui.Destroy()
        CLTheme_InputGui := ""
    }
}
