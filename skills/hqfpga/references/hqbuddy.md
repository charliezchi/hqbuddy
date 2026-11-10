<!-- 来源：hqbuddy 仓库 README.md 蒸馏（hqbuddy 用法参考）。对齐版本：hqbuddy 3.32.0 -->

# hqbuddy 用法参考

hqbuddy 是 HqFpga 的辅助工具集（Python 编写，发布为独立 `hqbuddy.exe`），封装了版本管理、流程执行、工程文件操作、IP 生成、下载调试等常用操作。**操作 HqFpga 时优先使用 hqbuddy，而不是直接拼 hqfpga.exe 命令。**

## 退出码语义（agent 判成败用这个，别靠输出文本）

- 常规约定：`0` = 成功；`1` = 失败（含所有 `Error:` 路径）；`-doctor` 任一 FAIL → 1；批量 `-xpn2bin` 任一失败 → 非零。
- **`-flow` 的 0 只代表 TCL 生成成功，不代表实现流程跑通**（它根本不执行流程）；`-build` 才带产物校验（无新鲜 .bin/.bit → 非零）。
- hqfpga 子进程崩溃码（如 4294967295）已被归一化为 1。

## 版本与配置

- 多版本 HqFpga 并存时，hqbuddy 负责选择使用哪个版本：
  - `hqbuddy -build_sel` — 交互式选择版本（支持模糊搜索，`[latest]` 自动选最新）
  - `hqbuddy -root` — 打印当前所选版本的根目录（**用来验证版本是否已就绪**：能打印出路径即已可用）
- 版本信息持久化在用户配置中，设置一次后续命令自动使用。

### 配置文件（首次使用前必须先配置好，否则找不到版本）

- 配置文件路径：`%APPDATA%\hqbuddy\config.json`。结构：
  ```json
  { "scan_path": ["C:\\"], "selected_build": null }
  ```
  - `scan_path`：HqFpga 安装根目录扫描列表，扫描其中形如 `hqv*_xist_*_win64` 的文件夹。
  - `selected_build`：null = 自动用扫描到的最新版本。
- **关键**：`scan_path` 默认 `["C:\\"]` 只扫 C 盘根；用户常装在别处——未配置时一切需要版本的命令报 `no HqFPGA versions found`。
- **agent 自助配置（不要用 `-cfg`，它开 GUI 编辑器）**：直接用文件工具读写该 JSON——定位用户 HqFpga 安装里 `hqv*_xist_*_win64` 文件夹的**父目录**，写进 `scan_path`，然后用 `hqbuddy -root` 验证能打印出路径。

## 工程文件（.hqprj）操作

- `.hqprj` 是 INI 风格工程描述：器件（`FAMILY`/`DIE`/`PACKAGES`/`SPEEDS`/`CONDITION`）、`TOP_MODULE`、`FILE_SRC`（.v/.vh，各配一行 `FILE_TIME`）、`FILE_TC`（.sdc）、`FILE_PC`（.upc，各配 `FILE_TIME_CST`）
- `hqbuddy -new_prj <name> [-device <part>]` — 从模板创建工程（无器件时交互选择）
- `hqbuddy -add <files...> [<.hqprj>]` — 添加文件：`.v/.vh`→FILE_SRC，`.sdc`→FILE_TC，`.upc`→FILE_PC；支持 `.f` filelist；目标工程可显式指定，缺省探测 cwd
  - 【实测】`-add` 同名文件返回 "Nothing to add"(不覆盖)——修改源文件内容后需 `hqbuddy -refresh_time <prj>` 刷新时间戳，否则流程仍用旧产物
