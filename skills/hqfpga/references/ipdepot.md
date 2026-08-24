<!-- 来源：ipdepot 目录结构调研（ipcreator 源码 + 实际 xml 分析） -->

# ipdepot 与 IP 配置体系

ipdepot（`<版本根目录>/build/ipcreator/sup_files/ipdepot/`）是 HqFpga 全部 IP 的**唯一事实来源**。理解这里的结构，agent 就能看懂每个 IP 配置项的含义，从而手工修改 `.hqip` 配置文件并生成 IP 网表。

## 1. 目录结构

```
ipdepot/
├── category.list / category.trans.chs   # IP 分类层级及其中文翻译
├── <IP族>/                    # 如 pll/、ddrc/、ebr_sl2/
│   ├── <变体>/                # 同一 IP 的不同器件/容量变体
│   │   ├── <变体>.xml         # meta XML：配置项定义（核心）
│   │   ├── <变体>.ii          # 内部默认 INI（随 .hqip 输出）
│   │   ├── <变体>.dgm         # GUI 框图（对 CLI 无用）
│   │   ├── _ipgen_.desc       # ipgen 可执行文件定位（INI）
│   │   ├── trans_lang.chs     # 配置项描述的中文翻译表
│   │   └── UG*.pdf            # 官方手册（最权威的参数说明）
│   ├── head.v                 # （部分 IP）版权/描述头模板
│   ├── example_design/        # （部分 IP）参考设计
│   └── *.enc                  # （部分 IP）加密网表
└── ...
```

注意：**目录名与 xml 文件名可能不一致**（如 `pll/pll_div_5k/pll_div_25k.xml`），始终以递归找到的 xml 路径为准。

## 2. meta XML：配置项的定义与解释

每个 `<cfg>` 携带三类信息：

```xml
<cfg_group name="clkfb" desc="Feedback{%clkfb%}">
    <cfg name="intfb" desc="Internal Feedback{%intfb%}">
        <values type="bool" default="true"></values>
    </cfg>
    <cfg name="usrfb" desc="Custom Feedback{%usrfb%}">
        <active_cond>clkfb.intfb == false</active_cond>
        <values type="bool" default="false"></values>
    </cfg>
</cfg_group>
```

- **cfg 属性**：`name`（短名）、`hide="1"`（不写入 .hqip）、`disp_only="1"`（派生只读量，不可改）
- **values 块**（合法值的关键）：`type`（bool/int/double/enum/text）、`range`（数值上下限，冒号或空格分隔）、`default`；枚举型用 `<value desc="显示名">实际值</value>` 列出合法值——**写入 .hqip 的是 value 文本，不是 desc**
- **desc 与 {%MSGID%}**：`desc` 中的 `{%xxx%}` 是翻译 ID，在同目录 `trans_lang.chs` 的 `TRANS_TABLE` 中查中文含义。例如 pll 的 `{%freq%}` → "频率(兆赫兹)"

### active_cond / cond 表达式

Python 语法，可引用其他 cfg 的 hier_name、`ip_device`、`startswith` 等：

- **cfg 级**：条件不满足时该配置项不生效（UI 置灰）。注意：生成 .hqip 时这些项仍带默认值写入，改它们通常无意义
- **values 级**：同一 cfg 可有多个 values 块，按条件选择合法值集。例如 ddrc 的 `CHIP.FREQ` 在 `SA5Z-50` 上合法范围 400..533，在 `SA5Z-30` 上固定 400——**改值前必须确认当前条件命中的那一组 values**

## 3. .hqip 文件结构

```ini
[General]
clki.freq=100.0          # 拍平的 cfg_group.cfg=value
clkfb.intfb=TRUE
[File]
output_module=xsIP_PLL_FREQ
[IP]
device=SL2-12E-8F256
meta_file=C:/.../ipdepot/pll/pll_freq_25k/pll_freq_25k.xml
```

- key = `cfg_group.name + "." + cfg.name`（嵌套组继续叠加；顶层独立 cfg 无前缀）
- 开头 `;internal ini values` 段来自 `<xml同名>.ii` 文件，通常不必改

## 4. 修改 .hqip 的约束（重要）

1. **值必须合法**：枚举项等于某个 `<value>` 文本；数值在 `range` 内；bool 写 `TRUE/FALSE`
2. **条件性合法值**：有 values 级 `<cond>` 时，先确定当前条件（器件、其他参数）命中哪组 values，再从中取值
3. **active_cond 为假的项不要改**（改了也不生效）；`disp_only`/`hide` 项不要改
4. **交叉约束**：部分 IP 有 `<rule>` 规则（如 pll 级联规则），避免违反
5. **不要动 `[IP]` 段的 `device=` 和 `meta_file=`**——`-ipgen` 靠它们定位 xml 和 ipgen 程序；`device=` 由 `hqbuddy -device` 统一维护

## 5. 标准操作流程：修改参数并生成网表

1. 读 .hqip 的 `[IP] meta_file=` 定位 meta xml
2. 在 xml 中按 hier_name 找到 cfg（如 `clkos2.freq` → `cfg_group clkos2` 下的 `cfg freq`）
3. 看 desc（必要时查 `trans_lang.chs` 翻译）确认含义与单位
4. 看 values 确定合法值（type/range/枚举列表/条件 cond），检查 cfg 级 active_cond 的前提项
5. 修改 .hqip `[General]` 中对应的 key（前提项如 `clkos2.enable` 一并设置）
6. 运行 `hqbuddy -ipgen <.hqip>` 生成网表（自动通过 `_ipgen_.desc` 定位 ipgen 程序，在 .hqip 同目录输出 `.v`）
7. 需要权威说明时查阅同目录 `UG*.pdf`（路径见 `_ipgen_.desc` 的 `DOC=`）

**端口与复位极性**：生成的网表是加密的（`pragma protect`），读不到内部逻辑。端口方向/宽度看网表模块声明即可；复位极性（如 `srst` 高有效）、握手信号语义（如 `tx_ready`）以 `UG*.pdf` 或 `example_design/` 中的例化为准——不要凭命名猜测，拿不准就写最小 TB 仿真验证

## 6. 辅助文件速查

| 文件 | 用途 |
|---|---|
| `_ipgen_.desc` | `[IPGEN]` 段：`EXE=`（ipgen 程序，`<ROOT>/` 或相对路径）、可选 `DOC=`、`HQFPGA=YES` |
| `<变体>.ii` | 底层默认参数（如 pll 的 `mode=2`），原样进入 .hqip |
| `trans_lang.chs` | `TRANS_TABLE` 元组：`(%MSGID%, 中文)`，用于理解 desc |
| `UG*.pdf` | IP 官方手册，参数最权威解释 |
| `example_design/` | 参考设计（接线/仿真参考） |
| `category.list` / `category.trans.chs` | IP 分类体系（仅浏览用） |
