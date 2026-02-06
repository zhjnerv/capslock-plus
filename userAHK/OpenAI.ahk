; #Include "../lib/lib_json.ahk" ; Already included by CapsLock+.ahk

;指定文件编码
; #Persistent ; Not needed in V2 for included files usually, main script persists
FileEncoding("UTF-8")

; Globals for OpenAI
global OpenAI_key := "", base_url := "", model := "", temperature := "", top_p := ""
global openaiGuiHwnd := "", openAI_transEditHwnd := "", openAI_transEdit := ""
global system_prompt := "", user_content := "", promptSelectionDone := 0
global selectedPromptFileName := "", selectedPromptIndex := 1
global OpenAIgs := "" ; GUI Object for Settings/Prompt

setOpenaiActive(*) {
    global openaiGuiHwnd
    if (openaiGuiHwnd && WinExist("ahk_id " . openaiGuiHwnd))
        WinActivate("ahk_id " . openaiGuiHwnd)
}

OpenAI_Cap(oo)
{
    global OpenAI_key, base_url, model, temperature, top_p, user_content
    
    ; 移除全局声明，因为已经在开头声明过了
    if (CLSets.Has("AI")) {
        OpenAI_key  := CLSets["AI"].Has("OpenAI_key") ? CLSets["AI"]["OpenAI_key"] : ""
        base_url    := CLSets["AI"].Has("base_url") ? CLSets["AI"]["base_url"] : ""
        model       := CLSets["AI"].Has("model") ? CLSets["AI"]["model"] : "gpt-3.5-turbo"
        temperature := CLSets["AI"].Has("temperature") ? CLSets["AI"]["temperature"] : 0.7
        top_p       := CLSets["AI"].Has("top_p") ? CLSets["AI"]["top_p"] : 1
    }
    
    ; 预处理输入文本
    oo := RegExReplace(oo, "\s+", " ") ; 将所有空白符替换为空格
    user_content := Trim(oo) ; 去除首尾空格
    
    ; 启动Prompt选择流程
    ShowPromptSelection()
}

;单独的显示prompt选择框的函数
ShowPromptSelection()
{
    global OpenAIgs, promptSelectionDone, selectedPromptFileName, selectedPromptIndex
    
    ; 显示选择对话框
    OpenAIgs := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", "选择 Prompt 文件")
    gsHwnd := OpenAIgs.Hwnd
    applyModernStyle(gsHwnd)
    OpenAIgs.BackColor := "010203"
    
    fontName := "Segoe UI Variable Text"
    OpenAIgs.SetFont("s11 cEEEEEE", fontName)

    margin := fixDpi(20)
    OpenAIgs.Add("Text", "x" . margin . " y" . margin, "请选择要使用的 Prompt 文件 (1-5):")
    
    ; Radio buttons
    OpenAIgs.SetFont("s10 cEEEEEE")
    OpenAIgs.Add("Radio", "vSelectedPrompt Checked x" . margin . " y+10", "1. 默认 (prompt.txt)").OnEvent("Click", RadioPrompt)
    OpenAIgs.Add("Radio", "x" . margin . " y+5", "2. 改写 (rewrite_prompt.txt)").OnEvent("Click", RadioPrompt)
    OpenAIgs.Add("Radio", "x" . margin . " y+5", "3. 翻译 (translate_prompt.txt)").OnEvent("Click", RadioPrompt)
    OpenAIgs.Add("Radio", "x" . margin . " y+5", "4. 总结 (summarize_prompt.txt)").OnEvent("Click", RadioPrompt)
    OpenAIgs.Add("Radio", "x" . margin . " y+5", "5. 润色 (polish_prompt.txt)").OnEvent("Click", RadioPrompt)
    
    OpenAIgs.SetFont("s10 c000000") ; Buttons usually look better with dark text or themed
    OpenAIgs.Add("Button", "Default x" . margin . " y+15 w80 h30", "确定").OnEvent("Click", ConfirmPromptFile)
    OpenAIgs.Add("Button", "x+10 w80 h30", "取消").OnEvent("Click", CancelPromptFile)
    
    OpenAIgs.Show("AutoSize Center")
    WinSetTransColor("010203", gsHwnd)

    ; 点击外部自动取消
    OnMessage(0x0006, OpenAI_WM_ACTIVATE)


    
    ; 添加热键 context
    hwnd := OpenAIgs.Hwnd
    HotIfWinActive("ahk_id " . hwnd)
    Hotkey("1", SelectPrompt1)
    Hotkey("2", SelectPrompt2)
    Hotkey("3", SelectPrompt3)
    Hotkey("4", SelectPrompt4)
    Hotkey("5", SelectPrompt5)
    Hotkey("Escape", CancelPromptFileAndDisableHotkeys)
    Hotkey("Enter", ConfirmPromptFileAndDisableHotkeys)
    HotIfWinActive
    
    ; 强制重置CapsLock状态
    ; CapsLock := "" ; Not strictly needed in V2 object scope usually
    
    ; 不使用 WinWaitClose，而是设置一个全局变量来标记选择状态
    promptSelectionDone := 0
    selectedPromptFileName := "prompt.txt"  ; 默认值
    selectedPromptIndex := 1  ; 默认选择第一项
    
    ; 等待选择完成
    waitCount := 0
    while (!promptSelectionDone) {
        Sleep(100)
        waitCount += 1
        if (waitCount > 100) {  ; 10秒 = 100 * 100ms
            promptSelectionDone := 1
            break
        }
    }
    
    DisablePromptHotkeys(hwnd)
    
    if (OpenAIgs)
        OpenAIgs.Destroy()
    
    ; 重置等待计数器
    waitCount := 0
}

