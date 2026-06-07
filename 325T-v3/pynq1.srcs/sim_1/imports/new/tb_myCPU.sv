`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2025 03:50:55 PM
// Design Name: 
// Module Name: tb_myCPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_myCPU;
    reg clk;

    // 补齐信号定义
    logic w_clk_50Mhz;
    logic cpu_clk;

    logic rst;            // 来自 PLL 的 locked
    logic w_clk_rst;      // 连接到 UART 的 rst_n

    logic top_uart_rx;
    logic top_uart_tx;

    logic [7:0] rx_data;
    logic       rx_ready;
    // 将 VIO 的 tx_data 单独命名，增加一个发送复用总线
    logic [7:0] vio_tx_data;
    logic [7:0] tx_data_mux;
    logic       tx_start;
    logic       tx_busy;

    // 原 tx_start 改为：VIO 输出（电平）+ UART 输入（脉冲）+ 打拍寄存器
    logic       tx_start_raw;    // VIO 输出电平
    logic       tx_start_pulse;  // 上升沿/切换脉冲 -> UART
    logic       tx_start_d;      // 打拍用于沿检测

    // 上升沿检测：raw 从 0->1 时产生单拍脉冲
    always_ff @(posedge cpu_clk or negedge rst) begin
        if (!rst) begin
            tx_start_d <= 1'b0;
        end else begin
            tx_start_d <= tx_start_raw;
        end
    end
    assign tx_start_pulse = tx_start_raw ^ tx_start_d;

    // ===== 自动发送 list_sem 逻辑 =====
    // 触发信号（通过 VIO 切换）
    logic auto_trig_raw = 1'b0;
    logic auto_trig_d = 1'b0;
    logic auto_active;           // 自动发送进行中
    logic       tx_start_auto;   // 自动发送产生的单拍启动脉冲
    logic [3:0] auto_idx;        // 发送到第几个字节
    logic [7:0] auto_tx_data;    // 当前要发送的字节

    // 接收握手：检测到新的接收字节（rx_ready 上升沿）
    logic rx_ready_d;
    logic rx_ready_edge;
    always_ff @(posedge cpu_clk or negedge rst) begin
        if (!rst) begin
            rx_ready_d <= 1'b0;
        end else begin
            rx_ready_d <= rx_ready;
        end
    end
    assign rx_ready_edge = rx_ready & ~rx_ready_d;

    // 要发送的字符串： "coremark\n"
    localparam int AUTO_LEN = 9;
    localparam logic [7:0] LIST_SEM [0:AUTO_LEN-1] = '{
        8'h63, // c
        8'h6F, // o
        8'h72, // r
        8'h65, // e
        8'h6D, // m
        8'h61, // a
        8'h72, // r
        8'h6B, // k
        8'h0A  // 结束符(换行)
    };

    // 自动发送状态机：检测 auto_trig_raw 的“任意翻转”触发一次发送
    always_ff @(posedge cpu_clk or negedge rst) begin
        if (!rst) begin
            auto_trig_d   <= 1'b0;
            auto_active   <= 1'b0;
            auto_idx      <= '0;
            auto_tx_data  <= 8'h00;
            tx_start_auto <= 1'b0;
        end else begin
            auto_trig_d <= auto_trig_raw;

            // 默认不发启动脉冲（单拍）
            tx_start_auto <= 1'b0;

            // 触发：检测翻转（上升/下降沿都触发一次）
            if ((auto_trig_raw ^ auto_trig_d) && !auto_active) begin
                auto_active <= 1'b1;
                auto_idx    <= 0;
            end

            if (auto_active) begin
                // 握手策略：
                // - 首字节：触发后立即发送（auto_idx==0）
                // - 后续字节：等收到一个新的字节 rx_ready_edge 后再发送下一字节
                if (!tx_busy && !tx_start_auto &&
                    ((auto_idx == 0) || rx_ready_edge)) begin
                    auto_tx_data  <= LIST_SEM[auto_idx];
                    tx_start_auto <= 1'b1;   // 单周期脉冲
                    auto_idx      <= auto_idx + 1'b1;
                end
                // 全部字节已触发发送，等待最后一个字节发送完毕后退出
                if (auto_idx == AUTO_LEN && !tx_busy) begin
                    auto_active <= 1'b0;
                end
            end
        end
    end

    // 发送数据复用：自动发送期间使用 auto_tx_data，否则使用 VIO 的 vio_tx_data
    assign tx_data_mux = auto_active ? auto_tx_data : vio_tx_data;

    // ===== virtual_seg 解码为 BCD =====
    wire [39:0] w_virtual_seg;

    // 7段码到BCD解码（共阴极，1=亮，与seg7.sv一致）
    function [3:0] seg7_to_bcd;
        input [6:0] seg;
        case(seg)
            7'b011_1111: seg7_to_bcd = 4'h0; // 0x3F
            7'b000_0110: seg7_to_bcd = 4'h1; // 0x06
            7'b101_1011: seg7_to_bcd = 4'h2; // 0x5B
            7'h4f:       seg7_to_bcd = 4'h3; // 0x4F
            7'h66:       seg7_to_bcd = 4'h4; // 0x66
            7'h6d:       seg7_to_bcd = 4'h5; // 0x6D
            7'h7d:       seg7_to_bcd = 4'h6; // 0x7D
            7'h07:       seg7_to_bcd = 4'h7; // 0x07
            7'h7f:       seg7_to_bcd = 4'h8; // 0x7F
            7'h6f:       seg7_to_bcd = 4'h9; // 0x6F
            7'h77:       seg7_to_bcd = 4'hA; // 0x77
            7'h7c:       seg7_to_bcd = 4'hB; // 0x7C
            7'h39:       seg7_to_bcd = 4'hC; // 0x39
            7'h5e:       seg7_to_bcd = 4'hD; // 0x5E
            7'h79:       seg7_to_bcd = 4'hE; // 0x79
            7'h71:       seg7_to_bcd = 4'hF; // 0x71
            default:     seg7_to_bcd = 4'hX;
        endcase
    endfunction

    // 提取各段和ans
    // display_seg 映射: seg4->s[31:28]/s[27:24], seg3->s[23:20]/s[19:16],
    //                   seg2->s[15:12]/s[11:8],   seg1->s[7:4]/s[3:0]
    // 高半字节(ans=10101010): digit1=seg1=s[7:4], digit4=seg4=s[31:28]
    // 低半字节(ans=01010101): digit1=seg1=s[3:0], digit4=seg4=s[27:24]
    logic [6:0] seg1, seg2, seg3, seg4;
    logic [7:0] ans;
    assign seg1 = w_virtual_seg[6:0];
    assign seg2 = w_virtual_seg[16:10];
    assign seg3 = w_virtual_seg[26:20];
    assign seg4 = w_virtual_seg[36:30];
    assign ans  = {w_virtual_seg[39:38], w_virtual_seg[29:28],
                   w_virtual_seg[19:18], w_virtual_seg[9:8]};

    // 锁存8个BCD数字，按正确的s[31:0]位序排列
    // seg4是最高位，seg1是最低位
    // 高半字节锁存: s[31:28]=seg4, s[23:20]=seg3, s[15:12]=seg2, s[7:4]=seg1
    // 低半字节锁存: s[27:24]=seg4, s[19:16]=seg3, s[11:8]=seg2,  s[3:0]=seg1
    logic [3:0] bcd8 [0:7];
    always_ff @(posedge cpu_clk or negedge rst) begin
        if (!rst) begin
            bcd8[0] <= 4'h0; bcd8[1] <= 4'h0; bcd8[2] <= 4'h0; bcd8[3] <= 4'h0;
            bcd8[4] <= 4'h0; bcd8[5] <= 4'h0; bcd8[6] <= 4'h0; bcd8[7] <= 4'h0;
        end else if (ans == 8'b10101010) begin
            // 高半字节: seg4=s[31:28], seg3=s[23:20], seg2=s[15:12], seg1=s[7:4]
            bcd8[7] <= seg7_to_bcd(seg4); // s[31:28]
            bcd8[5] <= seg7_to_bcd(seg3); // s[23:20]
            bcd8[3] <= seg7_to_bcd(seg2); // s[15:12]
            bcd8[1] <= seg7_to_bcd(seg1); // s[7:4]
        end else if (ans == 8'b01010101) begin
            // 低半字节: seg4=s[27:24], seg3=s[19:16], seg2=s[11:8], seg1=s[3:0]
            bcd8[6] <= seg7_to_bcd(seg4); // s[27:24]
            bcd8[4] <= seg7_to_bcd(seg3); // s[19:16]
            bcd8[2] <= seg7_to_bcd(seg2); // s[11:8]
            bcd8[0] <= seg7_to_bcd(seg1); // s[3:0]
        end
    end

    // 合并为32位BCD总线 [31:0] = {bcd8[7], bcd8[6], ..., bcd8[0]}
    wire [31:0] w_bcd_data = {bcd8[7], bcd8[6], bcd8[5], bcd8[4],
                              bcd8[3], bcd8[2], bcd8[1], bcd8[0]};

    top uut (
        .i_sys_clk_p(clk),
        .i_sys_clk_n(~clk),
        // .sw({1'b0, rst}),
        .i_uart_rx(top_uart_rx),
        .o_uart_tx(top_uart_tx),
        .virtual_led(),
        .virtual_seg(w_virtual_seg)
    );

    pll pll_inst(
        // .clk_in1(clk),
        // .clk_out1(w_clk_50Mhz),
        .clk_in1_p(clk),
        .clk_in1_n(~clk),
        .clk_out1(cpu_clk),
        .locked(rst)
    );

    uart0 uart_inst(
        .clk(cpu_clk),
        .rst_n(rst),
        .rx(top_uart_tx),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .tx(top_uart_rx),
        .tx_data(tx_data_mux),
        .tx_start(tx_start_pulse | tx_start | tx_start_auto), // 增加自动发送脉冲
        .tx_busy(tx_busy)
    );

    // vio_0 vio_inst(
    //     .clk(cpu_clk),
    //     .probe_in0(rx_data),
    //     .probe_out0(tx_start_raw), // VIO 驱动原始 tx_start 电平
    //     .probe_out1(tx_start),
    //     .probe_out2(vio_tx_data)
    // );

    //  clock 50MHz=2.5 20ns
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end
endmodule
