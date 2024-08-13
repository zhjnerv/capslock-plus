#Include ../lib/lib_json.ahk ;引入json解析文件


;指定文件编码
#Persistent
FileEncoding, UTF-8

OpenAIApiInit:
global OpenAI_key, base_url, model, temperature, top_p, openaiGuiHwnd, openAI_transEditHwnd, openAI_transEdit, system_prompt, user_content


;确认变量
; MsgBox, %OpenAI_key%, %base_url%, %model%, %temperature%, %top_p% , %system_prompt%

setopenAIGuiActive:
WinActivate, ahk_id %openaiGuiHwnd%
return


OpenAI_Cap(oo)
{

    OpenAI_key:=CLSets.TTranslate.OpenAI_key
    base_url:=CLSets.TTranslate.base_url
    model:=CLSets.TTranslate.model
    temperature:=CLSets.TTranslate.temperature
    top_p:=CLSets.TTranslate.top_p
    system_prompt = 
    (
    你是一个沟通专家，你的user集多种身份于一身，是一个好丈夫、好女婿、好儿子，同时他是一个专利律师，需要直接与客户沟通，并获取客户的信任，以其达到接案的目的。user需要你利用你的技巧帮助他修改他的语言文字，以期得到正面的、更好的沟通效果。
    你需要首先理解user的输入的内容，并推测user沟通的聊天对象，进而反推user在对话中的角色，然后根据对应的角色，修改文字。
    你要尽量维持user的意思表达，但可以根据角色的需要改变用语和语气，以维持user的角色。
    你使用通俗易懂的语言，关怀的词汇、积极的语言和温和的语气表达共情，来修改user的语言，以减少user的聊天对象的防御心理，让user的聊天对象感觉自己被尊重和理解。
    你使用积极、建设性的话语来塑造积极的氛围修改user的语言。例如，代替“不能”用“我们可以考虑另一种方式”，通过重新定义或重塑问题，将对话引导到对user有利的方向。
    注意，即使user输入的文字中表达了否定的含意，你基于你的技巧，会避免使用否定的用语。
    user的大多数使用场景都是即时通讯软件，因此你也要根据场景修改表达的方式。通过适度使用标点符号（如逗号、问号、感叹号等）来调节语气，避免user的谈话对象感到语气生硬或不友好。
    你在修改user的语言时，避免一次性发送过多的信息或长篇大论，将重要信息分成几段，逐步传达，可以帮助user的谈话对象更好地理解和消化。
    你只需要修改user输入的文字，然后直接反馈给user，不需要任何其他的说明。 
    )

oepnaiStart:
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
        Gui, Font, s10 w400, 微软雅黑
        gui, Add, Button, x-40 y-40 Default gButtonOK_OpenAI, OK  
        
        Gui, Add, Edit, x-2 y0 w504 h405 vopenAI_transEdit HwndopenAI_transEditHwnd -WantReturn -VScroll , %OpenAIMsgBoxStr% ;注意此处的vopenAI_transEdit
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
        data["messages"] := [{"role": "system","content": system_prompt},{"role": "user","content": user_content}]
        ;data["temperature"] := temperature
        ;data["top_p"] := top_p

        ; 将data数据转换为JSON格式
        json_data := JSON.Dump(data)
        
        ;msgbox, %json_data% ;确认data数据是否正确
        ; 构建请求头
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        post_url := base_url . "v1/chat/completions"
        http.Open("POST", post_url, True)
        http.SetRequestHeader("Content-Type", "application/json")
        http.SetRequestHeader("Authorization", "Bearer " . OpenAI_key)
        http.Send(json_data)
        http.WaitForResponse(-1)
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

        ; 显示结果
        ;MsgBox, %result%
        OpenAIMsgBoxStr  := result ; 将 OpenAI 返回的翻译结果赋值给 OpenAIMsgBoxStr 

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