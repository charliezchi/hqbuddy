<!-- 来源：docs/user_manual/hqfpga_um_chs.md 第 606–1180 行，§12 高级用户指南
     覆盖：UDM 数据模型、UDM 操控命令、Xdata 操控、cross-probe、SDC 风格对象访问 -->

# §12 高级用户指南（UDM 数据模型与操控命令）

本章涉及 HqFpga 深层技术细节与高级功能。核心是实现/优化模块（综合、工艺映射、布局布线等）都工作在单一数据模型 **UDM（Unified Data Model）** 上。HqFpga 提供专用 **U 命令**（基于 TCL）直接操控 UDM。

单一数据模型优点：

- 集中统一进行常用数据操作（如网表展平、保持设计层次），避免各模块重复实现。
- 不同模块间可更好地进行时序相关（timing correlation），保持时序一致性。
- 最大程度降低模块间接口复杂性，提高系统效率。

---

## 12.1 UDM 对象模型

UDM 对象层次（图 173）：Design → Library → Cell → View（含 Nview/Lview/Psview）→ Instance/Pin/Net 等。

### 所有对象的共性

- 每个对象有**对象名**用于网表查找；HqFpga 内部用哈希表建立“对象名 → 对象(指针)”映射，实现快速查找。
- 每个对象有唯一 **ID** 用于与其它对象相区别。
- 每个对象可包含与之关联的辅助数据（**Xdata**）。
- 除最顶层设计对象外，每个对象都有一个**属主（owner）**对象。
- 销毁一个对象时，其拥有的所有子对象也一并销毁。

### Xdata 的含义

Xdata 代表辅助（auxiliary）数据，对应：

- EDIF 中的 `property`
- Verilog 中的 `parameter` 或 `attribute`
- VHDL 中的 `generic`

### 对象类型逐一说明

| 对象 | 说明 |
|---|---|
| **Design（设计）** | 包含设计的一切信息，是其它所有对象的最终属主；全局只有一个，以单件(singleton)形式存在。直接包含多个 Library，并至少包含一个当前工作库 "work"。 |
| **Library（库）** | 逻辑/物理库，对应 VHDL 或 EDIF 中的库概念。由多个库单元组成，如 ASIC 标准单元、FPGA 基本逻辑元件（BLE）或用户自定义模块。缺省情况下新建库单元保存在 "work" 库，也可指定专门库作为 "work" 库。除用户库外还有预定义系统库，如与工艺无关的基本元件库 "U_PRIM"、FPGA 器件库等。（原文此处 "HqFpg" 疑为 "HqFpga" 之误） |
| **Cell（单元）** | 对应 Verilog 的 module declaration 或 VHDL 的 entity，定义设计实体对外接口。含若干 Port 对象。 |
| **Port（端口）** | 定义单元对外接口，有方向：`input`（外部信号流入单元）、`output`（信号流出单元）、`inout`（双向）。预定义库单元端口还含特定类型表示作用：时钟、数据或特殊控制（置位、复位、使能等）。 |
| **View（视图）** | 单元的一种实现形式，一个单元可含多个视图（如加法器的串行进位/超前进位实现）。类型：Bview/View（基础视图）、Nview（网表视图）、Lview（逻辑视图）、Psview（物理结构视图）。【注】后文如无特殊说明，View 即代表基础视图。 |
| **Nview（网表视图）** | 描述单元的结构化实现信息，即内部网表。用于描述用户模块或较复杂单元（如 ALU）。特殊视图"顶层视图(top view)"对应设计的顶层模块，**顶层视图一定是网表视图**。 |
| **Lview（逻辑视图）** | 描述简单逻辑单元（如与或非门），以覆盖表（cover table）表示逻辑功能。 |
| **Psview（物理结构视图）** | 描述 FPGA 硬件结构/层次（如 LAB→LC→LUT/触发器），由器件固有，非用户描述。HqFpga 实现过程可看作将 Nview（用户网表）在 Psview（物理网表）上实现/映射。 |
| **Instance（元件实例）** | 对视图（View）实例化产生，该视图称实例的**模板视图(template view)**。其属主必须是**网表视图(Nview)**。例：4 位加法器 myadd4 由 4 个一位全加器 FADD4 实例 a1~a4 搭成，a1 的模板视图为 FADD4 的视图（通常为 Lview），属主视图为 myadd4 的 Nview。 |
| **Pin（引脚）** | 端口的实例对象，两种：(1) 元件引脚，属主为元件实例，创建实例时按模板视图属主单元上的端口自动例化产生；(2) 主引脚(Primary pin)，属主为网表视图，创建 Nview 时按其属主单元上的端口自动实例化产生。 |
| **Net（连线）** | 引脚的集合，表示引脚间的连接关系。注意：**连线不是引脚的属主**（引脚属主是实例或网表视图）。因此销毁连线只去除引脚间连接关系，不会销毁引脚本身。 |

