/*
DeepLX 翻译 (原 有道翻译 模块迁移)
*/

; #Include lib_json.ahk   	; 已经在 CapsLock+.ahk 中包含，或应使用 V2 内置/wrapper
; V2 Note: Assumes standard JSON library or wrapper is available as JSON.

global TransEdit, transEditHwnd, transGuiHwnd, NativeString, DeepLXApiString
global transGui := ""

youdaoApiInit() {
    global DeepLXApiString, CLSets
    DeepLXApiString := ""

    ; 使用setting文件中的变量
    if (CLSets.Has("TTranslate") && CLSets["TTranslate"].Has("endpoint"))
        DeepLXApiString := CLSets["TTranslate"]["endpoint"]
    else
        DeepLXApiString := "http://localhost:1188/translate" ; Default DeepLX endpoint?
}

; 添加语言检测函数
IsChineseText(text) {
    ; 检查文本是否包含中文字符
    Loop Parse, text
    {
        ; 检查每个字符是否在中文Unicode范围内 (基本汉字范围: 0x4E00-0x9FFF)
        if (Ord(A_LoopField) >= 0x4E00 && Ord(A_LoopField) <= 0x9FFF)
            return true
    }
    return false
}

ydTranslate(ss)
{
    global NativeString, transGui, transGuiHwnd, transEditHwnd, lang_yd_name, lang_yd_translating
    global DeepLXApiString

    ; if(StrLen(ss) >= 2000) ...

    NativeString := ss

    MsgBoxStr := NativeString ? (IsSet(lang_yd_translating) ? lang_yd_translating : "Translating...") : ""

    DetectHiddenWindows(true)

    if (IsSet(transGui) && transGui && WinExist("ahk_id " . transGui.Hwnd))
    {
        try ControlSetText(MsgBoxStr, transEditHwnd)
        try ControlFocus(transEditHwnd)
        transGui.Show()
    }
    else
    {
        transGui := Gui("+AlwaysOnTop -Border +Caption -Disabled -MaximizeBox -OwnDialogs -Resize +SysMenu -Theme -ToolWindow", IsSet(lang_yd_name) ? lang_yd_name : "Translation")
        transGuiHwnd := transGui.Hwnd

        transGui.SetFont("s10 w400 c000000", "Microsoft YaHei UI")
        
        transGui.OnEvent("Escape", (*) => transGui.Hide())
        transGui.OnEvent("Close", (*) => transGui.Hide())

        ; Button needs an event
        btn := transGui.Add("Button", "x-40 y-40 Default", "OK")
        btn.OnEvent("Click", TransGuiSubmit)

        transEdit := transGui.Add("Edit", "x-2 y0 w504 h405 vTransEdit -WantReturn c000000 BackgroundWhite", MsgBoxStr)
        transEditHwnd := transEdit.Hwnd

        transGui.BackColor := "White"
        
        transGui.Show("Center w500 h402")
        try WinSetTransparent("Off", transGui) ; Force opaque
        try ControlFocus(transEditHwnd)

        ; SetTimer, setTransActive, 50 ; V2 approach below
    }

    if(NativeString)
    {
        SetTimer(DeepLApi, -1)
    }
}

TransGuiSubmit(*) {
    global transGui, NativeString
    saved := transGui.Submit(false) ; NoHide
    NativeString := saved.TransEdit
    ydTranslate(NativeString) ; Re-trigger
}

DeepLApi() {
    global NativeString, DeepLXApiString, transEditHwnd

    sendStr := DeepLXApiString
    if (sendStr == "")
        sendStr := "http://127.0.0.1:1188/translate" ; Fallback

    data := Map()
    data["text"] := NativeString

    if (IsChineseText(NativeString)) {
        data["source_lang"] := "ZH"
        data["target_lang"] := "EN"
    } else {
        data["source_lang"] := "EN"
        data["target_lang"] := "ZH"
    }

    json_data := JSON.stringify(data)

    whr := ComObject("WinHttp.WinHttpRequest.5.1")

    try {
        whr.Open("POST", sendStr, true) ; Async? No, V1 was sync default unless specified. Let's use Sync for simplicity first or async if needed.
        ; V1: whr.Open("POST", sendStr) -> default sync.
        ; To avoid blocking UI, ideally async, but let's stick to simple first.
        whr.Open("POST", sendStr, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(json_data)

        responseStr := whr.ResponseText

        transJson := JSON.parse(responseStr)

        if (transJson.Has("code") && transJson["code"] == 200) {
            primaryTranslation := transJson["data"]
            alternativeTranslations := transJson.Has("alternatives") ? transJson["alternatives"] : []

            MsgBoxStr := "原文：`r`n" . NativeString . "`r`n`r`n"
            MsgBoxStr .= "主要译文：`r`n" . primaryTranslation . "`r`n`r`n"

            if (alternativeTranslations.Length > 0) {
                MsgBoxStr .= "次要译文："
                for alt in alternativeTranslations {
                    MsgBoxStr .= "`r`n" . alt
                }
            }
        } else {
            code := transJson.Has("code") ? transJson["code"] : "Unknown"
            MsgBoxStr := "错误：" . code
        }
    } catch Error as e {
        MsgBoxStr := "Error: " . e.Message
    }

    ; Update UI
    ; Normalize Line Endings
    MsgBoxStr := StrReplace(MsgBoxStr, "`r`n", "`n")
    MsgBoxStr := StrReplace(MsgBoxStr, "`r", "`n")
    MsgBoxStr := StrReplace(MsgBoxStr, "`n", "`r`n")

    try ControlSetText(MsgBoxStr, transEditHwnd)
    ; try ControlFocus(transEditHwnd)
}