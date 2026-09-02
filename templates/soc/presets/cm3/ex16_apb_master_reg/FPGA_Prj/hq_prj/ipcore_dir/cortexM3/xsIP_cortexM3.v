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
    //## CH0 APB master00 interface
    output  wire    [31:0]  CH0_M00_PADDR,
    output  wire            CH0_M00_PSEL,
    output  wire            CH0_M00_PENABLE,
    output  wire            CH0_M00_PWRITE,
    output  wire    [31:0]  CH0_M00_PWDATA,
    output  wire    [2:0]   CH0_M00_PPROT,
    output  wire    [3:0]   CH0_M00_PSTRB,
    input   wire    [31:0]  CH0_M00_PRDATA,
    input   wire            CH0_M00_PREADY,
    input   wire            CH0_M00_PSLVERR,
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
    localparam M0_AXIL_S_COUNT = 1;                
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
core1770 #  (
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
    assign CH0_M00_PADDR             = CH0_M_PADDR[0*32+:32];
    assign CH0_M00_PWRITE            = CH0_M_PWRITE[0];
    assign CH0_M00_PWDATA            = CH0_M_PWDATA[0*32+:32];
    assign CH0_M00_PSEL              = CH0_M_PSEL[0];
    assign CH0_M00_PENABLE           = CH0_M_PENABLE[0];
    assign CH0_M_PREADY[0]            = CH0_M00_PREADY;
    assign CH0_M_PRDATA[0*32+:32]     = CH0_M00_PRDATA;
    assign CH0_M_PSLVERR[0]           = CH0_M00_PSLVERR;
    assign CH0_M00_PSTRB             = CH0_M_PSTRB[0*4+:4];
    assign CH0_M00_PPROT             = CH0_M_PPROT[0*3+:3];
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
    bus_matrix_03532 #  (
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
    .CH0_M_PADDR        (CH0_M_PADDR),            
    .CH0_M_PSEL         (CH0_M_PSEL),             
    .CH0_M_PENABLE      (CH0_M_PENABLE),          
    .CH0_M_PWRITE       (CH0_M_PWRITE),           
    .CH0_M_PWDATA       (CH0_M_PWDATA),           
    .CH0_M_PPROT        (CH0_M_PPROT),            
    .CH0_M_PSTRB        (CH0_M_PSTRB),            
    .CH0_M_PRDATA       (CH0_M_PRDATA),           
    .CH0_M_PREADY       (CH0_M_PREADY),           
    .CH0_M_PSLVERR      (CH0_M_PSLVERR),          
    .CH0_S_HRESETn      (RST_N)
    );
