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
| B2 | `-pinplan` clk 输入端口自动匹配（REF_*_CLK 候选自动选中） | 待做 |
| B3 | `-synopt` lo.slo.set 全键补全 + -device 校验 | 待做 |
| B4 | `-doctor` 增强：IO bank 电压冲突提示、多时钟设计提示 | 待做 |

## 阶段 C：复杂设计/调试盲评系列（≥30 轮，A/B 完成后开始）

| # | 任务 | 状态 |
|---|---|---|
| BD1 | UART 8N1 回环全链路（115200@25MHz，探针 rx_data/rx_done，LA 验证） | 任务书已备 |
| BD2 | 注入 bug 调试：BD1 植入 3 bug（分频错/去同步/复位极性），盲找修复 | 待做 |
| BD3 | 双时钟 CDC：两级同步器 + 格雷码握手 | 待做 |
| BD4 | SPI master 模式 0：VIO 驱动 + LA 抓波形核对 | 待做 |
| BD5 | 同步 FIFO（BRAM 推断）：满/空标志 + 读写序 | 待做 |
| BD6 | 8 位 FSM 数据通路（指令 ROM+译码+ALU）时序收敛 | 待做 |
| BD7 | PWM+按键消抖+VIO 调占空比 | 待做 |
| BD8 | 深度回归：BD1-BD7 全部重跑零回归 | 待做 |
| BD9+ | 池：I2C、CRC、看门狗、曼彻斯特、格雷码转换、脉冲整形……自主扩展 | 池 |

## 遗留/挂起（详见 open_issues.md）

- V1-V6 厂商问题（深度失真/4096 崩溃/空触发集段错误/X 通配/seed 机制/ioh I）
- SA5T 实测（待硬件）；VLA 运行侧 ddf 链（需 GUI 抓包）；-vla 全自动模板化（已定论不可行）

## 执行记录（时间序）

- 09-17 08:5x A1 收账：ip_catalog.md 83 条（含 {%XX%} 占位符清理）；A2 收账：
  eco.md 14 条公开命令（clear_clock/end/forbid_route_node/icdelay.annotate/
  init/place/read/report_pin_delay/route/set_clock/set_route_points/signal_probe
  +xist.seal/sealion）+4 条内部（'eco.mindly 等）；A3 探明 XPN=comp/logical/
  cellmodel-name 格式（inspect 命令下轮实现）。
- 09-17 08:4x 用户指示：先做能力补全 TODO 再盲评。阶段 A 开跑（A1 进行中）。

- 09-17 08:4x 用户指示：先做能力补全 TODO 再盲评。阶段 A 开跑（A1 进行中）。