---

## 12.2 UDM 操控命令

一组 U 命令（基于 TCL）操控 UDM 对象，可访问/修改对象。所有命令都接受两种对象引用方式：**名称引用**和 **ID 引用**。

### 12.2.1 对象引用

#### 名称引用

特殊分隔符 / 限定符：

| 符号 | 含义 |
|---|---|
| `/` | 层次分隔符；单独使用时表示 Design 对象 |
| `.` | 表示引脚或端口 |
| `n'` | 连线的限定符 |
| `i'` | 元件实例的限定符 |
| `~` | 代表顶层视图（top view） |

对象命名规则（表 3，原文表格部分碎裂，按下文规则合理还原）：

| UDM 对象 | 名称引用格式 | 说明 |
|---|---|---|
| 设计 Design | `/` | — |
| 库 Library | `/lib` | 例：`/mylib` |
| 单元 Cell | `/lib/cell` | 例：`/mylib/ADDER4` |
| 端口 Port | `/lib/cell.port` | `.` 表示随后为端口名。例：`/mylib/ADDER4.A0` |
| 视图 View | `/lib/cell/view`；或 `/lib/cell//`；或 `~` | 多数情况 cell 只有一个 view，可省略 view 名称，用两个连续斜线代替；`~` 代表顶层视图。例：`/mylib/ADDER4/CarryImpl` |
| 主引脚 PrimaryPin | `/lib/cell/view.pin`、`~.pin`、`.pin` 等 | 例：`/mylib/ADDER4/CarryImpl.A0.clk`（顶层视图的 clk 引脚） |
| 元件 Instance | `/lib/cell/view/instance` 或 `/lib/cell/view/i'instance` | `i` 表示随后为元件实例名 |
| | `~/instance` 或 `instance` | `instance` 是 `~/instance` 的短格式，即顶层视图中的实例。若对象层次名(hname)不以 `/` 开头，则等价于 `~/hname`，即路径相对顶层视图 |
| | `.../inst1/inst2/...` | 若 inst1 是 Nview 的实例，则该 Nview 中的另一实例 inst2 可写作 `inst1/inst2`。例：`/mylib/ADDER4/CarryImpl/fulladder_i1/xor_i` |
| 元件引脚 Instance pin | `instance_ref.pin` | `instance_ref` 可为上面 Instance 命名的任何形式。例：`/mylib/ADDER4/CarryImpl/fulladder_i1/xor_i.Y` |
| 连线 Net | `/lib/cell/view/net` 或 `/lib/cell/view/n'net` | `n` 表示随后为连线名。若网表中有连线与实例同名，引用连线必须加 `n` 限定符，否则按同名 HqFpga 返回实例对象 |
| | `~/net`、`net`、`n'net` | 引用顶层设计视图中的连线 |
| | `instance_ref/net` | `instance_ref` 可为上面 Instance 任何形式；所引用实例的模板视图必须是 Nview，且该 Nview 含名为 `net` 的连线 |

**含特殊分隔符的名称**：若对象名称本身含 `/`、`.`、`~`、`'` 等特殊符，应用大括号 `{}` 括起。例如展平网表中引用名为 "level1/level2/leaf_1" 的实例，若直接运行 `obj.get level1/level2/leaf_1` 会得到空值（HqFpga 将 `/` 视为层次分隔符干扰查找）。应改用：

```txt
obj.get "{level1/level2/leaf_1}"
```

或：

```txt
obj.get \{level1/level2/leaf_1\}
```

**注意**：必须用 `引号+大括号` 或 `反斜线+大括号` 方式，不能直接 `obj.get {level1/level2/leaf_1}`，因为它等价于无大括号的写法。这是 TCL 字符串替换规则所致（非 HqFpga 特殊要求），需熟悉 TCL 字符串替换机制。

#### ID 引用

