`include "defines.vh"

`timescale 1ns / 1ps

module iss_mem (
    input clk,
    input rst,

    // from issue
    input int_flag_i,                 // 中断标志
    input flush_flag_i,               // 冲刷标志
    input mem_stall_i,                // 访存暂停标志
    input issue_flag_i,               // 发射标志
    input [5:0] rob_id_i,             // ROB id
    input [3:0] mask_i,               // 分支掩码
    input [1:0] sq_id_i,              // SQ id
    input [3:0] subtype_i,            // 指令子类型
    input [1:0] op1_src_i,            // 操作数1来源选择
    input [1:0] op2_src_i,            // 操作数2来源选择
    input [5:0] praddr1_i,            // 物理寄存器1读地址
    input [5:0] praddr2_i,            // 物理寄存器2读地址
    input [5:0] pwaddr_i,             // 物理寄存器写地址
    input [31:0] imm_i,               // 立即数

    // from commit
    input free_mask_inst0_i,                   // 指令0释放掩码标志
    input [1:0] free_id_inst0_i,               // 指令0释放id
    input free_mask_inst1_i,                   // 指令1释放掩码标志
    input [1:0] free_id_inst1_i,               // 指令1释放id

    // from branch
    input jump_flag_i,                      // 跳转标志
    input [1:0] kill_mask_id_i,             // 杀死指令掩码id

    // to ex
    output reg inst_valid_o,          // 指令有效标志
    output reg [5:0] rob_id_o,        // ROB id
    output reg [3:0] mask_o,          // 分支掩码
    output reg [1:0] sq_id_o,         // SQ id
    output reg [3:0] subtype_o,       // 指令子类型
    output reg [1:0] op1_src_o,       // 操作数1
    output reg [1:0] op2_src_o,       // 操作数2
    output reg [5:0] praddr1_o,       // 物理寄存器1读地址
    output reg [5:0] praddr2_o,       // 物理寄存器2读地址
    output reg [5:0] pwaddr_o,        // 物理寄存器写地址
    output reg [31:0] imm_o           // 立即数

);

reg [3:0] next_mask;
always @(*) begin
    next_mask = mask_o;
    if (free_mask_inst0_i) begin
        next_mask[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        next_mask[free_id_inst1_i] = 1'b0;
    end
end

wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
wire next_valid = inst_valid_o && ((mask_o & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效

always @(posedge clk) begin
    if (!rst) begin
        inst_valid_o <= 1'b0;
        pwaddr_o <= 6'b0;
    end
    else if (int_flag_i) begin
        inst_valid_o <= 1'b0;
        pwaddr_o <= 6'b0;
    end
    else if (issue_flag_i) begin
        inst_valid_o <= 1'b1;
        pwaddr_o <= pwaddr_i;
    end
    else if (flush_flag_i) begin
        inst_valid_o <= 1'b0;
        pwaddr_o <= 6'b0;
    end
    else if (mem_stall_i) begin
        inst_valid_o <= next_valid;
        pwaddr_o     <= next_valid ? pwaddr_o : 6'd0;
    end
    else begin
        inst_valid_o <= 1'b0; // 非发射周期，也没有stall时指令无效
        pwaddr_o <= 6'b0;
    end
end

// 动态状态（伴随stall期间更新）
always @(posedge clk) begin
    if (issue_flag_i) begin
        mask_o <= mask_i;
    end
    else if (mem_stall_i) begin
        mask_o <= next_mask; // 在暂停期间允许被动态修改
    end
end

// 数据通路，仅在发射时更新
always @(posedge clk) begin
    if (issue_flag_i) begin
        rob_id_o <= rob_id_i;
        sq_id_o <= sq_id_i;
        subtype_o <= subtype_i;
        op1_src_o <= op1_src_i;
        op2_src_o <= op2_src_i;
        praddr1_o <= praddr1_i;
        praddr2_o <= praddr2_i;
        imm_o <= imm_i;
    end
end

endmodule