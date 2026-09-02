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
// Date            : 2026.07.17
// Revision        : 6.2
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
    input   wire            CH0_CDC_CLK,    
    //## CH0 AHB master00 interface
    output  wire            CH0_M00_HSEL,
    output  wire    [31:0]  CH0_M00_HADDR,
    output  wire    [1:0]   CH0_M00_HTRANS,
    output  wire    [2:0]   CH0_M00_HSIZE,
    output  wire    [2:0]   CH0_M00_HBURST,
    output  wire            CH0_M00_HMASTLOCK,
    output  wire    [3:0]   CH0_M00_HPROT,
    input   wire            CH0_M00_HRESP,
    output  wire            CH0_M00_HWRITE,
    output  wire    [31:0]  CH0_M00_HWDATA,
    input   wire    [31:0]  CH0_M00_HRDATA,
    output  wire            CH0_M00_HREADYMUX,
    input   wire            CH0_M00_HREADYOUT,
    //## CH0 AHB master01 interface
    output  wire            CH0_M01_HSEL,
    output  wire    [31:0]  CH0_M01_HADDR,
    output  wire    [1:0]   CH0_M01_HTRANS,
    output  wire    [2:0]   CH0_M01_HSIZE,
    output  wire    [2:0]   CH0_M01_HBURST,
    output  wire            CH0_M01_HMASTLOCK,
    output  wire    [3:0]   CH0_M01_HPROT,
    input   wire            CH0_M01_HRESP,
    output  wire            CH0_M01_HWRITE,
    output  wire    [31:0]  CH0_M01_HWDATA,
    input   wire    [31:0]  CH0_M01_HRDATA,
    output  wire            CH0_M01_HREADYMUX,
    input   wire            CH0_M01_HREADYOUT,
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
    localparam REF_SEL_30K  = "2.5V";     
    localparam REF_SEL_50K  = 0;            
    localparam OT_PD_ENABLE = "ENABLED";     
    localparam OT_CODE_L    = 0;            
    localparam OT_CODE_H    = 0;            
    localparam M0_AXI_M_COUNT = 1;                
    localparam M0_AXI_S_COUNT = 1;                
    localparam M0_AHB_M_COUNT = 2;  
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
core4543 #  (
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
    assign CH0_M00_HSEL              = CH0_M_HSEL[0];
    assign CH0_M00_HADDR             = CH0_M_HADDR[0*32+:32];
    assign CH0_M00_HTRANS            = CH0_M_HTRANS[0*2+:2];
    assign CH0_M00_HSIZE             = CH0_M_HSIZE[0*3+:3];
    assign CH0_M00_HBURST            = CH0_M_HBURST[0*3+:3];
    assign CH0_M00_HMASTLOCK         = CH0_M_HMASTLOCK[0];
    assign CH0_M00_HPROT             = CH0_M_HPROT[0*4+:4];
    assign CH0_M00_HWRITE            = CH0_M_HWRITE[0];
    assign CH0_M00_HWDATA            = CH0_M_HWDATA[0*32+:32];
    assign CH0_M00_HREADYMUX         = CH0_M_HREADYMUX[0];
    assign CH0_M_HRDATA[0*32+:32]     = CH0_M00_HRDATA;
    assign CH0_M_HREADYOUT[0]         = CH0_M00_HREADYOUT;
    assign CH0_M_HRESP[0]             = CH0_M00_HRESP;
    assign CH0_M01_HSEL              = CH0_M_HSEL[1];
    assign CH0_M01_HADDR             = CH0_M_HADDR[1*32+:32];
    assign CH0_M01_HTRANS            = CH0_M_HTRANS[1*2+:2];
    assign CH0_M01_HSIZE             = CH0_M_HSIZE[1*3+:3];
    assign CH0_M01_HBURST            = CH0_M_HBURST[1*3+:3];
    assign CH0_M01_HMASTLOCK         = CH0_M_HMASTLOCK[1];
    assign CH0_M01_HPROT             = CH0_M_HPROT[1*4+:4];
    assign CH0_M01_HWRITE            = CH0_M_HWRITE[1];
    assign CH0_M01_HWDATA            = CH0_M_HWDATA[1*32+:32];
    assign CH0_M01_HREADYMUX         = CH0_M_HREADYMUX[1];
    assign CH0_M_HRDATA[1*32+:32]     = CH0_M01_HRDATA;
    assign CH0_M_HREADYOUT[1]         = CH0_M01_HREADYOUT;
    assign CH0_M_HRESP[1]             = CH0_M01_HRESP;
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
    bus_matrix_06335 #  (
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
    .CH0_CDC_CLK        (CH0_CDC_CLK),                            
    .CH0_M_HSEL         (CH0_M_HSEL),                    
    .CH0_M_HADDR        (CH0_M_HADDR),             
    .CH0_M_HTRANS       (CH0_M_HTRANS),            
    .CH0_M_HSIZE        (CH0_M_HSIZE),             
    .CH0_M_HBURST       (CH0_M_HBURST),            
    .CH0_M_HMASTLOCK    (CH0_M_HMASTLOCK),         
    .CH0_M_HPROT        (CH0_M_HPROT),             
    .CH0_M_HWRITE       (CH0_M_HWRITE),            
    .CH0_M_HWDATA       (CH0_M_HWDATA),            
    .CH0_M_HRDATA       (CH0_M_HRDATA),                     
    .CH0_M_HRESP        (CH0_M_HRESP),     
    .CH0_M_HREADYMUX    (CH0_M_HREADYMUX),
    .CH0_M_HREADYOUT    (CH0_M_HREADYOUT),
    .CH0_S_HRESETn      (RST_N)
    );