- 名称引用每次查找时间复杂度为线性，效率低；重复处理对象时应改用 ID 引用。
- 对象 ID 即对象在计算机的内存地址，可快速引用。
- 用 `obj.get <obj_hier_name>` 获取对象 ID。

示例：

```tcl
set obj [obj.get /mylib/ADDER4/CarryImpl/fulladder_i1]
set inst_name [obj.info $obj name]
set inst_pin_cnt [obj.inst.info $obj pincnt]
puts "the instance $inst_name has $inst_pin_cnt pins"
```

【注意】使用 ID 引用时，若对象被删除或重新创建，必须相应更新 ID 引用；否则原 ID 指向非法内存位置，使用会造成 HqFpga 程序崩溃。

### 12.2.2 遍历 UDM 对象（obj.foreach）

#### 命令 obj.foreach

用于遍历指定对象的子对象（或相关对象）。

**语法**

```txt
obj.foreach <obj_type> <iter_var> <owner> <script>
```

- `<owner>`：对象的名称或 ID 引用（下文中"对象"与"对象引用"等价）。
- `<obj_type>`：`lib cell view inst nview_inst net pin port`。
- 每个子对象由 `<iter_var>` 变量表示。

**`<obj_type>` 与 `<owner>` 的合法关系**：

| owner 对象类型 | obj_type | 说明 |
|---|---|---|
| Design | lib | 遍历设计中的每个库 |
| Library | cell | 遍历库中的每个单元 |
| Cell | view | 遍历单元的每个视图 |
| Cell | port | 遍历单元的每个端口 |
| View | inst | 遍历视图的每个元件实例 |
| Nview | inst | 遍历 Nview 的每个元件实例 |
| Nview | nview_inst | 遍历 Nview 网表所包含的每个元件实例 |
| Nview | pin | 遍历 Nview 的每个主引脚 |
| Nview | net | 遍历 Nview 网表所包含的每个连线 |
| Instance | pin | 遍历元件实例的每个引脚 |
| Net | pin | 遍历连线的每个引脚 |

**示例**（列出单元所有端口，得到端口 ID 引用）：

```tcl
set mycell [obj.get /mylib/LUT4]
obj.foreach port p $mycell {
    puts $p
}
```

输出示例（ID 引用，不够友好）：

```txt
@@1575018
@@1229450
@@1226818
@@122FFB0
...
```

用 `obj.info` 返回名称、类型：

```tcl
set mycell [obj.get /mylib/LUT4]
obj.foreach port p $mycell {
    puts "name=[obj.info $p name] type=[obj.info $p type]"
}
```

输出：

```txt
name=I0 type=port
name=I1 type=port
name=I2 type=port
name=I3 type=port
name=O type=port
```

#### obj*.info 命令家族

`obj.info` 仅输出各种类型对象通用的信息；HqFpga 还提供与特定对象相关的命令返回该类型对象的特定信息：

```txt
obj.lib.info
obj.cell.info
obj.port.info
obj.view.info
obj.lview.info
obj.inst.info
obj.net.info
obj.pin.info
```

所有 `obj*.info` 命令格式统一：

```txt
obj*.info <obj> <type>
```

表示查询对象 `<obj>` 的 `<type>` 类型信息。以下逐一列出可用的 `<type>` 及返回值。

##### obj.info – 对象通用信息

| type | 返回信息 |
|---|---|
| name | 对象名 |
| hiername | 对象的层次名（名称引用） |
| type | 对象类型：`lib,cell,view,port,pin,net` |
| owner | 对象的属主对象（ID 引用） |
| all（缺省值） | 上述所有信息（以列表方式返回） |

##### obj.lib.info – 库对象专用信息

| type | 返回信息 |
|---|---|
| type | 库类型：`syslib` 系统库 / `usrlib` 用户库 |
| cellcnt | 库中单元个数 |
| all（缺省值） | 上述所有信息（列表返回） |

##### obj.cell.info – 单元对象专用信息

