<!-- 来源：docs/user_manual/hqfpga_um_chs.md 第4088–5437行（§15.76–15.99：rtl.*、root.query、srchpath.*、sdc.*、ta.*、taset.query、tc.*、upc.read、xpn.*） -->

# HqFpga 命令参考 Part 11：RTL 解析/综合、路径、SDC、时序分析（ta/tc）

本部分覆盖 RTL 源解析与综合（`rtl.*`）、HqFpga 根目录与搜索路径（`root.query`、`srchpath.*`）、SDC 时序约束导入（`sdc.*`）、静态时序分析（`ta.*`、`taset.query`）、自动时序约束（`tc.*`）、物理约束与物理网表（`upc.read`、`xpn.*`）。

---

## rtl.analyze

解析/分析 RTL 源描述（词法、语法检查与语义分析）。

```xml
rtl.analyze <src_file_list>
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| src_file_list | 字符串 | 无 | 要读入的 RTL 源文件名，可用 TCL 列表格式指定多个文件 |

- 本版本 HqFpga 支持 **Verilog** 格式的 RTL 源描述。
- 若未发现错误，则生成 HqFpga 内部语法树表示，供后续 `rtl.elaborate` 命令使用。
- 多文件设计**必须一次性以 TCL 列表格式统一解析**，**不能**多次调用本命令、每次分析一个文件。

```txt
# 正确：一次传入列表
rtl.analyze {mytop.v mymodule1.v mymodule2.v}
# 错误：逐个调用
rtl.analyze mytop.v
rtl.analyze mymodule1.v
rtl.analyze mymodule2.v
```

```txt
# 单一文件
rtl.analyze mydesign.v

# 用变量保存文件列表后解析
set my_hdl_files { \
top/mysystem.v \
cpu/cpu_core.v \
bus/bus_main.v \
bus/bus_control.v \
..
}
rtl.analyze $my_hdl_files
rtl.analyze [glob *.v]      # 用 TCL 内置 glob 解析当前目录所有 .v 文件
```

---

## rtl.elaborate

进行 RTL 综合确立，产生与工艺无关的门级网表。

```txt
rtl.elaborate [-top <top_value>]
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| top | 字符串 | 无 | 指定待确立的顶层模块名称 |

- 在 `rtl.analyze` 生成的语法树基础上，通过识别、转换最终产生与工艺无关的门级网表（类似普通编程语言的链接过程，结果是网表）。
- 网表由与工艺无关的 HqFpga 基本元件组成。
- **顶层模块自动识别规则**：若某模块未被实例化过则设为顶层；若有多个未被实例化的模块，则设**最后一个未被实例化**的模块为顶层。
- 无论自动识别结果如何，都可通过 `-top` 强行指定顶层。

```txt
rtl.analyze {myfile1.v myfile2.v myfile3.v}
rtl.elaborate -top mymodule2
```

---

## rtl.incpath.add

添加 RTL 文件包含路径。

```batch
rtl.incpath.add <inc_path>*
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| inc_path | 字符串 | 无 | RTL 文件包含路径，可多次给定 |

- 解析 Verilog 源时若含 `` `include <包含文件> `` 语句，`rtl.analyze` 缺省在当前工作目录寻找；未找到则按本命令指定目录**依次**寻找。

```batch
rtl.incpath.add /home/dev/common/inc
rtl.incpath.add /home/me/inc1 /home/me/inc2
```

第二条命令执行后，包含路径列表为 `/home/dev/common/inc`、`/home/me/inc1`、`/home/me/inc2`。

---

## rtl.incpath.clear

清除 RTL 文件包含路径。

```txt
rtl.incpath.clear
```

- 用于清除 `rtl.incpath.add` 命令所指定的 RTL 文件包含目录。

---

## rtl.macro.define

配合 `rtl.analyze`，在 RTL 源解析前定义宏、设定宏的值。

```txt
rtl.macro.define <macro> [<macro_val>]
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| macro | 字符串 | 无 | 要定义的宏名称 |
| macro_val | 字符串 | 无（可选） | 要定义的宏的值 |

- 等价于在每个 Verilog 源描述之前加入语句 `` `define <macro> <macro_val> ``。
- 若 Verilog 描述中有同名宏定义，**Verilog 中的宏定义优先级更高**，将覆盖本命令的宏定义。

