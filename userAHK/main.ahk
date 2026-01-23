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

#Include "*i demo.ahk"
#Include "*i OpenAI.ahk"
#Include "*i addtodo.ahk"

keyFunc_example1(){
    A_Clipboard := "http://ouo.io/qs/16EB70rI?s=" . A_Clipboard
    SendInput("{TEXT}http://ouo.io/qs/16EB70rI?s=" . A_Clipboard)
    Return
}

keyFunc_OpenAI(){
    ; global ; V2 functions are local by default, but can access globals if declared
    ; But here we probably don't need global unless OpenAI_Cap uses globals.
    ; Assuming OpenAI_Cap is in OpenAI.ahk and included in global scope or accessible.
    
    selText := getSelText()
    if(selText)
    {
        try OpenAI_Cap(selText)
    }
    else
    {
        ClipboardOld := ClipboardAll()
        A_Clipboard := ""
        
        ; 确保没有残留的修饰键状态
        Send("{Ctrl Up}{Shift Up}")
        Sleep(50)
        
        ; 分开发送Ctrl和A，确保正确解析
        Send("{Ctrl Down}")
        Sleep(50)  ; 给系统时间识别Ctrl键按下
        Send("a") ; V2 case insensitive usually, but 'a' is key name
        Sleep(50)  ; 保持Ctrl按下状态一段时间
        Send("{Ctrl Up}")
        
        Sleep(200)  ; 等待选择操作完成
        
        ; 同样分开发送Ctrl+C
        Send("{Ctrl Down}")
        Sleep(50)
        Send("c")
        Sleep(50)
        Send("{Ctrl Up}")
        
        if !ClipWait(2)
        {
             ; Timeout
             MsgBox("Failed to copy text.", "Error", 16)
             try A_Clipboard := ClipboardOld
             Return
        }
        
        selText := A_Clipboard
        
        if (selText = "") {
            MsgBox("Failed to get context.", "Error", 16)
            try A_Clipboard := ClipboardOld
            Return
        }
        
        try OpenAI_Cap(selText)
        try A_Clipboard := ClipboardOld
    }
    
    ; SetTimer, setopenAIGuiActive, -400 -> SetTimer(Func, -400)
    ; Assuming setOpenaiActive is defined in OpenAI.ahk
    try SetTimer(setOpenaiActive, -400)
    Return 
}


; 主功能：添加任务到Obsidian
keyFunc_addObsidianTask(){
    selText := getSelText()
    
    ; 如果没有选中文本，则尝试获取光标所在的单词
    if (!selText)
    {
        ClipboardOld := ClipboardAll()
        A_Clipboard := ""
        SendInput("^{Left}^+{Right}^c")
        if ClipWait(0.5) ; 
            selText := A_Clipboard
            
        try A_Clipboard := ClipboardOld
    }
    
    ; 如果成功获取到文本，则调用新脚本中的函数
    ; Assuming addObsidianTodo is defined in addtodo.ahk
    if (selText) {
        try addObsidianTodo(selText)
    } else {
        try addObsidianTodo("") ; 即使没有文本，也打开窗口让用户手动输入
    }
    return
}