DisablePromptHotkeys(hwnd) {
    try {
        HotIfWinActive("ahk_id " . hwnd)
        Hotkey("1", "Off")
        Hotkey("2", "Off")
        Hotkey("3", "Off")
        Hotkey("4", "Off")
        Hotkey("5", "Off")
        Hotkey("Escape", "Off")
        Hotkey("Enter", "Off")
        HotIfWinActive
    }
}


;专门用来处理API请求的函数
CallOpenAIAPI()
{
    global system_prompt, user_content, selectedPromptFileName
    global openaiGuiHwnd, openAI_transEditHwnd, OpenAIResGui
    
    ; 读取选定的 prompt 文件并继续执行
    promptPath := A_WorkingDir . "\userAHK\prompt\" . selectedPromptFileName
    ; userAHK path adjustment since prompted files likely moved or relative
    
    if !FileExist(promptPath)
        promptPath := A_WorkingDir . "\prompt\" . selectedPromptFileName ; Try root prompt

    try {
        system_prompt := FileRead(promptPath)
    } catch {
        system_prompt := ""
    }
    
    ; 如果读取失败，使用默认 prompt
    if (system_prompt == "") {
        try {
            system_prompt := FileRead(A_WorkingDir . "\userAHK\prompt\prompt.txt")
        }
    }

    ; 显示处理中的对话框
    OpenAIMsgBoxStr := user_content ? "正在修改……" : ""
    
    DetectHiddenWindows(true)
    
    if (openaiGuiHwnd && WinExist("ahk_id " . openaiGuiHwnd))
    {
        try ControlSetText(OpenAIMsgBoxStr, openAI_transEditHwnd)
        try ControlFocus(openAI_transEditHwnd)
        WinShow("ahk_id " . openaiGuiHwnd)
        OpenAIResGui := GuiFromHwnd(openaiGuiHwnd)
    }
    else
    {
        OpenAIResGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", "openai修饰")
        openaiGuiHwnd := OpenAIResGui.Hwnd
        
        applyModernStyle(openaiGuiHwnd)
        OpenAIResGui.BackColor := "010203"

        fontName := "Segoe UI Variable Text"
        OpenAIResGui.SetFont("s11 cEEEEEE", fontName)
        
        OpenAIResGui.OnEvent("Escape", (*) => OpenAIResGui.Hide())
        OpenAIResGui.OnEvent("Close", (*) => OpenAIResGui.Hide())
        
        ; Hidden default button
        OpenAIResGui.Add("Button", "x-100 y-100 Default", "OK").OnEvent("Click", ButtonOK_OpenAI) 

        margin := fixDpi(10)
        innerW := fixDpi(500)
        innerH := fixDpi(400)

        ; Background for Edit
        OpenAIResGui.Add("Text", "x" . margin . " y" . margin . " w" . innerW . " h" . innerH . " Background2D2D2D")

        openAI_transEditObj := OpenAIResGui.Add("Edit", "x" . (margin+5) . " y" . (margin+5) . " w" . (innerW-10) . " h" . (innerH-10) . " vopenAI_transEdit -WantReturn -E0x200 cEEEEEE Background2D2D2D", OpenAIMsgBoxStr)
        openAI_transEditHwnd := openAI_transEditObj.Hwnd
        
        OpenAIResGui.Show("Center w" . (innerW + 2*margin) . " h" . (innerH + 2*margin))
        WinSetTransColor("010203", openaiGuiHwnd)
        
        ; 点击外部自动隐藏
        OnMessage(0x0006, OpenAI_WM_ACTIVATE)
        
        try ControlFocus(openAI_transEditHwnd)

        SetTimer(setOpenaiActive, 50)
    }


    ; 如果有内容，则调用API处理
    if(user_content) 
    {
        ; 创建一个空对象
        data := Map()

        ; 设置请求数据
        data["model"] := model
        data["messages"] := [Map("role", "system", "content", system_prompt), Map("role", "user", "content", "目标内容如下：<" . user_content . ">")]

        ; 将data数据转换为JSON格式
        json_data := JSON.stringify(data)
        
        ; 构建请求头
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        post_url := base_url . "v1/chat/completions"
        http.Open("POST", post_url, true) ; Async=true
        http.SetRequestHeader("Content-Type", "application/json")
        http.SetRequestHeader("Authorization", "Bearer " . OpenAI_key)
        http.Send(json_data)
        
        try {
            http.WaitForResponse(-1)
        
            if (http.status != 200) {
                ; 获取错误信息
                try {
                    errorMessage := JSON.parse(http.responseText)["error"]["message"]
                } catch {
                    errorMessage := "OpenAI API Error: Status " . http.status . " - " . http.statusText
                }
                ; 显示错误信息到 GUI
                OpenAIMsgBoxStr := errorMessage
            }
            else {
                ; 获取响应
                arr := http.responseBody
                pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize, "Ptr")
                length := arr.MaxIndex() + 1
                response := StrGet(pData, length, "utf-8")
    
                ; 使用 JSON.Load 解析响应
                responseObject := JSON.parse(response)
    
                ; 获取助手消息内容
                ; V2 JSON object access depends on library, usually Map/Array
                try {
                    result := responseObject["choices"][1]["message"]["content"]
                    result := StrReplace(result, "`n", "`r`n")
                    
                    OpenAIMsgBoxStr := result
                    A_Clipboard := result ;将result数据复制到剪贴板
                } catch {
                    OpenAIMsgBoxStr := "Error parsing response."
                }
            }
        } catch as e {
             OpenAIMsgBoxStr := "Request Failed: " . e.Message
        }

        ; 更新GUI显示
        try ControlSetText(OpenAIMsgBoxStr, openAI_transEditHwnd)
        try ControlFocus(openAI_transEditHwnd)
        SetTimer(setOpenaiActive, 50)
    }
}


