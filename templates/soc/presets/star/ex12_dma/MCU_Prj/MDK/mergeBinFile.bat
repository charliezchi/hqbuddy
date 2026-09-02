@echo off
set fpgaBinFileDir= "D:\work\ziduojin\50K_100K\50K\M33\STAR_Demo_2023\XIST_STAR_dma\FPGA_Prj\hq_prj\hq_run\fpga_cm33.bin"
set cm3BinFileDir= "D:\work\ziduojin\50K_100K\50K\M33\STAR_Demo_2023\XIST_STAR_dma\MCU_Prj\MDK\dma.bin"
set fpgaAndCm3BinFileDir= "D:\work\ziduojin\50K_100K\50K\M33\STAR_Demo_2023\XIST_STAR_dma\FPGA_Prj\hq_prj\hq_run\fpga_cm33_dma.bin"
set HqDnLoadDir= D:\softInstall\HqFPGA\hq_xist_2.14.1_021923_win64\build\hqdnload

::cd D:\softInstall\HqFPGA\hq_xist_2.14.1_021923_win64\build\hqdnload
cd %HqDnLoadDir%

::合并fpga和CM33的Bin文件
cable.exe --merge %fpgaBinFileDir% --cm3file %cm3BinFileDir%

::下载合并后的文件
cable.exe --sealion  %fpgaAndCm3BinFileDir% --model SA50K --Burst

::pause
