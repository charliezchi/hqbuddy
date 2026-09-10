<!-- 来源：hqbuddy -insight 实测（HqFpga V3.1.1 FT090526，SA30K 开发板验证通过）+ hq_ins GUI 反编译逆向（docs/insight_re，本地） -->

# HqInsight 在线逻辑分析仪（CLI 全流程）

HqInsight 是 XiST 的在线逻辑分析仪（内嵌 LA IP + JTAG 回读）。GUI 操作可以全部由 `hqbuddy -insight` 的 CLI 替代，**agent 应优先走 CLI 全流程，不要要求用户开 GUI**。

前提：开发板已通过 XiST USB Cable 连接（先 `hqbuddy -cable --detect_model` 确认，见 references/download.md）。

## 两条路线

### 路线 A：全新工程，全 CLI 选信号（推荐）

```bat
hqbuddy -insight -init                              :: 初始化（elaborate 设计，建立信号数据库）
hqbuddy -insight -ls [关键字]                       :: 浏览/搜索设计信号（* = 已选入，含层次路径）
hqbuddy -insight -add <信号> -clk <采样时钟> -type both
hqbuddy -insight -add <信号2>                        :: 同模块后续信号不必再给 -clk/-module
hqbuddy -insight -run                               :: 重跑插桩实现流程（几分钟；完成会拉起 hqdnload 下载 GUI 并阻塞直至关窗，见注意事项）
hqbuddy -cable --sealion "<bin>" --model "SA30K" --Burst   :: 下载（bin 产物路径见 -run 后下方说明）
hqbuddy -insight -trig "<条件>"                      :: 设触发
hqbuddy -insight -capture                           :: 布防等待触发并抓波形
```

- `-add` 的 `-type`：`sample`（只采样）/ `trigger`（只触发）/ `both`（采样+触发）。**只触发不采样的信号不会出现在波形里**；想看它的值就用 `both`。**触发（trigger/both）信号会占用 LA 的 trigger 逻辑资源**，非必须做触发条件的信号一律用 `sample` 即可（实测 8 信号里 2~3 个 `both`、其余全 sample 运行良好）。
- **红线（实测必踩坑）：至少需要 1 个 trigger-capable 信号（`-type trigger` 或 `both`）。若全部只选 `sample`，`-add` 末尾的 ddf 重建会在 `insight.debugip.create` 段错误退出（`hqfpga.exe exited abnormally (code 3221225477)` = 0xC0000005，无堆栈）。正确做法：先把你打算做触发的信号用 `-type both` 加进去，其余信号再按 sample 加。**
- **触发信号尽量选"综合后仍存在且必然翻转"的信号**（FSM state、计数器、使能打拍等）。组合逻辑中间信号、被综合吸收的使能/译码信号可能 tap 到常量——波形恒 0、任何触发条件都不触发（详见下方"插桩探针陷阱"）。选不准就多加一个计数器类信号做保底。
- 每个模块第一次加信号时必须给 `-clk` 指定采样时钟（该模块的时钟信号）。
- **`-clk` 有效性判据（隐藏失败模式）：`-clk` 给的信号必须能 `-ls` 到、且其 module 等于被加信号所在模块。** 否则 LA 采样时钟悬空，抓回的波形会**全 0**，看着像没抓到。加之前先 `hqbuddy -insight -ls <候选时钟名>` 确认它在目标模块 catalog 里（例如 DDR demo 中 `ddrc_operator_axi[1]` 模块的采样时钟是 `aclk`）。
- **同名信号跨模块需 `-module <mod>` 消歧**：裸 `-add dq_err` 若信号存在于多个模块会报 `exists in multiple modules ... pick one with -module`。加 `-module ddrc_operator_axi`（模块名可不带 `[1]` 后缀）即可；若上一个信号已在目标模块，上下文会自动消歧，无需再给。
- **`-clk` / `-module` 上下文延续**：同一模块内，首个信号给过 `-clk`（和/或 `-module`）后，**后续同模块信号的 `-clk` 与 `-module` 均可省略**，会自动沿用并用于歧义消解。只有当要加的信号属另一模块、或上下文无法消歧时才需重新指定。
- `-insight -del <信号>` 移除。增删信号后必须重新 `-run` + 下载才生效。
- `-init` 在工程目录创建 `hqins_run/`，不影响原设计源文件。
- **`-run` 之后可下载的位流产物在 `hqins_run/hq_import/hqins_impl/<工程名>.bin`**（下载时 `--sealion` 指向它，不是工程根的 run_hqprj.tcl 产物；`-run` 末尾自动拉起的 hqdnload GUI 预填的是**普通工程 bin，是错的**，别照着窗口里的路径下载）。

