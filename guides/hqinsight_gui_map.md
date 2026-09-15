# HqInsight GUI 地图（采集模式 / 调试模式 全控件梳理）

> 基于 HqFpga 3.1.1 Build 090926 实测 + 反编译（FT090526/090926 逻辑零差异）。
> "文件变化"列 = 该操作在工程目录产生的实际文件写入（git diff 实证）。

## 0. 两种模式（核心概念）

> **hq_ins.exe 启动契约（R22 实测）**：`hq_ins.exe --hqprj <.hqprj> --hqexe <hqfpga.exe 绝对路径> --hqlang chs`
> （可选 `--hqins <独立.hqins工程>`、`--vla_cfg <vla.cfg>`、`--hqlog <log>`）。**裸位置参数不被认**
> ——报 "HqFpga project file doesn't exist!"；无参数启动则 cx_Freeze IndexError。agent 用 GUI 自动化时按此契约拉起。

| 模式 | 能做什么 | 对应 CLI |
|---|---|---|
| **采集模式**（插桩器） | 增删信号、改采样/触发类型、保存工程、跑插桩实现 | `-insight -init/-ls/-add/-del/-run` |
| **调试模式** | 运行采集：布防触发、等待、抓波形、看波形 | `-insight -trig/-capture` |

- 切换：窗口左上单选钮「采集模式 / 调试模式」。
- **增删信号只能在采集模式；调试模式只能运行采集。**
- 改信号后必须「保存工程 → FPGA 实现 → 下载」才生效；改触发条件不用。

## 1. 顶层布局（采集模式）

```
┌─ 菜单栏: 文件 操作 设置 帮助 ────────────────────────┐
│ 工具栏: 保存 ⚙采样参数 📊波形 ▶运行 ⏸停止 ↺重置 … │
│ 模式钮: ◉采集模式 ○调试模式  [单次触发▾]            │
├──────────────┬──────────────────────────────────────┤
│ 层次结构浏览器 │  src_0 源码视图（点层次节点跳转源码） │
│ (文件/模块/   │  Wave_0 波形视图（调试抓取后出现）    │
│  always块/信号)│                                      │
│ ┌ 搜索框 ─────│                                      │
├──────────────┤                                      │
│ 已标记信号列表 │                                      │
│ 触发条件|信号名|类型|模块|使能✓                     │
│ + [添加LA]   │                                      │
└──────────────┴──────────────────────────────────────┘
状态栏: 工程名|器件|顶层|工作目录   资源估算: EBR/LUT/FF
```

## 2. 工具栏按钮（从左到右）

| 按钮 | 作用 | 背后行为 / CLI 对应 |
|---|---|---|
| 💾 保存 | 保存工程（含 LA 配置） | 写 `.hqins`（[SIGNAL JSON INFO]+[LA SIGNAL INFO]）+ `.hqins.save` 备份；CLI 等价 `-insight -add/-del`（即时写盘） |
| ⚙ 采样参数 | 弹「**虚拟逻辑分析仪(VLA)配置**」对话框（R22 实测 FT091226）：当前VLA(VLA_0)、对被调试信号加寄存(YES/NO)、采样深度(256/512/1024/2048/4096/8192/16384/32768/65536)、触发窗口个数(spinbox)、触发级数(spinbox)、触发前必须预存足够拍数据(是/否 radio) | 写 `.hqins` 的 [MEMORY DEPTH INFO]/[ADD REGISTER]/[TRIGGER MULTI-WINDOW]/[TRIGGER LEVEL]（键形如 `0_LA:1024`，按 LA 编号）；「预存拍数」不落盘=布防期运行时参数。CLI 暂未暴露，设计：`-insight -depth N [-windows W] [-level L] [-reg yes|no]`，改后必须 -run+重下载；capture 解析须按 depth/窗口数适配（合法 offset `0 ≤ pos ≤ depth/窗口数−5`，多窗口一次出 N 份 VCD） |
| 📊 波形应用 | 打开 hqwave 波形视图查看已抓 VCD | CLI 等价 `hqbuddy -wave [vcd]` |
| ▶ 运行（调试模式） | 布防→等触发→抓波形→自动开波形 | CLI 等价 `-insight -trig` + `-capture`；背后同一套 `insight.svf_generator.*` |
| ⏸ 停止 | 中止等待触发 | CLI 无对应（Ctrl-C） |
| ↺ 重置 | LA 复制 | 包含在 CLI `-capture` 的布防序列内 |
| ⬇ 下载图标 | 拉起 hqdnload | CLI 等价 `-cable --sealion <bin> --model <板> --Burst` |

## 3. 层次结构浏览器（左上树）——只导航，不加信号

- 三层结构：`ROOT(顶层) → 实例(u_ddrc_operator…) → always块(always_NNN)`
- **always_NNN = 按驱动信号的 always 块分组**（NNN≈所在源码行号）；点节点跳转 src_0 源码对应行
- 搜索框：按信号名过滤，树里显示"包含该信号的模块 → always 块"
- 展开方式：点节点前 ▸ 箭头，或选中后按 **→** 键；`*` 展开全部子树（Qt 惯例）
- ⚠️ **树的 always_* 节点是叶子（双击/右键/拖拽均无效）**：信号添加不在这里！

