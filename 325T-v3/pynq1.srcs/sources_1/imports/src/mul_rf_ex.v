`include "defines.vh"

`timescale 1ns / 1ps

module mul_rf_ex (
    input clk,
    input rst,

    // from rf
    input inst_valid_i,               // 指令有效标志
    input [5:0] rob_id_i,             // ROB id
    input [3:0] subtype_i,            // 指令子类型
    input [31:0] rs1_data_i,          // rs1数据
    input [31:0] rs2_data_i,          // rs2数据
    input [5:0] pwaddr_i,             // 物理寄存器写地址

    // from clint
    input int_flag_i,                   // 中断标志
    
    // to ex
    output reg inst_valid_o,               // 指令有效标志
    output reg [5:0] rob_id_o,             // ROB id
    output reg [3:0] subtype_o,            // 指令子类型
    output reg [31:0] rs1_data_o,          // rs1数据
    output reg [31:0] rs2_data_o,          // rs2数据
    output reg [5:0] pwaddr_o              // 物理寄存器写地址
);

always @(posedge clk) begin
    if (!rst) begin
        inst_valid_o <= 1'b0;
    end
    else if (int_flag_i) begin
        inst_valid_o <= 1'b0;
    end
    else begin
        inst_valid_o <= inst_valid_i;
    end
end

always @(posedge clk) begin
    rob_id_o <= rob_id_i;
    subtype_o <= subtype_i;
    rs1_data_o <= rs1_data_i;
    rs2_data_o <= rs2_data_i;
    pwaddr_o <= pwaddr_i;
end



endmodule