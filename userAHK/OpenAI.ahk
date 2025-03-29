#Include ../lib/lib_json.ahk ;引入json解析文件

;指定文件编码
#Persistent
FileEncoding, UTF-8

OpenAIApiInit:
global OpenAI_key, base_url, model, temperature, top_p, openaiGuiHwnd, openAI_transEditHwnd, openAI_transEdit
global system_prompt, user_content, promptSelectionDone, selectedPromptFileName, selectedPromptIndex

setopenAIGuiActive:
WinActivate, ahk_id %openaiGuiHwnd%
return

OpenAI_Cap(oo)
{
    ; 移除全局声明，因为已经在开头声明过了
    OpenAI_key:=CLSets.AI.OpenAI_key
    base_url:=CLSets.AI.base_url
    model:=CLSets.AI.model
    temperature:=CLSets.AI.temperature
    top_p:=CLSets.AI.top_p
    
    ; 预处理输入文本
    oo := RegExReplace(oo, "\s+", " ") ; 将所有空白符替换为空格
    ; MsgBox, 输入内容：%oo%
    user_content := Trim(oo) ; 去除首尾空格
    
    ; 启动Prompt选择流程
    ShowPromptSelection()
}

;单独的显示prompt选择框的函数
ShowPromptSelection()
{
    ; 显示选择对话框
    Gui, PromptSelect:New, +AlwaysOnTop
    Gui, PromptSelect:Add, Text,, 请选择要使用的 Prompt 文件(或按对应数字键) ;两个逗号是跳过了一个宽度参数
    Gui, PromptSelect:Add, Radio, vSelectedPrompt Checked gRadioPrompt, 1. 默认(prompt.txt)
    Gui, PromptSelect:Add, Radio, gRadioPrompt, 2. 改写(rewrite_prompt.txt)
    Gui, PromptSelect:Add, Radio, gRadioPrompt, 3. 翻译(translate_prompt.txt)
    Gui, PromptSelect:Add, Radio, gRadioPrompt, 4. 总结(summarize_prompt.txt)
    Gui, PromptSelect:Add, Radio, gRadioPrompt, 5. 润色(polish_prompt.txt)
    Gui, PromptSelect:Add, Button, Default gConfirmPromptFile w100, 确定
    Gui, PromptSelect:Add, Button, gCancelPromptFile x+10 w100, 取消
    
    ; 添加热键
    Gui, PromptSelect:+LastFound
    hwnd := WinExist()
    Hotkey, IfWinActive, ahk_id %hwnd%
    ; Hotkey, 1, SelectPrompt1
    ; Hotkey, 2, SelectPrompt2
    ; Hotkey, 3, SelectPrompt3
    ; Hotkey, 4, SelectPrompt4
    ; Hotkey, 5, SelectPrompt5
    Hotkey, Escape, CancelPromptFile
    Hotkey, Enter, ConfirmPromptFile
    
    Gui, PromptSelect:Show,, 选择 Prompt 文件
    
    ; 不使用 WinWaitClose，而是设置一个全局变量来标记选择状态
    global promptSelectionDone := 0
    global selectedPromptFileName := "prompt.txt"  ; 默认值
    global selectedPromptIndex := 1  ; 默认选择第一项
    
    ; 等待选择完成
    while (!promptSelectionDone) {
        Sleep, 100
        ; 如果等待超过10秒，使用默认值
        static waitCount := 0
        waitCount += 1
        if (waitCount > 100) {  ; 10秒 = 100 * 100ms
            promptSelectionDone := 1
            break
        }
    }
    
    ; 禁用热键
    Hotkey, IfWinActive, ahk_id %hwnd%
    ; Hotkey, 1, Off
    ; Hotkey, 2, Off
    ; Hotkey, 3, Off
    ; Hotkey, 4, Off
    ; Hotkey, 5, Off
    Hotkey, Escape, Off
    Hotkey, Enter, Off
    Hotkey, IfWinActive
    
    Gui, PromptSelect:Destroy
    
    ; 重置等待计数器
    waitCount := 0
    
}
;专门用来处理API请求的函数
CallOpenAIAPI()
{
    ; 读取选定的 prompt 文件并继续执行
    FileRead, system_prompt, %A_WorkingDir%\prompt\%selectedPromptFileName%
    
    ; 如果读取失败，使用默认 prompt
    if (system_prompt = "") {
        FileRead, system_prompt, %A_WorkingDir%\prompt\prompt.txt
    }

    ; 显示处理中的对话框
    OpenAIMsgBoxStr := user_content ? "正在修改……" : ""
    
    DetectHiddenWindows, On ;可以检测到隐藏窗口
    WinGet, ifGuiExistButHide, Count, ahk_id %openaiGuiHwnd%
    if(ifGuiExistButHide)
    {
        ControlSetText, , %OpenAIMsgBoxStr%, ahk_id %openAI_transEditHwnd%
        ControlFocus, , ahk_id %openAI_transEditHwnd%
        WinShow, ahk_id %openaiGuiHwnd%
    }
    else ;IfWinNotExist,  ahk_id %openaiGuiHwnd%
    {
        Gui, new, +HwndopenaiGuiHwnd , openai修饰
        Gui, +AlwaysOnTop -Border +Caption -Disabled -LastFound -MaximizeBox -OwnDialogs -Resize +SysMenu -Theme -ToolWindow
        Gui, Font, s10 w400, Microsoft YaHei UI ;设置字体
        gui, Add, Button, x-40 y-40 Default gButtonOK_OpenAI, OK  

        Gui, Add, Edit, x-2 y0 w504 h405 vopenAI_transEdit HwndopenAI_transEditHwnd -WantReturn , %OpenAIMsgBoxStr% ;注意此处的vopenAI_transEdit
        Gui, Color, ffffff, fefefe
        Gui, +LastFound
        WinSet, TransColor, ffffff 210
        Gui, Show, Center w500 h402, openai修饰
        ControlFocus, , ahk_id %openAI_transEditHwnd%
        SetTimer, setOpenaiActive, 50
    }

    ; 如果有内容，则调用API处理
    if(user_content) 
    {
        ; 创建一个空对象
        data := {}

        ; 设置请求数据
        data["model"] := model
        data["messages"] := [{"role": "system","content": system_prompt},{"role": "user","content": "目标内容如下：<" . user_content . ">"}]

        ; 将data数据转换为JSON格式
        json_data := JSON.Dump(data)
        
        ; 显示data内容以供确认
        ; MsgBox, % "请求数据内容：`n" . json_data
        ; 构建请求头
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        post_url := base_url . "v1/chat/completions"
        http.Open("POST", post_url, True)
        http.SetRequestHeader("Content-Type", "application/json")
        http.SetRequestHeader("Authorization", "Bearer " . OpenAI_key)
        http.Send(json_data)
        http.WaitForResponse(-1)

        if (http.status != 200) {
            ; 获取错误信息
            try {
                errorMessage := JSON.Load(http.responseText).error.message
            } catch {
                errorMessage := "OpenAI API Error: Status " . http.status . " - " . http.statusText
            }
            ; 显示错误信息到 GUI
            OpenAIMsgBoxStr := errorMessage
        }
        else {
            ; 获取响应
            arr := http.responseBody
            pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize)
            length := arr.MaxIndex() + 1
            response := StrGet(pData, length, "utf-8")

            ; 使用 JSON.Load 解析响应
            responseObject := JSON.Load(response)

            ; 获取助手消息内容
            result := responseObject.choices[1].message.content
            result := StrReplace(result, "`n", "`r`n")

            ; 显示结果
            OpenAIMsgBoxStr := result
            clipboard := result ;将result数据复制到剪贴板
        }

        ; 更新GUI显示
        ControlSetText, , %OpenAIMsgBoxStr%, ahk_id %openAI_transEditHwnd%
        ControlFocus, , ahk_id %openAI_transEditHwnd%
        SetTimer, setOpenaiActive, 50
    }
}

