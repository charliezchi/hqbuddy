<!-- 来源：hqfpga_um_chs.md 第1181-1326行，即 §13 Verilog 可综合子集、§14 HqFpga 支持的 SDC 语法说明 -->

# HqFpga：Verilog 可综合子集与 SDC 语法说明

> 综合依据 Verilog-2001 (IEEE Std 1364-2001) LRM。本章按 LRM 章节顺序列出综合支持情况，并在末节列出常用元注释/综合引导(pragma)的支持情况。
> §14 支持 SDC 版本 1.7 中常用命令；不支持的命令参数在原文中用灰色带中划线文字标出（本蒸馏中标注为"不支持"）。

## 13. Verilog 可综合子集

### 13.1 数据类型 (Data Type)

| LRM | 语言点 | 支持情况 |
|---|---|---|
| 3.2 | Nets and variables | 支持 |
| 3.3 | Vectors | 支持 |
| 3.4 | Strengths | 忽略 |
| 3.5 | Implicit declarations | 支持 |
| 3.6 | Net initialization | 支持 |
| 3.7.1 | wire / tri | 支持 |
| 3.7.2 | wor, wand, trior, triand | 支持 |
| 3.7.3 | trireg | 不支持 |
| 3.7.4 | tri0 / tri1 | 不支持 |
| 3.7.5 | supply0 / supply1 | 支持 |
| 3.9 | Integer, real, time, realtime | 支持整数 |
| 3.19 | Arrays | 支持 |
| 3.11 | Parameters | 支持 |

### 13.2 表达式 (Expressions)

- 算术、关系、相等、逻辑、位运算、归约、移位、条件、拼接、事件或运算符、位选择/部分选择、存储器寻址、字符串操作数：均支持。
- 4.3 最小/典型/最大延迟表达式：不支持。

### 13.3 赋值 (Assignments)

- 连续赋值 (Continuous Assignments)：支持。
- 过程赋值 (Procedural Assignments)：详见 13.6 行为建模。

### 13.4 门级与开关级建模 (Gate and switch level)

- 支持：and/nand/nor/or/xor/xnor、buf/not、bufif1/bufif0/notif1/notif0。
- 不支持：MOS switches、双向 pass switches、CMOS switches、pullup/pulldown 源。

### 13.5 用户定义原语 (UDP)

- 组合型、电平敏感时序型、边沿敏感时序型 UDP 均不支持。

### 13.6 行为建模 (Behavioral Modeling)

| LRM | 语言点 | 支持情况 |
|---|---|---|
| 9.2.1 | 阻塞赋值 (blocking) | 支持 |
| 9.2.2 | 非阻塞赋值 (nonblocking) | 支持 |
| 9.3 | 过程连续赋值 | 不支持 |
| 9.4 | 条件语句 | 支持 |
| 9.5 | case 语句 | 支持 |
| 9.6 | 循环语句 | 支持 |
| 9.7.1 | 延迟控制 (Delay control) | 忽略 |
| 9.7.2 | 事件控制 (Event control) | 仅支持在 always 块开始处使用 |
| 9.7.3 | 命名事件 (Named events) | 不支持 |
| 9.7.4 | 事件或运算符 | 支持 |
| 9.7.5 | 隐式事件表达式列表 (@*) | 支持 |
| 9.7.6 | 电平敏感事件控制 | 不支持 |
| 9.7.7 | 赋值内时序控制 | 忽略 |
| 9.8.1 | 顺序块 (begin...end) | 支持 |
| 9.8.2 | 并行块 (fork...join) | 不支持 |
| 9.9.1 | initial 结构 | 不支持 |
| 9.9.2 | always 结构 | 支持 |
| 9.9.3 / 9.9.4 | Task / Function | 支持 |

### 13.7 任务与函数 (Tasks and functions)

- Task、Function 均支持。

### 13.8 Disable 语句

- Disable 语句：支持。

### 13.9 层次结构 (Hierarchical structures)

- Modules、Ports：支持。
- Defparam 语句：支持。
- 模块实例参数值赋值 (module instance parameter value assignment)：支持。
- 层次名 (Hierarchical names)：支持，但**不支持跨模块层次名称引用**。

### 13.10 配置 (Configuring the contents of a design)

- 综合时忽略配置。

### 13.11 说明块 (Specify blocks)

- 综合时忽略说明块。

### 13.12 编译引导 (Compiler directives)