### 路线 B：接管 GUI 里已选好信号的工程

工程目录已存在 `hqins_run/hq_import.hqins`（GUI 里选过信号并保存）时，跳过 init/add，直接：

```bat
hqbuddy -insight                  :: 先查看状态（信号列表、当前触发条件）
hqbuddy -insight -trig ...        :: 改触发条件（不必重新 -run！）
hqbuddy -insight -capture
```

**改触发条件只重写 ddf 并重新布防，不需要重新编译和下载**——这是 CLI 最大的优势：编译一次，触发条件随便改。

## 双板/多板环境与 model 校验

- `hqbuddy -cable --sealion <bin> --model <M>` 下载前会自动 `--detect_model` 校验：
  model 与板上实际型号不符会直接拒绝（防止把别的 bit 编进错误的板，导致之后
  LA 触发/抓波形全部异常——异常特征是采样时钟在走、数据通道恒值）。
- 多板环境换工程验收时，务必确认下载的 bit 与板上板卡对应。

## 采样时钟与信号增删规则（硬件限制）

- **每个 LA 只支持一个采样时钟**（GUI 采集模式同样强制）。`-init` 后第一次 `-add -clk` 确定时钟；之后所有信号（无论哪个模块）都并入该时钟组，`-clk` 与现有时钟不同会被拒绝并提示。
- **约束路径必须 `$WORK_DIR$` 前缀**：insight 流程的 cwd 是 `hqins_impl/`，
  FILE_TC/FILE_PC 写相对路径（`cons/xx.sdc`）会读不到 → 流程"成功"却无 bin。
  正确写法：`FILE_TC=$WORK_DIR$cons/xx.sdc`。产物校验（新版内置）会兜底报错。
- 跨时钟域信号：确认其确实由现采样时钟驱动（同同步域）后可去掉 `-clk` 直接添加；若它属于别的时钟域，采样到的会是常数或无效值——这不是工具 bug。
- GUI 模式模型：**采集模式**（插桩器）里增删信号；**调试模式**里只能运行采集（触发/抓波形）。改信号必须 `-run`+重新下载；改触发/抓取不用。
- 同信号多条件（AND 链）会自动折叠为单条件（硬件每信号一个比较单元）；矛盾或不可表达的组合（如 `NE 0 AND NE 7`、混用 NOT）直接报错并给出改写建议。

## 触发条件语法（-trig）

```
<信号> <op> <值>                          算术比较：EQ/GT/LT/NE/LE/GE，值支持 10 进制和 0x 16 进制
<信号> RANGE[_C|_LC|_RC] <lo> <hi>        范围：RANGE=开区间(GT,LT)、_C=闭区间(GE,LE)、_LC=GE..LT、_RC=GT..LE
<信号> RISE | FALL | BOTH | X             边沿/任意变化（单比特信号）
<条件1> AND <条件2> [AND <条件3> ...]      多条件链（全部 AND 或全部 OR，不得混用；≥2 个条件时必须写连接词）
NOT <条件>                                单条件取反；--negate 结尾 = 整体取反
```

例：

```bat
hqbuddy -insight -trig "dq_err GT 0"
hqbuddy -insight -trig "usr_dr_re_dly RISE"
hqbuddy -insight -trig "state EQ 4" AND "data_err RISE" AND "dq_err NE 0"   :: 3 条件 AND 链
hqbuddy -insight -trig "state RANGE_C 2 5" AND "NOT dq_err GT 0"
```

