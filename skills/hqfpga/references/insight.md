<!-- 来源：hqbuddy -insight 实测（HqFpga V3.1.1 FT082326，SEALION SA30K 开发板验证通过） -->

# HqInsight 在线逻辑分析仪（CLI 全流程）

HqInsight 是 XiST 的在线逻辑分析仪（内嵌 LA IP + JTAG 回读）。GUI 操作可以全部由 `hqbuddy -insight` 的 CLI 替代，**agent 应优先走 CLI 全流程，不要要求用户开 GUI**。

前提：开发板已通过 XiST USB Cable 连接（先 `hqbuddy -cable --detect_model` 确认，见 references/download.md）。

## 两条路线

### 路线 A：全新工程，全 CLI 选信号（推荐）

```bat
hqbuddy -insight -init                              :: 初始化（elaborate 设计，建立信号数据库）
hqbuddy -insight -ls [关键字]                       :: 浏览/搜索设计信号（* = 已选入）
hqbuddy -insight -add <信号> -clk <采样时钟> -type both
hqbuddy -insight -add <信号2>                        :: 同模块后续信号不必再给 -clk
hqbuddy -insight -run                               :: 重跑插桩实现流程（几分钟）
hqbuddy -cable --sealion "<bin>" --model "SA30K" --Burst   :: 下载
hqbuddy -insight -trig "<条件>"                      :: 设触发
hqbuddy -insight -capture                           :: 布防等待触发并抓波形
```

- `-add` 的 `-type`：`sample`（只采样）/ `trigger`（只触发）/ `both`（采样+触发）。**只触发不采样的信号不会出现在波形里**；想看它的值就用 `both`。
- **红线（实测必踩坑）：至少需要 1 个 trigger-capable 信号（`-type trigger` 或 `both`）。若全部只选 `sample`，`-add` 末尾的 ddf 重建会在 `insight.debugip.create` 段错误退出（`hqfpga.exe exited abnormally (code 3221225477)` = 0xC0000005，无堆栈）。正确做法：先把你打算做触发的信号用 `-type both` 加进去，其余信号再按 sample 加。**
- 每个模块第一次加信号时必须给 `-clk` 指定采样时钟（该模块的时钟信号）。
- **`-clk` 有效性判据（隐藏失败模式）：`-clk` 给的信号必须能 `-ls` 到、且其 module 等于被加信号所在模块。** 否则 LA 采样时钟悬空，抓回的波形会**全 0**，看着像没抓到。加之前先 `hqbuddy -insight -ls <候选时钟名>` 确认它在目标模块 catalog 里（例如 DDR demo 中 `ddrc_operator_native[1]` 模块的采样时钟是 `usr_clk`）。
- **同名信号跨模块需 `-module <mod>` 消歧**：裸 `-add dq_err` 若信号存在于多个模块会报 `exists in multiple modules ... pick one with -module`。加 `-module ddrc_operator_native`（模块名可不带 `[1]` 后缀）即可。
- `-insight -del <信号>` 移除。增删信号后必须重新 `-run` + 下载才生效。
- `-init` 在工程目录创建 `hqins_run/`，不影响原设计源文件。

### 路线 B：接管 GUI 里已选好信号的工程

工程目录已存在 `hqins_run/hq_import.hqins`（GUI 里选过信号并保存）时，跳过 init/add，直接：

```bat
hqbuddy -insight                  :: 先查看状态（信号列表、当前触发条件）
hqbuddy -insight -trig ...        :: 改触发条件（不必重新 -run！）
hqbuddy -insight -capture
```

**改触发条件只重写 ddf 并重新布防，不需要重新编译和下载**——这是 CLI 最大的优势：编译一次，触发条件随便改。

## 触发条件语法（-trig）

```
<信号> <op> <值>                          算术比较：EQ/GT/LT/NE/LE/GE，值支持 10 进制和 16'h 前缀
<信号> RANGE <lo> <hi>                    范围（闭区间）
<信号> RISE | FALL | BOTH | X             边沿/任意变化（单比特信号）
<条件1> AND <条件2>  /  <条件1> OR <条件2>  双条件组合
```

例：`hqbuddy -insight -trig "dq_err GT 0"`、`hqbuddy -insight -trig "usr_dr_re_dly RISE"`。

- **操作数只能是整个已选信号，不支持位选/表达式**：`counter[7:0] EQ 0` 会报 signal not found。需要"低 8 位为 0"这类条件时，用整信号迂回表达（如 `counter EQ 0` 或 `counter RANGE 0 255`，注意 RANGE 作用于整个向量的数值）。
- 不带参数 `hqbuddy -insight -trig` 进入交互向导。

## 抓取波形（-capture）

```bat
hqbuddy -insight -capture                :: 布防，等触发（默认超时 60s）
hqbuddy -insight -capture -timeout 120
hqbuddy -insight -capture -force         :: 不等触发条件，立即抓（用于冒烟验证链路）
```

成功后输出 `hqins_run/hq_import/<top>_insight_0_ww.vcd`，并打印触发时刻各信号的值摘要。用 `hqbuddy -wave`（缺省自动检测，或指定文件）调起 HqFPGA 自带的 GTKWave 打开波形——信号名自动缩短为最后一层，且自动把所有信号加入波形视图。

- 超时未触发说明条件不满足：换更宽松的条件，或先 `-force` 确认链路本身正常。
- 触发位置默认 offset=128（触发点前保留 128 点），由 ddf storage 配置决定。

## 波形判读（避免把正常现象误报为失败）

- **延迟采样信号天然与参考值"差一拍/一 beat"**：若同时抓了经打拍的读数据（如 `usr_read_data_dly`）和由模式发生器同步推进的参考值（如 `read_data_ref`），两者在触发采样瞬间**逐字比较往往不等**——这是采样延迟，不代表校验失败。
- 因此读校验场景里 `dq_err`/`data_err` 在活跃读写时**高频非零是正常的**，不能据此断定链路坏了。要看的是这些信号确实在随读活动翻转（说明 LA 抓到了活数据），而非静止全 0/全 1。
- 判据：抓到 VCD 后确认目标数据信号在持续翻转（读 `read_data`/`read_data_ref` 类的值随时间变化）即证明链路与采样正常。若抓回**全 0**，先查 `-clk` 是否给了目标模块 catalog 内的有效时钟（见上方 `-clk` 判据），再考虑用 `-force` 冒烟验证链路。
- 注意：板卡当前 DDR 状态可能随时间漂移（偶发周期性重训/复位），同一颗 bit 在不同时刻抓可能看到不同现象，需先排除板况再归因到工具链。

## 注意事项

- `-insight -run` 末尾会自动拉起 hqdnload 下载器 GUI 窗口（flow 内置步骤，无开关），**且 hqbuddy 进程会等该窗口关闭才退出**——批处理/自动化场景要在另一端把窗口关掉，或直接等 bitgen 完成后终止。下载用 cable 命令完成，不经过 hqdnload。
- 所有 `-insight` 子命令都可加 `.hqprj` 路径指定工程，缺省用当前目录检测到的第一个。
- `-insight`（无参数）打印工程状态：已选信号（s/t/st 类型、宽度、时钟）、当前触发条件、depth/offset——动手前先跑这个。
- 若 capture 报 "no trigger condition set"，说明信号增删后 ddf 被重建、条件已重置，重新 `-trig` 即可。