```txt
# myreg.v 中 `define WIDTH 8 被注释掉
rtl.macro.define WIDTH 16
rtl.analyze myreg.v
rtl.elaborate
# 结果：16 位寄存器；若去除 myreg.v 第一行注释，则为 8 位寄存器
```

---

## rtl.macro.undef

取消 `rtl.macro.define` 所产生的宏定义。

```txt
rtl.macro.undefine <macro>
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| macro | 字符串 | 无 | 将取消定义的宏的名称 |

---

## rtl.set

设定综合优化选项。

```tcl
rtl.set [-bmul_min_size <bmul_min_size_value>]
    [-expr_opt <expr_opt_value>]
    [-fsm_opt <fsm_opt_value>]
    [-infer_ram <infer_ram_value>]
    [-infer_rom <infer_rom_value>]
    [-infer_srl <infer_srl_value>]
    [-mux_opt <mux_opt_value>]
    [-ram <ram_value>]
    [-ram_infer_min_size <ram_infer_min_size_value>]
    [-ramb_min_addr <ramb_min_addr_value>]
    [-ramb_min_size <ramb_min_size_value>]
    [-reset_all]
    [-rom <rom_value>]
    [-share_opt <share_opt_value>]
    [-srl <srl_value>]
    [-tmp <tmp_value>]
    [-tmp_dir <tmp_dir_value>]
    [-utilize_muxf <utilize_muxf_value>]
    [-ver <ver_value>]
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| bmul_min_size | 整数 | 8 | 使用乘法器块（multiplier block）的最小位宽；操作数位宽小于此值则不用片上乘法器块实现 |
| expr_opt | 枚举(on\|off) | on | 是否在综合中进行表达式优化 |
| fsm_opt | 枚举(on\|off) | on | 是否进行有限状态机识别与优化 |
| infer_ram | 枚举(on\|off) | on | 是否进行 RAM 识别与优化 |
| infer_rom | 枚举(on\|off) | on | 是否进行 ROM 识别与优化 |
| infer_srl | 枚举(on\|off) | on | 是否进行移位寄存器识别与优化 |
| mux_opt | 枚举(on\|off) | on | 是否进行多路选择器识别与优化 |
| ram_infer_min_size | 整数 | 16 | 识别 RAM 的最小位数；小于此值不识别为 RAM。【注】仅当 infer_ram 为 on 时起作用 |
| ramb_min_addr | 整数 | 8 | 使用 Block-RAM 的最小地址位宽；地址位数 ≤ 此值则不用 Block RAM（可用分布式 RAM 或寄存器实现）。【注】仅当 infer_ram 为 on 时起作用 |
| ramb_min_size | 整数 | 1024 | 使用 Block-RAM 的最小位数；位数小于此值则不用 Block RAM（可用分布式 RAM 或寄存器阵列实现）。【注】仅当 infer_ram 为 on 时起作用 |
| share_opt | 枚举(on\|off) | on | 是否进行资源共享优化 |
| reset_all | 开关 | 无 | 将上述所有参数恢复为缺省值 |

> 原文中语法还列出了 `ram`、`rom`、`srl`、`tmp`、`tmp_dir`、`utilize_muxf`、`ver` 等参数，但正文参数说明未逐一解释（原文如此）。

```batch
rtl.set -mux_opt off -fsm_opt off
rtl.set -ramb_min_addr 4 -ramb_min_size 512
```

示例：设 `-ramb_min_addr 4 -ramb_min_size 512` 后，以下三个可综合成 RAM 的变量仅 `mem3` 用 BlockRAM 实现：

```txt
reg[31:0]mem1[3:0];   // addr bits=4 (<=ramb_min_addr), total bits=512  -> 不用 BlockRAM
reg[7:0]mem2[4:0];    // addr bits=5, total bits=256 (<ramb_min_size)    -> 不用 BlockRAM
reg[15:0]mem3[4:0];   // addr bits=5, total bits=512                     -> 用 BlockRAM
```

---

## root.query

查询 HqFpga 的根目录。

```txt
root.query
```

无参数。

---

## srchpath.config

为各种网表读入（EDIF 读入、Verilog 读入）模块指定源文件搜索路径。

```txt
srchpath.config <path_list> [-add]
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| path_list | 字符串 | None | 源文件搜索路径列表，格式必须符合 TCL 列表规定 |
| add | 开关 | None | 指定时，path_list 添加到已有路径列表；否则覆盖已有列表 |

