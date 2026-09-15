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
| R31 | 边沿方向专项：专用 1-bit 翻转信号核验 | T1 | ✅ 边沿语义正确，R25 恒真结论推翻；混位宽损坏复现→-add 警告已加（3.13.4） |
| R32 | `-insight -depth/-windows/-level` 实现+板上验证 | T1/T4 | ✅ 写入/校验/幂等全通过；发现 -run 不消费深度（S1）→ capture 不一致拒绝已上线；windows 仅写入 |
| R33 | -edf2v / -netlist_build 实现（第三方 TCL 链产品化） | T3 | ✅ 5/5 验收 PASS（bin 同尺寸）；smoke 通过；docs 同步。ModelSim 门级仿真链移 R34b |
| R34 | 第三方网表+VLA：GUI 路径探索（computer-use：hqui 生成 VLA IP 的入口与产物格式） | T4/T2 | ✅ 生成链摸清（ipdepot vla + hq_vla_ins.exe 独立生成器）；CLI 生成不可行（向导参数 GUI 收集）；突破路径=抓真实命令行（R34b） |
| R35 | -copy_prj 实现（复制工程+改写 FILE_SRC 路径，R29 发现） | T3 | ✅ 实现并双验证（-filelist/-init） |
| R36 | 小项清理：报错文案中英统一；片选 cnt[7] vs cnt[7:7] 行为；-vio -read -interval | T1-T3 | 待做 |

小项池：陈旧布防代际自动检测（R26 S2）；overflow 判读已入文档（R27）。

## 今晚探索新增候选（待排入队列，主会话 23:10 离线探测补充）

- **T-A**：hqbuddy 新命令 `-edf2v <a.edif> [-o a.v]`（一键 EDF→Verilog，封装
  dv.setup+edif.read+nl.write；第三方协同高频动作）
- **T-B**：hqbuddy 新命令 `-netlist_build <a.edif> --upc <u> --sdc <s> -o bin`
  （一键第三方网表 P&R+bitgen+产物校验；今晚 pnr.tcl 的产品化）
- **T-C**：第三方网表流程的报告产出（pnr.tcl 加 nl.report/ta.report → `-report`
  兼容；当前第三方流程无 fmax/slack 报告可看）
- **T-D**：`impl.guide.set -keep_hier` 对第三方网表的层次保留（利于调试定位）
- **T-E**：VLA IP 生成入口（hqui 的 IP 生成器里 VLA/VIO 参数 → .v/.prj 产物
  格式逆向，为 009 的 CLI 化铺路）
- **T-F**：`hqbuddy -synprj <rtl...> -device <part>` 生成 Synplify .prj 模板
  （R30 缺陷 #1 的工具化）

## 执行记录（时间序）

- 09-16 02:40 R35 收账：-copy_prj 实现并验收（5 文件拷贝+路径改写+时间戳重建；
  -filelist/-init 双验证复制工程在新目录完整可用）。README/hqbuddy.md 同步。
- 09-16 01:55 R34b 收账：**hq_vla_ins.exe 调用契约捕获成功**（-device/-lang/
  -output_module/-output_fname/-output_dir/-hq_exe），产物四件套（xsIP_VLA.v
  102KB + hqip + cfg + t.tcl）已留存 r21a/ipcore_dir/VLA/；HQ_VLA0 属性行=配置
  载体（第三方综合关键）。`-vla -gen` 可模板化实现（TODO）。.hqprj 未被动。

- 09-16 01:38 定时轮启动 R34b（向导命令行捕获）。**判据先于执行**：
  ①后台 wmic 轮询器先启动，持续抓 hq_vla_ins.exe 的 CommandLine 到日志；
  ②GUI 向导走一遍 VLA IP 生成（默认/最小配置即可）；
  ③拿到命令行 → 记录参数格式与产物文件清单 → GUI 地图 §8 + TODO 更新；
  ④若向导无法到达/轮询未捕获 → 如实记录，转 R35；全程不布防不下载。

- 09-16 01:10 R34 探索注记：SmartScreen 拦截 hqui 启动（每次新启动都弹），已按
  弹窗确认运行；两个孤儿 hqui 已清理。

- 09-16 00:59 定时轮启动 R34（VLA GUI 探索，computer-use 亲自）。**判据先于执行**：
  ①在 hqui 里定位 VLA IP 的生成/例化入口（IP 生成器或独立向导），记录菜单路径；
  ②捕获 VLA IP 产物（.v 模板的端口/参数、配套 .prj/ddf 雏形）到测试区留存；
  ③确认工具栏【VLA 调试】按钮的位置与前置条件（tip 009 说编译前灰色）；
  ④产出：GUI 地图 §8 增补 VLA IP 生成节 + CLI 化可行性结论；全程不布防、不下载。

- 09-15 22:30 主会话启动 R30（新 skill 文档盲评，agent 已派）。板载 r30syn.bin
  （Vivado 网表编译产物，已验下载）。agent 会用自己的构建覆盖，属预期。
- 09-15 23:05 R30 收账：链路通（Synplify 路线独立复现成功并上板）；文档 10 条缺陷
  （3 硬缺口+退出码语义+bitgen 假成功等）全部补齐进 thirdparty_synthesis.md。
  板载 r30tb 复现 bin（agent 下载验证）。

- 09-16 01:30 R34 收账：VLA IP 生成链=ipdepot vla + 独立生成器 hq_vla_ins.exe
  （向导参数 GUI 收集，无参挂起；ipcreator -gen 静默）；VLA调试按钮灰置判据=
  insight.check has_vla。GUI 全程未保存、未布防。hqui 已关闭。
- 09-16 00:45 R33 收账：netlist.py 新增（_run_tcl_streamed/_fail_on_tcl_errors/
  run_edf2v/run_netlist_build）；dispatch+help+README 同步；验收 5/5（含 ERROR(
  汇总防御意外实证）；exe 重建安装 smoke 通过。
- 09-16 00:25 R32 收账：-depth/-windows/-level 实现完成（写入/校验/幂等/
  触发位置上界全通过）；板上发现 -run 不消费 .hqins 深度（S1，深度生效链路待
  逆向）→ capture 一致性拒绝已上线并实测。板上终态=干净 1024/1/1 基线，
  触发 EQ 200 AND NE 0，健康抓取验证。
- 09-15 23:55 R31 收账：边沿方向【正确】（9/9 + 负控）；R25 恒真误判推翻（坏打包
  数据所致）；S1 混位宽复现 → -add 混位宽警告上线（板上实测 [1,8] 触发）；
  overflow 判读规则按 R31 实证改写。主会话误删 cnt 已恢复；工程=干净基线
  （cnt+lfsr，EQ 200 AND NE 0），bit 已同步下载。小项池新增：-del 段错误（第2次观察）。

## 下一轮建议（下一次定时触发执行）

- R31 边沿方向专项（板上）：先读 R30 结果防重复踩坑。判据先于执行：
  ①RTL 改动：顶层加 1-bit 直出信号（如 `reg t7; always@(posedge clk) t7<=cnt[7];`
  `assign dbg=t7;` 引出管脚）或尝试片选 -add cnt[7]（若工具支持）；
  ②-run+下载成功；③RISE 连抓 3 次：事件样本必须 0→1；FALL 连抓 3 次：必须 1→0；
  ④对照 R25"边沿疑似恒真"结论给出清欠判定，落账。
- 之后按队列 R32 → R33 → R34 → R35 → R36。
- 7:40 触发=收官轮：写 guides/night_report_20260916.md，勿开新工作。
