`include "defines.vh"

`timescale 1ns / 1ps

// 译码单元
module IDU(
    input clk,
    input rst,

    // from if_id
    input [2:0] ras_snap_ptr_i,               // RAS快照指针
    input inst_valid_port0_i,                 // 指令有效标志
    input inst_valid_port1_i,                 // 指令有效标志
    input [31:0] inst_port0_i,                // 指令内容
    input [31:0] inst_port1_i,                // 指令内容
    input [31:0] inst_addr_i,                 // 指令地址
    input [31:0] imm_port0_i,                 // 立即数
    input [31:0] imm_port1_i,                 // 立即数
    input bpu_pre_flag_port0_i,               // 预测标志
    input bpu_pre_flag_port1_i,               // 预测标志
    input [31:0] bpu_pre_addr_port0_i,        // 预测地址
    input [31:0] bpu_pre_addr_port1_i,        // 预测地址

    // to pc and if_id
    output jal_flush_o,                   // jal指令跳转冲刷
    output [31:0] jal_addr_o,             // jal指令的跳转地址

    // from ctrl
    input int_flag_i,                          // 中断标志
    input jump_flag_i,                         // 执行确认阶段跳转标志
    input [1:0] restore_snap_id_i,             // 需要恢复的快照id
    input stall_flag_i,                        // RS/ROB满暂停

    // from commit
    input free_snap_flag_inst0_i,
    input free_snap_flag_inst1_i,
    input [1:0] free_snap_id_inst0_i,     
    input [1:0] free_snap_id_inst1_i,
    input commit_inst0_i,                 // 指令0提交使能
    input [4:0] waddr_commit0_i,          // 提交指令的目标逻辑寄存器
    input [5:0] paddr_commit0_i,          // 提交指令的目标物理寄存器(成为架构状态)
    input [5:0] free_paddr_inst0_i,       // 释放的物理寄存器地址
    input commit_inst1_i,                 // 指令1提交使能
    input [4:0] waddr_commit1_i,          // 提交指令的目标逻辑寄存器
    input [5:0] paddr_commit1_i,          // 提交指令的目标物理寄存器(成为架构状态)
    input [5:0] free_paddr_inst1_i,       // 释放的物理寄存器地址

    // to regs
    output rn_alloc_flag_inst0_o,             // Inst0是否分配物理寄存器
    output rn_alloc_flag_inst1_o,             // Inst1是否分配物理寄存器
    output [5:0] rn_pwaddr_inst0_o,           // 指令0物理寄存器写地址
    output [5:0] rn_pwaddr_inst1_o,           // 指令1物理寄存器写地址

    // to pipeline
    output rn_stall_o,                        // 重命名和RS/ROB暂停信号

    // to Issue
    output [2:0] rn_dp_ras_snap_ptr_o,            // RAS快照指针
    output [31:0] rn_dp_inst_addr_o,              // 指令地址
    output [2:0] rn_dp_inst_type_port0_o,         // 指令类型
    output [2:0] rn_dp_inst_type_port1_o,         // 指令类型
    output [3:0] rn_dp_inst_subtype_port0_o,      // 指令子类型
    output [3:0] rn_dp_inst_subtype_port1_o,      // 指令子类型
    output [1:0] rn_dp_op1_src_port0_o,           // 操作数1来源选择
    output [1:0] rn_dp_op1_src_port1_o,           // 操作数1来源选择
    output [1:0] rn_dp_op2_src_port0_o,           // 操作数2来源选择
    output [1:0] rn_dp_op2_src_port1_o,           // 操作数2来源选择
    output [11:0] rn_dp_csr_addr_port0_o,         // CSR寄存器地址
    output [11:0] rn_dp_csr_addr_port1_o,         // CSR寄存器地址
    output rn_dp_csr_wflag_port0_o,               // CSR寄存器写使能
    output rn_dp_csr_wflag_port1_o,               // CSR寄存器写使能
    output rn_dp_reg_wflag_port0_o,               // 通用寄存器写使能
    output rn_dp_reg_wflag_port1_o,               // 通用寄存器写使能
    output [4:0] rn_dp_reg_waddr_port0_o,         // 写通用寄存器地址
    output [4:0] rn_dp_reg_waddr_port1_o,         // 写通用寄存器地址
    output rn_dp_inst_valid_port0_o,              // 指令有效标志
    output rn_dp_inst_valid_port1_o,              // 指令有效标志
    output [31:0] rn_dp_imm_port0_o,              // 立即数
    output [31:0] rn_dp_imm_port1_o,              // 立即数
    output [31:0] rn_dp_aux_addr_port0_o,         // Auxiliary Address（辅助地址）
    output [31:0] rn_dp_aux_addr_port1_o,         // Auxiliary Address（辅助地址）
    output rn_dp_bpu_pre_flag_port0_o,            // 预测标志
    output rn_dp_bpu_pre_flag_port1_o,            // 预测标志
    output [31:0] rn_dp_bpu_pre_addr_port0_o,     // 预测地址
    output [31:0] rn_dp_bpu_pre_addr_port1_o,     // 预测地址
    output [5:0] rn_dp_praddr1_inst0_o,           // 指令0物理寄存器1读地址
    output [5:0] rn_dp_praddr2_inst0_o,           // 指令0物理寄存器2读地址
    output [5:0] rn_dp_praddr1_inst1_o,           // 指令1物理寄存器1读地址
    output [5:0] rn_dp_praddr2_inst1_o,           // 指令1物理寄存器2读地址
    output [5:0] rn_dp_pwaddr_inst0_o,            // 指令0物理寄存器写地址
    output [5:0] rn_dp_pwaddr_inst1_o,            // 指令1物理寄存器写地址
    output [3:0] rn_dp_branch_mask_inst0_o,       // 指令0分支掩码
    output [3:0] rn_dp_branch_mask_inst1_o,       // 指令1分支掩码
    output [5:0] rn_dp_old_paddr_inst0_o,         // 指令0旧物理寄存器地址
    output [5:0] rn_dp_old_paddr_inst1_o,         // 指令1旧物理寄存器地址
    output [1:0] rn_dp_snap_id_inst0_o,           // 指令0快照id
    output [1:0] rn_dp_snap_id_inst1_o            // 指令1快照id
);

