<!-- 来源：XIST_CM3_Demo_2026_0805 / XIST_STAR_Demo_2026_0805 官方例程套件盘点 +
     hqbuddy SoC 工作流指令（-new_soc/-list_soc/-build/-mcu_build/-merge_bin） -->

# SoC（FPGA + ARM 软核）全 CLI 工作流

SA5Z 系列 SoC 器件在 FPGA 逻辑中内嵌 ARM 内核：**SA5Z-30 = Cortex-M3（core: cm3，板型 SA30K）**，**SA5Z-50 = Cortex-M33（core: star，板型 SA50K）**。开发=两件事：FPGA 侧逻辑（内核 IP 例化 + 用户 RTL）+ MCU 侧固件（CMSIS 标准库 + main.c），烧写时两边的 bin 合并为一个镜像。

## 全 CLI 链路（无 GUI，agent 可直接执行）

```bat
hqbuddy -list_soc                                # 看有哪些预设
hqbuddy -new_soc my_app -core cm3 -preset ex4_uart   # 生成完整工程树
cd my_app\FPGA_Prj\hq_prj
hqbuddy -build                                   # FPGA 全流程 -> my_app.bin（.hqprj 旁边）
hqbuddy -mcu_build                               # Keil 无人值守编译（工程根目录跑）
                                                 #   编译后自动 merge 出 my_app_merged.bin
hqbuddy -dl -f my_app\FPGA_Prj\hq_prj\my_app_merged.bin          # 下载到板
```

手动合并（不编译 MCU 时）：`hqbuddy -merge_bin <fpga.bin> <mcu.bin> [-o out.bin] [-model SA30K|SA50K] [-dl]`。
注意：mcu_build 后自动执行的 merge 是**合并但不下板**；`mergeBinFileAndProgram.bat -dl` 或上面 `-dl` 才真正下载。
`-build` 的 FPGA bin 输出在 `.hqprj` 同目录（CLI 流程不写入 hq_run，那是 GUI 的 OUT_DIR 习惯）。

## 生成工程的结构（-new_soc）

```
my_app/
├── FPGA_Prj/hq_prj/
│   ├── my_app.hqprj              # 工程文件（PROJ_NAME 已改为 my_app，时间戳已校准）
│   ├── constrain/30k_uart.sdc    # 时序约束（25MHz 时钟）
│   ├── constrain/30k_uart.upc    # 物理约束=管脚分配（含板级备选管脚注释库）
│   ├── rtl/top/demo_top.v        # 顶层：例化内核 IP + 接时钟/复位/LED
│   ├── rtl/include/inc_demo.v    # 参数宏
│   └── ipcore_dir/cortexM3/      # 内核 IP：xsIP_cortexM3.hqip(配置)+.v(wrapper)
│       └── STAR 套件为 ipcore_dir/STAR_Processor/
└── MCU_Prj/
    ├── Lib/CMSIS/                # 标准外设库（类 STM32 StdPeriph，已由 hqbuddy 去重还原）
    ├── MDK/CM3.uvprojx           # Keil 工程（相对路径，可移植；AfterBuild 自动 merge）
    │   └── mergeBinFileAndProgram.bat   # hqbuddy 版合并脚本（无硬编码路径）
    └── User/main.c + uart.c/h    # 用户代码（随 preset 不同）
```

## 预设（presets）

来自官方 Demo 套件的轻量例程（巨型例程 lwip/mqtt/FreeRTOS/bootloader/DDR/CAN 未内置，需要时手动拷贝 Demo 目录）。常用预设：

| 预设 | 内容 | MCU 侧要点 |
|---|---|---|
| ex1_led_systick | 点灯 + SysTick | gpio/systick 初始化模板 |
| ex2_key / ex3_gpio_int | 按键 / GPIO 中断 | EXTI 中断写法 |
| ex4_uart | 串口收发（printf 重定向） | uart.c + CM3_retarget |
| ex5_i2c / ex6_adc / ex7_timer / ex8_dual_timer / ex9_watchdog | I2C/ADC/定时器/看门狗 | 对应外设驱动用法 |
| ex10_spi / ex12_dma | SPI / DMA | |
| ex14_uart_pll | 串口 + PLL 改频 | rcc 时钟树配置 |
| ex11/13/16/17/18/19 | AHB/APB/AXI-Lite 总线扩展 | **自定义外设挂总线模板**（rtl/common 有 slave 样例） |

每个预设自带匹配的 IP 配置（内核哪些外设使能）、约束和用户代码——**选对预设比改配置省事**。

## 常用修改操作

- **改用户逻辑**：编辑 `rtl/top/demo_top.v` 后在 hq_prj 目录 `hqbuddy -add rtl/xxx.v` 登记新源文件（或 `-refresh_time` 校准时间戳），再 `-build`
- **改 MCU 代码**：编辑 `MCU_Prj/User/main.c`，在工程根目录 `hqbuddy -mcu_build`
- **改管脚**：编辑 `constrain/*.upc`（格式：`phycst.pin.set {NET} PIN -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"`，备选管脚在注释里）；改完需 `-refresh_time`
- **改内核外设使能**：编辑 `ipcore_dir/cortexM3/xsIP_cortexM3.hqip`（INI 风格）后 `-update_ip` 再生成网表，再 `-build`
- **换器件**：`hqbuddy -set_device`（30K↔50K 属不同 core 预设，建议直接换 preset 重新 -new_soc）

## 器件与授权

- cm3 预设器件 `SA5Z-30-D1-8U213-C`（U213 封装）；star 预设 `SA5Z-50-D0-F484-*`（F484）
- `hqbuddy -cmd -e "license.query" -q` 可查授权覆盖的器件清单
- 合并镜像的 `-model` 参数是下载器板型：SA30K（cm3）/SA50K（star），不是器件名
