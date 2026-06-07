`include "defines.vh"

`timescale 1ns / 1ps

// 取指单元
module IFU(
    input clk,
    input rst,

    // pc_reg
    input jump_flag_i,
    input [31:0] jump_addr_i,
    input int_flag_i,
    input [31:0] int_addr_i,
    input stall_flag_i,           // RS/ROB满，暂停前端
    input jal_flush_i,
    input [31:0] jal_addr_i,
    input [31:0] ras_pre_addr_i,
    input bpu_pre_flag_i,
    input [31:0] bpu_pre_addr_i,
    output [31:0] pc_o,

    // IF_Stage1
    input bpu_jump_odd_i,
    // input [63:0] rom_inst_i,

    // icache
    input [255:0] icache_line_i,

    // if_stage2
    input [2:0] ras_snap_ptr_i,    // RAS快照指针
    output ras_pop_flag_o,
    output ras_push_flag_o,
    output [31:0] ras_push_data_o,

    // if_id
    output [2:0] if_id_ras_snap_ptr_o,
    output if_id_inst_valid_port0_o,
    output if_id_inst_valid_port1_o,
    output [31:0] if_id_inst_port0_o,
    output [31:0] if_id_inst_port1_o,
    output [31:0] if_id_inst_addr_o,
    output [31:0] if_id_imm_port0_o,
    output [31:0] if_id_imm_port1_o,
    output if_id_bpu_pre_flag_port0_o,
    output if_id_bpu_pre_flag_port1_o,
    output [31:0] if_id_bpu_pre_addr_port0_o,
    output [31:0] if_id_bpu_pre_addr_port1_o
);

// icache
wire [63:0] icache_inst_o;
wire icache_miss;
wire icache_miss_hold;

// IF_Stage1
wire [63:0] if_stage1_inst_o;
wire [31:0] if_stage1_inst_addr_o;
wire bpu_pre_flag_o;
wire bpu_jump_odd_o;
wire [31:0] bpu_pre_addr_o;

// if_stage1_stage2
wire if_stage1_stage2_inst_valid_o;
wire [63:0] if_stage1_stage2_inst_o;
wire [31:0] if_stage1_stage2_inst_addr_o;
wire if_stage1_stage2_bpu_pre_flag_o;
wire if_stage1_stage2_bpu_jump_odd_o;
wire [31:0] if_stage1_stage2_bpu_pre_addr_o;

// if_stage2
wire if_stage2_ras_pre_flag_o;
wire [2:0] if_stage2_ras_snap_ptr_o;
wire if_stage2_inst_valid_port0_o;
wire if_stage2_inst_valid_port1_o;
wire [31:0] if_stage2_inst_port0_o;
wire [31:0] if_stage2_inst_port1_o;
wire [31:0] if_stage2_inst_addr_o;
wire [31:0] if_stage2_imm_port0_o;
wire [31:0] if_stage2_imm_port1_o;
wire if_stage2_bpu_pre_flag_port0_o;
wire if_stage2_bpu_pre_flag_port1_o;
wire [31:0] if_stage2_bpu_pre_addr_port0_o;
wire [31:0] if_stage2_bpu_pre_addr_port1_o;


// 实例化
// pc_reg
pc_reg u_pc_reg(
    .clk                (clk),
    .rst                (rst),
    // from ex
    .jump_flag_i       (jump_flag_i),
    .jump_addr_i       (jump_addr_i),
    .hold_flag_i       (icache_miss_hold),
    // from clint
    .int_flag_i        (int_flag_i),
    .int_addr_i        (int_addr_i),
    // from dispatch
    .stall_flag_i      (stall_flag_i),
    // from id
    .jal_flush_i       (jal_flush_i),
    .jal_addr_i        (jal_addr_i),
    // from if_stage2
    .ras_pre_flag_i    (if_stage2_ras_pre_flag_o),
    // from RAS
    .ras_pre_addr_i    (ras_pre_addr_i),
    // from BPU
    .bpu_pre_flag_i    (bpu_pre_flag_i),
    .bpu_pre_addr_i    (bpu_pre_addr_i),
    // to if
    .pc_o              (pc_o)
);

