`include "defines.vh"

`timescale 1ns / 1ps

// Load Store Unit
module LSU (
    input clk,
    input rst,

    // from issue
    input inst_valid_i,               // 指令有效标志
    input [5:0] rob_id_i,             // ROB id
    input [3:0] mask_i,               // 分支掩码
    input [1:0] sq_id_i,              // SQ id
    input [3:0] subtype_i,            // 指令子类型
    input [5:0] praddr1_i,            // 物理寄存器1读地址
    input [5:0] praddr2_i,            // 物理寄存器2读地址
    input [5:0] pwaddr_i,             // 物理寄存器写地址
    input [31:0] imm_i,               // 立即数

    // from forward_unit
    input rs1_forward_flag_i,           // rs1转发标志
    input [31:0] rs1_forward_data_i,    // rs1转发数据
    input rs2_forward_flag_i,           // rs2转发标志
    input [31:0] rs2_forward_data_i,    // rs2转发数据

    // from regs
    input [31:0] reg_rdata1_i,          // 寄存器1读数据
    input [31:0] reg_rdata2_i,          // 寄存器2读数据

    // from clint
    input int_flag_i,                   // 中断标志

    // from branch
    input jump_flag_i,                 // 跳转标志
    input [1:0] kill_mask_id_i,        // 分支掩码id

    // from commit
    input free_mask_inst0_i,                   // 指令0释放掩码标志
    input [1:0] free_id_inst0_i,               // 指令0释放id
    input free_mask_inst1_i,                   // 指令1释放掩码标志
    input [1:0] free_id_inst1_i,               // 指令1释放id

    // from commit
    input commit_store_flag_i,             // 提交store指令标志

    // from peripheral
    input [31:0] perip_rdata,

    // to peripheral
    output [31:0] mem_addr_o,

    // dcache 接口
    // from dram
    input [127:0] cache_line,
    // from commit
    input mem_wen,

    // to peripheral
    output [1:0] sq_mask_o,
    output [31:0] sq_addr_o,
    output [31:0] sq_data_o,

    // to commit
    output stall_store,                 // store指令暂停标志

    // to regs
    output [5:0] rf_raddr1_o,           // RF 阶段读寄存器1地址（同时传到转发模块）
    output [5:0] rf_raddr2_o,           // RF 阶段读寄存器2地址（同时传到转发模块）
    output reg_wflag_o,                 // 写回阶段写寄存器标志
    output [5:0] reg_waddr_o,           // 写回阶段写寄存器地址
    output [31:0] reg_wdata_o,          // 写回阶段写寄存器数据
    output mem_reg_wflag_o,             // Mem阶段写寄存器标志

    // to issue
    output flush_o,                     // 冲刷标志
    output stall_o,

    // to forward_unit
    output [5:0] mem_reg_waddr_o,           // Mem阶段写寄存器地址(同时传到regs)
    output [31:0] mem_reg_wdata_o,          // Mem阶段写寄存器数据

    // to ROB
    output store_complete_flag_o,             // store指令完成标志
    output [5:0] store_commit_rob_id_o,       // store提交ROB id
    output load_complete_flag_o,              // load指令完成标志
    output [5:0] load_commit_rob_id_o         // load提交ROB id
);

// rf
wire rf_inst_valid_o;               // 指令有效标志
wire [5:0] rf_rob_id_o;             // ROB id
wire [3:0] rf_mask_o;               // 分支掩码
wire [1:0] rf_sq_id_o;              // SQ id
wire [3:0] rf_subtype_o;            // 指令子类型
wire [31:0] rf_rs1_data_o;          // rs1数据
wire [31:0] rf_rs2_data_o;          // rs2数据
wire [5:0] rf_pwaddr_o;             // 物理寄存器写地址
wire [31:0] rf_imm_o;               // 立即数

