`include "defines.vh"

`timescale 1ns / 1ps

// 分支预测单元顶层模块
module BPU (
    input clk,
    input rst,

    // BTB
    input [31:0] if_pc,                    // 来自取指阶段的PC
    input btb_update_en,                   // 来自执行阶段的BTB更新使能
    input [31:0] jump_target,              // 来自执行阶段的实际跳转目标地址
    input [15:0] ex_pc,                    // 来自执行阶段的PC
    input is_branch,                       // 来自执行阶段的是否为分支指令

    // LHP
    input lhp_update_en,                   // 来自执行阶段的更新使能
    input branch_taken,                    // 来自执行阶段实际跳转结果

    // RAS
    input ras_push_en,                     // 来自取指阶段的压栈使能
    input [31:0] ras_data_in,              // 来自取指阶段的压栈数据
    input ras_pop_en,                      // 来自取指阶段的弹栈使能
    input ras_restore_en,                  // 来自执行阶段的恢复栈指针使能
    input [2:0] ras_restore_ptr,           // 来自执行阶段的恢复栈指针值
    input ras_hold_flag_i,                 // 来自dispatch的流水线暂停信号
    output [2:0] ras_snap_ptr,             // 传到取指阶段的快照栈指针
    output [31:0] ras_data_out,            // 传到取指阶段的弹栈数据

    // to if
    output reg odd_inst_jump,              // 跳转的是否是奇数指令（1为奇数，0为偶数，不跳默认为1）

    // to PC
    output reg jump_flag_o,                // 跳转使能
    output reg [31:0] jump_addr_o          // 跳转地址


);

// BTB
wire [41:0] btb_rdata[0:1];
wire [31:0] pre_addr[0:1];    // 预测地址
assign pre_addr[0] = btb_rdata[0][31:0];
assign pre_addr[1] = btb_rdata[1][31:0];
wire [7:0] btb_pc_tag[0:1];   // 标签
assign btb_pc_tag[0] = btb_rdata[0][39:32];
assign btb_pc_tag[1] = btb_rdata[1][39:32];
wire btb_is_branch[0:1];      // 是否为分支指令
assign btb_is_branch[0] = btb_rdata[0][40];
assign btb_is_branch[1] = btb_rdata[1][40];
wire btb_valid[0:1];          // 是否有效
assign btb_valid[0] = btb_rdata[0][41];
assign btb_valid[1] = btb_rdata[1][41];
// 标签匹配
wire btb_tag_hit[0:1];
assign btb_tag_hit[0] = (if_pc[15:8] == btb_pc_tag[0]) && btb_valid[0] && (if_pc[2] == 1'b0);    // PC地址8字节对齐时第一条指令才有效
assign btb_tag_hit[1] = (if_pc[15:8] == btb_pc_tag[1]) && btb_valid[1];                          // 第二条指令始终有效
// LHP
wire prediction_port0;        // 偶指令预测结果
wire prediction_port1;        // 奇指令预测结果
// 仲裁
always @(*) begin
    if (btb_tag_hit[0] && btb_tag_hit[1]) begin    // 两条指令都是分支跳转
        if (~btb_is_branch[0]) begin        // 第一条偶指令是无条件跳转
            jump_flag_o = 1'b1;
            jump_addr_o = pre_addr[0];
            odd_inst_jump = 1'b0;
        end
        else if (prediction_port0) begin    // 第一条偶指令是分支且预测跳转(不是无条件跳转就一定是分支不用再判断btb_is_branch[0]了)
            jump_flag_o = 1'b1;
            jump_addr_o = pre_addr[0];
            odd_inst_jump = 1'b0;
        end
        else if (~btb_is_branch[1]) begin   // 第二条奇指令是无条件跳转
            jump_flag_o = 1'b1;
            jump_addr_o = pre_addr[1];
            odd_inst_jump = 1'b1;
        end
        else if (prediction_port1) begin    // 第二条奇指令是分支且预测跳转
            jump_flag_o = 1'b1;
            jump_addr_o = pre_addr[1];
            odd_inst_jump = 1'b1;
        end
        else begin                          // 两条指令都不跳转
            jump_flag_o = 1'b0;
            jump_addr_o = 32'b0;
            odd_inst_jump = 1'b1;
        end
    end
    else if (btb_tag_hit[0]) begin     // 第一条偶指令是分支跳转
        if (btb_is_branch[0]) begin    // 分支
            jump_flag_o = prediction_port0;
            jump_addr_o = pre_addr[0] & {32{prediction_port0}};   // 预测不跳转时地址无效
            odd_inst_jump = ~prediction_port0;
        end
        else begin                     // 无条件跳转
            jump_flag_o = 1'b1;
            jump_addr_o = pre_addr[0];
            odd_inst_jump = 1'b0;
        end
    end
    else if (btb_tag_hit[1]) begin     // 第二条奇指令是分支跳转
        if (btb_is_branch[1]) begin    // 分支
            jump_flag_o = prediction_port1;
            jump_addr_o = pre_addr[1] & {32{prediction_port1}};   // 预测不跳转时地址无效
            odd_inst_jump = 1'b1;
        end
        else begin                     // 无条件跳转
            jump_flag_o = 1'b1;
            jump_addr_o = pre_addr[1];
            odd_inst_jump = 1'b1;
        end
    end
    else begin                         // 都不是分支跳转
        jump_flag_o = 1'b0;
        jump_addr_o = 32'b0;
        odd_inst_jump = 1'b1;
    end
end


// 实例化
// BTB_64_plus
BTB_64_plus u_BTB(
    .clk(clk),
    .rst(rst),
    .pc(if_pc),                  
    .update_en(btb_update_en),                  // 执行阶段更新BTB使能
    .jump_target(jump_target),         // 实际跳转目标地址
    .ex_pc(ex_pc),                     // 执行阶段的pc
    .is_branch(is_branch),                  // 是否为分支指令
    .pre_port0(btb_rdata[0]),     
    .pre_port1(btb_rdata[1])
);

// LHP_8
LHP_8 u_LHP(
    .clk(clk),
    .rst(rst),          
    .if_pc(if_pc),
    // from ex
    .update_en(lhp_update_en),              // 更新使能
    .branch_taken(branch_taken),        // 实际跳转结果(1为跳转)
    .ex_pc(ex_pc),                      // 执行阶段分支指令的PC地址（用于更新标签）
    // to selector
    .prediction_port0(prediction_port0),        // 预测结果(1为跳转)
    .prediction_port1(prediction_port1)         // 预测结果(1为跳转) 
);

// RAS
RAS u_RAS(
    .clk(clk),
    .rst(rst),
    // from if
    .push_en(ras_push_en),                     // 压栈使能
    .data_in(ras_data_in),              // 压栈数据
    .pop_en(ras_pop_en),                      // 弹栈使能
    // from ex
    .restore_en(ras_restore_en),                 // 恢复栈指针使能
    .restore_ptr(ras_restore_ptr),          // 恢复栈指针值
    // to if
    .snap_ptr(ras_snap_ptr),         // 快照栈指针(传到if，用于保存快照)
    // to PC
    .data_out(ras_data_out),        // 弹栈数据(同时传到if，需要在ex进行验证)
    // from ctrl
    .hold_flag_i(ras_hold_flag_i)
);




endmodule