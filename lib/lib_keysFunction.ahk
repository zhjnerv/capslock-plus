; keys functions start-------------
; 所有按键对应功能都放在这，为防止从set.ini通过按键设置调用到非按键功能函数，
; 规定函数以"keyFunc_"开头

keyFunc_doNothing(){
    return
}

keyFunc_test(){
    MsgBox("testing", , "T1")
    return
}

keyFunc_send(p){
    SendInput(p)
    return
}

keyFunc_run(p){
    Run(p)
    return
}

keyFunc_toggleCapsLock(){
    SetCapsLockState(GetKeyState("CapsLock","T") ? "Off" : "On")
    return
}

keyFunc_mouseSpeedIncrease(){
    global mouseSpeed
    mouseSpeed += 1
    if(mouseSpeed > 20)
    {
        mouseSpeed := 20
    }
    showMsg("mouse speed: " . mouseSpeed, 1000)
    setSettings("Global", "mouseSpeed", mouseSpeed)
    return
}

keyFunc_mouseSpeedDecrease(){
    global mouseSpeed
    mouseSpeed -= 1
    if(mouseSpeed < 1)
    {
        mouseSpeed := 1
    }
    showMsg("mouse speed: " . mouseSpeed, 1000)
    setSettings("Global", "mouseSpeed", mouseSpeed)
    return
}

keyFunc_moveLeft(i:=1){
    SendInput("{left " . i . "}")
    return
}

keyFunc_moveRight(i:=1){
    SendEvent("{Right " . i . "}")
    Return
}

keyFunc_moveUp(i:=1){
    global GuiHwnd, LV_show_Hwnd, editHwnd
    if(IsSet(GuiHwnd) && WinActive("ahk_id" . GuiHwnd))
    {
        try ControlFocus(LV_show_Hwnd)
        SendEvent("{Up " . i . "}")
        Sleep(5)
        try ControlFocus(editHwnd)
    }
    else
        SendEvent("{up " . i . "}")
    Return
}

keyFunc_moveDown(i:=1){
    global GuiHwnd, LV_show_Hwnd, editHwnd
    if(IsSet(GuiHwnd) && WinActive("ahk_id" . GuiHwnd))
    {
        try ControlFocus(LV_show_Hwnd)
        SendEvent("{Down " . i . "}")
        Sleep(5)
        try ControlFocus(editHwnd)
    }
    else
        SendEvent("{down " . i . "}")
    Return
}


keyFunc_moveWordLeft(i:=1){
    SendInput("^{Left " . i . "}")
    Return
}

keyFunc_moveWordRight(i:=1){
    SendInput("^{Right " . i . "}")
    Return
}

keyFunc_backspace(){
    SendInput("{backspace}")
    Return
}

keyFunc_delete(){
    SendInput("{delete}")
    Return
}

keyFunc_deleteAll(){
    SendInput("^{a}{delete}")
    Return
}

keyFunc_deleteWord(){
    SendInput("+^{left}")
    SendInput("{delete}")
    Return
}

keyFunc_forwardDeleteWord(){
    SendInput("+^{right}")
    SendInput("{delete}")
    Return
}

keyFunc_translate(){
    global
    selText := getSelText()
    if(selText)
    {
        ydTranslate(selText)
    }
    else
    {
        ClipboardOld := ClipboardAll()
        A_Clipboard := ""
        SendInput("^{Left}^+{Right}^{insert}")
        if ClipWait(0.05)
        {
            selText := A_Clipboard
            ydTranslate(selText)
        }
        A_Clipboard := ClipboardOld
    }
    SetTimer(setTransGuiActive, -400)
    Return
}

setTransGuiActive() {
    global GuiHwnd
    if (IsSet(GuiHwnd) && WinExist("ahk_id " . GuiHwnd))
    {
        WinActivate("ahk_id " . GuiHwnd)
    }
}

keyFunc_end(){
    SendInput("{End}")
    Return
}

keyFunc_home(){
    SendInput("{Home}")
    Return
}

keyFunc_moveToPageBeginning(){
    SendInput("^{Home}")
    Return
}

keyFunc_moveToPageEnd(){
    SendInput("^{End}")
    Return
}

keyFunc_deleteLine(){
    SendInput("{End}+{home}{bs}")
    Return
}

keyFunc_deleteToLineBeginning(){
    SendInput("+{Home}{bs}")
    Return
}

keyFunc_deleteToLineEnd(){
    SendInput("+{End}{bs}")
    Return
}

