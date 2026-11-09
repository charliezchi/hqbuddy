<!-- 智多晶产品族命名对照。来源:UG00101 产品宣传册 V2.18(2026-11 实测核对
     dv_list.xml / hqfpga dv.setup / -simlib 分库)。 -->

# 产品族命名对照(营销名 ↔ 器件前缀 ↔ dv_list family)

| 营销名 | 器件前缀 | dv_list family | dv.setup/-simlib 用名 | 定位 |
|---|---|---|---|---|
| Seagull 1000 | — (CPLD) | — | — | CPLD |
| **Sealion 2000** | **SL2***(SL2-12E/22E/25E + S/D 变体) | `SEALION` | SEALION / XiST_SEALION | FPGA(+合封 SDRAM/DDR 的 S、带 DDR2 的 D 型) |
| **Seal 5000** | **SA5***(SA5Z-30/50 SoC、SA5T-70/100/200/366/420 高性能) | `SEAL` | SEAL / XiST_SEAL | SoC FPGA(Cortex-M3/STAR-M33 硬核)+ 高性能 FPGA |
| **Shark 7000** | **SK7***(SK7Z-80/160) | `SHARK` | SHARK / XiST_SHARK | SoC FPGA(STAR-M33 / 64 位双核 RISC-V) |

要点:
- **名字是"错位"的**:dv_list 的 `SEALION`=SL2(营销叫 Sealion 2000),`SEAL`=SA5(营销叫 Seal 5000)——按 dv_list/dv.setup 用名走,别按营销直觉。
- `-family` 推导(hqdnload)、`-simlib` 家族库、`-gen_hqip` 的 IP 匹配全都以这套 family 为准;hqbuddy 已统一封装。
- 家族 token 匹配规则(hqip_gen._family_tokens):dv_list family 命中,或前缀正则 SL2*→SEALION、SA5*/SCM905→SEAL。

## Tiny_SoC 支持面(修正 2026-11-10,以 meta XML devices 字段为准)

`Seal SL2S-22E SL2-25E SL2S-25E SL2D-25E` = **Seal 5000 全系(SA5Z/SA5T 所有型号,
家族 token 命中;SA5Z-30/SA5T-100 已实测 -ipgen 通过)+ Sealion 2000 的
SL2S-22E/SL2-25E/SL2S-25E/SL2D-25E 显式列名**(SL2-12E 与不带 S 的 SL2-22E
不支持)。UG00034 资源表即基于 SA5T-100-D0 测试。
