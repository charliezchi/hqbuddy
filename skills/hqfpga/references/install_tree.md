<!-- 来源：FT110126 安装目录全树盘点（2026-11-06，hqbuddy C7 轮实测/strings 取证）。
     路径基准 <HQ>=安装根（如 C:\hqv3_xist_3.1.1_FT110126_win64）。未列出的散件（字体/加密 .etc/lic）勿动。 -->

# HqFPGA 安装目录资源地图

安装树里 hqbuddy 与本 skill 此前未覆盖的工具与资源，按用途分组。**注意**：`build\eco_editor\`、
`build\xsberteye\` 与其依赖（hqfpga.exe / cable.exe）是相对路径部署耦合（`../win_x64/bin`、
`..\hqdnload\cable.exe`），移动/精简安装目录会断链，勿单独拷贝子目录。

## 1. 未封装的 GUI 工具（了解用途，勿删）

| 工具 | 路径 | 用途与取证 |
|---|---|---|
| **eco_editor.exe** | `build\eco_editor\` | ECO 编辑器 GUI。strings 证据：启动契约 `eco_editor -l chs\|eng [-x XPN][-d DUMP][-u UDB]`；它以子进程+端口方式驱动 hqfpga（`@guisrv`），UI 流程=导入 XPN/DUMP/UDB → `design.reset` → `xpn.read` → 编辑 program 属性（类型/布尔函数/引脚配置）→ `xpn.write` → 出 bit（保留 `*_after.xpn`）。**编辑表格是 GUI-only，后端动作全部有对应 `eco.*` TCL 命令**（见 §3） |
| **xsberteye.exe** | `build\xsberteye\` | XSBERT IP 的眼图/误码率扫描前端（Serial I/O Links、Tx/Rx Pattern、Loopback、Inject Error、眼图 QCustomPlot）。它通过 `..\hqdnload\cable.exe --svf <file>` 播放自动生成的 SVF 序列（scan_pre1/scan_check2/scan_dataget3/scan_next_get4），结果回读 `Ibert_svf/out.csv`。链路调试流程：实例化 XSBERT IP（UG00036）→ bitgen 下载 → 本 GUI 扫描。CLI 无法直接出眼图 |
| **DocumentTracker.exe** | `build\DocumentTracker\` | 官网技术文档同步器（定时从 XiST 官网拉文档）。`Doc\` 下已缓存 AN05204（SA5Z-50 硬件设计指导）、DS02001（Sealion 2000 数据手册 V2.13）两份 PDF，查硬件设计问题时先看这两份 |

## 2. 命令行工具与运行时（潜在可封装）

| 资源 | 路径 | 说明 |
|---|---|---|
| **MS-MPI 多进程布线** | `build\win_x64\bin\msmpi.dll` + `build\common\util\{mpiexec.exe,smpd.exe}` | hqfpga.exe 内嵌 `-mpi` 顶层参数与 rtMpiRouter；实测（2026-11-06）：**无需 smpd 守护**，`mpiexec -n N hqfpga.exe -mpi -cmd t.tcl` 直接多进程跑通（双进程 RC=0；路由并行度对大设计的收益待测） |
| **fpl.exe（ML 布局器）** | `build\win_x64\bin\fpl.exe` + `build\win_x64\lib\fpl.d\`（各器件超参 cfg.json） | PyInstaller 程序（torch/numpy）；是 `lpp.fpl` TCL 命令的执行体，**不要直接跑**。RELEASE_NOTE FT101126："Add experimental LPP (Lut-level Packing&Placement) support (disabled by default)" |
| **hq_ipencrypt.exe** | `build\common\util\hq_ipencrypt.exe` + 同目录 `keys.txt` | 用法：`hqencrypt -l <list> -pk <keys_file> [-m aes128-cbc\|aes256-cbc] [-po]`。keys.txt 是 IEEE P1735 公钥表（勿改）。hqbuddy `-encrypt` 已封装 |

## 3. eco.* 命令族（ECO 完全可 CLI 化）

`eco_editor` 只是 GUI 壳，后端命令全部在 hqfpga TCL 里（strings 取证的完整清单）：

```
eco.init / eco.end / eco.clear_clock / eco.set_clock / eco.place / eco.route
eco.forbid_route_node / eco.set_route_points / eco.export / eco.validate
eco.icdelay.annotate / eco.report_pin_delay
eco.query.comp_index / eco.query.design_state / eco.query.program_detail / eco.query.routing_state
eco.signal_probe[.xist.seal|.sealion|.shark]
```

典型链路（GUI 流程的命令化）：导入 XPN/DUMP/UDB → `xpn.read` → 改 program 属性 → `eco.place/eco.route` → `xpn.write` → bitgen。
**hqbuddy 3.37.0 已封装：`hqbuddy -eco <routed.xpn> --script <eco.tcl> [-o out.xpn]`**（脚手架全包，脚本只写 ECO 修改；FT110126 实测 eco.route→xpn.write 全链通）。

**两级修改配方（FT110126 实板验证 2026-11-06）**：
- **方程/属性类修改（改 LUT 方程、IO 属性、FFMUX 选择等 program 字段）→ 无需重布**：直接文本编辑 XPN
  （program 段是明文，如 `"A5LUT:#LUT:O5=(A2@A4) "`，@=XOR * =AND + =OR ~=NOT；`#OFF`=未用）→ `hqbuddy -xpn2bin <改后.xpn>`
  直接出 bin（bitgen 直接消费 XPN 配置）。
