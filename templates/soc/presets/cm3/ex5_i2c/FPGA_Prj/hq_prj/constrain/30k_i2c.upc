phycst.start
#clk
phycst.pin.set  {CLK_IN}    A4      -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#SW1
phycst.pin.set  {RST_N}     L15     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#swd-port
phycst.pin.set  {SWD_IO}    B12     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.pin.set  {SWD_CLK}   E12     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
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
#I2C CLK
phycst.pin.set  {I2C_SCL}   P15     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#I2C SDA
phycst.pin.set  {I2C_SDA}   R15     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#EEPROM_WP_PIN
phycst.pin.set  {GPIO31}    N14     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.end


#ADC(U213)
#phycst.pin.set  {ADC_CH0}   P2  -attr "PULLMODE=NONE"
#phycst.pin.set  {ADC_CH1}   R1  -attr "PULLMODE=NONE"


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

