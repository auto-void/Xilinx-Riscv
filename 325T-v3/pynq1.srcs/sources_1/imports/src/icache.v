`include "defines.vh"

`timescale 1ns / 1ps

module icache (
    input clk,
    input rst,
    // from if
    input [31:0] pc,
    // from irom
    input [255:0] cache_line,
    // to if
    output reg [63:0] inst_o,
    // to pipeline
    output reg miss_hold,
    // to if
    output reg cache_miss

);

// 地址映射
wire [6:0] tag;              // 标签
assign tag = pc[15:9];

wire [3:0] index;            // 索引
assign index = pc[8:5];

wire [1:0] offset;                 // 偏移
assign offset = pc[4:3];

wire [255:0] icache_rdata[0:1];
wire [6:0]   icache_tag_rdata[0:1];
wire         icache_valid_rdata[0:1];

wire icache_way0_we, icache_way1_we;

Icache u_Icache_way0(
    .a(index),
    .d(cache_line),
    .clk(clk),
    .we(icache_way0_we),
    .spo(icache_rdata[0])
);

icache_tag u_Icache_tag_way0(
    .a(index),
    .d({1'b1, tag}),
    .clk(clk),
    .we(icache_way0_we),
    .spo({icache_valid_rdata[0], icache_tag_rdata[0]})
);

Icache u_Icache_way1(
    .a(index),
    .d(cache_line),
    .clk(clk),
    .we(icache_way1_we),
    .spo(icache_rdata[1])
);

icache_tag u_Icache_tag_way1(
    .a(index),
    .d({1'b1, tag}),
    .clk(clk),
    .we(icache_way1_we),
    .spo({icache_valid_rdata[1], icache_tag_rdata[1]})
);

// 判断是否命中
reg hit_way;
always @(*) begin
    cache_miss = 1'b1;
    hit_way = 1'b0;

    if((icache_valid_rdata[0] && icache_tag_rdata[0] == tag) || (icache_valid_rdata[1] && icache_tag_rdata[1] == tag)) begin
        cache_miss = 1'b0;
    end

    if(icache_valid_rdata[0] && icache_tag_rdata[0] == tag) begin
        hit_way = 1'b0;
    end
    else if(icache_valid_rdata[1] && icache_tag_rdata[1] == tag) begin
        hit_way = 1'b1;
    end
end

reg lru_way[0:15];
integer i;
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        for(i = 0; i < 16; i = i + 1) begin
            lru_way[i] <= 1'b0;
        end
    end
    else if(icache_way0_we) begin
        lru_way[index] <= 1'b1;
    end
    else if(icache_way1_we) begin
        lru_way[index] <= 1'b0;
    end
    else if(!cache_miss) begin
        lru_way[index] <= ~hit_way;
    end
end

// 命中时输出
always @(*) begin
    case (offset)
        2'b00: inst_o = hit_way ? icache_rdata[1][63:0] : icache_rdata[0][63:0];
        2'b01: inst_o = hit_way ? icache_rdata[1][127:64] : icache_rdata[0][127:64];
        2'b10: inst_o = hit_way ? icache_rdata[1][191:128] : icache_rdata[0][191:128];
        2'b11: inst_o = hit_way ? icache_rdata[1][255:192] : icache_rdata[0][255:192];
    endcase
end

// 未命中时等待irom数据输出,进行行替换
reg [1:0] miss_cnt;
reg [31:0] old_pc;
always @(posedge clk) begin
    old_pc <= pc;
end

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        miss_cnt <= 2'b0;
    end
    else if(pc != old_pc && cache_miss) begin
        miss_cnt <= 2'b1;
    end
    else if(cache_miss && miss_cnt < 2) begin
        miss_cnt <= miss_cnt + 1;
    end
    else begin
        miss_cnt <= 2'b0;
    end
end

always @(*) begin
    if (cache_miss && (miss_cnt < 2 || pc != old_pc)) begin
        miss_hold = 1'b1;
    end
    else begin
        miss_hold = 1'b0;
    end
end

assign icache_way0_we = (miss_cnt == 2 && pc == old_pc && lru_way[index] == 1'b0);
assign icache_way1_we = (miss_cnt == 2 && pc == old_pc && lru_way[index] == 1'b1);



endmodule