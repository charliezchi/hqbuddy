<!-- 来源：cable.exe 实测（XiST USB Cable v7.1，SEALION SA30K 开发板验证通过） -->

# 下载调试（cable.exe）

XiST 下载器（USB Cable）的命令行工具是 `cable.exe`，hqdnload GUI 底层也是调它。**所有下载/检测操作优先用 `hqbuddy -cable` 透传**（自动定位当前 HqFpga 版本的 cable.exe，参数原样转发）：

```bat
hqbuddy -cable <args...>
```

## 检测开发板

```bat
hqbuddy -cable --detect_model
```

输出示例（真实输出）：

```
2026-08-25 13:24:02 : XiST USB Cable v7.1
MCU version : v3.4
Device ID : 0C30C7FD
...detect Device Model : SA30K
UID :0087364516791C0A
Package:SA5Z-30-D1-8U213
```

关键信息：`Device Model`（下载时的 `--model` 参数值）、`Package`（器件封装）、`Device ID`。**下载前先跑这个确认板子连接正常、拿到 model**。

## 下载比特流（突发模式）

```bat
hqbuddy -cable --sealion "<bin文件>" --model "SA30K" --Burst
```

- `--sealion`：目标系列选项，**SEALION 和 SEAL 系列都用 `--sealion`**（SHARK 系列未验证，用时先 `--detect_model` 确认）
- `--model`：`--detect_model` 报出的 Device Model（如 `SA30K`）
- `--Burst`：突发下载模式（快速下载 bin）
- bin 文件路径含空格要加引号

成功输出末尾为 `Task completed.`；同时会打印 bin 的 Design name / Device / Date 信息，可核对是否下载了正确的文件。

## 与 GUI 的对应关系

HqFpga GUI / HqInsight 弹出的下载窗口实际执行：

```
hqdnload.exe -f <bin> -family <如 seal30k> -lang chs
```

hqbuddy 的 `-dl` 命令就是启动 hqdnload（缺省自动选当前目录最新 `.bin`）。需要纯 CLI 时用上面的 `cable.exe` 命令即可，不必经过 hqdnload。

## 注意事项

- 下载的是 `.bin`（非 `.bit`）；实现流程两个都会生成
- 下载属 RAM 加载，断电丢失；烧写 Flash 的流程未验证，不在本参考范围
- 在线逻辑分析仪（HqInsight）的 JTAG 交互（SVF 播放等）也走同一根下载线，见 references/insight.md（待补充）
