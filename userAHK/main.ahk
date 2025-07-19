; 1. Include the .ahk file(s) containing custom key functions here,
;   or just put the functions here.
;   * A key function must start with "keyFunc_" (case insensitive)

; 2. Add a setting under the [Keys] section in `CapsLock+settings.ini`

; Example:
; 1. There is a key function `keyFunc_example2` in demo.ahk.
; 2. Add below setting under the [Keys] section in `CapsLock+settings.ini`:
;   caps_f7=keyFunc_example2
; 3. Save, reload Capslock+ (CapsLock+F5)
; 4. Press `CapsLock+F7` to invoke the function

#include demo.ahk
#include OpenAI.ahk

keyFunc_example1(){
    SendInput % "{TEXT}" . "http://ouo.io/qs/16EB70rI?s=" . Clipboard
    Clipboard := "http://ouo.io/qs/16EB70rI?s=" . Clipboard
    Return
}

keyFunc_OpenAI(){
    global
    selText := getSelText()
    if(selText)
    {
        OpenAI_Cap(selText)
    }
    else
    {
        ClipboardOld := ClipboardAll
        Clipboard := ""
        SendInput, ^{A}
        sleep, 50 
        SendInput, ^{insert}
        ClipWait, 1
        selText := Clipboard 
        
        if (selText = "") {
            MsgBox, 16, Error , Failed to get context.
            Clipboard := ClipboardOld
            Return
        }
        
        OpenAI_Cap(selText)
        Clipboard := ClipboardOld
    }
    SetTimer, setopenAIGuiActive, -400
    Return 
}

; Obsidian快速任务添加功能
keyFunc_addObsidianTask() {
    ; 弹出输入框，让用户输入任务内容
    InputBox, taskContent, 添加任务到Obsidian, 请输入任务内容：
    
    ; 如果用户取消或者没有输入，则中止函数
    if ErrorLevel or (taskContent = "")
        return
    
    ; 获取当前日期和时间
    FormatTime, currentDate, , yyyy-MM-dd
    FormatTime, currentHour, , HH
    FormatTime, currentMin, , mm
    colonChar := ":"
    currentTime := currentDate . " " . currentHour . colonChar . currentMin
    
    ; 组合成最终需要添加到data参数的字符串
    ; 格式: > - [ ] 任务内容 来源:外部URL 记录于:YYYY-MM-DD HH:MM #待处理
    hashTag := "#"
    greaterThan := ">"
    dataString := greaterThan . " - [ ] " . taskContent . " 来源" . colonChar . "外部URL 记录于" . colonChar . currentTime . " " . hashTag . "待处理" . "`n"
    
    ; 对字符串进行URL编码
    encodedData := MyUrlEncode(dataString)
    
    ; 准备基础URL
    baseUrl := "obsidian://advanced-uri?vault=newob&filepath=00-%E6%94%B6%E9%9B%86%E7%AE%B1%2F%E6%94%B6%E9%9B%86%E7%AE%B1%E4%B8%BB%E9%A1%B5.md"
    baseUrl .= "&heading=%E2%86%93%E2%86%93%E2%86%93%E2%86%93%E2%86%93%E2%A6%93%20%E5%A4%96%E9%83%A8%E4%BB%BB%E5%8A%A1%E5%85%A5%E5%8F%A3%20%E2%86%93%E2%86%93%E2%86%93%E2%86%93%E2%86%93%E2%86%93"
    baseUrl .= "&mode=append&data="
    
    ; 拼接成最终要执行的URL
    finalUrl := baseUrl . encodedData
    
    ; 执行这个URL
    Run, %finalUrl%
}

; URL编码辅助函数
MyUrlEncode(str) {
    ; 创建一个足够大的缓冲区
    bufferSize := StrPut(str, "UTF-8") * 3
    VarSetCapacity(encoded, bufferSize)
    
    ; 调用Windows API进行URL编码
    DllCall("urlmon\UrlEscapeA", "Str", str, "Str", encoded, "UInt*", bufferSize, "UInt", 0)
    
    return encoded
}