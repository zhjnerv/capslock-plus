; lib_mathBoard.ahk - V2 Refactor
; Math Board (Caps + F2)

global CalcGui := ""
global CalcEdit := ""
global CalcGuiHwnd := ""
global CalcHeader := ""

keyFunc_mathBoard() {
    global CalcGui, CalcEdit, CalcGuiHwnd

    ClipboardOld := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{c}")
    if ClipWait(0.1) {
        result := clCalculate(A_Clipboard, &res, 0, 1)
        if (res == "?")
            result := ""
    } else {
        result := ""
    }

    if (CalcGui && WinExist("ahk_id " . CalcGuiHwnd)) {
        CalcEdit.Value := result
        CalcGui.Show()
        SendInput("{End}")
    } else {
        createMathBoard(result)
    }

    Sleep(200)
    A_Clipboard := ClipboardOld
}

createMathBoard(initialValue) {
    global CalcGui, CalcEdit, CalcGuiHwnd, CalcHeader

    CalcGui := Gui("+AlwaysOnTop -Border +Caption +Resize +SysMenu -ToolWindow", "Math Board")
    CalcGuiHwnd := CalcGui.Hwnd

    CLTheme_ApplyWindow(CalcGui, CalcGuiHwnd)
    headerH := CLTheme_Dpi(22)
    CalcGui.SetFont(CLTheme_FontOptions(8, "muted"), CLTheme_Font("mono"))
    CalcHeader := CLTheme_AddRainHeader(CalcGui, 0, 0, 600, "MATH BOARD")

    CalcGui.SetFont(CLTheme_FontOptions(12, "accent"), CLTheme_Font("ui"))
    CalcEdit := CalcGui.Add("Edit", "x0 y" . headerH . " w600 h378 " . CLTheme_EditOptions("-Wrap"), initialValue)
    CLTheme_ApplyNativeControlTheme(CalcEdit)

    CalcGui.OnEvent("Size", mathBoard_Size)
    CalcGui.OnEvent("Close", (*) => CalcGui.Hide())
    CalcGui.OnEvent("Escape", (*) => CalcGui.Hide())

    CalcGui.Show("w600 h400")
    SendInput("{End}")

    ; Internal Hotkeys for MathBoard
    HotIfWinActive("ahk_id " . CalcGuiHwnd)

    ; 根据开关决定是否需要 CapsLock 门控（默认 V1 行为）
    _numpadRequireCaps := true
    if (CLSets.Has("Global") && CLSets["Global"].Has("mathBoardNumpadCapsLock") && CLSets["Global"]["mathBoardNumpadCapsLock"] == "0")
        _numpadRequireCaps := false

    ; 嵌套函数：每次按键由 HotIf 调用，捕获外层 _numpadRequireCaps
    _mathBoard_HotIf(*) {
        if (!_numpadRequireCaps)
            return true
        return GetKeyState("CapsLock", "T")
    }

    HotIf _mathBoard_HotIf

    ; Mapping logic (Simplified from V1)
    Hotkey("u", (*) => Send("7"))
    Hotkey("i", (*) => Send("8"))
    Hotkey("o", (*) => Send("9"))
    Hotkey("j", (*) => Send("4"))
    Hotkey("k", (*) => Send("5"))
    Hotkey("l", (*) => Send("6"))
    Hotkey("m", (*) => Send("1"))
    Hotkey(",", (*) => Send("2"))
    Hotkey(".", (*) => Send("3"))
    Hotkey("Space", (*) => Send("0"))
    Hotkey("RAlt", (*) => Send("{U+002e}"))
    Hotkey(";", (*) => Send("{U+002b}"))
    Hotkey("'", (*) => Send("{U+002d}"))
    Hotkey("p", (*) => Send("{U+002a}"))
    Hotkey("/", (*) => Send("{U+002f}"))
    Hotkey("[", (*) => Send("{U+002f}"))

    ; Shift 版本仅要求窗口激活（与 V1 一致，不受 CapsLock 状态影响）
    HotIfWinActive("ahk_id " . CalcGuiHwnd)

    ; Shift versions
    Hotkey("+u", (*) => Send("7"))
    Hotkey("+i", (*) => Send("8"))
    Hotkey("+o", (*) => Send("9"))
    Hotkey("+j", (*) => Send("4"))
    Hotkey("+k", (*) => Send("5"))
    Hotkey("+l", (*) => Send("6"))
    Hotkey("+m", (*) => Send("1"))
    Hotkey("+,", (*) => Send("2"))
    Hotkey("+.", (*) => Send("3"))
    Hotkey("+Space", (*) => Send("0"))
    Hotkey("+RAlt", (*) => Send("{U+002e}"))
    Hotkey("+;", (*) => Send("{U+002b}"))
    Hotkey("+'", (*) => Send("{U+002d}"))
    Hotkey("+p", (*) => Send("{U+002a}"))
    Hotkey("+/", (*) => Send("{U+002f}"))
    Hotkey("+[", (*) => Send("{U+002f}"))

    Hotkey("Enter", mathBoard_Enter)
    Hotkey("NumpadEnter", mathBoard_Enter)

    HotIf
}

mathBoard_Size(thisGui, minMax, width, height) {
    global CalcEdit, CalcHeader
    headerH := CLTheme_Dpi(22)
    if (CalcHeader)
        CalcHeader.Move(,, width, headerH)
    CalcEdit.Move(, headerH, width, Max(1, height - headerH))
}

mathBoard_Enter(*) {
    ClipboardOld := ClipboardAll()
    A_Clipboard := ""

    SendInput("+{Home}")
    Sleep(10)
    SendInput("^{c}")

    if ClipWait(0.1) {
        text := A_Clipboard
        ; Check if it's an assignment or simple calc
        if (RegExMatch(text, "(?<=:\=).*;$", &match)) {
            clCalculate(text, &res, 0, 1)
            SendInput("{End}{Enter}")
        } else if (RegExMatch(text, "(?<=\=)[\deE\+\-\.a-fA-f]+$", &match)) {
            SendInput("{End}{Enter}")
        } else {
            newText := clCalculate(text, &res, 0, 1)
            A_Clipboard := newText
            SendInput("^{v}")
            Sleep(200)
        }
    }

    A_Clipboard := ClipboardOld
}