- 硬件模型（反编译+实测确认）：每个 trigger-capable 信号有独立的比较单元（EDGE/ARITHM/RANGE 三选一生效），条件链把它们按单一 AND（或 OR）组合，可对每个条件取反、可整体取反。**不支持括号嵌套/混合 AND+OR**（GUI 也只生成扁平链）。
- 条件数不限于 2：N 个条件生成 N 个操作数。但触发条件里只能引用 trigger/both 类型信号；`sample` 信号会报 `signal is sample-only, cannot trigger`。
- **同信号多条件自动折叠**：硬件上每个触发信号只有一个比较单元，`sig EQ 128 AND sig NE 0` 这类同信号 AND 链会被自动折叠成语义等价的单条件（EQ 128）；矛盾（EQ 1 AND EQ 2）或不可表达（NE 0 AND NE 7、混用 NOT）会直接报错并给出改写建议。RANGE 相交自动求交集。OR 链不做折叠（同信号 EQ|EQ 已实测可用）。
- **多条件组合触发：已修复并板级验证**。历史版本存在关键 bug：`la_set_trig_cond` 解析操作数比较值依赖 CWD，必须从 `hqins_run/` 运行（GUI 约定）；从工程根运行会导致操作数比较值丢失——同信号 AND 链变恒真（乱触发）、跨信号 AND 永不触发。当前 hqbuddy 已固定从 `hqins_run/` 运行 SVF 会话，2/3 条件 AND/OR/取反均正确命中（确定性设计双构建验证：触发值与条件精确吻合）。使用前提不变：板上必须是当前 .hqins 对应的插桩 bit。
- **操作数只能是整个已选信号，不支持位选/表达式**：`counter[7:0] EQ 0` 会报 signal not found。需要"低 8 位为 0"这类条件时，用整信号迂回表达（如 `counter EQ 0` 或 `counter RANGE 0 255`，RANGE 作用于整个向量的数值）。
- 不带参数 `hqbuddy -insight -trig` 进入交互向导。
- 触发条件写入 3 个文件（`trigger_expr.json` / `trigger_cond.json` / `.ddf`）+ `.hqins` 的 `[EXPRESSION OPERATION]` 段，GUI 重新打开也能看到。**改触发只重写文件，下次 -capture 直接生效，无需重新编译下载。**

## 抓取波形（-capture）

```bat
hqbuddy -insight -capture                :: 布防，等触发（默认超时 60s）
hqbuddy -insight -capture -timeout 120
hqbuddy -insight -capture -force         :: 不等触发条件，立即抓（用于冒烟验证链路）
hqbuddy -insight -capture -o hqins_run/hq_import/run1   :: 自定义输出前缀（产 run1_0_ww.vcd）
```

成功后输出 `hqins_run/hq_import/<top>_insight_0_ww.vcd`，并打印触发时刻各信号的值摘要。用 `hqbuddy -wave`（缺省自动检测，或指定文件）调起 HqFPGA 自带的 GTKWave 打开波形——信号名自动缩短为最后一层，且自动把所有信号加入波形视图。

- **多次抓取默认输出同名文件会互相覆盖**：需要保留对比时用 `-o` 区分（或抓后自行改名）。
- 超时未触发说明条件不满足：换更宽松的条件，或先 `-force` 确认链路本身正常。
- 触发位置默认 offset=128（触发点前保留 128 点），由 ddf storage 配置决定。
- **建议流程：布防后先用短超时（如 30s）抓一次。超时就换信号/条件，别死等。**
- **触发超时的第一排查项：板上 bit 是否对应当前 .hqins**（换设计/换信号后忘了重新 -run+下载是最常见原因）。
- **板况分相**：刚下载后的 1~2 分钟是 DDR 训练期（FSM 全状态轮转、burst 计数大范围变化、数据错误脉冲频繁），之后进入稳态（FSM 只剩少数状态、burst 模式固定）。涉及"训练期才出现的状态/计数值"的触发条件只在训练期有效——下载后**立即**布防这类条件。
- **触发标记点的取值有一拍级流水偏斜**：trigger_event 所在样本的原始值不一定逐字满足触发条件（比较通路与存储读出通路对齐差一拍），硬件触发本身真实发生。报告"触发时刻的值"时，用工具摘要与 VCD 中 trigger_event 附近波形交叉确认，别只看单点。

