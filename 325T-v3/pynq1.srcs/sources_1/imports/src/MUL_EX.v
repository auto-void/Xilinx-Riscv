`include "defines.vh"

`timescale 1ns / 1ps

module MUL_EX (
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

    // to regs
    output reg_wflag_o,                 // 写回阶段写寄存器标志
    output [5:0] reg_waddr_o,           // 写回阶段写寄存器地址
    output reg [31:0] reg_wdata_o,      // 写回阶段写寄存器数据
    output ex_wflag_o,                  // 执行阶段写寄存器标志
    output [5:0] ex_waddr_o,            // 执行阶段写寄存器地址

    // to ROB
    output complete_flag_o,             // 指令完成标志
    output [5:0] commit_rob_id_o        // 提交ROB id
);

wire [31:0] reg1_rdata_invert = ~rs1_data_i + 1;
wire [31:0] reg2_rdata_invert = ~rs2_data_i + 1;
reg [31:0] mul_op1;
reg [31:0] mul_op2;
reg inv_result_sign; // 表示结果需要取反加一
// 输入预处理
always @(*) begin
    mul_op1 = 32'b0;
    mul_op2 = 32'b0;
    inv_result_sign = 1'b0;

    case (subtype_i)
        `M_MUL: begin
            mul_op1 = rs1_data_i;
            mul_op2 = rs2_data_i;
            inv_result_sign = 1'b0;
        end
        `M_MULH: begin
            mul_op1 = (rs1_data_i[31] == 1'b1)? reg1_rdata_invert : rs1_data_i;    // 取绝对值
            mul_op2 = (rs2_data_i[31] == 1'b1)? reg2_rdata_invert : rs2_data_i;
            inv_result_sign = rs1_data_i[31] ^ rs2_data_i[31];
        end
        `M_MULHSU: begin
            mul_op1 = (rs1_data_i[31] == 1'b1)? reg1_rdata_invert : rs1_data_i;
            mul_op2 = rs2_data_i;
            inv_result_sign = rs1_data_i[31];
        end
        `M_MULHU: begin
            mul_op1 = rs1_data_i;
            mul_op2 = rs2_data_i;
            inv_result_sign = 1'b0;
        end
        default: begin
            mul_op1 = 32'b0;
            mul_op2 = 32'b0;
            inv_result_sign = 1'b0;
        end
    endcase
end

// 实例化乘法器
wire [63:0] mul_product_raw;
Mul_Core u_Mul_Core (
    .clk(clk),
    .rst_n(rst),
    .op1(mul_op1),
    .op2(mul_op2),
    .product(mul_product_raw)
);
wire [63:0] mul_product_invert = ~mul_product_raw + 1;    // 取反加一得到负数结果

// 控制信号流水线
reg       vld_pipe[0:2];         // 有效标志
reg [5:0] rob_pipe[0:2];         // ROB id
reg [3:0] sub_pipe[0:2];         // 指令子类型
reg [5:0] dst_pipe[0:2];         // 目标寄存器
reg       inv_pipe[0:2];         // 结果取反标志

integer i;
always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 3; i = i + 1) begin
            vld_pipe[i] <= 0;
        end
    end
    else if (int_flag_i) begin
        for (i = 0; i < 3; i = i + 1) begin
            vld_pipe[i] <= 0;
        end
    end
    else begin
        // 移位逻辑
        vld_pipe[0] <= inst_valid_i;

        for (i = 1; i < 3; i = i + 1) begin
            vld_pipe[i] <= vld_pipe[i-1];
        end
    end
end

always @(posedge clk) begin
    // 移位逻辑
    rob_pipe[0] <= rob_id_i;
    sub_pipe[0] <= subtype_i;
    dst_pipe[0] <= pwaddr_i;
    inv_pipe[0] <= inv_result_sign;

    for (i = 1; i < 3; i = i + 1) begin
        rob_pipe[i] <= rob_pipe[i-1];
        sub_pipe[i] <= sub_pipe[i-1];
        dst_pipe[i] <= dst_pipe[i-1];
        inv_pipe[i] <= inv_pipe[i-1];
    end
end

// 取出第3级流水线寄存器的内容
wire       wb_valid   = vld_pipe[2];
wire [5:0] wb_rob     = rob_pipe[2];
wire [3:0] wb_subtype = sub_pipe[2];
wire [5:0] wb_dst     = dst_pipe[2];
wire       wb_inv     = inv_pipe[2];

// 输出
assign ex_wflag_o = vld_pipe[0];    // 执行阶段写寄存器标志
assign ex_waddr_o = dst_pipe[0];    // 执行阶段写寄存器地址
assign complete_flag_o = wb_valid;  // 指令完成标志
assign commit_rob_id_o = wb_rob;    // 提交ROB id
assign reg_wflag_o = wb_valid;      // 写回阶段写寄存器标志
assign reg_waddr_o = wb_dst;        // 写回阶段写寄存器地址

always @(*) begin
    reg_wdata_o = 32'b0;
    case (wb_subtype)
        `M_MUL: begin
            reg_wdata_o = mul_product_raw[31:0];
        end
        `M_MULH: begin
            reg_wdata_o = wb_inv ? mul_product_invert[63:32] : mul_product_raw[63:32];
        end
        `M_MULHSU: begin
            reg_wdata_o = wb_inv ? mul_product_invert[63:32] : mul_product_raw[63:32];
        end
        `M_MULHU: begin
            reg_wdata_o = mul_product_raw[63:32];
        end
        default: begin
            reg_wdata_o = 32'b0;
        end
    endcase
end






endmodule