# hqbuddy 自回归迭代收官报告·第三夜（2026-09-17 08:00）

> 运行区间：2026-09-16 23:10 → 09-17 07:42（应用户"现在就开始收官"提前于 08:00 收官）。
> 主题：**深度生效链路逆向 + VLA CLI 化推进 + 遗留清账**。
> 逐轮详情：`guides/blind_eval_log.md`；接力状态：`guides/iteration_state.md`；
> 历史收官：night_report_20260915.md / night_report_20260916.md。

## 一、轮次总账（第三夜 12 轮）

| 轮 | 主题 | 结果 |
|---|---|---|
| R43 | 深度生效链路逆向（GUI 实验+字节级取证） | ✅ **定论：流程消费 ddf 不读 .hqins 深度**；改深度触发厂商崩溃（4096 稳定复现）；-depth 同步写 ddf 上线 |
| R44 | -vla -gen 全自动模板化分析 | ✅ 定论不可安全实现（结构耦合取证）；交付 1-probe 参考件 templates/vla/ |
| R44b | netlist 流程报告产出 | ✅ -netlist_build 内嵌全套报告，`-report` 兼容第三方流程（bin 字节不变） |
| R45 | VLA IP 第三方综合+网表解析 | ✅ **可行**——has_vla=1（阴性对照）；HQ_VLA0 穿透 EDIF；bin 产出 |
| R46 | FT091626 升级回归 | ✅ insight 基线无回归（网表链 R45 已隐式覆盖） |
| R47 | -del 段错误取证+防护 | ✅ **100% 复现→根因（删空触发集+debugip.create）→拒绝防护上线**；厂商素材留存 |
| R48 | overflow 异常复现尝试 | ✅ 未复现，专项关闭（R27 判定为陈旧 bit 场景） |
| R43b | depth=2048 端到端补完（干净状态） | ✅ **结构生效（2049 样本）但触发语义失真**（te 窗口 cnt≈129-134≠EQ 200）→ 生产保持 1024 |
| R47b | 静默回归（基线抓取） | ✅ 无异常 |
| R47c | 静默回归（基线+edf2v 冒烟） | ✅ 无异常 |
| R47d | 收官前终检 | ✅ 状态完美交接 |
| R51 | VIO 轮询/写抽测 | ✅ 全通；R51 关闭（功能已存在） |

累计本地 commit 15 次，**未 push**。

## 二、关键定论（第三夜）

1. **深度**：流程消费 **ddf**（`<depth>/<window_num>`），.hqins 深度段只是 GUI
   持久化；depth=2048 结构生效（2049 样本/13 位 cc）但**触发语义失真**；
   4096 使流程崩溃。**生产保持 1024**；`-depth` 现同步写 .hqins+ddf。
2. **-del 段错误根因**：删除最后一个触发信号 → ddf 触发集为空 →
   `insight.debugip.create` 段错误（100% 复现，与"全 sample 红线"同源）。
   防护：`-del` 拒绝清空触发集并给指引。厂商素材：r47del/vendor_feedback/。
3. **X 通配不可用（S1 厂商）**：mask 写入正确但板级判定矛盾（触发点不满足
   掩码语义、VCD te 全 0 与输出矛盾）——语法保留待厂商。
4. **VLA CLI 化路线图**：IP 经第三方综合+网表解析**可行**（has_vla=1 阴性对照）；
   生成契约已捕获（-vla -gen 半自动上线）；卡点收窄为**网表工程的 ddf 生成链**
   （GUI VLA 调试按钮背后环节，需 GUI 抓包）。
5. **insight.check** 结果经 TCL 返回值给出（无 FLAG: 打印行，S3 文档修正）。

## 三、新交付物

- 命令：`-vla -gen`（半自动 VLA IP 生成）；`-depth/-windows/-level`（采样参数）；
  `-edf2v`/`-netlist_build`/`-copy_prj`（第二夜交付，本夜报告产出增强）
- 参考件：`templates/vla/xsIP_VLA_1probe.v`（1-probe VLA IP 标准配置）
- 防护：-del 空触发集拒绝；capture 深度/窗口一致性拒绝；-add 混位宽警告
- 文档：thirdparty_synthesis.md（第三方全链路+VLA 契约）；GUI 地图 §8（VLA/MLA
  +深度消费点定论）；insight.md（-selftest/-depth/混位宽/overflow/X 通配/
  -del 崩溃/LFSR 可观测等价式）；modelsim.md（+acc/VCD 坑）；download.md/
  vio.md/hqbuddy.md/soc_workflow.md 各有补正

## 四、遗留（按优先级）

1. **深度>1024 的厂商崩溃**（4096 稳定复现，素材齐）——向智多晶反馈；
2. **VLA 运行侧 ddf 生成链**（网表工程 VLA 调试的最后一环，需 GUI 抓包）；
3. **-vla -gen 全自动**（依赖 hqip probe_port 解析，多 probe 需向导对照样本）；
4. 小项：-del 段错误随 R47 防护观察稳定性；SA5T 实测待硬件；
   overflow 专项已关闭；SA5Z-30 板卡本轮未复测（基线在 SA50K）。

## 五、板卡与环境状态

- 板卡：**SA50K**，JTAG 空闲；板上 = r21a 干净基线 bit（cnt/lfsr both，
  EQ 200 AND NE 0，1024/1/1），07:42 终检通过。
- 工具链：HqFPGA **FT091626**（09-16 新装，已过升级回归）；hqbuddy **3.14.0**
  （源码与 PATH exe 同步）。
- 测试区：r21a 基线、r23vio、r28soc、r29viol、r30syn（第三方+VLA+sim）、
  r36cp、r45vla（VLA 网表工程）、r47del（段错误取证+厂商素材）。
- 自动化：第三夜定时任务收官后由主会话删除（不再空转）。