- **结构类修改（改网线、挪 site、增删单元）→ 需要 `hqbuddy -eco`（eco.route 局部重布）→ -xpn2bin**。
- 查询接口：`eco.query.comp_index`（返回 JSON：全部 comp 按 PIO/SLICEL/IOLOGIC 分组 + site）、
  `eco.query.program_detail {comp名}`（返回该 comp 完整 program JSON——LUT 方程/FFMUX/INIT/SR 全字段，**注意 comp 名含 [ ] 时要花括号**）。
- 实证案例：comp bus_b_raw[2] 的 `AFFMUX:AX→O6` + `A6LUT:#OFF→#LUT:O6=(A6+(~A6))` 两处协同修改（FF 的 D 从
  直连路由切到恒 1 LUT）→ -xpn2bin → 上板 led[2] 恒亮；与基线 bin 差异 3846 字节（局部生效特征）。**注意**：hqbuddy 此前的决策边界是不做 eval-server（-guisrv）路线的 ECO/常驻会话——本节是普通批处理会话内的 eco.* 命令，二者不同；是否封装成 hqbuddy `-eco` 待用户定夺。

## 4. lpp.* 实验命令族（Lut-level Packing & Placement）

**FT110126 实测（2026-11-07）：只读分析命令不可用**——`lpp.grid_report` 与
`lpp.export_pin_delay` 崩溃（TIEOFF block 缺失，lpp_util:420）、`lpp.export_conn` 静默无产物。
`-lpp_report` 封装立项否决，待新版验证。

## 5. 知识与参考文件（agent 查询用）

