`include "defines.vh"

`timescale 1ns / 1ps

// 乘法单元
module MUL (
    input clk,
    input rst,

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

    // from clint
    input int_flag_i,                   // 中断标志

    // from branch
    input jump_flag_i,                  // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id

    // from regs
    input [31:0] reg_rdata1_i,          // 寄存器1读数据
    input [31:0] reg_rdata2_i,          // 寄存器2读数据

    // to regs
    output [5:0] rf_raddr1_o,           // RF 阶段读寄存器1地址（同时传到转发模块）
    output [5:0] rf_raddr2_o,           // RF 阶段读寄存器2地址（同时传到转发模块）
    output reg_wflag_o,                 // 写回阶段写寄存器标志
    output [5:0] reg_waddr_o,           // 写回阶段写寄存器地址
    output [31:0] reg_wdata_o,          // 写回阶段写寄存器数据
    output ex_wflag_o,                  // 执行阶段写寄存器标志
    output [5:0] ex_waddr_o,            // 执行阶段写寄存器地址

    // to ROB
    output complete_flag_o,             // 指令完成标志
    output [5:0] commit_rob_id_o        // 提交ROB id
);

// RF
wire rf_inst_valid_o;               // 指令有效标志
wire [5:0] rf_rob_id_o;             // ROB id
wire [3:0] rf_subtype_o;            // 指令子类型
wire [31:0] rf_rs1_data_o;          // rs1数据
wire [31:0] rf_rs2_data_o;          // rs2数据
wire [5:0] rf_pwaddr_o;             // 物理寄存器写地址

MUL_RF u_MUL_RF (
    // from issue
    .inst_valid_i(inst_valid_i),               // 指令有效标志
    .rob_id_i(rob_id_i),             // ROB id
    .mask_i(mask_i),               // 分支掩码
    .subtype_i(subtype_i),            // 指令子类型
    .praddr1_i(praddr1_i),            // 物理寄存器1读地址
    .praddr2_i(praddr2_i),            // 物理寄存器2读地址
    .pwaddr_i(pwaddr_i),              // 物理寄存器写地址
    // from forward_unit
    .rs1_forward_flag_i(rs1_forward_flag_i),           // rs1转发标志
    .rs1_forward_data_i(rs1_forward_data_i),    // rs1转发数据
    .rs2_forward_flag_i(rs2_forward_flag_i),           // rs2转发标志
    .rs2_forward_data_i(rs2_forward_data_i),    // rs2转发数据
    // from branch
    .jump_flag_i(jump_flag_i),                  // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),         // 分支掩码id
    // from regs
    .reg_rdata1_i(reg_rdata1_i),          // 寄存器1读数据
    .reg_rdata2_i(reg_rdata2_i),          // 寄存器2读数据
    // to regs
    .praddr1_o(rf_raddr1_o),            // 物理寄存器1读地址
    .praddr2_o(rf_raddr2_o),            // 物理寄存器2读地址
    // to ex
    .inst_valid_o(rf_inst_valid_o),               // 指令有效标志
    .rob_id_o(rf_rob_id_o),             // ROB id
    .subtype_o(rf_subtype_o),            // 指令子类型
    .rs1_data_o(rf_rs1_data_o),          // rs1数据
    .rs2_data_o(rf_rs2_data_o),          // rs2数据
    .pwaddr_o(rf_pwaddr_o)              // 物理寄存器写地址
);

// mul_rf_ex
wire rf_ex_inst_valid_o;               // 指令有效标志
wire [5:0] rf_ex_rob_id_o;             // ROB id
wire [3:0] rf_ex_subtype_o;            // 指令子类型
wire [31:0] rf_ex_rs1_data_o;          // rs1数据
wire [31:0] rf_ex_rs2_data_o;          // rs2数据
wire [5:0] rf_ex_pwaddr_o;             // 物理寄存器写地址

mul_rf_ex u_mul_rf_ex(
    .clk(clk),
    .rst(rst),
    // from rf
    .inst_valid_i(rf_inst_valid_o),               // 指令有效标志
    .rob_id_i(rf_rob_id_o),             // ROB id
    .subtype_i(rf_subtype_o),            // 指令子类型
    .rs1_data_i(rf_rs1_data_o),          // rs1数据
    .rs2_data_i(rf_rs2_data_o),          // rs2数据
    .pwaddr_i(rf_pwaddr_o),             // 物理寄存器写地址
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // to ex
    .inst_valid_o(rf_ex_inst_valid_o),               // 指令有效标志
    .rob_id_o(rf_ex_rob_id_o),             // ROB id
    .subtype_o(rf_ex_subtype_o),            // 指令子类型
    .rs1_data_o(rf_ex_rs1_data_o),          // rs1数据
    .rs2_data_o(rf_ex_rs2_data_o),          // rs2数据
    .pwaddr_o(rf_ex_pwaddr_o)              // 物理寄存器写地址
);

// ex
MUL_EX u_MUL_EX(
    .clk(clk),
    .rst(rst),
    // from rf
    .inst_valid_i(rf_ex_inst_valid_o),               // 指令有效标志
    .rob_id_i(rf_ex_rob_id_o),             // ROB id
    .subtype_i(rf_ex_subtype_o),            // 指令子类型
    .rs1_data_i(rf_ex_rs1_data_o),          // rs1数据
    .rs2_data_i(rf_ex_rs2_data_o),          // rs2数据
    .pwaddr_i(rf_ex_pwaddr_o),             // 物理寄存器写地址
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // to regs
    .reg_wflag_o(reg_wflag_o),                 // 写回阶段写寄存器标志
    .reg_waddr_o(reg_waddr_o),           // 写回阶段写寄存器地址
    .reg_wdata_o(reg_wdata_o),      // 写回阶段写寄存器数据
    .ex_wflag_o(ex_wflag_o),                  // 执行阶段写寄存器标志
    .ex_waddr_o(ex_waddr_o),            // 执行阶段写寄存器地址
    // to ROB
    .complete_flag_o(complete_flag_o),             // 指令完成标志
    .commit_rob_id_o(commit_rob_id_o)        // 提交ROB id
);





endmodule