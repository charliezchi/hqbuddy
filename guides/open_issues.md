# 遗留问题单（待用户/厂商解决）

> 盲评与回归迭代中**Agent 无法解决**的问题集中于此，供用户决策或向智多晶反馈。
> 每条附复现素材位置。解决后请移入 blind_eval_log.md 的"已解决"段。

## 厂商问题（需智多晶修复/答复）

| # | 问题 | 级别 | 素材 |
|---|---|---|---|
| V1 | **depth>1024 触发语义失真**：depth=2048 结构生效（2049 样本/cc 13 位）但触发比较或标记锚定错位（te 窗口 cnt≈129-134，条件 EQ 200 的 8 个匹配点全不在窗内）；4096 使 run_hqprj2hqins_flow 直接崩溃（0xFFFFFFFF，稳定复现）。生产只能用 1024。 | 高 | blind_eval_log R43/R43b；素材 r21a（VCD+ddf 快照已删，可按 R43b 步骤复现） |
| V2 | **insight.debugip.create 空触发集段错误**：删除最后一个触发信号后 ddf 触发集为空，debugip.create 必崩 0xC0000005（与"全 sample 红线"同源）。hqbuddy 已加拒绝防护，但 GUI 用户仍会踩。 | 高 | r47del/vendor_feedback/（post_del.ddf+TCL+日志+README） |
| V3 | **X 通配触发判定矛盾**：`cnt EQ xxxxx000` mask 正确写入 ddf（11111000），板上触发但触发点样本不满足掩码语义、VCD trigger_event 全 0 与"已触发"输出矛盾。 | 中 | blind_eval_log R49；复现步骤齐 |
| V4 | **'npl.set_seed 无参 U-command**：不接受数值参数（ARGF017），多种子扫描只能用 design.place -seed N（已产品化，无阻塞性）。 | 低 | R54 |
| V5 | **insight.check 输出为 TCL 返回值**而非 FLAG:VLA:x 打印行（hqbuddy 更上层封装或版本差异），CLI 解析需按返回值处理。 | 低 | R45 |
| V6 | **ioh.get_ports I（输入端口）实现前不产出**——引脚规划只能覆盖输出端口，clk 类输入靠启发式。 | 低 | R56 |

## 待用户决策/提供

| # | 事项 | 说明 |
|---|---|---|
| U1 | SA5T-100/200 板卡实测 | 需要硬件在位；boards 资料已齐 |
| U2 | 定时任务节奏 | 当前无定时任务（白天手工驱动）；需要恢复 40 分钟无人值守请说明 |
| U3 |智多晶反馈渠道 | V1/V2/V3 素材齐备，请提供 FAE 对接或确认由用户自行反馈 |
