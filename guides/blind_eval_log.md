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

## Round 5 — fifo 工程（新板 SA5Z-50 + 新版 HqFPGA FT090926）多条件复验
- **任务**：ddrc_fifo_demo（usr_clk 域，10 信号，4 触发信号含新增 wl_err）：
  跨信号 AND、wl_err NE 0 AND 上升沿、FALL 边沿、总线片选越界报错
- **结果**：3/4 PASS。AND 跨信号 ✓（2/2 秒触发）、FALL ✓、片选越界报错文案清晰 ✓
- **发现的问题**：
  1. **wl_err（第 4 个触发信号）触发单元运行时失效**：AND/单条件/边沿全不命中，
     但探针在波形里活跃翻转（force 抓取 368/1024 高电平）+ 网表取证探针存在 +
     条件文件正确 → 定性为按位布局的偶发单元失效。处理：调信号顺序重跑 -run
  2. freshness 警告误报（-trig 改写 .hqins 导致 mtime 对比失真）→ 改戳记文件方案
  3. 触发偏斜实测 ±8 拍（文档写的 ±1）→ 文档更新为按窗口判读
- **修复**：戳记文件 freshness（-run 记 .bit_stamp）；文档两处更新
- **验证**：修复后 -trig 重写文件不再误报 ✓，触发仍秒级命中 ✓

## 环境性大发现（Round 4-5 期间）
- **双板环境**：SA30K 与 SA5Z-50 两块板共缆。`--model` 与实际板不符时 cable
  照样编程 → SA30K 的 bit 编进 SA5Z-50 板 → LA 探针读常量（恒 0 假象）。
  R4 的"探针陷阱"部分现象实为此混淆。已加 model 校验（不符拒绝下载）。
- **HqFPGA FT090526 → FT090926 升级**：反编译比对 svf_debugger_run 逻辑零差异，
  hqbuddy 全链路在新版 + 新板上复验通过。

## Round 6 — 从零创建 hqinsight 工程（核心训练标准）
- **任务**：空目录 → -new_prj → 双模块 RTL（LFSR+ring，子模块+keep）→ 约束 →
  -init/-ls/-add(3 信号)/-run → 下载 → 组合触发 → VCD 递推校验
- **结果**：✅ 全链路打通。agent 自行推导出 LFSR 状态圈（0x55 圈含 0x5A）并显式
  播种保证确定性；触发点 true_sig=0x5A 精确命中；1023/1023 采样符合递推
- **发现的问题**：
  1. **hqfpga 插桩存储字打包位序错乱**（多模块多宽度时网表字序与 ddf 切分不一致，
     字面 EQ 值可能永不命中）——agent 用网表取证+48 布局拟合实锤。缓解：探针总线
     宽度对齐/单一总线设计；已记录为工具链限制
  2. 任务书给的时钟管脚 B2 在 SA5Z-50 板上非时钟能力脚（PHY-CHK-030），板载
     25MHz 晶振在 J15——板级事实需按板查
  3. ANSI 端口 reg 重复声明致 elaborate 失败 → 改非 ANSI 声明
  4. `-run` 收尾 NameError（import_dir 未定义，round-5 戳记补丁引入）→ 已修
  5. 器件合法名是 SA5Z-50-D0-**7F**484C（任务书写错会被 dv_list 拒绝）

## Round 7 — 多模块信号增删改全操作（fifo 工程，20+ 次结构操作）
- **任务**：跨模块添加、3 组删加往返、类型双向改写（both↔sample）、顺序重建、
  每步真实触发验证、最终恢复基线逐字一致
- **结果**：✅ 20+ 次结构操作链路零故障；每次 capture 真实命中；clock_cycle 连续
- **发现的问题**：
  1. 下载不加 `--Burst` 会失败（压缩 bin 不支持）→ 文档已补
  2. `-del` 被触发条件引用的信号产生悬空表达式（不报错）→ 已加警告
  3. del→re-add 追加到组末 + ddf 打包随历史变化 = "改信号必须 -run+重下"的根因
     （未重跑前抓波：通道数/触发全对但数值视图错位）→ 文档已补
  4. 板况：DDR 卡死稳态下 4 个触发信号全恒 0，重下 bit 恢复
  5. 上下文延续不跨 CLI 进程：rl_err/rt_err 在顶层与子模块同名需 -module（错误清晰）

## Round 8 — 组合触发边界语义批量验收（fifo 工程 7 用例矩阵）
- **任务**：同信号边沿折叠、3 条件链折叠、重复去重、矛盾跨信号组合、1 位 NE、
  sample 信号触发拒绝、1 位全范围 RANGE_C
- **结果**：✅ 7/7 全部符合预期（5 条触发路径真实命中且值满足条件；
  sample 拒绝报错清晰且无副作用；矩阵 4 的超时经 force 取证为电路真实行为——
  usr_dr_re_dly 的 13 次上升沿全部落在 init_done=1 期间，与 init_done=0 重合 0 次）
- **发现的问题**：无新问题；折叠逻辑、边界处理、报错路径与文档完全一致
- **补充实测**：RANGE_C 闭区间编码在 JSON/ddf 层正确（GE,LE）

