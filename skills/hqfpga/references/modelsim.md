<!-- 来源：hqbuddy/simlib.py 实现 + XiST 仿真约定 -->

# ModelSim/QuestaSim 仿真指南

用 ModelSim（或 QuestaSim）仿真包含 XiST 器件原语的设计（如 IP 网表、布线后网表）的标准流程。

## 1. 环境检查

1. **vsim 可用性**：`vsim` 必须在 PATH 中。检查方法：
   ```bat
   vsim -version
   ```
   找不到时，在常见安装位置找 `vsim.exe`（如 `C:\questasim*\win64\`、`C:\intelFPGA*\questa*\win64\`），把其所在目录加入 PATH 或用全路径调用。
2. **XiST 仿真库**：必须先编译一次（每个 ModelSim 安装只需一次）：
   ```bat
   hqbuddy -simlib
   ```
   它会把 `<HqFpga根目录>/build/common/sim/verilog/XIST` 下的原语库（.v/.vp）编译到 ModelSim 安装目录下的 `XiST` 库，并在 `modelsim.ini` 中加入映射 `XiST = $MODEL_TECH/../XiST`。
   验证：`modelsim.ini` 中有该行即完成。

## 2. 测试平台（TB）的强制要求

**凡是用到 XiST 原语的仿真，TB 中必须实例化全局置位/复位与上电原语**，否则原语不工作、仿真结果错误：

```verilog
xsGSR xsGSR_INST (.GSR(1'b1));
xsPWR xsPWR_INST (.PUR(1'b1));
```

- `xsGSR`：全局置位/复位（Global Set/Reset），`.GSR(1'b1)` 表示释放（高电平=正常工作）
- `xsPWR`：上电序列（Power-Up Reset），`.PUR(1'b1)` 表示上电完成
- 这两个实例放在 TB 顶层即可，无需连接其他信号
- 原语定义在 XiST 仿真库中，编译时通过 `-L XiST` 链接

## 3. 标准仿真流程（.do 脚本）

推荐写成 `.do` 文件用命令行跑，可重复、可自动化：

```tcl
# sim.do —— 标准仿真脚本（放在仿真工作目录，路径以该目录为基准写相对/绝对路径）
vlib work
vmap work work

# 编译设计：RTL、IP 网表、TB（按依赖顺序；路径为示例占位，按实际工程修改）
vlog ../rtl/top.v
vlog ../ipcore_dir/PLL_FREQ/xsIP_PLL_FREQ.v
vlog tb_top.sv

# 加载仿真：-L XiST 链接原语库
vsim -L XiST -t 1ps work.tb_top

# 波形（可选）
add wave -r /*
# 运行
run -all
# 命令行模式下退出（交互模式删掉这行）
quit -f
```

命令行执行：

```bat
vsim -c -do sim.do
```

- `-c`：命令行（无 GUI）模式；调试波形时去掉 `-c` 并删除 `quit -f`
- `-t 1ps`：仿真时间精度，门级/原语仿真建议 1ps
- 库链接：用了 XiST 原语就必须 `-L XiST`；纯 RTL 行为仿真（不含原语）可省略
- 加密的 IP 网表（`` `pragma protect ``）可直接 `vlog` 编译，仿真器内部解密
- **TB 文件后缀**：用 SystemVerilog 语法（`fork/join_any`、`logic`、`always_ff` 等）的 TB 必须命名为 `.sv`；命名为 `.v` 的 TB 只能用 Verilog-2001 语法，否则编译报 `Undefined variable` 之类错误
- **PLL 锁定延时**：含 PLL 的仿真有上电复位到锁定的延时（可达 20us 量级）。不要在 1us 内看结果就下结论；用 `run -all` 加 TB 内 `$finish`（或等 LOCK 拉高后再检查输出）最稳妥

## 4. 常见问题

| 问题 | 原因与解决 |
|---|---|
| 找不到 xsGSR/xsPLL 等模块 | 没编译仿真库 → 跑 `hqbuddy -simlib`；或没加 `-L XiST` |
| 输出恒为 X / 原语不动作 | TB 缺少 xsGSR/xsPWR 实例 |
| `vmap` 报错 / 找不到库 | `modelsim.ini` 缺 `XiST = ...` 映射 → 重跑 `hqbuddy -simlib` |
| vsim 不是内部命令 | vsim 不在 PATH → 定位 vsim.exe 并加 PATH 或用全路径 |
| 时序仿真需要 SDF | 流程网表配套的 `.sdf` 用 `-sdf` 选项加载（本参考未覆盖细节） |
