# 夜间自回归迭代状态（2026-09-14 晚 → 09-15 08:30）

> 本文件是整夜迭代的**接力棒**：定时自动化（automation-a3fca125，9月15日
> 0:40-7:40 每小时触发，至多 8 次；7:40 那轮=收官总结，8:00 后硬停）每次先读本
> 文件设定本轮目标（自动目标设定），收尾时必须更新本文件 + blind_eval_log.md +
> 本地 commit。框架与规则见 `autoregressive_cycle.md`。
> **硬性边界：只本地 commit，禁止 push；08:00 后不再开新工作。**

## 锁协议（防两轮并行撞板）

- 板卡/GUI 工作前：检查 `C:\Users\XiST\Desktop\hqbuddy_test\.round_lock`，
  存在且 <90 分钟 → 本次触发直接结束（不等待）。
- 取锁：覆盖写入 `{session, started_at, round, purpose}`。
- 收尾：删除锁文件。>90 分钟视为 stale，可接管。

## 队列（S0 修复永远最优先插队；每轮一个主题，45 分钟尺度）

| # | 主题 | 轨道 | 状态 |
|---|---|---|---|
| R21 | FT091226 新版升级回归：从零全链路+selftest+组合触发+report(-paths)+错误路径抽测 | 全轨道 | ✅ 完成（链路完好；4 项缺陷修复+复验，bump 3.13.2，详见 blind_eval_log R21） |
| R22 | GUI 探索：HqInsight 采样参数对话框（深度/窗口数/触发次数/offset）逆向 → CLI 暴露设计（先文档后代码） | T4/T1 | ✅ 探索完成（VLA 配置对话框全字段+启动契约入 GUI 地图）；**CLI 实现待做**（-depth/-windows/-level/-reg） |
| R23 | VIO 回归：从零 VIO 工程 → 读写位级校验 → `-loop` 异常输入报错（R13 用例在 FT091226 复演） | T2 | ✅ 完成（链路完好 a-e 全 PASS；`-reg` 逗号 S2 修复+复验；vio.md 对位法修正；exe 已重建） |
| R24 | GUI 探索：VLA（VIO+LA）入口与 FT091226 release note 的 VLA 修复验证可行性 | T4/T2 | ✅ 完成（vla.cfg 全格式+MLA 机制+GUI 入口；CLI 三级设计入 GUI 地图 §8） |
| R25 | 触发矩阵回归：R16 六条（BOTH 折叠/RANGE_C/NOT/跨信号 AND/电平/诚实超时）在新版复验 | T1 | 待做 |
| R26 | 错误路径矩阵复验（R11 六项防护+失败无副作用） | T1 | 待做 |
| R27 | SoC 离线链路（-list_soc/-new_soc/-build 至 route，不下板）视时间 | T3 | 待做 |
| R28 | `-report -paths N` 违例工程上的提取（找一个真实有违例的工程；当前全 MET） | T3 | 待做 |

## 执行记录（每轮收尾追加一行）

- 2026-09-15 01:41 定时轮启动 R24（VLA 探索）。**判据先于执行**：
  a) 反编译源码层面弄清 `--vla_cfg`/`vla.cfg` 的消费路径与格式（键、如何影响
     svf_generator 调用），以及 `insight.sealion.mla.*` 与单 LA 命令族的差异点；
  b) GUI 层面确认多 LA 添加入口（LA_0 页 + 按钮）与 VLA 模式下调试面板差异；
  c) 产出物：VLA/MLA CLI 可行性设计写入 GUI 地图与 TODO（只设计不实现）；
  d) 纪律：GUI 只探索不布防不保存；不下载任何 bit；板卡保持 r23vio VIO bit。
- 2026-09-15 02:00 R24 收账：a-d 全达成（vla.cfg 全格式/MLA 布防轮询机制/+按钮
  实测/设计入 GUI 地图 §8+insight.md）；纯探索零改动、无缺陷。板卡未动。

## 下一轮建议（下一次定时触发执行）

