## 二、U 命令概览（§11）

> HqFpga 将 FPGA 设计各项功能集成在单一可执行文件中，不同功能通过执行不同命令完成。命令按功能分为设计实现、时序分析与报告、数据接口等几大类。以下为命令地图（"详见章节"为原文标注的 15.x 节号）。

### 11.1 FPGA 设计实现

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 设定目标器件 | `dv.setup` | 15.18 |
| Verilog 源文件解析 | `design.analyze` | 15.74 |
| Verilog 源文件包含路径设定/清除 | `rtl.incpath.set/clear` | 15.78 / 15.79 |
| Verilog 源文件解析宏定义/消除 | `rtl.macro.define/undefined` | 15.80 / 15.81 |
| RTL 综合及逻辑优化 | `design.rtlsyn` | 15.77 |
| 综合优化选项设置 | `rtl.set` | 15.82 |
| 时序驱动优化及工艺映射 | `design.tdomap` | 15.7 |
| 组装（packing） | `design.pack` | 15.8 |
| 布局 | `design.place` | 15.9 |
| 布线 | `design.route` | 15.11 |
| 查询可用目标器件 | `dv.query` | 15.17 |
| 查询当前目标器件信息 | `dv.info` | 15.16 |
| 查询许可证信息 | `license.query` | 15.42 |

### 11.2 时序分析与报告

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 时序分析与报告设置 | `ta.set` | 15.93 |
| 运行时序分析 | `ta.run` | 15.92 |
| 结束时序分析 | `ta.end` | 15.89 |
| 时序报告 | `ta.report` | 15.91 |
| 报告最大时钟频率 | `ta.fmax.report` | 15.90 |

### 11.3 数据接口（design interface）

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 从外部文件读入设计数据 | `design.load` | 15.6 |
| 将内存中设计数据保存到外部文件 | `design.save` | 15.13 |
| 清空当前内存的所有设计数据 | `design.reset` | 15.10 |
| 读入 EDIF 文件 | `edif.read` | 15.19 |
| 输出 EDIF 文件 | `edif.write` | 15.20 |
| 读入 Verilog 网表 | `nvg.read` | 15.60 |
| 输出 Verilog 网表 | `nl.write` | 15.59 |
| 读入 XPN 物理网表 | `xpn.read` | 15.98 |
| 输出 XPN 物理网表 | `xpn.write` | 15.99 |
| 设置输入文件搜索路径 | `srchpath.config` | 15.84 |
| 查询输入文件搜索路径设置 | `srchpath.query` | 15.85 |
| 报告当前网表状态 | `nl.report` | 15.54 |

### 11.4 约束（constraint）与设计实现引导（implementation guide）

普通约束分为**物理约束**和**时序约束**两类。

**物理约束相关命令：**

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 读入物理约束文件 | `upc.read` | 15.97 |
| 开始物理约束命令处理 | `phycst.start` | 15.72 |
| 结束物理约束命令处理 | `phycst.end` | 15.63 |
| 设置外部参考电压 | `phycst.extvref.set` | 15.64 |
| 指定封装管脚位置 | `phycst.pin.set` | 15.68 |
| 设置位置约束 | `phycst.loc.set` | 15.66 |
| 检查位置约束合法性 | `phycst.loc.check` | 15.64 (原文如此) |
| 定义区域 | `phycst.region.create` | 15.70 |
| 指派区域 | `phycst.region.set` | 15.71 |
| 检查区域合法性 | `phycst.region.check` | 15.69 |
| 设置全局连线资源 | `phycst.net.set` | 15.67 |
| 设置 IO BANK 电压 | `phycst.vccio.set` | 15.73 |
| 合封 DDR RAM 器件自动约束 | `phycst.ddr` | 15.62 |
| 物理规则设置 | `phyrule.set` | 15.74 |
| 物理规则设置查询 | `phyrule.query` | 15.74 |

**物理约束中 IO 属性处理命令：**

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 获取当前器件支持的 IO 属性列表 | `ioh.get_attrs` | 15.31 |
| 获取当前设计顶层端口列表 | `ioh.get_ports` | 15.36 |
| 获取端口的可用 IO 属性值列表 | `ioh.get_attr_val` | 15.32 |
| 获取端口的可用 IO_TYPE 列表 | `ioh.get_iotype` | 15.33 |
| 获取缺省的 IO_TYPE 设置 | `ioh.get_default_iotype` | 15.34 |
| 获取当前缺省的 IO PULLMODE 设置 | `ioh.get_default_pullmode` | 15.35 |
| 设置缺省的 IO_TYPE | `ioh.set_default_iotype` | 15.37 |
| 设置缺省的 IO PULLMODE | `ioh.set_default_pullmode` | 15.38 |
| 设置全局 IO 属性 | `ioh.set_global_attr` | 15.39 |

**时序约束相关命令：**

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 读入 SDC 文件 | `sdc.read` | 15.87 |
| 开始 SDC 命令解析 | `sdc.start` | 15.88 |
| 结束 SDC 命令解析 | `sdc.end` | 15.86 |
| 自动生成时序约束 | `tc.autogen` | 15.95 |
| 清除时序约束 | `tc.clear` | 15.96 |

> HqFpga 支持常用 SDC（Synopsys Design Constraint）命令作为时序约束，语法说明详见原文第 14 章；SDC 命令语义详见 Synopsys 相关文档。

**设计实现引导（implementation guide）相关命令**（特殊约束，主要限制设计实现方式，如是否保持设计层次、某些元件引脚的扇出限制等）：

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 设置设计实现引导 | `impl.guide.set` | 15.24 |
| 解除设计实现引导 | `impl.guide.unset` | 15.25 |
| 查询设计实现引导 | `impl.guide.query` | 15.23 |

### 11.5 基本网表处理

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 清除网表中无用的元件实例（instance）和连线（net） | `nl.clean` | 15.47 |
| 展平网表 | `nl.flatten` | 15.50 |
| 恢复被"软展平"的层次结构 | `nl.unflatten` | 15.57 |
| 将网表中的 primitive 元件实例绑定目标库 | `nl.primbind` | 15.52 |
| 将网表中多输出组合逻辑门转换成单输出逻辑门 | `nl.cnvtmocombs` | 15.49 |
| 建立物理网表 | `nl.pstru.build` | 15.53 |
| 反向提取设计的逻辑网表 | `nl.revext` | 15.55 |
| 清理网表中的冗余 | `nl.sweep` | 15.56 |
| 对层次化网表进行 uniquify 操作 | `nl.uniquify` | 15.58 |
| 自动插入 IO 单元 | `nl.ioinsertion` | 15.51 |
| 自动检测网表中时钟源点 | `nl.clock.detect` | 15.48 |

### 11.6 程序设置及状态查询

| 功能 | 相关命令 | 详见章节 |
|---|---|---|
| 设置界面语言 | `lang.set` | 15.41 |
| 查询内存占用信息 | `info.memusage` | 15.40 |
| 消息显示与关闭 | `msg` | 15.45 |
| 设置输出目录 | `outdir.set` | 15.61 |
| 查询 HqFpga 根目录 | `root.query` | 15.74 (原文如此) |
