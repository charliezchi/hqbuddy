<!-- 来源：hqfpga_um_chs.md 第 3367–4087 行，对应 HqFpga 用户手册 §15.60–§15.75（nvlg.read、outdir.set、phycst.* 系列、phyrule.* 系列） -->

# HqFpga 命令参考（§15.60–15.75）：网表读入 / 输出目录 / 物理约束与物理规则

> 本部分命令用于：读入网表型 Verilog（§15.60）、设置输出目录（§15.61）、自动及手动设置物理约束（§15.62–15.73）、查询与设置物理规则（§15.74–15.75）。
> 除 §15.72 phycst.start 特别说明外，多数 `phycst.*` 命令须在 `phycst.start`/`phycst.end` 之间使用（详见 phycst.start 一节）。

---

## 15.60 nvlg.read

读入网表型 Verilog 文件。

**语法**

```txt
nvlg.read <filename> [-family <family_value>]
    [-tolib <tolib_value>] [-top <top_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| filename | 字符串 | 无 | 要读入的网表型 Verilog 文件名。程序先在当前目录按名称搜寻，若不存在，则根据 `srchpath.config` 指定的目录下按名称搜寻。 |
| family | 字符串 | 无 | 网表型 Verilog 文件所基于的器件族。若未指定，程序认为基于 `dv.setup` 所设定的器件族；若此前既未指定本参数、也未运行 `dv.setup` 设定目标器件，则本命令报错。 |
| tolib | 对象引用 | 无 | 将网表读入指定库中；未指定时读入 `/work` 库。 |
| top | 字符串 | 无 | 指定顶层模块名。当文件中含有多个未被例化的 module 时，用本参数指定其一为顶层；否则第一个这样的 module 自动成为顶层。 |

**示例**

```txt
nvlg.read a.v -lib /mylib
# 读入 a.v，结果存于 /mylib 库中

