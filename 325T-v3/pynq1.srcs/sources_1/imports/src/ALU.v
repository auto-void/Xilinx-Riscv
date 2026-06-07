`include "defines.vh"

`timescale 1ns / 1ps

module ALU (
    input clk,
    input rst,

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

    // from clint
    input int_flag_i,                   // 中断标志

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
    output [5:0] rf_raddr1_o,           // RF 阶段读寄存器1地址（同时传到转发模块）
    output [5:0] rf_raddr2_o,           // RF 阶段读寄存器2地址（同时传到转发模块）
    output reg_wflag_o,                 // 写回阶段写寄存器标志
    output [5:0] reg_waddr_o,           // 写回阶段写寄存器地址
    output [31:0] reg_wdata_o,          // 写回阶段写寄存器数据
    output rf_wflag_o,                  // RF 阶段写寄存器标志
    output [5:0] rf_waddr_o,            // RF 阶段写寄存器地址(同时传到issue阶段和ex)

    // to forward_unit
    output [5:0] exe_waddr_o,           // 执行阶段写寄存器地址
    output [31:0] exe_wdata_o,          // 执行阶段写寄存器数据

    // to ROB
    output complete_flag_o,             // 指令完成标志
    output [5:0] commit_rob_id_o        // 提交ROB id
);

// ALU_RF
wire rf_inst_valid_o;                 // ALU指令有效标志
wire [5:0] rf_rob_id_o;               // ALU ROB id
wire [3:0] rf_mask_o;                 // ALU分支掩码
wire [3:0] rf_subtype_o;              // ALU指令子类型
wire [1:0] rf_op1_src_o;              // ALU操作数1
wire [1:0] rf_op2_src_o;              // ALU操作数2
wire [31:0] rf_reg_rdata1_o;          // 寄存器1读数据
wire [31:0] rf_reg_rdata2_o;          // 寄存器2读数据
wire [31:0] rf_imm_o;                 // ALU立即数

// alu_rf_ex
wire rf_ex_inst_valid_o;             // ALU指令有效标志
wire [5:0] rf_ex_rob_id_o;           // ALU ROB id
wire [3:0] rf_ex_mask_o;             // ALU分支掩码
wire [3:0] rf_ex_subtype_o;          // ALU指令子类型
wire [1:0] rf_ex_op1_src_o;          // ALU操作数1
wire [1:0] rf_ex_op2_src_o;          // ALU操作数2
wire [31:0] rf_ex_reg_rdata1_o;      // 寄存器1读数据
wire [31:0] rf_ex_reg_rdata2_o;      // 寄存器2读数据
wire [5:0] rf_ex_pwaddr_o;           // 物理寄存器写地址
wire [31:0] rf_ex_imm_o;             // ALU立即数

// ALU_EX
wire ex_inst_valid_o;                 // ALU指令有效标志
wire [5:0] ex_rob_id_o;               // ALU ROB id

// alu_ex_wb
wire ex_wb_inst_valid_o;             // ALU指令有效标志
wire [5:0] ex_wb_rob_id_o;           // ALU ROB id
wire [5:0] ex_wb_pwaddr_o;           // 物理寄存器写地址
wire [31:0] ex_wb_reg_wdata_o;       // 写寄存器数据


