# hqbuddy 夜间自回归迭代收官报告（2026-09-15 08:00）

> 运行区间：2026-09-14 23:30 → 09-15 07:40（定时自动化 8 次触发全部按计划执行，
> 无跳过、无未收账轮次）。框架：`guides/autoregressive_cycle.md`；逐轮详情：
> `guides/blind_eval_log.md`；接力状态：`guides/iteration_state.md`。

## 一、夜间轮次总账

| 轮 | 主题 | 结果 |
|---|---|---|
| R21 | FT091226 新版升级回归（从零全链路+selftest+组合触发+report+错误路径，SA50K 板） | 链路完好；**4 缺陷修复+复验**（3.13.2） |
| R22 | GUI 探索：采样参数对话框 + hq_ins 启动契约 | ✅ VLA 配置对话框全字段测绘（纯探索零改动） |
| R23 | VIO 读写回归（r23vio 从零建工程） | ✅ 链路完好 a-e 全 PASS；-reg 逗号 S2 修复 |
| R24 | VLA/MLA 探索（反编译+GUI） | ✅ vla.cfg 全格式逆向+MLA 机制；CLI 三级设计入档 |
| R25 | 触发矩阵回归 | **抓到 2×S1 真回归**（NOT 丢弃/混位宽打包）→ 修复（3.13.3） |
| R26 | R25 修复板上复验 + 干净基线重建 | ✅ 两修复板上有效；**新 S1 -o 崩溃修复+复验** |
| R27 | 错误路径矩阵复验 | ✅ 9/9 全 PASS 无回归 |
| R28 | SoC 离线链路（-new_soc/-build/-mcu_build） | ✅ 6/6 PASS；3 条 S3 修复（预设拼写/命名/文档） |
| R29 | 违例工程 -report -paths 盲测 | **抓到 S1 去重缺陷+S2 端点截断** → 修复+ground truth 核对 |

累计 10 次本地 commit（bb89605..27d47b2 + 收官本条），**未 push**。

## 二、修复清单（全部经复验）

| # | 级别 | 缺陷 | 修复 |
|---|---|---|---|
| 1 | S1 | `-insight -selftest` 假阴性（8 位计数器回绕不容错+尾部重 dump 伪影） | 按位宽取模+丢弃尾部重复样本；板上 PASS |
| 2 | S1 | `-report -paths` 只在参数首位解析（静默失效） | 任意位置解析+未知旗标报错；全局 slack 升序 |
| 3 | S1 | `-build` 从未执行流程（产物校验误放生成阶段，殃及 `-flow` 恒 exit 1） | 校验移至真正执行后；端到端复验 |
| 4 | S2 | `-init` 预检 `$WORK_DIR$` 无分隔符拼接误报 | 展开时补分隔符 |
| 5 | S2 | `-selftest` 覆写触发条件不恢复 | 三文件快照/恢复 |
| 6 | S2 | `-vio -reg` 逗号多探针静默错登记 | 拆分+探针名校验；板上复验 |
| 7 | S1 | **NOT 单条件取反被硬件丢弃**（NOT EQ 7 在 ==7 命中，4/4） | 算术取反自动改写等价算子（打印 Note）；板上复验+反证 |
| 8 | S1 | 混合位宽探针打包损坏（+1b 后 8b 通道违例 770/1023，R6 旧患加重） | `-run` 记信号集戳记 `.bit_signals`；`-capture` 失配强警告；板上复验 |
| 9 | S1 | `-capture -o <相对路径>` 致 dump_vcd 崩溃（exit -1，7/7） | 前缀绝对化+目录自动创建；板上复验 |
| 10 | S1 | `-report -paths` 不去重 slack.rpt 重复段（top-N 被复制品挤占、计数翻倍） | `_slack_records` 四元组去重，-paths 与 WNS 计数共用；ground truth 核对 |
| 11 | S2 | -paths 端点截断（`led[0]_c/BQ`→`led`，无法溯源） | 整行捕获仅剥时钟注释；全名保留 |
| 12 | S3 | SoC star 预设拼写 `ex9_watcgdog`、两族 `ex15` 命名不一致 | 目录+manifest 统一（ex9_watchdog / ex15_ext_int） |

