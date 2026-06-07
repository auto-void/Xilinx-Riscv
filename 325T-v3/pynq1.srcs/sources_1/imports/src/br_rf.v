`include "defines.vh"

`timescale 1ns / 1ps

module br_rf (
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

    // from br_flush
    input jump_flag_i,                  // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id

    // to regs
    output [5:0] rf_raddr1_o,           // RF 阶段读寄存器1地址（同时传到转发模块）
    output [5:0] rf_raddr2_o,           // RF 阶段读寄存器2地址（同时传到转发模块）
    output rf_wflag_o,                  // RF 阶段写寄存器标志
    output [5:0] rf_waddr_o,            // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)

    // to ex
    output br_inst_valid_o,              // branch指令有效标志
    output [15:0] br_inst_addr_o,        // branch指令地址
    output [5:0] br_rob_id_o,            // branch ROB id
    output br_bpu_pre_flag_o,            // branch BPU预测标志
    output [31:0] br_bpu_pre_addr_o,     // branch BPU预测地址
    output [3:0] br_mask_o,              // branch分支掩码
    output [2:0] br_ras_ptr_o,           // branch RAS快照指针
    output [2:0] br_mem_wr_ptr_o,        // branch mem队列写操作快照指针
    output [2:0] br_sq_ptr_o,            // branch store queue快照指针
    output [1:0] br_snap_id_o,           // branch快照id
    output [2:0] br_type_o,              // branch指令类型
    output [3:0] br_subtype_o,           // branch指令子类型
    output [31:0] br_rs1_data_o,         // rs1数据
    output [31:0] br_rs2_data_o,         // rs2数据
    output [31:0] br_imm_o,              // branch立即数
    output [31:0] br_aux_addr_o          // branch辅助地址

);
// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
assign br_inst_valid_o = br_inst_valid_i && ((br_mask_i & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效
// 读寄存器文件
assign rf_raddr1_o = br_praddr1_i;
assign rf_raddr2_o = br_praddr2_i;
// 写寄存器文件ready信号
assign rf_wflag_o = br_inst_valid_i && (br_type_i == `TYPE_JAL); // 只有 JAL/JALR 指令需要写回寄存器
assign rf_waddr_o = br_pwaddr_i;
// 输出到执行阶段
assign br_inst_addr_o = br_inst_addr_i;
assign br_rob_id_o = br_rob_id_i;
assign br_bpu_pre_flag_o = br_bpu_pre_flag_i;
assign br_bpu_pre_addr_o = br_bpu_pre_addr_i;
assign br_mask_o = br_mask_i;
assign br_ras_ptr_o = br_ras_ptr_i;
assign br_mem_wr_ptr_o = br_mem_wr_ptr_i;
assign br_sq_ptr_o = br_sq_ptr_i;
assign br_snap_id_o = br_snap_id_i;
assign br_type_o = br_type_i;
assign br_subtype_o = br_subtype_i;
assign br_rs1_data_o = rs1_forward_flag_i ? rs1_forward_data_i : reg_rdata1_i; // 转发优先级高于寄存器文件
assign br_rs2_data_o = rs2_forward_flag_i ? rs2_forward_data_i : reg_rdata2_i;
assign br_imm_o = br_imm_i;
assign br_aux_addr_o = br_aux_addr_i;


endmodule