endmodule
module core4543(
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
module bus_matrix_06335(
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
    CH0_CDC_CLK,                
    CH0_M_HSEL,                 
    CH0_M_HADDR,                
    CH0_M_HTRANS,               
    CH0_M_HSIZE,                
    CH0_M_HBURST,               
    CH0_M_HMASTLOCK,            
    CH0_M_HPROT,                
    CH0_M_HWRITE,               
    CH0_M_HWDATA,               
    CH0_M_HRDATA,               
    CH0_M_HRESP,                
    CH0_M_HREADYMUX,            
    CH0_M_HREADYOUT,            
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
    input wire          CH0_CDC_CLK;                    
    output wire [32*AHB_M_COUNT-1:0]  CH0_M_HADDR;            
    output wire [2*AHB_M_COUNT-1:0]   CH0_M_HTRANS;           
    output wire [3*AHB_M_COUNT-1:0]   CH0_M_HSIZE;            
    output wire [3*AHB_M_COUNT-1:0]   CH0_M_HBURST;           
    output wire [AHB_M_COUNT-1:0]     CH0_M_HMASTLOCK;        
    output wire [4*AHB_M_COUNT-1:0]   CH0_M_HPROT;            
    output wire [AHB_M_COUNT-1:0]     CH0_M_HWRITE;           
    output wire [32*AHB_M_COUNT-1:0]  CH0_M_HWDATA;           
    input  wire [32*AHB_M_COUNT-1:0]  CH0_M_HRDATA;           
    input  wire [AHB_M_COUNT-1:0]     CH0_M_HRESP;            
    output wire [AHB_M_COUNT-1:0]     CH0_M_HSEL;             
    output wire [AHB_M_COUNT-1:0]     CH0_M_HREADYMUX;        
    input  wire [AHB_M_COUNT-1:0]     CH0_M_HREADYOUT;        
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
    wire m_hmaster;
    wire m_hactive;
    ahb_to_ahb_async2370 ahb2ahb_inst      (
    .HCLKS          (CH0_S_HCLK      ),  
    .HRESETSn       (CH0_S_HRESETn   ),
    .HADDRS         (CH0_S_HADDR     ),
    .HBURSTS        (CH0_S_HBURST    ),
    .HMASTLOCKS     (CH0_S_HMASTLOCK ),
    .HPROTS         (CH0_S_HPROT     ),
    .HREADYS        (CH0_S_HREADYMUX ),
    .HSELAHBS       (CH0_S_HSEL      ),
    .HSIZES         (CH0_S_HSIZE     ),
    .HTRANSS        (CH0_S_HTRANS    ),
    .HWDATAS        (CH0_S_HWDATA    ),
    .HWRITES        (CH0_S_HWRITE    ),
    .HMASTERS       (1'b1           ),
    .HRDATAS        (CH0_S_HRDATA    ),
    .HREADYOUTS     (CH0_S_HREADYOUT ),
    .HRESPS         (CH0_S_HRESP     ),
    .HCLKM          (CH0_CDC_CLK    ),  
    .HRESETMn       (CH0_S_HRESETn  ), 
    .HADDRM         (int_ahb_addr   ),
    .HBURSTM        (int_ahb_burst  ),
    .HMASTLOCKM     (int_ahb_lock   ),
    .HPROTM         (int_ahb_prot   ),
    .HSIZEM         (int_ahb_size   ),
    .HTRANSM        (int_ahb_trans  ),
    .HWDATAM        (int_ahb_wdata  ),
    .HWRITEM        (int_ahb_write  ),
    .HMASTERM       (m_hmaster      ),
    .HRDATAM        (int_ahb_rdata  ),
    .HREADYM        (int_ahb_readyout),
    .HRESPM         (int_ahb_resp   ),
    .HACTIVEM       (m_hactive      )
    );
    assign int_ahb_readymux = int_ahb_readyout;
    assign int_ahb_sel      = int_ahb_trans[1];
    ahb_master_expander #(
    .MASTER_NUM         (AHB_M_COUNT),
    .ADDR_WIDTH         (32),
    .DATA_WIDTH         (32),
    .BASE_ADDR          (BASE_ADDR),
    .OFFSET_SIZE_WIDTH  (OFFSET_SIZE_WIDTH)
    ) ahb_expander_inst (
    .HCLK               (CH0_CDC_CLK     ), 
    .sHSEL              (int_ahb_sel        ),
    .sHADDR             (int_ahb_addr       ),
    .sHTRANS            (int_ahb_trans      ),
    .sHWRITE            (int_ahb_write      ),
    .sHSIZE             (int_ahb_size       ),
    .sHBURST            (int_ahb_burst      ),
    .sHMASTLOCK         (int_ahb_lock       ),
    .sHPROT             (int_ahb_prot       ),
    .sHWDATA            (int_ahb_wdata      ),
    .sHRDATA            (int_ahb_rdata      ),
    .sHREADYMUX         (int_ahb_readymux   ),
    .sHREADYOUT         (int_ahb_readyout   ),
    .sHRESP             (int_ahb_resp       ),
    .mHSEL              (CH0_M_HSEL         ),
    .mHADDR             (CH0_M_HADDR        ),
    .mHTRANS            (CH0_M_HTRANS       ),
    .mHWRITE            (CH0_M_HWRITE       ),
    .mHSIZE             (CH0_M_HSIZE        ),
    .mHBURST            (CH0_M_HBURST       ),
    .mHMASTLOCK         (CH0_M_HMASTLOCK    ),
    .mHPROT             (CH0_M_HPROT        ),
    .mHWDATA            (CH0_M_HWDATA       ),
    .mHRDATA            (CH0_M_HRDATA       ),
    .mHREADYMUX         (CH0_M_HREADYMUX    ),
    .mHREADYOUT         (CH0_M_HREADYOUT    ),
    .mHRESP             (CH0_M_HRESP        )  
    );
endmodule
module ahb_to_ahb_async2370
(
    HCLKS,
    HRESETSn,
    HADDRS,
    HBURSTS,
    HMASTLOCKS,
    HPROTS,
    HREADYS,
    HSELAHBS,
    HSIZES,
    HTRANSS,
    HWDATAS,
    HWRITES,
    HMASTERS,
    HCLKM,
    HRESETMn,
    HRDATAM,
    HREADYM,
    HRESPM,
    HRDATAS,
    HREADYOUTS,
    HRESPS,
    HADDRM,
    HBURSTM,
    HMASTLOCKM,
    HPROTM,
    HSIZEM,
    HTRANSM,
    HWDATAM,
    HWRITEM,
    HMASTERM,
    HACTIVEM
);
    input  HCLKS;
    input  HRESETSn;
    input  [31:0] HADDRS;
    input  [2:0] HBURSTS;
    input  HMASTLOCKS;
    input  [3:0] HPROTS;
    input  HREADYS;
    input  HSELAHBS;
    input  [2:0] HSIZES;
    input  [1:0] HTRANSS;
    input  [31:0] HWDATAS;
    input  HWRITES;
    input  [0:0] HMASTERS;
    input  HCLKM;
    input  HRESETMn;
    input  [31:0] HRDATAM;
    input  HREADYM;
    input  HRESPM;
    output [31:0] HRDATAS;
    output HREADYOUTS;
    output HRESPS;
    output [31:0] HADDRM;
    output [2:0] HBURSTM;
    output HMASTLOCKM;
    output [3:0] HPROTM;
    output [2:0] HSIZEM;
    output [1:0] HTRANSM;
    output [31:0] HWDATAM;
    output HWRITEM;
    output [0:0] HMASTERM;
    output HACTIVEM;
    wire s_hmastlock_q;
    wire \u_sema_m_from_s/q_q[0] ;
    wire \u_lock_m_from_s/q_q[0] ;
    wire [1:0] \u_sema_s_from_m/q_q ;
    wire \u_m/m_delayed_unlock_nxt ;
    wire \m_rdata[0] ;
    wire \m_rdata[1] ;
    wire \m_rdata[2] ;
    wire \m_rdata[3] ;
    wire \m_rdata[4] ;
    wire \m_rdata[5] ;
    wire \m_rdata[6] ;
    wire \m_rdata[7] ;
    wire \m_rdata[8] ;
    wire \m_rdata[9] ;
    wire \m_rdata[10] ;
    wire \m_rdata[11] ;
    wire \m_rdata[12] ;
    wire \m_rdata[13] ;
    wire \m_rdata[14] ;
    wire \m_rdata[15] ;
    wire \m_rdata[16] ;
    wire \m_rdata[17] ;
    wire \m_rdata[18] ;
    wire \m_rdata[19] ;
    wire \m_rdata[20] ;
    wire \m_rdata[21] ;
    wire \m_rdata[22] ;
    wire \m_rdata[23] ;
    wire \m_rdata[24] ;
    wire \m_rdata[25] ;
    wire \m_rdata[26] ;
    wire \m_rdata[27] ;
    wire \m_rdata[28] ;
    wire \m_rdata[29] ;
    wire \m_rdata[30] ;
    wire \m_rdata[31] ;
    wire m_rd_en;
    wire s_wd_en;
    wire \u_sema_m/n_38 ;
    wire \u_s/n_37 ;
    wire \u_m/m_force_lock_nxt ;
    wire s_ad_en;
    wire \u_sema_s/q_q_reg_ctrl_din ;
    wire \u_s/s_state_q_reg[0]_ctrl_din ;
    wire \u_s/s_state_q_reg[1]_ctrl_din ;
    wire \u_m/m_mode_q_reg_ctrl_din ;
    wire \u_sema_m/q_q_reg_ctrl_din ;
    wire m_tx_sema_q;
    wire m_rx_sema_q;
    wire m_lock_q;
    wire \u_m/m_force_lock_q ;
    wire m_tx_sema_nxt;
    wire \u_resp/q_q[0] ;
    wire s_tx_sema_q;
    wire s_rx_sema_q;
    wire \u_s/s_state_q[1] ;
    wire \u_s/s_state_q[0] ;
    wire \u_m/m_delayed_unlock_q ;
    wire \u_m/m_in_rst_q ;
    wire \u_hmaster/q_q[0] ;
    wire \u_hwrite/q_q[0] ;
    wire \u_hwdata/q_q[0] ;
    wire \u_hwdata/q_q[1] ;
    wire \u_hwdata/q_q[2] ;
    wire \u_hwdata/q_q[3] ;
    wire \u_hwdata/q_q[4] ;
    wire \u_hwdata/q_q[5] ;
    wire \u_hwdata/q_q[6] ;
    wire \u_hwdata/q_q[7] ;
    wire \u_hwdata/q_q[8] ;
    wire \u_hwdata/q_q[9] ;
    wire \u_hwdata/q_q[10] ;
    wire \u_hwdata/q_q[11] ;
    wire \u_hwdata/q_q[12] ;
    wire \u_hwdata/q_q[13] ;
    wire \u_hwdata/q_q[14] ;
    wire \u_hwdata/q_q[15] ;
    wire \u_hwdata/q_q[16] ;
    wire \u_hwdata/q_q[17] ;
    wire \u_hwdata/q_q[18] ;
    wire \u_hwdata/q_q[19] ;
    wire \u_hwdata/q_q[20] ;
    wire \u_hwdata/q_q[21] ;
    wire \u_hwdata/q_q[22] ;
    wire \u_hwdata/q_q[23] ;
    wire \u_hwdata/q_q[24] ;
    wire \u_hwdata/q_q[25] ;
    wire \u_hwdata/q_q[26] ;
    wire \u_hwdata/q_q[27] ;
    wire \u_hwdata/q_q[28] ;
    wire \u_hwdata/q_q[29] ;
    wire \u_hwdata/q_q[30] ;
    wire \u_hwdata/q_q[31] ;
    wire \u_hmastlock/q_q[0] ;
    wire \u_hsize_1to0/q_q[0] ;
    wire \u_hsize_1to0/q_q[1] ;
    wire \u_hprot/q_q[0] ;
    wire \u_hprot/q_q[1] ;
    wire \u_hprot/q_q[2] ;
    wire \u_hprot/q_q[3] ;
    wire \u_haddr/q_q[0] ;
    wire \u_haddr/q_q[1] ;
    wire \u_haddr/q_q[2] ;
    wire \u_haddr/q_q[3] ;
    wire \u_haddr/q_q[4] ;
    wire \u_haddr/q_q[5] ;
    wire \u_haddr/q_q[6] ;
    wire \u_haddr/q_q[7] ;
    wire \u_haddr/q_q[8] ;
    wire \u_haddr/q_q[9] ;
    wire \u_haddr/q_q[10] ;
    wire \u_haddr/q_q[11] ;
    wire \u_haddr/q_q[12] ;
    wire \u_haddr/q_q[13] ;
    wire \u_haddr/q_q[14] ;
    wire \u_haddr/q_q[15] ;
    wire \u_haddr/q_q[16] ;
    wire \u_haddr/q_q[17] ;
    wire \u_haddr/q_q[18] ;
    wire \u_haddr/q_q[19] ;
    wire \u_haddr/q_q[20] ;
    wire \u_haddr/q_q[21] ;
    wire \u_haddr/q_q[22] ;
    wire \u_haddr/q_q[23] ;
    wire \u_haddr/q_q[24] ;
    wire \u_haddr/q_q[25] ;
    wire \u_haddr/q_q[26] ;
    wire \u_haddr/q_q[27] ;
    wire \u_haddr/q_q[28] ;
    wire \u_haddr/q_q[29] ;
    wire \u_haddr/q_q[30] ;
    wire \u_haddr/q_q[31] ;
    wire \u_rdata/q_q[0] ;
    wire \u_rdata/q_q[1] ;
    wire \u_rdata/q_q[2] ;
    wire \u_rdata/q_q[3] ;
    wire \u_rdata/q_q[4] ;
    wire \u_rdata/q_q[5] ;
    wire \u_rdata/q_q[6] ;
    wire \u_rdata/q_q[7] ;
    wire \u_rdata/q_q[8] ;
    wire \u_rdata/q_q[9] ;
    wire \u_rdata/q_q[10] ;
    wire \u_rdata/q_q[11] ;
    wire \u_rdata/q_q[12] ;
    wire \u_rdata/q_q[13] ;
    wire \u_rdata/q_q[14] ;
    wire \u_rdata/q_q[15] ;
    wire \u_rdata/q_q[16] ;
    wire \u_rdata/q_q[17] ;
    wire \u_rdata/q_q[18] ;
    wire \u_rdata/q_q[19] ;
    wire \u_rdata/q_q[20] ;
    wire \u_rdata/q_q[21] ;
    wire \u_rdata/q_q[22] ;
    wire \u_rdata/q_q[23] ;
    wire \u_rdata/q_q[24] ;
    wire \u_rdata/q_q[25] ;
    wire \u_rdata/q_q[26] ;
    wire \u_rdata/q_q[27] ;
    wire \u_rdata/q_q[28] ;
    wire \u_rdata/q_q[29] ;
    wire \u_rdata/q_q[30] ;
    wire \u_rdata/q_q[31] ;
    wire \u_s/s_ad_en_iHQX14_3_out ;
    wire \u_s/s_ad_en_iHQX14_4_out ;
    wire \u_s/s_ad_en_iHQX14_2_out ;
    wire \u_sema_s/q_q_reg_ctrlmux_1_out ;
    wire \u_s/s_state_q_reg[0]_ctrlmux_7_out ;
    wire \u_m/m_htrans_iHQX6_andor_decomp_0_1_out ;
    wire \u_s/s_state_q_reg[0]_ctrlmux_6_out ;
    xsDFFSA_K1C1 \u_s/s_state_q_reg[1] 
    (
    .C(HCLKS),
    .CLR(\u_s/n_37 ),
    .D(\u_s/s_state_q_reg[1]_ctrl_din ),
    .Q(\u_s/s_state_q[1] )
    );
    xsDFFSA_K1C1 \u_s/s_state_q_reg[0] 
    (
    .C(HCLKS),
    .CLR(\u_s/n_37 ),
    .D(\u_s/s_state_q_reg[0]_ctrl_din ),
    .Q(\u_s/s_state_q[0] )
    );
    xsDFFSA_K1C1 \u_sema_s/q_q_reg 
    (
    .C(HCLKS),
    .CLR(\u_s/n_37 ),
    .D(\u_sema_s/q_q_reg_ctrl_din ),
    .Q(s_tx_sema_q)
    );
    xsDFFSA_K1C1 \u_hmastlock_s/q_q_reg 
    (
    .C(HCLKS),
    .CLR(\u_s/n_37 ),
    .D(HMASTLOCKS),
    .Q(s_hmastlock_q)
    );
    xsDFFSA_K1C1 \u_sema_m/q_q_reg 
    (
    .C(HCLKM),
    .CLR(\u_sema_m/n_38 ),
    .D(\u_sema_m/q_q_reg_ctrl_din ),
    .Q(m_tx_sema_q)
    );
    xsDFFSA_K1 \u_sema_m_from_s/q_q_reg[0] 
    (
    .C(HCLKM),
    .D(s_tx_sema_q),
    .Q(\u_sema_m_from_s/q_q[0] )
    );
    xsDFFSA_K1 \u_sema_m_from_s/q_q_reg[1] 
    (
    .C(HCLKM),
    .D(\u_sema_m_from_s/q_q[0] ),
    .Q(m_rx_sema_q)
    );
    xsDFFSA_K1 \u_lock_m_from_s/q_q_reg[0] 
    (
    .C(HCLKM),
    .D(s_hmastlock_q),
    .Q(\u_lock_m_from_s/q_q[0] )
    );
    xsDFFSA_K1 \u_lock_m_from_s/q_q_reg[1] 
    (
    .C(HCLKM),
    .D(\u_lock_m_from_s/q_q[0] ),
    .Q(m_lock_q)
    );
    xsDFFSA_K1 \u_sema_s_from_m/q_q_reg[0] 
    (
    .C(HCLKS),
    .D(m_tx_sema_q),
    .Q(\u_sema_s_from_m/q_q [0])
    );
    xsDFFSA_K1 \u_sema_s_from_m/q_q_reg[1] 
    (
    .C(HCLKS),
    .D(\u_sema_s_from_m/q_q [0]),
    .Q(s_rx_sema_q)
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[31] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[31]),
    .Q(\u_haddr/q_q[31] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[30] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[30]),
    .Q(\u_haddr/q_q[30] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[29] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[29]),
    .Q(\u_haddr/q_q[29] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[28] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[28]),
    .Q(\u_haddr/q_q[28] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[27] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[27]),
    .Q(\u_haddr/q_q[27] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[26] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[26]),
    .Q(\u_haddr/q_q[26] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[25] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[25]),
    .Q(\u_haddr/q_q[25] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[24] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[24]),
    .Q(\u_haddr/q_q[24] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[23] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[23]),
    .Q(\u_haddr/q_q[23] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[22] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[22]),
    .Q(\u_haddr/q_q[22] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[21] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[21]),
    .Q(\u_haddr/q_q[21] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[20] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[20]),
    .Q(\u_haddr/q_q[20] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[19] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[19]),
    .Q(\u_haddr/q_q[19] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[18] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[18]),
    .Q(\u_haddr/q_q[18] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[17] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[17]),
    .Q(\u_haddr/q_q[17] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[16] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[16]),
    .Q(\u_haddr/q_q[16] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[15] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[15]),
    .Q(\u_haddr/q_q[15] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[14] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[14]),
    .Q(\u_haddr/q_q[14] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[13] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[13]),
    .Q(\u_haddr/q_q[13] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[12] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[12]),
    .Q(\u_haddr/q_q[12] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[11] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[11]),
    .Q(\u_haddr/q_q[11] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[10] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[10]),
    .Q(\u_haddr/q_q[10] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[9] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[9]),
    .Q(\u_haddr/q_q[9] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[8] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[8]),
    .Q(\u_haddr/q_q[8] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[7] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[7]),
    .Q(\u_haddr/q_q[7] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[6] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[6]),
    .Q(\u_haddr/q_q[6] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[5] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[5]),
    .Q(\u_haddr/q_q[5] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[4] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[4]),
    .Q(\u_haddr/q_q[4] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[3] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[3]),
    .Q(\u_haddr/q_q[3] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[2] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[2]),
    .Q(\u_haddr/q_q[2] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[1] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[1]),
    .Q(\u_haddr/q_q[1] )
    );
    xsDFFSA_K1E1 \u_haddr/q_q_reg[0] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HADDRS[0]),
    .Q(\u_haddr/q_q[0] )
    );
    xsDFFSA_K1E1 \u_hmaster/q_q_reg[0] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HMASTERS[0]),
    .Q(\u_hmaster/q_q[0] )
    );
    xsDFFSA_K1E1 \u_hmastlock/q_q_reg[0] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HMASTLOCKS),
    .Q(\u_hmastlock/q_q[0] )
    );
    xsDFFSA_K1E1 \u_hprot/q_q_reg[3] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HPROTS[3]),
    .Q(\u_hprot/q_q[3] )
    );
    xsDFFSA_K1E1 \u_hprot/q_q_reg[2] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HPROTS[2]),
    .Q(\u_hprot/q_q[2] )
    );
    xsDFFSA_K1E1 \u_hprot/q_q_reg[1] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HPROTS[1]),
    .Q(\u_hprot/q_q[1] )
    );
    xsDFFSA_K1E1 \u_hprot/q_q_reg[0] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HPROTS[0]),
    .Q(\u_hprot/q_q[0] )
    );
    xsDFFSA_K1E1 \u_hsize_1to0/q_q_reg[1] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HSIZES[1]),
    .Q(\u_hsize_1to0/q_q[1] )
    );
    xsDFFSA_K1E1 \u_hsize_1to0/q_q_reg[0] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HSIZES[0]),
    .Q(\u_hsize_1to0/q_q[0] )
    );
    xsDFFSA_K1E1 \u_hwrite/q_q_reg[0] 
    (
    .C(HCLKS),
    .CE(s_ad_en),
    .D(HWRITES),
    .Q(\u_hwrite/q_q[0] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[31] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[31]),
    .Q(\u_hwdata/q_q[31] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[30] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[30]),
    .Q(\u_hwdata/q_q[30] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[29] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[29]),
    .Q(\u_hwdata/q_q[29] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[28] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[28]),
    .Q(\u_hwdata/q_q[28] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[27] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[27]),
    .Q(\u_hwdata/q_q[27] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[26] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[26]),
    .Q(\u_hwdata/q_q[26] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[25] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[25]),
    .Q(\u_hwdata/q_q[25] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[24] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[24]),
    .Q(\u_hwdata/q_q[24] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[23] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[23]),
    .Q(\u_hwdata/q_q[23] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[22] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[22]),
    .Q(\u_hwdata/q_q[22] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[21] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[21]),
    .Q(\u_hwdata/q_q[21] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[20] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[20]),
    .Q(\u_hwdata/q_q[20] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[19] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[19]),
    .Q(\u_hwdata/q_q[19] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[18] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[18]),
    .Q(\u_hwdata/q_q[18] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[17] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[17]),
    .Q(\u_hwdata/q_q[17] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[16] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[16]),
    .Q(\u_hwdata/q_q[16] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[15] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[15]),
    .Q(\u_hwdata/q_q[15] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[14] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[14]),
    .Q(\u_hwdata/q_q[14] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[13] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[13]),
    .Q(\u_hwdata/q_q[13] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[12] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[12]),
    .Q(\u_hwdata/q_q[12] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[11] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[11]),
    .Q(\u_hwdata/q_q[11] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[10] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[10]),
    .Q(\u_hwdata/q_q[10] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[9] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[9]),
    .Q(\u_hwdata/q_q[9] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[8] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[8]),
    .Q(\u_hwdata/q_q[8] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[7] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[7]),
    .Q(\u_hwdata/q_q[7] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[6] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[6]),
    .Q(\u_hwdata/q_q[6] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[5] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[5]),
    .Q(\u_hwdata/q_q[5] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[4] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[4]),
    .Q(\u_hwdata/q_q[4] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[3] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[3]),
    .Q(\u_hwdata/q_q[3] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[2] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[2]),
    .Q(\u_hwdata/q_q[2] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[1] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[1]),
    .Q(\u_hwdata/q_q[1] )
    );
    xsDFFSA_K1E1 \u_hwdata/q_q_reg[0] 
    (
    .C(HCLKS),
    .CE(s_wd_en),
    .D(HWDATAS[0]),
    .Q(\u_hwdata/q_q[0] )
    );
    xsDFFSA_K1E1 \u_resp/q_q_reg[0] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(HRESPM),
    .Q(\u_resp/q_q[0] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[31] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[31] ),
    .Q(\u_rdata/q_q[31] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[30] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[30] ),
    .Q(\u_rdata/q_q[30] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[29] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[29] ),
    .Q(\u_rdata/q_q[29] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[28] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[28] ),
    .Q(\u_rdata/q_q[28] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[27] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[27] ),
    .Q(\u_rdata/q_q[27] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[26] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[26] ),
    .Q(\u_rdata/q_q[26] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[25] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[25] ),
    .Q(\u_rdata/q_q[25] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[24] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[24] ),
    .Q(\u_rdata/q_q[24] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[23] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[23] ),
    .Q(\u_rdata/q_q[23] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[22] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[22] ),
    .Q(\u_rdata/q_q[22] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[21] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[21] ),
    .Q(\u_rdata/q_q[21] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[20] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[20] ),
    .Q(\u_rdata/q_q[20] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[19] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[19] ),
    .Q(\u_rdata/q_q[19] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[18] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[18] ),
    .Q(\u_rdata/q_q[18] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[17] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[17] ),
    .Q(\u_rdata/q_q[17] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[16] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[16] ),
    .Q(\u_rdata/q_q[16] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[15] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[15] ),
    .Q(\u_rdata/q_q[15] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[14] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[14] ),
    .Q(\u_rdata/q_q[14] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[13] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[13] ),
    .Q(\u_rdata/q_q[13] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[12] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[12] ),
    .Q(\u_rdata/q_q[12] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[11] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[11] ),
    .Q(\u_rdata/q_q[11] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[10] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[10] ),
    .Q(\u_rdata/q_q[10] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[9] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[9] ),
    .Q(\u_rdata/q_q[9] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[8] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[8] ),
    .Q(\u_rdata/q_q[8] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[7] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[7] ),
    .Q(\u_rdata/q_q[7] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[6] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[6] ),
    .Q(\u_rdata/q_q[6] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[5] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[5] ),
    .Q(\u_rdata/q_q[5] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[4] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[4] ),
    .Q(\u_rdata/q_q[4] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[3] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[3] ),
    .Q(\u_rdata/q_q[3] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[2] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[2] ),
    .Q(\u_rdata/q_q[2] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[1] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[1] ),
    .Q(\u_rdata/q_q[1] )
    );
    xsDFFSA_K1E1 \u_rdata/q_q_reg[0] 
    (
    .C(HCLKM),
    .CE(m_rd_en),
    .D(\m_rdata[0] ),
    .Q(\u_rdata/q_q[0] )
    );
    xsDFFSA_K1C1 \u_m/m_mode_q_reg 
    (
    .C(HCLKM),
    .CLR(\u_sema_m/n_38 ),
    .D(\u_m/m_mode_q_reg_ctrl_din ),
    .Q(m_tx_sema_nxt)
    );
    xsDFFSA_K1C1 \u_m/m_force_lock_q_reg 
    (
    .C(HCLKM),
    .CLR(\u_sema_m/n_38 ),
    .D(\u_m/m_force_lock_nxt ),
    .Q(\u_m/m_force_lock_q )
    );
    xsDFFSA_K1C1 \u_m/m_delayed_unlock_q_reg 
    (
    .C(HCLKM),
    .CLR(\u_sema_m/n_38 ),
    .D(\u_m/m_delayed_unlock_nxt ),
    .Q(\u_m/m_delayed_unlock_q )
    );
    xsDFFSA_K1P1 \u_m/m_in_rst_q_reg 
    (
    .C(HCLKM),
    .D(HBURSTM[2]),
    .PRE(\u_sema_m/n_38 ),
    .Q(\u_m/m_in_rst_q )
    );
    xsLUTSA4 \u_m/m_delayed_unlock_nxt_iHQX3_andor_decomp_0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(m_lock_q),
    .I3(\u_m/m_force_lock_q ),
    .O(\u_m/m_delayed_unlock_nxt )
    );
    defparam \u_m/m_delayed_unlock_nxt_iHQX3_andor_decomp_0_0 .INIT = 16'H0900;
    xsLUTSA3 \u_m/m_rdata._i_31_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[0]),
    .O(\m_rdata[0] )
    );
    defparam \u_m/m_rdata._i_31_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_30_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[1]),
    .O(\m_rdata[1] )
    );
    defparam \u_m/m_rdata._i_30_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_29_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[2]),
    .O(\m_rdata[2] )
    );
    defparam \u_m/m_rdata._i_29_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_28_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[3]),
    .O(\m_rdata[3] )
    );
    defparam \u_m/m_rdata._i_28_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_27_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[4]),
    .O(\m_rdata[4] )
    );
    defparam \u_m/m_rdata._i_27_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_26_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[5]),
    .O(\m_rdata[5] )
    );
    defparam \u_m/m_rdata._i_26_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_25_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[6]),
    .O(\m_rdata[6] )
    );
    defparam \u_m/m_rdata._i_25_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_24_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[7]),
    .O(\m_rdata[7] )
    );
    defparam \u_m/m_rdata._i_24_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_23_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[8]),
    .O(\m_rdata[8] )
    );
    defparam \u_m/m_rdata._i_23_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_22_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[9]),
    .O(\m_rdata[9] )
    );
    defparam \u_m/m_rdata._i_22_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_21_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[10]),
    .O(\m_rdata[10] )
    );
    defparam \u_m/m_rdata._i_21_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_20_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[11]),
    .O(\m_rdata[11] )
    );
    defparam \u_m/m_rdata._i_20_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_19_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[12]),
    .O(\m_rdata[12] )
    );
    defparam \u_m/m_rdata._i_19_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_18_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[13]),
    .O(\m_rdata[13] )
    );
    defparam \u_m/m_rdata._i_18_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_17_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[14]),
    .O(\m_rdata[14] )
    );
    defparam \u_m/m_rdata._i_17_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_16_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[15]),
    .O(\m_rdata[15] )
    );
    defparam \u_m/m_rdata._i_16_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_15_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[16]),
    .O(\m_rdata[16] )
    );
    defparam \u_m/m_rdata._i_15_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_14_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[17]),
    .O(\m_rdata[17] )
    );
    defparam \u_m/m_rdata._i_14_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_13_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[18]),
    .O(\m_rdata[18] )
    );
    defparam \u_m/m_rdata._i_13_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_12_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[19]),
    .O(\m_rdata[19] )
    );
    defparam \u_m/m_rdata._i_12_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_11_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[20]),
    .O(\m_rdata[20] )
    );
    defparam \u_m/m_rdata._i_11_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_10_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[21]),
    .O(\m_rdata[21] )
    );
    defparam \u_m/m_rdata._i_10_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_9_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[22]),
    .O(\m_rdata[22] )
    );
    defparam \u_m/m_rdata._i_9_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_8_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[23]),
    .O(\m_rdata[23] )
    );
    defparam \u_m/m_rdata._i_8_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_7_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[24]),
    .O(\m_rdata[24] )
    );
    defparam \u_m/m_rdata._i_7_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_6_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[25]),
    .O(\m_rdata[25] )
    );
    defparam \u_m/m_rdata._i_6_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_5_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[26]),
    .O(\m_rdata[26] )
    );
    defparam \u_m/m_rdata._i_5_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_4_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[27]),
    .O(\m_rdata[27] )
    );
    defparam \u_m/m_rdata._i_4_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_3_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[28]),
    .O(\m_rdata[28] )
    );
    defparam \u_m/m_rdata._i_3_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_2_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[29]),
    .O(\m_rdata[29] )
    );
    defparam \u_m/m_rdata._i_2_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_1_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[30]),
    .O(\m_rdata[30] )
    );
    defparam \u_m/m_rdata._i_1_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rdata._i_0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HRDATAM[31]),
    .O(\m_rdata[31] )
    );
    defparam \u_m/m_rdata._i_0_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_rd_en_0 
    (
    .I0(m_tx_sema_q),
    .I1(HREADYM),
    .I2(m_tx_sema_nxt),
    .O(m_rd_en)
    );
    defparam \u_m/m_rd_en_0 .INIT = 8'H48;
    xsLUTSA2 \u_s/s_ad_en_iHQX14_3 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_resp/q_q[0] ),
    .O(\u_s/s_ad_en_iHQX14_3_out )
    );
    defparam \u_s/s_ad_en_iHQX14_3 .INIT = 4'H1;
    xsLUTSA2 \u_s/s_ad_en_iHQX14_4 
    (
    .I0(s_tx_sema_q),
    .I1(s_rx_sema_q),
    .O(\u_s/s_ad_en_iHQX14_4_out )
    );
    defparam \u_s/s_ad_en_iHQX14_4 .INIT = 4'H6;
    xsLUTSA2 \u_s/s_ad_en_iHQX14_2 
    (
    .I0(HSELAHBS),
    .I1(HTRANSS[1]),
    .O(\u_s/s_ad_en_iHQX14_2_out )
    );
    defparam \u_s/s_ad_en_iHQX14_2 .INIT = 4'H8;
    xsLUTSA4 \u_sema_s/q_q_reg_ctrlmux_1 
    (
    .I0(\u_s/s_ad_en_iHQX14_3_out ),
    .I1(HREADYS),
    .I2(\u_s/s_state_q[1] ),
    .I3(\u_s/s_state_q[0] ),
    .O(\u_sema_s/q_q_reg_ctrlmux_1_out )
    );
    defparam \u_sema_s/q_q_reg_ctrlmux_1 .INIT = 16'H0053;
    xsLUTSA2 \u_s/s_run_data/_i_0_0 
    (
    .I0(\u_s/s_state_q[1] ),
    .I1(\u_s/s_state_q[0] ),
    .O(s_wd_en)
    );
    defparam \u_s/s_run_data/_i_0_0 .INIT = 4'H4;
    xsLUTSA4 \u_s/s_state_q_reg[0]_ctrlmux_7 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_s/s_state_q[1] ),
    .I2(\u_s/s_state_q[0] ),
    .I3(\u_resp/q_q[0] ),
    .O(\u_s/s_state_q_reg[0]_ctrlmux_7_out )
    );
    defparam \u_s/s_state_q_reg[0]_ctrlmux_7 .INIT = 16'H0400;
    xsLUTSA4 \u_m/m_hactive_iHQX18_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_m/m_delayed_unlock_q ),
    .I3(\u_m/m_in_rst_q ),
    .O(HACTIVEM)
    );
    defparam \u_m/m_hactive_iHQX18_0 .INIT = 16'HFFF6;
    xsLUTSA3 \u_hmaster/Q_iHQX0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hmaster/q_q[0] ),
    .O(HMASTERM[0])
    );
    defparam \u_hmaster/Q_iHQX0_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwrite/Q_iHQX0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwrite/q_q[0] ),
    .O(HWRITEM)
    );
    defparam \u_hwrite/Q_iHQX0_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_31_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[0] ),
    .O(HWDATAM[0])
    );
    defparam \u_hwdata/Q._i_31_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_30_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[1] ),
    .O(HWDATAM[1])
    );
    defparam \u_hwdata/Q._i_30_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_29_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[2] ),
    .O(HWDATAM[2])
    );
    defparam \u_hwdata/Q._i_29_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_28_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[3] ),
    .O(HWDATAM[3])
    );
    defparam \u_hwdata/Q._i_28_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_27_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[4] ),
    .O(HWDATAM[4])
    );
    defparam \u_hwdata/Q._i_27_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_26_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[5] ),
    .O(HWDATAM[5])
    );
    defparam \u_hwdata/Q._i_26_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_25_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[6] ),
    .O(HWDATAM[6])
    );
    defparam \u_hwdata/Q._i_25_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_24_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[7] ),
    .O(HWDATAM[7])
    );
    defparam \u_hwdata/Q._i_24_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_23_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[8] ),
    .O(HWDATAM[8])
    );
    defparam \u_hwdata/Q._i_23_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_22_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[9] ),
    .O(HWDATAM[9])
    );
    defparam \u_hwdata/Q._i_22_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_21_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[10] ),
    .O(HWDATAM[10])
    );
    defparam \u_hwdata/Q._i_21_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_20_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[11] ),
    .O(HWDATAM[11])
    );
    defparam \u_hwdata/Q._i_20_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_19_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[12] ),
    .O(HWDATAM[12])
    );
    defparam \u_hwdata/Q._i_19_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_18_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[13] ),
    .O(HWDATAM[13])
    );
    defparam \u_hwdata/Q._i_18_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_17_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[14] ),
    .O(HWDATAM[14])
    );
    defparam \u_hwdata/Q._i_17_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_16_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[15] ),
    .O(HWDATAM[15])
    );
    defparam \u_hwdata/Q._i_16_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_15_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[16] ),
    .O(HWDATAM[16])
    );
    defparam \u_hwdata/Q._i_15_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_14_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[17] ),
    .O(HWDATAM[17])
    );
    defparam \u_hwdata/Q._i_14_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_13_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[18] ),
    .O(HWDATAM[18])
    );
    defparam \u_hwdata/Q._i_13_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_12_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[19] ),
    .O(HWDATAM[19])
    );
    defparam \u_hwdata/Q._i_12_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_11_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[20] ),
    .O(HWDATAM[20])
    );
    defparam \u_hwdata/Q._i_11_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_10_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[21] ),
    .O(HWDATAM[21])
    );
    defparam \u_hwdata/Q._i_10_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_9_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[22] ),
    .O(HWDATAM[22])
    );
    defparam \u_hwdata/Q._i_9_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_8_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[23] ),
    .O(HWDATAM[23])
    );
    defparam \u_hwdata/Q._i_8_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_7_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[24] ),
    .O(HWDATAM[24])
    );
    defparam \u_hwdata/Q._i_7_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_6_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[25] ),
    .O(HWDATAM[25])
    );
    defparam \u_hwdata/Q._i_6_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_5_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[26] ),
    .O(HWDATAM[26])
    );
    defparam \u_hwdata/Q._i_5_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_4_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[27] ),
    .O(HWDATAM[27])
    );
    defparam \u_hwdata/Q._i_4_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_3_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[28] ),
    .O(HWDATAM[28])
    );
    defparam \u_hwdata/Q._i_3_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_2_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[29] ),
    .O(HWDATAM[29])
    );
    defparam \u_hwdata/Q._i_2_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_1_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[30] ),
    .O(HWDATAM[30])
    );
    defparam \u_hwdata/Q._i_1_0 .INIT = 8'H60;
    xsLUTSA3 \u_hwdata/Q._i_0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hwdata/q_q[31] ),
    .O(HWDATAM[31])
    );
    defparam \u_hwdata/Q._i_0_0 .INIT = 8'H60;
    xsLUTSA3 \u_m/m_htrans_iHQX6_andor_decomp_0_1 
    (
    .I0(\u_m/m_force_lock_q ),
    .I1(\u_hmastlock/q_q[0] ),
    .I2(\u_m/m_delayed_unlock_q ),
    .O(\u_m/m_htrans_iHQX6_andor_decomp_0_1_out )
    );
    defparam \u_m/m_htrans_iHQX6_andor_decomp_0_1 .INIT = 8'H32;
    xsLUTSA3 \u_hsize_1to0/Q._i_1_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hsize_1to0/q_q[0] ),
    .O(HSIZEM[0])
    );
    defparam \u_hsize_1to0/Q._i_1_0 .INIT = 8'H60;
    xsLUTSA3 \u_hsize_1to0/Q._i_0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hsize_1to0/q_q[1] ),
    .O(HSIZEM[1])
    );
    defparam \u_hsize_1to0/Q._i_0_0 .INIT = 8'H60;
    xsLUTSA3 \u_hprot/Q._i_3_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hprot/q_q[0] ),
    .O(HPROTM[0])
    );
    defparam \u_hprot/Q._i_3_0 .INIT = 8'H60;
    xsLUTSA3 \u_hprot/Q._i_2_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hprot/q_q[1] ),
    .O(HPROTM[1])
    );
    defparam \u_hprot/Q._i_2_0 .INIT = 8'H60;
    xsLUTSA3 \u_hprot/Q._i_1_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hprot/q_q[2] ),
    .O(HPROTM[2])
    );
    defparam \u_hprot/Q._i_1_0 .INIT = 8'H60;
    xsLUTSA3 \u_hprot/Q._i_0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_hprot/q_q[3] ),
    .O(HPROTM[3])
    );
    defparam \u_hprot/Q._i_0_0 .INIT = 8'H60;
    xsLUTSA4 \u_m/m_hmastlock_iHQX16_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_m/m_force_lock_q ),
    .I3(\u_hmastlock/q_q[0] ),
    .O(HMASTLOCKM)
    );
    defparam \u_m/m_hmastlock_iHQX16_0 .INIT = 16'HF690;
    xsLUTSA3 \u_haddr/Q._i_31_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[0] ),
    .O(HADDRM[0])
    );
    defparam \u_haddr/Q._i_31_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_30_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[1] ),
    .O(HADDRM[1])
    );
    defparam \u_haddr/Q._i_30_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_29_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[2] ),
    .O(HADDRM[2])
    );
    defparam \u_haddr/Q._i_29_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_28_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[3] ),
    .O(HADDRM[3])
    );
    defparam \u_haddr/Q._i_28_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_27_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[4] ),
    .O(HADDRM[4])
    );
    defparam \u_haddr/Q._i_27_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_26_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[5] ),
    .O(HADDRM[5])
    );
    defparam \u_haddr/Q._i_26_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_25_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[6] ),
    .O(HADDRM[6])
    );
    defparam \u_haddr/Q._i_25_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_24_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[7] ),
    .O(HADDRM[7])
    );
    defparam \u_haddr/Q._i_24_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_23_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[8] ),
    .O(HADDRM[8])
    );
    defparam \u_haddr/Q._i_23_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_22_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[9] ),
    .O(HADDRM[9])
    );
    defparam \u_haddr/Q._i_22_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_21_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[10] ),
    .O(HADDRM[10])
    );
    defparam \u_haddr/Q._i_21_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_20_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[11] ),
    .O(HADDRM[11])
    );
    defparam \u_haddr/Q._i_20_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_19_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[12] ),
    .O(HADDRM[12])
    );
    defparam \u_haddr/Q._i_19_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_18_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[13] ),
    .O(HADDRM[13])
    );
    defparam \u_haddr/Q._i_18_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_17_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[14] ),
    .O(HADDRM[14])
    );
    defparam \u_haddr/Q._i_17_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_16_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[15] ),
    .O(HADDRM[15])
    );
    defparam \u_haddr/Q._i_16_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_15_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[16] ),
    .O(HADDRM[16])
    );
    defparam \u_haddr/Q._i_15_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_14_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[17] ),
    .O(HADDRM[17])
    );
    defparam \u_haddr/Q._i_14_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_13_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[18] ),
    .O(HADDRM[18])
    );
    defparam \u_haddr/Q._i_13_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_12_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[19] ),
    .O(HADDRM[19])
    );
    defparam \u_haddr/Q._i_12_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_11_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[20] ),
    .O(HADDRM[20])
    );
    defparam \u_haddr/Q._i_11_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_10_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[21] ),
    .O(HADDRM[21])
    );
    defparam \u_haddr/Q._i_10_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_9_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[22] ),
    .O(HADDRM[22])
    );
    defparam \u_haddr/Q._i_9_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_8_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[23] ),
    .O(HADDRM[23])
    );
    defparam \u_haddr/Q._i_8_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_7_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[24] ),
    .O(HADDRM[24])
    );
    defparam \u_haddr/Q._i_7_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_6_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[25] ),
    .O(HADDRM[25])
    );
    defparam \u_haddr/Q._i_6_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_5_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[26] ),
    .O(HADDRM[26])
    );
    defparam \u_haddr/Q._i_5_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_4_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[27] ),
    .O(HADDRM[27])
    );
    defparam \u_haddr/Q._i_4_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_3_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[28] ),
    .O(HADDRM[28])
    );
    defparam \u_haddr/Q._i_3_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_2_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[29] ),
    .O(HADDRM[29])
    );
    defparam \u_haddr/Q._i_2_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_1_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[30] ),
    .O(HADDRM[30])
    );
    defparam \u_haddr/Q._i_1_0 .INIT = 8'H60;
    xsLUTSA3 \u_haddr/Q._i_0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(\u_haddr/q_q[31] ),
    .O(HADDRM[31])
    );
    defparam \u_haddr/Q._i_0_0 .INIT = 8'H60;
    xsLUTSA4 \u_s/s_hresp_out_iHQX17_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_s/s_state_q[1] ),
    .I2(\u_s/s_state_q[0] ),
    .I3(\u_resp/q_q[0] ),
    .O(HRESPS)
    );
    defparam \u_s/s_hresp_out_iHQX17_0 .INIT = 16'HC4C0;
    xsLUTSA3 \u_s/s_hready_out_iHQX16_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_3_out ),
    .I1(\u_s/s_state_q[1] ),
    .I2(\u_s/s_state_q[0] ),
    .O(HREADYOUTS)
    );
    defparam \u_s/s_hready_out_iHQX16_0 .INIT = 8'HCB;
    xsLUTSA2 \u_rdata/Q._i_31_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[0] ),
    .O(HRDATAS[0])
    );
    defparam \u_rdata/Q._i_31_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_30_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[1] ),
    .O(HRDATAS[1])
    );
    defparam \u_rdata/Q._i_30_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_29_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[2] ),
    .O(HRDATAS[2])
    );
    defparam \u_rdata/Q._i_29_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_28_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[3] ),
    .O(HRDATAS[3])
    );
    defparam \u_rdata/Q._i_28_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_27_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[4] ),
    .O(HRDATAS[4])
    );
    defparam \u_rdata/Q._i_27_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_26_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[5] ),
    .O(HRDATAS[5])
    );
    defparam \u_rdata/Q._i_26_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_25_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[6] ),
    .O(HRDATAS[6])
    );
    defparam \u_rdata/Q._i_25_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_24_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[7] ),
    .O(HRDATAS[7])
    );
    defparam \u_rdata/Q._i_24_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_23_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[8] ),
    .O(HRDATAS[8])
    );
    defparam \u_rdata/Q._i_23_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_22_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[9] ),
    .O(HRDATAS[9])
    );
    defparam \u_rdata/Q._i_22_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_21_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[10] ),
    .O(HRDATAS[10])
    );
    defparam \u_rdata/Q._i_21_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_20_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[11] ),
    .O(HRDATAS[11])
    );
    defparam \u_rdata/Q._i_20_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_19_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[12] ),
    .O(HRDATAS[12])
    );
    defparam \u_rdata/Q._i_19_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_18_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[13] ),
    .O(HRDATAS[13])
    );
    defparam \u_rdata/Q._i_18_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_17_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[14] ),
    .O(HRDATAS[14])
    );
    defparam \u_rdata/Q._i_17_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_16_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[15] ),
    .O(HRDATAS[15])
    );
    defparam \u_rdata/Q._i_16_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_15_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[16] ),
    .O(HRDATAS[16])
    );
    defparam \u_rdata/Q._i_15_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_14_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[17] ),
    .O(HRDATAS[17])
    );
    defparam \u_rdata/Q._i_14_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_13_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[18] ),
    .O(HRDATAS[18])
    );
    defparam \u_rdata/Q._i_13_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_12_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[19] ),
    .O(HRDATAS[19])
    );
    defparam \u_rdata/Q._i_12_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_11_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[20] ),
    .O(HRDATAS[20])
    );
    defparam \u_rdata/Q._i_11_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_10_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[21] ),
    .O(HRDATAS[21])
    );
    defparam \u_rdata/Q._i_10_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_9_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[22] ),
    .O(HRDATAS[22])
    );
    defparam \u_rdata/Q._i_9_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_8_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[23] ),
    .O(HRDATAS[23])
    );
    defparam \u_rdata/Q._i_8_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_7_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[24] ),
    .O(HRDATAS[24])
    );
    defparam \u_rdata/Q._i_7_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_6_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[25] ),
    .O(HRDATAS[25])
    );
    defparam \u_rdata/Q._i_6_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_5_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[26] ),
    .O(HRDATAS[26])
    );
    defparam \u_rdata/Q._i_5_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_4_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[27] ),
    .O(HRDATAS[27])
    );
    defparam \u_rdata/Q._i_4_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_3_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[28] ),
    .O(HRDATAS[28])
    );
    defparam \u_rdata/Q._i_3_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_2_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[29] ),
    .O(HRDATAS[29])
    );
    defparam \u_rdata/Q._i_2_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_1_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[30] ),
    .O(HRDATAS[30])
    );
    defparam \u_rdata/Q._i_1_0 .INIT = 4'H4;
    xsLUTSA2 \u_rdata/Q._i_0_0 
    (
    .I0(\u_s/s_ad_en_iHQX14_4_out ),
    .I1(\u_rdata/q_q[31] ),
    .O(HRDATAS[31])
    );
    defparam \u_rdata/Q._i_0_0 .INIT = 4'H4;
    xsINVSA \u_sema_m/_i_0_0 
    (
    .I(HRESETMn),
    .O(\u_sema_m/n_38 )
    );
    xsINVSA \u_s/_i_0_0 
    (
    .I(HRESETSn),
    .O(\u_s/n_37 )
    );
    xsLUTSA5 \u_m/m_force_lock_nxt_iHQX14_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(m_lock_q),
    .I3(\u_m/m_force_lock_q ),
    .I4(\u_hmastlock/q_q[0] ),
    .O(\u_m/m_force_lock_nxt )
    );
    defparam \u_m/m_force_lock_nxt_iHQX14_0 .INIT = 32'HF6669000;
    xsLUTSA5 \u_s/s_ad_en_iHQX14_0 
    (
    .I0(HREADYS),
    .I1(\u_s/s_state_q[1] ),
    .I2(\u_s/s_state_q[0] ),
    .I3(\u_s/s_ad_en_iHQX14_3_out ),
    .I4(\u_s/s_ad_en_iHQX14_2_out ),
    .O(s_ad_en)
    );
    defparam \u_s/s_ad_en_iHQX14_0 .INIT = 32'HCEC20000;
    xsLUTSA5 \u_sema_s/q_q_reg_ctrlmux_0 
    (
    .I0(s_tx_sema_q),
    .I1(HWRITES),
    .I2(\u_s/s_ad_en_iHQX14_2_out ),
    .I3(\u_sema_s/q_q_reg_ctrlmux_1_out ),
    .I4(s_wd_en),
    .O(\u_sema_s/q_q_reg_ctrl_din )
    );
    defparam \u_sema_s/q_q_reg_ctrlmux_0 .INIT = 32'H5555AA9A;
    xsLUTSA6 \u_s/s_state_q_reg[0]_ctrlmux_0 
    (
    .I0(\u_s/s_state_q[1] ),
    .I1(\u_s/s_state_q[0] ),
    .I2(HWRITES),
    .I3(\u_s/s_ad_en_iHQX14_2_out ),
    .I4(\u_s/s_state_q_reg[0]_ctrlmux_6_out ),
    .I5(\u_s/s_state_q_reg[0]_ctrlmux_7_out ),
    .O(\u_s/s_state_q_reg[0]_ctrl_din )
    );
    defparam \u_s/s_state_q_reg[0]_ctrlmux_0 .INIT = 64'HCCCCFFFFCCCCB000;
    xsLUTSA6 \u_s/s_state_q_reg[0]_ctrlmux_6 
    (
    .I0(HREADYS),
    .I1(\u_s/s_state_q[1] ),
    .I2(\u_s/s_state_q[0] ),
    .I3(HSELAHBS),
    .I4(HTRANSS[1]),
    .I5(\u_s/s_ad_en_iHQX14_4_out ),
    .O(\u_s/s_state_q_reg[0]_ctrlmux_6_out )
    );
    defparam \u_s/s_state_q_reg[0]_ctrlmux_6 .INIT = 64'H0D0F0F0F01030303;
    xsLUTSA6 \u_s/s_state_q_reg[1]_ctrlmux_0 
    (
    .I0(\u_s/s_state_q[1] ),
    .I1(\u_s/s_state_q[0] ),
    .I2(HWRITES),
    .I3(\u_s/s_ad_en_iHQX14_2_out ),
    .I4(\u_s/s_state_q_reg[0]_ctrlmux_7_out ),
    .I5(\u_s/s_state_q_reg[0]_ctrlmux_6_out ),
    .O(\u_s/s_state_q_reg[1]_ctrl_din )
    );
    defparam \u_s/s_state_q_reg[1]_ctrlmux_0 .INIT = 64'HAAAAAAAAFFFF4F44;
    xsLUTSA5 \u_m/m_htrans_iHQX6_andor_decomp_0_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(m_tx_sema_nxt),
    .I3(\u_m/m_in_rst_q ),
    .I4(\u_m/m_htrans_iHQX6_andor_decomp_0_1_out ),
    .O(HTRANSM[1])
    );
    defparam \u_m/m_htrans_iHQX6_andor_decomp_0_0 .INIT = 32'H00000024;
    xsLUTSA6 \u_m/m_mode_q_reg_ctrlmux_0 
    (
    .I0(m_tx_sema_q),
    .I1(m_rx_sema_q),
    .I2(HREADYM),
    .I3(m_tx_sema_nxt),
    .I4(\u_m/m_in_rst_q ),
    .I5(\u_m/m_htrans_iHQX6_andor_decomp_0_1_out ),
    .O(\u_m/m_mode_q_reg_ctrl_din )
    );
    defparam \u_m/m_mode_q_reg_ctrlmux_0 .INIT = 64'HFF00EF80FF00CFC0;
    xsLUTSA4 \u_sema_m/q_q_reg_ctrlmux_0 
    (
    .I0(m_tx_sema_q),
    .I1(HREADYM),
    .I2(m_tx_sema_nxt),
    .I3(\u_m/m_in_rst_q ),
    .O(\u_sema_m/q_q_reg_ctrl_din )
    );
    defparam \u_sema_m/q_q_reg_ctrlmux_0 .INIT = 16'HAAE2;
    xs0 _i_3_0
    (
    .G(HBURSTM[2])
    );
    assign HBURSTM[1] = HBURSTM[2]; 
    assign HBURSTM[0] = HBURSTM[2]; 
    assign HSIZEM[2] = HBURSTM[2]; 
    assign HTRANSM[0] = HBURSTM[2]; 
