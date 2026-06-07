`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2025 06:21:13 PM
// Design Name: 
// Module Name: student_top
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
`include "defines.vh"

module student_top#(
    parameter                           P_SW_CNT            = 64,
    parameter                           P_LED_CNT           = 32,
    parameter                           P_SEG_CNT           = 40,
    parameter                           P_KEY_CNT           = 8
) (
    input                                       w_cpu_clk     ,
    input                                       w_clk_50Mhz   ,
    input                                       w_clk_rst     ,
    input  [P_KEY_CNT - 1:0]                    virtual_key   ,
    input  [P_SW_CNT  - 1:0]                    virtual_sw    ,

    output [P_LED_CNT - 1:0]                    virtual_led   ,
    output [P_SEG_CNT - 1:0]                    virtual_seg   ,

    input                                       rx            ,
    output                                      tx
);

    // IROM
    logic [31:0]  pc;
    logic [12:0]  inst_addr;
    logic [10:0]  cache_addr;
    logic [63:0]  instruction;
    logic [255:0] cache_line;

    // perip
    logic [31:0] perip_waddr, perip_addr, perip_wdata, perip_rdata, branch_hit_cnt, branch_miss_cnt;
    logic [127:0] dcache_line;
    logic perip_wen, timer_int_flag, uart_int_flag;
    logic [1:0] perip_mask;

    // 64KB = 2^14 * 32bit
    assign inst_addr = pc[15:3];
    assign cache_addr = pc[15:5];

    my_Riscv u_cpu(
        .clk(w_cpu_clk),
        .rst_p(w_clk_rst),

        // Interface to IROM
        .irom_addr          (pc),             
        // .irom_data          (instruction), 
        .cache_line         (cache_line),

        // Interface to DRAM & peripheral
        .perip_waddr        (perip_waddr),
        .perip_addr         (perip_addr),     
        .perip_wen          (perip_wen),     
        .perip_mask         (perip_mask),   
        .perip_wdata        (perip_wdata),
        .dcache_line        (dcache_line),
        .perip_rdata        (perip_rdata),
        .timer_int_flag     (timer_int_flag),
        .uart_int_flag      (uart_int_flag)

        `ifdef DEBUG
        ,.ex_branch_hit_cnt(branch_hit_cnt),
        .ex_branch_miss_cnt(branch_miss_cnt)
        `endif
    );

    // IROM Mem_IROM (
    //     .a          (inst_addr),
    //     .spo        (instruction)
    // );

    BRAM_IROM u_irom(
        // 64bit
        // .addrb(inst_addr),
        // .clkb(w_cpu_clk),
        // .doutb(instruction),
        // 128bit
        .addra(cache_addr),
        .clka(w_cpu_clk),
        .douta(cache_line)
    );
    
    perip_bridge bridge_inst (
        .clk				(w_cpu_clk),
        .cnt_clk            (w_clk_50Mhz),
        .rst                (w_clk_rst),
        .perip_waddr		(perip_waddr),
        .perip_addr			(perip_addr),
        .perip_wdata		(perip_wdata),
        .perip_wen			(perip_wen),
        .perip_mask			(perip_mask),
        .perip_rdata		(perip_rdata),
        .dcache_line        (dcache_line),
        .timer_int_flag     (timer_int_flag),
        .uart_int_flag      (uart_int_flag),
        .virtual_sw_input	(virtual_sw),
        .virtual_key_input	(virtual_key),	
        .virtual_seg_output	(virtual_seg),
        .virtual_led_output (virtual_led),
        .rx                 (rx),
        .tx                 (tx)

        `ifdef DEBUG
        ,.branch_hit_cnt(branch_hit_cnt),
        .branch_miss_cnt(branch_miss_cnt)
        `endif
    );

endmodule
