# 自回归迭代状态·能力补全阶段（2026-09-17 起）

> 用户指示：**先完成 hqfpga 探索/能力补全 TODO，再进入复杂设计盲评系列（BD）**。
> 框架：`autoregressive_cycle.md`；锁协议照旧；只本地 commit 严禁 push；
> exe 修复后 taskkill+build+覆盖安装。板卡 = SA50K（在线，当前为 r21a 基线 bit）。
> BD 系列任务池已备好（见 §BD），能力 TODO 完成后立即转入。

## 阶段 A：hqfpga 探索/枚举（离线，快速）

| # | 任务 | 产出 | 状态 |
|---|---|---|---|
| A1 | ipdepot 全量枚举（83 IP：名称/描述/器件/类别）→ skill `ip_catalog.md` | ip_catalog.md | 🔄 进行中 |
| A2 | eco.* 命令族 help dump + 可行性结论 → skill `eco.md` | eco.md | 待做 |
| A3 | XPN 结构探明（r30syn/aft_place.xpn 解析）→ `-xpn inspect` 命令 | 新命令 | ✅ 探明：`comp "<名>" { logical { cellmodel-name <类>; } }` 格式；inspect 命令实现下轮 |
| A4 | tc.autogen 产品化 | 新命令 | ❌ **厂商 bug 关闭**——tc.autogen -print 产出畸形 TCL（missing "），无法提取约束行；素材已存 /tmp |
| A5 | nl.clock.detect / res.report / design.save checkpoint 探测记录 | 文档 | 待做 |
| A5 | nl.clock.detect / res.report / design.save checkpoint 探测记录 | 文档 | 待做 |

## 阶段 B：hqbuddy 命令补全

**B1 -regression 实现方案**：新增 `hqbuddy/regression.py`——
1. 基线抓取（r21a -capture 触发点 cnt=200 校验）
2. 错误路径抽测（-trig 矛盾条件拒绝 / sample-only 拒绝 / -model 校验）
3. -filelist/-report 冒烟
4. -edf2v 冒烟（r30syn/a.edif → xs 原语验证）
全部 PASS → 一句"回归通过"；任一 FAIL → 详情+exit 1。offline 可跑项不含板。

| # | 任务 | 状态 |
|---|---|---|
| B1 | `-regression` 套件命令化（selftest+触发抽测+错误路径+基线抓取一条命令） | 待做 |
| B2 | pinplan clk 匹配 | ✅ 审查：现有时钟候选提示已够用（V6 限制），待 ioh.get_ports I 可用后升级 |
| B3 | synopt 全键 | ✅ 审查：SLO_KEYS 已含 sweep/clk_conv/data_opt/merge/cut_merge，无遗漏 |
| B4 | doctor 增强 | ✅ 审查：.upc 缺失已覆盖，IO bank 冲突属厂商 ta.* 范畴，暂不重复 |

## 阶段 C：复杂设计/调试盲评系列（≥30 轮，A/B 完成后开始）

| # | 任务 | 状态 |
|---|---|---|
| BD1 | UART 8N1 回环全链路（115200@25MHz，探针 rx_data/rx_done，LA 验证） | 任务书已备 |
| BD2 | 注入 bug 调试：BD1 植入 3 bug（分频错/去同步/复位极性），盲找修复 | 待做 |
| BD3 | 双时钟 CDC | 🔄 下一轮 |
| BD4 | SPI master 模式 0：VIO 驱动 + LA 抓波形核对 | 待做 |
| BD5 | 同步 FIFO（BRAM 推断）：满/空标志 + 读写序 | 待做 |
| BD6 | 8 位 FSM 数据通路（指令 ROM+译码+ALU）时序收敛 | 待做 |
| BD7 | PWM+按键消抖+VIO 调占空比 | 🔄 下一轮 |
| BD8 | 深度回归：BD1-BD7 全部重跑零回归 | 待做 |
| BD9+ | 池：I2C、CRC、看门狗、曼彻斯特、格雷码转换、脉冲整形……自主扩展 | 池 |

