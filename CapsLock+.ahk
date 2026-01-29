#Requires AutoHotkey v2.0
#SingleInstance Force


full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin || RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

if FileExist("capslock+icon.ico")
    TraySetIcon("capslock+icon.ico")

SetStoreCapsLockMode(false)

global CLversion := "Version: 3.3.0.0 (V2 Refactor)"

global cClipboardAll := ""
global caClipboardAll := ""
global sClipboardAll := ""
global whichClipboardNow := 0
global allowRunOnClipboardChange := true

global keyset := Map() 
keyset["press_caps"] := "keyFunc_toggleCapsLock"

#Include "lib\JSON.ahk"
#Include "lib\lib_functions.ahk"
#Include "lib\lib_settings.ahk"
#Include "lib\lib_keysSet.ahk"
#Include "lib\lib_keysFunction.ahk"

#Include "language\lang_func.ahk"
#Include "language\Simplified_Chinese.ahk"
#Include "lib\lib_init.ahk"

; Stubs for missing modules
#Include "lib\lib_loadAnimation.ahk"
#Include "lib\lib_ydTrans.ahk"
#Include "lib\lib_jsEval.ahk"
#Include "lib\lib_clTab.ahk"
#Include "lib\lib_bindWins.ahk"
#Include "lib\lib_clQ.ahk"
#Include "lib\lib_mathBoard.ahk"
#Include "lib\lib_mouseSpeed.ahk"
#Include "lib\lib_winJump.ahk"
#Include "lib\lib_winTransparent.ahk"


; User Extensions (Must be V2 compatible)
#Include "*i userAHK\main.ahk"


SetTimer(initAll, -400)

global clState := 0      
global clUsed := 0       
global ctrlZ := 0        

; GUI Globals (Q-Search etc)
global GuiHwnd := ""
global LV_show_Hwnd := ""
global editHwnd := ""   
global CLStats := ""
global qbarPathFuture := ""
global LVlistsType := 0


; Stubs removed, functions now in lib_loadAnimation.ahk
; mouseSpeedInit removed, now in lib_mouseSpeed.ahk
isCapsLockDown(*) {
    return clState
}

initCapsKeys() {
    global keyset
    
    ; Clear existing context to be safe (though this is initial run)
    HotIf isCapsLockDown
    
    for keyName, funcName in keyset {
        ; keyName e.g. "caps_a" or "caps_lalt_a"
        ; We only care about "caps_x" (single key) for now? 
        ; V1 logic implies CapsLock + A -> keyFunc...
        
        ; Parse the key part. 
        ; If starts with "caps_lalt_", it's Caps + LAlt + Key. 
        ; If starts with "caps_", it's Caps + Key.
        
        realKey := ""
        if (SubStr(keyName, 1, 10) == "caps_lalt_") {
            prefix := "!"
            suffix := SubStr(keyName, 11)
        }
        else if (SubStr(keyName, 1, 10) == "caps_lwin_") {
            prefix := "#"
            suffix := SubStr(keyName, 11)
        }
        else if (SubStr(keyName, 1, 5) == "caps_") {
            prefix := ""
            suffix := SubStr(keyName, 6)
        }
        else {
            continue
        }

        ; Map special names to symbols
        if (suffix == "semicolon") 
            suffix := ";"
        else if (suffix == "quote")
            suffix := "'"
        else if (suffix == "comma")
            suffix := ","
        else if (suffix == "dot")
            suffix := "."
        else if (suffix == "slash")
            suffix := "/"
        else if (suffix == "leftSquareBracket")
            suffix := "["
        else if (suffix == "rightSquareBracket")
            suffix := "]"
        else if (suffix == "equal")
            suffix := "="
        else if (suffix == "minus")
            suffix := "-"
        else if (suffix == "backquote")
            suffix := "``"

        finalKey := prefix . suffix
        try Hotkey(finalKey, keyDispatcher) 
    }
    
    HotIf ; Turn off context
}

