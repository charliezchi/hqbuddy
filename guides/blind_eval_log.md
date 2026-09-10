# hqbuddy insight 盲评日志

> 每轮：任务 → 实现/结果 → 发现的问题 → 修复 → 复验。循环至"从零创建工程、
> 任意多模块层次信号增删改、与 GUI 一致、触发抓波形指哪儿打哪儿"。

## Round 1 — 从零心跳灯全链路（评分制 125 分）
- **任务**：空目录从零建工程（VIO+心跳设计）→ 实现 → 下载 → VIO 读/写验收 →
  HqInsight 插桩 → 组合触发 → 抓波形 → 分析
- **结果**：✅ 全链路完成，自评 125/125；VIO 读到 0xA5→…→0x5A 旋转环，
  触发时刻 burst_cnt_rd=0x0B
- **发现的问题**：
  1. `_is_combined_trigger ==2`：3+ 条件静默降级单条件 → 已修 `>=2`
  2. `-vio -gen` 的 `-I` 参数在新版失效 → 改用规范 `-O`
  3. VIO 探针打包位序文档错误 → 板级回归确认 GUI 原规则正确，改回
  4. `-report` WNS 混算 setup/hold → 分列修复
  5. insight `-run`/`-build` 产物校验缺失（流程 exit 0 但 bitgen 失败）→ 新 bin 校验
- **验证**：修复后 VIO 读回归 ✓

## Round 2 — 多条件组合触发值校验（cli_gui_cmp 确定性计数器）
- **任务**：5 个组合触发用例各 2 次，校验触发点 sig 值严格满足条件
- **结果**：❌ 4/5 FAIL —— 同信号 AND 链恒真乱触发（pointer=4，触发值随机）；
  OR 链、NOT+AND、单条件 PASS
- **发现的问题**：
  1. Round-1 矩阵只验"触发快"没验"触发值满足条件"——恒真被误判通过
  2. cwd 根因确认：GUI 会话 cwd=hqins_run，hqbuddy 用工程根 → 操作数比较值
     丢失（GUI 正确载荷含 0x5A，hqbuddy 同位为 0）
- **修复**：run_capture 的 4 个 SVF 会话 cwd 改为 hqins_dir
- **验证**：heartbeat 构建 CLI 触发精确命中 hb_tick↑ ∧ heartbeat==0x5A ✓

## Round 3 — 组合触发修复复验（双工程）
- **任务**：cmp 工程 5 用例（含回绕边界）+ heartbeat 工程 1 用例，每用例 2 次
- **结果**：❌ cmp 同信号 AND 仍失败（第二条件覆盖第一：触发值全非零=NE0 生效；
  混用 NOT 触发在被排除值 0x0000=取反错传播）；OR/跨信号 PASS
- **发现的问题**：**硬件每信号仅一个比较单元**——同信号 AND 链硬件层面不可表达，
  非软件 bug；NE+NE、混 NOT 等组合也都不可能
- **修复**：`collapse_same_signal` —— 同信号 AND 条件自动折叠为语义等价单条件
  （EQ&NE→EQ、RANGE 求交集、RISE&FALL→BOTH），矛盾/不可表达直接报错+改写建议；
  OR 链不折叠（板级验证可用）
- **验证**：单测 8 用例全过 ✓

## Round 4 — 单采样时钟约束 + 新版 HqFPGA (FT090926) + 新板 SA5Z-50
- **任务**：fifo 工程（ddrc_operator_fifo[1]/usr_clk 域）加跨时钟域信号
- **结果**：❌ 跨时钟域 -add 创建第二采样时钟 → `rtl.elaborate -new_rtl` 失败
  （用户点破：调试只能有一个采样时钟）
- **发现的问题**：
  1. hqbuddy 允许多采样时钟条目，硬件不支持 → 加密失败且报错晦涩
  2. 产物校验按顶层名找 bin（实际按工程名）→ 漏报
- **修复**：`-add` 强制单采样时钟（第二时钟条目直接拒绝+清晰提示）；
  产物校验改为 glob 任意新 bin
- **验证**：同钟添加 ✓、跨钟拒绝文案清晰 ✓；e2e：FT090926 + SA5Z-50 新板
  插桩→下载→跨信号 AND 触发（usr_dr_re_dly RISE ∩ init_done NE 0）✓；
  `wl_err NE 0` 不触发为正确行为（健康 DDR 无写长错误）

## Round 5+ — 待进行（进行中…）
- 计划用例池：
  - A. 从零创建 hqinsight 工程（新空目录 + 模板工程）全链路
  - B. 任意层级信号增删改（跨多模块、多 always 块、含总线片选）
  - C. 组合触发边界（OR+NOT 混合、RANGE 交集、回绕、跨时钟拒绝）
  - D. 抓波形质量（深度/偏斜/连续性校验）
  - E. VIO 读写回归
  - F. -report 摘要正确性
  - G. 错误路径（bit 过期、跨时钟、矛盾条件）的提示质量
- 每轮 3-5 个用例，子 agent 独立判读；FAIL 项进入修复清单
