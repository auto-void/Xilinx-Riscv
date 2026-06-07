`include "defines.vh"

`timescale 1ns / 1ps

module iss_br (
    input clk,
    input rst,

    // from issue
    input int_flag_i,                 // 中断标志
    input issue_flag_i,               // 发射标志
    input [15:0] inst_addr_i,         // 指令地址
    input [5:0] rob_id_i,             // ROB id
    input bpu_pre_flag_i,             // BPU预测标志
    input [31:0] bpu_pre_addr_i,      // BPU预测地址
    input [3:0] mask_i,               // 分支掩码
    input [2:0] ras_ptr_i,            // RAS快照指针
    input [2:0] mem_wr_ptr_i,         // mem队列写操作快照指针
    input [2:0] sq_ptr_i,             // store queue快照指针
    input [1:0] snap_id_i,            // 快照id
    input [2:0] type_i,               // 指令类型
    input [3:0] subtype_i,            // 指令子类型
    input [1:0] op1_src_i,            // 操作数1来源选择
    input [1:0] op2_src_i,            // 操作数2来源选择
    input [5:0] praddr1_i,            // 物理寄存器1读地址
    input [5:0] praddr2_i,            // 物理寄存器2读地址
    input [5:0] pwaddr_i,             // 物理寄存器写地址
    input [31:0] imm_i,               // 立即数
    input [31:0] aux_addr_i,          // 辅助地址

    // to ex
    output reg inst_valid_o,          // 指令有效标志
    output reg [15:0] inst_addr_o,    // 指令地址
    output reg [5:0] rob_id_o,        // ROB id
    output reg bpu_pre_flag_o,        // BPU预测标志
    output reg [31:0] bpu_pre_addr_o, // BPU预测地址
    output reg [3:0] mask_o,          // 分支掩码
    output reg [2:0] ras_ptr_o,       // RAS快照指针
    output reg [2:0] mem_wr_ptr_o,    // mem队列写操作快照指针
    output reg [2:0] sq_ptr_o,        // store queue快照指针
    output reg [1:0] snap_id_o,       // 快照id
    output reg [2:0] type_o,          // 指令类型
    output reg [3:0] subtype_o,       // 指令子类型
    output reg [1:0] op1_src_o,       // 操作数1
    output reg [1:0] op2_src_o,       // 操作数2
    output reg [5:0] praddr1_o,       // 物理寄存器1读地址
    output reg [5:0] praddr2_o,       // 物理寄存器2读地址
    output reg [5:0] pwaddr_o,        // 物理寄存器写地址
    output reg [31:0] imm_o,          // 立即数
    output reg [31:0] aux_addr_o      // 辅助地址

);

always @(posedge clk) begin
    if (!rst) begin
        inst_valid_o <= 1'b0;
    end
    else if (int_flag_i) begin
        inst_valid_o <= 1'b0;
    end
    else if (issue_flag_i) begin
        inst_valid_o <= 1'b1;
    end
    else begin
        inst_valid_o <= 1'b0; // 非发射周期指令无效
    end
end

always @(posedge clk) begin
    inst_addr_o <= inst_addr_i;
    rob_id_o <= rob_id_i;
    bpu_pre_flag_o <= bpu_pre_flag_i;
    bpu_pre_addr_o <= bpu_pre_addr_i;
    mask_o <= mask_i;
    ras_ptr_o <= ras_ptr_i;
    mem_wr_ptr_o <= mem_wr_ptr_i;
    sq_ptr_o <= sq_ptr_i;
    snap_id_o <= snap_id_i;
    type_o <= type_i;
    subtype_o <= subtype_i;
    op1_src_o <= op1_src_i;
    op2_src_o <= op2_src_i;
    praddr1_o <= praddr1_i;
    praddr2_o <= praddr2_i;
    pwaddr_o <= pwaddr_i;
    imm_o <= imm_i;
    aux_addr_o <= aux_addr_i;
end

endmodule