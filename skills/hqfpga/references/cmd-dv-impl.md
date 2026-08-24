<!-- 来源：docs/user_manual/hqfpga_um_chs.md §15.16–15.27（第 1670–2347 行），命令类：dv.*、edif.*、help、impl.decomp、impl.guide.*、impl.legalize、impl.map -->
<!-- 注：本行范围内的 §15.28 impl.pack、§15.29 impl.place 未在指定命令清单内，故不蒸馏。 -->

# 命令参考（七）：dv.* / edif.* / help / impl 实现命令

> 交互式命令环境，提示符形如 `[>`（见 dv.info 示例）。命令名大小写不敏感。

## dv.info

查询当前目标器件的信息。

**语法**

```txt
dv.info <what> [-orgdev]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| what | 枚举 `name\|vendor\|family\|die\|package\|speedgrade\|condition` | `name` | 要获取的目标器件信息项 |
| orgdev | 开关 | 无 | 未知用途（原文仅有语法、无说明） |

`what` 各取值含义：

- `name` — 目标器件名称
- `vendor` — 目标器件厂商（枚举中存在该值，但原文未给出说明）
- `family` — 目标器件所属的器件族
- `die` — 目标器件的芯核(die)名称
- `package` — 目标器件的封装名称
- `speedgrade` — 目标器件的速度级
- `condition` — 目标器件的适用环境信息

**示例**

```txt
[> dv.setup sealion sl2-7v-6f256
...
[> dv.info name
SL2-7V-6F256
[> dv.info die
SL2-7V
[> dv.info package
F256
[> dv.info speedgrade
6
```

## dv.query

查询所支持的目标器件信息。

**语法**

```txt
dv.query [<family>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| family | 字符串 | 无 | 器件族名称；未给出则列出所有支持的器件族；为 `all` 则列出所有支持的器件；大小写无关 |

**行为说明**

- 未给 `family`：列出所有支持的器件族名称，格式为 `{<厂商名称> <器件族列表>}`。例：`{XIST "SEALION"}`。
- 指定 `family`：列出该器件族中支持的所有器件，格式为 `{<器件型号> <封装列表> <速度级列表> <环境列表>}`。例：

```txt
{"XIST.SEALION" "SL2-12V" "F256" "6 7 8" "C I"}
{"XIST.SEALION" "SL2-7V" "F256" "6" "C I"}
```

  （其中 C 代表商用环境，I 代表工业环境。）
- 参数为 `all`：列出所有支持的器件，格式为 `{<厂商名>.<器件族> <器件型号> <封装列表> <速度级列表> <环境列表>}`。
- 参数大小写无关，如 `SEALION` 与 `sealion` 等价。

**示例**

```txt
dv.query sealion
dv.query xist.sealion
```

上面两例作用相同：列出 SEALION 器件族中支持的所有器件信息。

```txt
dv.query
```

列出所有支持的厂商及器件族信息。

## dv.setup

设定目标器件。

**语法**

```txt
dv.setup <family> [<dev>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| family | 字符串 | 无 | 目标器件族(device family)，大小写无关 |
| dev | 字符串 | 无 | 具体目标器件，格式遵从厂商数据手册；必须属于 `family` 指定的器件族；若未给出，程序按设计大小自动选择目标器件 |

**示例**

```txt
dv.setup sealion sl2-12v-6f256
```

指定 SEALION 器件族的 SL2-12V-6F256 器件为目标器件。

## edif.read

读入 EDIF 网表文件。

**语法**

```txt
edif.read <filename> [-family <family_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| filename | 字符串 | 无 | 要读入的 EDIF 文件名；程序先在当前目录按名称搜寻，不存在则按 `srchpath.config` 指定的目录搜寻 |
| family | 字符串 | 无 | EDIF 网表所基于的器件族；未指定则视为基于 `dv.setup` 设定的器件族，但若此前也未运行 `dv.setup`，本命令将报错 |

**说明**

- 因 EDIF 多为第三方工具针对其它器件产生，一般需指定本参数，以便程序按不同器件对 EDIF 网表进行读取与转换。

**示例**

```txt
edif.read my.edf -family xo2
```

读取名为 `my.edf` 的 EDIF 网表文件，该网表是第三方综合工具基于 Lattice XO2 器件产生的。

## edif.write

输出 EDIF 网表文件。

**语法**

```txt
edif.write <filename> [-family <family_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| filename | 字符串 | 无 | 要输出的 EDIF 文件名 |
| family | 字符串 | 无 | 输出网表所基于的器件族；未指定则基于当前目标器件族 |

**示例**

```txt
edif.write my.edf
```

输出名为 `my.edf` 的 EDIF 网表文件。

## help

显示在线帮助信息。

**语法**

```txt
help [<cmd>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| cmd | 字符串 | 无 | 要显示帮助的命令名称；为 `all` 则列出程序中所有命令名称；未指定则提示输入 `help <命令名>` 或 `help all` |

**示例**

```txt
help edif.read
```

提示命令 `edif.read` 的帮助信息。

```txt
help all
```

列出程序中所有命令列表。

## impl.decomp

分解(decompose)工艺无关的多输入门。被 `design.map` 调用。

**语法**

```txt
impl.decomp [-max_cut <max_cut>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| max_cut | 整数 | `2` | 分解后门允许的最大输入数，取值为 2–6 |

**示例**

```txt
impl.decomp -max_cut 2
```

将网表中的逻辑门分解成最大为 2 输入的逻辑门。

## impl.guide.query

查询各种设计实现引导(guide)。

**语法**

```txt
impl.guide.query [<object>] [-dont_dup] [-dont_dup_ff] [-dont_merge_ff]
    [-dont_retime] [-dont_touch] [-fanout_limit] [-keep_hier]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| object | 对象引用 | 无 | 要查询引导的对象 |
| dont_dup | 开关 | 无 | 查询"不可复制"的引导 |
| dont_dup_ff | 开关 | 无 | 查询"不可复制寄存器"的引导 |
| dont_merge_ff | 开关 | 无 | 查询"不可合并寄存器"的引导 |
| dont_retime | 开关 | 无 | 查询"不可 retiming"的引导 |
| dont_touch | 开关 | 无 | 查询"不可改变"的引导 |
| keep_hier | 开关 | 无 | 查询"保持设计层次"的引导 |
| fanout_limit | 开关 | 无 | 查询"扇出限制"的引导 |

**示例**

```txt
impl.guide.query -keep_hier
```

查询是否保持整个设计的层次结构。

```txt
impl.guide.query -dont_touch u1/and3
```

查询元件实例 `u1/and3` 是否不可改变。

## impl.guide.set

设置各种设计实现引导(design guides/directives)。

**语法**

```txt
impl.guide.set [<object>] [-dont_dup] [-dont_dup_ff] [-dont_merge_ff]
    [-dont_retime] [-dont_touch] [-fanout_limit <fanout_limit_value>] [-keep_hier]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| object | 对象引用 | 无 | 要设置引导的对象 |
| dont_dup | 开关 | 无 | 设置"不可复制"的引导 |
| dont_dup_ff | 开关 | 无 | 设置"不可复制寄存器"的引导 |
| dont_merge_ff | 开关 | 无 | 设置"不可合并寄存器"的引导 |
| dont_retime | 开关 | 无 | 设置"不可 retiming"的引导 |
| dont_touch | 开关 | 无 | 设置"不可改变"的引导 |
| fanout_limit_value | 整数 | `INT_MAX` | 设置"扇出限制"引导，对象的扇出不能超过该值 |
| keep_hier | 开关 | 无 | 设置"保持设计层次"的引导 |

**示例**

```txt
impl.guide.set -keep_hier
```

保持整个设计的层次结构。

```txt
impl.guide.set -dont_touch u1/and3
```

不可改变元件实例 `u1/and3`。

## impl.guide.unset

取消设置各种设计实现引导(guide)。

**语法**

```txt
impl.guide.unset [<object>] [-dont_dup] [-dont_dup_ff] [-dont_merge_ff]
    [-dont_retime] [-dont_touch] [-fanout_limit] [-keep_hier] [-all]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| object | 对象引用 | 无 | 要取消设置引导的对象 |
| dont_dup | 开关 | 无 | 取消"不可复制"引导 |
| dont_dup_ff | 开关 | 无 | 取消"不可复制寄存器"引导 |
| dont_merge_ff | 开关 | 无 | 取消"不可合并寄存器"引导 |
| dont_retime | 开关 | 无 | 取消"不可 retiming"引导 |
| dont_touch | 开关 | 无 | 取消"不可改变"引导 |
| keep_hier | 开关 | 无 | 取消"保持设计层次"引导 |
| fanout_limit | 开关 | 无 | 取消"扇出限制"引导 |
| all | 开关 | 无 | 取消上述所有引导 |

**示例**

```txt
impl.guide.unset -keep_hier
```

取消设置保持整个设计的层次结构。

```txt
impl.guide.unset -dont_touch u1/and3
```

取消设置不可改变元件实例 `u1/and3`。

## impl.legalize

完成对网表的校正(legalize)。

**语法**

```txt
impl.legalize [-phase <phase_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| phase | 枚举 `map\|place\|route` | `place` | 指定设计阶段；因 FPGA 器件物理资源约束，不同阶段需要的网表校正不同 |

**示例**

```txt
impl.legalize
```

进行布局阶段的网表校正。

## impl.map

完成工艺映射(technology mapping)操作。

**语法**

```txt
impl.map [-max_cut <max_cut>]
    [-mode <mode_value>]
    [-effort <effort_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| max_cut | 整数 | `4` | 映射的 LUT 输入数，取值为 2–6 |
| mode | 枚举 `area\|timing` | `area` | 工艺映射的优化目标 |
| effort | 枚举 `extra\|high\|std\|low` | `std` | 映射强度，越高结果越好但运行时间越长；相邻强度间运行时间约为 2 倍关系（如 high 约 2 倍于 std） |

**说明（工艺映射将工艺无关逻辑网表转换成 LUT 网表）**

- 根据映射器件的体系结构指定 `-max_cut` 的值。
- 要好的定时结果设 `-mode timing`；要好的面积结果设 `-mode area`。
- 未设 `-mode` 但设计有时序约束时，工艺映射以优化时序为目标。
- `mode` 为 `timing` 且无时序约束时，工艺映射优化使关键路径上的 LUT 级数(level)最少。
- 要更好结果用更高的 `-effort`。

**示例**

```txt
impl.map -max_cut 4 -effort high
```

进行高强度映射，映射结果中 LUT 的最大输入数是 4。

<!-- 来源章节: 智多晶 HqFpga 用户手册 §15.28 impl.pack 与 §15.29 impl.place，以及其中关于 design.pack 参数 -ratio/-iob_dff 的说明（源文件第 2244–2371 行，对应 §15.27.2 参数 之后到 §15.30 impl.route 之前） -->

# impl.pack 与 impl.place

本文件蒸馏自用户手册 §15.28、§15.29 两个命令，并收录了其说明部分对 `design.pack` 参数 `-ratio` / `-iob_dff` 的补充说明。

---

## impl.pack

本命令用于完成组装（packing）操作。

组装过程类似一个"装箱"的过程，不同的组装策略会产生不同的效果：有的优化目标为面积最优（SLICE 数最少），有的优化目标为保证时序及布线率（例如尽量不把无关的逻辑放入同一 SLICE 中）。

### 语法

```txt
impl.pack [-area]
[-ratio <ratio_value>]
[-iob_dff <threshold>]
```

### 参数

| 参数 | 类型 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| `-area` | 开关 | 无 | 以面积最小为优化目标。副作用是可能使布线非常困难，导致后续布线不能布通 |
| `-ratio` | 整型 | 无 | 指定资源占用率上限，在此上限前提下以优化时序为目标 |
| `-iob_dff` | 整型 | 25 | 寄存器吸收阈值：当目标器件资源占用率超过该阈值时，将设计中与 IO 相连的寄存器吸收到 IO 中，使布局更紧凑 |

### 说明

HqFpga 缺省的优化策略是在保证时序优化的前提下尽量少占用 FPGA 单元。对于比较大的设计，组装结果的 FPGA 单元数目可能超出器件容量，此时可尝试以下方法解决：

1. 指定 `-area` 参数：以面积最小为优化目标。副作用是可能使布线非常困难、后续布不通，因此需要一种在"面积最优"和"时序最优"之间折衷的机制。
2. 指定 `-ratio <资源利用率>` 参数。例如：直接运行 `design.pack` 时组装结果超出目标器件资源，而用 `-area` 时占用 80% 资源但后续布线无法布通，则可尝试：

   $$\text { design.pack - ratio } 9 0$$

   此时 HqFpga 将在资源占用率不超过 90% 的前提下以优化时序，即可有 10% 的面积"余量"用于时序优化，从而既避免资源溢出、又能保证布线布通。

3. 指定 `-iob_dff <寄存器吸收阈值>` 参数。对于目标器件上资源占用率超过阈值的情况，尝试将设计中与 IO 相连的寄存器吸收到 IO 中，使布局更为紧凑。寄存器吸收阈值默认值为 25；设为 100 则禁止 IO 吸收寄存器；设为 0 则尽可能吸收。

### 示例

```txt
design.pack -ratio 90
```

组装在资源占用率不超过 90% 的前提下以优化时序。

```txt
design.pack -iob_dff 30
```

当 FPGA 资源利用率超过 30% 时，尝试将 DFF 组装到 IO 单元中。

---

## impl.place

本命令用于完成布局（placement）操作。

### 语法

```txt
impl.place [-effort <effort_value>]
```

### 参数

| 参数 | 类型 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| `-effort` | 枚举值（low\|std\|high） | std | 布局优化强度 |

#### 说明

当强度设为"低"时，HqFpga 将忽略用户给定的时序约束；当强度设为"高"时，HqFpga 会使用更长的运行时间以求得更好的性能。若用户没有给定时序约束，HqFpga 将自动把时序优化强度调整为"低"。

### 示例

```txt
impl.place -effort high
```

以最高优化强度进行布局。
