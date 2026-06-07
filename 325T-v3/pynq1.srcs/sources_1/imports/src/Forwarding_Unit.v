`include "defines.vh"

`timescale 1ns / 1ps

// 转发单元
module Forwarding_Unit (
    // from RF
    // from ALU_0
    input [5:0] alu0_rf_raddr1_i,     // ALU_0 RF阶段读寄存器1地址
    input [5:0] alu0_rf_raddr2_i,     // ALU_0 RF阶段读寄存器2地址
    // from ALU_1
    input [5:0] alu1_rf_raddr1_i,     // ALU_1 RF阶段读寄存器1地址
    input [5:0] alu1_rf_raddr2_i,     // ALU_1 RF阶段读寄存器2地址
    // from mem
    input [5:0] mem_rf_raddr1_i,      // mem RF阶段读寄存器1地址
    input [5:0] mem_rf_raddr2_i,      // mem RF阶段读寄存器2地址
    // from branch
    input [5:0] branch_rf_raddr1_i,   // branch RF阶段读寄存器1地址
    input [5:0] branch_rf_raddr2_i,   // branch RF阶段读寄存器2地址
    `ifdef use_m_extension
    // from mul
    input [5:0] mul_rf_raddr1_i,       // mul RF阶段读寄存器1地址
    input [5:0] mul_rf_raddr2_i,       // mul RF阶段读寄存器2地址
    // from div
    input [5:0] div_rf_raddr1_i,       // div RF阶段读寄存器1地址
    input [5:0] div_rf_raddr2_i,       // div RF阶段读寄存器2地址
    `endif

    // from ex
    // from ALU_0
    input [5:0] alu0_exe_waddr_i,     // ALU_0 执行阶段写寄存器地址
    input [31:0] alu0_exe_wdata_i,     // ALU_0 执行阶段写寄存器数据
    // from ALU_1
    input [5:0] alu1_exe_waddr_i,     // ALU_1 执行阶段写寄存器地址
    input [31:0] alu1_exe_wdata_i,     // ALU_1 执行阶段写寄存器数据
    // from mem
    input [5:0] mem_exe_waddr_i,      // mem 执行阶段写寄存器地址
    input [31:0] mem_exe_wdata_i,      // mem 执行阶段写寄存器数据
    // `ifdef use_m_extension
    // // from mul
    // input [5:0] mul_exe_waddr_i,      // mul 执行阶段写寄存器地址
    // input [31:0] mul_exe_wdata_i,      // mul 执行阶段写寄存器数据
    // `endif

    // to RF
    // to ALU_0
    output reg alu0_rs1_forward_flag_o,           // ALU_0 rs1转发标志
    output reg [31:0] alu0_rs1_forward_data_o,    // ALU_0 rs1转发数据
    output reg alu0_rs2_forward_flag_o,           // ALU_0 rs2转发标志
    output reg [31:0] alu0_rs2_forward_data_o,    // ALU_0 rs2转发数据
    // to ALU_1
    output reg alu1_rs1_forward_flag_o,           // ALU_1 rs1转发标志
    output reg [31:0] alu1_rs1_forward_data_o,    // ALU_1 rs1转发数据
    output reg alu1_rs2_forward_flag_o,           // ALU_1 rs2转发标志
    output reg [31:0] alu1_rs2_forward_data_o,    // ALU_1 rs2转发数据
    // to mem
    output reg mem_rs1_forward_flag_o,            // mem rs1转发标志
    output reg [31:0] mem_rs1_forward_data_o,     // mem rs1转发数据
    output reg mem_rs2_forward_flag_o,            // mem rs2转发标志
    output reg [31:0] mem_rs2_forward_data_o,     // mem rs2转发数据
    // to branch
    output reg branch_rs1_forward_flag_o,         // branch rs1转发标志
    output reg [31:0] branch_rs1_forward_data_o,  // branch rs1转发数据
    output reg branch_rs2_forward_flag_o,         // branch rs2转发标志
    output reg [31:0] branch_rs2_forward_data_o   // branch rs2转发数据
    `ifdef use_m_extension
    // to mul
    ,output reg mul_rs1_forward_flag_o,           // mul rs1转发标志
    output reg [31:0] mul_rs1_forward_data_o,     // mul rs1转发数据
    output reg mul_rs2_forward_flag_o,            // mul rs2转发标志
    output reg [31:0] mul_rs2_forward_data_o,     // mul rs2转发数据
    // to div
    output reg div_rs1_forward_flag_o,            // div rs1转发标志
    output reg [31:0] div_rs1_forward_data_o,     // div rs1转发数据
    output reg div_rs2_forward_flag_o,            // div rs2转发标志
    output reg [31:0] div_rs2_forward_data_o      // div rs2转发数据
    `endif
);

