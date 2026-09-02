<!-- 蒸馏自《HqFpga 软件综合指令使用说明》（UG1103 V2.04，2025.05.10，XiST 官方 PDF） -->

# 综合指令（Synthesis Directive）参考

在 RTL 中引导/约束 HqFPGA 综合行为。两种等价写法（以 syn_ramstyle 为例）：

- **元注释（pragma）**：`reg [7:0] mem [127:0]; /* synthesis syn_ramstyle = "block_ram" */` 或行注释 `// synthesis ...`
- **属性（attribute）**：`(* syn_ramstyle = "block_ram" *) reg [7:0] mem [127:0];`

注意：

- 元注释中关键字拼错（如 `sythesis`）不会报错，只是静默失效。生效时日志有确认信息，如 `ram_fifo_if.v(12), Found 'syn_ramstyle = block_ram' directive`。
- 一个对象施加多条指令：用**空格**分隔（不能用分号/逗号）写在同一注释内，或分成多个注释：`/* synthesis A="TRUE" syn_ramstyle="block_ram" */`。
- 未被 HQ 识别的指令视为给第三方工具的约束，会被**透传到网表**。

## 指令总表

| 指令 | 作用对象 | 取值 | 作用 |
|---|---|---|---|
| `syn_ramstyle` / `ram_style` | RAM 信号声明处 | `block` / `block_ram`、`distributed` / `distributed_ram`、`registers` | 指定 RAM 用 Block RAM / 分布式 RAM / 寄存器阵列实现 |
| `hq_romstyle` / `syn_romstyle` | **ROM 所在 module** | `block`、`distributed`、`logic` | 指定 ROM 用 Block ROM / 分布式 ROM / LUT+FF 逻辑 ROM |
| `syn_dspstyle` | module 或 net | `block`、`logic` | 乘法器/加减法用 DSP 硬核或分散逻辑 |
| `syn_srlstyle` / `srl_style` | 信号或 module | `registers`、`srl`（仅 Seal 器件）、`ram` | 移位寄存器用寄存器链 / SRL16/SRL32 原语 / RAM-based |
| `HQ_SRL_INFER` | reg/信号 | `"OFF"` | 关闭移位寄存器推断（保持寄存器链） |
| `keep` / `syn_keep` / `HQ_KEEP` | wire/net、reg | `"true"`、`1`、`"1"` | 保留 net、防单元合并、防时序元件吸入宏单元 |
| `HQ_IOREG` | 边界寄存器 reg | `"TRUE"` / `"FALSE"` | 允许/禁止用 IO 块寄存器（IOREG）实现 |
| `HQ_MAX_FANOUT` | reg/信号 | 整数 [2, INT_MAX] | 逻辑复制/插 buffer 降扇出 |
| `HQ_DATA_SKEW` | net | 单精度浮点 | 限制连线最大延迟（单扇出）或延迟差 skew（多扇出） |
| `HQ_IGNORE_PDPRAM_RWCONFLICT` | PDP-RAM 信号 | `"TRUE"` | 伪双口 RAM write-mode 强制 NORMAL（默认 READBEFOREWRITE 避冲突） |

## 各指令要点

### syn_ramstyle

- 缺省策略：容量 ≥1K 用 Block RAM，否则分布式 RAM。
- **坑**：指令为 `block_ram` 但 RAM 规模 <128 位时，HQ 仍会用 DRAM 实现。必须配合流程命令 `rtl.set -ramb_min_size 512`（或更小值）强制失效该自动处理，才能真正得到 BRAM。

### syn_romstyle / hq_romstyle

- **必须设置在 ROM 所在的 module 上**（不是信号上）；一个 module 内多个 ROM 全部受影响。要对单个 ROM 生效，单独包一个 module。
- `logic` 值的日志确认：`Candidate ROM has synthesis directive: syn_romstyle = logic, NOT infer ROM.`

### syn_dspstyle

- module 级：影响该 module 内所有乘法器、加减法；net 级：仅影响以该 net 为输出的乘法器/加减法。前提是器件结构支持。

### syn_srlstyle 与 HQ_SRL_INFER

- 三级优先级：**信号级 > 模块级 > 全局**（全局命令：`rtl.set -srl_style <registers|srl|ram>`）。
- HQ 缺省把 ≥3 级（文档他处亦提 >2 级）级联寄存器推断为 SRL16/SRL32。
- `HQ_SRL_INFER="OFF"` 加在寄存器链 DFF 的 Q-net 信号声明上；对 generate/for-loop/拼接式描述，加在数组/移位信号上即可。

### keep

- 三种名字等价：`keep`、`syn_keep`、`HQ_KEEP`；取值 `"true"`、`1`、`"1"` 均生效。
- 只保留"会被优化移除"的 net；完全悬空的照常删除。
- 关闭第三方 keep 支持（`keep`/`syn_keep` 可能意外保留 IO 或 buffer）：`rtl.set -enable_third_party_keep off`，此后只认 `HQ_KEEP`。
- **与 HQ_MAX_FANOUT 同用时后者失效**。

### HQ_IOREG

- 缺省把连到顶层端口的边界寄存器放入 IO 块（IREG/OREG）。
- 生效日志：`Info: Push r2_reg[3:0] to IREG.` / `Info: Push q1_reg[3:0] to OREG.`（被 `FALSE` 禁止的不会打印）。

### HQ_MAX_FANOUT

- 取整数 ≥2；实现为逻辑复制或插 buffer。
- 与 keep 指令同时存在时无效（keep 优先）。

### HQ_DATA_SKEW

- 单扇出 net：限制源→目标**最大延迟**；多扇出 net：限制**最大-最小延迟差（skew）**。值越苛刻越难满足。
- 只对内部数据连线有效；对以下无效：顶层边界连线（IO/IOREG）、专用布线（进位链、DSP 级联）、时钟线、全局控制线（走全局网络的 reset/set/ce）、常量线。
- **布线总是给最高优先级并走最短路径**：无论设定值大小，实质布线结果相同，只影响报告结论；可固化布线、减少扰动（TDC 固定延时场景）。
- 多扇出 skew 最小化需**配合位置约束**（各目标点等距且靠近源点），指令本身做不到。
- 建议**与 keep 联用**防连线被优化/改名。
- 布线末段打印每条指令连线的 delay（单扇出）/ skew+各目标 delay（多扇出）信息，满足或不满足均有消息。

### HQ_IGNORE_PDPRAM_RWCONFLICT

- 作用于读写同钟的伪双口 RAM；默认 write-mode=READBEFOREWRITE 规避读冲突，设 `"TRUE"` 强制 NORMAL。
- 全局等价命令：`rtl.set -ignore_pdpram_rwconflict`。

## 配套 rtl.set 全局开关速查

| 命令 | 对应指令/作用 |
|---|---|
| `rtl.set -ramb_min_size <n>` | 小 RAM 强制 BRAM（配合 syn_ramstyle=block_ram） |
| `rtl.set -srl_style <registers\|srl\|ram>` | 全局 SRL 风格（优先级最低） |
| `rtl.set -enable_third_party_keep off` | 只认 HQ_KEEP |
| `rtl.set -ignore_pdpram_rwconflict` | 全局 PDP-RAM NORMAL write-mode |
