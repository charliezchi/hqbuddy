<!-- 来源：docs/user_manual/hqfpga_um_chs.md 第 17–213 行（§3 FPGA 设计流程简介、§4 HqFpga 设计流程简介） -->

# HqFpga 流程原理蒸馏（§3 / §4）

> 本部分为叙述性章节（无命令参考），聚焦 FPGA 设计实现各阶段原理、输入输出与关键术语，以及 HqFpga 的两条实现流程。

## §3 FPGA 设计流程简介

本节从**工具实现的内部视角**介绍 FPGA 设计基本流程，用于理解后续章节术语。流程主线：**设计描述 → 综合 → 工艺映射 → 组装(packing) → 聚类(clustering) → 布局 → 布线 → 位流**。

### 3.1 设计描述

- 设计描述 = 用户用硬件描述语言（业界标准为 **Verilog / VHDL**）表达目标电路功能。
- 描述级别由高到低：
  | 描述级别 | 特点 | 典型描述方式 |
  | --- | --- | --- |
  | 算法级（行为级） | 粗略时序，功能复杂抽象 | 浮点数/复数运算、控制结构复杂（如循环次数无法预判） |
  | 寄存器传输级（RTL） | 精确时序，功能具体，划分好状态/时钟周期 | 定点/整型运算、比较、移位，简单控制结构，循环次数固定 |
  | 逻辑级（门级） | 简单逻辑功能 | 布尔运算、逻辑门 |

### 3.2 综合与工艺映射

- **综合**：由工具自动把设计描述生成电路结构的过程。与设计级别对应分高级综合、RTL 综合、逻辑综合；业界成熟且广泛采用的是 **RTL 综合**。HqFpga 支持的就是 RTL 综合（下文"综合"均指 RTL 综合）。
- **工艺映射(Technology Mapping)**：把工艺无关的电路结构映射到 FPGA 基本逻辑单元的过程。综合后的网表是工艺无关的，需映射到目标器件的基本单元。
- **基本逻辑单元**命名因厂商而异：Xilinx 称 LC(Logic Cell)（现在文档常以"切片"SLICE 代替，SLICE 分上下相同两半，每半可视为一个 LC）；Altera 称 LE(Logic Element) 或 ALM(Advanced Logic Module)。各厂商单元可抽象为通用结构 **BLE（Basic Logic Element）**：
  - 含 1 个查找表 **LUT(Look-Up Table)**、1 个时序元件、1 个多路复用器。
  - n 输入 LUT 可实现任意 n 输入组合逻辑（通常 4 输入）；LUT 也可配置成存储块（RAM）或移位寄存器。
  - 时序元件可配置成触发器（FF）或锁存器（LATCH）。
  - 多路复用器选择时序元件数据输入来自 LUT 还是 BLE 外部。
- **优化因素**：综合时针对同一功能有多种实现结构可选。例如加法器：行波进位（Carry Ripple）/ 超前进位（Carry Lookahead）/ 进位选择（Carry Select）。选型取决于：目标器件特性、设计规模、优化目标。多数厂商 FPGA 含专用算术进位资源，中小规模加法通常选行波进位以利用资源；某些器件含进位选择逻辑则可能选进位选择；大而高性能的加法可能选超前进位或直接用 DSP 块。
- **专用进位资源对映射的影响**：带进位链的 BLE（专用算术进位逻辑）可把某结构 FA 映射进单个 BLE，面积更省（1 个 vs 2 个）、时序更好（专用布线资源级联延迟小 vs 普通布线延迟大）。但通用 BLE 能映射的结构，专用进位 BLE 未必能直接映射——目标器件结构影响综合实现，这是综合工具需考虑的约束。

### 3.3 组装与聚类

