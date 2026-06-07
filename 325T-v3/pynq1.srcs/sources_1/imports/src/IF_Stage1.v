`include "defines.vh"

`timescale 1ns / 1ps

// 取指模块
module IF_Stage1(
    // from pc
    input [31:0] pc_addr_i,          // 指令地址
    // from icache
    input cache_miss,                // 缓存未命中
    input [63:0] cache_inst_i,       // 指令内容
    // from irom
    input [63:0] rom_inst_i,         // 指令内容

    // from BPU
    input bpu_pre_flag_i,             // 预测跳转标志
    input bpu_jump_odd_i,             // 跳转奇偶标志
    input [31:0] bpu_pre_addr_i,      // 预测跳转地址

    // to IF_Stage2
    output [63:0] inst_o,             // 指令内容
    output [31:0] inst_addr_o,        // 指令地址
    output bpu_pre_flag_o,            // 传给IF_Stage2的预测跳转标志
    output bpu_jump_odd_o,            // 传给IF_Stage2的跳转奇偶标志
    output [31:0] bpu_pre_addr_o      // 传给IF_Stage2的预测跳转地址

);

assign inst_addr_o = pc_addr_i;      
assign inst_o = cache_miss ? rom_inst_i : cache_inst_i;          
assign bpu_pre_flag_o = bpu_pre_flag_i;
assign bpu_jump_odd_o = bpu_jump_odd_i;
assign bpu_pre_addr_o = bpu_pre_addr_i;



endmodule