## 插桩探针陷阱（触发永不命中的头号原因）

**症状：`-capture` 永远超时，但 `-force` 抓回的 VCD 里其它信号活跃翻转。**

原因：LA 只能 tap 综合布线后**仍然存在**的 net。如果信号被综合吸收（如使能信号并进下游寄存器的 CE、译码中间量被优化、net 改名后 tap 到 tie-off），LA 看到的就是常量——该信号波形恒 0/恒 1，任何触发条件（含 `EQ 1`、`RISE`）都不会命中。这**不是工具 bug**：实测同一设计中 `data_err`（比较器输出寄存器）秒级触发，而 `usr_dr_re_dly`（被吸收的使能打拍）恒 0 不触发。

排查步骤：

1. `-capture -force` 抓一段，数目标信号的翻转次数（读 VCD 数 value changes，或看摘要里是否恒值）。
2. 波形里恒值 → 换一个"寄存器型"的触发信号（FSM state、计数器、带打拍的标志位），或重新综合时对该信号加 `(* keep *)` / `dont_touch` 属性后重跑 `-run`。
3. 波形里在翻转但触发了 → 判读问题，见下节。

## 波形判读（避免把正常现象误报为失败）

- **延迟采样信号天然与参考值"差一拍/一 beat"**：若同时抓了经打拍的读数据（如 `usr_read_data_dly`）和由模式发生器同步推进的参考值（如 `read_data_ref`），两者在触发采样瞬间**逐字比较往往不等**——这是采样延迟，不代表校验失败。
- 因此读校验场景里 `dq_err`/`data_err` 在活跃读写时**高频非零是正常的**，不能据此断定链路坏了。要看的是这些信号确实在随读活动翻转（说明 LA 抓到了活数据），而非静止全 0/全 1。
- 判据：抓到 VCD 后确认目标数据信号在持续翻转（读 `read_data`/`read_data_ref` 类的值随时间变化）即证明链路与采样正常。若抓回**全 0**，先查 `-clk` 是否给了目标模块 catalog 内的有效时钟（见上方 `-clk` 判据），再考虑用 `-force` 冒烟验证链路。
- 注意：板卡当前 DDR 状态可能随时间漂移（偶发周期性重训/复位），同一颗 bit 在不同时刻抓可能看到不同现象，需先排除板况再归因到工具链。

### VCD 解析要点（agent 写脚本时）

- 标准格式但**只记变化值**：必须按时间戳做值保持（value-hold）重建后再读"某时刻的值"，直接逐行读会把静态信号误判成"无数据"。
- `trigger_event` 是工具插入的触发标记信号，首次拉高的时间戳即触发点（与 -capture 输出的 "Trigger at #N" 一致）。
- 文件末尾最后一个时间戳（=depth，如 #1024）是 dump 工具的终止重 dump 伪影，真实采样为 depth 个（#0..#1023）。
- `$var` 名是完整层次路径 + 位选后缀；按短名匹配信号时取路径最后一段并剥掉 `[msb:lsb]` 后缀。
- 可用 `clock_cycle`（LA 内置采样计数器，11 位回绕）验证采样连续无缺口。

## CLI 与 GUI 等效性（已实测验证）

用确定性计数器设计做过对照：同一工程、同一触发条件（sig EQ 128），CLI（`-trig`+`-capture`）与 GUI（调试模式运行）各自布防抓取，产物 VCD 逐样本比对**完全一致**（触发点同为 #128，sig 全程确定 +1）。agent 可以放心全 CLI 工作流，不需要开 GUI 复核。

实验附带注意事项：
- GUI 调试运行前要在已标记信号列表里选中触发信号行，否则报"请先选择一个LA触发信号"。
- GUI 运行会清理同目录旧调试产物；CLI 侧用 `-o` 命名可避免被清/混淆。

## 注意事项

