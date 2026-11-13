# IP Creator meta XML 语法与特殊设置

以 `ipcreator/upkgs/meta_info.py`、`meta_expr.py` 和 `ipgen/ipgen_hdl_ip/ipgen_hdl_ip.py` 为准。以下标注的实测行为来自 FT111226。维护旧版 IP 时，用目标版本的解析器和后端复核。

## 文件结构与目录筛选

`<root>` 下常用 `name`、`desc`、`version`、`devices`、`categories/category`、`cfg`、`cfg_group`、`port`、`rule`。名称用稳定的标识符。分组内的配置用 `GROUP.KEY` 引用，嵌套组继续加前缀。通用 HDL 后端构造 RTL 参数名时只按直接所属组名去前缀，用嵌套组传参前检查实际生成的 wrapper。

`devices` 为按空白分隔的支持项，可用器件族或适用的料号写法。较新的 Creator 还识别 `exclusive_devices` 排除项。发布前分别用目标器件和排除器件检查目录筛选。表达式中的 `ip_device` 由解析器注入，构造元数据时优先读取 `IP_DEVICE`，其次读取 `PROJ_DEVICE`。用手工调用检查器时提前设为与 `.hqip` 一致的完整料号。器件前缀条件如 `ip_device startswith 'SK7'`，FT111226 实测不区分大小写。

配置、选项、端口、规则的显示文字可通过 `desc="English{%KEY%}"` 和同目录 `trans_lang.chs` 中的 `TRANS_TABLE` 本地化。枚举序列化和传参使用 `<value>` 内的值。修改翻译时保留稳定键和值。

## 值与条件

| 用途 | 写法 | 行为 |
|---|---|---|
| 整数／浮点输入 | `<values type="int" default="150" range="50:250"/>`，或 `type="double"` | 上下限都包含。支持边界表达式，界面输入整数时仍应使用整数文本，部分版本会把直接传入的浮点截断 |
| 离散数值 | `<values type="int" default="8" nums="8 16 32"/>` | 空白分隔。校验器优先用 `nums`，有 `nums` 时按该集合检查 |
| 带标签的枚举 | `<value desc="50 Ω{%DRIVE_50%}">1</value>`，放在 `<values type="enum">` 内 | 标签可翻译，实际配置是编码 1。引用普通数值枚举时用 `G.MODE == '1'`，做算术时用 `int(G.MODE)` |
| 布尔 | `<values type="bool" default="true"/>` | 表达式中是布尔量，`.hqip` 常用 `TRUE/FALSE`。需要生成 Verilog 0/1 参数时优先用数值枚举，避免 Python 布尔文本进入 HDL |
| 文本／文件 | `<values type="text" default="..."/>` 或 `<values type="file"/>` | 检查器接收文本，文件是否存在以及内容格式取决于实际消费方。通用 HDL 后端对文件型参数自动加引号 |
| 条件启用 | 在 `cfg` 或 `cfg_group` 内放 `<active_cond>G.ENABLE</active_cond>` | 组条件会影响其下配置。停用配置中的旧 INI 值可产生忽略警告，不能依赖其旧值参与规则或 RTL |
| 条件值集 | 在每个 `<values>` 内放一个 `<cond>…</cond>` | 同一配置可以有多块。使用互斥且覆盖有效配置的分支，确保条件切换有合法值。没有显式默认值时，运行时可从合法值解析默认 |

表达式接近 Python。常用 `and/or/not`、比较、四则运算、`int(...)`、`log2(...)` 和条件表达式 `a if cond else b`。XML 中用 `&lt;`、`&gt;`、`&amp;` 转义，属性中的引号按 XML 规则处理。 `cond`、`active_cond`、`vcond` 是源码识别的条件标签别名，维护时优先用所在位置的常见拼法。当前版本支持计算型 `default`，例如 `default="2 * int(G.MODE)"`。它只在缺省或重新求默认时计算，界面上的派生量宜用只读字段和互斥条件值集，并验证切换后回算。条件、默认值、范围及端口应引用存在的配置，避免循环依赖。

## 端口与跨项规则