keyFunc_deleteToPageBeginning(){
    SendInput("+^{Home}{bs}")
    Return
}

keyFunc_deleteToPageEnd(){
    SendInput("+^{End}{bs}")
    Return
}

keyFunc_enterWherever(){
    SendInput("{End}{Enter}")
    Return
}

keyFunc_esc(){
    SendInput("{Esc}")
    Return
}

keyFunc_enter(){
    SendInput("{Enter}")
    Return
}

;双字符
keyFunc_doubleChar(char1, char2:=""){
    global
    if(char2 == "")
    {
        char2 := char1
    }
    charLen := StrLen(char2)
    selText := getSelText()
    ClipboardOld := ClipboardAll()
    if(selText)
    {
        A_Clipboard := char1 . selText . char2
        SendInput("+{insert}")
    }
    else
    {
        A_Clipboard := char1 . char2
        SendInput("+{insert}")
        ; prevent the left input from interrupting the paste (may occur in vscode)
        ; fact: tests show that 50ms is not enough
        Sleep(75)
        SendInput("{left " . charLen . "}")
    }
    Sleep(100)
    A_Clipboard := ClipboardOld
    Return
}

keyFunc_sendChar(char){
    ClipboardOld := ClipboardAll()
    A_Clipboard := char
    SendInput("+{insert}")
    Sleep(50)
    A_Clipboard := ClipboardOld
    return
}

keyFunc_doubleAngle(){
    if(!keyFunc_qbar_lowerFolderPath())
        keyFunc_doubleChar("<",">")
    return
}

keyFunc_pageUp(){
    global GuiHwnd, LV_show_Hwnd, editHwnd
    if(IsSet(GuiHwnd) && WinActive("ahk_id" . GuiHwnd))
    {
        try ControlFocus(LV_show_Hwnd)
        SendInput("{PgUp}")
        try ControlFocus(editHwnd)
    }
    else
        SendInput("{PgUp}")
    return
}

keyFunc_pageDown(){
    global GuiHwnd, LV_show_Hwnd, editHwnd
    if(IsSet(GuiHwnd) && WinActive("ahk_id" . GuiHwnd))
    {
        try ControlFocus(LV_show_Hwnd)
        SendInput("{PgDn}")
        try ControlFocus(editHwnd)
    }
    else
        SendInput("{PgDn}")
    Return
}

;页面向上移动一页，光标不动
keyFunc_pageMoveUp(){
    SendInput("^{PgUp}")
    return
}

;页面向下移动一页，光标不动
keyFunc_pageMoveDown(){
    SendInput("^{PgDn}")
    return
}

keyFunc_switchClipboard(){
    global CLSets, allowRunOnClipboardChange
    if(CLSets["Global"]["allowClipboard"])
    {
        CLSets["Global"]["allowClipboard"] := "0"
        setSettings("Global","allowClipboard","0")
        showMsg("Clipboard OFF",1500)
    }
    else
    {
        CLSets["Global"]["allowClipboard"] := "1"
        setSettings("Global","allowClipboard","1")
        showMsg("Clipboard ON",1500)
    }
    return
}

keyFunc_pasteSystem(){
    global sClipboardAll, whichClipboardNow, allowRunOnClipboardChange

    ; ;
    ; 禁止 OnClipboardChange 运行，防止 Clipboard:=sClipboardAll 重复执行，导致偶尔会粘贴出空白
    ;  if(!CLsets.global.allowClipboard)  ;禁用剪贴板功能
    ;  {
    ;      CapsLock2:=""
    ;      return
    ;  }
    if (whichClipboardNow != 0)
    {
        allowRunOnClipboardChange := false
        A_Clipboard := sClipboardAll
        whichClipboardNow := 0
    }
    SendInput("^{v}")
    return
}

keyFunc_cut_1(){
    global
    if(CLsets["Global"]["allowClipboard"] == "0")  ;禁用剪贴板功能
    {
        ; CapsLock2:="" ; Undefined global in V1 too?
        return
    }

    ClipboardOld := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{x}")
    if ClipWait(0.1)
    {
        ; Success
    }
    else
    {
        SendInput("{home}+{End}^{x}")
        ClipWait(0.1)
    }

    if (A_Clipboard != "")
    {
        ;cClipboardAll:=ClipboardAll
        clipSaver("c")
        whichClipboardNow := 1
    }
    else
    {
        A_Clipboard := ClipboardOld
    }
    Return
}