| LRM | 指令 | 支持情况 |
|---|---|---|
| 16.1 | `` `celldefine `` / `` `endcelldefine `` | 支持 |
| 16.2 | `` `default_nettype `` | 不支持 |
| 16.3 | `` `define `` / `` `undef `` | 支持 |
| 16.4 | `` `ifdef `` / `` `else `` / `` `endif `` | 支持 |
| 16.5 | `` `include `` | 支持 |
| 16.6 | `` `resetall `` | 不支持 |
| 16.7 | `` `timescale `` | 忽略 |
| 16.8 | `` `unconnected_drive `` / `` `nounconnected_drive `` | 忽略 |

### 13.13 元注释 (meta-comment) 及综合引导 (pragma)

元注释可用等价的 Verilog 属性(pragma)形式表示，三种等价写法示例：

```verilog
// synopsys parallel_case            // 行注释形式
/* synopsys parallel_case */         // 块注释形式
(* synthesis, full_case *)           // 属性形式
```

支持的元注释/综合引导列表：

| 名称（三种等价写法） | 功能 |
|---|---|
| `` // synopsys translate_on `` / `` // synthesis translate_on `` | 将源文件中后续语句按综合语义解释 |
| `` // synopsys translate_off `` / `` // synthesis translate_off `` | 综合时忽略源文件中后续语句 |
| `` // synopsys parallel_case `` / `` // synthesis parallel_case `` / `` (* synthesis, parallel_case *) `` | 对相应 case 语句产生多路选择器（而非优先级编码器） |
| `` // synopsys full_case `` / `` // synthesis full_case `` / `` (* synthesis, full_case *) `` | 防止 case 语句在没有 default 分支时产生非预期的锁存器 |

---

## 14. HqFpga 所支持的 SDC 语法说明

> 支持 SDC 1.7 常用命令。对象访问命令按格式 `[-hierarchical][-hsc separator][-regexp][-nocase] ... [-of_objects objects] patterns` 共用一组通用选项。

### 14.1 对象访问命令

#### 获取单元/连线/引脚 get_cells / get_nets / get_pins

获取设计单元(cell)、引脚(pin)、连线(net)对象。

```
get_cells | get_nets | get_pins
  [-hierarchical] [-hsc separator] [-regexp] [-nocase]
  [-of_objects objects] patterns
```

| 参数 | 说明 |
|---|---|
| `-hierarchical` | 在网表中逐级（层次）查找 |
| `-hsc separator` | 指定层次分隔符 |
| `-regexp` | 利用正则表达式匹配对象名称 |
| `-nocase` | 大小写无关的正则表达式匹配 |
| `-of_objects objects` | 指定对象的属主对象 |
| `patterns` | 根据此名称模式查找对象 |

#### 获取时钟 get_clocks

```
get_clocks [-regexp] [-nocase] patterns
```

| 参数 | 说明 |
|---|---|
| `-regexp` | 利用正则表达式匹配时钟名称 |
| `-nocase` | 大小写无关的正则表达式匹配 |
| `patterns` | 根据此名称模式查找时钟 |

#### 获取端口 get_ports

```
get_ports [-regexp] [-nocase] patterns
```

| 参数 | 说明 |
|---|---|
| `-regexp` | 利用正则表达式匹配端口名称 |
| `-nocase` | 大小写无关的正则表达式匹配 |
| `patterns` | 根据此名称模式查找端口 |

#### 所有时钟 all_clocks

```
all_clocks
```

获取所有时钟对象。

#### 所有输入/输出 all_inputs / all_outputs

```
all_inputs  [-level_sensitive] [-edge_triggered] [-clock clock_name]
all_outputs [-level_sensitive] [-edge_triggered] [-clock clock_name]
```

| 参数 | 说明 |
|---|---|
| `-level_sensitive` | 限定带有电平敏感的输入/输出延迟的端口 |
| `-edge_triggered` | 限定带有边沿触发的输入/输出延迟的端口 |
| `-clock clock_name` | 限定具有相对于指定时钟的输入/输出延迟的端口 |

### 14.2 时钟级别约束命令

支持命令概览：

```
create_clock
create_generated_clock
set_clock_latency
set_clock_uncertainty
```

#### 创建时钟对象 create_clock

```
create_clock
  [-period period_value]
  [-name clock_name]
  [-waveform edge_list]
  [-add]
  [source_objects]
```

| 参数 | 说明 |
|---|---|
| `-period period_value` | 时钟周期 |
| `-name clock_name` | 时钟名称 |
| `-waveform edge_list` | 时钟波形 |
| `-add` | 用于在同一时钟源点创建多个时钟 |
| `source_objects` | 时钟源点：端口、引脚或连线 |

#### 创建生成时钟 create_generated_clock

```
create_generated_clock
  [-name clock_name]
  -source master_pin
  [-edges edge_list]
  [-divide_by factor]
  [-multiply_by factor]
  [-duty_cycle percent]
  [-invert]
  [-edge_shift shift_list]
  [-add]
  [-master_clock clock]
  source_objects
  [-combinational]