endmodule
module ahb_master_expander #(
    parameter MASTER_NUM        = 16,
    parameter ADDR_WIDTH        = 32,
    parameter DATA_WIDTH        = 32,
    parameter BASE_ADDR         = 32'h60000000,  
    parameter OFFSET_SIZE_WIDTH = 27    
)(
    input                       HCLK,               
    input                       sHSEL,
    input      [ADDR_WIDTH-1:0] sHADDR,
    input      [1:0]            sHTRANS,
    input                       sHWRITE,
    input      [2:0]            sHSIZE,
    input      [2:0]            sHBURST,
    input      [3:0]            sHPROT,
    input      [DATA_WIDTH-1:0] sHWDATA,
    output reg [DATA_WIDTH-1:0] sHRDATA,
    input                       sHMASTLOCK,
    input                       sHREADYMUX,
    output reg                  sHREADYOUT,
    output reg                  sHRESP,
    output reg [MASTER_NUM-1:0]            mHSEL,
    output reg [ADDR_WIDTH*MASTER_NUM-1:0] mHADDR,
    output reg [2*MASTER_NUM-1:0]          mHTRANS,
    output reg [MASTER_NUM-1:0]            mHWRITE,
    output reg [3*MASTER_NUM-1:0]          mHSIZE,
    output reg [3*MASTER_NUM-1:0]          mHBURST,
    output reg [4*MASTER_NUM-1:0]          mHPROT,
    output reg [DATA_WIDTH*MASTER_NUM-1:0] mHWDATA,
    input      [DATA_WIDTH*MASTER_NUM-1:0] mHRDATA,
    output reg [MASTER_NUM-1:0]            mHMASTLOCK,
    output reg [MASTER_NUM-1:0]            mHREADYMUX,
    input      [MASTER_NUM-1:0]            mHREADYOUT,
    input      [MASTER_NUM-1:0]            mHRESP
);
wire [3:0] raw_sel = sHADDR[OFFSET_SIZE_WIDTH+3:OFFSET_SIZE_WIDTH] - BASE_ADDR[OFFSET_SIZE_WIDTH+3:OFFSET_SIZE_WIDTH];
wire [3:0] slave_sel = (raw_sel < MASTER_NUM) ? raw_sel : (MASTER_NUM - 1);
reg [3:0] sel_reg = 4'd0;   
always @(posedge HCLK) begin
    if (sHTRANS[1] && sHREADYOUT)   
    sel_reg <= slave_sel;
    else
    sel_reg <= sel_reg;