| type | 返回信息 |
|---|---|
| type | 单元类型：`zero` 常量0(GND)、`one` 常量1(VCC)、`dff` D触发器、`tff` T触发器、`jkff` JK触发器、`latch` 锁存器、`tribuf` 三态缓冲器、`buf` 缓冲器、`inv` 反相器、`mux2` 二选一多路选择器、`comblogic` 组合逻辑、`lut` 查找表(LUT)、`block` 块元件如BLE(LUT+FF)、`io` IO单元、`bram` 块存储器(Block RAM)、`dram` 分布式存储器(distributed RAM)、`vendor` FPGA厂商的库单元、`undefined` 未定义类型单元 |
| portcnt | 单元端口个数 |
| viewcnt | 单元视图个数 |
| all（缺省值） | 上述所有信息（列表返回） |

##### obj.port.info – 端口对象专用信息

| type | 参数值 | 返回信息 |
|---|---|---|
| direction | — | 端口方向：`in`、`out` 或 `inout` |
| type | — | 端口类型：`data` 数据、`pad` 外部焊盘、`clk` 时钟、`ce` 时钟使能、`oe` (三态缓冲器)输出使能、`cin` 进位输入、`cout` 进位输出、`casin` 级联输入、`casout` 级联输出、`aset` 异步置位、`sset` 同步置位、`aclr` 异步复位、`sclr` 同步复位、`aload` 异步加载、`sload` 同步加载、`actrl` 异步控制(aset、aclr、aload)、`sctrl` 同步控制(sset、sclr、sload)、`we` (RAM)写使能、`re` (RAM)读使能、`qout` 寄存器输出、`if` 多路选择器选择端、`then` 选择端值为1时所选数据端口、`else` 选择端值为0时所选数据端口 |
| vec | — | 数组端口信息：若端口为数组端口中的一位，返回格式如 "703"（数组端口定义 [7:0]，本端口下标为3）；一位端口返回空串。（原文该参数说明格式碎裂，已按上下文还原） |
| all（缺省值） | — | 上述所有信息（列表返回） |

##### obj.view.info – 视图对象专用信息

| type | 返回信息 |
|---|---|
| type | 视图类型：`bview` 基础视图、`lview` 逻辑视图、`nview` 网表视图、`psview` 物理结构视图 |
| hasinst | 视图是否含元件实例：`0` 无 / `1` 有 |
| instancnt | 视图元件实例个数。**注意：本操作时间复杂度为线性** |
| all（缺省值） | 上述所有信息（列表返回） |

##### obj.inst.info – 元件实例对象专用信息

| type | 返回信息 |
|---|---|
| type | 元件实例类型，同 `obj.cell.info` 的返回值 |
| pincnt | 元件实例引脚个数 |
| incnt | 输入引脚个数 |
| outcnt | 输出引脚个数 |
| inoutcnt | 双向引脚个数 |
| view | 元件实例的模板视图对象（ID 引用） |
| all（缺省值） | 上述所有信息（列表返回） |

##### obj.pin.info – 引脚对象专用信息

| type | 返回信息 |
|---|---|
| net | 与引脚相连的连线对象（ID 引用） |
| port | 引脚相应的端口对象（ID 引用） |
| direction | 引脚方向：`in`、`out` 或 `inout` |
| type | 引脚类型，同 `obj.port.info` 的返回值 |
| vec | 同 `obj.port.info` 的 vec 参数解释 |
| all（缺省值） | 上述所有信息（列表返回） |

##### obj.net.info – 连线对象专用信息

| type | 返回信息 |
|---|---|
| pincnt | 连线所连接引脚个数 |
| drivercnt | 连线驱动引脚个数 |
| sinkcnt | 连线被驱动引脚个数 |
| driver | 连线驱动引脚对象（ID 引用） |
| all（缺省值） | 上述所有信息（列表返回） |

##### obj.lview.info – 逻辑视图对象专用信息

| type | 返回信息 |
|---|---|
| type | 逻辑类型：`one` 逻辑1、`zero` 逻辑0、`buf` 等于、`inv` 反向、`and` 与、`or` 或、`nand` 与非、`nor` 或非、`xor` 异或、`xnor` 同或、`mux` 2选1、`complex` 复杂逻辑 |
| cover | 以列表方式打印逻辑覆盖表。每项代表一个蕴含项，含输入部分和输出部分；输入部分每字符代表字面量(literal)，取值 `0`、`1` 或 `-`（无关项）；每个输出可为 `0` 或 `1`。例：三输入或门的逻辑视图运行 `obj.lview.info <obj> cover` 返回 "1--1 -1-1 --11"。本参数还可加选项 `-puts` 以用户友好方式输出到管道，例如 `obj.lview.info <obj> cover -puts stdout`，三输入或门输出可能如下：