- `hqbuddy -set_top <name> [<.hqprj>]` — 修改 TOP_MODULE
- `hqbuddy -get_device [<file>]` / `-set_device [<part>] [<file>]` — 查看/修改器件（交互选择+模糊搜索，自动同步 .hqip 的 device= 并校验 dv_list）
- `hqbuddy -get_pin_bank <pin> [-device <part>]` — 查询引脚所属 IO bank（底层 `dv.get_pin_bank`；无工程时用 `-device` 绕过）
- `hqbuddy -refresh_time [<.hqprj>]` — 重建 `FILE_TIME`/`FILE_TIME_CST` 条目（数目不一致时 GUI 打不开工程，用这个修）
- `hqbuddy -copy_prj <src.hqprj> <dst_dir>` — 复制工程到新目录：源文件/约束按原结构拷贝，FILE 路径改写为 `$WORK_DIR$` 相对引用，时间戳重建（解决"拷目录后工程仍引用旧绝对路径"）
- `hqbuddy -sync_prj [<tcl>] [<.hqprj>]` — 反向同步：把人在 `-flow` 产物 TCL 里手改的实现参数写回 `.hqprj`（映射关系是 hqprj2tcl 实测行为，非文档）
- `hqbuddy -filelist [<file>] [-o <out>]` — 提取 FILE_SRC 列表
- `hqbuddy -clean [-force]` — 按内置清单清理工程目录（保留 .hqprj）
- `hqbuddy -doctor [<.hqprj>] [--json]` — **接管陌生工程先跑这个**：源文件存在性/重复模块/时间戳一致性/器件合法性+授权（license.query）/UPC 球号与时钟 P 侧预检/HqInsight 状态，一次全查；任一 FAIL 退出码 1；`--json` 机器可读
- `hqbuddy -udev [<part>|<.hqprj>] [--arch|--iotype|--pkg] [-o <dir>] [--fmt text|csv|html]` — 原生 `'udev.*` 器件报告（**只需器件、无需设计**）。实现坑：同会话 `'udev.*` 互相干扰要分会话跑；`'udev.pkg.report` 直写控制台必须用 `-file`；`'udev.report` 的网格只在控制台输出里（3.23.0）

## 流程执行

- **agent 默认用 `hqbuddy -build [<.hqprj>]`**：生成 run_hqprj.tcl 并执行完整实现流程，带产物校验（无新鲜 bin 非零退出）。
- `hqbuddy -flow [<file>] [-o <out.tcl>]` — **只生成 TCL 不执行**（退出码 0 仅代表生成成功）。要自定义流程时：先生成再改，用 `hqbuddy -cmd run_hqprj.tcl` 执行。
  - `-looptdo`：保留综合段，替换为 `design.looptdo`（自动搜索优化参数）
  - `-bin_only [<name>]`：精简为只产 .bin
- `hqbuddy -synopt [<src.hqprj>] [-set k=<value> ...] [-show] [-clear]` — 工程级综合选项覆盖（sidecar `<proj>.synopt.json`，-flow/-build 全模式自动注入 hqprj2tcl 默认值之后）。键：infer_ram/infer_rom/infer_srl/fsm_opt/expr_opt/mux_opt/dsp_map/share_opt/macro_rebuild（rtl.set，on|off）、sweep/clk_conv/data_opt/merge/cut_merge（lo.slo.set，on|off）、`fsm_encoding`=auto|onehot|binary|gray|johnson（fsm.set -encoding，综合前）、`postsyn_areaopt`=tiny|low|std|high|extra|extreme|none|auto（postsyn.areaopt，注入 design.rtlsyn 之后；effort=high 在中大设计上要 15-20 分钟）；`cdc_sync`=on|off|<N>（综合后 lo.cdc_sync_reg.insert；⚠️ FT110126 实测不可用：无跨域目标静默无效果、含真实跨域使构建崩溃，RTL 手写同步链）
- `hqbuddy -seed_sweep [-ins] [-no_dl] [-n N] [-j J] [<src.hqprj>]` — 多种子 P&R 扫描：综合一次存共享 UDB，每 seed 独立进程并行重跑 P&R（默认 J=4），产物按 seed 分放 `seed_sweep/seed<N>/` + 汇总 `seed_sweep_summary.csv`（seed/WNS/fmax/耗时/status）；`-ins` 扫 HqInsight 插桩设计（先强制 -refresh 再跑官方 insight 流程，各 seed 位流带 VLA，产物在 `seed_sweep_ins/`）；完成后清下载备注并在 sweep 目录拉起 `-dl`（`-no_dl` 跳过，agent 用；bin 在 `seed_sweep[_ins]/seed<K>/` 直接 `-cable`）
- **insight 流程约束路径坑**：`.hqprj` 的 FILE_TC/FILE_PC 被 insight 流程使用时必须是 `$WORK_DIR$` 前缀（其 cwd 是 hqins_impl/），相对路径会"成功"却无 bin
- **bitgen 需要引脚约束**：工程无 `.upc` 时 bitgen 必停 `ERROR(BIT-11): pads have no location constraint`——route 成功后停这是预期，补 .upc 即可

