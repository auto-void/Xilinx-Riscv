`include "defines.vh"

`timescale 1ns / 1ps

module Branch (
    input clk,
    input rst,

    // from issue
    input br_inst_valid_i,              // branch指令有效标志
    input [15:0] br_inst_addr_i,        // branch指令地址
    input [5:0] br_rob_id_i,            // branch ROB id
    input br_bpu_pre_flag_i,            // branch BPU预测标志
    input [31:0] br_bpu_pre_addr_i,     // branch BPU预测地址
    input [3:0] br_mask_i,              // branch分支掩码
    input [2:0] br_ras_ptr_i,           // branch RAS快照指针
    input [2:0] br_mem_wr_ptr_i,        // branch mem队列写操作快照指针
    input [2:0] br_sq_ptr_i,            // branch store queue快照指针
    input [1:0] br_snap_id_i,           // branch快照id
    input [2:0] br_type_i,              // branch指令类型
    input [3:0] br_subtype_i,           // branch指令子类型
    input [5:0] br_praddr1_i,           // branch物理寄存器1读地址
    input [5:0] br_praddr2_i,           // branch物理寄存器2读地址
    input [5:0] br_pwaddr_i,            // branch物理寄存器写地址
    input [31:0] br_imm_i,              // branch立即数
    input [31:0] br_aux_addr_i,         // branch辅助地址

    // from forward_unit
    input rs1_forward_flag_i,           // rs1转发标志
    input [31:0] rs1_forward_data_i,    // rs1转发数据
    input rs2_forward_flag_i,           // rs2转发标志
    input [31:0] rs2_forward_data_i,    // rs2转发数据

    // from regs
    input [31:0] reg_rdata1_i,          // 寄存器1读数据
    input [31:0] reg_rdata2_i,          // 寄存器2读数据

    // from clint
    input int_flag_i,                   // 中断标志

    // to pipeline
    output jump_flag_o,                 // 跳转标志
    output [1:0] kill_mask_id_o,        // 分支掩码id

    // to RAS
    output [2:0] ras_snap_ptr_o,              // RAS快照指针

    // to issue
    output [2:0] br_mem_wr_ptr_o,        // branch mem队列写操作快照指针
    output [2:0] br_sq_ptr_o,            // branch store queue快照指针

    // to PC
    output [31:0] jump_addr_o,          // 跳转地址

    // to bpu_update_buffer
    output btb_update_en,                     // 执行阶段更新BTB使能
    output [15:0] ex_pc,                      // 执行阶段的pc
    output [31:0] ex_jump_addr_o,             // 跳转地址
    output is_branch,                         // 是否为分支指令
    output lhp_update_en,                     // 更新使能
    output branch_taken,                      // 实际跳转结果(1为跳转)

    // to regs
    output [5:0] rf_raddr1_o,           // RF 阶段读寄存器1地址（同时传到转发模块）
    output [5:0] rf_raddr2_o,           // RF 阶段读寄存器2地址（同时传到转发模块）
    output rf_wflag_o,                  // RF 阶段写寄存器标志
    output [5:0] rf_waddr_o,            // RF 阶段写寄存器地址(同时传到issue阶段)
    output reg_wflag_o,                 // 写回阶段写寄存器标志
    output [5:0] reg_waddr_o,           // 写回阶段写寄存器地址
    output [31:0] reg_wdata_o,          // 写回阶段写寄存器数据

    // to ROB
    output complete_flag_o,             // 指令完成标志
    output [5:0] commit_rob_id_o        // 提交ROB id
);

// br_rf
wire rf_br_inst_valid_o;              // branch指令有效标志
wire [15:0] rf_br_inst_addr_o;        // branch指令地址
wire [5:0] rf_br_rob_id_o;            // branch ROB id
wire rf_br_bpu_pre_flag_o;            // branch BPU预测标志
wire [31:0] rf_br_bpu_pre_addr_o;     // branch BPU预测地址
wire [3:0] rf_br_mask_o;              // branch分支掩码
wire [2:0] rf_br_ras_ptr_o;           // branch RAS快照指针
wire [2:0] rf_br_mem_wr_ptr_o;        // branch mem队列写操作快照指针
wire [2:0] rf_br_sq_ptr_o;            // branch store queue快照指针
wire [1:0] rf_br_snap_id_o;           // branch快照id
wire [2:0] rf_br_type_o;              // branch指令类型
wire [3:0] rf_br_subtype_o;           // branch指令子类型
wire [31:0] rf_br_rs1_data_o;         // rs1数据
wire [31:0] rf_br_rs2_data_o;         // rs2数据
wire [31:0] rf_br_imm_o;              // branch立即数
wire [31:0] rf_br_aux_addr_o;         // branch辅助地址

