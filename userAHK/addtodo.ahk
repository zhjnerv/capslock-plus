/*
    Obsidian 快速添加任务脚本
    - 捕获文本并显示一个编辑窗口
    - 用户确认后，构建 Advanced URI 并发送到 Obsidian
*/

global todoGuiHwnd := "", todoEditHwnd := "", initialTaskText := ""
global TodoGuiObj := ""
global TodoAddSource := 0

addObsidianTodo(text) {
    global todoGuiHwnd, todoEditHwnd, initialTaskText, TodoGuiObj, TodoAddSource

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
    
    TodoGuiObj.SetFont("s12 w400", "Microsoft YaHei UI")
    
    ; 隐藏的OK按钮，设置为Default，响应回车
    TodoGuiObj.Add("Button", "x-40 y-40 Default", "OK").OnEvent("Click", TodoButtonOK)
    
    editCtrl := TodoGuiObj.Add("Edit", "x5 y5 w490 h160 vTodoEdit -WantReturn", initialTaskText)
    todoEditHwnd := editCtrl.Hwnd
    
    TodoGuiObj.Add("Checkbox", "x10 y175 vAddSource", "添加来源 (当前窗口标题)")
    
    TodoGuiObj.BackColor := "fefefe"
    TodoGuiObj.OnEvent("Escape", TodoClose)
    TodoGuiObj.OnEvent("Close", TodoClose)
    
    TodoGuiObj.Show("Center w500 h210")
    
    try ControlFocus(todoEditHwnd)
}

; 按下回车键时触发
TodoButtonOK(*) {
    global TodoGuiObj
    if (!TodoGuiObj)
        return
        
    saved := TodoGuiObj.Submit()
    finalTask := saved.TodoEdit
    addSourceVal := saved.AddSource
    
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
    TrayTip("任务已添加", "Obsidian", 1) ; 1=Info icon
} 

TodoClose(*) {
    global TodoGuiObj
    if (TodoGuiObj)
        TodoGuiObj.Destroy()
}

; UrlEncode is already defined in lib/lib_functions.ahk
