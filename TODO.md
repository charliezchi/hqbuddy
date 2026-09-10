# hqbuddy 待办清单

> 2026-09-10 更新。按优先级排序；前 5 项来自 insight 工具完善建议（用户批准的顺序），
> 其余为探索过程中记录的待办。完成一项就在这里勾掉并跑一次对应盲测。

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
- [ ] 本地 commit 已全部推送（2026-09-10）；后续每完成一项待办 commit+push
- [ ] `hqbuddy/__init__.py` 版本号在下一批功能合并时 bump 到 3.11.0
- [ ] docs/insight_re/（反编译笔记、实验脚本）保持本地不入库（已在 .gitignore）
