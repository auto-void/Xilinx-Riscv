`include "defines.vh"

`timescale 1ns / 1ps

module dcache (
    input clk,
    input rst,
    // from mem
    input [31:0] mem_addr,
    input mem_ren,
    // from dram
    input [127:0] cache_line,
    // from commit
    input mem_wen,
    input [1:0] mem_mask,
    input [31:0] mem_wdata,
    input [31:0] mem_waddr,
    // to commit
    output reg stall_store,             // store指令暂停标志
    // to mem
    output reg [31:0] mem_rdata,

    // to pipeline/ctrl
    output reg miss_hold,

    // to mem
    output reg cache_miss
);
localparam DRAM_ADDR_START = 32'h8010_0000;
localparam DRAM_ADDR_END   = 32'h8013_FFFF;
wire access_dram = mem_waddr[31] == 1'b1 && mem_waddr[21] == 1'b0;

// 地址映射
wire [8:0] tag;              // 标签
assign tag = mem_addr[17:9];

wire [8:0] wr_tag;           // 写标签
assign wr_tag = mem_waddr[17:9];

wire [4:0] raddr;            // 读索引
assign raddr = mem_addr[8:4];

wire [4:0] waddr;            // 写索引
assign waddr = mem_waddr[8:4];

wire [1:0] offset;           // 读取字偏移
assign offset = mem_addr[3:2];

wire [1:0] wr_offset;        // 写入字偏移
assign wr_offset = mem_waddr[3:2];

wire [1:0] mem_index;        // 写入字节偏移
assign mem_index = mem_waddr[1:0];

wire [137:0] dcache_rdata;
wire [137:0] commit_dcache_rdata;
reg  [137:0] dcache_wdata;
reg dcache_we;
reg [4:0] dcache_waddr;

Dcache u_Dcache_512B(
    .a(dcache_waddr),
    .d(dcache_wdata),
    .dpra(raddr),
    .clk(clk),
    .we(dcache_we),
    .spo(commit_dcache_rdata),
    .dpo(dcache_rdata)
);

// 判断是否命中
always @(*) begin
    cache_miss = 1'b1;

    if(dcache_rdata[137] && dcache_rdata[136:128] == tag) begin
        cache_miss = 1'b0;
    end

end

// 读
always @(*) begin
    case(offset)
        2'b00:   mem_rdata = dcache_rdata[31:0];
        2'b01:   mem_rdata = dcache_rdata[63:32];
        2'b10:   mem_rdata = dcache_rdata[95:64];
        default: mem_rdata = dcache_rdata[127:96];
    endcase
end

// 未命中时等待dram数据输出,进行行替换
reg [1:0] miss_cnt;
// reg [31:0] mem_addr_old;
// always @(posedge clk) mem_addr_old <= mem_addr;

// 读写同一行cache
wire access_conflict = mem_wen && access_dram && (raddr == waddr);
always @(posedge clk) begin
    if(!rst) begin
        miss_cnt <= 2'b0;
    end
    else if(access_conflict && cache_miss && mem_ren) begin
        miss_cnt <= 2'b0;
    end
    else if(cache_miss && mem_ren && miss_cnt < 2) begin
        miss_cnt <= miss_cnt + 1;
    end
    else begin
        miss_cnt <= 2'b0;
    end
end

always @(*) begin
    if (cache_miss && mem_ren && (miss_cnt < 2)) begin
        miss_hold = 1'b1;
    end
    else begin
        miss_hold = 1'b0;
    end
end

// 写
reg [31:0] commit_rdata;
always @(*) begin
    case(wr_offset)
        2'b00:   commit_rdata = commit_dcache_rdata[31:0];
        2'b01:   commit_rdata = commit_dcache_rdata[63:32];
        2'b10:   commit_rdata = commit_dcache_rdata[95:64];
        default: commit_rdata = commit_dcache_rdata[127:96];
    endcase
end
reg [31:0] dcache_new_data;    // 写命中时的写数据
always @(*) begin
    case (mem_mask)
        2'b10: begin
            dcache_new_data = mem_wdata;  // sw
        end
        2'b01: begin           // sh
            case (mem_index[1])
                1'b0: dcache_new_data = {commit_rdata[31:16], mem_wdata[15:0]};
                1'b1: dcache_new_data = {mem_wdata[31:16], commit_rdata[15:0]};
            endcase
        end
        2'b00: begin           // sb
            case (mem_index)
                2'b00: dcache_new_data = {commit_rdata[31:8], mem_wdata[7:0]};
                2'b01: dcache_new_data = {commit_rdata[31:16], mem_wdata[15:8], commit_rdata[7:0]};
                2'b10: dcache_new_data = {commit_rdata[31:24], mem_wdata[23:16], commit_rdata[15:0]};
                2'b11: dcache_new_data = {mem_wdata[31:24], commit_rdata[23:0]};
            endcase
        end
        default: begin
            dcache_new_data = 32'b0;
        end
    endcase
end

reg [127:0] dcache_update_line;
always @(*) begin
    case (wr_offset)
        2'b00:   dcache_update_line = {commit_dcache_rdata[127:32], dcache_new_data}; 
        2'b01:   dcache_update_line = {commit_dcache_rdata[127:64], dcache_new_data, commit_dcache_rdata[31:0]}; 
        2'b10:   dcache_update_line = {commit_dcache_rdata[127:96], dcache_new_data, commit_dcache_rdata[63:0]}; 
        default: dcache_update_line = {dcache_new_data, commit_dcache_rdata[95:0]};
    endcase
end



wire refill = (miss_cnt == 2);
wire write_hit = (mem_wen && access_dram && commit_dcache_rdata[137] && commit_dcache_rdata[136:128] == wr_tag);
always @(*) begin
    stall_store = 1'b0;
    dcache_we = 1'b0;
    dcache_wdata = 138'b0;

    if (refill) begin
        dcache_waddr = raddr;  // Refill 用读地址
    end 
    else begin
        dcache_waddr = waddr;
    end

    if (refill) begin
        stall_store = 1'b1;
        dcache_we = 1'b1;
        dcache_wdata = {1'b1,tag,cache_line};
    end
    else if (write_hit) begin
        dcache_we = 1'b1;
        dcache_wdata = {1'b1,wr_tag,dcache_update_line};
    end
end



endmodule