// ALU0_rs1转发
always @(*) begin
    if (alu0_rf_raddr1_i != 6'b0) begin
        alu0_rs1_forward_flag_o = (alu0_rf_raddr1_i == alu0_exe_waddr_i) | (alu0_rf_raddr1_i == alu1_exe_waddr_i) | (alu0_rf_raddr1_i == mem_exe_waddr_i);
        alu0_rs1_forward_data_o = {32{alu0_rf_raddr1_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                  {32{alu0_rf_raddr1_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                  {32{alu0_rf_raddr1_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        alu0_rs1_forward_flag_o = 1'b0;
        alu0_rs1_forward_data_o = 32'b0;
    end
end
// ALU0_rs2转发
always @(*) begin
    if (alu0_rf_raddr2_i != 6'b0) begin
        alu0_rs2_forward_flag_o = (alu0_rf_raddr2_i == alu0_exe_waddr_i) | (alu0_rf_raddr2_i == alu1_exe_waddr_i) | (alu0_rf_raddr2_i == mem_exe_waddr_i);
        alu0_rs2_forward_data_o = {32{alu0_rf_raddr2_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                  {32{alu0_rf_raddr2_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                  {32{alu0_rf_raddr2_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        alu0_rs2_forward_flag_o = 1'b0;
        alu0_rs2_forward_data_o = 32'b0;
    end
end
// ALU1_rs1转发
always @(*) begin
    if (alu1_rf_raddr1_i != 6'b0) begin
        alu1_rs1_forward_flag_o = (alu1_rf_raddr1_i == alu0_exe_waddr_i) | (alu1_rf_raddr1_i == alu1_exe_waddr_i) | (alu1_rf_raddr1_i == mem_exe_waddr_i);
        alu1_rs1_forward_data_o = {32{alu1_rf_raddr1_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                  {32{alu1_rf_raddr1_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                  {32{alu1_rf_raddr1_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        alu1_rs1_forward_flag_o = 1'b0;
        alu1_rs1_forward_data_o = 32'b0;
    end
end
// ALU1_rs2转发
always @(*) begin
    if (alu1_rf_raddr2_i != 6'b0) begin
        alu1_rs2_forward_flag_o = (alu1_rf_raddr2_i == alu0_exe_waddr_i) | (alu1_rf_raddr2_i == alu1_exe_waddr_i) | (alu1_rf_raddr2_i == mem_exe_waddr_i);
        alu1_rs2_forward_data_o = {32{alu1_rf_raddr2_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                  {32{alu1_rf_raddr2_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                  {32{alu1_rf_raddr2_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        alu1_rs2_forward_flag_o = 1'b0;
        alu1_rs2_forward_data_o = 32'b0;
    end
end
// mem_rs1转发
always @(*) begin
    if (mem_rf_raddr1_i != 6'b0) begin
        mem_rs1_forward_flag_o = (mem_rf_raddr1_i == alu0_exe_waddr_i) | (mem_rf_raddr1_i == alu1_exe_waddr_i) | (mem_rf_raddr1_i == mem_exe_waddr_i);
        mem_rs1_forward_data_o = {32{mem_rf_raddr1_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                 {32{mem_rf_raddr1_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                 {32{mem_rf_raddr1_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        mem_rs1_forward_flag_o = 1'b0;
        mem_rs1_forward_data_o = 32'b0;
    end
end
// mem_rs2转发
always @(*) begin
    if (mem_rf_raddr2_i != 6'b0) begin
        mem_rs2_forward_flag_o = (mem_rf_raddr2_i == alu0_exe_waddr_i) | (mem_rf_raddr2_i == alu1_exe_waddr_i) | (mem_rf_raddr2_i == mem_exe_waddr_i);
        mem_rs2_forward_data_o = {32{mem_rf_raddr2_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                 {32{mem_rf_raddr2_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                 {32{mem_rf_raddr2_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        mem_rs2_forward_flag_o = 1'b0;
        mem_rs2_forward_data_o = 32'b0;
    end
end
// branch_rs1转发
always @(*) begin
    if (branch_rf_raddr1_i != 6'b0) begin
        branch_rs1_forward_flag_o = (branch_rf_raddr1_i == alu0_exe_waddr_i) | (branch_rf_raddr1_i == alu1_exe_waddr_i) | (branch_rf_raddr1_i == mem_exe_waddr_i);
        branch_rs1_forward_data_o = {32{branch_rf_raddr1_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                    {32{branch_rf_raddr1_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                    {32{branch_rf_raddr1_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        branch_rs1_forward_flag_o = 1'b0;
        branch_rs1_forward_data_o = 32'b0;
    end
end
// branch_rs2转发
always @(*) begin
    if (branch_rf_raddr2_i != 6'b0) begin
        branch_rs2_forward_flag_o = (branch_rf_raddr2_i == alu0_exe_waddr_i) | (branch_rf_raddr2_i == alu1_exe_waddr_i) | (branch_rf_raddr2_i == mem_exe_waddr_i);
        branch_rs2_forward_data_o = {32{branch_rf_raddr2_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                    {32{branch_rf_raddr2_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                    {32{branch_rf_raddr2_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        branch_rs2_forward_flag_o = 1'b0;
        branch_rs2_forward_data_o = 32'b0;
    end
end

`ifdef use_m_extension
// mul_rs1转发
always @(*) begin
    if (mul_rf_raddr1_i != 6'b0) begin
        mul_rs1_forward_flag_o = (mul_rf_raddr1_i == alu0_exe_waddr_i) | (mul_rf_raddr1_i == alu1_exe_waddr_i) | (mul_rf_raddr1_i == mem_exe_waddr_i);
        mul_rs1_forward_data_o = {32{mul_rf_raddr1_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                 {32{mul_rf_raddr1_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                 {32{mul_rf_raddr1_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        mul_rs1_forward_flag_o = 1'b0;
        mul_rs1_forward_data_o = 32'b0;
    end
end
// mul_rs2转发
always @(*) begin
    if (mul_rf_raddr2_i != 6'b0) begin
        mul_rs2_forward_flag_o = (mul_rf_raddr2_i == alu0_exe_waddr_i) | (mul_rf_raddr2_i == alu1_exe_waddr_i) | (mul_rf_raddr2_i == mem_exe_waddr_i);
        mul_rs2_forward_data_o = {32{mul_rf_raddr2_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                 {32{mul_rf_raddr2_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                 {32{mul_rf_raddr2_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        mul_rs2_forward_flag_o = 1'b0;
        mul_rs2_forward_data_o = 32'b0;
    end
end
// div_rs1转发
always @(*) begin
    if (div_rf_raddr1_i != 6'b0) begin
        div_rs1_forward_flag_o = (div_rf_raddr1_i == alu0_exe_waddr_i) | (div_rf_raddr1_i == alu1_exe_waddr_i) | (div_rf_raddr1_i == mem_exe_waddr_i);
        div_rs1_forward_data_o = {32{div_rf_raddr1_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                 {32{div_rf_raddr1_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                 {32{div_rf_raddr1_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        div_rs1_forward_flag_o = 1'b0;
        div_rs1_forward_data_o = 32'b0;
    end
end
// div_rs2转发
always @(*) begin
    if (div_rf_raddr2_i != 6'b0) begin
        div_rs2_forward_flag_o = (div_rf_raddr2_i == alu0_exe_waddr_i) | (div_rf_raddr2_i == alu1_exe_waddr_i) | (div_rf_raddr2_i == mem_exe_waddr_i);
        div_rs2_forward_data_o = {32{div_rf_raddr2_i == alu0_exe_waddr_i}} & alu0_exe_wdata_i |
                                 {32{div_rf_raddr2_i == alu1_exe_waddr_i}} & alu1_exe_wdata_i |
                                 {32{div_rf_raddr2_i == mem_exe_waddr_i}}  & mem_exe_wdata_i;
    end 
    else begin
        div_rs2_forward_flag_o = 1'b0;
        div_rs2_forward_data_o = 32'b0;
    end
end
`endif



endmodule