```txt
srchpath.config c:/temp
srchpath.config {d:/mysuite1 d:/mysuite2}
srchpath.config "e:/mysuite3" -add
# 第一条后：c:/temp
# 第二条后：d:/mysuite1 d:/mysuite2（覆盖）
# 第三条后：d:/mysuite1 d:/mysuite2 e:/mysuite3（追加）
```

> 疑点：原文第三条命令参数为 `"e:/mysuite3"`，但第三条命令执行后显示的结果列表为 `d:/mysuite1 d:/mysuite2 d:/mysuite3`（e 写成了 d，原文如此）。

---

## srchpath.query

查询源文件搜索路径。

```txt
srchpath.query
```

无参数。

```txt
srchpath.config {d:/mysuite1 d:/mysuite2}
srchpath.config "e:/mysuite3" -add
srchpath.query
# 显示：d:/mysuite1 d:/mysuite2 d:/mysuite3
```

---

## sdc.end

与 `sdc.start` 配对，标示 SDC 命令解析结束。

```txt
sdc.end
```

无参数。

SDC 约束可两种方式导入 HqFpga：
- **文件方式**：通过 `sdc.read` 一次性读入 SDC 文件。
- **命令方式**：解析 SDC 命令前必须运行 `sdc.start`，结束后必须运行 `sdc.end`。

> 需用 `sdc.start`/`sdc.end` 标示的原因：SDC 中设计对象的命名方式与 HqFpga 缺省命名方式不同，需要利用这两条命令进行命名方式转换。

```tcl
sdc.start
create_clock -period 10 [get_ports clk]
set_input_delay -clock clk [get_ports {in*}]
sdc.end
```

---

## sdc.read

读入 SDC 时序约束文件。

```txt
sdc.read <filename>
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| filename | 字符串 | None | 要读入的 SDC 文件名称 |

```txt
sdc.read my.sdc   # 读取名为 "my.sdc" 的 SDC 文件
```

---

## sdc.start

与 `sdc.end` 配对，标示 SDC 命令解析开始。

```txt
sdc.start
```

无参数。

示例同 `sdc.end`：多条 SDC 命令被 `sdc.start` 和 `sdc.end` 包围。

---

## ta.end

释放静态时序分析（`ta.run`）所占用的内存资源。

```txt
ta.end
```

无参数。

- 静态时序分析结果保存在内存中供时序报告使用；做完时序报告后，通过本命令释放相应系统资源。

---

## ta.fmax.report

报告设计的最大时钟频率（FMAX）。

```txt
ta.fmax.report [-fields <fields_value>] [-iph]
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| fields | 字符串 | 见 ta.report | 详见 15.91.2 节同名参数说明 |
| iph | 开关 | — | 详见 15.91.2 节同名参数说明 |

FMAX 计算要点：
- 仅针对**同一时钟域内**的寄存器到寄存器路径。
- 跨时钟域路径（包括主时钟及其生成时钟之间）被忽略。
- 时钟与其反向时钟之间的路径：按频宽比（duty cycle）等比例扩展路径延迟。例如路径起点由上升沿驱动、终点由同一时钟下降沿驱动，若频宽比 50%，则路径延迟乘以 2（即除以 50%）。
- 对复杂设计（多时钟、跨时钟域），FMAX 分析往往不够精确；**强烈建议**施加时序约束后用 `ta.report` 报告时序做深入分析。

---

## ta.report

报告时序分析结果。

> **注意**：用户必须先给定时序约束，才能进行时序报告。

```txt
ta.report [-exclude <exclude_value>]
    [-fields <fields_value>]
    [-from <from_value>]
    [-from_clk <from_clk_value>]
    [-inside_phy_hier/-iph <inside_phy_hier_value>]
    [-max_common_paths/-m <max_common_paths_value>]
    [-max_common_start/-ms <max_common_start_value>]
    [-max_paths/-n <max_paths_value>]
    [-through <through_value>]*
    [-to <to_value>]
    [-to_clk <to_clk_value>]
    [-no_header]
    [-rpt_only]
    [-type <type_value>]
```

### 参数

**exclude** — 类型：字符串，缺省值：无
指定要报告的时序路径**不能经过**的时序节点名称列表。名称可为引脚、元件实例或连线名。类型限定符：
- `p'`（小写 p 加单引号）→ 引脚（pin）
- `I'`（大写 I 加单引号）→ 元件实例（instance）
- `N'`（大写 N 加单引号）→ 连线（net）

若名称不含限定符，按【引脚→元件实例→连线】顺序查找。名称可含通配符 `*` 或 `?`（同 unix 文件系统通配符含义）。

