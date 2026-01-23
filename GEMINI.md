# CapsLock+ Pro (V2 Refactor) - 开发者手册

> **最后更新**: 2026-01-23
> **版本**: 3.3.0.0 (Alpha/Beta)
> **引擎**: AutoHotkey v2.0+

本文档旨在记录 CapsLock+ 从 AHK v1 迁移至 v2 的架构设计、核心逻辑重构心得及开发规范，以便后续维护和功能复用。

---

## 🏗️ 项目架构 (Architecture)

本项目采用模块化设计，核心入口为 `CapsLock+.ahk`，功能逻辑分散在 `lib/` 目录下的各个库文件中。

### 1. 核心文件
- **`CapsLock+.ahk`**: 程序入口。
  - 负责权限检查 (`RunAs Admin`)。
  - 处理 `Include` 依赖链。
  - 定义全局变量 (Globals) 和核心状态 (`clState`, `clUsed`)。
  - 包含 `*CapsLock::` 主热键逻辑及分发器 (`keyDispatcher`)。

### 2. 库文件 (`lib/`)
| 文件名 | 职责描述 | 关键 V2 变更点 |
| :--- | :--- | :--- |
| **`lib_init.ahk`** | 初始化流程 | 避免显式调用 GUI Show；使用 `Suspend` 控制冷启动。 |
| **`lib_keysSet.ahk`** | 热键映射定义 | 使用 `Map` 存储键值对；支持 `caps_` 和 `caps_lalt_` 前缀区分模式。 |
| **`lib_keysFunction.ahk`** | 具体的按键功能实现 | 统一命名 `keyFunc_*`；通过 `runFunc` 动态调用。 |
| **`lib_bindWins.ahk`** | 窗口绑定核心逻辑 | Mode 1/2/3 实现；修复了无限循环和类型匹配问题。 |
| **`lib_clQ.ahk`** | **Q-Bar** (快速启动/搜索) | `Gui` 对象化；`ListView` 图标处理；启动时不仅 `Init` 还要 `Show`。 |
| **`lib_ydTrans.ahk`** | 有道/DeepLX 翻译 | 使用 `WinHttp.WinHttpRequest.5.1`；修复透明度导致文字不可见问题。 |
| **`lib_mathBoard.ahk`** | 数学计算板 | 独立 GUI；按键映射重写。 |
| **`lib_settings.ahk`** | INI 设置管理 | 大量使用 `Map` 替代伪数组；严格的变更检测逻辑。 |
| **`lib_functions.ahk`** | 通用工具函数 | `runFunc` 参数解析 (Str->Int)；DPI 适配；剪贴板增强。 |
| **`lib_winJump.ahk`** | 窗口切换/导航 | 使用 `Map` 存储窗口栈；坐标计算适配 DPI。 |

---

## 🛠️ AHK V2 迁移与开发规范 (Migration Guide)

在维护本项目时，必须严格遵守以下 AutoHotkey v2 规范：

### 1. 变量与作用域
- **全局变量**：在函数内部修改全局变量必须显式声明 `global varName`。
- **未初始化变量**：V2 对未赋值变量的使用会抛出错误，需使用 `IsSet()` 检查或赋予初始值。

### 2. GUI 构建
- **对象化**：废弃 `Gui, Add...` 语法。
  ```autohotkey
  ; V1
  ; Gui, Add, Edit, vMyEdit
  
  ; V2
  MyGui := Gui()
  editObj := MyGui.Add("Edit", "vMyEdit")
  editObj.OnEvent("Change", OnChangeFunc)
  ```
- **Hwnd 获取**：直接通过对象获取 `guiObj.Hwnd`。

### 3. 数据结构 (Map & Array)
- **Map 代替伪数组**：
  - ❌ 禁止使用 `Array%i%` 这种动态变量名。
  - ✅ 使用 `MyMap := Map()`, `MyMap["Key"] := "Value"`。
- **类型严格**：`Map` 的键是区分类型的。`MyMap[1]` (Integer) 和 `MyMap["1"]` (String) 是两个不同的键。
  - **坑点**：从 INI 读取或 InputBox 获取的数字通常是字符串，作为 Map Key 使用前如果不转换类型 (`Integer()`)，可能导致查找失败。