// icache
icache u_icache(
    .clk                (clk),
    .rst                (rst),
    // from if_stage1
    .pc                 (pc_o),                 // 指令地址
    // from irom
    .cache_line         (icache_line_i),         // 一行指令数据
    // to if_stage1
    .inst_o             (icache_inst_o),             // 指令内容
    .miss_hold          (icache_miss_hold),             // 未命中暂停信号
    .cache_miss         (icache_miss)                // 缓存未命中
);

// IF_Stage1
reg [63:0] rom_inst_i;
always @(*) begin
    case (pc_o[4:3])
        2'b00: rom_inst_i = icache_line_i[63:0];
        2'b01: rom_inst_i = icache_line_i[127:64];
        2'b10: rom_inst_i = icache_line_i[191:128];
        2'b11: rom_inst_i = icache_line_i[255:192];
    endcase
end
IF_Stage1 u_if_stage1(
    // from pc
    .pc_addr_i          (pc_o),          // 指令地址
    // from icache
    .cache_miss         (icache_miss),                // 缓存未命中
    .cache_inst_i       (icache_inst_o),       // 指令内容
    // from rom
    .rom_inst_i         (rom_inst_i),         // 指令内容
    // from BPU
    .bpu_pre_flag_i     (bpu_pre_flag_i),            // 预测跳转标志
    .bpu_jump_odd_i     (bpu_jump_odd_i),             // 跳转奇偶标志
    .bpu_pre_addr_i     (bpu_pre_addr_i),      // 预测跳转地址
    // to IF_Stage2
    .inst_o             (if_stage1_inst_o),             // 指令内容
    .inst_addr_o        (if_stage1_inst_addr_o),        // 指令地址
    .bpu_pre_flag_o     (bpu_pre_flag_o),           // 传给IF_Stage2的预测跳转标志
    .bpu_jump_odd_o     (bpu_jump_odd_o),            // 传给IF_Stage2的跳转奇偶标志
    .bpu_pre_addr_o     (bpu_pre_addr_o)      // 传给IF_Stage2的预测跳转地址
);

// if_stage1_stage2
if_stage1_stage2 u_if_stage1_stage2(
    .clk                (clk),
    .rst                (rst),
    // from IF_Stage1
    .inst_i             (if_stage1_inst_o),
    .inst_addr_i        (if_stage1_inst_addr_o),
    .bpu_pre_flag_i     (bpu_pre_flag_o),
    .bpu_jump_odd_i     (bpu_jump_odd_o),
    .bpu_pre_addr_i     (bpu_pre_addr_o),
    // from ctrl
    .int_flag_i         (int_flag_i),         // 中断
    .hold_flag_i        (icache_miss_hold),   // icache miss暂停
    .jump_flag_i        (jump_flag_i),        // 执行确认阶段冲刷
    .stall_flag_i       (stall_flag_i),       // RS/ROB满暂停
    .jal_flush_i        (jal_flush_i),        // jal指令冲刷
    .ras_pre_flag_i     (if_stage2_ras_pre_flag_o),     // RAS分支预测
    // to IF_Stage2
    .inst_valid_o       (if_stage1_stage2_inst_valid_o),
    .inst_o             (if_stage1_stage2_inst_o),
    .inst_addr_o        (if_stage1_stage2_inst_addr_o),
    .bpu_pre_flag_o     (if_stage1_stage2_bpu_pre_flag_o),
    .bpu_jump_odd_o     (if_stage1_stage2_bpu_jump_odd_o),
    .bpu_pre_addr_o     (if_stage1_stage2_bpu_pre_addr_o)
);

