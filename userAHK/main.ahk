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
#include OpenAI.ahk




keyFunc_example1(){
  SendInput % "{TEXT}" . "http://ouo.io/qs/16EB70rI?s=" . Clipboard
Clipboard := "http://ouo.io/qs/16EB70rI?s=" . Clipboard
Return
}

keyFunc_OpenAI(){ ;定义一个函数，函数名为keyFunc_OpenAI
  global ;声明全局变量
  selText:=getSelText() ;获取选中的文本
  if(selText) ;如果选中的文本不为空，则调用OpenAI_Cap函数
  {
    OpenAI_Cap(selText) ;调用OpenAI_Cap函数
  }
  else ;如果选中的文本为空
  {
      ClipboardOld:=ClipboardAll ;保存剪贴板内容
      Clipboard:="" ;清空剪贴板内容
      SendInput, ^{A}
      sleep, 50 
      SendInput, ^{insert}  ;模拟按键：Ctrl+Up移到段落开头，然后Ctrl+Shift+Down选中整个段落，最后Ctrl+Insert复制选中内容
      ClipWait, 1 ;增加等待时间到1秒
      selText:=Clipboard 
      
      ; 检查是否成功获取到文本
      if (selText = "") {
          MsgBox, 16, Error , Failed to get context.
          Clipboard:=ClipboardOld ;将剪贴板内容恢复为之前保存的内容
          Return
      }
      
      ; 使用标准MsgBox格式，避免特殊字符问题
      ; MsgBox, 0, 文本内容, %selText%
      OpenAI_Cap(selText) ;调用OpenAI_Cap函数处理selText变量
      Clipboard:=ClipboardOld ;将剪贴板内容恢复为之前保存的内容
  }
  ;WinActivate, ahk_id %openaiGuiHwnd%
  SetTimer, setopenAIGuiActive, -400 ;设置一个定时器，每隔400毫秒执行一次setopenAIGuiActive函数
  Return 
}

; Obsidian 快速任务添加功能
keyFunc_addObsidianTask() {
    ; 弹出输入框，让用户输入任务内容
    InputBox, taskContent, 添加任务到 Obsidian, 请输入任务内容：
    
    ; 如果用户取消或者没有输入，则中止函数
    if ErrorLevel or (taskContent = "")
        return
    
    ; 获取当前日期和时间
    FormatTime, currentTime, , yyyy-MM-dd HH:mm
    
    ; 组合成最终需要添加到 data 参数的字符串
    ; 格式: > - [ ] 任务内容 来源:外部URL 记录于:YYYY-MM-DD HH:MM #待处理
    ; 注：`n 是 AutoHotkey 中换行符的表示方法
    dataString := "> - [ ] " . taskContent . " 来源:外部URL 记录于:" . currentTime . " #待处理" . "`n"
    
    ; 对字符串进行 URL 编码，以确保特殊字符能被正确处理
    encodedData := UrlEncode(dataString)
    
    ; 准备基础 URL，这是固定的部分
    baseUrl := "obsidian://advanced-uri?vault=newob&filepath=00-%E6%94%B6%E9%9B%86%E7%AE%B1%2F%E6%94%B6%E9%9B%86%E7%AE%B1%E4%B8%BB%E9%A1%B5.md&heading=%E2%86%93%E2%86%93%E2%86%93%E2%86%93%E2%86%93%E2%A6%93%20%E5%A4%96%E9%83%A8%E4%BB%BB%E5%8A%A1%E5%85%A5%E5%8F%A3%20%E2%86%93%E2%86%93%E2%86%93%E2%86%93%E2%86%93%E2%86%93&mode=append&data="
    
    ; 拼接成最终要执行的 URL
    finalUrl := baseUrl . encodedData
    
    ; 执行这个 URL，系统会自动调用 Obsidian 来处理这个链接
    Run, %finalUrl%
}

; URL 编码辅助函数
; 用于将字符串转换为 URL 安全的格式，例如将空格转换为 %20
UrlEncode(str) {
    VarSetCapacity(encoded, StrPut(str, "UTF-8") * 3)
    DllCall("urlmon\UrlEscapeA", "str", str, "str", encoded, "uint*", VarSetCapacity(encoded), "uint", 0)
    return encoded
}
