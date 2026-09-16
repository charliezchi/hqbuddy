# 自回归迭代状态·第三夜（2026-09-16 晚 23:00 → 09-17 08:30）

> 接力棒：定时自动化（每 40 分钟触发，**23:00 前的触发一律空转**；8:00-8:30 收官
> 窗口写 night_report_20260917.md；9-17 08:30 后一律不做工作）。每次先读本文件
> 设定本轮目标，收尾必须更新本文件 + blind_eval_log.md + 本地 commit。
> **硬性边界：只本地 commit，禁止 push；09-17 08:30 后不再开新工作。**
> 每轮修复后 `python build.py` 同步 exe（先 taskkill 残留 hqbuddy.exe）。
> 历史存档：iteration_state_20260915.md（第一夜）、iteration_state_20260916_night2.md
>（第二夜，收官报告 night_report_20260916.md）。

## 锁协议（防两轮并行撞板）

- 板卡/GUI 工作前：检查 `C:\Users\XiST\Desktop\hqbuddy_test\.round_lock`，
  存在且 <90 分钟 → 本次触发直接结束（不等待、不写文件）。
- 取锁：覆盖写入 `{session, started_at, round, purpose}`；收尾删除。>90 分钟可接管。

## 今晚主题：深度生效链路 + VLA CLI 化推进 + 遗留清账

当前基线：hqbuddy **3.14.0**；板上 = r21a 干净基线 bit（cnt/lfsr both，
EQ 200 AND NE 0，depth 1024/1/1）；仓库 5f0c716。

## 队列（S0/S1 修复永远最优先；R 编号沿用）

| # | 主题 | 轨道 | 状态 |
|---|---|---|---|
| R43 | **深度生效链路逆向**（R32 S1 根因）：GUI 采样参数对话框写 depth=2048+保存 → GUI 跑 FPGA 实现 → 检查 ddf/insight_ip.v 是否变 2048，定位消费点；GUI 同样不生效则记录"官方未实现"并评估替代方案 | T1 | 待做（computer-use 主会话亲自） |
| R44 | `-vla -gen` 全自动模板化：从 ipcore_dir/VLA/xsIP_VLA.v 提取模板+HQ_VLA0 属性行参数化（probe_port 解析 hqip）；多 probe 对照样本用 hq_vla_ins 向导生成第二份 | T4/T2 | 待做 |
| R45 | VLA 运行侧逆向：insight.load 的 ddf 格式 + VLA 抓取 SVF 命令族（结合 vla.cfg 逆向） | T2 | 待做 |
| R46 | netlist 流程报告产出：pnr TCL 加 nl.report/ta.report → `-report` 兼容第三方流程 | T3 | 待做 |
| R47 | -del 段错误复现条件收集（del/add 循环脚本，厂商反馈素材） | T1 | 待做 |
| R48 | overflow 标记点异常现象复现尝试（R27 一次观察 vs R31 未复现） | T1 | 待做 |
| R49 | X 通配触发（ddf mask 已支持，CLI 语法+板验） | T1 | 待做 |
| R50 | SA5T 板卡实测（**待硬件**，板上当前仅 SA50K/SA30K） | T6 | 挂起 |
| R51 | -vio -read -interval 高频轮询模式 | T2 | 待做 |
| R52 | 边沿×混位宽交叉复测（低优先，依赖 R31 结论） | T1 | 挂起 |

小项池：-device 合法性预校验（R33 遗留）；Sealion 网表流程（bitgen 换 .sealion）；
报错文案扫尾；commands.md 补新命令索引。

## 执行记录（时间序）

- 09-16 10:30 主会话完成第三夜准备：队列重建、定时任务改至今晚窗口
  （23:00 前 R43 由主会话提前开跑则锁协议照旧）。

## 下一轮建议（第一次触发执行）

- **R43 深度生效链路逆向**（computer-use，主会话亲自；23:00 后的触发改由
  定时轮接手其余队列）。判据：①GUI 写 depth=2048+保存后 .hqins 确认；
  ②GUI 实现（或 -run）后 ddf/insight_ip.v 深度实测；③消费点定位结论
  （elaborate 参数？单独段？官方未实现？）写入 GUI 地图 §8 与 TODO。
- 之后按队列 R44 → R45 → R46 → R47 → R48 → R49 → R51。
- 9-17 08:00-08:30 收官窗口：写 night_report_20260917.md，勿开新工作。
