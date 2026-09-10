# HqInsight GUI 地图（采集模式 / 调试模式 全控件梳理）

> 基于 HqFpga 3.1.1 Build 090926 实测 + 反编译（FT090526/090926 逻辑零差异）。
> "文件变化"列 = 该操作在工程目录产生的实际文件写入（git diff 实证）。

## 0. 两种模式（核心概念）

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
| ⚙ 采样参数 | 弹「采样参数设置」：采样深度(1024/2048/…)、触发窗口个数、触发次数、触发首次条件满足时的拍数据(是/否) | 写 `.hqins` 的 [MEMORY DEPTH INFO]/[TRIGGER MULTI-WINDOW]/[TRIGGER LEVEL]；CLI 暂未暴露（固定 1024/1/1） |
| 📊 波形应用 | 打开 hqwave 波形视图查看已抓 VCD | CLI 等价 `hqbuddy -wave [vcd]` |
| ▶ 运行（调试模式） | 布防→等触发→抓波形→自动开波形 | CLI 等价 `-insight -trig` + `-capture`；背后同一套 `insight.svf_generator.*` |
| ⏸ 停止 | 中止等待触发 | CLI 无对应（Ctrl-C） |
| ↺ 重置 | LA 复制 | 包含在 CLI `-capture` 的布防序列内 |
| ⬇ 下载图标 | 拉起 hqdnload | CLI 等价 `-cable --sealion <bin> --model <板> --Burst` |

## 3. 层次结构浏览器（左上树）

- 三层结构：`ROOT(顶层) → 实例(u_ddrc_operator…) → always块(always_NNN)`
- **always_NNN = 按驱动信号的 always 块分组**（NNN≈所在源码行号）；点节点跳转 src_0 源码对应行
- 搜索框：按信号名过滤，树里显示"包含该信号的模块 → always 块"
- 展开方式：点节点前 ▸ 箭头，或选中后按 **→** 键；`*` 展开全部子树（Qt 惯例）
- **信号叶子在 always 块下**：叶子即信号本体，双击/右键加入已标记列表

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

## 7. 硬件限制（GUI 与 CLI 同）

- **一个 LA 只支持一个采样时钟**；跨时钟域信号采样无意义
- 一个 JTAG 调试槽：VIO+LA 不能同 bit（PHY-PLA-665 JTAG capacity overflow）
- 每个触发信号一个比较单元：同信号 AND 链不可表达（CLI 已自动折叠/报错）
- 组合触发表达式：扁平 AND/OR 链 + 单元取反 + 整体取反；无括号嵌套
