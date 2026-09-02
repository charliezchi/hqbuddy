phycst.start
#clk
phycst.pin.set  {CLK_IN}    J15     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#SW0
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
#SW1
phycst.pin.set {SWITCH1}    P20     -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
phycst.end


######UART0######
#uart0-rx
#phycst.pin.set  {UART0_RX}  G15 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"
#uart0-tx
#phycst.pin.set  {UART0_TX}  G16 -attr "IO_TYPE=LVCMOS33 PULLMODE=NONE"

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

#ADC(F484)
#phycst.pin.set  {ADC_CH0}   E1  -attr "PULLMODE=NONE"
#phycst.pin.set  {ADC_CH1}   B1  -attr "PULLMODE=NONE"
#phycst.pin.set  {ADC_CH2}   D1  -attr "PULLMODE=NONE"
#phycst.pin.set  {ADC_CH3}   A1  -attr "PULLMODE=NONE"
#phycst.pin.set  {ADC_CH4}   G1  -attr "PULLMODE=NONE"
#phycst.pin.set  {ADC_CH5}   C2  -attr "PULLMODE=NONE"
#phycst.pin.set  {ADC_CH6}   F1  -attr "PULLMODE=NONE"
#phycst.pin.set  {ADC_CH7}   B2 -attr "PULLMODE=NONE"



