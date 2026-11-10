<!-- Tiny_SoC(RISC-V 软核)全流程参考。实测基线:hqbuddy 3.45.0 + FT110826,
     沙箱端到端验证 2026-11-09/10(含 ModelSim 软件仿真闭环)。-->

# Tiny_SoC IP(RISC-V 软核)嵌入式开发指南

Tiny_SoC = 32bit RISC-V(RV32-[I], 5 级流水, ~1K LUT, ~120MHz@Seal5000)+ JTAG 调试
+ 可选外设,OnChipRAM 4KB~512KB 档位。**支持 Seal 5000 全系(SA5Z/SA5T,家族
token 命中,SA5Z-30/SA5T-100 已实测 ipgen 通过)+ Sealion 2000 的 SL2S-22E /
SL2-25E / SL2S-25E / SL2D-25E**(不支持 SL2-12E/SL2-22E)。产品族命名对照见
families.md。手册 UG00034(ipdepot 内,`hqbuddy -ipdoc Tiny_SoC` 打开)。

**hqbuddy 入口:`-tinysoc <sub>`**(new/fw/bin/sim/list/ocd,`-tinysoc` 无参数看用法)。

## 1. 全流程(硬件侧→软件侧)

1. **生成 IP**:`hqbuddy -tinysoc new --device SL2S-25E-8U213C --ram-size 65536
   --uart0 --gpio --plic` → 生成 `ipcore_dir/Tiny_SoC/xsIP_Tiny_SoC.hqip`
   (等价 `-gen_hqip --ip Tiny_SoC --set ...`)+ `-ipgen` 综合出加密网表
   `xsIP_Tiny_SoC.v`(自动跑解密→综合→加密,内部含 rtlsyn)。
   外设开关:`--uart0/--uart1/--spi0/--spi1/--i2c0/--i2c1/--timer0/--timer1/
   --gpio/--plic/--clint/--usr-axi0/--usr-axi1/--apb0..4/--ddr-axi`。
2. **挂进工程**:`hqbuddy -add <netlist>.v <proj.hqprj>`。顶层端口固定前缀 `io_`:
   io_sys_clk / io_asyncReset(高有效)/ io_jtag_{tms,tdi,tdo,tck} / 外设口。
   仿真模板与固件脚手架在 hqbuddy 仓库 `templates/`(tinysoc_tb.v、tinysoc_fw/)。
3. **固件编译**(xPack riscv-none-embed-gcc,SP/入口约束见 §4):
   `make`(模板 Makefile)→ `fw.bin`。
4. **固件固化准备**:`hqbuddy -tinysoc fw fw.bin` → 切 4 个 BIN lane 写回 .hqip
   → 自动重跑 -ipgen(固件烧进 OnChipRAM 初值)→ `-build` 全链出 bit。
5. **软件仿真**(改固件不重做 bit 先仿真):`hqbuddy -tinysoc sim --tb tinysoc_tb.v`
   → 明文网表导出 + ModelSim 网表仿真 + TB 内置 UART 帧解码,
   仿真完成后命令行直接回显解码出的固件输出。
6. **在线调试**:OpenOCD 软 JTAG(§6;debug_softTap.cfg 为厂商附件专属,待补)。

## 2. .hqip 配置键(实测)

```ini
[General]
INPUT_PARAMS.RAM_SIZE=4096        # 4KB~512KB 共 11 档: 4096 8192 16384 32768
                                  # 65536 73728 81920 98304 131072 262144 524288
INPUT_PARAMS.BIN0_PATH=           # 固件 lane0; BIN1..3 同理, 空串=无固件
USER_PORT_SEL.uart0=TRUE          # 外设开关, bool; 其余同名 cfg 全 FALSE 缺省
[File]
output_module=xsIP_Tiny_SoC
[IP]
device=SL2S-25E-8U213C
meta_file=.../ipdepot/Tiny_SoC/Tiny_SoC/Tiny_SOC.xml
```

