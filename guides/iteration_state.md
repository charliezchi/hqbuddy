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
| R43 | **深度生效链路逆向** | T1 | ✅ 定论：流程消费 ddf 不读 .hqins 深度；4096 触发厂商流程崩溃（S1 反馈素材）；-depth 已同步写 ddf；工程恢复干净 1024 基线 |
| R44 | -vla -gen 全自动模板化：结构取证定论——dep/probe_num 与内部结构强耦合，文本模板化不安全 → **关闭**；交付 1-probe 参考件 templates/vla/ + 例化契约 | T4/T2 | ✅ 分析定论+参考件交付 |
| R45 | VLA 运行侧逆向：insight.load 的 ddf 格式 + VLA 抓取 SVF 命令族（结合 vla.cfg 逆向） | T2 | 待做 |
| R46 | netlist 流程报告产出：pnr TCL 加 nl.report/ta.report → `-report` 兼容第三方流程 | T3 | ✅ 完成（R44b 提前做掉）|
| R47 | -del 段错误复现条件收集（del/add 循环脚本，厂商反馈素材） | T1 | 待做 |
| R48 | overflow 标记点异常现象复现尝试（R27 一次观察 vs R31 未复现） | T1 | 待做 |
| R49 | X 通配触发（ddf mask 已支持，CLI 语法+板验） | T1 | 待做 |
| R50 | SA5T 板卡实测（**待硬件**，板上当前仅 SA50K/SA30K） | T6 | 挂起 |
| R51 | -vio -read -interval 高频轮询模式 | T2 | 待做 |
| R52 | 边沿×混位宽交叉复测（低优先，依赖 R31 结论） | T1 | 挂起 |

小项池：-device 合法性预校验（R33 遗留）；Sealion 网表流程（bitgen 换 .sealion）；
报错文案扫尾；commands.md 补新命令索引。

## 执行记录（时间序）

- 09-17 02:30 R46 收账：FT091626 升级回归（insight 部分）**无回归**——基线
  抓取触发点 cnt=200(0xc8) 严格、lfsr=0xb8 满足 NE 0、clock_cycle 11 位
  （1024 配置正确）；-root 确认 FT091626。网表链部分 R45 已隐式覆盖。
  至此 FT091626 升级回归【通过】。

- 09-17 02:22 定时轮启动 R46（FT091626 升级回归·insight 部分）。**判据先于执行**：
  ①hqbuddy -root 确认 FT091626；②--detect_model 板在线 SA50K；③r21a 基线
  -capture：触发点 cnt=200(0xc8) 严格、lfsr 满足 NE 0、clock_cycle 11 位
  （1024 配置）；④-insight 状态零漂移。④任一不符按框架升级为回归问题。
  （网表链已在 R45 于 FT091626 上隐式验证。）

- 09-17 01:55 R45 收账：**VLA IP 第三方综合+网表解析可行**（has_vla=1 经阴性
  对照；HQ_VLA0 穿透 EDIF；bin 产出）；发现 **FT091626 新版本**（09-16 10:31 装，
  hqbuddy 自动选中——R45 已隐式在新版上验证网表链）。未下板。

- 09-17 01:42 定时轮启动 R45（VLA IP 第三方综合 + has_vla 解析验证）。
  **判据先于执行**：①VLA IP（templates/vla/xsIP_VLA_1probe.v）实例进第三方
  综合（Vivado OOC+bufg0），产出含 VLA 的 a.edif；②netlist_build 全链成功；
  ③`insight.check has_vla` 返回 1（HqFpga 从网表解析出 VLA）；④has_vio=0；
  ⑤任意失败点如实记录（决定 009 的 CLI 化深浅）。不下板（下载验证明早视时间）。

- 09-17 01:15 R44b 收账：netlist_build 内嵌报告产出（fmax/final_ta/res_place/res_pack/aft_place.xpn），-report 完整读取（bin 字节不变）；exe 重建安装。
- 09-17 00:30 R44 收账：模板化不可安全实现（结构耦合取证：dep↔地址位宽、
  probe_num↔触发单元复制）；交付 1-probe 参考件+例化契约；exe 重建分发。
- 09-16 10:30 主会话完成第三夜准备：队列重建、定时任务改至今晚窗口
  （23:00 前 R43 由主会话提前开跑则锁协议照旧）。
- 09-16 23:10-00:20 R43 收账：GUI/CLI 同流实证；**ddf=权威配置（.hqins 深度
  流程不读）；4096 崩溃复现+状态污染，恢复流程验证**；-depth 同步写 ddf 已上线。
  板上=r21a 干净 1024 基线。GUI 实验未保存工程。

## 下一轮建议（第一次触发执行）

- **R45 VLA 运行侧逆向**（离线+板）：insight.load ddf 格式 + VLA 抓取 SVF。判据：ddf/VLA 关联格式记录 + 可行性结论。
- 之后：R45 VLA 运行侧逆向 → R46 netlist 报告 → R47 段错误取证 → R48/R49。
- 小项池：4096 崩溃厂商反馈（R43 素材齐）；-del 段错误（第2次）；SA5T 待硬件。
- 9-17 08:00-08:30 收官窗口：写 night_report_20260917.md，勿开新工作。
