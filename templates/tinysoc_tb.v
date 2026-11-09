`timescale 1ns / 1ps
// Tiny_SoC 网表级最小仿真 TB(hqbuddy -tinysoc sim --tb 使用, 也可手跑)
// 要点:
//   - 例化 Tiny_SoC 网表顶层(实例名 dut), JTAG/UART 空闲态拉高
//   - 门级仿真必须例化 xsGSR/xsPWR(实例名固定, 原语模型按层次名引用)
//   - 内置 UART 帧解码: 位宽 TB_BITP 可用 vsim -gTB_BITP=<ns> 覆盖
//     缺省 2240ns = 50MHz 系统时钟 + DividerFactor=13 + 8 data bit
//     (波特率 = clk/((div+1)*(DL+1)), dl=7 表示 8 数据位)
module tb_tinysoc;
    parameter TB_BITP = 2240;  // ns, UART 位宽

    reg         io_sys_clk = 1'b0;
    reg         io_asyncReset = 1'b1;
    reg         io_jtag_tms = 1'b1;
    reg         io_jtag_tdi = 1'b0;
    reg         io_jtag_tck = 1'b0;
    reg         io_uart0_rxd = 1'b1;   // UART 空闲态
    wire        io_jtag_tdo;
    wire        io_uart0_txd;

    // 50 MHz 系统时钟(20ns); 换时钟频率请同步改 TB_BITP
    always #10 io_sys_clk = ~io_sys_clk;

    xsIP_Tiny_SoC dut (
        .io_sys_clk    (io_sys_clk),
        .io_asyncReset (io_asyncReset),
        .io_jtag_tms   (io_jtag_tms),
        .io_jtag_tdi   (io_jtag_tdi),
        .io_jtag_tdo   (io_jtag_tdo),
        .io_jtag_tck   (io_jtag_tck),
        .io_uart0_txd  (io_uart0_txd),
        .io_uart0_rxd  (io_uart0_rxd)
    );

    // 复位: 高电平有效, 保持 300ns(>16 拍)后释放
    initial begin
        #300 io_asyncReset = 1'b0;
    end

    // 门级仿真必需: 全局置位/上电原语
    xsGSR xsGSR_INST (.GSR(1'b1));
    xsPWR xsPWR_INST (.PUR(1'b1));

    // UART 帧解码: 起始位下降沿后按 TB_BITP 采样 8 个数据位
    reg [7:0] rx_byte;
    integer bi;
    always @(negedge io_uart0_txd) begin
        #(TB_BITP * 3 / 2);  // 跳到第 1 个数据位中心
        for (bi = 0; bi < 8; bi = bi + 1) begin
            rx_byte[bi] = io_uart0_txd;
            #(TB_BITP);
        end
        $display("[%0t] UART RX decoded: 0x%02h", $time, rx_byte);
    end

    initial begin
        $display("=== Tiny_SoC netlist sim start ===");
        #3_000_000;  // 3ms 超时兜底
        $display("=== sim end (timeout) ===");
        $finish;
    end
endmodule