nvlg.read multi_add.v -top add18
# 读取 multi_add.v，并将其中名为 add18 的 module 设为顶层模块
```

> 疑点：示例用 `-lib`，而语法/参数表用 `-tolib`（原文如此）。

---

## 15.61 outdir.set

设置输出文件目录。缺省情况下 HqFpga 的输出文件（网表、报告等）产生在当前目录，本命令可将其输出到指定目录。

**语法**

```txt
outdir.set [<dir>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| dir | 字符串 | 无 | 指定新的输出文件目录。 |

**示例**

```txt
outdir.set /tmp    # 将输出目录设为 /tmp
```

---

## 15.62 phycst.ddr

启动/关闭 DDR 端口相关的自动物理约束设置（用于合封 DDR 内存颗粒的器件）。

**语法**

```txt
phycst.ddr <val>
[-seperated] [-external] [-internal] [-ratio <ratio_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| val | 枚举(on\|off) | 无 | 启动/关闭 DDR 端口相关的自动物理约束设置。 |
| seperated | 开关 | 无 | 用于合封 DDR 内存颗粒与 FPGA 各自单独设置参考电平。 |
| external | 开关 | 无 | 设置外部方式的参考电平模式。 |
| internal | 开关 | 无 | 设置内部方式的参考电平模式。 |
| ratio | 枚举(I45\|I50\|I55) | 无 | 内部参考电平模式下选择 VCCIO 的百分比。仅当设置了 `-internal` 后才有效。 |

**示例**

```txt
phycst.ddr on -external
# 自动设置合封 DDR2-SDRAM 器件的物理约束，并将参考电平模式设为外部模式
```

**备注**

本命令自动设置的约束，如用户需要自行设置并覆盖，可给相关约束增加 `-force` 参数，例如：

```txt
phycst.pin.set ... -force
```

---

## 15.63 phycst.end

结束物理约束分析器。详见 §15.72 `phycst.start` 命令说明（与 `phycst.start` 配对使用）。

---

## 15.64 phycst.extvref.set

设置外部参考电压信息（指定外部参考电压源引脚及其电压值）。

**语法**

```txt
phycst.extvref.set <loc> <vccio>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| loc | 字符串 | 无 | 作为外部参考电压源的引脚位置。 |
| vccio | 枚举(0.9V\|1.2V\|1.5V\|1.8V\|2.5V\|3.3V\|5V) | 无 | 外部参考电压值。 |

**示例**

```txt
phycst.extvref.set 214 1.8V
phycst.pin.set porta 211 -attr {IO_TYPE=SSTL18_I VREF=EXTERN}
# 设置封装引脚 214 为外部参考电压源，BANK VCCIO 为 1.8V；并将同 BANK 中与端口 porta 绑定的引脚 211 的参考电压源设为外部
```

---

## 15.65 phycst.loc.check

检测元件实例位置是否有效。有效返回字符串 `"1"`，无效返回 `"0"`。

**语法**

```txt
phycst.loc.check <loc>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| loc | 字符串 | 无 | 待检验的元件实例位置。 |

**示例**

```txt
phycst.loc.check EBR_R24C29
# EBR_R24C29 是 Sealion 25K 器件的合法位置，返回 "1"；对其它器件返回 "0"
```

---

## 15.66 phycst.loc.set

设置元件实例(instance)的位置。

**语法**

```txt
phycst.loc.set <instance> <location> [-soft]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| instance | 字符串 | 无 | 元件实例的名称。 |
| location | 字符串 | 无 | 目标位置，一般格式见下。 |
| soft | 开关 | 无 | 说明必要时该约束可被忽略。 |

**位置格式（location）**

```json
[ [type] _ ] RmCn [ltype] [. [sub_elem]]
```

- `type` 代表资源类型：
  - `MULT18`/`MULT9`/`ALU24`/`ALU9` – DSP 资源（Seal/Sealion 器件）
  - `EBR` – 块存储器资源（Seal/Sealion 器件）
  - 为空时表示逻辑（SLICE/PLB）资源
- `ltype` 代表逻辑资源类型：
  - Seal 器件：`L` – 纯逻辑类型 slice；`M` – 分布式 RAM 型 slice
  - Sealion 器件：`A`/`B`/`C`/`D` – 分别代表所在位置 PLB 的四个 SLICE
- `sub_elem` 代表逻辑资源子元素：
  - Seal 器件：`LUT[A|B|C|D]`、`REG[A|B|C|D]`
  - Sealion 器件：`LUT[0|1]`、`REG[0|1]`
- `m` 和 `n` 分别代表行号和列号，整数值类型。

**示例**

```txt
phycst.loc.set myff1 R2C15L
# 指派(触发器)实例 myff1 到 (Seal) 器件的 R2C15L 位置

phycst.loc.set mymult MULT18_R16C29
# 指派(乘法器)实例 mymult 到目标器件的 MULT18_R16C29 位置

phycst.loc.set {lut_a} R2C2A.LUT0
phycst.loc.set {reg_a} R2C2A.REG0
phycst.loc.set {lut_b} R2C2A.LUT1
phycst.loc.set {reg_b} R2C2A.REG1
# 将 4 个元件实例放到 (Sealion 器件) 同一个位置的 SLICE 中
```

> 注意：带 sub_elem 的约束若与器件物理连接（如进位链资源或宽输入 MUX 资源）相矛盾，软件将忽略这些约束。

---

## 15.67 phycst.net.set

指定全局连线（global net）资源。

智多晶 FPGA 有两种全局连线资源：

- **PCLK** – Primary Clock，主要用于时钟走线，特点是大扇出、低时钟偏斜（high fanout, low skew）。
- **SCLK** – Secondary Clock，主要用于大扇出控制信号（如 RESET）走线。在 Sealion 12K 器件中 SCLK 的 skew 较高，不适合做时钟走线；在 Sealion 其它器件（25K/5K/7K 等）中 SCLK skew 很小，也可用作时钟走线。

资源数量：Sealion 器件共 8 条 PCLK + 8 条 SCLK；Seal 器件只有 PCLK 一种，共 24 条。

本命令用于指定设计中的信号使用或禁用特定的 PCLK/SCLK 资源。

**语法**

```txt
phycst.net.set <net> <type> [-disable] [-index <index_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| net | 字符串 | 无 | 连线名称。 |
| type | 字符串 | 无 | 全局连线资源类型，取值为 `pclk` 或 `sclk`。 |
| disable | 开关 | 无 | 禁用相关的全局连线资源。 |
| index | 整数 | 无 | 全局连线资源编号：Sealion 器件取值范围 0-7；Seal 器件取值范围 0-23。 |

**示例**

```txt
phycst.net.set myclk pclk
# 将连线 myclk 分配到 PCLK 资源上

phycst.net.set gRst sclk
# 将连线 gRst 分配到 SCLK 资源上

phycst.net.set VCC sclk -disable
# 禁止软件将连线 VCC 分配到 SCLK 资源上

phycst.net.set clk166Mhz pclk -index 1
# 将连线 clk166Mhz 分配到编号为 1 的 PCLK 资源上
```

---

## 15.68 phycst.pin.set

指派设计中顶层 IO 端口的封装引脚位置及属性。

**语法**

```txt
phycst.pin.set <pin> <location>
[-attr <attr_value>] [-force]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| pin | 字符串 | 无 | 顶层端口名。 |
| location | 字符串 | 无 | 引脚的位置。 |
| attr_value | 字符串 | 无 | 引脚属性，格式为 `属性名称=属性值` 的列表，主要属性见下表。 |

**主要属性表（attr_value）**

| 属性 | 属性值 | 说明 |
|------|--------|------|
| IO_TYPE | LVCMOS25, LVDS25, SSTL18_I 等 | 设置端口的 IO 电平标准。 |
| PULLMODE | UP, DOWN, NONE, KEEPER 等 | 设置端口的上拉模式。 |
| SLEWRATE | FAST, SLOW | 对输出及双向端口设置压摆率控制。不适用于真差分输出。 |
| DRIVE | 2,4,6,8,10,12,16,24 | 对输出及双向端口设置驱动强度。缺省值与 IO_TYPE 相关。 |
| CLAMP | OFF, ON | 设置钳位控制。 |
| HYSTERESIS | SMALL, LARGE | 对 LVTTL/LVCMOS 标准的输入/双向端口设置迟滞控制。 |
| DIFFRESISTOR | OFF, 100 | 对差分输入端口设置片上终止电阻值（on-chip termination resistor）。 |
| DIFFDRIVE | 1.25, 2.0, 2.5, 3.5 | 真 LVDS 差分输出端口设置驱动强度。 |
| OPENDRAIN | OFF, ON | 对 LVTTL/LVCMOS 标准的输出/双向端口设置漏极开路。 |
| BANK_VCCIO | 3.3, 2.5, 1.8, 1.5, 1.2 | 设置 bank 的 IO 电压。 |
| VREF | OFF, I45, I50, I55, EXTERN | 对单端 SSTL/HSTL 输入及参考 LVCMOS 输入端口设置参考电压。 |

> 注：上表仅为典型属性、属性值及典型用法，更详细说明需参考目标器件数据手册或应用手册。

**示例**

```txt
phycst.pin.set data_in A10
# 将顶层端口 data_in 放置到封装 A10 位置

phycst.pin.set data_out K7 -attr{IO_TYPE=LVCMOS33 SLEWRATE=FAST}
# 将顶层端口 data_out 放置到封装 K7 位置并设定 IO 属性

phycst.pin.set video_data_out_p C5 -attr {IO_TYPE=LVDS25 BANK_VCCIO=3.3}
# 将端口放置到封装 C5 位置，在 3.3V BANK 中使用 LVDS25 差分输出

phycst.pin.set porta 211 -attr {IO_TYPE=SSTL18_I VREF=EXTERN}
# 将顶层端口 porta 放置到封装 211 位置，设置其参考电压来自外部（同 BANK 中的 214）管脚
```

> 疑点：本示例段中混入了一条与 phycst.pin.set 无关、应属 §15.69 的内容：`phycst.extvref.set porta 211 1.8V` 以及 `phycst.region.check {R33C33 R33C33}`（"这是 Sealion 器件一个合法的矩形区域定义，返回字符串 1"），系原文格式碎裂/串节（原文如此）。

---

## 15.69 phycst.region.check

检查一个矩形区域是否有效。有效返回字符串 `"1"`，无效返回 `"0"`。

**语法**

```txt
phycst.region.check <rect>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| rect | 字符串 | 无 | 以 `{ll_loc ur_loc}` 形式定义矩形区域，ll 表示左下、ur 表示右上。ll_loc 与 ur_loc 的格式与 phycst.loc.set 中 `location` 参数相同。 |

> 疑点：本节正文为空（标题 `## 15.69.3 示例` 后无内容，直接进入 §15.70），其示例内容被误放在 §15.68 的示例段中（原文如此）。

---

## 15.70 phycst.region.create

创建矩形区域（组）。

**语法**

```txt
phycst.region.create <name> <rect>
    [-type <region_type>] [-add]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| name | 字符串 | 无 | 指定区域名。 |
| rect | — | — | 以 `{ul lr}` 形式定义矩形区域，ul 表示左上、lr 表示右下；格式与 phycst.loc.set 的 `location` 相同。 |
| type | 枚举(inclusive\|exclusive\|empty) | inclusive | 指定区域类型，见下。 |
| add | 开关 | — | 见下说明。 |

**区域类型（type）**

- `inclusive`：用户和布局器都可将实例放入该区域。
- `exclusive`：仅用户可将实例放入该区域。
- `empty`：用户和布局器都不可将实例放入该区域。
- 缺省为 `inclusive`。

**`-add` 说明**

若本次定义的区域与先前定义的区域同名：
- 指定 `-add` 时，本次区域与之前的同名区域构成一个区域组，且本次的 `type` 参数被忽略（区域组类型与之前定义的区域相同）；
- 否则（未指定 `-add`），本次定义的区域将覆盖之前的同名区域。

**示例**

```txt
phycst.region.create region {R25C28 R37C34}
# 创建左上角 R25C28、右下角 R37C34 的区域，类型 inclusive

phycst.region.create region {R25C35 R37C39} -type exclusive
# 创建一个布局器不能将实例放入其中的区域

phycst.region.create my_region {R15C4 R37C27}
phycst.region.create my_region {R17C1 R23C48} -add
phycst.region.create my_region {EBR_R24C29 EBR_R24C47} -add
# 创建一个名为 my_region 的区域组：
# - 若将 LUT/FF 实例指派到该区域组，可放置于 {R15C4 R37C27} 或 {R17C1 R23C48} 中；
#   EBR 区域 {EBR_R24C29 EBR_R24C47} 用于限制 RamBlock 实例，会被忽略。
# - 若将层次模块指派到该区域组，模块中所有 LUT/FF 实例放在逻辑区域中，
#   Block RAM 实例放在 EBR 区域中。
```

> 疑点：
> 1. 示例段中文字写到 "区域{RAMB4_R3C0 RAMB4_R4C0} 将被忽略"，但上面实际创建的是 `{EBR_R24C29 EBR_R24C47}`，二者不符（原文如此）。
> 2. "模块中的所有 LUT/FF 实例将被放置在 {R17C1 R23C48}或{R17C1 R23C48}之中" —— 两处区域名相同，疑似应为 {R15C4 R37C27}或{R17C1 R23C48}（原文如此）。

---

## 15.71 phycst.region.set

指派实例或互连线到一个区域。

**语法**

```txt
phycst.region.set <inst_net_list> <region_name> [-net]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| inst_net_list | 字符串 | 无 | 元件实例或连线名称，名称中可使用通配符。指派连线表示指派该互连线相连的所有元件实例。 |
| region_name | 字符串 | 无 | 区域名。该区域应已用 `phycst.region.create` 创建。 |
| net | 开关 | 无 | 指定本参数时，inst_net_list 是连线名称；否则是元件实例名称。 |

**示例**

```txt
phycst.region.set {myreg* myadd*} my_region1
# 指派名字以 myreg 或 myadd 开头的实例到 my_region1 区域

phycst.region.set {myreg_net*} my_region1 -net
# 指派名字以 myreg_net 开头的互连线到 my_region1 区域
```

---

## 15.72 phycst.start

启动物理约束分析器。必须与 `phycst.end` 配对出现。

除 `phycst.instloc.check`、`phycst.rgnrect.check` 和 `phycst.pinloclist.get` 可直接调用外，其它物理约束命令须以 `phycst.start` 开始、以 `phycst.end` 结束。

**语法**

```txt
phycst.start
```

**参数**

无。

**示例**

```txt
phycst.start
phycst.pin.set wb_we_i Y2
phycst.pin.set sdata_pad_i A13
phycst.loc.set slice42 CLB_R7C7.S0
phycst.end
# 多条物理约束命令被 phycst.start 和 phycst.end 包围
```

---

## 15.73 phycst.vccio.set

设置 IO Bank 的电压。

**语法**

```txt
phycst.vccio.set <bank> <vccio>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| bank | 字符串 | 无 | 要设置电压的 IO bank 名称。 |
| vccio | 枚举值 | 无 | 要设置的电压值，取值为 `0.9|0.9V|1.2|1.2V|1.35|1.35V|1.5|1.5V|1.8|1.8V|2.5|2.5V|3.3|3.3V|5.0|5.0V`。 |

**说明**

本命令对指定的 IO Bank 设置 IO 电压。

**示例**

```txt
phycst.vccio.set 7 1.2V
# 将 BANK 7 的电压设置为 1.2 伏
```

> 疑点：本节中 `## 15.73.3 说明` 标题前混入了一行独立文本 `■ phyrule.query`，系原文格式碎裂（原文如此）。

---

## 15.74 phyrule.query

查询当前的物理规则设置。

**语法**

```txt
phyrule.query <what>
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| what | 枚举(rtfo\|chk_clkio\|bgen_padloc\|all) | all | 见下。 |

各取值说明：

- `rtfo`：查询当前布线开关限制是否开启。
- `chk_clkio`：查询当前差分时钟检查是否开启。
- `bgen_padloc`：查询位流生成时是否检查用户管脚约束缺失。
- `all`：查询上述所有设置。

> 上述取值的意义可进一步参见 `phyrule.set` 命令说明。

**示例**

```txt
phyrule.query
# 查询所有物理规则限制，可能输出：-rtfo off -chk_clkio on -bgen_padloc off

phyrule.query chk_clkio
# 查询差分时钟检查是否开启，返回值为 on 或 off
```

> 疑点：原文正文写 "参见第 15.74 节 phyrule.set 命令说明"，但 phyrule.set 实为 §15.75，交叉引用编号有误（原文如此）。

---

## 15.75 phyrule.set

设置物理规则。

**语法**

```txt
phyrule.set
[-chk_clkio <chk_clkio_value>]
[-bgen_padloc <bgen_padloc_value>]
[-rtfo <rtfo_value>]
```

**参数**

| 参数 | 类型 | 缺省值 | 说明 |
|------|------|--------|------|
| chk_clkio | 枚举(on\|off) | 根据器件不同 | 是否进行差分 Clock IO 检查。值为 on 时执行相关检查，包括但不限于：P 端是单端时钟输入时，N 端禁止当普通 IO 使用；N 端是单端时钟时禁止使用。具体限制与器件型号相关，可参阅相关器件数据手册或用户说明。 |
| bgen_padloc | 枚举(on\|off) | 根据器件不同 | 是否在位流生成时检查用户管脚约束。值为 on 时，若某顶层端口没有绑定外部管脚（而是软件自动分配的管脚），则比特流生成报错。 |
| rtfo | 枚举(on\|off) | 根据器件不同 | 是否开启布线开关扇出数与级联数限制。 |

**示例**

```txt
phyrule.set -rtfo on
# 强制开启布线开关扇出数与级联数限制

phyrule.set -bgen_padloc off
# 在位流生成时对用户管脚约束缺失进行检查（见下疑点）
```

> 疑点：`-bgen_padloc off` 示例配的说明是"强制在位流生成时对用户管脚约束缺失进行检查"，但值为 `off` 时按参数表应为不检查，示例值与说明矛盾（原文如此）。
