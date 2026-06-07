`include "defines.vh"

`timescale 1ns / 1ps

module LSU_Mem (
    input clk,
    input rst,

    // from ex
    input inst_valid_i,               // 指令有效标志
    input [5:0] rob_id_i,             // ROB id
    input [3:0] mask_i,               // 分支掩码
    input [1:0] sq_id_i,              // SQ id
    input [3:0] subtype_i,            // 指令子类型
    input [31:0] rs2_data_i,          // rs2数据
    input [5:0] pwaddr_i,             // 物理寄存器写地址
    input [31:0] mem_addr_i,          // 访存地址

    // from clint
    input int_flag_i,                   // 中断标志

    // from branch
    input jump_flag_i,                 // 跳转标志
    input [1:0] kill_mask_id_i,        // 分支掩码id

    // from commit
    input commit_store_flag_i,             // 提交store指令标志

    // from commit
    input free_mask_inst0_i,                   // 指令0释放掩码标志
    input [1:0] free_id_inst0_i,               // 指令0释放id
    input free_mask_inst1_i,                   // 指令1释放掩码标志
    input [1:0] free_id_inst1_i,               // 指令1释放id

    // from peripheral
    input [31:0] perip_rdata,

    // from dcache
    input [31:0] dcache_rdata,
    input dcache_miss,

    // to dcache
    output dcache_ren,
    output [31:0] mem_addr_o,
    output flush_o,

    // to pipeline
    output stall_o,

    // to commit
    output [1:0] sq_mask_o,
    output [31:0] sq_addr_o,
    output [31:0] sq_data_o,

    // to regs
    output mem_reg_wflag_o,                     // Mem阶段load写寄存器标志(给ready置1)

    // to forward_unit and wb
    output [5:0] mem_reg_waddr_o,               // Mem阶段写寄存器地址(同时传到regs)
    output reg [31:0] mem_reg_wdata_o,          // Mem阶段写寄存器数据

    // to wb
    output inst_valid_o,
    output [3:0] subtype_o,              // 指令子类型

    // to ROB
    output store_complete_flag_o,            // store指令完成标志
    output [5:0] store_commit_rob_id_o       // store提交ROB id
);
assign store_complete_flag_o = inst_valid_i && (subtype_i[3] == 1'b1);
assign store_commit_rob_id_o = rob_id_i;
// 内存地址范围
localparam DRAM_ADDR_START = 32'h8010_0000;
localparam DRAM_ADDR_END   = 32'h8013_FFFF;
wire access_dram;
assign access_dram = mem_addr_i[31] == 1'b1 && mem_addr_i[21] == 1'b0;
assign mem_addr_o = mem_addr_i;
// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
assign inst_valid_o = inst_valid_i && ((mask_i & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效
assign subtype_o = subtype_i;
assign flush_o = inst_valid_i && ((mask_i & kill_mask) != 0); // 当前指令被冲刷
// reg [3:0] mask_o;
// always @(*) begin
//     mask_o = mask_i;
//     if (free_mask_inst0_i) begin
//         mask_o[free_id_inst0_i] = 1'b0;
//     end
//     if (free_mask_inst1_i) begin
//         mask_o[free_id_inst1_i] = 1'b0;
//     end
// end
// Store Queue
reg sq_valid[0:3];              // SQ有效位
reg [3:0] sq_br_mask[0:3];      // SQ分支掩码
reg [3:0] sq_byte_mask[0:3];    // SQ字节掩码
reg [1:0] sq_mem_mask[0:3];     // SQ存储掩码(00 = SB, 01 = SH, 10 = SW)
reg [31:0] sq_mem_addr[0:3];    // SQ存储访存地址
reg [31:0] sq_mem_data[0:3];    // SQ存储数据
integer i;
reg sq_we;                      // SQ写使能
reg [31:0] sq_w_data;           // SQ写数据
reg [31:0] sq_w_addr;           // SQ写地址
reg [3:0] sq_br_mask_wdata;     // SQ写分支掩码
reg [3:0] sq_byte_mask_wdata;   // SQ写字节掩码
reg [1:0] sq_mem_mask_wdata;    // SQ写存储掩码
// Store指令提交读取SQ
reg [1:0] sq_rd_ptr;           // SQ读指针
assign sq_mask_o = sq_mem_mask[sq_rd_ptr];
assign sq_addr_o = sq_mem_addr[sq_rd_ptr];
assign sq_data_o = sq_mem_data[sq_rd_ptr];
// SQ写入逻辑
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sq_rd_ptr <= 2'b0;
        for (i = 0; i < 4; i = i + 1) begin
            sq_valid[i] <= 1'b0;
            sq_br_mask[i] <= 4'b0;
            sq_byte_mask[i] <= 4'b0;
            sq_mem_mask[i] <= 2'b0;
            sq_mem_addr[i] <= 32'b0;
            sq_mem_data[i] <= 32'b0;
        end
    end
    else if (int_flag_i) begin
        sq_rd_ptr <= 2'b0;
        for (i = 0; i < 4; i = i + 1) begin
            sq_valid[i] <= 1'b0;
        end
    end
    else begin
        if (jump_flag_i) begin
            // 冲刷
            for (i = 0; i < 4; i = i + 1) begin
                if ((sq_br_mask[i] & kill_mask) != 0) begin
                    sq_valid[i] <= 1'b0; // 如果SQ条目的分支掩码被kill_mask覆盖，则无效
                end
            end
        end
        // 写入
        if (sq_we) begin // sq_we为1，证明当前指令未被冲刷
            sq_valid[sq_id_i] <= 1'b1;
            sq_br_mask[sq_id_i] <= sq_br_mask_wdata;
            sq_byte_mask[sq_id_i] <= sq_byte_mask_wdata;
            sq_mem_mask[sq_id_i] <= sq_mem_mask_wdata;
            sq_mem_addr[sq_id_i] <= sq_w_addr;
            sq_mem_data[sq_id_i] <= sq_w_data;
        end
        // 提交
        if (free_mask_inst0_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                sq_br_mask[i][free_id_inst0_i] <= 1'b0; // 指令0释放，检查并清除所有被其分支掩码覆盖的SQ条目
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                sq_br_mask[i][free_id_inst1_i] <= 1'b0; // 指令1释放，检查并清除所有被其分支掩码覆盖的SQ条目
            end
        end
        if (commit_store_flag_i) begin
            sq_valid[sq_rd_ptr] <= 1'b0;      // 提交store指令，SQ条目完成，置无效
            sq_rd_ptr <= sq_rd_ptr + 1'b1;    // SQ读指针前移
        end
    end
end

// SQ匹配辅助变量定义
reg [3:0] load_byte_mask;         // 当前Load指令需要的字节掩码
reg [3:0] sq_match_vec;           // 4个SQ条目的匹配状态(Mask重叠) vector
reg sq_multi_match;               // 是否存在多于1个的SQ匹配 (需要Stall)
// reg sq_full_hit;                  // 是否所需的字节全在SQ里 (不需要读Dcache)
// reg [3:0] effective_byte_from_sq; // SQ能提供的有效字节总和
integer k;
assign dcache_ren = inst_valid_i && access_dram && (subtype_i[3] == 1'b0) && !sq_multi_match;
assign stall_o = inst_valid_i && (subtype_i[3] == 1'b0) && sq_multi_match; // 如果Load指令存在多于1个的SQ匹配，Stall等待
assign mem_reg_waddr_o = pwaddr_i;
assign mem_reg_wflag_o = inst_valid_i && (subtype_i[3] == 1'b0) && !sq_multi_match;
// 匹配逻辑
always @(*) begin
    // Load Mask 生成
    case (subtype_i)
        `MEM_LB, `MEM_LBU: load_byte_mask = 4'b0001 << mem_addr_i[1:0];
        `MEM_LH, `MEM_LHU: load_byte_mask = (mem_addr_i[1] == 0) ? 4'b0011 : 4'b1100;
        `MEM_LW:           load_byte_mask = 4'b1111;
        default:           load_byte_mask = 4'b0000;
    endcase

    // SQ 扫描与状态生成
    sq_match_vec = 4'b0000;
    // effective_byte_from_sq = 4'b0000;
    for (k = 0; k < 4; k = k + 1) begin
        // 只有 Valid 且 Address(字对齐) 匹配才算
        if (sq_valid[k] && (sq_mem_addr[k][31:2] == mem_addr_i[31:2])) begin
            // 只要有任何字节重叠，就标记为匹配
            if ((sq_byte_mask[k] & load_byte_mask) != 0) begin
                sq_match_vec[k] = 1'b1;
                // effective_byte_from_sq = effective_byte_from_sq | sq_byte_mask[k];
            end
        end
    end

    // 多重匹配判断
    case (sq_match_vec)
        4'b0000: sq_multi_match = 1'b0;
        default: sq_multi_match = 1'b1;
    endcase

    // 全覆盖判断
    // sq_full_hit = ((load_byte_mask & effective_byte_from_sq) == load_byte_mask);
end


// 拼接合并逻辑
// reg [31:0] base_data_32;        // 基底数据 (Cache or Perip)
// reg [7:0]  merged_byte_0, merged_byte_1, merged_byte_2, merged_byte_3;
// reg [31:0] final_merged_32;     // 合并完全部数据后的32位宽结果
// always @(*) begin
//     base_data_32 = 32'b0;
//     merged_byte_0 = 8'b0;
//     merged_byte_1 = 8'b0;
//     merged_byte_2 = 8'b0;
//     merged_byte_3 = 8'b0;
//     final_merged_32 = 32'b0;

//     // 选择基底数据
//     if (access_dram && !dcache_miss) begin
//         base_data_32 = dcache_rdata;
//     end 
//     else begin
//         base_data_32 = perip_rdata;
//     end

//     // 将基底数据拆分为字节
//     merged_byte_0 = base_data_32[7:0];
//     merged_byte_1 = base_data_32[15:8];
//     merged_byte_2 = base_data_32[23:16];
//     merged_byte_3 = base_data_32[31:24];

//     // SQ 数据覆盖
//     for (i = 0; i < 4; i = i + 1) begin
//         // 如果该 SQ 条目命中 (Address Match & Valid)
//         if (sq_match_vec[i]) begin
//             // 逐字节检查并覆盖
//             if (sq_byte_mask[i][0]) merged_byte_0 = sq_mem_data[i][7:0];
//             if (sq_byte_mask[i][1]) merged_byte_1 = sq_mem_data[i][15:8];
//             if (sq_byte_mask[i][2]) merged_byte_2 = sq_mem_data[i][23:16];
//             if (sq_byte_mask[i][3]) merged_byte_3 = sq_mem_data[i][31:24];
//         end
//     end

//     // 重组成 32位数据 (此时包含了 SQ 和 Cache/Perip 的混合数据)
//     final_merged_32 = {merged_byte_3, merged_byte_2, merged_byte_1, merged_byte_0};
// end
// 访存操作逻辑
reg [31:0] dcache_wdata;
reg [31:0] perip_wdata;
always @(*) begin
    mem_reg_wdata_o = 32'b0;
    if (access_dram && !dcache_miss) begin
        mem_reg_wdata_o = dcache_wdata;
    end 
    else begin
        mem_reg_wdata_o = perip_wdata;
    end
end
always @(*) begin
    // L type
    dcache_wdata = 32'b0;
    perip_wdata = 32'b0;
    // S type
    sq_we = 1'b0;
    sq_w_data = 32'b0;
    sq_w_addr = mem_addr_i;
    sq_br_mask_wdata = mask_i;
    sq_byte_mask_wdata = 4'b0;
    sq_mem_mask_wdata = 2'b0;
    case (subtype_i)
        `MEM_SB: begin
            sq_we = inst_valid_o;
            sq_mem_mask_wdata = 2'b00;
            case (mem_addr_i[1:0])
                2'b00: begin
                    sq_byte_mask_wdata = 4'b0001;
                    sq_w_data = {24'b0, rs2_data_i[7:0]};
                end
                2'b01: begin
                    sq_byte_mask_wdata = 4'b0010;
                    sq_w_data = {16'b0, rs2_data_i[7:0], 8'b0};
                end
                2'b10: begin
                    sq_byte_mask_wdata = 4'b0100;
                    sq_w_data = {8'b0, rs2_data_i[7:0], 16'b0};
                end
                2'b11: begin
                    sq_byte_mask_wdata = 4'b1000;
                    sq_w_data = {rs2_data_i[7:0], 24'b0};
                end
            endcase
        end
        `MEM_SH: begin
            sq_we = inst_valid_o;
            sq_mem_mask_wdata = 2'b01;
            case (mem_addr_i[1])
                1'b0: begin
                    sq_byte_mask_wdata = 4'b0011;
                    sq_w_data = {16'b0, rs2_data_i[15:0]};
                end
                1'b1: begin
                    sq_byte_mask_wdata = 4'b1100;
                    sq_w_data = {rs2_data_i[15:0], 16'b0};
                end
            endcase
        end
        `MEM_SW: begin
            sq_we = inst_valid_o;
            sq_mem_mask_wdata = 2'b10;
            sq_byte_mask_wdata = 4'b1111;
            sq_w_data = rs2_data_i;
        end
        `MEM_LB: begin
            case (mem_addr_i[1:0])
                2'b00: begin
                    dcache_wdata = {{24{dcache_rdata[7]}}, dcache_rdata[7:0]};
                    perip_wdata = {{24{perip_rdata[7]}}, perip_rdata[7:0]};
                end
                2'b01: begin
                    dcache_wdata = {{24{dcache_rdata[15]}}, dcache_rdata[15:8]};
                    perip_wdata = {{24{perip_rdata[15]}}, perip_rdata[15:8]};
                end
                2'b10: begin
                    dcache_wdata = {{24{dcache_rdata[23]}}, dcache_rdata[23:16]};
                    perip_wdata = {{24{perip_rdata[23]}}, perip_rdata[23:16]};
                end
                2'b11: begin
                    dcache_wdata = {{24{dcache_rdata[31]}}, dcache_rdata[31:24]};
                    perip_wdata = {{24{perip_rdata[31]}}, perip_rdata[31:24]};
                end
            endcase
        end
        `MEM_LH: begin
            case (mem_addr_i[1])
                1'b0: begin
                    dcache_wdata = {{16{dcache_rdata[15]}}, dcache_rdata[15:0]};
                    perip_wdata = {{16{perip_rdata[15]}}, perip_rdata[15:0]};
                end
                1'b1: begin
                    dcache_wdata = {{16{dcache_rdata[31]}}, dcache_rdata[31:16]};
                    perip_wdata = {{16{perip_rdata[31]}}, perip_rdata[31:16]};
                end
            endcase
        end
        `MEM_LW: begin
            dcache_wdata = dcache_rdata;
            perip_wdata = perip_rdata;
        end
        `MEM_LBU: begin
            case (mem_addr_i[1:0])
                2'b00: begin
                    dcache_wdata = {24'b0, dcache_rdata[7:0]};
                    perip_wdata = {24'b0, perip_rdata[7:0]};
                end
                2'b01: begin
                    dcache_wdata = {24'b0, dcache_rdata[15:8]};
                    perip_wdata = {24'b0, perip_rdata[15:8]};
                end
                2'b10: begin
                    dcache_wdata = {24'b0, dcache_rdata[23:16]};
                    perip_wdata = {24'b0, perip_rdata[23:16]};
                end
                2'b11: begin
                    dcache_wdata = {24'b0, dcache_rdata[31:24]};
                    perip_wdata = {24'b0, perip_rdata[31:24]};
                end
            endcase
        end
        `MEM_LHU: begin
            case (mem_addr_i[1])
                1'b0: begin
                    dcache_wdata = {16'b0, dcache_rdata[15:0]};
                    perip_wdata = {16'b0, perip_rdata[15:0]};
                end
                1'b1: begin
                    dcache_wdata = {16'b0, dcache_rdata[31:16]};
                    perip_wdata = {16'b0, perip_rdata[31:16]};
                end
            endcase
        end
        default: begin
            dcache_wdata = 32'b0;
            perip_wdata = 32'b0;
        end
    endcase
end





endmodule