```txt
I2 I1 I0 0
1 - 0 1
- 1 1 1
```
（原文示例输出行略有碎裂，已按上下文还原，仅供参考）

### 12.2.3 设置单元和端口类型

#### 命令 obj.cell.set / obj.port.set

分别设置单元和端口的类型。

**语法**

```txt
obj.cell.set <obj> <type>
obj.port.set <obj> <type>
```

两个命令中 `<type>` 取值分别与 `obj.cell.info` 及 `obj.port.info` 中 type 参数取值相同。

### 12.2.4 创建或删除元件实例（obj.inst.op）

创建或删除元件实例。

**语法**

```txt
obj.inst.op <op> <inst> [<view>] [<nview>]
```

| 参数 | 说明 |
|---|---|
| op | `create` 或 `delete` |
| inst | 创建时为新建实例名称；删除时为待删除的实例对象 |
| view | 仅 create 时必填：新实例的模板视图 |
| nview | 仅 create 时必填：新实例所属的网表视图 |

**示例**（先在顶层视图创建四输入查找表 LUT4 的实例，再删除）：

```tcl
set tview [obj.get /mylib/LUT4/LUT4]
set newinst [obj.inst.op create "my_muxinst" $tview ~]
...
obj.inst.op delete $newinst
# ( "~" 代表顶层视图 )
```

### 12.2.5 操控连线对象（obj.net.op）

**语法**

```txt
obj.net.op <op> <net> [<context_obj>] [-vec <vec_value>]
```

`<op>` 取值：

| op | 含义 | 参数要求 |
|---|---|---|
| create | 创建连线 | `<net>` 为新连线名称；`<context_obj>` 必须是连线所属的网表视图对象 |
| delete | 删除连线 | `<net>` 指定待删连线对象 |
| connect | 连接引脚 | `<net>` 为连线对象；`<context_obj>` 必须为引脚对象 |
| disconnect | 断开引脚 | `<net>` 为连线对象；`<context_obj>` 必须为引脚对象 |
| merge | 合并连线 | `<net>` 和 `<context_obj>` 必须都是连线对象 |

- create 时 `-vec` 可选：给定则创建连线数组（net vector），格式为 `"<msb> <lsb>"`。
- create 的返回值为新创建的连线对象引用；若给定了 `-vec` 则返回新创建的连线对象列表。

### 12.2.6 根据下标获取引脚对象（obj.pin.get）

从元件实例或网表视图上通过下标获取引脚。

**语法**

```txt
obj.pin.get <owner> <index> [-direction <direction_value>]
```

- `<owner>`：元件实例或网表视图对象。
- `-direction`：`in`、`out`、`inout` 或 `all`，缺省值 `all`；表示要获取指定方向的第几个引脚。

**示例**（通过引脚下标遍历实例所有引脚并断开相连连线）：

```tcl
set pincnt [obj.inst.info $myinst pincnt]
for {set i 0} {$i < $pincnt} {incr i} {
    set pin [obj.pin.get $myinst $i]
    set net [obj.pin.info $pin net]
    if {$net != ""} {
    puts " disconnecting pin [obj.info $pin hiername]
    with net [obj.info $net name]"
    obj.net.op disconnect $net $pin
    }
}
```
（原文示例中 `obj.ino $net name` 疑为 `obj.info $net name` 之误，已修正）

---

## 12.3 Xdata 操控命令

Xdata 即对象关联的辅助数据（见 12.1，对应 EDIF property / Verilog parameter·attribute / VHDL generic）。

### 命令 obj.xdata.list – 列出对象 Xdata 名称

```txt
obj.xdata.list <obj>
```

返回指定对象的所有 Xdata 名称列表。

### 命令 obj.xdata.info – 查询 Xdata 值与类型

```txt
obj.xdata.info <obj> <xdata_name> <info>
```

`<info>` 取值：

| 取值 | 说明 |
|---|---|
| value | 查询名为 `<xdata_name>` 的 Xdata 的值 |
| type | 查询名为 `<xdata_name>` 的 Xdata 的类型 |
| all（缺省值） | 查询该 Xdata 的值和类型 |

**示例**（打印对象所有 Xdata 及其取值）：

```txt
foreach xdname [obj.xdata.list $myobj] {
    puts "xdata $xdname = [obj.xdata.info $myobj $xdname value]"
}
```
（原文示例中 `obj.xdata.info $ xdname value` 缺 `$myobj` 参数，应为此处写法，已还原）

