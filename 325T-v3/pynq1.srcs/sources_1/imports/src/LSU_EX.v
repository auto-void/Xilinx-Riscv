`include "defines.vh"

`timescale 1ns / 1ps

module LSU_EX (
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

    // from branch
    input jump_flag_i,                 // 跳转标志
    input [1:0] kill_mask_id_i,        // 分支掩码id

    // from commit
    input free_mask_inst0_i,                   // 指令0释放掩码标志
    input [1:0] free_id_inst0_i,               // 指令0释放id
    input free_mask_inst1_i,                   // 指令1释放掩码标志
    input [1:0] free_id_inst1_i,               // 指令1释放id

    // to mem
    output inst_valid_o,               // 指令有效标志
    output [5:0] rob_id_o,             // ROB id
    output reg [3:0] mask_o,           // 分支掩码
    output [1:0] sq_id_o,              // SQ id
    output [3:0] subtype_o,            // 指令子类型
    output [31:0] rs2_data_o,          // rs2数据
    output [5:0] pwaddr_o,             // 物理寄存器写地址
    output [31:0] mem_addr_o           // 访存地址
);

wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
assign inst_valid_o = inst_valid_i && ((mask_i & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效
assign rob_id_o = rob_id_i;
assign sq_id_o = sq_id_i;
assign subtype_o = subtype_i;
assign rs2_data_o = rs2_data_i;
assign pwaddr_o = pwaddr_i;
assign mem_addr_o = rs1_data_i + imm_i;

always @(*) begin
    mask_o = mask_i;
    if (free_mask_inst0_i) begin
        mask_o[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        mask_o[free_id_inst1_i] = 1'b0;
    end
end


endmodule