## 报告与分析

- `hqbuddy -report [<dir>|<.hqprj>] [-paths N] [--json] [--diff <dirB>]` — **主流程报告摘要（agent 必用）**：Fmax（各时钟）/WNS（MET/VIOLATED）/资源利用率（IO/SLICE/LUT/FF/BRAM/DSP）/bit 文件；`-paths N` 提取最差 N 条违例路径；`--diff` 两轮对比；`--json` 机器可读
- `hqbuddy -analyze [<.hqprj>] [-n N] [-detail] [-toggle_rate X] [-o <dir>]` — **实现前设计体检**：综合一次（不 P&R），六类报告落 `<工程根>/analysis/`（clocks/fanout/clkdom/hier/power/loop.rpt，重跑只覆盖本工具 .rpt）+ stdout 摘要。FT110126 实测格式：`nl.clock.detect`/`ta.clock.list` 是返回值式（已 puts 捕获）、扇出排行需先 `nl.flatten -nmnc`、功耗需布线后设计（优雅降级）、`nl.hier.report` 该版本无输出；每段 catch 防护
- `hqbuddy -autosdc <src.hqprj> [-period ns] [-o out.sdc]` — **FT110126 上不可用**（tc.autogen 批处理会话静默无输出，疑似厂商变更）；用 `-analyze` 的 clocks.rpt 按时钟清单手写 SDC 替代
- XPN 可视化三件套（均从布线后 XPN，`-no_open` 静默、`-lang chs|eng`）：`-heatmap`（rtheatmap 热力图 JSON，只布局的 XPN 出全零图）、`-floorplan`（ChipEditor 布局图，只需布局）、`-routing`（rtviewer 布线图）；`-ffloc <clk_net> [<.xpn>]` — 导出某时钟域全部 SLICE FF 物理位置（官方 extr_slice_ff_loc 移植）
- `hqbuddy -xpn [<.hqprj>] [-o <out>] [-no_open] [-ins [-from_src]]` — 生成 XPN 物理网表（普通读 hq_run / `-ins` 读 hqins_impl；两条流的库不通用；`-from_src` 布线结果缺失时自动补跑 insight 实现）；`-xpn inspect [<file.xpn>]` — 解析 XPN 结构摘要（cwd 唯一 .xpn 可省略文件名）
- `hqbuddy -xpn2bin [<.xpn>] [-o <out>] [-no_dl]` — XPN 转 BIN：单个成功后自动探测板上型号并下载；批量时全部转换后拉起 `-dl`，任一失败退出码非零
- `hqbuddy -bitinfo <file.bin> [...] [--json]` — 纯 Python 解析 XiST 位流头（设计名/器件/架构/日期/大小；与 -dl 同一解析器；只读无会话），下载前核对 bin 身份

## 管脚工作流