- **组装(packing)**：把组合逻辑与时序逻辑一起"打包"进 FPGA 基本逻辑单元的过程。BLE 既含组合也含时序单元，工具需将 DFF 等时序逻辑与组合逻辑（如 FA）装入 BLE。
- **组装质量**：相关逻辑（如 FA 的某端口组合逻辑 + 其对应寄存器）应打包进同一单元；**无关组装(un-related packing)** 把不相关逻辑打包进同一单元会产生多余 BLE 间互连，导致性能下降（参考示例：BLE0 的 O 引脚 → BLE1 的 E 引脚）。
- **聚类(clustering)**：把基本逻辑单元合入更大层次结构块。FPGA 硬件分层次：
  - 例：Altera Stratix II，基本单元 ALM，10 个 ALM 组成 1 个 LAB(Logic Array Block)。
  - LAB 内 ALM 互连用较短较快互连线，但数量少且有特殊限制（如一个 LAB 中所有 ALM 的时序控制信号 clock/reset/preset 必须相同）。
  - LAB 外互连线种类丰富（单线、双线、4 倍线等）数量多，但延迟较长。
  - Clustering 需据此决策哪些单元放同一 LAB。
- **组装 vs 聚类本质相同**：都是打包/装箱过程。区别：组装把电路逻辑打包成 FPGA 单元；聚类把低层次 FPGA 单元打包成高层次 FPGA 结构块。

### 3.4 布局布线

- 组装与聚类完成后，所用单元/结构块的类型与数目确定。
- **布局(Placement)**：将不同类型单元放置到合适位置。示例：3 个 BLE（BLE0 与 BLE1、BLE2 相连，BLE1 与 BLE2 不相连）放置到 3×3 BLE 阵列，方案有 9×8×7=504 种。好的布局使布线容易、总线长更短。
- **布线(Routing)**：将位置固定的单元连接起来。布局相同的情况下，布线结果仍有优劣。
- **位流**：布线完成后得到完整物理网表，再产生位流(bitstream)，下载到 FPGA 芯片或配置存储器，最终完成设计实现。

### 3.5 小结与厂商术语对照

- 上述步骤在 HqFpga 中均集成在一个可执行文件中，通过不同命令实现。
- 各厂商对流程定义/术语不同：
  | 厂商/软件 | 阶段划分 | 对应本节步骤 | 工具名 |
  | --- | --- | --- | --- |
  | Xilinx ISE | 综合 | 综合与工艺映射 | `xst` |
  | Xilinx ISE | 实现(Implementation) | 组装与聚类 | `map` |
  | Xilinx ISE | 实现(Implementation) | 布局布线 | `par` |
  | Altera Quartus II | 分析与综合(Analysis & Synthesis) | 综合与工艺映射 + 组装与聚类 | `quartus_map` |
  | Altera Quartus II | 适配(Fitting) | 布局布线 | `quartus_fit` |

## §4 HqFpga 设计流程简介

HqFpga 支持两种实现流程：

### ■ RTL 到 FPGA 实现流程（RTL-to-FPGA 流程）

- **起点**：原始 RTL 描述。
- **步骤序列**：RTL 综合 → 组装/聚类 → 布局 → 布线 → ……（含全部 FPGA 设计实现步骤）。
- **注意**：目前 HqFpga 内置综合器**支持 Verilog，不支持 VHDL**（详见手册第 8 章）。

### ■ 网表到 FPGA 实现流程（Netlist-to-FPGA 流程）

- **起点**：第三方 FPGA 综合工具（如 Synopsys 的 Synplify）的 RTL 综合结果网表。
- **步骤序列**：先用第三方工具综合（选取与 HqFpga 所支持器件结构类似的器件）→ 用 HqFpga 的**重映射(remapping)** 功能将网表重新映射到 XIST 器件 → 完成后续设计实现。
- **关键术语**：重映射(remapping / re-mapping)。

---

## 关键术语速查（本章涉及）

- 综合 synthesis / 工艺映射 technology mapping (mapping) / 反映射 unmapping / 重映射 re-mapping
- 组装 packing / 聚类 clustering / 布局 placement / 布线 routing
- 网表 netlist / 位流 bitstream / 基本逻辑单元（BLE/LC/LE/ALM）/ LUT / FF / LATCH / LAB
- RTL 寄存器传输级 / 单元 cell / 元件实例 instance / 引脚 pin / 端口 port

## 原文疑点