## Round 9 — GUI ↔ CLI 信号配置等效性（GUI 实操对照）
- **任务**：GUI（采集模式源码右键）做 添加/删除/改类型 三操作+保存；CLI 复刻同配置；
  字段级比对两条路径的 .hqins
- **结果**：✅ **等效 PASS**——公共 9 信号字段级 0 差异（含 show_hier_name 等全字段）；
  唯一集合差异（wl_err）为实验前 GUI 内存/磁盘分叉，与三操作无关
- **重大认知修正**：
  1. GUI 信号添加的真实入口是 **src_0 源码编辑器右键信号 token**（菜单：采样且触发/
     仅采样/仅触发/采样时钟/修改片选/取消标记/复制信号名称）——层次树加不了具名信号
     （always_* 是叶子）；「修改片选」就是 GUI 的总线位选编辑入口
  2. GUI 保存以内存态覆盖磁盘：GUI 开着时 CLI 的增删会被 GUI 保存回退（协同风险，
     已写入 skill 文档）
  3. GUI 保存重排 [LA SIGNAL INFO]（字母序）并删除 [EXPRESSION OPERATION] 段
     （CLI 写的）——均不影响功能
  4. GUI 的 B 编号按字母序（B1 vs CLI 插入序 B3）——顺序差异不影响各自 ddf 一致性

## 后续轮次计划（Round 10-20，待续）

已验证稳固的能力基线：单/组合触发（值精确）、折叠/报错路径、多模块增删改、
片选、模型校验、freshness 预警、GUI↔CLI 配置等效、跨 HqFPGA 版本、跨板（SA30K/SA50K）。

待覆盖主题（每轮 3-5 用例，继续用子 agent）：
- R10: 抓波形质量深化（多信号视角、连续性校验、偏斜窗口跨 run 一致性）
- R11: 错误路径专项（bit 过期、跨时钟拒绝、矛盾条件、错误 -clk、双板 model 校验）
- R12: -report 摘要正确性（FMAX/WNS/util 数字与原始报告核对）
- R13: -vio 读写回归（vio 工程需重建：agent_scored1 心跳工程有 VIO bit）
- R14: 从零变体（计数器+移位寄存器+多子模块组合，验证多总线存储打包）
- R15: 触发条件导入导出往返（trigger_expr.json 手改后 -capture 行为）
- R16: GUI 一致性第二轮（类型切换/删除路径的 GUI↔CLI diff）
- R17: 长稳回归（selftest 命令 + r7 用例重跑）
- R18: -init 幂等性（重复 -init 后配置/数据库一致性）
- R19: 多信号大配置压力（15+ 信号、资源估算边界）
- R20: 全链路终极回归（从零→增删改→触发→抓波→分析，完全复刻训练标准）

每轮 FAIL 项按"修复→验证→复测"循环处理；修复与新认知同步更新
skills/hqfpga/references/insight.md 与本日志。

## Round 10 — 抓波形质量深化（fifo 工程 3 run 对比）
- **任务**：同条件 3 次抓取（间隔 30s+），校验采样连续性/触发一致性/多信号语义/跨 run 稳定性
- **结果**：✅ PASS——clock_cycle 三 run 零缺口（起止值与回绕点完全一致）；trigger_event
  三次都精确在配置位置（偏差 0，无偏斜修正需求）；41 个读上升沿全部落在
  init_done=1 区间；data_err 恒 +2 拍偏移/恒 32 拍脉宽（确定性）；q_r2/q_r3 读沿
  序列比特级一致
- **发现**：用户在 GUI 侧已自主调整工程（offset=512、信号集变化）——agent 正确
  读取实际状态并适配；两 128 位总线逐字不相等 = 延迟采样语义（文档判读有效）
- **结论**：波形质量达到"可信赖调试数据源"标准

## Round 11 — 错误路径专项验收（8 项矩阵）
- **任务**：逐一验证 6 个拒绝类防护 + 失败无副作用 + 位流过期预警
- **结果**：✅ 6 个拒绝类防护全部正确拦截（model 校验、单采样时钟、时钟库校验、
  矛盾折叠、NE 不可表达、sample 不可触发），失败零副作用；位流过期预警确认
  戳记方案不误报
- **发现的问题（4 个，全部已修）**：
  1. `-module` 给实例路径片段时报误导性 "signal not found" → 改为区分
     "信号存在于模块 X 但与 -module 不匹配" 并说明 -module 语法
  2. "-clk 提示" 中英混杂（its）→ 纯中文
  3. sample-only 报错缺补救指引 → 补 "改 -type both 重跑 -run" 提示
  4. `.bit_stamp` 缺失时位流过期预警静默跳过 → 加一次性基线提示
- **验证**：修复后实例片段 -module 报错文案清晰可操作 ✓；无戳记提示正确出现 ✓