## 遗留/挂起（详见 open_issues.md）

- V1-V6 厂商问题（深度失真/4096 崩溃/空触发集段错误/X 通配/seed 机制/ioh I）
- SA5T 实测（待硬件）；VLA 运行侧 ddf 链（需 GUI 抓包）；-vla 全自动模板化（已定论不可行）

## 执行记录（时间序）

- 09-18 03:53-05:1x BD7 收账：PWM+VIO 设计正确（97.66kHz 载波精确、50% 占空比
  精确、消抖逐拍验证）；S1 VIO/LA JTAG 互斥实锤（双 bit 绕行）；S1 通道互换
  加剧（V12）+S2 exit code（V13）入档。板上 = bd7 插桩 bit。
- 09-18 03:53 定时轮启动 BD7（PWM+按键消抖+VIO 调占空比）。判据：PWM 输出频率正确、VIO 调占空比后 LED 亮度可变、按键消抖后计数正确。

- 09-18 03:19 定时轮启动 BD6（8 位 FSM 数据通路盲评）。判据：设计正确（build+时序+下载+insight 探针验证 FSM 状态转移正确）。

- 09-18 02:52-04:5x BD5 收账：FIFO 正确+BRAM 推断成功；S1 混位宽再复现
  （危险点=坏探针集上触发仍正常命中）；S2 RAM 优化删除设计陷阱。板上 = bd5
  FIFO bit。

- 09-18 02:15 BD4 收账：SPI master 设计正确（仿真 43 帧 0 错 + 板上 13 帧全
  PASS）；新发现 V10 LA VCD 通道映射静默互换（S1 厂商）、V11 常量预警失真
  （S2）；VCD 通道映射不可信为系统性限制（insight.md 已有混位宽警告）。

- 09-18 02:15 定时轮启动 BD4（SPI master 盲评）。判据：SPI master 模式 0 设计 + LA 探针 + 仿真回环验收 + 板上下载；痛点清单。

- 09-18 01:42 BD3 收账：CDC 设计正确——双域时序全 MET、同步器最坏相位差 0、
  格雷码 1024 样本零失配、分频 2048 拍与快域相位锁定；S1 规格矛盾（判据 d
  512 拍 vs 实际 2048 拍分频）非设计缺陷；S3 ≥3 探针组合错位（V7 同源）、
  SRL16 推断使同步链失效（HQ_SRL_INFER="OFF" 解决）→ 记入 open_issues；
  11 VCD 归档 bd3\sim\。板上 = bd3 CDC 设计 bit。
- 09-18 01:18 定时轮启动 BD3（双时钟 CDC 设计盲评）。判据：快/慢双时钟域
  设计，两级同步器+格雷码握手，探针抓波验证。

- 09-18 01:18 定时轮启动 BD3（双时钟 CDC 设计盲评）。判据：快/慢双时钟域设计，两级同步器+格雷码握手，探针抓波验证。

- 09-17 08:5x A1 收账：ip_catalog.md 83 条（含 {%XX%} 占位符清理）；A2 收账：
  eco.md 14 条公开命令（clear_clock/end/forbid_route_node/icdelay.annotate/
  init/place/read/report_pin_delay/route/set_clock/set_route_points/signal_probe
  +xist.seal/sealion）+4 条内部（'eco.mindly 等）；A3 探明 XPN=comp/logical/
  cellmodel-name 格式（inspect 命令下轮实现）。
- 09-17 08:4x 用户指示：先做能力补全 TODO 再盲评。阶段 A 开跑（A1 进行中）。
- 09-18 00:10 B2-B4 审查完成：均为小幅打磨，现有实现已够用。转入阶段 C（BD 系列）。

- 09-17 08:4x 用户指示：先做能力补全 TODO 再盲评。阶段 A 开跑（A1 进行中）。
- 09-18 00:10 B2-B4 审查完成：均为小幅打磨，现有实现已够用。转入阶段 C（BD 系列）。
