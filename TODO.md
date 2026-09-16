# hqbuddy 待办清单

> 2026-09-10 更新（2026-09-14 起并入自回归迭代框架）。按优先级排序；前 5 项来自
> insight 工具完善建议（用户批准的顺序），其余为探索过程中记录的待办。
> 完成一项就在这里勾掉并跑一次对应盲测。

## 〇、自回归迭代 Round 21+（2026-09-14 起）

框架、评价/反馈系统、板卡协议、退出条件见 `guides/autoregressive_cycle.md`。
任务池种子（按序消费，发现项随时插队）：

- [x] R21-A：FT091226 新版本升级回归——链路完好；4 项缺陷（selftest 假阴性/
      -paths 失效/-build 不执行/预检路径）全部修复+复验，bump 3.13.2（2026-09-15）
- [x] R21-B：文档债 `-selftest` / `-report -paths N` 补入 README 与 skill（2026-09-14）
- [x] R22-C：GUI 采样参数对话框探索完成（2026-09-15）——实为「虚拟逻辑分析仪(VLA)配置」：
      深度 256~65536、窗口数、触发级数、加寄存、预存拍数；.hqins 键 `0_LA:*`；
      启动契约已入 GUI 地图。**CLI 实现待做**：`-insight -depth/-windows/-level/-reg`
      （写四段 + 改后强制 -run 提示 + capture 按 depth/窗口适配，多窗口出 N 份 VCD）
- [x] R23：VIO 读写回归（2026-09-15）——链路完好，判据 a-e 全 PASS；
      S2 修复 `-reg` 逗号静默错登记（拆分+名校验）；vio.md 对位验证法修正
- [x] R24：VLA/MLA 探索（2026-09-15）——vla.cfg 全格式逆向（DEVICE INFO/TRIGGER PARAM
      逐 LA `:` 分隔/SIGNAL INFO 行格式）、MLA 布防与轮询机制、GUI 多 LA 入口（+按钮）；
      CLI 三级实现设计入 GUI 地图 §8。**实现待做**（深度/窗口 → MLA → VLA 编译编排）
- [x] 收官：夜间自回归迭代 R21-R29 完成（2026-09-15 08:00）——总账见
      `guides/night_report_20260915.md`；12 项修复、6×S1 全部闭环；版本 3.13.3
- [x] R34b：hq_vla_ins.exe 调用契约捕获成功（2026-09-16）——产物四件套
      （xsIP_VLA.v/hqip/cfg/t.tcl）留存；HQ_VLA0 属性行=第三方综合的配置载体
- [x] R36b：`-vla -gen` 半自动上线（2026-09-16）——按 R34b 契约调起官方向导+
      产物自动检测（端到端验证）；全自动模板化（probe_port 解析）与运行侧
      （VLA 抓取 ddf/SVF）继续逆向
- [x] R34c：第三方网表 ModelSim 门级仿真链验证（2026-09-16）——simlib/vlog/25µs 仿真全通，LFSR 序列 2492 拍零失配；vsim -voptargs=+acc 与 VCD 解析坑入档
- [x] 第二夜收官（2026-09-16 08:20）——R30-R42 共 14 轮；第三方综合全链路
      CLI 化（-edf2v/-netlist_build/-vla -gen/-copy_prj 四条新命令）+ depth 参数 +
      capture 防护 + ModelSim 门级仿真验证；总账见 `guides/night_report_20260916.md`
- [x] R43：深度生效链路逆向定论（2026-09-16）——流程消费 ddf 不读 .hqins
      深度；改深度触发厂商流程崩溃（4096 稳定复现）；保持 1024，待厂商
- [x] R44：-vla -gen 全自动模板化分析定论（2026-09-17）——结构耦合不可安全
      模板化，关闭；交付 1-probe 参考件 templates/vla/ + 例化契约
- [ ] 白天优先：VLA 运行侧逆向；边沿×混位宽交叉复测；
      4096 崩溃厂商反馈（R43 素材齐）
- [ ] 待排：`-vio -read -interval`；SA5T 板卡实测；X 通配触发；`-vio -read -interval`；
      SA5T 板卡实测；X 通配触发；
      多窗口/多级触发 CLI 化（并入 R22-C 实现项）；边沿方向专项（1-bit 专用设计）；
      陈旧布防代际自动检测；`-copy_prj`
- [x] R25：触发矩阵回归（2026-09-15）——**抓到 2×S1 真回归并修复**：NOT 取反硬件
      丢弃（算术取反自动改写等价算子）+混合位宽打包损坏复现（信号集戳记+capture
      强警告）；S2 边沿语义待干净复测（R26）。bump 3.13.3
- [x] R29：违例工程 -paths 盲测（2026-09-15）——抓到 S1 重复段不去重+S2 端点截断，
      均修复并对照 ground truth 通过；标签三态化；排序语义文档注明
- [x] R31：边沿方向专项（2026-09-15）——边沿语义正确，R25 恒真误判推翻
      （混位宽坏数据所致）；-add 混位宽警告上线；overflow 判读规则修正（R31 实证）
