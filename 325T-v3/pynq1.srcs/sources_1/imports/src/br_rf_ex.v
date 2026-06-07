`include "defines.vh"

`timescale 1ns / 1ps

module br_rf_ex (
    input clk,
    input rst,

    // from RF
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
    input [31:0] br_rs1_data_i,         // rs1数据
    input [31:0] br_rs2_data_i,         // rs2数据
    input [5:0] br_waddr_i,             // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)
    input [31:0] br_imm_i,              // branch立即数
    input [31:0] br_aux_addr_i,         // branch辅助地址

    // from clint
    input int_flag_i,                   // 中断标志

    // to ex
    output reg br_inst_valid_o,              // branch指令有效标志
    output reg [15:0] br_inst_addr_o,        // branch指令地址
    output reg [5:0] br_rob_id_o,            // branch ROB id
    output reg br_bpu_pre_flag_o,            // branch BPU预测标志
    output reg [31:0] br_bpu_pre_addr_o,     // branch BPU预测地址
    output reg [3:0] br_mask_o,              // branch分支掩码
    output reg [2:0] br_ras_ptr_o,           // branch RAS快照指针
    output reg [2:0] br_mem_wr_ptr_o,        // branch mem队列写操作快照指针
    output reg [2:0] br_sq_ptr_o,            // branch store queue快照指针
    output reg [1:0] br_snap_id_o,           // branch快照id
    output reg [2:0] br_type_o,              // branch指令类型
    output reg [3:0] br_subtype_o,           // branch指令子类型
    output reg [31:0] br_rs1_data_o,         // rs1数据
    output reg [31:0] br_rs2_data_o,         // rs2数据
    output reg [5:0] br_waddr_o,             // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)
    output reg [31:0] br_imm_o,              // branch立即数
    output reg [31:0] br_aux_addr_o          // branch辅助地址
);

always @(posedge clk) begin
    if (!rst) begin
        br_inst_valid_o <= 1'b0;
    end
    else if (int_flag_i) begin
        br_inst_valid_o <= 1'b0;
    end
    else begin
        br_inst_valid_o <= br_inst_valid_i;
    end
end

always @(posedge clk) begin
    br_inst_addr_o <= br_inst_addr_i;
    br_rob_id_o <= br_rob_id_i;
    br_bpu_pre_flag_o <= br_bpu_pre_flag_i;
    br_bpu_pre_addr_o <= br_bpu_pre_addr_i;
    br_mask_o <= br_mask_i;
    br_ras_ptr_o <= br_ras_ptr_i;
    br_mem_wr_ptr_o <= br_mem_wr_ptr_i;
    br_sq_ptr_o <= br_sq_ptr_i;
    br_snap_id_o <= br_snap_id_i;
    br_type_o <= br_type_i;
    br_subtype_o <= br_subtype_i;
    br_rs1_data_o <= br_rs1_data_i;
    br_rs2_data_o <= br_rs2_data_i;
    br_waddr_o <= br_waddr_i;
    br_imm_o <= br_imm_i;
    br_aux_addr_o <= br_aux_addr_i;
end



endmodule