1. 图 3、图 9 两处"如图 5 所示"的 BLE 进位链结构在正文中未见明确图片对应说明，图 9 的标题标注在正文文字之前，排版顺序略有错乱（§3.3 组装与聚类）。文中示例所引图片均为外部 cdn 链接，正文蒸馏时已剥离。
2. §3.5 厂商对照表中"（布局布线）"等括号部分因原文换行断裂，含义已按上下文还原。
3. 部分标点/字母渲染碎裂（如 FF 的"F1ipFlop"、Carry Select 的"Carry Select"、Synplify 的"Synplify"），均按上下文还原为标准写法。
4. §4 RTL-to-FPGA 与 Netlist-to-FPGA 两段均为短描述，原文未列出二者详细的逐步命令序列，本蒸馏仅还原原文所述步骤，未编造命令。

<!-- 来源：docs/user_manual/hqfpga_um_chs.md 第 334–605 行（§10 综合、§11 U 命令概览） -->

# Part 03：综合流程与命令地图（§10 综合、§11 U 命令概览）

## 一、综合（§10）

### 10.1 简介

HqFpga 内置综合器以 **Verilog RTL** 描述为输入，综合并生成映射到 FPGA 基本单元的设计网表（mapped netlist）。主要功能：

- Verilog 语言解析
- 组合逻辑网络生成
- 时序器件推断与生成
- FPGA 特殊资源（快速算术运算单元、Block RAM 等）的推断与映射
- 表达式优化
- 资源共享
- 有限状态自动机优化
- MUX 优化
- 两级与多级逻辑优化
- 工艺映射

### 10.2 Verilog 语言支持

综合器支持 **Verilog-2001（IEEE Std 1364-2001）**，向下兼容 **Verilog-95（IEEE Std 1364-1995）**。可综合子集参考 IEEE Std 1364.1-2002 及常用 RTL 综合工具的可综合性支持。

| 方面 | 支持情况 |
|---|---|
| 变量、表达式 | 绝大部分支持；**不支持实数和 time 类型** |
| 层次化结构 | 绝大部分支持；**不支持跨模块层次名称引用** |
| 行为语句 | 大部分支持；**不支持**：过程性连续赋值（assign/deassign、force/release）、fork/join、wait、always 块中多个敏感列表 |
| 任务和函数 | 支持函数，含递归自动函数调用（recursive automatic function call） |
| 元注释（meta-comment）及综合引导（pragma） | 支持，如 `parallel_case`、`full_case`、`translate_on`、`translate_off` 等 |
| 触发器/锁存器推断 | 支持 |
| 三态推断 | 支持；可从条件语句、case 语句、条件表达式等各种部分 Z 值赋值中推断三态 |
| 存储器推断 | 支持多种模式：写优先（write first）/读优先（read first）、单端口/双端口、同步读/异步读等 |

> 详细支持情况参见原文第 13 章。

### 10.3 综合流程

综合流程按命令执行顺序进行，各步骤对应命令见下（原文有流程总图，此处以文字还原）：

```
设定 RTL 综合优化选项 (rtl.set)
   ↓
Verilog RTL 文件分析 (design.analyze)
   ↓
RTL 综合及逻辑优化
   ├─ RTL 综合确立 (rtl.elaborate)
   ├─ 宏单元映射 (macro.map)
   └─ 两级与多级逻辑优化 (design.lo.area)
   ↓
读入时序约束（可选）(sdc.read)
   ↓
时序驱动优化及映射
   ├─ 时序驱动优化 (design.lo.timing)
   ├─ 插入 IO 单元 (nl.ioinsertion)
   └─ 工艺映射 (design.map)
   ↓
综合结果输出、检查 (nl.write / edif.write / nl.report / ta.report)
```

#### 10.3.1 设定 RTL 综合优化选项

综合前可通过 U 命令 `rtl.set` 设定 RTL 综合优化选项。

**示例**
```batch
rtl.set -infer_ram off -mux_opt off
```
（含义：RTL 综合时不识别 RTL 源描述中的 RAM，且不进行 MUX 优化。）

