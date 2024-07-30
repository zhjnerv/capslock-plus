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
#Include ../lib/lib_json.ahk ;引入json解析文件

;定义全局变量
global OpenAI_key, base_url, model, temperature, top_p

OpenAI_key:=CLSets.TTranslate.OpenAI_key
bash_url:=CLSets.TTranslate.bash_url
model:=CLSets.TTranslate.model
temperature:=CLSets.TTranslate.temperature
top_p:=CLSets.TTranslate.top_p



keyFunc_OpenAI(){
    ; 设置OpenAI API密钥
    ;OpenAI_key := "YOUR_OpenAI_key"
    
    ; 定义基础URL地址变量
    ;base_url := "https://api.openai.com/"

    ; 定义模型变量
    ;model := "gpt-4o-mini"

    ; 定义temperature和top_p参数
    ;temperature := 0.7
    ;top_p := 0.9

    ; 快捷键：Ctrl+Shift+O
    ;^+o::
        ; 获取光标左侧的文本
        Send, ^+{Up}
        Send, ^c
        ClipWait, 1
        prompt := Clipboard
    
        ; 使用变量发送请求到OpenAI
        response := SendToOpenAI(prompt, OpenAI_key, base_url, model, temperature, top_p)
    
        ; 将返回的结果插入到光标所在的位置
        Send, %response%
    return
}

SendToOpenAI(prompt, OpenAI_key, base_url, model, temperature, top_p) {
    ; 创建HTTP请求
    http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    post_url := base_url . "v1/chat/completions"
    http.Open("POST", post_url, false)
    http.SetRequestHeader("Content-Type", "application/json")
    http.SetRequestHeader("Authorization", "Bearer " . OpenAI_key)

    ; 设置请求数据
    data := "{""model"": """ model """, ""messages"": [{""role"": ""user"", ""content"": """ prompt """}], ""temperature"": " temperature ", ""top_p"": " top_p "}"
    http.Send(data)

    ; 获取响应
    response := http.ResponseText
    json := JSON_Load(response)
    result := json.choices[1].message.content
    return result
}

; JSON解析函数
JSON_Load(json) {
    static jsonObj := ComObjCreate("Scripting.Dictionary")
    jsonObj.RemoveAll()
    jsonObj.LoadJSON(json)
    return jsonObj
}