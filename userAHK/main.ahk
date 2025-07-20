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
#include addtodo.ahk

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
        
        ; 确保没有残留的修饰键状态
        Send, {Ctrl Up}{Shift Up}
        Sleep, 50
        
        ; 分开发送Ctrl和A，确保正确解析
        Send, {Ctrl Down}
        Sleep, 50  ; 给系统时间识别Ctrl键按下
        Send, {A}
        Sleep, 50  ; 保持Ctrl按下状态一段时间
        Send, {Ctrl Up}
        
        Sleep, 200  ; 等待选择操作完成
        
        ; 同样分开发送Ctrl+C
        Send, {Ctrl Down}
        Sleep, 50
        Send, {C}
        Sleep, 50
        Send, {Ctrl Up}
        
        ClipWait, 2
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


; 主功能：添加任务到Obsidian
keyFunc_addObsidianTask(){
    global
    local selText := getSelText()
    
    ; 如果没有选中文本，则尝试获取光标所在的单词
    if (!selText)
    {
        local ClipboardOld := ClipboardAll
        Clipboard := ""
        SendInput, ^{Left}^+{Right}^c
        ClipWait, 0.5 ; 先执行ClipWait命令
        if (!ErrorLevel) ; 然后检查ErrorLevel判断是否成功
            selText := Clipboard
        Clipboard := ClipboardOld
    }
    
    ; 如果成功获取到文本，则调用新脚本中的函数
    if (selText)
        addObsidianTodo(selText)
    else
        addObsidianTodo("") ; 即使没有文本，也打开窗口让用户手动输入
    return
}
