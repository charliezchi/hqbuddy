phycst.start
#clk
phycst.pin.set  {CLK_IN}    A4     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#SW1
phycst.pin.set  {RST_N}     L15     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#swd-port
phycst.pin.set  {SWD_IO}    A14     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.pin.set  {SWD_CLK}   A15     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#LED-D1
phycst.pin.set  {FPGA_LED}  P14     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#LED-D2
phycst.pin.set  {LED2}      R14     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#LED-D3
phycst.pin.set  {LED3}      P13     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
######UART0######
#uart0-rx
phycst.pin.set  {UART0_RX}  P12     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#uart0-tx
phycst.pin.set  {UART0_TX}  R12     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.end

#LED1,LED2,3,4
#phycst.pin.set {xx}        P14   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        R14   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        P13   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        R13   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"

#SWITCH 1,2,3,4
#phycst.pin.set {xx}        L15   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        M15   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        R11   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {xx}        P11   -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"

#phycst.pin.set {jtag_tms}           F15 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {jtag_tdi}           D15 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {jtag_tdo}           D14 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#phycst.pin.set {jtag_tck}           E13 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"