```

| 参数 | 说明 |
|---|---|
| `-name clock_name` | 时钟名称 |
| `-source master_pin` | 主时钟源点：端口、引脚或连线 |
| `-edges edge_list` | 产生生成时钟波形的主时钟波形边沿序号 |
| `-divide_by factor` | 时钟分频因子 |
| `-multiply_by factor` | 时钟倍频因子 |
| `-duty_cycle percent` | 生成时钟的占空比 |
| `-invert` | 将生成的时钟波形反相 |
| `-edge_shift shift_list` | 生成时钟波形相对于主时钟波形的偏移 |
| `-add` | 用于在同一时钟源点创建多个生成时钟 |
| `-master_clock clock` | 当同一主时钟源点上有多个主时钟时，指定本生成时钟的主时钟 |
| `source_objects` | 生成时钟源点：端口、引脚或连线 |
| `-combinational` | 生成时钟的源延时仅和主时钟传播路径相关，不经过时序元件 |

#### 设置时钟时延 set_clock_latency

```
set_clock_latency
  [-rise] [-fall] [-min] [-max]
  [-source] [-late] [-early]
  [-clock clock_list]
  delay
  object_list
```

| 参数 | 说明 |
|---|---|
| `-rise` | 上升时延 |
| `-fall` | 下降时延 |
| `-min` | 最好情况时延 |
| `-max` | 最坏情况时延 |
| `-source` | 时延类型为源时延（缺省为网络时延） |
| `-late` | 最晚时延 |
| `-early` | 最早时延 |
| `-clock clock_list` | 当时延设置对象为端口或引脚时，指定相关时钟 |
| `delay` | 时延值 |
| `object_list` | 时延要设置的对象：时钟、端口或引脚 |

#### 设置时钟不确定性 set_clock_uncertainty

原文命令名为 `set_clock_uncertainy`（疑为拼写错误，标准 SDC 为 `set_clock_uncertainty`）。

```
set_clock_uncertainty
  [-from from_clock]
  [-rise_from rise_from_clock]
  [-fall_from fall_from_clock]
  [-to to_clock]
  [-rise_to rise_to_clock]
  [-fall_to fall_to_clock]
  [-rise] [-fall] [-setup] [-hold]
  Uncertainty
  [object_list]
```

| 参数 | 说明 |
|---|---|
| `-from from_clock` | 指定时钟间不确定性之源时钟 |
| `-rise_from rise_from_clock` | 限定源时钟为上升沿 |
| `-fall_from fall_from_clock` | 限定源时钟为下降沿 |
| `-to to_clock` | 指定时钟间不确定性之目标时钟 |
| `-rise_to rise_to_clock` | 限定目标时钟为上升沿（原文此行的参数名写作 `rise_from`，应为 `rise_to`，疑为原文笔误） |
| `-fall_to fall_to_clock` | 限定目标时钟为下降沿 |
| `-rise` | 不确定性只作用于目标时钟的上升沿 |
| `-fall` | 不确定性只作用于目标时钟的下降沿 |
| `-setup` | 不确定性只在建立(setup)分析时有效 |
| `-hold` | 不确定性只在保持(hold)分析时有效 |
| `Uncertainty` | 最大不确定值 |
| `object_list` | 时钟不确定性作用的时钟、端口或引脚 |

### 14.3 IO 约束命令

支持命令概览：

```
set_input_delay
set_output_delay
```

#### 设置输入/输出延迟 set_input_delay / set_output_delay

```
set_input_delay | set_output_delay
  [-clock clock_name]
  [-clock_fall]
  [-level_sensitive]
  [-rise] [-fall] [-max] [-min]
  [-add_delay]
  [-network_latency_included]
  [-source_latency_included]
  delay_value
  port_pin_list
```

| 参数 | 说明 |
|---|---|
| `-clock clock_name` | 相关时钟名称 |
| `-clock_fall` | 相关时钟下降沿 |
| `-level_sensitive` | 相关时钟为电平触发 |
| `-rise` | 上升延迟 |
| `-fall` | 下降延迟 |
| `-max` | 最长延迟 |
| `-min` | 最短延迟 |
| `-add_delay` | 用于对同一端口设置不同延迟 |
| `-network_latency_included` | 延迟值中包含了时钟网络时延 |
| `-source_latency_included` | 延迟值中包含了时钟源时延 |
| `delay_value` | 延迟值 |
| `port_pin_list` | 要设置延迟的输入/输出端口 |

### 14.4 路径约束/时序例外命令

支持命令概览：

```
set_max_delay
set_min_delay
set_multicycle_path
set_false_path
```

#### 设置最大/最小延迟 set_max_delay / set_min_delay

set_max_delay 设置最大路径延迟，set_min_delay 设置最小路径延迟。

```
set_max_delay | set_min_delay
  [-rise] [-fall]
  [-from from_list]
  [-rise_from rise_from_list]
  [-fall_from fall_from_list]
  [-to to_list]
  [-rise_to rise_to_list]
  [-fall_to fall_to_list]
  [-through through_list]
  [-rise_through rise_through_list]
  [-fall_through fall_through_list]
  delay_value
