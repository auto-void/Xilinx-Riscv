`include "defines.vh"

`timescale 1ns / 1ps

// 取指和译码之间插入一级寄存器
module if_id(
    input clk,
    input rst,

    // from if_stage2
    input [2:0] ras_snap_ptr_i,

    input inst_valid_port0_i,     // 指令有效标志
    input inst_valid_port1_i,

    input [31:0] inst_port0_i,    // 指令内容
    input [31:0] inst_port1_i,

    input [31:0] inst_addr_i,

    input [31:0] imm_port0_i,
    input [31:0] imm_port1_i,

    input bpu_pre_flag_port0_i,
    input bpu_pre_flag_port1_i,

    input [31:0] bpu_pre_addr_port0_i,
    input [31:0] bpu_pre_addr_port1_i,

    // from id
    input jal_flush_i,                 // jal指令冲刷

    // from Ctrl
    input jump_flag_i,                 // 执行确认阶段跳转标志
    input stall_flag_i,                // RS/ROB满暂停

    // from clint
    input int_flag_i,

    // to id
    output reg [2:0] ras_snap_ptr_o,

    output reg inst_valid_port0_o,     // 指令有效标志
    output reg inst_valid_port1_o,

    output reg [31:0] inst_port0_o,    // 指令内容
    output reg [31:0] inst_port1_o,

    output reg [31:0] inst_addr_o,

    output reg [31:0] imm_port0_o,
    output reg [31:0] imm_port1_o,

    output reg bpu_pre_flag_port0_o,
    output reg bpu_pre_flag_port1_o,

    output reg [31:0] bpu_pre_addr_port0_o,
    output reg [31:0] bpu_pre_addr_port1_o

);

always @(posedge clk) begin
    if(!rst) begin
        inst_valid_port0_o <= 1'b0;
        inst_valid_port1_o <= 1'b0;
    end
    else if(int_flag_i || jump_flag_i) begin
        inst_valid_port0_o <= 1'b0;
        inst_valid_port1_o <= 1'b0;
    end
    else if(stall_flag_i) begin
        inst_valid_port0_o <= inst_valid_port0_o;
        inst_valid_port1_o <= inst_valid_port1_o;
    end
    else if(jal_flush_i) begin
        inst_valid_port0_o <= 1'b0;
        inst_valid_port1_o <= 1'b0;
    end
    else begin
        inst_valid_port0_o <= inst_valid_port0_i;
        inst_valid_port1_o <= inst_valid_port1_i;
    end
end

always @(posedge clk) begin
    if (!stall_flag_i) begin
        ras_snap_ptr_o <= ras_snap_ptr_i;
        inst_port0_o <= inst_port0_i;           
        inst_port1_o <= inst_port1_i;           
        inst_addr_o <= inst_addr_i;   
        imm_port0_o <= imm_port0_i;
        imm_port1_o <= imm_port1_i;
        bpu_pre_flag_port0_o <= bpu_pre_flag_port0_i;
        bpu_pre_flag_port1_o <= bpu_pre_flag_port1_i;
        bpu_pre_addr_port0_o <= bpu_pre_addr_port0_i;
        bpu_pre_addr_port1_o <= bpu_pre_addr_port1_i;
    end
end

endmodule