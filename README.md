# HqBuddy

智多晶海麒（HqFPGA）开发工具的辅助工具集。

## 当前版本

3.6.0

## 功能特点

- **提取 filelist**：从 `.hqprj` 工程文件中提取 `FILE_SRC` 源文件列表
- **路径解析**：自动将 `$WORK_DIR$` 替换为 `.hqprj` 文件所在目录的绝对路径
- **Flow TCL 生成**：通过 `hqprj2tcl` 生成实现流程 TCL（只生成不执行，用 `-cmd` 执行），支持 `-looptdo` 与 `-bin_only` 模式
- **XPN 生成**：从布线后的设计生成 XPN 文件，支持普通模式和 hqinsight 模式
- **HqInsight 在线调试**：状态查看、触发条件设置（参数/交互）、波形抓取为 VCD（`-insight`）
- **XPN 转 BIN**：将 XPN 文件通过 `design.bitgen` 转换为 BIN 比特流文件
- **器件查看/修改**：查看 `.hqprj` 使用的器件型号，或修改为新器件（自动验证合法性，支持交互式搜索选择）
- **新建工程**：从模板创建 `.hqprj` 工程（`-new_prj`）
- **添加源文件**：向工程添加 `.v` / `.vh` / `.sdc` / `.upc` / `.f` 文件并维护对应时间戳（`-add`）
- **设置顶层模块**：修改 `TOP_MODULE`（`-set_top`）
- **工程清理**：按 `clean_list.json` 清理工程目录中的中间产物（`-clean`）
- **IP 网表生成**：根据 `.hqip` 自动定位并调用对应 ipgen 工具生成网表（`-ipgen` / `-update_ip`）
- **HDL 加密**：调用版本自带的 `hq_ipencrypt.exe` 加密源文件，密钥自动定位（`-encrypt`）
- **仿真库编译**：自动将 XiST 原语仿真库编译到 ModelSim/QuestaSim 中
- **版本选择**：通过交互式菜单选择 HqFPGA 版本，支持模糊查找与 latest 自动选择（`-build_sel`）
- **启动 GUI**：无参数运行或双击 `.hqprj` 直接启动 HqFPGA GUI（hqui）
- **命令行执行**：通过 hqfpga CLI 执行 TCL 脚本（`-cmd`）
- **下载器**：启动 hqdnload 下载器，自动检测最新 `.bin`（`-dl`）
- **线缆工具**：启动 cable.exe，透传所有参数（`-cable`）
- **配置管理**：用系统编辑器打开 config.json 管理扫描路径和版本选择（`-cfg`）
- **自动检测**：`-filelist`、`-flow`、`-xpn`、`-device` 可省略 `.hqprj` 路径，自动检测当前目录下的第一个 `.hqprj` 文件

## 构建

从源码仓库一行命令完成编译并注册到 PATH：会先清理构建产物，再用 PyInstaller 打包，成功后自动将 `hqbuddy.exe` 复制到 `%APPDATA%\hqbuddy\` 并添加到用户 PATH：

```bat
python build.py
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

### HqInsight 在线逻辑分析仪

前提：开发板已连接。选信号可以在 HqFPGA GUI 中完成，也可以全程用 CLI（`-init`/`-ls`/`-add`/`-del`）完成。

```bat
hqbuddy -insight -init                     # 初始化 HqInsight 工程（elaborate 设计，无需 GUI）
hqbuddy -insight -ls [关键字]              # 列出设计信号（* = 已选入）
hqbuddy -insight -add dq_err -clk usr_clk -type both   # 添加信号（sample/trigger/both）
hqbuddy -insight -del dq_err               # 移除信号
hqbuddy -insight                           # 查看 HqInsight 工程状态（信号/触发条件）
hqbuddy -insight -trig                     # 交互式设置触发条件
hqbuddy -insight -trig "dq_err EQ 0"       # 参数式设置触发（EQ/GT/LT/NE/LE/GE）
hqbuddy -insight -trig "dq_err RANGE 1 10"           # 范围触发
hqbuddy -insight -trig "usr_clk RISE"                # 边沿触发（RISE/FALL/BOTH/X）
hqbuddy -insight -trig "dq_err EQ 0 AND usr_clk RISE"  # 双条件组合（AND/OR）
hqbuddy -insight -capture                  # 布防并等待触发，抓取波形（默认超时 60s）
hqbuddy -insight -capture -timeout 120     # 自定义超时
hqbuddy -insight -capture -force           # 强制触发，立即抓取
hqbuddy -insight -run                      # 重跑插桩实现流程（生成含 LA 的 .bin）
```

添加/移除信号后需执行 `-insight -run` 重新生成插桩 bitstream，并用 cable.exe 下载后方可抓取。注意 `-run` 末尾会拉起 hqdnload 下载器窗口，且进程会等该窗口关闭才退出。

抓取成功后生成 VCD 波形（`hqins_run/hq_import/<top>_insight_0_ww.vcd`），并打印触发时刻各信号的值。用 `hqbuddy -wave` 打开波形（自动定位 HqFPGA 自带的 GTKWave，可指定文件）。

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