// if_stage2
IF_Stage2 u_if_stage2(
    .clk                  (clk),
    .rst                  (rst),
    // from IF_Stage1
    .inst_valid_i         (if_stage1_stage2_inst_valid_o),
    .inst_i               (if_stage1_stage2_inst_o),
    .inst_addr_i          (if_stage1_stage2_inst_addr_o),
    .bpu_pre_flag_i       (if_stage1_stage2_bpu_pre_flag_o),
    .bpu_jump_odd_i       (if_stage1_stage2_bpu_jump_odd_o),
    .bpu_pre_addr_i       (if_stage1_stage2_bpu_pre_addr_o),
    // to PC
    .ras_pre_flag_o       (if_stage2_ras_pre_flag_o),
    // from RAS
    .ras_snap_ptr_i       (ras_snap_ptr_i),    // RAS快照指针
    .ras_pop_data_i       (ras_pre_addr_i),    // RAS弹栈数据
    // to RAS
    .ras_pop_flag_o       (ras_pop_flag_o),
    .ras_push_flag_o      (ras_push_flag_o),
    .ras_push_data_o      (ras_push_data_o),
    // to id
    .ras_snap_ptr_o       (if_stage2_ras_snap_ptr_o),
    .inst_valid_port0_o   (if_stage2_inst_valid_port0_o),     // 指令有效标志
    .inst_valid_port1_o   (if_stage2_inst_valid_port1_o),
    .inst_port0_o         (if_stage2_inst_port0_o),           // 指令内容
    .inst_port1_o         (if_stage2_inst_port1_o),
    .inst_addr_o          (if_stage2_inst_addr_o),
    .imm_port0_o          (if_stage2_imm_port0_o),
    .imm_port1_o          (if_stage2_imm_port1_o),
    .bpu_pre_flag_port0_o (if_stage2_bpu_pre_flag_port0_o),
    .bpu_pre_flag_port1_o (if_stage2_bpu_pre_flag_port1_o),
    .bpu_pre_addr_port0_o (if_stage2_bpu_pre_addr_port0_o),
    .bpu_pre_addr_port1_o (if_stage2_bpu_pre_addr_port1_o)
);

// if_id
if_id u_if_id(
    .clk(clk),
    .rst(rst),
    // from if_stage2
    .ras_snap_ptr_i(if_stage2_ras_snap_ptr_o),
    .inst_valid_port0_i(if_stage2_inst_valid_port0_o),     // 指令有效标志
    .inst_valid_port1_i(if_stage2_inst_valid_port1_o),
    .inst_port0_i(if_stage2_inst_port0_o),    // 指令内容
    .inst_port1_i(if_stage2_inst_port1_o),
    .inst_addr_i(if_stage2_inst_addr_o),
    .imm_port0_i(if_stage2_imm_port0_o),
    .imm_port1_i(if_stage2_imm_port1_o),
    .bpu_pre_flag_port0_i(if_stage2_bpu_pre_flag_port0_o),
    .bpu_pre_flag_port1_i(if_stage2_bpu_pre_flag_port1_o),
    .bpu_pre_addr_port0_i(if_stage2_bpu_pre_addr_port0_o),
    .bpu_pre_addr_port1_i(if_stage2_bpu_pre_addr_port1_o),
    // from id
    .jal_flush_i(jal_flush_i),                 // jal指令冲刷
    // from Ctrl
    .jump_flag_i(jump_flag_i),                 // 执行确认阶段跳转标志
    .stall_flag_i(stall_flag_i),                // RS/ROB满暂停
    // from clint
    .int_flag_i(int_flag_i),
    // to id
    .ras_snap_ptr_o(if_id_ras_snap_ptr_o),
    .inst_valid_port0_o(if_id_inst_valid_port0_o),     // 指令有效标志
    .inst_valid_port1_o(if_id_inst_valid_port1_o),
    .inst_port0_o(if_id_inst_port0_o),    // 指令内容
    .inst_port1_o(if_id_inst_port1_o),
    .inst_addr_o(if_id_inst_addr_o),
    .imm_port0_o(if_id_imm_port0_o),
    .imm_port1_o(if_id_imm_port1_o),
    .bpu_pre_flag_port0_o(if_id_bpu_pre_flag_port0_o),
    .bpu_pre_flag_port1_o(if_id_bpu_pre_flag_port1_o),
    .bpu_pre_addr_port0_o(if_id_bpu_pre_addr_port0_o),
    .bpu_pre_addr_port1_o(if_id_bpu_pre_addr_port1_o)
);




endmodule