## 3b. 信号添加/删除/改类型的真实入口：src_0 源码编辑器右键

1. 层次树点 always_NNN（或搜索定位）→ src_0 跳到对应代码行
2. **右键信号 token（LHS）** → 上下文菜单：
   「采样且触发 / 仅采样 / 仅触发 / 采样时钟 / 修改片选 / 取消标记 / 复制信号名称」
3. 点类型即完成添加/改类型；「取消标记」=删除；「修改片选」=总线位选（GUI 的
   slice_msb/slice_lsb 编辑入口）
- 已标记列表里同样右键信号行 → 同款菜单（改类型/取消标记）
- 菜单项建议用 ↓+Enter 键盘选中（鼠标点击坐标易偏差）
- 文件变化：改完点保存（Ctrl+S）→ .hqins 更新（GUI 以紧凑 JSON 重写
  [LA SIGNAL INFO]，data_in_order/trig_in_order 按字母重排；**删除**
  [EXPRESSION OPERATION] 段——CLI 写的这个段会被 GUI 保存移除，属 GUI 行为）

## 4. 已标记信号列表（左下）

| 列 | 含义 | CLI 对应 |
|---|---|---|
| 触发条件 | B0/B1/B0&B1…（组合单元分配）| trigger_cond.json 的 signal_id |
| 信号名称 | 原名（点击选中行=选触发信号）| - |
| 类型 | 采样时钟/仅采样/采样且触发/仅触发 | sample_type: 1/2/4/3 |
| 模块名称 | 所属模块 | module_name |
| 信号使能 ✓ | 勾选=参与采样；去掉=禁用（保留但不采） | disable_list |

- 运行前必须**选中一行触发信号**（否则报"请先选择一个LA触发信号"）
- 「修改」按钮：编辑当前触发条件（对话框：类型=边沿/算术/范围 + 操作数）
- 「触发后直接打开波形」勾选 = 抓完自动弹 hqwave

## 5. 调试模式特有

- 「当前触发条件」面板：显示 C0 表达式（从 trigger_cond.json/trigger_expr.json 读入，
  **与 hqbuddy -trig 写的文件互通**）
- 信息窗口：等待触发中……→ 完成触发（对应 CLI -capture 的轮询输出）
- 波形视图：trigger_event 拉高 ±1 拍 = 触发判定偏斜（CLI VCD 相同）

## 6. 关键文件变化（GUI 操作 ↔ 文件）

| GUI 操作 | 文件变化 |
|---|---|
| 打开工程/加载 | `hqins_run/hq_import.hqins` 读入；`insight.log` |
| 添加/删除信号+保存 | `.hqins` [SIGNAL JSON INFO]（module_sample_list.normal_signals）+ [LA SIGNAL INFO]（la_list.s/t/st_list）|
| 保存 | 触发 `rtl.elaborate -new_rtl` 刷新 `hq_import_with_bscan.v`（CLI: `-add` 时自动做）|
| 保存（组合条件）| `trigger_cond.json`（C0 表达式+操作数）、`trigger_expr.json`（GUI 持久化）、`.ddf`（比较单元）、`.hqins` [EXPRESSION OPERATION] |
| FPGA 实现 | `hqins_run/hq_import/hqins_impl/`：`<工程名>.bin/.bit`、`*_rtl.v`、全套 .rpt |
| 调试运行 | `insight.svf`（运行中存在，结束清空）、`tdo_data.txt`、`<top>_insight_0_ww.vcd`、`gtkwave_0.tcl`；**运行会删除上次调试产物** |
| 采样参数设置 | `.hqins` [MEMORY DEPTH INFO]/[TRIGGER MULTI-WINDOW]/[TRIGGER LEVEL] |

## 7. GUI 与 CLI 协同风险（重要）

- **GUI 保存以内存态覆盖磁盘**：GUI 打开期间用 CLI 增删的信号，GUI 一保存就丢
  （GUI 内存还是打开时的旧状态）。规则：要么全 CLI，要么先关 GUI 再 CLI 改。
- GUI 保存还会把触发条件回退为其内存值、重排 [LA SIGNAL INFO] 顺序、
  删除 [EXPRESSION OPERATION] 段——这些差异不影响功能（各写各的合法状态），
  但 diff 时会看到。

## 8. VLA / MLA（R24 逆向 + GUI 实测，FT091226）

**多 LA 添加入口**：采集模式下已标记信号列表的「+」按钮（LA_0 页旁）——直接创建空
LA_1 页（+src_1 源码视图），无对话框；「−」删除当前 LA；第二个采样时钟在给 LA_1
加信号时指定。关闭窗口会提示保存（取消=放弃内存态）。

