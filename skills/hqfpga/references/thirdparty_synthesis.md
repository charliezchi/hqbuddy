<!-- 来源：官方《使用技巧006-第三方综合工具与HqFpga协同说明》《使用技巧009-使用第三方综合工具在线调试的方法说明》（20260911）+ hqbuddy 在 FT091226 上全链路实测（2026-09-15，Vivado 与 Synplify 双路线 → EDIF → P&R → bin → 下载 SA50K 板验证通过；R30 盲评后按缺口清单补齐） -->

# 第三方综合工具协同（Synplify/Vivado → EDIF → HqFpga）

HqFpga 支持用第三方综合工具（Synplify Pro / Vivado）完成 RTL 综合，输出 EDIF 网表后导入 HqFpga 做 P&R 和位流。本文是**全 CLI 实操路径**，关键命令链均在 FT091226 上实测通过（含 R30 独立 agent 仅凭本文从零复现成功）。

## 判成败的通用规则（先读）

- **`hqbuddy -cmd` 的退出码不反映 TCL 执行错误**：TCL 里出现 `ERROR(...)` 进程仍可能 exit 0。判定成败必须：①检查输出中**没有 `ERROR(`**；②确认预期产物文件真实存在（`ls`）。
- **bitgen 有静默假成功**：输出路径父目录不存在时，`impl.bitgen.xist.seal` 照样打印 `Generating bitstream file ... Done.` 但**不建目录、不写文件、零报错**——输出目录须预先存在，生成后必须核实文件确实产出。
- **`-family` 参数不要用**：FT091226 上 `edif.read x.edf -family artix7` 会报 `ERROR(DVST001): Unable to determine the vendor...`（vendor 表只剩 XIST）。**省略 `-family`，依赖 `dv.setup` 设定的目标族**（实测成功）。
- 合法器件名可用 `dv.query`（无参列出全部 vendor/family）确认。

## 器件兼容关系（选错综合不出可用网表）

| 智多晶器件 | 第三方工具中选择的兼容器件 |
|---|---|
| **Seal**（SA5Z-30/50 等） | Xilinx **Artix7**（Vivado 任选 Artix7 型号即可） |
| **Sealion**（SL2 等） | Lattice **MachXO2**（仅 Synplify 路线；Vivado 只支持 Seal） |

- 原语库（必须用**当前 HqFPGA 版本**的，旧版会在第三方综合时报错）：`<HqFPGA>/build/common/syn/verilog/XIST/seal_syn_prim.v`（Seal）或 `sealion_syn_prim.v`（Sealion）。
- HqFPGA 仅支持 Verilog/SV；VHDL 有限支持不推荐。
- **引脚约束前置**：第三方网表流程 bitgen 前必须有引脚约束 `.upc`（`upc.read` 加载）+ 时序 `.sdc`（`sdc.read`），否则 bitgen 报 `ERROR(BIT-11): pads have no location constraint`。约束来源：工程自带，或按 boards 手册（`references/boards.md`）用 `phycst.pin.set` 逐脚写。

## 路线 A：Vivado（≥2018.1，本机 2018.3 实测通过）

批量脚本（把 RTL + 原语库综合为 `a.edif`）：

```tcl
# viv_synth.tcl —— 在工作目录执行 vivado -mode batch -source viv_synth.tcl
create_project -force r30viv ./prj -part xc7a100tcsg324-1
add_files [list [file normalize rtl/counter8.v] [file normalize rtl/lfsr8.v] \
                [file normalize rtl/r21a_top.v] [file normalize seal_syn_prim.v]]
set_property top r21a_top [current_fileset]
synth_design -top r21a_top -part xc7a100tcsg324-1 -mode out_of_context -bufg 0
write_edif -force a.edif
exit
```

**两个必改项**（缺一不可）：
- `-mode out_of_context`：关闭 IO buffer 自动插入；
- `-bufg 0`：不让 Vivado 插 BUFG（是 `synth_design` 的命令行选项，不是 fileset property）。