// id
wire [2:0] id_ras_snap_ptr_o;            // RAS快照指针
wire [31:0] id_inst_addr_o;              // 指令地址
wire [2:0] id_inst_type_port0_o;         // 指令类型
wire [2:0] id_inst_type_port1_o;         // 指令类型
wire [3:0] id_inst_subtype_port0_o;      // 指令子类型
wire [3:0] id_inst_subtype_port1_o;      // 指令子类型
wire [1:0] id_op1_src_port0_o;           // 操作数1来源选择
wire [1:0] id_op1_src_port1_o;           // 操作数1来源选择
wire [1:0] id_op2_src_port0_o;           // 操作数2来源选择
wire [1:0] id_op2_src_port1_o;           // 操作数2来源选择
wire [11:0] id_csr_addr_port0_o;         // CSR寄存器地址
wire [11:0] id_csr_addr_port1_o;         // CSR寄存器地址
wire id_csr_wflag_port0_o;               // CSR寄存器写使能
wire id_csr_wflag_port1_o;               // CSR寄存器写使能
wire [4:0] id_reg1_raddr_port0_o;        // 读通用寄存器1地址
wire [4:0] id_reg1_raddr_port1_o;        // 读通用寄存器1地址
wire [4:0] id_reg2_raddr_port0_o;        // 读通用寄存器2地址
wire [4:0] id_reg2_raddr_port1_o;        // 读通用寄存器2地址
wire id_reg_wflag_port0_o;               // 通用寄存器写使能
wire id_reg_wflag_port1_o;               // 通用寄存器写使能
wire [4:0] id_reg_waddr_port0_o;        // 写通用寄存器地址
wire [4:0] id_reg_waddr_port1_o;        // 写通用寄存器地址
wire id_inst_valid_port0_o;             // 指令有效标志
wire id_inst_valid_port1_o;             // 指令有效标志
wire [31:0] id_imm_port0_o;             // 立即数
wire [31:0] id_imm_port1_o;             // 立即数
wire [31:0] id_aux_addr_port0_o;        // Auxiliary Address（辅助地址）
wire [31:0] id_aux_addr_port1_o;        // Auxiliary Address（辅助地址）
wire id_bpu_pre_flag_port0_o;           // 预测标志
wire id_bpu_pre_flag_port1_o;           // 预测标志
wire [31:0] id_bpu_pre_addr_port0_o;    // 预测地址
wire [31:0] id_bpu_pre_addr_port1_o;    // 预测地址