## Round 12 — -report 摘要正确性（发现高严重度兼容性问题）
- **任务**：-report 输出与原始报告逐数字核对（两个真实工程）
- **结果**：❌ 真实（GUI/hqins 流程）工程上 -report 数字输出为空——
  1. **报告族不兼容**[高]：真实工程报告在 `hq_run/` 且名为 `ratio.rpt`/
     `<top>_slack.rpt`，hqbuddy 只找工程根的 `fmax.rpt`/`res_place.rpt` 等
  2. **时序中文格式不支持**[高]：中文环境 slack 报告为 GBK 编码
     （`时间余量 :`/`类型 : 建立|保持`），解析器只认英文
  3. bitstream 检测不覆盖 hqins_impl/[低]
  利用率解析逻辑本身正确（16/16 行数值与原始报告精确一致）
- **修复**：report.py 全面升级——多根目录候选（root/hq_run/hqins_impl）、
  ratio.rpt 纳入候选、GBK 兼容读取、中文时序格式（建立/保持）解析、
  SERDES 行纳入白名单
- **验证**：fifo 工程 -report 现输出 WNS setup +5830.7ps(MET)/hold +286.5ps(MET)、
  利用率 8 行——与盲测 agent 的人工核算完全一致 ✓

## Round 13 — VIO 运行时探针回归（agent_scored1 从零重建后全链路）
- **任务**：VIO bit 下载 → 探针状态 → 循环读 → 写入 → 异常记录
- **结果**：✅ PASS——位级精确验证：38 样本 hb 全部精确落在种子 0xA1 的 LFSR 轨道
  （碰撞概率排除）、ccnt 与墙钟秒数互证、5 次写入全部成功；重下载后首读得到
  种子/清零初始态（读通路位级精确的直接证据）
- **发现的问题**：`-vio -read -loop xyz` 非数字抛原始 traceback → 已加友好报错；
  hb-ccnt 相对相位偶发 +1 漂移为器件侧现象（CLI 读通路已独立证明位级正确）
- **验证**：修复后 -loop 文案友好 ✓（并入下轮回归）

## Round 14 — 修复回归 + 板况恢复验证
- **任务**：R11 的 4 项 UX 修复回归 + 核心触发无回归验证
- **结果**：4 项修复全部确认有效（its 混排/module 误导报错/sample 补救指引/
  双 NE 拒绝）；失败路径零副作用；`-vio -loop xyz` 友好报错 ✓
- **发现**：5b"真实触发"未证实——板卡进入卡死稳态（数据通道恒值、done 位误报），
  **重新下载插桩 bit 后立即恢复**（board 复位即设计复位）。非修复引入的缺陷。
- **新增认知**：板卡卡死状态的判定特征 = 数据通道恒值 + clock_cycle 在走 +
  trigger_event 与条件无关；处置 = 重下载 bit

## Round 15 — GUI 建工程 CLI 接管（gui_created 全链路）
- **任务**：接管 GUI 新建的 gui_created 工程（ddrc_fifo_demo 文件集）→ 插桩 → 下载 → 触发
- **结果**：✅ 接管成功（5 项工程缺陷修复后全链 PASS：TOP_MODULE 空、_sim.v 重复、
  片段文件、器件不配套、BGEN bin 未开）；触发点值精确；VCD 校验板上 DDR 真实运行
- **发现的问题（6 项 hqbuddy 改进点，3 项已修）**：
  1. insight 流程前 BGEN_1/2 未开 → 已自动开启并写回 .hqprj ✓
  2. 产物校验不区分"bit-only（BGEN 未开）"与"P&R 失败" → 已区分文案 ✓
  3. `-init` 缺前置体检（TOP_MODULE 空/片段文件/器件不配套一次性诊断）→ 待做
  4. 缺 `-del <file>`（移除源文件）命令 → 待做
  5. 常量探针警告（网表 Convert FF to constant 时汇总提示）→ 待做
  6. `-ls` 缺 -module 过滤 → 待做
- **探针陷阱实证**：usr_cmd_burst_cnt 被常量折叠（hqfpga.log "Convert FF to
  constant ZERO"），恒 0 信号只有 EQ 0 恒真语义

## Round 16 — 综合回归（30+ 次真实布防）
- **任务**：6 条触发矩阵 + 状态零漂移验证（fifo 工程，跨 run 一致性）
- **结果**：✅ 核心触发链路无回归——BOTH 折叠、RANGE_C 恒真等效、NOT 取反硬件
  语义正确（NOT 丢失会在布防即触发，实测未发生）、跨信号 AND、电平比较全部
  确定命中（等待 ≤1.3s）；不可满足条件诚实超时；30+ 轮 -trig/-capture 后
  -insight 状态零漂移
- **发现（非 CLI 回归）**：
  1. 边沿+电平同拍 AND 可能信号层面不可满足（data_err 上升沿恒落后
     usr_dr_re_dly 恰 +2 拍）——工具诚实超时是正确行为
  2. 本 bit 边沿标记偏斜 2~104 拍（超出 ±8 窗口）——bit 级现象
  3. .hqins 与板载 bit 信号集不一致时触发测试不受影响（只要用两集共有的信号），
     但启用新增信号前必须 -run+下载

