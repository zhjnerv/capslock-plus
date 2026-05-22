;~ 初始化段，也就是自动运行段，所有需要自动运行的代码放这里，然后放到程序最开头
; SetTimer(initAll, -400) 
; Moved to CapsLock+.ahk or called here? 
; In V2, better to call it from main script after includes.

initAll() {
    Suspend(true) ;挂起所有热键
    
    loadingAnimation := "1"
    try {
        loadingAnimation := IniRead("CapsLock+settings.ini", "Global", "loadingAnimation", "1")
    } catch {
        loadingAnimation := "1"
    }

    if(loadingAnimation != "0")
    {
        try showLoading() ; In lib_loadAnimation.ahk
    }
    
    ; Load language settings first to initialize global variables like lang_settingsDemoFileContent_1
    language_Simplified_Chinese() 
    
    settingsInit() ;初始化设置
    initCapsKeys() ; 初始化热键绑定

    ;------------  language -----------

    try {
        bindWinsInit()
    } catch {
    }

    try {
        jsEval_init()
    } catch {
    }

    try {
        SetTimer(youdaoApiInit, 1) ;初始化翻译api
    } catch {
    }

    getDefaultBrowser()

    global needInitQ := 1 ;+q初始化标志位
    try {
        ; CLq() ;初始化+q - Disabled to prevent auto-show on startup
    } catch {
    }

    try {
        SetTimer(mouseSpeedInit, 1)
    } catch {
    }

    Suspend(false)

    if(loadingAnimation != "0")
    {
        try {
            hideLoading()
        } catch {
        }
    }
}

getDefaultBrowser() {
    global defaultBrowser := ""
    ;获取默认浏览器图标，QWeb的listview用
    try {
        defaultBrowser := RegRead("HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice", "ProgId")
        defaultBrowser := RegRead("HKLM\SOFTWARE\Classes\" . defaultBrowser . "\shell\open\command")
        RegExMatch(defaultBrowser, '[a-zA-Z]:\\[\s\S]*\.exe', &defaultBrowser)
    }
    ; MsgBox, % defaultBrowser
    if(defaultBrowser == "")
        defaultBrowser := "C:\Program Files (x86)\Internet Explorer\IExplore.exe"
}
