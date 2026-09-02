<!-- 来源：docs/user_manual/hqfpga_um_chs.md 第 214–333 行（§5 安装指南、§6 HqFpga 控制台主程序运行帮助） -->

# HqFpga 安装指南与控制台主程序运行帮助（Skill 蒸馏）

> 本文件为 AI agent 操作 HqFpga 工具链的参考资料，蒸馏自官方中文用户手册 §5、§6。

## §5 安装指南

### 支持的操作系统

- **Windows**：`Windows NT/2000/XP/Vista/Win7/Win8/Win10`，32 位及 64 位系统
- **Linux**：`Linux kernel 2.6`，64 位系统

### 安装方式

- 将 HqFpga 软件包直接解压缩至目标目录即可完成安装（绿色解压方式）。
- Windows 平台若提供安装程序（名为 `setup_hqfpga.exe` 或相似名称的程序），可直接运行该安装程序，按指示完成安装。

### 关键执行文件位置

- 图形用户界面程序：

  ```
  <安装目录>/build/<platform>/hqui/hqui[.exe]
  ```

- 主程序（控制台命令行主程序）：

  ```
  <安装目录>/build/<platform>/bin/hqfpga[.exe]
  ```

其中 `<platform>` 可取：

| platform        | 含义                           |
| --------------- | ------------------------------ |
| `linux26_x86_64` | Linux 内核 2.6，64 位操作系统 |
| `win_x86`       | Windows X86，32 位操作系统      |
| `win_x64`       | Windows X86，64 位操作系统      |

### 安装后目录结构

安装后的 HqFpga 顶层包含：

| 目录 | 说明 |
| ---- | ---- |
| `build/`   | 包含 HqFpga 主执行文件以及辅助文件 |
| `doc/`     | 包含 HqFpga 的帮助文档 |
| `samples/` | 包含示例文件，便于用户快速学习使用 HqFpga |

`build/` 目录下的子目录：

| 子目录 | 说明 |
| ------ | ---- |
| `common/`    | 公用文件目录，包含器件文件、消息文件等 |
| `ipcreator/` | IP 工具相关文件目录 |
| `HqInsight/` | FPGA 实时调试器相关文件目录 |
| `dsxp/`      | 设计浏览器相关文件目录 |
| `<platform>/`| 平台相关（如 `win_x64`）文件目录 |
| `bin/`       | 主执行程序文件目录 |
| `hqui/`      | 主图形用户界面目录 |
| `lib/`       | 库文件目录 |

### Windows 平台注意事项

1. 多数 HqFpga 图形用户界面组件依赖于微软 **Visual C++ 2015-2022 x86 和 x64 再发行组件包**（32 位和 64 位都需要），需从微软网站下载并安装：
   - 下载页：https://learn.microsoft.com/zh-cn/cpp/windows/latest-supported-vc-redist?view=msvc-140
   - 直接下载 32 位：https://aka.ms/vs/17/release/vc_redist.x86.exe
   - 直接下载 64 位：https://aka.ms/vs/17/release/vc_redist.x64.exe
2. **Windows XP** 上只能运行主图形界面和主程序，不能运行其它图形界面工具，如 **IP Creator**（IP 工具）、**HqInsight**（FPGA 调试工具）等。
3. HqFpga 图形界面程序通过 **TCP/IP 管道**与主程序通信，可能触发 Windows 防火墙警告；此时应选择允许 hqfpga 主程序运行。
4. 若将 HqFpga 安装到 Windows 系统目录下（如 `C:\Program Files` 或 `C:\Program Files(x86)`），**必须用管理员权限运行** HqFpga。
5. 若 HqFpga 运行过程中发生异常的文件或目录错误，建议关闭防病毒软件再重试。

## §6 HqFpga 控制台主程序运行帮助

控制台主程序执行文件位于每个 `<platform>/bin` 目录下。例如：

- Linux64 平台：`<HqFpga 安装目录>/build/linux26_x86_64/bin/hqfpga`
- Windows 32 位平台：`<HqFpga 安装目录>\build\win_x86\bin\hqfpga.exe`

### hqfpga 命令

HqFpga 控制台主程序，可按批处理方式或交互式方式运行。

#### 语法

```
Hqfpga [-cmd <脚本文件名>]
       [-outdir <输出目录>]
       [-log <日志文件名>]
       [-lang <语言>]
       [-help]
```

#### 参数说明

| 参数 | 类型 | 缺省值 | 说明 |
| ---- | ---- | ------ | ---- |
| `-cmd`   | 脚本文件名 | 无（缺省为交互式） | 指定本参数时，HqFpga 以**批处理方式**运行脚本文件中的命令；缺省情况下以交互式方式运行。 |
| `-outdir`| 输出目录 | 当前目录（即 HqFpga 启动目录） | 缺省时 HqFpga 在当前目录下输出各种文件（日志文件、脚本文件等）；可用本参数指定输出到其它目录。 |
| `-log`   | 日志文件名 | `hqfpga.log`（位于目录 `<outdir>`） | 缺省日志文件名为 `hqfpga.log`；可用本参数指定其它日志文件名。 |
| `-lang`  | 语言 | `eng` | 语言选择：`eng` 英文 / `chs` 简体中文 / `jpn` 日文（实测补充，原文截断）。 |
| `-help`  | — | — | 打印用法（`[Syntax]`/`[Arguments]`/`[Example]`）。注意 `-h`、`--help` 均无效，**必须用 `-help`**（实测补充）。 |

> 【实测补充】顶层参数仅以上 5 个；工具的全部能力在 TCL 命令层（`-cmd` 交互中），全量命令清单见 `references/tcl_commands_help.md`，任意命令语法用 `help <命令名>` 查询。

---

## 原文疑点（格式碎裂处）

> 疑点 1、2 已由实测（hqv3_xist 3.1.1 FT082926）补充进上方参数表：`-lang` 取 `eng`/`chs`/`jpn` 缺省 `eng`；`-help` 打印用法。原文疑点保留如下备查。

1. **`-lang` 参数说明被截断**：§6.1.2 中 `lang` 参数的描述在第 333 行（仅列出的参数名 `lang`）后即截断，直接跳转到 §10“综合”章节，无任何关于 `-lang` 参数含义、可选值的说明（原文如此）。
2. **`-help` 参数无说明**：语法块中列出了 `[-help]`，但 §6.1.2 参数说明中没有任何对应条目（原文如此）。
3. **小节序号错乱**：§6.1 下列出 `## 6.1.1 语法`、`## 6.1.2 参数说明` 两个小标题，但“语法”和“参数说明”的实际内容块位于 §5 结尾处（第 290–296 行）的代码块中，并非紧跟在 6.1.1 标题之下（原文如此）。
4. **平台枚举名称与示例不一致**：§5 中 `<platform>` 取值为 `linux26_x86_64`、`win_x86`、`win_x64`，但安装目录说明行出现 `win_x64` 与 `win_x86` 混用（原文如此）；Linux 示例路径使用 `linux26_x86_64`，Windows 示例使用 `win_x86`。
5. **语句缺失**：第 307–308 行“对于 Windows 32 位平台为:”后直接给出带反斜杠的 Windows 路径，未用代码块包裹，且缺失“主程序为：”类的引导语，格式碎裂（原文如此）。
6. 第 269 行出现孤立文本 “Xian Intelligence Silicon”（公司署名，原文如此）。
