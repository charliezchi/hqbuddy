# 自回归迭代状态·第二夜（2026-09-15 晚 → 09-16 08:30）

> 接力棒：定时自动化（9月15日 23:40 → 9月16日 7:40 每小时触发，至多 9 次；
> 7:40 那轮=收官总结，8:00 后硬停）。每次先读本文件设定本轮目标，收尾必须更新
> 本文件 + blind_eval_log.md + 本地 commit。框架：`autoregressive_cycle.md`。
> **硬性边界：只本地 commit，禁止 push；08:00 后不再开新工作。**
> 每轮修复后 `python build.py` 同步 exe（注意先 taskkill 残留 hqbuddy.exe 再装）。
> 上一夜状态存档：`guides/iteration_state_20260915.md`（R21-R29，收官报告
> night_report_20260915.md）。

## 锁协议（防两轮并行撞板）

- 板卡/GUI 工作前：检查 `C:\Users\XiST\Desktop\hqbuddy_test\.round_lock`，
  存在且 <90 分钟 → 本次触发直接结束（不等待）。
- 取锁：覆盖写入 `{session, started_at, round, purpose}`；收尾删除。>90 分钟可接管。

## 今晚主题：第三方综合协同（新能力）+ 遗留清账

已验货（主会话 21:30-22:40）：Vivado 2018.3 / Synplify 2013.03
（**bin\mbin\synbatch.exe**，bin 包装器的 win64 路径 license 失效）→ EDF →
HqFpga P&R → bin → 下载 SA50K 全通。skill 新文档
`skills/hqfpga/references/thirdparty_synthesis.md` 已写入（含 mbin license 坑、
technology 必须写 `Artix7` 无空格、`-family` 在 FT091226 报 DVST001 要省略、
.hqprj 不认 .edf 必须显式 TCL）。

## 队列（S0/S1 修复永远最优先）

| # | 主题 | 轨道 | 状态 |
|---|---|---|---|
| R30 | 第三方综合链路盲评：agent 只按新 skill 文档从零复现，挑文档毛病 | T3/新 | ✅ 链路通；10 条文档缺陷全数补齐（.prj 模板/文件衔接/约束前置/退出码语义/bitgen 假成功/端点全名等） |
| R31 | 边沿方向专项：RTL 加 1-bit 直出信号 → -add → -run → RISE/FALL 方向核验（清 R25/R26 S2 遗留） | T1 | 待做 |
| R32 | R22-C 实现：`-insight -depth N [-windows W] [-level L]`（写 .hqins 四段 + 提示必须 -run；板上盲测 depth=2048 生效） | T1/T4 | 待做 |
| R33 | EDF→Verilog 网表 ↔ ModelSim 门级仿真链验证（modelsim.md + 第三方网表 a.v） | T3 | 待做 |
| R34 | 第三方网表+VLA：GUI 路径探索（computer-use：hqui 生成 VLA IP 的入口与产物格式） | T4/T2 | 待做 |
| R35 | -copy_prj 实现（复制工程+改写 FILE_SRC 路径，R29 发现） | T3 | 待做 |
| R36 | 小项清理：报错文案中英统一；片选 cnt[7] vs cnt[7:7] 行为；-vio -read -interval | T1-T3 | 待做 |

小项池：陈旧布防代际自动检测（R26 S2）；overflow 判读已入文档（R27）。

## 执行记录（时间序）

- 09-15 22:30 主会话启动 R30（新 skill 文档盲评，agent 已派）。板载 r30syn.bin
  （Vivado 网表编译产物，已验下载）。agent 会用自己的构建覆盖，属预期。
- 09-15 23:05 R30 收账：链路通（Synplify 路线独立复现成功并上板）；文档 10 条缺陷
  （3 硬缺口+退出码语义+bitgen 假成功等）全部补齐进 thirdparty_synthesis.md。
  板载 r30tb 复现 bin（agent 下载验证）。

## 下一轮建议（下一次定时触发执行）

- R31 边沿方向专项（板上）：先读 R30 结果防重复踩坑。判据先于执行：
  ①RTL 改动：顶层加 1-bit 直出信号（如 `reg t7; always@(posedge clk) t7<=cnt[7];`
  `assign dbg=t7;` 引出管脚）或尝试片选 -add cnt[7]（若工具支持）；
  ②-run+下载成功；③RISE 连抓 3 次：事件样本必须 0→1；FALL 连抓 3 次：必须 1→0；
  ④对照 R25"边沿疑似恒真"结论给出清欠判定，落账。
- 之后按队列 R32 → R33 → R34 → R35 → R36。
- 7:40 触发=收官轮：写 guides/night_report_20260916.md，勿开新工作。