- [ ] 小项：-del 时 hqfpga 偶发段错误 0xC0000005（R18/R31 两次观察，重试即恢复，
      向厂商反馈候选）；overflow=True 时触发点判读语义已按 R31 修正入档；
      `-copy_prj` 候选（.hqprj 复制绝对路径自引用，S3，R29）；
      `-insight` 报错文案中英混排统一（S2，R21）；`-selftest` 列入 -h 帮助（S3，R21）；
      `cnt[7]` not found vs `cnt[7:7]` 静默归一化整总线行为不一致（S3，R25）；
      RISE AND FALL 折叠为 BOTH 缺文案（S3，R25）

## 一、insight CLI 完善（按用户批准顺序）

### 1. 组合触发可靠性 ✅（2026-09-10 完成）
- [x] 修复 `_is_combined_trigger` `==2` → `>=2`（3+ 条件曾被静默降级为单条件）
- [x] 修复 cwd 根因：`la_set_trig_cond` 解析操作数比较值依赖 CWD，
      SVF 会话固定从 `hqins_run/` 运行（GUI 约定）
- [x] 同信号 AND 链自动折叠（硬件每信号仅 1 个比较单元）：
      `EQ 128 AND NE 0 → EQ 128`；RANGE 求交集；矛盾/不可表达组合清晰报错
- [x] 盲测验证：round-3 9/9 全 PASS（折叠/跨信号 AND 值精确/OR/回绕边界/报错文案）
- 残留：同信号 OR 链已实测可用但未覆盖折叠；条件级取反 bit 语义（NOT A AND B 的
  硬件传播）未穷尽，遇可疑现象先单条件化再排查

### 2. `-capture` 位流过期预警 ✅（2026-09-10 完成）
- 比较 `hqins_run/hq_import/hqins_impl/<工程>.bin` 与 `.hqins`（及最近 -add）的
  mtime，位流更旧则在 `-capture` 布防前警告"板上 bit 可能过期，先 -run+下载"
- 动机：本轮两次踩"陈旧 bit → 全 X/垃圾波形"，每次浪费一轮抓取才定位
- 预计 30 分钟；完成后拉子 agent 盲测（故意用错 bit 验证警告触发）

### 3. `$WORK_DIR$` 约束路径坑写入 skill 文档 ✅（2026-09-10 完成）
- insight 流程（run_hqprj2hqins_flow）cwd 是 `hqins_impl/`，FILE_TC/FILE_PC
  相对路径读不到 → 流程"成功"却无 bin（产物校验可兜底，但根因要写文档）
- 顺带：`-new_prj` 模板补齐后写入 .hqprj 的路径应自动加 `$WORK_DIR$` 前缀
- 预计 15 分钟；盲测：让 agent 从零建工程跑通 insight 全链路

### 4. `-add` 总线片选 ✅（2026-09-10 完成）
- GUI 支持 `[SIGNAL JSON INFO]` 的 `slice_msb/slice_lsb`（当前恒写全宽）
- 语法：`hqbuddy -insight -add sig[7:0] ...`；省 LA 位宽资源（深度固定 1024）
- 涉及 ddf/la_list/VCD 命名联动，中等工程量；盲测：片选后 VCD 位宽与值正确

### 5. 最小回归自测命令 ✅（2026-09-10 完成）
- 把 cli_gui_cmp 确定性对照实验固化为 `hqbuddy -insight -selftest [<dir>]`
- 内容：下载插桩 bit → 布防 sig EQ 128 → 抓取 → 校验 1024 样本 +1 序列 →
  （可选）CLI/GUI SVF 载荷一致性
- 动机：HqFPGA 升级后一条命令验证链路没坏；盲测：升级模拟/全新环境跑通

## 二、insight 已知边界（无需开发，文档已载明）
- 多条件组合触发前提：板上必须是当前 .hqins 对应的插桩 bit（写错 bit 会产生
  永不触发/乱触发假象）
- 板况分相：DDR 等设计下载后 1~2 分钟为训练期，涉及训练期才有的状态要立即布防
- 触发判定 ±1 拍偏斜：判读用窗口（trig-1 ~ trig+2），不用单点

## 三、VIO / 其他（探索中记录）
- [ ] VIO + LA 组合（VLA 模式，`-is_ip_mode`/`-vio_out_value`）：需更深逆向
- [ ] 多 LA（MLA，最多 2 个，双时钟域）：`insight.sealion.mla.*` 命令族
- [ ] 多窗口触发（一次抓 N 个事件窗，4×N TDO 解析）
- [ ] 多级触发（TRIGGER LEVEL>1，顺序触发语义待逆向）
- [ ] X 通配值触发（ddf mask 已支持，CLI 语法层待加，硬件行为未验证）
- [ ] `-vio -read` 高频轮询模式（GUI 有 auto-refresh，CLI 循环即可但可加 -interval 0.2）
- [ ] vio.md 补充"VIO 与 LA 板上互斥（一次一个 bit）"已写；再加编译期
      JTAG 槽冲突（ERROR PHY-PLA-665）案例

## 四、工程化
- [x] 本地 commit 已全部推送（2026-09-12）；20 轮盲评完成（guides/blind_eval_log.md）
- [ ] `hqbuddy/__init__.py` 版本号在下一批功能合并时 bump 到 3.11.0
- [ ] docs/insight_re/（反编译笔记、实验脚本）保持本地不入库（已在 .gitignore）
