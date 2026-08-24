# HqBuddy

智多晶海麒（HqFPGA）开发工具的辅助工具集。

## 当前版本

2.5.3

## 功能特点

- **提取 filelist**：从 `.hqprj` 工程文件中提取 `FILE_SRC` 源文件列表
- **路径解析**：自动将 `$WORK_DIR$` 替换为 `.hqprj` 文件所在目录的绝对路径
- **Flow 执行**：通过 `hqprj2tcl` 生成 TCL 脚本，支持 `-looptdo` 与 `-bin_only` 模式
- **XPN 生成**：从布线后的设计生成 XPN 文件，支持普通模式和 hqinsight 模式
- **XPN 转 BIN**：将 XPN 文件通过 `design.bitgen` 转换为 BIN 比特流文件
- **器件查看/修改**：查看 `.hqprj` 使用的器件型号，或修改为新器件（自动验证合法性，支持交互式搜索选择）
- **新建工程**：从模板创建 `.hqprj` 工程（`-new_prj`）
- **添加源文件**：向工程添加 `.v` / `.vh` / `.sdc` / `.upc` / `.f` 文件并维护对应时间戳（`-add`）
- **设置顶层模块**：修改 `TOP_MODULE`（`-set_top`）
- **工程清理**：按 `clean_list.json` 清理工程目录中的中间产物（`-clean`）
- **IP 网表生成**：根据 `.hqip` 自动定位并调用对应 ipgen 工具生成网表（`-ipgen` / `-update_ip`）
- **仿真库编译**：自动将 XiST 原语仿真库编译到 ModelSim/QuestaSim 中
- **版本选择**：通过交互式菜单选择 HqFPGA 版本，支持模糊查找与 latest 自动选择（`-build_sel`）
- **启动 GUI**：无参数运行或双击 `.hqprj` 直接启动 HqFPGA GUI（hqui）
- **命令行执行**：通过 hqfpga CLI 执行 TCL 脚本（`-cmd`）
- **下载器**：启动 hqdnload 下载器，自动检测最新 `.bin`（`-dl`）
- **线缆工具**：启动 cable.exe，透传所有参数（`-cable`）
- **配置管理**：管理 HqFPGA 扫描路径和版本选择，支持 `auto` 自动扫描（`-cfg`）
- **自动检测**：`-filelist`、`-flow`、`-xpn`、`-device` 可省略 `.hqprj` 路径，自动检测当前目录下的第一个 `.hqprj` 文件
- **零依赖运行**：提供独立 `exe`，无 Python 环境也能开箱即用

## 开箱即用

从 [Releases](../../releases) 页面下载最新版 `hqbuddy.exe`，放到任意目录即可。

如果你从源码仓库使用，一行命令完成编译并注册到 PATH。默认（不带参数）会先 `clean` 再 `build`，`build` 成功后会自动将 `hqbuddy.exe` 复制到 `%APPDATA%\hqbuddy\` 并添加到用户 PATH：

```bat
python build.py        :: 先 clean 再 build + 自动注册
python build.py build  :: 仅 build + 自动注册
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

**looptdo 模式**：移除 packing / placement / routing / bitgen 阶段，改用 `design.looptdo` 随机搜索优化参数：

```bat
hqbuddy -flow -looptdo                     # 自动检测当前目录的 .hqprj
hqbuddy -flow example/ddrc_native_demo.hqprj -looptdo
```

**bin-only 模式**：只生成 `.bin` 比特流，不产生中间文件，可自定义 bin 名称（默认与 `-flow` 一致）：

```bat
hqbuddy -flow -bin_only                    # 自动检测，默认 bin 名称
hqbuddy -flow example/ddrc_native_demo.hqprj -bin_only my_bitstream.bin
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
hqbuddy -device -set                                  # 交互式搜索并选择器件
hqbuddy -device -set SA5T-100-D0-7F676CI
hqbuddy -device -set SA5T-100-D0-7F676CI example/ddrc_native_demo.hqprj
hqbuddy -device -set example/ddrc_native_demo.hqprj   # 指定工程 + 交互式选择
```

