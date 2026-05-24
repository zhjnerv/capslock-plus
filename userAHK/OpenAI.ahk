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
global OpenAIPromptControls := [], OpenAIPromptLabels := Map()
global OpenAIPromptHotkeyHwnd := ""

setOpenaiActive(*) {
    global openaiGuiHwnd, OpenAIgs
    if (OpenAIgs) {
        try {
            if WinExist("ahk_id " . OpenAIgs.Hwnd)
                return
        }
    }
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
    global OpenAIgs, promptSelectionDone, selectedPromptFileName, selectedPromptIndex, OpenAIPromptControls, OpenAIPromptLabels
    global OpenAIPromptHotkeyHwnd, clState, clUsed

    ; 选择框是独立交互入口，打开后立即释放 CapsLock+ 前缀上下文，
    ; 避免 1-5、e、d 等按键继续被主分发器当作 CapsLock 组合键处理。
    clState := 0
    clUsed := 1
    try SetTimer(changeMouseSpeed, 0)

    if (OpenAIgs)
        OpenAI_ClosePromptSelection(false)

    ; 显示选择对话框
    OpenAIgs := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", "选择 Prompt 文件")
    gsHwnd := OpenAIgs.Hwnd
    CLTheme_ApplyWindow(OpenAIgs, gsHwnd)
    selectedPromptIndex := 1
    selectedPromptFileName := "prompt.txt"
    promptSelectionDone := 0
    OpenAIPromptHotkeyHwnd := gsHwnd
    
    fontName := CLTheme_Font("ui")

    margin := fixDpi(20)
    headerW := fixDpi(360)
    CLTheme_AddRainHeader(OpenAIgs, margin, margin, headerW, "PROMPT MATRIX")
    OpenAIgs.SetFont(CLTheme_FontOptions(11, "textStrong"), fontName)
    OpenAIgs.Add("Text", "x" . margin . " y+10 Background" . CLTheme_Color("window"), "请选择要使用的 Prompt 文件 (1-5):")
    
    ; 使用主题化文本选项替代原生 Radio，避免浅色系统控件破坏 Matrix 风格。
    OpenAIPromptControls := []
    OpenAIPromptLabels := Map()
    optionY := margin + fixDpi(68)
    optionW := fixDpi(360)
    optionH := fixDpi(24)
    OpenAI_AddPromptOption(1, "1. 默认 (prompt.txt)", margin, optionY, optionW, optionH)
    OpenAI_AddPromptOption(2, "2. 改写 (rewrite_prompt.txt)", margin, optionY + optionH, optionW, optionH)
    OpenAI_AddPromptOption(3, "3. 翻译 (translate_prompt.txt)", margin, optionY + optionH*2, optionW, optionH)
    OpenAI_AddPromptOption(4, "4. 总结 (summarize_prompt.txt)", margin, optionY + optionH*3, optionW, optionH)
    OpenAI_AddPromptOption(5, "5. 润色 (polish_prompt.txt)", margin, optionY + optionH*4, optionW, optionH)
    
    ; 原生按钮不易完整换肤，保留隐藏默认按钮处理 Enter，用文本按钮呈现主题风格。
    OpenAIgs.Add("Button", "x0 y0 w0 h0 Default Hidden", "确定").OnEvent("Click", ConfirmPromptFile)
    btnY := optionY + optionH*5 + fixDpi(14)
    CLTheme_AddTextButton(OpenAIgs, margin, btnY, fixDpi(86), fixDpi(30), "确定", ConfirmPromptFile)
    CLTheme_AddTextButton(OpenAIgs, margin + fixDpi(96), btnY, fixDpi(86), fixDpi(30), "取消", CancelPromptFile)
    OpenAIgs.OnEvent("Escape", CancelPromptFile)
    OpenAIgs.OnEvent("Close", CancelPromptFile)
    
    OpenAIgs.Show("AutoSize Center")

    ; 点击外部自动取消
    OnMessage(0x0006, OpenAI_WM_ACTIVATE)


    EnablePromptHotkeys(gsHwnd)
    SetTimer(OpenAI_PromptSelectionTimeout, -10000)
}

OpenAI_AddPromptOption(index, label, x, y, w, h) {
    global OpenAIgs, OpenAIPromptControls, OpenAIPromptLabels, selectedPromptIndex
    OpenAIPromptLabels[index] := label
    OpenAIPromptControls.Push(CLTheme_AddSelectableText(OpenAIgs, x, y, w, h, label, index == selectedPromptIndex, OpenAI_PromptOption_Click.Bind(index)))
}

OpenAI_PromptOption_Click(index, *) {
    SelectPromptOnly(index)
}

SelectPromptOnly(index) {
    global selectedPromptIndex, OpenAIPromptControls, OpenAIPromptLabels
    if (index < 1)
        index := 5
    else if (index > 5)
        index := 1

    selectedPromptIndex := index
    Loop OpenAIPromptControls.Length {
        ctrl := OpenAIPromptControls[A_Index]
        label := OpenAIPromptLabels.Has(A_Index) ? OpenAIPromptLabels[A_Index] : ""
        if (label != "")
            CLTheme_SetSelectableText(ctrl, label, A_Index == selectedPromptIndex)
    }
}

MovePromptSelection(offset) {
    global selectedPromptIndex
    SelectPromptOnly(selectedPromptIndex + offset)
}

SelectPromptPrevious(*) {
    MovePromptSelection(-1)
}

SelectPromptNext(*) {
    MovePromptSelection(1)
}