// id_rename
wire [2:0] id_rn_ras_snap_ptr_o;            // RAS快照指针
wire [31:0] id_rn_inst_addr_o;              // 指令地址
wire [2:0] id_rn_inst_type_port0_o;         // 指令类型
wire [2:0] id_rn_inst_type_port1_o;         // 指令类型
wire [3:0] id_rn_inst_subtype_port0_o;      // 指令子类型
wire [3:0] id_rn_inst_subtype_port1_o;      // 指令子类型
wire [1:0] id_rn_op1_src_port0_o;           // 操作数1来源选择
wire [1:0] id_rn_op1_src_port1_o;           // 操作数1来源选择
wire [1:0] id_rn_op2_src_port0_o;           // 操作数2来源选择
wire [1:0] id_rn_op2_src_port1_o;           // 操作数2来源选择
wire [11:0] id_rn_csr_addr_port0_o;         // CSR寄存器地址
wire [11:0] id_rn_csr_addr_port1_o;         // CSR寄存器地址
wire id_rn_csr_wflag_port0_o;               // CSR寄存器写使能
wire id_rn_csr_wflag_port1_o;               // CSR寄存器写使能
wire [4:0] id_rn_reg1_raddr_port0_o;        // 读通用寄存器1地址
wire [4:0] id_rn_reg1_raddr_port1_o;        // 读通用寄存器1地址
wire [4:0] id_rn_reg2_raddr_port0_o;        // 读通用寄存器2地址
wire [4:0] id_rn_reg2_raddr_port1_o;        // 读通用寄存器2地址
wire id_rn_reg_wflag_port0_o;               // 通用寄存器写使能
wire id_rn_reg_wflag_port1_o;               // 通用寄存器写使能
wire [4:0] id_rn_reg_waddr_port0_o;        // 写通用寄存器地址
wire [4:0] id_rn_reg_waddr_port1_o;        // 写通用寄存器地址
wire id_rn_inst_valid_port0_o;             // 指令有效标志
wire id_rn_inst_valid_port1_o;             // 指令有效标志
wire [31:0] id_rn_imm_port0_o;             // 立即数
wire [31:0] id_rn_imm_port1_o;             // 立即数
wire [31:0] id_rn_aux_addr_port0_o;       // Auxiliary Address（辅助地址）
wire [31:0] id_rn_aux_addr_port1_o;       // Auxiliary Address（辅助地址）
wire id_rn_bpu_pre_flag_port0_o;          // 预测标志
wire id_rn_bpu_pre_flag_port1_o;          // 预测标志
wire [31:0] id_rn_bpu_pre_addr_port0_o;   // 预测地址
wire [31:0] id_rn_bpu_pre_addr_port1_o;   // 预测地址

// rename
wire rename_alloc_snap_inst0 = id_rn_inst_valid_port0_o && ((id_rn_inst_type_port0_o == `TYPE_BR) || (id_rn_inst_type_port0_o == `TYPE_JAL && id_rn_inst_subtype_port0_o == `JUMP_JALR));          // 为指令0分配快照标志
wire rename_alloc_snap_inst1 = id_rn_inst_valid_port1_o && ((id_rn_inst_type_port1_o == `TYPE_BR) || (id_rn_inst_type_port1_o == `TYPE_JAL && id_rn_inst_subtype_port1_o == `JUMP_JALR));          // 为指令1分配快照标志
wire [5:0] rn_praddr1_inst0_o;          // 指令0物理寄存器1读地址
wire [5:0] rn_praddr2_inst0_o;          // 指令0物理寄存器2读地址
wire [5:0] rn_praddr1_inst1_o;          // 指令1物理寄存器1读地址
wire [5:0] rn_praddr2_inst1_o;          // 指令1物理寄存器2读地址
wire [3:0] rn_branch_mask_inst0_o;      // 指令0分支掩码
wire [3:0] rn_branch_mask_inst1_o;      // 指令1分支掩码
wire [5:0] rn_old_paddr_inst0_o;        // 指令0旧物理寄存器地址
wire [5:0] rn_old_paddr_inst1_o;        // 指令1旧物理寄存器地址
wire [1:0] rn_snap_id_inst0_o;          // 指令0快照id
wire [1:0] rn_snap_id_inst1_o;          // 指令1快照id