- `hqbuddy -pinplan <src.hqprj> -board <板卡名> [-o <upc>]` — 引脚规划骨架：ioh.get_ports 取端口，按 boards/<板>.md 的 net→pin 表生成 phycst.pin.set 骨架（未匹配标 TODO）
- `hqbuddy -ucf2upc <in.ucf> [-o <out.upc>]` — Xilinx UCF 管脚约束转 UPC（厂商 ucf2upc 封装，FT110126 实测**可用**；无需设计；总线位输出为 名称<位> 形式需人工核对）
- `hqbuddy -pin2csv [<.hqprj>] [-o <out.csv>]` / `-csv2upc <in.csv> [-o <out.upc>] [-device <part>|<.hqprj>]` — UPC↔CSV 管脚表互转（Excel 工作流，两者配对）。**本地实现，勿用厂商 TCL 原生命令**（FT110126 实测 pin2csv 对已分配信号不填 Pad Location、csv2upc 静默产空 UPC）。pin2csv 先按 TCL 求值 UPC（板卡变体 set/if 条件分支取实际值）再与 'udev.pkg.report 封装表 join；csv2upc 消费其表头格式，器件可解析时先校验球名；vccio/ioh 约束不进 CSV 往返

## hqfpga CLI 驱动

- `hqbuddy -cmd` — 进入 hqfpga 交互式 CLI
- `hqbuddy -cmd <file.tcl>` — 执行 TCL 脚本（原样输出）
- `hqbuddy -cmd -e "<tcl>" [-q]` — 执行单条 TCL 命令；`-q` 过滤 banner 与 `Info:` 行，只留结果与警告/错误。例：
  ```bat
  hqbuddy -cmd -e "dv.setup SEALION SL2-12E-8F256; dv.query" -q
  ```
- 内部侧会话（doctor/udev/pin 查询等）的 hqfpga 日志统一落 `%TEMP%\hqbuddy\hq_logs\hqfpga.log`（最后一轮覆盖），用户 cwd 不被污染

## IP 与仿真库

- `hqbuddy -gen_hqip [<meta.xml>] [-device <part>] [--ip <name>] [--set k=v ...]` — 生成 IP 默认配置 `.hqip`（无参时交互式 IP 选择器；`--ip Tiny_SoC` 按名字非交互选择，`--set` 直接覆盖 [General] 键值，如 `--set INPUT_PARAMS.RAM_SIZE=65536`）
- `hqbuddy -ipgen [<.hqip>] [-lang <lang>]` — 生成 IP 网表（经 ipdepot `_ipgen_.desc` 定位 ipgen 程序）
- `hqbuddy -update_ip [<.hqprj>]` — 工程内所有 .hqip 全部重新 ipgen
- `hqbuddy -simlib [<dir>]` — 编译 XiST 仿真库到 ModelSim/QuestaSim（3.45.0 起按器件家族分库：**XiST_SEAL / XiST_SEALION / XiST_SHARK**——同名原语各家族内容不同（如 xsLUT4），混编一库会按编译顺序互相覆盖；seal/shark 库自动补编 sealion 目录的公共原语 xsDFF_K*；个别 SV 语法的模型（shark xsMIPI_CTRL）自动以 -sv 重试。门级仿真 `-L XiST_<家族>`，家族从器件查 dv_list：SL2S-25E→SEALION、SA5Z→SEAL）

## 第三方综合

- `hqbuddy -edf2v <a.edif> [-o <a.v>] [-device <part>]` — 第三方 EDIF 网表转 XIST 原语 Verilog（门级仿真用）
- `hqbuddy -netlist_build <a.edif> --upc <u.upc> --sdc <s.sdc> [-o <bin>] [-device <part>]` — 第三方网表一键 P&R+位流（缺 .upc 报 BIT-11）
- `hqbuddy -vla -gen [-name VLA] [-dir <dir>] [-device <part>]` — 调起 VLA IP 生成向导（半自动）

## 下载与调试

- `hqbuddy -dl` — GUI 下载器（detached 不阻塞；递归扫描 .bin 按位流头过滤 FPGA bitstream，点击即下载）；带参数透传 hqdnload
- `hqbuddy -cable [args...]` — 启动 cable.exe，参数透传（`--sealion` 下载前自动校验 `--model` 与板上实测型号一致）
- `hqbuddy -wave [<file.vcd>]` — GTKWave 打开波形（自动定位最新 insight VCD）