- meta 里可见 bool 的隐藏派生(`def_uart0_en` 等)由 active_cond 自动联动,
  **不要手改**;`_DESC.TXT`(生成后出现在 ipcore_dir)是权威例化模板与
  `` `define `` 清单(USR_AXI0_DIS/RAM_SIZE/BIN0_PATH...)。

## 3. 固件 BIN 4-bank 格式(bin_regen 等价,hqbuddy 已实现)

- BIN0~3 是 **$readmemb 文本**:每行 8 个 0/1(一个字节,MSB 在前),
  **行数 = RAM_SIZE/4**(每 bank 字节宽)。
- **BIN_k = 固件每个 32 位小端字的第 k 字节**:BIN0→bits[7:0]、BIN1→[15:8]、
  BIN2→[23:16]、BIN3→[31:24](实测:常数填充定 bank 映射,递增地址定行序)。
- 固件超 RAM_SIZE 报错;不足补 0x00。**格式含非 0/1 字符会在综合期报
  SFE-E-126**(readmemb 语法错)——这是此前误传"bin 格式"的真相。
- **BIN 路径必须纯正斜杠**: 混合分隔符(如 `C:/x\y/lane0.bin`)综合期 $readmemb 失败且无明确报错(ipgen 只报 "error rtl dump");hqbuddy -tinysoc fw 写入的路径已规范化。
- 物理地址有 XOR 扰码(综合器↔仿真模型两侧一致),对固件制作无影响。

## 4. 裸机固件三坑(全部实测踩过)

1. **SP 必须先初始化**(`li sp, 0xF0000800`):未初始化 SP 时函数 prologue
   写未映射地址(0xfffffff0 区),ra 保存失败,`ret` 跳到 0。
2. **_start 必须链接在 0xF0000000**(复位向量):`ENTRY(_start)` 只定入口
   符号**不定位置**——gcc -O2 会把别的函数排前面,导致复位后跑错函数。
   用 link.ld 的 `KEEP(*(.text.init))` + `_start` 加
   `__attribute__((section(".text.init")))`。
3. **连续 putc 必须轮询 Status 的 writeAvailability [23:16]**(0=满),
   否则 TX FIFO 溢出丢字(实测 "Hello TinySoC!" 丢 2 字符)。

链接脚本:`. = 0xF0000000; .text : { KEEP(*(.text.init)) *(.text*) *(.rodata*) }`。
编译:`riscv-none-embed-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles
-Tlink.ld -O2` + `objcopy -O binary`。

## 5. UART0 寄存器(实测定音,UG 表 12 有误植)

基址 **0x8100_0000**(APB 外设区首);寄存器:Data@0x0、Status@0x4、
Clock Divider@0x8、Config@0xC、Error/Break@0x10。

| 寄存器 | 字段 | 语义(实测) |
|---|---|---|
| Data 0x0 | [7:0] data | 写即触发 TX |
| Status 0x4 | [23:16] writeAvailability | TX FIFO 空位数,0=满(putc 前轮询) |
| | [31:24] readOccupancy | RX FIFO 占用 |
| Divider 0x8 | [19:0] | **波特率 = clk / ((div+1) × (DL+1))** |
| Config 0xC | **[2:0] DataLength** | **实际数据位 = 字段值+1**(写 7 = 8 位!) |
| | [9:8] Parity | 0 无 / 1 偶 / 2 奇 |
| | [16] Stop | 停止位 |

注意:UG 表 12 的 [7:3]/[2:0] 列错位——**DataLength 在 [2:0]**;
把 8 写成 `0x40`(按 [7:3] 理解)实际 = DataLength 0 = 1 数据位,
波形上是"start + 1 位高电平"的短帧(易误读为 0xFF)。

## 6. 软件仿真(网表级,ModelSim)

**为什么不能直接仿加密网表**:ipgen 产出的 `xsIP_Tiny_SoC.v` 是 P1735 加密
网表,`vlog` 能解但 **vopt 不能**(3300 个 "in protected region",-novopt 也
被 2020.4 判错)。正解 = hqfpga 重综合导出明文网表(`-tinysoc sim` 自动做):

```
dv.setup SEALION SL2S-25E-8U213C     # 注意 SL2 系列家族名是 SEALION(SEAL 会报 DVST005)
design.analyze {xsIP_Tiny_SoC.v}     # hqfpga 原生解密
design.rtlsyn -top xsIP_Tiny_SoC
design.tdomap -no_ioins
nl.write {sim_plain.v}               # 明文 + 可选 nl.write {...} -sdf
```

仿真要点(模板 `templates/tinysoc_tb.v` 全含):
- 必须例化 **`xsGSR xsGSR_INST(.GSR(1'b1))` + `xsPWR xsPWR_INST(.PUR(1'b1))`**,
  否则 vopt 报 "Failed to find xsGSR_INST"(寄存器不初始化)。
- 库:`-L XiST_SEAL`(hqbuddy -simlib 编译;SL2S 器件用 SEAL 家族库——
  sealion 目录承载公共 UDT 原语 xsDFF_K*,家族目录放特调模型)。
- TB 内置 UART 帧解码,位宽参数 `TB_BITP`(vsim `-gTB_BITP=<ns>` 覆盖;
  缺省 2240ns = 50MHz/div13/8bit)。
- 明文网表是扁平的,内部信号可层次引用调试,如
  `dut.\Tiny_Soc_v1_inst/axi_core_cpu/IBusSimplePlugin_fetchPc_pcReg `(VexRiscv PC)
  —— PC 轨迹是判断"固件是否在跑"的第一手段。
- 性能参考:uncached AXI 取指,~6 拍/指令(0.5 DMIPS/MHz 量级),ms 级仿真
  只能跑千级指令——长程序请缩小 delay 循环。

## 7. 约束与硬件注意事项(UG00034 §5.2)

- io_sys_clk 按实际频率约束;**io_jtag_tck ≤ 10MHz**,若无法落在时钟专用脚,
  编译报错时在 Global Setting→Other Set 加 `phyrule.set -chk_clkio off`
  (hqbuddy 可用 `-flow <prj> --hook "BeforePlace=phyrule.set -chk_clkio off"`
  注入),同时确认工程内其它时钟仍正确分配。
- 复位高有效,释放后 **16 拍**才开始工作。
- `io_usrInterrupts[7:0]` 对应 PLIC 中断号 16-9,**未用 bit 必须接 0**,勿悬空。
- 地址映射:OnChipRAM 0xF000_0000(≤512KB)/ APB 外设 0x8100_0000(每 APB
  接口 1MB)/ 用户 AXI0 0x9200_0000、AXI1 0xB300_0000 / DDR_AXI 0x0000_1000。
- 资源(4KB RAM 基准):默认配置(1×UART)1580 LUT/4 RAMB18K;每开一个
  AXI+165、APB+99、SPI/I2C/TIMER 若干;PLIC/CLINT 另计(UG 表 1)。

## 8. 板卡实测(SA5T-100-D0A2,2026-11-10 通过)

- 全链:`-tinysoc fw`(固件进 IP)→ `-build` → `-cable --sealion <bin>
  --model SA100K_A2 --Burst` 下载 → CPU 从 EBR 初值启动 → UART 115200 实收
  `Hello TinySoC!`。**EBR init 随 bit 上电加载已实板证实**。
- 注意 `-dl -f` 只拉起 GUI 下载器;脚本化下载用 `-cable --sealion <bin>
  --model <型号> --Burst`(型号先 `-cable --detect_model` 实测)。
- 引脚坑:实际板载器件可能是 D0A2 变体(boards.md 记的是 8F676C)——
  先 `--detect_model` 定器件;UART tx 脚以官方 DG05303 demo UPC 为准
  (tx=L23, boards.md 的 K25 对 D0A2 板不适用)。
- 引脚考古法(引脚存疑时 10 分钟定位):①顶层 LED 心跳证时钟/逻辑活;
  ②`assign txd = rxd` 纯环回 bit,PC 发什么回什么,排除 SoC/固件变量;
  ③对照官方参考设计 UPC。

## 9. 外设组合覆盖(3.46.0 批量仿真,SL2S-25E+固件启动仿真)

7/8 配置启动仿真通过(固件 Hello 全文解出):gpio/spi0/i2c0/timer0/
plic+clint/apb0/ram128k(148s)。**usr_axi0 仿真挂起是 TB 伪象**:使能后
IP 多出 29 个 io_axi0_* 端口,TB 悬空→X 态灌入 AXI 交叉开关→CPU 总线挂;
TB 需 tie-off 才能仿(真机引脚有拉载不受影响)。**中断功能级验证**
(PLIC/CLINT 真实触发)仍需外设驱动固件,未覆盖。

## 10. OpenOCD 联调状态(A1,2026-11-10)

- **cpu0.yaml 阻塞已解除**:最小 yaml(workspace/software/cpu0.yaml,
  内容 `debug:`+`  - hardwareBreakpointCount: 4` 两行)被厂商 OpenOCD
  接受,demo 工程缺失不再阻塞配置解析(参数以官方原件为准仍建议补齐)。
- **硬件阻塞**:厂商 OpenOCD **无 XiST 线缆驱动**(binary 内无 xist
  adapter,原版含 cmsis-dap/jlink/ftdi)——需 CMSIS-DAP/J-Link/FTDI 探针
  物理接软 TAP(本次约束: J14=TDO J15=TDI K15=TMS J16=TCK,FMC
  LA02-LA03)。OpenOCD 报 "unable to find a matching CMSIS-DAP device"
  即卡在此。

## 11. 已知边界(截至 3.46.0 / FT110826)

- **UG00034 官方附件已获取**(2026-11-10,开放目录 http://211.157.136.83/hqfpga_xist/IP_manage/UG00034_Tiny_SoC_IP/):
  bin_regen.zip(与逆向格式逐条对照一致——定音获官方证实)/build_tools.zip
  (MSYS 微工具集 make/busybox)/openocd.zip(厂商编译版 0.11.0+dev,**内建 vexriscv target**,已装 %USERPROFILE%\.hqbuddy\tools\openocd-xist)/toolchain.zip(366M 未下,xPack 已替代验证)。
  **demo 参考工程(cpu0.yaml/makefile)未发布**——OpenOCD 联调待厂商补。
  其它官网文档/附件走 `-doclist/-docget`(isilicontech.com 直链)。
- ram_symbol 的 BRAM 仿真模型(xsBRAM8KTD)对 seal/sealion 家族同文件;
  xsLUT4 两家族不同,-simlib 家族分库后按器件族取用。
- IP 生成内部 rtlsyn 约 40s/次;改固件 = `-tinysoc fw` 一条命令重生成。
- ipgen 收尾清理临时目录偶发 `WinError 32`(杀软/索引服务瞬时锁文件)
  → 退出码 1 但产物已生成;重跑即可。另有僵留 hqfpga 进程持锁导致
  批量 ipgen 连环失败——先 `Get-Process hqfpga | Stop-Process -Force`。
- OpenOCD 在线调试:`-tinysoc ocd` 打印完整指引。官方 debug_softTap.cfg
  关键参数(实录):TAP `irlen 4 / expected-id 0x10001fff`,
  `target vexriscv dbgbase 0xF00F0000`,readWaitCycles 12,启动即
  soft_reset_halt;需环境变量 workspace_loc + workspace/software/cpu0.yaml
  (最小可用 yaml 见 §10,官方原件仍待厂商补)。
