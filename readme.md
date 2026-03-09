中文 | [English](readme_en.md)

---

## 修改简介
由于原有的翻译接口(有道翻译)一直无法使用，在Gemini的帮助下修改了翻译接口为白嫖(DeepL)接口，顺带自己搭建了 [DeepLX Powerful DeepL Translation API](https://deeplx.owo.network)。

- 能力有限，无法像原作者一样给出对应的选择配置，文件已经内置好了我自己搭建的 [DeepLX](https://zhjwork.online/2024/04/30/deeplx%e7%99%bd%e5%ab%96%e6%9c%8d%e5%8a%a1/) 服务，直接使用即可。
- 同时修改了翻译窗口，对应长段落翻译增加了滚动条。

**再次感谢 Google Gemini 和 DeepLX 的无私奉献。**

---

## 项目现状
当前仓库已经以 **AutoHotkey v2** 为唯一运行基线，不再兼容 AutoHotkey v1。

- 入口脚本 [CapsLock+.ahk](CapsLock+.ahk) 使用 `#Requires AutoHotkey v2.0`
- 主体模块已经按 AHK v2 语法重构
- README 以下说明全部以当前仓库代码为准
- 旧版 README 中基于 AHK v1 的内容保留在文末，供历史参考

## 项目简介
CapsLock+ 是一个把 `CapsLock` 改造成高频效率键的桌面增强工具，核心思路是：

- 用 `CapsLock + 字母/符号/F 键` 承担光标移动、选择、删除、剪贴板、窗口控制等常用操作
- 用 `CapsLock + Q` 打开 Qbar，完成搜索、网页打开、文件启动和字符串记录
- 用 `CapsLock + Tab` 触发 TabScript，进行文本替换或行内计算
- 通过 `CapsLock + F2/F3/F4/F6` 等组合提供计算、翻译、窗口透明、窗口置顶等能力
- 允许通过 [userAHK/main.ahk](userAHK/main.ahk) 自定义扩展

## 当前主要能力
- 文本编辑：光标移动、按词移动、整段选择、行首行尾跳转、删除到行首/行尾、页面级跳转
- 独立剪贴板：内置两套独立剪贴板，默认对应 `CapsLock + C/X/V` 和 `CapsLock + LAlt + C/X/V`
- Qbar：快速搜索、启动文件、打开网页、记录热字符串，支持选中文本/路径/网址直接带入
- TabScript：文本替换、快捷短语、行内表达式计算、JavaScript 扩展计算
- 翻译：当前实现基于 DeepLX，自动判断中英方向并显示结果窗口
- 窗口控制：窗口绑定、窗口置顶、窗口透明、窗口跳转
- 鼠标控制：`CapsLock + LAlt` 临时切换系统鼠标速度，`CapsLock + LAlt + 滚轮` 调整速度值
- 计算板：独立数学输入窗口，支持快速计算
- 用户扩展：已内置 OpenAI 文本处理和 Obsidian 任务追加示例

## 环境与运行
1. 安装 [AutoHotkey v2.x](https://www.autohotkey.com/)。
2. 克隆或下载本仓库。
3. 运行 [CapsLock+.ahk](CapsLock+.ahk)。

首次运行时，程序会：

- 请求管理员权限
- 自动生成 [CapsLock+settings.ini](CapsLock+settings.ini) 和只读示例 [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini)
- 初始化语言、热键、窗口绑定、翻译和 JavaScript 计算环境

## 常用默认热键
下面只列当前代码里最常用、最稳定的一组默认组合。完整映射以 [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini) 的 `[Keys]` 和 [lib/lib_keysSet.ahk](lib/lib_keysSet.ahk) 为准。

| 热键 | 作用 |
|:---|:---|
| `单击 CapsLock` | 切换大小写 |
| `CapsLock + Q` | 打开 Qbar |
| `CapsLock + Tab` | 执行 TabScript / 行内计算 |
| `CapsLock + F2` | 打开计算板 |
| `CapsLock + F3` | 翻译选中文本或当前内容 |
| `CapsLock + F4` | 窗口透明控制模式 |
| `CapsLock + F5` | 重载脚本 |
| `CapsLock + F6` | 切换当前窗口置顶 |
| `CapsLock + F12` | 切换独立剪贴板功能开关 |
| `连按两下 CapsLock` | 在当前资源管理器 / 桌面 / Total Commander 目录打开终端并切到前台 |
| `CapsLock + C / X / V` | 独立剪贴板 1 的复制 / 剪切 / 粘贴 |
| `CapsLock + LAlt + C / X / V` | 独立剪贴板 2 的复制 / 剪切 / 粘贴 |
| `CapsLock + 1..0` | 激活已绑定窗口 |
| `CapsLock + LAlt + 1..0` | 绑定当前窗口到对应数字 |
| `CapsLock + LAlt + 滚轮上/下` | 增加 / 减少目标鼠标速度 |

### 文本编辑布局
当前默认布局仍然保留了 CapsLock+ 的核心编辑手感，典型组合如下：

- `CapsLock + A/S/D/F`：按词左移 / 左移 / 下移 / 右移
- `CapsLock + E`：上移
- `CapsLock + H/J/K/L`：向左 / 下 / 上 / 右选择
- `CapsLock + W/R`：退格 / 删除
- `CapsLock + P/;`：行首 / 行尾
- `CapsLock + [ / /`：删到行首 / 删到行尾

## 特色功能说明
### 1. Qbar
`CapsLock + Q` 打开 Qbar，对应实现位于 [lib/lib_clQ.ahk](lib/lib_clQ.ahk)。

Qbar 当前支持：

- 搜索指令，配置在 `[QSearch]`
- 快速打开文件、文件夹、程序，配置在 `[QRun]`
- 快速打开网址，配置在 `[QWeb]`
- 从选中文本、资源管理器选中路径中自动带入输入框
- 通过 `xxx -> yyy` 形式直接写入设置

### 2. TabScript
`CapsLock + Tab` 对应 [lib/lib_clTab.ahk](lib/lib_clTab.ahk)。

它会优先尝试：

- 命中 `[TabHotString]` 中的文本替换
- 否则把当前位置附近文本当作表达式交给 JavaScript 引擎计算

JavaScript 引擎由 [lib/lib_jsEval.ahk](lib/lib_jsEval.ahk) 提供，也支持通过 `loadScript/` 加载自定义脚本。

### 3. 翻译
`CapsLock + F3` 对应 [lib/lib_ydTrans.ahk](lib/lib_ydTrans.ahk)。

当前仓库实际行为是：

- 使用 DeepLX 接口，而不是旧版 README 中的有道免费接口
- 中文占比较高时翻译成英文，否则翻译成中文
- 自动把主译文复制到剪贴板
- 结果显示在可滚动的独立窗口中

### 4. 窗口控制
- `CapsLock + F6`：切换当前窗口置顶
- `CapsLock + F4`：进入透明度调整模式，配合滚轮增减透明度，短按可切换默认透明状态
- `CapsLock + 1..0` / `CapsLock + LAlt + 1..0`：窗口绑定与快速激活
- 连按两下 `CapsLock`：在当前资源管理器、桌面或 Total Commander 当前面板目录打开终端并切到前台；打开程序可通过 `[Global]` 中的 `terminalProgram` 配置为 `terminal`、`pwsh` 或 `cmd`

相关实现分别在 [lib/lib_keysFunction.ahk](lib/lib_keysFunction.ahk)、[lib/lib_winTransparent.ahk](lib/lib_winTransparent.ahk) 和 [lib/lib_bindWins.ahk](lib/lib_bindWins.ahk)。

### 5. 鼠标速度
相关实现位于 [lib/lib_mouseSpeed.ahk](lib/lib_mouseSpeed.ahk)。

实际逻辑是：

- `CapsLock + LAlt` 按住时，临时把 Windows 系统鼠标速度切到配置值
- `CapsLock + LAlt + 滚轮上/下` 修改这个配置值，范围为 `1..20`
- 松开 `LAlt` 或 `CapsLock` 后恢复原系统鼠标速度

## 配置说明
程序会读取 [CapsLock+settings.ini](CapsLock+settings.ini)。完整示例在 [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini)。

当前代码识别的主要配置段如下：

| 段名 | 作用 |
|:---|:---|
| `[Global]` | 全局设置，例如开机自启、热键布局、脚本加载、鼠标速度、终端类型、剪贴板开关 |
| `[QSearch]` | Qbar 搜索指令 |
| `[QRun]` | Qbar 快速运行文件、程序、文件夹 |
| `[QWeb]` | Qbar 快速打开网页 |
| `[TabHotString]` | TabScript 字符串替换 |
| `[QStyle]` | Qbar 外观样式 |
| `[TTranslate]` | 翻译设置，当前代码主要使用 `endpoint` |
| `[AI]` | OpenAI 扩展设置 |
| `[Obsidian]` | Obsidian 任务追加扩展设置 |
| `[Keys]` | 热键映射 |

### 推荐的新增配置示例
当前代码里，`AI` 和 `Obsidian` 已经可用，终端类型也支持通过配置覆盖。可以按下面方式添加。

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
vault=你的仓库名
file=Inbox.md
heading=Tasks
tag=inbox
```

`terminalProgram` 支持以下值：

- `terminal`：优先使用 Windows Terminal，不可用时回退到 PowerShell
- `pwsh`：使用 `pwsh`，不可用时回退到 Windows PowerShell
- `cmd`：使用命令提示符

## 自定义热键与扩展
建议把自定义逻辑写在 [userAHK/main.ahk](userAHK/main.ahk)。

基本步骤：

1. 在 [userAHK/main.ahk](userAHK/main.ahk) 中编写一个以 `keyFunc_` 开头的函数。
2. 在 [CapsLock+settings.ini](CapsLock+settings.ini) 的 `[Keys]` 中把某个按键映射到它。
3. 按 `CapsLock + F5` 重载脚本。

示例：

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

然后在 [CapsLock+settings.ini](CapsLock+settings.ini) 中添加：

```ini
[Keys]
caps_q=keyFunc_listary()
```

## 项目结构与文件说明
### 根目录

| 文件 / 目录 | 说明 |
|:---|:---|
| [CapsLock+.ahk](CapsLock+.ahk) | 主入口，负责提权、载入模块、初始化全局状态和主热键 |
| [CapsLock+settings.ini](CapsLock+settings.ini) | 用户实际使用的配置文件，启动时自动生成 |
| [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini) | 配置样例，主要作为说明文档 |
| [CapsLock+winsInfosRecorder.ini](CapsLock+winsInfosRecorder.ini) | 窗口绑定信息持久化文件 |
| [language](language) | 语言字符串和配置模板 |
| [lib](lib) | 主功能模块 |
| [loadScript](loadScript) | JavaScript 扩展示例，供 TabScript / 计算使用 |
| [prompt](prompt) | AI 扩展使用的提示词模板 |
| [userAHK](userAHK) | 用户扩展入口和附加功能 |
| [readme.md](readme.md) | 中文说明文档 |
| [readme_en.md](readme_en.md) | 英文说明文档 |

### `language/`

| 文件 | 说明 |
|:---|:---|
| [language/lang_func.ahk](language/lang_func.ahk) | 语言切换辅助函数 |
| [language/Simplified_Chinese.ahk](language/Simplified_Chinese.ahk) | 简体中文字符串与默认配置模板 |
| [language/English.ahk](language/English.ahk) | 英文字符串与默认配置模板 |

### `lib/`

| 文件 | 说明 |
|:---|:---|
| [lib/JSON.ahk](lib/JSON.ahk) | JSON 解析与序列化库 |
| [lib/lib_init.ahk](lib/lib_init.ahk) | 启动初始化流程，串联设置、语言、Qbar、翻译、鼠标速度等模块 |
| [lib/lib_settings.ahk](lib/lib_settings.ahk) | 读取、监控和写回 `CapsLock+settings.ini` |
| [lib/lib_functions.ahk](lib/lib_functions.ahk) | 通用工具函数，如选中文本获取、URL 编码、提示显示等 |
| [lib/lib_keysSet.ahk](lib/lib_keysSet.ahk) | 默认热键布局定义 |
| [lib/lib_keysFunction.ahk](lib/lib_keysFunction.ahk) | 绝大多数 `keyFunc_*` 功能实现 |
| [lib/lib_clQ.ahk](lib/lib_clQ.ahk) | Qbar 搜索与快速运行模块 |
| [lib/lib_clTab.ahk](lib/lib_clTab.ahk) | TabScript 与行内计算入口 |
| [lib/lib_jsEval.ahk](lib/lib_jsEval.ahk) | 基于 IE/HTMLfile 的 JavaScript 执行环境 |
| [lib/lib_mathBoard.ahk](lib/lib_mathBoard.ahk) | 计算板 GUI |
| [lib/lib_mouseSpeed.ahk](lib/lib_mouseSpeed.ahk) | 鼠标速度临时切换与调节 |
| [lib/lib_bindWins.ahk](lib/lib_bindWins.ahk) | 窗口绑定、激活和持久化 |
| [lib/lib_winTransparent.ahk](lib/lib_winTransparent.ahk) | 窗口透明度调整 |
| [lib/lib_winJump.ahk](lib/lib_winJump.ahk) | 基于方向和鼠标点选的窗口跳转辅助 |
| [lib/lib_loadAnimation.ahk](lib/lib_loadAnimation.ahk) | 启动加载动画 |
| [lib/lib_ydTrans.ahk](lib/lib_ydTrans.ahk) | 当前的 DeepLX 翻译实现，文件名沿用历史命名 |
| [lib/sha256.ahk](lib/sha256.ahk) | SHA-256 辅助实现 |
| [lib/lib_json_v1.bak](lib/lib_json_v1.bak) | 历史备份文件 |

### `userAHK/`

| 文件 | 说明 |
|:---|:---|
| [userAHK/main.ahk](userAHK/main.ahk) | 用户扩展总入口，推荐把自定义函数放在这里 |
| [userAHK/OpenAI.ahk](userAHK/OpenAI.ahk) | 选中文本调用 OpenAI 接口进行改写、翻译、润色等 |
| [userAHK/addtodo.ahk](userAHK/addtodo.ahk) | 通过 `obsidian://advanced-uri` 向 Obsidian 追加任务 |
| [userAHK/demo.ahk](userAHK/demo.ahk) | 示例扩展 |

### `prompt/`

| 文件 | 说明 |
|:---|:---|
| [prompt/prompt.txt](prompt/prompt.txt) | 默认 Prompt |
| [prompt/rewrite_prompt.txt](prompt/rewrite_prompt.txt) | 改写 Prompt |
| [prompt/translate_prompt.txt](prompt/translate_prompt.txt) | 翻译 Prompt |
| [prompt/polish_prompt.txt](prompt/polish_prompt.txt) | 润色 Prompt |
| [prompt/prompt-1.txt](prompt/prompt-1.txt) | 历史 Prompt 文件 |
| [prompt/prompt-2.txt](prompt/prompt-2.txt) | 历史 Prompt 文件 |
| [prompt/prompt-3.txt](prompt/prompt-3.txt) | 历史 Prompt 文件 |

### `loadScript/`

| 文件 | 说明 |
|:---|:---|
| [loadScript/debug.html](loadScript/debug.html) | JavaScript 调试页面 |
| [loadScript/scriptDemo.js](loadScript/scriptDemo.js) | 自定义计算脚本示例 |

## 已知现状
- 当前仓库运行基线是 AHK v2，但部分文件名和注释仍沿用了 v1 时代命名
- [CapsLock+settingsDemo.ini](CapsLock+settingsDemo.ini) 中部分说明仍保留历史注释，不完全等同于当前代码行为
- README 这里优先以当前源码实现为准

## 历史说明
以下内容保留自旧版 README，主要对应 AHK v1 时代的写法，仅作备查。

### 旧版分支说明
master 分支：v3.0+

v2 分支：v2.x

[官网（说明文档）](https://capslox.com/capslock-plus/)

### 旧版运行说明
1. 下载并安装 [AutoHotkey v2.x](https://www.autohotkey.com/)。
2. 从 GitHub 下载 CapsLock+ 源码。
3. 运行 `CapsLock+.ahk`。

> 当前仓库入口文件已使用 `#Requires AutoHotkey v2.0`，请不要再使用 AutoHotkey v1.1。

### 旧版自定义热键说明
1. 在 `/userAHK/main.ahk`，编写自定义的按键功能函数，例如 `keyFunc_example1`
2. 在 `CapsLock+settings.ini` 的 `[Keys]` 字段下添加设置按键设置，例如：
   `caps_f7=keyFunc_example1`
3. 保存后重载 Capslock+ (`Capslock+F5`)
4. 之后再按下 `CapsLock+F7` 就可以触发该函数。

为了避免按键设置会调到内部函数，所以规定了所有函数以 `keyfunc_` 开头。

### 旧版示例：把 Capslock+Q 替换成 Listary
有同学跟我吐槽 `qbar` 太弱鸡，让我参考 `WOX`、`Listary` 等把 `qbar` 写得厉害一点，但我觉得 `qbar` 就是够用就好，如果有更高的需求那就直接用它们代替 `qbar` 吧。以 `Listary` 为例子，`Listary` 虽然强大，但是个人觉得跟 `qbar` 比有两个不足的地方：

1. 我觉得 `Listary` 的默认热键不如 `Capslock+Q` 顺手。
2. 不能将选中的文字直接填入。

那我们可以这样做来解决这两个问题：

1. 把下面代码复制到 `/userAHK/main.ahk` 里：

```ahk
keyfunc_listary(){
    ; 获取选中的文字
    selText:=getSelText()

    ; 发送 win+F 按键（Listary默认的呼出快捷键），呼出Listary
    sendinput, #{f}

    ; 等待 Listary 输入框打开
    winwait, ahk_exe Listary.exe, , 0.5

    ; 如果有选中文字的话
    if(selText){
        ; 在选中的字前面加上"gg "，使用 google 搜索
        selText:="gg " . selText

        ; 输出刚才复制的文字，并按一下`home`键将光标移到开头，以方便加入其它关键词
        sendinput, %selText%{home}
    }
}
```

2. 在 `CapsLock+settings.ini` `[keys]` 设置：`caps_q=keyfunc_listary()`，保存，按下 `CapsLock+F5` 重载，搞定。

### 旧版文件说明
`CapsLock+.ahk` 是入口文件，其他所有依赖文件都扔 `/lib` 里了，各文件说明如下：

| 文件 | 说明 |
|:---|:---|
| `lib_bindWins.ahk` | 窗口绑定 |
| `lib_clQ.ahk` | qbar |
| `lib_clTab.ahk` | CapsLock+Tab |
| `lib_functions.ahk` | 一些依赖函数 |
| `lib_init.ahk` | 各种初始化从这里开始 |
| `lib_jsEval.ahk` | 调用 IE 引擎实现的计算功能，计算板和 Caps+Tab 的计算功能都用到 |
| `lib_json.ahk` | json 库 |
| `lib_keysFunction.ahk` | 几乎所有按键功能都在这实现 |
| `lib_keysSet.ahk` | 热键布局 |
| `lib_language.ahk` | 程序用到的字符串放到这 |
| `lib_loadAnimation.ahk` | 程序加载动画 |
| `lib_mathBoard.ahk` | 计算板 |
| `lib_mouseSpeed.ahk` | 鼠标变速 |
| `lib_settings.ahk` | Capslock+settings.ini 设置项提取 |
| `lib_ydTrans.ahk` | 翻译 |
