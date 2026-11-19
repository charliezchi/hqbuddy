# 用 .hqip 无界面生成 VLA + VIO

从 [VLA + VIO 模板](../assets/vla_vio.hqip) 复制一份 .hqip 到独立输出目录。模板包含一个 16 位 LA、1024 拍、128 拍触发前采样、一个 9 位 VIO 读回和一个 5 位 VIO 驱动。IST158 的目标器件为 SA5Z-30-D0-8U324C。

| 改什么 | 修改位置 |
| --- | --- |
| 安装路径和器件 | 将 `meta_file` 里的 `@HQFPGA_ROOT@` 换成 `hqbuddy -root` 返回的路径。从工程查询完整器件料号后填入 `device` |
| 模块名和文件名 | 改 `output_module`。生成器用 .hqip 的文件基本名作为 .v 的文件基本名。建议模块与文件基本名相同 |
| LA 宽度、深度和触发前样本 | 改 `probe_port_0:16:Sample and Trigger`、`sample_depth` 和 `trig_pos`。触发前样本数须小于深度 |
| VIO 驱动宽度和初值 | 同时修改 `probe_out0:5:5'h00` 的端口宽度和初值位宽。用全零表示空闲时，适合 hqbuddy 联合采集期间置零 |
| 仅保留 VIO 驱动 | 设 `input_count=0`，删除 `probe_in0:9`，保留 `probe_in={}` 空块 |

保留 `generate_net:False` 可生成 Verilog RTL。使用 hqbuddy 联合采集时，保持单 LA、单窗口配置。生成器会回写输出目录中的 .hqip，保留模板原件。

## 直接调用官方生成器

用当前安装的 `hq_vla_ins.exe -gen`。VLA 的独立生成器使用这套参数，`-modify` 和 hqbuddy 的 `-vla -gen --config` 会打开向导。

FT111526 下，Windows 生成器可能在保护段写完前退出，也可能生成明文后仍存活。要把生成与加密分成可验证的两步，先在 .hqip 同目录创建空文件 `.debug.txt`。该文件关闭生成器内置的异步加密，最后仍由同一安装的官方工具生成保护段。

下面是两条直接命令。将 `HQFPGA_ROOT` 和 `WORK_DIR` 换成实际绝对路径。工具调用的工作目录设为 `WORK_DIR`。

```text
"HQFPGA_ROOT/build/ipcreator/sup_files/ipdepot/vla/_ipgen_/hq_vla_ins.exe" -lang eng -gen "WORK_DIR/dual_debug_ip.hqip" -hq_exe "HQFPGA_ROOT/build/win_x64/bin/hqfpga.exe"
"HQFPGA_ROOT/build/common/util/hq_ipencrypt.exe" -f "WORK_DIR/dual_debug_ip.v" -po -r -pk "HQFPGA_ROOT/build/common/util/keys.txt"
```

1. 执行第一条，等待新 .v 写完。用文件末尾的 Verilog 指令 `pragma protect end` 判断原始 RTL 保护区域已完整写出，并确认 .hqip 已回写。进程退出码或 .v 文件出现均不足以判定完成。给生成器有限的等待时间，例如 30 秒，超时则检查日志、路径和配置。
2. 执行第二条并检查退出码、`pragma protect end_protected` 和模块端口。原样模板应生成模块 `dual_debug_ip`，输入 `probe0[15:0]`、`probe_in0[8:0]`，输出 `probe_out0[4:0]`。只驱动时核对 `probe_in0` 端口不存在。工程使用加密完成的 .v。
