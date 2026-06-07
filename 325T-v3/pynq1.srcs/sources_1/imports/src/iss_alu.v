`include "defines.vh"

`timescale 1ns / 1ps

module iss_alu (
    input clk,
    input rst,

    // from issue
    input int_flag_i,                     // 中断标志
    input issue_flag_i,                   // 发射标志
    input [5:0] alu_rob_id_i,             // ROB id
    input [3:0] alu_mask_i,               // 分支掩码
    input [3:0] alu_subtype_i,            // 指令子类型
    input [1:0] alu_op1_src_i,            // 操作数1来源选择
    input [1:0] alu_op2_src_i,            // 操作数2来源选择
    input [5:0] alu_praddr1_i,            // 物理寄存器1读地址
    input [5:0] alu_praddr2_i,            // 物理寄存器2读地址
    input [5:0] alu_pwaddr_i,             // 物理寄存器写地址
    input [31:0] alu_imm_i,               // 立即数

    // to ex
    output reg alu_inst_valid_o,          // 指令有效标志
    output reg [5:0] alu_rob_id_o,        // ROB id
    output reg [3:0] alu_mask_o,          // 分支掩码
    output reg [3:0] alu_subtype_o,       // 指令子类型
    output reg [1:0] alu_op1_src_o,       // 操作数1
    output reg [1:0] alu_op2_src_o,       // 操作数2
    output reg [5:0] alu_praddr1_o,       // 物理寄存器1读地址
    output reg [5:0] alu_praddr2_o,       // 物理寄存器2读地址
    output reg [5:0] alu_pwaddr_o,        // 物理寄存器写地址
    output reg [31:0] alu_imm_o           // 立即数

);

always @(posedge clk) begin
    if (!rst) begin
        alu_inst_valid_o <= 1'b0;
        alu_pwaddr_o <= 6'b0;
    end
    else if (int_flag_i) begin
        alu_inst_valid_o <= 1'b0; // 中断发生时清空流水线
        alu_pwaddr_o <= 6'b0;
    end
    else if (issue_flag_i) begin
        alu_inst_valid_o <= 1'b1;
        alu_pwaddr_o <= alu_pwaddr_i;
    end
    else begin
        alu_inst_valid_o <= 1'b0; // 非发射周期指令无效
        alu_pwaddr_o <= 6'b0;
    end
end

always @(posedge clk) begin
    alu_rob_id_o <= alu_rob_id_i;
    alu_mask_o <= alu_mask_i;
    alu_subtype_o <= alu_subtype_i;
    alu_op1_src_o <= alu_op1_src_i;
    alu_op2_src_o <= alu_op2_src_i;
    alu_praddr1_o <= alu_praddr1_i;
    alu_praddr2_o <= alu_praddr2_i;
    alu_imm_o <= alu_imm_i;
end

endmodule