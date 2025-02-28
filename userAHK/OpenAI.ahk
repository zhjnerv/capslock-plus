#Include ../lib/lib_json.ahk ;引入json解析文件


;指定文件编码
#Persistent
FileEncoding, UTF-8

OpenAIApiInit:
global OpenAI_key, base_url, model, temperature, top_p, openaiGuiHwnd, openAI_transEditHwnd, openAI_transEdit, system_prompt, user_content


;确认变量
; MsgBox, %OpenAI_key%, %base_url%, %model%, %temperature%, %top_p% , %system_prompt%

; 读取 prompt 文件内容


setopenAIGuiActive:
WinActivate, ahk_id %openaiGuiHwnd%
return


OpenAI_Cap(oo)
{

    OpenAI_key:=CLSets.AI.OpenAI_key
    base_url:=CLSets.AI.base_url
    model:=CLSets.AI.model
    temperature:=CLSets.AI.temperature
    top_p:=CLSets.AI.top_p
    
    ; 添加 prompt 文件选择功能
    ; 显示选择对话框
    Gui, PromptSelect:New, +AlwaysOnTop
    Gui, PromptSelect:Add, Text,, 请选择要使用的 Prompt 文件(或按对应数字键):
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
    Hotkey, 1, SelectPrompt1
    Hotkey, 2, SelectPrompt2
    Hotkey, 3, SelectPrompt3
    Hotkey, 4, SelectPrompt4
    Hotkey, 5, SelectPrompt5
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
    Hotkey, 1, Off
    Hotkey, 2, Off
    Hotkey, 3, Off
    Hotkey, 4, Off
    Hotkey, 5, Off
    Hotkey, Escape, Off
    Hotkey, Enter, Off
    Hotkey, IfWinActive
    
    ; 读取选定的 prompt 文件
    FileRead, system_prompt, %selectedPromptFileName%
    
    ; 如果读取失败，使用默认 prompt
    if (system_prompt = "") {
        FileRead, system_prompt, prompt.txt
    }
    
    ; 重置等待计数器
    waitCount := 0
    
    ; 继续原来的代码
    oo := RegExReplace(oo, "\s", " ") ; 将所有空白符替换为空格
    user_content := Trim(oo) ; 去除首尾空格
    
    ;user_content := UTF8encode(user_content) ; 转换为 UTF-8 编码
    ; msgbox, %user_content% ;确认user_content数据是否正确

openaiGui:
    ;~ WinClose, 有道翻译
    OpenAIMsgBoxStr  := user_content ? "正在修改……" : "" ; 使用 user_content 变量

    ; MsgBox, %OpenAIMsgBoxStr%  ; 显示 OpenAIMsgBoxStr  的值

    ; 检查窗口是否存在
    ; if WinExist("ahk_id " . openaiGuiHwnd) {
    ;     MsgBox, 窗口存在
    ; } else {
    ;     MsgBox, 窗口不存在
    ; }
    ; 显示窗口和 Edit 控件的句柄
    ; MsgBox, openaiGuiHwnd: %openaiGuiHwnd%`nopenAI_transEditHwnd: %openAI_transEditHwnd%

    DetectHiddenWindows, On ;可以检测到隐藏窗口
    WinGet, ifGuiExistButHide, Count, ahk_id %openaiGuiHwnd%
    if(ifGuiExistButHide)
    {
        ControlSetText, , %OpenAIMsgBoxStr%, ahk_id %openAI_transEditHwnd%
        ControlFocus, , ahk_id %openAI_transEditHwnd%
        WinShow, ahk_id %openaiGuiHwnd%
    }
    else ;IfWinNotExist,  ahk_id %openaiGuiHwnd% ;有道翻译
    {
        ;~ MsgBox, 0
        
        Gui, new, +HwndopenaiGuiHwnd , openai修饰
        Gui, +AlwaysOnTop -Border +Caption -Disabled -LastFound -MaximizeBox -OwnDialogs -Resize +SysMenu -Theme -ToolWindow
        Gui, Font, s10 w400, Microsoft YaHei UI ;设置字体
        ; Gui, Font, s10 w400, 微软雅黑
        gui, Add, Button, x-40 y-40 Default gButtonOK_OpenAI, OK  
        
        Gui, Add, Edit, x-2 y0 w504 h405 vopenAI_transEdit HwndopenAI_transEditHwnd -WantReturn , %OpenAIMsgBoxStr% ;注意此处的vopenAI_transEdit
        Gui, Color, ffffff, fefefe
        Gui, +LastFound
        WinSet, TransColor, ffffff 210
        ;~ MsgBox, 1
        Gui, Show, Center w500 h402, openai修饰
        ControlFocus, , ahk_id %openAI_transEditHwnd%
        SetTimer, setOpenaiActive, 50
    }

if(user_content) ;如果传入的字符串非空则翻译
    {
        ;~ MsgBox, 2
        SetTimer, OpenAI_Api, -1
        return
    }


Return

OpenAI_Api:
        ;创建一个空对象
        data := {}

        ; 设置请求数据
        data["model"] := model
        data["messages"] := [{"role": "system","content": system_prompt},{"role": "user","content": "帮我改写以下语句:(" . user_content . ")"}]
        ;data["temperature"] := temperature
        ;data["top_p"] := top_p

        ; 将data数据转换为JSON格式
        json_data := JSON.Dump(data)
        
        ; msgbox, %json_data% ;确认data数据是否正确
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
            goto, setOpneai_TransText
            return
        }
        ; 获取响应
        

        arr := http.responseBody
        pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize)
        length := arr.MaxIndex() + 1
        response := StrGet(pData, length, "utf-8")

        ; 使用 JSON.Load 解析响应 (移除 .Text)
        responseObject := JSON.Load(response)
        ;MsgBox, %responseObject%

        ; 获取助手消息内容
        result := responseObject.choices[1].message.content
        result := StrReplace(result, "`n", "`r`n")

        ; 显示结果
        ;MsgBox, %result%
        OpenAIMsgBoxStr  := result ; 将 OpenAI 返回的翻译结果赋值给 OpenAIMsgBoxStr 
        ; MsgBox, API 返回内容: %result%

        ; 使用正则表达式提取 [[[]]] 包裹的内容
        ; if RegExMatch(result, "\[{3}(.*?)\]{3}", extractedText) {
        ;     clipboard := Trim(extractedText1) ; 将提取的内容复制到剪贴板
        ;     MsgBox, 提取到的内容已复制到剪贴板: %extractedText1%
        ; } else {
        ;     ; 没有找到匹配的内容，复制原始结果
        ;     clipboard := result
        ;     MsgBox, 未找到 [[[]]] 包裹的内容，原始结果已复制到剪贴板: %result%
        ; }
        clipboard := result ;将result数据复制到剪贴板
            ; 显示翻译结果窗口
        goto, setOpneai_TransText
        Return

    

setOpneai_TransText:
ControlSetText, , %OpenAIMsgBoxStr%, ahk_id %openAI_transEditHwnd%
ControlFocus, , ahk_id %openAI_transEditHwnd%
SetTimer, setOpenaiActive, 50
return 
    
ButtonOK_OpenAI:
Gui, Submit, NoHide
; 获取 Edit 控件中的文本，并去除多余空格
openAI_transEdit := RegExReplace(openAI_transEdit, "\s", " ")
user_content := Trim(openAI_transEdit)

; 重新执行 OpenAI_Cap 函数
;OpenAI_Cap(newText)

; 返回到 openaiGui 标签，类似 ydTranslate 函数中的 goto, transGui
goto, openaiGui 


return result
    
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
Gui, PromptSelect:Destroy
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
SelectPrompt1:
GuiControl, PromptSelect:, SelectedPrompt, 1
selectedPromptIndex := 1
goto, ConfirmPromptFile
return

SelectPrompt2:
GuiControl, PromptSelect:, SelectedPrompt, 2
selectedPromptIndex := 2
goto, ConfirmPromptFile
return

SelectPrompt3:
GuiControl, PromptSelect:, SelectedPrompt, 3
selectedPromptIndex := 3
goto, ConfirmPromptFile
return

SelectPrompt4:
GuiControl, PromptSelect:, SelectedPrompt, 4
selectedPromptIndex := 4
goto, ConfirmPromptFile
return

SelectPrompt5:
GuiControl, PromptSelect:, SelectedPrompt, 5
selectedPromptIndex := 5
goto, ConfirmPromptFile
return