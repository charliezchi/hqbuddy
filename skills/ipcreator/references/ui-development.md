# IP Creator 界面开发流程与目录结构

先明确交付范围：配置界面预览，或可在项目里生成 HDL 的 IP。两者共用 meta XML。库目录由 `hqbuddy -root` 选中的 HqFpga 版本决定，安装版位于 `build/ipcreator/sup_files/ipdepot`。维护 IP Creator 源码时，对应目录为 `sup_files/ipdepot`。

## 库结构与文件职责

```text
ipdepot/
├── category.list               整个库共用的分类树
├── category.trans.chs          分类中文名称
└── demo_family/                可选组织层
    └── demo_variant/           IP 变体目录
        ├── demo.xml            IP 元数据，目录扫描入口
        ├── trans_lang.chs      IP 自身的中文词条
        ├── demo.dgm            配置窗口的端口框图
        ├── demo.dfv            可选的新建配置预设
        ├── demo.ii             可选的内部 INI 参数
        ├── _ipgen_.desc        生成后端及帮助文档路径
        ├── demo.enc            通用 HDL 后端的源包
        ├── head.v              通用 HDL 后端的输出文件头
        ├── UG_demo.pdf         可选的用户文档
        └── example/            可选的配套示例
```

| 文件 | 何时需要 | 加载方式 |
|---|---|---|
| `demo.xml` | 界面和生成都需要 | 浏览器递归扫描 `.xml`，读取 IP 名称、描述、分类、器件和版本。打开窗口时再完整解析配置、端口和规则 |
| `category.list` | 整个库需要一份 | 分类独立于文件夹层级。复用已有分类时只在 XML 写分类键 |
| `category.trans.chs` | 需要分类中文显示时 | 与 `category.list` 同目录，使用同一分类翻译键 |
| `trans_lang.chs` | 需要 IP 中文界面时 | 变体目录内固定文件名，`TRANS_TABLE` 对应 XML 的 `{%KEY%}` |
| `demo.dgm` | 需要自定义端口框图时 | 从 XML 文件基名查找。图形布局写在 `[DIAGRAM-START]` 与 `[DIAGRAM-END]` 之间。端口名字与 XML 对齐，端口条件和位宽以 XML 为准 |
| `demo.dfv` | 新建时需要一套独立的预设值 | 与 XML 同基名，按 INI 的 `[General]` 使用完整配置键。打开已有实例时用该实例的 `.hqip`，新建时才加载 `.dfv`。普通缺省值优先直接写 XML |
| `demo.ii` | 后端需要随实例保存的内部参数时 | 与 XML 同基名，读取为 INI，内部项会附入实例 `.hqip`。以同一后端的现有 IP 为模板 |
| `_ipgen_.desc` | 可生成版本需要 | 与 XML 同目录，`[IPGEN]` 中写普通 `EXE` 或独立生成器契约，可写 `DOC`。仅做预览时可先省略 |
| `demo.enc`、`head.v` | 采用 `ipgen_hdl_ip.exe` 时 | 源包和 XML 同基名。专用后端按自己的依赖交付。详见 [通用 HDL IP 封装](package.md) |
| 用户文档、`example/` | 随 IP 提供帮助或参考工程时 | 帮助优先用描述文件的 `DOC`。新版 GUI 识别 `example/`，其他版本或后端按同类 IP 的布局核对 |

变体目录名可与 XML 基名不同。相关旁文件按 **XML 基名** 查找，`trans_lang.chs`、`_ipgen_.desc` 等使用固定文件名。递归扫描也会捡到备份 XML，所以把开发草稿和备份放在库外。变体目录中的 `.disable` 会让库条目成为禁用项。

项目生成目录与 IP 库目录分开。项目的 `ipcore_dir/<实例>/` 存放实例 `.hqip`、生成 HDL 及后端附件。实例通过 `[IP] meta_file` 引用库元数据。使用 GUI 工程工作目录时，项目可能另有 `.ipcr/ipcr_cfg.ini` 维护实例索引。

