English | [中文](readme.md)

---

## Modified Introduction
Since the original translation backend was no longer usable, I replaced it with a free DeepL-compatible flow with help from Gemini, and also deployed my own [DeepLX Powerful DeepL Translation API](https://deeplx.owo.network).

- I cannot provide the same configuration selection flow as the original author. The project is preconfigured to work with my self-hosted [DeepLX](https://zhjwork.online/2024/04/30/deeplx%e7%99%bd%e5%ab%96%e6%9c%8d%e5%8a%a1/) service out of the box.
- I also updated the translation window so long paragraphs can be viewed with a scrollbar.

**Thanks again to Google Gemini and DeepLX for making this possible.**

---

## Current Status
This repository now targets **AutoHotkey v2** as the only supported runtime. AutoHotkey v1 is no longer the baseline.

- The entry script [CapsLock+.ahk](CapsLock+.ahk) declares `#Requires AutoHotkey v2.0`
- The main modules have already been migrated to AHK v2 syntax
- The documentation below reflects the current codebase
- The previous AHK v1-era README content is preserved at the end for reference

## Overview
CapsLock+ turns `CapsLock` into a general-purpose productivity modifier for Windows. The current design centers on:

- `CapsLock + letters/symbols/F keys` for editing, selection, deletion, clipboard, and window actions
- `CapsLock + Q` for Qbar, which handles search, web shortcuts, app/file launching, and quick records
- `CapsLock + Tab` for TabScript, including text replacement and inline calculation
- `CapsLock + F2/F3/F4/F6` for calculator, translation, transparency, and always-on-top controls
- [userAHK/main.ahk](userAHK/main.ahk) as the user extension entry point

## Main Features
- Text editing: cursor movement, word movement, selection, line/page navigation, delete-to-start/end behavior
- Dual independent clipboards: default mappings for `CapsLock + C/X/V` and `CapsLock + LAlt + C/X/V`
- Qbar: search, open files, open URLs, record strings, and prefill from selected text, URLs, or Explorer selections
- TabScript: string replacement, quick snippets, inline expression evaluation, and JavaScript-assisted calculations
- Translation: DeepLX-based translation with automatic Chinese/English direction handling
- Window tools: binding, pinning, transparency, and jump/navigation helpers
- Mouse tools: temporary system mouse speed switching with wheel-based adjustment
- Math Board: a standalone calculation window
- User extensions: included OpenAI text processing and Obsidian task append examples

## Requirements and Startup
1. Install [AutoHotkey v2.x](https://www.autohotkey.com/).
2. Clone or download this repository.
3. Run [CapsLock+.ahk](CapsLock+.ahk).

On first launch, the program will:

- request administrator privileges
- generate [CapsLock+settings.ini](CapsLock+settings.ini) and the read-only sample [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini)
- initialize language resources, hotkeys, window bindings, translation, and the JavaScript evaluation environment

## Common Default Hotkeys
This section lists the most commonly used defaults from the current codebase. For the full mapping, refer to `[Keys]` in [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini) and [lib/lib_keysSet.ahk](lib/lib_keysSet.ahk).

| Hotkey | Action |
|:---|:---|
| `Tap CapsLock` | Toggle Caps Lock |
| `CapsLock + Q` | Open Qbar |
| `CapsLock + Tab` | Run TabScript / inline calculation |
| `CapsLock + F2` | Open Math Board |
| `CapsLock + F3` | Translate selected text or current content |
| `CapsLock + F4` | Enter window transparency mode |
| `CapsLock + F5` | Reload the script |
| `CapsLock + F6` | Toggle always-on-top for the active window |
| `CapsLock + F12` | Toggle the independent clipboard feature |
| `Double-tap CapsLock` | Open a terminal in the current Explorer / Desktop / Total Commander directory and bring it to the front |
| `CapsLock + C / X / V` | Copy / cut / paste using clipboard slot 1 |
| `CapsLock + LAlt + C / X / V` | Copy / cut / paste using clipboard slot 2 |
| `CapsLock + 1..0` | Activate a bound window |
| `CapsLock + LAlt + 1..0` | Bind the current window to that number |
| `CapsLock + LAlt + WheelUp/WheelDown` | Increase / decrease target mouse speed |

### Editing Layout
The current default layout still keeps the core CapsLock+ editing scheme intact. Typical examples:

- `CapsLock + A/S/D/F`: move left by word / left / down / right
- `CapsLock + E`: move up
- `CapsLock + H/J/K/L`: selection movement
- `CapsLock + W/R`: backspace / delete
- `CapsLock + P/;`: home / end
- `CapsLock + [ / /`: delete to line start / delete to line end

## Feature Notes
### 1. Qbar
`CapsLock + Q` opens Qbar. The implementation is in [lib/lib_clQ.ahk](lib/lib_clQ.ahk).

Qbar currently supports:

- search commands from `[QSearch]`
- app/file/folder launch entries from `[QRun]`
- URL shortcuts from `[QWeb]`
- prefilling from selected text or Explorer selections
- direct settings insertion using the `xxx -> yyy` pattern

### 2. TabScript
`CapsLock + Tab` is implemented in [lib/lib_clTab.ahk](lib/lib_clTab.ahk).

It tries the following in order:

- match a replacement from `[TabHotString]`
- otherwise evaluate nearby text as an expression through the JavaScript engine

The JavaScript runtime comes from [lib/lib_jsEval.ahk](lib/lib_jsEval.ahk), and can be extended through files in `loadScript/`.

### 3. Translation
`CapsLock + F3` is implemented in [lib/lib_ydTrans.ahk](lib/lib_ydTrans.ahk).

In the current repository, translation works like this:

- it uses a DeepLX endpoint instead of the old Youdao-free-api flow
- it translates mostly-Chinese text to English, and other text to Chinese
- it copies the primary translation result to the clipboard
- it shows the result in a scrollable standalone window

### 4. Window Controls
- `CapsLock + F6`: toggle always-on-top for the active window
- `CapsLock + F4`: enter transparency adjustment mode; use the wheel to change opacity, and short tap behavior toggles the default transparent state
- `CapsLock + 1..0` / `CapsLock + LAlt + 1..0`: bind and activate windows
- double-tap `CapsLock`: open a terminal in the current Explorer, Desktop, or active Total Commander panel directory and bring it to the front; the launched program can be configured through `[Global].terminalProgram` as `terminal`, `pwsh`, or `cmd`

Relevant implementations are in [lib/lib_keysFunction.ahk](lib/lib_keysFunction.ahk), [lib/lib_winTransparent.ahk](lib/lib_winTransparent.ahk), and [lib/lib_bindWins.ahk](lib/lib_bindWins.ahk).

### 5. Mouse Speed
The implementation lives in [lib/lib_mouseSpeed.ahk](lib/lib_mouseSpeed.ahk).

The current behavior is:

- holding `CapsLock + LAlt` temporarily switches the Windows system mouse speed to the configured value
- `CapsLock + LAlt + WheelUp/WheelDown` changes that configured value in the `1..20` range
- releasing `LAlt` or `CapsLock` restores the original system speed

## Configuration
The program reads [CapsLock+settings.ini](CapsLock+settings.ini). The full sample file is [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini).

The current code recognizes these main sections:

| Section | Purpose |
|:---|:---|
| `[Global]` | Global options such as autostart, hotkey scheme, script loading, mouse speed, terminal type, and clipboard toggle |
| `[QSearch]` | Qbar search commands |
| `[QRun]` | Qbar entries for files, folders, and programs |
| `[QWeb]` | Qbar web shortcuts |
| `[TabHotString]` | TabScript string replacements |
| `[QStyle]` | Qbar appearance |
| `[TTranslate]` | Translation settings; the current code mainly uses `endpoint` |
| `[AI]` | OpenAI extension settings |
| `[Obsidian]` | Obsidian task append settings |
| `[Keys]` | Hotkey mappings |

### Recommended Additional Config Example
The current code already supports `AI` and `Obsidian`, and the terminal choice can also be overridden through config. You can add them like this:

```ini
[Global]
terminalProgram=terminal

[TTranslate]
endpoint=http://127.0.0.1:1188/translate

[AI]
OpenAI_key=sk-xxxx
base_url=https://api.openai.com/
model=gpt-4o-mini
temperature=0.7
top_p=1

[Obsidian]
vault=YourVaultName
file=Inbox.md
heading=Tasks
tag=inbox
```

`terminalProgram` supports:

- `terminal`: prefer Windows Terminal and fall back to PowerShell if unavailable
- `pwsh`: use `pwsh`, falling back to Windows PowerShell if needed
- `cmd`: use Command Prompt

## Custom Hotkeys and Extensions
The recommended place for custom logic is [userAHK/main.ahk](userAHK/main.ahk).

Basic flow:

1. Create a function whose name starts with `keyFunc_` in [userAHK/main.ahk](userAHK/main.ahk).
2. Map a key to it under `[Keys]` in [CapsLock+settings.ini](CapsLock+settings.ini).
3. Press `CapsLock + F5` to reload the script.

Example:

```ahk
keyFunc_listary() {
    selText := getSelText()
    Send("#f")
    if WinWait("ahk_exe Listary.exe", , 0.5) && selText {
        SendText("gg " . selText)
        Send("{Home}")
    }
}
```

Then add this to [CapsLock+settings.ini](CapsLock+settings.ini):

```ini
[Keys]
caps_q=keyFunc_listary()
```

## Project Structure and File Notes
### Root

| File / Directory | Description |
|:---|:---|
| [CapsLock+.ahk](CapsLock+.ahk) | Main entry point. Handles elevation, module loading, global state, and the main CapsLock behavior |
| [CapsLock+settings.ini](CapsLock+settings.ini) | Actual user settings file generated at startup |
| [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini) | Read-only sample configuration and reference guide |
| [CapsLock+winsInfosRecorder.ini](CapsLock+winsInfosRecorder.ini) | Persistent storage for window binding data |
| [language](language) | Language resources and generated config templates |
| [lib](lib) | Main feature modules |
| [loadScript](loadScript) | JavaScript extension examples for TabScript and calculation |
| [prompt](prompt) | Prompt templates used by the AI extension |
| [userAHK](userAHK) | User extension entry point and extra modules |
| [readme.md](readme.md) | Chinese README |
| [readme_en.md](readme_en.md) | English README |

### `language/`

| File | Description |
|:---|:---|
| [language/lang_func.ahk](language/lang_func.ahk) | Language helper functions |
| [language/Simplified_Chinese.ahk](language/Simplified_Chinese.ahk) | Simplified Chinese strings and config templates |
| [language/English.ahk](language/English.ahk) | English strings and config templates |

### `lib/`

| File | Description |
|:---|:---|
| [lib/JSON.ahk](lib/JSON.ahk) | JSON parsing and serialization library |
| [lib/lib_init.ahk](lib/lib_init.ahk) | Startup initialization flow that wires settings, language, Qbar, translation, mouse speed, and more |
| [lib/lib_settings.ahk](lib/lib_settings.ahk) | Reads, watches, and writes `CapsLock+settings.ini` |
| [lib/lib_functions.ahk](lib/lib_functions.ahk) | Shared utility functions such as selected text capture, URL encoding, and message display |
| [lib/lib_keysSet.ahk](lib/lib_keysSet.ahk) | Default hotkey layout definitions |
| [lib/lib_keysFunction.ahk](lib/lib_keysFunction.ahk) | Most `keyFunc_*` implementations |
| [lib/lib_clQ.ahk](lib/lib_clQ.ahk) | Qbar search and quick-launch module |
| [lib/lib_clTab.ahk](lib/lib_clTab.ahk) | TabScript and inline calculation entry point |
| [lib/lib_jsEval.ahk](lib/lib_jsEval.ahk) | IE/HTMLfile-based JavaScript execution environment |
| [lib/lib_mathBoard.ahk](lib/lib_mathBoard.ahk) | Math Board GUI |
| [lib/lib_mouseSpeed.ahk](lib/lib_mouseSpeed.ahk) | Temporary mouse speed switching and adjustment |
| [lib/lib_bindWins.ahk](lib/lib_bindWins.ahk) | Window binding, activation, and persistence |
| [lib/lib_winTransparent.ahk](lib/lib_winTransparent.ahk) | Window transparency controls |
| [lib/lib_winJump.ahk](lib/lib_winJump.ahk) | Window jump/navigation helper |
| [lib/lib_loadAnimation.ahk](lib/lib_loadAnimation.ahk) | Startup loading animation |
| [lib/lib_ydTrans.ahk](lib/lib_ydTrans.ahk) | Current DeepLX translation implementation; the filename keeps the historical name |
| [lib/sha256.ahk](lib/sha256.ahk) | SHA-256 helper implementation |
| [lib/lib_json_v1.bak](lib/lib_json_v1.bak) | Historical backup file |

### `userAHK/`

| File | Description |
|:---|:---|
| [userAHK/main.ahk](userAHK/main.ahk) | Main user extension entry point |
| [userAHK/OpenAI.ahk](userAHK/OpenAI.ahk) | OpenAI-based text rewrite, translation, polishing, and related actions |
| [userAHK/addtodo.ahk](userAHK/addtodo.ahk) | Adds tasks to Obsidian through `obsidian://advanced-uri` |
| [userAHK/demo.ahk](userAHK/demo.ahk) | Demo extension file |

### `prompt/`

| File | Description |
|:---|:---|
| [prompt/prompt.txt](prompt/prompt.txt) | Default prompt |
| [prompt/rewrite_prompt.txt](prompt/rewrite_prompt.txt) | Rewrite prompt |
| [prompt/translate_prompt.txt](prompt/translate_prompt.txt) | Translation prompt |
| [prompt/polish_prompt.txt](prompt/polish_prompt.txt) | Polishing prompt |
| [prompt/prompt-1.txt](prompt/prompt-1.txt) | Historical prompt file |
| [prompt/prompt-2.txt](prompt/prompt-2.txt) | Historical prompt file |
| [prompt/prompt-3.txt](prompt/prompt-3.txt) | Historical prompt file |

### `loadScript/`

| File | Description |
|:---|:---|
| [loadScript/debug.html](loadScript/debug.html) | JavaScript debug page |
| [loadScript/scriptDemo.js](loadScript/scriptDemo.js) | Example custom calculation script |

## Known Notes
- The runtime baseline is now AHK v2, but some filenames and comments still keep older naming conventions from the v1 era
- Parts of [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini) still contain historical notes and do not perfectly match the current implementation
- When documentation and code differ, the current source code should be treated as authoritative

## Historical Notes
The content below is preserved from the older README and mostly reflects the AHK v1 era. It remains here as an archive.

### Legacy Branch Notes
master branch: v3.0+

v2 branch: v2.x

[Docs](https://capslox.com/capslock-plus/en.html)

### Legacy Runtime Instructions
1. Download and install [AutoHotkey v2.x](https://www.autohotkey.com/)
2. Clone the CapsLock+ source code
3. Run `CapsLock+.ahk`

> The current entry script uses `#Requires AutoHotkey v2.0`, so AutoHotkey v1.1 is no longer supported in this repository.

### Legacy Custom Hotkey Notes
1. There is a key function `keyFunc_example2` in `demo.ahk`.
2. Add below setting under the `[Keys]` section in `CapsLock+settings.ini`:
   `caps_f7=keyFunc_example2`
3. Save, reload Capslock+ (`CapsLock+F5`)
4. Press `CapsLock+F7` to invoke the function

To avoid calling internal functions by mistake, custom key functions were historically required to start with `keyfunc_`.

### Legacy Example: Replace Capslock+Q with Listary
Listary is a good app launcher, and the original example aimed to add two features:

1. Activate Listary with `CapsLock+Q`
2. Fill the selected text into the popup input box

It was described like this:

1. Copy the following code to `/userAHK/main.ahk`:

```ahk
keyfunc_listary(){
    ; Get the selected text
    selText:=getSelText()

    ; Send win+F (the default hotkey of Listary) to activate Listary
    sendinput, #{f}

    ; Wait until Listary is activated
    winwait, ahk_exe Listary.exe, , 0.5

    ; If there is any selected text
    if(selText){
        ; Add "gg " before the selected text to google
        selText:="gg " . selText

        ; Fill the text, and press `home` key to move the cursor to the beginning,
        ; in order to add other keywords if you need.
        sendinput, %selText%{home}
    }
}
```

2. Add a setting `caps_q=keyfunc_listary()` under `[Keys]` in `CapsLock+settings.ini`, save, press `CapsLock+F5` to reload, done.

### Legacy File Notes
`CapsLock+.ahk` is the entry file, and library files are in `/lib`:

| Filename | Description |
|:---|:---|
| `lib_bindWins.ahk` | Window binding |
| `lib_clQ.ahk` | qbar |
| `lib_clTab.ahk` | CapsLock+Tab |
| `lib_functions.ahk` | Some utils |
| `lib_init.ahk` | Program initialization |
| `lib_jsEval.ahk` | Calculation based on the IE engine, used by Math Board and CapsLock+Tab |
| `lib_json.ahk` | json library |
| `lib_keysFunction.ahk` | All key functions |
| `lib_keysSet.ahk` | Hotkey layouts |
| `lib_loadAnimation.ahk` | Loading animation when the program starts |
| `lib_mathBoard.ahk` | Math Board |
| `lib_mouseSpeed.ahk` | Mouse speed modification |
| `lib_settings.ahk` | Load settings from CapsLock+settings.ini |
| `lib_ydTrans.ahk` | Youdao Translation |
