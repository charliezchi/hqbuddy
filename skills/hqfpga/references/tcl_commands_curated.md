<!-- 从全量 1055 个 TCL 命令（见 tcl_commands_help.md）中人工策展：挑出手册未覆盖/覆盖浅、
     实际使用价值高的命令。标注【实测】的均在 hqv3_xist 3.1.1 FT082926 上验证过。 -->

# TCL 命令精选（手册之外的实用清单）

查询任意命令完整语法：`hqbuddy -cmd -e "help <命令名>" -q`。

## 1. 工程体检与流程辅助

| 命令 | 用途 |
|---|---|
| `hqprj2tcl <prj.hqprj> [out.tcl]` | 工程转标准流程 TCL（out 缺省 run_hqprj.tcl），自定义流程的起点 |
| `rtl.module.list` / `rtl.topmodule.list` | 综合解析后列出所有 module / 顶层候选，确认顶层选对了没 |
| `nl.stat.check <is_mapped\|is_packed\|is_placed\|is_routed>` | 检查网表当前处于流程哪个阶段（脚本里判断断点恢复） |
| `tc.query ifany` / `tc.query clocks` | 查询是否有时序约束 / 已定义的时钟——跑时序前先确认约束真的加载了 |
| `tc.autogen [-period 10] [-idly 2] [-odly 2] [-print]` | **无约束设计自动生成时序约束**（所有时钟缺省 10ns），bring-up 神器；`-print` 打印将生成的内容 |
| `license.query` | 【实测】打印授权类型、各 key 有效期与授权器件清单 |

## 2. 器件/管脚查询（只 dv.setup，无需加载设计）

【实测】示例（`dv.setup <family> <device_part>` 之后全部可用）：

```tcl
dv.setup SEAL SA5Z-30-D2-8U256CI
dv.get_pin_bank G10   ;# → 2
dv.get_pin_loc G10    ;# → PT61B
dv.bank.list          ;# → 1 2 3 5（存在的 bank）
dv.vccio.list 1       ;# → 3.3 1.8 2.5（bank 1 可选 VCCIO）
```

| 命令 | 用途 |
|---|---|
| `dv.get_pin_bank <pin>` / `dv.get_pin_loc <pin>` | 管脚 → bank / 封装位置（hqbuddy `-get_pin_bank` 的底层） |
| `dv.pinloc.list` | 列出全部管脚位置 |
| `dv.bank.list` / `dv.vccio.list <bank>` | bank 清单 / 某 bank 支持的 VCCIO 电压（做电平分配前查） |
| `dv.sloc.tran <loc>` / `dv.sloc.gen <type> <row> <col>` | 位置名 ↔ 器件坐标互转（**需加载设计**，配合 UDM 网表用） |

## 3. TCL 交互式 SDC 约束（不写 .sdc 文件直接约束）

对象访问需 `sdc.start` … `sdc.end` 包裹，且查询命令加 `-now` 立即返回（手册 §12.5）：

```tcl
sdc.start
set regs [get_cells -hierarchical *rx_data* -now]   ;# 按模式找单元
sdc.end
```

| 命令 | 说明 |
|---|---|
| `get_cells / get_nets / get_pins / get_ports / get_clocks` | SDC 风格对象查询，支持 `-regexp -nocase -hierarchical -of_objects` |
| `xsdc.get_regs <patterns>` | 按模式找**寄存器**（同风格参数） |
| `create_clock [-period 10] [-name clk] [-waveform {...}] [源端口]` | 交互式建时钟 |
| `set_input_delay <val> <ports> [-clock clk] [-max/-min]` / `set_output_delay ...` | IO 延迟约束 |
| `set_false_path [-from x] [-to y] [-setup/-hold]` / `set_multicycle_path <n> [-from/-to] [-setup/-hold]` | 伪路径 / 多周期 |
| `set_clock_groups -asynchronous -group {clk1 clk2} -group {clk3}` | 异步时钟组（免逐对 false_path） |
| `sdc.normalize [-ignore_derived_clocks]` | 归一化/检查已有约束 |

## 4. 设计体检报告（综合或布线后）

| 命令 | 用途 |
|---|---|
| `nl.clkdom.report [-detail]` | 时钟域报告，`-detail` 列出跨域路径——**CDC 排查第一步** |
| `nl.clock.detect -net -obj` | 自动侦测网表里的时钟（约束前确认哪些线被当时钟） |
| `nl.stat.fanout [clk\|data\|ctrl] [-n 20] [-detail]` | 高扇出连线排行（`-n` 取前 N），配 HQ_MAX_FANOUT 优化 |
| `nl.hier.report -inc_devcnt` | 层次化资源统计——**按 module 看面积占用**，找资源大头 |
| `nl.power.report [-toggle_rate 0.15]` | 功耗估算；`nl.power.params.report` 导出参数 |
| `ta.clock.list [-uncst_only]` / `ta.clock.report` | 已定义时钟清单（`-uncst_only` 找漏约束的时钟）/ 时钟汇总表 |
| `ta.slack.report [-n 20] [-rptf worst.rpt]` | 最差路径 slack 排行（缺省前 10）；`extr_wns` 直接取 WNS 数值 |
| `nl.loop.report` / `nl.loop.brkpnt.set` | 组合环报告与打断点 |

