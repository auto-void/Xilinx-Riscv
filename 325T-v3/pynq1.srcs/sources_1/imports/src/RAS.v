`include "defines.vh"

`timescale 1ns / 1ps

// 返回地址栈，处理jalr指令从函数返回的场景
module RAS(
    input clk,
    input rst,
    // from if
    input push_en,                     // 压栈使能
    input [31:0] data_in,              // 压栈数据
    input pop_en,                      // 弹栈使能

    // from ex
    input restore_en,                 // 恢复栈指针使能
    input [2:0] restore_ptr,          // 恢复栈指针值

    // to if
    output [2:0] snap_ptr,         // 快照栈指针(传到if，用于保存快照)
    
    // to PC
    output [31:0] data_out,        // 弹栈数据(同时传到if，需要在ex进行验证)

    // from ctrl
    input hold_flag_i

);

reg [31:0] stack[0:7];          // 栈
reg [2:0] top_ptr;              // 栈顶指针（指向下一个未压栈的位置）
integer i;

// 压栈
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        top_ptr <= 3'd0;
        for(i = 0; i < 8; i = i + 1) begin
            stack[i] <= 32'b0;
        end
    end
    else if(restore_en) begin
        top_ptr <= restore_ptr;
    end
    else if(hold_flag_i) begin
        top_ptr <= top_ptr;
    end
    else if(push_en) begin
        stack[top_ptr] <= data_in;
        top_ptr <= top_ptr + 3'd1;
    end
    else if(pop_en) begin
        top_ptr <= top_ptr - 3'd1;
    end
end

// 弹栈
assign data_out = stack[top_ptr - 3'd1];

assign snap_ptr = push_en ? (top_ptr + 3'd1) :
                  pop_en  ? (top_ptr - 3'd1) :
                            (top_ptr);



endmodule