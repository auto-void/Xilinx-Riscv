`include "defines.vh"

`timescale 1ns / 1ps

module lsu_rf_ex (
    input clk,
    input rst,

    // from rf
    input inst_valid_i,               // 指令有效标志
    input [5:0] rob_id_i,             // ROB id
    input [3:0] mask_i,               // 分支掩码
    input [1:0] sq_id_i,              // SQ id
    input [3:0] subtype_i,            // 指令子类型
    input [31:0] rs1_data_i,          // rs1数据
    input [31:0] rs2_data_i,          // rs2数据
    input [5:0] pwaddr_i,             // 物理寄存器写地址
    input [31:0] imm_i,               // 立即数

    // from clint
    input int_flag_i,                   // 中断标志

    // from mem
    input flush_i,                      // 冲刷标志
    input stall_i,

    // from commit
    input free_mask_inst0_i,                   // 指令0释放掩码标志
    input [1:0] free_id_inst0_i,               // 指令0释放id
    input free_mask_inst1_i,                   // 指令1释放掩码标志
    input [1:0] free_id_inst1_i,               // 指令1释放id

    // from branch
    input jump_flag_i,                 // 跳转标志
    input [1:0] kill_mask_id_i,        // 分支掩码id

    // to ex
    output reg inst_valid_o,               // 指令有效标志
    output reg [5:0] rob_id_o,             // ROB id
    output reg [3:0] mask_o,               // 分支掩码
    output reg [1:0] sq_id_o,              // SQ id
    output reg [3:0] subtype_o,            // 指令子类型
    output reg [31:0] rs1_data_o,          // rs1数据
    output reg [31:0] rs2_data_o,          // rs2数据
    output reg [5:0] pwaddr_o,             // 物理寄存器写地址
    output reg [31:0] imm_o                // 立即数
);

reg [3:0] next_mask;
always @(*) begin
    next_mask = mask_o;
    if (free_mask_inst0_i) begin
        next_mask[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        next_mask[free_id_inst1_i] = 1'b0;
    end
end

wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
wire next_valid = inst_valid_o && ((mask_o & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效

always @(posedge clk) begin
    if (!rst) begin
        inst_valid_o <= 1'b0;
        pwaddr_o <= 6'b0;
    end
    else if (int_flag_i) begin
        inst_valid_o <= 1'b0;
        pwaddr_o <= 6'b0;
    end
    else if (flush_i) begin
        inst_valid_o <= 1'b0;
        pwaddr_o <= 6'b0;
    end
    else if (stall_i) begin
        inst_valid_o <= next_valid;
        pwaddr_o     <= next_valid ? pwaddr_o : 6'd0;
    end
    else begin
        inst_valid_o <= inst_valid_i;
        pwaddr_o <= pwaddr_i;
    end
end

always @(posedge clk) begin
    if (!stall_i) begin
        mask_o <= mask_i;
    end
    else begin
        mask_o <= next_mask;
    end
end

always @(posedge clk) begin
    if (!stall_i) begin
        rob_id_o <= rob_id_i;
        sq_id_o <= sq_id_i;
        subtype_o <= subtype_i;
        rs1_data_o <= rs1_data_i;
        rs2_data_o <= rs2_data_i;
        imm_o <= imm_i;
    end
end





endmodule