module cmsdk_ahb_eg_slave #(
  // Parameter for address width
  parameter    ADDRWIDTH =12)
 (
  input  wire                  HCLK,       // 25MhzClock
  input  wire                  HRESETn,    // Reset

  input  wire  [3:0]           ECOREVNUM,  // Engineering-change-order revision bits

  // AHB connection to master
  input  wire                  HSELS,		//从机选择
  input  wire  [ADDRWIDTH-1:0] HADDRS,
  input  wire  [1:0]           HTRANSS,		//传输类型
  input  wire  [2:0]           HSIZES,
  input  wire                  HWRITES,//高写低读
  input  wire                  HREADYS,//输入的从机ready
  input  wire  [31:0]          HWDATAS,

  output wire                  HREADYOUTS,//输出的从机ready
  output wire                  HRESPS,//从机附加状态信息
  output wire  [31:0]          HRDATAS,
  
  output [3:0] led
  );

  // ----------------------------------------
  // Internal wires declarations

  // Register module interface signals
  wire  [ADDRWIDTH-1:0]  reg_addr;
  wire                   reg_read_en;
  wire                   reg_write_en;
  wire  [3:0]            reg_byte_strobe;
  wire  [31:0]           reg_wdata;
  wire  [31:0]           reg_rdata;
  
  
	//fifo
	wire		fifo_wren;
	wire		fifo_rden;
	wire [31:0] fifo_wrdata;
	wire [31:0] fifo_rddata;
	
	wire		fifo_empty;

  //-----------------------------------------------------------
  // Module logic start
  //----------------------------------------------------------

  // Interface block to convert AHB transfers to simple read/write
  // controls.
  cmsdk_ahb_eg_slave_interface
   #(.ADDRWIDTH (ADDRWIDTH))
    u_ahb_eg_slave_interface (
  .hclk         (HCLK),//25mhz
  .hresetn      (HRESETn),//复位信号

  // Input slave port: 32 bit data bus interface
  .hsels        (HSELS),	//片选
  .haddrs       (HADDRS),	//地址信号
  .htranss      (HTRANSS),	//传输类型（连续，非连续）
  .hsizes       (HSIZES),	//大小（字节，半字，字）
  .hwrites      (HWRITES),	//高写低读
  .hreadys      (HREADYS),	//M-ready
  .hwdatas      (HWDATAS),	//写数据信号

  .hreadyouts   (HREADYOUTS),//S-ready
  .hresps       (HRESPS),	 //从设备响应信息
  .hrdatas      (HRDATAS),	 //读数据信号

  .fifo_rden(fifo_rden),
  .fifo_wren(fifo_wren),
  .fifo_rddata(fifo_rddata),
  .fifo_wrdata(fifo_wrdata),
  
  .fifo_empty(fifo_empty),
  .led(led)
  );
  
 
  FIFO_32bit  FIFO_32bit_inst( 
							.Data(fifo_wrdata), 
							.WrClock(HCLK), 
							.RdClock(HCLK), 
							.WrEn(fifo_wren), 
							.RdEn(fifo_rden),  
							.Reset(!HRESETn), 
							.RPReset(), 

							.Q(fifo_rddata), 
							.Empty(fifo_empty), 
							.Full(), 
							.AlmostEmpty(), 
							.AlmostFull()
							);
endmodule

