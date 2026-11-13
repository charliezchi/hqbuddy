# 逐文件写法与生成来源

以下样例与 [通用 HDL IP 封装](package.md) 使用同一个 `demo`。先按 [目录结构](ui-development.md) 放置文件，再按交付范围选用。库级文件应合并到现有库中。

## 手写的界面文件

**`demo.xml`** 使用 UTF-8。这个文件可单独用于检查界面元数据。加入 `Functional_Selection` 和 `SYS_PARAMS` 后，同一份 XML 也可驱动通用 HDL 后端。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <name>demo</name>
    <desc>Polarity demo{%IP_TITLE%}</desc>
    <version>1.0</version>
    <devices>Shark</devices>
    <categories><category>Basic Elements</category></categories>

    <cfg name="Functional_Selection" hide="1">
        <values type="enum" default="invert_demo"><value>invert_demo</value></values>
    </cfg>
    <cfg name="SYS_PARAMS" hide="1">
        <values type="enum"><value>LOGIC.INVERT</value></values>
    </cfg>
    <cfg_group name="LOGIC" desc="Logic{%GROUP_LOGIC%}">
        <cfg name="INVERT" desc="Output polarity{%OUTPUT_POLARITY%}">
            <values type="enum" default="0">
                <value desc="Pass through{%PASS%}">0</value>
                <value desc="Invert{%INVERT%}">1</value>
            </values>
        </cfg>
    </cfg_group>

    <port name="a"><dir>input</dir></port>
    <port name="y"><dir>output</dir></port>
</root>
```

**`trans_lang.chs`** 是 UTF-8 文本，`TRANS_TABLE` 使用 Python 元组写法。每个条目由 XML 中的翻译 ID 和中文显示文字组成。

```python
TRANS_TABLE = (
    ('IP_TITLE', '极性示例'),
    ('GROUP_LOGIC', '逻辑'),
    ('OUTPUT_POLARITY', '输出极性'),
    ('PASS', '直通'),
    ('INVERT', '反相'),
)
```

**`demo.dgm`** 是手写或由脚本从端口清单排版的 UTF-8 等宽文本。下面是一份完整的最小框图。保留空格，让输入和输出分别靠近对应边。动态接口可列出所有候选端口，条件和位宽来自 XML。若需要虚拟端口或组合标签，参考源码 `ui_new/diagram_functions.py::parse_verilog_port_declarations` 的 `[PORT-DECLARE-START]` 块，并在目标 GUI 核对渲染。

```text
[DIAGRAM-START]
Polarity demo
+-------------------+
|a                 y|
+-------------------+
[DIAGRAM-END]
```

**`category.list` 和 `category.trans.chs`** 属于整个库。上例复用已有的 `Basic Elements`，两个文件都无需编辑。需要新增分类时，向列表追加 `> Logic Examples {%CAT-LOGIC-EXAMPLES%}`，并在原有分类翻译表追加 `('CAT-LOGIC-EXAMPLES', '逻辑示例'),`。XML 中使用 `<category>Logic Examples</category>`。增加子分类时用 `>>`，XML 引用 `父分类/子分类`。

## 可选 INI 旁文件与实例

**`demo.dfv`** 手写，或从已校验的 `.hqip` 提取希望预设的 `[General]` 键。下面的预设让 GUI 新建时选反相。已有实例继续使用保存的选项。CLI 的 `hqbuddy -gen_hqip` 从 XML 与内部 INI 构造默认文件，需要同一预设时显式传 `--set LOGIC.INVERT=1`。

```ini
[General]
LOGIC.INVERT=1
```

**`demo.ii`** 手写，键名和值来自选用后端的内部契约。样例 `demo` 无需内部参数。现成的 Shark 单口 EBR 的 `ebr_sp.ii` 内容如下，`ebr_mode` 由 EBR 后端消费。

```ini
[General]
ebr_mode=0
```

**`demo.hqip`** 由 GUI 保存或由 `hqbuddy -gen_hqip` 创建，也可手写用于测试。 `meta_file` 指向当前待测 XML 的实际路径。 `output_module` 是生成模块名。实例完整样例见 [通用 HDL IP 封装](package.md)。项目中的 `.ipcr/ipcr_cfg.ini` 由 Creator 在项目工作目录维护，开发变体时无需手写。

## 可生成版本的附加文件

| 文件 | 写法或生成来源 |
|---|---|
| `_ipgen_.desc` | 手写 INI。普通通用后端使用 `[IPGEN]`、`EXE=<ROOT>/ipgen_hdl_ip.exe` 和 `HQFPGA=YES`。专用或独立后端按 [后端调用契约](generate.md) 填写 |
| `head.v` | 手写 Verilog 文件头，最小内容为一行注释，例如 `// Polarity demo` |
| `demo.enc` | 准备 `package/demo/top/invert_demo.v` 及依赖。在 `package` 内用 `hqencrypt.exe -id demo -np 1 -o <绝对路径>/demo.enc` 打包开发源包。完整调用和验证见 [封装](package.md) |
| `opt.tcl`、`lo.tcl`、`pp.tcl` | 可选，按后端的 Tcl 运行阶段手写。 `opt.tcl` 可用 `lappend vlog_files src/demo/rtl/helper.v` 补充综合源文件。文件须在归档内存在 |
| `UG_demo.pdf` | 将独立的 IP 用户文档导出为 PDF，放到变体目录。描述文件可加 `DOC=<ROOT>/sup_files/ipdepot/demo_family/demo_variant/UG_demo.pdf`，路径从 IP Creator 根目录展开 |
| `example/` | 随库放入已验证的示例工程及依赖，按目标版本的导出布局准备。示例内容取自该 IP 的实际连接方式和约束 |
| 生成的 `.v`、实例模板、仿真或约束附件 | 运行后端生成。不同后端产物不同，以输出目录和日志为准 |

对应的最小 RTL 顶层可放在 `package/demo/top/invert_demo.v`。

```verilog
module invert_demo #(parameter INVERT = 0)(input a, output y);
    assign y = INVERT ? ~a : a;
endmodule
```
