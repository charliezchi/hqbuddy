`include "../include/inc_demo.v"

module demo_top(
    input  wire         CLK_IN,         
    //## SWD interface
    input  wire         SWD_CLK,        
    inout  wire         SWD_IO,         
    //## GPIO interface
    inout  wire         LED2, 
    inout  wire         LED3,
    input  wire         UART0_RX,
    output wire         UART0_TX,

    output reg          FPGA_LED,              
    //## External interrupt interface
    //## reset interface
    input  wire         RST_N  
);
 

// 定义 1Hz 闪烁的计数器参数（25MHz / 25e6 = 1秒）
parameter CLK_FREQ = 25_000_000;  // 25MHz 系统时钟
parameter BLINK_FREQ = 1;         // 1Hz 闪烁频率
localparam COUNT_MAX = CLK_FREQ / (2 * BLINK_FREQ) - 1;

reg [24:0] counter;  // 计数器（最大计数值 > 25e6）
// 计数器逻辑
always @(posedge CLK_IN) begin
    if (!RST_N) begin
        counter <= 0;
        FPGA_LED <= 1'b0;   // 复位时 LED 关闭
    end
    else if (counter == COUNT_MAX) begin
        counter <= 0;
        FPGA_LED <= ~FPGA_LED;  // 翻转 LED 状态
    end
    else begin
        counter <= counter + 1;
    end
end
/////////////////////////////////////////////////////////
wire    [31:0]  CH0_M00_AXIL_AWADDR     ;
wire    [2:0]   CH0_M00_AXIL_AWPROT     ;
wire            CH0_M00_AXIL_AWVALID    ;
wire            CH0_M00_AXIL_AWREADY    ;
wire    [31:0]  CH0_M00_AXIL_WDATA      ;
wire    [3:0]   CH0_M00_AXIL_WSTRB      ;
wire            CH0_M00_AXIL_WVALID     ;
wire            CH0_M00_AXIL_WREADY     ;
wire    [1:0]   CH0_M00_AXIL_BRESP      ;
wire            CH0_M00_AXIL_BVALID     ;
wire            CH0_M00_AXIL_BREADY     ;
wire    [31:0]  CH0_M00_AXIL_ARADDR     ;
wire    [2:0]   CH0_M00_AXIL_ARPROT     ;
wire            CH0_M00_AXIL_ARVALID    ;
wire            CH0_M00_AXIL_ARREADY    ;
wire    [31:0]  CH0_M00_AXIL_RDATA      ;
wire    [1:0]   CH0_M00_AXIL_RRESP      ;
wire            CH0_M00_AXIL_RVALID     ;
wire            CH0_M00_AXIL_RREADY     ;


//core instance
cortexM3 mcu_inst(
    .CLK_IN                 (CLK_IN                 ),         
    .SWD_CLK                (SWD_CLK                ),        
    .SWD_IO                 (SWD_IO                 ),         
    .GPIO0                  (LED2                   ),
    .GPIO1                  (LED3                   ),
    .UART0_RX               (UART0_RX               ),
    .UART0_TX               (UART0_TX               ), 
    .CH0_M00_AXIL_AWADDR    (CH0_M00_AXIL_AWADDR    ),
    .CH0_M00_AXIL_AWPROT    (CH0_M00_AXIL_AWPROT    ),
    .CH0_M00_AXIL_AWVALID   (CH0_M00_AXIL_AWVALID   ),
    .CH0_M00_AXIL_AWREADY   (CH0_M00_AXIL_AWREADY   ),
    .CH0_M00_AXIL_WDATA     (CH0_M00_AXIL_WDATA     ),
    .CH0_M00_AXIL_WSTRB     (CH0_M00_AXIL_WSTRB     ),
    .CH0_M00_AXIL_WVALID    (CH0_M00_AXIL_WVALID    ),
    .CH0_M00_AXIL_WREADY    (CH0_M00_AXIL_WREADY    ),
    .CH0_M00_AXIL_BRESP     (CH0_M00_AXIL_BRESP     ),
    .CH0_M00_AXIL_BVALID    (CH0_M00_AXIL_BVALID    ),
    .CH0_M00_AXIL_BREADY    (CH0_M00_AXIL_BREADY    ),
    .CH0_M00_AXIL_ARADDR    (CH0_M00_AXIL_ARADDR    ),
    .CH0_M00_AXIL_ARPROT    (CH0_M00_AXIL_ARPROT    ),
    .CH0_M00_AXIL_ARVALID   (CH0_M00_AXIL_ARVALID   ),
    .CH0_M00_AXIL_ARREADY   (CH0_M00_AXIL_ARREADY   ),
    .CH0_M00_AXIL_RDATA     (CH0_M00_AXIL_RDATA     ),
    .CH0_M00_AXIL_RRESP     (CH0_M00_AXIL_RRESP     ),
    .CH0_M00_AXIL_RVALID    (CH0_M00_AXIL_RVALID    ),
    .CH0_M00_AXIL_RREADY    (CH0_M00_AXIL_RREADY    ),
    .RST_N                  (RST_N                  )         
);


// Instantiation of Axi Bus Interface S00_AXI
 axi4_lite_slave # ( 
    .C_S_AXI_DATA_WIDTH    (32),
    .C_S_AXI_ADDR_WIDTH    (32)
 ) axil_slave_inst (
    .S_AXI_ACLK             (CLK_IN                 ),
    .S_AXI_ARESETN          (RST_N                  ),
    .S_AXI_AWADDR           (CH0_M00_AXIL_AWADDR    ),
    .S_AXI_AWPROT           (CH0_M00_AXIL_AWPROT    ),
    .S_AXI_AWVALID          (CH0_M00_AXIL_AWVALID   ),
    .S_AXI_AWREADY          (CH0_M00_AXIL_AWREADY   ),
    .S_AXI_WDATA            (CH0_M00_AXIL_WDATA     ),
    .S_AXI_WSTRB            (CH0_M00_AXIL_WSTRB     ),
    .S_AXI_WVALID           (CH0_M00_AXIL_WVALID    ),
    .S_AXI_WREADY           (CH0_M00_AXIL_WREADY    ),
    .S_AXI_BRESP            (CH0_M00_AXIL_BRESP     ),
    .S_AXI_BVALID           (CH0_M00_AXIL_BVALID    ),
    .S_AXI_BREADY           (CH0_M00_AXIL_BREADY    ),
    .S_AXI_ARADDR           (CH0_M00_AXIL_ARADDR    ),
    .S_AXI_ARPROT           (CH0_M00_AXIL_ARPROT    ),
    .S_AXI_ARVALID          (CH0_M00_AXIL_ARVALID   ),
    .S_AXI_ARREADY          (CH0_M00_AXIL_ARREADY   ),
    .S_AXI_RDATA            (CH0_M00_AXIL_RDATA     ),
    .S_AXI_RRESP            (CH0_M00_AXIL_RRESP     ),
    .S_AXI_RVALID           (CH0_M00_AXIL_RVALID    ),
    .S_AXI_RREADY           (CH0_M00_AXIL_RREADY    )
 );



endmodule