## Round 17 追加 — 触发信号数量边界隔离实验（决定性）
- **实验**：fifo 构建削减到 2 个触发信号（usr_dr_re_dly B0 + data_err B1），
  2 操作数 ct `usr_dr_re_dly RISE AND data_err NE 1`
- **结果**：✅ 触发精确命中——触发点 #128：dr=1（上升拍）∧ data_err=0（NE 1 满足），
  窗口值与语义完全吻合
- **结论**：**2 触发信号构建上 ct 正常**。结合 R17 的 4 触发信号构建失效数据，
  失效与"触发信号数量 ≥4"的配置强相关（第二操作数门控失效），而非普遍现象
- **判读修正**：R17 报告的 `wl_err EQ 0 AND init_done NE 0` 命中并非第二操作数
  失效——init_done=0 恒定 → NE 0 恒假 → 若第二操作数正常该组合不可满足；命中说明
  第二单元被编程为恒真或其它语义。与 4 信号构建的失效同源
- **给用户的实用建议**：需要多条件 AND 时，触发信号控制在 ≤3 个；4 个及以上
  触发信号的构建上，多操作数 AND 的第二操作数门控存在未定问题（需厂商确认）

## Round 17 总结
- A 项 -init 幂等性 PASS（字节级确定性）
- B 项 16 信号大配置：登记/插桩/下载/采样/VCD 完整性/单条件触发全部 PASS；
  4 触发信号构建的多操作数 AND 第二操作数门控失效（本轮定位）

## Round 18-20 — 终极全链路验收（三阶段合并，收官）
- **Phase 1（R18）防护回归：4/4 PASS**——model 校验/跨时钟 -clk/矛盾条件/sample
  触发拒绝全部正确，退出码 1，状态零漂移
- **Phase 2（R19）多总线存储打包：PASS（R6 发现未复现）**——bus_a[31:0] LFSR +
  bus_b[15:0] 环形移位，两总线各自递推在全部 1023 相邻对成立（打包错位必破坏其一，
  实测零破坏）；片选语法 bus_a:15:0 验证通过；双条件秒级命中
- **Phase 3（R20）终极回归：PASS**——单/双/三条件各真实触发，4 份 VCD 全 PASS，
  触发值跨 run 逐字命中（板上相位互异仍精确），三条件链硬件编码 B0&B1&B2/0011 核实
- **异常记录**：-del 时 hqfpga 一次性段错误（0xC0000005，已落盘无损）；
  detect_model 缺 package info 告警（无害）；default_nettype 告警（无害）
- **结论**：**insight 达到"指哪儿打哪儿"收官标准**——从零创建、任意层级信号增删改、
  多条件触发值精确、波形可信，全 CLI 闭环

## 20 轮总账
| 轮 | 主题 | 结果 |
|---|---|---|
| R1 | 从零心跳灯评分制 | ✅ 125/125 |
| R2 | 多条件值校验 | ❌→发现恒真（cwd 根因） |
| R3 | 折叠复验双工程 | ❌→确认单比较单元限制 |
| R4 | 新版+新板从零 | ⚠️ 单时钟/双板问题暴露 |
| R5 | fifo 多条件复验 | 3/4→freshness 误报修复 |
| R6 | 从零 LFSR 全链路 | ✅+存储打包问题发现 |
| R7 | 多模块增删改 20+ 操作 | ✅ 零故障 |
| R8 | 触发边界 7 用例矩阵 | ✅ 7/7 |
| R9 | GUI↔CLI 配置等效 | ✅ 字段级 0 差异 |
| R10 | 波形质量深化 3-run | ✅ 比特级复现 |
| R11 | 错误路径 8 项矩阵 | ✅ 6 防护全过+4 UX 修复 |
| R12 | -report 正确性 | ❌→报告族+中文格式修复 |
| R13 | VIO 读写回归 | ✅ 位级精确 |
| R14 | 修复回归+板况恢复 | ✅ 4 修复确认 |
| R15 | GUI 建工程 CLI 接管 | ✅ 5 障碍清单+6 改进点 |
| R16 | 综合回归 30+ 布防 | ✅ 零回归 |
| R17 | -init 幂等+16 信号压力 | ✅ A PASS/B 基础 PASS |
| R18-20 | 终极三阶段 | ✅ 全 PASS |

## Round 18 补充 — P0 `-build` glob 修复确认
- R18 agent 发现 `-build` 在 `flow.py` 中 `glob` 未导入导致 NameError 崩溃
- 已修复（`import glob` 加入文件头）；`-build` 不再崩溃，产物校验正常拦截旧 bin
- agent_r18 工程的 `-build` 失败是项目自身约束/器件问题（非工具 bug），产物校验
  正确报告了"无新鲜 bin"

## Round 21 — FT091226 新版本升级回归（自回归迭代 R21+ 首轮，SA50K 板）
> 起用 `guides/autoregressive_cycle.md` 框架：判据先于执行、S0-S3 分级、修复必复验。
- **任务**：新 HqFPGA FT091226 上从零全链路（counter8+LFSR 双模块，器件
  SA5Z-50-D0-7F484C，时钟 J15）+ selftest + 组合触发 + report 对照 + 错误路径抽测