LSU_RF u_LSU_RF(
    // from issue
    .inst_valid_i(inst_valid_i),               // 指令有效标志
    .rob_id_i(rob_id_i),             // ROB id
    .mask_i(mask_i),               // 分支掩码
    .sq_id_i(sq_id_i),              // SQ id
    .subtype_i(subtype_i),            // 指令子类型
    .praddr1_i(praddr1_i),            // 物理寄存器1读地址
    .praddr2_i(praddr2_i),            // 物理寄存器2读地址
    .pwaddr_i(pwaddr_i),              // 物理寄存器写地址
    .imm_i(imm_i),                    // 立即数
    // from forward_unit
    .rs1_forward_flag_i(rs1_forward_flag_i),           // rs1转发标志
    .rs1_forward_data_i(rs1_forward_data_i),    // rs1转发数据
    .rs2_forward_flag_i(rs2_forward_flag_i),           // rs2转发标志
    .rs2_forward_data_i(rs2_forward_data_i),    // rs2转发数据
    // from regs
    .reg_rdata1_i(reg_rdata1_i),          // 寄存器1读数据
    .reg_rdata2_i(reg_rdata2_i),          // 寄存器2读数据
    // from branch
    .jump_flag_i(jump_flag_i),                 // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),        // 分支掩码id
    // from commit
    .free_mask_inst0_i(free_mask_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_mask_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_id_inst1_i),               // 指令1释放id
    // to regs
    .rf_raddr1_o(rf_raddr1_o),           // RF 阶段读寄存器1地址（同时传到转发模块）
    .rf_raddr2_o(rf_raddr2_o),           // RF 阶段读寄存器2地址（同时传到转发模块）
    // to ex
    .inst_valid_o(rf_inst_valid_o),               // 指令有效标志
    .rob_id_o(rf_rob_id_o),             // ROB id
    .mask_o(rf_mask_o),               // 分支掩码
    .sq_id_o(rf_sq_id_o),              // SQ id
    .subtype_o(rf_subtype_o),            // 指令子类型
    .rs1_data_o(rf_rs1_data_o),          // rs1数据
    .rs2_data_o(rf_rs2_data_o),          // rs2数据
    .pwaddr_o(rf_pwaddr_o),             // 物理寄存器写地址
    .imm_o(rf_imm_o)                    // 立即数
);

// rf_ex
wire rf_ex_inst_valid_o;               // 指令有效标志
wire [5:0] rf_ex_rob_id_o;             // ROB id
wire [3:0] rf_ex_mask_o;               // 分支掩码
wire [1:0] rf_ex_sq_id_o;              // SQ id
wire [3:0] rf_ex_subtype_o;            // 指令子类型
wire [31:0] rf_ex_rs1_data_o;          // rs1数据
wire [31:0] rf_ex_rs2_data_o;          // rs2数据
wire [5:0] rf_ex_pwaddr_o;             // 物理寄存器写地址
wire [31:0] rf_ex_imm_o;               // 立即数

lsu_rf_ex u_lsu_rf_ex(
    .clk(clk),
    .rst(rst),
    // from rf
    .inst_valid_i(rf_inst_valid_o),               // 指令有效标志
    .rob_id_i(rf_rob_id_o),             // ROB id
    .mask_i(rf_mask_o),               // 分支掩码
    .sq_id_i(rf_sq_id_o),              // SQ id
    .subtype_i(rf_subtype_o),            // 指令子类型
    .rs1_data_i(rf_rs1_data_o),          // rs1数据
    .rs2_data_i(rf_rs2_data_o),          // rs2数据
    .pwaddr_i(rf_pwaddr_o),             // 物理寄存器写地址
    .imm_i(rf_imm_o),                   // 立即数
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // from mem
    .flush_i(flush_o),                      // 冲刷标志
    .stall_i(stall_o),
    // from commit
    .free_mask_inst0_i(free_mask_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_mask_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_id_inst1_i),               // 指令1释放id
    // from branch
    .jump_flag_i(jump_flag_i),                 // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),        // 分支掩码id
    // to ex
    .inst_valid_o(rf_ex_inst_valid_o),               // 指令有效标志
    .rob_id_o(rf_ex_rob_id_o),             // ROB id
    .mask_o(rf_ex_mask_o),               // 分支掩码
    .sq_id_o(rf_ex_sq_id_o),              // SQ id
    .subtype_o(rf_ex_subtype_o),            // 指令子类型
    .rs1_data_o(rf_ex_rs1_data_o),          // rs1数据
    .rs2_data_o(rf_ex_rs2_data_o),          // rs2数据
    .pwaddr_o(rf_ex_pwaddr_o),             // 物理寄存器写地址
    .imm_o(rf_ex_imm_o)                    // 立即数
);

// ex
wire ex_inst_valid_o;               // 指令有效标志
wire [5:0] ex_rob_id_o;             // ROB id
wire [3:0] ex_mask_o;               // 分支掩码
wire [1:0] ex_sq_id_o;              // SQ id
wire [3:0] ex_subtype_o;            // 指令子类型
wire [31:0] ex_rs2_data_o;          // rs2数据
wire [5:0] ex_pwaddr_o;             // 物理寄存器写地址
wire [31:0] ex_mem_addr_o;          // 访存地址