```txt
ta.report ... -exclude {N'xornet* p'mymux?/S}
# 路径不能经过名字形如 "xornet*" 的连线，及名字形如 "mymux?/" 的元件实例的 "S" 端引脚
```

**fields**（原文参数名亦写作 field）— 类型：字符串，缺省值：None
指定报告字段，为如下关键字组合：
- `NODE` — 时序节点名（通常是元件实例的引脚 pin）
- `NET` — 与时序节点相连的连线名
- `CELL` — 时序节点相应元件实例所对应的单元名
- `DELAY` — 前一时序节点到当前时序节点的延迟
- `AT` — 到达时间（Arrival Time）
- `RT` — 规定时间（Required Time）
- `SLACK` — 时间余量（Slack）
- `TRANS` — 信号沿（Transition）：上升（rise）或下降（fall）
- `LOC` — 时序节点相应元件实例的物理位置
- `FANOUT` — 与时序节点相关的连线的扇出数
- `TYPE` — 前一时序节点到当前时序节点的延迟类型：单元延迟还是连线延迟

未指定时默认字段为 `{NODE CELL DELAY AT TYPE LOC FANOUT}`。

**from** — 类型：字符串，缺省值：无
指定时序路径的**起始点**名称列表。合法起始点包括：外部输入或双向端口、时序元件上被时钟触发的输出引脚（如触发器 Q 端）。类型限定符：
- `P'`（大写 P）→ 端口（port）
- `p'`（小写 p）→ 引脚（pin）
- `I'`（大写 I）→ 元件实例（instance）
- `N'`（大写 N）→ 连线（net）

不含限定符时按【端口→引脚→元件实例→连线】顺序查找。起始点为元件实例名时表示该实例上被时钟触发的输出引脚；为连线名时表示驱动该连线的引脚或端口。名称可含通配符。

```txt
ta.report ... -from {P'in? p'myff*/Q}
# 起始点必须为名字形如 "in?" 的外部端口，或名字形如 "myff*" 的元件实例的 "Q" 端引脚
```

**from_clk** — 类型：字符串，缺省值：无
指定起始点的时钟条件，格式：
- `<时钟名>` — 起始点必须由相应名称的时钟触发
- `<时钟名称>|R` — 必须由该时钟上升沿触发
- `<时钟名称>|F` — 必须由该时钟下降沿触发

> 注意：`<时钟名称>` 中**不能包含通配符**。

```txt
ta.report ... -from_clk clk1|F   # 起始点必须由时钟 clk1 的下降沿触发
```

**max_common_paths / -m** — 类型：整数，缺省值：无
指定每个时序检查点（如寄存器数据输入引脚）要报告的最大路径数。未指定时每个检查点只报告一条路径。

**max_common_start / -ms** — 类型：整数，缺省值：无
指定每个时序路径起始点能报告的最大路径数。未指定时路径数目不受限制。

**max_paths / -n** — 类型：整数，缺省值：1
指定报告的最大路径数。未指定时只报告一条最关键的路径。

**no_header** — 类型：开关，缺省值：无
报告开始会输出时序分析总结信息（如下）；指定本参数时不输出总结信息。

```txt
# 时序分析报告 Tue Jan 12 15:25:30 2010
# 分析类型 : 建立 (setup)
# 分析/报告未加约束 IO 与寄存器之间路径 : No
# 分析/报告跨时钟域路径 : No
# 分析/报告物理层次中的的时序节点 : No
# 分析中动态截断组合回路 : No
# 报告用户层次模块上的时序节点 : No
# 要报告的最大路径数目 : 10
# 每个检查点上的要报告最大路径数目 : 1
```

**through** — 类型：字符串，缺省值：无
指定时序路径**必须经过**的时序节点名称列表。名称可为引脚、元件实例或连线名，限定符及查找顺序同 `exclude`（引脚→元件实例→连线）。名称可含通配符。

本参数可在命令中**多次出现**，后出现的 `-through` 所指定的时序节点必须是先前 `-through` 指定节点的**后继节点**。

```txt
-through {I'add1 I'add2} -through {N'mux1_o N'mux2_o}
# 路径必须先经过名为 add1 或 add2 的元件实例，然后经过名为 mux1_o 或 mux2_o 的连线
```

**to** — 类型：字符串，缺省值：无
指定时序路径的**终点**名称列表。合法终点包括：输出或双向端口、时序元件上与时钟同步的输入端引脚（如触发器 D 端）。类型限定符及查找顺序同 `from`（端口→引脚→元件实例→连线）。终点为元件实例名时表示该实例上与时钟同步的输入引脚；为连线名时表示驱动该连线的引脚或端口。名称可含通配符。