; 添加确认 prompt 文件选择的标签
ConfirmPromptFile(*) {
    global OpenAIgs, promptSelectionDone, selectedPromptIndex, selectedPromptFileName
    if (OpenAIgs)
        saved := OpenAIgs.Submit() ; Hide?
        
    promptSelectionDone := 1
    
    ; 根据选择的索引设置文件名
    if (selectedPromptIndex = 1) {
        selectedPromptFileName := "prompt.txt"
    } else if (selectedPromptIndex = 2) {
        selectedPromptFileName := "rewrite_prompt.txt"
    } else if (selectedPromptIndex = 3) {
        selectedPromptFileName := "translate_prompt.txt"
    } else if (selectedPromptIndex = 4) {
        selectedPromptFileName := "summarize_prompt.txt"
    } else if (selectedPromptIndex = 5) {
        selectedPromptFileName := "polish_prompt.txt"
    }
    
    ;在选择好文件之后，立即调用API请求相关的函数
    ; Use SetTimer to decouple stack
    SetTimer(CallOpenAIAPI, -10)
}

ConfirmPromptFileAndDisableHotkeys(*) {
    ConfirmPromptFile()
}

; 添加取消选择的标签
CancelPromptFile(*) {
    global OpenAIgs, promptSelectionDone, selectedPromptFileName
    if (OpenAIgs)
        OpenAIgs.Destroy()
        
    promptSelectionDone := 1
    selectedPromptFileName := "prompt.txt"  ; 使用默认值
}

