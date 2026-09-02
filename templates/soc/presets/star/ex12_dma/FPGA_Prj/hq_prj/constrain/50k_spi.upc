phycst.start
#clk
phycst.pin.set  {CLK_IN}    J15     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#SW4
phycst.pin.set  {RST_N}     P19     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#swd-port
phycst.pin.set  {SWD_IO}    B18     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.pin.set  {SWD_CLK}   B17     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#LED-D1
phycst.pin.set  {FPGA_LED}  R19     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#LED-D2
phycst.pin.set  {LED2}      T21     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#LED-D3
phycst.pin.set  {LED3}      T20     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
######UART0######
#uart0-rx
phycst.pin.set  {UART0_RX}  G15     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#uart0-tx
phycst.pin.set  {UART0_TX}  G16     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
######SPI0,FLASH######
phycst.pin.set  {SPI0_SCK_OUT}  L12 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.pin.set  {SPI0_SEL_OUT}  T19 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.pin.set  {SPI0_DATA[0]}  P22 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.pin.set  {SPI0_DATA[1]}  R22 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.pin.set  {SPI0_DATA[2]}  P21 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.pin.set  {SPI0_DATA[3]}  R21 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.end


#LED1,LED2,3,4
#phycst.pin.set {xx}        R19   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        T21   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        T20   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        U21   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"

#SWITCH 0,1,2,3
#phycst.pin.set {xx}        P19   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        P20   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        F21   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        H17   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"