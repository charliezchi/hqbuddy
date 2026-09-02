@echo off
set current_dir=%cd%
set baseDir=%current_dir:~0,-11%
set fpgaBinFile=FPGA_Prj\hq_prj\hq_run\hq_prj.bin
set CM33BinFile=MCU_Prj\MDK\uart.bin
set fpgaAndCm3BinFile=FPGA_Prj\hq_prj\hq_run\hq_prj_uart.bin

set fpgaBinFileDir="%baseDir%%fpgaBinFile%"
set cm3BinFileDir="%baseDir%%CM33BinFile%"
set fpgaAndCm3BinFileDir="%baseDir%%fpgaAndCm3BinFile%"

:: hqdnload安装目录
set HqDnLoadDir= D:\hqui\hqv3_xist_3.0.6_FT090925_win64\build\hqdnload


cd %HqDnLoadDir%

::合并fpga和CM33的Bin文件
cable.exe --merge %fpgaBinFileDir% --cm3file %cm3BinFileDir% --remap  "000"

::下载合并后的文件
cable.exe --sealion  %fpgaAndCm3BinFileDir% --model SA30K --Burst

::pause
