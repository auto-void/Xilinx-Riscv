`include "defines.vh"

`timescale 1ns / 1ps

module DIV_WB (
    // from ex
    input inst_valid_i,                 // 指令有效标志
    input [5:0] rob_id_i,               // ROB id
    input [5:0] pwaddr_i,               // 物理寄存器写地址
    input [31:0] reg_wdata_i,           // 写寄存器数据

    // to regs
    output reg_wflag_o,                 // 写回阶段写寄存器标志
    output [5:0] reg_waddr_o,           // 写回阶段写寄存器地址
    output [31:0] reg_wdata_o,          // 写回阶段写寄存器数据

    // to ROB
    output complete_flag_o,             // 指令完成标志
    output [5:0] commit_rob_id_o        // 提交ROB id
);
// 写回
assign reg_wflag_o = inst_valid_i;
assign reg_waddr_o = pwaddr_i;
assign reg_wdata_o = reg_wdata_i;

// 提交ROB
assign complete_flag_o = inst_valid_i;
assign commit_rob_id_o = rob_id_i;

endmodule