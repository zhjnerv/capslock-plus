; lib_loadAnimation.ahk - V2 Refactor
; Simple loading animation on startup

global LoadingGui := ""
global LoadingText := ""
global charIndex := 1
global LoadingChar := ["010010", "101101", "001011", "111001", "000111", "110100", "011010", "100101", "SYSTEM", "READY_"]

showLoading() {
    global LoadingGui, LoadingText, LoadingChar, charIndex
    
    if (LoadingGui)
        try LoadingGui.Destroy()
        
    LoadingGui := Gui("-Caption +AlwaysOnTop +Owner", "CapsLock+ Loading")
    CLTheme_ApplyWindow(LoadingGui, LoadingGui.Hwnd, false)
    LoadingGui.SetFont(CLTheme_FontOptions(12, "accent"), CLTheme_Font("mono"))
    
    LoadingText := LoadingGui.Add("Text", "h24 w150 Center 0x200 Background" . CLTheme_Color("surface"), LoadingChar[1])
    
    LoadingGui.Show("Center NA")
    WinSetTransparent(235, LoadingGui)
    
    charIndex := 1
    SetTimer(changeLoadingChar, 250)
}

hideLoading() {
    SetTimer(changeLoadingChar, 0) ; Off
    if (LoadingGui)
        try LoadingGui.Destroy()
}

changeLoadingChar() {
    global charIndex, LoadingChar, LoadingText
    charIndex := Mod(charIndex, LoadingChar.Length) + 1
    if (LoadingText)
        LoadingText.Value := LoadingChar[charIndex]
}
