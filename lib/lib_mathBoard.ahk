; lib_mathBoard.ahk - V2 Refactor
; Math Board (Caps + F2)

global CalcGui := ""
global CalcEdit := ""
global CalcGuiHwnd := ""

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
    global CalcGui, CalcEdit, CalcGuiHwnd

    CalcGui := Gui("+AlwaysOnTop -Border +Caption +Resize +SysMenu -ToolWindow", "Math Board")
    CalcGuiHwnd := CalcGui.Hwnd

    CalcGui.SetFont("s12", "consolas")
    CalcEdit := CalcGui.Add("Edit", "x0 y0 w600 h400 -Wrap", initialValue)

    CalcGui.OnEvent("Size", mathBoard_Size)
    CalcGui.OnEvent("Close", (*) => CalcGui.Hide())
    CalcGui.OnEvent("Escape", (*) => CalcGui.Hide())

    CalcGui.Show("w600 h400")
    SendInput("{End}")

    ; Internal Hotkeys for MathBoard
    HotIfWinActive("ahk_id " . CalcGuiHwnd)

    ; If CapsLock is on (logic state), enable numpad-like mapping
    ; V1 used GetKeyState("CapsLock", "T")
    ; Here we can use our clState too

    ; Since we want this even if CapsLock is just logically used:

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
    global CalcEdit
    CalcEdit.Move(,, width, height)
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