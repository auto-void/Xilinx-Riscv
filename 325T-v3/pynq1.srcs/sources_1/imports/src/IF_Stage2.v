`include "defines.vh"

`timescale 1ns / 1ps

// fetch stage 2: pre-decode
module IF_Stage2(
    input clk,
    input rst,

    // from IF_Stage1
    input inst_valid_i,
    input [63:0] inst_i,
    input [31:0] inst_addr_i,
    input bpu_pre_flag_i,
    input bpu_jump_odd_i,
    input [31:0] bpu_pre_addr_i,

    // to PC
    output reg ras_pre_flag_o,

    // from RAS
    input [2:0] ras_snap_ptr_i,    // RAS快照指针
    input [31:0] ras_pop_data_i,   // RAS弹栈数据

    // to RAS
    output reg ras_pop_flag_o,
    output reg ras_push_flag_o,
    output reg [31:0] ras_push_data_o,

    // to id
    output [2:0] ras_snap_ptr_o,

    output inst_valid_port0_o,     // 指令有效标志
    output inst_valid_port1_o,

    output [31:0] inst_port0_o,    // 指令内容
    output [31:0] inst_port1_o,

    output [31:0] inst_addr_o,

    output reg [31:0] imm_port0_o,
    output reg [31:0] imm_port1_o,

    output reg bpu_pre_flag_port0_o,
    output reg bpu_pre_flag_port1_o,

    output reg [31:0] bpu_pre_addr_port0_o,
    output reg [31:0] bpu_pre_addr_port1_o
);
// 指令地址
assign inst_addr_o = inst_addr_i;
// 指令有效性
assign inst_valid_port0_o = inst_valid_i && (inst_addr_i[2] == 1'b0);              // 是否对齐取指
assign inst_valid_port1_o = inst_valid_i && bpu_jump_odd_i && ~ras_pre_flag_0;     // 第一条是否跳走了
// 指令内容
assign inst_port0_o = inst_i[31:0];
assign inst_port1_o = inst_i[63:32];
// opcode
wire [6:0] opcode_port0 = inst_port0_o[6:0];
wire [6:0] opcode_port1 = inst_port1_o[6:0];
wire [4:0] inst0_rd = inst_port0_o[11:7];
wire [4:0] inst0_rs1 = inst_port0_o[19:15];
wire [4:0] inst1_rd = inst_port1_o[11:7];
wire [4:0] inst1_rs1 = inst_port1_o[19:15];

// RAS快照指针传递
assign ras_snap_ptr_o = ras_snap_ptr_i;

// pre-decode
reg ras_pre_flag_0,ras_pop_flag_0,ras_push_flag_0,ras_pre_flag_1,ras_pop_flag_1,ras_push_flag_1;
reg [31:0] ras_push_data_0,ras_push_data_1;
always @(*) begin
    // 赋默认值
    ras_pre_flag_0 = 1'b0;
    ras_pre_flag_1 = 1'b0;
    ras_pop_flag_0 = 1'b0;
    ras_pop_flag_1 = 1'b0;
    ras_push_flag_0 = 1'b0;
    ras_push_flag_1 = 1'b0;
    ras_push_data_0 = 32'b0;
    ras_push_data_1 = 32'b0;
    bpu_pre_flag_port0_o = 1'b0;
    bpu_pre_flag_port1_o = 1'b0;
    bpu_pre_addr_port0_o = 32'b0;
    bpu_pre_addr_port1_o = 32'b0;
    imm_port0_o = 32'b0;
    imm_port1_o = 32'b0;

    // port0
    case (opcode_port0)
        `INST_TYPE_I: begin
            imm_port0_o = {{20{inst_port0_o[31]}}, inst_port0_o[31:20]};
        end
        `INST_TYPE_L: begin
            imm_port0_o = {{20{inst_port0_o[31]}}, inst_port0_o[31:20]};
        end
        `INST_TYPE_S: begin
            imm_port0_o = {{20{inst_port0_o[31]}},inst_port0_o[31:25],inst_port0_o[11:7]};
        end
        `INST_TYPE_B: begin
            imm_port0_o = {{20{inst_port0_o[31]}}, inst_port0_o[7], inst_port0_o[30:25], inst_port0_o[11:8], 1'b0};
            bpu_pre_flag_port0_o = inst_valid_port0_o && bpu_pre_flag_i && ~bpu_jump_odd_i;
            bpu_pre_addr_port0_o = bpu_pre_addr_i & {32{bpu_pre_flag_port0_o}};
        end
        `INST_JAL: begin
            imm_port0_o = {{12{inst_port0_o[31]}}, inst_port0_o[19:12], inst_port0_o[20], inst_port0_o[30:21], 1'b0};
            ras_push_flag_0 = (inst0_rd == 5'd1 || inst0_rd == 5'd5) && inst_valid_port0_o;
            ras_push_data_0 = {inst_addr_i[31:3], 3'b000} + 32'd4;
            bpu_pre_flag_port0_o = inst_valid_port0_o && bpu_pre_flag_i && ~bpu_jump_odd_i;
            bpu_pre_addr_port0_o = bpu_pre_addr_i & {32{bpu_pre_flag_port0_o}};
        end
        `INST_JALR: begin
            imm_port0_o = {{20{inst_port0_o[31]}}, inst_port0_o[31:20]};
            ras_pre_flag_0 = (inst0_rs1 == 5'd1 || inst0_rs1 == 5'd5) && inst0_rd == 5'd0 && inst_valid_port0_o;
            ras_pop_flag_0 = ras_pre_flag_0;
            ras_push_flag_0 = (inst0_rd == 5'd1 || inst0_rd == 5'd5) && inst_valid_port0_o;
            ras_push_data_0 = {inst_addr_i[31:3], 3'b000} + 32'd4;
            bpu_pre_flag_port0_o = ras_pre_flag_0;
            bpu_pre_addr_port0_o = ras_pop_data_i & {32{bpu_pre_flag_port0_o}};
        end
        `INST_LUI: begin
            imm_port0_o = {inst_port0_o[31:12], 12'b0};
        end
        `INST_AUIPC: begin
            imm_port0_o = {inst_port0_o[31:12], 12'b0};
        end
        `INST_CSR: begin
            imm_port0_o = {27'h0, inst_port0_o[19:15]};
        end
        default: begin
            imm_port0_o = 32'b0;
            ras_push_flag_0 = 1'b0;
            ras_push_data_0 = 32'b0;
            ras_pop_flag_0 = 1'b0;
            ras_pre_flag_0 = 1'b0;
            bpu_pre_flag_port0_o = 1'b0;
            bpu_pre_addr_port0_o = 32'b0;
        end
    endcase

    // port1
    case (opcode_port1)
        `INST_TYPE_I: begin
            imm_port1_o = {{20{inst_port1_o[31]}}, inst_port1_o[31:20]};
        end
        `INST_TYPE_L: begin
            imm_port1_o = {{20{inst_port1_o[31]}}, inst_port1_o[31:20]};
        end
        `INST_TYPE_S: begin
            imm_port1_o = {{20{inst_port1_o[31]}},inst_port1_o[31:25],inst_port1_o[11:7]};
        end
        `INST_TYPE_B: begin
            imm_port1_o = {{20{inst_port1_o[31]}}, inst_port1_o[7], inst_port1_o[30:25], inst_port1_o[11:8], 1'b0};
            bpu_pre_flag_port1_o = inst_valid_port1_o && bpu_pre_flag_i;
            bpu_pre_addr_port1_o = bpu_pre_addr_i & {32{bpu_pre_flag_port1_o}};
        end
        `INST_JAL: begin
            imm_port1_o = {{12{inst_port1_o[31]}}, inst_port1_o[19:12], inst_port1_o[20], inst_port1_o[30:21], 1'b0};
            ras_push_flag_1 = (inst1_rd == 5'd1 || inst1_rd == 5'd5) && inst_valid_port1_o;
            ras_push_data_1 = {inst_addr_i[31:3], 3'b100} + 32'd4;
            bpu_pre_flag_port1_o = inst_valid_port1_o && bpu_pre_flag_i;
            bpu_pre_addr_port1_o = bpu_pre_addr_i & {32{bpu_pre_flag_port1_o}};
        end
        `INST_JALR: begin
            imm_port1_o = {{20{inst_port1_o[31]}}, inst_port1_o[31:20]};
            ras_pre_flag_1 = (inst1_rs1 == 5'd1 || inst1_rs1 == 5'd5) && inst1_rd == 5'd0 && inst_valid_port1_o;
            ras_pop_flag_1 = ras_pre_flag_1;
            ras_push_flag_1 = (inst1_rd == 5'd1 || inst1_rd == 5'd5) && inst_valid_port1_o;
            ras_push_data_1 = {inst_addr_i[31:3], 3'b100} + 32'd4;
            bpu_pre_flag_port1_o = ras_pre_flag_1;
            bpu_pre_addr_port1_o = ras_pop_data_i & {32{bpu_pre_flag_port1_o}};
        end
        `INST_LUI: begin
            imm_port1_o = {inst_port1_o[31:12], 12'b0};
        end
        `INST_AUIPC: begin
            imm_port1_o = {inst_port1_o[31:12], 12'b0};
        end
        `INST_CSR: begin
            imm_port1_o = {27'h0, inst_port1_o[19:15]};
        end
        default: begin
            imm_port1_o = 32'b0;
            ras_push_flag_1 = 1'b0;
            ras_push_data_1 = 32'b0;
            ras_pop_flag_1 = 1'b0;
            ras_pre_flag_1 = 1'b0;
            bpu_pre_flag_port1_o = 1'b0;
            bpu_pre_addr_port1_o = 32'b0;
        end
    endcase
end

// RAS信号合并
always @(*) begin
    if (ras_push_flag_0 || ras_pop_flag_0) begin
        ras_push_flag_o = ras_push_flag_0;
        ras_pop_flag_o = ras_pop_flag_0;
        ras_pre_flag_o = ras_pre_flag_0;
        ras_push_data_o = ras_push_data_0;
    end 
    else if (ras_push_flag_1 || ras_pop_flag_1) begin
        ras_push_flag_o = ras_push_flag_1;
        ras_pop_flag_o = ras_pop_flag_1;
        ras_pre_flag_o = ras_pre_flag_1;
        ras_push_data_o = ras_push_data_1;
    end
    else begin
        ras_push_flag_o = 1'b0;
        ras_pop_flag_o = 1'b0;
        ras_pre_flag_o = 1'b0;
        ras_push_data_o = 32'b0;
    end
end



endmodule