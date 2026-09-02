---
name: hqfpga
description: Use when working with XiST HqFpga FPGA development - .hqprj project files, hqfpga.exe TCL console commands (design.*, dv.*, rtl.*, ta.*, phycst.*, nl.*), synthesis/place/route/bitgen flows, timing analysis, SDC/UPC constraints, UDM netlist manipulation, the hqbuddy wrapper tool, ModelSim/QuestaSim simulation (vsim, testbench, XiST sim library), or HqInsight on-chip logic analyzer debugging (signal selection, trigger, VCD capture via hqbuddy -insight)
---

# HqFpga 操作指南

智多晶（XiST）HqFpga FPGA 开发工具的操作参考。核心：HqFpga 通过 **TCL 命令（U 命令体系）** 驱动，工程描述文件是 `.hqprj`，约束为 `.sdc`（时序）和 `.upc`（物理）。

## 执行途径（按优先级选择）

1. **hqbuddy 封装**（首选，已处理版本解析与路径；完整用法见 references/hqbuddy.md）：
   - `hqbuddy -flow [<.hqprj>]` — 生成完整实现流程 TCL（`run_hqprj.tcl`；**只生成不执行**，再用 `hqbuddy -cmd run_hqprj.tcl` 执行）
   - `hqbuddy -cmd -e "<tcl>" [-q]` — 执行单条 TCL 命令；`-q` 过滤 banner 和 `Info:` 行
   - `hqbuddy -cmd <file.tcl>` / `hqbuddy -cmd` — 执行脚本 / 交互式 CLI
2. **hqfpga.exe 直接调用**：`hqfpga.exe -cmd <script.tcl>`（启动参数见 references/setup.md）
3. **生成标准流程脚本**：在 hqfpga CLI 中执行 `hqprj2tcl <prj.hqprj> [out.tcl]`，得到官方完整流程 TCL——需要自定义流程时，**先生成再修改**，不要凭空写命令

## 关键命令速查

| 阶段 | 命令 |
|---|---|
| 器件设置 | `dv.setup <family> <device>`，`dv.query` / `dv.info` 查询 |
| 加载工程 | `design.load <prj.hqprj>` |
| 综合 | `rtl.analyze` / `rtl.elaborate` / `design.rtlsyn` / `design.flatten` |
| 实现 | `design.map` → `design.pack` → `design.place` → `design.route` |
| 位流 | `design.bitgen` |
| 时序 | `sdc.read`、`ta.run` / `ta.report` / `ta.fmax.report`、`design.looptdo`（自动调参优化） |
| 物理约束 | `upc.read`、`phycst.*` |
| 网表 | `nl.*`、`xpn.read` / `xpn.write` |

## 深入参考（按需加载，勿一次全读）

- `references/hqbuddy.md` — hqbuddy 封装工具完整用法（操作 HqFpga 前先读这个，优先用 hqbuddy 而非原生命令）
- `references/ipdepot.md` — IP 库（ipdepot）结构与 .hqip 配置修改方法（要配置/修改 IP 时读这个）
- `references/commands.md` — U 命令分类地图（先查这里定位命令，再读对应详情文件）
- `references/tcl_commands_curated.md` — 精选实用命令（约束体检、CDC/扇出/层次/功耗报告、交互式 SDC、综合选项、ECO、管脚查询等，手册未覆盖的都在这）
- `references/tcl_commands_help.md` — 全量 1055 个 TCL 命令的实测 help dump（含手册未载的隐藏命令；查命令语法先试 `help <命令名>`）
- `references/cmd-design.md` / `cmd-dv-impl.md` / `cmd-ioh-lo.md` / `cmd-nl.md` / `cmd-phy.md` / `cmd-rtl-ta.md` — 99 个命令的语法、参数、缺省值、示例
- `references/flow.md` — 设计流程原理与综合流程细节
- `references/setup.md` — 安装、目录结构、hqfpga.exe 启动参数
- `references/udm.md` — UDM 数据模型与网表对象操控（高级）
- `references/verilog-sdc.md` — Verilog 可综合子集与 SDC 约束语法
- `references/synthesis_directives.md` — RTL 综合指令（syn_ramstyle/keep/HQ_MAX_FANOUT/HQ_DATA_SKEW 等，写 RTL 前后按需读）
- `references/modelsim.md` — ModelSim/QuestaSim 仿真（XiST 仿真库、xsGSR/xsPWR 强制实例、.do 脚本模板，做仿真任务前必读）
- `references/download.md` — cable.exe 下载调试（检测开发板、下载 bin，要下载/连接开发板时读）
- `references/insight.md` — HqInsight 在线逻辑分析仪全 CLI 流程（选信号、触发条件、抓波形为 VCD，做在线调试时读）

## 注意事项

- TCL 中路径一律用**正斜杠** `/`，避免反斜杠转义问题
- 命令拼写以 references 为准——手册由 PDF 转换而来，个别地方正文与标题不一致（疑点已在各文件中标注）
- 手册缺失章节（§7-9）为 GUI 相关内容，无 CLI 接口，不在本 Skill 范围
- 完整手册原文在 hqbuddy 仓库 `docs/user_manual/hqfpga_um_chs.md`（references 已覆盖其全部 CLI 相关内容）
