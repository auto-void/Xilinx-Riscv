`include "defines.vh"

`timescale 1ns / 1ps

module MUL_RF (
    // from issue
    input inst_valid_i,               // 指令有效标志
    input [5:0] rob_id_i,             // ROB id
    input [3:0] mask_i,               // 分支掩码
    input [3:0] subtype_i,            // 指令子类型
    input [5:0] praddr1_i,            // 物理寄存器1读地址
    input [5:0] praddr2_i,            // 物理寄存器2读地址
    input [5:0] pwaddr_i,             // 物理寄存器写地址

    // from forward_unit
    input rs1_forward_flag_i,           // rs1转发标志
    input [31:0] rs1_forward_data_i,    // rs1转发数据
    input rs2_forward_flag_i,           // rs2转发标志
    input [31:0] rs2_forward_data_i,    // rs2转发数据

    // from branch
    input jump_flag_i,                  // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id

    // from regs
    input [31:0] reg_rdata1_i,          // 寄存器1读数据
    input [31:0] reg_rdata2_i,          // 寄存器2读数据

    // to regs
    output [5:0] praddr1_o,            // 物理寄存器1读地址
    output [5:0] praddr2_o,            // 物理寄存器2读地址

    // to ex
    output inst_valid_o,               // 指令有效标志
    output [5:0] rob_id_o,             // ROB id
    output [3:0] subtype_o,            // 指令子类型
    output [31:0] rs1_data_o,          // rs1数据
    output [31:0] rs2_data_o,          // rs2数据
    output [5:0] pwaddr_o              // 物理寄存器写地址
);
// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
assign inst_valid_o = inst_valid_i && ((mask_i & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效

assign rob_id_o = rob_id_i;
assign subtype_o = subtype_i;
assign praddr1_o = praddr1_i;
assign praddr2_o = praddr2_i;
assign rs1_data_o = rs1_forward_flag_i ? rs1_forward_data_i : reg_rdata1_i;
assign rs2_data_o = rs2_forward_flag_i ? rs2_forward_data_i : reg_rdata2_i;
assign pwaddr_o = pwaddr_i;


endmodule