endmodule
module core1770(
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
module bus_matrix_03532(
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
    CH0_M_PADDR,            
    CH0_M_PSEL,             
    CH0_M_PENABLE,          
    CH0_M_PWRITE,           
    CH0_M_PWDATA,           
    CH0_M_PPROT,            
    CH0_M_PSTRB,            
    CH0_M_PRDATA,           
    CH0_M_PREADY,           
    CH0_M_PSLVERR,          
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
    output wire [32*APB_M_COUNT-1:0]  CH0_M_PADDR;            
    output wire [APB_M_COUNT-1:0]     CH0_M_PSEL;             
    output wire [APB_M_COUNT-1:0]     CH0_M_PENABLE;          
    output wire [APB_M_COUNT-1:0]     CH0_M_PWRITE;           
    output wire [32*APB_M_COUNT-1:0]  CH0_M_PWDATA;           
    output wire [3*APB_M_COUNT-1:0]   CH0_M_PPROT;            
    output wire [4*APB_M_COUNT-1:0]   CH0_M_PSTRB;            
    input  wire [32*APB_M_COUNT-1:0]  CH0_M_PRDATA;           
    input  wire [APB_M_COUNT-1:0]     CH0_M_PREADY;           
    input  wire [APB_M_COUNT-1:0]     CH0_M_PSLVERR;          
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
    cmsdk_ahb_to_apb9341 ahb2apb_inst    (
    .HCLK          (CH0_S_HCLK      ),
    .HRESETn        (CH0_S_HRESETn  ),
    .PCLKEN         (1'b1           ), 
    .HSEL           (int_ahb_sel    ), 
    .HADDR          (int_ahb_addr   ), 
    .HTRANS         (int_ahb_trans  ), 
    .HSIZE          (int_ahb_size   ), 
    .HPROT          (int_ahb_prot   ), 
    .HWRITE         (int_ahb_write  ), 
    .HREADY         (int_ahb_readymux), 
    .HWDATA         (int_ahb_wdata  ), 
    .HREADYOUT      (int_ahb_readyout), 
    .HRDATA         (int_ahb_rdata  ), 
    .HRESP          (int_ahb_resp   ), 
    .PADDR          (int_apb_addr    ),
    .PENABLE        (int_apb_enable  ), 
    .PWRITE         (int_apb_write   ), 
    .PSTRB          (int_apb_strb    ),     
    .PPROT          (int_apb_prot    ),     
    .PWDATA         (int_apb_wdata   ), 
    .PSEL           (int_apb_sel     ), 
    .APBACTIVE      (int_apb_active  ),                              
    .PRDATA         (int_apb_rdata   ), 
    .PREADY         (int_apb_ready   ), 
    .PSLVERR        (int_apb_slverr  )
    );
    assign CH0_M_PADDR    = int_apb_addr;
    assign CH0_M_PSEL     = int_apb_sel;
    assign CH0_M_PENABLE  = int_apb_enable;
    assign CH0_M_PWRITE   = int_apb_write;
    assign CH0_M_PWDATA   = int_apb_wdata;
    assign CH0_M_PPROT    = int_apb_prot;
    assign CH0_M_PSTRB    = int_apb_strb;
    assign int_apb_rdata  = CH0_M_PRDATA   ;
    assign int_apb_ready  = CH0_M_PREADY   ;
    assign int_apb_slverr = CH0_M_PSLVERR  ;
endmodule
module cmsdk_ahb_to_apb9341
(
    HCLK,
    HRESETn,
    PCLKEN,
    HSEL,
    HADDR,
    HTRANS,
    HSIZE,
    HPROT,
    HWRITE,
    HREADY,
    HWDATA,
    PRDATA,
    PREADY,
    PSLVERR,
    HREADYOUT,
    HRDATA,
    HRESP,
    PADDR,
    PENABLE,
    PWRITE,
    PSTRB,
    PPROT,
    PWDATA,
    PSEL,
    APBACTIVE
);
    input  HCLK;
    input  HRESETn;
    input  PCLKEN;
    input  HSEL;
    input  [31:0] HADDR;
    input  [1:0] HTRANS;
    input  [2:0] HSIZE;
    input  [3:0] HPROT;
    input  HWRITE;
    input  HREADY;
    input  [31:0] HWDATA;
    input  [31:0] PRDATA;
    input  PREADY;
    input  PSLVERR;
    output HREADYOUT;
    output [31:0] HRDATA;
    output HRESP;
    output [31:0] PADDR;
    output PENABLE;
    output PWRITE;
    output [3:0] PSTRB;
    output [2:0] PPROT;
    output [31:0] PWDATA;
    output PSEL;
    output APBACTIVE;
    wire \pstrb_nxt[3] ;
    wire \pstrb_nxt[2] ;
    wire \pstrb_nxt[1] ;
    wire \pstrb_nxt[0] ;
    wire n_42;
    wire apb_select;
    wire \pprot_nxt[1] ;
    wire n_25;
    wire n_44;
    wire n_41;
    wire \next_state[0] ;
    wire \state_reg[0] ;
    wire \state_reg[2] ;
    wire \state_reg[1] ;
    wire pstrb_nxt_iHQX12_1_out;
    wire pstrb_nxt_iHQX11_1_out;
    wire _i_35_1_out;
    wire \next_state_0/_i_0_3_out ;
    xsDFFSA_K1C1 \state_reg_reg[0] 
    (
    .C(HCLK),
    .CLR(n_25),
    .D(\next_state[0] ),
    .Q(\state_reg[0] )
    );
    xsDFFSA_K1C1 \state_reg_reg[1] 
    (
    .C(HCLK),
    .CLR(n_25),
    .D(n_41),
    .Q(\state_reg[1] )
    );
    xsDFFSA_K1C1 \state_reg_reg[2] 
    (
    .C(HCLK),
    .CLR(n_25),
    .D(n_42),
    .Q(\state_reg[2] )
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[0] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[2]),
    .Q(PADDR[2])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[1] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[3]),
    .Q(PADDR[3])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[2] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[4]),
    .Q(PADDR[4])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[3] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[5]),
    .Q(PADDR[5])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[4] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[6]),
    .Q(PADDR[6])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[5] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[7]),
    .Q(PADDR[7])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[6] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[8]),
    .Q(PADDR[8])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[7] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[9]),
    .Q(PADDR[9])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[8] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[10]),
    .Q(PADDR[10])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[9] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[11]),
    .Q(PADDR[11])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[10] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[12]),
    .Q(PADDR[12])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[11] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[13]),
    .Q(PADDR[13])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[12] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[14]),
    .Q(PADDR[14])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[13] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[15]),
    .Q(PADDR[15])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[14] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[16]),
    .Q(PADDR[16])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[15] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[17]),
    .Q(PADDR[17])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[16] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[18]),
    .Q(PADDR[18])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[17] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[19]),
    .Q(PADDR[19])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[18] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[20]),
    .Q(PADDR[20])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[19] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[21]),
    .Q(PADDR[21])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[20] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[22]),
    .Q(PADDR[22])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[21] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[23]),
    .Q(PADDR[23])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[22] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[24]),
    .Q(PADDR[24])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[23] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[25]),
    .Q(PADDR[25])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[24] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[26]),
    .Q(PADDR[26])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[25] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[27]),
    .Q(PADDR[27])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[26] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[28]),
    .Q(PADDR[28])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[27] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[29]),
    .Q(PADDR[29])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[28] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[30]),
    .Q(PADDR[30])
    );
    xsDFFSA_K1C1E1 \addr_reg_reg[29] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HADDR[31]),
    .Q(PADDR[31])
    );
    xsDFFSA_K1C1E1 \pprot_reg_reg[0] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HPROT[1]),
    .Q(PPROT[0])
    );
    xsDFFSA_K1C1E1 \pprot_reg_reg[1] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(\pprot_nxt[1] ),
    .Q(PPROT[2])
    );
    xsDFFSA_K1C1E1 \pstrb_reg_reg[0] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(\pstrb_nxt[0] ),
    .Q(PSTRB[0])
    );
    xsDFFSA_K1C1E1 \pstrb_reg_reg[1] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(\pstrb_nxt[1] ),
    .Q(PSTRB[1])
    );
    xsDFFSA_K1C1E1 \pstrb_reg_reg[2] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(\pstrb_nxt[2] ),
    .Q(PSTRB[2])
    );
    xsDFFSA_K1C1E1 \pstrb_reg_reg[3] 
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(\pstrb_nxt[3] ),
    .Q(PSTRB[3])
    );
    xsDFFSA_K1C1E1 wr_reg_reg
    (
    .C(HCLK),
    .CE(apb_select),
    .CLR(n_25),
    .D(HWRITE),
    .Q(PWRITE)
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[31] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[31]),
    .Q(HRDATA[31])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[30] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[30]),
    .Q(HRDATA[30])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[29] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[29]),
    .Q(HRDATA[29])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[28] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[28]),
    .Q(HRDATA[28])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[27] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[27]),
    .Q(HRDATA[27])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[26] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[26]),
    .Q(HRDATA[26])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[25] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[25]),
    .Q(HRDATA[25])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[24] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[24]),
    .Q(HRDATA[24])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[23] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[23]),
    .Q(HRDATA[23])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[22] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[22]),
    .Q(HRDATA[22])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[21] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[21]),
    .Q(HRDATA[21])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[20] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[20]),
    .Q(HRDATA[20])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[19] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[19]),
    .Q(HRDATA[19])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[18] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[18]),
    .Q(HRDATA[18])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[17] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[17]),
    .Q(HRDATA[17])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[16] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[16]),
    .Q(HRDATA[16])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[15] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[15]),
    .Q(HRDATA[15])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[14] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[14]),
    .Q(HRDATA[14])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[13] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[13]),
    .Q(HRDATA[13])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[12] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[12]),
    .Q(HRDATA[12])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[11] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[11]),
    .Q(HRDATA[11])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[10] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[10]),
    .Q(HRDATA[10])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[9] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[9]),
    .Q(HRDATA[9])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[8] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[8]),
    .Q(HRDATA[8])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[7] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[7]),
    .Q(HRDATA[7])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[6] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[6]),
    .Q(HRDATA[6])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[5] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[5]),
    .Q(HRDATA[5])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[4] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[4]),
    .Q(HRDATA[4])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[3] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[3]),
    .Q(HRDATA[3])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[2] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[2]),
    .Q(HRDATA[2])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[1] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[1]),
    .Q(HRDATA[1])
    );
    xsDFFSA_K1C1E1 \rwdata_reg_reg[0] 
    (
    .C(HCLK),
    .CE(n_44),
    .CLR(n_25),
    .D(PRDATA[0]),
    .Q(HRDATA[0])
    );
    xsLUTSA4 pstrb_nxt_iHQX12_0
    (
    .I0(pstrb_nxt_iHQX12_1_out),
    .I1(HADDR[1]),
    .I2(HSIZE[1]),
    .I3(HWRITE),
    .O(\pstrb_nxt[3] )
    );
    defparam pstrb_nxt_iHQX12_0.INIT = 16'HF400;
    xsLUTSA2 pstrb_nxt_iHQX12_1
    (
    .I0(HADDR[0]),
    .I1(HSIZE[0]),
    .O(pstrb_nxt_iHQX12_1_out)
    );
    defparam pstrb_nxt_iHQX12_1.INIT = 4'H1;
    xsLUTSA4 pstrb_nxt_iHQX11_0
    (
    .I0(pstrb_nxt_iHQX11_1_out),
    .I1(HADDR[1]),
    .I2(HSIZE[1]),
    .I3(HWRITE),
    .O(\pstrb_nxt[2] )
    );
    defparam pstrb_nxt_iHQX11_0.INIT = 16'HF400;
    xsLUTSA2 pstrb_nxt_iHQX11_1
    (
    .I0(HADDR[0]),
    .I1(HSIZE[0]),
    .O(pstrb_nxt_iHQX11_1_out)
    );
    defparam pstrb_nxt_iHQX11_1.INIT = 4'H2;
    xsLUTSA4 pstrb_nxt_iHQX9_0
    (
    .I0(pstrb_nxt_iHQX12_1_out),
    .I1(HADDR[1]),
    .I2(HSIZE[1]),
    .I3(HWRITE),
    .O(\pstrb_nxt[1] )
    );
    defparam pstrb_nxt_iHQX9_0.INIT = 16'HF100;
    xsLUTSA4 pstrb_nxt_iHQX8_0
    (
    .I0(pstrb_nxt_iHQX11_1_out),
    .I1(HADDR[1]),
    .I2(HSIZE[1]),
    .I3(HWRITE),
    .O(\pstrb_nxt[0] )
    );
    defparam pstrb_nxt_iHQX8_0.INIT = 16'HF100;
    xsLUTSA4 _i_35_0
    (
    .I0(_i_35_1_out),
    .I1(PCLKEN),
    .I2(\state_reg[0] ),
    .I3(\state_reg[2] ),
    .O(n_42)
    );
    defparam _i_35_0.INIT = 16'HF080;
    xsLUTSA2 _i_35_1
    (
    .I0(PREADY),
    .I1(\state_reg[1] ),
    .O(_i_35_1_out)
    );
    defparam _i_35_1.INIT = 4'H8;
    xsLUTSA2 PSEL_iHQX20_0
    (
    .I0(\state_reg[1] ),
    .I1(\state_reg[2] ),
    .O(PSEL)
    );
    defparam PSEL_iHQX20_0.INIT = 4'H2;
    xsLUTSA3 apb_select_iHQX5_0
    (
    .I0(HSEL),
    .I1(HTRANS[1]),
    .I2(HREADY),
    .O(apb_select)
    );
    defparam apb_select_iHQX5_0.INIT = 8'H80;
    xsLUTSA4 \next_state_0/_i_0_3 
    (
    .I0(PCLKEN),
    .I1(PREADY),
    .I2(\state_reg[0] ),
    .I3(PSLVERR),
    .O(\next_state_0/_i_0_3_out )
    );
    defparam \next_state_0/_i_0_3 .INIT = 16'H05D5;
    xsLUTSA3 \PENABLE/_i_0_0 
    (
    .I0(\state_reg[0] ),
    .I1(\state_reg[1] ),
    .I2(\state_reg[2] ),
    .O(PENABLE)
    );
    defparam \PENABLE/_i_0_0 .INIT = 8'H08;
    xsLUTSA3 HRESP_iHQX21_0
    (
    .I0(\state_reg[0] ),
    .I1(\state_reg[1] ),
    .I2(\state_reg[2] ),
    .O(HRESP)
    );
    defparam HRESP_iHQX21_0.INIT = 8'H60;
    xsLUTSA2 _i_13_0
    (
    .I0(PSEL),
    .I1(\state_reg[0] ),
    .O(HREADYOUT)
    );
    defparam _i_13_0.INIT = 4'H1;
    xsINVSA _i_0_0
    (
    .I(HRESETn),
    .O(n_25)
    );
    xsLUTSA5 _i_7_0
    (
    .I0(\state_reg[0] ),
    .I1(\state_reg[1] ),
    .I2(\state_reg[2] ),
    .I3(PCLKEN),
    .I4(PREADY),
    .O(n_44)
    );
    defparam _i_7_0.INIT = 32'H08000000;
    xsLUTSA6 _i_32_0
    (
    .I0(\state_reg[0] ),
    .I1(\state_reg[2] ),
    .I2(PCLKEN),
    .I3(_i_35_1_out),
    .I4(PSEL),
    .I5(apb_select),
    .O(n_41)
    );
    defparam _i_32_0.INIT = 64'HDFFFD8F8DFFF88A8;
    xsLUTSA6 \next_state_0/_i_0_0 
    (
    .I0(\state_reg[0] ),
    .I1(\state_reg[1] ),
    .I2(\state_reg[2] ),
    .I3(PCLKEN),
    .I4(apb_select),
    .I5(\next_state_0/_i_0_3_out ),
    .O(\next_state[0] )
    );
    defparam \next_state_0/_i_0_0 .INIT = 64'H005B000A0C5F0C0E;
    xsLUTSA5 APBACTIVE_iHQX22_0
    (
    .I0(\state_reg[0] ),
    .I1(\state_reg[1] ),
    .I2(\state_reg[2] ),
    .I3(HSEL),
    .I4(HTRANS[1]),
    .O(APBACTIVE)
    );
    defparam APBACTIVE_iHQX22_0.INIT = 32'HFFFEFEFE;
    xs0 _i_37_0
    (
    .G(PADDR[1])
    );
    xsINVSA pprot_nxt_0
    (
    .I(HPROT[0]),
    .O(\pprot_nxt[1] )
    );
    assign PADDR[0] = PADDR[1]; 
    assign PPROT[1] = PADDR[1]; 
    assign PWDATA[31] = HWDATA[31]; 
    assign PWDATA[30] = HWDATA[30]; 
    assign PWDATA[29] = HWDATA[29]; 
    assign PWDATA[28] = HWDATA[28]; 
    assign PWDATA[27] = HWDATA[27]; 
    assign PWDATA[26] = HWDATA[26]; 
    assign PWDATA[25] = HWDATA[25]; 
    assign PWDATA[24] = HWDATA[24]; 
    assign PWDATA[23] = HWDATA[23]; 
    assign PWDATA[22] = HWDATA[22]; 
    assign PWDATA[21] = HWDATA[21]; 
    assign PWDATA[20] = HWDATA[20]; 
    assign PWDATA[19] = HWDATA[19]; 
    assign PWDATA[18] = HWDATA[18]; 
    assign PWDATA[17] = HWDATA[17]; 
    assign PWDATA[16] = HWDATA[16]; 
    assign PWDATA[15] = HWDATA[15]; 
    assign PWDATA[14] = HWDATA[14]; 
    assign PWDATA[13] = HWDATA[13]; 
    assign PWDATA[12] = HWDATA[12]; 
    assign PWDATA[11] = HWDATA[11]; 
    assign PWDATA[10] = HWDATA[10]; 
    assign PWDATA[9] = HWDATA[9]; 
    assign PWDATA[8] = HWDATA[8]; 
    assign PWDATA[7] = HWDATA[7]; 
    assign PWDATA[6] = HWDATA[6]; 
    assign PWDATA[5] = HWDATA[5]; 
    assign PWDATA[4] = HWDATA[4]; 
    assign PWDATA[3] = HWDATA[3]; 
    assign PWDATA[2] = HWDATA[2]; 
    assign PWDATA[1] = HWDATA[1]; 
    assign PWDATA[0] = HWDATA[0]; 
endmodule