## 5. 综合选项精调（rtl.set 全参数见 tcl_commands_help.md；rtl.query 同名参数查询）

```tcl
rtl.query -all          ;# 查全部当前综合选项
rtl.set -reset_all      ;# 恢复缺省
```

高频旋钮：

| 选项 | 作用 |
|---|---|
| `-ramb_min_size <n>` | 小于 n 位的 RAM 不用 BRAM（配 syn_ramstyle 用，参考 synthesis_directives.md） |
| `-ramb_outreg on/off` | BRAM 输出寄存器 |
| `-ram_infer_min_size <n>` | RAM 推断下限（小于它不推断为 RAM） |
| `-infer_srl_length_lb <n>` / `-srl_style <registers\|srl\|ram\|auto>` / `-static_srl_mode <area\|timing>` | SRL 推断长度下限 / 全局 SRL 风格 / 静态 SRL 优化目标 |
| `-fsm_opt on/off` | FSM 重新编码开关（配合下面的 fsm.set） |
| `-share_opt` / `-mux_opt` / `-expr_opt` / `-lut_combine` | 资源共享 / MUX 优化 / 表达式优化 / LUT 合并 |
| `-dsp_map on/off` / `-map_adder_to_dsp on/off` / `-absorb_register_to_dsp <off\|1\|2>` | DSP 映射三件套 |
| `-system_verilog on/off` | SystemVerilog 语法支持 |
| `-enable_third_party_keep on/off` | 第三方 keep 指令支持 |

FSM 编码与综合后面积优化：

```tcl
fsm.set -encoding onehot      ;# 亦可 gray|johnson|binary|auto；另有 -max_states 等阈值
fsm.optimize                  ;# 执行 FSM 优化
postsyn.areaopt.set -effort high   ;# tiny|low|std|high|extra|extreme|none|auto
postsyn.areaopt               ;# 执行综合后面积优化
```

## 6. 高级/特殊武器

| 命令 | 用途 |
|---|---|
| `lo.cdc_sync_reg.insert [-from_clk a] [-to_clk b] [-regcnt 2] [-inc_reg sig]` | **自动插 CDC 同步寄存器链**（默认 2 级），可指定例外 from/to |
| `design.tmr` | 三模冗余（TMR），无 help 条目，属内部流程命令，谨慎使用 |
| `design.saveSdb <file>` / `design.loadSdb <file>` | 设计数据库快照/恢复（长流程断点） |
| `macro.flatten [<nview>]` | 展平宏单元（区别于 design.flatten 的全网表展平） |
| `dconv.xpn2chipedit <file.xpn>` | XPN 转 ChipEdit 格式（可视化逐器件检查布线结果） |
| `xdl.write <file> [nmmap] [formality\|lec]` | 导出网表给**形式验证**（Formality/LEC 等价性检查） |
| `flowcfg.algo.set -packer <std\|lpp> -placer <std\|ap\|lpp>` | 换打包/布图算法引擎（同一设计换算法对比 QoR） |
| `tarc.derate.set <cell> <factor>` | 对单元设时序降额因子（guard-band） |
| `opcond.set <cond>` / `opcond.query names\|detail` | 设置/查询工作条件（工艺角） |
| `ucf2upc <in.ucf> <out.upc> [-conv_instloc]` | **Xilinx UCF 转物理约束**（老工程迁移） |
| `csv2upc <in.csv> <out.upc>` / `pin2csv <out.csv>` | CSV 管脚表 ↔ UPC 互转（用 Excel 管管脚分配） |
| `insight.svf_generator.start <svf> <die> [-ddf x.ddf]` | 生成 JTAG 链编程 SVF 文件 |
| `eco.init` → `eco.place` → `eco.route`（另有 eco.set_clock/eco.read/eco.report_pin_delay 等） | ECO 小改动流程：改时钟/少量布线后局部重布，不必全流程重跑 |

## 7. 使用注意

- 需要设计上下文的命令（nl.*、ta.*、obj.*、sdc 对象访问）要先 `design.load` 或跑过综合；器件查询类（dv.*、license.query）只要 `dv.setup`。
- 无 help 条目的命令（如 `design.tmr`、`extr_wns`、`xist_bit2svf`）仍可直接调用，参数靠试或查内部脚本 `hqprj2tcl` 产物中的用法。
- `'` 开头的命令是内部隐藏命令（222 个），不稳定且随时可能变更，不要写进交付脚本。
