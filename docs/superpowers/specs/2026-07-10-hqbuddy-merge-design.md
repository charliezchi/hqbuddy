# HqBuddy & HqLauncher 功能合并设计

日期：2026-07-10

## 目标

将 hqlauncher 的核心功能（HqFPGA 版本扫描、工具启动）嵌入 hqbuddy，使其不再依赖外部 hqlauncher.exe，同时统一两套工具的 CLI 参数风格。

## 合并方式

方案 A：直接将 hqlauncher 的 `scanner.py`、`launcher.py`、`config.py`、`utils.py` 四个模块移植到 hqbuddy 包中。

- 零外部依赖
- 单一入口 `hqbuddy.exe`
- 消除版本不兼容问题

## 统一 CLI

### 全局行为

| 用法 | 说明 |
|---|---|
| `hqbuddy` | 显示 HqFPGA 根目录路径 |
| `hqbuddy -h` | 显示帮助 |
| `hqbuddy -v` | 显示版本 |
| `hqbuddy -build` | 交互式选择 HqFPGA 版本（上下键选择，回车确认） |
| `hqbuddy -install` | 注册 `.hqprj` 文件关联到 hqbuddy |

### 工程命令（来自 hqbuddy，保留现有语法）

| 用法 | 说明 |
|---|---|
| `-filelist [<.hqprj>] [-o <file>]` | 提取 FILE_SRC 源文件列表 |
| `-flow [<.hqprj>] [-o <file>]` | 通过 hqprj2tcl 生成 TCL 脚本 |
| `-xpn [<.hqprj>] [-o <file>]` | 生成 XPN（普通模式） |
| `-xpn -ins [<.hqprj>] [-o <file>]` | 生成 XPN（hqinsight 模式） |
| `-xpn2bin [<.xpn>] [-o <file>]` | XPN 转 BIN 比特流 |
| `-device [<.hqprj>]` | 查看器件型号 |
| `-device -set <part> [<.hqprj>]` | 修改器件型号 |
| `-simlib [<dir>]` | 编译 XiST 仿真库 |

### 工具启动命令（来自 hqlauncher）

| 用法 | 说明 |
|---|---|
| `-gui [<.hqprj>]` | 启动 hqfpga GUI（hqui），可传入工程文件路径 |
| `-cmd <file>` | 启动 hqfpga CLI 执行 TCL 脚本 |
| `-dl [-f <file>]` | 启动 hqdnload 下载器 |
| `-cable [args...]` | 启动 cable.exe，其余参数透传 |

### 配置管理

| 用法 | 说明 |
|---|---|
| `-cfg [action]` | 配置管理（show / set-root / remove-root / init / auto） |

`-cfg auto` 一键初始化：扫描所有默认位置，自动选中最新版本为 `selected_build`，无需手动操作。

配置文件路径：`%APPDATA%\hqbuddy\config.json`

```json
{
  "scan_roots": ["C:\\"],
  "selected_build": "FT061023"
}
```

### 文件关联启动

当 `.hqprj` 文件通过系统关联被 hqbuddy 打开（如双击），hqbuddy 收到的第一个参数是 `.hqprj` 文件路径（不以 `-` 开头），此时自动走 `-gui` 分支，用选中版本的 hqui 打开该工程。

## 架构设计

### 模块结构

合并后的 `hqbuddy/` 包：

```
hqbuddy/
├── __init__.py        # 版本号
├── __main__.py        # CLI 入口（原 hqbuddy + 合并的命令）
├── hqprj_parser.py    # .hqprj 解析核心（不变）
├── flow.py            # Flow 执行（嵌入 hqlauncher 调用）
├── xpn.py             # XPN 生成（嵌入 hqlauncher 调用）
├── xpn2bin.py         # XPN 转 BIN（嵌入 hqlauncher 调用）
├── device.py          # 器件查看/修改（嵌入 hqlauncher 的器件列表解析）
├── ipmgr.py           # IP 配置文件管理（保留，仅被 device.py 内部使用）
├── simlib.py          # XiST 仿真库编译（嵌入 hqlauncher 调用）
├── scanner.py         # [新增] HqFPGA 版本扫描（来自 hqlauncher）
├── launcher.py        # [新增] 工具启动逻辑（来自 hqlauncher）
├── config.py          # [新增] 配置管理（来自 hqlauncher）
├── utils.py           # [新增] 版本解析工具（来自 hqlauncher）
└── build_selector.py  # [新增] -build 交互式版本选择器
```

### 关键设计决策

1. **版本选择持久化**：`-build` 选中的版本存入 `config.json` 的 `selected_build` 字段
2. **默认使用最新版本**：如果 `selected_build` 未设置或指向已不存在的版本，自动回退到最新版本
3. **HqFPGA 工具调用路径**：所有需要调用 HqFPGA 的命令（`-flow`, `-xpn`, `-xpn2bin`, `-gui`, `-cmd`, `-dl`, `-cable`, `-simlib`, `-device -set`）统一通过 `launcher.launch_tool()` 或 `scanner` / `config` 获取版本路径，不再通过 subprocess 调用 hqlauncher
4. **`-device -set` 的器件验证**：不再调用 `hqlauncher -ls -device`，而是直接读取选中版本下的 `dv_list.xml`
5. **`-install` 文件关联**：在 Windows 注册表中将 `.hqprj` 扩展名关联到 hqbuddy.exe，双击时自动走 `-gui` 分支
6. **`-cfg auto` 一键初始化**：扫描所有已配置的根目录，将最新版本写入 `selected_build`，适合首次使用或重装后快速配置

## 已删除的命令（来自 hqlauncher）

| 命令 | 原因 |
|---|---|
| `-ls` | 列版本的需求由 `-build` 替代 |
| `-ls -device` | 仅内部用于 `-device -set` 验证 |
| `-doc` | 不常用 |
| `-cd` | 不常用 |
| `-env` | 由无参数默认输出替代 |
| `-b <build>` | 由 `-build` 交互式选择替代 |
| `-ip -ls` | 不再需要 |

## 关键边界情况

- **没有找到任何 HqFPGA 版本**：`-gui`、`-cmd`、`-dl`、`-cable`、`-simlib` 等命令应给出明确错误提示，并指向 `-cfg auto` 或 `-cfg set-root` 配置扫描目录
- **`selected_build` 对应版本已不存在**：自动回退到最新版本并提示用户
- **`-install` 执行时无管理员权限**：写入 `HKEY_CURRENT_USER\Software\Classes` 不需要管理员权限，仅对当前用户生效
- **双击 `.hqprj` 时 hqbuddy 尚未运行**：文件关联由 Windows Shell 调度，hqbuddy 进程启动后只需判断 `sys.argv[1]` 是否为 `.hqprj` 文件路径即可