// br_rf_ex
wire rf_ex_br_inst_valid_o;              // branch指令有效标志
wire [15:0] rf_ex_br_inst_addr_o;        // branch指令地址
wire [5:0] rf_ex_br_rob_id_o;            // branch ROB id
wire rf_ex_br_bpu_pre_flag_o;            // branch BPU预测标志
wire [31:0] rf_ex_br_bpu_pre_addr_o;     // branch BPU预测地址
wire [3:0] rf_ex_br_mask_o;              // branch分支掩码
wire [2:0] rf_ex_br_ras_ptr_o;           // branch RAS快照指针
wire [2:0] rf_ex_br_mem_wr_ptr_o;        // branch mem队列写操作快照指针
wire [2:0] rf_ex_br_sq_ptr_o;            // branch store queue快照指针
wire [1:0] rf_ex_br_snap_id_o;           // branch快照id
wire [2:0] rf_ex_br_type_o;              // branch指令类型
wire [3:0] rf_ex_br_subtype_o;           // branch指令子类型
wire [31:0] rf_ex_br_rs1_data_o;         // rs1数据
wire [31:0] rf_ex_br_rs2_data_o;         // rs2数据
wire [5:0] rf_ex_br_waddr_o;             // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)
wire [31:0] rf_ex_br_imm_o;              // branch立即数
wire [31:0] rf_ex_br_aux_addr_o;         // branch辅助地址

// br_ex
wire ex_br_inst_valid_o;              // branch指令有效标志
wire [5:0] ex_commit_rob_id_o;        // 提交ROB id
wire ex_jump_flag_o;                  // 跳转标志
wire [1:0] ex_kill_mask_id_o;         // 分支掩码id
wire [2:0] ex_ras_snap_ptr_o;         // RAS快照指针
wire [2:0] ex_br_mem_wr_ptr_o;        // branch mem队列写操作快照指针
wire [2:0] ex_br_sq_ptr_o;            // branch store queue快照指针


