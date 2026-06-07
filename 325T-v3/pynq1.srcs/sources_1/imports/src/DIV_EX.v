`include "defines.vh"

`timescale 1ns / 1ps

module DIV_EX (
    input clk,
    input rst,

    // from rf
    input inst_valid_i,               // 指令有效标志
    input [5:0] rob_id_i,             // ROB id
    input [3:0] mask_i,               // 分支掩码
    input [3:0] subtype_i,            // 指令子类型
    input [31:0] reg1_rdata_i,        // rs1数据
    input [31:0] reg2_rdata_i,        // rs2数据
    input [5:0] pwaddr_i,             // 物理寄存器写地址

    // from branch
    input jump_flag_i,                  // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id

    // to pipeline
    output flush_o,
    output stall_o,

    // to regs
    output ex_wflag_o,                  // 执行阶段写寄存器标志
    output [5:0] ex_waddr_o,            // 执行阶段写寄存器地址(同时传到wb)

    // to wb
    output inst_valid_o,                 // 指令有效标志
    output [5:0] rob_id_o,               // ROB id
    output reg [31:0] reg_wdata_o        // 写寄存器数据
);
// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
assign inst_valid_o = inst_valid_i && ((mask_i & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效
assign flush_o = inst_valid_i && ((mask_i & kill_mask) != 0);

assign stall_o = inst_valid_i && !div_done; // 当指令有效且除法未完成时，发出stall信号
assign rob_id_o = rob_id_i;
assign ex_waddr_o = pwaddr_i;

reg div_start;
reg signed_div;             // 有符号除法标志
reg [31:0] div_dividend;    // 被除数
reg [31:0] div_divisor;     // 除数
wire [31:0] div_quotient;   // 商
wire [31:0] div_remainder;  // 余数
wire div_done;
SRT_div SRT_div_inst (
    .clk(clk),
    .rst_n(rst),
    .start(div_start),
    .signed_div(signed_div),
    .dividend(div_dividend),
    .divisor(div_divisor),
    .quotient(div_quotient),
    .remainder(div_remainder),
    .ready_for_wakeup(ex_wflag_o),
    .done(div_done)
);

always @(*) begin
    div_start = 1'b0;
    signed_div = 1'b0;
    div_dividend = 32'b0;
    div_divisor = 32'b0;
    reg_wdata_o = 32'b0;

    case (subtype_i)
        `M_DIV: begin
            div_start = inst_valid_o;
            signed_div = 1'b1;
            div_dividend = reg1_rdata_i;
            div_divisor = reg2_rdata_i;
            reg_wdata_o = div_quotient;
        end
        `M_DIVU: begin
            div_start = inst_valid_o;
            signed_div = 1'b0;
            div_dividend = reg1_rdata_i;
            div_divisor = reg2_rdata_i;
            reg_wdata_o = div_quotient;
        end
        `M_REM: begin
            div_start = inst_valid_o;
            signed_div = 1'b1;
            div_dividend = reg1_rdata_i;
            div_divisor = reg2_rdata_i;
            reg_wdata_o = div_remainder;
        end
        `M_REMU: begin
            div_start = inst_valid_o;
            signed_div = 1'b0;
            div_dividend = reg1_rdata_i;
            div_divisor = reg2_rdata_i;
            reg_wdata_o = div_remainder;
        end
        default: begin
            div_start = 1'b0;
            signed_div = 1'b0;
            div_dividend = 32'b0;
            div_divisor = 32'b0;
            reg_wdata_o = 32'b0;
        end
    endcase
end

endmodule