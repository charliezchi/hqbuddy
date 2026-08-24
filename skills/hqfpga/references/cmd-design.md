<!-- 来源：docs/user_manual/hqfpga_um_chs.md 第1327–1669行（§15.1–15.15，design.* 命令参考） -->

# Part 06 — design.* 命令参考（§15.1–15.15）

本部分蒸馏自《智多晶 HqFpga 用户手册》第 15 章"命令参考"中 `design.*` 系列命令。多数 `design.*` 命令是对底层 `nl.*` / `impl.*` 命令的封装组合，目的是方便调用。

---

## 15.1 design.analyze

分析 RTL 源描述。功能等同于 `rtl.analyze`，并在其基础上增加了一些友好信息输出功能。

（`rtl.analyze` 的详细说明见原文 15.74 节。）

---

## 15.2 design.bitgen

产生位流文件。

### 语法

```txt
design.bitgen <bitfile> [-lsc]
```

### 参数

| 参数 | 类型 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| bitfile | 字符串 | 无 | 指定要生成的位流文件名 |
| lsc | 可选 | 无 | 指定时生成 Lattice XO2 的位流文件格式 |

---

## 15.3 design.flatten

执行对输入网表的展平（flatten）。

### 语法

```txt
design.flatten
```

### 参数

无。

### 说明

- 用于展平层次化的设计网表。对层次化网表执行后，网表只保留一个层次。
- 本命令实际封装组合了 `nl.flatten` 和 `nl.unflatten`（见 15.50、15.57 节）。
- 因 `nl.flatten` 与 `nl.unflatten` 必须成对使用，本命令主要为方便而设立。

---

## 15.4 design.lo.area

执行对输入网表的面积逻辑优化（主要优化 literal 数）。

### 语法

```txt
design.lo.area [-effort <effort_value>] [-so_effort <so_effort_value>]
```

### 参数

| 参数 | 类型 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| effort | 枚举 (low\|std\|high) | std | 逻辑优化强度 |
| so_effort | 枚举 (low\|std\|high) | std | 时序元件优化（sequential optimization）强度 |

### 说明

- 循环执行一系列逻辑变换操作优化面积，通常比较耗时。`-effort` 控制优化质量与运行时间的折中：
  - `low`：运行时间短，但结果可能不太好；
  - `std`：在好结果与可接受运行时间之间平衡；
  - `high`：目标是面积最小，但运行时间最长。
- 缺省情况下只优化组合逻辑元件；若指定 `-so_effort`，则时序元件也会被处理（例如去除数据输入为常数的触发器）。

### 示例

```txt
design.lo.area -effort high
```

进行高强度的逻辑优化。

---

## 15.5 design.lo.timing

执行对输入网表的时序驱动（timing-driven）逻辑优化。

### 语法

```txt
design.lo.timing [-effort <effort_value>]
```

### 参数

| 参数 | 类型 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| effort | 枚举 (low\|std\|high) | std | 逻辑优化强度 |

### 说明

- `-effort` 用于控制优化质量与运行时间的折中。
- 【注意】时序驱动优化必须针对时序约束进行；若用户未指定时序约束，本命令不执行任何操作。

### 示例

```txt
design.lo.timing -effort low
```

进行低强度的时序驱动逻辑优化。

---

## 15.6 design.load

从外部文件（UDB 存储格式）读入设计数据。

### 语法

```txt
design.load <filename>
```

### 参数

| 参数 | 类型 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| filename | 字符串 | 无 | 指定外部文件名 |

### 说明

- 从 `<filename>` 指定的外部文件读入设计数据，该文件必须是通过 `design.save` 保存的，扩展名通常为 `udb`。
- 注意事项：
  1. 读外部文件之前会清空当前内存的所有设计数据；
  2. 外部文件不保存时序约束信息，调用后往往需要重新读入时序约束；
  3. UDB（Universal Design DataBase）为 HqFpga 专有的内部设计数据存贮格式。

### 示例

```txt
design.load my.udb
```

从 `my.udb` 文件中读入设计数据。

---

## 15.7 design.map

进行工艺映射（technology mapping）操作。

### 说明

- 本命令封装组合了如下命令：

```txt
nl.flatten
impl.decomp
impl.map
nl.unflatten
```

- `design.map` 的命令参数与 `impl.map` 完全相同（impl.map 详见 15.27 节；impl.decomp 见 15.22 节；nl.flatten 见 15.47 节；nl.unflatten 见 15.55 节）。

---

## 15.8 design.pack

进行组装（pack）操作。

### 说明

- 本命令封装组合了如下命令：

```ignorefile
nl.flatten
impl.pack
nl.unflatten
```

