`include "defines.vh"

`timescale 1ns / 1ps

//PC寄存器
module pc_reg(
    input clk,
    input rst,

    // from ex
    input jump_flag_i,              // 跳转标志
    input [31:0] jump_addr_i,       // 跳转地址
    
    // from icache
    input hold_flag_i,              // 流水线暂停标志

    // from clint
    input int_flag_i,
    input [31:0] int_addr_i,

    // from dispatch
    input stall_flag_i,             // RS/ROB满，暂停取指

    // from id
    input jal_flush_i,              // jal指令冲刷
    input [31:0] jal_addr_i,        // jal指令的跳转地址

    // from RAS
    input ras_pre_flag_i,           // RAS地址预测标志
    input [31:0] ras_pre_addr_i,    // 预测地址

    // from BPU
    input bpu_pre_flag_i,           // BPU地址预测标志
    input [31:0] bpu_pre_addr_i,    // 预测地址

    // to if
    output reg [31:0] pc_o          // pc寄存器输出下一条指令的地址

);

always @(posedge clk or negedge rst) begin
    if(!rst) begin                 // 复位
        pc_o <= 32'h8000_0000;
    end
    else if(int_flag_i) begin      // 中断优先级最高
        pc_o <= int_addr_i;
    end
    else if(jump_flag_i) begin     // 执行确认阶段冲刷
        pc_o <= jump_addr_i;
    end
    else if(stall_flag_i) begin    // RS/ROB满暂停，保持原值
        pc_o <= pc_o;
    end
    else if(jal_flush_i) begin     // 译码阶段jal指令冲刷
        pc_o <= jal_addr_i;
    end
    else if(ras_pre_flag_i) begin  // RAS分支预测
        pc_o <= ras_pre_addr_i;
    end
    else if(hold_flag_i) begin     // Cache Miss暂停，保持原值
        pc_o <= pc_o;
    end
    else if(bpu_pre_flag_i) begin  // BPU分支预测
        pc_o <= bpu_pre_addr_i;
    end
    else begin                     // 地址加8
        pc_o <= {pc_o[31:3], 3'b0} + 32'd8;
    end
end



endmodule