```txt
ta.report ... -to {P'out? p'myff*/D}
# 终点必须为名字形如 "out?" 的外部端口，或名字形如 "myff*" 的元件实例的 "D" 端引脚
```

**to_clk** — 类型：字符串，缺省值：无
指定终点的时钟条件，格式：
- `<时钟名>` — 终点必须同步于相应名称的时钟
- `<时钟名称>|R` — 必须同步于该时钟上升沿
- `<时钟名称>|F` — 必须同步于该时钟下降沿

```txt
ta.report ... -to clk2|F   # 终点必须同步于时钟 clk2 的下降沿
```

**type** — 类型：枚举(setup|hold)，缺省值：setup
指定报告的关键路径类型：setup 路径或 hold 路径。
> **注**：时序分析时可用 `ta.set` 设定同时分析 setup 和 hold，但**每次时序报告只能报告一种类型**的路径。

### 示例

```txt
ta.report -type hold                 # 报告 hold 关键路径
ta.report -max_common_paths 10       # 每个时序检查点最多报告 10 条路径
ta.report -max_paths 10 -fields {NODE AT LOC}   # 报告前 10 条关键路径，字段为节点名、到达时间、位置
```

> 疑点：原文示例第三条使用 `-max_path`（单数），而语法为 `-max_paths`（复数）。

---

## ta.run

运行静态时序分析（STA – Static Timing Analysis）。

```txt
ta.run
```

无参数。

- **注意**：必须先给定时序约束才能进行时序分析。
- 运行时序分析前可通过 `ta.set` 设置各种时序分析选项。

---

## ta.set

设置时序分析选项。

> **注**：HqFpga 中时序分析与优化使用同一引擎，本命令的设置也会影响核心例程（如布局、布线）的结果。

```txt
ta.set
[-analysis_type/-at <analysis_type_value>]
[-cross_clkdom_analysis/-cca <cross_clkdom_analysis_value>]
[-dynamic_loop_breaking/-dlb <dynamic_loop_breaking_value>]
[-io_reg_analysis/-ira <io_reg_analysis_value>]
[-see_thru_usr_hier/-stuh <see_thru_usr_hier_value>]
[-time_unit/-tu <time_unit_value>]
[-reset_all]
```

| 参数（别名） | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| analysis_type（-at） | 枚举(setup\|hold\|both) | setup | 分析类型：setup 只做建立分析；hold 只做保持分析；both 同时做建立/保持分析。设为 both 运行时间较长，运行核心例程前一般不推荐 |
| cross_clkdom_analysis（-cca） | 枚举(on\|off) | off | 是否分析跨时钟域的路径 |
| dynamic_loop_breaking（-dlb） | 枚举(on\|off) | off | 是否对组合回路动态截断。缺省 off 即静态截断，静态截断可能漏掉一些路径；动态截断不遗漏路径但运行时间变长 |
| io_reg_analysis（-ira） | 枚举(on\|off) | on | 是否分析未加约束 IO 与时钟之间的路径。为 on 时，自动对每个未加约束输入端口相对每个时钟设置零输入延迟（input delay），对每个未加约束输出端口相对每个时钟设置零输出延迟（output delay） |
| see_thru_usr_hier（-stuh） | 枚举(on\|off) | on | 时序分析时是否“看穿”用户层次模块，即是否仅考虑“叶子”节点而忽略用户层次模块 |
| time_unit（-tu） | 枚举(1ps\|10ps\|100ps\|1ns\|10ns\|100ns\|1us\|10us\|100us\|1ms\|10ms\|100ms\|1s) | 1ns | 时序约束中使用的时间值单位。例：time_unit 设为 100ps 时，`create_clock -period 50` 中 "50" 实际为 50×100ps=5000ps |
| reset_all | 开关 | 无 | 将上述所有设置恢复为缺省值 |

```batch
ta.set -cca on   # 分析跨时钟域路径
```

> 疑点：原文参数说明中 `dynamic_loop_breaking` 的别名写作 `-d1b`（数字 1），与语法中的 `-dlb` 不一致，应为 `-dlb`（字母 l）。

---

## taset.query

查询时序分析选项（即 `ta.set` 设定的值）。