不指定 `part` 时进入交互式器件列表：上下键选择、输入关键字模糊查找，选中项带箭头标记。

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

通过交互式菜单选择当前使用的 HqFPGA 版本。按上下键导航，回车确认；支持输入关键字模糊查找，`[latest]` 行可自动选择最新版本。

```bat
hqbuddy -build_sel
```

### 查看 HqFPGA 根目录

打印当前所选 HqFPGA 版本的根目录路径。

```bat
hqbuddy -root
```

### 新建工程

按 `templates/project.hqprj` 模板在当前目录创建 `.hqprj` 工程，文件名即为 `PROJ_NAME`。可显式指定 `-device`，否则会唤起交互式器件选择。

```bat
hqbuddy -new_prj my_project
hqbuddy -new_prj my_project -device SA5T-100-D0-7F676CI
```

### 添加源文件

向工程添加设计文件与约束文件，并自动维护对应时间戳：

- `.v` / `.vh` → 添加到 `FILE_SRC`，每条新增一条 `FILE_TIME`
- `.sdc` → 添加到 `FILE_TC`
- `.upc` → 添加到 `FILE_PC`
- `.f`（filelist）→ 展开其中的 `.v` / `.vh` 后加入 `FILE_SRC`

支持绝对路径与相对路径（相对路径以 filelist 文件所在目录为基准），找不到的文件或不支持的后缀会报错提示。

```bat
hqbuddy -add test.v test2.v timing.sdc physical.upc files.f
```

### 设置顶层模块

修改 `TOP_MODULE`：

```bat
hqbuddy -set_top my_top
```

### 清理工程目录

按 `configs/clean_list.json` 中的清单清理脚本所在目录下的中间文件与空文件夹（保留 `.hqprj`）。清理前会二次确认，`-force` 跳过确认：

```bat
hqbuddy -clean
hqbuddy -clean -force
```

### 生成 IP 网表

根据 `.hqip` 文件（INI 格式）中的 `meta_file` 定位对应的 ipgen 工具并生成 IP 网表。省略路径时自动使用当前目录下找到的第一个 `.hqip`。

```bat
hqbuddy -ipgen                                      # 自动检测 .hqip
hqbuddy -ipgen my_ip.hqip
hqbuddy -ipgen my_ip.hqip -lang chs
```

### 更新工程 IP 网表

找到工程中的所有 `.hqip` 文件，逐一重新生成网表：

```bat
hqbuddy -update_ip
```

### 启动 GUI

不带任何参数运行即启动 HqFPGA GUI（hqui）；将 `.hqprj` 文件路径作为首个参数传入可直接打开对应工程（注册文件关联后，双击 `.hqprj` 文件也会触发）。

```bat
hqbuddy              # 启动 GUI
hqbuddy example/ddrc_native_demo.hqprj  # 启动 GUI 并打开工程
```

### 命令行执行

通过 hqfpga CLI 执行指定的 TCL 脚本。不带参数时直接进入 hqfpga 交互式 CLI。