### 4. 正则表达式
- **引用传递**：`RegExMatch` 的输出变量现在通过引用传递 (`&OutputVar`)。
  ```autohotkey
  RegExMatch(haystack, "Pat(tern)", &match)
  MsgBox match[1] ; 获取第一个捕获组
  ```

### 5. 动态调用
- 使用 `%FuncName%(params*)` 进行动态函数调用。
- 确保参数数组中的类型正确（如 V2 函数需要 Int，不要传 String）。

---

## 🌟 核心功能逻辑复盘

### 1. 窗口绑定系统 (Window Binding)
- **Mode 1 (单窗口)**: `Caps+Alt+1` 绑定当前窗口。
- **Mode 2 (多窗口组)**: 双击 `Caps+Alt+1`。激活时循环切换。自动降级逻辑：如果组内剩下一个窗口，表现如 Mode 1。
- **Mode 3 (应用组)**: 三击 `Caps+Alt+1`。绑定当前 exe 所有窗口。激活时循环切换。**新增**：单窗口时支持最小化切换。

### 2. Q-Bar (搜索框)
- **启动优化**：初始化时不显示窗口 (`CLq()` 仅在热键触发时调用)。
- **事件处理**：列表选择 (`Up/Down`) 需要判断焦点；回车执行 (`Run` 或 `Web Search`)。

### 3. HTTP 请求 (翻译模块)
- **COM 对象**：使用 `ComObject("WinHttp.WinHttpRequest.5.1")`。
- **JSON 解析**：集成 `JSON.parse` (第三方库)，替换原本的 `eval` 或正则解析。
- **GUI 坑点**：`WinSetTransColor` 会导致控件背景透明从而看不清文字，V2 中建议直接控制背景色或仅设置整体透明度。

---

## 📝 调试与维护技巧

1. **热重载**：`Caps+F5` 已绑定 `keyFunc_reload`，修改代码后直接重载即可。
2. **调试输出**：
   - 简单调试：`ToolTip("Value: " . val)`
   - 复杂调试：写文件或使用 `MsgBox` (注意 MsgBox 会阻塞)。
3. **IDE 支持**：建议使用 VSCode + AutoHotkey v2 Language Support 插件，配置好格式化规则。

---

## 📖 使用指南 (User Guide)

### 1. 窗口绑定 (Window Binding)
- **绑定窗口**: `Caps + Alt + 数字键 (1-9)`
  - **点击 1 次**: 绑定**单个窗口** (Mode 1)。
  - **点击 2 次**: 将窗口**加入组** (Mode 2)。
  - **点击 3 次**: 绑定当前**程序的所有窗口** (Mode 3)。
- **激活窗口**: `Caps + 数字键 (1-9)`
  - 单次按下激活或最小化。
  - 多窗口模式下，重复按下在窗口间循环切换。

### 2. Q-Bar 快速搜索
- **呼出**: `Caps + Q`
- **功能**:
  - 输入关键词过滤启动项或文件。
  - 输入算式直接计算。
  - `Caps + -` / `Caps + =`: 在文件路径中跳转 上/下 级目录。

### 3. 翻译 (Translation)
- **操作**: 选中一段文本，按下 `Caps + F3` (或 `Caps + T`)。
- **关闭**: 按 `Esc` 键或点击关闭按钮。

### 4. Tab 增强 / 计算 (Tab Enhancement)
- **操作**: 选中简单的数学算式 (如 `15*3`)，按下 `Caps + Tab`，会自动补全为 `15*3=45`。
- **代码补全**: 如果在 `settings.ini` 中配置了 `TabHotString`，选中缩写按下 `Caps + Tab` 可展开为代码片段。

### 5. 其他常用快捷键
- **光标移动**: `Caps + E/S/D/F` (上/左/下/右) 或 `Caps + I/J/K/L`。
- **选择文本**: `Caps + Shift + 方向键` (如 `Caps + LeftSquareBracket` 删除至行首)。
- **重载脚本**: `Caps + F5` (开发调试时非常有用)。
- **窗口透明**: `Caps + F4` + 滚轮调整当前窗口透明度。

---

此文档旨在帮助开发者快速理解 CapsLock+ 的 V2 版本架构，既是开发指南，也是重构过程的经验总结。
