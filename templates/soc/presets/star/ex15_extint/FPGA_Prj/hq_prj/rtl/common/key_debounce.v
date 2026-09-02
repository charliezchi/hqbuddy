module key_debounce(
    input   clk,        // 系统时钟（50MHz）
    input   rst_n,      // 低电平复位信号
    input   key_in,     // 按键输入（0=按下，1=弹起）
    output  key_pulse   // 消抖后的按键脉冲（1个时钟周期高电平）
);

// 参数定义（50MHz时钟）
parameter DEBOUNCE_TIME = 20;     // 消抖时间20ms
parameter CLK_FREQ = 50_000_000;  // 50MHz系统时钟
localparam CNT_MAX = CLK_FREQ / 1000 * DEBOUNCE_TIME - 1;  // 20ms计数器最大值

reg [19:0] cnt;                  // 20ms计数器（足够计数1e6）
reg [1:0] sync_reg;              // 同步寄存器
reg [1:0] state, next_state;     // 状态机寄存器

// 状态编码
localparam IDLE     = 2'b00;     // 等待按键按下
localparam CHECK    = 2'b01;     // 检测抖动
localparam DOWN     = 2'b10;     // 确认按下状态
localparam RELEASE  = 2'b11;     // 等待释放

// 双级同步器消除亚稳态
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        sync_reg <= 2'b11;
    else 
        sync_reg <= {sync_reg[0], key_in};
end

// 按键状态转换（时序逻辑）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

// 状态机核心逻辑（组合逻辑）
always @(*) begin
    next_state = state;  // 默认保持状态
    case(state)
        IDLE: 
            if(~sync_reg[1]) next_state = CHECK;  // 检测到按键按下
            
        CHECK: 
            if(sync_reg[1])         // 中途检测到按键释放
                next_state = IDLE;
            else if(cnt == CNT_MAX) // 达到消抖时间
                next_state = DOWN;
        
        DOWN: 
            if(sync_reg[1])         // 等待释放
                next_state = RELEASE;
        
        RELEASE: 
            if(sync_reg[1] && cnt == CNT_MAX) // 释放完成
                next_state = IDLE;
            else if(~sync_reg[1])   // 重新按下
                next_state = DOWN;
    endcase
end

// 计数器控制逻辑
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= 0;
    else if(state != next_state)    // 状态变更时复位计数器
        cnt <= 0;
    else if(state == CHECK || state == RELEASE)
        cnt <= cnt + 1;             // 在需要消抖的状态计数
    else
        cnt <= 0;
end

// 输出按键脉冲
assign key_pulse = (state == DOWN && next_state == RELEASE) ? 1'b1 : 1'b0;

endmodule