// 实例化
// id
id u_id(
    // from if_stage2
    .ras_snap_ptr_i(ras_snap_ptr_i),
    .inst_valid_port0_i(inst_valid_port0_i),
    .inst_valid_port1_i(inst_valid_port1_i),
    .inst_port0_i(inst_port0_i),
    .inst_port1_i(inst_port1_i),
    .inst_addr_i(inst_addr_i),
    .imm_port0_i(imm_port0_i),
    .imm_port1_i(imm_port1_i),
    .bpu_pre_flag_port0_i(bpu_pre_flag_port0_i),
    .bpu_pre_flag_port1_i(bpu_pre_flag_port1_i),
    .bpu_pre_addr_port0_i(bpu_pre_addr_port0_i),
    .bpu_pre_addr_port1_i(bpu_pre_addr_port1_i),
    // to pc and if_id
    .jal_flush_o(jal_flush_o),                    // jal指令跳转冲刷
    .jal_addr_o(jal_addr_o),              // jal指令的跳转地址
    // to dispatch
    .ras_snap_ptr_o(id_ras_snap_ptr_o),               // RAS快照指针
    .inst_addr_o(id_inst_addr_o),                       // 指令地址
    .inst_type_port0_o(id_inst_type_port0_o),              // 指令类型
    .inst_type_port1_o(id_inst_type_port1_o),              // 指令类型
    .inst_subtype_port0_o(id_inst_subtype_port0_o),           // 指令子类型
    .inst_subtype_port1_o(id_inst_subtype_port1_o),           // 指令子类型
    .op1_src_port0_o(id_op1_src_port0_o),                // 操作数1来源选择
    .op1_src_port1_o(id_op1_src_port1_o),                // 操作数1来源选择
    .op2_src_port0_o(id_op2_src_port0_o),                // 操作数2来源选择
    .op2_src_port1_o(id_op2_src_port1_o),                // 操作数2来源选择
    .csr_addr_port0_o(id_csr_addr_port0_o),              // CSR寄存器地址
    .csr_addr_port1_o(id_csr_addr_port1_o),              // CSR寄存器地址
    .csr_wflag_port0_o(id_csr_wflag_port0_o),                    // CSR寄存器写使能
    .csr_wflag_port1_o(id_csr_wflag_port1_o),                    // CSR寄存器写使能
    .reg1_raddr_port0_o(id_reg1_raddr_port0_o),             // 读通用寄存器1地址
    .reg1_raddr_port1_o(id_reg1_raddr_port1_o),             // 读通用寄存器1地址
    .reg2_raddr_port0_o(id_reg2_raddr_port0_o),             // 读通用寄存器2地址
    .reg2_raddr_port1_o(id_reg2_raddr_port1_o),             // 读通用寄存器2地址
    .reg_wflag_port0_o(id_reg_wflag_port0_o),                    // 通用寄存器写使能
    .reg_wflag_port1_o(id_reg_wflag_port1_o),                    // 通用寄存器写使能
    .reg_waddr_port0_o(id_reg_waddr_port0_o),              // 写通用寄存器地址
    .reg_waddr_port1_o(id_reg_waddr_port1_o),              // 写通用寄存器地址
    .inst_valid_port0_o(id_inst_valid_port0_o),                 // 指令有效标志
    .inst_valid_port1_o(id_inst_valid_port1_o),                 // 指令有效标志
    .imm_port0_o(id_imm_port0_o),                 // 立即数
    .imm_port1_o(id_imm_port1_o),                 // 立即数
    .aux_addr_port0_o(id_aux_addr_port0_o),        // Auxiliary Address（辅助地址）
    .aux_addr_port1_o(id_aux_addr_port1_o),        // Auxiliary Address（辅助地址）
    .bpu_pre_flag_port0_o(id_bpu_pre_flag_port0_o),               // 预测标志
    .bpu_pre_flag_port1_o(id_bpu_pre_flag_port1_o),               // 预测标志
    .bpu_pre_addr_port0_o(id_bpu_pre_addr_port0_o),        // 预测地址
    .bpu_pre_addr_port1_o(id_bpu_pre_addr_port1_o)         // 预测地址
);