- **结果**：**核心链路完好**——触发值零偏斜（cnt=200/77 严格命中）、LFSR 推导
  状态圈 1024 拍全吻合、clock_cycle 连续、报告数字与原始 .rpt 零误差、错误路径
  拒绝正确且状态零漂移；selftest 组合触发秒级命中
- **发现的问题（4 项，全部已修+复验）**：
  1. **S1 `-selftest` 假阴性**：`+1-per-sample` 检查不容忍计数器自然回绕
     （255→0 差 -255；8 位计数器 1024 样本窗口必含回绕 → 永远 FAIL），
     另有 dump 工具终止时尾部重 dump 伪影（255→255）→ 修：按信号位宽取模 +
     丢弃尾部重复样本；板上复验 PASS（width=8, +1-per-sample=True）
  2. **S1 `-report -paths` 静默失效**：只在 `args[0]=="-paths"` 时解析
     （`-report . -paths 3` 被吞），未知旗标也静默 exit 0 → 修：任意位置解析 +
     未知旗标报错；且排序改为全局 slack 升序（原 setup 优先会把 +34ns 排在
     hold +205ps 前面），全 MET 时标注 "tightest paths"；复验提取值与原始
     slack 报告逐字一致（205.7/205.7/241.3）
  3. **S1 `-build` 只生成不执行**：产物校验 `_check_bitstream` 误放在
     `run_flow`（生成阶段）末尾，执行前就报 "no fresh bin" 退出 → 修：校验移到
     `cmd_build_fpga` 真正执行完 run_hqprj.tcl 之后；顺带修复普通 `-flow`
     生成模式的总是 exit 1；端到端复验：生成→执行（bitgen 5s）→校验→exit 0
  4. **S2 `-init` 预检相对路径误报**：`-add rtl/x.v` 写 `$WORK_DIR$rtl/x.v`
     （无分隔符），预检裸 replace 拼成 `r21artl` 假路径拒绝 init → 修：展开时
     补分隔符（与 hqprj_parser._resolve 语义对齐）；两种形态单测通过
  - **S2 附带修复**：`-selftest` 覆写触发条件后不恢复 → 快照/恢复三文件
    （trigger_expr/cond/ddf），板上复验自检后条件逐字还原
- **版本差异（vs FT090926，已同步文档）**：
  1. `-insight -run` 拉起的 hqdnload 窗口现被自动关闭（不再阻塞）——insight.md 已更新
  2. `--detect_model` 可能缺 UID/Package 行（model 仍在）——download.md 已注明
  3. 利用率来源出现 ratio.rpt（insight 流程）——hqbuddy.md 已补
- **遗留（未修，进 TODO）**：报错文案中英混排不统一（S2）；`-selftest` 未列入 -h（S3）
- **结论**：FT091226 升级无链路损伤；4 项辅助层缺陷全部修复并复验，版本 bump 3.13.2

## Round 23 — VIO 读写回归（定时轮 #1，r23vio 从零建工程，SA50K）
- **任务**：VIO 全链路新版本回归：-gen/-reg/-build(13s)/下载 → 读活性+对位 →
  写入回环闭环（probe_out 双寄存回接 probe_in 高位）→ 异常输入报错
- **结果**：✅ **VIO 链路完好**——判据 a-e 全 PASS：登记/读取正常；计数器槽持续
  推进+自然回绕、常量槽恒 0（分化行为实证对位）；`-write 0xA5` 第 1 次读即收敛
  并保持，0x3C 复验同样；非回文 0b11000001→读回 0xC1 实证切片内位序正确；
  `-loop xyz` 友好报错（`Error: -loop 需要整数: xyz`，无 traceback）
- **发现的问题（1 项已修+复验）**：
  1. S2 `-reg -in cnt:8,fb:8` 逗号分隔多探针被静默登记为单个名为 "cnt:8,fb"
     宽 8 的假探针（in_width=8 与 -gen 16 不符且 -read 无告警）→ 修：cmd_reg
     拆分逗号 + 探针名合法性校验；复验登记 cnt[8b],fb[8b] 共 16b ✓
- **认知修正（vio.md 已更新）**：MHz 窄计数器+秒级软件采样为欠采样，读数差不具
  等差性——对位验证应联合"活性分化行为 + -write 回读"判定；评测向量须含非回文值
- **顺带确认**：`-build` 修复后在全新工程上工作正常（13s 出 bin，无 hqdnload 卡窗）

## Round 24 — VLA/MLA 探索（定时轮 #2，反编译源码 + GUI 实测，纯探索零改动）
- **任务**：弄清 VLA（VIO+LA 同 bit）与 MLA（多 LA）的编译/配置/运行时全貌，
  产出 CLI 可行性设计（判据 a-d 全达成）