keyFunc_copy_1(){
    global
    if(CLsets["Global"]["allowClipboard"] == "0")  ;禁用剪贴板功能
    {
        return
    }

    ClipboardOld := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{insert}")
    if ClipWait(0.1)
    {
    }
    else
    {
        SendInput("{home}+{End}^{insert}{End}")
        ClipWait(0.1)
    }

    if (A_Clipboard != "")
    {
        ;  cClipboardAll:=ClipboardAll
        clipSaver("c")
        whichClipboardNow := 1
    }
    else
    {
        A_Clipboard := ClipboardOld
    }
    return
}

keyFunc_paste_1(){
    global
    if(CLsets["Global"]["allowClipboard"] == "0")  ;禁用剪贴板功能
    {
        return
    }

    if (whichClipboardNow != 1)
    {
        A_Clipboard := cClipboardAll
        whichClipboardNow := 1
    }
    SendInput("^{v}")
    Return
}

keyFunc_undoRedo(){
    global ctrlZ
    if(ctrlZ)
    {
        SendInput("^{z}")
        ctrlZ := ""
    }
    Else
    {
        SendInput("^{y}")
        ctrlZ := 1
    }
    Return
}

keyFunc_cut_2(){
    global
    if(CLsets["Global"]["allowClipboard"] == "0")  ;禁用剪贴板功能
    {
        return
    }

    ClipboardOld := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{x}")
    if ClipWait(0.1)
    {
        ;
    }
    else
    {
        SendInput("{home}+{End}^{x}")
        ClipWait(0.1)
    }

    if (A_Clipboard != "")
    {
        ;  caClipboardAll:=ClipboardAll
        clipSaver("ca")
        whichClipboardNow := 2
    }
    else
    {
        A_Clipboard := ClipboardOld
    }
    Return
}

keyFunc_copy_2(){
    global
    if(CLsets["Global"]["allowClipboard"] == "0")  ;禁用剪贴板功能
    {
        return
    }

    ClipboardOld := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{insert}")
    if ClipWait(0.1)
    {
    }
    else
    {
        SendInput("{home}+{End}^{insert}{End}")
        ClipWait(0.1)
    }

    if (A_Clipboard != "")
    {
        ;  caClipboardAll:=ClipboardAll
        clipSaver("ca")
        whichClipboardNow := 2
    }
    else
    {
        A_Clipboard := ClipboardOld
    }
    return
}

keyFunc_paste_2(){
    global
    if(CLsets["Global"]["allowClipboard"] == "0")  ;禁用剪贴板功能
    {
        return
    }

    if (whichClipboardNow != 2)
    {
        A_Clipboard := caClipboardAll
        whichClipboardNow := 2
    }
    SendInput("^{v}")
    Return
}

keyFunc_qbar(){
    global CLStats
    SetTimer(setCLqActive, 50)
    ;先关闭所有Caps热键，然后再打开
    ;防止其他功能在 qbar 出来这段时间因为输入文字而被触发
    ; CapsLock:=CapsLock2:="" ; Global vars undefined, need to check CapsLock logic
    CLq()
    return
}

setCLqActive() {
    global GuiHwnd
    if (IsSet(GuiHwnd) && WinExist("ahk_id " . GuiHwnd))
    {
        SetTimer(setCLqActive, 0)
        WinActivate("ahk_id " . GuiHwnd)
    }
}

keyFunc_tabPrve(){
    SendInput("^+{tab}")
    return
}

keyFunc_tabNext(){
    SendInput("^{tab}")
    return
}

keyFunc_jumpPageTop(){
    SendInput("^{Home}")
    return
}

keyFunc_jumpPageBottom(){
    SendInput("^{End}")
    return
}

keyFunc_selectUp(i:=1){
    SendInput("+{Up " . i . "}")
    return
}

keyFunc_selectDown(i:=1){
    SendInput("+{Down " . i . "}")
    return
}

keyFunc_selectLeft(i:=1){
    SendInput("+{Left " . i . "}")
    return
}

keyFunc_selectRight(i:=1){
    SendInput("+{Right " . i . "}")
    return
}

keyFunc_selectHome(){
    SendInput("+{Home}")
    return
}

keyFunc_selectEnd(){
    SendInput("+{End}")
    return
}

keyFunc_selectToPageBeginning(){
    SendInput("+^{Home}")
    return
}

