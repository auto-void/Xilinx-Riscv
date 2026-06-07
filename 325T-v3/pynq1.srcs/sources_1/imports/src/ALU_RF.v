`include "defines.vh"

`timescale 1ns / 1ps

// Read Register File
module ALU_RF (
    // from issue
    input inst_valid_i,                 // ALU指令有效标志
    input [5:0] rob_id_i,               // ALU ROB id
    input [3:0] mask_i,                 // ALU分支掩码
    input [3:0] subtype_i,              // ALU指令子类型
    input [1:0] op1_src_i,              // ALU操作数1
    input [1:0] op2_src_i,              // ALU操作数2
    input [5:0] praddr1_i,              // ALU物理寄存器1读地址
    input [5:0] praddr2_i,              // ALU物理寄存器2读地址
    input [5:0] pwaddr_i,               // ALU物理寄存器写地址
    input [31:0] imm_i,                 // ALU立即数

    // from forward_unit
    input rs1_forward_flag_i,           // rs1转发标志
    input [31:0] rs1_forward_data_i,    // rs1转发数据
    input rs2_forward_flag_i,           // rs2转发标志
    input [31:0] rs2_forward_data_i,    // rs2转发数据

    // from branch
    input jump_flag_i,                  // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id

    // from commit
    input free_mask_inst0_i,                   // 指令0释放掩码标志
    input [1:0] free_id_inst0_i,               // 指令0释放id
    input free_mask_inst1_i,                   // 指令1释放掩码标志
    input [1:0] free_id_inst1_i,               // 指令1释放id

    // from regs
    input [31:0] reg_rdata1_i,          // 寄存器1读数据
    input [31:0] reg_rdata2_i,          // 寄存器2读数据

    // to regs
    output [5:0] praddr1_o,             // 读寄存器1地址
    output [5:0] praddr2_o,             // 读寄存器2地址
    output rf_wflag_o,                  // RF 阶段写寄存器标志
    output [5:0] rf_waddr_o,            // RF 阶段写寄存器地址(同时传到issue阶段和ex)

    // to ex
    output inst_valid_o,                 // ALU指令有效标志
    output [5:0] rob_id_o,               // ALU ROB id
    output reg [3:0] mask_o,             // ALU分支掩码
    output [3:0] subtype_o,              // ALU指令子类型
    output [1:0] op1_src_o,              // ALU操作数1
    output [1:0] op2_src_o,              // ALU操作数2
    output [31:0] reg_rdata1_o,          // 寄存器1读数据
    output [31:0] reg_rdata2_o,          // 寄存器2读数据
    output [31:0] imm_o                  // ALU立即数
);

// 读寄存器文件
assign praddr1_o = praddr1_i;
assign praddr2_o = praddr2_i;
// 提前唤醒发射队列里的指令
assign rf_wflag_o = inst_valid_i;
assign rf_waddr_o = pwaddr_i;
// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
assign inst_valid_o = inst_valid_i && ((mask_i & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效
// 输出到执行阶段
assign rob_id_o = rob_id_i;
assign subtype_o = subtype_i;
assign op1_src_o = op1_src_i;
assign op2_src_o = op2_src_i;
assign reg_rdata1_o = rs1_forward_flag_i ? rs1_forward_data_i : reg_rdata1_i; // 转发优先于寄存器文件
assign reg_rdata2_o = rs2_forward_flag_i ? rs2_forward_data_i : reg_rdata2_i;
assign imm_o = imm_i;

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