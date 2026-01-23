; lib_loadAnimation.ahk - V2 Refactor
; Simple loading animation on startup

global LoadingGui := ""
global LoadingText := ""
global charIndex := 1
global LoadingChar := ["----------", "-=--------", "--=-------", "---=------", "----=-----", "-----=----", "------=---", "-------=--", "--------=-", "---------="]

showLoading() {
    global LoadingGui, LoadingText, LoadingChar, charIndex
    
    if (LoadingGui)
        try LoadingGui.Destroy()
        
    LoadingGui := Gui("-Caption +AlwaysOnTop +Owner", "CapsLock+ Loading")
    LoadingGui.BackColor := "FFFFFF"
    LoadingGui.SetFont("s12 c555555", "Consolas")
    
    LoadingText := LoadingGui.Add("Text", "h20 w100 Center", LoadingChar[1])
    
    LoadingGui.Show("Center NA")
    WinSetTransparent(230, LoadingGui)
    
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