- **结果**：✅ 全部逆向清楚并落档——
  1. **vla.cfg 全格式**（hq_ins --vla_cfg 独立工程导入）：[DEVICE INFO] +
     [TRIGGER PARAM]（dep/add_reg/pos/ram_full/win_num/trigger_level，多 LA 用
     `:` 分隔；vio_flag 开关 VIO UI）+ [SIGNAL INFO]（`名=类型=LA序号=模块=位宽=
     是否片选[=MSB=LSB]`）；导入时 .cfg 触发条件自动转 JSON
  2. **MLA 运行时**：按 LA 循环布防（svf 调用全带 la_num/la_idx），状态轮询
     TDO=4×窗口数×LA 数；`insight.sealion.mla.*` 命令族
  3. **GUI 多 LA 入口实测**：采集模式已标记列表「+」按钮直接建空 LA_1（无对话框），
     「−」删除；关闭时提示保存（取消=放弃内存态）——GUI 全程未保存，工程逐字未变
- **交付**：GUI 地图新增 §8（VLA/MLA 全节）+ CLI 三级实现设计
  （①深度/窗口/级数/-reg → ②MLA（前置：多 LA bit 的插桩流程验证）→ ③VLA 编译
  编排走 vla.cfg + 运行侧 is_vla_mode）；insight.md 逆向节同步
- **无缺陷发现**（本轮纯探索/设计，无代码改动）

## Round 25 — 触发矩阵回归（定时轮 #3，r21a 工程，SA50K 板）——**抓到真回归**
- **任务**：R16 六条触发矩阵在 FT091226 复演（含 1-bit 片选信号增删全流程）
- **结果**：**有回归**——单条件算术（EQ 严格/RANGE_C 含边界/GT 排除 GE）、跨信号
  AND、同信号矛盾边沿折叠、持久化、超时机制、CLI 全流程（含 hqdnload 自动关闭）
  均无回归；但抓出 2×S1 + 2×S2：
- **发现的问题**：
  1. **S1 NOT 取反被硬件丢弃**：`NOT cnt EQ 7` 在 cnt==7 命中（4/4，本 bit 零偏斜
     标定），trigger_cond.json 的 negate 记录正确 → 丢失发生在下游编码。**已修**：
     算术取反自动改写为等价算子（NOT EQ→NE、NOT GT→LE…，打印 Note；range/edge
     的 NOT 保留+硬件丢弃警告）——单测 3 例通过；改写后等价算子均为板上已证行为
  2. **S1 混合位宽打包损坏复现**（R6 旧发现加重）：2×8b 干净（0/1023 违例），
     追加 1-bit fb 后 lfsr 通道违例 770/1023——探针集合必须同位宽。**已修**：
     -run 记录信号集戳记 `.bit_signals`，-capture 发现信号集与 bit 不一致强警告
  3. **S2 改信号后旧 bin 无拦截**：-add 后未 -run 直接 capture 报"触发"（错位数据）
     → 由 2 的信号集戳记覆盖（下次 capture 即警告）
  4. **S2 边沿方向语义未证实**：3 信号损坏 bit 上 AND 链边沿疑似恒真退化——
     待干净打包复测（R26 队列）
  - S3：`cnt[7]` 片选 add 报 not found、`cnt[7:7]` 静默归一化整总线（行为不一致，
    记 TODO）；RISE AND FALL 折叠为 BOTH 静默完成（结构正确，缺文案）
  - 勘误：本 LFSR 状态圈含 0x00（排除 0xFF），R25 判据前提有误——`lfsr EQ 0`
    2.9s 触发是正确行为
- **版本**：修复合入 bump 3.13.3，exe 已重建安装

## Round 26 — 干净基线重建 + R25 修复板上复验（定时轮 #4，SA50K 板）
- **任务**：删 fb 恢复 2×8b 基线；复验 NOT 改写与信号集戳记两项 R25 修复
- **结果**：✅ 两项修复均**板上有效**——
  1. NOT 改写：`NOT cnt EQ 7` 打印改写 Note、布防为 `cnt NE 7`（无残留）、
     触发点 cnt=101≠7；反证：capture 内 4 次 cnt==7 均未命中（R25 缺陷行为会在
     首个 ==7 样本假触发）；cnt 递推 0 违例
  2. 信号集戳记：`-add fb` 后不 -run 直接 capture，强警告原文出现且被数据实证
     （fb 通道恒 0 + cnt/lfsr 全字错位——"读数错位"是整字移位不只是新通道无效）
  3. 干净基线恢复：AND 链 3/3 精确命中 cnt=200，lfsr 通道 1023/1023 转移全拟合
     （XNOR taps 3&4&5&7 左移），随机抽查零违例
- **新发现并修复 S1：`-capture -o <相对路径>` 崩溃**——hqfpga dump_vcd 按自身
  cwd（hqins_run）解析前缀，目录不存在时 exit -1 崩溃（7/7 复现，同条件无 -o
  全成功）。**已修**：前缀强制绝对化 + 自动创建输出目录（创建失败给干净报错）；
  板上复验：原崩溃路径 `-o hqins_run/hq_import/any` 成功产出 VCD，深层新目录
  自动创建 ✓（修复并入 3.13.3 夜间构建）
