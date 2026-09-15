<!-- 来源：官方《使用技巧006-第三方综合工具与HqFpga协同说明》《使用技巧009-使用第三方综合工具在线调试的方法说明》（20260911）+ hqbuddy 在 FT091226 上全链路实测（2026-09-15，Vivado→EDIF→P&R→bin→下载 SA50K 板验证通过） -->

# 第三方综合工具协同（Synplify/Vivado → EDIF → HqFpga）

HqFpga 支持用第三方综合工具（Synplify Pro / Vivado）完成 RTL 综合，输出 EDIF 网表后导入 HqFpga 做 P&R 和位流。本文是**全 CLI 实操路径**，关键命令链均在 FT091226 上实测通过。

## 器件兼容关系（选错综合不出可用网表）

| 智多晶器件 | 第三方工具中选择的兼容器件 |
|---|---|
| **Seal**（SA5Z-30/50 等） | Xilinx **Artix7**（Vivado 任选 Artix7 型号即可） |
| **Sealion**（SL2 等） | Lattice **MachXO2**（仅 Synplify 路线；Vivado 只支持 Seal） |

- 原语库（必须用**当前 HqFPGA 版本**的，旧版会在第三方综合时报错）：`<HqFPGA>/build/common/syn/verilog/XIST/seal_syn_prim.v`（Seal）或 `sealion_syn_prim.v`（Sealion）。
- HqFPGA 仅支持 Verilog/SV；VHDL 有限支持不推荐。

## 路线 A：Vivado（本机实测通过）

版本 ≥2018.1（本机 2018.3 验证）。批量脚本（把 RTL + 原语库综合为 `a.edif`）：

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

**两个必改项**（官方文档强调，缺一不可）：
- `-mode out_of_context`：关闭 IO buffer 自动插入；
- `-bufg 0`：不让 Vivado 插 BUFG。

## 路线 B：Synplify Pro（2013.03，本机实测通过）

- 工程添加 RTL + VLA IP（如用）+ 新版原语库；**顶层文件拖到文件列表最底部**（混合语言工程改用 Implementation Options 手填 top）。
- Device → Technology：Seal 选 **Artix7**（2013.03 的 .prj 里必须写 `set_option -technology Artix7`，**带空格的 "Artix 7" 会报 Unrecognized technology**），Sealion 选 MachXO2。
- **必须勾选 Disable IO Insertion**（.prj 里 `set_option -disable_io_insertion 1`）。
- RUN 后取输出目录 `rev_1/*.edf`（实测 cell 为 Lattice XO2 风格 `LUT1_L/MUXCY_L/XORCY`，HqFpga legalize 可正常映射到 Seal）。
- VLA IP 例化末尾加 `/* synthesis syn_noprune=1 */`（VLA 只有输入端口，会被默认优化掉）。

**批处理调用的坑（实测）**：`bin\synplify_pro.exe -batch` 包装器会路由到
`win64\mbin\synbatch.exe`，其 license 校验失败（FLEXnet -8,234）。**用 32 位
`bin\mbin\synbatch.exe` 直接调用则 license 有效**：

```bat
C:\Synopsys\fpga_H201303\bin\mbin\synbatch.exe -product synplify_pro -batch r30syn.prj
```

实测：exit 0，产出 `rev_1/r30syn.edf` → 经下方 P&R 链产出可用 bin（与 Vivado 路线同尺寸）。

## EDF→Verilog 网表转换（可选，实测通过）

用途：Modelsim 门级仿真 / 需要 Verilog 原语网表。`edn.tcl`：

```tcl
dv.setup SEAL SA5Z-50-D0-7F484C   ;# 换成实际目标器件
edif.read a.edif
nl.write a.v -eqn
```

执行 `hqbuddy -cmd edn.tcl`，产出 `a.v`（内含 `xsDFFSA/xsLUTSA` 等 XIST 原语）。

## 第三方网表 → 位流（全 CLI，实测通过并下载上板）

```tcl
# pnr.tcl —— hqbuddy -cmd pnr.tcl
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

- **`design.flatten` 必须在 pack 前**（第三方网表已展平，直接 pack 报 PK1002 can not be packed）。
- bitgen 命令按器件族选：`impl.bitgen.xist.seal`（Seal）/ `.sealion`；不带 `-bin` 只出 `.bit`。
- 下载照常：`hqbuddy -cable --sealion <bin> --model <detect 到的 model> --Burst`。
- 实测记录：netlist P&R 约 10s（15 nets）；无 `-eqn` 的 `nl.write a.v` 也可用于检查。

## 已知的坑（实测踩过）

1. **`-family` 参数在 FT091226 会报 DVST001**（`Unable to determine the vendor...`）——官方 006 文档写 `edif.read x.edf -family artix7`，但当前版 vendor 表只剩 XIST（`dv_list.xml` 仅 XIST vendor）。**解法：省略 `-family`，依赖 `dv.setup` 设定的目标族**（实测成功）。
2. **`.hqprj` 的 FILE_SRC 不认 `.edf`**：hqprj2tcl 生成流程时会忽略 edif 文件、仍走 RTL 综合——**第三方网表必须走上面的显式 TCL 链，不能塞进 .hqprj**。
3. `.hqprj` 复制到新目录后 FILE_SRC 绝对路径仍指旧目录（综合的是旧代码）——复制工程要手工改 FILE_SRC。
4. Vivado `set_property -bufg 0` 是对 `synth_design` 的命令行选项（`synth_design -bufg 0`），不是 fileset property。

## 第三方综合 + VLA 在线调试（技巧 009）

原理：在 RTL 里例化 **VLA IP**（HqFpga 生成，可勾选带 VIO），随第三方综合进 EDIF；HqFpga FT090925+ 能解析网表里的 VLA IP，编译下载后用【VLA 调试】做在线抓波/VIO。

- **约束**：VLA IP 只允许例化一次（多次报 JTAG 资源溢出），待观测信号统一汇总到单例 VLA；Synplify 必须加 `syn_noprune=1`。
- **现状（诚实边界）**：GUI 路径（网表工程编译 → VLA 调试按钮）官方支持；**CLI 路径 hqbuddy 暂未打通**——insight 插桩流程基于 `rtl.elaborate`（对展平网表不适用），`insight.load` 需要 .ddf（由 GUI/插桩流程生成）。要把该流程 CLI 化，需要逆向 VLA 工程的 ddf/SVF 生成链（见 `guides/hqinsight_gui_map.md` §8 的 vla.cfg 逆向），已列入 TODO。
