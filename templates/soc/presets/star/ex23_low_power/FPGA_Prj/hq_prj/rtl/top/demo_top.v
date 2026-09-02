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
    input  wire         SW1,

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

////////////////////////////////////////////////////
wire        key_release;
reg         clk_en;
wire        clk_mcu;
wire        clk_200;
wire        locked;
reg [28:0]  clk_cnt;
reg         mcu_run;
reg         clk_on;
reg         clk_off;

PLL_FREQ pll_inst(
    .CLKI   (CLK_IN ), 
    .CLKOP  (clk_200), 
    .LOCK   (locked)
    );

always @(posedge CLK_IN)
begin
    if  (!RST_N)
        clk_cnt <= 29'd0;
    else if (clk_cnt == 29'd275_000_000) //最大29‘d500_000_000,25MHz时钟下，为20s
        clk_cnt <= 29'd25_000_000;      //mcu启动时间，1s
    else
        clk_cnt <= clk_cnt + 29'd1;  
end

always @(posedge CLK_IN)
begin
    if  (!RST_N)
    begin
        mcu_run <= 1'b0;
        clk_on  <= 1'b1;
        clk_off <= 1'b0;
    end
    else if (clk_cnt == 29'd25_000_000)     //等待MCU正常运行，开启时钟（第一次时，时钟已开启）
    begin                                   //25MHz时钟，1s后开始开关时钟测试
        mcu_run <= 1'b1;
        clk_on  <= 1'b1;
        clk_off <= 1'b0;
    end
    else if (clk_cnt == 29'd150_500_000)     //关闭时钟
    begin
        mcu_run <= 1'b1;
        clk_on  <= 1'b0;
        clk_off <= 1'b1;
    end
    else
    begin
        mcu_run <= mcu_run;
        clk_on  <= clk_on ;
        clk_off <= clk_off;
    end
end

key_debounce debounce_inst(
    .clk        (CLK_IN     ),
    .rst_n      (RST_N      ),
    .key_in     (SW1        ),
    .key_pulse  (key_release)  // 按键释放时输出脉冲
    );

//auto
// always @(posedge CLK_IN)
// begin
//     if  (!RST_N | !mcu_run | clk_on)
//         clk_en <= 1'b1;
//     else if (clk_off)
//         clk_en <= 1'b0;
//     else
//         clk_en <= clk_en;
// end   

//manual
always @(posedge CLK_IN)
begin
    if  (!RST_N | !mcu_run)
        clk_en <= 1'b1;
    else if (key_release)
        clk_en <= ~clk_en;
    else
        clk_en <= clk_en;
end  

xsDCC xsDCC_inst(
    .CLKI   (clk_200    ),
    .CE     (clk_en     ),
    .CLKO   (clk_mcu    )
);

//core instance
STAR_Processor mcu_inst(
    .CLK_IN             (clk_mcu     ),         
    .SWD_CLK            (SWD_CLK     ),        
    .SWD_IO             (SWD_IO      ),         
    .GPIO0              (LED2        ),
    .GPIO1              (LED3        ),   
    .UART0_RX           (UART0_RX    ),
    .UART0_TX           (UART0_TX    ),           
    .RST_N              (RST_N       )       
);
endmodule