- `design.pack` 的命令参数与 `impl.pack` 完全相同（impl.pack 详见 15.28 节；nl.flatten 见 15.47 节；nl.unflatten 见 15.55 节）。

---

## 15.9 design.place

进行布局（placement）操作。

### 说明

- 本命令封装组合了如下命令：

```txt
nl.flatten
impl.place
impl.legalize
nl.unflatten
```

- `design.place` 的命令参数与 `impl.place` 完全相同（impl.place 详见 15.29 节；impl.legalize 见 15.22 节；nl.flatten 见 15.47 节；nl.unflatten 见 15.55 节）。

---

## 15.10 design.reset

清空当前内存的所有设计数据。执行后 HqFpga 程序状态基本等同于程序刚启动时的状态。

### 语法

```txt
design.reset
```

### 参数

无。

---

## 15.11 design.route

进行布线（routing）操作。

### 说明

- 本命令封装组合了如下命令：

```txt
nl.flatten
impl.route
nl.unflatten
```

- `design.route` 的命令参数与 `impl.route` 完全相同（impl.route 详见 15.30 节；nl.flatten 见 15.47 节；nl.unflatten 见 15.55 节）。

---

## 15.12 design.rtlsyn

进行 RTL 综合及面向面积的逻辑优化。

### 说明

- 本命令封装组合了如下命令：

```txt
rtl.elaborate
macro.map
design.lo.area
```

- 子命令详解：rtl.elaborate 见 15.77 节；macro.map 见 15.45 节；design.lo.area 见 15.4 节。

---

## 15.13 design.save

将内存中的设计数据保存到外部文件。

### 语法

```txt
design.save <filename>
```

### 参数

| 参数 | 类型 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| filename | 字符串 | 无 | 指定外部文件名 |

### 说明

- 将内存中的设计数据保存到 `<filename>` 指定的外部文件，扩展名通常为 `udb`。
- 【注】保存除时序约束之外的所有设计信息。若当前设计含时序约束，日后通过 `design.load` 回读所保存的文件后，需要重新读入时序约束。

### 示例

```txt
design.save my.udb
```

将内存中的设计数据保存到文件 `my.udb` 中。

---

## 15.14 design.tdomap

进行时序驱动优化及工艺映射。

### 说明

- 本命令封装组合了如下命令：

```ignorefile
design.lo.timing
nl.ioinsertion
design.map
```

- 子命令详解：design.lo.timing 见 15.5 节；nl.ioinsertion 见 15.51 节；design.map 见 15.7 节。

---

## 15.15 design.unmap

完成网表的反映射（unmapping）：将映射后与工艺相关的网表转换成与工艺无关的网表。

### 语法

```txt
design.unmap [<nview>]
```

### 参数

| 参数 | 类型 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| nview | 对象引用 | 无 | 指定要反映射的模块（对应的网表视图 netlist view）；若未指定，则对顶层设计网表进行反映射 |

### 示例

```txt
design.unmap
```

对顶层设计网表进行反映射。

---

## 疑点标注（原文如此）

1. **§15.4 design.lo.area 章节号与语法**：正文标题为 "15.4 design.lo.area"，但其语法块开头写的是 `design.lo`（见原文 1388–1391 行），应为 `design.lo.area`。§15.5 design.lo.timing 的语法块同样写成 `design.lo`（原文 1435 行），也应为 `design.lo.timing`。
2. **§15.2 参数清单**：参数列表用"类型: 字符串"描述 bitfile，未列出缺省值；`lsc` 仅标注"类型: 可选"，其缺省语义不明确。按原文保留。
3. **§15.5 参数说明**：原文未给出 `-effort` 缺省值，蒸馏时按 §15.4 的 std 推断标注，如存疑请以原文为准。
4. **§15.7/15.8/15.9/15.11/15.14 封装命令列表**：各段引用的内部命令章节号（impl.decomp=15.22、impl.map=15.27、impl.pack=15.28、impl.place=15.29、impl.route=15.30 等）与 design.map 段落中"nl.flatten 见 15.47 节 / nl.unflatten 见 15.55 节"等编号存在交叉引用不一致的迹象（同一命令在不同段落被引用为不同节号），无法确认真伪，已在正文中按原文分段保留。
5. **§15.13 说明**："本命令除时序约束之外的所有设计信息"一句原文缺谓语动词（疑为"本命令保存除时序约束之外的所有设计信息"），已在蒸馏中按上下文还原。
6. **格式碎裂**：原文档标题如 "## 15.10design.reset"、"## 15.14design.tdomap" 在数字与命令名之间缺空格；小节标题（如"15.2.1 语法"）未用 `##` 而直接以段落出现。已在蒸馏文件中统一为规范格式，不影响内容。