keyFunc_selectToPageEnd(){
    SendInput("+^{End}")
    return
}

keyFunc_selectCurrentWord(){
    SendInput("^{Left}")
    SendInput("+^{Right}")
    return
}

keyFunc_selectCurrentLine(){
    SendInput("{Home}")
    SendInput("+{End}")
    return
}

keyFunc_selectWordLeft(i:=1){
    SendInput("+^{Left " . i . "}")
    return
}

keyFunc_selectWordRight(i:=1){
    SendInput("+^{Right " . i . "}")
    return
}

;页面移动一行，光标不动
keyFunc_pageMoveLineUp(i:=1){
    SendInput("^{Up " . i . "}")
    return
}

keyFunc_pageMoveLineDown(i:=1){
    SendInput("^{Down " . i . "}")
    return
}

keyFunc_getJSEvalString(){
    global lang_kf_getDebugText
    ClipboardOld := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{insert}") ;
    if ClipWait(0.1)
    {
        ; result := escapeString(A_Clipboard) ; escapeString not defined?
        result := A_Clipboard
        ib := InputBox(result, "Debug Text", "w300 h150", result)
        if(ib.Result == "OK")
        {
            A_Clipboard := ib.Value
            return
        }
    }
    Sleep(200)
    A_Clipboard := ClipboardOld
    return
}

keyFunc_tabScript(){
    try tabAction()
    Return
}

keyFunc_openCpasDocs(){
    if(isLangChinese())
    {
        Run("https://capslox.com/capslock-plus")
    } else {
        Run("https://capslox.com/capslock-plus/en.html")
    }
    return
}

keyFunc_mediaPrev(){
    SendInput("{Media_Prev}")
    return
}

keyFunc_mediaNext(){
    SendInput("{Media_Next}")
    return
}

keyFunc_mediaPlayPause(){
    SendInput("{Media_Play_Pause}")
    return
}

keyFunc_volumeUp(){
    SendInput("{Volume_Up}")
    return
}

keyFunc_volumeDown(){
    SendInput("{Volume_Down}")
    return
}

keyFunc_volumeMute(){
    SendInput("{Volume_Mute}")
    return
}

keyFunc_reload(){
    MsgBox("Reloading...", "Reload", "T0.5")
    Reload
    return
}

keyFunc_send_dot(){
    if(!keyFunc_qbar_lowerFolderPath())
        SendInput("{U+002e}")
    return
}

;qbar中跳到上层文件路径
keyFunc_qbar_upperFolderPath(){
    global GuiHwnd, LVlistsType, editHwnd, qbarPathFuture
    if(!IsSet(GuiHwnd) || !WinActive("ahk_id" . GuiHwnd))
    {
        return
    }
    if(LVlistsType == 0)
    {

        return true
    }
    editText := ControlGetText(editHwnd)
    ;  if(historyIndex>1)
    ;      historyIndex--

    ;  _t:=qbarPathHistory[historyIndex+1]
    ;  if(_t=editText)
    ;  {
    ;      editText:=qbarPathHistory[historyIndex]
    ;  }
    ;  else
    ;      editText:=_t
    ; qbarPathFuture.insert(editText)    ;记录路径历史

    ; editText := RegExReplace(editText,"i)([^\\]*\\|[^\\]*)$") ; Double quote escaping check
    editText := RegExReplace(editText, 'i)([^\\]*\\|[^\\]*)$')

    ;  ifInsertHistory:=0  ;禁止记录地址
    ; ifClearFuture:=0
    try ControlSetText(editText, editHwnd)
    sendinput("{end}")
    return true
}

;qbar中跳到下层文件路径
keyFunc_qbar_lowerFolderPath(){
    global GuiHwnd, qbarPathFuture, editHwnd
    if(!IsSet(GuiHwnd) || !WinActive("ahk_id" . GuiHwnd))
    {
        return
    }
    ;  ifInsertHistory:=0  ;禁止记录地址
    ; editText:=qbarPathFuture.remove()
    editText := "" ; TODO: fix history
    if(editText)
    {
        ; ifClearFuture:=0
        try ControlSetText(editText, editHwnd)
        sendinput("{end}")
    }
    return true
}

;winbind-------------
keyFunc_winbind_activate(n){
    global
    try activateWinAction(n) ; In lib_bindWins.ahk
    return
}

keyFunc_winbind_binding(n){
    global
    try tapTimesFunc(n) ; In lib_bindWins.ahk
    return
}