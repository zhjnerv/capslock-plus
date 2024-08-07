#Include ../lib/lib_json.ahk ;引入json解析文件


keyFunc_OpenAI(){
    ;指定文件编码
    #Persistent
    FileEncoding, UTF-8
    ;确认function调用成功
    msgbox, "OpenAI 启动成功"
    ; 设置OpenAI API密钥
    ;OpenAI_key := "YOUR_OpenAI_key"
    
    ; 定义基础URL地址变量
    ;base_url := "https://api.openai.com/"

    ; 定义模型变量
    ;model := "gpt-4o-mini"

    ; 定义temperature和top_p参数
    ;temperature := 0.7
    ;top_p := 0.9

    global OpenAI_key, base_url, model, temperature, top_p

    OpenAI_key:=CLSets.TTranslate.OpenAI_key
    base_url:=CLSets.TTranslate.base_url
    model:=CLSets.TTranslate.model
    temperature:=CLSets.TTranslate.temperature
    top_p:=CLSets.TTranslate.top_p
    system_prompt = 
    (
    你是一个客户关系处理专家，知识产权法律顾问，精通各种销售技巧，并具良好的心理学技巧。我希望你能帮我将以下内容转化为与客户沟通的公关用语。在不改变意思表示的情况下改变语气，使用自然朴实的语言，巧妙地提供情绪价值，以获得客户信任，完成销售目的。
    )
    ;确认变量
    MsgBox, [ %OpenAI_key%, %base_url%, %model%, %temperature%, %top_p% ]

    ; 快捷键：Ctrl+Shift+O
    ;^+o::
        ; 获取光标左侧的文本
        clipboard:="" ;将剪贴板清空
        ;MsgBox, %clipboard% ;确认剪贴板内容清空
        SendInput, +{Up}
        Sendinput, ^{c}
        ClipWait, 1
        
        user_content := clipboard
        msgbox, %user_content% ;确认user_content数据是否正确

        ;创建一个空对象
        data := {}

        ; 设置请求数据
        data["model"] := model
        data["messages"] := [{"role": "system","content": system_prompt},{"role": "user","content": user_content}]
        ;data["temperature"] := temperature
        ;data["top_p"] := top_p

        ; 将data数据转换为JSON格式
        json_data := JSON.Dump(data)
        
        msgbox, %json_data% ;确认data数据是否正确
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
        MsgBox, %result%

        clipboard := result ;将result数据复制到剪贴板

        return result
    
}


ConvertToUTF8(str) {
    VarSetCapacity(utf8Str, StrPut(str, "CP0") * 2)
    StrPut(str, &utf8Str, "CP0")
    return StrGet(&utf8Str, "UTF-8")
}