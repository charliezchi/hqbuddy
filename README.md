# HqBuddy

智多晶海麒（HqFPGA）开发工具的辅助工具集。

## 当前版本

1.0.0

## 功能特点

- **提取 filelist**：从 `.hqprj` 工程文件中提取 `FILE_SRC` 源文件列表
- **路径解析**：自动将 `$WORK_DIR$` 替换为 `.hqprj` 文件所在目录的绝对路径
- **Flow 执行**：通过 hqlauncher 调用 `hqprj2tcl` 生成 TCL 脚本
- **XPN 生成**：从布线后的设计生成 XPN 文件，支持普通模式和 hqinsight 模式
- **XPN 转 BIN**：将 XPN 文件通过 `design.bitgen` 转换为 BIN 比特流文件
- **器件查看/修改**：查看 `.hqprj` 使用的器件型号，或修改为新器件（自动验证合法性）
- **IP 罗列**：列出工程中使用的 `.hqip` IP 配置文件
- **自动检测**：`-filelist`、`-flow`、`-xpn`、`-device`、`-ip` 可省略 `.hqprj` 路径，自动检测当前目录下的第一个 `.hqprj` 文件
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

**依赖**：`-flow` 需要 [hqlauncher](https://github.com/charliezchi/hqlauncher) 已安装并在 PATH 中。

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

**依赖**：`-xpn` 和 `-xpn -ins` 需要 [hqlauncher](https://github.com/charliezchi/hqlauncher) 已安装并在 PATH 中。

### XPN 转 BIN

将 `.xpn` 文件转换为 `.bin` 比特流文件。

```bat
hqbuddy -xpn2bin                           # 自动检测当前目录的 .xpn
hqbuddy -xpn2bin debug.xpn                 # 默认生成 debug.bin
hqbuddy -xpn2bin -o my_bitstream.bin       # 自动检测 + 自定义输出
hqbuddy -xpn2bin debug.xpn -o my_bitstream.bin
```

**依赖**：`-xpn2bin` 需要 [hqlauncher](https://github.com/charliezchi/hqlauncher) 已安装并在 PATH 中。

### 查看/修改器件

查看 `.hqprj` 当前使用的器件型号（格式：DIE-SPEED-PACKAGE-CONDITION）。

```bat
hqbuddy -device                            # 自动检测当前目录的 .hqprj
hqbuddy -device example/ddrc_native_demo.hqprj
```

修改 `.hqprj` 的器件型号，修改前会通过 `hqlauncher -ls -device` 验证器件是否合法。修改 `.hqprj` 的同时，会自动同步修改工程中直接使用的 `.hqip` IP 配置文件中的 `device=` 字段。

**注意**：此功能仅支持直接加入到工程中的文件（即 `.hqprj` 的 `FILE_SRC` 中列出的文件），不支持通过 `include` 等方式间接引用的文件。

```bat
hqbuddy -device -set SA5T-100-D0-7F676CI
hqbuddy -device -set SA5T-100-D0-7F676CI example/ddrc_native_demo.hqprj
```

### 列出 IP 配置文件

列出工程中所有使用的 `.hqip` 文件。对每个 `FILE_SRC` 源文件，检查同目录下是否存在同名 `.hqip` 文件。

```bat
hqbuddy -ip -ls                            # 自动检测当前目录的 .hqprj
hqbuddy -ip -ls example/ddrc_native_demo.hqprj
```

### 其他命令

```bat
hqbuddy -h              # 显示帮助
```

## 参数速查

| 参数 | 说明 |
|------|------|
| `-h` | 显示帮助 |
| `-v` | 显示版本 |
| `-filelist [<file>]` | 从 `.hqprj` 提取 FILE_SRC filelist，省略时自动检测 |
| `-filelist [<file>] -o <out>` | 将 filelist 输出到指定文件 |
| `-flow [<file>]` | 通过 hqlauncher 执行 hqprj2tcl，省略时自动检测，默认生成 `run_hqprj.tcl` |
| `-flow [<file>] -o <out>` | 指定生成的 TCL 文件名 |
| `-xpn [<file>] [-o <file>]` | 生成 XPN（普通模式），省略时自动检测，默认生成 `hq.xpn` |
| `-xpn -ins [<file>] [-o <file>]` | 生成 XPN（hqinsight 模式），省略时自动检测，默认生成 `hq_ins.xpn` |
| `-xpn2bin [<file>] [-o <file>]` | 将 XPN 转换为 BIN，省略时自动检测，默认生成 `<input>.bin` |
| `-device [<file>]` | 查看 `.hqprj` 使用的器件型号 |
| `-device -set <part> [<file>]` | 修改 `.hqprj` 及关联 `.hqip` 的器件型号，并验证合法性 |
| `-ip -ls [<file>]` | 列出工程中使用的 `.hqip` 文件 |

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
│   ├── flow.py           # Flow 执行（hqlauncher 调用）
│   ├── xpn.py            # XPN 生成（普通模式 + hqinsight 模式）
│   ├── xpn2bin.py        # XPN 转 BIN
│   ├── device.py         # 器件查看/修改
│   └── ipmgr.py          # IP 配置文件管理
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
