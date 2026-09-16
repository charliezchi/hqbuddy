# hqbuddy 自回归迭代收官报告·第二夜（2026-09-16 08:00）

> 运行区间：2026-09-15 22:30 → 09-16 08:20（40 分钟节奏连续轮转；8:00 后进入收官）。
> 主题：**第三方综合协同（技巧 006/009）新能力 + 遗留清账 + 静默回归**。
> 逐轮详情：`guides/blind_eval_log.md`；接力状态：`guides/iteration_state.md`；
> 上一夜收官：`guides/night_report_20260915.md`。

## 一、轮次总账（R30-R42）

| 轮 | 主题 | 结果 |
|---|---|---|
| R30 | 第三方综合 skill 文档盲评（独立 agent 仅凭文档复现） | ✅ 链路通；**10 条文档缺陷全数补齐**（.prj 模板/文件衔接/约束前置/退出码语义/bitgen 假成功等） |
| R31 | 边沿方向专项（专用 1-bit 翻转信号） | ✅ **边沿语义正确**（RISE 0→1 3/3、FALL 1→0 3/3、AND 链真实参与、负控永不触发）；**推翻 R25"恒真"误判**；混位宽损坏复现 → -add 警告上线 |
| R32 | -depth/-windows/-level 实现+板上验证 | ✅ 写入/校验/幂等通过；**发现 -run 不消费 .hqins 深度**（S1）→ capture 一致性拒绝上线 |
| R33 | -edf2v / -netlist_build 产品化 | ✅ 5/5 验收（bin 与手工链路同尺寸）；ERROR( 汇总防御意外实证 |
| R34 | VLA 生成链逆向（ipdepot + hqui） | ✅ 生成链摸清；CLI 生成不可行的原因定位 |
| R34b | VLA 生成器命令行捕获 | ✅ **hq_vla_ins.exe 契约捕获**（-device/-lang/-output_module/...）；产物四件套留存 |
| R34c | ModelSim 门级仿真 | ✅ **可用**——simlib 454 单元 0 错、25µs 无 error、LFSR 2492 拍零失配（周期 255 实证） |
| R35 | -copy_prj 实现 | ✅ 复制+路径改写+时间戳重建；-filelist/-init 双验证 |
| R36 | 小项清理 | ✅ 7 条报错改中文+指引；vio.md/hqbuddy.md 补齐 |
| R36b | -vla -gen 上线 | ✅ 按 R34b 契约调起官方向导+产物自动检测（端到端验证） |
| R37-R42 | 静默回归 ×6 | ✅ 基线抓取/report/filelist/init 幂等/VIO 抽测/文档审计——R40 抽检发现 -copy_prj 缺帮助行（已补） |

累计本地 commit 14 次（4b67925.. 收官本条），**未 push**。

## 二、新能力清单（本夜交付）

1. **第三方综合全链路 CLI 化**（技巧 006）：Vivado/Synplify → EDIF → HqFpga
   P&R → bin → 下载，双路线实测上板；`-edf2v` / `-netlist_build` 两条新命令；
   skill 新文档 `references/thirdparty_synthesis.md`（含 mbin license 坑、
   Artix7 写法、-family DVST001 边界、bitgen 静默假成功等全部实测坑）。
2. **采样参数 CLI**：`-insight -depth/-windows/-level`（写入 + 校验 + 幂等 +
   触发位置上界），capture 深度/窗口一致性拒绝（防静默错位）。
3. **-vla -gen 半自动生成**：按 R34b 契约调起官方 VLA 向导 + 产物自动检测；
   vla.cfg / HQ_VLA0 属性 / 生成器契约全逆向入档（GUI 地图 §8）。
4. **-copy_prj**：工程复制 + FILE 路径改写 + 时间戳重建（R29 痛点闭环）。
5. **防御与体验**：-add 混位宽警告、capture 信号集戳记、BOTH 折叠提示、
   7 条报错中文化、-selftest/-paths/-copy_prj/-vla 进 help。

## 三、发现与修复分级

- **S1（2 项，均已修）**：
  1. capture 深度/窗口泄漏静默错位（.hqins ≠ ddf 时触发点错位+通道损坏）→
     一致性拒绝（R32 板上实测）；
  2. slack.rpt 重复段不去重（-paths top-N 失真+计数翻倍）→ `_slack_records`
     去重（R29，ground truth 核对）。
  - 另：R31 复现混位宽打包损坏（S1 级工具链限制）→ 警告+文档（硬件限制，
    修复需厂商侧）。
- **S2（已修/缓解）**：-reg 逗号错登记（上夜）；bitgen 静默假成功 → makedirs+
  校验；陈旧布防假触发 → 警告补"重新 -trig"。
- **S3 认知修正（入档）**：边沿方向语义正确（R25 恒真误判推翻，系坏打包数据）；
  LFSR 可观测等价式 `led(n)=~(led(n-4)^led(n-5)^led(n-6)^led(n-8))`（周期 255
  实证）；overflow 标志不改变标记点判读效力（R27 保守规则按 R31 实证修正）；
  混位宽=数据静默损坏（探针集合必须同宽）；VLA 生成契约与 hqip 格式全逆向。
- **遗留（按优先级）**：
  1. 深度生效链路（-run 消费 .hqins 深度 → ddf/插桩 IP ADDR_WIDTH）——需逆向
     GUI 写深度后的 elaborate 消费点（R32）；
  2. -windows>1 的布防/轮询/多 VCD capture（依赖 1）；
  3. VLA 运行侧（insight.load 的 ddf + VLA 抓取 SVF）与 `-vla -gen` 全自动
     模板化（probe_port 解析）；
  4. -del 时 hqfpga 偶发段错误（2 次观察，厂商反馈候选）；
  5. 小项：overflow 专项、片选行为统一、中英文案扫尾、SA5T 板卡实测。

## 四、板卡与环境状态

- 板卡：**SA50K**（SA5Z-50-D0-7F484C），JTAG 空闲；板上 = r21a 干净基线
  bit（cnt/lfsr both，触发 EQ 200 AND NE 0，深度 1024/1/1），2026-09-16 07:05
  验证后未再动。
- 工具链：HqFPGA FT091226；hqbuddy **3.13.4**（本夜新增 -edf2v/-netlist_build/
  -vla/-copy_prj 与全部修复，源码与 PATH exe 同步）。
- 测试区：r21a（LA 基线+dbg_out 混位宽备份）、r23vio（VIO 工程）、r28soc
  （SoC 工程）、r29viol（违例工程）、r30syn（第三方综合+VLA IP 产物+sim_ms
  门级仿真区）、r36cp（复制工程）——均可复用。
- 自动化：40 分钟节奏定时任务在 8:30 后仅空转（时间守卫），可直接删除。

## 五、白天建议

1. 深度生效链路逆向（R32 S1 根因——GUI 写深度后哪一步消费它）；
2. `-vla -gen` 全自动模板化（hqip probe_port 解析）+ VLA 运行侧逆向；
3. 边沿×混位宽交叉复测（在厂商修复混位宽前仅用同宽探针）；
4. 静默回归转日常：每次 HqFPGA 升级跑一遍回归集（selftest 思路+触发矩阵+错误路径）。