end
genvar i;
generate
    for (i = 0; i < MASTER_NUM; i = i + 1) begin : SLAVE_MUX
    always @(*) begin
    mHSEL[i]                            = (slave_sel == i) ? sHSEL : 1'b0;
    mHADDR[i*ADDR_WIDTH +: ADDR_WIDTH]  = sHADDR;
    mHTRANS[i*2 +: 2]                   = (sHTRANS != 2'b00) && (slave_sel == i) ? sHTRANS : 2'b00; 
    mHWRITE[i]                          = sHWRITE;
    mHSIZE[i*3 +: 3]                    = sHSIZE;
    mHBURST[i*3 +: 3]                   = sHBURST;
    mHPROT[i*4 +: 4]                    = sHPROT;
    mHWDATA[i*DATA_WIDTH +: DATA_WIDTH] = sHWDATA;
    mHMASTLOCK[i]                       = (slave_sel == i) ? sHMASTLOCK : 1'b0;
    end
    end
endgenerate
always @(*) begin
    sHRDATA = mHRDATA[sel_reg*DATA_WIDTH +: DATA_WIDTH];
    sHRESP  = mHRESP[sel_reg];
    sHREADYOUT  = &mHREADYOUT;
    mHREADYMUX  = {MASTER_NUM{&mHREADYOUT & sHREADYMUX}};
end
endmodule
