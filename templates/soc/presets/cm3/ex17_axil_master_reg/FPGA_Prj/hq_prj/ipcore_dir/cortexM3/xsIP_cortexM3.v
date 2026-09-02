// ============================================================================
//                          COPYRIGHT NOTICE
// Copyright (c) 2014       Xi'an Intelligence Silicon Technology Co.,Ltd.
// ALL RIGHTS RESERVED
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Xi'an Intelligence Silicon Technology Co.,Ltd. The entire
// notice above must be reproduced on all authorized copies and copies may
// only be made to the extent permitted by a licensing agreement from
// Xi'an Intelligence Silicon Technology Co.,Ltd.
// ============================================================================
// Description     : The Cortex-M3 is a low-power processor that features low gate count, 
// low interrupt latency, and low-cost debug. It is intended for deeply embedded 
// applications that require optimal interrupt response features. 
//
// Author          : Liu Chengzhang
// Date            : Dec. 5th, 2025
// Revision        : 4.1
// Revision History: 
// v3.0            : Sep. 28th, 2025
//  1. Modify the IP clock, reset the interface, and add a bus matrix to achieve interface expansion, etc.
// v4.0            : Nov. 7th, 2025
//  1. When selecting the SA5Z-30-D3 component, ADC configuration is no longer supported;
//  2. The debugging interface supports either JTAG or SWD, or neither can be selected;
//  3. Support for example output;
//  4. Correct the channel selection error when using AHB and APB for channel expansion;
//  5. Correct the pin number value of the U324 package for the 30K device in the ADC description information of the peripheral page.
// v4.1            : Dec. 5th, 2025
//  1. Add head-related descriptions to the IP file.
// v4.2            : Jan. 4th, 2026
//  1. Correct the problem of the bus ready signal remaining constantly high.
//  2. Correct the problem of incorrect initial data caused by the unused tristate buffer for the serial port TX signal.
//  3. Correct the problem of not using the tri-state buffer when all GPIO pins are selected.
// ============================================================================
module cortexM3(
    input  wire         CLK_IN,         
    //## SWD interface
    input  wire         SWD_CLK,        
    inout  wire         SWD_IO,         
    //## GPIO interface
    inout  wire         GPIO0,          
    inout  wire         GPIO1,          
    //## UART0 interface
    input  wire         UART0_RX,        
    output wire         UART0_TX,        
    //## External interrupt interface
    //## CH0 interface
    //## CH0 AXIL master00 interface
    output  wire    [31:0]  CH0_M00_AXIL_AWADDR,
    output  wire    [2:0]   CH0_M00_AXIL_AWPROT,
    output  wire            CH0_M00_AXIL_AWVALID,
    input   wire            CH0_M00_AXIL_AWREADY,
    output  wire    [31:0]  CH0_M00_AXIL_WDATA,
    output  wire    [3:0]   CH0_M00_AXIL_WSTRB,
    output  wire            CH0_M00_AXIL_WVALID,
    input   wire            CH0_M00_AXIL_WREADY,
    input   wire    [1:0]   CH0_M00_AXIL_BRESP,
    input   wire            CH0_M00_AXIL_BVALID,
    output  wire            CH0_M00_AXIL_BREADY,
    output  wire    [31:0]  CH0_M00_AXIL_ARADDR,
    output  wire    [2:0]   CH0_M00_AXIL_ARPROT,
    output  wire            CH0_M00_AXIL_ARVALID,
    input   wire            CH0_M00_AXIL_ARREADY,
    input   wire    [31:0]  CH0_M00_AXIL_RDATA,
    input   wire    [1:0]   CH0_M00_AXIL_RRESP,
    input   wire            CH0_M00_AXIL_RVALID,
    output  wire            CH0_M00_AXIL_RREADY,
    //## reset interface
    input  wire         RST_N       
);
    localparam PCLK_DIV = 0;                     
    localparam SYSTICK_EN = "FALSE";                    
    localparam QSPI_ADDRSEL = "FALSE";                  
    localparam QSPI_SCKMODE = "FALSE";                  
    localparam QSPI_XPRALBSIZE = "FALSE";               
    localparam QSPI_XPRDDRMODE = "FALSE";               
    localparam QSPI_XPREN = "FALSE";                    
    localparam MPU_NSDISABLE = "TRUE";           
    localparam CFGFMADDR = 12'b0000_0000_0001;
    localparam REF_SEL_30K  = "VCCAUX";     
    localparam REF_SEL_50K  = 0;            
    localparam OT_PD_ENABLE = "ENABLED";     
    localparam OT_CODE_L    = 0;            
    localparam OT_CODE_H    = 0;            
    localparam M0_AXI_M_COUNT = 1;                
    localparam M0_AXI_S_COUNT = 1;                
    localparam M0_AHB_M_COUNT = 1;                
    localparam M0_APB_M_COUNT = 1;                
    localparam M0_AXIL_M_COUNT = 1;  
    localparam M0_AXIL_S_COUNT = 0;  
    localparam M1_AXI_M_COUNT = 1;                
    localparam M1_AXI_S_COUNT = 1;                
    localparam M1_AHB_M_COUNT = 1;                
    localparam M1_APB_M_COUNT = 1;                
    localparam M1_AXIL_M_COUNT = 1;                
    localparam M1_AXIL_S_COUNT = 1;                
    localparam M0_BASE_ADDR = 32'hA0000000;  
    localparam M1_BASE_ADDR = 32'hC0000000;  
    localparam M0_OFFSET_SIZE_WIDTH = 25;    
    localparam M1_OFFSET_SIZE_WIDTH = 25;    
    wire            M0HSEL;
    wire    [31:0]  M0HADDR;
    wire    [31:0]  M0HWDATA;
    wire    [2:0]   M0HWSTRB;
    wire            M0HWRITE;
    wire            M0HREADYMUX;
    wire            M0HREADYOUT;
    wire    [31:0]  M0HRDATA;
    wire            M0HRESP;
    wire    [1:0]   M0HTRANS;
    wire    [2:0]   M0HSIZE;
    wire    [2:0]   M0HBURST;
    wire    [3:0]   M0HPROT;
    wire            M0HMASTLOCK;
core2048 #  (
    .PCLK_DIV           (PCLK_DIV),           
    .CFGFMADDR          (CFGFMADDR),        
    .MPU_NSDISABLE      (MPU_NSDISABLE)       
)
core_inst   (
    .CLK_IN             (CLK_IN),       
    .SWDIO              (SWD_IO),           
    .SWCLK              (SWD_CLK),          
    .GPIO0              (GPIO0),        
    .GPIO1              (GPIO1),        
    .UART0_TX           (UART0_TX),     
    .UART0_RX           (UART0_RX),      
    .M0HADDR            (M0HADDR),      
    .M0HBURST           (M0HBURST),     
    .M0HMASTLOCK        (M0HMASTLOCK),  
    .M0HPROT            (M0HPROT),      
    .M0HRDATA           (M0HRDATA),     
    .M0HRESP            (M0HRESP),      
    .M0HSEL             (M0HSEL),       
    .M0HSIZE            (M0HSIZE),      
    .M0HTRANS           (M0HTRANS),     
    .M0HWDATA           (M0HWDATA),     
    .M0HWRITE           (M0HWRITE),     
    .M0HREADYMUX        (M0HREADYMUX),  
    .M0HREADYOUT        (M0HREADYOUT),  
    .RST_N              (RST_N)       
);
wire [M0_AHB_M_COUNT-1:0]      CH0_M_HSEL;
wire [M0_AHB_M_COUNT *32-1:0]  CH0_M_HADDR;
wire [M0_AHB_M_COUNT *2-1:0]   CH0_M_HTRANS;
wire [M0_AHB_M_COUNT *3-1:0]   CH0_M_HSIZE;
wire [M0_AHB_M_COUNT *3-1:0]   CH0_M_HBURST;
wire [M0_AHB_M_COUNT-1:0]      CH0_M_HMASTLOCK;
wire [M0_AHB_M_COUNT *4-1:0]   CH0_M_HPROT;
wire [M0_AHB_M_COUNT-1:0]      CH0_M_HWRITE;
wire [M0_AHB_M_COUNT *32-1:0]  CH0_M_HWDATA;
wire [M0_AHB_M_COUNT-1:0]      CH0_M_HREADYMUX;
wire [M0_AHB_M_COUNT *32-1:0]  CH0_M_HRDATA;
wire [M0_AHB_M_COUNT-1:0]      CH0_M_HRESP;
wire [M0_AHB_M_COUNT-1:0]      CH0_M_HREADYOUT;
wire [M0_APB_M_COUNT *32-1:0]  CH0_M_PADDR;
wire [M0_APB_M_COUNT *32-1:0]  CH0_M_PWDATA;
wire [M0_APB_M_COUNT-1:0]      CH0_M_PSEL;
wire [M0_APB_M_COUNT-1:0]      CH0_M_PENABLE;
wire [M0_APB_M_COUNT-1:0]      CH0_M_PWRITE;
wire [M0_APB_M_COUNT *4-1:0]   CH0_M_PSTRB;
wire [M0_APB_M_COUNT *3-1:0]   CH0_M_PPROT;
wire [M0_APB_M_COUNT-1:0]      CH0_M_PREADY;
wire [M0_APB_M_COUNT *32-1:0]  CH0_M_PRDATA;
wire [M0_APB_M_COUNT-1:0]      CH0_M_PSLVERR;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_AWID;
wire [M0_AXI_M_COUNT *32-1:0]  CH0_M_AXI_AWADDR;
wire [M0_AXI_M_COUNT *8-1:0]   CH0_M_AXI_AWLEN;
wire [M0_AXI_M_COUNT *3-1:0]   CH0_M_AXI_AWSIZE;
wire [M0_AXI_M_COUNT *2-1:0]   CH0_M_AXI_AWBURST;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_AWLOCK;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_AWCACHE;
wire [M0_AXI_M_COUNT *3-1:0]   CH0_M_AXI_AWPROT;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_AWREGION;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_AWQOS;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_AWVALID;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_AWREADY;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_AWUSER;
wire [M0_AXI_M_COUNT *32-1:0]  CH0_M_AXI_WDATA;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_WSTRB;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_WLAST;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_WUSER;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_WVALID;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_WREADY;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_BID;
wire [M0_AXI_M_COUNT *2-1:0]   CH0_M_AXI_BRESP;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_BVALID;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_BREADY;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_BUSER;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_ARID;
wire [M0_AXI_M_COUNT *32-1:0]  CH0_M_AXI_ARADDR;
wire [M0_AXI_M_COUNT *8-1:0]   CH0_M_AXI_ARLEN;
wire [M0_AXI_M_COUNT *3-1:0]   CH0_M_AXI_ARSIZE;
wire [M0_AXI_M_COUNT *2-1:0]   CH0_M_AXI_ARBURST;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_ARLOCK;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_ARCACHE;
wire [M0_AXI_M_COUNT *3-1:0]   CH0_M_AXI_ARPROT;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_ARREGION;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_ARQOS;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_ARVALID;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_ARREADY;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_ARUSER;
wire [M0_AXI_M_COUNT *4-1:0]   CH0_M_AXI_RID;
wire [M0_AXI_M_COUNT *32-1:0]  CH0_M_AXI_RDATA;
wire [M0_AXI_M_COUNT *2-1:0]   CH0_M_AXI_RRESP;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_RLAST;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_RVALID;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_RREADY;
wire [M0_AXI_M_COUNT-1:0]      CH0_M_AXI_RUSER;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_AWID;
wire [M0_AXI_S_COUNT *32-1:0]   CH0_S_AXI_AWADDR;
wire [M0_AXI_S_COUNT *8-1:0]    CH0_S_AXI_AWLEN;
wire [M0_AXI_S_COUNT *3-1:0]    CH0_S_AXI_AWSIZE;
wire [M0_AXI_S_COUNT *2-1:0]    CH0_S_AXI_AWBURST;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_AWLOCK;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_AWCACHE;
wire [M0_AXI_S_COUNT *3-1:0]    CH0_S_AXI_AWPROT;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_AWQOS;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_AWVALID;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_AWREADY;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_AWUSER;
wire [M0_AXI_S_COUNT *32-1:0]   CH0_S_AXI_WDATA;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_WSTRB;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_WLAST;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_WVALID;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_WREADY;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_WUSER;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_BID;
wire [M0_AXI_S_COUNT *2-1:0]    CH0_S_AXI_BRESP;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_BVALID;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_BREADY;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_BUSER;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_ARID;
wire [M0_AXI_S_COUNT *32-1:0]   CH0_S_AXI_ARADDR;
wire [M0_AXI_S_COUNT *8-1:0]    CH0_S_AXI_ARLEN;
wire [M0_AXI_S_COUNT *3-1:0]    CH0_S_AXI_ARSIZE;
wire [M0_AXI_S_COUNT *2-1:0]    CH0_S_AXI_ARBURST;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_ARLOCK;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_ARCACHE;
wire [M0_AXI_S_COUNT *3-1:0]    CH0_S_AXI_ARPROT;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_ARQOS;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_ARVALID;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_ARREADY;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_ARUSER;
wire [M0_AXI_S_COUNT *4-1:0]    CH0_S_AXI_RID;
wire [M0_AXI_S_COUNT *32-1:0]   CH0_S_AXI_RDATA;
wire [M0_AXI_S_COUNT *2-1:0]    CH0_S_AXI_RRESP;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_RLAST;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_RVALID;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_RREADY;
wire [M0_AXI_S_COUNT-1:0]       CH0_S_AXI_RUSER;
wire [M0_AXIL_M_COUNT *32-1:0]  CH0_M_AXIL_AWADDR;
wire [M0_AXIL_M_COUNT *3-1:0]   CH0_M_AXIL_AWPROT;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_AWVALID;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_AWREADY;
wire [M0_AXIL_M_COUNT *32-1:0]  CH0_M_AXIL_WDATA;
wire [M0_AXIL_M_COUNT *4-1:0]   CH0_M_AXIL_WSTRB;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_WVALID;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_WREADY;
wire [M0_AXIL_M_COUNT *2-1:0]   CH0_M_AXIL_BRESP;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_BVALID;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_BREADY;
wire [M0_AXIL_M_COUNT *32-1:0]  CH0_M_AXIL_ARADDR;
wire [M0_AXIL_M_COUNT *3-1:0]   CH0_M_AXIL_ARPROT;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_ARVALID;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_ARREADY;
wire [M0_AXIL_M_COUNT *32-1:0]  CH0_M_AXIL_RDATA;
wire [M0_AXIL_M_COUNT *2-1:0]   CH0_M_AXIL_RRESP;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_RVALID;
wire [M0_AXIL_M_COUNT-1:0]      CH0_M_AXIL_RREADY;
wire [M0_AXIL_S_COUNT *32-1:0]  CH0_S_AXIL_AWADDR;
wire [M0_AXIL_S_COUNT *3-1:0]   CH0_S_AXIL_AWPROT;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_AWVALID;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_AWREADY;
wire [M0_AXIL_S_COUNT *32-1:0]  CH0_S_AXIL_WDATA;
wire [M0_AXIL_S_COUNT *4-1:0]   CH0_S_AXIL_WSTRB;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_WVALID;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_WREADY;
wire [M0_AXIL_S_COUNT *2-1:0]   CH0_S_AXIL_BRESP;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_BVALID;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_BREADY;
wire [M0_AXIL_S_COUNT *32-1:0]  CH0_S_AXIL_ARADDR;
wire [M0_AXIL_S_COUNT *3-1:0]   CH0_S_AXIL_ARPROT;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_ARVALID;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_ARREADY;
wire [M0_AXIL_S_COUNT *32-1:0]  CH0_S_AXIL_RDATA;
wire [M0_AXIL_S_COUNT *2-1:0]   CH0_S_AXIL_RRESP;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_RVALID;
wire [M0_AXIL_S_COUNT-1:0]      CH0_S_AXIL_RREADY;
    assign CH0_M00_AXIL_AWADDR       = CH0_M_AXIL_AWADDR[0*32+:32];
    assign CH0_M00_AXIL_AWPROT       = CH0_M_AXIL_AWPROT[0*3+:3];
    assign CH0_M00_AXIL_AWVALID      = CH0_M_AXIL_AWVALID[0];
    assign CH0_M_AXIL_AWREADY[0]      = CH0_M00_AXIL_AWREADY;
    assign CH0_M00_AXIL_WDATA        = CH0_M_AXIL_WDATA[0*32+:32];
    assign CH0_M00_AXIL_WSTRB        = CH0_M_AXIL_WSTRB[0*4+:4];
    assign CH0_M00_AXIL_WVALID       = CH0_M_AXIL_WVALID[0];
    assign CH0_M_AXIL_WREADY[0]       = CH0_M00_AXIL_WREADY;
    assign CH0_M_AXIL_BRESP[0*2+:2]   = CH0_M00_AXIL_BRESP;
    assign CH0_M_AXIL_BVALID[0]       = CH0_M00_AXIL_BVALID;
    assign CH0_M00_AXIL_BREADY       = CH0_M_AXIL_BREADY[0];
    assign CH0_M00_AXIL_ARADDR       = CH0_M_AXIL_ARADDR[0*32+:32];
    assign CH0_M00_AXIL_ARPROT       = CH0_M_AXIL_ARPROT[0*3+:3];
    assign CH0_M00_AXIL_ARVALID      = CH0_M_AXIL_ARVALID[0];
    assign CH0_M_AXIL_ARREADY[0]      = CH0_M00_AXIL_ARREADY;
    assign CH0_M_AXIL_RDATA[0*32+:32] = CH0_M00_AXIL_RDATA;
    assign CH0_M_AXIL_RRESP[0*2+:2]   = CH0_M00_AXIL_RRESP;
    assign CH0_M_AXIL_RVALID[0]       = CH0_M00_AXIL_RVALID;
    assign CH0_M00_AXIL_RREADY       = CH0_M_AXIL_RREADY[0];
wire [M1_AHB_M_COUNT-1:0]      CH1_M_HSEL;
wire [M1_AHB_M_COUNT *32-1:0]  CH1_M_HADDR;
wire [M1_AHB_M_COUNT *2-1:0]   CH1_M_HTRANS;
wire [M1_AHB_M_COUNT *3-1:0]   CH1_M_HSIZE;
wire [M1_AHB_M_COUNT *3-1:0]   CH1_M_HBURST;
wire [M1_AHB_M_COUNT-1:0]      CH1_M_HMASTLOCK;
wire [M1_AHB_M_COUNT *4-1:0]   CH1_M_HPROT;
wire [M1_AHB_M_COUNT-1:0]      CH1_M_HWRITE;
wire [M1_AHB_M_COUNT *32-1:0]  CH1_M_HWDATA;
wire [M1_AHB_M_COUNT-1:0]      CH1_M_HREADYMUX;
wire [M1_AHB_M_COUNT *32-1:0]  CH1_M_HRDATA;
wire [M1_AHB_M_COUNT-1:0]      CH1_M_HRESP;
wire [M1_AHB_M_COUNT-1:0]      CH1_M_HREADYOUT;
wire [M1_APB_M_COUNT *32-1:0]  CH1_M_PADDR;
wire [M1_APB_M_COUNT *32-1:0]  CH1_M_PWDATA;
wire [M1_APB_M_COUNT-1:0]      CH1_M_PSEL;
wire [M1_APB_M_COUNT-1:0]      CH1_M_PENABLE;
wire [M1_APB_M_COUNT-1:0]      CH1_M_PWRITE;
wire [M1_APB_M_COUNT *4-1:0]   CH1_M_PSTRB;
wire [M1_APB_M_COUNT *3-1:0]   CH1_M_PPROT;
wire [M1_APB_M_COUNT-1:0]      CH1_M_PREADY;
wire [M1_APB_M_COUNT *32-1:0]  CH1_M_PRDATA;
wire [M1_APB_M_COUNT-1:0]      CH1_M_PSLVERR;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_AWID;
wire [M1_AXI_M_COUNT *32-1:0]  CH1_M_AXI_AWADDR;
wire [M1_AXI_M_COUNT *8-1:0]   CH1_M_AXI_AWLEN;
wire [M1_AXI_M_COUNT *3-1:0]   CH1_M_AXI_AWSIZE;
wire [M1_AXI_M_COUNT *2-1:0]   CH1_M_AXI_AWBURST;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_AWLOCK;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_AWCACHE;
wire [M1_AXI_M_COUNT *3-1:0]   CH1_M_AXI_AWPROT;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_AWREGION;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_AWQOS;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_AWVALID;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_AWREADY;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_AWUSER;
wire [M1_AXI_M_COUNT *32-1:0]  CH1_M_AXI_WDATA;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_WSTRB;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_WLAST;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_WUSER;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_WVALID;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_WREADY;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_BID;
wire [M1_AXI_M_COUNT *2-1:0]   CH1_M_AXI_BRESP;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_BVALID;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_BREADY;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_BUSER;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_ARID;
wire [M1_AXI_M_COUNT *32-1:0]  CH1_M_AXI_ARADDR;
wire [M1_AXI_M_COUNT *8-1:0]   CH1_M_AXI_ARLEN;
wire [M1_AXI_M_COUNT *3-1:0]   CH1_M_AXI_ARSIZE;
wire [M1_AXI_M_COUNT *2-1:0]   CH1_M_AXI_ARBURST;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_ARLOCK;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_ARCACHE;
wire [M1_AXI_M_COUNT *3-1:0]   CH1_M_AXI_ARPROT;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_ARREGION;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_ARQOS;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_ARVALID;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_ARREADY;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_ARUSER;
wire [M1_AXI_M_COUNT *4-1:0]   CH1_M_AXI_RID;
wire [M1_AXI_M_COUNT *32-1:0]  CH1_M_AXI_RDATA;
wire [M1_AXI_M_COUNT *2-1:0]   CH1_M_AXI_RRESP;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_RLAST;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_RVALID;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_RREADY;
wire [M1_AXI_M_COUNT-1:0]      CH1_M_AXI_RUSER;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_AWID;
wire [M1_AXI_S_COUNT *32-1:0]   CH1_S_AXI_AWADDR;
wire [M1_AXI_S_COUNT *8-1:0]    CH1_S_AXI_AWLEN;
wire [M1_AXI_S_COUNT *3-1:0]    CH1_S_AXI_AWSIZE;
wire [M1_AXI_S_COUNT *2-1:0]    CH1_S_AXI_AWBURST;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_AWLOCK;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_AWCACHE;
wire [M1_AXI_S_COUNT *3-1:0]    CH1_S_AXI_AWPROT;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_AWQOS;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_AWVALID;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_AWREADY;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_AWUSER;
wire [M1_AXI_S_COUNT *32-1:0]   CH1_S_AXI_WDATA;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_WSTRB;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_WLAST;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_WVALID;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_WREADY;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_WUSER;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_BID;
wire [M1_AXI_S_COUNT *2-1:0]    CH1_S_AXI_BRESP;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_BVALID;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_BREADY;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_BUSER;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_ARID;
wire [M1_AXI_S_COUNT *32-1:0]   CH1_S_AXI_ARADDR;
wire [M1_AXI_S_COUNT *8-1:0]    CH1_S_AXI_ARLEN;
wire [M1_AXI_S_COUNT *3-1:0]    CH1_S_AXI_ARSIZE;
wire [M1_AXI_S_COUNT *2-1:0]    CH1_S_AXI_ARBURST;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_ARLOCK;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_ARCACHE;
wire [M1_AXI_S_COUNT *3-1:0]    CH1_S_AXI_ARPROT;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_ARQOS;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_ARVALID;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_ARREADY;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_ARUSER;
wire [M1_AXI_S_COUNT *4-1:0]    CH1_S_AXI_RID;
wire [M1_AXI_S_COUNT *32-1:0]   CH1_S_AXI_RDATA;
wire [M1_AXI_S_COUNT *2-1:0]    CH1_S_AXI_RRESP;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_RLAST;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_RVALID;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_RREADY;
wire [M1_AXI_S_COUNT-1:0]       CH1_S_AXI_RUSER;
wire [M1_AXIL_M_COUNT *32-1:0]  CH1_M_AXIL_AWADDR;
wire [M1_AXIL_M_COUNT *3-1:0]   CH1_M_AXIL_AWPROT;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_AWVALID;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_AWREADY;
wire [M1_AXIL_M_COUNT *32-1:0]  CH1_M_AXIL_WDATA;
wire [M1_AXIL_M_COUNT *4-1:0]   CH1_M_AXIL_WSTRB;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_WVALID;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_WREADY;
wire [M1_AXIL_M_COUNT *2-1:0]   CH1_M_AXIL_BRESP;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_BVALID;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_BREADY;
wire [M1_AXIL_M_COUNT *32-1:0]  CH1_M_AXIL_ARADDR;
wire [M1_AXIL_M_COUNT *3-1:0]   CH1_M_AXIL_ARPROT;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_ARVALID;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_ARREADY;
wire [M1_AXIL_M_COUNT *32-1:0]  CH1_M_AXIL_RDATA;
wire [M1_AXIL_M_COUNT *2-1:0]   CH1_M_AXIL_RRESP;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_RVALID;
wire [M1_AXIL_M_COUNT-1:0]      CH1_M_AXIL_RREADY;
wire [M1_AXIL_S_COUNT *32-1:0]  CH1_S_AXIL_AWADDR;
wire [M1_AXIL_S_COUNT *3-1:0]   CH1_S_AXIL_AWPROT;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_AWVALID;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_AWREADY;
wire [M1_AXIL_S_COUNT *32-1:0]  CH1_S_AXIL_WDATA;
wire [M1_AXIL_S_COUNT *4-1:0]   CH1_S_AXIL_WSTRB;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_WVALID;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_WREADY;
wire [M1_AXIL_S_COUNT *2-1:0]   CH1_S_AXIL_BRESP;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_BVALID;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_BREADY;
wire [M1_AXIL_S_COUNT *32-1:0]  CH1_S_AXIL_ARADDR;
wire [M1_AXIL_S_COUNT *3-1:0]   CH1_S_AXIL_ARPROT;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_ARVALID;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_ARREADY;
wire [M1_AXIL_S_COUNT *32-1:0]  CH1_S_AXIL_RDATA;
wire [M1_AXIL_S_COUNT *2-1:0]   CH1_S_AXIL_RRESP;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_RVALID;
wire [M1_AXIL_S_COUNT-1:0]      CH1_S_AXIL_RREADY;
    bus_matrix_05172 #  (
    .AHB_M_COUNT        (M0_AHB_M_COUNT),
    .APB_M_COUNT        (M0_APB_M_COUNT),
    .AXI_M_COUNT        (M0_AXI_M_COUNT),
    .AXI_S_COUNT        (M0_AXI_S_COUNT),
    .AXIL_M_COUNT       (M0_AXIL_M_COUNT),
    .AXIL_S_COUNT       (M0_AXIL_S_COUNT),
    .BASE_ADDR          (M0_BASE_ADDR),
    .OFFSET_SIZE_WIDTH  (M0_OFFSET_SIZE_WIDTH)
    )
    bus_matrix_0_inst(
    .CH0_S_HCLK         (CLK_IN), 
    .CH0_S_HSEL         (M0HSEL),         
    .CH0_S_HADDR        (M0HADDR),             
    .CH0_S_HTRANS       (M0HTRANS),            
    .CH0_S_HSIZE        (M0HSIZE),             
    .CH0_S_HBURST       (M0HBURST),            
    .CH0_S_HMASTLOCK    (M0HMASTLOCK),         
    .CH0_S_HPROT        (M0HPROT),             
    .CH0_S_HWRITE       (M0HWRITE),            
    .CH0_S_HWDATA       (M0HWDATA),            
    .CH0_S_HRDATA       (M0HRDATA),            
    .CH0_S_HREADYOUT    (M0HREADYOUT),         
    .CH0_S_HRESP        (M0HRESP),             
    .CH0_S_HREADYMUX    (M0HREADYMUX),         
    .CH0_M_AXIL_AWADDR  (CH0_M_AXIL_AWADDR),   
    .CH0_M_AXIL_AWPROT  (CH0_M_AXIL_AWPROT),   
    .CH0_M_AXIL_AWVALID (CH0_M_AXIL_AWVALID),  
    .CH0_M_AXIL_AWREADY (CH0_M_AXIL_AWREADY),  
    .CH0_M_AXIL_WDATA   (CH0_M_AXIL_WDATA),    
    .CH0_M_AXIL_WSTRB   (CH0_M_AXIL_WSTRB),    
    .CH0_M_AXIL_WVALID  (CH0_M_AXIL_WVALID),   
    .CH0_M_AXIL_WREADY  (CH0_M_AXIL_WREADY),   
    .CH0_M_AXIL_BRESP   (CH0_M_AXIL_BRESP),    
    .CH0_M_AXIL_BVALID  (CH0_M_AXIL_BVALID),   
    .CH0_M_AXIL_BREADY  (CH0_M_AXIL_BREADY),   
    .CH0_M_AXIL_ARADDR  (CH0_M_AXIL_ARADDR),   
    .CH0_M_AXIL_ARPROT  (CH0_M_AXIL_ARPROT),   
    .CH0_M_AXIL_ARVALID (CH0_M_AXIL_ARVALID),  
    .CH0_M_AXIL_ARREADY (CH0_M_AXIL_ARREADY),  
    .CH0_M_AXIL_RDATA   (CH0_M_AXIL_RDATA),    
    .CH0_M_AXIL_RRESP   (CH0_M_AXIL_RRESP),    
    .CH0_M_AXIL_RVALID  (CH0_M_AXIL_RVALID),   
    .CH0_M_AXIL_RREADY  (CH0_M_AXIL_RREADY),   
    .CH0_S_HRESETn      (RST_N)
    );
endmodule
module core2048(
    CLK_IN,       
    SWDIO,         
    SWCLK,         
    GPIO0,          
    GPIO1,          
    UART0_TX,     
    UART0_RX,      
    M0HADDR,   
    M0HBURST,  
    M0HMASTLOCK, 
    M0HPROT,   
    M0HRDATA,  
    M0HRESP,   
    M0HSEL,    
    M0HSIZE,   
    M0HTRANS,  
    M0HWDATA,  
    M0HWRITE,  
    M0HREADYMUX, 
    M0HREADYOUT, 
    RST_N       
);
parameter PCLK_DIV = 0;  
parameter QSPI_ADDRSEL = "FALSE"; 
parameter QSPI_SCKMODE = "FALSE";  
parameter QSPI_XPRALBSIZE = "FALSE"; 
parameter QSPI_XPRDDRMODE = "FALSE"; 
parameter QSPI_XPREN = "FALSE"; 
parameter QSPI_XPRXFERMODE = 2'b00; 
parameter QSPI_XPRALTBYTES = 8'h00; 
parameter QSPI_XPRNUMDC = 5'h00; 
parameter SYSTICK_EN = "TRUE"; 
parameter MPU_NSDISABLE = "FALSE"; 
parameter CFGFMADDR = 12'b0000_0000_0001; 
input wire CLK_IN; 
input wire RST_N; 
    inout wire SWDIO; 
    input wire SWCLK; 
    inout wire GPIO0; 
    inout wire GPIO1; 
    output wire UART0_TX; 
    input wire UART0_RX; 
    output wire [31:0] M0HADDR;      
    output wire [2:0] M0HBURST;      
    output wire M0HMASTLOCK;         
    output wire [3:0] M0HPROT;       
    input wire [31:0] M0HRDATA;    
    input wire M0HRESP;            
    output wire M0HSEL;              
    output wire [2:0] M0HSIZE;       
    output wire [1:0] M0HTRANS;      
    output wire [31:0] M0HWDATA;     
    output wire M0HWRITE;            
    output wire M0HREADYMUX;        
    input wire M0HREADYOUT;        
reg rst_n_int; 
always @(posedge CLK_IN or negedge RST_N) 
begin
    if (!RST_N) 
    rst_n_int <= 1'b0; 
    else 
    rst_n_int <= 1'b1; 
end
wire tclk;      
wire nsrst;     
wire ntrst;     
wire tdi;       
wire tdo;       
wire swdi_tms;  
wire swdo;      
wire swdo_en;   
    assign tclk = SWCLK;            
    assign nsrst = 1'b1;            
    assign ntrst = 1'b1;            
    assign tdi = 1'b0;             
    xsIOBB xsDebug(.I(swdo), .T(swdo_en), .O(swdi_tms), .B(SWDIO)); 
    wire [31:0] GPIO_IN;        
    wire [31:0] GPIO_OUT;       
    wire [31:0] GPIO_OUT_EN;    
    xsIOBB xsGpio0(.I(GPIO_OUT[0]), .T(~GPIO_OUT_EN[0]), .O(GPIO_IN[0]), .B(GPIO0));
    xsIOBB xsGpio1(.I(GPIO_OUT[1]), .T(~GPIO_OUT_EN[1]), .O(GPIO_IN[1]), .B(GPIO1));
    assign GPIO_IN[4] = 1'b0; 
    assign GPIO_IN[5] = 1'b0; 
    assign GPIO_IN[6] = 1'b0; 
    assign GPIO_IN[7] = 1'b0; 
    assign GPIO_IN[8] = 1'b0; 
    assign GPIO_IN[9] = 1'b0; 
    assign GPIO_IN[10] = 1'b0; 
    assign GPIO_IN[11] = 1'b0; 
    assign GPIO_IN[12] = 1'b0; 
    assign GPIO_IN[13] = 1'b0; 
    assign GPIO_IN[14] = 1'b0; 
    assign GPIO_IN[15] = 1'b0; 
    assign GPIO_IN[16] = 1'b0; 
    assign GPIO_IN[17] = 1'b0; 
    assign GPIO_IN[18] = 1'b0; 
    assign GPIO_IN[19] = 1'b0; 
    assign GPIO_IN[20] = 1'b0; 
    assign GPIO_IN[21] = 1'b0; 
    assign GPIO_IN[22] = 1'b0; 
    assign GPIO_IN[23] = 1'b0; 
    assign GPIO_IN[24] = 1'b0; 
    assign GPIO_IN[25] = 1'b0; 
    assign GPIO_IN[26] = 1'b0; 
    assign GPIO_IN[27] = 1'b0; 
    assign GPIO_IN[28] = 1'b0; 
    assign GPIO_IN[29] = 1'b0; 
    assign GPIO_IN[30] = 1'b0; 
    assign GPIO_IN[31] = 1'b0; 
    assign GPIO_IN[2] = UART0_RX;                                           
    xsIOBT xsUart0(.I(GPIO_OUT[3]), .T(~GPIO_OUT_EN[3]), .O(UART0_TX));  
    wire [15:0] EXTINT; 
    assign EXTINT[0] = 1'b0; 
    assign EXTINT[1] = 1'b0; 
    assign EXTINT[2] = 1'b0; 
    assign EXTINT[3] = 1'b0; 
    assign EXTINT[4] = 1'b0; 
    assign EXTINT[5] = 1'b0; 
    assign EXTINT[6] = 1'b0; 
    assign EXTINT[7] = 1'b0; 
    assign EXTINT[8] = 1'b0; 
    assign EXTINT[9] = 1'b0; 
    assign EXTINT[10] = 1'b0; 
    assign EXTINT[11] = 1'b0; 
    assign EXTINT[12] = 1'b0; 
    assign EXTINT[13] = 1'b0; 
    assign EXTINT[14] = 1'b0; 
    assign EXTINT[15] = 1'b0; 
