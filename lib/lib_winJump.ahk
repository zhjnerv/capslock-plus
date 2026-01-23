; lib_winJump.ahk - V2 Refactor

global winJumpSelected := 0
global winJumpIgnoreCount := 0
global minimizeWinArr := []

activateSideWin(UDLR) {
    global winJumpSelected, winJumpIgnoreCount
    sensitivity := Ceil(20/96 * A_ScreenDPI)
    deskTopExtra := 0
    winLastFoundId := 0

    CoordMode("Mouse", "Screen")

    if (!winJumpSelected) {
        winHwnd := WinExist("A")
    } else {
        winHwnd := winJumpSelected
    }

    try WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . winHwnd)
    catch {
        winX := 0, winY := 0, winW := A_ScreenWidth, winH := A_ScreenHeight
    }

    MouseGetPos(&mouX, &mouY)
    screenW := A_ScreenWidth
    screenH := A_ScreenHeight

    goY := winY + winH/2
    goX := winX + winW/2

    if (UDLR == "r")
        goX := winX + winW
    else if (UDLR == "l")
        goX := winX
    else if (UDLR == "u")
        goY := winY
    else if (UDLR == "d")
        goY := winY + winH
    else if (UDLR == "fl")
        goX := 0
    else if (UDLR == "fr")
        goX := screenW
    else if (UDLR == "c") {
        goXY := []
        w14 := winW/4
        h14 := winH/4
        goXY.Push({x: goX, y: goY})
        goXY.Push({x: goX - w14, y: goY - h14})
        goXY.Push({x: goX + w14, y: goY + h14})
        goXY.Push({x: goX - w14, y: goY + h14})
        goXY.Push({x: goX + w14, y: goY - h14})

        winJumpCover(winX + 10, winY, 0, 0)
        winLastFoundId := winHwnd
    }

    ; SystemCursor(0) ; Needs lib_functions.ahk

    Loop {
        if (UDLR == "r")
            goX += sensitivity + deskTopExtra
        else if (UDLR == "l")
            goX -= sensitivity + deskTopExtra
        else if (UDLR == "u")
            goY -= sensitivity + deskTopExtra
        else if (UDLR == "d")
            goY += sensitivity + deskTopExtra
        else if (UDLR == "fl")
            goX += (A_Index == 1 ? 0 : sensitivity + deskTopExtra)
        else if (UDLR == "fr")
            goX -= (A_Index == 1 ? 0 : sensitivity + deskTopExtra)
        else if (UDLR == "c") {
            if (A_Index <= goXY.Length) {
                goX := goXY[A_Index].x
                goY := goXY[A_Index].y
            } else {
                winJumpCover(winX, winY, winW, winH)
                break
            }
        }

        if (UDLR != "c" && (goX < 0 || goX > screenW || goY < 0 || goY > screenH))
            break

        MouseMove(goX, goY, 0)
        winNowId := WindowFromPoint(goX, goY)

        if (winNowId == winLastFoundId) {
            deskTopExtra += 10
            continue
        }

        title := WinGetTitle("ahk_id " . winNowId)
        if (title == "Program Manager" || title == "") {
            deskTopExtra += 10
            continue
        }

        try WinGetPos(&nx, &ny, &nw, &nh, "ahk_id " . winNowId)

        if (winJumpIgnoreCount > 0) {
            winLastFoundId := winNowId
            winJumpIgnoreCount--
            continue
        }

        winJumpCover(nx, ny, nw, nh)
        winJumpSelected := winNowId
        SetTimer(winJumpActivate, 50)
        break
    }

    MouseMove(mouX, mouY, 0)
    ; SystemCursor(1)
}

WindowFromPoint(x, y) {
    return DllCall("WindowFromPoint", "Int64", (x & 0xFFFFFFFF) | (y << 32), "Ptr")
}

winJumpActivate() {
    global winJumpSelected, clState, winJumpIgnoreCount
    if (!GetKeyState("LAlt", "P") || !clState) {
        destroyWinJumpCover()
        winJumpIgnoreCount := 0
        if (winJumpSelected) {
            try WinActivate("ahk_id " . winJumpSelected)
        }
        winJumpSelected := 0
        SetTimer(winJumpActivate, 0)
    }
}

global winCoverGui := ""
winJumpCover(x, y, w, h) {
    global winCoverGui
    if (!winCoverGui) {
        winCoverGui := Gui("-Caption -Disabled +ToolWindow +AlwaysOnTop", "winCover")
        winCoverGui.BackColor := "000000"
    }
    winCoverGui.Show("x" . x . " y" . y . " w" . w . " h" . h . " NA")
    WinSetTransparent(100, winCoverGui)
}

destroyWinJumpCover() {
    global winCoverGui
    if (winCoverGui)
        winCoverGui.Hide()
}

popWinMinimizeStack() {
    global minimizeWinArr
    if (minimizeWinArr.Length > 0) {
        id := minimizeWinArr.Pop()
        try WinActivate("ahk_id " . id)
    }
}

pushWinMinimizeStack() {
    global minimizeWinArr, winJumpSelected
    id := winJumpSelected ? winJumpSelected : WinExist("A")
    if (id) {
        try WinMinimize("ahk_id " . id)
        minimizeWinArr.Push(id)
    }
}