## 路线 B：Synplify Pro（2013.03，实测通过）

最小 `.prj` 模板（可直接改用；**顶层文件必须列在 add_file 的最后一个**）：

```txt
# r30syn.prj
add_file -verilog {rtl/counter8.v}
add_file -verilog {rtl/lfsr8.v}
add_file -verilog {rtl/r21a_top.v}
add_file -verilog {seal_syn_prim.v}
set_option -technology Artix7
set_option -part XC7A100T
set_option -package CSG324
set_option -speed_grade -1
set_option -disable_io_insertion 1
set_option -top r21a_top
project -result_file {rev_1/r30syn.edf}
impl -active r30syn
project -run
```

要点：
- technology 必须写 **`Artix7`（无空格）**——`Artix 7` 报 `Unrecognized technology`；Sealion 用 MachXO2 对应写法。
- `set_option -disable_io_insertion 1` 必设；实测产出 EDF 无 IBUF/OBUF。
- 若用 VLA IP：例化末尾加 `/* synthesis syn_noprune=1 */`（VLA 只有输入端口，会被默认优化掉）。

**批处理调用的坑（实测）**：`bin\synplify_pro.exe -batch` 包装器**退出码 4 且无任何输出**（不可用）。改用 32 位 mbin 里的批处理 runner 直接调用：

```bat
C:\Synopsys\fpga_H201303\bin\mbin\synbatch.exe -product synplify_pro -batch r30syn.prj
```

实测：exit 0，产出 `rev_1/r30syn.edf`。EDF cell 为 Xilinx 风格原语（`FD/LUT*_L/SRL16E/MUXCY_L/XORCY`），HqFpga legalize 可正常映射到 Seal。

## 文件衔接

路线 B 产出在 `rev_1/<工程名>.edf`，而下文 TCL 默认引用 `a.edif`——先复制对齐：
`cp rev_1/r30syn.edf a.edif`（或把 TCL 里的 `a.edif` 改成实际路径）。

## EDF→Verilog 网表转换（可选，实测通过）

用途：Modelsim 门级仿真 / 需要 Verilog 原语网表。`edn.tcl`：

```tcl
dv.setup SEAL SA5Z-50-D0-7F484C   ;# 换成实际目标器件（dv.query 可查合法名）
edif.read a.edif
nl.write a.v -eqn
```

执行 `hqbuddy -cmd edn.tcl`，或直接用产品化命令（3.13.4 起）：

```bat
hqbuddy -edf2v a.edif -o a.v
```

产出 `a.v`（内含 `xsDFFSA_K1/xsLUTSA/xsMUXCY_L/xsSRL16E` 等 XIST 原语，R30 实测 13×DFF+LUT+SRL 与设计规模吻合）。

## 第三方网表 → 位流（全 CLI，实测通过并下载上板）

产品化命令（3.13.4 起，封装下方整条 TCL 链 + 产物校验 + 目录自动创建）：

内嵌报告产出（3.14.0）：ta.set 块 + nl.report -ratio -location + xpn.write aft_place.xpn + ta.fmax.report fmax.rpt + ta.report -n 100 final_ta.rpt——跑完即可 `hqbuddy -report` 直接读取。

```bat
hqbuddy -netlist_build a.edif --upc cons/r21a.upc --sdc cons/r21a.sdc -o r30syn.bin
```

等价手工 TCL（`pnr.tcl` + `hqbuddy -cmd pnr.tcl`）：

```tcl
dv.setup SEAL SA5Z-50-D0-7F484C
edif.read a.edif
design.flatten
upc.read cons/r21a.upc
sdc.read cons/r21a.sdc
impl.pack
impl.place
impl.route
impl.bitgen.xist.seal r30syn.bin -bin
```

