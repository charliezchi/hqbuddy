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
wire    [31:0]  M00_PADDR   ;
wire            M00_PSEL    ;
wire            M00_PENABLE ;
wire            M00_PWRITE  ;
wire    [31:0]  M00_PWDATA  ;
wire    [2:0]   M00_PPROT   ;
wire    [3:0]   M00_PSTRB   ;
wire    [31:0]  M00_PRDATA  ;
wire            M00_PREADY  ;
wire            M00_PSLVERR ;

wire    [31:0]  M01_PADDR   ;
wire            M01_PSEL    ;
wire            M01_PENABLE ;
wire            M01_PWRITE  ;
wire    [31:0]  M01_PWDATA  ;
wire    [2:0]   M01_PPROT   ;
wire    [3:0]   M01_PSTRB   ;
wire    [31:0]  M01_PRDATA  ;
wire            M01_PREADY  ;
wire            M01_PSLVERR ;
//////////////////////////////////////////
//pll
wire    clk_100m;
wire    clk_50m;
wire    clk_50;

PLL_FREQ pll_isnt(
    .CLKI       (CLK_IN     ), 
    .CLKOP      (clk_100m   ), 
    .CLKOS      (clk_50m    )
);

//core instance
STAR_Processor mcu_inst(
    .CLK_IN             (clk_100m     ),         
    .SWD_CLK            (SWD_CLK    ),        
    .SWD_IO             (SWD_IO     ),         
    .GPIO0              (LED2       ),
    .GPIO1              (LED3       ),
    .UART0_RX           (UART0_RX   ),
    .UART0_TX           (UART0_TX   ), 
    .CH0_CDC_CLK        (clk_50m),    
    .CH0_M00_PADDR      (M00_PADDR      ),
    .CH0_M00_PSEL       (M00_PSEL       ),
    .CH0_M00_PENABLE    (M00_PENABLE    ),
    .CH0_M00_PWRITE     (M00_PWRITE     ),
    .CH0_M00_PWDATA     (M00_PWDATA     ),
    .CH0_M00_PPROT      (M00_PPROT      ),
    .CH0_M00_PSTRB      (M00_PSTRB      ),
    .CH0_M00_PRDATA     (M00_PRDATA     ),
    .CH0_M00_PREADY     (M00_PREADY     ),
    .CH0_M00_PSLVERR    (M00_PSLVERR    ), 
    .CH0_M01_PADDR      (M01_PADDR      ),
    .CH0_M01_PSEL       (M01_PSEL       ),
    .CH0_M01_PENABLE    (M01_PENABLE    ),
    .CH0_M01_PWRITE     (M01_PWRITE     ),
    .CH0_M01_PWDATA     (M01_PWDATA     ),
    .CH0_M01_PPROT      (M01_PPROT      ),
    .CH0_M01_PSTRB      (M01_PSTRB      ),
    .CH0_M01_PRDATA     (M01_PRDATA     ),
    .CH0_M01_PREADY     (M01_PREADY     ),
    .CH0_M01_PSLVERR    (M01_PSLVERR    ),   
    .RST_N              (RST_N      )         
);


//apb_slave instance
apb3_slave #(
	    .ADDR_WIDTH	    (32         ),
	    .DATA_WIDTH	    (32         ),
	    .NUM_REG	    (4          )
) 
apb3_slave_inst(
	    .clk            (clk_50m     ),
	    .resetn         (RST_N      ),
	    .PADDR          (M00_PADDR      ),
	    .PSEL           (M00_PSEL       ),
	    .PENABLE        (M00_PENABLE    ),
	    .PREADY         (M00_PREADY     ),
	    .PWRITE         (M00_PWRITE     ),
	    .PWDATA         (M00_PWDATA     ),
	    .PRDATA         (M00_PRDATA     ),
	    .PSLVERROR      (M00_PSLVERR    )
);


//apb_slave instance
apb3_slave #(
	    .ADDR_WIDTH	    (32         ),
	    .DATA_WIDTH	    (32         ),
	    .NUM_REG	    (4          )
) 
apb3_slave1_inst(
	    .clk            (clk_50m     ),
	    .resetn         (RST_N      ),
	    .PADDR          (M01_PADDR      ),
	    .PSEL           (M01_PSEL       ),
	    .PENABLE        (M01_PENABLE    ),
	    .PREADY         (M01_PREADY     ),
	    .PWRITE         (M01_PWRITE     ),
	    .PWDATA         (M01_PWDATA     ),
	    .PRDATA         (M01_PRDATA     ),
	    .PSLVERROR      (M01_PSLVERR    )
);

endmodule
