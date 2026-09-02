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
wire    [31:0]  M00_ROMWADDRESS ;
wire    [31:0]  M00_ROMWDATA    ;
wire            M00_regW_en     ;
wire    [31:0]  M00_ROMRADDRESS ;
wire    [31:0]  M00_ROMRDATA1   ;
wire    [31:0]  M00_ROMRDATA    ;
wire    [31:0]  M00_ROMCONTROL  ;

wire    [31:0]  M01_ROMWADDRESS ;
wire    [31:0]  M01_ROMWDATA    ;
wire            M01_regW_en     ;
wire    [31:0]  M01_ROMRADDRESS ;
wire    [31:0]  M01_ROMRDATA1   ;
wire    [31:0]  M01_ROMRDATA    ;
wire    [31:0]  M01_ROMCONTROL  ;

wire            M00_HSEL        ;
wire    [31:0]  M00_HADDR       ;
wire    [1:0]   M00_HTRANS      ;
wire    [2:0]   M00_HSIZE       ;
wire    [2:0]   M00_HBURST      ;
wire            M00_HMASTLOCK   ;
wire    [3:0]   M00_HPROT       ;
wire            M00_HRESP       ;
wire            M00_HWRITE      ;
wire    [31:0]  M00_HWDATA      ;
wire    [31:0]  M00_HRDATA      ;
wire            M00_HREADYMUX   ;
wire            M00_HREADYOUT   ;

wire            M01_HSEL        ;
wire    [31:0]  M01_HADDR       ;
wire    [1:0]   M01_HTRANS      ;
wire    [2:0]   M01_HSIZE       ;
wire    [2:0]   M01_HBURST      ;
wire            M01_HMASTLOCK   ;
wire    [3:0]   M01_HPROT       ;
wire            M01_HRESP       ;
wire            M01_HWRITE      ;
wire    [31:0]  M01_HWDATA      ;
wire    [31:0]  M01_HRDATA      ;
wire            M01_HREADYMUX   ;
wire            M01_HREADYOUT   ;

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
    .CLK_IN             (clk_100m   ),         
    .SWD_CLK            (SWD_CLK    ),        
    .SWD_IO             (SWD_IO     ),         
    .GPIO0              (LED2       ),
    .GPIO1              (LED3       ),
    .UART0_RX           (UART0_RX    ),
    .UART0_TX           (UART0_TX    ), 

    .CH0_CDC_CLK        (clk_50m    ),   
    .CH0_M00_HSEL       (M00_HSEL       ),
    .CH0_M00_HADDR      (M00_HADDR      ),
    .CH0_M00_HTRANS     (M00_HTRANS     ),
    .CH0_M00_HSIZE      (M00_HSIZE      ),
    .CH0_M00_HBURST     (M00_HBURST     ),
    .CH0_M00_HMASTLOCK  (M00_HMASTLOCK  ),
    .CH0_M00_HPROT      (M00_HPROT      ),
    .CH0_M00_HRESP      (M00_HRESP      ),
    .CH0_M00_HWRITE     (M00_HWRITE     ),
    .CH0_M00_HWDATA     (M00_HWDATA     ),
    .CH0_M00_HRDATA     (M00_HRDATA     ),
    .CH0_M00_HREADYMUX  (M00_HREADYMUX  ),
    .CH0_M00_HREADYOUT  (M00_HREADYOUT  ),   
    .CH0_M01_HSEL       (M01_HSEL       ),
    .CH0_M01_HADDR      (M01_HADDR      ),
    .CH0_M01_HTRANS     (M01_HTRANS     ),
    .CH0_M01_HSIZE      (M01_HSIZE      ),
    .CH0_M01_HBURST     (M01_HBURST     ),
    .CH0_M01_HMASTLOCK  (M01_HMASTLOCK  ),
    .CH0_M01_HPROT      (M01_HPROT      ),
    .CH0_M01_HRESP      (M01_HRESP      ),
    .CH0_M01_HWRITE     (M01_HWRITE     ),
    .CH0_M01_HWDATA     (M01_HWDATA     ),
    .CH0_M01_HRDATA     (M01_HRDATA     ),
    .CH0_M01_HREADYMUX  (M01_HREADYMUX  ),
    .CH0_M01_HREADYOUT  (M01_HREADYOUT  ),               
    .RST_N              (RST_N      )       
);