wire [2:0] remap; 
    xsCM3 inst (
    .CIBCLK            (CLK_IN),
    .TREECLK           (1'b0),
    .CPURSTN           (rst_n_int),
    .MTXRSTN           (rst_n_int),
    .TDO_ENABLE        (),
    .TDO_TMS           (tdo),
    .CS_TDI            (tdi),
    .CS_TCK            (tclk),
    .DBG_SWDI_TMS      (swdi_tms),
    .NSRST             (nsrst),
    .NTRST             (ntrst),
    .DBG_SWDO          (swdo),
    .DBG_SWDO_EN       (swdo_en),
    .DMACBREQ          (),
    .DMACLBREQ         (),
    .DMACSREQ          (),
    .DMACLSREQ         (),
    .DMACCLR           (),
    .DMACTC            (),
    .GPIOI             (GPIO_IN),
    .GPIOO             (GPIO_OUT),
    .GPIOOEN           (GPIO_OUT_EN),
    .EXTINT            (EXTINT),
    .INITEXP0HADDR     (),
    .INITEXP0HBURST    (),
    .INITEXP0HMASTLOCK (),
    .INITEXP0HPROT     (),
    .INITEXP0HRDATA    (),
    .INITEXP0HREADY    (),
    .INITEXP0HRESP     (),
    .INITEXP0HSEL      (),
    .INITEXP0HSIZE     (),
    .INITEXP0HTRANS    (),
    .INITEXP0HWDATA    (),
    .INITEXP0HWRITE    (),
    .INITEXP1HADDR     (),
    .INITEXP1HBURST    (),
    .INITEXP1HMASTLOCK (),
    .INITEXP1HPROT     (),
    .INITEXP1HRDATA    (),
    .INITEXP1HREADY    (),
    .INITEXP1HRESP     (),
    .INITEXP1HSEL      (),
    .INITEXP1HSIZE     (),
    .INITEXP1HTRANS    (),
    .INITEXP1HWDATA    (),
    .INITEXP1HWRITE    (),
    .TARGEXP0HADDR     (M0HADDR),
    .TARGEXP0HBURST    (M0HBURST),
    .TARGEXP0HMASTLOCK (M0HMASTLOCK),
    .TARGEXP0HPROT     (M0HPROT),
    .TARGEXP0HRDATA    (M0HRDATA),
    .TARGEXP0HREADYMUX (M0HREADYMUX),
    .TARGEXP0HREADYOUT (M0HREADYOUT),
    .TARGEXP0HRESP     (M0HRESP),
    .TARGEXP0HSEL      (M0HSEL),
    .TARGEXP0HSIZE     (M0HSIZE),
    .TARGEXP0HTRANS    (M0HTRANS),
    .TARGEXP0HWDATA    (M0HWDATA),
    .TARGEXP0HWRITE    (M0HWRITE),
    .TARGEXP1HADDR     (),
    .TARGEXP1HBURST    (),
    .TARGEXP1HMASTLOCK (),
    .TARGEXP1HPROT     (),
    .TARGEXP1HRDATA    (),
    .TARGEXP1HREADYMUX (),
    .TARGEXP1HREADYOUT (),
    .TARGEXP1HRESP     (),
    .TARGEXP1HSEL      (),
    .TARGEXP1HSIZE     (),
    .TARGEXP1HTRANS    (),
    .TARGEXP1HWDATA    (),
    .TARGEXP1HWRITE    ()
    );
    defparam inst.CORE_SET = "TRUE";    
    defparam inst.CORECLK = "CIB_CLK";  
    defparam inst.CORECLK_EN ="TRUE"; 
    defparam inst.MTXCLK = "CORECLK";   
    defparam inst.PCLK_DIV = PCLK_DIV; 
    defparam inst.RSTN_ENABLE = "TRUE"; 
endmodule
module bus_matrix_05172(
    CH0_S_HCLK,     
    CH0_S_HSEL,                
    CH0_S_HADDR,              
    CH0_S_HTRANS,             
    CH0_S_HSIZE,              
    CH0_S_HBURST,             
    CH0_S_HMASTLOCK,         
    CH0_S_HPROT,              
    CH0_S_HWRITE,             
    CH0_S_HWDATA,             
    CH0_S_HRDATA,             
    CH0_S_HREADYOUT,          
    CH0_S_HRESP,              
    CH0_S_HREADYMUX,          
    CH0_M_AXIL_AWADDR,   
    CH0_M_AXIL_AWPROT,   
    CH0_M_AXIL_AWVALID,  
    CH0_M_AXIL_AWREADY,  
    CH0_M_AXIL_WDATA,    
    CH0_M_AXIL_WSTRB,    
    CH0_M_AXIL_WVALID,   
    CH0_M_AXIL_WREADY,   
    CH0_M_AXIL_BRESP,    
    CH0_M_AXIL_BVALID,   
    CH0_M_AXIL_BREADY,   
    CH0_M_AXIL_ARADDR,   
    CH0_M_AXIL_ARPROT,   
    CH0_M_AXIL_ARVALID,  
    CH0_M_AXIL_ARREADY,  
    CH0_M_AXIL_RDATA,    
    CH0_M_AXIL_RRESP,    
    CH0_M_AXIL_RVALID,   
    CH0_M_AXIL_RREADY,   
    CH0_S_HRESETn            
);
parameter  AXI_S_COUNT = 4; 
parameter  AXI_M_COUNT = 4; 
parameter  AXIL_S_COUNT = 4; 
parameter  AXIL_M_COUNT = 4; 
parameter  AHB_M_COUNT = 4; 
parameter  APB_M_COUNT = 4; 
parameter  BASE_ADDR = 32'h60000000; 
parameter  OFFSET_SIZE_WIDTH = 27;    
    input wire          CH0_S_HCLK;                  
    input wire          CH0_S_HRESETn;               
    input wire          CH0_S_HSEL;                  
    input wire [31:0]   CH0_S_HADDR;                 
    input wire [1:0]    CH0_S_HTRANS;                
    input wire [2:0]    CH0_S_HSIZE;                 
    input wire [2:0]    CH0_S_HBURST;                
    input wire          CH0_S_HMASTLOCK;             
    input wire [3:0]    CH0_S_HPROT;                 
    input wire          CH0_S_HWRITE;                
    input wire [31:0]   CH0_S_HWDATA;                
    output wire [31:0]  CH0_S_HRDATA;                
    output wire         CH0_S_HREADYOUT;             
    output wire         CH0_S_HRESP;                 
    input wire          CH0_S_HREADYMUX;             
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_AWID;    
    wire [32*AXI_S_COUNT-1:0]  CH0_S_AXI_AWADDR;  
    wire [8*AXI_S_COUNT-1:0]   CH0_S_AXI_AWLEN;   
    wire [3*AXI_S_COUNT-1:0]   CH0_S_AXI_AWSIZE;  
    wire [2*AXI_S_COUNT-1:0]   CH0_S_AXI_AWBURST; 
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_AWLOCK;  
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_AWCACHE; 
    wire [3*AXI_S_COUNT-1:0]   CH0_S_AXI_AWPROT;  
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_AWQOS;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_AWUSER;  
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_AWVALID; 
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_AWREADY; 
    wire [32*AXI_S_COUNT-1:0]  CH0_S_AXI_WDATA;   
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_WSTRB;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_WLAST;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_WUSER;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_WVALID;  
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_WREADY;  
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_BID;     
    wire [2*AXI_S_COUNT-1:0]   CH0_S_AXI_BRESP;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_BUSER;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_BVALID;  
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_BREADY;  
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_ARID;    
    wire [32*AXI_S_COUNT-1:0]  CH0_S_AXI_ARADDR;  
    wire [8*AXI_S_COUNT-1:0]   CH0_S_AXI_ARLEN;   
    wire [3*AXI_S_COUNT-1:0]   CH0_S_AXI_ARSIZE;  
    wire [2*AXI_S_COUNT-1:0]   CH0_S_AXI_ARBURST; 
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_ARLOCK;  
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_ARCACHE; 
    wire [3*AXI_S_COUNT-1:0]   CH0_S_AXI_ARPROT;  
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_ARQOS;   
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_ARUSER;  
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_ARVALID; 
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_ARREADY; 
    wire [4*AXI_S_COUNT-1:0]   CH0_S_AXI_RID;     
    wire [32*AXI_S_COUNT-1:0]  CH0_S_AXI_RDATA;   
    wire [2*AXI_S_COUNT-1:0]   CH0_S_AXI_RRESP;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_RLAST;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_RUSER;   
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_RVALID;  
    wire [AXI_S_COUNT-1:0]     CH0_S_AXI_RREADY;  
    output wire [32*AXIL_M_COUNT-1:0]  CH0_M_AXIL_AWADDR;   
    output wire [3*AXIL_M_COUNT-1:0]   CH0_M_AXIL_AWPROT;   
    output wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_AWVALID;  
    input  wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_AWREADY;  
    output wire [32*AXIL_M_COUNT-1:0]  CH0_M_AXIL_WDATA;    
    output wire [4*AXIL_M_COUNT-1:0]   CH0_M_AXIL_WSTRB;    
    output wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_WVALID;   
    input  wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_WREADY;   
    input  wire [2*AXIL_M_COUNT-1:0]   CH0_M_AXIL_BRESP;    
    input  wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_BVALID;   
    output wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_BREADY;   
    output wire [32*AXIL_M_COUNT-1:0]  CH0_M_AXIL_ARADDR;   
    output wire [3*AXIL_M_COUNT-1:0]   CH0_M_AXIL_ARPROT;   
    output wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_ARVALID;  
    input  wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_ARREADY;  
    input  wire [32*AXIL_M_COUNT-1:0]  CH0_M_AXIL_RDATA;    
    input  wire [2*AXIL_M_COUNT-1:0]   CH0_M_AXIL_RRESP;    
    input  wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_RVALID;   
    output wire [AXIL_M_COUNT-1:0]     CH0_M_AXIL_RREADY;   
    wire [32*AXIL_S_COUNT-1:0]  CH0_S_AXIL_AWADDR;   
    wire [3*AXIL_S_COUNT-1:0]   CH0_S_AXIL_AWPROT;   
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_AWVALID;  
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_AWREADY;  
    wire [32*AXIL_S_COUNT-1:0]  CH0_S_AXIL_WDATA;    
    wire [4*AXIL_S_COUNT-1:0]   CH0_S_AXIL_WSTRB;    
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_WVALID;   
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_WREADY;   
    wire [2*AXIL_S_COUNT-1:0]   CH0_S_AXIL_BRESP;    
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_BVALID;   
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_BREADY;   
    wire [32*AXIL_S_COUNT-1:0]  CH0_S_AXIL_ARADDR;   
    wire [3*AXIL_S_COUNT-1:0]   CH0_S_AXIL_ARPROT;   
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_ARVALID;  
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_ARREADY;  
    wire [32*AXIL_S_COUNT-1:0]  CH0_S_AXIL_RDATA;    
    wire [2*AXIL_S_COUNT-1:0]   CH0_S_AXIL_RRESP;    
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_RVALID;   
    wire [AXIL_S_COUNT-1:0]     CH0_S_AXIL_RREADY;   
wire   [31:0]  int_axi_awaddr;
wire   [2:0]   int_axi_awprot;
wire   [3:0]   int_axi_awqos = 4'd0;
wire   [3:0]   int_axi_awregion;
wire           int_axi_awvalid;
wire           int_axi_awready;
wire   [31:0]  int_axi_wdata;
wire   [3:0]   int_axi_wstrb;
wire           int_axi_wvalid;
wire           int_axi_wready;
wire   [1:0]   int_axi_bresp;
wire           int_axi_bvalid;
wire           int_axi_bready;
wire   [31:0]  int_axi_araddr;
wire   [2:0]   int_axi_arprot;
wire   [3:0]   int_axi_arqos = 4'd0;
wire   [3:0]   int_axi_arregion;
wire           int_axi_arvalid;
wire           int_axi_arready;
wire   [31:0]  int_axi_rdata;
wire   [1:0]   int_axi_rresp;
wire           int_axi_rvalid;
wire           int_axi_rready;
wire           int_axi_aclk;
wire           int_axi_aresetn;
wire           int_axi_awlock;
wire           int_axi_arlock;
wire   [3:0]   int_axi_awcache;
wire   [3:0]   int_axi_arcache;
wire   [7:0]   int_axi_awlen;
wire   [7:0]   int_axi_arlen;
wire   [2:0]   int_axi_awsize;
wire   [2:0]   int_axi_arsize;
wire   [1:0]   int_axi_awburst;
wire   [1:0]   int_axi_arburst;
wire   [3:0]   int_axi_awid;
wire   [3:0]   int_axi_arid;
wire   [3:0]   int_axi_bid;
wire   [3:0]   int_axi_rid;
wire           int_axi_awuser = 1'b0;
wire           int_axi_wuser = 1'b0;
wire           int_axi_buser;
wire           int_axi_aruser = 1'b0;
wire           int_axi_ruser;
wire           int_axi_rlast;
wire           int_axi_wlast;
wire   [31:0]  int_axil_awaddr;
wire   [2:0]   int_axil_awprot;
wire           int_axil_awvalid;
wire           int_axil_awready;
wire   [31:0]  int_axil_wdata;
wire   [3:0]   int_axil_wstrb;
wire           int_axil_wvalid;
wire           int_axil_wready;
wire   [1:0]   int_axil_bresp;
wire           int_axil_bvalid;
wire           int_axil_bready;
wire   [31:0]  int_axil_araddr;
wire   [2:0]   int_axil_arprot;
wire           int_axil_arvalid;
wire           int_axil_arready;
wire   [31:0]  int_axil_rdata;
wire   [1:0]   int_axil_rresp;
wire           int_axil_rvalid;
wire           int_axil_rready;
wire           int_axil_aclk;
wire           int_axil_aresetn;
wire           int_axil_awlock;
wire           int_axil_arlock;
wire   [3:0]   int_axil_awcache;
wire   [3:0]   int_axil_arcache;
wire   [7:0]   int_axil_arlen;
wire   [3:0]   int_axil_awid;
wire   [3:0]   int_axil_arid;
wire   [3:0]   int_axil_bid = 4'd0;
wire   [3:0]   int_axil_rid  = 4'd0;
wire           int_axil_rlast = 1'b1;
wire           int_axil_wlast;
wire            int_ahb_sel;        
wire    [31:0]  int_ahb_addr;       
wire    [2:0]   int_ahb_burst;      
wire            int_ahb_lock;       
wire            int_ahb_readymux;   
wire    [3:0]   int_ahb_prot;       
wire    [2:0]   int_ahb_size;       
wire    [1:0]   int_ahb_trans;      
wire    [31:0]  int_ahb_wdata;      
wire            int_ahb_write;      
wire    [31:0]  int_ahb_rdata;      
wire            int_ahb_readyout;   
wire            int_ahb_resp;       
wire    [31:0]  int_apb_addr;           
wire            int_apb_enable;         
wire            int_apb_write;          
wire    [31:0]  int_apb_wdata;          
wire    [31:0]  int_apb_rdata;          
wire            int_apb_ready;          
wire            int_apb_slverr;        
wire            int_apb_sel;            
wire    [2:0]   int_apb_prot;           
wire    [3:0]   int_apb_strb;           
wire            int_apb_active;         
    assign  int_ahb_sel         = CH0_S_HSEL;
    assign  int_ahb_addr        = CH0_S_HADDR;
    assign  int_ahb_burst       = CH0_S_HBURST;
    assign  int_ahb_lock        = CH0_S_HMASTLOCK;
    assign  int_ahb_readymux    = CH0_S_HREADYMUX;
    assign  int_ahb_prot        = CH0_S_HPROT;
    assign  int_ahb_size        = CH0_S_HSIZE;
    assign  int_ahb_trans       = CH0_S_HTRANS;
    assign  int_ahb_wdata       = CH0_S_HWDATA;
    assign  int_ahb_write       = CH0_S_HWRITE;
    assign  CH0_S_HREADYOUT     = int_ahb_readyout;
    assign  CH0_S_HRESP         = int_ahb_resp;
    assign  CH0_S_HRDATA        = int_ahb_rdata;
    ahblite_axi_lite_bridge_03513 ahb2axi_lite_inst(
    .s_ahb_hclk         (CH0_S_HCLK      ),
    .s_ahb_hresetn      (CH0_S_HRESETn   ),
    .s_ahb_hready_in    (int_ahb_readymux), 
    .s_ahb_hsel         (int_ahb_sel),         
    .s_ahb_hwrite       (int_ahb_write),
    .s_ahb_haddr        (int_ahb_addr),
    .s_ahb_hburst       (int_ahb_burst),
    .s_ahb_hprot        (int_ahb_prot  ),
    .s_ahb_hsize        (int_ahb_size  ),
    .s_ahb_htrans       (int_ahb_trans),
    .s_ahb_hwdata       (int_ahb_wdata  ),
    .s_ahb_hrdata       (int_ahb_rdata  ),
    .s_ahb_hready_out   (int_ahb_readyout),
    .s_ahb_hresp        (int_ahb_resp),
    .m_axi_aclk         (int_axil_aclk),
    .m_axi_aresetn      (int_axil_aresetn),
    .m_axi_awaddr       (int_axil_awaddr),
    .m_axi_awcache      (int_axil_awcache),
    .m_axi_awid         (int_axil_awid),
    .m_axi_awprot       (int_axil_awprot),
    .m_axi_awready      (int_axil_awready),
    .m_axi_awlock       (int_axil_awlock),
    .m_axi_awvalid      (int_axil_awvalid),
    .m_axi_arlock       (int_axil_arlock),
    .m_axi_arready      (int_axil_arready),
    .m_axi_arvalid      (int_axil_arvalid),
    .m_axi_araddr       (int_axil_araddr),
    .m_axi_arcache      (int_axil_arcache),
    .m_axi_arid         (int_axil_arid),
    .m_axi_arprot       (int_axil_arprot),
    .m_axi_wlast        (int_axil_wlast),
    .m_axi_wvalid       (int_axil_wvalid),
    .m_axi_wdata        (int_axil_wdata),
    .m_axi_wstrb        (int_axil_wstrb),
    .m_axi_wready       (int_axil_wready),
    .m_axi_rdata        (int_axil_rdata),
    .m_axi_rid          (int_axil_rid),
    .m_axi_rresp        (int_axil_rresp),
    .m_axi_rready       (int_axil_rready),
    .m_axi_rlast        (int_axil_rlast),
    .m_axi_rvalid       (int_axil_rvalid),
    .m_axi_bid          (int_axil_bid),
    .m_axi_bresp        (int_axil_bresp),
    .m_axi_bvalid       (int_axil_bvalid),
    .m_axi_bready       (int_axil_bready)
    );
    assign CH0_M_AXIL_AWADDR  = int_axil_awaddr;
    assign CH0_M_AXIL_AWPROT  = int_axil_awprot;
    assign CH0_M_AXIL_AWVALID = int_axil_awvalid;
    assign int_axil_awready   = CH0_M_AXIL_AWREADY;
    assign CH0_M_AXIL_WDATA   = int_axil_wdata;
    assign CH0_M_AXIL_WSTRB   = int_axil_wstrb;
    assign CH0_M_AXIL_WVALID  = int_axil_wvalid;
    assign int_axil_wready    = CH0_M_AXIL_WREADY;
    assign int_axil_bresp     = CH0_M_AXIL_BRESP;
    assign int_axil_bvalid    = CH0_M_AXIL_BVALID;
    assign CH0_M_AXIL_BREADY  = int_axil_bready;
    assign CH0_M_AXIL_ARADDR  = int_axil_araddr;
    assign CH0_M_AXIL_ARPROT  = int_axil_arprot;
    assign CH0_M_AXIL_ARVALID = int_axil_arvalid;
    assign int_axil_arready   = CH0_M_AXIL_ARREADY;
    assign int_axil_rdata     = CH0_M_AXIL_RDATA;
    assign int_axil_rresp     = CH0_M_AXIL_RRESP;
    assign int_axil_rvalid    = CH0_M_AXIL_RVALID;
    assign CH0_M_AXIL_RREADY  = int_axil_rready;
endmodule
/*
Copyright (c) 2018 Alex Forencich
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
`resetall
`timescale 1ns / 1ps
`default_nettype none
/*
 * AXI4 interconnect
 */
module axi_interconnect #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter ID_WIDTH = 8,
    parameter AWUSER_ENABLE = 0,
    parameter AWUSER_WIDTH = 1,
    parameter WUSER_ENABLE = 0,
    parameter WUSER_WIDTH = 1,
    parameter BUSER_ENABLE = 0,
    parameter BUSER_WIDTH = 1,
    parameter ARUSER_ENABLE = 0,
    parameter ARUSER_WIDTH = 1,
    parameter RUSER_ENABLE = 0,
    parameter RUSER_WIDTH = 1,
    parameter FORWARD_ID = 0,
    parameter M_REGIONS = 1,
    parameter M_BASE_ADDR = 0,
    parameter M_ADDR_WIDTH = {M_COUNT{{M_REGIONS{32'd30}}}},         
    parameter M_CONNECT_READ = {M_COUNT{{S_COUNT{1'b1}}}},      
    parameter M_CONNECT_WRITE = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter M_SECURE = {M_COUNT{1'b0}}
)
(
    input  wire                            clk,
    input  wire                            rst,
    /*
    * AXI slave interfaces
    */
    input  wire [S_COUNT*ID_WIDTH-1:0]     s_axi_awid,
    input  wire [S_COUNT*ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [S_COUNT*8-1:0]            s_axi_awlen,
    input  wire [S_COUNT*3-1:0]            s_axi_awsize,
    input  wire [S_COUNT*2-1:0]            s_axi_awburst,
    input  wire [S_COUNT-1:0]              s_axi_awlock,
    input  wire [S_COUNT*4-1:0]            s_axi_awcache,
    input  wire [S_COUNT*3-1:0]            s_axi_awprot,
    input  wire [S_COUNT*4-1:0]            s_axi_awqos,
    input  wire [S_COUNT*AWUSER_WIDTH-1:0] s_axi_awuser,
    input  wire [S_COUNT-1:0]              s_axi_awvalid,
    output wire [S_COUNT-1:0]              s_axi_awready,
    input  wire [S_COUNT*DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [S_COUNT*STRB_WIDTH-1:0]   s_axi_wstrb,
    input  wire [S_COUNT-1:0]              s_axi_wlast,
    input  wire [S_COUNT*WUSER_WIDTH-1:0]  s_axi_wuser,
    input  wire [S_COUNT-1:0]              s_axi_wvalid,
    output wire [S_COUNT-1:0]              s_axi_wready,
    output wire [S_COUNT*ID_WIDTH-1:0]     s_axi_bid,
    output wire [S_COUNT*2-1:0]            s_axi_bresp,
    output wire [S_COUNT*BUSER_WIDTH-1:0]  s_axi_buser,
    output wire [S_COUNT-1:0]              s_axi_bvalid,
    input  wire [S_COUNT-1:0]              s_axi_bready,
    input  wire [S_COUNT*ID_WIDTH-1:0]     s_axi_arid,
    input  wire [S_COUNT*ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [S_COUNT*8-1:0]            s_axi_arlen,
    input  wire [S_COUNT*3-1:0]            s_axi_arsize,
    input  wire [S_COUNT*2-1:0]            s_axi_arburst,
    input  wire [S_COUNT-1:0]              s_axi_arlock,
    input  wire [S_COUNT*4-1:0]            s_axi_arcache,
    input  wire [S_COUNT*3-1:0]            s_axi_arprot,
    input  wire [S_COUNT*4-1:0]            s_axi_arqos,
    input  wire [S_COUNT*ARUSER_WIDTH-1:0] s_axi_aruser,
    input  wire [S_COUNT-1:0]              s_axi_arvalid,
    output wire [S_COUNT-1:0]              s_axi_arready,
    output wire [S_COUNT*ID_WIDTH-1:0]     s_axi_rid,
    output wire [S_COUNT*DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [S_COUNT*2-1:0]            s_axi_rresp,
    output wire [S_COUNT-1:0]              s_axi_rlast,
    output wire [S_COUNT*RUSER_WIDTH-1:0]  s_axi_ruser,
    output wire [S_COUNT-1:0]              s_axi_rvalid,
    input  wire [S_COUNT-1:0]              s_axi_rready,
    /*
    * AXI master interfaces
    */
    output wire [M_COUNT*ID_WIDTH-1:0]     m_axi_awid,
    output wire [M_COUNT*ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire [M_COUNT*8-1:0]            m_axi_awlen,
    output wire [M_COUNT*3-1:0]            m_axi_awsize,
    output wire [M_COUNT*2-1:0]            m_axi_awburst,
    output wire [M_COUNT-1:0]              m_axi_awlock,
    output wire [M_COUNT*4-1:0]            m_axi_awcache,
    output wire [M_COUNT*3-1:0]            m_axi_awprot,
    output wire [M_COUNT*4-1:0]            m_axi_awqos,
    output wire [M_COUNT*4-1:0]            m_axi_awregion,
    output wire [M_COUNT*AWUSER_WIDTH-1:0] m_axi_awuser,
    output wire [M_COUNT-1:0]              m_axi_awvalid,
    input  wire [M_COUNT-1:0]              m_axi_awready,
    output wire [M_COUNT*DATA_WIDTH-1:0]   m_axi_wdata,
    output wire [M_COUNT*STRB_WIDTH-1:0]   m_axi_wstrb,
    output wire [M_COUNT-1:0]              m_axi_wlast,
    output wire [M_COUNT*WUSER_WIDTH-1:0]  m_axi_wuser,
    output wire [M_COUNT-1:0]              m_axi_wvalid,
    input  wire [M_COUNT-1:0]              m_axi_wready,
    input  wire [M_COUNT*ID_WIDTH-1:0]     m_axi_bid,
    input  wire [M_COUNT*2-1:0]            m_axi_bresp,
    input  wire [M_COUNT*BUSER_WIDTH-1:0]  m_axi_buser,
    input  wire [M_COUNT-1:0]              m_axi_bvalid,
    output wire [M_COUNT-1:0]              m_axi_bready,
    output wire [M_COUNT*ID_WIDTH-1:0]     m_axi_arid,
    output wire [M_COUNT*ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire [M_COUNT*8-1:0]            m_axi_arlen,
    output wire [M_COUNT*3-1:0]            m_axi_arsize,
    output wire [M_COUNT*2-1:0]            m_axi_arburst,
    output wire [M_COUNT-1:0]              m_axi_arlock,
    output wire [M_COUNT*4-1:0]            m_axi_arcache,
    output wire [M_COUNT*3-1:0]            m_axi_arprot,
    output wire [M_COUNT*4-1:0]            m_axi_arqos,
    output wire [M_COUNT*4-1:0]            m_axi_arregion,
    output wire [M_COUNT*ARUSER_WIDTH-1:0] m_axi_aruser,
    output wire [M_COUNT-1:0]              m_axi_arvalid,
    input  wire [M_COUNT-1:0]              m_axi_arready,
    input  wire [M_COUNT*ID_WIDTH-1:0]     m_axi_rid,
    input  wire [M_COUNT*DATA_WIDTH-1:0]   m_axi_rdata,
    input  wire [M_COUNT*2-1:0]            m_axi_rresp,
    input  wire [M_COUNT-1:0]              m_axi_rlast,
    input  wire [M_COUNT*RUSER_WIDTH-1:0]  m_axi_ruser,
    input  wire [M_COUNT-1:0]              m_axi_rvalid,
    output wire [M_COUNT-1:0]              m_axi_rready
);
parameter CL_S_COUNT = $clog2(S_COUNT);
parameter CL_M_COUNT = $clog2(M_COUNT);
parameter AUSER_WIDTH = AWUSER_WIDTH > ARUSER_WIDTH ? AWUSER_WIDTH : ARUSER_WIDTH;
function [M_COUNT*M_REGIONS*ADDR_WIDTH-1:0] calcBaseAddrs(input [31:0] dummy);
    integer i;
    reg [ADDR_WIDTH-1:0] base;
    reg [ADDR_WIDTH-1:0] width;
    reg [ADDR_WIDTH-1:0] size;
    reg [ADDR_WIDTH-1:0] mask;
    begin
    calcBaseAddrs = {M_COUNT*M_REGIONS*ADDR_WIDTH{1'b0}};
    base = 0;
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    width = M_ADDR_WIDTH[i*32 +: 32];
    mask = {ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - width);
    size = mask + 1;
    if (width > 0) begin
    if ((base & mask) != 0) begin
    base = base + size - (base & mask); 
    end
    calcBaseAddrs[i * ADDR_WIDTH +: ADDR_WIDTH] = base;
    base = base + size; 
    end
    end
    end
endfunction
parameter M_BASE_ADDR_INT = M_BASE_ADDR ? M_BASE_ADDR : calcBaseAddrs(0);
integer i, j;
initial begin
    if (M_REGIONS < 1 || M_REGIONS > 16) begin
    $error("Error: M_REGIONS must be between 1 and 16 (instance %m)");
    $finish;
    end
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    if (M_ADDR_WIDTH[i*32 +: 32] && (M_ADDR_WIDTH[i*32 +: 32] < 12 || M_ADDR_WIDTH[i*32 +: 32] > ADDR_WIDTH)) begin
    $error("Error: address width out of range (instance %m)");
    $finish;
    end
    end
    $display("Addressing configuration for axi_interconnect instance %m");
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    if (M_ADDR_WIDTH[i*32 +: 32]) begin
    $display("%2d (%2d): %x / %02d -- %x-%x",
    i/M_REGIONS, i%M_REGIONS,
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
    M_ADDR_WIDTH[i*32 +: 32],
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
    );
    end
    end
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    if ((M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & (2**M_ADDR_WIDTH[i*32 +: 32]-1)) != 0) begin
    $display("Region not aligned:");
    $display("%2d (%2d): %x / %2d -- %x-%x",
    i/M_REGIONS, i%M_REGIONS,
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
    M_ADDR_WIDTH[i*32 +: 32],
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
    );
    $error("Error: address range not aligned (instance %m)");
    $finish;
    end
    end
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    for (j = i+1; j < M_COUNT*M_REGIONS; j = j + 1) begin
    if (M_ADDR_WIDTH[i*32 +: 32] && M_ADDR_WIDTH[j*32 +: 32]) begin
    if (((M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32])) <= (M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[j*32 +: 32]))))
    && ((M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[j*32 +: 32])) <= (M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))))) begin
    $display("Overlapping regions:");
    $display("%2d (%2d): %x / %2d -- %x-%x",
    i/M_REGIONS, i%M_REGIONS,
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
    M_ADDR_WIDTH[i*32 +: 32],
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
    );
    $display("%2d (%2d): %x / %2d -- %x-%x",
    j/M_REGIONS, j%M_REGIONS,
    M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH],
    M_ADDR_WIDTH[j*32 +: 32],
    M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[j*32 +: 32]),
    M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[j*32 +: 32]))
    );
    $error("Error: address ranges overlap (instance %m)");
    $finish;
    end
    end
    end
    end
end
localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_DECODE = 3'd1,
    STATE_WRITE = 3'd2,
    STATE_WRITE_RESP = 3'd3,
    STATE_WRITE_DROP = 3'd4,
    STATE_READ = 3'd5,
    STATE_READ_DROP = 3'd6,
    STATE_WAIT_IDLE = 3'd7;
reg [2:0] state_reg = STATE_IDLE, state_next;
reg match;
reg [CL_M_COUNT-1:0] m_select_reg = 2'd0, m_select_next;
reg [ID_WIDTH-1:0] axi_id_reg = {ID_WIDTH{1'b0}}, axi_id_next;
reg [ADDR_WIDTH-1:0] axi_addr_reg = {ADDR_WIDTH{1'b0}}, axi_addr_next;
reg axi_addr_valid_reg = 1'b0, axi_addr_valid_next;
reg [7:0] axi_len_reg = 8'd0, axi_len_next;
reg [2:0] axi_size_reg = 3'd0, axi_size_next;
reg [1:0] axi_burst_reg = 2'd0, axi_burst_next;
reg axi_lock_reg = 1'b0, axi_lock_next;
reg [3:0] axi_cache_reg = 4'd0, axi_cache_next;
reg [2:0] axi_prot_reg = 3'b000, axi_prot_next;
reg [3:0] axi_qos_reg = 4'd0, axi_qos_next;
reg [3:0] axi_region_reg = 4'd0, axi_region_next;
reg [AUSER_WIDTH-1:0] axi_auser_reg = {AUSER_WIDTH{1'b0}}, axi_auser_next;
reg [1:0] axi_bresp_reg = 2'b00, axi_bresp_next;
reg [BUSER_WIDTH-1:0] axi_buser_reg = {BUSER_WIDTH{1'b0}}, axi_buser_next;
reg [S_COUNT-1:0] s_axi_awready_reg = 0, s_axi_awready_next;
reg [S_COUNT-1:0] s_axi_wready_reg = 0, s_axi_wready_next;
reg [S_COUNT-1:0] s_axi_bvalid_reg = 0, s_axi_bvalid_next;
reg [S_COUNT-1:0] s_axi_arready_reg = 0, s_axi_arready_next;
reg [M_COUNT-1:0] m_axi_awvalid_reg = 0, m_axi_awvalid_next;
reg [M_COUNT-1:0] m_axi_bready_reg = 0, m_axi_bready_next;
reg [M_COUNT-1:0] m_axi_arvalid_reg = 0, m_axi_arvalid_next;
reg [M_COUNT-1:0] m_axi_rready_reg = 0, m_axi_rready_next;
reg  [ID_WIDTH-1:0]    s_axi_rid_int;
reg  [DATA_WIDTH-1:0]  s_axi_rdata_int;
reg  [1:0]             s_axi_rresp_int;
reg                    s_axi_rlast_int;
reg  [RUSER_WIDTH-1:0] s_axi_ruser_int;
reg                    s_axi_rvalid_int;
reg                    s_axi_rready_int_reg = 1'b0;
wire                   s_axi_rready_int_early;
reg  [DATA_WIDTH-1:0]  m_axi_wdata_int;
reg  [STRB_WIDTH-1:0]  m_axi_wstrb_int;
reg                    m_axi_wlast_int;
reg  [WUSER_WIDTH-1:0] m_axi_wuser_int;
reg                    m_axi_wvalid_int;
reg                    m_axi_wready_int_reg = 1'b0;
wire                   m_axi_wready_int_early;
assign s_axi_awready = s_axi_awready_reg;
assign s_axi_wready = s_axi_wready_reg;
assign s_axi_bid = {S_COUNT{axi_id_reg}};
assign s_axi_bresp = {S_COUNT{axi_bresp_reg}};
assign s_axi_buser = {S_COUNT{BUSER_ENABLE ? axi_buser_reg : {BUSER_WIDTH{1'b0}}}};
assign s_axi_bvalid = s_axi_bvalid_reg;
assign s_axi_arready = s_axi_arready_reg;
assign m_axi_awid = {M_COUNT{FORWARD_ID ? axi_id_reg : {ID_WIDTH{1'b0}}}};
assign m_axi_awaddr = {M_COUNT{axi_addr_reg}};
assign m_axi_awlen = {M_COUNT{axi_len_reg}};
assign m_axi_awsize = {M_COUNT{axi_size_reg}};
assign m_axi_awburst = {M_COUNT{axi_burst_reg}};
assign m_axi_awlock = {M_COUNT{axi_lock_reg}};
assign m_axi_awcache = {M_COUNT{axi_cache_reg}};
assign m_axi_awprot = {M_COUNT{axi_prot_reg}};
assign m_axi_awqos = {M_COUNT{axi_qos_reg}};
assign m_axi_awregion = {M_COUNT{axi_region_reg}};
assign m_axi_awuser = {M_COUNT{AWUSER_ENABLE ? axi_auser_reg[AWUSER_WIDTH-1:0] : {AWUSER_WIDTH{1'b0}}}};
assign m_axi_awvalid = m_axi_awvalid_reg;
assign m_axi_bready = m_axi_bready_reg;
assign m_axi_arid = {M_COUNT{FORWARD_ID ? axi_id_reg : {ID_WIDTH{1'b0}}}};
assign m_axi_araddr = {M_COUNT{axi_addr_reg}};
assign m_axi_arlen = {M_COUNT{axi_len_reg}};
assign m_axi_arsize = {M_COUNT{axi_size_reg}};
assign m_axi_arburst = {M_COUNT{axi_burst_reg}};
assign m_axi_arlock = {M_COUNT{axi_lock_reg}};
assign m_axi_arcache = {M_COUNT{axi_cache_reg}};
assign m_axi_arprot = {M_COUNT{axi_prot_reg}};
assign m_axi_arqos = {M_COUNT{axi_qos_reg}};
assign m_axi_arregion = {M_COUNT{axi_region_reg}};
assign m_axi_aruser = {M_COUNT{ARUSER_ENABLE ? axi_auser_reg[ARUSER_WIDTH-1:0] : {ARUSER_WIDTH{1'b0}}}};
assign m_axi_arvalid = m_axi_arvalid_reg;
assign m_axi_rready = m_axi_rready_reg;
wire [(CL_S_COUNT > 0 ? CL_S_COUNT-1 : 0):0] s_select;
wire [ID_WIDTH-1:0]     current_s_axi_awid      = s_axi_awid[s_select*ID_WIDTH +: ID_WIDTH];
wire [ADDR_WIDTH-1:0]   current_s_axi_awaddr    = s_axi_awaddr[s_select*ADDR_WIDTH +: ADDR_WIDTH];
wire [7:0]              current_s_axi_awlen     = s_axi_awlen[s_select*8 +: 8];
wire [2:0]              current_s_axi_awsize    = s_axi_awsize[s_select*3 +: 3];
wire [1:0]              current_s_axi_awburst   = s_axi_awburst[s_select*2 +: 2];
wire                    current_s_axi_awlock    = s_axi_awlock[s_select];
wire [3:0]              current_s_axi_awcache   = s_axi_awcache[s_select*4 +: 4];
wire [2:0]              current_s_axi_awprot    = s_axi_awprot[s_select*3 +: 3];
wire [3:0]              current_s_axi_awqos     = s_axi_awqos[s_select*4 +: 4];
wire [AWUSER_WIDTH-1:0] current_s_axi_awuser    = s_axi_awuser[s_select*AWUSER_WIDTH +: AWUSER_WIDTH];
wire                    current_s_axi_awvalid   = s_axi_awvalid[s_select];
wire                    current_s_axi_awready   = s_axi_awready[s_select];
wire [DATA_WIDTH-1:0]   current_s_axi_wdata     = s_axi_wdata[s_select*DATA_WIDTH +: DATA_WIDTH];
wire [STRB_WIDTH-1:0]   current_s_axi_wstrb     = s_axi_wstrb[s_select*STRB_WIDTH +: STRB_WIDTH];
wire                    current_s_axi_wlast     = s_axi_wlast[s_select];
wire [WUSER_WIDTH-1:0]  current_s_axi_wuser     = s_axi_wuser[s_select*WUSER_WIDTH +: WUSER_WIDTH];
wire                    current_s_axi_wvalid    = s_axi_wvalid[s_select];
wire                    current_s_axi_wready    = s_axi_wready[s_select];
wire [ID_WIDTH-1:0]     current_s_axi_bid       = s_axi_bid[s_select*ID_WIDTH +: ID_WIDTH];
wire [1:0]              current_s_axi_bresp     = s_axi_bresp[s_select*2 +: 2];
wire [BUSER_WIDTH-1:0]  current_s_axi_buser     = s_axi_buser[s_select*BUSER_WIDTH +: BUSER_WIDTH];
wire                    current_s_axi_bvalid    = s_axi_bvalid[s_select];
wire                    current_s_axi_bready    = s_axi_bready[s_select];
wire [ID_WIDTH-1:0]     current_s_axi_arid      = s_axi_arid[s_select*ID_WIDTH +: ID_WIDTH];
wire [ADDR_WIDTH-1:0]   current_s_axi_araddr    = s_axi_araddr[s_select*ADDR_WIDTH +: ADDR_WIDTH];
wire [7:0]              current_s_axi_arlen     = s_axi_arlen[s_select*8 +: 8];
wire [2:0]              current_s_axi_arsize    = s_axi_arsize[s_select*3 +: 3];
wire [1:0]              current_s_axi_arburst   = s_axi_arburst[s_select*2 +: 2];
wire                    current_s_axi_arlock    = s_axi_arlock[s_select];
wire [3:0]              current_s_axi_arcache   = s_axi_arcache[s_select*4 +: 4];
wire [2:0]              current_s_axi_arprot    = s_axi_arprot[s_select*3 +: 3];
wire [3:0]              current_s_axi_arqos     = s_axi_arqos[s_select*4 +: 4];
wire [ARUSER_WIDTH-1:0] current_s_axi_aruser    = s_axi_aruser[s_select*ARUSER_WIDTH +: ARUSER_WIDTH];
wire                    current_s_axi_arvalid   = s_axi_arvalid[s_select];
wire                    current_s_axi_arready   = s_axi_arready[s_select];
wire [ID_WIDTH-1:0]     current_s_axi_rid       = s_axi_rid[s_select*ID_WIDTH +: ID_WIDTH];
wire [DATA_WIDTH-1:0]   current_s_axi_rdata     = s_axi_rdata[s_select*DATA_WIDTH +: DATA_WIDTH];
wire [1:0]              current_s_axi_rresp     = s_axi_rresp[s_select*2 +: 2];
wire                    current_s_axi_rlast     = s_axi_rlast[s_select];
wire [RUSER_WIDTH-1:0]  current_s_axi_ruser     = s_axi_ruser[s_select*RUSER_WIDTH +: RUSER_WIDTH];
wire                    current_s_axi_rvalid    = s_axi_rvalid[s_select];
wire                    current_s_axi_rready    = s_axi_rready[s_select];
wire [ID_WIDTH-1:0]     current_m_axi_awid      = m_axi_awid[m_select_reg*ID_WIDTH +: ID_WIDTH];
wire [ADDR_WIDTH-1:0]   current_m_axi_awaddr    = m_axi_awaddr[m_select_reg*ADDR_WIDTH +: ADDR_WIDTH];
wire [7:0]              current_m_axi_awlen     = m_axi_awlen[m_select_reg*8 +: 8];
wire [2:0]              current_m_axi_awsize    = m_axi_awsize[m_select_reg*3 +: 3];
wire [1:0]              current_m_axi_awburst   = m_axi_awburst[m_select_reg*2 +: 2];
wire                    current_m_axi_awlock    = m_axi_awlock[m_select_reg];
wire [3:0]              current_m_axi_awcache   = m_axi_awcache[m_select_reg*4 +: 4];
wire [2:0]              current_m_axi_awprot    = m_axi_awprot[m_select_reg*3 +: 3];
wire [3:0]              current_m_axi_awqos     = m_axi_awqos[m_select_reg*4 +: 4];
wire [3:0]              current_m_axi_awregion  = m_axi_awregion[m_select_reg*4 +: 4];
wire [AWUSER_WIDTH-1:0] current_m_axi_awuser    = m_axi_awuser[m_select_reg*AWUSER_WIDTH +: AWUSER_WIDTH];
wire                    current_m_axi_awvalid   = m_axi_awvalid[m_select_reg];
wire                    current_m_axi_awready   = m_axi_awready[m_select_reg];
wire [DATA_WIDTH-1:0]   current_m_axi_wdata     = m_axi_wdata[m_select_reg*DATA_WIDTH +: DATA_WIDTH];
wire [STRB_WIDTH-1:0]   current_m_axi_wstrb     = m_axi_wstrb[m_select_reg*STRB_WIDTH +: STRB_WIDTH];
wire                    current_m_axi_wlast     = m_axi_wlast[m_select_reg];
wire [WUSER_WIDTH-1:0]  current_m_axi_wuser     = m_axi_wuser[m_select_reg*WUSER_WIDTH +: WUSER_WIDTH];
wire                    current_m_axi_wvalid    = m_axi_wvalid[m_select_reg];
wire                    current_m_axi_wready    = m_axi_wready[m_select_reg];
wire [ID_WIDTH-1:0]     current_m_axi_bid       = m_axi_bid[m_select_reg*ID_WIDTH +: ID_WIDTH];
wire [1:0]              current_m_axi_bresp     = m_axi_bresp[m_select_reg*2 +: 2];
wire [BUSER_WIDTH-1:0]  current_m_axi_buser     = m_axi_buser[m_select_reg*BUSER_WIDTH +: BUSER_WIDTH];
wire                    current_m_axi_bvalid    = m_axi_bvalid[m_select_reg];
wire                    current_m_axi_bready    = m_axi_bready[m_select_reg];
wire [ID_WIDTH-1:0]     current_m_axi_arid      = m_axi_arid[m_select_reg*ID_WIDTH +: ID_WIDTH];
wire [ADDR_WIDTH-1:0]   current_m_axi_araddr    = m_axi_araddr[m_select_reg*ADDR_WIDTH +: ADDR_WIDTH];
wire [7:0]              current_m_axi_arlen     = m_axi_arlen[m_select_reg*8 +: 8];
wire [2:0]              current_m_axi_arsize    = m_axi_arsize[m_select_reg*3 +: 3];
wire [1:0]              current_m_axi_arburst   = m_axi_arburst[m_select_reg*2 +: 2];
wire                    current_m_axi_arlock    = m_axi_arlock[m_select_reg];
wire [3:0]              current_m_axi_arcache   = m_axi_arcache[m_select_reg*4 +: 4];
wire [2:0]              current_m_axi_arprot    = m_axi_arprot[m_select_reg*3 +: 3];
wire [3:0]              current_m_axi_arqos     = m_axi_arqos[m_select_reg*4 +: 4];
wire [3:0]              current_m_axi_arregion  = m_axi_arregion[m_select_reg*4 +: 4];
wire [ARUSER_WIDTH-1:0] current_m_axi_aruser    = m_axi_aruser[m_select_reg*ARUSER_WIDTH +: ARUSER_WIDTH];
wire                    current_m_axi_arvalid   = m_axi_arvalid[m_select_reg];
wire                    current_m_axi_arready   = m_axi_arready[m_select_reg];
wire [ID_WIDTH-1:0]     current_m_axi_rid       = m_axi_rid[m_select_reg*ID_WIDTH +: ID_WIDTH];
wire [DATA_WIDTH-1:0]   current_m_axi_rdata     = m_axi_rdata[m_select_reg*DATA_WIDTH +: DATA_WIDTH];
wire [1:0]              current_m_axi_rresp     = m_axi_rresp[m_select_reg*2 +: 2];
wire                    current_m_axi_rlast     = m_axi_rlast[m_select_reg];
wire [RUSER_WIDTH-1:0]  current_m_axi_ruser     = m_axi_ruser[m_select_reg*RUSER_WIDTH +: RUSER_WIDTH];
wire                    current_m_axi_rvalid    = m_axi_rvalid[m_select_reg];
wire                    current_m_axi_rready    = m_axi_rready[m_select_reg];
wire [S_COUNT*2-1:0] request;
wire [S_COUNT*2-1:0] acknowledge;
wire [S_COUNT*2-1:0] grant;
wire grant_valid;
wire [CL_S_COUNT:0] grant_encoded;
wire read = grant_encoded[0];
assign s_select = grant_encoded >> 1;
arbiter #(
    .PORTS(S_COUNT*2),
    .ARB_TYPE_ROUND_ROBIN(1),
    .ARB_BLOCK(1),
    .ARB_BLOCK_ACK(1),
    .ARB_LSB_HIGH_PRIORITY(1)
)
arb_inst (
    .clk(clk),
    .rst(rst),
    .request(request),
    .acknowledge(acknowledge),
    .grant(grant),
    .grant_valid(grant_valid),
    .grant_encoded(grant_encoded)
);
genvar n;
generate
for (n = 0; n < S_COUNT; n = n + 1) begin
    assign request[2*n]   = s_axi_awvalid[n];
    assign request[2*n+1] = s_axi_arvalid[n];
end
endgenerate
generate
for (n = 0; n < S_COUNT; n = n + 1) begin
    assign acknowledge[2*n]   = grant[2*n]   && s_axi_bvalid[n] && s_axi_bready[n];
    assign acknowledge[2*n+1] = grant[2*n+1] && s_axi_rvalid[n] && s_axi_rready[n] && s_axi_rlast[n];
end
endgenerate
always @* begin
    state_next = STATE_IDLE;
    match = 1'b0;
    m_select_next = m_select_reg;
    axi_id_next = axi_id_reg;
    axi_addr_next = axi_addr_reg;
    axi_addr_valid_next = axi_addr_valid_reg;
    axi_len_next = axi_len_reg;
    axi_size_next = axi_size_reg;
    axi_burst_next = axi_burst_reg;
    axi_lock_next = axi_lock_reg;
    axi_cache_next = axi_cache_reg;
    axi_prot_next = axi_prot_reg;
    axi_qos_next = axi_qos_reg;
    axi_region_next = axi_region_reg;
    axi_auser_next = axi_auser_reg;
    axi_bresp_next = axi_bresp_reg;
    axi_buser_next = axi_buser_reg;
    s_axi_awready_next = 0;
    s_axi_wready_next = 0;
    s_axi_bvalid_next = s_axi_bvalid_reg & ~s_axi_bready;
    s_axi_arready_next = 0;
    m_axi_awvalid_next = m_axi_awvalid_reg & ~m_axi_awready;
    m_axi_bready_next = 0;
    m_axi_arvalid_next = m_axi_arvalid_reg & ~m_axi_arready;
    m_axi_rready_next = 0;
    s_axi_rid_int = axi_id_reg;
    s_axi_rdata_int = current_m_axi_rdata;
    s_axi_rresp_int = current_m_axi_rresp;
    s_axi_rlast_int = current_m_axi_rlast;
    s_axi_ruser_int = current_m_axi_ruser;
    s_axi_rvalid_int = 1'b0;
    m_axi_wdata_int = current_s_axi_wdata;
    m_axi_wstrb_int = current_s_axi_wstrb;
    m_axi_wlast_int = current_s_axi_wlast;
    m_axi_wuser_int = current_s_axi_wuser;
    m_axi_wvalid_int = 1'b0;
    case (state_reg)
    STATE_IDLE: begin
    if (grant_valid) begin
    axi_addr_valid_next = 1'b1;
    if (read) begin
    axi_addr_next = current_s_axi_araddr;
    axi_prot_next = current_s_axi_arprot;
    axi_id_next = current_s_axi_arid;
    axi_addr_next = current_s_axi_araddr;
    axi_len_next = current_s_axi_arlen;
    axi_size_next = current_s_axi_arsize;
    axi_burst_next = current_s_axi_arburst;
    axi_lock_next = current_s_axi_arlock;
    axi_cache_next = current_s_axi_arcache;
    axi_prot_next = current_s_axi_arprot;
    axi_qos_next = current_s_axi_arqos;
    axi_auser_next = current_s_axi_aruser;
    s_axi_arready_next[s_select] = 1'b1;
    end else  begin
    axi_addr_next = current_s_axi_awaddr;
    axi_prot_next = current_s_axi_awprot;
    axi_id_next = current_s_axi_awid;
    axi_addr_next = current_s_axi_awaddr;
    axi_len_next = current_s_axi_awlen;
    axi_size_next = current_s_axi_awsize;
    axi_burst_next = current_s_axi_awburst;
    axi_lock_next = current_s_axi_awlock;
    axi_cache_next = current_s_axi_awcache;
    axi_prot_next = current_s_axi_awprot;
    axi_qos_next = current_s_axi_awqos;
    axi_auser_next = current_s_axi_awuser;
    s_axi_awready_next[s_select] = 1'b1;
    end
    state_next = STATE_DECODE;
    end else begin
    state_next = STATE_IDLE;
    end
    end
    STATE_DECODE: begin
    match = 1'b0;
    for (i = 0; i < M_COUNT; i = i + 1) begin
    for (j = 0; j < M_REGIONS; j = j + 1) begin
    if (M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32] && (!M_SECURE[i] || !axi_prot_reg[1]) && ((read ? M_CONNECT_READ : M_CONNECT_WRITE) & (1 << (s_select+i*S_COUNT))) && (axi_addr_reg >> M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32]) == (M_BASE_ADDR_INT[(i*M_REGIONS+j)*ADDR_WIDTH +: ADDR_WIDTH] >> M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32])) begin
    m_select_next = i;
    axi_region_next = j;
    match = 1'b1;
    end
    end
    end
    if (match) begin
    if (read) begin
    m_axi_rready_next[m_select_reg] = s_axi_rready_int_early;
    state_next = STATE_READ;
    end else begin
    s_axi_wready_next[s_select] = m_axi_wready_int_early;
    state_next = STATE_WRITE;
    end
    end else begin
    if (read) begin
    state_next = STATE_READ_DROP;
    end else begin
    axi_bresp_next = 2'b11;
    s_axi_wready_next[s_select] = 1'b1;
    state_next = STATE_WRITE_DROP;
    end
    end
    end
    STATE_WRITE: begin
    s_axi_wready_next[s_select] = m_axi_wready_int_early;
    if (axi_addr_valid_reg) begin
    m_axi_awvalid_next[m_select_reg] = 1'b1;
    end
    axi_addr_valid_next = 1'b0;
    if (current_s_axi_wready && current_s_axi_wvalid) begin
    m_axi_wdata_int = current_s_axi_wdata;
    m_axi_wstrb_int = current_s_axi_wstrb;
    m_axi_wlast_int = current_s_axi_wlast;
    m_axi_wuser_int = current_s_axi_wuser;
    m_axi_wvalid_int = 1'b1;
    if (current_s_axi_wlast) begin
    s_axi_wready_next[s_select] = 1'b0;
    m_axi_bready_next[m_select_reg] = 1'b1;
    state_next = STATE_WRITE_RESP;
    end else begin
    state_next = STATE_WRITE;
    end
    end else begin
    state_next = STATE_WRITE;
    end
    end
    STATE_WRITE_RESP: begin
    m_axi_bready_next[m_select_reg] = 1'b1;
    if (current_m_axi_bready && current_m_axi_bvalid) begin
    m_axi_bready_next[m_select_reg] = 1'b0;
    axi_bresp_next = current_m_axi_bresp;
    s_axi_bvalid_next[s_select] = 1'b1;
    state_next = STATE_WAIT_IDLE;
    end else begin
    state_next = STATE_WRITE_RESP;
    end
    end
    STATE_WRITE_DROP: begin
    s_axi_wready_next[s_select] = 1'b1;
    axi_addr_valid_next = 1'b0;
    if (current_s_axi_wready && current_s_axi_wvalid && current_s_axi_wlast) begin
    s_axi_wready_next[s_select] = 1'b0;
    s_axi_bvalid_next[s_select] = 1'b1;
    state_next = STATE_WAIT_IDLE;
    end else begin
    state_next = STATE_WRITE_DROP;
    end
    end
    STATE_READ: begin
    m_axi_rready_next[m_select_reg] = s_axi_rready_int_early;
    if (axi_addr_valid_reg) begin
    m_axi_arvalid_next[m_select_reg] = 1'b1;
    end
    axi_addr_valid_next = 1'b0;
    if (current_m_axi_rready && current_m_axi_rvalid) begin
    s_axi_rid_int = axi_id_reg;
    s_axi_rdata_int = current_m_axi_rdata;
    s_axi_rresp_int = current_m_axi_rresp;
    s_axi_rlast_int = current_m_axi_rlast;
    s_axi_ruser_int = current_m_axi_ruser;
    s_axi_rvalid_int = 1'b1;
    if (current_m_axi_rlast) begin
    m_axi_rready_next[m_select_reg] = 1'b0;
    state_next = STATE_WAIT_IDLE;
    end else begin
    state_next = STATE_READ;
    end
    end else begin
    state_next = STATE_READ;
    end
    end
    STATE_READ_DROP: begin
    s_axi_rid_int = axi_id_reg;
    s_axi_rdata_int = {DATA_WIDTH{1'b0}};
    s_axi_rresp_int = 2'b11;
    s_axi_rlast_int = axi_len_reg == 0;
    s_axi_ruser_int = {RUSER_WIDTH{1'b0}};
    s_axi_rvalid_int = 1'b1;
    if (s_axi_rready_int_reg) begin
    axi_len_next = axi_len_reg - 1;
    if (axi_len_reg == 0) begin
    state_next = STATE_WAIT_IDLE;
    end else begin
    state_next = STATE_READ_DROP;
    end
    end else begin
    state_next = STATE_READ_DROP;
    end
    end
    STATE_WAIT_IDLE: begin
    if (!grant_valid || acknowledge) begin
    state_next = STATE_IDLE;
    end else begin
    state_next = STATE_WAIT_IDLE;
    end
    end
    endcase
end
always @(posedge clk) begin
    if (rst) begin
    state_reg <= STATE_IDLE;
    s_axi_awready_reg <= 0;
    s_axi_wready_reg <= 0;
    s_axi_bvalid_reg <= 0;
    s_axi_arready_reg <= 0;
    m_axi_awvalid_reg <= 0;
    m_axi_bready_reg <= 0;
    m_axi_arvalid_reg <= 0;
    m_axi_rready_reg <= 0;
    end else begin
    state_reg <= state_next;
    s_axi_awready_reg <= s_axi_awready_next;
    s_axi_wready_reg <= s_axi_wready_next;
    s_axi_bvalid_reg <= s_axi_bvalid_next;
    s_axi_arready_reg <= s_axi_arready_next;
    m_axi_awvalid_reg <= m_axi_awvalid_next;
    m_axi_bready_reg <= m_axi_bready_next;
    m_axi_arvalid_reg <= m_axi_arvalid_next;
    m_axi_rready_reg <= m_axi_rready_next;
    end
    m_select_reg <= m_select_next;
    axi_id_reg <= axi_id_next;
    axi_addr_reg <= axi_addr_next;
    axi_addr_valid_reg <= axi_addr_valid_next;
    axi_len_reg <= axi_len_next;
    axi_size_reg <= axi_size_next;
    axi_burst_reg <= axi_burst_next;
    axi_lock_reg <= axi_lock_next;
    axi_cache_reg <= axi_cache_next;
    axi_prot_reg <= axi_prot_next;
    axi_qos_reg <= axi_qos_next;
    axi_region_reg <= axi_region_next;
    axi_auser_reg <= axi_auser_next;
    axi_bresp_reg <= axi_bresp_next;
    axi_buser_reg <= axi_buser_next;
end
reg [ID_WIDTH-1:0]    s_axi_rid_reg    = {ID_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0]  s_axi_rdata_reg  = {DATA_WIDTH{1'b0}};
reg [1:0]             s_axi_rresp_reg  = 2'd0;
reg                   s_axi_rlast_reg  = 1'b0;
reg [RUSER_WIDTH-1:0] s_axi_ruser_reg  = 1'b0;
reg [S_COUNT-1:0]     s_axi_rvalid_reg = 1'b0, s_axi_rvalid_next;
reg [ID_WIDTH-1:0]    temp_s_axi_rid_reg    = {ID_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0]  temp_s_axi_rdata_reg  = {DATA_WIDTH{1'b0}};
reg [1:0]             temp_s_axi_rresp_reg  = 2'd0;
reg                   temp_s_axi_rlast_reg  = 1'b0;
reg [RUSER_WIDTH-1:0] temp_s_axi_ruser_reg  = 1'b0;
reg                   temp_s_axi_rvalid_reg = 1'b0, temp_s_axi_rvalid_next;
reg store_axi_r_int_to_output;
reg store_axi_r_int_to_temp;
reg store_axi_r_temp_to_output;
assign s_axi_rid = {S_COUNT{s_axi_rid_reg}};
assign s_axi_rdata = {S_COUNT{s_axi_rdata_reg}};
assign s_axi_rresp = {S_COUNT{s_axi_rresp_reg}};
assign s_axi_rlast = {S_COUNT{s_axi_rlast_reg}};
assign s_axi_ruser = {S_COUNT{RUSER_ENABLE ? s_axi_ruser_reg : {RUSER_WIDTH{1'b0}}}};
assign s_axi_rvalid = s_axi_rvalid_reg;
assign s_axi_rready_int_early = current_s_axi_rready | (~temp_s_axi_rvalid_reg & (~current_s_axi_rvalid | ~s_axi_rvalid_int));
always @* begin
    s_axi_rvalid_next = s_axi_rvalid_reg;
    temp_s_axi_rvalid_next = temp_s_axi_rvalid_reg;
    store_axi_r_int_to_output = 1'b0;
    store_axi_r_int_to_temp = 1'b0;
    store_axi_r_temp_to_output = 1'b0;
    if (s_axi_rready_int_reg) begin
    if (current_s_axi_rready | ~current_s_axi_rvalid) begin
    s_axi_rvalid_next[s_select] = s_axi_rvalid_int;
    store_axi_r_int_to_output = 1'b1;
    end else begin
    temp_s_axi_rvalid_next = s_axi_rvalid_int;
    store_axi_r_int_to_temp = 1'b1;
    end
    end else if (current_s_axi_rready) begin
    s_axi_rvalid_next[s_select] = temp_s_axi_rvalid_reg;
    temp_s_axi_rvalid_next = 1'b0;
    store_axi_r_temp_to_output = 1'b1;
    end
end
always @(posedge clk) begin
    if (rst) begin
    s_axi_rvalid_reg <= 1'b0;
    s_axi_rready_int_reg <= 1'b0;
    temp_s_axi_rvalid_reg <= 1'b0;
    end else begin
    s_axi_rvalid_reg <= s_axi_rvalid_next;
    s_axi_rready_int_reg <= s_axi_rready_int_early;
    temp_s_axi_rvalid_reg <= temp_s_axi_rvalid_next;
    end
    if (store_axi_r_int_to_output) begin
    s_axi_rid_reg <= s_axi_rid_int;
    s_axi_rdata_reg <= s_axi_rdata_int;
    s_axi_rresp_reg <= s_axi_rresp_int;
    s_axi_rlast_reg <= s_axi_rlast_int;
    s_axi_ruser_reg <= s_axi_ruser_int;
    end else if (store_axi_r_temp_to_output) begin
    s_axi_rid_reg <= temp_s_axi_rid_reg;
    s_axi_rdata_reg <= temp_s_axi_rdata_reg;
    s_axi_rresp_reg <= temp_s_axi_rresp_reg;
    s_axi_rlast_reg <= temp_s_axi_rlast_reg;
    s_axi_ruser_reg <= temp_s_axi_ruser_reg;
    end
    if (store_axi_r_int_to_temp) begin
    temp_s_axi_rid_reg <= s_axi_rid_int;
    temp_s_axi_rdata_reg <= s_axi_rdata_int;
    temp_s_axi_rresp_reg <= s_axi_rresp_int;
    temp_s_axi_rlast_reg <= s_axi_rlast_int;
    temp_s_axi_ruser_reg <= s_axi_ruser_int;
    end
end
reg [DATA_WIDTH-1:0]  m_axi_wdata_reg  = {DATA_WIDTH{1'b0}};
reg [STRB_WIDTH-1:0]  m_axi_wstrb_reg  = {STRB_WIDTH{1'b0}};
reg                   m_axi_wlast_reg  = 1'b0;
reg [WUSER_WIDTH-1:0] m_axi_wuser_reg  = 1'b0;
reg [M_COUNT-1:0]     m_axi_wvalid_reg = 1'b0, m_axi_wvalid_next;
reg [DATA_WIDTH-1:0]  temp_m_axi_wdata_reg  = {DATA_WIDTH{1'b0}};
reg [STRB_WIDTH-1:0]  temp_m_axi_wstrb_reg  = {STRB_WIDTH{1'b0}};
reg                   temp_m_axi_wlast_reg  = 1'b0;
reg [WUSER_WIDTH-1:0] temp_m_axi_wuser_reg  = 1'b0;
reg                   temp_m_axi_wvalid_reg = 1'b0, temp_m_axi_wvalid_next;
reg store_axi_w_int_to_output;
reg store_axi_w_int_to_temp;
reg store_axi_w_temp_to_output;
assign m_axi_wdata = {M_COUNT{m_axi_wdata_reg}};
assign m_axi_wstrb = {M_COUNT{m_axi_wstrb_reg}};
assign m_axi_wlast = {M_COUNT{m_axi_wlast_reg}};
assign m_axi_wuser = {M_COUNT{WUSER_ENABLE ? m_axi_wuser_reg : {WUSER_WIDTH{1'b0}}}};
assign m_axi_wvalid = m_axi_wvalid_reg;
assign m_axi_wready_int_early = current_m_axi_wready | (~temp_m_axi_wvalid_reg & (~current_m_axi_wvalid | ~m_axi_wvalid_int));
always @* begin
    m_axi_wvalid_next = m_axi_wvalid_reg;
    temp_m_axi_wvalid_next = temp_m_axi_wvalid_reg;
    store_axi_w_int_to_output = 1'b0;
    store_axi_w_int_to_temp = 1'b0;
    store_axi_w_temp_to_output = 1'b0;
    if (m_axi_wready_int_reg) begin
    if (current_m_axi_wready | ~current_m_axi_wvalid) begin
    m_axi_wvalid_next[m_select_reg] = m_axi_wvalid_int;
    store_axi_w_int_to_output = 1'b1;
    end else begin
    temp_m_axi_wvalid_next = m_axi_wvalid_int;
    store_axi_w_int_to_temp = 1'b1;
    end
    end else if (current_m_axi_wready) begin
    m_axi_wvalid_next[m_select_reg] = temp_m_axi_wvalid_reg;
    temp_m_axi_wvalid_next = 1'b0;
    store_axi_w_temp_to_output = 1'b1;
    end
end
always @(posedge clk) begin
    if (rst) begin
    m_axi_wvalid_reg <= 1'b0;
    m_axi_wready_int_reg <= 1'b0;
    temp_m_axi_wvalid_reg <= 1'b0;
    end else begin
    m_axi_wvalid_reg <= m_axi_wvalid_next;
    m_axi_wready_int_reg <= m_axi_wready_int_early;
    temp_m_axi_wvalid_reg <= temp_m_axi_wvalid_next;
    end
    if (store_axi_w_int_to_output) begin
    m_axi_wdata_reg <= m_axi_wdata_int;
    m_axi_wstrb_reg <= m_axi_wstrb_int;
    m_axi_wlast_reg <= m_axi_wlast_int;
    m_axi_wuser_reg <= m_axi_wuser_int;
    end else if (store_axi_w_temp_to_output) begin
    m_axi_wdata_reg <= temp_m_axi_wdata_reg;
    m_axi_wstrb_reg <= temp_m_axi_wstrb_reg;
    m_axi_wlast_reg <= temp_m_axi_wlast_reg;
    m_axi_wuser_reg <= temp_m_axi_wuser_reg;
    end
    if (store_axi_w_int_to_temp) begin
    temp_m_axi_wdata_reg <= m_axi_wdata_int;
    temp_m_axi_wstrb_reg <= m_axi_wstrb_int;
    temp_m_axi_wlast_reg <= m_axi_wlast_int;
    temp_m_axi_wuser_reg <= m_axi_wuser_int;
    end
end
endmodule
`resetall
/*
Copyright (c) 2014-2021 Alex Forencich
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
`resetall
`timescale 1ns / 1ps
`default_nettype none
/*
* Arbiter module0969
 */
module arbiter #
(
    parameter PORTS = 4,
    parameter ARB_TYPE_ROUND_ROBIN = 0,
    parameter ARB_BLOCK = 0,
    parameter ARB_BLOCK_ACK = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 0
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [PORTS-1:0]         request,
    input  wire [PORTS-1:0]         acknowledge,
    output wire [PORTS-1:0]         grant,
    output wire                     grant_valid,
    output wire [$clog2(PORTS)-1:0] grant_encoded
);
reg [PORTS-1:0] grant_reg = 0, grant_next;
reg grant_valid_reg = 0, grant_valid_next;
reg [$clog2(PORTS)-1:0] grant_encoded_reg = 0, grant_encoded_next;
assign grant_valid = grant_valid_reg;
assign grant = grant_reg;
assign grant_encoded = grant_encoded_reg;
wire request_valid;
wire [$clog2(PORTS)-1:0] request_index;
wire [PORTS-1:0] request_mask;
priority_encoder #(
    .WIDTH(PORTS),
    .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
priority_encoder_inst (
    .input_unencoded(request),
    .output_valid(request_valid),
    .output_encoded(request_index),
    .output_unencoded(request_mask)
);
reg [PORTS-1:0] mask_reg = 0, mask_next;
wire masked_request_valid;
wire [$clog2(PORTS)-1:0] masked_request_index;
wire [PORTS-1:0] masked_request_mask;
priority_encoder #(
    .WIDTH(PORTS),
    .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
priority_encoder_masked (
    .input_unencoded(request & mask_reg),
    .output_valid(masked_request_valid),
    .output_encoded(masked_request_index),
    .output_unencoded(masked_request_mask)
);
always @* 
begin
    grant_next = 0;
    grant_valid_next = 0;
    grant_encoded_next = 0;
    mask_next = mask_reg;
    if (ARB_BLOCK && !ARB_BLOCK_ACK && grant_reg & request)
    begin
    grant_valid_next = grant_valid_reg;
    grant_next = grant_reg;
    grant_encoded_next = grant_encoded_reg;
    end 
    else if (ARB_BLOCK && ARB_BLOCK_ACK && grant_valid && !(grant_reg & acknowledge)) 
    begin
    grant_valid_next = grant_valid_reg;
    grant_next = grant_reg;
    grant_encoded_next = grant_encoded_reg;
    end 
    else if (request_valid) 
    begin
    if (ARB_TYPE_ROUND_ROBIN) 
    begin
    if (masked_request_valid) 
    begin
    grant_valid_next = 1;
    grant_next = masked_request_mask;
    grant_encoded_next = masked_request_index;
    if (ARB_LSB_HIGH_PRIORITY)
    begin
    mask_next = {PORTS{1'b1}} << (masked_request_index + 1);
    end
    else
    begin
    mask_next = {PORTS{1'b1}} >> (PORTS - masked_request_index);
    end
    end 
    else 
    begin
    grant_valid_next = 1;
    grant_next = request_mask;
    grant_encoded_next = request_index;
    if (ARB_LSB_HIGH_PRIORITY)
    begin
    mask_next = {PORTS{1'b1}} << (request_index + 1);
    end 
    else 
    begin
    mask_next = {PORTS{1'b1}} >> (PORTS - request_index);
    end
    end
    end 
    else
    begin
    grant_valid_next = 1;
    grant_next = request_mask;
    grant_encoded_next = request_index;
    end
    end
end
always @(posedge clk) begin
    if (rst) begin
    grant_reg <= 0;
    grant_valid_reg <= 0;
    grant_encoded_reg <= 0;
    mask_reg <= 0;
    end else begin
    grant_reg <= grant_next;
    grant_valid_reg <= grant_valid_next;
    grant_encoded_reg <= grant_encoded_next;
    mask_reg <= mask_next;
    end
end
endmodule
`resetall
/*
Copyright (c) 2014-2021 Alex Forencich
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
`resetall
`timescale 1ns / 1ps
`default_nettype none
/*
* Priority encoder module2864
 */
module priority_encoder #
(
    parameter WIDTH = 4,
    parameter LSB_HIGH_PRIORITY = 0
)
(
    input  wire [WIDTH-1:0]         input_unencoded,
    output wire                     output_valid,
    output wire [$clog2(WIDTH)-1:0] output_encoded,
    output wire [WIDTH-1:0]         output_unencoded
);
parameter LEVELS = WIDTH > 2 ? $clog2(WIDTH) : 1;   
parameter W = 2**LEVELS;                           
wire [W-1:0] input_padded = {{W-WIDTH{1'b0}}, input_unencoded};
wire [W/2-1:0] stage_valid[LEVELS-1:0];
wire [W/2-1:0] stage_enc[LEVELS-1:0];
generate
    genvar l, n;
    for (n = 0; n < W/2; n = n + 1) begin : loop_in
    assign stage_valid[0][n] = |input_padded[n*2+1:n*2];    
    if (LSB_HIGH_PRIORITY) begin
    assign stage_enc[0][n] = !input_padded[n*2+0];
    end else begin
    assign stage_enc[0][n] = input_padded[n*2+1];
    end
    end
    for (l = 1; l < LEVELS; l = l + 1) begin : loop_levels
    for (n = 0; n < W/(2*2**l); n = n + 1) begin : loop_compress
    assign stage_valid[l][n] = |stage_valid[l-1][n*2+1:n*2];
    if (LSB_HIGH_PRIORITY) begin
    assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+0] ? {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]} : {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]};
    end else begin
    assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+1] ? {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]} : {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]};
    end
    end
    end
endgenerate
assign output_valid = stage_valid[LEVELS-1];
assign output_encoded = stage_enc[LEVELS-1];
assign output_unencoded = 1 << output_encoded;
endmodule
`resetall
module ahblite_axi_full_bridge_04404
(
    m_axi_arready,
    m_axi_awready,
    m_axi_bvalid,
    m_axi_rlast,
    m_axi_rvalid,
    m_axi_wready,
    s_ahb_hclk,
    s_ahb_hready_in,
    s_ahb_hresetn,
    s_ahb_hsel,
    s_ahb_hwrite,
    m_axi_bid,
    m_axi_bresp,
    m_axi_rdata,
    m_axi_rid,
    m_axi_rresp,
    s_ahb_haddr,
    s_ahb_hburst,
    s_ahb_hprot,
    s_ahb_hsize,
    s_ahb_htrans,
    s_ahb_hwdata,
    m_axi_aclk,
    m_axi_aresetn,
    m_axi_arlock,
    m_axi_arvalid,
    m_axi_awlock,
    m_axi_awvalid,
    m_axi_bready,
    m_axi_rready,
    m_axi_wlast,
    m_axi_wvalid,
    s_ahb_hready_out,
    s_ahb_hresp,
    m_axi_araddr,
    m_axi_arburst,
    m_axi_arcache,
    m_axi_arid,
    m_axi_arlen,
    m_axi_arprot,
    m_axi_arsize,
    m_axi_awaddr,
    m_axi_awburst,
    m_axi_awcache,
    m_axi_awid,
    m_axi_awlen,
    m_axi_awprot,
    m_axi_awsize,
    m_axi_wdata,
    m_axi_wstrb,
    s_ahb_hrdata
);
    input  m_axi_arready;
    input  m_axi_awready;
    input  m_axi_bvalid;
    input  m_axi_rlast;
    input  m_axi_rvalid;
    input  m_axi_wready;
    input  s_ahb_hclk;
    input  s_ahb_hready_in;
    input  s_ahb_hresetn;
    input  s_ahb_hsel;
    input  s_ahb_hwrite;
    input  [3:0] m_axi_bid;
    input  [1:0] m_axi_bresp;
    input  [31:0] m_axi_rdata;
    input  [3:0] m_axi_rid;
    input  [1:0] m_axi_rresp;
    input  [31:0] s_ahb_haddr;
    input  [2:0] s_ahb_hburst;
    input  [3:0] s_ahb_hprot;
    input  [2:0] s_ahb_hsize;
    input  [1:0] s_ahb_htrans;
    input  [31:0] s_ahb_hwdata;
    output m_axi_aclk;
    output m_axi_aresetn;
    output m_axi_arlock;
    output m_axi_arvalid;
    output m_axi_awlock;
    output m_axi_awvalid;
    output m_axi_bready;
    output m_axi_rready;
    output m_axi_wlast;
    output m_axi_wvalid;
    output s_ahb_hready_out;
    output s_ahb_hresp;
    output [31:0] m_axi_araddr;
    output [1:0] m_axi_arburst;
    output [3:0] m_axi_arcache;
    output [3:0] m_axi_arid;
    output [7:0] m_axi_arlen;
    output [2:0] m_axi_arprot;
    output [2:0] m_axi_arsize;
    output [31:0] m_axi_awaddr;
    output [1:0] m_axi_awburst;
    output [3:0] m_axi_awcache;
    output [3:0] m_axi_awid;
    output [7:0] m_axi_awlen;
    output [2:0] m_axi_awprot;
    output [2:0] m_axi_awsize;
    output [31:0] m_axi_wdata;
    output [3:0] m_axi_wstrb;
    output [31:0] s_ahb_hrdata;
    wire \U0/AHBLITE_AXI_CONTROL_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_1 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_10 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_11 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_12 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_13 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_14 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_15 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_16 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_17 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_18 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_19 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_20 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_4 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_6 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_7 ;
    wire \U0/AHB_DATA_COUNTER_n_0 ;
    wire \U0/AHB_DATA_COUNTER_n_1 ;
    wire \U0/AHB_DATA_COUNTER_n_2 ;
    wire \U0/AHB_DATA_COUNTER_n_3 ;
    wire \U0/AHB_DATA_COUNTER_n_4 ;
    wire \U0/AHB_DATA_COUNTER_n_5 ;
    wire \U0/AHB_IF_n_12 ;
    wire \U0/AHB_IF_n_14 ;
    wire \U0/AHB_IF_n_16 ;
    wire \U0/AHB_IF_n_18 ;
    wire \U0/AHB_IF_n_19 ;
    wire \U0/AHB_IF_n_21 ;
    wire \U0/AHB_IF_n_22 ;
    wire \U0/AHB_IF_n_23 ;
    wire \U0/AHB_IF_n_24 ;
    wire \U0/AHB_IF_n_3 ;
    wire \U0/AHB_IF_n_30 ;
    wire \U0/AHB_IF_n_32 ;
    wire \U0/AHB_IF_n_39 ;
    wire \U0/AXI_ALEN_i0 ;
    wire \U0/AXI_RCHANNEL_n_10 ;
    wire \U0/AXI_RCHANNEL_n_3 ;
    wire \U0/AXI_RCHANNEL_n_5 ;
    wire \U0/AXI_WCHANNEL_n_10 ;
    wire \U0/AXI_WCHANNEL_n_12 ;
    wire \U0/AXI_WCHANNEL_n_13 ;
    wire \U0/AXI_WCHANNEL_n_14 ;
    wire \U0/AXI_WCHANNEL_n_6 ;
    wire \U0/AXI_WCHANNEL_n_7 ;
    wire \U0/AXI_WCHANNEL_n_8 ;
    wire \U0/AXI_WCHANNEL_n_9 ;
    wire \U0/M_AXI_RREADY_i5__0 ;
    wire \U0/M_AXI_WLAST_i110_out ;
    wire \U0/S_AHB_HREADY_OUT_i116_out ;
    wire \U0/ahb_burst_done ;
    wire \U0/ahb_data_valid ;
    wire \U0/ahb_data_valid_burst_term ;
    wire \U0/ahb_done_axi_in_progress ;
    wire \U0/ahb_hburst_incr ;
    wire \U0/ahb_hburst_single ;
    wire \U0/axi_waddr_done_i ;
    wire \U0/burst_term ;
    wire \U0/burst_term_cur_cnt[0] ;
    wire \U0/burst_term_cur_cnt[1] ;
    wire \U0/burst_term_cur_cnt[2] ;
    wire \U0/burst_term_cur_cnt[3] ;
    wire \U0/burst_term_cur_cnt[4] ;
    wire \U0/burst_term_hwrite ;
    wire \U0/burst_term_single_incr ;
    wire \U0/burst_term_txer_cnt[1] ;
    wire \U0/burst_term_txer_cnt[2] ;
    wire \U0/burst_term_txer_cnt[3] ;
    wire \U0/burst_term_with_nonseq ;
    wire \U0/busy_detected ;
    wire \U0/cntr_rst ;
    wire \U0/ctl_sm_ns033_out ;
    wire \U0/ctl_sm_ns1 ;
    wire \U0/ctl_sm_ns14_out ;
    wire \U0/eqOp6_out ;
    wire \U0/idle_txfer_pending ;
    wire \U0/init_pending_txfer ;
    wire \U0/last_axi_rd_sample ;
    wire \U0/local_en ;
    wire \U0/nonseq_detected ;
    wire \U0/nonseq_txfer_pending ;
    wire \U0/p_12_in ;
    wire \U0/p_27_in ;
    wire \U0/rd_load_timeout_cntr ;
    wire \U0/reset_hready010_out ;
    wire \U0/seq_detected ;
    wire \U0/set_axi_waddr ;
    wire \U0/valid_cnt_required[1] ;
    wire \U0/valid_cnt_required[2] ;
    wire \U0/valid_cnt_required[3] ;
    wire \U0/AHBLITE_AXI_CONTROL/<const1> ;
    wire \U0/AHBLITE_AXI_CONTROL/AHB_IF/p_9_in ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ;
    wire \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/reset_hready ;
    wire \U0/AHBLITE_AXI_CONTROL/set_axi_raddr ;
    wire \U0/AHBLITE_AXI_CONTROL/set_axi_wdata_burst ;
    wire \U0/AHBLITE_AXI_CONTROL/set_hready ;
    wire \U0/AHBLITE_AXI_CONTROL/set_hresp_err ;
    wire \U0/AHB_IF/<const0> ;
    wire \U0/AHB_IF/<const1> ;
    wire \U0/AHB_IF/AHBLITE_AXI_CONTROL/ctl_sm_ns132_out ;
    wire \U0/AHB_IF/AHBLITE_AXI_CONTROL/hburst_single_incr ;
    wire \U0/AHB_IF/AHBLITE_AXI_CONTROL/reset_hready2__0 ;
    wire \U0/AHB_IF/AXI_ABURST_i[0]_i_1_n_0 ;
    wire \U0/AHB_IF/AXI_ABURST_i[1]_i_1_n_0 ;
    wire \U0/AHB_IF/AXI_ALEN_i[1] ;
    wire \U0/AHB_IF/AXI_ALEN_i[3] ;
    wire \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1_n_0 ;
    wire \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17_n_0 ;
    wire \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_8_n_0 ;
    wire \U0/AHB_IF/ahb_done_axi_in_progress_i_1_n_0 ;
    wire \U0/AHB_IF/ahb_hburst_incr_i_i_1_n_0 ;
    wire \U0/AHB_IF/ahb_hburst_single_i_i_1_n_0 ;
    wire \U0/AHB_IF/ahb_penult_beat_i_1_n_0 ;
    wire \U0/AHB_IF/burst_term_txer_cnt_i0 ;
    wire \U0/AHB_IF/dummy_on_axi_progress_i_5_n_0 ;
    wire \U0/AHB_IF/dummy_txfer_in_progress_i_1_n_0 ;
    wire \U0/AHB_IF/eqOp ;
    wire \U0/AHB_IF/eqOp0_in ;
    wire \U0/AHB_IF/p_1_out[2] ;
    wire \U0/AHB_IF/valid_cnt_required_i[1]_i_1_n_0 ;
    wire \U0/AHB_IF/valid_cnt_required_i[2]_i_1_n_0 ;
    wire \U0/AHB_IF/valid_cnt_required_i[3]_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/<const0> ;
    wire \U0/AXI_RCHANNEL/<const1> ;
    wire \U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/ahb_rd_req ;
    wire \U0/AXI_RCHANNEL/ahb_rd_req_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/ahb_rd_txer_pending ;
    wire \U0/AXI_RCHANNEL/ahb_rd_txer_pending07_out__0 ;
    wire \U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_last_avlbl_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_last_avlbl_i_2_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_last_avlbl_reg_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_rd_avlbl ;
    wire \U0/AXI_RCHANNEL/axi_rd_avlbl_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_rresp_avlbl[1] ;
    wire \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2_n_0 ;
    wire \U0/AXI_RCHANNEL/bridge_rd_in_progress ;
    wire \U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/rvalid_rready ;
    wire \U0/AXI_RCHANNEL/seq_detected_d1 ;
    wire \U0/AXI_WCHANNEL/<const0> ;
    wire \U0/AXI_WCHANNEL/<const1> ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_5 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_7 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_8 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_9 ;
    wire \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/M_AXI_WLAST_i__1 ;
    wire \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[1] ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[1]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[2] ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[3] ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_last_beat_reg_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 ;
    wire \U0/AXI_WCHANNEL/dummy_on_axi__0 ;
    wire \U0/AXI_WCHANNEL/dummy_on_axi_progress ;
    wire \U0/AXI_WCHANNEL/local_en_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/local_wdata[0] ;
    wire \U0/AXI_WCHANNEL/local_wdata[10] ;
    wire \U0/AXI_WCHANNEL/local_wdata[11] ;
    wire \U0/AXI_WCHANNEL/local_wdata[12] ;
    wire \U0/AXI_WCHANNEL/local_wdata[13] ;
    wire \U0/AXI_WCHANNEL/local_wdata[14] ;
    wire \U0/AXI_WCHANNEL/local_wdata[15] ;
    wire \U0/AXI_WCHANNEL/local_wdata[16] ;
    wire \U0/AXI_WCHANNEL/local_wdata[17] ;
    wire \U0/AXI_WCHANNEL/local_wdata[18] ;
    wire \U0/AXI_WCHANNEL/local_wdata[19] ;
    wire \U0/AXI_WCHANNEL/local_wdata[1] ;
    wire \U0/AXI_WCHANNEL/local_wdata[20] ;
    wire \U0/AXI_WCHANNEL/local_wdata[21] ;
    wire \U0/AXI_WCHANNEL/local_wdata[22] ;
    wire \U0/AXI_WCHANNEL/local_wdata[23] ;
    wire \U0/AXI_WCHANNEL/local_wdata[24] ;
    wire \U0/AXI_WCHANNEL/local_wdata[25] ;
    wire \U0/AXI_WCHANNEL/local_wdata[26] ;
    wire \U0/AXI_WCHANNEL/local_wdata[27] ;
    wire \U0/AXI_WCHANNEL/local_wdata[28] ;
    wire \U0/AXI_WCHANNEL/local_wdata[29] ;
    wire \U0/AXI_WCHANNEL/local_wdata[2] ;
    wire \U0/AXI_WCHANNEL/local_wdata[30] ;
    wire \U0/AXI_WCHANNEL/local_wdata[31] ;
    wire \U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/local_wdata[3] ;
    wire \U0/AXI_WCHANNEL/local_wdata[4] ;
    wire \U0/AXI_WCHANNEL/local_wdata[5] ;
    wire \U0/AXI_WCHANNEL/local_wdata[6] ;
    wire \U0/AXI_WCHANNEL/local_wdata[7] ;
    wire \U0/AXI_WCHANNEL/local_wdata[8] ;
    wire \U0/AXI_WCHANNEL/local_wdata[9] ;
    wire \U0/AXI_WCHANNEL/p_1_in[0] ;
    wire \U0/AXI_WCHANNEL/p_1_in[10] ;
    wire \U0/AXI_WCHANNEL/p_1_in[11] ;
    wire \U0/AXI_WCHANNEL/p_1_in[12] ;
    wire \U0/AXI_WCHANNEL/p_1_in[13] ;
    wire \U0/AXI_WCHANNEL/p_1_in[14] ;
    wire \U0/AXI_WCHANNEL/p_1_in[15] ;
    wire \U0/AXI_WCHANNEL/p_1_in[16] ;
    wire \U0/AXI_WCHANNEL/p_1_in[17] ;
    wire \U0/AXI_WCHANNEL/p_1_in[18] ;
    wire \U0/AXI_WCHANNEL/p_1_in[19] ;
    wire \U0/AXI_WCHANNEL/p_1_in[1] ;
    wire \U0/AXI_WCHANNEL/p_1_in[20] ;
    wire \U0/AXI_WCHANNEL/p_1_in[21] ;
    wire \U0/AXI_WCHANNEL/p_1_in[22] ;
    wire \U0/AXI_WCHANNEL/p_1_in[23] ;
    wire \U0/AXI_WCHANNEL/p_1_in[24] ;
    wire \U0/AXI_WCHANNEL/p_1_in[25] ;
    wire \U0/AXI_WCHANNEL/p_1_in[26] ;
    wire \U0/AXI_WCHANNEL/p_1_in[27] ;
    wire \U0/AXI_WCHANNEL/p_1_in[28] ;
    wire \U0/AXI_WCHANNEL/p_1_in[29] ;
    wire \U0/AXI_WCHANNEL/p_1_in[2] ;
    wire \U0/AXI_WCHANNEL/p_1_in[30] ;
    wire \U0/AXI_WCHANNEL/p_1_in[31] ;
    wire \U0/AXI_WCHANNEL/p_1_in[3] ;
    wire \U0/AXI_WCHANNEL/p_1_in[4] ;
    wire \U0/AXI_WCHANNEL/p_1_in[5] ;
    wire \U0/AXI_WCHANNEL/p_1_in[6] ;
    wire \U0/AXI_WCHANNEL/p_1_in[7] ;
    wire \U0/AXI_WCHANNEL/p_1_in[8] ;
    wire \U0/AXI_WCHANNEL/p_1_in[9] ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/GLOBAL_LOGIC1 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_2_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_5_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_6_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_init ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp1_out ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp3_out ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp5_out ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp8_out ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp__5 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ;
    xs0 GND
    (
    .G(m_axi_arlock)
    );
    xsLUTSA5 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I2(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3_n_0 ),
    .I3(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1 .INIT = 32'HB8FFB800;
    xsLUTSA5 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2 
    (
    .I0(\U0/nonseq_detected ),
    .I1(\U0/nonseq_txfer_pending ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2 .INIT = 32'H00E00FE0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3 
    (
    .I0(\U0/axi_waddr_done_i ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/nonseq_txfer_pending ),
    .I3(\U0/nonseq_detected ),
    .I4(m_axi_bvalid),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3 .INIT = 64'HDDD11111FFFFFFFF;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1 
    (
    .I0(\U0/AHB_IF_n_23 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I2(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I3(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1 .INIT = 64'H8F80FFFF8F800000;
    xsLUTSA3 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3 
    (
    .I0(\U0/axi_waddr_done_i ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3 .INIT = 8'H38;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I2(\U0/AHB_IF_n_24 ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1 .INIT = 64'HB888FFFFB8880000;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2 
    (
    .I0(\U0/ctl_sm_ns1 ),
    .I1(\U0/ctl_sm_ns14_out ),
    .I2(\U0/idle_txfer_pending ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2 .INIT = 64'H0000020000FF0200;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5 
    (
    .I0(m_axi_bvalid),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(m_axi_wready),
    .I4(m_axi_wlast),
    .I5(\U0/AXI_ALEN_i0 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5 .INIT = 64'HBFB3B3B3BCB0B0B0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/ctl_sm_ns033_out ),
    .I3(\U0/ctl_sm_ns1 ),
    .I4(\U0/idle_txfer_pending ),
    .I5(\U0/ctl_sm_ns14_out ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6 .INIT = 64'HFDFDFDFDFDFDFFFD;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHBLITE_AXI_CONTROL_n_1 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHBLITE_AXI_CONTROL_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2] .INIT = 1'B0;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 )
    );
    xsLUTSA2 \U0/AHBLITE_AXI_CONTROL/INFERRED_GEN.icount_out[0]_i_1 
    (
    .I0(\U0/set_axi_waddr ),
    .I1(\U0/AXI_WCHANNEL_n_10 ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_4 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/INFERRED_GEN.icount_out[0]_i_1 .INIT = 4'H1;
    xsLUTSA3 \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_1 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/set_axi_raddr ),
    .I1(m_axi_arready),
    .I2(m_axi_arvalid),
    .O(\U0/AHBLITE_AXI_CONTROL_n_11 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_1 .INIT = 8'HBA;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I2(\U0/ctl_sm_ns033_out ),
    .I3(\U0/ctl_sm_ns14_out ),
    .I4(\U0/burst_term_hwrite ),
    .I5(s_ahb_hwrite),
    .O(\U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4 .INIT = 64'H0000000000004000;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_reg_i_2 
    (
    .I0(\U0/AHB_IF_n_22 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/set_axi_raddr )
    );
    xsLUTSA3 \U0/AHBLITE_AXI_CONTROL/M_AXI_BREADY_i_i_1 
    (
    .I0(\U0/axi_waddr_done_i ),
    .I1(m_axi_bvalid),
    .I2(m_axi_bready),
    .O(\U0/AHBLITE_AXI_CONTROL_n_19 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_BREADY_i_i_1 .INIT = 8'HBA;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/last_axi_rd_sample ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/M_AXI_RREADY_i_i_2 
    (
    .I0(\U0/M_AXI_RREADY_i5__0 ),
    .I1(\U0/AXI_RCHANNEL_n_10 ),
    .I2(\U0/busy_detected ),
    .I3(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I5(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6_n_0 ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_7 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_RREADY_i_i_2 .INIT = 64'HFFFFFFFEFEFEFFFE;
    xsLUTSA5 \U0/AHBLITE_AXI_CONTROL/M_AXI_WVALID_i_i_2 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/set_axi_wdata_burst ),
    .I1(\U0/ahb_data_valid_burst_term ),
    .I2(\U0/local_en ),
    .I3(\U0/ahb_data_valid ),
    .I4(\U0/axi_waddr_done_i ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_10 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_WVALID_i_i_2 .INIT = 32'HFFFCAAA0;
    xsLUTSA5 \U0/AHBLITE_AXI_CONTROL/M_AXI_WVALID_i_i_3 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/ahb_hburst_single ),
    .I3(\U0/ahb_hburst_incr ),
    .I4(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/set_axi_wdata_burst )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_WVALID_i_i_3 .INIT = 32'H00000004;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13 
    (
    .I0(\U0/AHB_IF_n_14 ),
    .I1(\U0/axi_waddr_done_i ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I4(\U0/ahb_hburst_single ),
    .I5(\U0/AXI_WCHANNEL_n_12 ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13 .INIT = 64'HA0C0AFC0A0C0A0C0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/ctl_sm_ns14_out ),
    .I3(\U0/ctl_sm_ns033_out ),
    .I4(\U0/idle_txfer_pending ),
    .I5(\U0/AXI_RCHANNEL_n_3 ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14 .INIT = 64'HDFDDDFDFDFDDDDDD;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_2 
    (
    .I0(\U0/busy_detected ),
    .I1(\U0/S_AHB_HREADY_OUT_i116_out ),
    .I2(\U0/AHBLITE_AXI_CONTROL/reset_hready ),
    .I3(\U0/AHBLITE_AXI_CONTROL/set_hready ),
    .I4(\U0/AHBLITE_AXI_CONTROL/AHB_IF/p_9_in ),
    .I5(s_ahb_hready_out),
    .O(\U0/AHBLITE_AXI_CONTROL_n_13 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_2 .INIT = 64'H3333232333332320;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_5 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/AXI_RCHANNEL_n_5 ),
    .I2(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I3(\U0/AHB_IF_n_18 ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I5(\U0/AHB_IF_n_19 ),
    .O(\U0/AHBLITE_AXI_CONTROL/reset_hready )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_5 .INIT = 64'H4F400F0F4F400000;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_reg_i_6 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/set_hready )
    );
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_1 
    (
    .I0(s_ahb_hresp),
    .I1(\U0/AHBLITE_AXI_CONTROL/set_hresp_err ),
    .I2(s_ahb_hresetn),
    .I3(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I5(\U0/AHB_IF_n_16 ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_17 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_1 .INIT = 64'H00E0000000E0E0E0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/ctl_sm_ns1 ),
    .I2(\U0/idle_txfer_pending ),
    .I3(\U0/ctl_sm_ns033_out ),
    .I4(\U0/ctl_sm_ns14_out ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3 .INIT = 64'H0000510100000000;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(m_axi_bvalid),
    .I3(\U0/ctl_sm_ns14_out ),
    .I4(m_axi_bresp[1]),
    .I5(\U0/idle_txfer_pending ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5 .INIT = 64'H0000000000800000;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/nonseq_txfer_pending ),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/ctl_sm_ns1 ),
    .I4(\U0/idle_txfer_pending ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6 .INIT = 64'H00000100FFFFFFFF;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_reg_i_2 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/set_hresp_err )
    );
    xs1 \U0/AHBLITE_AXI_CONTROL/VCC 
    (
    .P(\U0/AHBLITE_AXI_CONTROL/<const1> )
    );
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I2(s_ahb_hwrite),
    .I3(\U0/burst_term_hwrite ),
    .I4(\U0/ctl_sm_ns14_out ),
    .I5(\U0/ctl_sm_ns033_out ),
    .O(\U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3 .INIT = 64'H4440000000000000;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/set_axi_waddr ),
    .R(\U0/cntr_rst ),
    .Q(\U0/axi_waddr_done_i )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_reg .INIT = 1'B0;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_reg_i_1 
    (
    .I0(\U0/AHB_IF_n_21 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/set_axi_waddr )
    );
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_1 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2_n_0 ),
    .I1(s_ahb_hresetn),
    .I2(\U0/AXI_WCHANNEL_n_13 ),
    .I3(\U0/init_pending_txfer ),
    .I4(\U0/burst_term ),
    .I5(\U0/last_axi_rd_sample ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_16 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_1 .INIT = 64'H00000000000C0404;
    xsLUTSA4 \U0/AHBLITE_AXI_CONTROL/burst_term_single_incr_i_1 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I2(\U0/burst_term_with_nonseq ),
    .I3(\U0/burst_term_single_incr ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_20 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/burst_term_single_incr_i_1 .INIT = 16'HFF10;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/burst_term_txer_cnt_i[3]_i_2 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(\U0/ahb_done_axi_in_progress ),
    .I4(\U0/AHB_IF_n_3 ),
    .I5(\U0/seq_detected ),
    .O(\U0/p_12_in )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/burst_term_txer_cnt_i[3]_i_2 .INIT = 64'H00FEFEFEFEFEFEFE;
    xsLUTSA4 \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_1 
    (
    .I0(\U0/idle_txfer_pending ),
    .I1(\U0/AHBLITE_AXI_CONTROL/AHB_IF/p_9_in ),
    .I2(s_ahb_hresetn),
    .I3(\U0/init_pending_txfer ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_14 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_1 .INIT = 16'H00E0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/nonseq_txfer_pending ),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/idle_txfer_pending ),
    .I4(m_axi_bvalid),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3 .INIT = 64'HFFFD555500000000;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/nonseq_txfer_pending ),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/idle_txfer_pending ),
    .I4(\U0/ctl_sm_ns033_out ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4 .INIT = 64'H5554000000000000;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_reg_i_2 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/init_pending_txfer )
    );
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/nonseq_txfer_pending_i_i_2 
    (
    .I0(\U0/ahb_burst_done ),
    .I1(\U0/ahb_done_axi_in_progress ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I5(\U0/nonseq_detected ),
    .O(\U0/burst_term_with_nonseq )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/nonseq_txfer_pending_i_i_2 .INIT = 64'H7777777000000000;
    xsLUTSA6_2 \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2 
    (
    .I0(\U0/p_12_in ),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_htrans[1]),
    .I3(s_ahb_hready_in),
    .I4(s_ahb_hsel),
    .I5(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .O6(\U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2_n_0 ),
    .O5(\U0/AHBLITE_AXI_CONTROL/AHB_IF/p_9_in )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2 .INIT = 64'HDDFFFFFF02000000;
    xsLUTSA6_2 \U0/AHBLITE_AXI_CONTROL/nonseq_txfer_pending_i_i_1 
    (
    .I0(s_ahb_hwrite),
    .I1(\U0/burst_term_with_nonseq ),
    .I2(\U0/burst_term_hwrite ),
    .I3(\U0/init_pending_txfer ),
    .I4(\U0/nonseq_txfer_pending ),
    .I5(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .O6(\U0/AHBLITE_AXI_CONTROL_n_15 ),
    .O5(\U0/AHBLITE_AXI_CONTROL_n_18 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/nonseq_txfer_pending_i_i_1 .INIT = 64'HCCFFCCCCB8B8B8B8;
    xsLUTSA6_2 \U0/AHBLITE_AXI_CONTROL/M_AXI_AWVALID_i_i_1 
    (
    .I0(\U0/set_axi_waddr ),
    .I1(m_axi_wready),
    .I2(m_axi_wvalid),
    .I3(m_axi_awready),
    .I4(m_axi_awvalid),
    .I5(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .O6(\U0/AHBLITE_AXI_CONTROL_n_12 ),
    .O5(\U0/AHBLITE_AXI_CONTROL_n_6 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_AWVALID_i_i_1 .INIT = 64'HAAFFAAAAEAEAEAEA;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[0]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[0])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[10] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[10]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[10])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[10] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[11] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[11]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[11])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[11] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[12] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[12]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[12])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[12] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[13] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[13]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[13])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[13] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[14] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[14]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[14])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[14] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[15] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[15]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[15])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[15] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[16] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[16]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[16])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[16] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[17] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[17]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[17])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[17] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[18] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[18]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[18])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[18] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[19] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[19]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[19])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[19] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[1]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[1])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[20] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[20]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[20])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[20] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[21] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[21]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[21])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[21] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[22] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[22]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[22])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[22] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[23] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[23]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[23])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[23] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[24] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[24]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[24])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[24] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[25] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[25]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[25])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[25] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[26] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[26]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[26])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[26] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[27] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[27]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[27])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[27] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[28] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[28]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[28])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[28] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[29] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[29]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[29])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[29] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[2]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[2])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[30] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[30]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[30])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[30] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[31] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[31]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[31])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[31] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[3]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[3])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[4]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[4])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[5] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[5]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[5])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[5] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[6] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[6]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[6])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[6] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[7] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[7]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[7])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[7] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[8] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[8]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[8])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[8] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[9] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[9]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[9])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[9] .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_IF/AXI_ABURST_i[0]_i_1 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I2(s_ahb_hburst[0]),
    .I3(\U0/AXI_ALEN_i0 ),
    .I4(s_ahb_hresetn),
    .I5(m_axi_arburst[0]),
    .O(\U0/AHB_IF/AXI_ABURST_i[0]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/AXI_ABURST_i[0]_i_1 .INIT = 64'HF1FF0000F1000000;
    xsLUTSA6 \U0/AHB_IF/AXI_ABURST_i[1]_i_1 
    (
    .I0(s_ahb_hburst[0]),
    .I1(s_ahb_hburst[1]),
    .I2(s_ahb_hburst[2]),
    .I3(\U0/AXI_ALEN_i0 ),
    .I4(s_ahb_hresetn),
    .I5(m_axi_arburst[1]),
    .O(\U0/AHB_IF/AXI_ABURST_i[1]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/AXI_ABURST_i[1]_i_1 .INIT = 64'H54FF000054000000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ABURST_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/AXI_ABURST_i[0]_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(m_axi_arburst[0])
    );
    defparam \U0/AHB_IF/AXI_ABURST_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ABURST_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/AXI_ABURST_i[1]_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(m_axi_arburst[1])
    );
    defparam \U0/AHB_IF/AXI_ABURST_i_reg[1] .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/AXI_ALEN_i[3]_i_1 
    (
    .I0(\U0/ahb_hburst_incr ),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_hsel),
    .I4(s_ahb_htrans[1]),
    .O(\U0/AXI_ALEN_i0 )
    );
    defparam \U0/AHB_IF/AXI_ALEN_i[3]_i_1 .INIT = 32'HB0000000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ALEN_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(\U0/AHB_IF/AXI_ALEN_i[1] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arlen[1])
    );
    defparam \U0/AHB_IF/AXI_ALEN_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ALEN_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_hburst[2]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arlen[2])
    );
    defparam \U0/AHB_IF/AXI_ALEN_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ALEN_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(\U0/AHB_IF/AXI_ALEN_i[3] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arlen[3])
    );
    defparam \U0/AHB_IF/AXI_ALEN_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ASIZE_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(s_ahb_hsize[0]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arsize[0])
    );
    defparam \U0/AHB_IF/AXI_ASIZE_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ASIZE_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(s_ahb_hsize[1]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arsize[1])
    );
    defparam \U0/AHB_IF/AXI_ASIZE_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ASIZE_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(s_ahb_hsize[2]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arsize[2])
    );
    defparam \U0/AHB_IF/AXI_ASIZE_i_reg[2] .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/FSM_sequential_ctl_sm_cs[1]_i_2 
    (
    .I0(\U0/ctl_sm_ns1 ),
    .I1(\U0/nonseq_detected ),
    .I2(\U0/nonseq_txfer_pending ),
    .I3(\U0/idle_txfer_pending ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHB_IF_n_23 )
    );
    defparam \U0/AHB_IF/FSM_sequential_ctl_sm_cs[1]_i_2 .INIT = 32'H00000002;
    xsLUTSA6 \U0/AHB_IF/FSM_sequential_ctl_sm_cs[2]_i_3 
    (
    .I0(\U0/idle_txfer_pending ),
    .I1(m_axi_bresp[1]),
    .I2(\U0/ctl_sm_ns14_out ),
    .I3(m_axi_bvalid),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I5(\U0/axi_waddr_done_i ),
    .O(\U0/AHB_IF_n_24 )
    );
    defparam \U0/AHB_IF/FSM_sequential_ctl_sm_cs[2]_i_3 .INIT = 64'H040000000400FFFF;
    xsDFFSA_K1S1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_ACACHE_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_hprot[2]),
    .S(\U0/cntr_rst ),
    .Q(m_axi_arcache[0])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_ACACHE_i_reg[0] .INIT = 1'B1;
    xsDFFSA_K1S1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_ACACHE_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_hprot[3]),
    .S(\U0/cntr_rst ),
    .Q(m_axi_arcache[1])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_ACACHE_i_reg[1] .INIT = 1'B1;
    xsLUTSA3 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1 
    (
    .I0(m_axi_arprot[1]),
    .I1(s_ahb_hresetn),
    .I2(\U0/AXI_ALEN_i0 ),
    .O(\U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1 .INIT = 8'HFB;
    xsLUTSA1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[2]_i_1 
    (
    .I0(s_ahb_hprot[0]),
    .O(\U0/AHB_IF/p_1_out[2] )
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[2]_i_1 .INIT = 2'H1;
    xsDFFSA_K1R1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_hprot[1]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arprot[0])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(m_axi_arprot[1])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(\U0/AHB_IF/p_1_out[2] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arprot[2])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[2] .INIT = 1'B0;
    xs0 \U0/AHB_IF/GND 
    (
    .G(\U0/AHB_IF/<const0> )
    );
    xsLUTSA6 \U0/AHB_IF/INFERRED_GEN.icount_out[4]_i_1__0 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_hsel),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_htrans[0]),
    .I4(s_ahb_hwrite),
    .I5(\U0/ahb_hburst_incr ),
    .O(\U0/AHB_IF_n_30 )
    );
    defparam \U0/AHB_IF/INFERRED_GEN.icount_out[4]_i_1__0 .INIT = 64'H0080008080800080;
    xsLUTSA6 \U0/AHB_IF/M_AXI_ARVALID_i_i_3 
    (
    .I0(\U0/burst_term_hwrite ),
    .I1(\U0/AHB_IF/AHBLITE_AXI_CONTROL/ctl_sm_ns132_out ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(s_ahb_hwrite),
    .I4(\U0/AXI_ALEN_i0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHB_IF_n_22 )
    );
    defparam \U0/AHB_IF/M_AXI_ARVALID_i_i_3 .INIT = 64'H40C040C0000F0000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[0]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[0])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[10] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[10]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[10])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[10] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[11] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[11]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[11])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[11] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[12] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[12]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[12])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[12] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[13] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[13]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[13])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[13] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[14] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[14]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[14])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[14] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[15] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[15]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[15])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[15] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[16] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[16]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[16])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[16] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[17] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[17]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[17])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[17] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[18] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[18]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[18])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[18] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[19] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[19]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[19])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[19] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[1]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[1])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[20] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[20]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[20])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[20] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[21] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[21]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[21])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[21] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[22] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[22]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[22])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[22] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[23] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[23]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[23])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[23] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[24] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[24]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[24])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[24] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[25] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[25]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[25])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[25] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[26] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[26]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[26])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[26] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[27] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[27]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[27])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[27] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[28] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[28]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[28])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[28] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[29] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[29]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[29])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[29] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[2]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[2])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[30] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[30]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[30])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[30] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[31] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[31]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[31])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[31] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[3]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[3])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[4]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[4])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[5] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[5]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[5])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[5] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[6] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[6]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[6])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[6] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[7] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[7]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[7])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[7] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[8] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[8]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[8])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[8] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[9] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[9]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[9])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[9] .INIT = 1'B0;
    xsLUTSA1 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_1 
    (
    .I0(s_ahb_hresetn),
    .O(\U0/cntr_rst )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_1 .INIT = 2'H1;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_11 
    (
    .I0(\U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/axi_waddr_done_i ),
    .I3(s_ahb_hwrite),
    .I4(\U0/ahb_hburst_single ),
    .I5(\U0/ahb_hburst_incr ),
    .O(\U0/AHB_IF_n_18 )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_11 .INIT = 64'HB8B8B8B8B8B888B8;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_12 
    (
    .I0(\U0/AHB_IF/AHBLITE_AXI_CONTROL/reset_hready2__0 ),
    .I1(\U0/AXI_WCHANNEL_n_12 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I3(\U0/AXI_ALEN_i0 ),
    .I4(s_ahb_hwrite),
    .I5(\U0/AHB_IF/AHBLITE_AXI_CONTROL/hburst_single_incr ),
    .O(\U0/AHB_IF_n_19 )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_12 .INIT = 64'HBFB0BFB0B0B0BFB0;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17 
    (
    .I0(\U0/reset_hready010_out ),
    .I1(m_axi_bvalid),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/nonseq_txfer_pending ),
    .I4(m_axi_bresp[1]),
    .I5(\U0/idle_txfer_pending ),
    .O(\U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17_n_0 )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17 .INIT = 64'H88808880888C8880;
    xsLUTSA5 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_20 
    (
    .I0(m_axi_bresp[1]),
    .I1(\U0/idle_txfer_pending ),
    .I2(\U0/nonseq_txfer_pending ),
    .I3(\U0/nonseq_detected ),
    .I4(m_axi_bvalid),
    .O(\U0/AHB_IF_n_14 )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_20 .INIT = 32'H000D0000;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_4 
    (
    .I0(\U0/nonseq_txfer_pending ),
    .I1(\U0/burst_term_with_nonseq ),
    .I2(\U0/ahb_done_axi_in_progress ),
    .I3(\U0/AHB_IF/S_AHB_HREADY_OUT_i_i_8_n_0 ),
    .I4(s_ahb_hwrite),
    .I5(\U0/ahb_burst_done ),
    .O(\U0/S_AHB_HREADY_OUT_i116_out )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_4 .INIT = 64'HFFFFFFFEFEFEFFFE;
    xsDFFSA_K1S1E1 \U0/AHB_IF/S_AHB_HREADY_OUT_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_13 ),
    .S(\U0/cntr_rst ),
    .Q(s_ahb_hready_out)
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_reg .INIT = 1'B1;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HRESP_i_i_4 
    (
    .I0(m_axi_bvalid),
    .I1(\U0/ctl_sm_ns14_out ),
    .I2(\U0/idle_txfer_pending ),
    .I3(m_axi_bresp[1]),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHB_IF_n_16 )
    );
    defparam \U0/AHB_IF/S_AHB_HRESP_i_i_4 .INIT = 64'H202200000000FFFF;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRESP_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_17 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(s_ahb_hresp)
    );
    defparam \U0/AHB_IF/S_AHB_HRESP_i_reg .INIT = 1'B0;
    xs1 \U0/AHB_IF/VCC 
    (
    .P(\U0/AHB_IF/<const1> )
    );
    xsLUTSA3 \U0/AHB_IF/ahb_data_valid_burst_term_i_1 
    (
    .I0(\U0/nonseq_txfer_pending ),
    .I1(\U0/init_pending_txfer ),
    .I2(\U0/ahb_data_valid_burst_term ),
    .O(\U0/AHB_IF_n_39 )
    );
    defparam \U0/AHB_IF/ahb_data_valid_burst_term_i_1 .INIT = 8'HBA;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_data_valid_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AXI_WCHANNEL_n_14 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_data_valid )
    );
    defparam \U0/AHB_IF/ahb_data_valid_i_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/ahb_done_axi_in_progress_i_1 
    (
    .I0(\U0/seq_detected ),
    .I1(\U0/AHB_IF_n_3 ),
    .I2(m_axi_wlast),
    .I3(m_axi_wready),
    .I4(\U0/ahb_done_axi_in_progress ),
    .O(\U0/AHB_IF/ahb_done_axi_in_progress_i_1_n_0 )
    );
    defparam \U0/AHB_IF/ahb_done_axi_in_progress_i_1 .INIT = 32'H8FFF8888;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_done_axi_in_progress_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/ahb_done_axi_in_progress_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_done_axi_in_progress )
    );
    defparam \U0/AHB_IF/ahb_done_axi_in_progress_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/ahb_hburst_incr_i_i_1 
    (
    .I0(\U0/AHB_IF/eqOp ),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_htrans[1]),
    .I3(s_ahb_hready_out),
    .I4(\U0/ahb_hburst_incr ),
    .O(\U0/AHB_IF/ahb_hburst_incr_i_i_1_n_0 )
    );
    defparam \U0/AHB_IF/ahb_hburst_incr_i_i_1 .INIT = 32'HEFFF2000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_hburst_incr_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/ahb_hburst_incr_i_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_hburst_incr )
    );
    defparam \U0/AHB_IF/ahb_hburst_incr_i_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/ahb_hburst_single_i_i_1 
    (
    .I0(\U0/AHB_IF/eqOp0_in ),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_htrans[1]),
    .I3(s_ahb_hready_out),
    .I4(\U0/ahb_hburst_single ),
    .O(\U0/AHB_IF/ahb_hburst_single_i_i_1_n_0 )
    );
    defparam \U0/AHB_IF/ahb_hburst_single_i_i_1 .INIT = 32'HEFFF2000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_hburst_single_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/ahb_hburst_single_i_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_hburst_single )
    );
    defparam \U0/AHB_IF/ahb_hburst_single_i_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_IF/ahb_penult_beat_i_1 
    (
    .I0(\U0/AHB_IF_n_3 ),
    .I1(s_ahb_hresetn),
    .I2(\U0/AHB_DATA_COUNTER_n_5 ),
    .I3(\U0/p_27_in ),
    .I4(s_ahb_htrans[1]),
    .I5(s_ahb_htrans[0]),
    .O(\U0/AHB_IF/ahb_penult_beat_i_1_n_0 )
    );
    defparam \U0/AHB_IF/ahb_penult_beat_i_1 .INIT = 64'HC008080800080008;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_penult_beat_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/ahb_penult_beat_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(\U0/AHB_IF_n_3 )
    );
    defparam \U0/AHB_IF/ahb_penult_beat_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_IF/ahb_wnr_i_i_2 
    (
    .I0(\U0/burst_term_hwrite ),
    .I1(\U0/AHB_IF/AHBLITE_AXI_CONTROL/ctl_sm_ns132_out ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(s_ahb_hwrite),
    .I4(\U0/AXI_ALEN_i0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHB_IF_n_21 )
    );
    defparam \U0/AHB_IF/ahb_wnr_i_i_2 .INIT = 64'HC080C0800F000000;
    xsLUTSA6 \U0/AHB_IF/ahb_wnr_i_i_4 
    (
    .I0(m_axi_bvalid),
    .I1(s_ahb_hsel),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_htrans[0]),
    .I4(s_ahb_htrans[1]),
    .I5(\U0/nonseq_txfer_pending ),
    .O(\U0/AHB_IF/AHBLITE_AXI_CONTROL/ctl_sm_ns132_out )
    );
    defparam \U0/AHB_IF/ahb_wnr_i_i_4 .INIT = 64'HAAAAAAAA00800000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_4 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[0] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_3 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[1] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_2 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[2] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_1 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[3] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[4] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_hwrite_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_18 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_hwrite )
    );
    defparam \U0/AHB_IF/burst_term_hwrite_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_16 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(\U0/burst_term )
    );
    defparam \U0/AHB_IF/burst_term_i_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_single_incr_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_20 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_single_incr )
    );
    defparam \U0/AHB_IF/burst_term_single_incr_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/burst_term_txer_cnt_i[3]_i_1 
    (
    .I0(\U0/burst_term ),
    .I1(\U0/p_12_in ),
    .I2(s_ahb_htrans[0]),
    .I3(s_ahb_hready_in),
    .I4(s_ahb_hsel),
    .O(\U0/AHB_IF/burst_term_txer_cnt_i0 )
    );
    defparam \U0/AHB_IF/burst_term_txer_cnt_i[3]_i_1 .INIT = 32'H04000000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_txer_cnt_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/valid_cnt_required[1] ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_txer_cnt[1] )
    );
    defparam \U0/AHB_IF/burst_term_txer_cnt_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_txer_cnt_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/valid_cnt_required[2] ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_txer_cnt[2] )
    );
    defparam \U0/AHB_IF/burst_term_txer_cnt_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_txer_cnt_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/valid_cnt_required[3] ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_txer_cnt[3] )
    );
    defparam \U0/AHB_IF/burst_term_txer_cnt_i_reg[3] .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/dummy_on_axi_progress_i_3 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/burst_term_cur_cnt[3] ),
    .I2(\U0/AHB_IF/dummy_on_axi_progress_i_5_n_0 ),
    .I3(\U0/burst_term_cur_cnt[4] ),
    .I4(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/eqOp6_out )
    );
    defparam \U0/AHB_IF/dummy_on_axi_progress_i_3 .INIT = 32'H90000090;
    xsLUTSA6 \U0/AHB_IF/dummy_on_axi_progress_i_5 
    (
    .I0(\U0/burst_term_cur_cnt[0] ),
    .I1(\U0/AXI_WCHANNEL_n_10 ),
    .I2(\U0/burst_term_cur_cnt[2] ),
    .I3(\U0/AXI_WCHANNEL_n_8 ),
    .I4(\U0/burst_term_cur_cnt[1] ),
    .I5(\U0/AXI_WCHANNEL_n_9 ),
    .O(\U0/AHB_IF/dummy_on_axi_progress_i_5_n_0 )
    );
    defparam \U0/AHB_IF/dummy_on_axi_progress_i_5 .INIT = 64'H9009000000009009;
    xsLUTSA3 \U0/AHB_IF/dummy_on_axi_progress_i_7 
    (
    .I0(\U0/burst_term_cur_cnt[1] ),
    .I1(\U0/burst_term_cur_cnt[0] ),
    .I2(\U0/burst_term_cur_cnt[2] ),
    .O(\U0/AHB_IF_n_32 )
    );
    defparam \U0/AHB_IF/dummy_on_axi_progress_i_7 .INIT = 8'HFE;
    xsLUTSA6 \U0/AHB_IF/dummy_txfer_in_progress_i_1 
    (
    .I0(\U0/AHB_IF_n_12 ),
    .I1(\U0/burst_term ),
    .I2(s_ahb_hresetn),
    .I3(\U0/init_pending_txfer ),
    .I4(m_axi_wlast),
    .I5(m_axi_wready),
    .O(\U0/AHB_IF/dummy_txfer_in_progress_i_1_n_0 )
    );
    defparam \U0/AHB_IF/dummy_txfer_in_progress_i_1 .INIT = 64'HC0C000A000A000A0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/dummy_txfer_in_progress_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/dummy_txfer_in_progress_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(\U0/AHB_IF_n_12 )
    );
    defparam \U0/AHB_IF/dummy_txfer_in_progress_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/idle_txfer_pending_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_14 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(\U0/idle_txfer_pending )
    );
    defparam \U0/AHB_IF/idle_txfer_pending_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/nonseq_txfer_pending_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_15 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/nonseq_txfer_pending )
    );
    defparam \U0/AHB_IF/nonseq_txfer_pending_i_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_IF/valid_cnt_required_i[2]_i_1 
    (
    .I0(s_ahb_hburst[2]),
    .I1(s_ahb_hsel),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_htrans[0]),
    .I4(s_ahb_htrans[1]),
    .I5(\U0/valid_cnt_required[2] ),
    .O(\U0/AHB_IF/valid_cnt_required_i[2]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i[2]_i_1 .INIT = 64'HFFBFFFFF00800000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/valid_cnt_required_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/valid_cnt_required_i[1]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/valid_cnt_required[1] )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/valid_cnt_required_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/valid_cnt_required_i[2]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/valid_cnt_required[2] )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/valid_cnt_required_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/valid_cnt_required_i[3]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/valid_cnt_required[3] )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i_reg[3] .INIT = 1'B0;
    xsLUTSA6_2 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_18 
    (
    .I0(\U0/axi_waddr_done_i ),
    .I1(\U0/ahb_hburst_incr ),
    .I2(\U0/ahb_hburst_single ),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/AHB_IF/AHBLITE_AXI_CONTROL/reset_hready2__0 ),
    .O5(\U0/M_AXI_WLAST_i110_out )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_18 .INIT = 64'HFCFCFCFCA8A8A8A8;
    xsLUTSA6_2 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_19 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/AHB_IF/AHBLITE_AXI_CONTROL/hburst_single_incr ),
    .O5(\U0/AHB_IF/AXI_ALEN_i[1] )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_19 .INIT = 64'H11111111EEEEEEEE;
    xsLUTSA6_2 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_15 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I2(\U0/burst_term_single_incr ),
    .I3(\U0/burst_term_hwrite ),
    .I4(s_ahb_hwrite),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/reset_hready010_out ),
    .O5(\U0/AHB_IF/AXI_ALEN_i[3] )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_15 .INIT = 64'HF1FFFFFF88888888;
    xsLUTSA6_2 \U0/AHB_IF/S_AHB_HRESP_i_i_9 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_hready_in),
    .I2(s_ahb_hsel),
    .I3(s_ahb_htrans[0]),
    .I4(\U0/nonseq_txfer_pending ),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/ctl_sm_ns14_out ),
    .O5(\U0/busy_detected )
    );
    defparam \U0/AHB_IF/S_AHB_HRESP_i_i_9 .INIT = 64'HFFFF008040004000;
    xsLUTSA6_2 \U0/AHB_IF/valid_cnt_required_i[3]_i_2 
    (
    .I0(\U0/AHB_IF_n_3 ),
    .I1(s_ahb_htrans[1]),
    .I2(s_ahb_hsel),
    .I3(s_ahb_hready_in),
    .I4(s_ahb_htrans[0]),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/nonseq_detected ),
    .O5(\U0/ahb_burst_done )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i[3]_i_2 .INIT = 64'H0000C00080000000;
    xsLUTSA6_2 \U0/AHB_IF/ahb_penult_beat_i_3 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_hsel),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_htrans[0]),
    .I4(\U0/ahb_hburst_incr ),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/p_27_in ),
    .O5(\U0/AHB_IF/S_AHB_HREADY_OUT_i_i_8_n_0 )
    );
    defparam \U0/AHB_IF/ahb_penult_beat_i_3 .INIT = 64'HC0C0C0C080000000;
    xsLUTSA6_2 \U0/AHB_IF/valid_cnt_required_i[3]_i_1 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/valid_cnt_required[1] ),
    .I4(\U0/valid_cnt_required[3] ),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/AHB_IF/valid_cnt_required_i[3]_i_1_n_0 ),
    .O5(\U0/AHB_IF/valid_cnt_required_i[1]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i[3]_i_1 .INIT = 64'H8F8F8080EFE0EFE0;
    xsLUTSA6_2 \U0/AHB_IF/ahb_hburst_single_i_i_2 
    (
    .I0(s_ahb_hburst[2]),
    .I1(s_ahb_hburst[0]),
    .I2(s_ahb_hburst[1]),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/AHB_IF/eqOp0_in ),
    .O5(\U0/AHB_IF/eqOp )
    );
    defparam \U0/AHB_IF/ahb_hburst_single_i_i_2 .INIT = 64'H0101010104040404;
    xs0 \U0/AXI_RCHANNEL/GND 
    (
    .G(\U0/AXI_RCHANNEL/<const0> )
    );
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/M_AXI_ARVALID_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_11 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arvalid)
    );
    defparam \U0/AXI_RCHANNEL/M_AXI_ARVALID_i_reg .INIT = 1'B0;
    xsLUTSA4 \U0/AXI_RCHANNEL/M_AXI_RLAST_reg_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/axi_last_avlbl_reg_n_0 ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I2(m_axi_rlast),
    .I3(m_axi_rvalid),
    .O(\U0/last_axi_rd_sample )
    );
    defparam \U0/AXI_RCHANNEL/M_AXI_RLAST_reg_i_1 .INIT = 16'HBAAA;
    xsLUTSA6 \U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1 
    (
    .I0(m_axi_arvalid),
    .I1(m_axi_arready),
    .I2(\U0/seq_detected ),
    .I3(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_7 ),
    .I5(m_axi_rready),
    .O(\U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1 .INIT = 64'H8888FFFF8888FFF8;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/M_AXI_RREADY_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_rready)
    );
    defparam \U0/AXI_RCHANNEL/M_AXI_RREADY_i_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_10 
    (
    .I0(\U0/ctl_sm_ns033_out ),
    .I1(\U0/reset_hready010_out ),
    .I2(\U0/ctl_sm_ns14_out ),
    .I3(\U0/AXI_RCHANNEL/rvalid_rready ),
    .I4(\U0/ctl_sm_ns1 ),
    .I5(\U0/idle_txfer_pending ),
    .O(\U0/AXI_RCHANNEL_n_5 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_10 .INIT = 64'H808080808F8F808F;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_16 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I2(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I3(m_axi_rready),
    .I4(m_axi_rvalid),
    .I5(\U0/busy_detected ),
    .O(\U0/AXI_RCHANNEL/rvalid_rready )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_16 .INIT = 64'H888888888F888888;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_21 
    (
    .I0(m_axi_rresp[1]),
    .I1(\U0/rd_load_timeout_cntr ),
    .I2(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I3(\U0/busy_detected ),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_txer_pending07_out__0 ),
    .I5(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1] ),
    .O(\U0/AXI_RCHANNEL_n_3 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_21 .INIT = 64'H00040004FFF70004;
    xsLUTSA2 \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_10 
    (
    .I0(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I1(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .O(\U0/AXI_RCHANNEL/ahb_rd_txer_pending07_out__0 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_10 .INIT = 4'H8;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_7 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1] ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending07_out__0 ),
    .I2(\U0/busy_detected ),
    .I3(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I4(\U0/rd_load_timeout_cntr ),
    .I5(m_axi_rresp[1]),
    .O(\U0/ctl_sm_ns1 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_7 .INIT = 64'H888F888888808888;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_8 
    (
    .I0(\U0/busy_detected ),
    .I1(\U0/rd_load_timeout_cntr ),
    .I2(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I3(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I4(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I5(\U0/last_axi_rd_sample ),
    .O(\U0/ctl_sm_ns033_out )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_8 .INIT = 64'HFF04040400000000;
    xs1 \U0/AXI_RCHANNEL/VCC 
    (
    .P(\U0/AXI_RCHANNEL/<const1> )
    );
    xsLUTSA6 \U0/AXI_RCHANNEL/ahb_rd_req_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/seq_detected_d1 ),
    .I1(\U0/seq_detected ),
    .I2(s_ahb_hresetn),
    .I3(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I5(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .O(\U0/AXI_RCHANNEL/ahb_rd_req_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/ahb_rd_req_i_1 .INIT = 64'H00F04040B0B00000;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/ahb_rd_req_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/ahb_rd_req_i_1_n_0 ),
    .R(\U0/AXI_RCHANNEL/<const0> ),
    .Q(\U0/AXI_RCHANNEL/ahb_rd_req )
    );
    defparam \U0/AXI_RCHANNEL/ahb_rd_req_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I1(\U0/AXI_RCHANNEL/bridge_rd_in_progress ),
    .I2(\U0/busy_detected ),
    .I3(s_ahb_hresetn),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I5(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .O(\U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1 .INIT = 64'H0000EA00EA00EA00;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/ahb_rd_txer_pending_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1_n_0 ),
    .R(\U0/AXI_RCHANNEL/<const0> ),
    .Q(\U0/AXI_RCHANNEL/ahb_rd_txer_pending )
    );
    defparam \U0/AXI_RCHANNEL/ahb_rd_txer_pending_reg .INIT = 1'B0;
    xsLUTSA3 \U0/AXI_RCHANNEL/axi_last_avlbl_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I2(s_ahb_hresetn),
    .O(\U0/AXI_RCHANNEL/axi_last_avlbl_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_last_avlbl_i_1 .INIT = 8'H8F;
    xsLUTSA6 \U0/AXI_RCHANNEL/axi_last_avlbl_i_2 
    (
    .I0(m_axi_rlast),
    .I1(m_axi_rready),
    .I2(m_axi_rvalid),
    .I3(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I4(\U0/busy_detected ),
    .I5(\U0/AXI_RCHANNEL/axi_last_avlbl_reg_n_0 ),
    .O(\U0/AXI_RCHANNEL/axi_last_avlbl_i_2_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_last_avlbl_i_2 .INIT = 64'HBFBFBFFF80808000;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/axi_last_avlbl_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/axi_last_avlbl_i_2_n_0 ),
    .R(\U0/AXI_RCHANNEL/axi_last_avlbl_i_1_n_0 ),
    .Q(\U0/AXI_RCHANNEL/axi_last_avlbl_reg_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_last_avlbl_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_RCHANNEL/axi_rd_avlbl_i_1 
    (
    .I0(\U0/rd_load_timeout_cntr ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I2(\U0/busy_detected ),
    .I3(s_ahb_hresetn),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I5(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .O(\U0/AXI_RCHANNEL/axi_rd_avlbl_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_rd_avlbl_i_1 .INIT = 64'H0000FF00A800A800;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/axi_rd_avlbl_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/axi_rd_avlbl_i_1_n_0 ),
    .R(\U0/AXI_RCHANNEL/<const0> ),
    .Q(\U0/AXI_RCHANNEL/axi_rd_avlbl )
    );
    defparam \U0/AXI_RCHANNEL/axi_rd_avlbl_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1] ),
    .I1(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2_n_0 ),
    .I2(m_axi_rresp[1]),
    .I3(s_ahb_hresetn),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I5(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .O(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1 .INIT = 64'H0000E200E200E200;
    xsLUTSA6 \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2 
    (
    .I0(\U0/rd_load_timeout_cntr ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I2(s_ahb_htrans[1]),
    .I3(s_ahb_hready_in),
    .I4(s_ahb_hsel),
    .I5(s_ahb_htrans[0]),
    .O(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2 .INIT = 64'H8A88888888888888;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/axi_rresp_avlbl_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1_n_0 ),
    .R(\U0/AXI_RCHANNEL/<const0> ),
    .Q(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1] )
    );
    defparam \U0/AXI_RCHANNEL/axi_rresp_avlbl_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/bridge_rd_in_progress_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_RCHANNEL/bridge_rd_in_progress )
    );
    defparam \U0/AXI_RCHANNEL/bridge_rd_in_progress_reg .INIT = 1'B0;
    xsLUTSA4 \U0/AXI_RCHANNEL/seq_detected_d1_i_1 
    (
    .I0(s_ahb_htrans[0]),
    .I1(s_ahb_hready_in),
    .I2(s_ahb_hsel),
    .I3(s_ahb_htrans[1]),
    .O(\U0/seq_detected )
    );
    defparam \U0/AXI_RCHANNEL/seq_detected_d1_i_1 .INIT = 16'H8000;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/seq_detected_d1_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/seq_detected ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_RCHANNEL/seq_detected_d1 )
    );
    defparam \U0/AXI_RCHANNEL/seq_detected_d1_reg .INIT = 1'B0;
    xsLUTSA6_2 \U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1 
    (
    .I0(m_axi_rready),
    .I1(m_axi_rvalid),
    .I2(m_axi_rlast),
    .I3(m_axi_arvalid),
    .I4(\U0/AXI_RCHANNEL/bridge_rd_in_progress ),
    .I5(\U0/AXI_RCHANNEL/<const1> ),
    .O6(\U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1_n_0 ),
    .O5(\U0/M_AXI_RREADY_i5__0 )
    );
    defparam \U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1 .INIT = 64'HFF7FFF0080808080;
    xsLUTSA6_2 \U0/AXI_RCHANNEL/S_AHB_HRDATA_i[31]_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I2(m_axi_rvalid),
    .I3(m_axi_rready),
    .I5(\U0/AXI_RCHANNEL/<const1> ),
    .O6(\U0/rd_load_timeout_cntr ),
    .O5(\U0/AXI_RCHANNEL_n_10 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HRDATA_i[31]_i_1 .INIT = 64'HF000F000EAAAEAAA;
    xs0 \U0/AXI_WCHANNEL/GND 
    (
    .G(\U0/AXI_WCHANNEL/<const0> )
    );
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_AWVALID_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_12 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_awvalid)
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_AWVALID_i_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_BREADY_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_19 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_bready)
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_BREADY_i_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[0]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[0] ),
    .I1(s_ahb_hwdata[0]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[0] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[0]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[10]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[10] ),
    .I1(s_ahb_hwdata[10]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[10] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[10]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[11]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[11] ),
    .I1(s_ahb_hwdata[11]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[11] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[11]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[12]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[12] ),
    .I1(s_ahb_hwdata[12]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[12] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[12]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[13]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[13] ),
    .I1(s_ahb_hwdata[13]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[13] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[13]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[14]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[14] ),
    .I1(s_ahb_hwdata[14]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[14] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[14]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[16]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[16] ),
    .I1(s_ahb_hwdata[16]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[16] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[16]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[17]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[17] ),
    .I1(s_ahb_hwdata[17]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[17] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[17]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[18]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[18] ),
    .I1(s_ahb_hwdata[18]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[18] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[18]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[19]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[19] ),
    .I1(s_ahb_hwdata[19]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[19] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[19]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[1]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[1] ),
    .I1(s_ahb_hwdata[1]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[1] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[1]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[20]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[20] ),
    .I1(s_ahb_hwdata[20]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[20] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[20]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[21]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[21] ),
    .I1(s_ahb_hwdata[21]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[21] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[21]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[22]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[22] ),
    .I1(s_ahb_hwdata[22]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[22] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[22]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[23]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[23] ),
    .I1(s_ahb_hwdata[23]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[23] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[23]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[24]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[24] ),
    .I1(s_ahb_hwdata[24]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[24] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[24]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[25]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[25] ),
    .I1(s_ahb_hwdata[25]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[25] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[25]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[26]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[26] ),
    .I1(s_ahb_hwdata[26]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[26] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[26]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[27]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[27] ),
    .I1(s_ahb_hwdata[27]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[27] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[27]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[28]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[28] ),
    .I1(s_ahb_hwdata[28]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[28] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[28]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[29]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[29] ),
    .I1(s_ahb_hwdata[29]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[29] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[29]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[2]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[2] ),
    .I1(s_ahb_hwdata[2]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[2] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[2]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[30]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[30] ),
    .I1(s_ahb_hwdata[30]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[30] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[30]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA2 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1 
    (
    .I0(m_axi_wvalid),
    .I1(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1 .INIT = 4'HD;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_2 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[31] ),
    .I1(s_ahb_hwdata[31]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[31] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_2 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[3]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[3] ),
    .I1(s_ahb_hwdata[3]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[3] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[3]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[4]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[4] ),
    .I1(s_ahb_hwdata[4]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[4] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[4]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[5]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[5] ),
    .I1(s_ahb_hwdata[5]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[5] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[5]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[6]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[6] ),
    .I1(s_ahb_hwdata[6]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[6] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[6]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[7]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[7] ),
    .I1(s_ahb_hwdata[7]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[7] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[7]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[8]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[8] ),
    .I1(s_ahb_hwdata[8]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[8] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[8]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[9]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[9] ),
    .I1(s_ahb_hwdata[9]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[9] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[9]_i_1 .INIT = 32'HACACCCAC;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[0] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[0])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[10] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[10] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[10])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[10] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[11] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[11] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[11])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[11] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[12] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[12] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[12])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[12] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[13] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[13] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[13])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[13] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[14] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[14] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[14])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[14] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[15] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[15] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[15])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[15] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[16] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[16] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[16])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[16] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[17] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[17] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[17])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[17] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[18] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[18] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[18])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[18] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[19] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[19] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[19])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[19] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[1] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[1])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[20] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[20] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[20])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[20] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[21] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[21] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[21])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[21] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[22] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[22] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[22])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[22] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[23] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[23] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[23])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[23] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[24] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[24] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[24])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[24] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[25] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[25] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[25])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[25] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[26] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[26] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[26])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[26] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[27] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[27] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[27])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[27] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[28] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[28] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[28])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[28] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[29] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[29] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[29])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[29] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[2] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[2])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[30] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[30] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[30])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[30] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[31] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[31] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[31])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[31] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[3] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[3])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[4] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[4])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[5] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[5] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[5])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[5] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[6] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[6] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[6])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[6] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[7] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[7] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[7])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[7] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[8] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[8] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[8])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[8] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[9] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[9] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[9])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[9] .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/M_AXI_WLAST_i__1 ),
    .I1(\U0/M_AXI_WLAST_i110_out ),
    .I2(m_axi_wlast),
    .I3(m_axi_wready),
    .I4(\U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 ),
    .I5(\U0/AXI_WCHANNEL/axi_last_beat_reg_n_0 ),
    .O(\U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1 .INIT = 64'HCEFECEFECEFECCFC;
    xsLUTSA6 \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_2 
    (
    .I0(m_axi_wready),
    .I1(m_axi_wvalid),
    .I2(\U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 ),
    .I3(\U0/local_en ),
    .I4(\U0/ahb_data_valid ),
    .I5(\U0/burst_term ),
    .O(\U0/AXI_WCHANNEL/M_AXI_WLAST_i__1 )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_2 .INIT = 64'H8F8F8F8F8F8F8F00;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WLAST_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wlast)
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WLAST_i_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1 
    (
    .I0(m_axi_wvalid),
    .I1(\U0/AXI_WCHANNEL/dummy_on_axi__0 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_10 ),
    .I3(s_ahb_hresetn),
    .I4(m_axi_wready),
    .I5(m_axi_wlast),
    .O(\U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1 .INIT = 64'H0000FE00FC00FE00;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WVALID_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1_n_0 ),
    .R(\U0/AXI_WCHANNEL/<const0> ),
    .Q(m_axi_wvalid)
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WVALID_i_reg .INIT = 1'B0;
    xsDFFSA_K1S1E1 \U0/AXI_WCHANNEL/NARROW_TRANSFER_OFF.M_AXI_WSTRB_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_5 ),
    .S(\U0/cntr_rst ),
    .Q(m_axi_wstrb[3])
    );
    defparam \U0/AXI_WCHANNEL/NARROW_TRANSFER_OFF.M_AXI_WSTRB_i_reg[3] .INIT = 1'B1;
    xs1 \U0/AXI_WCHANNEL/VCC 
    (
    .P(\U0/AXI_WCHANNEL/<const1> )
    );
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/ahb_data_valid_burst_term_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AHB_IF_n_39 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_data_valid_burst_term )
    );
    defparam \U0/AXI_WCHANNEL/ahb_data_valid_burst_term_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AXI_WCHANNEL/ahb_data_valid_i_i_1 
    (
    .I0(\U0/local_en ),
    .I1(\U0/AXI_WCHANNEL_n_12 ),
    .I2(\U0/ahb_data_valid ),
    .I3(\U0/p_27_in ),
    .I4(s_ahb_htrans[1]),
    .O(\U0/AXI_WCHANNEL_n_14 )
    );
    defparam \U0/AXI_WCHANNEL/ahb_data_valid_i_i_1 .INIT = 32'HFF200020;
    xsLUTSA3 \U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1 
    (
    .I0(\U0/valid_cnt_required[2] ),
    .I1(\U0/axi_waddr_done_i ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[2] ),
    .O(\U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1 .INIT = 8'HB8;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_cnt_required_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/axi_cnt_required[1]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/axi_cnt_required[1] )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_cnt_required_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/axi_cnt_required[2] )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_cnt_required_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/axi_cnt_required[3] )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_last_beat_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_8 ),
    .R(\U0/AXI_WCHANNEL/<const0> ),
    .Q(\U0/AXI_WCHANNEL/axi_last_beat_reg_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/axi_last_beat_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_penult_beat_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_7 ),
    .R(\U0/AXI_WCHANNEL/<const0> ),
    .Q(\U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/axi_penult_beat_reg .INIT = 1'B0;
    xsLUTSA3 \U0/AXI_WCHANNEL/burst_term_i_i_3 
    (
    .I0(m_axi_wlast),
    .I1(m_axi_wready),
    .I2(\U0/AHB_IF_n_12 ),
    .O(\U0/AXI_WCHANNEL_n_13 )
    );
    defparam \U0/AXI_WCHANNEL/burst_term_i_i_3 .INIT = 8'HF8;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/dummy_on_axi_progress_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_9 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/dummy_on_axi_progress )
    );
    defparam \U0/AXI_WCHANNEL/dummy_on_axi_progress_reg .INIT = 1'B0;
    xsLUTSA4 \U0/AXI_WCHANNEL/local_en_i_1 
    (
    .I0(m_axi_wvalid),
    .I1(\U0/ahb_data_valid ),
    .I2(\U0/local_en ),
    .I3(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/local_en_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/local_en_i_1 .INIT = 16'H80F8;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_en_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/local_en_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/local_en )
    );
    defparam \U0/AXI_WCHANNEL/local_en_reg .INIT = 1'B0;
    xsLUTSA4 \U0/AXI_WCHANNEL/local_wdata[31]_i_1 
    (
    .I0(m_axi_wready),
    .I1(m_axi_wvalid),
    .I2(\U0/ahb_data_valid ),
    .I3(\U0/local_en ),
    .O(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata[31]_i_1 .INIT = 16'H80FF;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[0]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[0] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[10] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[10]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[10] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[10] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[11] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[11]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[11] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[11] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[12] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[12]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[12] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[12] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[13] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[13]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[13] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[13] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[14] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[14]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[14] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[14] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[15] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[15]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[15] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[15] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[16] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[16]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[16] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[16] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[17] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[17]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[17] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[17] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[18] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[18]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[18] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[18] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[19] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[19]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[19] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[19] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[1]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[1] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[20] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[20]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[20] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[20] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[21] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[21]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[21] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[21] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[22] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[22]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[22] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[22] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[23] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[23]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[23] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[23] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[24] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[24]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[24] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[24] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[25] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[25]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[25] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[25] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[26] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[26]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[26] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[26] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[27] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[27]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[27] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[27] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[28] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[28]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[28] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[28] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[29] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[29]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[29] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[29] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[2]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[2] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[30] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[30]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[30] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[30] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[31] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[31]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[31] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[31] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[3]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[3] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[4]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[4] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[5] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[5]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[5] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[5] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[6] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[6]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[6] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[6] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[7] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[7]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[7] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[7] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[8] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[8]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[8] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[8] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[9] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[9]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[9] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[9] .INIT = 1'B0;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/ahb_data_valid_i_i_2 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[15] ),
    .I1(s_ahb_hwdata[15]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .I5(\U0/AXI_WCHANNEL/<const1> ),
    .O6(\U0/AXI_WCHANNEL_n_12 ),
    .O5(\U0/AXI_WCHANNEL/p_1_in[15] )
    );
    defparam \U0/AXI_WCHANNEL/ahb_data_valid_i_i_2 .INIT = 64'HFFFF00FFACACCCAC;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1 
    (
    .I0(\U0/valid_cnt_required[1] ),
    .I1(\U0/axi_waddr_done_i ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[1] ),
    .I3(\U0/valid_cnt_required[3] ),
    .I4(\U0/AXI_WCHANNEL/axi_cnt_required[3] ),
    .I5(\U0/AXI_WCHANNEL/<const1> ),
    .O6(\U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1_n_0 ),
    .O5(\U0/AXI_WCHANNEL/axi_cnt_required[1]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1 .INIT = 64'HFF33CC00B8B8B8B8;
    xsLUTSA5 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_hsel),
    .I4(\U0/AHB_DATA_COUNTER_n_4 ),
    .O(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0 .INIT = 32'H2000FFFF;
    xsLUTSA6 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_hsel),
    .I4(\U0/AHB_DATA_COUNTER_n_3 ),
    .I5(\U0/AHB_DATA_COUNTER_n_4 ),
    .O(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0 .INIT = 64'H0000DFFFDFFF0000;
    xsLUTSA6 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0 
    (
    .I0(\U0/AHB_DATA_COUNTER_n_1 ),
    .I1(\U0/AHB_DATA_COUNTER_n_0 ),
    .I2(\U0/AHB_DATA_COUNTER_n_2 ),
    .I3(\U0/AHB_DATA_COUNTER_n_4 ),
    .I4(\U0/AHB_DATA_COUNTER_n_3 ),
    .I5(\U0/nonseq_detected ),
    .O(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0 .INIT = 64'H000000006CCCCCCC;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_4 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_3 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_2 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_1 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[4] .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_2 
    (
    .I0(\U0/AHB_DATA_COUNTER_n_1 ),
    .I1(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4_n_0 ),
    .I2(\U0/valid_cnt_required[3] ),
    .I3(\U0/valid_cnt_required[1] ),
    .I4(\U0/valid_cnt_required[2] ),
    .I5(\U0/AHB_DATA_COUNTER_n_0 ),
    .O(\U0/AHB_DATA_COUNTER_n_5 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_2 .INIT = 64'H0000000884848440;
    xsLUTSA5 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4 
    (
    .I0(\U0/AHB_DATA_COUNTER_n_4 ),
    .I1(\U0/valid_cnt_required[2] ),
    .I2(\U0/valid_cnt_required[1] ),
    .I3(\U0/AHB_DATA_COUNTER_n_2 ),
    .I4(\U0/AHB_DATA_COUNTER_n_3 ),
    .O(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4 .INIT = 32'H42180000;
    xsLUTSA6_2 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0 
    (
    .I0(\U0/AHB_DATA_COUNTER_n_3 ),
    .I1(\U0/AHB_DATA_COUNTER_n_2 ),
    .I2(\U0/AHB_DATA_COUNTER_n_4 ),
    .I3(\U0/nonseq_detected ),
    .I4(\U0/AHB_DATA_COUNTER_n_1 ),
    .I5(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0_n_0 ),
    .O5(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1__0_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0 .INIT = 64'H007F0080006C006C;
    xs1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/VCC 
    (
    .P(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/GLOBAL_LOGIC1 )
    );
    xsLUTSA3 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1 
    (
    .I0(\U0/set_axi_waddr ),
    .I1(\U0/AXI_WCHANNEL_n_9 ),
    .I2(\U0/AXI_WCHANNEL_n_10 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1 .INIT = 8'H14;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL_n_6 ),
    .I2(\U0/AXI_WCHANNEL_n_8 ),
    .I3(\U0/AXI_WCHANNEL_n_10 ),
    .I4(\U0/AXI_WCHANNEL_n_9 ),
    .I5(\U0/set_axi_waddr ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2 .INIT = 64'H000000006CCCCCCC;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_4 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_10 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_9 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_8 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_7 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_6 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[4] .INIT = 1'B0;
    xsLUTSA1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/NARROW_TRANSFER_OFF.M_AXI_WSTRB_i[3]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/dummy_on_axi__0 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_5 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/NARROW_TRANSFER_OFF.M_AXI_WSTRB_i[3]_i_1 .INIT = 2'H1;
    xsLUTSA5 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/axi_last_beat_reg_n_0 ),
    .I1(s_ahb_hresetn),
    .I2(m_axi_wready),
    .I3(m_axi_wvalid),
    .I4(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_2_n_0 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_8 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_1 .INIT = 32'H0888C000;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_3 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_5_n_0 ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[3] ),
    .I3(\U0/AXI_WCHANNEL/axi_cnt_required[1] ),
    .I4(\U0/AXI_WCHANNEL/axi_cnt_required[2] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp__5 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_3 .INIT = 64'H0000000884848440;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_4 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_6_n_0 ),
    .I2(\U0/burst_term_txer_cnt[3] ),
    .I3(\U0/burst_term_txer_cnt[1] ),
    .I4(\U0/burst_term_txer_cnt[2] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp1_out )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_4 .INIT = 64'H0000000884848440;
    xsLUTSA5 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 ),
    .I1(s_ahb_hresetn),
    .I2(m_axi_wready),
    .I3(m_axi_wvalid),
    .I4(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2_n_0 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_7 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_1 .INIT = 32'H0888C000;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_3 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5_n_0 ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[3] ),
    .I3(\U0/AXI_WCHANNEL/axi_cnt_required[1] ),
    .I4(\U0/AXI_WCHANNEL/axi_cnt_required[2] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp3_out )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_3 .INIT = 64'H0000000884848440;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_4 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6_n_0 ),
    .I2(\U0/burst_term_txer_cnt[3] ),
    .I3(\U0/burst_term_txer_cnt[1] ),
    .I4(\U0/burst_term_txer_cnt[2] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp5_out )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_4 .INIT = 64'H0000000884848440;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_2 
    (
    .I0(\U0/AXI_WCHANNEL/dummy_on_axi_progress ),
    .I1(\U0/eqOp6_out ),
    .I2(m_axi_wvalid),
    .I3(m_axi_wready),
    .I4(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp8_out ),
    .I5(\U0/burst_term ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_init )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_2 .INIT = 64'H5444444400000000;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_4 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6_n_0 ),
    .I2(\U0/burst_term_cur_cnt[4] ),
    .I3(\U0/AHB_IF_n_32 ),
    .I4(\U0/burst_term_cur_cnt[3] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp8_out )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_4 .INIT = 64'H8040400808040480;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6 
    (
    .I0(\U0/AXI_WCHANNEL_n_10 ),
    .I1(\U0/burst_term_cur_cnt[2] ),
    .I2(\U0/burst_term_cur_cnt[0] ),
    .I3(\U0/burst_term_cur_cnt[1] ),
    .I4(\U0/AXI_WCHANNEL_n_8 ),
    .I5(\U0/AXI_WCHANNEL_n_9 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6 .INIT = 64'H4002100808400210;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5 
    (
    .I0(\U0/AXI_WCHANNEL_n_10 ),
    .I1(\U0/AXI_WCHANNEL/axi_cnt_required[2] ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[1] ),
    .I3(\U0/AXI_WCHANNEL_n_8 ),
    .I4(\U0/AXI_WCHANNEL_n_9 ),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5_n_0 ),
    .O5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_5_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5 .INIT = 64'H0104802042180000;
    xs1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/VCC 
    (
    .P(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 )
    );
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6 
    (
    .I0(\U0/AXI_WCHANNEL_n_10 ),
    .I1(\U0/burst_term_txer_cnt[2] ),
    .I2(\U0/burst_term_txer_cnt[1] ),
    .I3(\U0/AXI_WCHANNEL_n_8 ),
    .I4(\U0/AXI_WCHANNEL_n_9 ),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6_n_0 ),
    .O5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_6_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6 .INIT = 64'H0104802042180000;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL_n_9 ),
    .I1(\U0/AXI_WCHANNEL_n_8 ),
    .I2(\U0/AXI_WCHANNEL_n_10 ),
    .I3(\U0/set_axi_waddr ),
    .I4(\U0/AXI_WCHANNEL_n_7 ),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1_n_0 ),
    .O5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1 .INIT = 64'H007F0080006C006C;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_init ),
    .I1(\U0/AXI_WCHANNEL/dummy_on_axi_progress ),
    .I2(m_axi_wlast),
    .I3(m_axi_wready),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_9 ),
    .O5(\U0/AXI_WCHANNEL/dummy_on_axi__0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_1 .INIT = 64'HAEEEAEEEEEEEEEEE;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2 
    (
    .I0(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp__5 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp1_out ),
    .I2(\U0/burst_term ),
    .I3(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp3_out ),
    .I4(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp5_out ),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2_n_0 ),
    .O5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_2_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2 .INIT = 64'H000F00FF15151515;
    assign m_axi_aclk = s_ahb_hclk; 
    assign m_axi_aresetn = s_ahb_hresetn; 
    assign m_axi_awlock = m_axi_arlock; 
    assign m_axi_arcache[3] = m_axi_arlock; 
    assign m_axi_arcache[2] = m_axi_arlock; 
    assign m_axi_arid[3] = m_axi_arlock; 
    assign m_axi_arid[2] = m_axi_arlock; 
    assign m_axi_arid[1] = m_axi_arlock; 
    assign m_axi_arid[0] = m_axi_arlock; 
    assign m_axi_arlen[7] = m_axi_arlock; 
    assign m_axi_arlen[6] = m_axi_arlock; 
    assign m_axi_arlen[5] = m_axi_arlock; 
    assign m_axi_arlen[4] = m_axi_arlock; 
    assign m_axi_arlen[0] = m_axi_arlen[1]; 
    assign m_axi_awaddr[31] = m_axi_araddr[31]; 
    assign m_axi_awaddr[30] = m_axi_araddr[30]; 
    assign m_axi_awaddr[29] = m_axi_araddr[29]; 
    assign m_axi_awaddr[28] = m_axi_araddr[28]; 
    assign m_axi_awaddr[27] = m_axi_araddr[27]; 
    assign m_axi_awaddr[26] = m_axi_araddr[26]; 
    assign m_axi_awaddr[25] = m_axi_araddr[25]; 
    assign m_axi_awaddr[24] = m_axi_araddr[24]; 
    assign m_axi_awaddr[23] = m_axi_araddr[23]; 
    assign m_axi_awaddr[22] = m_axi_araddr[22]; 
    assign m_axi_awaddr[21] = m_axi_araddr[21]; 
    assign m_axi_awaddr[20] = m_axi_araddr[20]; 
    assign m_axi_awaddr[19] = m_axi_araddr[19]; 
    assign m_axi_awaddr[18] = m_axi_araddr[18]; 
    assign m_axi_awaddr[17] = m_axi_araddr[17]; 
    assign m_axi_awaddr[16] = m_axi_araddr[16]; 
    assign m_axi_awaddr[15] = m_axi_araddr[15]; 
    assign m_axi_awaddr[14] = m_axi_araddr[14]; 
    assign m_axi_awaddr[13] = m_axi_araddr[13]; 
    assign m_axi_awaddr[12] = m_axi_araddr[12]; 
    assign m_axi_awaddr[11] = m_axi_araddr[11]; 
    assign m_axi_awaddr[10] = m_axi_araddr[10]; 
    assign m_axi_awaddr[9] = m_axi_araddr[9]; 
    assign m_axi_awaddr[8] = m_axi_araddr[8]; 
    assign m_axi_awaddr[7] = m_axi_araddr[7]; 
    assign m_axi_awaddr[6] = m_axi_araddr[6]; 
    assign m_axi_awaddr[5] = m_axi_araddr[5]; 
    assign m_axi_awaddr[4] = m_axi_araddr[4]; 
    assign m_axi_awaddr[3] = m_axi_araddr[3]; 
    assign m_axi_awaddr[2] = m_axi_araddr[2]; 
    assign m_axi_awaddr[1] = m_axi_araddr[1]; 
    assign m_axi_awaddr[0] = m_axi_araddr[0]; 
    assign m_axi_awburst[1] = m_axi_arburst[1]; 
    assign m_axi_awburst[0] = m_axi_arburst[0]; 
    assign m_axi_awcache[3] = m_axi_arlock; 
    assign m_axi_awcache[2] = m_axi_arlock; 
    assign m_axi_awcache[1] = m_axi_arcache[1]; 
    assign m_axi_awcache[0] = m_axi_arcache[0]; 
    assign m_axi_awid[3] = m_axi_arlock; 
    assign m_axi_awid[2] = m_axi_arlock; 
    assign m_axi_awid[1] = m_axi_arlock; 
    assign m_axi_awid[0] = m_axi_arlock; 
    assign m_axi_awlen[7] = m_axi_arlock; 
    assign m_axi_awlen[6] = m_axi_arlock; 
    assign m_axi_awlen[5] = m_axi_arlock; 
    assign m_axi_awlen[4] = m_axi_arlock; 
    assign m_axi_awlen[3] = m_axi_arlen[3]; 
    assign m_axi_awlen[2] = m_axi_arlen[2]; 
    assign m_axi_awlen[1] = m_axi_arlen[1]; 
    assign m_axi_awlen[0] = m_axi_arlen[1]; 
    assign m_axi_awprot[2] = m_axi_arprot[2]; 
    assign m_axi_awprot[1] = m_axi_arprot[1]; 
    assign m_axi_awprot[0] = m_axi_arprot[0]; 
    assign m_axi_awsize[2] = m_axi_arsize[2]; 
    assign m_axi_awsize[1] = m_axi_arsize[1]; 
    assign m_axi_awsize[0] = m_axi_arsize[0]; 
    assign m_axi_wstrb[2] = m_axi_wstrb[3]; 
    assign m_axi_wstrb[1] = m_axi_wstrb[3]; 
    assign m_axi_wstrb[0] = m_axi_wstrb[3]; 
endmodule
/*
Copyright (c) 2018 Alex Forencich
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
`resetall
`timescale 1ns / 1ps
`default_nettype none
/*
 * AXI4 lite interconnect
 */
module axil_interconnect #
(
    parameter S_COUNT = 2,
    parameter M_COUNT = 2,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (4),
    parameter M_REGIONS = 1,
    parameter M_BASE_ADDR = 0,
    parameter M_ADDR_WIDTH = {M_COUNT{{M_REGIONS{32'd30}}}},     
    parameter M_CONNECT_READ = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter M_CONNECT_WRITE = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter M_SECURE = {M_COUNT{1'b0}}    
)
(
    input  wire                           clk,
    input  wire                           rst,
    /*
    * AXI lite slave interfaces
    */
    input  wire [S_COUNT*ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [S_COUNT*3-1:0]           s_axil_awprot,
    input  wire [S_COUNT-1:0]             s_axil_awvalid,
    output wire [S_COUNT-1:0]             s_axil_awready,
    input  wire [S_COUNT*DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [S_COUNT*STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire [S_COUNT-1:0]             s_axil_wvalid,
    output wire [S_COUNT-1:0]             s_axil_wready,
    output wire [S_COUNT*2-1:0]           s_axil_bresp,
    output wire [S_COUNT-1:0]             s_axil_bvalid,
    input  wire [S_COUNT-1:0]             s_axil_bready,
    input  wire [S_COUNT*ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [S_COUNT*3-1:0]           s_axil_arprot,
    input  wire [S_COUNT-1:0]             s_axil_arvalid,
    output wire [S_COUNT-1:0]             s_axil_arready,
    output wire [S_COUNT*DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [S_COUNT*2-1:0]           s_axil_rresp,
    output wire [S_COUNT-1:0]             s_axil_rvalid,
    input  wire [S_COUNT-1:0]             s_axil_rready,
    /*
    * AXI lite master interfaces
    */
    output wire [M_COUNT*ADDR_WIDTH-1:0]  m_axil_awaddr,
    output wire [M_COUNT*3-1:0]           m_axil_awprot,
    output wire [M_COUNT-1:0]             m_axil_awvalid,
    input  wire [M_COUNT-1:0]             m_axil_awready,
    output wire [M_COUNT*DATA_WIDTH-1:0]  m_axil_wdata,
    output wire [M_COUNT*STRB_WIDTH-1:0]  m_axil_wstrb,
    output wire [M_COUNT-1:0]             m_axil_wvalid,
    input  wire [M_COUNT-1:0]             m_axil_wready,
    input  wire [M_COUNT*2-1:0]           m_axil_bresp,
    input  wire [M_COUNT-1:0]             m_axil_bvalid,
    output wire [M_COUNT-1:0]             m_axil_bready,
    output wire [M_COUNT*ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [M_COUNT*3-1:0]           m_axil_arprot,
    output wire [M_COUNT-1:0]             m_axil_arvalid,
    input  wire [M_COUNT-1:0]             m_axil_arready,
    input  wire [M_COUNT*DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [M_COUNT*2-1:0]           m_axil_rresp,
    input  wire [M_COUNT-1:0]             m_axil_rvalid,
    output wire [M_COUNT-1:0]             m_axil_rready
);
parameter CL_S_COUNT = $clog2(S_COUNT);
parameter CL_M_COUNT = $clog2(M_COUNT);
function [M_COUNT*M_REGIONS*ADDR_WIDTH-1:0] calcBaseAddrs(input [31:0] dummy);
    integer i;
    reg [ADDR_WIDTH-1:0] base;
    reg [ADDR_WIDTH-1:0] width;
    reg [ADDR_WIDTH-1:0] size;
    reg [ADDR_WIDTH-1:0] mask;
    begin
    calcBaseAddrs = {M_COUNT*M_REGIONS*ADDR_WIDTH{1'b0}};
    base = 0;
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    width = M_ADDR_WIDTH[i*32 +: 32];
    mask = {ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - width);
    size = mask + 1;
    if (width > 0) begin
    if ((base & mask) != 0) begin
    base = base + size - (base & mask); 
    end
    calcBaseAddrs[i * ADDR_WIDTH +: ADDR_WIDTH] = base;
    base = base + size; 
    end
    end
    end
endfunction
parameter M_BASE_ADDR_INT = M_BASE_ADDR ? M_BASE_ADDR : calcBaseAddrs(0);
integer i, j;
initial begin
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    if (M_ADDR_WIDTH[i*32 +: 32] && (M_ADDR_WIDTH[i*32 +: 32] < 0 || M_ADDR_WIDTH[i*32 +: 32] > ADDR_WIDTH)) begin
    $error("Error: address width out of range (instance %m)");
    $finish;
    end
    end
    $display("Addressing configuration for axil_interconnect instance %m");
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    if (M_ADDR_WIDTH[i*32 +: 32]) begin
    $display("%2d (%2d): %x / %02d -- %x-%x",
    i/M_REGIONS, i%M_REGIONS,
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
    M_ADDR_WIDTH[i*32 +: 32],
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
    );
    end
    end
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    if ((M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & (2**M_ADDR_WIDTH[i*32 +: 32]-1)) != 0) begin
    $display("Region not aligned:");
    $display("%2d (%2d): %x / %2d -- %x-%x",
    i/M_REGIONS, i%M_REGIONS,
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
    M_ADDR_WIDTH[i*32 +: 32],
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
    );
    $error("Error: address range not aligned (instance %m)");
    $finish;
    end
    end
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
    for (j = i+1; j < M_COUNT*M_REGIONS; j = j + 1) begin
    if (M_ADDR_WIDTH[i*32 +: 32] && M_ADDR_WIDTH[j*32 +: 32]) begin
    if (((M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32])) <= (M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[j*32 +: 32]))))
    && ((M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[j*32 +: 32])) <= (M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))))) begin
    $display("Overlapping regions:");
    $display("%2d (%2d): %x / %2d -- %x-%x",
    i/M_REGIONS, i%M_REGIONS,
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
    M_ADDR_WIDTH[i*32 +: 32],
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
    M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
    );
    $display("%2d (%2d): %x / %2d -- %x-%x",
    j/M_REGIONS, j%M_REGIONS,
    M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH],
    M_ADDR_WIDTH[j*32 +: 32],
    M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[j*32 +: 32]),
    M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[j*32 +: 32]))
    );
    $error("Error: address ranges overlap (instance %m)");
    $finish;
    end
    end
    end
    end
end
localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_DECODE = 3'd1,
    STATE_WRITE = 3'd2,
    STATE_WRITE_RESP = 3'd3,
    STATE_WRITE_DROP = 3'd4,
    STATE_READ = 3'd5,
    STATE_WAIT_IDLE = 3'd6;
reg [2:0] state_reg = STATE_IDLE, state_next;
reg match;
reg [CL_M_COUNT-1:0] m_select_reg = 2'd0, m_select_next;
reg [ADDR_WIDTH-1:0] axil_addr_reg = {ADDR_WIDTH{1'b0}}, axil_addr_next;
reg axil_addr_valid_reg = 1'b0, axil_addr_valid_next;
reg [2:0] axil_prot_reg = 3'b000, axil_prot_next;
reg [DATA_WIDTH-1:0] axil_data_reg = {DATA_WIDTH{1'b0}}, axil_data_next;
reg [STRB_WIDTH-1:0] axil_wstrb_reg = {STRB_WIDTH{1'b0}}, axil_wstrb_next;
reg [1:0] axil_resp_reg = 2'b00, axil_resp_next;
reg [S_COUNT-1:0] s_axil_awready_reg = 0, s_axil_awready_next;
reg [S_COUNT-1:0] s_axil_wready_reg = 0, s_axil_wready_next;
reg [S_COUNT-1:0] s_axil_bvalid_reg = 0, s_axil_bvalid_next;
reg [S_COUNT-1:0] s_axil_arready_reg = 0, s_axil_arready_next;
reg [S_COUNT-1:0] s_axil_rvalid_reg = 0, s_axil_rvalid_next;
reg [M_COUNT-1:0] m_axil_awvalid_reg = 0, m_axil_awvalid_next;
reg [M_COUNT-1:0] m_axil_wvalid_reg = 0, m_axil_wvalid_next;
reg [M_COUNT-1:0] m_axil_bready_reg = 0, m_axil_bready_next;
reg [M_COUNT-1:0] m_axil_arvalid_reg = 0, m_axil_arvalid_next;
reg [M_COUNT-1:0] m_axil_rready_reg = 0, m_axil_rready_next;
assign s_axil_awready = s_axil_awready_reg;
assign s_axil_wready = s_axil_wready_reg;
assign s_axil_bresp = {S_COUNT{axil_resp_reg}};
assign s_axil_bvalid = s_axil_bvalid_reg;
assign s_axil_arready = s_axil_arready_reg;
assign s_axil_rdata = {S_COUNT{axil_data_reg}};
assign s_axil_rresp = {S_COUNT{axil_resp_reg}};
assign s_axil_rvalid = s_axil_rvalid_reg;
assign m_axil_awaddr = {M_COUNT{axil_addr_reg}};
assign m_axil_awprot = {M_COUNT{axil_prot_reg}};
assign m_axil_awvalid = m_axil_awvalid_reg;
assign m_axil_wdata = {M_COUNT{axil_data_reg}};
assign m_axil_wstrb = {M_COUNT{axil_wstrb_reg}};
assign m_axil_wvalid = m_axil_wvalid_reg;
assign m_axil_bready = m_axil_bready_reg;
assign m_axil_araddr = {M_COUNT{axil_addr_reg}};
assign m_axil_arprot = {M_COUNT{axil_prot_reg}};
assign m_axil_arvalid = m_axil_arvalid_reg;
assign m_axil_rready = m_axil_rready_reg;
wire [(CL_S_COUNT > 0 ? CL_S_COUNT-1 : 0):0] s_select;
wire [ADDR_WIDTH-1:0] current_s_axil_awaddr  = s_axil_awaddr[s_select*ADDR_WIDTH +: ADDR_WIDTH];
wire [2:0]            current_s_axil_awprot  = s_axil_awprot[s_select*3 +: 3];
wire                  current_s_axil_awvalid = s_axil_awvalid[s_select];
wire                  current_s_axil_awready = s_axil_awready[s_select];
wire [DATA_WIDTH-1:0] current_s_axil_wdata   = s_axil_wdata[s_select*DATA_WIDTH +: DATA_WIDTH];
wire [STRB_WIDTH-1:0] current_s_axil_wstrb   = s_axil_wstrb[s_select*STRB_WIDTH +: STRB_WIDTH];
wire                  current_s_axil_wvalid  = s_axil_wvalid[s_select];
wire                  current_s_axil_wready  = s_axil_wready[s_select];
wire [1:0]            current_s_axil_bresp   = s_axil_bresp[s_select*2 +: 2];
wire                  current_s_axil_bvalid  = s_axil_bvalid[s_select];
wire                  current_s_axil_bready  = s_axil_bready[s_select];
wire [ADDR_WIDTH-1:0] current_s_axil_araddr  = s_axil_araddr[s_select*ADDR_WIDTH +: ADDR_WIDTH];
wire [2:0]            current_s_axil_arprot  = s_axil_arprot[s_select*3 +: 3];
wire                  current_s_axil_arvalid = s_axil_arvalid[s_select];
wire                  current_s_axil_arready = s_axil_arready[s_select];
wire [DATA_WIDTH-1:0] current_s_axil_rdata   = s_axil_rdata[s_select*DATA_WIDTH +: DATA_WIDTH];
wire [1:0]            current_s_axil_rresp   = s_axil_rresp[s_select*2 +: 2];
wire                  current_s_axil_rvalid  = s_axil_rvalid[s_select];
wire                  current_s_axil_rready  = s_axil_rready[s_select];
wire [ADDR_WIDTH-1:0] current_m_axil_awaddr  = m_axil_awaddr[m_select_reg*ADDR_WIDTH +: ADDR_WIDTH];
wire [2:0]            current_m_axil_awprot  = m_axil_awprot[m_select_reg*3 +: 3];
wire                  current_m_axil_awvalid = m_axil_awvalid[m_select_reg];
wire                  current_m_axil_awready = m_axil_awready[m_select_reg];
wire [DATA_WIDTH-1:0] current_m_axil_wdata   = m_axil_wdata[m_select_reg*DATA_WIDTH +: DATA_WIDTH];
wire [STRB_WIDTH-1:0] current_m_axil_wstrb   = m_axil_wstrb[m_select_reg*STRB_WIDTH +: STRB_WIDTH];
wire                  current_m_axil_wvalid  = m_axil_wvalid[m_select_reg];
wire                  current_m_axil_wready  = m_axil_wready[m_select_reg];
wire [1:0]            current_m_axil_bresp   = m_axil_bresp[m_select_reg*2 +: 2];
wire                  current_m_axil_bvalid  = m_axil_bvalid[m_select_reg];
wire                  current_m_axil_bready  = m_axil_bready[m_select_reg];
wire [ADDR_WIDTH-1:0] current_m_axil_araddr  = m_axil_araddr[m_select_reg*ADDR_WIDTH +: ADDR_WIDTH];
wire [2:0]            current_m_axil_arprot  = m_axil_arprot[m_select_reg*3 +: 3];
wire                  current_m_axil_arvalid = m_axil_arvalid[m_select_reg];
wire                  current_m_axil_arready = m_axil_arready[m_select_reg];
wire [DATA_WIDTH-1:0] current_m_axil_rdata   = m_axil_rdata[m_select_reg*DATA_WIDTH +: DATA_WIDTH];
wire [1:0]            current_m_axil_rresp   = m_axil_rresp[m_select_reg*2 +: 2];
wire                  current_m_axil_rvalid  = m_axil_rvalid[m_select_reg];
wire                  current_m_axil_rready  = m_axil_rready[m_select_reg];
wire [S_COUNT*2-1:0] request;
wire [S_COUNT*2-1:0] acknowledge;
wire [S_COUNT*2-1:0] grant;
wire grant_valid;
wire [CL_S_COUNT:0] grant_encoded;
wire read = grant_encoded[0];
assign s_select = grant_encoded >> 1;
arbiter #(
    .PORTS(S_COUNT*2),
    .ARB_TYPE_ROUND_ROBIN(1),
    .ARB_BLOCK(1),
    .ARB_BLOCK_ACK(1),
    .ARB_LSB_HIGH_PRIORITY(1)
)
arb_inst (
    .clk(clk),
    .rst(rst),
    .request(request),
    .acknowledge(acknowledge),
    .grant(grant),
    .grant_valid(grant_valid),
    .grant_encoded(grant_encoded)
);
genvar n;
generate
for (n = 0; n < S_COUNT; n = n + 1) begin
    assign request[2*n]   = s_axil_awvalid[n];
    assign request[2*n+1] = s_axil_arvalid[n];
end
endgenerate
generate
for (n = 0; n < S_COUNT; n = n + 1) begin
    assign acknowledge[2*n]   = grant[2*n]   && s_axil_bvalid[n] && s_axil_bready[n];
    assign acknowledge[2*n+1] = grant[2*n+1] && s_axil_rvalid[n] && s_axil_rready[n];
end
endgenerate
always @* begin
    state_next = STATE_IDLE;
    match = 1'b0;
    m_select_next = m_select_reg;
    axil_addr_next = axil_addr_reg;
    axil_addr_valid_next = axil_addr_valid_reg;
    axil_prot_next = axil_prot_reg;
    axil_data_next = axil_data_reg;
    axil_wstrb_next = axil_wstrb_reg;
    axil_resp_next = axil_resp_reg;
    s_axil_awready_next = 0;
    s_axil_wready_next = 0;
    s_axil_bvalid_next = s_axil_bvalid_reg & ~s_axil_bready;
    s_axil_arready_next = 0;
    s_axil_rvalid_next = s_axil_rvalid_reg & ~s_axil_rready;
    m_axil_awvalid_next = m_axil_awvalid_reg & ~m_axil_awready;
    m_axil_wvalid_next = m_axil_wvalid_reg & ~m_axil_wready;
    m_axil_bready_next = 0;
    m_axil_arvalid_next = m_axil_arvalid_reg & ~m_axil_arready;
    m_axil_rready_next = 0;
    case (state_reg)
    STATE_IDLE: begin
    if (grant_valid) begin
    axil_addr_valid_next = 1'b1;
    if (read) begin
    axil_addr_next = current_s_axil_araddr;
    axil_prot_next = current_s_axil_arprot;
    s_axil_arready_next[s_select] = 1'b1;
    end else  begin
    axil_addr_next = current_s_axil_awaddr;
    axil_prot_next = current_s_axil_awprot;
    s_axil_awready_next[s_select] = 1'b1;
    end
    state_next = STATE_DECODE;
    end else begin
    state_next = STATE_IDLE;
    end
    end
    STATE_DECODE: begin
    match = 1'b0;
    for (i = 0; i < M_COUNT; i = i + 1) begin
    for (j = 0; j < M_REGIONS; j = j + 1) begin
    if (M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32] && (!M_SECURE[i] || !axil_prot_reg[1]) && ((read ? M_CONNECT_READ : M_CONNECT_WRITE) & (1 << (s_select+i*S_COUNT))) && (axil_addr_reg >> M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32]) == (M_BASE_ADDR_INT[(i*M_REGIONS+j)*ADDR_WIDTH +: ADDR_WIDTH] >> M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32])) begin
    m_select_next = i;
    match = 1'b1;
    end
    end
    end
    if (match) 
    begin
    if (read)
    begin
    m_axil_rready_next[m_select_next] = 1'b1;
    state_next = STATE_READ;
    end 
    else
    begin
    s_axil_wready_next[s_select] = 1'b1;
    state_next = STATE_WRITE;
    end
    end 
    else 
    begin
    axil_data_next = {DATA_WIDTH{1'b0}};
    axil_resp_next = 2'b11;
    if (read) 
    begin
    s_axil_rvalid_next[s_select] = 1'b1;
    state_next = STATE_WAIT_IDLE;
    end 
    else
    begin
    s_axil_wready_next[s_select] = 1'b1;
    state_next = STATE_WRITE_DROP;
    end
    end
    end
    STATE_WRITE: begin
    s_axil_wready_next[s_select] = 1'b1;
    if (axil_addr_valid_reg) begin
    m_axil_awvalid_next[m_select_reg] = 1'b1;
    end
    axil_addr_valid_next = 1'b0;
    if (current_s_axil_wready && current_s_axil_wvalid) begin
    s_axil_wready_next[s_select] = 1'b0;
    axil_data_next = current_s_axil_wdata;
    axil_wstrb_next = current_s_axil_wstrb;
    m_axil_wvalid_next[m_select_reg] = 1'b1;
    m_axil_bready_next[m_select_reg] = 1'b1;
    state_next = STATE_WRITE_RESP;
    end else begin
    state_next = STATE_WRITE;
    end
    end
    STATE_WRITE_RESP: begin
    m_axil_bready_next[m_select_reg] = 1'b1;
    if (current_m_axil_bready && current_m_axil_bvalid) begin
    m_axil_bready_next[m_select_reg] = 1'b0;
    axil_resp_next = current_m_axil_bresp;
    s_axil_bvalid_next[s_select] = 1'b1;
    state_next = STATE_WAIT_IDLE;
    end else begin
    state_next = STATE_WRITE_RESP;
    end
    end
    STATE_WRITE_DROP: begin
    s_axil_wready_next[s_select] = 1'b1;
    axil_addr_valid_next = 1'b0;
    if (current_s_axil_wready && current_s_axil_wvalid) begin
    s_axil_wready_next[s_select] = 1'b0;
    s_axil_bvalid_next[s_select] = 1'b1;
    state_next = STATE_WAIT_IDLE;
    end else begin
    state_next = STATE_WRITE_DROP;
    end
    end
    STATE_READ: begin
    m_axil_rready_next[m_select_reg] = 1'b1;
    if (axil_addr_valid_reg) begin
    m_axil_arvalid_next[m_select_reg] = 1'b1;
    end
    axil_addr_valid_next = 1'b0;
    if (current_m_axil_rready && current_m_axil_rvalid) begin
    m_axil_rready_next[m_select_reg] = 1'b0;
    axil_data_next = current_m_axil_rdata;
    axil_resp_next = current_m_axil_rresp;
    s_axil_rvalid_next[s_select] = 1'b1;
    state_next = STATE_WAIT_IDLE;
    end else begin
    state_next = STATE_READ;
    end
    end
    STATE_WAIT_IDLE: begin
    if (!grant_valid || acknowledge) begin
    state_next = STATE_IDLE;
    end else begin
    state_next = STATE_WAIT_IDLE;
    end
    end
    endcase
end
always @(posedge clk) 
begin
    if (rst) 
    begin
    state_reg <= STATE_IDLE;
    s_axil_awready_reg <= 0;
    s_axil_wready_reg <= 0;
    s_axil_bvalid_reg <= 0;
    s_axil_arready_reg <= 0;
    s_axil_rvalid_reg <= 0;
    m_axil_awvalid_reg <= 0;
    m_axil_wvalid_reg <= 0;
    m_axil_bready_reg <= 0;
    m_axil_arvalid_reg <= 0;
    m_axil_rready_reg <= 0;
    end 
    else
    begin
    state_reg <= state_next;
    s_axil_awready_reg <= s_axil_awready_next;
    s_axil_wready_reg <= s_axil_wready_next;
    s_axil_bvalid_reg <= s_axil_bvalid_next;
    s_axil_arready_reg <= s_axil_arready_next;
    s_axil_rvalid_reg <= s_axil_rvalid_next;
    m_axil_awvalid_reg <= m_axil_awvalid_next;
    m_axil_wvalid_reg <= m_axil_wvalid_next;
    m_axil_bready_reg <= m_axil_bready_next;
    m_axil_arvalid_reg <= m_axil_arvalid_next;
    m_axil_rready_reg <= m_axil_rready_next;
    end
    m_select_reg <= m_select_next;
    axil_addr_reg <= axil_addr_next;
    axil_addr_valid_reg <= axil_addr_valid_next;
    axil_prot_reg <= axil_prot_next;
    axil_data_reg <= axil_data_next;
    axil_wstrb_reg <= axil_wstrb_next;
    axil_resp_reg <= axil_resp_next;
end
endmodule
`resetall
module ahblite_axi_lite_bridge_03513
(
    m_axi_arready,
    m_axi_awready,
    m_axi_bvalid,
    m_axi_rlast,
    m_axi_rvalid,
    m_axi_wready,
    s_ahb_hclk,
    s_ahb_hready_in,
    s_ahb_hresetn,
    s_ahb_hsel,
    s_ahb_hwrite,
    m_axi_bid,
    m_axi_bresp,
    m_axi_rdata,
    m_axi_rid,
    m_axi_rresp,
    s_ahb_haddr,
    s_ahb_hburst,
    s_ahb_hprot,
    s_ahb_hsize,
    s_ahb_htrans,
    s_ahb_hwdata,
    m_axi_aclk,
    m_axi_aresetn,
    m_axi_arlock,
    m_axi_arvalid,
    m_axi_awlock,
    m_axi_awvalid,
    m_axi_bready,
    m_axi_rready,
    m_axi_wlast,
    m_axi_wvalid,
    s_ahb_hready_out,
    s_ahb_hresp,
    m_axi_araddr,
    m_axi_arcache,
    m_axi_arid,
    m_axi_arprot,
    m_axi_awaddr,
    m_axi_awcache,
    m_axi_awid,
    m_axi_awprot,
    m_axi_wdata,
    m_axi_wstrb,
    s_ahb_hrdata
);
    input  m_axi_arready;
    input  m_axi_awready;
    input  m_axi_bvalid;
    input  m_axi_rlast;
    input  m_axi_rvalid;
    input  m_axi_wready;
    input  s_ahb_hclk;
    input  s_ahb_hready_in;
    input  s_ahb_hresetn;
    input  s_ahb_hsel;
    input  s_ahb_hwrite;
    input  [3:0] m_axi_bid;
    input  [1:0] m_axi_bresp;
    input  [31:0] m_axi_rdata;
    input  [3:0] m_axi_rid;
    input  [1:0] m_axi_rresp;
    input  [31:0] s_ahb_haddr;
    input  [2:0] s_ahb_hburst;
    input  [3:0] s_ahb_hprot;
    input  [2:0] s_ahb_hsize;
    input  [1:0] s_ahb_htrans;
    input  [31:0] s_ahb_hwdata;
    output m_axi_aclk;
    output m_axi_aresetn;
    output m_axi_arlock;
    output m_axi_arvalid;
    output m_axi_awlock;
    output m_axi_awvalid;
    output m_axi_bready;
    output m_axi_rready;
    output m_axi_wlast;
    output m_axi_wvalid;
    output s_ahb_hready_out;
    output s_ahb_hresp;
    output [31:0] m_axi_araddr;
    output [3:0] m_axi_arcache;
    output [3:0] m_axi_arid;
    output [2:0] m_axi_arprot;
    output [31:0] m_axi_awaddr;
    output [3:0] m_axi_awcache;
    output [3:0] m_axi_awid;
    output [2:0] m_axi_awprot;
    output [31:0] m_axi_wdata;
    output [3:0] m_axi_wstrb;
    output [31:0] s_ahb_hrdata;
    wire [1:0] m_axi_arburst;
    wire [7:0] m_axi_arlen;
    wire [2:0] m_axi_arsize;
    wire [7:0] m_axi_awlen;
    wire [1:0] m_axi_awburst;
    wire [2:0] m_axi_awsize;                
    wire \U0/AHBLITE_AXI_CONTROL_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_1 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_10 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_11 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_12 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_13 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_14 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_15 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_16 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_17 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_18 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_19 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_20 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_4 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_6 ;
    wire \U0/AHBLITE_AXI_CONTROL_n_7 ;
    wire \U0/AHB_DATA_COUNTER_n_0 ;
    wire \U0/AHB_DATA_COUNTER_n_1 ;
    wire \U0/AHB_DATA_COUNTER_n_2 ;
    wire \U0/AHB_DATA_COUNTER_n_3 ;
    wire \U0/AHB_DATA_COUNTER_n_4 ;
    wire \U0/AHB_DATA_COUNTER_n_5 ;
    wire \U0/AHB_IF_n_12 ;
    wire \U0/AHB_IF_n_14 ;
    wire \U0/AHB_IF_n_16 ;
    wire \U0/AHB_IF_n_18 ;
    wire \U0/AHB_IF_n_19 ;
    wire \U0/AHB_IF_n_21 ;
    wire \U0/AHB_IF_n_22 ;
    wire \U0/AHB_IF_n_23 ;
    wire \U0/AHB_IF_n_24 ;
    wire \U0/AHB_IF_n_3 ;
    wire \U0/AHB_IF_n_30 ;
    wire \U0/AHB_IF_n_32 ;
    wire \U0/AHB_IF_n_39 ;
    wire \U0/AXI_ALEN_i0 ;
    wire \U0/AXI_RCHANNEL_n_10 ;
    wire \U0/AXI_RCHANNEL_n_3 ;
    wire \U0/AXI_RCHANNEL_n_5 ;
    wire \U0/AXI_WCHANNEL_n_10 ;
    wire \U0/AXI_WCHANNEL_n_12 ;
    wire \U0/AXI_WCHANNEL_n_13 ;
    wire \U0/AXI_WCHANNEL_n_14 ;
    wire \U0/AXI_WCHANNEL_n_6 ;
    wire \U0/AXI_WCHANNEL_n_7 ;
    wire \U0/AXI_WCHANNEL_n_8 ;
    wire \U0/AXI_WCHANNEL_n_9 ;
    wire \U0/M_AXI_RREADY_i5__0 ;
    wire \U0/M_AXI_WLAST_i110_out ;
    wire \U0/S_AHB_HREADY_OUT_i116_out ;
    wire \U0/ahb_burst_done ;
    wire \U0/ahb_data_valid ;
    wire \U0/ahb_data_valid_burst_term ;
    wire \U0/ahb_done_axi_in_progress ;
    wire \U0/ahb_hburst_incr ;
    wire \U0/ahb_hburst_single ;
    wire \U0/axi_waddr_done_i ;
    wire \U0/burst_term ;
    wire \U0/burst_term_cur_cnt[0] ;
    wire \U0/burst_term_cur_cnt[1] ;
    wire \U0/burst_term_cur_cnt[2] ;
    wire \U0/burst_term_cur_cnt[3] ;
    wire \U0/burst_term_cur_cnt[4] ;
    wire \U0/burst_term_hwrite ;
    wire \U0/burst_term_single_incr ;
    wire \U0/burst_term_txer_cnt[1] ;
    wire \U0/burst_term_txer_cnt[2] ;
    wire \U0/burst_term_txer_cnt[3] ;
    wire \U0/burst_term_with_nonseq ;
    wire \U0/busy_detected ;
    wire \U0/cntr_rst ;
    wire \U0/ctl_sm_ns033_out ;
    wire \U0/ctl_sm_ns1 ;
    wire \U0/ctl_sm_ns14_out ;
    wire \U0/eqOp6_out ;
    wire \U0/idle_txfer_pending ;
    wire \U0/init_pending_txfer ;
    wire \U0/last_axi_rd_sample ;
    wire \U0/local_en ;
    wire \U0/nonseq_detected ;
    wire \U0/nonseq_txfer_pending ;
    wire \U0/p_12_in ;
    wire \U0/p_27_in ;
    wire \U0/rd_load_timeout_cntr ;
    wire \U0/reset_hready010_out ;
    wire \U0/seq_detected ;
    wire \U0/set_axi_waddr ;
    wire \U0/valid_cnt_required[1] ;
    wire \U0/valid_cnt_required[2] ;
    wire \U0/valid_cnt_required[3] ;
    wire \U0/AHBLITE_AXI_CONTROL/<const1> ;
    wire \U0/AHBLITE_AXI_CONTROL/AHB_IF/p_9_in ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ;
    wire \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4_n_0 ;
    wire \U0/AHBLITE_AXI_CONTROL/reset_hready ;
    wire \U0/AHBLITE_AXI_CONTROL/set_axi_raddr ;
    wire \U0/AHBLITE_AXI_CONTROL/set_axi_wdata_burst ;
    wire \U0/AHBLITE_AXI_CONTROL/set_hready ;
    wire \U0/AHBLITE_AXI_CONTROL/set_hresp_err ;
    wire \U0/AHB_IF/<const0> ;
    wire \U0/AHB_IF/<const1> ;
    wire \U0/AHB_IF/AHBLITE_AXI_CONTROL/ctl_sm_ns132_out ;
    wire \U0/AHB_IF/AHBLITE_AXI_CONTROL/hburst_single_incr ;
    wire \U0/AHB_IF/AHBLITE_AXI_CONTROL/reset_hready2__0 ;
    wire \U0/AHB_IF/AXI_ABURST_i[0]_i_1_n_0 ;
    wire \U0/AHB_IF/AXI_ABURST_i[1]_i_1_n_0 ;
    wire \U0/AHB_IF/AXI_ALEN_i[1] ;
    wire \U0/AHB_IF/AXI_ALEN_i[3] ;
    wire \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1_n_0 ;
    wire \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17_n_0 ;
    wire \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_8_n_0 ;
    wire \U0/AHB_IF/ahb_done_axi_in_progress_i_1_n_0 ;
    wire \U0/AHB_IF/ahb_hburst_incr_i_i_1_n_0 ;
    wire \U0/AHB_IF/ahb_hburst_single_i_i_1_n_0 ;
    wire \U0/AHB_IF/ahb_penult_beat_i_1_n_0 ;
    wire \U0/AHB_IF/burst_term_txer_cnt_i0 ;
    wire \U0/AHB_IF/dummy_on_axi_progress_i_5_n_0 ;
    wire \U0/AHB_IF/dummy_txfer_in_progress_i_1_n_0 ;
    wire \U0/AHB_IF/eqOp ;
    wire \U0/AHB_IF/eqOp0_in ;
    wire \U0/AHB_IF/p_1_out[2] ;
    wire \U0/AHB_IF/valid_cnt_required_i[1]_i_1_n_0 ;
    wire \U0/AHB_IF/valid_cnt_required_i[2]_i_1_n_0 ;
    wire \U0/AHB_IF/valid_cnt_required_i[3]_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/<const0> ;
    wire \U0/AXI_RCHANNEL/<const1> ;
    wire \U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/ahb_rd_req ;
    wire \U0/AXI_RCHANNEL/ahb_rd_req_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/ahb_rd_txer_pending ;
    wire \U0/AXI_RCHANNEL/ahb_rd_txer_pending07_out__0 ;
    wire \U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_last_avlbl_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_last_avlbl_i_2_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_last_avlbl_reg_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_rd_avlbl ;
    wire \U0/AXI_RCHANNEL/axi_rd_avlbl_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_rresp_avlbl[1] ;
    wire \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2_n_0 ;
    wire \U0/AXI_RCHANNEL/bridge_rd_in_progress ;
    wire \U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1_n_0 ;
    wire \U0/AXI_RCHANNEL/rvalid_rready ;
    wire \U0/AXI_RCHANNEL/seq_detected_d1 ;
    wire \U0/AXI_WCHANNEL/<const0> ;
    wire \U0/AXI_WCHANNEL/<const1> ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_5 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_7 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_8 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_9 ;
    wire \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/M_AXI_WLAST_i__1 ;
    wire \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[1] ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[1]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[2] ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[3] ;
    wire \U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_last_beat_reg_n_0 ;
    wire \U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 ;
    wire \U0/AXI_WCHANNEL/dummy_on_axi__0 ;
    wire \U0/AXI_WCHANNEL/dummy_on_axi_progress ;
    wire \U0/AXI_WCHANNEL/local_en_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/local_wdata[0] ;
    wire \U0/AXI_WCHANNEL/local_wdata[10] ;
    wire \U0/AXI_WCHANNEL/local_wdata[11] ;
    wire \U0/AXI_WCHANNEL/local_wdata[12] ;
    wire \U0/AXI_WCHANNEL/local_wdata[13] ;
    wire \U0/AXI_WCHANNEL/local_wdata[14] ;
    wire \U0/AXI_WCHANNEL/local_wdata[15] ;
    wire \U0/AXI_WCHANNEL/local_wdata[16] ;
    wire \U0/AXI_WCHANNEL/local_wdata[17] ;
    wire \U0/AXI_WCHANNEL/local_wdata[18] ;
    wire \U0/AXI_WCHANNEL/local_wdata[19] ;
    wire \U0/AXI_WCHANNEL/local_wdata[1] ;
    wire \U0/AXI_WCHANNEL/local_wdata[20] ;
    wire \U0/AXI_WCHANNEL/local_wdata[21] ;
    wire \U0/AXI_WCHANNEL/local_wdata[22] ;
    wire \U0/AXI_WCHANNEL/local_wdata[23] ;
    wire \U0/AXI_WCHANNEL/local_wdata[24] ;
    wire \U0/AXI_WCHANNEL/local_wdata[25] ;
    wire \U0/AXI_WCHANNEL/local_wdata[26] ;
    wire \U0/AXI_WCHANNEL/local_wdata[27] ;
    wire \U0/AXI_WCHANNEL/local_wdata[28] ;
    wire \U0/AXI_WCHANNEL/local_wdata[29] ;
    wire \U0/AXI_WCHANNEL/local_wdata[2] ;
    wire \U0/AXI_WCHANNEL/local_wdata[30] ;
    wire \U0/AXI_WCHANNEL/local_wdata[31] ;
    wire \U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/local_wdata[3] ;
    wire \U0/AXI_WCHANNEL/local_wdata[4] ;
    wire \U0/AXI_WCHANNEL/local_wdata[5] ;
    wire \U0/AXI_WCHANNEL/local_wdata[6] ;
    wire \U0/AXI_WCHANNEL/local_wdata[7] ;
    wire \U0/AXI_WCHANNEL/local_wdata[8] ;
    wire \U0/AXI_WCHANNEL/local_wdata[9] ;
    wire \U0/AXI_WCHANNEL/p_1_in[0] ;
    wire \U0/AXI_WCHANNEL/p_1_in[10] ;
    wire \U0/AXI_WCHANNEL/p_1_in[11] ;
    wire \U0/AXI_WCHANNEL/p_1_in[12] ;
    wire \U0/AXI_WCHANNEL/p_1_in[13] ;
    wire \U0/AXI_WCHANNEL/p_1_in[14] ;
    wire \U0/AXI_WCHANNEL/p_1_in[15] ;
    wire \U0/AXI_WCHANNEL/p_1_in[16] ;
    wire \U0/AXI_WCHANNEL/p_1_in[17] ;
    wire \U0/AXI_WCHANNEL/p_1_in[18] ;
    wire \U0/AXI_WCHANNEL/p_1_in[19] ;
    wire \U0/AXI_WCHANNEL/p_1_in[1] ;
    wire \U0/AXI_WCHANNEL/p_1_in[20] ;
    wire \U0/AXI_WCHANNEL/p_1_in[21] ;
    wire \U0/AXI_WCHANNEL/p_1_in[22] ;
    wire \U0/AXI_WCHANNEL/p_1_in[23] ;
    wire \U0/AXI_WCHANNEL/p_1_in[24] ;
    wire \U0/AXI_WCHANNEL/p_1_in[25] ;
    wire \U0/AXI_WCHANNEL/p_1_in[26] ;
    wire \U0/AXI_WCHANNEL/p_1_in[27] ;
    wire \U0/AXI_WCHANNEL/p_1_in[28] ;
    wire \U0/AXI_WCHANNEL/p_1_in[29] ;
    wire \U0/AXI_WCHANNEL/p_1_in[2] ;
    wire \U0/AXI_WCHANNEL/p_1_in[30] ;
    wire \U0/AXI_WCHANNEL/p_1_in[31] ;
    wire \U0/AXI_WCHANNEL/p_1_in[3] ;
    wire \U0/AXI_WCHANNEL/p_1_in[4] ;
    wire \U0/AXI_WCHANNEL/p_1_in[5] ;
    wire \U0/AXI_WCHANNEL/p_1_in[6] ;
    wire \U0/AXI_WCHANNEL/p_1_in[7] ;
    wire \U0/AXI_WCHANNEL/p_1_in[8] ;
    wire \U0/AXI_WCHANNEL/p_1_in[9] ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4_n_0 ;
    wire \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/GLOBAL_LOGIC1 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_2_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_5_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_6_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_init ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6_n_0 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp1_out ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp3_out ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp5_out ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp8_out ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp__5 ;
    wire \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ;
    xs0 GND
    (
    .G(m_axi_arlock)
    );
    xsLUTSA5 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I2(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3_n_0 ),
    .I3(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1 .INIT = 32'HB8FFB800;
    xsLUTSA5 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2 
    (
    .I0(\U0/nonseq_detected ),
    .I1(\U0/nonseq_txfer_pending ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_2 .INIT = 32'H00E00FE0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3 
    (
    .I0(\U0/axi_waddr_done_i ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/nonseq_txfer_pending ),
    .I3(\U0/nonseq_detected ),
    .I4(m_axi_bvalid),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_3 .INIT = 64'HDDD11111FFFFFFFF;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1 
    (
    .I0(\U0/AHB_IF_n_23 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I2(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I3(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1 .INIT = 64'H8F80FFFF8F800000;
    xsLUTSA3 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3 
    (
    .I0(\U0/axi_waddr_done_i ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_3 .INIT = 8'H38;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I2(\U0/AHB_IF_n_24 ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1 .INIT = 64'HB888FFFFB8880000;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2 
    (
    .I0(\U0/ctl_sm_ns1 ),
    .I1(\U0/ctl_sm_ns14_out ),
    .I2(\U0/idle_txfer_pending ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_2 .INIT = 64'H0000020000FF0200;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5 
    (
    .I0(m_axi_bvalid),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(m_axi_wready),
    .I4(m_axi_wlast),
    .I5(\U0/AXI_ALEN_i0 ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5 .INIT = 64'HBFB3B3B3BCB0B0B0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/ctl_sm_ns033_out ),
    .I3(\U0/ctl_sm_ns1 ),
    .I4(\U0/idle_txfer_pending ),
    .I5(\U0/ctl_sm_ns14_out ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6 .INIT = 64'HFDFDFDFDFDFDFFFD;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[0]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHBLITE_AXI_CONTROL_n_1 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[1]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHBLITE_AXI_CONTROL_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2] .INIT = 1'B0;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_5_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs[2]_i_6_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/FSM_sequential_ctl_sm_cs_reg[2]_i_4_n_0 )
    );
    xsLUTSA2 \U0/AHBLITE_AXI_CONTROL/INFERRED_GEN.icount_out[0]_i_1 
    (
    .I0(\U0/set_axi_waddr ),
    .I1(\U0/AXI_WCHANNEL_n_10 ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_4 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/INFERRED_GEN.icount_out[0]_i_1 .INIT = 4'H1;
    xsLUTSA3 \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_1 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/set_axi_raddr ),
    .I1(m_axi_arready),
    .I2(m_axi_arvalid),
    .O(\U0/AHBLITE_AXI_CONTROL_n_11 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_1 .INIT = 8'HBA;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I2(\U0/ctl_sm_ns033_out ),
    .I3(\U0/ctl_sm_ns14_out ),
    .I4(\U0/burst_term_hwrite ),
    .I5(s_ahb_hwrite),
    .O(\U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4 .INIT = 64'H0000000000004000;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_reg_i_2 
    (
    .I0(\U0/AHB_IF_n_22 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/M_AXI_ARVALID_i_i_4_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/set_axi_raddr )
    );
    xsLUTSA3 \U0/AHBLITE_AXI_CONTROL/M_AXI_BREADY_i_i_1 
    (
    .I0(\U0/axi_waddr_done_i ),
    .I1(m_axi_bvalid),
    .I2(m_axi_bready),
    .O(\U0/AHBLITE_AXI_CONTROL_n_19 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_BREADY_i_i_1 .INIT = 8'HBA;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/last_axi_rd_sample ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_RLAST_reg_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/M_AXI_RREADY_i_i_2 
    (
    .I0(\U0/M_AXI_RREADY_i5__0 ),
    .I1(\U0/AXI_RCHANNEL_n_10 ),
    .I2(\U0/busy_detected ),
    .I3(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I5(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6_n_0 ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_7 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_RREADY_i_i_2 .INIT = 64'HFFFFFFFEFEFEFFFE;
    xsLUTSA5 \U0/AHBLITE_AXI_CONTROL/M_AXI_WVALID_i_i_2 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/set_axi_wdata_burst ),
    .I1(\U0/ahb_data_valid_burst_term ),
    .I2(\U0/local_en ),
    .I3(\U0/ahb_data_valid ),
    .I4(\U0/axi_waddr_done_i ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_10 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_WVALID_i_i_2 .INIT = 32'HFFFCAAA0;
    xsLUTSA5 \U0/AHBLITE_AXI_CONTROL/M_AXI_WVALID_i_i_3 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/ahb_hburst_single ),
    .I3(\U0/ahb_hburst_incr ),
    .I4(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/set_axi_wdata_burst )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_WVALID_i_i_3 .INIT = 32'H00000004;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13 
    (
    .I0(\U0/AHB_IF_n_14 ),
    .I1(\U0/axi_waddr_done_i ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I4(\U0/ahb_hburst_single ),
    .I5(\U0/AXI_WCHANNEL_n_12 ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13 .INIT = 64'HA0C0AFC0A0C0A0C0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/ctl_sm_ns14_out ),
    .I3(\U0/ctl_sm_ns033_out ),
    .I4(\U0/idle_txfer_pending ),
    .I5(\U0/AXI_RCHANNEL_n_3 ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14 .INIT = 64'HDFDDDFDFDFDDDDDD;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_2 
    (
    .I0(\U0/busy_detected ),
    .I1(\U0/S_AHB_HREADY_OUT_i116_out ),
    .I2(\U0/AHBLITE_AXI_CONTROL/reset_hready ),
    .I3(\U0/AHBLITE_AXI_CONTROL/set_hready ),
    .I4(\U0/AHBLITE_AXI_CONTROL/AHB_IF/p_9_in ),
    .I5(s_ahb_hready_out),
    .O(\U0/AHBLITE_AXI_CONTROL_n_13 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_2 .INIT = 64'H3333232333332320;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_5 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/AXI_RCHANNEL_n_5 ),
    .I2(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I3(\U0/AHB_IF_n_18 ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I5(\U0/AHB_IF_n_19 ),
    .O(\U0/AHBLITE_AXI_CONTROL/reset_hready )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_5 .INIT = 64'H4F400F0F4F400000;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_reg_i_6 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_13_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/S_AHB_HREADY_OUT_i_i_14_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/set_hready )
    );
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_1 
    (
    .I0(s_ahb_hresp),
    .I1(\U0/AHBLITE_AXI_CONTROL/set_hresp_err ),
    .I2(s_ahb_hresetn),
    .I3(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I5(\U0/AHB_IF_n_16 ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_17 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_1 .INIT = 64'H00E0000000E0E0E0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/ctl_sm_ns1 ),
    .I2(\U0/idle_txfer_pending ),
    .I3(\U0/ctl_sm_ns033_out ),
    .I4(\U0/ctl_sm_ns14_out ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_3 .INIT = 64'H0000510100000000;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(m_axi_bvalid),
    .I3(\U0/ctl_sm_ns14_out ),
    .I4(m_axi_bresp[1]),
    .I5(\U0/idle_txfer_pending ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5 .INIT = 64'H0000000000800000;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/nonseq_txfer_pending ),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/ctl_sm_ns1 ),
    .I4(\U0/idle_txfer_pending ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6 .INIT = 64'H00000100FFFFFFFF;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_reg_i_2 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_5_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/S_AHB_HRESP_i_i_6_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/AHBLITE_AXI_CONTROL/set_hresp_err )
    );
    xs1 \U0/AHBLITE_AXI_CONTROL/VCC 
    (
    .P(\U0/AHBLITE_AXI_CONTROL/<const1> )
    );
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I2(s_ahb_hwrite),
    .I3(\U0/burst_term_hwrite ),
    .I4(\U0/ctl_sm_ns14_out ),
    .I5(\U0/ctl_sm_ns033_out ),
    .O(\U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3 .INIT = 64'H4440000000000000;
    xsDFFSA_K1R1E1 \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .D(\U0/set_axi_waddr ),
    .R(\U0/cntr_rst ),
    .Q(\U0/axi_waddr_done_i )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_reg .INIT = 1'B0;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_reg_i_1 
    (
    .I0(\U0/AHB_IF_n_21 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/ahb_wnr_i_i_3_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/set_axi_waddr )
    );
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_1 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2_n_0 ),
    .I1(s_ahb_hresetn),
    .I2(\U0/AXI_WCHANNEL_n_13 ),
    .I3(\U0/init_pending_txfer ),
    .I4(\U0/burst_term ),
    .I5(\U0/last_axi_rd_sample ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_16 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_1 .INIT = 64'H00000000000C0404;
    xsLUTSA4 \U0/AHBLITE_AXI_CONTROL/burst_term_single_incr_i_1 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I2(\U0/burst_term_with_nonseq ),
    .I3(\U0/burst_term_single_incr ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_20 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/burst_term_single_incr_i_1 .INIT = 16'HFF10;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/burst_term_txer_cnt_i[3]_i_2 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(\U0/ahb_done_axi_in_progress ),
    .I4(\U0/AHB_IF_n_3 ),
    .I5(\U0/seq_detected ),
    .O(\U0/p_12_in )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/burst_term_txer_cnt_i[3]_i_2 .INIT = 64'H00FEFEFEFEFEFEFE;
    xsLUTSA4 \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_1 
    (
    .I0(\U0/idle_txfer_pending ),
    .I1(\U0/AHBLITE_AXI_CONTROL/AHB_IF/p_9_in ),
    .I2(s_ahb_hresetn),
    .I3(\U0/init_pending_txfer ),
    .O(\U0/AHBLITE_AXI_CONTROL_n_14 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_1 .INIT = 16'H00E0;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/nonseq_txfer_pending ),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/idle_txfer_pending ),
    .I4(m_axi_bvalid),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3 .INIT = 64'HFFFD555500000000;
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I1(\U0/nonseq_txfer_pending ),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/idle_txfer_pending ),
    .I4(\U0/ctl_sm_ns033_out ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .O(\U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4_n_0 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4 .INIT = 64'H5554000000000000;
    xsMUXF7 \U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_reg_i_2 
    (
    .I0(\U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_3_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL/idle_txfer_pending_i_4_n_0 ),
    .S(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .O(\U0/init_pending_txfer )
    );
    xsLUTSA6 \U0/AHBLITE_AXI_CONTROL/nonseq_txfer_pending_i_i_2 
    (
    .I0(\U0/ahb_burst_done ),
    .I1(\U0/ahb_done_axi_in_progress ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I4(\U0/AHBLITE_AXI_CONTROL/ctl_sm_cs[2] ),
    .I5(\U0/nonseq_detected ),
    .O(\U0/burst_term_with_nonseq )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/nonseq_txfer_pending_i_i_2 .INIT = 64'H7777777000000000;
    xsLUTSA6_2 \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2 
    (
    .I0(\U0/p_12_in ),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_htrans[1]),
    .I3(s_ahb_hready_in),
    .I4(s_ahb_hsel),
    .I5(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .O6(\U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2_n_0 ),
    .O5(\U0/AHBLITE_AXI_CONTROL/AHB_IF/p_9_in )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/burst_term_i_i_2 .INIT = 64'HDDFFFFFF02000000;
    xsLUTSA6_2 \U0/AHBLITE_AXI_CONTROL/nonseq_txfer_pending_i_i_1 
    (
    .I0(s_ahb_hwrite),
    .I1(\U0/burst_term_with_nonseq ),
    .I2(\U0/burst_term_hwrite ),
    .I3(\U0/init_pending_txfer ),
    .I4(\U0/nonseq_txfer_pending ),
    .I5(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .O6(\U0/AHBLITE_AXI_CONTROL_n_15 ),
    .O5(\U0/AHBLITE_AXI_CONTROL_n_18 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/nonseq_txfer_pending_i_i_1 .INIT = 64'HCCFFCCCCB8B8B8B8;
    xsLUTSA6_2 \U0/AHBLITE_AXI_CONTROL/M_AXI_AWVALID_i_i_1 
    (
    .I0(\U0/set_axi_waddr ),
    .I1(m_axi_wready),
    .I2(m_axi_wvalid),
    .I3(m_axi_awready),
    .I4(m_axi_awvalid),
    .I5(\U0/AHBLITE_AXI_CONTROL/<const1> ),
    .O6(\U0/AHBLITE_AXI_CONTROL_n_12 ),
    .O5(\U0/AHBLITE_AXI_CONTROL_n_6 )
    );
    defparam \U0/AHBLITE_AXI_CONTROL/M_AXI_AWVALID_i_i_1 .INIT = 64'HAAFFAAAAEAEAEAEA;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[0]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[0])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[10] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[10]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[10])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[10] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[11] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[11]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[11])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[11] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[12] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[12]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[12])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[12] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[13] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[13]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[13])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[13] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[14] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[14]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[14])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[14] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[15] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[15]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[15])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[15] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[16] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[16]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[16])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[16] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[17] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[17]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[17])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[17] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[18] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[18]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[18])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[18] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[19] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[19]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[19])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[19] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[1]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[1])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[20] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[20]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[20])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[20] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[21] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[21]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[21])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[21] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[22] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[22]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[22])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[22] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[23] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[23]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[23])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[23] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[24] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[24]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[24])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[24] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[25] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[25]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[25])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[25] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[26] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[26]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[26])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[26] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[27] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[27]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[27])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[27] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[28] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[28]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[28])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[28] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[29] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[29]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[29])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[29] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[2]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[2])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[30] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[30]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[30])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[30] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[31] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[31]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[31])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[31] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[3]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[3])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[4]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[4])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[5] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[5]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[5])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[5] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[6] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[6]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[6])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[6] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[7] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[7]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[7])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[7] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[8] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[8]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[8])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[8] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_AADDR_i_reg[9] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_haddr[9]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_araddr[9])
    );
    defparam \U0/AHB_IF/AXI_AADDR_i_reg[9] .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_IF/AXI_ABURST_i[0]_i_1 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I2(s_ahb_hburst[0]),
    .I3(\U0/AXI_ALEN_i0 ),
    .I4(s_ahb_hresetn),
    .I5(m_axi_arburst[0]),
    .O(\U0/AHB_IF/AXI_ABURST_i[0]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/AXI_ABURST_i[0]_i_1 .INIT = 64'HF1FF0000F1000000;
    xsLUTSA6 \U0/AHB_IF/AXI_ABURST_i[1]_i_1 
    (
    .I0(s_ahb_hburst[0]),
    .I1(s_ahb_hburst[1]),
    .I2(s_ahb_hburst[2]),
    .I3(\U0/AXI_ALEN_i0 ),
    .I4(s_ahb_hresetn),
    .I5(m_axi_arburst[1]),
    .O(\U0/AHB_IF/AXI_ABURST_i[1]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/AXI_ABURST_i[1]_i_1 .INIT = 64'H54FF000054000000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ABURST_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/AXI_ABURST_i[0]_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(m_axi_arburst[0])
    );
    defparam \U0/AHB_IF/AXI_ABURST_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ABURST_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/AXI_ABURST_i[1]_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(m_axi_arburst[1])
    );
    defparam \U0/AHB_IF/AXI_ABURST_i_reg[1] .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/AXI_ALEN_i[3]_i_1 
    (
    .I0(\U0/ahb_hburst_incr ),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_hsel),
    .I4(s_ahb_htrans[1]),
    .O(\U0/AXI_ALEN_i0 )
    );
    defparam \U0/AHB_IF/AXI_ALEN_i[3]_i_1 .INIT = 32'HB0000000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ALEN_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(\U0/AHB_IF/AXI_ALEN_i[1] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arlen[1])
    );
    defparam \U0/AHB_IF/AXI_ALEN_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ALEN_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_hburst[2]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arlen[2])
    );
    defparam \U0/AHB_IF/AXI_ALEN_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ALEN_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(\U0/AHB_IF/AXI_ALEN_i[3] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arlen[3])
    );
    defparam \U0/AHB_IF/AXI_ALEN_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ASIZE_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(s_ahb_hsize[0]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arsize[0])
    );
    defparam \U0/AHB_IF/AXI_ASIZE_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ASIZE_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(s_ahb_hsize[1]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arsize[1])
    );
    defparam \U0/AHB_IF/AXI_ASIZE_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/AXI_ASIZE_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(s_ahb_hsize[2]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arsize[2])
    );
    defparam \U0/AHB_IF/AXI_ASIZE_i_reg[2] .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/FSM_sequential_ctl_sm_cs[1]_i_2 
    (
    .I0(\U0/ctl_sm_ns1 ),
    .I1(\U0/nonseq_detected ),
    .I2(\U0/nonseq_txfer_pending ),
    .I3(\U0/idle_txfer_pending ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHB_IF_n_23 )
    );
    defparam \U0/AHB_IF/FSM_sequential_ctl_sm_cs[1]_i_2 .INIT = 32'H00000002;
    xsLUTSA6 \U0/AHB_IF/FSM_sequential_ctl_sm_cs[2]_i_3 
    (
    .I0(\U0/idle_txfer_pending ),
    .I1(m_axi_bresp[1]),
    .I2(\U0/ctl_sm_ns14_out ),
    .I3(m_axi_bvalid),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I5(\U0/axi_waddr_done_i ),
    .O(\U0/AHB_IF_n_24 )
    );
    defparam \U0/AHB_IF/FSM_sequential_ctl_sm_cs[2]_i_3 .INIT = 64'H040000000400FFFF;
    xsDFFSA_K1S1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_ACACHE_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_hprot[2]),
    .S(\U0/cntr_rst ),
    .Q(m_axi_arcache[0])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_ACACHE_i_reg[0] .INIT = 1'B1;
    xsDFFSA_K1S1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_ACACHE_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_hprot[3]),
    .S(\U0/cntr_rst ),
    .Q(m_axi_arcache[1])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_ACACHE_i_reg[1] .INIT = 1'B1;
    xsLUTSA3 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1 
    (
    .I0(m_axi_arprot[1]),
    .I1(s_ahb_hresetn),
    .I2(\U0/AXI_ALEN_i0 ),
    .O(\U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1 .INIT = 8'HFB;
    xsLUTSA1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[2]_i_1 
    (
    .I0(s_ahb_hprot[0]),
    .O(\U0/AHB_IF/p_1_out[2] )
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[2]_i_1 .INIT = 2'H1;
    xsDFFSA_K1R1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(s_ahb_hprot[1]),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arprot[0])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i[1]_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(m_axi_arprot[1])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_ALEN_i0 ),
    .D(\U0/AHB_IF/p_1_out[2] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arprot[2])
    );
    defparam \U0/AHB_IF/GEN_1_PROT_CACHE_REG_NON_SECURE.AXI_APROT_i_reg[2] .INIT = 1'B0;
    xs0 \U0/AHB_IF/GND 
    (
    .G(\U0/AHB_IF/<const0> )
    );
    xsLUTSA6 \U0/AHB_IF/INFERRED_GEN.icount_out[4]_i_1__0 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_hsel),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_htrans[0]),
    .I4(s_ahb_hwrite),
    .I5(\U0/ahb_hburst_incr ),
    .O(\U0/AHB_IF_n_30 )
    );
    defparam \U0/AHB_IF/INFERRED_GEN.icount_out[4]_i_1__0 .INIT = 64'H0080008080800080;
    xsLUTSA6 \U0/AHB_IF/M_AXI_ARVALID_i_i_3 
    (
    .I0(\U0/burst_term_hwrite ),
    .I1(\U0/AHB_IF/AHBLITE_AXI_CONTROL/ctl_sm_ns132_out ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(s_ahb_hwrite),
    .I4(\U0/AXI_ALEN_i0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHB_IF_n_22 )
    );
    defparam \U0/AHB_IF/M_AXI_ARVALID_i_i_3 .INIT = 64'H40C040C0000F0000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[0]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[0])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[10] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[10]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[10])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[10] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[11] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[11]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[11])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[11] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[12] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[12]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[12])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[12] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[13] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[13]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[13])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[13] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[14] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[14]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[14])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[14] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[15] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[15]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[15])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[15] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[16] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[16]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[16])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[16] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[17] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[17]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[17])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[17] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[18] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[18]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[18])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[18] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[19] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[19]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[19])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[19] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[1]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[1])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[20] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[20]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[20])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[20] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[21] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[21]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[21])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[21] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[22] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[22]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[22])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[22] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[23] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[23]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[23])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[23] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[24] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[24]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[24])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[24] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[25] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[25]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[25])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[25] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[26] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[26]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[26])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[26] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[27] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[27]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[27])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[27] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[28] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[28]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[28])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[28] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[29] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[29]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[29])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[29] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[2]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[2])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[30] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[30]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[30])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[30] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[31] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[31]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[31])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[31] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[3]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[3])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[4]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[4])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[5] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[5]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[5])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[5] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[6] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[6]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[6])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[6] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[7] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[7]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[7])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[7] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[8] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[8]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[8])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[8] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRDATA_i_reg[9] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/rd_load_timeout_cntr ),
    .D(m_axi_rdata[9]),
    .R(\U0/cntr_rst ),
    .Q(s_ahb_hrdata[9])
    );
    defparam \U0/AHB_IF/S_AHB_HRDATA_i_reg[9] .INIT = 1'B0;
    xsLUTSA1 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_1 
    (
    .I0(s_ahb_hresetn),
    .O(\U0/cntr_rst )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_1 .INIT = 2'H1;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_11 
    (
    .I0(\U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17_n_0 ),
    .I1(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I2(\U0/axi_waddr_done_i ),
    .I3(s_ahb_hwrite),
    .I4(\U0/ahb_hburst_single ),
    .I5(\U0/ahb_hburst_incr ),
    .O(\U0/AHB_IF_n_18 )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_11 .INIT = 64'HB8B8B8B8B8B888B8;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_12 
    (
    .I0(\U0/AHB_IF/AHBLITE_AXI_CONTROL/reset_hready2__0 ),
    .I1(\U0/AXI_WCHANNEL_n_12 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .I3(\U0/AXI_ALEN_i0 ),
    .I4(s_ahb_hwrite),
    .I5(\U0/AHB_IF/AHBLITE_AXI_CONTROL/hburst_single_incr ),
    .O(\U0/AHB_IF_n_19 )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_12 .INIT = 64'HBFB0BFB0B0B0BFB0;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17 
    (
    .I0(\U0/reset_hready010_out ),
    .I1(m_axi_bvalid),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/nonseq_txfer_pending ),
    .I4(m_axi_bresp[1]),
    .I5(\U0/idle_txfer_pending ),
    .O(\U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17_n_0 )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_17 .INIT = 64'H88808880888C8880;
    xsLUTSA5 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_20 
    (
    .I0(m_axi_bresp[1]),
    .I1(\U0/idle_txfer_pending ),
    .I2(\U0/nonseq_txfer_pending ),
    .I3(\U0/nonseq_detected ),
    .I4(m_axi_bvalid),
    .O(\U0/AHB_IF_n_14 )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_20 .INIT = 32'H000D0000;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_4 
    (
    .I0(\U0/nonseq_txfer_pending ),
    .I1(\U0/burst_term_with_nonseq ),
    .I2(\U0/ahb_done_axi_in_progress ),
    .I3(\U0/AHB_IF/S_AHB_HREADY_OUT_i_i_8_n_0 ),
    .I4(s_ahb_hwrite),
    .I5(\U0/ahb_burst_done ),
    .O(\U0/S_AHB_HREADY_OUT_i116_out )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_4 .INIT = 64'HFFFFFFFEFEFEFFFE;
    xsDFFSA_K1S1E1 \U0/AHB_IF/S_AHB_HREADY_OUT_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_13 ),
    .S(\U0/cntr_rst ),
    .Q(s_ahb_hready_out)
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_reg .INIT = 1'B1;
    xsLUTSA6 \U0/AHB_IF/S_AHB_HRESP_i_i_4 
    (
    .I0(m_axi_bvalid),
    .I1(\U0/ctl_sm_ns14_out ),
    .I2(\U0/idle_txfer_pending ),
    .I3(m_axi_bresp[1]),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHB_IF_n_16 )
    );
    defparam \U0/AHB_IF/S_AHB_HRESP_i_i_4 .INIT = 64'H202200000000FFFF;
    xsDFFSA_K1R1E1 \U0/AHB_IF/S_AHB_HRESP_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_17 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(s_ahb_hresp)
    );
    defparam \U0/AHB_IF/S_AHB_HRESP_i_reg .INIT = 1'B0;
    xs1 \U0/AHB_IF/VCC 
    (
    .P(\U0/AHB_IF/<const1> )
    );
    xsLUTSA3 \U0/AHB_IF/ahb_data_valid_burst_term_i_1 
    (
    .I0(\U0/nonseq_txfer_pending ),
    .I1(\U0/init_pending_txfer ),
    .I2(\U0/ahb_data_valid_burst_term ),
    .O(\U0/AHB_IF_n_39 )
    );
    defparam \U0/AHB_IF/ahb_data_valid_burst_term_i_1 .INIT = 8'HBA;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_data_valid_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AXI_WCHANNEL_n_14 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_data_valid )
    );
    defparam \U0/AHB_IF/ahb_data_valid_i_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/ahb_done_axi_in_progress_i_1 
    (
    .I0(\U0/seq_detected ),
    .I1(\U0/AHB_IF_n_3 ),
    .I2(m_axi_wlast),
    .I3(m_axi_wready),
    .I4(\U0/ahb_done_axi_in_progress ),
    .O(\U0/AHB_IF/ahb_done_axi_in_progress_i_1_n_0 )
    );
    defparam \U0/AHB_IF/ahb_done_axi_in_progress_i_1 .INIT = 32'H8FFF8888;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_done_axi_in_progress_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/ahb_done_axi_in_progress_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_done_axi_in_progress )
    );
    defparam \U0/AHB_IF/ahb_done_axi_in_progress_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/ahb_hburst_incr_i_i_1 
    (
    .I0(\U0/AHB_IF/eqOp ),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_htrans[1]),
    .I3(s_ahb_hready_out),
    .I4(\U0/ahb_hburst_incr ),
    .O(\U0/AHB_IF/ahb_hburst_incr_i_i_1_n_0 )
    );
    defparam \U0/AHB_IF/ahb_hburst_incr_i_i_1 .INIT = 32'HEFFF2000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_hburst_incr_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/ahb_hburst_incr_i_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_hburst_incr )
    );
    defparam \U0/AHB_IF/ahb_hburst_incr_i_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/ahb_hburst_single_i_i_1 
    (
    .I0(\U0/AHB_IF/eqOp0_in ),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_htrans[1]),
    .I3(s_ahb_hready_out),
    .I4(\U0/ahb_hburst_single ),
    .O(\U0/AHB_IF/ahb_hburst_single_i_i_1_n_0 )
    );
    defparam \U0/AHB_IF/ahb_hburst_single_i_i_1 .INIT = 32'HEFFF2000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_hburst_single_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/ahb_hburst_single_i_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_hburst_single )
    );
    defparam \U0/AHB_IF/ahb_hburst_single_i_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_IF/ahb_penult_beat_i_1 
    (
    .I0(\U0/AHB_IF_n_3 ),
    .I1(s_ahb_hresetn),
    .I2(\U0/AHB_DATA_COUNTER_n_5 ),
    .I3(\U0/p_27_in ),
    .I4(s_ahb_htrans[1]),
    .I5(s_ahb_htrans[0]),
    .O(\U0/AHB_IF/ahb_penult_beat_i_1_n_0 )
    );
    defparam \U0/AHB_IF/ahb_penult_beat_i_1 .INIT = 64'HC008080800080008;
    xsDFFSA_K1R1E1 \U0/AHB_IF/ahb_penult_beat_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/ahb_penult_beat_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(\U0/AHB_IF_n_3 )
    );
    defparam \U0/AHB_IF/ahb_penult_beat_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_IF/ahb_wnr_i_i_2 
    (
    .I0(\U0/burst_term_hwrite ),
    .I1(\U0/AHB_IF/AHBLITE_AXI_CONTROL/ctl_sm_ns132_out ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_1 ),
    .I3(s_ahb_hwrite),
    .I4(\U0/AXI_ALEN_i0 ),
    .I5(\U0/AHBLITE_AXI_CONTROL_n_0 ),
    .O(\U0/AHB_IF_n_21 )
    );
    defparam \U0/AHB_IF/ahb_wnr_i_i_2 .INIT = 64'HC080C0800F000000;
    xsLUTSA6 \U0/AHB_IF/ahb_wnr_i_i_4 
    (
    .I0(m_axi_bvalid),
    .I1(s_ahb_hsel),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_htrans[0]),
    .I4(s_ahb_htrans[1]),
    .I5(\U0/nonseq_txfer_pending ),
    .O(\U0/AHB_IF/AHBLITE_AXI_CONTROL/ctl_sm_ns132_out )
    );
    defparam \U0/AHB_IF/ahb_wnr_i_i_4 .INIT = 64'HAAAAAAAA00800000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_4 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[0] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_3 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[1] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_2 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[2] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_1 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[3] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_cur_cnt_i_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/AHB_DATA_COUNTER_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_cur_cnt[4] )
    );
    defparam \U0/AHB_IF/burst_term_cur_cnt_i_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_hwrite_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_18 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_hwrite )
    );
    defparam \U0/AHB_IF/burst_term_hwrite_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_16 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(\U0/burst_term )
    );
    defparam \U0/AHB_IF/burst_term_i_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_single_incr_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_20 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_single_incr )
    );
    defparam \U0/AHB_IF/burst_term_single_incr_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/burst_term_txer_cnt_i[3]_i_1 
    (
    .I0(\U0/burst_term ),
    .I1(\U0/p_12_in ),
    .I2(s_ahb_htrans[0]),
    .I3(s_ahb_hready_in),
    .I4(s_ahb_hsel),
    .O(\U0/AHB_IF/burst_term_txer_cnt_i0 )
    );
    defparam \U0/AHB_IF/burst_term_txer_cnt_i[3]_i_1 .INIT = 32'H04000000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_txer_cnt_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/valid_cnt_required[1] ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_txer_cnt[1] )
    );
    defparam \U0/AHB_IF/burst_term_txer_cnt_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_txer_cnt_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/valid_cnt_required[2] ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_txer_cnt[2] )
    );
    defparam \U0/AHB_IF/burst_term_txer_cnt_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/burst_term_txer_cnt_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/burst_term_txer_cnt_i0 ),
    .D(\U0/valid_cnt_required[3] ),
    .R(\U0/cntr_rst ),
    .Q(\U0/burst_term_txer_cnt[3] )
    );
    defparam \U0/AHB_IF/burst_term_txer_cnt_i_reg[3] .INIT = 1'B0;
    xsLUTSA5 \U0/AHB_IF/dummy_on_axi_progress_i_3 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/burst_term_cur_cnt[3] ),
    .I2(\U0/AHB_IF/dummy_on_axi_progress_i_5_n_0 ),
    .I3(\U0/burst_term_cur_cnt[4] ),
    .I4(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/eqOp6_out )
    );
    defparam \U0/AHB_IF/dummy_on_axi_progress_i_3 .INIT = 32'H90000090;
    xsLUTSA6 \U0/AHB_IF/dummy_on_axi_progress_i_5 
    (
    .I0(\U0/burst_term_cur_cnt[0] ),
    .I1(\U0/AXI_WCHANNEL_n_10 ),
    .I2(\U0/burst_term_cur_cnt[2] ),
    .I3(\U0/AXI_WCHANNEL_n_8 ),
    .I4(\U0/burst_term_cur_cnt[1] ),
    .I5(\U0/AXI_WCHANNEL_n_9 ),
    .O(\U0/AHB_IF/dummy_on_axi_progress_i_5_n_0 )
    );
    defparam \U0/AHB_IF/dummy_on_axi_progress_i_5 .INIT = 64'H9009000000009009;
    xsLUTSA3 \U0/AHB_IF/dummy_on_axi_progress_i_7 
    (
    .I0(\U0/burst_term_cur_cnt[1] ),
    .I1(\U0/burst_term_cur_cnt[0] ),
    .I2(\U0/burst_term_cur_cnt[2] ),
    .O(\U0/AHB_IF_n_32 )
    );
    defparam \U0/AHB_IF/dummy_on_axi_progress_i_7 .INIT = 8'HFE;
    xsLUTSA6 \U0/AHB_IF/dummy_txfer_in_progress_i_1 
    (
    .I0(\U0/AHB_IF_n_12 ),
    .I1(\U0/burst_term ),
    .I2(s_ahb_hresetn),
    .I3(\U0/init_pending_txfer ),
    .I4(m_axi_wlast),
    .I5(m_axi_wready),
    .O(\U0/AHB_IF/dummy_txfer_in_progress_i_1_n_0 )
    );
    defparam \U0/AHB_IF/dummy_txfer_in_progress_i_1 .INIT = 64'HC0C000A000A000A0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/dummy_txfer_in_progress_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/dummy_txfer_in_progress_i_1_n_0 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(\U0/AHB_IF_n_12 )
    );
    defparam \U0/AHB_IF/dummy_txfer_in_progress_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/idle_txfer_pending_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_14 ),
    .R(\U0/AHB_IF/<const0> ),
    .Q(\U0/idle_txfer_pending )
    );
    defparam \U0/AHB_IF/idle_txfer_pending_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/nonseq_txfer_pending_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_15 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/nonseq_txfer_pending )
    );
    defparam \U0/AHB_IF/nonseq_txfer_pending_i_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_IF/valid_cnt_required_i[2]_i_1 
    (
    .I0(s_ahb_hburst[2]),
    .I1(s_ahb_hsel),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_htrans[0]),
    .I4(s_ahb_htrans[1]),
    .I5(\U0/valid_cnt_required[2] ),
    .O(\U0/AHB_IF/valid_cnt_required_i[2]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i[2]_i_1 .INIT = 64'HFFBFFFFF00800000;
    xsDFFSA_K1R1E1 \U0/AHB_IF/valid_cnt_required_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/valid_cnt_required_i[1]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/valid_cnt_required[1] )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/valid_cnt_required_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/valid_cnt_required_i[2]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/valid_cnt_required[2] )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_IF/valid_cnt_required_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF/<const1> ),
    .D(\U0/AHB_IF/valid_cnt_required_i[3]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/valid_cnt_required[3] )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i_reg[3] .INIT = 1'B0;
    xsLUTSA6_2 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_18 
    (
    .I0(\U0/axi_waddr_done_i ),
    .I1(\U0/ahb_hburst_incr ),
    .I2(\U0/ahb_hburst_single ),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/AHB_IF/AHBLITE_AXI_CONTROL/reset_hready2__0 ),
    .O5(\U0/M_AXI_WLAST_i110_out )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_18 .INIT = 64'HFCFCFCFCA8A8A8A8;
    xsLUTSA6_2 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_19 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/AHB_IF/AHBLITE_AXI_CONTROL/hburst_single_incr ),
    .O5(\U0/AHB_IF/AXI_ALEN_i[1] )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_19 .INIT = 64'H11111111EEEEEEEE;
    xsLUTSA6_2 \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_15 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I2(\U0/burst_term_single_incr ),
    .I3(\U0/burst_term_hwrite ),
    .I4(s_ahb_hwrite),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/reset_hready010_out ),
    .O5(\U0/AHB_IF/AXI_ALEN_i[3] )
    );
    defparam \U0/AHB_IF/S_AHB_HREADY_OUT_i_i_15 .INIT = 64'HF1FFFFFF88888888;
    xsLUTSA6_2 \U0/AHB_IF/S_AHB_HRESP_i_i_9 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_hready_in),
    .I2(s_ahb_hsel),
    .I3(s_ahb_htrans[0]),
    .I4(\U0/nonseq_txfer_pending ),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/ctl_sm_ns14_out ),
    .O5(\U0/busy_detected )
    );
    defparam \U0/AHB_IF/S_AHB_HRESP_i_i_9 .INIT = 64'HFFFF008040004000;
    xsLUTSA6_2 \U0/AHB_IF/valid_cnt_required_i[3]_i_2 
    (
    .I0(\U0/AHB_IF_n_3 ),
    .I1(s_ahb_htrans[1]),
    .I2(s_ahb_hsel),
    .I3(s_ahb_hready_in),
    .I4(s_ahb_htrans[0]),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/nonseq_detected ),
    .O5(\U0/ahb_burst_done )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i[3]_i_2 .INIT = 64'H0000C00080000000;
    xsLUTSA6_2 \U0/AHB_IF/ahb_penult_beat_i_3 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_hsel),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_htrans[0]),
    .I4(\U0/ahb_hburst_incr ),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/p_27_in ),
    .O5(\U0/AHB_IF/S_AHB_HREADY_OUT_i_i_8_n_0 )
    );
    defparam \U0/AHB_IF/ahb_penult_beat_i_3 .INIT = 64'HC0C0C0C080000000;
    xsLUTSA6_2 \U0/AHB_IF/valid_cnt_required_i[3]_i_1 
    (
    .I0(s_ahb_hburst[1]),
    .I1(s_ahb_hburst[2]),
    .I2(\U0/nonseq_detected ),
    .I3(\U0/valid_cnt_required[1] ),
    .I4(\U0/valid_cnt_required[3] ),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/AHB_IF/valid_cnt_required_i[3]_i_1_n_0 ),
    .O5(\U0/AHB_IF/valid_cnt_required_i[1]_i_1_n_0 )
    );
    defparam \U0/AHB_IF/valid_cnt_required_i[3]_i_1 .INIT = 64'H8F8F8080EFE0EFE0;
    xsLUTSA6_2 \U0/AHB_IF/ahb_hburst_single_i_i_2 
    (
    .I0(s_ahb_hburst[2]),
    .I1(s_ahb_hburst[0]),
    .I2(s_ahb_hburst[1]),
    .I5(\U0/AHB_IF/<const1> ),
    .O6(\U0/AHB_IF/eqOp0_in ),
    .O5(\U0/AHB_IF/eqOp )
    );
    defparam \U0/AHB_IF/ahb_hburst_single_i_i_2 .INIT = 64'H0101010104040404;
    xs0 \U0/AXI_RCHANNEL/GND 
    (
    .G(\U0/AXI_RCHANNEL/<const0> )
    );
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/M_AXI_ARVALID_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_11 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_arvalid)
    );
    defparam \U0/AXI_RCHANNEL/M_AXI_ARVALID_i_reg .INIT = 1'B0;
    xsLUTSA4 \U0/AXI_RCHANNEL/M_AXI_RLAST_reg_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/axi_last_avlbl_reg_n_0 ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I2(m_axi_rlast),
    .I3(m_axi_rvalid),
    .O(\U0/last_axi_rd_sample )
    );
    defparam \U0/AXI_RCHANNEL/M_AXI_RLAST_reg_i_1 .INIT = 16'HBAAA;
    xsLUTSA6 \U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1 
    (
    .I0(m_axi_arvalid),
    .I1(m_axi_arready),
    .I2(\U0/seq_detected ),
    .I3(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I4(\U0/AHBLITE_AXI_CONTROL_n_7 ),
    .I5(m_axi_rready),
    .O(\U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1 .INIT = 64'H8888FFFF8888FFF8;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/M_AXI_RREADY_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/M_AXI_RREADY_i_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_rready)
    );
    defparam \U0/AXI_RCHANNEL/M_AXI_RREADY_i_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_10 
    (
    .I0(\U0/ctl_sm_ns033_out ),
    .I1(\U0/reset_hready010_out ),
    .I2(\U0/ctl_sm_ns14_out ),
    .I3(\U0/AXI_RCHANNEL/rvalid_rready ),
    .I4(\U0/ctl_sm_ns1 ),
    .I5(\U0/idle_txfer_pending ),
    .O(\U0/AXI_RCHANNEL_n_5 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_10 .INIT = 64'H808080808F8F808F;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_16 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I2(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I3(m_axi_rready),
    .I4(m_axi_rvalid),
    .I5(\U0/busy_detected ),
    .O(\U0/AXI_RCHANNEL/rvalid_rready )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_16 .INIT = 64'H888888888F888888;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_21 
    (
    .I0(m_axi_rresp[1]),
    .I1(\U0/rd_load_timeout_cntr ),
    .I2(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I3(\U0/busy_detected ),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_txer_pending07_out__0 ),
    .I5(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1] ),
    .O(\U0/AXI_RCHANNEL_n_3 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HREADY_OUT_i_i_21 .INIT = 64'H00040004FFF70004;
    xsLUTSA2 \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_10 
    (
    .I0(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I1(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .O(\U0/AXI_RCHANNEL/ahb_rd_txer_pending07_out__0 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_10 .INIT = 4'H8;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_7 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1] ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending07_out__0 ),
    .I2(\U0/busy_detected ),
    .I3(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I4(\U0/rd_load_timeout_cntr ),
    .I5(m_axi_rresp[1]),
    .O(\U0/ctl_sm_ns1 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_7 .INIT = 64'H888F888888808888;
    xsLUTSA6 \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_8 
    (
    .I0(\U0/busy_detected ),
    .I1(\U0/rd_load_timeout_cntr ),
    .I2(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I3(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I4(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I5(\U0/last_axi_rd_sample ),
    .O(\U0/ctl_sm_ns033_out )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HRESP_i_i_8 .INIT = 64'HFF04040400000000;
    xs1 \U0/AXI_RCHANNEL/VCC 
    (
    .P(\U0/AXI_RCHANNEL/<const1> )
    );
    xsLUTSA6 \U0/AXI_RCHANNEL/ahb_rd_req_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/seq_detected_d1 ),
    .I1(\U0/seq_detected ),
    .I2(s_ahb_hresetn),
    .I3(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I5(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .O(\U0/AXI_RCHANNEL/ahb_rd_req_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/ahb_rd_req_i_1 .INIT = 64'H00F04040B0B00000;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/ahb_rd_req_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/ahb_rd_req_i_1_n_0 ),
    .R(\U0/AXI_RCHANNEL/<const0> ),
    .Q(\U0/AXI_RCHANNEL/ahb_rd_req )
    );
    defparam \U0/AXI_RCHANNEL/ahb_rd_req_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I1(\U0/AXI_RCHANNEL/bridge_rd_in_progress ),
    .I2(\U0/busy_detected ),
    .I3(s_ahb_hresetn),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I5(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .O(\U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1 .INIT = 64'H0000EA00EA00EA00;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/ahb_rd_txer_pending_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/ahb_rd_txer_pending_i_1_n_0 ),
    .R(\U0/AXI_RCHANNEL/<const0> ),
    .Q(\U0/AXI_RCHANNEL/ahb_rd_txer_pending )
    );
    defparam \U0/AXI_RCHANNEL/ahb_rd_txer_pending_reg .INIT = 1'B0;
    xsLUTSA3 \U0/AXI_RCHANNEL/axi_last_avlbl_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I2(s_ahb_hresetn),
    .O(\U0/AXI_RCHANNEL/axi_last_avlbl_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_last_avlbl_i_1 .INIT = 8'H8F;
    xsLUTSA6 \U0/AXI_RCHANNEL/axi_last_avlbl_i_2 
    (
    .I0(m_axi_rlast),
    .I1(m_axi_rready),
    .I2(m_axi_rvalid),
    .I3(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I4(\U0/busy_detected ),
    .I5(\U0/AXI_RCHANNEL/axi_last_avlbl_reg_n_0 ),
    .O(\U0/AXI_RCHANNEL/axi_last_avlbl_i_2_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_last_avlbl_i_2 .INIT = 64'HBFBFBFFF80808000;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/axi_last_avlbl_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/axi_last_avlbl_i_2_n_0 ),
    .R(\U0/AXI_RCHANNEL/axi_last_avlbl_i_1_n_0 ),
    .Q(\U0/AXI_RCHANNEL/axi_last_avlbl_reg_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_last_avlbl_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_RCHANNEL/axi_rd_avlbl_i_1 
    (
    .I0(\U0/rd_load_timeout_cntr ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I2(\U0/busy_detected ),
    .I3(s_ahb_hresetn),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I5(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .O(\U0/AXI_RCHANNEL/axi_rd_avlbl_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_rd_avlbl_i_1 .INIT = 64'H0000FF00A800A800;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/axi_rd_avlbl_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/axi_rd_avlbl_i_1_n_0 ),
    .R(\U0/AXI_RCHANNEL/<const0> ),
    .Q(\U0/AXI_RCHANNEL/axi_rd_avlbl )
    );
    defparam \U0/AXI_RCHANNEL/axi_rd_avlbl_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1] ),
    .I1(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2_n_0 ),
    .I2(m_axi_rresp[1]),
    .I3(s_ahb_hresetn),
    .I4(\U0/AXI_RCHANNEL/ahb_rd_req ),
    .I5(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .O(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1 .INIT = 64'H0000E200E200E200;
    xsLUTSA6 \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2 
    (
    .I0(\U0/rd_load_timeout_cntr ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I2(s_ahb_htrans[1]),
    .I3(s_ahb_hready_in),
    .I4(s_ahb_hsel),
    .I5(s_ahb_htrans[0]),
    .O(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2_n_0 )
    );
    defparam \U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_2 .INIT = 64'H8A88888888888888;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/axi_rresp_avlbl_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1]_i_1_n_0 ),
    .R(\U0/AXI_RCHANNEL/<const0> ),
    .Q(\U0/AXI_RCHANNEL/axi_rresp_avlbl[1] )
    );
    defparam \U0/AXI_RCHANNEL/axi_rresp_avlbl_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/bridge_rd_in_progress_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_RCHANNEL/bridge_rd_in_progress )
    );
    defparam \U0/AXI_RCHANNEL/bridge_rd_in_progress_reg .INIT = 1'B0;
    xsLUTSA4 \U0/AXI_RCHANNEL/seq_detected_d1_i_1 
    (
    .I0(s_ahb_htrans[0]),
    .I1(s_ahb_hready_in),
    .I2(s_ahb_hsel),
    .I3(s_ahb_htrans[1]),
    .O(\U0/seq_detected )
    );
    defparam \U0/AXI_RCHANNEL/seq_detected_d1_i_1 .INIT = 16'H8000;
    xsDFFSA_K1R1E1 \U0/AXI_RCHANNEL/seq_detected_d1_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_RCHANNEL/<const1> ),
    .D(\U0/seq_detected ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_RCHANNEL/seq_detected_d1 )
    );
    defparam \U0/AXI_RCHANNEL/seq_detected_d1_reg .INIT = 1'B0;
    xsLUTSA6_2 \U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1 
    (
    .I0(m_axi_rready),
    .I1(m_axi_rvalid),
    .I2(m_axi_rlast),
    .I3(m_axi_arvalid),
    .I4(\U0/AXI_RCHANNEL/bridge_rd_in_progress ),
    .I5(\U0/AXI_RCHANNEL/<const1> ),
    .O6(\U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1_n_0 ),
    .O5(\U0/M_AXI_RREADY_i5__0 )
    );
    defparam \U0/AXI_RCHANNEL/bridge_rd_in_progress_i_1 .INIT = 64'HFF7FFF0080808080;
    xsLUTSA6_2 \U0/AXI_RCHANNEL/S_AHB_HRDATA_i[31]_i_1 
    (
    .I0(\U0/AXI_RCHANNEL/axi_rd_avlbl ),
    .I1(\U0/AXI_RCHANNEL/ahb_rd_txer_pending ),
    .I2(m_axi_rvalid),
    .I3(m_axi_rready),
    .I5(\U0/AXI_RCHANNEL/<const1> ),
    .O6(\U0/rd_load_timeout_cntr ),
    .O5(\U0/AXI_RCHANNEL_n_10 )
    );
    defparam \U0/AXI_RCHANNEL/S_AHB_HRDATA_i[31]_i_1 .INIT = 64'HF000F000EAAAEAAA;
    xs0 \U0/AXI_WCHANNEL/GND 
    (
    .G(\U0/AXI_WCHANNEL/<const0> )
    );
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_AWVALID_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_12 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_awvalid)
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_AWVALID_i_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_BREADY_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_19 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_bready)
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_BREADY_i_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[0]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[0] ),
    .I1(s_ahb_hwdata[0]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[0] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[0]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[10]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[10] ),
    .I1(s_ahb_hwdata[10]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[10] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[10]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[11]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[11] ),
    .I1(s_ahb_hwdata[11]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[11] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[11]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[12]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[12] ),
    .I1(s_ahb_hwdata[12]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[12] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[12]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[13]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[13] ),
    .I1(s_ahb_hwdata[13]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[13] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[13]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[14]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[14] ),
    .I1(s_ahb_hwdata[14]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[14] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[14]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[16]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[16] ),
    .I1(s_ahb_hwdata[16]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[16] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[16]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[17]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[17] ),
    .I1(s_ahb_hwdata[17]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[17] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[17]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[18]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[18] ),
    .I1(s_ahb_hwdata[18]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[18] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[18]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[19]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[19] ),
    .I1(s_ahb_hwdata[19]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[19] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[19]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[1]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[1] ),
    .I1(s_ahb_hwdata[1]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[1] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[1]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[20]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[20] ),
    .I1(s_ahb_hwdata[20]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[20] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[20]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[21]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[21] ),
    .I1(s_ahb_hwdata[21]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[21] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[21]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[22]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[22] ),
    .I1(s_ahb_hwdata[22]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[22] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[22]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[23]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[23] ),
    .I1(s_ahb_hwdata[23]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[23] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[23]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[24]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[24] ),
    .I1(s_ahb_hwdata[24]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[24] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[24]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[25]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[25] ),
    .I1(s_ahb_hwdata[25]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[25] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[25]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[26]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[26] ),
    .I1(s_ahb_hwdata[26]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[26] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[26]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[27]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[27] ),
    .I1(s_ahb_hwdata[27]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[27] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[27]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[28]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[28] ),
    .I1(s_ahb_hwdata[28]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[28] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[28]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[29]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[29] ),
    .I1(s_ahb_hwdata[29]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[29] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[29]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[2]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[2] ),
    .I1(s_ahb_hwdata[2]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[2] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[2]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[30]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[30] ),
    .I1(s_ahb_hwdata[30]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[30] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[30]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA2 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1 
    (
    .I0(m_axi_wvalid),
    .I1(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1 .INIT = 4'HD;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_2 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[31] ),
    .I1(s_ahb_hwdata[31]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[31] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_2 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[3]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[3] ),
    .I1(s_ahb_hwdata[3]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[3] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[3]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[4]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[4] ),
    .I1(s_ahb_hwdata[4]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[4] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[4]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[5]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[5] ),
    .I1(s_ahb_hwdata[5]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[5] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[5]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[6]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[6] ),
    .I1(s_ahb_hwdata[6]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[6] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[6]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[7]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[7] ),
    .I1(s_ahb_hwdata[7]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[7] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[7]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[8]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[8] ),
    .I1(s_ahb_hwdata[8]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[8] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[8]_i_1 .INIT = 32'HACACCCAC;
    xsLUTSA5 \U0/AXI_WCHANNEL/M_AXI_WDATA_i[9]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[9] ),
    .I1(s_ahb_hwdata[9]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/p_1_in[9] )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i[9]_i_1 .INIT = 32'HACACCCAC;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[0] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[0])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[10] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[10] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[10])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[10] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[11] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[11] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[11])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[11] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[12] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[12] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[12])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[12] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[13] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[13] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[13])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[13] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[14] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[14] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[14])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[14] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[15] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[15] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[15])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[15] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[16] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[16] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[16])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[16] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[17] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[17] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[17])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[17] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[18] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[18] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[18])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[18] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[19] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[19] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[19])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[19] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[1] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[1])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[20] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[20] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[20])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[20] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[21] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[21] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[21])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[21] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[22] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[22] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[22])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[22] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[23] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[23] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[23])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[23] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[24] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[24] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[24])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[24] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[25] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[25] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[25])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[25] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[26] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[26] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[26])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[26] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[27] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[27] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[27])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[27] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[28] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[28] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[28])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[28] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[29] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[29] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[29])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[29] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[2] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[2])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[30] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[30] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[30])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[30] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[31] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[31] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[31])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[31] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[3] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[3])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[4] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[4])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[5] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[5] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[5])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[5] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[6] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[6] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[6])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[6] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[7] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[7] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[7])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[7] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[8] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[8] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[8])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[8] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[9] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/M_AXI_WDATA_i[31]_i_1_n_0 ),
    .D(\U0/AXI_WCHANNEL/p_1_in[9] ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wdata[9])
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WDATA_i_reg[9] .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/M_AXI_WLAST_i__1 ),
    .I1(\U0/M_AXI_WLAST_i110_out ),
    .I2(m_axi_wlast),
    .I3(m_axi_wready),
    .I4(\U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 ),
    .I5(\U0/AXI_WCHANNEL/axi_last_beat_reg_n_0 ),
    .O(\U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1 .INIT = 64'HCEFECEFECEFECCFC;
    xsLUTSA6 \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_2 
    (
    .I0(m_axi_wready),
    .I1(m_axi_wvalid),
    .I2(\U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 ),
    .I3(\U0/local_en ),
    .I4(\U0/ahb_data_valid ),
    .I5(\U0/burst_term ),
    .O(\U0/AXI_WCHANNEL/M_AXI_WLAST_i__1 )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_2 .INIT = 64'H8F8F8F8F8F8F8F00;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WLAST_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/M_AXI_WLAST_i_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(m_axi_wlast)
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WLAST_i_reg .INIT = 1'B0;
    xsLUTSA6 \U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1 
    (
    .I0(m_axi_wvalid),
    .I1(\U0/AXI_WCHANNEL/dummy_on_axi__0 ),
    .I2(\U0/AHBLITE_AXI_CONTROL_n_10 ),
    .I3(s_ahb_hresetn),
    .I4(m_axi_wready),
    .I5(m_axi_wlast),
    .O(\U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1 .INIT = 64'H0000FE00FC00FE00;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/M_AXI_WVALID_i_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/M_AXI_WVALID_i_i_1_n_0 ),
    .R(\U0/AXI_WCHANNEL/<const0> ),
    .Q(m_axi_wvalid)
    );
    defparam \U0/AXI_WCHANNEL/M_AXI_WVALID_i_reg .INIT = 1'B0;
    xsDFFSA_K1S1E1 \U0/AXI_WCHANNEL/NARROW_TRANSFER_OFF.M_AXI_WSTRB_i_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_5 ),
    .S(\U0/cntr_rst ),
    .Q(m_axi_wstrb[3])
    );
    defparam \U0/AXI_WCHANNEL/NARROW_TRANSFER_OFF.M_AXI_WSTRB_i_reg[3] .INIT = 1'B1;
    xs1 \U0/AXI_WCHANNEL/VCC 
    (
    .P(\U0/AXI_WCHANNEL/<const1> )
    );
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/ahb_data_valid_burst_term_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AHB_IF_n_39 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/ahb_data_valid_burst_term )
    );
    defparam \U0/AXI_WCHANNEL/ahb_data_valid_burst_term_reg .INIT = 1'B0;
    xsLUTSA5 \U0/AXI_WCHANNEL/ahb_data_valid_i_i_1 
    (
    .I0(\U0/local_en ),
    .I1(\U0/AXI_WCHANNEL_n_12 ),
    .I2(\U0/ahb_data_valid ),
    .I3(\U0/p_27_in ),
    .I4(s_ahb_htrans[1]),
    .O(\U0/AXI_WCHANNEL_n_14 )
    );
    defparam \U0/AXI_WCHANNEL/ahb_data_valid_i_i_1 .INIT = 32'HFF200020;
    xsLUTSA3 \U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1 
    (
    .I0(\U0/valid_cnt_required[2] ),
    .I1(\U0/axi_waddr_done_i ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[2] ),
    .O(\U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1 .INIT = 8'HB8;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_cnt_required_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/axi_cnt_required[1]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/axi_cnt_required[1] )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_cnt_required_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/axi_cnt_required[2]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/axi_cnt_required[2] )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_cnt_required_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/axi_cnt_required[3] )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_last_beat_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_8 ),
    .R(\U0/AXI_WCHANNEL/<const0> ),
    .Q(\U0/AXI_WCHANNEL/axi_last_beat_reg_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/axi_last_beat_reg .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/axi_penult_beat_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_7 ),
    .R(\U0/AXI_WCHANNEL/<const0> ),
    .Q(\U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/axi_penult_beat_reg .INIT = 1'B0;
    xsLUTSA3 \U0/AXI_WCHANNEL/burst_term_i_i_3 
    (
    .I0(m_axi_wlast),
    .I1(m_axi_wready),
    .I2(\U0/AHB_IF_n_12 ),
    .O(\U0/AXI_WCHANNEL_n_13 )
    );
    defparam \U0/AXI_WCHANNEL/burst_term_i_i_3 .INIT = 8'HF8;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/dummy_on_axi_progress_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_9 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/dummy_on_axi_progress )
    );
    defparam \U0/AXI_WCHANNEL/dummy_on_axi_progress_reg .INIT = 1'B0;
    xsLUTSA4 \U0/AXI_WCHANNEL/local_en_i_1 
    (
    .I0(m_axi_wvalid),
    .I1(\U0/ahb_data_valid ),
    .I2(\U0/local_en ),
    .I3(m_axi_wready),
    .O(\U0/AXI_WCHANNEL/local_en_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/local_en_i_1 .INIT = 16'H80F8;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_en_reg 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/<const1> ),
    .D(\U0/AXI_WCHANNEL/local_en_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/local_en )
    );
    defparam \U0/AXI_WCHANNEL/local_en_reg .INIT = 1'B0;
    xsLUTSA4 \U0/AXI_WCHANNEL/local_wdata[31]_i_1 
    (
    .I0(m_axi_wready),
    .I1(m_axi_wvalid),
    .I2(\U0/ahb_data_valid ),
    .I3(\U0/local_en ),
    .O(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata[31]_i_1 .INIT = 16'H80FF;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[0]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[0] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[10] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[10]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[10] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[10] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[11] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[11]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[11] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[11] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[12] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[12]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[12] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[12] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[13] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[13]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[13] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[13] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[14] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[14]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[14] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[14] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[15] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[15]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[15] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[15] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[16] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[16]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[16] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[16] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[17] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[17]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[17] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[17] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[18] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[18]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[18] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[18] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[19] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[19]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[19] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[19] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[1]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[1] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[20] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[20]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[20] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[20] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[21] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[21]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[21] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[21] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[22] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[22]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[22] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[22] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[23] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[23]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[23] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[23] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[24] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[24]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[24] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[24] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[25] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[25]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[25] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[25] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[26] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[26]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[26] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[26] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[27] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[27]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[27] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[27] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[28] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[28]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[28] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[28] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[29] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[29]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[29] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[29] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[2]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[2] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[30] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[30]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[30] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[30] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[31] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[31]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[31] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[31] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[3]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[3] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[4]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[4] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[4] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[5] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[5]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[5] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[5] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[6] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[6]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[6] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[6] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[7] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[7]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[7] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[7] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[8] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[8]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[8] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[8] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/local_wdata_reg[9] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AXI_WCHANNEL/local_wdata[31]_i_1_n_0 ),
    .D(s_ahb_hwdata[9]),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL/local_wdata[9] )
    );
    defparam \U0/AXI_WCHANNEL/local_wdata_reg[9] .INIT = 1'B0;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/ahb_data_valid_i_i_2 
    (
    .I0(\U0/AXI_WCHANNEL/local_wdata[15] ),
    .I1(s_ahb_hwdata[15]),
    .I2(\U0/local_en ),
    .I3(m_axi_wvalid),
    .I4(m_axi_wready),
    .I5(\U0/AXI_WCHANNEL/<const1> ),
    .O6(\U0/AXI_WCHANNEL_n_12 ),
    .O5(\U0/AXI_WCHANNEL/p_1_in[15] )
    );
    defparam \U0/AXI_WCHANNEL/ahb_data_valid_i_i_2 .INIT = 64'HFFFF00FFACACCCAC;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1 
    (
    .I0(\U0/valid_cnt_required[1] ),
    .I1(\U0/axi_waddr_done_i ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[1] ),
    .I3(\U0/valid_cnt_required[3] ),
    .I4(\U0/AXI_WCHANNEL/axi_cnt_required[3] ),
    .I5(\U0/AXI_WCHANNEL/<const1> ),
    .O6(\U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1_n_0 ),
    .O5(\U0/AXI_WCHANNEL/axi_cnt_required[1]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/axi_cnt_required[3]_i_1 .INIT = 64'HFF33CC00B8B8B8B8;
    xsLUTSA5 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_hsel),
    .I4(\U0/AHB_DATA_COUNTER_n_4 ),
    .O(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0 .INIT = 32'H2000FFFF;
    xsLUTSA6 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0 
    (
    .I0(s_ahb_htrans[1]),
    .I1(s_ahb_htrans[0]),
    .I2(s_ahb_hready_in),
    .I3(s_ahb_hsel),
    .I4(\U0/AHB_DATA_COUNTER_n_3 ),
    .I5(\U0/AHB_DATA_COUNTER_n_4 ),
    .O(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0 .INIT = 64'H0000DFFFDFFF0000;
    xsLUTSA6 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0 
    (
    .I0(\U0/AHB_DATA_COUNTER_n_1 ),
    .I1(\U0/AHB_DATA_COUNTER_n_0 ),
    .I2(\U0/AHB_DATA_COUNTER_n_2 ),
    .I3(\U0/AHB_DATA_COUNTER_n_4 ),
    .I4(\U0/AHB_DATA_COUNTER_n_3 ),
    .I5(\U0/nonseq_detected ),
    .O(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0 .INIT = 64'H000000006CCCCCCC;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[0]_i_1__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_4 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_3 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_2 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_1 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHB_IF_n_30 ),
    .D(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2__0_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AHB_DATA_COUNTER_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out_reg[4] .INIT = 1'B0;
    xsLUTSA6 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_2 
    (
    .I0(\U0/AHB_DATA_COUNTER_n_1 ),
    .I1(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4_n_0 ),
    .I2(\U0/valid_cnt_required[3] ),
    .I3(\U0/valid_cnt_required[1] ),
    .I4(\U0/valid_cnt_required[2] ),
    .I5(\U0/AHB_DATA_COUNTER_n_0 ),
    .O(\U0/AHB_DATA_COUNTER_n_5 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_2 .INIT = 64'H0000000884848440;
    xsLUTSA5 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4 
    (
    .I0(\U0/AHB_DATA_COUNTER_n_4 ),
    .I1(\U0/valid_cnt_required[2] ),
    .I2(\U0/valid_cnt_required[1] ),
    .I3(\U0/AHB_DATA_COUNTER_n_2 ),
    .I4(\U0/AHB_DATA_COUNTER_n_3 ),
    .O(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/ahb_penult_beat_i_4 .INIT = 32'H42180000;
    xsLUTSA6_2 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0 
    (
    .I0(\U0/AHB_DATA_COUNTER_n_3 ),
    .I1(\U0/AHB_DATA_COUNTER_n_2 ),
    .I2(\U0/AHB_DATA_COUNTER_n_4 ),
    .I3(\U0/nonseq_detected ),
    .I4(\U0/AHB_DATA_COUNTER_n_1 ),
    .I5(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0_n_0 ),
    .O5(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1__0_n_0 )
    );
    defparam \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1__0 .INIT = 64'H007F0080006C006C;
    xs1 \U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/VCC 
    (
    .P(\U0/AHB_DATA_COUNTER/AHB_SAMPLE_CNT_MODULE/GLOBAL_LOGIC1 )
    );
    xsLUTSA3 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1 
    (
    .I0(\U0/set_axi_waddr ),
    .I1(\U0/AXI_WCHANNEL_n_9 ),
    .I2(\U0/AXI_WCHANNEL_n_10 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1 .INIT = 8'H14;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL_n_6 ),
    .I2(\U0/AXI_WCHANNEL_n_8 ),
    .I3(\U0/AXI_WCHANNEL_n_10 ),
    .I4(\U0/AXI_WCHANNEL_n_9 ),
    .I5(\U0/set_axi_waddr ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2 .INIT = 64'H000000006CCCCCCC;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[0] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AHBLITE_AXI_CONTROL_n_4 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_10 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[0] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[1] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[1]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_9 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[1] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[2] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_8 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[2] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[3] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_7 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[3] .INIT = 1'B0;
    xsDFFSA_K1R1E1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[4] 
    (
    .C(s_ahb_hclk),
    .CE(\U0/AHBLITE_AXI_CONTROL_n_6 ),
    .D(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[4]_i_2_n_0 ),
    .R(\U0/cntr_rst ),
    .Q(\U0/AXI_WCHANNEL_n_6 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out_reg[4] .INIT = 1'B0;
    xsLUTSA1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/NARROW_TRANSFER_OFF.M_AXI_WSTRB_i[3]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/dummy_on_axi__0 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_5 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/NARROW_TRANSFER_OFF.M_AXI_WSTRB_i[3]_i_1 .INIT = 2'H1;
    xsLUTSA5 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/axi_last_beat_reg_n_0 ),
    .I1(s_ahb_hresetn),
    .I2(m_axi_wready),
    .I3(m_axi_wvalid),
    .I4(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_2_n_0 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_8 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_1 .INIT = 32'H0888C000;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_3 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_5_n_0 ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[3] ),
    .I3(\U0/AXI_WCHANNEL/axi_cnt_required[1] ),
    .I4(\U0/AXI_WCHANNEL/axi_cnt_required[2] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp__5 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_3 .INIT = 64'H0000000884848440;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_4 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_6_n_0 ),
    .I2(\U0/burst_term_txer_cnt[3] ),
    .I3(\U0/burst_term_txer_cnt[1] ),
    .I4(\U0/burst_term_txer_cnt[2] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp1_out )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_4 .INIT = 64'H0000000884848440;
    xsLUTSA5 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/axi_penult_beat_reg_n_0 ),
    .I1(s_ahb_hresetn),
    .I2(m_axi_wready),
    .I3(m_axi_wvalid),
    .I4(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2_n_0 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_7 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_1 .INIT = 32'H0888C000;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_3 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5_n_0 ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[3] ),
    .I3(\U0/AXI_WCHANNEL/axi_cnt_required[1] ),
    .I4(\U0/AXI_WCHANNEL/axi_cnt_required[2] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp3_out )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_3 .INIT = 64'H0000000884848440;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_4 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6_n_0 ),
    .I2(\U0/burst_term_txer_cnt[3] ),
    .I3(\U0/burst_term_txer_cnt[1] ),
    .I4(\U0/burst_term_txer_cnt[2] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp5_out )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_4 .INIT = 64'H0000000884848440;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_2 
    (
    .I0(\U0/AXI_WCHANNEL/dummy_on_axi_progress ),
    .I1(\U0/eqOp6_out ),
    .I2(m_axi_wvalid),
    .I3(m_axi_wready),
    .I4(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp8_out ),
    .I5(\U0/burst_term ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_init )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_2 .INIT = 64'H5444444400000000;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_4 
    (
    .I0(\U0/AXI_WCHANNEL_n_7 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6_n_0 ),
    .I2(\U0/burst_term_cur_cnt[4] ),
    .I3(\U0/AHB_IF_n_32 ),
    .I4(\U0/burst_term_cur_cnt[3] ),
    .I5(\U0/AXI_WCHANNEL_n_6 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp8_out )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_4 .INIT = 64'H8040400808040480;
    xsLUTSA6 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6 
    (
    .I0(\U0/AXI_WCHANNEL_n_10 ),
    .I1(\U0/burst_term_cur_cnt[2] ),
    .I2(\U0/burst_term_cur_cnt[0] ),
    .I3(\U0/burst_term_cur_cnt[1] ),
    .I4(\U0/AXI_WCHANNEL_n_8 ),
    .I5(\U0/AXI_WCHANNEL_n_9 ),
    .O(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_6 .INIT = 64'H4002100808400210;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5 
    (
    .I0(\U0/AXI_WCHANNEL_n_10 ),
    .I1(\U0/AXI_WCHANNEL/axi_cnt_required[2] ),
    .I2(\U0/AXI_WCHANNEL/axi_cnt_required[1] ),
    .I3(\U0/AXI_WCHANNEL_n_8 ),
    .I4(\U0/AXI_WCHANNEL_n_9 ),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5_n_0 ),
    .O5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_5_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_5 .INIT = 64'H0104802042180000;
    xs1 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/VCC 
    (
    .P(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 )
    );
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6 
    (
    .I0(\U0/AXI_WCHANNEL_n_10 ),
    .I1(\U0/burst_term_txer_cnt[2] ),
    .I2(\U0/burst_term_txer_cnt[1] ),
    .I3(\U0/AXI_WCHANNEL_n_8 ),
    .I4(\U0/AXI_WCHANNEL_n_9 ),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6_n_0 ),
    .O5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_6_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_6 .INIT = 64'H0104802042180000;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1 
    (
    .I0(\U0/AXI_WCHANNEL_n_9 ),
    .I1(\U0/AXI_WCHANNEL_n_8 ),
    .I2(\U0/AXI_WCHANNEL_n_10 ),
    .I3(\U0/set_axi_waddr ),
    .I4(\U0/AXI_WCHANNEL_n_7 ),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1_n_0 ),
    .O5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[2]_i_1_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/INFERRED_GEN.icount_out[3]_i_1 .INIT = 64'H007F0080006C006C;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_1 
    (
    .I0(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_init ),
    .I1(\U0/AXI_WCHANNEL/dummy_on_axi_progress ),
    .I2(m_axi_wlast),
    .I3(m_axi_wready),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE_n_9 ),
    .O5(\U0/AXI_WCHANNEL/dummy_on_axi__0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/dummy_on_axi_progress_i_1 .INIT = 64'HAEEEAEEEEEEEEEEE;
    xsLUTSA6_2 \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2 
    (
    .I0(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp__5 ),
    .I1(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp1_out ),
    .I2(\U0/burst_term ),
    .I3(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp3_out ),
    .I4(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/eqOp5_out ),
    .I5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/GLOBAL_LOGIC1 ),
    .O6(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2_n_0 ),
    .O5(\U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_last_beat_i_2_n_0 )
    );
    defparam \U0/AXI_WCHANNEL/AXI_WRITE_CNT_MODULE/axi_penult_beat_i_2 .INIT = 64'H000F00FF15151515;
    assign m_axi_aclk = s_ahb_hclk; 
    assign m_axi_aresetn = s_ahb_hresetn; 
    assign m_axi_awlock = m_axi_arlock; 
    assign m_axi_arcache[3] = m_axi_arlock; 
    assign m_axi_arcache[2] = m_axi_arlock; 
    assign m_axi_arid[3] = m_axi_arlock; 
    assign m_axi_arid[2] = m_axi_arlock; 
    assign m_axi_arid[1] = m_axi_arlock; 
    assign m_axi_arid[0] = m_axi_arlock; 
    assign m_axi_arlen[7] = m_axi_arlock; 
    assign m_axi_arlen[6] = m_axi_arlock; 
    assign m_axi_arlen[5] = m_axi_arlock; 
    assign m_axi_arlen[4] = m_axi_arlock; 
    assign m_axi_arlen[0] = m_axi_arlen[1]; 
    assign m_axi_awaddr[31] = m_axi_araddr[31]; 
    assign m_axi_awaddr[30] = m_axi_araddr[30]; 
    assign m_axi_awaddr[29] = m_axi_araddr[29]; 
    assign m_axi_awaddr[28] = m_axi_araddr[28]; 
    assign m_axi_awaddr[27] = m_axi_araddr[27]; 
    assign m_axi_awaddr[26] = m_axi_araddr[26]; 
    assign m_axi_awaddr[25] = m_axi_araddr[25]; 
    assign m_axi_awaddr[24] = m_axi_araddr[24]; 
    assign m_axi_awaddr[23] = m_axi_araddr[23]; 
    assign m_axi_awaddr[22] = m_axi_araddr[22]; 
    assign m_axi_awaddr[21] = m_axi_araddr[21]; 
    assign m_axi_awaddr[20] = m_axi_araddr[20]; 
    assign m_axi_awaddr[19] = m_axi_araddr[19]; 
    assign m_axi_awaddr[18] = m_axi_araddr[18]; 
    assign m_axi_awaddr[17] = m_axi_araddr[17]; 
    assign m_axi_awaddr[16] = m_axi_araddr[16]; 
    assign m_axi_awaddr[15] = m_axi_araddr[15]; 
    assign m_axi_awaddr[14] = m_axi_araddr[14]; 
    assign m_axi_awaddr[13] = m_axi_araddr[13]; 
    assign m_axi_awaddr[12] = m_axi_araddr[12]; 
    assign m_axi_awaddr[11] = m_axi_araddr[11]; 
    assign m_axi_awaddr[10] = m_axi_araddr[10]; 
    assign m_axi_awaddr[9] = m_axi_araddr[9]; 
    assign m_axi_awaddr[8] = m_axi_araddr[8]; 
    assign m_axi_awaddr[7] = m_axi_araddr[7]; 
    assign m_axi_awaddr[6] = m_axi_araddr[6]; 
    assign m_axi_awaddr[5] = m_axi_araddr[5]; 
    assign m_axi_awaddr[4] = m_axi_araddr[4]; 
    assign m_axi_awaddr[3] = m_axi_araddr[3]; 
    assign m_axi_awaddr[2] = m_axi_araddr[2]; 
    assign m_axi_awaddr[1] = m_axi_araddr[1]; 
    assign m_axi_awaddr[0] = m_axi_araddr[0]; 
    assign m_axi_awburst[1] = m_axi_arburst[1]; 
    assign m_axi_awburst[0] = m_axi_arburst[0]; 
    assign m_axi_awcache[3] = m_axi_arlock; 
    assign m_axi_awcache[2] = m_axi_arlock; 
    assign m_axi_awcache[1] = m_axi_arcache[1]; 
    assign m_axi_awcache[0] = m_axi_arcache[0]; 
    assign m_axi_awid[3] = m_axi_arlock; 
    assign m_axi_awid[2] = m_axi_arlock; 
    assign m_axi_awid[1] = m_axi_arlock; 
    assign m_axi_awid[0] = m_axi_arlock; 
    assign m_axi_awlen[7] = m_axi_arlock; 
    assign m_axi_awlen[6] = m_axi_arlock; 
    assign m_axi_awlen[5] = m_axi_arlock; 
    assign m_axi_awlen[4] = m_axi_arlock; 
    assign m_axi_awlen[3] = m_axi_arlen[3]; 
    assign m_axi_awlen[2] = m_axi_arlen[2]; 
    assign m_axi_awlen[1] = m_axi_arlen[1]; 
    assign m_axi_awlen[0] = m_axi_arlen[1]; 
    assign m_axi_awprot[2] = m_axi_arprot[2]; 
    assign m_axi_awprot[1] = m_axi_arprot[1]; 
    assign m_axi_awprot[0] = m_axi_arprot[0]; 
    assign m_axi_awsize[2] = m_axi_arsize[2]; 
    assign m_axi_awsize[1] = m_axi_arsize[1]; 
    assign m_axi_awsize[0] = m_axi_arsize[0]; 
    assign m_axi_wstrb[2] = m_axi_wstrb[3]; 
    assign m_axi_wstrb[1] = m_axi_wstrb[3]; 
    assign m_axi_wstrb[0] = m_axi_wstrb[3]; 
endmodule