- `-insight -run` 末尾会自动拉起 hqdnload 下载器 GUI 窗口（flow 内置步骤，无开关），**且 hqbuddy 进程会等该窗口关闭才退出**——批处理/自动化场景要在另一端把窗口关掉，或直接等 bitgen 完成后终止。下载用 cable 命令完成，不经过 hqdnload。
- 所有 `-insight` 子命令都可加 `.hqprj` 路径指定工程，缺省用当前目录检测到的第一个。
- `-insight`（无参数）打印工程状态：已选信号（s/t/st 类型、宽度、时钟）、当前触发条件、depth/offset——动手前先跑这个。
- 若 capture 报 "no trigger condition set"，说明信号增删后 ddf 被重建、条件已重置，重新 `-trig` 即可。
- **改信号（-add/-del）必须 -run+下载；只改触发（-trig）/抓取（-capture）不用。**

## 逆向参考：GUI 未暴露但硬件支持的能力（来自 hq_ins.exe 反编译 + hqfpga TCL help）

以下能力已逆向确认，尚未全部封装进 CLI；需要时按此扩展：

- **VIO（Virtual IO，运行时驱动/采样管脚）**：独立于 LA 的调试 IP，工程目录 `hqvla_vio/`（`hq_vio.prj` + `[SIGNAL INFO]` 段：`序号=信号名=input|output=位宽[=初值]`）。编译流程 `run_hqprj2hqvio_flow`；运行时 `insight.svf_generator.vio_write -value <N>'b<LSBfirst串> -radix_type Binary -is_vla_mode True` 写输出探针、`vio_read -bit_length <总输入位宽>` 读输入探针（TDO 取低 N 位、按 LSB-first 切分）。SVF 生成无需 ddf。LA+VIO 联合模式叫 VLA（`-is_ip_mode`，采样参数对话框里的 VLA_0）。**multi-LA 下不支持 trigger-VIO**。
- **多窗口触发（multi-window）**：`[TRIGGER MULTI-WINDOW]` >1 时每 LA 的存储划成 N 个窗口，合法触发位置 `0 ≤ pos ≤ depth/窗口数 − 5`（窗口数取 2 的幂）。布防时多发 `la_window_num`，状态轮询读 `4×窗口数` 个 TDO、每窗口 done 全真才算完；dump_vcd 一次出 N 个 VCD。
- **多 LA（MLA，最多 2 个）**：不同时钟域各挂一个 LA（右键 LA_0 页添加 LA_1）。`insight.sealion.mla.*` 命令族；同时运行时两个 LA 都要设触发条件；不支持连续触发。
- **连续触发**：采集模式下拉的"连续触发"= 布防→抓→再布防循环（`is_continuous True`），GUI 间隔 `continuous_interval_time`；CLI 用脚本循环单次抓取等效。
- **`[EXPRESSION OPERATION]`（.hqins 段）**：`00`=AND、`01`=NOT(AND)、`10`=OR、`11`=NOT(OR)，与 `-expr_op` 编码一致；GUI 调试器靠它恢复组合状态。
- **组合触发编码（已实证）**：SVF 由 `trigger_cond.json` 每个操作数的 `operation` 4bit 驱动：`0011`=AND 链、`0101`=OR 链、bit3=该单元取反（`1011`/`1101`）；`signal_id`（B0/B1/...）纯符号可任意改名（SVF 逐位不变，已 diff 实证）；`expression` 字符串 GUI 记账用，hqfpga 不解析。B 编号在 GUI 界面按触发信号的**添加顺序**显示（B0=最先加的 trigger 信号）。
- **ddf 合法值（insight.load 实测）**：EDGE `<op>` 只认 `RISE`/`FALL`（BOTH 边沿 = RISE + `<mask>` 全 1；X = 该单元 ignore=yes）；ARITHM op ∈ EQ/NE/GT/LT/GE/LE（mask 来自值的 X 通配位，operand=值 LSB-first、X 按 0）；RANGE op 为 `GT,LT`/`GE,LE`/`GT,LE`/`GE,LT`，operand=`左值,右值`（各 LSB-first）。合法边界（GUI 触发位置对话框同款）：`0 ≤ offset ≤ depth/窗口数 − 5`。
- 相关 TCL 命令全表：`references/tcl_commands_help.md` 搜 `insight.`（51 条）。
