# HqBuddy

智多晶海麒（HqFPGA）开发工具的辅助工具集。

## 当前版本

0.0.2

## 功能特点

- **提取 filelist**：从 `.hqprj` 工程文件中提取 `FILE_SRC` 源文件列表
- **路径解析**：自动将 `$WORK_DIR$` 替换为 `.hqprj` 文件所在目录的绝对路径
- **Flow 执行**：通过 hqlauncher 调用 `hqprj2tcl` 生成 TCL 脚本
- **零依赖运行**：提供独立 `exe`，无 Python 环境也能开箱即用

## 开箱即用

从 [Releases](../../releases) 页面下载最新版 `hqbuddy.exe`，放到任意目录即可。

如果你从源码仓库使用，一行命令完成编译并注册到 PATH。默认（不带参数）会先 `clean` 再 `build`，`build` 成功后会自动将 `hqbuddy.exe` 复制到 `%APPDATA%\hqbuddy\` 并添加到用户 PATH：

```powershell
.\build.ps1        # 先 clean 再 build + 自动注册
.\build.ps1 build  # 仅 build + 自动注册
```

## 使用方式

### 查看版本

```bat
hqbuddy -v
```

### 提取 filelist

```bat
hqbuddy -filelist example/ddrc_native_demo.hqprj
hqbuddy -filelist example/ddrc_native_demo.hqprj -o filelist.f
```

### 执行 Flow（生成 TCL）

```bat
hqbuddy -flow example/ddrc_native_demo.hqprj
hqbuddy -flow example/ddrc_native_demo.hqprj -o my_output.tcl
```

**依赖**：`-flow` 需要 [hqlauncher](https://github.com/charliezchi/hqlauncher) 已安装并在 PATH 中。

### 其他命令

```bat
hqbuddy -h              # 显示帮助
```

## 参数速查

| 参数 | 说明 |
|------|------|
| `-h` | 显示帮助 |
| `-v` | 显示版本 |
| `-filelist <file>` | 从 `.hqprj` 提取 FILE_SRC filelist |
| `-filelist <file> -o <out>` | 将 filelist 输出到指定文件 |
| `-flow <file>` | 通过 hqlauncher 执行 hqprj2tcl，默认生成 `run_hqprj.tcl` |
| `-flow <file> -o <out>` | 指定生成的 TCL 文件名 |

## 开发与打包

```bat
:: 克隆仓库
git clone https://github.com/XiST-ZhC/hqbuddy.git
cd hqbuddy

:: 开发运行（Python 源码）
.\hqbuddy.bat -v
python -m hqbuddy -v

:: 打包 exe
.\build.ps1 build

:: 清理构建产物
.\build.ps1 clean
```

使用 `build.ps1` 统一管理：

| 命令                | 说明                                              |
| ------------------- | ------------------------------------------------- |
| `.\build.ps1`       | 先 `clean` 再 `build`，成功后自动复制 exe 并注册 PATH |
| `.\build.ps1 build` | 打包 `hqbuddy.exe`，成功后自动复制 exe 并注册 PATH    |
| `.\build.ps1 clean` | 清理 exe、log、dump 及 PyInstaller 临时文件          |
| `.\build.ps1 help`  | 显示帮助                                          |

打包时会临时生成入口脚本，完成后自动清理，仓库内无残留。

## 项目结构

```
hqbuddy/
├── hqbuddy/              # Python 源码包
│   ├── __init__.py       # 版本号
│   ├── __main__.py       # CLI 入口
│   ├── hqprj_parser.py   # .hqprj 解析核心
│   └── flow.py           # Flow 执行（hqlauncher 调用）
├── hqbuddy.bat           # 开发入口（调用 Python 源码）
├── build.ps1             # 构建 / 清理统一管理，build 成功后自动注册 PATH
├── .gitignore
├── .gitattributes
├── AGENTS.md
├── LICENSE
└── README.md
```

## License

[LICENSE](LICENSE)
