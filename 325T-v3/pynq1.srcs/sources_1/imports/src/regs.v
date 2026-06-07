`include "defines.vh"

`timescale 1ns / 1ps

// 通用寄存器模块
module regs(
    input clk,
    input rst,

    // from ALU0
    input alu0_exe_wflag_i,         // 执行阶段写寄存器标志
    input [5:0] alu0_exe_waddr_i,   // 执行阶段写寄存器地址
    input alu0_wflag_i,             // 写回阶段写寄存器标志
    input [5:0] alu0_waddr_i,       // 写回阶段写寄存器地址
    input [31:0] alu0_wdata_i,      // 写回阶段写寄存器数据

    // from ALU1
    input alu1_exe_wflag_i,         // 执行阶段写寄存器标志
    input [5:0] alu1_exe_waddr_i,   // 执行阶段写寄存器地址
    input alu1_wflag_i,             // 写回阶段写寄存器标志
    input [5:0] alu1_waddr_i,       // 写回阶段写寄存器地址
    input [31:0] alu1_wdata_i,      // 写回阶段写寄存器数据

    // from branch
    input branch_rf_wflag_i,            // 读寄存器文件阶段写寄存器标志
    input [5:0] branch_rf_waddr_i,      // 读寄存器文件阶段写寄存器地址
    input branch_wflag_i,               // 写回阶段写寄存器标志
    input [5:0] branch_waddr_i,         // 写回阶段写寄存器地址
    input [31:0] branch_wdata_i,        // 写回阶段写寄存器数据

    // from mem
    input mem_exe_wflag_i,           // 执行阶段写寄存器标志
    input [5:0] mem_exe_waddr_i,     // 执行阶段写寄存器地址
    input mem_wflag_i,               // 写回阶段写寄存器标志
    input [5:0] mem_waddr_i,         // 写回阶段写寄存器地址
    input [31:0] mem_wdata_i,        // 写回阶段写寄存器数据

    `ifdef use_m_extension
    // from mul
    input mul_exe_wflag_i,           // 执行阶段写寄存器标志
    input [5:0] mul_exe_waddr_i,     // 执行阶段写寄存器地址
    input mul_wflag_i,               // 写回阶段写寄存器标志
    input [5:0] mul_waddr_i,         // 写回阶段写寄存器地址
    input [31:0] mul_wdata_i,        // 写回阶段写寄存器数据

    // from div
    input div_exe_wflag_i,           // 执行阶段写寄存器标志
    input [5:0] div_exe_waddr_i,     // 执行阶段写寄存器地址
    input div_wflag_i,               // 写回阶段写寄存器标志
    input [5:0] div_waddr_i,         // 写回阶段写寄存器地址
    input [31:0] div_wdata_i,        // 写回阶段写寄存器数据
    `endif

    // from RF
    // from ALU_iss_que
    input [5:0] alu_inst0_raddr1_i,      // 读寄存器1地址
    input [5:0] alu_inst0_raddr2_i,      // 读寄存器2地址
    input [5:0] alu_inst1_raddr1_i,      // 读寄存器1地址
    input [5:0] alu_inst1_raddr2_i,      // 读寄存器2地址

    // from branch_iss_que
    input [5:0] branch_raddr1_i,         // 读寄存器1地址
    input [5:0] branch_raddr2_i,         // 读寄存器2地址

    // from mem_iss_que
    input [5:0] mem_raddr1_i,            // 读寄存器1地址
    input [5:0] mem_raddr2_i,            // 读寄存器2地址

    `ifdef use_m_extension
    // from mul_iss_que
    input [5:0] mul_raddr1_i,            // 读寄存器1地址
    input [5:0] mul_raddr2_i,            // 读寄存器2地址

    // from div_iss_que
    input [5:0] div_raddr1_i,            // 读寄存器1地址
    input [5:0] div_raddr2_i,            // 读寄存器2地址
    `endif

    // from commit
    input [5:0] csr_raddr_i,             // CSR指令在提交阶段才读取执行结果，所以CSR寄存器的读地址由commit阶段提供
    input csr_wflag_i,                   // CSR指令写回阶段写寄存器标志
    input [5:0] csr_waddr_i,             // CSR指令写回阶段写寄存器地址
    input [31:0] csr_wdata_i,            // CSR指令写回阶段写寄存器数据

    // from rename
    input alloc_flag_inst0_i,             // Inst0是否分配物理寄存器
    input [5:0] alloc_paddr_inst0_i,      // Inst0分配的物理寄存器地址
    input alloc_flag_inst1_i,             // Inst1是否分配物理寄存器
    input [5:0] alloc_paddr_inst1_i,      // Inst1分配的物理寄存器地址

    // to commit
    output reg [31:0] csr_rdata_o,       // CSR指令读RS1数据

    // to RF
    output [63:0] ready_flag_o,              // 寄存器就绪标志，位0-63分别对应物理寄存器0-63
    output reg [31:0] alu_inst0_rdata1_o,    // 读寄存器1数据
    output reg [31:0] alu_inst0_rdata2_o,    // 读寄存器2数据
    output reg [31:0] alu_inst1_rdata1_o,    // 读寄存器1数据
    output reg [31:0] alu_inst1_rdata2_o,    // 读寄存器2数据
    output reg [31:0] branch_rdata1_o,       // 读寄存器1数据
    output reg [31:0] branch_rdata2_o,       // 读寄存器2数据
    output reg [31:0] mem_rdata1_o,          // 读寄存器1数据
    output reg [31:0] mem_rdata2_o           // 读寄存器2数据
    `ifdef use_m_extension
    ,output reg [31:0] mul_rdata1_o,         // 读寄存器1数据
    output reg [31:0] mul_rdata2_o,          // 读寄存器2数据
    output reg [31:0] div_rdata1_o,          // 读寄存器1数据
    output reg [31:0] div_rdata2_o           // 读寄存器2数据
    `endif

);