- **R25 触发矩阵回归**（板上 SA50K）：R16 六条矩阵在 FT091226 复演——
  BOTH 折叠/RANGE_C/NOT 取反/跨信号 AND/电平比较/不可满足诚实超时；
  工程复用 r21a（LA bit 需重下载，板上现为 r23vio VIO bit）。
  判据：六条各自真实命中或诚实超时，触发值严格满足条件，等待秒级。
- 之后：R26 错误路径矩阵 → R27 SoC 离线 → R28 违例工程 -paths → R22-C 实现起步。
- 定时轮注意：每轮修复后 `python build.py` 同步 exe；GUI 与 CLI 板卡操作互斥（锁协议）。

- 2026-09-15 00:56 定时轮启动 R23（VIO 回归）。**判据先于执行**：
  a) r23vio 从零建工程（计数器→probe_in；probe_out 双寄存回环→probe_in 高位），
     -vio -gen/-reg/-build 全 exit 0 且产物 bin 存在；
  b) 下载成功后 `-read -loop` 读到计数器推进特征（对位按 vio.md MSB 规则核验）；
  c) `-write X` 后连读 ≥2 次高位字节收敛到 X（回环闭环证据）；
  d) `-vio -read -loop xyz`（非数字）友好报错 exit≠0，不抛 traceback；
  e) 全程无 insight 交互（VIO/LA 同板互斥，当前板载 r21a 插桩 bit，须先下载 VIO bit）。
- 2026-09-15 01:12 R23 收账：a-e 全 PASS（写入回读第 1 次收敛；0xA5/0x3C 为回文向量、
  以 0xC1 补证位序；欠采样认知修正进 vio.md）；S2 `-reg` 逗号静默错登记已修
  （拆分+名校验）并复验；3.13.2 exe 重建同步。板卡现载 r23vio VIO bit（SA50K）。

- 2026-09-14 23:30 主会话启动 R21（盲评 agent 已派出，独立判读）。
- 2026-09-15 00:35 R21 收账：链路完好；selftest 回绕/伪影假阴性、-paths 静默失效、
  -build 不执行、预检 $WORK_DIR$ 拼接——4 项全修+复验；3.13.2 已构建安装；
  文档三处同步（insight.md/download.md/hqbuddy.md）。commit 待落。
- 小项插队池：报错文案中英统一（S2）；-selftest 进 -h（S3）。
- 2026-09-15 01:05 R22 收账：VLA 配置对话框全字段捕获（深度 256~65536/窗口/级数/
  加寄存 YES-NO/预存拍数）；hq_ins 启动契约实锤（--hqprj/--hqexe/--hqlang，裸参数报
  "project doesn't exist"）；.hqins 键形 `0_LA:*`（[MEMORY DEPTH INFO]/[ADD REGISTER]/
  [TRIGGER MULTI-WINDOW]/[TRIGGER LEVEL]），预存拍数为布防期参数不落盘。
  GUI 全程未保存、工程逐字未变。
- 2026-09-15 02:00 R24 收账：a-d 全达成（vla.cfg 全格式/MLA 布防轮询机制/+按钮
  实测/设计入 GUI 地图 §8+insight.md）；纯探索零改动、无缺陷。板卡未动。

## 下一轮建议（下一次定时触发执行）

- **R25 触发矩阵回归**（板上 SA50K）：R16 六条矩阵在 FT091226 复演——
  BOTH 折叠/RANGE_C/NOT 取反/跨信号 AND/电平比较/不可满足诚实超时；
  工程复用 r21a（板上现为 r23vio VIO bit，需先重下载 r21a 插桩 bin：
  `hqbuddy -cable --sealion C:\Users\XiST\Desktop\hqbuddy_test\r21a\hqins_run\hq_import\hqins_impl\r21a.bin --model SA50K --Burst`）。
  判据：六条各自真实命中（或不可满足条件诚实超时），触发值严格满足条件，等待秒级。
- 之后：R26 错误路径矩阵 → R27 SoC 离线 → R28 违例工程 -paths → R22-C 实现起步。
- 定时轮注意：每轮修复后 `python build.py` 同步 exe（R23 起惯例）；GUI 与 CLI 板卡
  操作互斥（锁协议）。
