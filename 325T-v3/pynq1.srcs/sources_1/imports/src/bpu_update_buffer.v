`include "defines.vh"

`timescale 1ns / 1ps

// 更新分支预测前打一拍
module bpu_update_buffer (
    input clk,
    input rst,

    // from br_ex
    input [31:0] jump_addr_i,          // 跳转地址(同时传到bpu_update_buffer)
    input btb_update_en_i,                     // 执行阶段更新BTB使能
    input [15:0] ex_pc_i,                          // 执行阶段的pc
    input is_branch_i,                             // 是否为分支指令
    input lhp_update_en_i,                     // 更新使能
    input branch_taken_i,                       // 实际跳转结果(1为跳转)

    // to BPU
    output reg [31:0] jump_addr_o,          // 跳转地址(同时传到bpu_update_buffer)
    output reg btb_update_en_o,                     // 执行阶段更新BTB使能
    output reg [15:0] ex_pc_o,                          // 执行阶段的pc
    output reg is_branch_o,                             // 是否为分支指令
    output reg lhp_update_en_o,                     // 更新使能
    output reg branch_taken_o                       // 实际跳转结果(1为跳转)
);

always @(posedge clk) begin
    if(!rst) begin
        btb_update_en_o <= 1'b0;
        lhp_update_en_o <= 1'b0;
    end
    else begin
        btb_update_en_o <= btb_update_en_i;
        lhp_update_en_o <= lhp_update_en_i;
    end
end

always @(posedge clk) begin
    jump_addr_o <= jump_addr_i;
    ex_pc_o <= ex_pc_i;
    is_branch_o <= is_branch_i;
    branch_taken_o <= branch_taken_i;
end

endmodule