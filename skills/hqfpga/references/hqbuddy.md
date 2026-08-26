<!-- 来源：hqbuddy 仓库 README.md 蒸馏（hqbuddy 用法参考） -->

# hqbuddy 用法参考

hqbuddy 是 HqFpga 的辅助工具集（Python 编写，发布为独立 `hqbuddy.exe`），封装了版本管理、流程执行、工程文件操作、IP 生成、下载调试等常用操作。**操作 HqFpga 时优先使用 hqbuddy，而不是直接拼 hqfpga.exe 命令。**

## 版本与配置

- 多版本 HqFpga 并存时，hqbuddy 负责选择使用哪个版本：
  - `hqbuddy -build_sel` — 交互式选择版本（支持模糊搜索，`[latest]` 自动选最新）
  - `hqbuddy -cfg` — 用系统编辑器打开 `%APPDATA%\hqbuddy\config.json` 手动管理（`scan_path` 扫描根列表 + `selected_build` 选中版本，字段含义见仓库 README）
  - `hqbuddy -root` — 打印当前所选版本的根目录
- 版本信息持久化在用户配置中，设置一次后续命令自动使用

## 工程文件（.hqprj）操作

- `.hqprj` 是 INI 风格的工程描述文件：器件（`FAMILY`/`DIE`/`PACKAGES`/`SPEEDS`/`CONDITION`）、`TOP_MODULE`、`FILE_SRC`（.v/.vh，每个对应一行 `FILE_TIME`）、`FILE_TC`（.sdc）、`FILE_PC`（.upc，约束各对应 `FILE_TIME_CST`）
- `hqbuddy -new_prj <name> [-device <part>]` — 从模板创建工程；未指定器件时唤起交互式选择
- `hqbuddy -add <files...>` — 添加文件：`.v`/`.vh` → FILE_SRC，`.sdc` → FILE_TC，`.upc` → FILE_PC；支持 `.f` filelist（其中的相对路径相对于 filelist 所在目录）；找不到的文件与不支持的后缀会报错
- `hqbuddy -set_top <name>` — 修改 TOP_MODULE
- `hqbuddy -get_device [<file>]` — 查看器件；`hqbuddy -set_device [<part>] [<file>]` — 修改器件（支持交互式选择+模糊搜索），自动同步工程内 `.hqip` 的 `device=` 字段并校验 dv_list.xml
- `hqbuddy -get_pin_bank <pin> [-device <part>]` — 查询引脚所属 IO bank（缺省器件取当前目录 `.hqprj`），底层用 `dv.get_pin_bank`
- `hqbuddy -filelist [<file>] [-o <out>]` — 提取 FILE_SRC 列表
- `hqbuddy -clean [-force]` — 按内置清单清理工程目录（保留 .hqprj；当前目录无 .hqprj 时拒绝执行；`-force` 跳过确认，同时删除空目录）

## 流程执行

- **注意：`-flow` 只生成 TCL，不执行流程。** 生成后需再执行 `hqbuddy -cmd run_hqprj.tcl` 才真正跑实现流程；`-flow` 退出码为 0 只代表 TCL 生成成功
- `hqbuddy -flow [<file>] [-o <out.tcl>]` — 生成完整实现流程 TCL（默认 `run_hqprj.tcl`），内部用 `hqprj2tcl <prj.hqprj>`
- `hqbuddy -flow <file> -looptdo` — looptdo 模式：生成后保留综合部分，删除 pack/place/route/bitgen，替换为 `design.looptdo -sdc $SDC_FILE -upc $UPC_FILE -slack 0 -j 4 -timeout 1800`（自动搜索实现优化参数）
- `hqbuddy -flow <file> -bin_only [<name>]` — bin-only 模式：生成的 TCL 被精简为只产出 `.bin`（自动删除 .xpn/.rpt/.log 等中间文件的生成指令），名称缺省用流程默认
- `hqbuddy -xpn [<file>] [-o <out>]` / `-xpn -ins ...` — 生成 XPN 物理网表（普通 / hqinsight 模式）
- `hqbuddy -xpn2bin [<file>] [-o <out>]` — XPN 转 BIN
- 省略 `.hqprj` 参数时，自动检测当前目录下的工程文件
- **bitgen 需要引脚约束**：工程无 `.upc`（FILE_PC）时，bitgen 必停于 `ERROR(BIT-11): pads have no location constraint`——跑到 route 成功、bitgen 报这个错是预期行为，补 `.upc` 后即可

## hqfpga CLI 驱动

- `hqbuddy -cmd` — 进入 hqfpga 交互式 CLI
- `hqbuddy -cmd <file.tcl>` — 执行 TCL 脚本（原样输出）
- `hqbuddy -cmd -e "<tcl>" [-q]` — 执行单条 TCL 命令；`-q` 过滤 banner 和所有 `Info:` 行，只留结果与警告/错误。适合在脚本/自动化中查询信息，例如：
  ```bat
  hqbuddy -cmd -e "dv.setup SEALION SL2-12E-8F256; dv.query" -q
  ```

## IP 与仿真库

- `hqbuddy -gen_hqip [<meta.xml>] [-device <part>]` — 生成 IP 默认配置 `.hqip`（输出到当前目录 `ipcore_dir/<name>/xsIP_<name>.hqip`）。**从零创建 IP 配置的入口**：不带参数时进入交互式 IP 选择器（列出支持当前器件的 IP，支持模糊搜索，可搜 xml 中 describe 描述）；也可直接指定 ipdepot 中的 meta xml 路径跳过交互
- `hqbuddy -ipgen [<.hqip>] [-lang <lang>]` — 生成 IP 网表：从 `.hqip`（INI）中读取 `meta_file=` 定位 IP 的 xml（按当前版本安装目录重新定位），从 xml 同目录 `_ipgen_.desc` 读取 ipgen 程序路径，在 `.hqip` 同目录生成网表。典型流程：`-gen_hqip` 生成默认配置 → 按 ipdepot 文档修改参数 → `-ipgen` 生成网表
- `hqbuddy -update_ip [<.hqprj>]` — 对工程内所有 `.hqip` 全部重新执行 ipgen
- `hqbuddy -simlib [<dir>]` — 编译 XiST 仿真库到 ModelSim/QuestaSim（支持 .v/.vp）

## 下载与调试

- `hqbuddy -dl [-f <file>]` — 启动 hqdnload 下载器；缺省时自动选当前目录最新 `.bin`
- `hqbuddy -cable [args...]` — 启动 cable.exe，参数透传

## 其他

- `hqbuddy`（无参数）— 启动 HqFpga GUI（hqui）
- `hqbuddy <file>.hqprj` — 启动 GUI 并打开工程（.hqprj 关联打开也走此分支）
- `hqbuddy -h` / `-v` — 帮助 / 版本
- 中文输出：hqfpga/ipgen 等子进程输出为 GBK，在 UTF-8 终端会显示乱码，属显示问题、不影响执行结果
