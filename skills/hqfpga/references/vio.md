<!-- 来源：hqbuddy -vio 实测（HqFpga V3.1.1 FT090526，SA30K 开发板验证通过）+ hq_ins 反编译（vio_tab/cable/svf_debugger_run） -->

# VIO 虚拟 IO（运行时探针，全 CLI）

VIO = 不重编译即可**读取**设计内部信号、**驱动**设计内部信号的调试 IP。与 HqInsight（LA）互补：LA 看波形历史，VIO 做"此刻"的窥探/注入。生成探针模块 → 正常实现流程 → 下载 → `hqbuddy -vio -read/-write`。

## 与 HqInsight 的关系（重要）

- **同板互斥**：VIO bit 与 LA 插桩 bit 都会占用 JTAG 调试链，板上一次只能有一个。切换要做两次下载。
- LA 插桩用 `hqbuddy -insight -run`（hqprj2hqins_flow）；VIO 用**标准实现流程**（`hqbuddy -build`），无需插桩流程。
- VIO 探针在设计 RTL 里实例化（`vio.ip.create` 生成的模块），探针选择发生在编码期——这与 LA 的"事后任意选信号"不同，**写 RTL 时就要想好看什么、控什么**。

## 全流程（CLI）

```bat
hqbuddy -vio -gen -in 8 -out 8             :: 生成 src/hq_vio_ins.v（probe_in[7:0]/probe_out[7:0] 端口）
::  ① 在 RTL 里实例化模块：probe_in 接要观测的总线，probe_out 接要驱动的逻辑
::  ② 把 src/hq_vio_ins.v 加进 .hqprj 的 FILE_SRC
hqbuddy -build <工程>.hqprj                :: 标准实现流程（含 HQ_VIO 属性的 TAP 自动接入 JTAG）
hqbuddy -cable --sealion <bin> --model SA30K --Burst
hqbuddy -vio -reg -in cnt:8 -out led:2     :: 登记探针名/位宽（hqvla_vio/probes.json）
hqbuddy -vio -read                         :: 读输入探针（0x.. 每探针一行）
hqbuddy -vio -read -loop 5 -interval 0.5   :: 连续读 5 次
hqbuddy -vio -write led=0b10               :: 驱动输出探针（写完即生效）
hqbuddy -vio                               :: 查看探针登记
```

- `-gen` 生成的模块模板：`vio_reg_0`（输出探针，host→device，`dout=probe_out`）+ `vio_reg_1`（输入探针，device→host，`din=probe_in`）+ `VIO_TAP`（xsJTAG 桥）。hqbuddy 自动改 `LENGTH` defparam 并注入 probe 端口。
- `-reg` 位打包顺序 = 登记顺序（GUI 约定，板上回归实测）：**第一个登记的探针对应读值位串的 MSB 端切片**（切片内反转即为探针值）。RTL 连线时注意 JTAG 链方向与端口序号相反——probe_in[低位字节] 会出现在读值高位端。登记后先 `-read -loop` 用已知翻转特征（如自增计数器）验证对位，不对就交换登记顺序，无需重编译。
- `-write` 的值支持十进制/`0x`/`0b`；写入立即生效（update 寄存器双拍，无毛刺）。
- 探针总宽建议 ≤ 32b；VIO 与 LA 组合（VLA 模式）的 CLI 尚未支持。

## 使用模式与经验

- **运行时验证**：`-read -loop` 观测计数器/状态机是否推进，等价于"板子心跳检查"。
- **运行时注入**：`-write` 驱动 mux 选择、伪随机种子、寄存器配置——配合 LA 抓"注入后"的波形，是不重编译的闭环调试。
- **分相提醒**：与 LA 相同，DDR 等硬核设计在训练期的信号行为与稳态不同。
- 如果 `-read` 全 0/恒定：确认下载的是含 VIO 的 bit（标准流程产物，不是 insight 插桩 bit）、探针在 RTL 里真实连接、位宽登记与 -gen 一致。