按 `templates/clean_list.json` 中的清单清理脚本所在目录下的中间文件与空文件夹（保留 `.hqprj`）。清理前会二次确认，`-force` 跳过确认：

```bat
hqbuddy -clean
hqbuddy -clean -force
```

### 生成 IP 默认配置文件

从 IP meta XML 生成默认配置的 `.hqip` 文件。不带参数时，按当前工程的器件（或 `-device` 指定的器件）列出当前版本支持的所有 IP，交互式选择（支持模糊搜索 IP 名 / 变体 / 描述）：

```bat
hqbuddy -gen_hqip                          :: 交互选择 IP，按当前工程器件筛选
hqbuddy -gen_hqip -device SL2-12E-8F256    :: 交互选择 IP，显式指定器件
hqbuddy -gen_hqip <meta.xml>               :: 直接指定 xml 生成
```

生成的 `.hqip` 输出到 `ipcore_dir/<IP_NAME>/xsIP_<IP_NAME>.hqip`，可直接用 `hqbuddy -ipgen` 生成网表。

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

### 加密 HDL 源代码

调用当前所选版本自带的 `hq_ipencrypt.exe` 加密 `.v` / `.vh` 源文件（密钥文件自动定位，无需指定）：

```bat
hqbuddy -encrypt                         :: 缺省处理当前目录所有 .v 和 .f（.f 走 -l 分支）
hqbuddy -encrypt top.v core.v            :: 加密多个文件，输出到 encrypted/
hqbuddy -encrypt filelist.f -d out       :: 支持 .f filelist，-d 指定输出目录（自动创建）
hqbuddy -encrypt top.v -m aes128-cbc     :: 指定算法（缺省 aes256-cbc）
hqbuddy -encrypt top.v -po               :: 只加密 protect begin/end 块
```

### 启动 GUI

不带任何参数运行即启动 HqFPGA GUI（hqui）；将 `.hqprj` 文件路径作为首个参数传入可直接打开对应工程（注册文件关联后，双击 `.hqprj` 文件也会触发）。

```bat
hqbuddy              # 启动 GUI
hqbuddy example/ddrc_native_demo.hqprj  # 启动 GUI 并打开工程
```

### 命令行执行

通过 hqfpga CLI 执行指定的 TCL 脚本。不带参数时直接进入 hqfpga 交互式 CLI；也可以用 `-e` 直接执行一条 TCL 命令字符串。`-e` 模式支持 `-q` 安静模式：过滤 banner 和所有 `Info:` 行，只保留结果与警告/错误。

