# XiST 原语库框架指南（primitives.md）

> 原语仿真/综合库**随 HqFPGA 版本随时更新**，本文不固化任何清单，
> 只提供：①库在哪（发现路径）②命名规则怎么解 ③如何按需提取清单
> ④使用规则。需要具体清单时按 §3 现场提取。

## 1. 原语库在哪（发现路径）

| 库 | 路径（相对所选 HqFPGA 版本根） | 用途 |
|---|---|---|
| 第三方综合原语库 | `build/common/syn/verilog/XIST/seal_syn_prim.v` | Seal 器件（SA5Z-30/50）第三方综合必加 |
| 同上（Sealion） | `build/common/syn/verilog/XIST/sealion_syn_prim.v` | Sealion（SL2）第三方综合必加 |
| 门级仿真库 | `hqbuddy -simlib` 编译至 ModelSim（XiST 库映射） | 门级/SDF 仿真的原语模型 |

- **版本同代铁律**：HqFPGA 升级后必须换用新版自带的库文件，否则第三方综合报错。
- 实测网表（EDIF→Verilog 转换产物）中的原语名与库内模型同名（xs 前缀）。

## 2. 命名规则怎么解（通用框架，非固定清单）

原语名 = `xs` + **家族词干** + **变体后缀**：

- 家族词干（按需从库文件现场提取，常见语义）：IOB*=IO 缓冲、*DFF*=D 触发器、
  *LAT*=锁存、LUT*=查找表、SRL*=移位寄存、MUX*=选择器、*CARRY/XORCY*=进位链、
  BRAM*=块 RAM（TD 双口/S 单口/PD 伪双口）、DSP*=乘加、PLL*/DLL*=时钟、
  GSR/PWR*=复位、JTAG/BSCAN*=调试链、OSC*/BUFG*=振荡与时钟缓冲。
- 变体后缀：`_K1`（时钟极性）、`_P1/_C1`（置位/清零）、`_R1/_S1`（复位/置位）、
  `_E1`（使能）；数值=位宽或参数档位。以源文件内端口声明为准。
- 具体某器件支持哪些原语：以该器件库文件里实际存在的 module 为准（§3 现场提取）。

## 3. 如何按需提取清单（可复用方法）

```python
import re
txt = open(r"<HqFPGA 版本根>/build/common/syn/verilog/XIST/seal_syn_prim.v",
           encoding="utf-8", errors="replace").read()
mods = []
for m in re.finditer(
        r"^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\s*\((.*?)\)\s*"
        r"(?:/\*[^*]*\*/)?\s*;", txt, re.M | re.S):
    name = m.group(1)
    ports = re.findall(r"(input|output|inout)\s*(?:\[[^\]]*\])?\s*"
                       r"([A-Za-z_][A-Za-z0-9_$]*)", m.group(2))
    mods.append((name, ports))
```

- 声明样式注意：`)/*synthesis syn_black_box syn_noprune=1*/;`——括号与分号之间
  可能有注释，正则需容忍。
- 需要"家族聚合"时按词干分组即可（见 §2）。

## 4. 使用规则

- 第三方综合工程：源码 + 原语库 .v 一起加入；实例化 VLA/自定义 IP 时实例末尾加
  `/* synthesis syn_noprune=1 */` 防优化。
- 门级仿真：强制例化 `xsGSR(.GSR(1'b1))` 与 `xsPWR(.PUR(1'b1))`（见 modelsim.md）。
- 原语模型若不支持 SDF 反标，则门级时序仿真不可用（FT091626 现状，勿尝试）。
