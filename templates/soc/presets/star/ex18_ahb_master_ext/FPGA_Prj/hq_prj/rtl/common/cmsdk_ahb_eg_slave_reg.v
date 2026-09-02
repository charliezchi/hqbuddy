//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2010-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//      SVN Information
//
//      Checked In          : $Date: 2013-01-09 12:55:25 +0000 (Wed, 09 Jan 2013) $
//
//      Revision            : $Revision: 233070 $
//
//      Release Information : Cortex-M System Design Kit-r1p0-00rel0
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Abstract : AHB-lite example slave register module. provide register write
//            and read operation. Data and address valid at the same clock
//            cycle.
//-----------------------------------------------------------------------------

module cmsdk_ahb_eg_slave_reg #(
  // parameter for address width
  parameter   ADDRWIDTH=12)
 (
  input  wire                   hclk,       // clock
  input  wire                   hresetn,    // reset

   //Register interface
  input  wire [ADDRWIDTH-1:0]   addr,
  input  wire                   read_en,
  input  wire                   write_en,
  input  wire [3:0]             byte_strobe,
  input  wire [31:0]            wdata,
  input  wire [3:0]             ecorevnum,
  output reg  [31:0]            rdata,
  
  //ROM W/R Data
  output wire  [31:0] ROM_Control,
  output wire  [31:0] ROM_WAddress,
  output wire  [31:0] ROM_WData,
  output reg          regW_en,
  output wire  [31:0] ROM_RAddress,
  input  wire  [31:0] ROM_RData
  
  );


  // internal signals
  reg    [31:0]            regControl;
  reg    [31:0]            regWAddress;
  reg    [31:0]            regWData;
  reg    [31:0]            regRAddress;
  wire   [31:0]            regRData;
  wire   [4:0]             wr_sel;


   // Local ID parameters, AHB example slave has part number of 817