```bat
hqbuddy -cmd my_script.tcl  :: 执行 TCL 脚本
hqbuddy -cmd                :: 进入 hqfpga 交互式 CLI
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

### 其他命令

```bat
hqbuddy -h           # 显示帮助
hqbuddy -v           # 显示版本
hqbuddy -root        # 显示 HqFPGA 根目录路径
```

## 参数速查

| 参数 | 说明 |
|------|------|
| （无参数） | 启动 HqFPGA GUI（hqui） |
| `<file>.hqprj` | 启动 HqFPGA GUI 并打开工程 |
| `-h` | 显示帮助 |
| `-v` | 显示版本 |
| `-root` | 显示 HqFPGA 根目录路径 |
| `-build_sel` | 交互式选择 HqFPGA 版本（支持搜索与 latest） |
| `-filelist [<file>]` | 从 `.hqprj` 提取 FILE_SRC filelist，省略时自动检测 |
| `-filelist [<file>] -o <out>` | 将 filelist 输出到指定文件 |
| `-flow [<file>]` | 生成 `hqprj2tcl` TCL 脚本，省略时自动检测，默认生成 `run_hqprj.tcl` |
| `-flow [<file>] -o <out>` | 指定生成的 TCL 文件名 |
| `-flow [<file>] -looptdo` | looptdo 模式：合成后运行 `design.looptdo` 搜索优化参数 |
| `-flow [<file>] -bin_only [<name>]` | bin-only 模式：仅生成 `.bin`，不产生中间文件 |
| `-xpn [<file>] [-o <file>]` | 生成 XPN（普通模式），省略时自动检测，默认生成 `hq.xpn` |
| `-xpn -ins [<file>] [-o <file>]` | 生成 XPN（hqinsight 模式），省略时自动检测，默认生成 `hq_ins.xpn` |
| `-xpn2bin [<file>] [-o <file>]` | 将 XPN 转换为 BIN，省略时自动检测，默认生成 `<input>.bin` |
| `-device [<file>]` | 查看 `.hqprj` 使用的器件型号 |
| `-device -set [<part>] [<file>]` | 修改器件型号（支持交互式选择），并同步关联 `.hqip` |
| `-new_prj <name> [-device <part>]` | 从模板创建 `.hqprj` 工程 |
| `-add <files...>` | 添加 `.v` / `.vh` / `.sdc` / `.upc` / `.f` 文件到工程 |
| `-set_top <name>` | 设置顶层模块 `TOP_MODULE` |
| `-clean [-force]` | 按 `clean_list.json` 清理工程目录，`-force` 跳过确认 |
| `-ipgen [<file>] [-lang <lang>]` | 根据 `.hqip` 生成 IP 网表，省略时自动检测 |
| `-update_ip [<file>]` | 重新生成工程内所有 IP 网表 |
| `-simlib [<dir>]` | 编译 XiST 仿真库到 ModelSim/QuestaSim，省略时自动检测 HqFPGA 根目录 |
| `-cmd [<file>]` | 通过 hqfpga CLI 执行 TCL 脚本；缺省时进入 hqfpga 交互式 CLI |
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
python build.py build

:: 清理构建产物
python build.py clean
```

使用 `build.py` 统一管理：

| 命令                   | 说明                                                 |
| ---------------------- | ---------------------------------------------------- |
| `python build.py`       | 先 `clean` 再 `build`，成功后自动复制 exe 并注册 PATH |
| `python build.py build` | 打包 `hqbuddy.exe`，成功后自动复制 exe 并注册 PATH    |
| `python build.py clean` | 清理 exe、log、dump 及 PyInstaller 临时文件          |
| `python build.py help`  | 显示帮助                                             |

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
│   ├── flow.py           # Flow 执行（普通 / looptdo / bin-only 模式）
│   ├── xpn.py            # XPN 生成（普通模式 + hqinsight 模式）
│   ├── xpn2bin.py        # XPN 转 BIN
│   ├── device.py         # 器件查看/修改（含交互式选择）
│   ├── ipgen.py          # IP 网表生成
│   ├── ipmgr.py          # IP 配置文件管理（内部使用）
│   ├── simlib.py         # XiST 仿真库编译
│   └── utils.py          # 版本解析与比较工具函数
├── scripts/
│   └── compile_xist.tcl  # XiST 仿真库编译脚本（手动或自动均使用此脚本，支持 .v / .vp）
├── hqbuddy.bat           # 开发入口（调用 Python 源码）
├── build.py              # 构建 / 清理统一管理，build 成功后自动注册 PATH
├── .gitignore
├── .gitattributes
├── AGENTS.md
├── LICENSE
└── README.md
```

## License

[LICENSE](LICENSE)
