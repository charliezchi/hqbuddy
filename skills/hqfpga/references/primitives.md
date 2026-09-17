# XiST 原语库参考（primitives.md）

> R57 自动提取（2026-09-17）。来源：HqFPGA FT091626
> `build/common/syn/verilog/XIST/` 下的第三方综合原语库，外加实测网表
> （r30syn/r45vla 的 EDIF→Verilog 产物）中的映射原语集合。
> **用途**：第三方综合（Synplify/Vivado）按技巧 006 需要这些库；Agent 阅读
> 门级网表/EDIF 时据此识别原语义。原语名大小写敏感；后缀含义见表内说明。

## Seal（SA5Z-30/50 等）（seal_syn_prim.v，278 模块 / 130 家族）

| 家族 | 变体数 | 说明 |
|---|---|---|
| xs（无族名前缀） | 2 | 特殊单元 |
| xsADC | 1 | 其他原语 |
| xsALU | 4 | 其他原语 |
| xsBCODT | 1 | 其他原语 |
| xsBCTMDSO | 1 | 其他原语 |
| xsBOOT | 1 | 其他原语 |
| xsBRAM | 11 | 块 RAM（16K/32K/8K，TD=双口 S=单口 PD=伪双口） |
| xsBRIDGE | 1 | 其他原语 |
| xsCDELAY | 1 | 其他原语 |
| xsCEM | 1 | 其他原语 |
| xsCFG_PERSIST | 1 | 其他原语 |
| xsCLA | 1 | 其他原语 |
| xsCLKBRANCH | 1 | 时钟相关（BUF/分频） |
| xsCLKDIV | 1 | 时钟相关（BUF/分频） |
| xsCLKDIVSA | 1 | 时钟相关（BUF/分频） |
| xsCM | 2 | 其他原语 |
| xsDBCINRD | 1 | 其他原语 |
| xsDBCLVDS | 1 | 其他原语 |
| xsDCC | 1 | 其他原语 |
| xsDCCB | 1 | 其他原语 |
| xsDCLKSEL | 1 | 其他原语 |
| xsDDR | 12 | 其他原语 |
| xsDDRCTRL | 3 | 其他原语 |
| xsDDRCTRL_ | 7 | 其他原语 |
| xsDDRDLL | 1 | 其他原语 |
| xsDDRDLLB | 1 | 其他原语 |
| xsDDRDLLC | 1 | 其他原语 |
| xsDDRMDQIN | 1 | 其他原语 |
| xsDDRMDQOUT | 1 | 其他原语 |
| xsDDRMDQSOUT | 1 | 其他原语 |
| xsDDRMDQSTRIOUT | 1 | 其他原语 |
| xsDDRMDQTRIOUT | 1 | 其他原语 |
| xsDELAYDYN | 1 | 其他原语 |
| xsDELAYDYN_ | 1 | 其他原语 |
| xsDELAYSA | 1 | 其他原语 |
| xsDFFSA | 20 | 通用 D 触发器 |
| xsDLLDLY | 1 | 延时锁相环 |
| xsDMP | 1 | 其他原语 |
| xsDNA_PORT | 1 | 其他原语 |
| xsDQSBUF | 1 | DQS（DDR 数据选通）相关 |
| xsDQSBUFN | 1 | DQS（DDR 数据选通）相关 |
| xsDQSBUFP | 1 | DQS（DDR 数据选通）相关 |
| xsDQSBUFQ | 1 | DQS（DDR 数据选通）相关 |
| xsDQSBUFS | 1 | DQS（DDR 数据选通）相关 |
| xsECC_CEM | 1 | 其他原语 |
| xsECC_CEM_ | 1 | 其他原语 |
| xsECC_EFB | 1 | 其他原语 |
| xsECC_EFB_ | 1 | 其他原语 |
| xsECLKBCS | 1 | 其他原语 |
| xsECLKSBK | 1 | 其他原语 |
| xsECLKSYNC | 1 | 其他原语 |
| xsEFB | 1 | 其他原语 |
| xsFBCLKPLL | 1 | 其他原语 |
| xsFIFO | 4 | 其他原语 |
| xsGADC | 1 | 其他原语 |
| xsGND | 1 | 其他原语 |
| xsGSR | 1 | 全局置位/复位 |
| xsGSRS | 1 | 全局置位/复位 |
| xsGTI | 1 | 其他原语 |
| xsHBUF | 1 | 其他原语 |
| xsIBUFDS | 1 | 其他原语 |
| xsIBUFDS_DYN | 1 | 其他原语 |
| xsIDDRSA | 1 | 其他原语 |
| xsIDDRSAX | 4 | 其他原语 |
| xsIDFF | 4 | 输入 D 触发器（K=时钟极性 P/C/R/S=置位类 E=使能变体） |
| xsILAT | 4 | 输入锁存器 |
| xsINVSA | 1 | 其他原语 |
| xsIOBB | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBB_K | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBB_PD | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBB_PU | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBI | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBI_D | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBI_PD | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBI_PU | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBO | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBO_C | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBO_D | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBT | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBT_PU | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIRDB | 1 | 其他原语 |
| xsISCPU | 1 | 其他原语 |
| xsJTAG | 1 | JTAG 相关（BSCAN/调试 TAP） |
| xsLATSA | 12 | 其他原语 |
| xsLPLL_MFGOUT_MUX | 1 | 其他原语 |
| xsLRAM | 22 | 其他原语 |
| xsLROM | 5 | 其他原语 |
| xsLUTSA | 19 | 查找表 |
| xsMULT | 4 | 其他原语 |
| xsMUXCY | 1 | 多路选择器 |
| xsMUXCY_D | 1 | 多路选择器 |
| xsMUXCY_L | 1 | 多路选择器 |
| xsMUXF | 12 | 多路选择器 |
| xsOBUFLVDS | 1 | 其他原语 |
| xsODDRSA | 2 | 其他原语 |
| xsODDRSAX | 3 | 其他原语 |
| xsODELAY | 1 | 其他原语 |
| xsODFF | 4 | 输出 D 触发器 |
| xsOSC | 1 | 内部振荡器 |
| xsPCIE | 1 | 其他原语 |
| xsPCIE_ | 1 | 其他原语 |
| xsPLLREFCS | 1 | PLL（SA/SL25 等为器件专属型号） |
| xsPLLSA | 1 | PLL（SA/SL25 等为器件专属型号） |
| xsPOWCTR | 1 | 其他原语 |
| xsPOWG | 1 | 其他原语 |
| xsPREADD | 2 | 其他原语 |
| xsPWR | 1 | 上电复位 |
| xsRBUF | 1 | 其他原语 |
| xsRCLKDIV | 1 | 其他原语 |
| xsSADC_ | 1 | 其他原语 |
| xsSEDBM | 1 | 其他原语 |
| xsSEDFC | 1 | 其他原语 |
| xsSEDFD | 1 | 其他原语 |
| xsSEDOHM | 1 | 其他原语 |
| xsSERDES_CH | 1 | 其他原语 |
| xsSERDES_COM | 1 | 其他原语 |
| xsSERDES_COM_ | 2 | 其他原语 |
| xsSOC_INTERFACE | 1 | 其他原语 |
| xsSRL | 4 | 移位寄存器（SRL16/SRL16E 等） |
| xsSRLC | 5 | 移位寄存器（SRL16/SRL16E 等） |
| xsSTAR | 1 | 其他原语 |
| xsSTART | 1 | 其他原语 |
| xsTAPTEST | 1 | 其他原语 |
| xsTDDRSA | 1 | 其他原语 |
| xsTEST | 1 | 其他原语 |
| xsVCC | 1 | 其他原语 |
| xsWAKEUP | 1 | 其他原语 |
| xsXORCY | 1 | 进链异或 |
| xsXORCY_D | 1 | 进链异或 |
| xsXORCY_L | 1 | 进链异或 |

