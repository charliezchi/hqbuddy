`include "../include/inc_demo.v"

module demo_top(
    input  wire         CLK_IN,         
    //## SWD interface
    input  wire         SWD_CLK,        
    inout  wire         SWD_IO,         
    //## GPIO interface
    inout  wire         LED2, 
    inout  wire         LED3,

    output reg          FPGA_LED, 
    //## UART0 interface
    input  wire         UART0_RX,        
    output wire         UART0_TX,        
    //## SPI0 interface
    output wire         SPI0_SCK_OUT,           
    output wire         SPI0_SEL_OUT,                
    inout wire [3:0]    SPI0_DATA,             
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

wire          SPI0_SCK_IN = 1'b1;     
wire          SPI0_SEL_IN = 1'b1;

//core instance
STAR_Processor mcu_inst(
    .CLK_IN             (CLK_IN      ),         
    .SWD_CLK            (SWD_CLK     ),        
    .SWD_IO             (SWD_IO      ),         
    .GPIO0              (LED2        ),
    .GPIO1              (LED3        ), 
    .UART0_RX           (UART0_RX    ),
    .UART0_TX           (UART0_TX    ), 
    .SPI0_SCK_OUT       (SPI0_SCK_OUT),     
    .SPI0_SEL_OUT       (SPI0_SEL_OUT),     
    .SPI0_SCK_IN        (SPI0_SCK_IN ),  
    .SPI0_SEL_IN        (SPI0_SEL_IN ),  
    .SPI0_DATA          (SPI0_DATA   ),              
    .RST_N              (RST_N       )       
);
endmodule