// 实例化
// br_rf
br_rf u_br_rf(
    // from issue
    .br_inst_valid_i(br_inst_valid_i),              // branch指令有效标志
    .br_inst_addr_i(br_inst_addr_i),        // branch指令地址
    .br_rob_id_i(br_rob_id_i),            // branch ROB id
    .br_bpu_pre_flag_i(br_bpu_pre_flag_i),            // branch BPU预测标志
    .br_bpu_pre_addr_i(br_bpu_pre_addr_i),     // branch BPU预测地址
    .br_mask_i(br_mask_i),              // branch分支掩码
    .br_ras_ptr_i(br_ras_ptr_i),           // branch RAS快照指针
    .br_mem_wr_ptr_i(br_mem_wr_ptr_i),        // branch mem队列写操作快照指针
    .br_sq_ptr_i(br_sq_ptr_i),            // branch store queue快照指
    .br_snap_id_i(br_snap_id_i),           // branch快照id
    .br_type_i(br_type_i),              // branch指令类型
    .br_subtype_i(br_subtype_i),           // branch指令子类型
    .br_praddr1_i(br_praddr1_i),           // branch物理寄存器1读地址
    .br_praddr2_i(br_praddr2_i),           // branch物理寄存器2读地址
    .br_pwaddr_i(br_pwaddr_i),            // branch物理寄存器写地址
    .br_imm_i(br_imm_i),              // branch立即数
    .br_aux_addr_i(br_aux_addr_i),         // branch辅助地址
    // from forward_unit
    .rs1_forward_flag_i(rs1_forward_flag_i),           // rs1转发标志
    .rs1_forward_data_i(rs1_forward_data_i),    // rs1转发数据
    .rs2_forward_flag_i(rs2_forward_flag_i),           // rs2转发标志
    .rs2_forward_data_i(rs2_forward_data_i),    // rs2转发数据
    // from regs
    .reg_rdata1_i(reg_rdata1_i),          // 寄存器1读数据
    .reg_rdata2_i(reg_rdata2_i),          // 寄存器2读数据
    // from br_flush
    .jump_flag_i(jump_flag_o),                  // 跳转标志
    .kill_mask_id_i(kill_mask_id_o),         // 分支掩码id
    // to regs
    .rf_raddr1_o(rf_raddr1_o),           // RF 阶段读寄存器1地址（同时传到转发模块）
    .rf_raddr2_o(rf_raddr2_o),           // RF 阶段读寄存器2地址（同时传到转发模块）
    .rf_wflag_o(rf_wflag_o),                  // RF 阶段写寄存器标志
    .rf_waddr_o(rf_waddr_o),            // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)
    // to ex
    .br_inst_valid_o(rf_br_inst_valid_o),              // branch指令有效标志
    .br_inst_addr_o(rf_br_inst_addr_o),        // branch指令地址
    .br_rob_id_o(rf_br_rob_id_o),            // branch ROB id
    .br_bpu_pre_flag_o(rf_br_bpu_pre_flag_o),            // branch BPU预测标志
    .br_bpu_pre_addr_o(rf_br_bpu_pre_addr_o),     // branch BPU预测地址
    .br_mask_o(rf_br_mask_o),              // branch分支掩码
    .br_ras_ptr_o(rf_br_ras_ptr_o),           // branch RAS快照指针
    .br_mem_wr_ptr_o(rf_br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_o(rf_br_sq_ptr_o),            // branch store queue快照指针
    .br_snap_id_o(rf_br_snap_id_o),           // branch快照id
    .br_type_o(rf_br_type_o),              // branch指令类型
    .br_subtype_o(rf_br_subtype_o),           // branch指令子类型
    .br_rs1_data_o(rf_br_rs1_data_o),         // rs1数据
    .br_rs2_data_o(rf_br_rs2_data_o),         // rs2数据
    .br_imm_o(rf_br_imm_o),              // branch立即数
    .br_aux_addr_o(rf_br_aux_addr_o)          // branch辅助地址
);

// br_rf_ex
br_rf_ex u_br_rf_ex(
    .clk(clk),
    .rst(rst),
    // from RF
    .br_inst_valid_i(rf_br_inst_valid_o),              // branch指令有效标志
    .br_inst_addr_i(rf_br_inst_addr_o),        // branch指令地址
    .br_rob_id_i(rf_br_rob_id_o),            // branch ROB id
    .br_bpu_pre_flag_i(rf_br_bpu_pre_flag_o),            // branch BPU预测标志
    .br_bpu_pre_addr_i(rf_br_bpu_pre_addr_o),     // branch BPU预测地址
    .br_mask_i(rf_br_mask_o),              // branch分支掩码
    .br_ras_ptr_i(rf_br_ras_ptr_o),           // branch RAS快照指针
    .br_mem_wr_ptr_i(rf_br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_i(rf_br_sq_ptr_o),            // branch store queue快照指针
    .br_snap_id_i(rf_br_snap_id_o),           // branch快照id
    .br_type_i(rf_br_type_o),              // branch指令类型
    .br_subtype_i(rf_br_subtype_o),           // branch指令子类型
    .br_rs1_data_i(rf_br_rs1_data_o),         // rs1数据
    .br_rs2_data_i(rf_br_rs2_data_o),         // rs2数据
    .br_waddr_i(rf_waddr_o),             // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)
    .br_imm_i(rf_br_imm_o),              // branch立即数
    .br_aux_addr_i(rf_br_aux_addr_o),         // branch辅助地址
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // to ex
    .br_inst_valid_o(rf_ex_br_inst_valid_o),              // branch指令有效标志
    .br_inst_addr_o(rf_ex_br_inst_addr_o),        // branch指令地址
    .br_rob_id_o(rf_ex_br_rob_id_o),            // branch ROB id
    .br_bpu_pre_flag_o(rf_ex_br_bpu_pre_flag_o),            // branch BPU预测标志
    .br_bpu_pre_addr_o(rf_ex_br_bpu_pre_addr_o),     // branch BPU预测地址
    .br_mask_o(rf_ex_br_mask_o),              // branch分支掩码
    .br_ras_ptr_o(rf_ex_br_ras_ptr_o),           // branch RAS快照指针
    .br_mem_wr_ptr_o(rf_ex_br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_o(rf_ex_br_sq_ptr_o),            // branch store queue快照指针
    .br_snap_id_o(rf_ex_br_snap_id_o),           // branch快照id
    .br_type_o(rf_ex_br_type_o),              // branch指令类型
    .br_subtype_o(rf_ex_br_subtype_o),           // branch指令子类型
    .br_rs1_data_o(rf_ex_br_rs1_data_o),         // rs1数据
    .br_rs2_data_o(rf_ex_br_rs2_data_o),         // rs2数据
    .br_waddr_o(rf_ex_br_waddr_o),             // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)
    .br_imm_o(rf_ex_br_imm_o),              // branch立即数
    .br_aux_addr_o(rf_ex_br_aux_addr_o)          // branch辅助地址
);

// br_ex
br_ex u_br_ex(
    // from RF
    .br_inst_valid_i(rf_ex_br_inst_valid_o),              // branch指令有效标志
    .br_inst_addr_i(rf_ex_br_inst_addr_o),        // branch指令地址
    .br_rob_id_i(rf_ex_br_rob_id_o),            // branch ROB id
    .br_bpu_pre_flag_i(rf_ex_br_bpu_pre_flag_o),            // branch BPU预测标志
    .br_bpu_pre_addr_i(rf_ex_br_bpu_pre_addr_o),     // branch BPU预测地址
    .br_mask_i(rf_ex_br_mask_o),              // branch分支掩码
    .br_ras_ptr_i(rf_ex_br_ras_ptr_o),           // branch RAS快照指针
    .br_mem_wr_ptr_i(rf_ex_br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_i(rf_ex_br_sq_ptr_o),            // branch store queue快照指针
    .br_snap_id_i(rf_ex_br_snap_id_o),           // branch快照id
    .br_type_i(rf_ex_br_type_o),              // branch指令类型
    .br_subtype_i(rf_ex_br_subtype_o),           // branch指令子类型
    .br_rs1_data_i(rf_ex_br_rs1_data_o),         // rs1数据
    .br_rs2_data_i(rf_ex_br_rs2_data_o),         // rs2数据
    .br_waddr_i(rf_ex_br_waddr_o),             // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)
    .br_imm_i(rf_ex_br_imm_o),              // branch立即数
    .br_aux_addr_i(rf_ex_br_aux_addr_o),         // branch辅助地址
    // from br_flush
    .jump_flag_i(jump_flag_o),                  // 跳转标志
    .kill_mask_id_i(kill_mask_id_o),         // 分支掩码id
    // to pipeline
    .jump_flag_o(ex_jump_flag_o),                 // 跳转标志
    .kill_mask_id_o(ex_kill_mask_id_o),            // 分支掩码id
    // to RAS
    .ras_snap_ptr_o(ex_ras_snap_ptr_o),              // RAS快照指针
    // to issue
    .br_mem_wr_ptr_o(ex_br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_o(ex_br_sq_ptr_o),            // branch store queue快照指针
    // to PC
    .jump_addr_o(ex_jump_addr_o),          // 跳转地址(同时传到bpu_update_buffer)
    // to bpu_update_buffer
    .btb_update_en(btb_update_en),                     // 执行阶段更新BTB使能
    .ex_pc(ex_pc),                          // 执行阶段的pc
    .is_branch(is_branch),                             // 是否为分支指令
    .lhp_update_en(lhp_update_en),                     // 更新使能
    .branch_taken(branch_taken),                      // 实际跳转结果(1为跳转)
    // to regs
    .reg_wflag_o(reg_wflag_o),                 // 写寄存器标志
    .reg_waddr_o(reg_waddr_o),           // 写寄存器地址
    .reg_wdata_o(reg_wdata_o),      // 写寄存器数据
    // to br_flush
    .br_inst_valid_o(ex_br_inst_valid_o),
    .commit_rob_id_o(ex_commit_rob_id_o)        // 提交ROB id
);

// br_ex_flush
br_ex_flush u_br_ex_flush(
    .clk(clk),
    .rst(rst),
    // from br_ex
    .br_inst_valid_i(ex_br_inst_valid_o),              // branch指令有效标志
    .commit_rob_id_i(ex_commit_rob_id_o),        // 提交ROB id
    .jump_flag_i(ex_jump_flag_o),                   // 跳转标志
    .kill_mask_id_i(ex_kill_mask_id_o),         // 分支掩码id
    .ras_snap_ptr_i(ex_ras_snap_ptr_o),         // RAS快照指针
    .br_mem_wr_ptr_i(ex_br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_i(ex_br_sq_ptr_o),            // branch store queue快照指针
    .jump_addr_i(ex_jump_addr_o),           // 跳转地址
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // to br_flush
    .br_inst_valid_o(complete_flag_o),              // branch指令有效标志
    .commit_rob_id_o(commit_rob_id_o),        // 提交ROB id
    .jump_flag_o(jump_flag_o),                  // 跳转标志
    .kill_mask_id_o(kill_mask_id_o),         // 分支掩码id
    .ras_snap_ptr_o(ras_snap_ptr_o),         // RAS快照指针
    .br_mem_wr_ptr_o(br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_o(br_sq_ptr_o),            // branch store queue快照指针
    .jump_addr_o(jump_addr_o)            // 跳转地址
);



endmodule