逐个文件的可复制样例与生成命令见 [逐文件写法与生成来源](file-examples.md)。

## 从空目录到可预览

1. **定入口。** 确定 IP 稳定名称、目标器件、分类及配置窗口的语言。在库外建变体目录。从同器件、同后端且形态相近的库 IP 取最小参考。独立生成器可能自带配置窗口，本流程针对由 IP Creator XML 驱动的界面。
2. **建骨架。** 写 UTF-8 XML，先填 `<root>`、`name`、`desc`、`version`、`devices` 和 `categories`。如需与 DDRC 同类，使用 `<categories><category>DDR Controller</category></categories>`。如果需要新分类，在库级 `category.list` 用 `>` 写一级分类、`>>` 写二级分类。XML 用原始分类路径，如 `Storage Elements/Block RAMs`，中文写进 `category.trans.chs`。分类无法匹配时，新版界面会归入杂项。
3. **加参数和端口。** 从上到下按使用顺序设计 `cfg_group`，用组划分原有分页的内容。先定可写值、单位、默认值及下发契约，再写条件值集、只读结果、动态端口和规则。用 `trans_lang.chs` 补 IP、分组、参数及选项的中文。具体语法见 [meta XML](meta-xml.md)。有框图需求时，从 XML 端口名制作同基名 `.dgm`，保证接口切换时图和端口表一致。
4. **在库外检查。** 用目标版本的 `ipcr_chkmeta.exe <XML> -lang eng` 查元数据。再构造缺省和代表性非缺省 `.hqip`，用 `-ini <配置> -vo <独立检查文件.v>` 验证有效值和端口。设定与目标器件一致的环境变量，命令示例见 [配置与生成](generate.md)。可用 `ipcr_chkmeta.exe <XML> -gui -lang chs` 单独预览，`-gui` 使用检查器内置配置页，最终外观和库入口以实际 Creator 为准。
5. **检查真实库入口。** 把变体目录放进选定版本的 `ipdepot`，重新打开该版 IP Creator，选实际项目器件，在分类中找到条目并打开。可用 `ipcreator.exe -lang chs -device <完整料号> -workdir <测试目录>` 启动独立的库验证。检查分类、中文、默认值、组展开和端口，切换主要模式以及条件依赖项，测试非法值提示。改动已发布配置时，用一份旧 `.hqip` 重开，检查旧值与新默认值。
6. **按范围交付。** 预览的完成条件是能从库里找到、配置窗口能打开、参数与端口联动正确。需要真正生成时，补后端描述、后端所需源包和资源，按 [通用 HDL IP 封装](package.md) 验证至少一个默认与非默认实例的真实 HDL。端口空壳用于对照声明。

## 出现问题时定位加载阶段

- **列表里找不到**：核对当前安装根目录、XML 扩展名、设备过滤、`.disable` 和搜索条件。归入杂项时检查 XML 分类键与 `category.list` 的完整路径。
- **能看到但打不开**：检查完整解析和默认值校验。逐个核对同名 `.dfv`、`.ii` 的内容及编码，并用检查器重现。列表阶段可以只解析头部，因此显示条目只能证明已扫描。
- **打开后联动或显示错误**：分别核对 XML 里的条件与有效值、翻译键、`.dgm` 端口名。查看实际模式下生成的端口声明。
- **只在点击生成时失败**：检查 `_ipgen_.desc`、后端二进制、目标版本、RTL 参数映射和后端日志。

FT111226 用现有 PSRAM 预览验证了递归扫描、DDR 分类键、中英文默认配置和 Native／AXI 端口切换。在临时目录去掉框图与翻译后，XML 仍可完成全量解析和默认求值。最终界面样式仍应在实际 Creator 中检查。

源码入口见 `upkgs/meta_file_browser.py`、`upkgs/category_info.py`、`ui_new/ips_list.py`、`ui_new/main_window.py` 和 `ui_new/diagram_functions.py`。