localparam  ARM_CMSDK_AHB_EG_SLAVE_PID4 = 32'h00000004; // 0xFD0 : PID 4
localparam  ARM_CMSDK_AHB_EG_SLAVE_PID5 = 32'h00000000; // 0xFD4 : PID 5
localparam  ARM_CMSDK_AHB_EG_SLAVE_PID6 = 32'h00000000; // 0xFD8 : PID 6
localparam  ARM_CMSDK_AHB_EG_SLAVE_PID7 = 32'h00000000; // 0xFDC : PID 7
localparam  ARM_CMSDK_AHB_EG_SLAVE_PID0 = 32'h00000017; // 0xFE0 : PID 0 AHB Example slave part number[7:0]
localparam  ARM_CMSDK_AHB_EG_SLAVE_PID1 = 32'h000000B8; // 0xFE4 : PID 1 [7:4] jep106_id_3_0. [3:0] part number [11:8]
localparam  ARM_CMSDK_AHB_EG_SLAVE_PID2 = 32'h0000001B; // 0xFE8 : PID 2 [7:4] revision, [3] jedec_used. [2:0] jep106_id_6_4
localparam  ARM_CMSDK_AHB_EG_SLAVE_PID3 = 32'h00000000; // 0xFEC : PID 3
localparam  ARM_CMSDK_AHB_EG_SLAVE_CID0 = 32'h0000000D; // 0xFF0 : CID 0
localparam  ARM_CMSDK_AHB_EG_SLAVE_CID1 = 32'h000000F0; // 0xFF4 : CID 1 PrimeCell class
localparam  ARM_CMSDK_AHB_EG_SLAVE_CID2 = 32'h00000005; // 0xFF8 : CID 2
localparam  ARM_CMSDK_AHB_EG_SLAVE_CID3 = 32'h000000B1; // 0xFFC : CID 3
         // Note : Customer changing the design should modify
         // - jep106 value (www.jedec.org)
         // - part number (customer define)
         // - Optional revision and modification number (e.g. rXpY)

 //------------------------------------------------------------------------------
 // module logic start
 //------------------------------------------------------------------------------
  // Address decoding for write operations
  assign wr_sel[0] = ((addr[11:2]==10'b0000000000)&(write_en)) ? 1'b1: 1'b0;  //0xA0000000
  assign wr_sel[1] = ((addr[11:2]==10'b0000000001)&(write_en)) ? 1'b1: 1'b0;  //0xA0000004
  assign wr_sel[2] = ((addr[11:2]==10'b0000000010)&(write_en)) ? 1'b1: 1'b0;  //0xA0000008
  assign wr_sel[3] = ((addr[11:2]==10'b0000000011)&(write_en)) ? 1'b1: 1'b0;  //0xA000000c
  assign wr_sel[4] = ((addr[11:2]==10'b0000000100)&(write_en)) ? 1'b1: 1'b0;  //0xA0000010


  // register write, with byte enable
  // regControl
  always @(posedge hclk or negedge hresetn)
    begin
    if (~hresetn)
      begin
        regControl <= {32{1'b0}}; // reset data register to 0x00000000
      end
    else if (wr_sel[0])
      begin
        if (byte_strobe[0])
            regControl[ 7: 0] <= wdata[ 7: 0];
        if (byte_strobe[1])
            regControl[15: 8] <= wdata[15: 8];
        if (byte_strobe[2])
            regControl[23:16] <= wdata[23:16];
        if (byte_strobe[3])
            regControl[31:24] <= wdata[31:24];
      end
    end


   //regWAddress
  always @(posedge hclk or negedge hresetn)
    begin
    if (~hresetn)
      begin
        regWAddress <= {32{1'b0}}; // reset data register to 0x00000000
      end
    else if (wr_sel[1])
      begin
        if (byte_strobe[0])
            regWAddress[ 7: 0] <= wdata[ 7: 0];
        if (byte_strobe[1])
            regWAddress[15: 8] <= wdata[15: 8];
        if (byte_strobe[2])
            regWAddress[23:16] <= wdata[23:16];
        if (byte_strobe[3])
            regWAddress[31:24] <= wdata[31:24];
      end
    end


  //regWData
  always @(posedge hclk or negedge hresetn)
    begin
    if (~hresetn)
      begin
        regWData <= {32{1'b0}}; // reset data register to 0x00000000
      end
    else if (wr_sel[2])
      begin
        if (byte_strobe[0])
            regWData[ 7: 0] <= wdata[ 7: 0];
        if (byte_strobe[1])
            regWData[15: 8] <= wdata[15: 8];
        if (byte_strobe[2])
            regWData[23:16] <= wdata[23:16];
        if (byte_strobe[3])
            regWData[31:24] <= wdata[31:24];
      end
    end

always @(posedge hclk or negedge hresetn)
begin
   if (~hresetn)
   begin
      regW_en <= 1'b0; // reset data register to 0x00000000
   end
   else if (wr_sel[2])
   begin
      if (byte_strobe == 4'b1111)
         regW_en <= 1'b1;
      else
         regW_en <= 1'b0;
   end
   else
	  regW_en <= 1'b0;
end

  //regRAddress
  always @(posedge hclk or negedge hresetn)
    begin
    if (~hresetn)
      begin
        regRAddress <= {32{1'b0}}; // reset data register to 0x00000000
      end
    else if (wr_sel[3])
      begin
        if (byte_strobe[0])
            regRAddress[ 7: 0] <= wdata[ 7: 0];
        if (byte_strobe[1])
            regRAddress[15: 8] <= wdata[15: 8];
        if (byte_strobe[2])
            regRAddress[23:16] <= wdata[23:16];
        if (byte_strobe[3])
            regRAddress[31:24] <= wdata[31:24];
      end
    end

/*	
  //regRData
  always @(posedge hclk or negedge hresetn)
    begin
    if (~hresetn)
      begin
        regRData <= {32{1'b0}}; // reset data register to 0x00000000
      end
    else if (wr_sel[4])
      begin
        if (byte_strobe[0])
            regRData[ 7: 0] <= wdata[ 7: 0];
        if (byte_strobe[1])
            regRData[15: 8] <= wdata[15: 8];
        if (byte_strobe[2])
            regRData[23:16] <= wdata[23:16];
        if (byte_strobe[3])
            regRData[31:24] <= wdata[31:24];
      end
    end
*/

assign ROM_Control = regControl;
assign ROM_RAddress = regRAddress;
assign ROM_WAddress = regWAddress;
assign ROM_WData = regWData;
assign regRData = ROM_RData;

 //register read
always @ (read_en or addr or regControl or regWAddress or regWData or regRAddress or regRData or ecorevnum)
 begin
   case (read_en)
     1'b1:
     begin
       if (addr[11:5] == 8'h00) begin
         case(addr[4:2])
           3'b000: rdata =  regControl;    //0xA0000000
           3'b001: rdata =  regWAddress;   //0xA0000004
           3'b010: rdata =  regWData;      //0xA0000008
           3'b011: rdata =  regRAddress;   //0xA000000c
		   3'b100: rdata =  regRData;      //0xA0000010
           default: rdata = {32{1'bx}};
         endcase
       end
       else if (addr[11:6] == 6'h3F) begin
         case(addr[5:2])
          // Peripheral IDs and Component IDs.
          // AHB example slave has part number of 817
         4'b0100: rdata = ARM_CMSDK_AHB_EG_SLAVE_PID4; // 0xFD0 : PID 4
         4'b0101: rdata = ARM_CMSDK_AHB_EG_SLAVE_PID5; // 0xFD4 : PID 5
         4'b0110: rdata = ARM_CMSDK_AHB_EG_SLAVE_PID6; // 0xFD8 : PID 6
         4'b0111: rdata = ARM_CMSDK_AHB_EG_SLAVE_PID7; // 0xFDC : PID 7
         4'b1000: rdata = ARM_CMSDK_AHB_EG_SLAVE_PID0; // 0xFE0 : PID 0 AHB Example slave part number[7:0]
         4'b1001: rdata = ARM_CMSDK_AHB_EG_SLAVE_PID1; // 0xFE4 : PID 1 [7:4] jep106_id_3_0. [3:0] part number [11:8]
         4'b1010: rdata = ARM_CMSDK_AHB_EG_SLAVE_PID2; // 0xFE8 : PID 2 [7:4] revision, [3] jedec_used. [2:0] jep106_id_6_4
         4'b1011: rdata = {ARM_CMSDK_AHB_EG_SLAVE_PID3[31:8], ecorevnum[3:0], 4'h0};
                                         // 0xFEC : PID 3 [7:4]  ECO rev number, [3:0] modification number
         4'b1100: rdata = ARM_CMSDK_AHB_EG_SLAVE_CID0; // 0xFF0 : CID 0
         4'b1101: rdata = ARM_CMSDK_AHB_EG_SLAVE_CID1; // 0xFF4 : CID 1 PrimeCell class
         4'b1110: rdata = ARM_CMSDK_AHB_EG_SLAVE_CID2; // 0xFF8 : CID 2
         4'b1111: rdata = ARM_CMSDK_AHB_EG_SLAVE_CID3; // 0xFFC : CID 3
         // Note : Customer changing the design should modify
         // - jep106 value (www.jedec.org)
         // - part number (customer define)
         // - Optional revision and modification number (e.g. rXpY)
         4'b0000, 4'b0001,4'b0010,4'b0011: rdata = {32'h00000000}; // default
         default: rdata =  {32{1'bx}};  // x propogation
         endcase
       end
       else begin
         rdata = {32'h00000000}; // default
       end
     end
   1'b0:
     begin
       rdata =  {32{1'b0}};
     end
   default:
     begin
       rdata =  {32{1'bx}};
     end
   endcase
 end

 //------------------------------------------------------------------------------
 // module logic end
 //------------------------------------------------------------------------------



 endmodule