```xml
<port name="clk"><dir>input</dir></port>
<port name="data">
    <cond>G.ENABLE</cond>
    <dir>output</dir>
    <bus_range>G.WIDTH - 1 : 0</bus_range>
</port>
<rule name="WidthCheck" desc="Width exceeds configured limit{%WIDTH_CHECK%}">
    <sub_rule>not G.ENABLE or G.WIDTH &lt;= 32</sub_rule>
</rule>
```

`dir` 支持 `input`、`output`、`inout`。标量省略范围，向量用 `bus_range`，解析器也接受 `range`。规则中的每个 `sub_rule` 都必须为真。写涉及可停用项的规则时先判断功能是否启用。库例子见 `fifo_generator` 的多项规则和 `ebr_shark/ebr_sp` 的初始化文件选择。

FT111226 的 `processPort` 要求解析结果为列表。XML 恰好只有一个 `<port>` 时会触发类型错误。遇到单端口需求，先核对目标版本是否修复，或使用能表达真实接口的封装方案。端口条件和范围可用 `ipcr_chkmeta -vo` 对照生成的声明核验。

## 显示、保存与下发

- `hide="1"` 隐藏 GUI 项，隐藏值仍可用于表达式和 RTL 映射。FT111226 的 `get_ini_content()` 跳过顶层隐藏项与隐藏组，递归组内时仍可能保存隐藏子项。固定内部值宜有明确默认值，查看实际 `.hqip` 再判断它是否被持久化。
- `disp_only="1"` 使字段只读，普通 `.hqip` 序列化跳过该项。解析器仍可在运行时计算它，通用后端可在活动且列入 `SYS_PARAMS` 时传入 RTL。比如固定标准温度下，XML 显示「标准温度」，底层值为 4000，可直接绑定 `TCEM_NS`。
- `active_cond` 控制启用状态和通用后端的活动检查。一个参数能显示或出现在 `.hqip`，仍需检查后端有没有消费它。 `hqbuddy -gen_hqip` 的默认文件由 hqbuddy 自己生成，和原生 GUI 保存结果可能不同。

## 通用 HDL 后端识别的顶层配置名

这些名字由 `ipgen_hdl_ip` 识别。专用生成器可使用自己的配置契约。列表类配置通常定义为顶层隐藏枚举，后端读取第一块 `values` 中的整份列表。

| 名字 | 作用 |
|---|---|
| `Functional_Selection` | 选源包 `top/` 下的顶层文件基名。可用它作为分组、参数和端口条件 |
| `SYS_PARAMS` | 按完整键查找配置，从活动项的当前值生成 `defparam`。RTL 命名和例子见 [通用 HDL IP 封装](package.md) |
| `DEFINE_PARAMS` | 列出的每个键，其活动值作为无值宏的名称。例如隐藏项 `FLAG` 的值为 `FLAG_ON`，生成 Verilog 的 `` `define FLAG_ON `` |
| `DEFINE_VAL_PARAMS` | 列出的每个活动键生成带值宏，键去掉直接所属组前缀。例如 `G.WIDTH_CODE=1` 生成 `` `define WIDTH_CODE 1 `` |
| `ENC_OFF` | 后端按这个配置项是否存在选择明文输出。FT111226 实测即使值为 0，仍走明文路径 |
| `DEVICE`、`Sim_output` | 在 `DEFINE_PARAMS` 中有特殊分支。前者按配置的候选文本匹配实际器件或族，匹配项作为宏名。后者让后端另外生成带其宏的仿真版本。实际命名和产物以目标版本运行结果为准 |

已有库例子见 `PSRAM_Controller` 的 `SYS_PARAMS`、`xstc_8b10b` 的两类宏列表、`Bus_Bridge` 的条件端口。

## 验证组合

先用 `ipcr_chkmeta <xml> -ini <hqip> -vo <stub.v>` 检查默认配置、非默认配置、启用／停用切换、相关器件及非法组合。新增动态界面时用实际 MetaInfo 运行时切换参数或在 Creator 里操作，核对选项文本、读回值和端口。通用后端可用 `-debug` 查看参数、宏和保留的 wrapper，再核对真实网表。

FT111226 最小样例验证了数值枚举与描述分离、器件前缀、计算默认值、动态位宽、停用覆盖项被忽略，以及非法 `nums` 和跨项规则报错。另一份样例验证固定只读参数进入网表，以及两类宏的传值。
