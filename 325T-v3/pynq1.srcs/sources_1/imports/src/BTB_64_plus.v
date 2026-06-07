`include "defines.vh"

`timescale 1ns / 1ps

// 分支目标缓冲区，用于预测跳转地址
module BTB_64_plus (
    input clk,
    input rst,

    // from IF
    input [31:0] pc,            // 取指阶段PC地址

    // from ex
    input update_en,                        // 执行阶段更新BTB使能
    input [31:0] jump_target,               // 实际跳转目标地址
    input [15:0] ex_pc,                     // 执行阶段的pc
    input is_branch,                        // 是否为分支指令

    // to PC
    output [41:0] pre_port0,     
    output [41:0] pre_port1      

);
// 取指阶段进行预测
// localparam WIDTH = 6;
// wire [WIDTH-1:0] pc_index;      // pc低位作为索引
// assign pc_index = pc[WIDTH+1:2];

// 执行阶段更新BTB
// wire [WIDTH-1:0] ex_pc_index;      // 执行阶段pc索引
// assign ex_pc_index = ex_pc[WIDTH+1:2];
wire [41:0] btb_wdata[0:1];
assign btb_wdata[0] = {1'b1, is_branch, ex_pc[15:8], jump_target};
assign btb_wdata[1] = {1'b1, is_branch, ex_pc[15:8], jump_target};

// 偶
BTB_BANK u_BTB_BANK_0(
    .a(ex_pc[7:3]),
    .d(btb_wdata[0]),
    .dpra(pc[7:3]),
    .clk(clk),
    .we(update_en && (ex_pc[2] == 1'b0)),    // 只有偶数指令才更新偶数BTB
    .dpo(pre_port0)
);
// 奇
BTB_BANK u_BTB_BANK_1(
    .a(ex_pc[7:3]),
    .d(btb_wdata[1]),
    .dpra(pc[7:3]),
    .clk(clk),
    .we(update_en && (ex_pc[2] == 1'b1)),    // 只有奇数指令才更新奇数BTB
    .dpo(pre_port1)
);


endmodule 