EnablePromptHotkeys(hwnd) {
    HotIfWinActive("ahk_id " . hwnd)
    Hotkey("1", SelectPrompt1)
    Hotkey("2", SelectPrompt2)
    Hotkey("3", SelectPrompt3)
    Hotkey("4", SelectPrompt4)
    Hotkey("5", SelectPrompt5)
    Hotkey("Numpad1", SelectPrompt1)
    Hotkey("Numpad2", SelectPrompt2)
    Hotkey("Numpad3", SelectPrompt3)
    Hotkey("Numpad4", SelectPrompt4)
    Hotkey("Numpad5", SelectPrompt5)
    Hotkey("Up", SelectPromptPrevious)
    Hotkey("Down", SelectPromptNext)
    Hotkey("e", SelectPromptPrevious)
    Hotkey("d", SelectPromptNext)
    Hotkey("CapsLock & e", SelectPromptPrevious)
    Hotkey("CapsLock & d", SelectPromptNext)
    Hotkey("Escape", CancelPromptFileAndDisableHotkeys)
    Hotkey("Enter", ConfirmPromptFileAndDisableHotkeys)
    HotIfWinActive
}

DisablePromptHotkeys(hwnd) {
    HotIfWinActive("ahk_id " . hwnd)
    for _, keyName in ["1", "2", "3", "4", "5", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Up", "Down", "e", "d", "CapsLock & e", "CapsLock & d", "Escape", "Enter"] {
        try Hotkey(keyName, "Off")
    }
    HotIfWinActive
}

OpenAI_GetPromptFileName(index) {
    switch index {
        case 1:
            return "prompt.txt"
        case 2:
            return "rewrite_prompt.txt"
        case 3:
            return "translate_prompt.txt"
        case 4:
            return "summarize_prompt.txt"
        case 5:
            return "polish_prompt.txt"
        default:
            return "prompt.txt"
    }
}

OpenAI_ClosePromptSelection(runApi := false) {
    global OpenAIgs, promptSelectionDone, OpenAIPromptControls, OpenAIPromptLabels, OpenAIPromptHotkeyHwnd

    alreadyDone := promptSelectionDone
    promptSelectionDone := 1
    try SetTimer(OpenAI_PromptSelectionTimeout, 0)

    hwnd := OpenAIPromptHotkeyHwnd
    if (!hwnd && OpenAIgs) {
        try hwnd := OpenAIgs.Hwnd
    }
    if (hwnd)
        DisablePromptHotkeys(hwnd)

    promptGui := OpenAIgs

    ; Destroy 会触发失焦消息。必须先清掉全局引用，避免 WM_ACTIVATE
    ; 在销毁过程中再次进入 CancelPromptFile，造成同一个 GUI 重复销毁。
    OpenAIgs := ""
    OpenAIPromptHotkeyHwnd := ""
    OpenAIPromptControls := []
    OpenAIPromptLabels := Map()

    if (promptGui) {
        try promptGui.Hide()
        SetTimer(OpenAI_DestroyPromptGui.Bind(promptGui), -100)
    }

    if (runApi && !alreadyDone)
        SetTimer(CallOpenAIAPI, -10)
}

OpenAI_DestroyPromptGui(promptGui, *) {
    try promptGui.Destroy()
}

OpenAI_PromptSelectionTimeout(*) {
    global promptSelectionDone
    if (!promptSelectionDone)
        OpenAI_ClosePromptSelection(false)
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
        
        CLTheme_ApplyWindow(OpenAIResGui, openaiGuiHwnd)

        fontName := CLTheme_Font("ui")
        OpenAIResGui.SetFont(CLTheme_FontOptions(11, "text"), fontName)
        
        OpenAIResGui.OnEvent("Escape", (*) => OpenAIResGui.Hide())
        OpenAIResGui.OnEvent("Close", (*) => OpenAIResGui.Hide())
        
        ; Hidden default button
        OpenAIResGui.Add("Button", "x0 y0 w0 h0 Default Hidden", "OK").OnEvent("Click", ButtonOK_OpenAI) 

        margin := fixDpi(10)
        innerW := fixDpi(500)
        innerH := fixDpi(400)
        headerH := CLTheme_Dpi(20)
        headerGap := CLTheme_Dpi(8)
        fieldY := margin + headerH + headerGap

        CLTheme_AddRainHeader(OpenAIResGui, margin, margin, innerW, "AI RESPONSE STREAM")
        CLTheme_AddPanel(OpenAIResGui, margin, fieldY, innerW, innerH, "panel")

        OpenAIResGui.SetFont(CLTheme_FontOptions(11, "text"), fontName)
        openAI_transEditObj := OpenAIResGui.Add("Edit", "x" . (margin+5) . " y" . (fieldY+5) . " w" . (innerW-10) . " h" . (innerH-10) . " " . CLTheme_EditOptions("vopenAI_transEdit -WantReturn"), OpenAIMsgBoxStr)
        openAI_transEditHwnd := openAI_transEditObj.Hwnd
        CLTheme_ApplyNativeControlTheme(openAI_transEditObj)
        
        OpenAIResGui.Show("Center w" . (innerW + 2*margin) . " h" . (innerH + 2*margin + headerH + headerGap))
        
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
    global selectedPromptIndex, selectedPromptFileName

    selectedPromptFileName := OpenAI_GetPromptFileName(selectedPromptIndex)
    OpenAI_ClosePromptSelection(true)
}

ConfirmPromptFileAndDisableHotkeys(*) {
    ConfirmPromptFile()
}

; 添加取消选择的标签
CancelPromptFile(*) {
    global selectedPromptFileName
    selectedPromptFileName := "prompt.txt"  ; 使用默认值
    OpenAI_ClosePromptSelection(false)
}

CancelPromptFileAndDisableHotkeys(*) {
    CancelPromptFile()
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
    SelectPromptOnly(idx)
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