### 命令 obj.xdata.set – 为对象设置 Xdata

```txt
obj.xdata.set <obj> <xdata_name> <xdata_value> <xdata_type>
```

`<xdata_type>` 取值：

| 类型 | 说明 |
|---|---|
| short | 短整型 |
| int | 整型 |
| long | 长整型 |
| float | 浮点型 |
| double | 双精度型 |
| string（缺省值） | 字符串类型 |

### 命令 obj.xdata.delete – 删除对象 Xdata

```txt
obj.xdata.delete <obj> <xdata_name>
```

---

## 12.4 交叉查询 cross-probe（obj.probe）

对通过 HqFpga RTL 综合产生的设计网表，其中的元件实例、连线及端口 UDM 对象都保存有原始 RTL 信息（原始文件名、行、列），用于交叉查询对象与原始 RTL 描述的对应关系。

- 原始 RTL 文件列表信息在综合后保存在 Design 对象上，用如下命令获取所有 RTL 文件名称列表：

```txt
obj.probe / flist
```

（`/` 表示全局唯一的 Design 对象）

- 对其它对象查询原始 RTL 信息：

```txt
obj.probe <obj> <what> [-idx2nm]
```

`<what>` 取值：

| 取值 | 说明 |
|---|---|
| l1 | `<obj>` 在原始 RTL 文件中的起始行 |
| l2 | `<obj>` 在原始 RTL 文件中的终止行 |
| c1 | `<obj>` 在原始 RTL 文件中的起始列 |
| c2 | `<obj>` 在原始 RTL 文件中的终止列 |
| fidx | 产生 `<obj>` 的原始 RTL 文件在所有 RTL 文件名称列表中的下标（列表由 `obj.probe / flist` 产生）；据下标+文件列表可得 RTL 文件名 |
| all（缺省值） | 上述所有信息（列表返回） |

- `-idx2nm`：配合 `fidx`/`all` 使用，直接获取产生 `<obj>` 对象的原始 RTL 文件名称。

**示例**（打印 RTL 综合后所有实例和连线的原始 RTL 信息，参考 myff.v）：

```tcl
# RTL synthesis
design.analyze myff.v
rtl.elaborate
#
# print cross-probing info for instances
obj.foreach nview_inst x ~ {
    set cell [obj.info [obj.inst.info $x view] owner]
    puts "INST [obj.info $x name]([obj.info $cell name])"
    puts " [obj.probe $x all -idx2nm]"
}
#
# print cross-probing info for nets
obj.foreach net x ~ {
    puts "NET [obj.info $x name]"
    puts " [obj.probe $x all -idx2nm]"
}
```

---

## 12.5 SDC 风格的 UDM 对象访问

很多 ASIC/FPGA 设计者习惯 Synopsys 工具（如 DC）的对象命名方式。HqFpga 提供通过 SDC（Synopsys Design Constraint）命令访问 UDM 对象的方式。

**示例**：

```tcl
sdc.start
# Find instances with "sr" level by level in the netlist
set collection1 [get_cells sr* -hierarchical -now]
# Find nets with name matching the specified regular expression
set collection2 [get_nets {.*_ack[^\[]+} -regexp -now]
...
sdc.end
#
# process the found objects
foreach obj $collection1 {
    puts [obj.info $obj all]
}
```

**【重要注意】**
1. SDC 对象访问命令必须以 `sdc.start` 开始、以 `sdc.end` 结束。HqFpga 通过这两个命令进行对象命名规则的切换。
2. 必须在 SDC 对象访问命令之后加特殊参数 `-now` 以即时返回对象列表；否则查找到的对象会存在 HqFpga 内部数据结构中而不暴露给用户。

**SDC 对象与 HqFpga 对象的对应关系**：

| SDC 对象 | HqFpga 对象 |
|---|---|
| Design | Design |
| Library | Library |
| Lib_cell | Cell |
| Lib_pin | Port |
| Port | Primary pin |
| Cell | Instance |
| Net | Net |
| Pin | Pin |

HqFpga 所支持 SDC 对象访问命令的详情见原手册第 14.14.1 节（不在本次蒸馏范围内）。

---

## 附录：实测补充（hqfpga 3.1.1 build FT082926，`info commands` + `help` 实测）