**`--vla_cfg <vla.cfg>` 独立启动**（hq_ins 契约之一，is_indep_mode）：从 vla.cfg 导入
整个 VLA 工程——`[DEVICE INFO]`（device_die/device_name）+ `[TRIGGER PARAM]`
（dep/add_reg/pos/ram_full/win_num/trigger_level，多 LA 用 `:` 分隔；`vio_flag=true`
启用 VIO UI）+ `[SIGNAL INFO]`（每行 `信号名=类型=LA序号=模块=位宽=是否片选[=MSB=LSB]`，
类型 ∈ Sample Only/Trigger Only/Sample and Trigger/Sample Clock）。导入时把
trigger_expr.cfg/trigger_cond.cfg 转成 JSON 并删除 .cfg；la_num>1 时自动为每个 LA
建信号页与波形视图。

**MLA 运行时（svf_debugger_run.start_debugger_mla）**：按 LA 逐个布防
（`add_la_reset/add_la_window_num/add_la_offset/add_la_set_trig_cond` 都带
`la_num, la_idx`），状态轮询每 LA 每窗口 `add_la_status_window+add_la_status`
（TDO 长度 = 4×窗口数×LA 数）；`la_opt_list` 掩码决定哪些 LA 参与连续触发不支持
（RE 旧结论）。TCL 族：`insight.sealion.mla.condition_te/offset/reset/status`+`mlas.status`。

**VLA IP 生成链（R34 实测）**：VLA IP 属 ipdepot 的 `vla` 条目
（`build/ipcreator/sup_files/ipdepot/vla/`），由**独立生成器**
`_ipgen_/hq_vla_ins.exe` 产出（`_ipgen_.desc` 注册 `[IPGEN] INDEPENDENT=YES`）。
hqui 欢迎页/流程栏有【VLA调试】【VIO调试】按钮；`insight.check has_vla/has_vio`
TCL 是灰置判据（编译后网表含 VLA 才置 1）。生成器向导需 GUI 收集参数
（VIO 勾选、输入/输出端口数与位宽——tip 009），无参运行挂起待输入，
`ipcreator.exe -gen <VLA.xml>` 亦静默无产物 → **CLI 生成 VLA IP 尚不可行**，
下一步需 GUI 向导跑一次并抓取其命令行/产物（Procmon 或 wmic）拿到
hq_vla_ins.exe 的真实调用格式。

**VLA 生成器命令行契约（R34b 实测捕获）**：IP Creator 里双击 VLA → 创建对话框
（模块名 VLA / 文件名 xsIP_VLA.v / 输出 ipcore_dir/VLA）→ 确定 后调起：

```
hq_vla_ins.exe -device <part> -lang chs -output_module VLA -output_fname xsIP_VLA.v   -output_dir <ipcore_dir/VLA> -hq_exe <hqfpga.exe>
```

该进程弹出配置向导（信号个数[1..512]/采样深度/加寄存/触发窗口/预存拍数 128/
使用VIO/直接输出综合网表☑/触发级数），确定后产出四件套：
- `xsIP_VLA.v`（102KB 完整 insight 核心 RTL，参数在头部综合属性：
  `/* synthesis HQ_VLA0 = "dep=1024 add_reg=True pos=128 ram_full=False win_num=1
  trigger_level=1 probe0=1=0 " */`——第三方综合靠它把配置带进 EDIF）
- `xsIP_VLA.hqip`（INI：LA_NUM / VLA_0={probe_num, sample_depth, window_num,
  add_reg, trig_pos, ram_full, generate_net, trigger_level, probe_port_N:宽:类型}）
- `xsIP_VLA.cfg`（has_vio / dbg_module_name）
- `t.tcl`（IP 自身综合链：design.analyze→rtlsyn→tdomap -no_ioins→nl.write）

**CLI 化路径已打通一半**（R36b：`hqbuddy -vla -gen` 已上线——按下方契约调起
向导并自动检测产物；全自动模板化仍在 TODO）：hqbuddy 可按此契约调起向导（半自动），或仿 vio.py
内嵌模板直接生成 .v（属性行参数化）——probe 端口定义在向导"信号"页收集，
模板化时需解析 hqip 的 probe_port_N。

**CLI 可行性设计（未实现，按序）**：
1. `-depth/-windows/-level/-reg`（R22 设计，.hqins 四段键已明）——改后必须 -run+重下载；
2. MLA：`-add -la 1 ...`（LA_1 信号集）；触发/布防/capture 按 la_num 循环，
   VCD 按 LA 输出；前置：插桩流程需产出多 LA bit（hqprj2hqins_flow 的 la_list
   双条目是否足够待验证——这是 MLA 的第一个板上实验）；
3. VLA（VIO+LA 同 bit）：编译侧走 vla.cfg（hqbuddy 生成 cfg + 调 flow）；
   运行侧 vio_read/vio_write 加 `-is_vla_mode True` + LA 布防传 `vio_out_value`——
   hqbuddy 的 vio.py 已复用 svf_generator，改造量集中在编译流程编排。

## 9. 硬件限制（GUI 与 CLI 同）

- **一个 LA 只支持一个采样时钟**；跨时钟域信号采样无意义
- 一个 JTAG 调试槽：VIO+LA 不能同 bit（PHY-PLA-665 JTAG capacity overflow）
- 每个触发信号一个比较单元：同信号 AND 链不可表达（CLI 已自动折叠/报错）
- 组合触发表达式：扁平 AND/OR 链 + 单元取反 + 整体取反；无括号嵌套
