/*
    Obsidian 快速添加任务脚本
    - 捕获文本并显示一个编辑窗口
    - 用户确认后，构建 Advanced URI 并发送到 Obsidian
*/

global todoGuiHwnd, todoEditHwnd, initialTaskText

addObsidianTodo(text) {
    global todoGuiHwnd, todoEditHwnd, initialTaskText

    initialTaskText := text

    ; 检查窗口是否已存在
    if (WinExist("ahk_id " . todoGuiHwnd)) {
        ControlSetText, , %initialTaskText%, ahk_id %todoEditHwnd%
        WinActivate, ahk_id %todoGuiHwnd%
        ControlFocus, , ahk_id %todoEditHwnd%
        return
    }

    ; 创建新窗口
    Gui, new, +HwndtodoGuiHwnd +LabelTodo, 添加任务到 Obsidian ; 使用 +Label 为所有GUI事件添加"Todo"前缀
    Gui, +AlwaysOnTop -Border +Caption -Disabled -LastFound -MaximizeBox -OwnDialogs -Resize +SysMenu -Theme -ToolWindow
    Gui, Font, s12 w400, Microsoft YaHei UI
    Gui, Add, Button, x-40 y-40 gButtonOK, OK ; 隐藏的OK按钮，用于GoSub跳转
    Gui, Add, Edit, x5 y5 w490 h160 vTodoEdit HwndtodoEditHwnd -WantReturn, %initialTaskText%
    Gui, Add, Checkbox, x10 y175 vAddSource, 添加来源 (当前窗口标题) ; 默认不勾选
    Gui, Color, ffffff, fefefe
    Gui, Show, Center w500 h210, 添加任务到 Obsidian
    ControlFocus, , ahk_id %todoEditHwnd%

    ; --- OnMessage 防火墙 ---2
    ; 监视发送到此脚本GUI线程的按键消息，这是最可靠的按键捕获方式
    OnMessage(0x100, "Todo_WM_KEYDOWN") ; 0x100 is WM_KEYDOWN
} ; <--- 函数在这里结束

; 按下回车键时触发 (标签已添加 "Todo" 前缀)
TodoButtonOK:
    Gui, Submit, NoHide
    Gui, Destroy ; 提交变量后销毁窗口

    finalTask := TodoEdit
    if (Trim(finalTask) = "") {
        return ; 如果内容为空则不执行
    }

    ; --- 构建 URI ---
    ; 从 CapsLock+settings.ini 读取配置
    OBSIDIAN_VAULT   := CLSets.Obsidian.vault
    OBSIDIAN_FILE    := CLSets.Obsidian.file
    OBSIDIAN_HEADING := CLSets.Obsidian.heading
    OBSIDIAN_TAG     := CLSets.Obsidian.tag


    ; 获取时间和来源
    FormatTime, currentDate, , yyyy-MM-dd
    FormatTime, currentTime, , HH:mm
    
    sourcePart := ""
    if (AddSource = 1) { ; 检查复选框是否被选中
        WinGetTitle, windowTitle, A
        source := windowTitle ? Trim(windowTitle) : "快捷键添加"
        sourcePart := " 来源:" . source
    }

    ; 格式化任务行
    taskLine := "- [ ] " . finalTask . sourcePart . " " . currentTime . " #" . OBSIDIAN_TAG . " ➕ " . currentDate . "`n"
     

    ; 编码
    encodedVault := FullURLencode(OBSIDIAN_VAULT)
    encodedFile := FullURLencode(OBSIDIAN_FILE)
    encodedHeading := FullURLencode(OBSIDIAN_HEADING)
    encodedContent := FullURLencode(taskLine)

    ; 构建最终 URI
    uri := "obsidian://advanced-uri?vault=" . encodedVault . "&filepath=" . encodedFile . "&heading=" . encodedHeading . "&mode=append&data=" . encodedContent

    ; 执行
    Run, %uri%
    TrayTip, Obsidian, 任务已添加, 2, 1
return

; 按下 Esc 键时触发 (由热键或关闭按钮调用)
TodoEscape:
; 点击关闭按钮时触发 (标签已添加 "Todo" 前缀)
TodoClose:
    Gui, Destroy
return

; GUI销毁时自动触发的事件，用于清理热键
TodoGuiDestroy:
    ; 停止监视按键消息，清理现场
    OnMessage(0x100, "")
return

; OnMessage 回调函数，处理我们窗口的按键事件
Todo_WM_KEYDOWN(wParam, lParam, msg, hwnd) {
    global todoGuiHwnd, todoEditHwnd
    ; 确保消息来自我们的任务窗口或其编辑控件，忽略其他窗口的消息
    if (hwnd != todoGuiHwnd and hwnd != todoEditHwnd)
        return

    key := wParam ; wParam 是虚拟按键码
    
    ; VK_RETURN (Enter) = 0x0D
    if (key = 0x0D) {
        GoSub, TodoButtonOK ; 跳转到OK标签
    }
    ; VK_ESCAPE (Esc) = 0x1B
    else if (key = 0x1B) {
        GoSub, TodoEscape ; 跳转到Escape标签
    }
}
