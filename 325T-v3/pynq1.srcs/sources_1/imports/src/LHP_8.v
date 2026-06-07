`include "defines.vh"

`timescale 1ns / 1ps

module LHP_8 (
    input clk,
    input rst,
    // from if
    input [31:0] if_pc,      // 取指阶段分支指令的PC地址（用于查表预测）


    // from ex
    input update_en,                 // 更新使能
    input branch_taken,              // 实际跳转结果(1为跳转)
    input [15:0] ex_pc,              // 执行阶段分支指令的PC地址（用于更新标签）

    // to selector
    output prediction_port0,        // 预测结果(1为跳转)
    output prediction_port1         // 预测结果(1为跳转)
);

// wire [6:0] BHT_raddr;       // 分支历史表索引
// assign BHT_raddr = if_pc[8:2];

// wire [6:0] BHT_waddr;       // 分支历史表索引
// assign BHT_waddr = ex_pc[8:2];

wire [7:0] BHT_rdata[0:1];
wire [7:0] lhr[0:1];
wire [7:0] BHT_wdata[0:1];
assign BHT_wdata[0] = {lhr[0][6:0], branch_taken};
assign BHT_wdata[1] = {lhr[1][6:0], branch_taken};
// 偶
BHT_BANK u_BHT_BANK_0(
    .a(ex_pc[8:3]),
    .d(BHT_wdata[0]),
    .dpra(if_pc[8:3]),
    .clk(clk),
    .we(update_en && (ex_pc[2] == 1'b0)),    // 只有偶数指令才更新偶数BHT
    .spo(lhr[0]),
    .dpo(BHT_rdata[0])
);
// 奇
BHT_BANK u_BHT_BANK_1(
    .a(ex_pc[8:3]),
    .d(BHT_wdata[1]),
    .dpra(if_pc[8:3]),
    .clk(clk),
    .we(update_en && (ex_pc[2] == 1'b1)),    // 只有奇数指令才更新奇数BHT
    .spo(lhr[1]),            
    .dpo(BHT_rdata[1])
);

wire [7:0] PHT_raddr_odd = {if_pc[10:8] ^ if_pc[7:5], if_pc[12:11] ^ if_pc[4:3], 3'b0} ^ {BHT_rdata[1]};     // 奇
wire [7:0] PHT_raddr_even = {if_pc[10:8] ^ if_pc[7:5], if_pc[12:11] ^ if_pc[4:3], 3'b0} ^ {BHT_rdata[0]};    // 偶

wire [7:0] PHT_waddr_odd = {ex_pc[10:8] ^ ex_pc[7:5], ex_pc[12:11] ^ ex_pc[4:3], 3'b0} ^ {lhr[1]};         // 奇
wire [7:0] PHT_waddr_even = {ex_pc[10:8] ^ ex_pc[7:5], ex_pc[12:11] ^ ex_pc[4:3], 3'b0} ^ {lhr[0]};    // 偶

reg [1:0] PHT_wdata_odd, PHT_wdata_even;
wire [1:0] PHT_rdata_odd[0:3];
wire [1:0] PHT_rdata_even[0:3];
wire [1:0] ex_PHT_rdata_odd[0:3];
wire [1:0] ex_PHT_rdata_even[0:3];

generate
    genvar i,j;
    for (i = 0; i < 4; i = i + 1) begin:PHT_BANK_odd
        PHT_BANK u_PHT_64_odd(
            .a(PHT_waddr_odd[5:0]),
            .d(PHT_wdata_odd),
            .dpra(PHT_raddr_odd[5:0]),
            .clk(clk),
            .we(update_en && (ex_pc[2] == 1'b1) && PHT_waddr_odd[7:6] == i),   
            .spo(ex_PHT_rdata_odd[i]),
            .dpo(PHT_rdata_odd[i])
        );
    end

    for (j = 0; j < 4; j = j + 1) begin:PHT_BANK_even
        PHT_BANK u_PHT_64_even(
            .a(PHT_waddr_even[5:0]),
            .d(PHT_wdata_even),
            .dpra(PHT_raddr_even[5:0]),
            .clk(clk),
            .we(update_en && (ex_pc[2] == 1'b0) && PHT_waddr_even[7:6] == j),    
            .spo(ex_PHT_rdata_even[j]),
            .dpo(PHT_rdata_even[j])
        );
    end
endgenerate

// 取指阶段预测
assign prediction_port0 = PHT_rdata_even[PHT_raddr_even[7:6]][1];
assign prediction_port1 = PHT_rdata_odd[PHT_raddr_odd[7:6]][1];


// 更新PHT
always @(*) begin
    PHT_wdata_odd = 2'b0;
    if(branch_taken && ex_PHT_rdata_odd[PHT_waddr_odd[7:6]] != 2'b11) begin
        PHT_wdata_odd = ex_PHT_rdata_odd[PHT_waddr_odd[7:6]] + 1;
    end
    else if(!branch_taken && ex_PHT_rdata_odd[PHT_waddr_odd[7:6]] != 2'b00) begin
        PHT_wdata_odd = ex_PHT_rdata_odd[PHT_waddr_odd[7:6]] - 1;
    end
    else begin
        PHT_wdata_odd = ex_PHT_rdata_odd[PHT_waddr_odd[7:6]];
    end
end

always @(*) begin
    PHT_wdata_even = 2'b0;
    if(branch_taken && ex_PHT_rdata_even[PHT_waddr_even[7:6]] != 2'b11) begin
        PHT_wdata_even = ex_PHT_rdata_even[PHT_waddr_even[7:6]] + 1;
    end
    else if(!branch_taken && ex_PHT_rdata_even[PHT_waddr_even[7:6]] != 2'b00) begin
        PHT_wdata_even = ex_PHT_rdata_even[PHT_waddr_even[7:6]] - 1;
    end
    else begin
        PHT_wdata_even = ex_PHT_rdata_even[PHT_waddr_even[7:6]];
    end
end



endmodule 