`include "defines.vh"

`timescale 1ns / 1ps

module br_ex_flush (
    input clk,
    input rst,

    // from br_ex
    input br_inst_valid_i,              // branch指令有效标志
    input [5:0] commit_rob_id_i,        // 提交ROB id
    input jump_flag_i,                   // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id
    input [2:0] ras_snap_ptr_i,         // RAS快照指针
    input [2:0] br_mem_wr_ptr_i,        // branch mem队列写操作快照指针
    input [2:0] br_sq_ptr_i,            // branch store queue快照指针
    input [31:0] jump_addr_i,           // 跳转地址

    // from clint
    input int_flag_i,                   // 中断标志

    // to br_flush
    output reg br_inst_valid_o,              // branch指令有效标志
    output reg [5:0] commit_rob_id_o,        // 提交ROB id
    output reg jump_flag_o,                  // 跳转标志
    output reg [1:0] kill_mask_id_o,         // 分支掩码id
    output reg [2:0] ras_snap_ptr_o,         // RAS快照指针
    output reg [2:0] br_mem_wr_ptr_o,        // branch mem队列写操作快照指针
    output reg [2:0] br_sq_ptr_o,            // branch store queue快照指针
    output reg [31:0] jump_addr_o            // 跳转地址
);

always @(posedge clk) begin
    if (!rst) begin
        br_inst_valid_o <= 1'b0;
        jump_flag_o <= 1'b0;
    end
    else if (int_flag_i) begin
        br_inst_valid_o <= 1'b0;
        jump_flag_o <= 1'b0;
    end
    else begin
        br_inst_valid_o <= br_inst_valid_i;
        jump_flag_o <= jump_flag_i;
    end
end

always @(posedge clk) begin
    commit_rob_id_o <= commit_rob_id_i;
    kill_mask_id_o <= kill_mask_id_i;
    ras_snap_ptr_o <= ras_snap_ptr_i;
    br_mem_wr_ptr_o <= br_mem_wr_ptr_i;
    br_sq_ptr_o <= br_sq_ptr_i;
    jump_addr_o <= jump_addr_i;
end



endmodule