LSU_EX u_LSU_EX(
    // from rf
    .inst_valid_i(rf_ex_inst_valid_o),               // 指令有效标志
    .rob_id_i(rf_ex_rob_id_o),             // ROB id
    .mask_i(rf_ex_mask_o),               // 分支掩码
    .sq_id_i(rf_ex_sq_id_o),              // SQ id
    .subtype_i(rf_ex_subtype_o),            // 指令子类型
    .rs1_data_i(rf_ex_rs1_data_o),          // rs1数据
    .rs2_data_i(rf_ex_rs2_data_o),          // rs2数据
    .pwaddr_i(rf_ex_pwaddr_o),             // 物理寄存器写地址
    .imm_i(rf_ex_imm_o),                   // 立即数
    // from branch
    .jump_flag_i(jump_flag_i),                 // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),        // 分支掩码id
    // from commit
    .free_mask_inst0_i(free_mask_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_mask_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_id_inst1_i),               // 指令1释放id
    // to mem
    .inst_valid_o(ex_inst_valid_o),               // 指令有效标志
    .rob_id_o(ex_rob_id_o),             // ROB id
    .mask_o(ex_mask_o),               // 分支掩码
    .sq_id_o(ex_sq_id_o),              // SQ id
    .subtype_o(ex_subtype_o),            // 指令子类型
    .rs2_data_o(ex_rs2_data_o),          // rs2数据
    .pwaddr_o(ex_pwaddr_o),             // 物理寄存器写地址
    .mem_addr_o(ex_mem_addr_o)           // 访存地址
);

// ex_mem
wire ex_mem_inst_valid_o;               // 指令有效标志
wire [5:0] ex_mem_rob_id_o;             // ROB id
wire [3:0] ex_mem_mask_o;               // 分支掩码
wire [1:0] ex_mem_sq_id_o;              // SQ id
wire [3:0] ex_mem_subtype_o;            // 指令子类型
wire [31:0] ex_mem_rs2_data_o;          // rs2数据
wire [5:0] ex_mem_pwaddr_o;             // 物理寄存器写地址
wire [31:0] ex_mem_mem_addr_o;          // 访存地址

lsu_ex_mem u_lsu_ex_mem(
    .clk(clk),
    .rst(rst),
    // from ex
    .inst_valid_i(ex_inst_valid_o),               // 指令有效标志
    .rob_id_i(ex_rob_id_o),             // ROB id
    .mask_i(ex_mask_o),               // 分支掩码
    .sq_id_i(ex_sq_id_o),              // SQ id
    .subtype_i(ex_subtype_o),            // 指令子类型
    .rs2_data_i(ex_rs2_data_o),          // rs2数据
    .pwaddr_i(ex_pwaddr_o),             // 物理寄存器写地址
    .mem_addr_i(ex_mem_addr_o),          // 访存地址
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // from mem
    .flush_i(flush_o),                      // 冲刷标志
    .stall_i(stall_o),
    // from commit
    .free_mask_inst0_i(free_mask_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_mask_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_id_inst1_i),               // 指令1释放id
    // to mem
    .inst_valid_o(ex_mem_inst_valid_o),               // 指令有效标志
    .rob_id_o(ex_mem_rob_id_o),             // ROB id
    .mask_o(ex_mem_mask_o),               // 分支掩码
    .sq_id_o(ex_mem_sq_id_o),              // SQ id
    .subtype_o(ex_mem_subtype_o),            // 指令子类型
    .rs2_data_o(ex_mem_rs2_data_o),          // rs2数据
    .pwaddr_o(ex_mem_pwaddr_o),             // 物理寄存器写地址
    .mem_addr_o(ex_mem_mem_addr_o)           // 访存地址
);

// LSU_Mem
wire mem_inst_valid_o;
wire [3:0] mem_subtype_o;
wire mem_dcache_ren;
wire mem_stall_o;

