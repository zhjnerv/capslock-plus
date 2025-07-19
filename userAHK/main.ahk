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
; ===============================================
; Obsidian 任务快速添加功能（简化版）
; 依赖: lib_functions.ahk 中的 UTF8encode() 和 URLencode()
; ===============================================

; 配置区域 - 根据你的实际情况修改这些变量
OBSIDIAN_VAULT := "newob"
OBSIDIAN_FILE := "00-收集箱/收集箱主页.md"
OBSIDIAN_HEADING := "外部任务入口"

; 主功能：添加任务到Obsidian
keyFunc_addObsidianTask(){
    ; 获取用户输入
    InputBox, taskContent, 添加任务到Obsidian, 请输入任务内容：, , 400, 120
    
    ; 检查用户是否取消或输入为空
    if ErrorLevel or (taskContent = "")
        return
    
    ; 添加任务
    AddTaskToObsidian(taskContent)
    
    ; 简单反馈
    TrayTip, Obsidian, 任务已添加, 2, 1
}

; 从剪贴板添加任务
keyFunc_addObsidianTaskFromClipboard(){
    clipContent := Clipboard
    
    if (clipContent = "") {
        MsgBox, 48, 提示, 剪贴板为空
        return
    }
    
    ; 清理内容
    cleanContent := Trim(clipContent)
    cleanContent := RegExReplace(cleanContent, "\r?\n+", " ")
    if (StrLen(cleanContent) > 200)
        cleanContent := SubStr(cleanContent, 1, 200) . "..."
    
    ; 添加任务
    AddTaskToObsidian(cleanContent)
    TrayTip, Obsidian, 剪贴板内容已添加, 2, 1
}

; 核心函数：将任务添加到Obsidian
AddTaskToObsidian(taskContent) {
    global OBSIDIAN_VAULT, OBSIDIAN_FILE, OBSIDIAN_HEADING
    
    ; 获取时间和来源
    FormatTime, currentTime, , yyyy-MM-dd HH:mm
    WinGetTitle, windowTitle, A
    source := windowTitle ? windowTitle : "快捷键添加"
    
    ; 格式化任务（保持你原来的格式）
    taskLine := " - [ ] " . taskContent . " 来源:" . source . " 记录于:" . currentTime . " #待处理" . "`n"
    
    ; 编码
    encodedVault := URLencode(OBSIDIAN_VAULT)
    encodedFile := UTF8encode(OBSIDIAN_FILE)
    encodedHeading := UTF8encode(OBSIDIAN_HEADING)
    encodedContent := UTF8encode(taskLine)
    
    ; 构建URI
    uri := "obsidian://advanced-uri?vault=" . encodedVault . "&filepath=" . encodedFile . "&heading=" . encodedHeading . "&mode=append&data=" . encodedContent
    
    ; 执行
    Run, %uri%
}

; ===============================================
; 使用说明：
; 1. 修改顶部的三个配置变量
; 2. 在 CapsLock+settings.ini 添加：
;    caps_t=keyFunc_addObsidianTask
;    caps_shift_t=keyFunc_addObsidianTaskFromClipboard
; 3. 重启CapsLock+工具
; ===============================================