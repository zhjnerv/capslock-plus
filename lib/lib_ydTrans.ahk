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
        transGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", IsSet(lang_yd_name) ? lang_yd_name : "Translation")
        transGuiHwnd := transGui.Hwnd
        
        applyModernStyle(transGuiHwnd)
        transGui.BackColor := "010203"

        fontName := "Segoe UI Variable Text"
        transGui.SetFont("s11 cEEEEEE", fontName)
        
        transGui.OnEvent("Escape", (*) => transGui.Hide())
        transGui.OnEvent("Close", (*) => transGui.Hide())

        ; Hidden default button for Enter to submit
        btn := transGui.Add("Button", "x-100 y-100 Default", "OK")
        btn.OnEvent("Click", TransGuiSubmit)

        margin := fixDpi(10)
        innerW := fixDpi(500)
        innerH := fixDpi(400)
        
        ; Background for Edit
        transGui.Add("Text", "x" . margin . " y" . margin . " w" . innerW . " h" . innerH . " Background2D2D2D")
        
        ; Edit Control
        transEdit := transGui.Add("Edit", "x" . (margin+5) . " y" . (margin+5) . " w" . (innerW-10) . " h" . (innerH-10) . " vTransEdit -WantReturn -E0x200 cEEEEEE Background2D2D2D", MsgBoxStr)
        transEditHwnd := transEdit.Hwnd

        transGui.Show("Center w" . (innerW + 2*margin) . " h" . (innerH + 2*margin))
        WinSetTransColor("010203", transGuiHwnd)
        try ControlFocus(transEditHwnd)
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