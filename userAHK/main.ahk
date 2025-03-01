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
          MsgBox, nonono
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