// id_rn
id_rn u_id_rn(
    .clk(clk),
    .rst(rst),
    // from id
    .ras_snap_ptr_i(id_ras_snap_ptr_o),                 // RAS快照指针
    .inst_addr_i(id_inst_addr_o),                   // 指令地址
    .inst_type_port0_i(id_inst_type_port0_o),              // 指令类型
    .inst_type_port1_i(id_inst_type_port1_o),              // 指令类型
    .inst_subtype_port0_i(id_inst_subtype_port0_o),           // 指令子类型
    .inst_subtype_port1_i(id_inst_subtype_port1_o),           // 指令子类型
    .op1_src_port0_i(id_op1_src_port0_o),                // 操作数1来源选择
    .op1_src_port1_i(id_op1_src_port1_o),                // 操作数1来源选择
    .op2_src_port0_i(id_op2_src_port0_o),                // 操作数2来源选择
    .op2_src_port1_i(id_op2_src_port1_o),                // 操作数2来源选择
    .csr_addr_port0_i(id_csr_addr_port0_o),              // CSR寄存器地址
    .csr_addr_port1_i(id_csr_addr_port1_o),              // CSR寄存器地址
    .csr_wflag_port0_i(id_csr_wflag_port0_o),                    // CSR寄存器写使能
    .csr_wflag_port1_i(id_csr_wflag_port1_o),                    // CSR寄存器写使能
    .reg1_raddr_port0_i(id_reg1_raddr_port0_o),             // 读通用寄存器1地址
    .reg1_raddr_port1_i(id_reg1_raddr_port1_o),             // 读通用寄存器1地址
    .reg2_raddr_port0_i(id_reg2_raddr_port0_o),             // 读通用寄存器2地址
    .reg2_raddr_port1_i(id_reg2_raddr_port1_o),             // 读通用寄存器2地址
    .reg_wflag_port0_i(id_reg_wflag_port0_o),                    // 通用寄存器写使能
    .reg_wflag_port1_i(id_reg_wflag_port1_o),                    // 通用寄存器写使能
    .reg_waddr_port0_i(id_reg_waddr_port0_o),              // 写通用寄存器地址
    .reg_waddr_port1_i(id_reg_waddr_port1_o),              // 写通用寄存器地址
    .inst_valid_port0_i(id_inst_valid_port0_o),                 // 指令有效标志
    .inst_valid_port1_i(id_inst_valid_port1_o),                 // 指令有效标志
    .imm_port0_i(id_imm_port0_o),                 // 立即数
    .imm_port1_i(id_imm_port1_o),                 // 立即数
    .aux_addr_port0_i(id_aux_addr_port0_o),        // Auxiliary Address（辅助地址）
    .aux_addr_port1_i(id_aux_addr_port1_o),        // Auxiliary Address（辅助地址）
    .bpu_pre_flag_port0_i(id_bpu_pre_flag_port0_o),               // 预测标志
    .bpu_pre_flag_port1_i(id_bpu_pre_flag_port1_o),               // 预测标志
    .bpu_pre_addr_port0_i(id_bpu_pre_addr_port0_o),        // 预测地址
    .bpu_pre_addr_port1_i(id_bpu_pre_addr_port1_o),        // 预测地址
    // from ctrl
    .int_flag_i(int_flag_i),                          // 中断标志
    .jump_flag_i(jump_flag_i),                  // 执行确认阶段跳转标志
    .stall_flag_i(rn_stall_o),                        // RS/ROB满暂停
    // to rename and dispatch
    .ras_snap_ptr_o(id_rn_ras_snap_ptr_o),                 // RAS快照指针
    .inst_addr_o(id_rn_inst_addr_o),                   // 指令地址
    .inst_type_port0_o(id_rn_inst_type_port0_o),              // 指令类型
    .inst_type_port1_o(id_rn_inst_type_port1_o),              // 指令类型
    .inst_subtype_port0_o(id_rn_inst_subtype_port0_o),           // 指令子类型
    .inst_subtype_port1_o(id_rn_inst_subtype_port1_o),           // 指令子类型
    .op1_src_port0_o(id_rn_op1_src_port0_o),                // 操作数1来源选择
    .op1_src_port1_o(id_rn_op1_src_port1_o),                // 操作数1来源选择
    .op2_src_port0_o(id_rn_op2_src_port0_o),                // 操作数2来源选择
    .op2_src_port1_o(id_rn_op2_src_port1_o),                // 操作数2来源选择
    .csr_addr_port0_o(id_rn_csr_addr_port0_o),              // CSR寄存器地址
    .csr_addr_port1_o(id_rn_csr_addr_port1_o),              // CSR寄存器地址
    .csr_wflag_port0_o(id_rn_csr_wflag_port0_o),                    // CSR寄存器写使能
    .csr_wflag_port1_o(id_rn_csr_wflag_port1_o),                    // CSR寄存器写使能
    .reg1_raddr_port0_o(id_rn_reg1_raddr_port0_o),             // 读通用寄存器1地址
    .reg1_raddr_port1_o(id_rn_reg1_raddr_port1_o),             // 读通用寄存器1地址
    .reg2_raddr_port0_o(id_rn_reg2_raddr_port0_o),             // 读通用寄存器2地址
    .reg2_raddr_port1_o(id_rn_reg2_raddr_port1_o),             // 读通用寄存器2地址
    .reg_wflag_port0_o(id_rn_reg_wflag_port0_o),                    // 通用寄存器写使能
    .reg_wflag_port1_o(id_rn_reg_wflag_port1_o),                    // 通用寄存器写使能
    .reg_waddr_port0_o(id_rn_reg_waddr_port0_o),              // 写通用寄存器地址
    .reg_waddr_port1_o(id_rn_reg_waddr_port1_o),              // 写通用寄存器地址
    .inst_valid_port0_o(id_rn_inst_valid_port0_o),                 // 指令有效标志
    .inst_valid_port1_o(id_rn_inst_valid_port1_o),                 // 指令有效标志
    .imm_port0_o(id_rn_imm_port0_o),                 // 立即数
    .imm_port1_o(id_rn_imm_port1_o),                 // 立即数
    .aux_addr_port0_o(id_rn_aux_addr_port0_o),        // Auxiliary Address（辅助地址）
    .aux_addr_port1_o(id_rn_aux_addr_port1_o),        // Auxiliary Address（辅助地址）
    .bpu_pre_flag_port0_o(id_rn_bpu_pre_flag_port0_o),               // 预测标志
    .bpu_pre_flag_port1_o(id_rn_bpu_pre_flag_port1_o),               // 预测标志
    .bpu_pre_addr_port0_o(id_rn_bpu_pre_addr_port0_o),        // 预测地址
    .bpu_pre_addr_port1_o(id_rn_bpu_pre_addr_port1_o)         // 预测地址
);