reg [31:0] regs[0:63];    // 物理寄存器
reg [63:0] ready;         // 寄存器就绪标志，位0-63分别对应物理寄存器0-63
integer i;
assign ready_flag_o = ready;
// always @(*) begin
//     ready_flag_o[0] = ready[0];  // x0寄存器始终就绪
//     for (i = 1; i < 64; i = i + 1) begin
//         // 已写回或者正在写入可以旁路
//         ready_flag_o[i] = ready[i] || (branch_wflag_i && (branch_waddr_i == i[5:0]));
//     end
// end

// 写
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        ready <= {32'b0, 32'hFFFF_FFFF};
        for (i = 0; i < 64; i = i + 1) begin     // 用for循环初始化
            regs[i] <= 32'b0;
        end
    end
    else begin       // 无法对x0寄存器写入
        // 写寄存器，将ready置1
        if (alu0_exe_wflag_i && alu0_exe_waddr_i != 0)     ready[alu0_exe_waddr_i]  <= 1'b1;
        if (alu1_exe_wflag_i && alu1_exe_waddr_i != 0)     ready[alu1_exe_waddr_i]  <= 1'b1;
        if (branch_rf_wflag_i && branch_rf_waddr_i != 0)   ready[branch_rf_waddr_i] <= 1'b1;
        if (mem_exe_wflag_i && mem_exe_waddr_i != 0)       ready[mem_exe_waddr_i]   <= 1'b1;
        if (csr_wflag_i && csr_waddr_i != 0)               ready[csr_waddr_i]       <= 1'b1;
        `ifdef use_m_extension
        if (mul_exe_wflag_i && mul_exe_waddr_i != 0)       ready[mul_exe_waddr_i]   <= 1'b1;
        if (div_exe_wflag_i && div_exe_waddr_i != 0)       ready[div_exe_waddr_i]   <= 1'b1;
        `endif
        // 分配物理寄存器，将ready清零
        if (alloc_flag_inst0_i && alloc_paddr_inst0_i != 0)
            ready[alloc_paddr_inst0_i] <= 1'b0;
        if (alloc_flag_inst1_i && alloc_paddr_inst1_i != 0)
            ready[alloc_paddr_inst1_i] <= 1'b0;

        // 使用 i 从 1 开始，天然保护了 x0，x0 自动被综合为常数 0
        for(i = 1; i < 64; i = i + 1) begin
            if (alu0_wflag_i && (alu0_waddr_i == i[5:0])) // ALU0
                regs[i] <= alu0_wdata_i;
            else if (alu1_wflag_i && (alu1_waddr_i == i[5:0])) // ALU1
                regs[i] <= alu1_wdata_i;
            else if (branch_wflag_i && (branch_waddr_i == i[5:0])) // Branch
                regs[i] <= branch_wdata_i;
            else if (mem_wflag_i && (mem_waddr_i == i[5:0])) // Mem
                regs[i] <= mem_wdata_i;
            else if (csr_wflag_i && (csr_waddr_i == i[5:0])) // CSR
                regs[i] <= csr_wdata_i;
            `ifdef use_m_extension
            else if (mul_wflag_i && (mul_waddr_i == i[5:0])) // Mul
                regs[i] <= mul_wdata_i;
            else if (div_wflag_i && (div_waddr_i == i[5:0])) // Div
                regs[i] <= div_wdata_i;
            `endif
        end
    end
