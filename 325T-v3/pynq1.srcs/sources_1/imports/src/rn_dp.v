`include "defines.vh"

`timescale 1ns / 1ps

module rn_dp (
    input clk,
    input rst,

    // from id
    input [2:0] ras_snap_ptr_i,                 // RAS快照指针
    input [31:0] inst_addr_i,                   // 指令地址
    input [2:0] inst_type_port0_i,              // 指令类型
    input [2:0] inst_type_port1_i,              // 指令类型
    input [3:0] inst_subtype_port0_i,           // 指令子类型
    input [3:0] inst_subtype_port1_i,           // 指令子类型
    input [1:0] op1_src_port0_i,                // 操作数1来源选择
    input [1:0] op1_src_port1_i,                // 操作数1来源选择
    input [1:0] op2_src_port0_i,                // 操作数2来源选择
    input [1:0] op2_src_port1_i,                // 操作数2来源选择
    input [11:0] csr_addr_port0_i,              // CSR寄存器地址
    input [11:0] csr_addr_port1_i,              // CSR寄存器地址
    input csr_wflag_port0_i,                    // CSR寄存器写使能
    input csr_wflag_port1_i,                    // CSR寄存器写使能
    input reg_wflag_port0_i,                    // 通用寄存器写使能
    input reg_wflag_port1_i,                    // 通用寄存器写使能
    input [4:0] reg_waddr_port0_i,              // 写通用寄存器地址
    input [4:0] reg_waddr_port1_i,              // 写通用寄存器地址
    input inst_valid_port0_i,                   // 指令有效标志
    input inst_valid_port1_i,                   // 指令有效标志
    input [31:0] imm_port0_i,                   // 立即数
    input [31:0] imm_port1_i,                   // 立即数
    input [31:0] aux_addr_port0_i,              // Auxiliary Address（辅助地址）
    input [31:0] aux_addr_port1_i,              // Auxiliary Address（辅助地址）
    input bpu_pre_flag_port0_i,                 // 预测标志
    input bpu_pre_flag_port1_i,                 // 预测标志
    input [31:0] bpu_pre_addr_port0_i,          // 预测地址
    input [31:0] bpu_pre_addr_port1_i,          // 预测地址
    // from rename
    input [5:0] praddr1_inst0_i,        // 指令0物理寄存器1读地址
    input [5:0] praddr2_inst0_i,        // 指令0物理寄存器2读地址
    input [5:0] praddr1_inst1_i,        // 指令1物理寄存器1读地址
    input [5:0] praddr2_inst1_i,        // 指令1物理寄存器2读地址
    input [5:0] pwaddr_inst0_i,         // 指令0物理寄存器写地址
    input [5:0] pwaddr_inst1_i,         // 指令1物理寄存器写地址
    input [3:0] branch_mask_inst0_i,    // 指令0分支掩码
    input [3:0] branch_mask_inst1_i,    // 指令1分支掩码
    input [5:0] old_paddr_inst0_i,      // 指令0旧的物理寄存器映射
    input [5:0] old_paddr_inst1_i,      // 指令1旧的物理寄存器映射
    input [1:0] snap_id_inst0_i,         // 指令0快照id
    input [1:0] snap_id_inst1_i,         // 指令1快照id
    
    // from ctrl
    input int_flag_i,                          // 中断标志
    input jump_flag_i,                         // 执行确认阶段跳转标志
    input dp_stall_flag_i,                     // RS/ROB满暂停
    input rn_stall_flag_i,                     // 重命名阶段暂停

    // from commit
    input free_mask_inst0_i,                   // 指令0释放掩码标志
    input [1:0] free_id_inst0_i,               // 指令0释放id
    input free_mask_inst1_i,                   // 指令1释放掩码标志
    input [1:0] free_id_inst1_i,               // 指令1释放id

    // to dispatch
    output reg [2:0] ras_snap_ptr_o,                 // RAS快照指针
    output reg [31:0] inst_addr_o,                   // 指令地址
    output reg [2:0] inst_type_port0_o,              // 指令类型
    output reg [2:0] inst_type_port1_o,              // 指令类型
    output reg [3:0] inst_subtype_port0_o,           // 指令子类型
    output reg [3:0] inst_subtype_port1_o,           // 指令子类型
    output reg [1:0] op1_src_port0_o,                // 操作数1来源选择
    output reg [1:0] op1_src_port1_o,                // 操作数1来源选择
    output reg [1:0] op2_src_port0_o,                // 操作数2来源选择
    output reg [1:0] op2_src_port1_o,                // 操作数2来源选择
    output reg [11:0] csr_addr_port0_o,              // CSR寄存器地址
    output reg [11:0] csr_addr_port1_o,              // CSR寄存器地址
    output reg csr_wflag_port0_o,                    // CSR寄存器写使能
    output reg csr_wflag_port1_o,                    // CSR寄存器写使能
    output reg reg_wflag_port0_o,                    // 通用寄存器写使能
    output reg reg_wflag_port1_o,                    // 通用寄存器写使能
    output reg [4:0] reg_waddr_port0_o,              // 写通用寄存器地址
    output reg [4:0] reg_waddr_port1_o,              // 写通用寄存器地址
    output reg inst_valid_port0_o,                   // 指令有效标志
    output reg inst_valid_port1_o,                   // 指令有效标志
    output reg [31:0] imm_port0_o,                   // 立即数
    output reg [31:0] imm_port1_o,                   // 立即数
    output reg [31:0] aux_addr_port0_o,              // Auxiliary Address（辅助地址）
    output reg [31:0] aux_addr_port1_o,              // Auxiliary Address（辅助地址）
    output reg bpu_pre_flag_port0_o,                 // 预测标志
    output reg bpu_pre_flag_port1_o,                 // 预测标志
    output reg [31:0] bpu_pre_addr_port0_o,          // 预测地址
    output reg [31:0] bpu_pre_addr_port1_o,          // 预测地址
    output reg [5:0] praddr1_inst0_o,                // 指令0物理寄存器1读地址
    output reg [5:0] praddr2_inst0_o,                // 指令0物理寄存器2读地址
    output reg [5:0] praddr1_inst1_o,                // 指令1物理寄存器1读地址
    output reg [5:0] praddr2_inst1_o,                // 指令1物理寄存器2读地址
    output reg [5:0] pwaddr_inst0_o,                 // 指令0物理寄存器写地址
    output reg [5:0] pwaddr_inst1_o,                 // 指令1物理寄存器写地址
    output reg [3:0] branch_mask_inst0_o,            // 指令0分支掩码
    output reg [3:0] branch_mask_inst1_o,            // 指令1分支掩码
    output reg [5:0] old_paddr_inst0_o,              // 指令0旧的物理寄存器映射
    output reg [5:0] old_paddr_inst1_o,              // 指令1旧的物理寄存器映射
    output reg [1:0] snap_id_inst0_o,                // 指令0快照id
    output reg [1:0] snap_id_inst1_o                 // 指令1快照id
);