- **`design.flatten` 必须在 pack 前**（第三方网表直接 pack 报 `PK1002: Cell xxx can not be packed!!!`，R30 对照实测一致）。
- bitgen 命令按器件族选：`impl.bitgen.xist.seal`（Seal）/ `.sealion`；不带 `-bin` 只出 `.bit`。
- 下载：`hqbuddy -cable --sealion <bin> --model <板卡型号> --Burst`。`--model` 无需预先探测（cable 下载前会打印 `detect Device Model` 并做板上型号校验；Seal/Sealion 器件都用 `--sealion` 旗标）。成功标志 `Task completed.` + `[OK] 板上型号校验通过`。
- 生成后**必须 `ls` 核实 bin 存在**（见"判成败的通用规则"的静默假成功条目）。
- 实测记录：netlist P&R 约 10s（15 nets）；仅无害的 IOH009/IOH010 未用脚 pullmode 告警。

## 第三方综合 + VLA 在线调试（技巧 009）

原理：在 RTL 里例化 **VLA IP**（HqFpga 生成，可勾选带 VIO），随第三方综合进 EDIF；HqFpga FT090925+ 能解析网表里的 VLA IP，编译下载后用【VLA 调试】做在线抓波/VIO。

- **约束**：VLA IP 只允许例化一次（多次报 JTAG 资源溢出），待观测信号统一汇总到单例 VLA；Synplify 必须加 `syn_noprune=1`。
- **预生成 1-probe VLA IP（R44）**：`templates/vla/xsIP_VLA_1probe.v`（随仓库/包分发，
  标准配置 dep=1024/pos=128/win=1/level=1/无VIO）。例化契约：
  `VLA u_x(.probe0(<待观测信号>), .ref_clk(<clk>));` 例化处加
  `/* synthesis syn_noprune=1 */`；直接当普通 .v 加入第三方综合工程即可
  （配置在文件内 HQ_VLA0 属性行，第三方综合透传给 HqFpga）。
- **为什么不做全自动模板化（R44 结论）**：VLA .v 的内部结构（地址位宽
  [9:0]、per-probe 触发单元复制）与 dep/probe_num 强耦合——文本替换属性行
  会产出属性与结构不一致的坏 RTL。非默认配置（多 probe/更大深度/VIO）请用
  `hqbuddy -vla -gen` 走官方向导。
- **VLA IP 生成（R34b 契约 + R36b 产品化）**：`hqbuddy -vla -gen [-name VLA] [-dir <dir>] [-device <part>]`
  一键调起官方生成向导（参数契约与 IP Creator 相同），生成完成后自动检测并提示下一步。
  底层：IP Creator 生成 VLA IP 时实际调起
  `hq_vla_ins.exe -device <part> -lang chs -output_module VLA -output_fname
  xsIP_VLA.v -output_dir <dir> -hq_exe <hqfpga.exe>`，其向导收集
  信号个数/深度/窗口/VIO 等参数后产出 xsIP_VLA.v + xsIP_VLA.hqip + .cfg。
  生成的 .v 头部带 `HQ_VLA0` 综合属性携带全部配置，第三方综合靠 syn_noprune
  保留实例、靠属性把配置带进 EDIF。hqbuddy `-vla -gen`（调起向导或模板化）
  已列入 TODO；运行侧（insight.load 的 ddf + VLA 抓取）仍需逆向。
- **现状（诚实边界）**：GUI 路径（网表工程编译 → VLA 调试按钮）官方支持；**CLI 路径 hqbuddy 暂未打通**——insight 插桩流程基于 `rtl.elaborate`（对展平网表不适用），`insight.load` 需要 .ddf（由 GUI/插桩流程生成）。CLI 化需逆向 VLA 工程的 ddf/SVF 生成链（见同目录 `hqinsight_gui_map.md` §8 的 vla.cfg 逆向），已列入 TODO。

## 附：.hqprj 通用坑（与第三方综合无直接关系）

复制 `.hqprj` 到新目录后，`FILE_SRC` 里的绝对路径仍指旧目录（会综合旧代码）——复制工程必须手工改写 FILE_SRC（`-copy_prj` 自动化已列入 TODO）。