文档同步：README（-selftest/-paths/版本 3.13.3）、insight.md（selftest 用法、NOT
行为、混位宽警告、MLA/vla.cfg、hqdnload 自动关闭）、vio.md（逗号语法、对位验证
方法修正）、download.md（新版 detect_model 输出差异）、hqbuddy.md（ratio.rpt、
-paths）、GUI 地图（VLA 配置对话框、hq_ins 契约、§8 VLA/MLA 全节）、soc_workflow.md。

## 三、新发现按分级

- **S0：0 项**（全程无数据级错误漏网——触发值/报告数字/合并镜像均验证正确）。
- **S1：6 项**（#1/2/3/7/8/9/10，全部已修，见上表）。
- **S2 遗留（未修）**：
  - 信号集变更后不重新 -trig 即 capture 会用陈旧布防假触发（已补提示，自动代际
    检测待做，R26）
  - 边沿方向语义（RISE/FALL 落点方向、AND 链边沿疑似恒真退化）需专用 1-bit 设计
    复测（R25/R26，损坏 bit 上无法定论）
- **S3 遗留（小项池）**：overflow=True 触发点判读语义未文档化（数据完整性专项）；
  `cnt[7]`/`cnt[7:7]` 片选行为不一致；BOTH 折叠缺文案；报错文案中英统一；
  -selftest 进 -h；`-copy_prj` 候选（.hqprj 复制绝对路径自引用）。
- **认知修正（已入文档）**：FT091226 硬件取反位丢弃（NOT 规避法）；混位宽打包
  限制边界；欠采样下 VIO 对位判定法；LFSR 圈含 0x00 勘误；新版 hqdnload 自动关闭、
  detect_model 缺 UID/Package、ratio.rpt 新报告源；vla.cfg 全格式与 MLA 运行时机制。

## 四、能力基线（本夜结束时的可信状态）

- **insight**：从零建工程→插桩→下载→触发（算术/RANGE_C/跨信号 AND/NOT 改写后）→
  抓波→VCD 递推校验，全 CLI 闭环在 FT091226 上无回归；2×8b 同宽探针为可信配置，
  **混位宽探针集合暂不可信**（警告已拦截）。
- **VIO**：读写回环位级精确；与 LA 同板互斥照旧。
- **-build/-report**：普通与 SoC 工程一键出 bin；报告摘要（FMAX/WNS/利用率/-paths）
  与原始 .rpt 逐字可溯。
- **SoC**：cm3/star 预设离线全链路完好。
- **错误路径防护**：9 项矩阵全 PASS，失败零副作用。

## 五、板卡与环境状态

- 板卡：**SA50K**（SA5Z-50-D0-7F484C，Device ID 0C3147FD），JTAG 空闲；
  板上为 r21a 干净 2 信号插桩 bit（cnt/lfsr，cnt NE 7 布防），可直接复用或重下。
- 工具链：HqFPGA **FT091226**；hqbuddy **3.13.3**（源码与 PATH exe 同步）。
- 测试区：`C:\Users\XiST\Desktop\hqbuddy_test\`（r21a 基线工程、r23vio VIO 工程、
  r28soc SoC 工程、r29viol 违例工程，均可复用；.round_lock 已清理）。
- 遗留环境观察：两个孤儿 hqui.exe（昨日 22:57 起）建议人工确认后关闭。

## 六、白天建议优先级

1. **R30：R22-C 实现**——`-insight -depth/-windows/-level/-reg`（设计已入 GUI 地图
   §8，.hqins 四段键与合法边界均已逆向）；
2. 边沿方向专项（含 1-bit 信号的专用测试设计，一次 -run 后复测 R25/R26 遗留）；
3. 陈旧布防代际自动检测（-capture 拒绝或强提示）；
4. 小项池批量清理（文案统一/-h 补全/overflow 语义/-copy_prj）。