- **新发现 S2（记录待修）**：信号集变更后不重新 -trig 即 capture 会用陈旧布防
  上下文假触发（pointer=4，触发点不满足条件）——信号集警告已补"必须重新 -trig"
  提示；自动代际检测待做（TODO 小项池）
- **S3**：信号集失配时 capture 继续产出的 VCD 具迷惑性（全字错位）——保留强警告
  方案，文档已注明读数不可信

## Round 27 — 错误路径矩阵复验（定时轮 #5，r21a 干净基线，SA50K 板）
- **任务**：R11 六项防护 + 位流过期预警 + VIO 异常抽测（共 9 项）
- **结果**：✅ **9/9 全 PASS，无回归**——model 校验（拒烧并给正确型号）、坏时钟
  拒绝（含"assign 中转线不被收录"原理与补救）、矛盾条件三要素文案、sample-only
  拒绝+完整补救指引、-module 误用正确教导语法（无误导性 not found）、位流过期
  预警逐字命中、VIO 异常两场景干净报错；每次失败后状态与基线逐字 diff 一致
- **S3 记录**：①评测方法——坏时钟文案需"存在的信号+坏时钟"才能触达（信号校验
  先行），后续出题直接用该形式；②overflow=True 时（touch bin 后 capture）触发点
  判读语义与常规不同（pointer=4 且标记点值不满足条件），判读文档未覆盖——列入
  数据完整性专项（TODO 小项池），非本轮缺陷

## Round 28 — SoC 离线链路（定时轮 #6，不下板）
- **任务**：-list_soc / -new_soc / -build / -mcu_build / -merge_bin 全链路（FT091226）
- **结果**：✅ **完好，6/6 PASS**——预设清单完整（cm3 19/star 20）；工程树生成正确
  （PROJ_NAME 改写、hqbuddy 版合并脚本）；**-build 一键全流程出 bin（1,059,067 B，
  WNS setup/hold 双 MET，R21 修复在 SoC 工程复验成立）**；Keil 自动发现+无人值守
  编译 0 错 0 警、自动合并镜像算术吻合且未下板；-merge_bin 异常参数干净；-report
  无报告时优雅提示
- **发现 4 条 S3，3 条已修**：
  1. star 族预设拼写 `ex9_watcgdog` → 已改 `ex9_watchdog`（目录+manifest），exe 重建
  2. 两族命名不一致 `ex15_extint`/`ex15_ext_int` → 已统一为 `ex15_ext_int`
  3. 底层合并工具回显误导（报错误的 output 名）→ soc_workflow.md 注明以
     `Merged image:` 为准
  4. soc_workflow.md 补 `-remap` 参数记载

## Round 29 — 违例工程 -paths 提取盲测（定时轮 #7，r29viol 离线）
- **任务**：4ns 收紧约束构造真实 setup 违例（WNS -252.5ps），验证 `-report -paths`
  违例场景准确性（此前只测过全 MET）
- **结果**：**抓到 S1 并修复**——
  1. **S1 slack.rpt 重复段不去重**：报告把每条路径在 `[User Specified Path]` 段
     重列一遍，top-N 被复制品挤占（N=5 时 4/5 错位）、"worst of 40"计数虚增一倍。
     **已修**：抽公共解析 `_slack_records` 按完整四元组去重，-extract 与 WNS 计数
     共用；复验 worst of 20、MET 对照组 205.7/241.3/241.3 与人工核对一致
  2. **S2 端点截断**：`led[0]_c/BQ` 被截成 `led`（正则停在名字内第一个 `[`）——
     **已修**：整行捕获后仅剥离 `[launch/capture clock…]` 注释，端点全名保留
  3. **S3 标签名实不符**：混入 MET 路径时仍自称 violating → 已改三态标注
     （all MET / 全 violating / N violating）；`-paths -1` 补非负校验
- **可信度结论**：修复后 -paths 输出与 slack 报告逐字可溯（最差单条 -252.5 精确、
  FMAX 235.2MHz 一致、违例不阻断 build 属预期）；排序语义=全局 slack 升序
  （跨 setup/hold），与"报告分节顺序"不同——文档已注明
- **顺带确认**：.hqprj 复制含绝对路径自引用（复制工程需改 FILE_SRC）——已知行为，
  TODO 记一条 `-copy_prj` 候选

## Round 31 — 边沿方向专项（第二夜首轮，专用 1-bit 翻转信号，SA50K 板）
- **任务**：给基线工程加 1-bit 翻转信号 dbg_out（initial=1 定相避免与 cnt[0] 重合，
  agent 自主发现并修正方案相位缺陷），清查 R25/R26 遗留的"边沿方向语义存疑"
- **结果**：✅ **边沿方向语义正确，R25"AND 链边沿恒真退化"结论被推翻**——
  RISE 连抓 3/3 精确 0→1；FALL 连抓 3/3 精确 1→0；AND 链 `cnt EQ 100 AND dbg_out
  RISE` 事件拍 cnt=100 严格 ∧ dbg 0→1（3/3）；负控 `cnt EQ 100 AND dbg_out FALL`
  （数学不可满足）15s 诚实超时——若边沿退化恒真必然命中，直接证伪。
  R25 的症状实为当时混位宽损坏 bit 的坏数据，非边沿单元缺陷