| 资源 | 路径 | 价值 |
|---|---|---|
| **IP 用户手册 97 份** | `build\ipcreator\sup_files\ipdepot\<IP>\UG*.pdf` | 84 个 IP 各带 UG 手册；索引见本 skill [ip_doc_index.md](ip_doc_index.md) |
| **GUI↔TCL 官方对照表** | `build\common\gui\cmd.xml`（+ `flow.xml` 步骤定义） | `<ucmd>` 表 = "GUI 每个动作对应哪条 TCL 命令"的官方映射（design.load/reset/save、nl.*、ta.*、edif/xdl/nvlg、design.tmr、saveUdm/loadUdm 等）；比逆向 GUI 快 |
| **三语错误码消息目录** | `build\common\message\{chs,eng,jpn}\{default,advopt,device,netlist,phy,sfe}.xml` | 错误码 → 官方文本（RT0019、FOBJ003 等排障时查表） |
| **原语/约束代码模板库** | `build\win_x64\hqui\resources\app\languagetemplates\`（templates.csv 索引 + *.code） | Verilog 原语例化（seal/sealion_syn_prim：LUT/FF/BRAM/FIFO/DSP/SERDES/DDR/PCIE…）、UPC/SDC、JTAG/VIO 调试模板——不用翻手册的最快例化参考 |
| **综合阶段钩子范本** | `build\common\debug\step_dbg_sample.tcl` | `::HQ.DEBUG.STEP.*` 变量：BeforeAnalyzeHDL/AfterRtlsyn/BeforeTmap… 各阶段前后自动执行的 TCL（示例含 design.saveSdb/bef_rsyn.udb）——官方流程插桩机制，定位综合问题比重跑全流程高效 |
| **官方批处理 TCL 骨架** | `samples\i2c_master_top\rtl_flow\t.tcl`、`samples\ac97\rtl_flow\t.tcl` | dv.setup → analyze → rtlsyn → sdc.read（演示 `tc.autogen -print -ccf -allio` 备选）→ tdomap → ta.report → upc.read → pack/place/route → nl.report → nl.write -phy → bitgen；ac97 的 upc 演示 `phycst.pin.set` 三种位选语法 `port(0)` / `port<1>` / `{port[2]}` |
| **英文版用户手册** | `doc\hqfpga_um_eng.pdf`（+ chs 版已知） | 按用户语言选 |
| **RELEASE_NOTE.TXT** | 安装根 | 各构建号的功能清单（新命令、修复）——判断"某命令从哪个版本开始有"的第一来源 |
| **samples 例程** | `samples\{ac97,i2c_master_top}` | 完整可跑最小流程范本（含 .sdc/.upc），新手入门指路 |

## 6. 器件数据库与库文件

| 资源 | 路径 | 价值 |
|---|---|---|
| dv_list.xml | `build\common\device\dv_list.xml` | 全部器件/封装清单（hqbuddy 器件搜索的本地数据源） |
| macro_lib | `build\common\device\xist\sealion\macro_lib_*.tcl`（4 份） | 宏单元→bram/dram 分类映射（第三方综合排错资源类型时参考） |
| 时钟专用资源表 | `build\common\device\xist\seal\200k_clkdst\200k_clksrc` | 200K 系列时钟资源 |
| **U_PRIM 通用仿真原语** | `build\common\sim\verilog\U_PRIM\`（HQ_FF_*/HQ_LATCH_*/HQ_PRIMS/HQ_TRIBUF/mcnc_prim） | **第三方综合门级仿真需 U_PRIM + `sim\verilog\XIST\{seal,sealion,shark}\` 一起编译**——此前 skill 只覆盖 XIST 目录 |
| 加密器件模型 | `build\common\device\xist\**\*.ebz/.egr/.etc` | 器件模型本体（勿动） |

## 7. 下载器与驱动排障素材

| 资源 | 路径 | 说明 |
|---|---|---|
| 下载器手册 | `build\hqdnload\script0\UG00001_DnloadUserManual_V2.5.pdf` | 下载失败/HS 模式查错第一来源 |
| JtagPro 桥固件 | `script0\JtagPro_*.bit`（SL7K/12K/22K/25K、SA30K/30K213/50K_324/50K_484） | 各器件专用 JTAG 下载桥固件；另有 HSPI_DOWNLOADER/IAP_BOOT/USB_HSPI 固件 |
| 操作序列脚本 | `script1\*.xuc`（jtag/mspi） | 下载器内部脚本，勿动 |
| BSDL | `build\hqdnload\bsdl\*.bsdl` | Sealion 各封装边界扫描描述 |
| 线缆驱动 | `driver\win_install_HS\`（CH372/CH375 高速线，WCH）+ `win_install_LS\`（USB CDC/libusb）+ `Linux_install_usb.sh` | HS=CH372 高速线；LS=USB CDC/libusb 模式；V7.0 起下载器自动检测 HScable |

## 8. HqInsight 附属

| 资源 | 路径 | 说明 |
|---|---|---|
| MLA 数据手册 | `build\HqInsight\instrumentor\doc\HqInsight_MLA_DataSheet.pdf` | 多 LA 硬件资料 |
| 波形查看器配置 | `build\HqInsight\instrumentor\config.toml` | HQwave 外观/行为可定制 |
| 信号名翻译器源码 | `build\HqInsight\instrumentor\translator\`（Python） | 插桩信号名映射参考（低优先） |
| VIO 调试器 | `build\HqInsight\VioDebugger\hq_vio_dbg.exe`（内置 ripgrep） | GUI VIO 调试器 |

## 9. IP 生成内幕（排错用）

- `.hqip` → `ipdepot\<IP>\<variant>\_ipgen_.desc` → 生成器：`INDEPENDENT=YES` 的 IP 用自带 `INDEPENDENT_EXE`（21 个 IP 族有 `_ipgen_\` 私有环境：vio/vla/mvla/cortexM3/pll/serdes/pcie/ebr_* 等），其余走通用 `ipgen_*` 生成器（`build\ipcreator\ipgen_{adc,ddrc,dsp_*,hdl_ip,sed}.exe`，Python 启动器，逻辑在 `lib\`）。
- FT110126 起**非独立 IP 输出 `<ip>_inst.v` 例化模板**——生成网表后照抄例化。
- `ipcr_chkmeta.exe`：IP 包元数据校验（被 ipcreator 内部调用，无独立使用价值）。
- GUI 主程序驱动脚本参考：`build\win_x64\hqui\resources\app\public\tcl\`（common/project/runSynthesis/downloadBit.tcl）——官方 GUI 的 TCL 封装，可作 hqbuddy 自研逻辑的交叉验证。
- Tcl 运行时（`build\win_x64\lib\tcl8.6\`）无独立 tclsh，不能当通用 shell 用。


## 10. GUI 官方 TCL 层（第二轮深挖·最重要发现）

hqui（Electron）无参 spawn hqfpga.exe 后 **stdin `source` 这 5 个 TCL 文件**，之后所有 GUI 动作都是调其中的 proc——它们就是厂商的官方 CLI 层（共 4799 行，可直接 source 复用或抄序列）：

`build\win_x64\hquiesourcespp\public	cl\{common,runSynthesis,downloadBit,project,dealChinese}.tcl`

### 与 hqprj2tcl 生成物的流程差异（GUI 版多做的事）

- `tc.clear -del_tc_hier`（层次约束清除）；`tc.autogen -period <1000/Fmax>`（按 GUI Fmax 字段）
- `ioh.set_default_pullmode <NONE|DOWN|UP|KEEPER>` + `ioh.set_global_attr -unused_io tie_z`
- `impl.guide.query -keep_hier` 为 1 时：`impl.guide.unset -keep_hier` + `design.flatten`
- `design.tdomap -no_ioins`；`ta.set -actrl2q`；`lo.slo.set -ff_init force0|force1`；`rtl.incpath.clear/add`
- bitgen 三连发：bit →（BGEN_1）`-bin` →（BGEN_4）`-rbin`，全选项 `-compress -nocrc -framecrc -trans_mode -sspi -i2c -config {...} -dclk <八档> -fuse_protect`（fuse_protect 为隐藏选项），同写 `<PROJ>.bgen.txt`
- dump 续跑：每阶段 `design.save hq_temp/_step_run_*.dump` + `.dumpValidation` 哨兵 + `info.udbversion` 版本比对 → 增量编译
- 报告双跑：`lang.set eng` 切换技巧；XML 化：`udt::'mrpt2xml/prpt2xml`