end

// 读
// function [31:0] read_reg;
//     input [5:0] raddr;

//     reg [31:0] bypass_data;
//     reg bypass_hit;
//     // 临时变量，用于判断是否命中
//     reg hit_alu0, hit_alu1, hit_branch, hit_mem;

//     `ifdef use_m_extension
//     reg  hit_mul, hit_div;
//     `endif

//     begin
//         if (raddr == 6'b0) begin
//             read_reg = 32'b0;
//         end
//         else begin
//             // 并行比较命中信号
//             hit_alu0 = alu0_wflag_i && (alu0_waddr_i == raddr);
//             hit_alu1 = alu1_wflag_i && (alu1_waddr_i == raddr);
//             hit_branch = branch_wflag_i && (branch_waddr_i == raddr);
//             hit_mem = mem_wflag_i && (mem_waddr_i == raddr);

//             `ifdef use_m_extension
//             hit_mul = mul_wflag_i && (mul_waddr_i == raddr);
//             hit_div = div_wflag_i && (div_waddr_i == raddr);
//             `endif

//             // 并行数据选择
//             bypass_data = ({32{hit_alu0}} & alu0_wdata_i) |
//                           ({32{hit_alu1}} & alu1_wdata_i) |
//                           ({32{hit_branch}} & branch_wdata_i) |
//                           ({32{hit_mem}} & mem_wdata_i)
//                           `ifdef use_m_extension
//                           | ({32{hit_mul}} & mul_wdata_i) 
//                           | ({32{hit_div}} & div_wdata_i)
//                           `endif
//                           ;
            
//             bypass_hit = hit_alu0 | hit_alu1 | hit_branch | hit_mem
//             `ifdef use_m_extension
//             | hit_mul | hit_div
//             `endif
//             ;

//             // 最终选择旁路数据或堆数据
//             if (bypass_hit)
//                 read_reg = bypass_data;
//             else
//                 read_reg = regs[raddr];
//         end
//     end
// endfunction

always @(*) begin
    // // ALU Inst0
    // alu_inst0_rdata1_o = read_reg(alu_inst0_raddr1_i);
    // alu_inst0_rdata2_o = read_reg(alu_inst0_raddr2_i);
    // // ALU Inst1
    // alu_inst1_rdata1_o = read_reg(alu_inst1_raddr1_i);
    // alu_inst1_rdata2_o = read_reg(alu_inst1_raddr2_i);
    // // Branch
    // branch_rdata1_o = read_reg(branch_raddr1_i);
    // branch_rdata2_o = read_reg(branch_raddr2_i);
    // // Mem
    // mem_rdata1_o = read_reg(mem_raddr1_i);
    // mem_rdata2_o = read_reg(mem_raddr2_i);
    // `ifdef use_m_extension
    // // Mul
    // mul_rdata1_o = read_reg(mul_raddr1_i);
    // mul_rdata2_o = read_reg(mul_raddr2_i);
    // // Div
    // div_rdata1_o = read_reg(div_raddr1_i);
    // div_rdata2_o = read_reg(div_raddr2_i);
    // `endif
    `read_reg(alu_inst0_raddr1_i, alu_inst0_rdata1_o);
    `read_reg(alu_inst0_raddr2_i, alu_inst0_rdata2_o);
    `read_reg(alu_inst1_raddr1_i, alu_inst1_rdata1_o);
    `read_reg(alu_inst1_raddr2_i, alu_inst1_rdata2_o);
    `read_reg(branch_raddr1_i, branch_rdata1_o);
    `read_reg(branch_raddr2_i, branch_rdata2_o);
    `read_reg(mem_raddr1_i, mem_rdata1_o);
    `read_reg(mem_raddr2_i, mem_rdata2_o);
    `ifdef use_m_extension
    `read_reg(mul_raddr1_i, mul_rdata1_o);
    `read_reg(mul_raddr2_i, mul_rdata2_o);
    `read_reg(div_raddr1_i, div_rdata1_o);
    `read_reg(div_raddr2_i, div_rdata2_o);
    `endif
    // CSR
    if (csr_raddr_i == 6'b0) begin
        csr_rdata_o = 32'b0;
    end
    else begin
        csr_rdata_o = regs[csr_raddr_i];    // CSR执行时前面指令已全部提交写回，不需要旁路
    end
end



endmodule