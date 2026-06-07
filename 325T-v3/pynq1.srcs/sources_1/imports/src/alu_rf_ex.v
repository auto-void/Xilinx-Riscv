`include "defines.vh"

`timescale 1ns / 1ps

module alu_rf_ex (
    input clk,
    input rst,

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

    // from clint
    input int_flag_i,                   // 中断标志

    // to ex
    output reg inst_valid_o,             // ALU指令有效标志
    output reg [5:0] rob_id_o,           // ALU ROB id
    output reg [3:0] mask_o,             // ALU分支掩码
    output reg [3:0] subtype_o,          // ALU指令子类型
    output reg [1:0] op1_src_o,          // ALU操作数1
    output reg [1:0] op2_src_o,          // ALU操作数2
    output reg [31:0] reg_rdata1_o,      // 寄存器1读数据
    output reg [31:0] reg_rdata2_o,      // 寄存器2读数据
    output reg [5:0] pwaddr_o,           // 物理寄存器写地址
    output reg [31:0] imm_o              // ALU立即数
);

always @(posedge clk) begin
    if (!rst) begin
        inst_valid_o <= 1'b0;
        pwaddr_o <= 6'b0;
    end
    else if (int_flag_i) begin
        inst_valid_o <= 1'b0; // 中断发生时清空流水线
        pwaddr_o <= 6'b0;
    end
    else begin
        inst_valid_o <= inst_valid_i;
        pwaddr_o <= pwaddr_i;
    end
end

always @(posedge clk) begin
    rob_id_o <= rob_id_i;
    mask_o <= mask_i;
    subtype_o <= subtype_i;
    op1_src_o <= op1_src_i;
    op2_src_o <= op2_src_i;
    reg_rdata1_o <= reg_rdata1_i;
    reg_rdata2_o <= reg_rdata2_i;
    imm_o <= imm_i;
end


endmodule