`include "defines.vh"

`timescale 1ns / 1ps

module ALU_EX (
    // from RF
    input inst_valid_i,                 // ALU指令有效标志
    input [5:0] rob_id_i,               // ALU ROB id
    input [3:0] mask_i,                 // ALU分支掩码
    input [3:0] subtype_i,              // ALU指令子类型
    input [1:0] op1_src_i,              // ALU操作数1
    input [1:0] op2_src_i,              // ALU操作数2
    input [31:0] reg_rdata1_i,          // 寄存器1读数据
    input [31:0] reg_rdata2_i,          // 寄存器2读数据
    input [5:0] pwaddr_i,               // ALU物理寄存器写地址
    input [31:0] imm_i,                 // ALU立即数

    // from branch
    input jump_flag_i,                  // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id

    // to wb
    output inst_valid_o,                 // ALU指令有效标志
    output [5:0] rob_id_o,               // ALU ROB id
    output [5:0] pwaddr_o,               // 物理寄存器写地址(同时传到forward_unit和issue阶段)
    output reg [31:0] reg_wdata_o        // 写寄存器数据(同时传到forward_unit)

);

// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
assign inst_valid_o = inst_valid_i && ((mask_i & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效
// 执行
assign rob_id_o = rob_id_i;
assign pwaddr_o = pwaddr_i;
wire [31:0] op1 = (op1_src_i == `OP1_REG) ? reg_rdata1_i : imm_i;
wire [31:0] op2 = (op2_src_i == `OP2_REG) ? reg_rdata2_i : imm_i;
always @(*) begin
    reg_wdata_o = 32'b0;

    case (subtype_i)
        `ALU_ADD:   reg_wdata_o = op1 + op2;
        `ALU_SUB:   reg_wdata_o = op1 - op2;
        `ALU_AND:   reg_wdata_o = op1 & op2;
        `ALU_OR:    reg_wdata_o = op1 | op2;
        `ALU_XOR:   reg_wdata_o = op1 ^ op2;
        `ALU_SLL:   reg_wdata_o = op1 << op2[4:0];
        `ALU_SRL:   reg_wdata_o = op1 >> op2[4:0];
        `ALU_SRA:   reg_wdata_o = $signed(op1) >>> op2[4:0];
        `ALU_SLT:   reg_wdata_o = ($signed(op1) < $signed(op2)) ? 32'b1 : 32'b0;
        `ALU_SLTU:  reg_wdata_o = (op1 < op2) ? 32'b1 : 32'b0;
        `ALU_LUI:   reg_wdata_o = imm_i;
        `ALU_AUIPC: reg_wdata_o = imm_i; // id阶段已经把 PC 加到立即数上了
        default:    reg_wdata_o = 32'b0;
    endcase
end




endmodule