`include "defines.vh"

`timescale 1ns / 1ps

module if_stage1_stage2 (
    input clk,
    input rst,

    // from IF_Stage1
    input [63:0] inst_i,
    input [31:0] inst_addr_i,
    input bpu_pre_flag_i,
    input bpu_jump_odd_i,
    input [31:0] bpu_pre_addr_i,

    // from ctrl
    input int_flag_i,         // 中断
    input hold_flag_i,        // icache miss暂停
    input jump_flag_i,        // 执行确认阶段冲刷
    input stall_flag_i,       // RS/ROB满暂停
    input jal_flush_i,        // jal指令冲刷
    input ras_pre_flag_i,     // RAS分支预测

    // to IF_Stage2
    output reg inst_valid_o,
    output reg [63:0] inst_o,
    output reg [31:0] inst_addr_o,
    output reg bpu_pre_flag_o,
    output reg bpu_jump_odd_o,
    output reg [31:0] bpu_pre_addr_o
);

always @(posedge clk) begin
    if (!rst) begin
        inst_valid_o <= 1'b0;
    end
    else if (int_flag_i || jump_flag_i) begin
        inst_valid_o <= 1'b0;
    end
    else if (stall_flag_i) begin
        inst_valid_o <= inst_valid_o;
    end
    else if (jal_flush_i) begin
        inst_valid_o <= 1'b0;
    end
    else if (ras_pre_flag_i) begin
        inst_valid_o <= 1'b0;
    end
    else if (hold_flag_i) begin
        inst_valid_o <= 1'b0;
    end
    else begin
        inst_valid_o <= 1'b1;
    end
end

always @(posedge clk) begin
    if (!stall_flag_i) begin
        inst_o <= inst_i;
        inst_addr_o <= inst_addr_i;
        bpu_pre_flag_o <= bpu_pre_flag_i;
        bpu_jump_odd_o <= bpu_jump_odd_i;
        bpu_pre_addr_o <= bpu_pre_addr_i;
    end
end

endmodule