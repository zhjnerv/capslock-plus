; lib_mouseSpeed.ahk - V2 Refactor
; Regulates mouse speed (Caps + Alt + Wheel)

global mouseSpeed := 3
global OrigMouseSpeed := 10
global SPI_GETMOUSESPEED := 0x70
global SPI_SETMOUSESPEED := 0x71

mouseSpeedInit() {
    global mouseSpeed, CLSets

    if (CLSets.Has("Global") && CLSets["Global"].Has("mouseSpeed")) {
        val := CLSets["Global"]["mouseSpeed"]
        mouseSpeed := IsInteger(val) ? Integer(val) : 3
    }

    if (mouseSpeed < 1) {
        mouseSpeed := 1
        setSettings("Global", "mouseSpeed", mouseSpeed)
    } else if (mouseSpeed > 20) {
        mouseSpeed := 20
        setSettings("Global", "mouseSpeed", mouseSpeed)
    }
}

; Function to trigger speed change
; Typically called when Caps is down + certain key combos or logic
; V1 used a Timer. In V2 we can use the same or a logic check.

changeMouseSpeed() {
    global mouseSpeed, OrigMouseSpeed, clState

    if (GetKeyState("LAlt", "P")) {
        ; Save original
        DllCall("SystemParametersInfo", "UInt", 0x70, "UInt", 0, "UInt*", &OrigMouseSpeed, "UInt", 0)

        ; Set target
        DllCall("SystemParametersInfo", "UInt", 0x71, "UInt", 0, "Ptr", mouseSpeed, "UInt", 0)

        SetTimer(stopChangeMouseSpeed, 50)
        SetTimer(changeMouseSpeed, 0) ; Turn off self
    }

    if (!clState) {
        SetTimer(changeMouseSpeed, 0)
    }
}

stopChangeMouseSpeed() {
    global OrigMouseSpeed, clState

    if (!GetKeyState("LAlt", "P") || !clState) {
        SetTimer(stopChangeMouseSpeed, 0)
        ; Restore
        DllCall("SystemParametersInfo", "UInt", 0x71, "UInt", 0, "Ptr", OrigMouseSpeed, "UInt", 0)

        if (clState) {
            SetTimer(changeMouseSpeed, 50)
        }
    }
}