```txt
taset.query
[-analysis_type/-at <analysis_type_value>]
[-cross_clkdom_analysis/-cca <cross_clkdom_analysis_value>]
[-dynamic_loop_breaking/-dlb <dynamic_loop_breaking_value>]
[-inside_phy_hier/-iph <inside_phy_hier_value>]
[-io_reg_analysis/-ira <io_reg_analysis_value>]
[-see_thru_usr_hier/-stuh <see_thru_usr_hier_value>]
[-time_unit/-tu <time_unit_value>]
[-all]
```

| 参数（别名） | 返回值 |
|------|--------|
| analysis_type（-at） | setup / hold / both |
| cross_clkdom_analysis | on 或 off（是否分析跨时钟域路径） |
| dynamic_loop_breaking | on 或 off（是否动态截断组合回路） |
| inside_phy_hier（-iph） | on 或 off（是否分析物理层次内的时序路径） |
| io_reg_analysis（-ira） | on 或 off（是否分析未加约束 IO 与时钟之间的路径） |
| see_thru_usr_hier（-stuh） | on 或 off（是否“看穿”用户层次模块，仅考虑叶子节点） |
| time_unit（-tu） | 1ps\|10ps\|100ps\|1ns\|10ns\|100ns\|1us\|10us\|100us\|1ms\|10ms\|100ms\|1s |
| all | 查询上述所有设置 |

```txt
taset.query -cca     # 查询是否分析跨时钟域路径
taset.query -all
# 可能结果：
-see_thru_usr_hier on \
-inside_phy_hier off \
-analysis_type setup \
-dynamic_loop_breaking off \
-io_reg_analysis off \
-cross_clkdom_analysis off \
-time_unit 1ns
```

> 疑点：原文参数说明中 `io_reg_analysis` 的说明错置于 `see_thru_usr_hier` 之后，本蒸馏已按语义整理归位。

---

## tc.autogen

自动产生时序约束。

```txt
tc.autogen [-force] [-idly <idly_value>]
    [-odly <odly_value>] [-period <period_value>]
    [-print]
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| force | 开关 | 无 | 设计中已存在时序约束时，缺省本命令不起作用；指定后强行自动产生并替换已有约束 |
| idly | 浮点 | 无 | 指定时对每一个非时钟输入端口或双向端口自动生成指定值的输入延迟（input delay） |
| odly | 浮点 | None | 指定时对每一个输出端口或双向端口自动生成指定值的输出延迟（output delay） |
| period | 浮点 | 10 | 缺省自动检测设计中时钟，将每个时钟周期设为 10ns；指定后设为用户期望值 |
| print | 开关 | 无 | 缺省自动产生的约束立即生效；指定后仅以 SDC 格式打印生成的约束（不生效） |

```txt
tc.autogen                        # 时钟周期 10ns，不产生输入/输出延迟约束
tc.autogen -period 8 -idly 0.4 -odly 0.5
# 时钟周期 8ns，输入延迟 0.4ns，输出延迟 0.5ns
```

---

## tc.clear

清除所有的时序约束。

```txt
tc.clear
```

无参数。

---

## upc.read

读入 UPC 格式的物理约束文件（HqFpga 专有物理约束文件格式）。

```txt
upc.read <filename>
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| filename | 字符串 | None | 要读入的物理约束文件名称 |

- 物理约束文件文件名后缀通常为 `.upc`。
- 基于 TCL 语法，支持如下物理约束命令：

```txt
phycst.pin.set
phycst.loc.set
phycst.region.create
phycst.region.set
```

```txt
upc.read my.upc   # 读取名为 "my.upc" 的物理约束文件
```

---

## xpn.read

读入 XPN（Xist Physical Netlist）物理网表。

```txt
xpn.read <filename>
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| filename | 字符串 | 无 | 将要读入的 XPN 文件名 |

- XPN 主要用于帮助完成 **ECO** 功能。
- 可读入组装、布局、布线各阶段产生的 XPN 文件并完成后续步骤（如读入布局后的 XPN 后运行布线）。
- 相比 `design.save/load` 的二进制文件，XPN 是**纯文本文件**，可读性和可修改性更好。

```txt
xpn.read aft_place.xpn   # 读取名为 "aft_place.xpn" 的 XPN 文件
```

---

## xpn.write

输出 XPN（Xist Physical Netlist）物理网表。

```txt
xpn.write <filename>
```

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| filename | 字符串 | 无 | 将要输出的 XPN 文件名 |

```txt
xpn.write aft_place.xpn   # 输出名为 "aft_place" 的 XPN 网表文件
```
