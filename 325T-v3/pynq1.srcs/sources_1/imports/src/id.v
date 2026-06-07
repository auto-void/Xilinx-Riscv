`include "defines.vh"

`timescale 1ns / 1ps

// 译码模块
module id(

    // from if_stage2
    input [2:0] ras_snap_ptr_i,

    input inst_valid_port0_i,     // 指令有效标志
    input inst_valid_port1_i,

    input [31:0] inst_port0_i,    // 指令内容
    input [31:0] inst_port1_i,

    input [31:0] inst_addr_i,

    input [31:0] imm_port0_i,
    input [31:0] imm_port1_i,

    input bpu_pre_flag_port0_i,
    input bpu_pre_flag_port1_i,

    input [31:0] bpu_pre_addr_port0_i,
    input [31:0] bpu_pre_addr_port1_i,

    // to pc and if_id
    output reg jal_flush_o,                    // jal指令跳转冲刷
    output reg [31:0] jal_addr_o,              // jal指令的跳转地址

    // to dispatch
    output [2:0] ras_snap_ptr_o,               // RAS快照指针

    output [31:0] inst_addr_o,                       // 指令地址
    output [2:0] inst_type_port0_o,              // 指令类型
    output [2:0] inst_type_port1_o,              // 指令类型

    output [3:0] inst_subtype_port0_o,           // 指令子类型
    output [3:0] inst_subtype_port1_o,           // 指令子类型

    output [1:0] op1_src_port0_o,                // 操作数1来源选择
    output [1:0] op1_src_port1_o,                // 操作数1来源选择

    output [1:0] op2_src_port0_o,                // 操作数2来源选择
    output [1:0] op2_src_port1_o,                // 操作数2来源选择

    output [11:0] csr_addr_port0_o,              // CSR寄存器地址
    output [11:0] csr_addr_port1_o,              // CSR寄存器地址

    output csr_wflag_port0_o,                    // CSR寄存器写使能
    output csr_wflag_port1_o,                    // CSR寄存器写使能

    output [4:0] reg1_raddr_port0_o,             // 读通用寄存器1地址
    output [4:0] reg1_raddr_port1_o,             // 读通用寄存器1地址

    output [4:0] reg2_raddr_port0_o,             // 读通用寄存器2地址
    output [4:0] reg2_raddr_port1_o,             // 读通用寄存器2地址

    output reg_wflag_port0_o,                    // 通用寄存器写使能
    output reg_wflag_port1_o,                    // 通用寄存器写使能

    output [4:0] reg_waddr_port0_o,              // 写通用寄存器地址
    output [4:0] reg_waddr_port1_o,              // 写通用寄存器地址

    output inst_valid_port0_o,                 // 指令有效标志
    output inst_valid_port1_o,                 // 指令有效标志

    output [31:0] imm_port0_o,                 // 立即数
    output [31:0] imm_port1_o,                 // 立即数

    output [31:0] aux_addr_port0_o,            // Auxiliary Address（辅助地址）
    output [31:0] aux_addr_port1_o,            // Auxiliary Address（辅助地址）
    output bpu_pre_flag_port0_o,               // 预测标志
    output bpu_pre_flag_port1_o,               // 预测标志

    output [31:0] bpu_pre_addr_port0_o,        // 预测地址
    output [31:0] bpu_pre_addr_port1_o         // 预测地址

);
// RAS快照指针传递
assign ras_snap_ptr_o = ras_snap_ptr_i;
// 指令地址传递
assign inst_addr_o = inst_addr_i;
// 指令有效性传递
assign inst_valid_port0_o = inst_valid_port0_i;
assign inst_valid_port1_o = inst_valid_port1_i && (inst_port0_i[6:0] != `INST_JAL || ~inst_valid_port0_i);
// 预测标志传递
assign bpu_pre_flag_port0_o = bpu_pre_flag_port0_i;
assign bpu_pre_flag_port1_o = bpu_pre_flag_port1_i;
// 预测地址传递
assign bpu_pre_addr_port0_o = bpu_pre_addr_port0_i;
assign bpu_pre_addr_port1_o = bpu_pre_addr_port1_i;
// 立即数传递
assign imm_port0_o = (inst_port0_i[6:0] == `INST_AUIPC) ? ({inst_addr_i[31:3],3'b000} + imm_port0_i) : imm_port0_i;
assign imm_port1_o = (inst_port1_i[6:0] == `INST_AUIPC) ? ({inst_addr_i[31:3],3'b100} + imm_port1_i) : imm_port1_i;

// 译码
// inst0
wire jal_flush_port0;
wire [31:0] jal_addr_port0;
inst_decoder inst_decoder_port0(
    .inst_i(inst_port0_i),
    .inst_addr_i({inst_addr_i[31:3],3'b000}),
    .imm_i(imm_port0_i),
    .pre_addr_i(bpu_pre_addr_port0_i),
    .inst_type_o(inst_type_port0_o),
    .inst_subtype_o(inst_subtype_port0_o),
    .op1_src_o(op1_src_port0_o),
    .op2_src_o(op2_src_port0_o),
    .csr_addr_o(csr_addr_port0_o),
    .csr_wflag_o(csr_wflag_port0_o),
    .reg1_raddr_o(reg1_raddr_port0_o),
    .reg2_raddr_o(reg2_raddr_port0_o),
    .reg_wflag_o(reg_wflag_port0_o),
    .reg_waddr_o(reg_waddr_port0_o),
    .jal_flush_o(jal_flush_port0),
    .jal_addr_o(jal_addr_port0),
    .aux_addr_o(aux_addr_port0_o)
);

// inst1
wire jal_flush_port1;
wire [31:0] jal_addr_port1;
inst_decoder inst_decoder_port1(
    .inst_i(inst_port1_i),
    .inst_addr_i({inst_addr_i[31:3],3'b100}),
    .imm_i(imm_port1_i),
    .pre_addr_i(bpu_pre_addr_port1_i),
    .inst_type_o(inst_type_port1_o),
    .inst_subtype_o(inst_subtype_port1_o),
    .op1_src_o(op1_src_port1_o),
    .op2_src_o(op2_src_port1_o),
    .csr_addr_o(csr_addr_port1_o),
    .csr_wflag_o(csr_wflag_port1_o),
    .reg1_raddr_o(reg1_raddr_port1_o),
    .reg2_raddr_o(reg2_raddr_port1_o),
    .reg_wflag_o(reg_wflag_port1_o),
    .reg_waddr_o(reg_waddr_port1_o),
    .jal_flush_o(jal_flush_port1),
    .jal_addr_o(jal_addr_port1),
    .aux_addr_o(aux_addr_port1_o)
);

// jal指令冲刷和跳转地址选择
always @(*) begin
    jal_flush_o = 1'b0;
    jal_addr_o = 32'b0;

    if (inst_valid_port0_i && jal_flush_port0) begin
        jal_flush_o = 1'b1;
        jal_addr_o = jal_addr_port0;
    end
    else if (inst_valid_port1_i && jal_flush_port1) begin
        jal_flush_o = 1'b1;
        jal_addr_o = jal_addr_port1;
    end

end


endmodule