LSU_Mem u_LSU_Mem(
    .clk(clk),
    .rst(rst),
    // from ex
    .inst_valid_i(ex_mem_inst_valid_o),               // 指令有效标志
    .rob_id_i(ex_mem_rob_id_o),             // ROB id
    .mask_i(ex_mem_mask_o),               // 分支掩码
    .sq_id_i(ex_mem_sq_id_o),              // SQ id
    .subtype_i(ex_mem_subtype_o),            // 指令子类型
    .rs2_data_i(ex_mem_rs2_data_o),          // rs2数据
    .pwaddr_i(ex_mem_pwaddr_o),             // 物理寄存器写地址
    .mem_addr_i(ex_mem_mem_addr_o),          // 访存地址
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // from branch
    .jump_flag_i(jump_flag_i),                 // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),        // 分支掩码id
    // from commit
    .commit_store_flag_i(commit_store_flag_i),             // 提交store指令标志
    // from commit
    .free_mask_inst0_i(free_mask_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_mask_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_id_inst1_i),               // 指令1释放id
    // from peripheral
    .perip_rdata(perip_rdata),
    // from dcache
    .dcache_rdata(dcache_mem_rdata),
    .dcache_miss(dcache_miss),
    // to dcache
    .dcache_ren(mem_dcache_ren),
    .mem_addr_o(mem_addr_o),
    .flush_o(flush_o),
    // to pipeline
    .stall_o(mem_stall_o),
    // to peripheral and dcache
    .sq_mask_o(sq_mask_o),
    .sq_addr_o(sq_addr_o),
    .sq_data_o(sq_data_o),
    // to regs
    .mem_reg_wflag_o(mem_reg_wflag_o),                     // Mem阶段load写寄存器标志(给ready置1)
    // to forward_unit and wb
    .mem_reg_waddr_o(mem_reg_waddr_o),               // Mem阶段写寄存器地址(同时传到regs)
    .mem_reg_wdata_o(mem_reg_wdata_o),          // Mem阶段写寄存器数据
    // to wb
    .inst_valid_o(mem_inst_valid_o),                 // 指令有效标志
    .subtype_o(mem_subtype_o),              // 指令子类型
    // to ROB
    .store_complete_flag_o(store_complete_flag_o),            // store指令完成标志
    .store_commit_rob_id_o(store_commit_rob_id_o)       // store提交ROB id
);

// dcache
wire [31:0] dcache_mem_rdata;
wire dcache_stall_o;
wire dcache_miss;
assign stall_o = mem_stall_o || dcache_stall_o;

dcache u_dcache(
    .clk(clk),
    .rst(rst),
    // from mem
    .mem_addr(mem_addr_o),
    .mem_ren(mem_dcache_ren),
    // from dram
    .cache_line(cache_line),
    // from commit
    .mem_wen(mem_wen),
    .mem_mask(sq_mask_o),
    .mem_wdata(sq_data_o),
    .mem_waddr(sq_addr_o),
    // to commit
    .stall_store(stall_store),
    // to mem
    .mem_rdata(dcache_mem_rdata),
    // to pipeline/ctrl
    .miss_hold(dcache_stall_o),
    // to mem
    .cache_miss(dcache_miss)
);

// mem_wb
wire mem_wb_inst_valid_o;                 // 指令有效标志
wire [3:0] mem_wb_subtype_o;              // 指令子类型
wire [5:0] mem_wb_rob_id_o;               // ROB id
wire [5:0] mem_wb_pwaddr_o;               // 物理寄存器写地址
wire [31:0] mem_wb_reg_wdata_o;           // 写寄存器数据

lsu_mem_wb u_lsu_mem_wb(
    .clk(clk),
    .rst(rst),
    // from mem
    .inst_valid_i(mem_inst_valid_o),                 // 指令有效标志
    .subtype_i(mem_subtype_o),              // 指令子类型
    .rob_id_i(store_commit_rob_id_o),               // ROB id
    .pwaddr_i(mem_reg_waddr_o),               // 物理寄存器写地址
    .reg_wdata_i(mem_reg_wdata_o),           // 写寄存器数据
    .stall_i(stall_o),
    // from clint
    .int_flag_i(int_flag_i),                   // 中断标志
    // to wb
    .inst_valid_o(mem_wb_inst_valid_o),                 // 指令有效标志
    .subtype_o(mem_wb_subtype_o),              // 指令子类型
    .rob_id_o(mem_wb_rob_id_o),               // ROB id
    .pwaddr_o(mem_wb_pwaddr_o),               // 物理寄存器写地址
    .reg_wdata_o(mem_wb_reg_wdata_o)           // 写寄存器数据
);

// wb
LSU_WB u_LSU_WB(
    // from mem
    .inst_valid_i(mem_wb_inst_valid_o),                 // 指令有效标志
    .subtype_i(mem_wb_subtype_o),              // 指令子类型
    .rob_id_i(mem_wb_rob_id_o),               // ROB id
    .pwaddr_i(mem_wb_pwaddr_o),               // 物理寄存器写地址
    .reg_wdata_i(mem_wb_reg_wdata_o),           // 写寄存器数据
    // to regs
    .reg_wflag_o(reg_wflag_o),                 // 写回阶段写寄存器标志
    .reg_waddr_o(reg_waddr_o),           // 写回阶段写寄存器地址
    .reg_wdata_o(reg_wdata_o),          // 写回阶段写寄存器数据
    // to ROB
    .load_complete_flag_o(load_complete_flag_o),              // load指令完成标志
    .load_commit_rob_id_o(load_commit_rob_id_o)         // load提交ROB id
);











endmodule