### GUI 里有、hqbuddy 还没有的现成配方（project.tcl/common.tcl）

| 配方 | 命令序列 |
|---|---|
| 时钟探测→SDC 骨架 | `sdc.start` → `nl.clock.detect -net -type` → `sdc.end` |
| IO 属性表/UPC 校验数据源 | `ioh.get_ports I\|O\|B`、`ioh.get_iotype <port>`、`ioh.get_attr_val <p> <iotype> <attr>`、`dv.bank.list`、`dv.vccio.list`、`ioh.get_dpio*` |
| 时序查询对话框 | `taset.query -all` → `ta.set -analysis_type both ...` → `ta.run` → `ta.report -no_sta -type t -n N -from/-to/-through ...` |
| 源文件依赖全清单 | `rtl.srcfiles.list -print -o> f` |
| VIO/VLA 在位检查 | `insight.check has_vio` / `has_vla` |
| EDIF 导入增强 | `edif.read -lut_combine` → `nl.merge_cut` → `lo.ffctrlset.opt`；`nl.write -eqn` |
| 功耗估算流水线 | `nl.power.params.report -file` → hqui `powerCalc` 路由的 xls 模板填充（`server\templates\power_calc_*.xls`） |

### 其他高价值事实

- **.hqprj 权威格式**：cp936 编码 key=value；FILE_*/FILE_TIME 可重复（=lappend）；RTL_1..17/GLOBAL_*/MAP_*/PACK_*/PLACE_*/ROUTE_*/BGEN_1..13/DIMPORT_1..3；WORK_DIR 键被忽略——hqbuddy 解析/生成以此为准（common.tcl readOptV3）
- **hqfpga.js FLAG 协议**：`FLAG:synthesisDone/placeDone/routingDone/bitGenDone`、`logSeg:xxx:Begin/End`、`FLAG:TOPLIST:`、`FLAG:SDCUPC:READ:START/END`——hqbuddy 解析 hqfpga 输出可对齐同一套标记（server/hqfpga.js 3000+ 行）
- **编程器 CLI**：`hqdnload.exe -f <bit> -family <fam> -lang L`，fam 由 die 推导（SL2-12X→sealion12x、-30→seal30k…）；ipcreator/ChipEditor/rtviewer/rtheatmap/hq_ins/hq_vio_dbg 的完整 CLI 契约见 downloadBit.tcl 注释块
- **mcnc_prim.v**："for edif verify"（MCNC 基准 EDIF 验证用）；U_PRIM 共 38 文件（HQ_FF 24 + HQ_LATCH 9 + TRIBUF/PRIMS/XCV stubs）
- **macro_lib_22k.tcl**：`obj.cell.set /MACRO_SYN/MSYN_RAM_9216_B8KS1S1WW bram` 形式的宏映射——MSYN_ 命名 = 类型_宽度_深度_端口模式编码，读网报时理解 RAM/ADD 推断结果
- **功耗数据源**：`sealion_pwr.xml`（每封装热阻/静态电流常量）+ power_calc xls 模板 + params.report
- **DocumentTracker**：`Doc\AN05204_SA5Z-50 硬件设计应用指导` 与 `DS02001_Sealion 2000 数据手册`；`data.json` 含官网文档标题与 `/Private/NewsImgs/<ts>.pdf` 下载相对路径（主站域名需实验）
- **dealChinese.tcl**：中文路径 workaround——**.hqprj 以 cp936 读取**；中文工程走临时 ASCII 文件 + `xxxChinese <tempFile>` 包装 proc
- chipeditor/xsberteye 目录本体纯 GUI 无脚本（上轮结论维持）；ChipEditor Sealion 模式输入由 `'ui.save_inst`/`'ui.save_net` 导出（`-s <xml> -l <fp.inst.info> -n <fp_net.info>`）

