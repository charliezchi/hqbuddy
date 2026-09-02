/* Xist IP builder*/

`timescale 1 ns / 1 ps
module FIFO_32bit ( Data, WrClock, RdClock, WrEn, RdEn,  Reset, RPReset, 
    Q, Empty, Full, AlmostEmpty, AlmostFull);
    input wire [31:0] Data;
    input wire WrClock;
    input wire RdClock;
    input wire WrEn;
    input wire RdEn;
    
    input wire Reset;
    input wire RPReset;
    output wire [31:0] Q;
    output wire Empty;
    output wire Full;
    output wire AlmostEmpty;
    output wire AlmostFull;

    wire Empty_int;
    wire Full_int;
	
    supply1 ipgen_VCC;
    supply0 ipgen_GND;

	

	defparam fifo_0_0_0.EMPTYPOINTER = "0b00000";
    defparam fifo_0_0_0.EMPTYPOINTER1 = "0b000000";
    defparam fifo_0_0_0.USE_EMPTYPOINTER = "FALSE";
    defparam fifo_0_0_0.FULLPOINTER1 = "0b01111111110000" ;
    defparam fifo_0_0_0.FULLPOINTER = "0b10000000000000" ;
    defparam fifo_0_0_0.AFPOINTER1 = "0b01111111010000" ;
    defparam fifo_0_0_0.AFPOINTER = "0b01111111100000" ;
    defparam fifo_0_0_0.AEPOINTER1 = "0b00000010110000" ;
    defparam fifo_0_0_0.AEPOINTER = "0b00000010100000" ;
    defparam fifo_0_0_0.ASYNC_RESET_RELEASE = "ASYNC" ;
    defparam fifo_0_0_0.GSR = "DISABLED" ;
    defparam fifo_0_0_0.RESETMODE = "ASYNC" ;
    defparam fifo_0_0_0.REGMODE = "NOREG" ;
    defparam fifo_0_0_0.CSDECODE_R = "0b11" ;
    defparam fifo_0_0_0.CSDECODE_W = "0b11" ;
    defparam fifo_0_0_0.DATA_WIDTH_R = 18 ;
    defparam fifo_0_0_0.DATA_WIDTH_W = 18 ;
    xsFIFO8KB fifo_0_0_0  (.DI0(Data[0]), .DI1(Data[1]), .DI2(Data[2]), 
        .DI3(Data[3]), .DI4(Data[4]), .DI5(Data[5]), .DI6(Data[6]), 
        .DI7(Data[7]), .DI8(ipgen_GND), .DI9(Data[8]), .DI10(Data[9]), 
        .DI11(Data[10]), .DI12(Data[11]), .DI13(Data[12]), .DI14(Data[13]), 
        .DI15(Data[14]), .DI16(Data[15]), .DI17(ipgen_GND), .DI18(ipgen_GND),
		.DI19(ipgen_GND), .DI20(ipgen_GND), .DI21(ipgen_GND), .DI22(ipgen_GND),
		.DI23(ipgen_GND), .DI24(ipgen_GND), .DI25(ipgen_GND), .DI26(ipgen_GND),
		.DI27(ipgen_GND), .DI28(ipgen_GND), .DI29(ipgen_GND), .DI30(ipgen_GND),
		.DI31(ipgen_GND), .DI32(ipgen_GND), .DI33(ipgen_GND), .DI34(ipgen_GND),
		.DI35(ipgen_GND), .CSW0(ipgen_VCC), .CSW1(ipgen_VCC), .CSR0(ipgen_VCC),
		.CSR1(ipgen_VCC), .FULLI(Full_int), .EMPTYI(Empty_int), .WE(WrEn), .RE(RdEn),
		.ORE(RdEn),.CLKW(WrClock), .CLKR(RdClock), .RST(Reset), .RPRST(RPReset),
		.DO0(Q[0]), .DO1(Q[1]), .DO2(Q[2]), .DO3(Q[3]), .DO4(Q[4]), .DO5(Q[5]), .DO6(Q[6]), .DO7(Q[7]),
		.DO8(), .DO9(Q[8]), .DO10(Q[9]), .DO11(Q[10]), .DO12(Q[11]), .DO13(Q[12]), .DO14(Q[13]),
		.DO15(Q[14]), .DO16(Q[15]), .DO17(), .DO18(), .DO19(), .DO20(), .DO21(),
		.DO22(), .DO23(), .DO24(), .DO25(), .DO26(), .DO27(), .DO28(),
		.DO29(), .DO30(), .DO31(), .DO32(), .DO33(), .DO34(), .DO35(), 
		.EF(Empty_int), .AEF(AlmostEmpty), .AFF(AlmostFull), .FF(Full_int));

    
		

	defparam fifo_0_1_1.EMPTYPOINTER = "0b00000";
    defparam fifo_0_1_1.EMPTYPOINTER1 = "0b000000";
    defparam fifo_0_1_1.USE_EMPTYPOINTER = "FALSE";
    defparam fifo_0_1_1.FULLPOINTER1 = "0b01111111110000" ;
    defparam fifo_0_1_1.FULLPOINTER = "0b10000000000000" ;
    defparam fifo_0_1_1.AFPOINTER1 = "0b01111111010000" ;
    defparam fifo_0_1_1.AFPOINTER = "0b01111111100000" ;
    defparam fifo_0_1_1.AEPOINTER1 = "0b00000010110000" ;
    defparam fifo_0_1_1.AEPOINTER = "0b00000010100000" ;
    defparam fifo_0_1_1.ASYNC_RESET_RELEASE = "ASYNC" ;
    defparam fifo_0_1_1.GSR = "DISABLED" ;
    defparam fifo_0_1_1.RESETMODE = "ASYNC" ;
    defparam fifo_0_1_1.REGMODE = "NOREG" ;
    defparam fifo_0_1_1.CSDECODE_R = "0b11" ;
    defparam fifo_0_1_1.CSDECODE_W = "0b11" ;
    defparam fifo_0_1_1.DATA_WIDTH_R = 18 ;
    defparam fifo_0_1_1.DATA_WIDTH_W = 18 ;
    xsFIFO8KB fifo_0_1_1  (.DI0(Data[16]), .DI1(Data[17]), .DI2(Data[18]), 
        .DI3(Data[19]), .DI4(Data[20]), .DI5(Data[21]), .DI6(Data[22]), 
        .DI7(Data[23]), .DI8(ipgen_GND), .DI9(Data[24]), .DI10(Data[25]), 
        .DI11(Data[26]), .DI12(Data[27]), .DI13(Data[28]), .DI14(Data[29]), 
        .DI15(Data[30]), .DI16(Data[31]), .DI17(ipgen_GND), .DI18(ipgen_GND),
		.DI19(ipgen_GND), .DI20(ipgen_GND), .DI21(ipgen_GND), .DI22(ipgen_GND),
		.DI23(ipgen_GND), .DI24(ipgen_GND), .DI25(ipgen_GND), .DI26(ipgen_GND),
		.DI27(ipgen_GND), .DI28(ipgen_GND), .DI29(ipgen_GND), .DI30(ipgen_GND),
		.DI31(ipgen_GND), .DI32(ipgen_GND), .DI33(ipgen_GND), .DI34(ipgen_GND),
		.DI35(ipgen_GND), .CSW0(ipgen_VCC), .CSW1(ipgen_VCC), .CSR0(ipgen_VCC),
		.CSR1(ipgen_VCC), .FULLI(Full_int), .EMPTYI(Empty_int), .WE(WrEn), .RE(RdEn),
		.ORE(RdEn),.CLKW(WrClock), .CLKR(RdClock), .RST(Reset), .RPRST(RPReset),
		.DO0(Q[16]), .DO1(Q[17]), .DO2(Q[18]), .DO3(Q[19]), .DO4(Q[20]), .DO5(Q[21]), .DO6(Q[22]), .DO7(Q[23]),
		.DO8(), .DO9(Q[24]), .DO10(Q[25]), .DO11(Q[26]), .DO12(Q[27]), .DO13(Q[28]), .DO14(Q[29]),
		.DO15(Q[30]), .DO16(Q[31]), .DO17(), .DO18(), .DO19(), .DO20(), .DO21(),
		.DO22(), .DO23(), .DO24(), .DO25(), .DO26(), .DO27(), .DO28(),
		.DO29(), .DO30(), .DO31(), .DO32(), .DO33(), .DO34(), .DO35(), 
		.EF(), .AEF(), .AFF(), .FF());

    
		
    assign Empty = Empty_int;
    assign Full = Full_int;
endmodule