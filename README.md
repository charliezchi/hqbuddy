# HqBuddy

智多晶海麒（HqFPGA）开发工具的辅助工具集。

## 当前版本

1.1.0

## 功能特点

- **提取 filelist**：从 `.hqprj` 工程文件中提取 `FILE_SRC` 源文件列表
- **路径解析**：自动将 `$WORK_DIR$` 替换为 `.hqprj` 文件所在目录的绝对路径
- **Flow 执行**：通过 `hqprj2tcl` 生成 TCL 脚本
- **XPN 生成**：从布线后的设计生成 XPN 文件，支持普通模式和 hqinsight 模式
- **XPN 转 BIN**：将 XPN 文件通过 `design.bitgen` 转换为 BIN 比特流文件
- **器件查看/修改**：查看 `.hqprj` 使用的器件型号，或修改为新器件（自动验证合法性）
- **仿真库编译**：自动将 XiST 原语仿真库编译到 ModelSim/QuestaSim 中
- **版本选择**：通过交互式菜单选择 HqFPGA 版本（`-build`）
- **启动 GUI**：直接启动 HqFPGA GUI（hqui），可选打开工程（`-gui`）
- **命令行执行**：通过 hqfpga CLI 执行 TCL 脚本（`-cmd`）
- **下载器**：启动 hqdnload 下载器，自动检测最新 `.bin`（`-dl`）
- **线缆工具**：启动 cable.exe，透传所有参数（`-cable`）
- **配置管理**：管理 HqFPGA 扫描路径和版本选择（`-cfg`）
- **文件关联**：注册 `.hqprj` 文件关联，双击直接打开（`-install`）
- **自动检测**：`-filelist`、`-flow`、`-xpn`、`-device` 可省略 `.hqprj` 路径，自动检测当前目录下的第一个 `.hqprj` 文件
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
hqbuddy -filelist                          # 自动检测当前目录的 .hqprj
hqbuddy -filelist example/ddrc_native_demo.hqprj
hqbuddy -filelist example/ddrc_native_demo.hqprj -o filelist.f
hqbuddy -filelist -o filelist.f            # 自动检测 + 自定义输出
```

### 执行 Flow（生成 TCL）

```bat
hqbuddy -flow                              # 自动检测当前目录的 .hqprj
hqbuddy -flow example/ddrc_native_demo.hqprj
hqbuddy -flow example/ddrc_native_demo.hqprj -o my_output.tcl
hqbuddy -flow -o my_output.tcl             # 自动检测 + 自定义输出
```

### 生成 XPN（普通模式）

从 `hq_run/hq_temp/_step_run_route.dump` 生成 XPN 文件。生成完成后会自动打开 XPN 文件。

```bat
hqbuddy -xpn                               # 自动检测，默认生成 hq.xpn
hqbuddy -xpn example/ddrc_native_demo.hqprj
hqbuddy -xpn -o my_design.xpn              # 自动检测，生成 my_design.xpn
hqbuddy -xpn example/ddrc_native_demo.hqprj -o my_design.xpn
```

### 生成 XPN（hqinsight 模式）

从 `hqins_run/hq_import/hqins_impl/hq_temp/_step_run_route.dump` 生成 XPN 文件。生成完成后会自动打开 XPN 文件。

```bat
hqbuddy -xpn -ins                          # 自动检测，默认生成 hq_ins.xpn
hqbuddy -xpn -ins example/ddrc_native_demo.hqprj
hqbuddy -xpn -ins -o my_ins_design.xpn     # 自动检测，生成 my_ins_design.xpn
hqbuddy -xpn -ins example/ddrc_native_demo.hqprj -o my_ins_design.xpn
```

### XPN 转 BIN

将 `.xpn` 文件转换为 `.bin` 比特流文件。

```bat
hqbuddy -xpn2bin                           # 自动检测当前目录的 .xpn
hqbuddy -xpn2bin debug.xpn                 # 默认生成 debug.bin
hqbuddy -xpn2bin -o my_bitstream.bin       # 自动检测 + 自定义输出
hqbuddy -xpn2bin debug.xpn -o my_bitstream.bin
```

### 查看/修改器件

查看 `.hqprj` 当前使用的器件型号（格式：DIE-SPEED-PACKAGE-CONDITION）。

```bat
hqbuddy -device                            # 自动检测当前目录的 .hqprj
hqbuddy -device example/ddrc_native_demo.hqprj
```

修改 `.hqprj` 的器件型号，修改前会通过所选版本的 `dv_list.xml` 验证器件是否合法。修改 `.hqprj` 的同时，会自动同步修改工程中直接使用的 `.hqip` IP 配置文件中的 `device=` 字段。

**注意**：此功能仅支持直接加入到工程中的文件（即 `.hqprj` 的 `FILE_SRC` 中列出的文件），不支持通过 `include` 等方式间接引用的文件。

```bat
hqbuddy -device -set SA5T-100-D0-7F676CI
hqbuddy -device -set SA5T-100-D0-7F676CI example/ddrc_native_demo.hqprj
```

### 编译 XiST 仿真库

自动将 XiST 原语仿真库编译到 ModelSim/QuestaSim 中。默认自动检测所选版本的 HqFPGA 根目录，也可以手动指定。

```bat
hqbuddy -simlib                            # 自动检测 HqFPGA 根目录
hqbuddy -simlib C:/hqv3_xist_3.1.1_FT053026_win64
```

**过程：**
1. 复制 `scripts/compile_xist.tcl` 到 `<HQ>/build/common/sim/verilog/XIST/`
2. 运行 `vsim -c -do compile_xist.tcl`
3. 自动修改 ModelSim/QuestaSim 根目录的 `modelsim.ini`，将 `XiST` 映射改为 `XiST = $MODEL_TECH/../XiST`

**依赖**：需要 `vsim` 在 PATH 中。如果 `modelsim.ini` 是只读文件，脚本会尝试自动解除只读；若失败会提示手动处理。

### 选择 HqFPGA 版本

通过交互式菜单选择当前使用的 HqFPGA 版本。按上下键导航，回车确认。

```bat
hqbuddy -build
```

### 启动 GUI

启动 HqFPGA GUI（hqui），可选指定工程文件直接打开。

```bat
hqbuddy -gui                              # 启动 GUI
hqbuddy -gui example/ddrc_native_demo.hqprj  # 启动 GUI 并打开工程
```

双击 `.hqprj` 文件（通过 `-install` 注册文件关联后）也会触发此命令。

### 命令行执行

通过 hqfpga CLI 执行指定的 TCL 脚本。

```bat
hqbuddy -cmd my_script.tcl
```

### 启动下载器

启动 hqdnload 下载器。若不指定文件，自动检测当前目录下最新的 `.bin` 文件。

```bat
hqbuddy -dl                               # 自动检测最新 .bin
hqbuddy -dl -f my_bitstream.bin           # 指定下载文件
```

### 线缆工具

启动 cable.exe，所有参数透传给电缆工具。

```bat
hqbuddy -cable                            # 启动 cable.exe
hqbuddy -cable -scan                      # 透传 -scan 参数
```

### 配置管理

管理 HqFPGA 扫描路径和版本选择配置。

```bat
hqbuddy -cfg                              # 显示当前配置
hqbuddy -cfg show                         # 显示当前配置
hqbuddy -cfg set-root C:/hqfpga_installs  # 添加扫描路径
hqbuddy -cfg remove-root C:/hqfpga_installs  # 移除扫描路径
hqbuddy -cfg auto                         # 自动扫描并选择最新版本
hqbuddy -cfg init                         # 重置为默认配置
```

### 安装文件关联

注册 `.hqprj` 文件关联，双击 `.hqprj` 文件即可通过 hqbuddy 打开。

```bat
hqbuddy -install
```

### 其他命令

```bat
hqbuddy              # 显示 HqFPGA 根目录路径
hqbuddy -h           # 显示帮助
```

## 参数速查

| 参数 | 说明 |
|------|------|
| `-h` | 显示帮助 |
| `-v` | 显示版本 |
| `-build` | 交互式选择 HqFPGA 版本 |
| `-install` | 注册 `.hqprj` 文件关联 |
| `-filelist [<file>]` | 从 `.hqprj` 提取 FILE_SRC filelist，省略时自动检测 |
| `-filelist [<file>] -o <out>` | 将 filelist 输出到指定文件 |
| `-flow [<file>]` | 生成 `hqprj2tcl` TCL 脚本，省略时自动检测，默认生成 `run_hqprj.tcl` |
| `-flow [<file>] -o <out>` | 指定生成的 TCL 文件名 |
| `-xpn [<file>] [-o <file>]` | 生成 XPN（普通模式），省略时自动检测，默认生成 `hq.xpn` |
| `-xpn -ins [<file>] [-o <file>]` | 生成 XPN（hqinsight 模式），省略时自动检测，默认生成 `hq_ins.xpn` |
| `-xpn2bin [<file>] [-o <file>]` | 将 XPN 转换为 BIN，省略时自动检测，默认生成 `<input>.bin` |
| `-device [<file>]` | 查看 `.hqprj` 使用的器件型号 |
| `-device -set <part> [<file>]` | 修改 `.hqprj` 及关联 `.hqip` 的器件型号，并验证合法性 |
| `-simlib [<dir>]` | 编译 XiST 仿真库到 ModelSim/QuestaSim，省略时自动检测 HqFPGA 根目录 |
| `-gui [<file>]` | 启动 HqFPGA GUI（hqui），可选打开工程 |
| `-cmd <file>` | 通过 hqfpga CLI 执行 TCL 脚本 |
| `-dl [-f <file>]` | 启动 hqdnload 下载器，省略时自动检测最新 `.bin` |
| `-cable [args]` | 启动 cable.exe，透传所有参数 |
| `-cfg [action]` | 管理配置（show / set-root / remove-root / init / auto） |

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
│   ├── config.py         # 配置管理
│   ├── scanner.py        # 磁盘扫描 HqFPGA 安装
│   ├── launcher.py       # 工具路径解析与启动
│   ├── build_selector.py # 交互式版本选择
│   ├── hqprj_parser.py   # .hqprj 解析核心
│   ├── flow.py           # Flow 执行（hqfpga -cmd）
│   ├── xpn.py            # XPN 生成（普通模式 + hqinsight 模式）
│   ├── xpn2bin.py        # XPN 转 BIN
│   ├── device.py         # 器件查看/修改
│   ├── ipmgr.py          # IP 配置文件管理（内部使用）
│   ├── simlib.py         # XiST 仿真库编译
│   └── utils.py          # 版本解析与比较工具函数
├── scripts/
│   └── compile_xist.tcl  # XiST 仿真库编译脚本（手动或自动均使用此脚本）
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
