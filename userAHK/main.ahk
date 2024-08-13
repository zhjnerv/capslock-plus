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

keyFunc_OpenAI(){
  global
  selText:=getSelText()
  if(selText)
  {
    OpenAI_Cap(selText)
  }
  else
  {
      ClipboardOld:=ClipboardAll
      Clipboard:=""
      SendInput, ^{Left}^+{Right}^{insert}
      ClipWait, 0.05
      selText:=Clipboard
      OpenAI_Cap(selText)
      Clipboard:=ClipboardOld
  }
  ;WinActivate, ahk_id %openaiGuiHwnd%
  SetTimer, setopenAIGuiActive, -400
  Return
}