;确保激活
setOpenaiActive:
IfWinExist, ahk_id %openaiGuiHwnd%
{
    SetTimer, ,Off
    WinActivate, ahk_id %openaiGuiHwnd%
}
return

; 添加确认 prompt 文件选择的标签
ConfirmPromptFile:
Gui, PromptSelect:Submit
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
CallOpenAIAPI()
return

; 添加取消选择的标签
CancelPromptFile:
Gui, PromptSelect:Destroy
promptSelectionDone := 1
selectedPromptFileName := "prompt.txt"  ; 使用默认值
return

; 处理单选按钮变化
RadioPrompt:
Gui, PromptSelect:Submit, NoHide
; 根据 SelectedPrompt 的值设置 selectedPromptIndex
selectedPromptIndex := SelectedPrompt
return

; 数字键快捷选择
; SelectPrompt1:
; GuiControl, PromptSelect:, SelectedPrompt, 1
; selectedPromptIndex := 1
; goto, ConfirmPromptFile
; return

; SelectPrompt2:
; GuiControl, PromptSelect:, SelectedPrompt, 2
; selectedPromptIndex := 2
; goto, ConfirmPromptFile
; return

; SelectPrompt3:
; GuiControl, PromptSelect:, SelectedPrompt, 3
; selectedPromptIndex := 3
; goto, ConfirmPromptFile
; return

; SelectPrompt4:
; GuiControl, PromptSelect:, SelectedPrompt, 4
; selectedPromptIndex := 4
; goto, ConfirmPromptFile
; return

; SelectPrompt5:
; GuiControl, PromptSelect:, SelectedPrompt, 5
; selectedPromptIndex := 5
; goto, ConfirmPromptFile
; return

; 添加按钮处理函数
ButtonOK_OpenAI:
Gui, Submit, NoHide
; 获取 Edit 控件中的文本，并去除多余空格
openAI_transEdit := RegExReplace(openAI_transEdit, "\s+", " ") ;20250302增加了一个加号不知道是为什么。
user_content := Trim(openAI_transEdit)

; 重新调用 OpenAI_Cap 函数处理新文本
CallOpenAIAPI()
return
