/*
有道翻译
*/

#Include lib_json.ahk   	;引入json解析文件

global TransEdit,transEditHwnd,transGuiHwnd, NativeString

youdaoApiInit:
global youdaoApiString:="http://deepl.zhjwork.online/translate"



;  #Include *i youdaoApiKey.ahk





setTransGuiActive:
WinActivate, ahk_id %transGuiHwnd%
return

ydTranslate(ss)
{
transStart:
    ;  if(StrLen(ss) >= 2000)
    ;  {
    ;      MsgBox, , , 文本过长，请重新选择。, 1
    ;      return 
    ;  }
	ss:=RegExReplace(ss, "\s", " ") ;把所有空白符换成空格，因为如果有回车符的话，json转换时会出错
	
	;~ global 
	
	NativeString:=Trim(ss)

transGui:
;~ WinClose, 有道翻译
MsgBoxStr:=NativeString?lang_yd_translating:""

DetectHiddenWindows, On ;可以检测到隐藏窗口
WinGet, ifGuiExistButHide, Count, ahk_id %transGuiHwnd%
if(ifGuiExistButHide)
{
	ControlSetText, , %MsgBoxStr%, ahk_id %transEditHwnd%
	ControlFocus, , ahk_id %transEditHwnd%
	WinShow, ahk_id %transGuiHwnd%
}
else ;IfWinNotExist,  ahk_id %transGuiHwnd% ;有道翻译
{
	;~ MsgBox, 0
	
	Gui, new, +HwndtransGuiHwnd , %lang_yd_name%
	Gui, +AlwaysOnTop -Border +Caption -Disabled -LastFound -MaximizeBox -OwnDialogs -Resize +SysMenu -Theme -ToolWindow
	Gui, Font, s10 w400, Microsoft YaHei UI ;设置字体
	Gui, Font, s10 w400, 微软雅黑
	gui, Add, Button, x-40 y-40 Default, OK  
	
	Gui, Add, Edit, x-2 y0 w504 h405 vTransEdit HwndtransEditHwnd -WantReturn -VScroll , %MsgBoxStr%
	Gui, Color, ffffff, fefefe
	Gui, +LastFound
	WinSet, TransColor, ffffff 210
	;~ MsgBox, 1
	Gui, Show, Center w500 h402, %lang_yd_name%
	ControlFocus, , ahk_id %transEditHwnd%
	SetTimer, setTransActive, 50
}
;~ DetectHiddenWindows, On ;可以检测到隐藏窗口

if(NativeString) ;如果传入的字符串非空则翻译
{
	;~ MsgBox, 2
	SetTimer, ydApi, -1
	return
}

Return


ydApi:


sendStr:=youdaoApiString

; 创建一个空对象
data := {}

; 添加属性
data["text"] := NativeString
data["source_lang"] := "EN"
data["target_lang"] := "ZH"

; 将 JSON 对象转换为字符串
json_data := JSON.Dump(data)

whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")

whr.Open("POST", sendStr)

whr.setRequestHeader("Content-Type", "application/json")

whr.Send(json_data)


afterSend:
responseStr := whr.ResponseText


; transJson:=JSON_from(responseStr) 
transJson:=JSON.Load(responseStr)
MsgBox, 输出结果：%transJson%
;MsgBox, %JSON.to(transJson)% ;弹出整个翻译结果的json，测试用
; 检查返回的状态码

if (transJson.code = 200) {
    ; 如果状态码是200，表示翻译成功
    primaryTranslation := transJson.data ; 主要翻译结果
    alternativeTranslations := transJson.alternatives ; 次要翻译结果列表
    ; 构建要显示的消息字符串
    MsgBoxStr := "主要翻译结果：" . primaryTranslation
    if (alternativeTranslations.MaxIndex() > 0) {
        MsgBoxStr .= "`n`n次要翻译结果："
        Loop, % alternativeTranslations.MaxIndex() {
            MsgBoxStr .= "`n" . alternativeTranslations[A_Index]
        }
    }
} else {
    ; 如果状态码不是200，表示翻译失败，显示错误信息
    MsgBoxStr := "错误：" . transJson.code
}
MsgBox, 翻译结果：%MsgBoxStr%


; 初始化消息字符串
MsgBoxStr := NativeString . "`t"  ; 原单词

; 添加主要翻译结果
MsgBoxStr .= " " . primaryTranslation . "`n`n"

; 检查alternatives是否存在并且不为空
if (ObjHasKey(transJson, "alternatives") && transJson.alternatives.Length > 0) {
    ; 添加次要翻译结果
    MsgBoxStr .= "次要翻译结果：`n"
    Loop % transJson.alternatives.Length {
        MsgBoxStr .= transJson.alternatives[A_Index] . "`n"
    }
}

; 显示消息框
MsgBox, 翻译结果：%MsgBoxStr%
;~ MsgBox, % MsgBoxStr




setTransText:
ControlSetText, , %MsgBoxStr%, ahk_id %transEditHwnd%
ControlFocus, , ahk_id %transEditHwnd%
SetTimer, setTransActive, 50
return 
;================拼MsgBox显示的内容

ButtonOK:
Gui, Submit, NoHide

TransEdit:=RegExReplace(TransEdit, "\s", " ") ;把所有空白符换成空格，因为如果有回车符的话，json转换时会出错
NativeString:=Trim(TransEdit)
;~ goto, ydApi
goto, transGui

return

}


;确保激活
setTransActive:
IfWinExist, ahk_id %transGuiHwnd%
{
    SetTimer, ,Off
    WinActivate, ahk_id %transGuiHwnd%
}
return