module cmsdk_ahb_eg_slave_interface
#(parameter   ADDRWIDTH=12)
 (
  input  wire                  hclk,       // 25mhz clock
  input  wire                  hresetn,    // reset

  // AHB connection to master
  input  wire                  hsels,
  input  wire [ADDRWIDTH-1:0]  haddrs,
  input  wire [1:0]            htranss,
  input  wire [2:0]            hsizes,
  input  wire                  hwrites,
  input  wire                  hreadys,
  input  wire [31:0]           hwdatas,

  output wire                  hreadyouts,
  //output reg                 	hreadyouts,
  output wire                  hresps,
  output reg [31:0]            hrdatas,
  
  //fifo
  
  output reg		fifo_rden,
  input	 	 [31:0]	fifo_rddata,
  input 			fifo_full,
  output reg 		fifo_wren,
  input				fifo_empty,
  output reg [31:0] fifo_wrdata,
  output reg [3:0]  led
  
  );
	
	reg [9:0] ready_cnt;
	
   wire                   trans_req= hreadys & hsels & htranss[1];

   wire                   ahb_read_req  = trans_req & (~hwrites);
   wire                   ahb_write_req = trans_req &  hwrites;  
  
   wire                   update_read_req;   
   wire                   update_write_req;
	
   reg  [ADDRWIDTH-1:0]   addr_reg;    
   reg                    read_en_reg; 
   reg                    write_en_reg;

   reg  [3:0]             byte_strobe_reg;
   reg  [3:0]             byte_strobe_nxt;

  //-----------------------------------------------------------
  // Module logic start
  //----------------------------------------------------------
  always @(posedge hclk or negedge hresetn)
  begin
    if (~hresetn)
      addr_reg <= {(ADDRWIDTH){1'b0}};
    else if (trans_req)
      addr_reg <= haddrs[ADDRWIDTH-1:0];
  end
  
 //---------------write----------------------------------------------------------------- 
	assign update_write_req = ahb_write_req |( write_en_reg & hreadys);

	always @(posedge hclk or negedge hresetn)
	begin
	  if (~hresetn)
		begin
		  write_en_reg <= 1'b0;
		end
	  else if (update_write_req)
		begin
		  write_en_reg  <= ahb_write_req;
		end
	end  

 //---------------read----------------------------------------------------------------- 
  assign update_read_req = ahb_read_req | (read_en_reg & hreadys); 

  always @(posedge hclk or negedge hresetn)
  begin
    if (~hresetn)
      begin
        read_en_reg <= 1'b0;
      end
    else if (update_read_req)
      begin
        read_en_reg  <= ahb_read_req;
      end
  end
//----------------fifo-----------------------------------------------------------------

always @(posedge hclk or negedge hresetn)
  begin
    if (~hresetn)
      begin
		fifo_wrdata<=32'b0;
		fifo_wren<=1'b0;
	  end
	else
		begin
			if(write_en_reg==1)
			begin
				fifo_wren<=1'b1;
				fifo_wrdata<=hwdatas;
			end
			else
				begin
					fifo_wrdata<=32'b0;
					fifo_wren<=1'b0;
				end
		end
  end
  
	always@(*)
	begin
		if((read_en_reg==1)&&(addr_reg!=0))
			hrdatas<=fifo_rddata;
		else
			hrdatas<=32'd0;
	end
	
	always@(*)
	begin
		if(ahb_read_req)
			fifo_rden<=1'b1;
		else
			fifo_rden<=1'b0;
	end
//----------------led-----------------------------------------------------------------  
  always @(posedge hclk or negedge hresetn)
  begin
    if (~hresetn)
		led<=4'b1111;
	else
		begin
			if(fifo_empty==1)
				led<=4'b1110;
			else if(fifo_empty==0)
				led<=4'b1100;
			else
				led<=led;
		end
  end
  
  // always@(posedge hclk or negedge hresetn)
  // begin
	// if (~hresetn)begin
		// hreadyouts  <= 1'b0; 
		// ready_cnt  <=10'b0;  end
	// else
		// begin
			// if(ready_cnt<10)begin
				// hreadyouts  <= 1'b0;
				// ready_cnt  <=ready_cnt +1'b1;
				// end
			// else
				// begin
				// hreadyouts  <= 1'b1;
				// ready_cnt  <=ready_cnt;
				// end
		// end
  // end
  assign hreadyouts  = 1'b1;  
  assign hresps      = 1'b0;  // OKAY response from slave

endmodule