```bat
hqbuddy -cmd my_script.tcl              :: 执行 TCL 脚本
hqbuddy -cmd                            :: 进入 hqfpga 交互式 CLI
hqbuddy -cmd -e "dv.setup SEALION SL2-12E-8F256; dv.query"  :: 执行单条 TCL 命令
hqbuddy -cmd -e "dv.query" -q           :: 安静模式，只保留结果
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

### 配置（config.json）

配置保存在 `%APPDATA%\hqbuddy\config.json`，用 `hqbuddy -cfg` 打开编辑：

- `scan_path`：HqFPGA 安装根目录扫描列表，每个条目是一个目录，hqbuddy 会扫描其中形如 `hqv*_xist_*_win64` 的目录作为可用版本
- `selected_build`：当前选中的版本 build（由 `-build_sel` 维护，留空则自动使用最新版本）

修改保存后下次运行即生效。

### 其他命令

```bat
hqbuddy -h           # 显示帮助
hqbuddy -v           # 显示版本
hqbuddy -root        # 显示 HqFPGA 根目录路径
```

## 参数速查

| 参数                                  | 说明                                                                   |
| ------------------------------------- | ---------------------------------------------------------------------- |
| （无参数）                            | 启动 HqFPGA GUI（hqui）                                                |
| `<file>.hqprj`                      | 启动 HqFPGA GUI 并打开工程                                             |
| `-h`                                | 显示帮助                                                               |
| `-v`                                | 显示版本                                                               |
| `-root`                             | 显示 HqFPGA 根目录路径                                                 |
| `-build_sel`                        | 交互式选择 HqFPGA 版本（支持搜索与 latest）                            |
| `-filelist [<file>]`                | 从`.hqprj` 提取 FILE_SRC filelist，省略时自动检测                    |
| `-filelist [<file>] -o <out>`       | 将 filelist 输出到指定文件                                             |
| `-flow [<file>]`                    | 生成`hqprj2tcl` TCL 脚本，省略时自动检测，默认生成 `run_hqprj.tcl` |
| `-flow [<file>] -o <out>`           | 指定生成的 TCL 文件名                                                  |
| `-flow [<file>] -looptdo`           | looptdo 模式：合成后运行`design.looptdo` 搜索优化参数                |
| `-flow [<file>] -bin_only [<name>]` | bin-only 模式：仅生成`.bin`，不产生中间文件                          |
| `-xpn [<file>] [-o <file>]`         | 生成 XPN（普通模式），省略时自动检测，默认生成`hq.xpn`               |
| `-xpn -ins [<file>] [-o <file>]`    | 生成 XPN（hqinsight 模式），省略时自动检测，默认生成`hq_ins.xpn`     |
| `-xpn2bin [<file>] [-o <file>]`     | 将 XPN 转换为 BIN，省略时自动检测，默认生成`<input>.bin`             |
| `-device [<file>]`                  | 查看`.hqprj` 使用的器件型号                                          |
| `-device -set [<part>] [<file>]`    | 修改器件型号（支持交互式选择），并同步关联`.hqip`                    |
| `-new_prj <name> [-device <part>]`  | 从模板创建`.hqprj` 工程                                              |
| `-add <files...>`                   | 添加`.v` / `.vh` / `.sdc` / `.upc` / `.f` 文件到工程         |
| `-set_top <name>`                   | 设置顶层模块`TOP_MODULE`                                             |
| `-clean [-force]`                   | 按`clean_list.json` 清理工程目录，`-force` 跳过确认                |
| `-ipgen [<file>] [-lang <lang>]`    | 根据`.hqip` 生成 IP 网表，省略时自动检测                             |
| `-gen_hqip [<meta.xml>] [-device <part>]` | 生成默认配置 .hqip（省略 xml 时交互选择 IP）                  |
| `-update_ip [<file>]`               | 重新生成工程内所有 IP 网表                                             |
| `-encrypt [<files...>] [-d dir] [-m m] [-po]` | 加密 HDL 源文件（缺省处理当前目录所有 .v/.f，aes256-cbc，输出 encrypted/） |
| `-simlib [<dir>]`                   | 编译 XiST 仿真库到 ModelSim/QuestaSim，省略时自动检测 HqFPGA 根目录    |
| `-cmd [<file>]`                     | 通过 hqfpga CLI 执行 TCL 脚本；缺省时进入 hqfpga 交互式 CLI            |
| `-cmd -e "<tcl>" [-q]`              | 执行单条 TCL 命令字符串；`-q` 过滤 banner 与 `Info:` 行              |
| `-dl [-f <file>]`                   | 启动 hqdnload 下载器，省略时自动检测最新`.bin`                       |
| `-cable [args]`                     | 启动 cable.exe，透传所有参数                                           |
| `-wave [<file>]`                    | 用 GTKWave 打开 VCD 波形（缺省自动检测最新 insight 波形）              |
| `-insight [<file>]`                 | 查看 HqInsight 在线逻辑分析仪工程状态                                  |
| `-insight -trig [<expr>]`           | 设置触发条件（缺省进入交互向导）                                       |
| `-insight -capture [-force] [-timeout N]` | 布防并抓取波形为 VCD，`-force` 立即抓取                          |
| `-insight -run`                     | 重跑插桩实现流程                                                       |
| `-insight -init`                    | 初始化 HqInsight 工程（无需 GUI）                                      |
| `-insight -ls [关键字]`             | 列出设计信号                                                           |
| `-insight -add/-del <信号>`         | 添加/移除采样/触发信号                                                 |
| `-cfg`                              | 用系统编辑器打开 config.json（scan_path + selected_build）               |

## 开发与打包

```bat
:: 克隆仓库
git clone https://github.com/XiST-ZhC/hqbuddy.git
cd hqbuddy

:: 开发运行（Python 源码）
.\hqbuddy.bat -v
python -m hqbuddy -v

:: 打包 exe（先清理再构建，成功后自动注册 PATH 并安装 hqfpga Skill）
python build.py
```

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
│   ├── hqip_gen.py       # IP 默认配置 .hqip 生成（含交互式 IP 选择）
│   ├── encrypt.py        # HDL 源代码加密
│   ├── ipmgr.py          # IP 配置文件管理（内部使用）
│   ├── simlib.py         # XiST 仿真库编译
│   ├── insight.py        # HqInsight 在线逻辑分析仪（触发/抓取/VCD）
│   └── utils.py          # 版本解析与比较工具函数
├── scripts/
│   └── compile_xist.tcl  # XiST 仿真库编译脚本（手动或自动均使用此脚本，支持 .v / .vp）
├── skills/
│   └── hqfpga/           # Kimi Code Skill：HqFpga 操作指南（含 references 命令参考）
├── docs/
│   └── user_manual/      # HqFpga 官方用户手册（md / pdf）
├── hqbuddy.bat           # 开发入口（调用 Python 源码）
├── build.py              # 构建 / 清理统一管理，build 成功后自动注册 PATH 并安装 Skill
├── install_skill.py      # 安装 hqfpga Skill 到用户级 skills 目录
├── .gitignore
├── .gitattributes
├── AGENTS.md
├── LICENSE
└── README.md
```

## Kimi Code Skill：hqfpga

仓库内置一个面向 AI agent 的 Skill，让 agent 理解 HqFpga 的操作流程与 U 命令体系（设计流程、99 个命令参考、UDM、SDC/物理约束），由官方用户手册蒸馏而来。

运行 `python build.py` 打包时会自动安装；也可单独手动安装：

```bat
python install_skill.py
```

安装后重启 Kimi Code CLI 生效。Skill 源文件在 `skills/hqfpga/`，随仓库版本管理。

## License

[LICENSE](LICENSE)