## Sealion（SL2 等）（sealion_syn_prim.v，232 模块 / 120 家族）

| 家族 | 变体数 | 说明 |
|---|---|---|
| xsADC_ | 2 | 其他原语 |
| xsADC_SL | 1 | 其他原语 |
| xsALU | 2 | 其他原语 |
| xsAND | 4 | 其他原语 |
| xsBCHSLP | 1 | 其他原语 |
| xsBCTERM | 1 | 其他原语 |
| xsBIODLY | 1 | 其他原语 |
| xsBOOT | 1 | 其他原语 |
| xsBRAM | 3 | 块 RAM（16K/32K/8K，TD=双口 S=单口 PD=伪双口） |
| xsCB | 6 | 其他原语 |
| xsCC | 1 | 其他原语 |
| xsCD | 6 | 其他原语 |
| xsCEM | 1 | 其他原语 |
| xsCLKDIV | 1 | 时钟相关（BUF/分频） |
| xsCRC | 1 | 其他原语 |
| xsCU | 7 | 其他原语 |
| xsDBCINRD | 1 | 其他原语 |
| xsDBCLVDS | 1 | 其他原语 |
| xsDCC | 1 | 其他原语 |
| xsDCMUX | 1 | 其他原语 |
| xsDDR | 12 | 其他原语 |
| xsDDRMDQIN | 1 | 其他原语 |
| xsDDRMDQOUT | 1 | 其他原语 |
| xsDDRMDQSOUT | 1 | 其他原语 |
| xsDDRMDQSTRIOUT | 1 | 其他原语 |
| xsDDRMDQTRIOUT | 1 | 其他原语 |
| xsDELAYDYN | 1 | 其他原语 |
| xsDELAYSA | 1 | 其他原语 |
| xsDFF | 16 | 通用 D 触发器 |
| xsDFF_K | 4 | 通用 D 触发器 |
| xsDLLDEL | 1 | 延时锁相环 |
| xsDLLDLYE | 1 | 延时锁相环 |
| xsDMP | 1 | 其他原语 |
| xsDNA_PORT | 1 | 其他原语 |
| xsDPR | 1 | 其他原语 |
| xsDQS | 1 | DQS（DDR 数据选通）相关 |
| xsDQSBUFR | 1 | DQS（DDR 数据选通）相关 |
| xsDQSDLL | 1 | DQS（DDR 数据选通）相关 |
| xsDQSDLLD | 1 | DQS（DDR 数据选通）相关 |
| xsDTR | 1 | 其他原语 |
| xsECC_CEM | 1 | 其他原语 |
| xsECC_CEM_ | 1 | 其他原语 |
| xsECC_EFB | 1 | 其他原语 |
| xsECC_MEM | 1 | 其他原语 |
| xsECLKBBCS | 1 | 其他原语 |
| xsECLKSYNC | 1 | 其他原语 |
| xsEFB | 1 | 其他原语 |
| xsEQNLUT | 3 | 其他原语 |
| xsFBCLKPLL | 1 | 其他原语 |
| xsFIFO | 1 | 其他原语 |
| xsFL | 1 | 其他原语 |
| xsFL_ | 2 | 其他原语 |
| xsGND | 1 | 其他原语 |
| xsGSR | 1 | 全局置位/复位 |
| xsGSRS | 1 | 全局置位/复位 |
| xsGTI | 1 | 其他原语 |
| xsIDDRDQS | 1 | 其他原语 |
| xsIDDRSA | 1 | 其他原语 |
| xsIDDRSAX | 3 | 其他原语 |
| xsIDDRX | 4 | 其他原语 |
| xsIDFF | 4 | 输入 D 触发器（K=时钟极性 P/C/R/S=置位类 E=使能变体） |
| xsILAT | 4 | 输入锁存器 |
| xsINV | 1 | 其他原语 |
| xsIOBB | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBB_K | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBB_PD | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBB_PU | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBI | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBI_D | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBI_PD | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBI_PU | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBO | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBO_C | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBO_D | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBT | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIOBT_PU | 1 | IO 缓冲（输入/输出/三态，后缀 PD/PU/D/K=上下拉等变体） |
| xsIODLY | 1 | 其他原语 |
| xsIRDB | 1 | 其他原语 |
| xsJTAG | 1 | JTAG 相关（BSCAN/调试 TAP） |
| xsL | 1 | 其他原语 |
| xsLAT | 4 | 其他原语 |
| xsLAT_K | 2 | 其他原语 |
| xsLAT_L | 6 | 其他原语 |
| xsLUT | 3 | 查找表 |
| xsMULT | 4 | 其他原语 |
| xsMUX | 6 | 多路选择器 |
| xsNAND | 4 | 其他原语 |
| xsNO | 4 | 其他原语 |
| xsO | 4 | 其他原语 |
| xsOBUFLVDS | 1 | 其他原语 |
| xsODDR | 1 | 其他原语 |
| xsODDRDQS | 1 | 其他原语 |
| xsODDRSA | 2 | 其他原语 |
| xsODDRSAX | 2 | 其他原语 |
| xsODDRX | 3 | 其他原语 |
| xsODELAY | 1 | 其他原语 |
| xsODFF | 4 | 输出 D 触发器 |
| xsOSC | 1 | 内部振荡器 |
| xsPLL | 1 | PLL（SA/SL25 等为器件专属型号） |
| xsPLLREFCS | 1 | PLL（SA/SL25 等为器件专属型号） |
| xsPOWCTR | 1 | 其他原语 |
| xsPOWG | 1 | 其他原语 |
| xsPRBS | 1 | 其他原语 |
| xsPWR | 1 | 上电复位 |
| xsRAM | 2 | 其他原语 |
| xsROM | 5 | 其他原语 |
| xsSEDBM | 1 | 其他原语 |
| xsSEDFD | 1 | 其他原语 |
| xsSEDOHM | 1 | 其他原语 |
| xsSL | 1 | 其他原语 |
| xsSPRAM | 1 | 其他原语 |
| xsSTART | 1 | 其他原语 |
| xsTDDR | 1 | 其他原语 |
| xsTEST | 1 | 其他原语 |
| xsTESTCNT | 1 | 其他原语 |
| xsTEST_ | 1 | 其他原语 |
| xsVCC | 1 | 其他原语 |
| xsWAKEUP | 1 | 其他原语 |
| xsXNO | 4 | 其他原语 |
| xsXO | 4 | 其他原语 |

## 常用原语端口速查（Seal 库选摘）

- **xsBRAM32KTD**(IN_1BIT_ERR:I, SBIT_ECC_ERR:O, DIA17:I, YDIA17:I, YADA3:I, YDOA17:O, DOA17:O)
- **xsPLLSA**(CLKI:I, CLKOP:O)
- **xsSRL16E**()
- **xsPWR**()
- **xsGSR**()

- 例化防优化（第三方综合）：实例末尾加 `/* synthesis syn_noprune=1 */`
- 原语库必须与 HqFPGA 版本同代（FT091626 的库配 FT091626 工具）
