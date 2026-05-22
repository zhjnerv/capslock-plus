/*
    Obsidian 快速添加任务脚本
    - 捕获文本并显示一个编辑窗口
    - 用户确认后，构建 Advanced URI 并发送到 Obsidian
*/

global todoGuiHwnd := "", todoEditHwnd := "", initialTaskText := ""
global TodoGuiObj := ""
global TodoAddSource := 0
global TodoSourceToggleCtrl := ""

addObsidianTodo(text) {
    global todoGuiHwnd, todoEditHwnd, initialTaskText, TodoGuiObj, TodoAddSource, TodoSourceToggleCtrl

    initialTaskText := text

    ; 检查窗口是否已存在
    if (todoGuiHwnd && WinExist("ahk_id " . todoGuiHwnd)) {
        try ControlSetText(initialTaskText, todoEditHwnd)
        WinActivate("ahk_id " . todoGuiHwnd)
        try ControlFocus(todoEditHwnd)
        return
    }

    ; 创建新窗口
    TodoGuiObj := Gui("+AlwaysOnTop -Border +Caption -Disabled -LastFound -MaximizeBox -OwnDialogs -Resize +SysMenu -Theme +ToolWindow", "添加任务到 Obsidian")
    todoGuiHwnd := TodoGuiObj.Hwnd
    TodoAddSource := 0
    TodoSourceToggleCtrl := ""
    
    CLTheme_ApplyWindow(TodoGuiObj, todoGuiHwnd)
    TodoGuiObj.SetFont(CLTheme_FontOptions(12, "text"), CLTheme_Font("ui"))
    
    ; 隐藏的OK按钮，设置为Default，响应回车
    TodoGuiObj.Add("Button", "x0 y0 w0 h0 Default Hidden", "OK").OnEvent("Click", TodoButtonOK)
    
    margin := fixDpi(10)
    headerH := CLTheme_Dpi(20)
    headerGap := CLTheme_Dpi(8)
    editY := margin + headerH + headerGap
    CLTheme_AddRainHeader(TodoGuiObj, margin, margin, fixDpi(480), "OBSIDIAN TASK")
    CLTheme_AddPanel(TodoGuiObj, margin, editY, fixDpi(480), fixDpi(150), "panel")

    TodoGuiObj.SetFont(CLTheme_FontOptions(11, "text"), CLTheme_Font("mono"))
    editCtrl := TodoGuiObj.Add("Edit", "x" . (margin+5) . " y" . (editY+5) . " w" . fixDpi(470) . " h" . fixDpi(140) . " " . CLTheme_EditOptions("vTodoEdit -WantReturn"), initialTaskText)
    todoEditHwnd := editCtrl.Hwnd
    CLTheme_ApplyNativeControlTheme(editCtrl)
    
    ; 使用主题化文本开关替代原生 Checkbox，避免系统浅色控件露出。
    TodoSourceToggleCtrl := CLTheme_AddSelectableText(TodoGuiObj, margin, editY + fixDpi(160), fixDpi(250), fixDpi(24), "添加来源 (当前窗口标题)", false, TodoToggleSource)
    
    TodoGuiObj.OnEvent("Escape", TodoClose)
    TodoGuiObj.OnEvent("Close", TodoClose)
    
    TodoGuiObj.Show("Center w500 h230")
    
    try ControlFocus(todoEditHwnd)
}

; 按下回车键时触发
TodoButtonOK(*) {
    global TodoGuiObj, TodoAddSource
    if (!TodoGuiObj)
        return
        
    saved := TodoGuiObj.Submit()
    finalTask := saved.TodoEdit
    addSourceVal := TodoAddSource
    
    TodoGuiObj.Destroy()
    
    
    if (Trim(finalTask) == "") {
        return ; 如果内容为空则不执行
    }

    ; --- 构建 URI ---
    ; 从 CapsLock+settings.ini 读取配置
    OBSIDIAN_VAULT   := ""
    OBSIDIAN_FILE    := ""
    OBSIDIAN_HEADING := ""
    OBSIDIAN_TAG     := ""
    
    if (CLSets.Has("Obsidian")) {
        OBSIDIAN_VAULT   := CLSets["Obsidian"].Has("vault") ? CLSets["Obsidian"]["vault"] : ""
        OBSIDIAN_FILE    := CLSets["Obsidian"].Has("file") ? CLSets["Obsidian"]["file"] : ""
        OBSIDIAN_HEADING := CLSets["Obsidian"].Has("heading") ? CLSets["Obsidian"]["heading"] : ""
        OBSIDIAN_TAG     := CLSets["Obsidian"].Has("tag") ? CLSets["Obsidian"]["tag"] : ""
    }


    ; 获取时间和来源
    currentDate := FormatTime(, "yyyy-MM-dd")
    currentTime := FormatTime(, "HH:mm")
    
    sourcePart := ""
    if (addSourceVal == 1) { ; 检查复选框是否被选中
        try {
             windowTitle := WinGetTitle("A")
        } catch {
             windowTitle := ""
        }
        source := windowTitle ? Trim(windowTitle) : "快捷键添加"
        sourcePart := " 来源:" . source
    }

    ; 格式化任务行
    taskLine := "- [ ] " . finalTask . sourcePart . " " . currentTime . " #" . OBSIDIAN_TAG . " ➕ " . currentDate . "`n"
     

    ; 编码 (Need FullURLencode function in lib_functions or similar)
    ; Assuming simple URI encoding if not available, OR rely on available function
    ; If FullURLencode is not defined in scope, we need it.
    ; Checking lib_functions.ahk... it might not be there or named differently.
    ; Safe bet: simple JSEval based encode or native AHK manual encode.
    
    encodedVault := UrlEncode(OBSIDIAN_VAULT)
    encodedFile := UrlEncode(OBSIDIAN_FILE)
    encodedHeading := UrlEncode(OBSIDIAN_HEADING)
    encodedContent := UrlEncode(taskLine)

    ; 构建最终 URI
    uri := "obsidian://advanced-uri?vault=" . encodedVault . "&filepath=" . encodedFile . "&heading=" . encodedHeading . "&mode=append&data=" . encodedContent

    ; 执行
    try Run(uri)
    showMsg("任务已添加到 Obsidian", 1500)
} 

TodoToggleSource(*) {
    global TodoAddSource, TodoSourceToggleCtrl
    TodoAddSource := TodoAddSource ? 0 : 1
    if (TodoSourceToggleCtrl)
        CLTheme_SetSelectableText(TodoSourceToggleCtrl, "添加来源 (当前窗口标题)", TodoAddSource)
}

TodoClose(*) {
    global TodoGuiObj, TodoSourceToggleCtrl
    if (TodoGuiObj)
        TodoGuiObj.Destroy()
    TodoSourceToggleCtrl := ""
}

; UrlEncode is already defined in lib/lib_functions.ahk