// 实例化
// ALU_RF
ALU_RF u_ALU_RF(
    // from issue
    .inst_valid_i(inst_valid_i),                 // ALU指令有效标志
    .rob_id_i(rob_id_i),               // ALU ROB id
    .mask_i(mask_i),                 // ALU分支掩码
    .subtype_i(subtype_i),              // ALU指令子类型
    .op1_src_i(op1_src_i),              // ALU操作数1
    .op2_src_i(op2_src_i),              // ALU操作数2
    .praddr1_i(praddr1_i),              // ALU物理寄存器1读地址
    .praddr2_i(praddr2_i),              // ALU物理寄存器2读地址
    .pwaddr_i(pwaddr_i),               // ALU物理寄存器写地址
    .imm_i(imm_i),                 // ALU立即数
    // from forward_unit
    .rs1_forward_flag_i(rs1_forward_flag_i),           // rs1转发标志
    .rs1_forward_data_i(rs1_forward_data_i),    // rs1转发数据
    .rs2_forward_flag_i(rs2_forward_flag_i),           // rs2转发标志
    .rs2_forward_data_i(rs2_forward_data_i),    // rs2转发数据
    // from branch
    .jump_flag_i(jump_flag_i),                  // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),         // 分支掩码id
    // from commit
    .free_mask_inst0_i(free_mask_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_mask_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_id_inst1_i),               // 指令1释放id
    // from regs
    .reg_rdata1_i(reg_rdata1_i),          // 寄存器1读数据
    .reg_rdata2_i(reg_rdata2_i),          // 寄存器2读数据
    // to regs
    .praddr1_o(rf_raddr1_o),             // 读寄存器1地址
    .praddr2_o(rf_raddr2_o),             // 读寄存器2地址
    .rf_wflag_o(rf_wflag_o),             // RF 阶段写寄存器标志
    .rf_waddr_o(rf_waddr_o),             // RF 阶段写寄存器地址(同时传到issue阶段和ex)
    // to ex
    .inst_valid_o(rf_inst_valid_o),                 // ALU指令有效标志
    .rob_id_o(rf_rob_id_o),               // ALU ROB id
    .mask_o(rf_mask_o),                 // ALU分支掩码
    .subtype_o(rf_subtype_o),              // ALU指令子类型
    .op1_src_o(rf_op1_src_o),              // ALU操作数1
    .op2_src_o(rf_op2_src_o),              // ALU操作数2
    .reg_rdata1_o(rf_reg_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_o(rf_reg_rdata2_o),          // 寄存器2读数据
    .imm_o(rf_imm_o)                  // ALU立即数
);

// alu_rf_ex
alu_rf_ex u_alu_rf_ex(
    .clk(clk),
    .rst(rst),
    // from RF
    .inst_valid_i(rf_inst_valid_o),                 // ALU指令有效标志
    .rob_id_i(rf_rob_id_o),               // ALU ROB id
    .mask_i(rf_mask_o),                 // ALU分支掩码
    .subtype_i(rf_subtype_o),              // ALU指令子类型
    .op1_src_i(rf_op1_src_o),              // ALU操作数1
    .op2_src_i(rf_op2_src_o),              // ALU操作数2
    .reg_rdata1_i(rf_reg_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_i(rf_reg_rdata2_o),          // 寄存器2读数据
    .pwaddr_i(rf_waddr_o),               // ALU物理寄存器写地址
    .imm_i(rf_imm_o),                 // ALU立即数
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // to ex
    .inst_valid_o(rf_ex_inst_valid_o),             // ALU指令有效标志
    .rob_id_o(rf_ex_rob_id_o),           // ALU ROB id
    .mask_o(rf_ex_mask_o),             // ALU分支掩码
    .subtype_o(rf_ex_subtype_o),          // ALU指令子类型
    .op1_src_o(rf_ex_op1_src_o),          // ALU操作数1
    .op2_src_o(rf_ex_op2_src_o),          // ALU操作数2
    .reg_rdata1_o(rf_ex_reg_rdata1_o),      // 寄存器1读数据
    .reg_rdata2_o(rf_ex_reg_rdata2_o),      // 寄存器2读数据
    .pwaddr_o(rf_ex_pwaddr_o),           // 物理寄存器写地址
    .imm_o(rf_ex_imm_o)              // ALU立即数
);

// ALU_EX
ALU_EX u_ALU_EX(
    // from RF
    .inst_valid_i(rf_ex_inst_valid_o),                 // ALU指令有效标志
    .rob_id_i(rf_ex_rob_id_o),               // ALU ROB id
    .mask_i(rf_ex_mask_o),                 // ALU分支掩码
    .subtype_i(rf_ex_subtype_o),              // ALU指令子类型
    .op1_src_i(rf_ex_op1_src_o),              // ALU操作数1
    .op2_src_i(rf_ex_op2_src_o),              // ALU操作数2
    .reg_rdata1_i(rf_ex_reg_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_i(rf_ex_reg_rdata2_o),          // 寄存器2读数据
    .pwaddr_i(rf_ex_pwaddr_o),               // ALU物理寄存器写地址
    .imm_i(rf_ex_imm_o),                 // ALU立即数
    // from branch
    .jump_flag_i(jump_flag_i),                  // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),         // 分支掩码id
    // to wb
    .inst_valid_o(ex_inst_valid_o),                 // ALU指令有效标志
    .rob_id_o(ex_rob_id_o),               // ALU ROB id
    .pwaddr_o(exe_waddr_o),               // 物理寄存器写地址(同时传到forward_unit)
    .reg_wdata_o(exe_wdata_o)        // 写寄存器数据(同时传到forward_unit)
);

// alu_ex_wb
alu_ex_wb u_alu_ex_wb(
    .clk(clk),
    .rst(rst),
    // from ex
    .inst_valid_i(ex_inst_valid_o),                 // ALU指令有效标志
    .rob_id_i(ex_rob_id_o),               // ALU ROB id
    .pwaddr_i(exe_waddr_o),               // 物理寄存器写地址
    .reg_wdata_i(exe_wdata_o),           // 写寄存器数据
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // to wb
    .inst_valid_o(ex_wb_inst_valid_o),            // ALU指令有效标志
    .rob_id_o(ex_wb_rob_id_o),          // ALU ROB id
    .pwaddr_o(ex_wb_pwaddr_o),          // 物理寄存器写地址
    .reg_wdata_o(ex_wb_reg_wdata_o)       // 写寄存器数据
);

// ALU_WB
ALU_WB u_ALU_WB(
    // from ex
    .inst_valid_i(ex_wb_inst_valid_o),                 // ALU指令有效标志
    .rob_id_i(ex_wb_rob_id_o),               // ALU ROB id
    .pwaddr_i(ex_wb_pwaddr_o),               // 物理寄存器写地址
    .reg_wdata_i(ex_wb_reg_wdata_o),           // 写寄存器数据
    // to regs
    .reg_wflag_o(reg_wflag_o),                 // 写寄存器标志
    .reg_waddr_o(reg_waddr_o),           // 写寄存器地址
    .reg_wdata_o(reg_wdata_o),          // 写寄存器数据
    // to ROB
    .complete_flag_o(complete_flag_o),             // 指令完成标志
    .commit_rob_id_o(commit_rob_id_o)        // 提交ROB id
);






endmodule