// rename
rename u_rename(
    .clk(clk),
    .rst(rst),
    // from ctrl
    .int_flag_i(int_flag_i),                  // 中断信号
    .flush_i(jump_flag_i),                         // 流水线冲刷信号
    .restore_snap_id_i(restore_snap_id_i),     // 需要恢复的快照id
    .alloc_snap_inst0_i(rename_alloc_snap_inst0),          // 为指令0分配快照标志
    .alloc_snap_inst1_i(rename_alloc_snap_inst1),          // 为指令1分配快照标志
    // from id
    .inst0_valid_i(id_rn_inst_valid_port0_o),              // 指令0有效标志
    .inst1_valid_i(id_rn_inst_valid_port1_o),              // 指令1有效标志
    .raddr1_inst0_i(id_rn_reg1_raddr_port0_o),       // 读寄存器1地址
    .raddr2_inst0_i(id_rn_reg2_raddr_port0_o),       // 读寄存器2地址
    .raddr1_inst1_i(id_rn_reg1_raddr_port1_o),       // 读寄存器1地址
    .raddr2_inst1_i(id_rn_reg2_raddr_port1_o),       // 读寄存器2地址
    .waddr_inst0_i(id_rn_reg_waddr_port0_o),        // 目标寄存器地址
    .waddr_inst1_i(id_rn_reg_waddr_port1_o),        // 目标寄存器地址
    .wflag_inst0_i(id_rn_reg_wflag_port0_o),              // 写寄存器标志
    .wflag_inst1_i(id_rn_reg_wflag_port1_o),              // 写寄存器标志
    // from dispatch
    .stall_flag_i(stall_flag_i),               // RS/ROB满暂停
    // from commit
    .free_snap_flag_inst0_i(free_snap_flag_inst0_i),         // 指令0释放快照标志
    .free_snap_flag_inst1_i(free_snap_flag_inst1_i),         // 指令1释放快照标志
    // 释放 ID，用于清理内部 Mask
    .free_snap_id_inst0_i(free_snap_id_inst0_i),     
    .free_snap_id_inst1_i(free_snap_id_inst1_i),
    .commit_inst0_i(commit_inst0_i),                 // 指令0提交使能
    .waddr_commit0_i(waddr_commit0_i),          // 提交指令的目标逻辑寄存器
    .paddr_commit0_i(paddr_commit0_i),          // 提交指令的目标物理寄存器(成为架构状态)
    .free_paddr_inst0_i(free_paddr_inst0_i),       // 释放的物理寄存器地址
    .commit_inst1_i(commit_inst1_i),                 // 指令1提交使能
    .waddr_commit1_i(waddr_commit1_i),          // 提交指令的目标逻辑寄存器
    .paddr_commit1_i(paddr_commit1_i),          // 提交指令的目标物理寄存器(成为架构状态)
    .free_paddr_inst1_i(free_paddr_inst1_i),       // 释放的物理寄存器地址
    // to pipeline
    .stall_o(rn_stall_o),                          // 重命名阶段暂停信号
    // to RS
    .praddr1_inst0_o(rn_praddr1_inst0_o),        // 物理寄存器1地址
    .praddr2_inst0_o(rn_praddr2_inst0_o),        // 物理寄存器2地址
    .praddr1_inst1_o(rn_praddr1_inst1_o),        // 物理寄存器1地址
    .praddr2_inst1_o(rn_praddr2_inst1_o),        // 物理寄存器2地址
    .pwaddr_inst0_o(rn_pwaddr_inst0_o),         // 分配的物理寄存器地址
    .pwaddr_inst1_o(rn_pwaddr_inst1_o),         // 分配的物理寄存器地址
    .branch_mask_inst0_o(rn_branch_mask_inst0_o),    // 指令0携带的依赖掩码
    .branch_mask_inst1_o(rn_branch_mask_inst1_o),    // 指令1携带的依赖掩码
    // To ROB - 旧的物理映射 (用于提交时释放)
    .old_paddr_inst0_o(rn_old_paddr_inst0_o),
    .old_paddr_inst1_o(rn_old_paddr_inst1_o),
    // to regs
    .alloc_flag_inst0_o(rn_alloc_flag_inst0_o),             // Inst0是否分配物理寄存器
    .alloc_flag_inst1_o(rn_alloc_flag_inst1_o),             // Inst1是否分配物理寄存器
    // To Dispatch - 分配给当前分支指令的快照 ID (随指令流水线流动)
    .snap_id_inst0_o(rn_snap_id_inst0_o),
    .snap_id_inst1_o(rn_snap_id_inst1_o)
);