`rtl.set` 常用选项及缺省值：

| 选项 | 取值 | 说明 | 缺省 |
|---|---|---|---|
| `-infer_ram` | on/off | 允许/禁止识别 RAM | on |
| `-infer_rom` | on/off | 允许/禁止识别 ROM | on |
| `-infer_srl` | on/off | 允许/禁止识别移位寄存器 | on |
| `-mux_opt` | on/off | 允许/禁止 MUX 优化 | on |
| `-fsm_opt` | on/off | 允许/禁止状态机优化 | on |
| `-expr_opt` | on/off | 允许/禁止表达式优化 | on |
| `-share_opt` | on/off | 允许/禁止资源共享优化 | on |

#### 10.3.2 Verilog RTL 文件分析

本步骤对原始 Verilog 文件进行解析/分析（词法、语法、语义分析），生成内部语法树表示，类似普通编程语言的编译过程。

命令：`design.analyze`，输入是**文件名列表**，用于指定要分析的文件；分析成功则生成内部语法树表示。

**示例**
```txt
# 解析单个文件
design.analyze mydesign.v

# 解析多个文件
design.analyze {mytop.v mymodule1.v mymodule2.v}

# 解析当前目录下所有后缀为 .v 的文件（文件名列表由 TCL 内置命令 glob 产生）
design.analyze [glob *.v]
```

与 `design.analyze` 相关的命令：

- `rtl.incpath.add/clear`：定义/清除 Verilog 文件包含路径。
- `macro.define/undefine`：定义/清除宏定义。
- 详情分别参见原文 15.78、15.79、15.80、15.81 节。

#### 10.3.3 RTL 综合及逻辑优化

分如下子步骤：

**（1）RTL 综合确立（elaboration）**

在语法树基础上，通过一系列识别、转换过程最终产生**工艺无关的门级网表**（类似编译过程的"链接"，结果是网表而非汇编/机器码）。

命令：`rtl.elaborate`。执行后自动识别并设置顶层模块，规则：
- 若某模块未被实例化过，则设其为顶层；
- 若有多个未被实例化的模块，则设**最后一个未被实例化**的模块为顶层；
- 上述任何情况下，均可通过 `-top` 参数强行指定顶层模块。

**示例**
```txt
design.analyze {myfile1.v myfile2.v myfile3.v}
rtl.elaborate -top mymodule2
```

**（2）宏单元映射**

RTL 综合确立后生成的工艺无关门级网表，还需针对 FPGA 宏单元进行映射。宏单元指数据通路元件（加法器、减法器、乘法器、计数器、移位寄存器等）、存储器阵列（RAM）及其它较大颗粒度的非门级 FPGA 特殊元件。综合确立阶段推断出宏单元后，本步骤将它们映射到 FPGA 相应资源。

命令：`macro.map`。

**（3）两级与多级逻辑优化**

主要完成面积优化。

命令：`design.lo.area`（详见原文 15.4 节）。

#### 10.3.4 读入时序约束（可选）

HqFpga 所有优化过程都是**时序驱动（timing-driven）**的；时序驱动的关键在于给定**时序约束**。

- 约束命令：`sdc.read`（详见原文 15.87 节及第 7.2.3.3 节）。
- 若跳过本步骤（不指定时序约束），后续优化过程**都以面积为优化目标**。

#### 10.3.5 时序驱动优化及映射

**（1）时序驱动优化**

命令：`design.lo.timing`（详见原文 15.5 节）。

**（2）插入 IO 单元**

命令：`nl.ioinsertion`（详见原文 15.51 节）。

**（3）工艺映射**

命令：`design.map`（详见原文 15.7 节）。

#### 10.3.6 综合结果输出、检查

工艺映射完成后产生映射后网表（mapped netlist），可输出与检查：

- 输出网表：`nl.write`（Verilog 网表格式）、`edif.write`（EDIF 网表格式）。
- 报告资源使用情况：`nl.report`（详见原文 15.54 节）。
- 时序报告：`ta.report`（详见原文 15.91 节及 7.2.3.14 节）。

---
