; lib_winTransparent.ahk - V2 Refactor

global winTranSetting := false
global transpWinId := 0
global allowWinTranspToggle := false
global transp := 255

keyFunc_winTransparent() {
    global winTranSetting, allowWinTranspToggle, transpWinId, transp

    if (!winTranSetting) {
        winTranSetting := true
        allowWinTranspToggle := true

        transpWinId := WinExist("A")
        try {
            val := WinGetTransparent("ahk_id " . transpWinId)
            transp := (val == "") ? 255 : val
        } catch {
            transp := 255
        }

        SetTimer(winTranspKeyCheck, 50)
        SetTimer(checkIfTranspToggle, -300) ; Short press detection
    }
}

checkIfTranspToggle() {
    global allowWinTranspToggle
    allowWinTranspToggle := false
}

winTranspReduce() {
    global transp, transpWinId
    if (transp == 255 || transp == "")
        transp := 245
    else
        transp -= 10

    if (transp < 15)
        transp := 15

    try WinSetTransparent(transp, "ahk_id " . transpWinId)
}

winTranspAdd() {
    global transp, transpWinId
    if (transp == 255 || transp == "")
        return

    transp += 10
    if (transp >= 255) {
        transp := 255
        try WinSetTransparent("Off", "ahk_id " . transpWinId)
        try WinRedraw("ahk_id " . transpWinId)
    } else {
        try WinSetTransparent(transp, "ahk_id " . transpWinId)
    }
}

winTranspKeyCheck() {
    global winTranSetting, allowWinTranspToggle, transpWinId, transp, clState

    if (!GetKeyState("F4", "P") || !clState) {
        SetTimer(checkIfTranspToggle, 0)
        SetTimer(winTranspKeyCheck, 0)

        if (allowWinTranspToggle) {
            if (transp < 255) {
                try WinSetTransparent("Off", "ahk_id " . transpWinId)
                try WinRedraw("ahk_id " . transpWinId)
                transp := 255
            } else {
                transp := 170
                try WinSetTransparent(transp, "ahk_id " . transpWinId)
            }
        }
        winTranSetting := false
    }
}

; Hotkeys in context of winTranSetting
#HotIf winTranSetting
WheelUp::winTranspAdd()
WheelDown::winTranspReduce()
#HotIf