## HqInsight 在线逻辑分析仪

- `hqbuddy -insight` — 状态；`-init` 初始化；`-ls [kw]` 列信号；`-add/-del <sig>`（`-type sample|trigger|both`）；`-run` 跑插桩实现流程；`-trig [<expr>]` 布防；`-capture [-force] [-timeout N] [-o prefix]` 抓 VCD
- `hqbuddy -insight -refresh` — 原地重建插桩产物（保留信号选择与触发条件，等价 GUI 保存）。改 IP/RTL（逻辑**或属性**，含 IP 内部 include 的文件）后必须先 refresh 再 -run；也是 HQINS001 的恢复入口
- `hqbuddy -insight -depth N [-windows W] [-level L] [-position P]` — 采样参数（深度/窗口改后必须 -run+重下载才生效）
- `hqbuddy -insight -selftest` — 确定性回归自测（下载→布防→抓取→校验计数序列）
- 详见 references/insight.md（探针陷阱/触发语义/板况分相）

## VIO 运行时探针

- `hqbuddy -vio` — 查看探针登记（hqvla_vio/probes.json）
- `hqbuddy -vio -gen [-module m] [-in w] [-out w]` — 生成 VIO IP 模块（宽度 ≥1；标准实现流程即可，无需插桩）
- `hqbuddy -vio -reg -in cnt:8 [-in ...] [-out led:2 ...]` / `-reg -clear` — 登记探针（支持逗号分隔多探针）
- `hqbuddy -vio -read [-loop N] [-interval s]` / `-write <name>=<val>[,...]` — 运行时读/驱动（write 支持逗号分隔多赋值）
- 与 LA 互斥（一次一个 bit）、编译期 JTAG 槽冲突（PHY-PLA-665）：references/vio.md

## SoC 与杂项