```

| 参数 | 说明 |
|---|---|
| `-rise` | 限定路径终点仅允许上升沿信号/时钟通过 |
| `-fall` | 限定路径终点仅允许下降沿信号/时钟通过 |
| `-from from_list` | 路径起点：时钟、端口、引脚或单元 |
| `-rise_from rise_from_list` | 限定路径起点仅允许上升沿信号/时钟通过 |
| `-fall_from fall_from_list` | 限定路径起点仅允许下降沿信号/时钟通过 |
| `-to to_list` | 路径终点：时钟、端口、引脚或单元 |
| `-rise_to rise_to_list` | 限定路径终点仅允许上升沿信号/时钟通过 |
| `-fall_to fall_to_list` | 限定路径终点仅允许下降沿信号/时钟通过 |
| `-through through_list` | 路径经过点：端口、引脚、单元或连线 |
| `-rise_through rise_through_list` | 限定路径经过点仅允许上升沿信号/时钟通过 |
| `-fall_through fall_through_list` | 限定路径经过点仅允许下降沿信号/时钟通过 |
| `delay_value` | 延迟值 |

#### 设置多时钟周期路径 set_multicycle_path

```
set_multicycle_path
  [-setup] [-hold] [start] [end]
  [-rise] [-fall]
  [-from from_list]
  [-rise_from rise_from_list]
  [-fall_from fall_from_list]
  [-to to_list]
  [-rise_to rise_to_list]
  [-fall_to fall_to_list]
  [-through through_list]
  [-rise_through rise_through_list]
  [-fall_through fall_through_list]
  path_multiplier
```

| 参数 | 说明 |
|---|---|
| `-setup` | 影响建立(setup)分析 |
| `-hold` | 影响保持(hold)分析 |
| `start` | 周期指路径起点时钟的周期 |
| `end` | 周期指路径终点时钟的周期 |
| `-rise` / `-fall` | 限定路径终点仅允许上升沿/下降沿信号或时钟通过 |
| `-from from_list` | 路径起点：时钟、端口、引脚或单元 |
| `-rise_from rise_from_list` | 限定路径起点仅允许上升沿信号/时钟通过 |
| `-fall_from fall_from_list` | 限定路径起点仅允许下降沿信号/时钟通过 |
| `-to to_list` | 路径终点：时钟、端口、引脚或单元 |
| `-rise_to rise_to_list` | 限定路径终点仅允许上升沿信号/时钟通过 |
| `-fall_to fall_to_list` | 限定路径终点仅允许下降沿信号/时钟通过 |
| `-through through_list` | 路径经过点：端口、引脚、单元或连线 |
| `-rise_through rise_through_list` | 限定路径经过点仅允许上升沿信号/时钟通过 |
| `-fall_through fall_through_list` | 限定路径经过点仅允许下降沿信号/时钟通过 |
| `path_multiplier` | 时钟倍数 |

#### 设置伪路径 set_false_path

```
set_false_path
  [-setup] [-hold]
  [-rise] [-fall]
  [-from from_list]
  [-rise_from rise_from_list]
  [-fall_from fall_from_list]
  [-to to_list]
  [-rise_to rise_to_list]
  [-fall_to fall_to_list]
  [-through through_list]
  [-rise_through rise_through_list]
  [-fall_through fall_through_list]
```

| 参数 | 说明 |
|---|---|
| `-setup` | 建立(setup)分析时符合条件的路径为伪路径 |
| `-hold` | 保持(hold)分析时符合条件的路径为伪路径 |
| `-rise` / `-fall` | 限定路径终点仅允许上升沿/下降沿信号或时钟通过 |
| `-from from_list` | 路径起点：时钟、端口、引脚或单元 |
| `-rise_from rise_from_list` | 限定路径起点仅允许上升沿信号/时钟通过 |
| `-fall_from fall_from_list` | 限定路径起点仅允许下降沿信号/时钟通过 |
| `-to to_list` | 路径终点：时钟、端口、引脚或单元 |
| `-rise_to rise_to_list` | 限定路径终点仅允许上升沿信号/时钟通过 |
| `-fall_to fall_to_list` | 限定路径终点仅允许下降沿信号/时钟通过 |
| `-through through_list` | 路径经过点：端口、引脚、单元或连线 |
| `-rise_through rise_through_list` | 限定路径经过点仅允许上升沿信号/时钟通过 |
| `-fall_through fall_through_list` | 限定路径经过点仅允许下降沿信号/时钟通过 |