keyDispatcher(ThisHotkey) {
    global keyset
    ; ThisHotkey could be "a", "!", "Up", etc. 
    ; We need to reverse map it to "caps_..." keys.
    ; Or constructing the key name from ThisHotkey.
    
    ; Handle modifiers
    prefix := "caps_"
    
    cleanKey := ThisHotkey
    if (SubStr(cleanKey, 1, 1) == "!") {
        prefix := "caps_lalt_"
        cleanKey := SubStr(cleanKey, 2)
    }
    else if (SubStr(cleanKey, 1, 1) == "#") {
        prefix := "caps_lwin_"
        cleanKey := SubStr(cleanKey, 2)
    }
    else if (SubStr(cleanKey, 1, 1) == "+") {
        ; Shift? Not handled in loop above yet.
    }
    
    ; Reverse map symbols
    if (cleanKey == ";") 
        cleanKey := "semicolon"
    else if (cleanKey == "'")
        cleanKey := "quote"
    else if (cleanKey == ",")
        cleanKey := "comma"
    else if (cleanKey == ".")
        cleanKey := "dot"
    else if (cleanKey == "/")
        cleanKey := "slash"
    else if (cleanKey == "[")
        cleanKey := "leftSquareBracket"
    else if (cleanKey == "]")
        cleanKey := "rightSquareBracket"
    else if (cleanKey == "=")
        cleanKey := "equal"
    else if (cleanKey == "-")
        cleanKey := "minus"
    else if (cleanKey == "``")
        cleanKey := "backquote"
        
    lookupKey := prefix . cleanKey
    
    ; DEBUG OUTPUT
    ; ToolTip("Triggered: " . ThisHotkey . "`nLookup: " . lookupKey . "`nHasKey: " . keyset.Has(lookupKey))
    
    if (keyset.Has(lookupKey)) {
        global clUsed
        clUsed := 1 ; Mark CapsLock as used effectively
        funcName := keyset[lookupKey]
        ; ToolTip("Dispatcher calling: " . funcName)
        try {
             runFunc(funcName)
        } catch Error as e {
             MsgBox("Error calling " . funcName . ": " . e.Message)
        }
    } else {
        ; ToolTip("Key not found in keyset: " . lookupKey)
    }

}

*CapsLock::
{
    ; ToolTip("CapsLock Down")
    global clState, clUsed, ctrlZ
    
    clState := 1
    clUsed := 0
    ctrlZ := 1
    
    SetTimer(setCapsLockTimeout, -300) 
    SetTimer(changeMouseSpeed, 50) 
    
    KeyWait("CapsLock")
    
    if (IsSet(winTapedX) && winTapedX != -1)
        try winsSort(winTapedX)
        
    clState := 0
    SetTimer(changeMouseSpeed, 0)
    ; ToolTip("CapsLock Up. Used: " . clUsed)
    
    if (clUsed == 0) 
    {
        if (keyset.Has("press_caps"))
        {
            try {
                runFunc(keyset["press_caps"])
            }
        }
        else
        {
             keyFunc_toggleCapsLock()
        }
    }
    
    clUsed := 0
}

setCapsLockTimeout() {
    global clUsed
    clUsed := 1 
}

; mouseSpeed stubs removed - now in lib_mouseSpeed.ahk
OnClipboardChange_Func(Type) {
    global allowRunOnClipboardChange, clState, CLSets, whichClipboardNow
    
    if (allowRunOnClipboardChange && !clState && CLSets.Has("Global") && CLSets["Global"].Has("allowClipboard") && CLSets["Global"]["allowClipboard"] != "0")
    {
        try {
            clipSaver("s")
        } catch {
             Sleep(100)
             try {
                clipSaver("s")
             }
        }
        whichClipboardNow := 0
    }
    allowRunOnClipboardChange := true
}
OnClipboardChange(OnClipboardChange_Func)