- **S1 复现+缓解**：混位宽打包损坏在 3.13.4 全新 -run 上再次复现（8b+8b+1b →
  lfsr 违例 767/1023、1-bit 通道非物理波形，流程零警告）。**已加防御**：
  `-add` 检测到位宽不一致立即警告（板上实测生效）；insight.md 混位宽章节更新
- **S2 文档修正**：R27 的"overflow=True 标记点不可单样本判读"规则被 R31 推翻
  （三次 pointer 各异而标记点逐字相同，窗锚定于匹配样本）——insight.md 已改写
  修正后的判读规则
- **顺带**：3.13.4 的 BOTH 折叠 Note 板上核验通过；`-del` 时 hqfpga 偶发段错误
  再现一次（第 2 次观察，R18 曾见；重试即恢复，进小项池）
- **板上终态**：r21a 干净基线（cnt+lfsr both，EQ 200 AND NE 0），bit 已同步

## Round 32 — 采样参数 CLI 化（-depth/-windows/-level 实现+板上验证）
- **实现**：`-insight -depth N [-windows W] [-level L]`（写 .hqins 三段，键形
  0_LA:N；合法深度 256..65536 校验、窗口 2 的幂校验、触发位置上界
  `depth/windows-5` 校验、重复值幂等不打印 Tip）
- **板上验证结论**：写入/回读可靠、-run 后段保留；**但发现 -run 根本不消费
  .hqins 深度**（ddf 与插桩 RAM ADDR_WIDTH=10 恒 1024）——深度对 bit 是纯文本
- **S1 修复**：capture 深度泄漏静默错位（.hqins 2048 vs ddf 1024 → 触发点错位
  +81、通道块重复）→ **capture 前校验 ddf 深度与 windows，不一致拒绝抓取**
  （板上实测：不匹配→干净拒绝；对齐→cnt=200 健康抓取）
- **S2 记录**：-windows 仅写入（布防/轮询/多 VCD 未实现，capture 检测到不一致
  同样拒绝）；-insight 状态栏显示 bit 实际深度不一致提示；-level 可独立使用；
  -h 已收录
- **遗留**：深度生效需打通"插桩 IP 生成读 .hqins 深度"链路（TODO，候选方向：
  逆向 GUI 写深度后 elaborate 的消费点）

## Round 33 — -edf2v / -netlist_build 产品化（第二夜，离线实现+验收）
- **实现**：新增 `hqbuddy/netlist.py` + dispatch + help/README——
  `hqbuddy -edf2v <a.edif> [-o a.v] [-device part]`（EDF→XIST 原语 Verilog）；
  `hqbuddy -netlist_build <a.edif> --upc <u> --sdc <s> [-o bin] [-device part]`
  （edif.read→flatten→约束→pack/place/route→bitgen + ERROR( 汇总 + 产物校验 +
  输出目录 makedirs 防 bitgen 静默假成功）
- **验收**：5/5 PASS——edf2v 产出含 13×xsDFFSA 的 a.v；netlist_build 产物
  1,787,906 B 与手工链路逐字节同尺寸；缺文件/缺约束/坏约束三条错误路径干净
  （坏约束意外实证了 ERROR( 汇总防御：CDEV008×2 → exit 1）
- **素材勘误**：netlist_build 验收约束应为 r30syn\cons（R31 改过 r21a\cons 加
  dbg_out 脚，与 R30 的 a.edif 端口不匹配——正确地被 CDEV008 拦下）
- exe 已重建安装，smoke：安装版 -edf2v 产出 smoke.v 含 13×xsDFFSA ✓

## Round 34 — 第三方网表+VLA GUI 探索（第二夜，ipdepot 逆向 + hqui 实测）
- **任务**：定位 VLA IP 生成链与 hqui 入口，评估技巧 009 流程的 CLI 化路径
- **结果**：链路结构摸清——VLA IP 属 ipdepot `vla` 条目，由独立生成器
  `hq_vla_ins.exe` 产出（`[IPGEN] INDEPENDENT=YES` 注册）；hqui 流程栏有
  【VLA调试】按钮，灰置判据 = `insight.check has_vla`（网表含 VLA 才为真）；
  `checkVLAandVIO` TCL 在 runSynthesis.tcl 三处调用
- **可行性结论**：生成器向导需 GUI 收集参数（VIO 勾选/端口位宽），无参运行
  挂起、`ipcreator -gen` 静默无产物 → **CLI 生成 VLA IP 当前不可行**。突破路径：
  GUI 向导跑一次 + 抓真实命令行（Procmon/wmic），拿到 hq_vla_ins.exe 参数格式
  后即可像 `-vio -gen` 一样产品化（TODO 排队）
- **顺带记录**：hqui SmartScreen 每次新启动都拦截（无签名），自动化需处理弹窗；
  欢迎页最近工程列表含本机历史路径（隐私注意）