// rn_dp
rn_dp u_rn_dp(
    .clk(clk),
    .rst(rst),
    // from id
    .ras_snap_ptr_i(id_rn_ras_snap_ptr_o),                 // RAS快照指针
    .inst_addr_i(id_rn_inst_addr_o),                   // 指令地址
    .inst_type_port0_i(id_rn_inst_type_port0_o),              // 指令类型
    .inst_type_port1_i(id_rn_inst_type_port1_o),              // 指令类型
    .inst_subtype_port0_i(id_rn_inst_subtype_port0_o),           // 指令子类型
    .inst_subtype_port1_i(id_rn_inst_subtype_port1_o),           // 指令子类型
    .op1_src_port0_i(id_rn_op1_src_port0_o),                // 操作数1来源选择
    .op1_src_port1_i(id_rn_op1_src_port1_o),                // 操作数1来源选择
    .op2_src_port0_i(id_rn_op2_src_port0_o),                // 操作数2来源选择
    .op2_src_port1_i(id_rn_op2_src_port1_o),                // 操作数2来源选择
    .csr_addr_port0_i(id_rn_csr_addr_port0_o),              // CSR寄存器地址
    .csr_addr_port1_i(id_rn_csr_addr_port1_o),              // CSR寄存器地址
    .csr_wflag_port0_i(id_rn_csr_wflag_port0_o),                    // CSR寄存器写使能
    .csr_wflag_port1_i(id_rn_csr_wflag_port1_o),                    // CSR寄存器写使能
    .reg_wflag_port0_i(id_rn_reg_wflag_port0_o),                    // 通用寄存器写使能
    .reg_wflag_port1_i(id_rn_reg_wflag_port1_o),                    // 通用寄存器写使能
    .reg_waddr_port0_i(id_rn_reg_waddr_port0_o),              // 写通用寄存器地址
    .reg_waddr_port1_i(id_rn_reg_waddr_port1_o),              // 写通用寄存器地址
    .inst_valid_port0_i(id_rn_inst_valid_port0_o),                   // 指令有效标志
    .inst_valid_port1_i(id_rn_inst_valid_port1_o),                   // 指令有效标志
    .imm_port0_i(id_rn_imm_port0_o),                   // 立即数
    .imm_port1_i(id_rn_imm_port1_o),                   // 立即数
    .aux_addr_port0_i(id_rn_aux_addr_port0_o),              // Auxiliary Address（辅助地址）
    .aux_addr_port1_i(id_rn_aux_addr_port1_o),              // Auxiliary Address（辅助地址）
    .bpu_pre_flag_port0_i(id_rn_bpu_pre_flag_port0_o),                 // 预测标志
    .bpu_pre_flag_port1_i(id_rn_bpu_pre_flag_port1_o),                 // 预测标志
    .bpu_pre_addr_port0_i(id_rn_bpu_pre_addr_port0_o),          // 预测地址
    .bpu_pre_addr_port1_i(id_rn_bpu_pre_addr_port1_o),          // 预测地址
    // from rename
    .praddr1_inst0_i(rn_praddr1_inst0_o),        // 指令0物理寄存器1读地址
    .praddr2_inst0_i(rn_praddr2_inst0_o),        // 指令0物理寄存器2读地址
    .praddr1_inst1_i(rn_praddr1_inst1_o),        // 指令1物理寄存器1读地址
    .praddr2_inst1_i(rn_praddr2_inst1_o),        // 指令1物理寄存器2读地址
    .pwaddr_inst0_i(rn_pwaddr_inst0_o),         // 指令0物理寄存器写地址
    .pwaddr_inst1_i(rn_pwaddr_inst1_o),         // 指令1物理寄存器写地址
    .branch_mask_inst0_i(rn_branch_mask_inst0_o),    // 指令0分支掩码
    .branch_mask_inst1_i(rn_branch_mask_inst1_o),    // 指令1分支掩码
    .old_paddr_inst0_i(rn_old_paddr_inst0_o),      // 指令0旧的物理寄存器映射
    .old_paddr_inst1_i(rn_old_paddr_inst1_o),      // 指令1旧的物理寄存器映射
    .snap_id_inst0_i(rn_snap_id_inst0_o),         // 指令0快照id
    .snap_id_inst1_i(rn_snap_id_inst1_o),         // 指令1快照id
    // from ctrl
    .int_flag_i(int_flag_i),                          // 中断标志
    .jump_flag_i(jump_flag_i),                         // 执行确认阶段跳转标志
    .dp_stall_flag_i(stall_flag_i),                     // RS/ROB满暂停
    .rn_stall_flag_i(rn_stall_o),                     // 重命名阶段暂停
    // from commit
    .free_mask_inst0_i(free_snap_flag_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_snap_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_snap_flag_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_snap_id_inst1_i),               // 指令1释放id
    // to dispatch
    .ras_snap_ptr_o(rn_dp_ras_snap_ptr_o),                 // RAS快照指针
    .inst_addr_o(rn_dp_inst_addr_o),                   // 指令地址
    .inst_type_port0_o(rn_dp_inst_type_port0_o),              // 指令类型
    .inst_type_port1_o(rn_dp_inst_type_port1_o),              // 指令类型
    .inst_subtype_port0_o(rn_dp_inst_subtype_port0_o),           // 指令子类型
    .inst_subtype_port1_o(rn_dp_inst_subtype_port1_o),           // 指令子类型
    .op1_src_port0_o(rn_dp_op1_src_port0_o),                // 操作数1来源选择
    .op1_src_port1_o(rn_dp_op1_src_port1_o),                // 操作数1来源选择
    .op2_src_port0_o(rn_dp_op2_src_port0_o),                // 操作数2来源选择
    .op2_src_port1_o(rn_dp_op2_src_port1_o),                // 操作数2来源选择
    .csr_addr_port0_o(rn_dp_csr_addr_port0_o),              // CSR寄存器地址
    .csr_addr_port1_o(rn_dp_csr_addr_port1_o),              // CSR寄存器地址
    .csr_wflag_port0_o(rn_dp_csr_wflag_port0_o),                    // CSR寄存器写使能
    .csr_wflag_port1_o(rn_dp_csr_wflag_port1_o),                    // CSR寄存器写使能
    .reg_wflag_port0_o(rn_dp_reg_wflag_port0_o),                    // 通用寄存器写使能
    .reg_wflag_port1_o(rn_dp_reg_wflag_port1_o),                    // 通用寄存器写使能
    .reg_waddr_port0_o(rn_dp_reg_waddr_port0_o),              // 写通用寄存器地址
    .reg_waddr_port1_o(rn_dp_reg_waddr_port1_o),              // 写通用寄存器地址
    .inst_valid_port0_o(rn_dp_inst_valid_port0_o),                   // 指令有效标志
    .inst_valid_port1_o(rn_dp_inst_valid_port1_o),                   // 指令有效标志
    .imm_port0_o(rn_dp_imm_port0_o),                   // 立即数
    .imm_port1_o(rn_dp_imm_port1_o),                   // 立即数
    .aux_addr_port0_o(rn_dp_aux_addr_port0_o),              // Auxiliary Address（辅助地址）
    .aux_addr_port1_o(rn_dp_aux_addr_port1_o),              // Auxiliary Address（辅助地址）
    .bpu_pre_flag_port0_o(rn_dp_bpu_pre_flag_port0_o),                 // 预测标志
    .bpu_pre_flag_port1_o(rn_dp_bpu_pre_flag_port1_o),                 // 预测标志
    .bpu_pre_addr_port0_o(rn_dp_bpu_pre_addr_port0_o),          // 预测地址
    .bpu_pre_addr_port1_o(rn_dp_bpu_pre_addr_port1_o),          // 预测地址
    .praddr1_inst0_o(rn_dp_praddr1_inst0_o),                // 指令0物理寄存器1读地址
    .praddr2_inst0_o(rn_dp_praddr2_inst0_o),                // 指令0物理寄存器2读地址
    .praddr1_inst1_o(rn_dp_praddr1_inst1_o),                // 指令1物理寄存器1读地址
    .praddr2_inst1_o(rn_dp_praddr2_inst1_o),                // 指令1物理寄存器2读地址
    .pwaddr_inst0_o(rn_dp_pwaddr_inst0_o),                 // 指令0物理寄存器写地址
    .pwaddr_inst1_o(rn_dp_pwaddr_inst1_o),                 // 指令1物理寄存器写地址
    .branch_mask_inst0_o(rn_dp_branch_mask_inst0_o),            // 指令0分支掩码
    .branch_mask_inst1_o(rn_dp_branch_mask_inst1_o),            // 指令1分支掩码
    .old_paddr_inst0_o(rn_dp_old_paddr_inst0_o),              // 指令0旧的物理寄存器映射
    .old_paddr_inst1_o(rn_dp_old_paddr_inst1_o),              // 指令1旧的物理寄存器映射
    .snap_id_inst0_o(rn_dp_snap_id_inst0_o),                // 指令0快照id
    .snap_id_inst1_o(rn_dp_snap_id_inst1_o)                 // 指令1快照id
);




endmodule