reg [3:0] next_mask_inst0;
reg [3:0] next_mask_inst1;
always @(*) begin
    next_mask_inst0 = branch_mask_inst0_o;
    next_mask_inst1 = branch_mask_inst1_o;
    if (free_mask_inst0_i) begin
        next_mask_inst0[free_id_inst0_i] = 1'b0;
        next_mask_inst1[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        next_mask_inst0[free_id_inst1_i] = 1'b0;
        next_mask_inst1[free_id_inst1_i] = 1'b0;
    end
end

always @(posedge clk) begin
    if (!rst) begin
        inst_valid_port0_o <= 1'b0;
        inst_valid_port1_o <= 1'b0;
    end
    else if (int_flag_i || jump_flag_i) begin
        inst_valid_port0_o <= 1'b0;
        inst_valid_port1_o <= 1'b0;
    end
    else if (dp_stall_flag_i) begin // 这个信号是来自RS/ROB的满标志，表示下游资源无法接受新的指令了，因此需要保持上一次输出不变尝试继续写入
        inst_valid_port0_o <= inst_valid_port0_o;
        inst_valid_port1_o <= inst_valid_port1_o;
    end
    else if (rn_stall_flag_i) begin // 前级暂停，流水线填气泡
        inst_valid_port0_o <= 1'b0;
        inst_valid_port1_o <= 1'b0;
    end
    else begin
        inst_valid_port0_o <= inst_valid_port0_i;
        inst_valid_port1_o <= inst_valid_port1_i;
    end
end

always @(posedge clk) begin
    if (!dp_stall_flag_i) begin
        branch_mask_inst0_o <= branch_mask_inst0_i;
        branch_mask_inst1_o <= branch_mask_inst1_i;
    end
    else begin
        branch_mask_inst0_o <= next_mask_inst0;
        branch_mask_inst1_o <= next_mask_inst1;
    end
end

// 数据通路
always @(posedge clk) begin
    if (!dp_stall_flag_i) begin
        ras_snap_ptr_o <= ras_snap_ptr_i;
        inst_addr_o <= inst_addr_i;
        inst_type_port0_o <= inst_type_port0_i;
        inst_type_port1_o <= inst_type_port1_i;
        inst_subtype_port0_o <= inst_subtype_port0_i;
        inst_subtype_port1_o <= inst_subtype_port1_i;
        op1_src_port0_o <= op1_src_port0_i;
        op1_src_port1_o <= op1_src_port1_i;
        op2_src_port0_o <= op2_src_port0_i;
        op2_src_port1_o <= op2_src_port1_i;
        csr_addr_port0_o <= csr_addr_port0_i;
        csr_addr_port1_o <= csr_addr_port1_i;
        csr_wflag_port0_o <= csr_wflag_port0_i;
        csr_wflag_port1_o <= csr_wflag_port1_i;
        reg_wflag_port0_o <= reg_wflag_port0_i;
        reg_wflag_port1_o <= reg_wflag_port1_i;
        reg_waddr_port0_o <= reg_waddr_port0_i;
        reg_waddr_port1_o <= reg_waddr_port1_i;
        imm_port0_o <= imm_port0_i;
        imm_port1_o <= imm_port1_i;
        aux_addr_port0_o <= aux_addr_port0_i;
        aux_addr_port1_o <= aux_addr_port1_i;
        bpu_pre_flag_port0_o <= bpu_pre_flag_port0_i;
        bpu_pre_flag_port1_o <= bpu_pre_flag_port1_i;
        bpu_pre_addr_port0_o <= bpu_pre_addr_port0_i;
        bpu_pre_addr_port1_o <= bpu_pre_addr_port1_i;
        praddr1_inst0_o <= praddr1_inst0_i;
        praddr2_inst0_o <= praddr2_inst0_i; 
        praddr1_inst1_o <= praddr1_inst1_i; 
        praddr2_inst1_o <= praddr2_inst1_i;
        pwaddr_inst0_o <= pwaddr_inst0_i;
        pwaddr_inst1_o <= pwaddr_inst1_i;
        old_paddr_inst0_o <= old_paddr_inst0_i;
        old_paddr_inst1_o <= old_paddr_inst1_i;
        snap_id_inst0_o <= snap_id_inst0_i;
        snap_id_inst1_o <= snap_id_inst1_i;
    end
end

endmodule