## 11. FT110826 构建增量与实测结论(2026-11-10,hqbuddy 3.45.0 探测)

**构建演进**(RELEASE_NOTE.TXT):FT110526 = LPP refine(MCP IO 约束/pin offset)、
功耗报告支持 post-pack 资源统计、下载器 V7.5;FT110826 = Shark 80K(EBR fuse/
PIO_MIPI/PROG_INCR_CMP)、MIPI 仿真/LEC 模型、Routing Viewer Seal 200K、Heatmap
Seal 80K+按时钟域热图、IP Creator tag 禁用 IP。`bin/` 与 `cmd.xml/flow.xml`
与 FT101726 无增删(纯主程序迭代);CM33_Creator.exe 移入 STAR_Processor/ 目录。

**探测结论(hqbuddy 3.45.0 沙箱,SL2S-25E 工程)**:

| 探测项 | 结论 |
|---|---|
| `lpp.*` 只读命令 | **复测仍不可用**:`lpp.grid_report` json parse error(空输入)、`export_pin_delay` 0 字节静默无产物;grid_report 还需器件 .pdv(见下)。`-lpp_report` 立项否决维持 |
| `SL2S-25E.pdv` | `device/xist/sealion/SL2-25E.pdv` 缺失(FILE003/FILE501)——依赖 .pdv 的命令(rt.genResourceUsage/lpp)在该器件上不可用;`-heatmap`/`-routing` 对 SL2S-25E 不可用(FT110826 的 Heatmap 新增支持是 Seal 80K) |
| 功耗流水线 | **post-pack 可用**:`nl.power.params.report` 需 baseline——BeforePack(map 后 pack 前)`-baseline_out x.json -refresh_baseline`,AfterPack `-baseline_in x.json -file out.txt` 出 746KB 机器可读详表(时钟/逻辑/翻转率/扇出);`nl.power.report`(功耗分析本体)仍需布线完成,否则 WARN(PWR001)。封装立项见 TODO |
| `impl.bitgen.xist.sealion` 完整语法 | `-bin -compress -compress_line_len <n> -config <s> -dclk <s> -ext_crystal -framecrc -fuse_protect -i2c -nocrc -rbin -rxfb -sspi -trans_mode -v`(-ext_crystal/-rxfb/-compress_line_len 为 install_tree §10 清单之外新发现;GUI 全选项三连发 bit→-bin(BGEN_1)→-rbin(BGEN_4)) |

**编程器 family 推导权威源**(downloadBit.tcl:100-140):SL2 trait → sealion,
die 后缀 -12X→sealion12x/-12→12k/-25→25k/-7→7k/-5→5k/-4→4k/-2→2k;SA trait →
seal,-30→seal30k/-100→seal100k/-50→seal50k/-366→seal366k/-126→seal126k/-22→
seal22k/SCM905;其它族不加 -family。hqbuddy `-dl -f <bit>` 已自动推导(3.45.0)。
