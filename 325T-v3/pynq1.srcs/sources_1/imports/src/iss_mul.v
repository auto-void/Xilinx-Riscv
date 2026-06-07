`include "defines.vh"

`timescale 1ns / 1ps

module iss_mul (
    input clk,
    input rst,

    // from issue
    input int_flag_i,                 // 中断标志
    input issue_flag_i,               // 发射标志
    input [5:0] rob_id_i,             // ROB id
    input [3:0] mask_i,               // 分支掩码
    input [3:0] subtype_i,            // 指令子类型
    input [5:0] praddr1_i,            // 物理寄存器1读地址
    input [5:0] praddr2_i,            // 物理寄存器2读地址
    input [5:0] pwaddr_i,             // 物理寄存器写地址

    // to ex
    output reg inst_valid_o,          // 指令有效标志
    output reg [5:0] rob_id_o,        // ROB id
    output reg [3:0] mask_o,          // 分支掩码
    output reg [3:0] subtype_o,       // 指令子类型
    output reg [5:0] praddr1_o,       // 物理寄存器1读地址
    output reg [5:0] praddr2_o,       // 物理寄存器2读地址
    output reg [5:0] pwaddr_o         // 物理寄存器写地址

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
    rob_id_o <= rob_id_i;
    mask_o <= mask_i;
    subtype_o <= subtype_i;
    praddr1_o <= praddr1_i;
    praddr2_o <= praddr2_i;
    pwaddr_o <= pwaddr_i;
end

endmodule