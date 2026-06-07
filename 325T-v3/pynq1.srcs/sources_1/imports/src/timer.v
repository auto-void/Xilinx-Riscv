`include "defines.vh"

`timescale 1ns / 1ps

module timer (
    input clk,
    input rst,

    // from cpu
    input [1:0] waddr,
    input [1:0] addr,            // 00：读mtime低32位 | 01：读mtime高32位 | 10：写mtimecmp低32位 | 11：写mtimecmp高32位
    input we,
    input [31:0] data_in,

    // to cpu
    output reg [31:0] data_out,
    output reg int_flag_o
);

reg [63:0] mtime;        // 记录系统运行时间，只读
reg [63:0] mtimecmp;     // 软件设置目标时间

// mtime复位后一直递增计时
always @(posedge clk) begin
    if (rst) begin               
        mtime <= 64'b0;          
    end 
    else begin                
        mtime <= mtime + 1'b1;     
    end
end

// mtimecmp写逻辑
always @(posedge clk) begin
    if (rst) begin               
        mtimecmp <= 64'b0;
    end 
    else if (we) begin          
        case (waddr)       
            2'b10: mtimecmp[31:0]  <= data_in;  
            2'b11: mtimecmp[63:32] <= data_in;  
            default: ;                           
        endcase
    end
end

// 读
always @(*) begin                               
    case (addr)                
        2'b00:   data_out = mtime[31:0];  
        2'b01:   data_out = mtime[63:32];  
        2'b10:   data_out = mtimecmp[31:0]; 
        2'b11:   data_out = mtimecmp[63:32];
        default: data_out = 32'b0;     
    endcase
end

// 触发中断
always @(posedge clk) begin
    if (rst) begin              
        int_flag_o <= 1'b0;        
    end 
    else begin                 
        int_flag_o <= (mtime >= mtimecmp);    // 比较mtime和mtimecmp，满足条件则中断拉高
    end
end


endmodule