//ahb_slave0 instance
cmsdk_ahb_eg_slave #(32) ahb_slave0(
  .HCLK      (clk_50m    ),// Clock
  .HRESETn   (RST_N     ),  // Reset
  .ECOREVNUM (4'b0      ), // Engineering-change-order revision bits
  
  // AHB connection to master
  .HSELS     (1'b1      ),
  .HADDRS    (M00_HADDR     ),
  .HTRANSS   (M00_HTRANS    ),
  .HSIZES    (M00_HSIZE     ),
  .HWRITES   (M00_HWRITE    ),
  .HREADYS   (M00_HREADYMUX ),
  .HWDATAS   (M00_HWDATA    ),
  .HREADYOUTS(M00_HREADYOUT ),
  .HRESPS    (M00_HRESP     ),
  .HRDATAS   (M00_HRDATA    ),
  
  //ROM W/R Data
  .ROMCONTROL	(M00_ROMCONTROL),
  .ROMWADDRESS	(M00_ROMWADDRESS),
  .ROMWDATA	    (M00_ROMWDATA),
  .regW_en      (M00_regW_en),
  .ROMRADDRESS	(M00_ROMRADDRESS),
  .ROMRDATA	    (M00_ROMRDATA)
);

// ram0 instance
EBR_PDP U_EBR_PDP0(
   .WrAddress   (M00_ROMWADDRESS[9:0]),
   .RdAddress   (M00_ROMRADDRESS[9:0]),
   .Data        (M00_ROMWDATA),
   .WE          (M00_regW_en),
   .RdClock     (clk_50m),
   .RdClockEn   (1'b1), 
   .Reset       (1'b0),
   .WrClock     (clk_50m),
   .WrClockEn   (1'b1),
   .Q           (M00_ROMRDATA)
);

//ahb_slave1 instance
cmsdk_ahb_eg_slave #(32) ahb_slave1(
  .HCLK      (clk_50m    ),// Clock
  .HRESETn   (RST_N     ),  // Reset
  .ECOREVNUM (4'b0      ), // Engineering-change-order revision bits
  
  // AHB connection to master
  .HSELS     (M01_HSEL      ),
  .HADDRS    (M01_HADDR     ),
  .HTRANSS   (M01_HTRANS    ),
  .HSIZES    (M01_HSIZE     ),
  .HWRITES   (M01_HWRITE    ),
  .HREADYS   (M01_HREADYMUX ),
  .HWDATAS   (M01_HWDATA    ),
  .HREADYOUTS(M01_HREADYOUT ),
  .HRESPS    (M01_HRESP     ),
  .HRDATAS   (M01_HRDATA    ),
  
  //ROM W/R Data
  .ROMCONTROL	(M01_ROMCONTROL),
  .ROMWADDRESS	(M01_ROMWADDRESS),
  .ROMWDATA	    (M01_ROMWDATA),
  .regW_en      (M01_regW_en),
  .ROMRADDRESS	(M01_ROMRADDRESS),
  .ROMRDATA	    (M01_ROMRDATA)
);

// ram1 instance
EBR_PDP U_EBR_PDP1(
   .WrAddress   (M01_ROMWADDRESS[9:0]),
   .RdAddress   (M01_ROMRADDRESS[9:0]),
   .Data        (M01_ROMWDATA),
   .WE          (M01_regW_en),
   .RdClock     (clk_50m),
   .RdClockEn   (1'b1), 
   .Reset       (1'b0),
   .WrClock     (clk_50m),
   .WrClockEn   (1'b1),
   .Q           (M01_ROMRDATA)
);

endmodule