CancelPromptFileAndDisableHotkeys(*) {
    CancelPromptFile()
}

; 处理单选按钮变化
RadioPrompt(*) {
    ; Not really needed to auto-submit in V2 events usually pass the control
    ; But we can store index if needed manually or just rely on submit
    ; Let's just update index when clicked based on name?
    ; Or easier: submit in Confirm.
    ; But original code updated on click.
    global OpenAIgs, selectedPromptIndex
    if OpenAIgs {
        saved := OpenAIgs.Submit(0)
        selectedPromptIndex := saved.SelectedPrompt
    }
}

; 数字键快捷选择
SelectPrompt1(*) {
    UpdatePromptSelection(1)
}
SelectPrompt2(*) {
    UpdatePromptSelection(2)
}
SelectPrompt3(*) {
    UpdatePromptSelection(3)
}
SelectPrompt4(*) {
    UpdatePromptSelection(4)
}
SelectPrompt5(*) {
    UpdatePromptSelection(5)
}

UpdatePromptSelection(idx) {
    global OpenAIgs, selectedPromptIndex
    selectedPromptIndex := idx
    if (OpenAIgs) {
        ; Check the radio button
        try ControlSetChecked(1, "Button" . idx, OpenAIgs.Hwnd) ; Buttons are usually sequentual
    }
    ConfirmPromptFile()
}

; 添加按钮处理函数
ButtonOK_OpenAI(*) {
    global OpenAIResGui, openAI_transEdit, user_content
    if (OpenAIResGui)
        saved := OpenAIResGui.Submit(0)
    
    ; openAI_transEdit variable bound to control in V1, V2 needs object access or saved.openAI_transEdit
    ; But we used variable name vopenAI_transEdit
    
    userInput := saved.openAI_transEdit
    userInput := RegExReplace(userInput, "\s+", " ")
    user_content := Trim(userInput)

    ; 重新调用 OpenAI_Cap 函数处理新文本
    CallOpenAIAPI()
}

/**
 * 处理 WM_ACTIVATE 消息 (0x06)，当 OpenAI 相关窗口失去激活状态时隐藏或取消
 */
OpenAI_WM_ACTIVATE(wParam, lParam, msg, hwnd) {
    global OpenAIResGui, openaiGuiHwnd, OpenAIgs
    ; wParam == 0 表示 WA_INACTIVE（失去激活）
    if (wParam == 0) {
        ; 如果是结果窗口失去焦点，直接隐藏
        if (IsSet(openaiGuiHwnd) && hwnd == openaiGuiHwnd) {
            if (IsSet(OpenAIResGui) && OpenAIResGui) {
                try OpenAIResGui.Hide()
            }
        }
        ; 如果是 Prompt 选择窗口失去焦点，触发取消逻辑
        else if (IsSet(OpenAIgs) && OpenAIgs && hwnd == OpenAIgs.Hwnd) {
            try CancelPromptFile()
        }
    }
}
