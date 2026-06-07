`include "defines.vh"

`timescale 1ns / 1ps

module div_ex_wb (
    input clk,
    input rst,

    // from ex
    input inst_valid_i,                 // 指令有效标志
    input [5:0] rob_id_i,               // ROB id
    input [5:0] pwaddr_i,               // 物理寄存器写地址
    input [31:0] reg_wdata_i,           // 写寄存器数据

    input stall_i,                      // 暂停标志

    // from clint
    input int_flag_i,                   // 中断标志

    // to wb
    output reg inst_valid_o,                 // 指令有效标志
    output reg [5:0] rob_id_o,               // ROB id
    output reg [5:0] pwaddr_o,               // 物理寄存器写地址
    output reg [31:0] reg_wdata_o            // 写寄存器数据
);

always @(posedge clk) begin
    if (!rst) begin
        inst_valid_o <= 1'b0;
    end
    else if (int_flag_i) begin
        inst_valid_o <= 1'b0;
    end
    else if (stall_i) begin
        inst_valid_o <= 1'b0;
    end
    else begin
        inst_valid_o <= inst_valid_i;
    end
end

always @(posedge clk) begin
    rob_id_o <= rob_id_i;
    pwaddr_o <= pwaddr_i;
    reg_wdata_o <= reg_wdata_i;
end

endmodule