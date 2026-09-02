`include "../include/inc_demo.v"

module demo_top(
    input  wire         CLK_IN,         
    //## SWD interface
    input  wire         SWD_CLK,        
    inout  wire         SWD_IO,         
    //## GPIO interface
    inout  wire         LED2, 
    inout  wire         LED3,
    inout  wire         GPIO31,
    //## UART0 interface
    input  wire         UART0_RX,        
    output wire         UART0_TX, 
    //## I2C interface
    inout  wire         I2C_SCL,            
    inout  wire         I2C_SDA, 
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

//core instance
cortexM3 mcu_inst(
    .CLK_IN             (CLK_IN      ),         
    .SWD_CLK            (SWD_CLK     ),        
    .SWD_IO             (SWD_IO      ),         
    .GPIO0              (LED2        ),
    .GPIO1              (LED3        ), 
    .GPIO31             (GPIO31      ),  
    .UART0_RX           (UART0_RX    ),
    .UART0_TX           (UART0_TX    ), 
    .I2C_SCL            (I2C_SCL     ),
    .I2C_SDA            (I2C_SDA     ),  
    .RST_N              (RST_N       )       
);
endmodule
