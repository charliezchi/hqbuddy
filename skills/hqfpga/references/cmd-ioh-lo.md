<!-- 来源：docs/user_manual/hqfpga_um_chs.md 第 2348–2911 行（§15.30–15.46：impl.route、ioh.*、info.memusage、lang.set、license.query、lo.boolresub、lo.simplify、macro.map、msg；含 §15.29 impl.place 结尾部分） -->

# HqFpga 命令参考（三）：impl.route / ioh.* / info.memusage / lang.set / license.query / lo.* / macro.map / msg

## impl.place（§15.29，结尾部分）

完成布局（place）工作。

**语法**

```txt
impl.place [-effort <effort_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| effort | 枚举（low\|std\|high） | std | 布局优化强度。设为 low 时忽略用户给定的时序约束；设为 high 时用更长运行时间换取更好性能。若用户未给定时序约束，HqFpga 自动将强度调整为 low |

**示例**

```txt
impl.place -effort high
```

以最高优化强度进行布局。

## impl.route（§15.30）

完成布线（routing）工作。

**语法**

```txt
impl.route [-effort <effort_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| effort | 枚举（low\|std\|high\|extra） | std | 布线强度，越高结果越优化但运行时间越长 |

**说明**

FPGA 芯片中 90% 的资源用于布线，布线通常非常耗时。-effort 用于在布线时间与质量间折衷：

- `low`：快速寻找布线通路，运行时间短，但最终时序可能较差。
- `std`：平衡时序优化结果与运行时间。
- `high`：尽最大可能优化时序，运行时间可能很长。
- `extra`：采用最激进的优化策略，但会牺牲可布通率。

注意：

- 当 effort 为 low 时，HqFpga 布线时强制忽略时序约束（如果用户给定了时序约束）；如果用户未指定时序约束，则布线时强制使用 `-effort low`（忽略用户指定的 effort 值）。
- `extra` 仅适用于 Sealion 器件。通常 extra 模式的优化性能（FMAX）比 std 平均高 8%，但运行时间平均是 std 的两倍，且会牺牲可布通率。

**示例**

```txt
impl.route -effort high
```

进行高强度的布线。

## ioh.get_attrs（§15.31）

获取当前器件所支持的 IO 属性列表。

**语法**

```txt
info.get_attrs
```

**参数**：无

**示例**

```txt
info.get_attrs
```

列出器件 SL2-12E-8F256 所支持的 IO 属性，返回结果为（示例）：

```
IO_TYPE PULLMODE CLAMP HYSTERESIS DRIVE SLEWRATE DIFFDRIVE OPENDRAIN DIFFRESISTOR BANK_VCCIO VREF
```

## ioh.get_attr_val（§15.32）

获取端口的可用 IO 属性值列表。

**语法**

```txt
ioh.get_attr_val <port_name> <io_std> <attr_name>
```

**参数**

对特定端口、特定 IO_TYPE（IO Standard）的特定 IO 属性，获取该 IO 属性的合法值列表。

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| port_name | 字符串 | 无 | 指定端口名称 |
| io_std | 字符串 | 无 | 指定 IO_TYPE（IO standard） |
| attr_name | 字符串 | 无 | 指定 IO 属性名称 |

**示例**

```txt
ioh.get_attr_val q LVCMOS25 DRIVE
```

对端口 `q`，列出 IO_TYPE 为 `LVCMOS25` 时 IO 属性 `DRIVE` 的合法值列表，可能输出：

```txt
8 4 12 16
```

## ioh.get_iotype（§15.33）

获取端口可用的 IO_TYPE 列表。

**语法**

```txt
ioh.get_iotype <port_name>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| port_name | 字符串 | 无 | 指定端口名称 |

**示例**

```txt
ioh.get_iotype {in[1]}
```

对端口 `in[1]`，列出其适用的 IO_TYPE，可能的返回值：

```
LVCMOS25 LVCMOS12 LVCMOS15 LVCMOS18 LVCMOS33 PCI33 LVTTL33 SSTL18_I SSTL25_I HSTL18_I LVCMOS25D LVCMOS18D LVCMOS33D LVTTL33D SSTL18D_I SSTL25D_I HSTL18D_I LVCMOS25R33 LVCMOS15R33 LVCMOS18R33 LVCMOS15R25 LVCMOS18R25 SSTL18_II SSTL25_II HSTL18_II LVCMOS12D LVCMOS15D SSTL18D_II SSTL25D_II HSTL18D_II LVDS25 BLVDS25 MLVDS25 RSDS25 LVPECL33
```

## ioh.get_default_iotype（§15.34）

获取缺省的 IO_TYPE 设置。

**语法**

```txt
info.get_default_iotype
```

**参数**：无

**示例**

```txt
info.set_default_iotype LVCMOS18
info.get_default_iotype
```

上述命令执行后返回值为：`LVCMOS18`

## ioh.get_default_pullmode（§15.35）

获取缺省的 PULLMODE 设置。

**语法**

```txt
info.get_default_pullmode
```

**参数**：无

**示例**

```txt
info.set_default_pullmode KEEPER
info.get_default_pullmode
```

上述命令执行后返回值为：`KEEPER`

## ioh.get_ports（§15.36）

获取当前设计顶层端口列表。

**语法**

```txt
info.get_ports <dir>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| dir | 枚举（I\|O\|B） | 无 | 指定端口的数据传输方向：I=输入，O=输出，B=双向 |

**示例**

```txt
ioh.get_ports I
```

列出当前设计网表中所有输入类型的顶层端口。

```txt
set all_ports [concat [ioh.get_ports I] [ioh.get_ports O] [ioh.get_ports B]]
puts $all_ports
```

列出当前设计网表中所有顶层端口。

## ioh.set_default_iotype（§15.37）

设置缺省 IO_TYPE。软件对设计中的端口进行 IO 电平标准设置时，如该端口无显式 IO_TYPE 约束，则其电平标准将被设为本命令指定的类型。

**语法**

```txt
ioh.set_default_iotype <type>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| type | 字符串 | 无 | 指定 IO_TYPE |

**示例**

```txt
ioh.set_default_iotype LVCMOS18
```

将缺省 IO 电平标准设为 `LVCMOS18`。

## ioh.set_default_pullmode（§15.38）

设置缺省 PULLMODE。软件对端口进行 PULLMODE 设置时，如端口无显式 PULLMODE 约束，则其 PULLMODE 将被设为本命令指定的模式。

**语法**

```txt
ioh.set_default_pullmode <mode>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| mode | 枚举（NONE\|DOWN\|UP\|KEEPER） | 无 | 指定 PULLMODE |

**示例**

```txt
ioh.set_default_pullmode DOWN
```

将缺省 PULLMODE 设为 `DOWN`。

## ioh.set_global_attr（§15.39）

设置全局 IO 属性。

**语法**

```txt
ioh.set_global_attr [-unused_io <unused_io_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| unused_io | 枚举（auto\|tie_z） | 无 | 值为 tie_z 时，将未使用 IO 引脚设为高阻态 |

**示例**

```txt
ioh.set_global_attr -unused_io tie_z
```

将未使用 IO 引脚设为高阻态。

## info.memusage（§15.40）

报告内存占用信息。

**语法**

```txt
info.memusage [-peak]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| peak | 开关 | 无 | 报告 HqFpga 运行以来最大的内存占用；未指定则报告当前内存占用 |

**示例**

```txt
info.memusage -peak
```

报告 HqFpga 运行以来最大的内存占用情况。

## lang.set（§15.41）

设定 HqFpga 的界面语言。

**语法**

```txt
lang.set <lang>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| lang | 字符串 | 无 | 目前支持简体中文（chs）和英文（eng），取值必须是 chs 或 eng 之一 |

**示例**

```txt
lang.set chs
```

将界面语言设为简体中文。

## license.query（§15.42）

查询软件的许可证信息。

**语法**

```txt
license.query
```

**参数**：无

**运行示例**

```txt
license.query
```

查询软件的许可证信息，可能的输出如下：

```txt
#
# 本软件版本许可证信息
#
# 许可给 : Xian Intelligence Silicon Technology, Inc. (XiST)
# 类型 : volume
#
# [许可项 ] hq.main
# [失效日期] 2099.12.31
# [支持器件]
#
# [许可项 ] hq.base
# [失效日期] 2099.12.31
# [支持器件]
# SL2-12V-F256
# SL2-12E-F256
# SL2-7V-F256
# SL2-7E-F256
```

## lo.boolresub（§15.43）

执行布尔替换（Boolean re-substitution，逻辑优化操作之一）。通常被 design.lo 调用，也可单独使用。

**语法**

```txt
lo.boolresub [-algorithm <algr_type>] [-object <obj_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| algorithm | 枚举（ESPRESSO\|NOCOMP\|SNOCOMP\|EXACT\|SEPARATE\|PHASE） | NOCOMP | 指定布尔替换算法，含义与 lo.simplify 相同（见下） |
| object | 枚举（CUBE\|LITERAL\|SUPPORT） | LITERAL | 指定布尔替换目标，含义与 lo.simplify 相同（见下） |

**示例**

```txt
lo.boolresub
```

执行布尔替换：NOCOMP 算法，以 literal 数最少为优化目标。

## lo.simplify（§15.44）

执行逻辑化简（logic simplification，逻辑优化操作之一）。通常被 design.lo 调用，也可单独使用。

**语法**

```txt
lo.simplify [-algorithm <algr_type>] [-object <obj_value>] [-dc <dc_type>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| algorithm | 枚举（ESPRESSO\|NOCOMP\|SNOCOMP\|EXACT\|SEPARATE\|PHASE） | NOCOMP | 指定逻辑化简算法 |
| object | 枚举（CUBE\|LITERAL\|SUPPORT） | LITERAL | 指定优化目标 |
| dc | 枚举（DC\|NODC） | DC | 指定优化中是否生成和使用无关项 |

algorithm 取值含义：

- `ESPRESSO`：Tlo Espresso 算法
- `NOCOMP`：没有取补的 Espresso 算法
- `SNOCOMP`：一遍且没有取补的 Espresso 算法
- `EXACT`：精确的 Quine-McCluskey 算法
- `SEPARATE`：分别优化每一个多输出的函数
- `PHASE`：带有状态赋值的优化

object 取值含义：

- `CUBE`：以 cube 数最少为优化目标
- `LITERAL`：以 literal 数最少为优化目标
- `SUPPORT`：以函数的输入数（support size）最少为优化目标

dc 取值含义：

- `DC`：生成和使用无关项
- `NODC`：不生成无关项，直接优化每一个函数

**示例**

```txt
lo.simplify
```

执行网表化简：NOCOMP 算法，以 literal 数最少为优化目标，生成和使用无关项。

## macro.map（§15.45）

**语法**

```txt
macro.map
```

**参数**：无

**说明**

本命令将宏单元映射到 FPGA 的相应资源实现。宏单元指数据通路元件（如加法器、减法器、乘法器、计数器、移位寄存器等）、存储器阵列（RAM）以及其它较大颗粒度的非门级 FPGA 特殊元件。

## msg（§15.46）

关闭或打开消息显示，也可查询消息显示设置状态。

**语法**

```txt
msg <switch>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| switch | 枚举（on\|off\|stat） | 无 | off=关闭消息显示；on=打开消息显示；stat=查询当前消息显示设置（on 还是 off） |

**示例**

```txt
msg off
```

关闭消息显示。

```txt
msg stat
```

查询当前消息显示设置（on 还是 off）。
