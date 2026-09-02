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
wire    [31:0]  ROMWADDRESS ;
wire    [31:0]  ROMWDATA    ;
wire            regW_en     ;
wire    [31:0]  ROMRADDRESS ;
wire    [31:0]  ROMRDATA1   ;
wire    [31:0]  ROMRDATA    ;
wire    [31:0]  ROMCONTROL  ;

wire            HSEL        ;
wire    [31:0]  HADDR       ;
wire    [1:0]   HTRANS      ;
wire    [2:0]   HSIZE       ;
wire    [2:0]   HBURST      ;
wire            HMASTLOCK   ;
wire    [3:0]   HPROT       ;
wire            HRESP       ;
wire            HWRITE      ;
wire    [31:0]  HWDATA      ;
wire    [31:0]  HRDATA      ;
wire            HREADYMUX   ;
wire            HREADYOUT   ;


//core instance
cortexM3 mcu_inst(
    .CLK_IN             (CLK_IN     ),         
    .SWD_CLK            (SWD_CLK    ),        
    .SWD_IO             (SWD_IO     ),         
    .GPIO0              (LED2       ),
    .GPIO1              (LED3       ),
    .UART0_RX           (UART0_RX    ),
    .UART0_TX           (UART0_TX    ), 
    .CH0_M00_HSEL       (HSEL       ),
    .CH0_M00_HADDR      (HADDR      ),
    .CH0_M00_HTRANS     (HTRANS     ),
    .CH0_M00_HSIZE      (HSIZE      ),
    .CH0_M00_HBURST     (HBURST     ),
    .CH0_M00_HMASTLOCK  (HMASTLOCK  ),
    .CH0_M00_HPROT      (HPROT      ),
    .CH0_M00_HRESP      (HRESP      ),
    .CH0_M00_HWRITE     (HWRITE     ),
    .CH0_M00_HWDATA     (HWDATA     ),
    .CH0_M00_HRDATA     (HRDATA     ),
    .CH0_M00_HREADYMUX  (HREADYMUX  ),
    .CH0_M00_HREADYOUT  (HREADYOUT  ),           
    .RST_N              (RST_N      )       
);

//ahb_slave instance
cmsdk_ahb_eg_slave #(32) ahb_slave(
  .HCLK      (CLK_IN    ),// Clock
  .HRESETn   (RST_N     ),  // Reset
  .ECOREVNUM (4'b0      ), // Engineering-change-order revision bits
  
  // AHB connection to master
  .HSELS     (HSEL      ),
  .HADDRS    (HADDR     ),
  .HTRANSS   (HTRANS    ),
  .HSIZES    (HSIZE     ),
  .HWRITES   (HWRITE    ),
  .HREADYS   (HREADYMUX ),
  .HWDATAS   (HWDATA    ),
  .HREADYOUTS(HREADYOUT ),
  .HRESPS    (HRESP     ),
  .HRDATAS   (HRDATA    ),
  
  //ROM W/R Data
  .ROMCONTROL	(ROMCONTROL),
  .ROMWADDRESS	(ROMWADDRESS),
  .ROMWDATA	    (ROMWDATA),
  .regW_en      (regW_en),
  .ROMRADDRESS	(ROMRADDRESS),
  .ROMRDATA	    (ROMRDATA)
);

// ram instance
EBR_PDP U_EBR_PDP(
   .WrAddress   (ROMWADDRESS[9:0]),
   .RdAddress   (ROMRADDRESS[9:0]),
   .Data        (ROMWDATA),
   .WE          (regW_en),
   .RdClock     (CLK_IN),
   .RdClockEn   (1'b1), 
   .Reset       (1'b0),
   .WrClock     (CLK_IN),
   .WrClockEn   (1'b1),
   .Q           (ROMRDATA)
);

endmodule