- `hqbuddy -new_soc <name> [-core cm3|star] [-preset <example>] [-dir <p>]` / `-list_soc` — SoC 工程脚手架（FPGA+MCU）
- `hqbuddy -mcu_build [-p <file.uvprojx>]` — Keil 无人值守编译 MCU 固件（config `mcu_toolchain=gcc` 时走 arm-none-eabi-gcc）
- `hqbuddy -merge_bin <fpga.bin> <mcu.bin> [-o <file>] [-model SA30K] [-remap] [-dl]` — 合并 FPGA+MCU bin（-dl 直接下载）
- `hqbuddy -encrypt [<files...>] [-d dir] [-m m] [-po]` — 加密 HDL 源文件（输出 encrypted/）
- `hqbuddy -regression [--offline] [base_dir]` — 一键回归套件（触发捕获+错误路径+冒烟；--offline 跳过板卡项）
- `hqbuddy`（无参数）— 启动 HqFPGA GUI；`hqbuddy <file>.hqprj` — GUI 打开工程
- `hqbuddy -h` / `-v` — 帮助 / 版本；`-cfg` — 编辑 config.json
- `hqbuddy -autosdc --detect <prj>` — 时钟骨架模式（nl.clock.detect，FT110126 可用；端口时钟出 create_clock、内部/衍生转注释；周期占位需复核）——tc.autogen 路径不可用的替代
- 流程对齐配方（GUI 版流程多做、批处理可经 --hook 注入，FT110126 实测通）：`ioh.set_default_pullmode <NONE|DOWN|UP|KEEPER>`、`ioh.set_global_attr -unused_io tie_z`（Unused IO 悬空处理）——见 install_tree.md §10 流程对照
- `hqbuddy -serv`（交互 REPL）/ `-serv -f <file.tcl>` — 常驻会话（**单次调用**：eval server 单连接生命周期，跨进程 broker 实测不可行——守护理由见记忆；会话内多命令状态持久、错误后健康；通道仅限 ASCII 命令，中文内容用 -f + ANSI/GBK 文件；吞吐 2.7x 于逐条 -cmd -e）
- `hqbuddy -analyze --routed <布线后.xpn>` — 对布线后数据库跑六类分析（功耗真数据、层次报告可用；3 秒级）
- `hqbuddy -regression --offline` — 自包含离线回归（9 项，免基线/板卡）
- `hqbuddy -gatesim <routed.xpn> --tb <tb.v>` — 门级时序仿真一键化（XPN→网表+SDF 导出→vsim SDF 注解自动实例探测→gatesim.rpt；TB 需 xsGSR/xsPWR；布线后网表只需 XiST 库，U_PRIM 仅 EDIF 流程需要——FT110126 实测 SDF 注解 0 error）
- `hqbuddy -eco --query/--force-signal/--set-lut` — ECO 便捷子命令（两阶段查询、SLICE FF 一键钉死 A/B 侧通吃、A6LUT 方程改写；文本级免重布）
- `hqbuddy -flow/-build --hook STEP="script"` — 官方 ::HQ.DEBUG.STEP.* 阶段钩子注入（26 步白名单；综合/P&R 中途免重跑取现场）
- `hqbuddy -eco <routed.xpn> --script <eco.tcl> [-o <out.xpn>]` — 批处理 ECO：布线后 XPN 上跑 eco.* 修改并局部重布（脚手架全包，无需 eval server；实测通）
- `hqbuddy -ipdoc <ip> [--list] [--no_open]` — 定位并打开 IP 的 UG 用户手册（ipdepot 模糊匹配；全量索引见 references/ip_doc_index.md）
- `hqbuddy -tinysoc <sub>` — Tiny_SoC（RISC-V 软核，Seal 5000 全系 SA5Z/SA5T + SL2S/SL2D-25E）嵌入式软件全链：`new`（非交互生成 .hqip+ipgen，外设开关 `--uart0/--gpio/--plic` 等）、`fw <fw.bin|fw.elf>`（固件切 4 个 BIN lane 写回 .hqip 并重生成 IP——改固件=一条命令）、`bin`（仅切分，bin_regen 等价）、`sim --tb <tb.v>`（明文网表导出+ModelSim 网表仿真，TB 内置 UART 帧解码直接回显固件输出）、`list`、`ocd`（OpenOCD 指引+cpu0.yaml 最小替代+适配器要求）、`boardtest --detect|--loopback`（板测封装：detect_model 器件核对；环回小工程 build+下载+串口回显自检，缺省引脚 L23/K26/D19=SA5T-100 D0A2 官方 demo）。new 支持 --prj <proj> 自动挂载，并生成 tinysoc_template.sdc/upc + tinysoc_ports.txt 约束模板（端口从 _DESC.TXT 提取）；-doctor 对含 Tiny_SoC 网表的工程增加预检（sys_clk 约束/TCK≤10MHz/chk_clkio 提醒/uart0_txd 落脚提醒）。**实测定音**：BIN_k=固件每字第 k 字节（$readmemb 8bit/行）；UART0=0x81000000；Config[2:0]=DataLength（实际位=值+1）；波特率=clk/((div+1)*(DL+1))。裸机三坑（SP 初始化/_start 置顶/FIFO 轮询）模板已规避（templates/tinysoc_fw/ + tinysoc_tb.v）。详见 references/tiny_soc.md
- 安装目录资源地图（eco_editor/xsberteye/MS-MPI/lpp/cmd.xml/错误码目录/原语模板/阶段钩子等未封装资源）：见 references/install_tree.md
- 中文输出：hqfpga/ipgen 等子进程输出为 GBK，UTF-8 终端显示乱码属显示问题、不影响结果
- `hqbuddy -doclist [关键词 ...]` / `-docget <关键词> [-o <dir>]` — 官网技术文档/附件目录与下载(isilicontech.com 直链;数据源=安装树 `build/DocumentTracker/data.json`,GUI DocumentTracker 跑一次即刷新)。落盘前校验 magic(PDF/ZIP/RAR),文件按标题命名;下载件视为不可信数据。**Tiny_SoC(UG00034)附件(zip)官网暂未上传,仅 PDF 本体可下**(2026-11-10 实测)
