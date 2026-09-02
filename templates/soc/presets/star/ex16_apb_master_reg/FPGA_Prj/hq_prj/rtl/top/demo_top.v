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
wire    [31:0]  PADDR   ;
wire            PSEL    ;
wire            PENABLE ;
wire            PWRITE  ;
wire    [31:0]  PWDATA  ;
wire    [2:0]   PPROT   ;
wire    [3:0]   PSTRB   ;
wire    [31:0]  PRDATA  ;
wire            PREADY  ;
wire            PSLVERR ;


//core instance
STAR_Processor mcu_inst(
    .CLK_IN             (CLK_IN     ),         
    .SWD_CLK            (SWD_CLK    ),        
    .SWD_IO             (SWD_IO     ),         
    .GPIO0              (LED2       ),
    .GPIO1              (LED3       ),
    .UART0_RX           (UART0_RX   ),
    .UART0_TX           (UART0_TX   ), 
    .CH0_M00_PADDR      (PADDR      ),
    .CH0_M00_PSEL       (PSEL       ),
    .CH0_M00_PENABLE    (PENABLE    ),
    .CH0_M00_PWRITE     (PWRITE     ),
    .CH0_M00_PWDATA     (PWDATA     ),
    .CH0_M00_PPROT      (PPROT      ),
    .CH0_M00_PSTRB      (PSTRB      ),
    .CH0_M00_PRDATA     (PRDATA     ),
    .CH0_M00_PREADY     (PREADY     ),
    .CH0_M00_PSLVERR    (PSLVERR    ),   
    .RST_N              (RST_N      )         
);


//apb_slave instance
apb3_slave #(
	    .ADDR_WIDTH	    (32         ),
	    .DATA_WIDTH	    (32         ),
	    .NUM_REG	    (4          )
) 
apb3_slave_inst(
	    .clk            (CLK_IN     ),
	    .resetn         (RST_N      ),
	    .PADDR          (PADDR      ),
	    .PSEL           (PSEL       ),
	    .PENABLE        (PENABLE    ),
	    .PREADY         (PREADY     ),
	    .PWRITE         (PWRITE     ),
	    .PWDATA         (PWDATA     ),
	    .PRDATA         (PRDATA     ),
	    .PSLVERROR      (PSLVERR    )
);


endmodule