手册 §12 并未列全。在 hqfpga TCL 交互中：

- `info commands obj*` 可列出本 build 实际存在的全部 `obj.*` 命令（共 27 个，手册描述约 20 个）。
- `help <cmd>` 可输出任意命令的 `[Syntax]` / `[Arguments]`（含枚举取值），比手册更权威。

### 手册未记载的命令

| 命令 | 语法（help 实测） | 说明 |
|---|---|---|
| `obj.lib.create` | `obj.lib.create <name>` | 新建用户库 |
| `obj.port.create` | `obj.port.create <obj> <name> <direction>` | 在单元上创建端口，direction ∈ `in\|out\|inout` |
| `obj.lview.set` | `obj.lview.set <view> <type> [-cover <cover_value>]` | 设置逻辑视图功能；type ∈ one/zero/buf/inv/and/or/nand/nor/xor/xnor/mux2/complex，cover 为覆盖表字符串 |
| `obj.nview.info` | `obj.nview.info <obj> <info>` | info ∈ `instcnt\|netcnt\|psview\|all`；psview 返回对应物理视图 |
| `obj.psview.info` | `obj.psview.info <obj> <info>` | info ∈ `nview\|cfgstr\|all`；cfgstr 为物理配置串 |
| `obj.sys.get` | `obj.sys.get <sysobj>` | 获取系统对象引用：`design\|topview\|worklib\|primlib\|archlib\|synlib\|org_archlib\|org_synlib`（免写死 `/`、`~` 等名字） |
| `obj.index.start` / `obj.index.stop` | 无参数 | 开启/关闭对象索引（大批量遍历前开启，疑似加速名称→ID 查找） |
| `obj.flag.list` | `obj.flag.list <obj>` | 列出对象上的内部标志位 |

### 手册有载但取值/参数不全的

- `obj.port.info`：手册漏了 `bubbled`（查询端口是否取反/bubbled-up）。
- `obj.port.set`：额外支持 `-bubbled` 开关。
- `obj.view.info`：手册漏了 `unique_inst`（唯一实例计数）。
- `obj.net.info`：手册漏了 `phynet`（物理网表中的对应连线）。
- `obj.pin.info`：手册漏了 `bubbled`、`delay`。
- `obj.cell.set`：type 除手册所列外还有 `dsp|cmu|ext`。
- `obj.xdata.set`：xdata_type 还支持 `ull`（手册只列到 long）。
- `obj.probe` 的 `<what>`：除 l1/l2/c1/c2/fidx 外还有 `flist`（配 `/` 使用列出 RTL 文件清单，手册在示例中提到但未入表）。



1. **表 3（UDM 对象命名规则，行 757）**：表格多列内容被粘连成单行（如 `/lib/cell/view/lib/cell//~`、`~/instanceinstance`、`~/netnetn'net`、`/lib/cell/view.pin~.pin.pin`、`/lib/cell/view/net/lib/cell/view/n'net`），已按下文的限定符说明与示例逐行拆解还原，还原结果可能与原文本意有细微出入。
2. **行 761**：“用户将得到空的值” 一段在表格之后出现，但对应的是行 753 关于 `level1/level2/leaf_1` 名称含 `/` 的例子；上下文衔接碎裂，已按语义归并到 12.2.1 名称引用小节。
3. **行 1053**：`obj.xdata.info $ xdname value` 缺少对象参数，应为 `obj.xdata.info $myobj $xdname value`，已按上下文还原。
4. **行 1013**：示例中 `obj.ino $net name` 疑为 `obj.info $net name` 之笔误。
5. **行 907（obj.port.info 的 vec）**：“返回格式值的格式为''"，例如"703"” 原文格式碎裂，语义已按上下文还原（数组端口定义+下标）。
6. **行 931（obj.lview.info 的 cover）**：`obj.lview.infocover` 缺空格；`-puts stdout` 后的示例输出行有碎裂，已按上下文重排，仅供示意。
7. **行 664**：原文 “HqFpg 还包含一些预定义系统库” 疑为 “HqFpga” 之误。
8. **行 817/824**：`obj.foreach` 的 `<obj_type>` 列表为 `lib cell view inst nview_inst net pin port`，其中含 `nview_inst`；表内说明 Nview 的 `inst` 与 `nview_inst` 语义相近，两者并存的精确差异原文未明确说明。
