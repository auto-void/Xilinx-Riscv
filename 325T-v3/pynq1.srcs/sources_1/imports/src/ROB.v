`include "defines.vh"

`timescale 1ns / 1ps

module ROB (
    input clk,
    input rst,

    // from dispatch
    input [31:0] inst_addr_i,                   // 指令地址
    input [2:0] inst_type_port0_i,              // 指令类型
    input [2:0] inst_type_port1_i,              // 指令类型
    input [3:0] inst_subtype_port0_i,           // 指令子类型
    input [3:0] inst_subtype_port1_i,           // 指令子类型
    input [1:0] op2_src_port0_i,                // 操作数2来源选择
    input [1:0] op2_src_port1_i,                // 操作数2来源选择
    input [11:0] csr_addr_port0_i,              // CSR寄存器地址
    input [11:0] csr_addr_port1_i,              // CSR寄存器地址
    input [4:0] reg_waddr_port0_i,              // 写通用寄存器地址
    input [4:0] reg_waddr_port1_i,              // 写通用寄存器地址
    input inst_valid_port0_i,                   // 指令有效标志
    input inst_valid_port1_i,                   // 指令有效标志
    input [31:0] imm_port0_i,                   // 立即数
    input [31:0] imm_port1_i,                   // 立即数
    input [5:0] praddr1_inst0_i,        // 指令0物理寄存器1读地址
    input [5:0] praddr1_inst1_i,        // 指令1物理寄存器1读地址
    input [5:0] pwaddr_inst0_i,         // 指令0物理寄存器写地址
    input [5:0] pwaddr_inst1_i,         // 指令1物理寄存器写地址
    input [3:0] branch_mask_inst0_i,    // 指令0分支掩码
    input [3:0] branch_mask_inst1_i,    // 指令1分支掩码
    input [1:0] snap_id_inst0_i,        // 指令0快照id
    input [1:0] snap_id_inst1_i,        // 指令1快照id
    input [5:0] old_paddr_inst0_i,      // 指令0旧的物理寄存器映射
    input [5:0] old_paddr_inst1_i,      // 指令1旧的物理寄存器映射

    // from clint
    input int_flag_i,                   // 中断标志
    input int_w_disable_i,              // 中断发生时禁止写内存和CSR寄存器

    // from issue
    input stall_i,

    // from branch
    input jump_flag_i,                  // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id

    // from mem
    input stall_store,                 // store指令暂停标志

    // from ex
    input alu0_complete_flag_i,             // ALU_0指令完成标志
    input [5:0] alu0_commit_rob_id_i,       // ALU_0提交ROB id
    input alu1_complete_flag_i,             // ALU_1指令完成标志
    input [5:0] alu1_commit_rob_id_i,       // ALU_1提交ROB id
    input br_complete_flag_i,               // branch指令完成标志
    input [5:0] br_commit_rob_id_i,         // branch提交ROB id
    input store_complete_flag_i,            // store指令完成标志
    input [5:0] store_commit_rob_id_i,      // store提交ROB id
    input load_complete_flag_i,             // load指令完成标志
    input [5:0] load_commit_rob_id_i,       // load提交ROB id
    `ifdef use_m_extension
    input mul_complete_flag_i,              // mul指令完成标志
    input [5:0] mul_commit_rob_id_i,        // mul提交ROB id
    input div_complete_flag_i,              // div指令完成标志
    input [5:0] div_commit_rob_id_i,        // div提交ROB id
    `endif

    // from csr_reg
    input [31:0] csr_rdata_i,               // CSR寄存器读数据

    // from regs
    input [31:0] reg1_rdata_i,              // 通用寄存器1读数据

    // to clint
    output int_ready_flag_o,                   // 中断准备好标志
    output [31:0] mret_inst_addr_o,            // mret指令的返回地址（mepc寄存器的值）
    output reg exception_flag_o,               // 异常发生标志
    output reg [31:0] exception_cause_o,       // 异常编号
    output reg mret_flag_o,                    // 中断返回标志

    // to pipeline
    output stall_o,

    // to issue
    output reg [1:0] sq_commit_cnt_o,             // store queue提交数量
    output reg [5:0] rob_id_inst0_o,              // 指令0 ROB id
    output reg [5:0] rob_id_inst1_o,              // 指令1 ROB id

    // to mem
    output reg commit_store_flag_o,             // 提交store指令标志

    // to peripheral
    output reg perip_wen,

    // to dcache
    output reg dcache_wen,

    // to csr_reg
    output csr_reg_wflag_o,
    output [11:0] csr_reg_addr_o,
    output [31:0] csr_reg_wdata_o,            

    // to regs
    output [5:0] reg_raddr_o,                 // CSR指令在提交阶段才读取执行结果，所以CSR寄存器的读地址由commit阶段提供
    output reg_wflag_o,                       // CSR指令写回阶段写寄存器标志
    output [5:0] reg_waddr_o,                 // CSR指令写回阶段写寄存器地址
    output [31:0] reg_wdata_o,                // CSR指令写回阶段写寄存器数据

    // to rename
    output reg free_snap_flag_inst0_o,         // 指令0释放快照标志
    output reg free_snap_flag_inst1_o,         // 指令1释放快照标志
    // 释放 ID，用于清理内部 Mask
    output [1:0] free_snap_id_inst0_o,     
    output [1:0] free_snap_id_inst1_o,
    output reg commit_inst0_o,                 // 指令0提交使能
    output [4:0] waddr_commit0_o,              // 提交指令的目标逻辑寄存器
    output [5:0] paddr_commit0_o,              // 提交指令的目标物理寄存器(成为架构状态)
    output [5:0] free_paddr_inst0_o,           // 释放的物理寄存器地址
    output reg commit_inst1_o,                 // 指令1提交使能
    output [4:0] waddr_commit1_o,              // 提交指令的目标逻辑寄存器
    output [5:0] paddr_commit1_o,              // 提交指令的目标物理寄存器(成为架构状态)
    output [5:0] free_paddr_inst1_o            // 释放的物理寄存器地址
);

localparam TYPE_STORE = 2'b00,
           TYPE_BRANCH = 2'b01,
           TYPE_CSR = 2'b10;

// ROB
reg rob_valid[0:31];
reg rob_complete[0:31];
reg [1:0] rob_snap_id[0:31];
reg [3:0] rob_br_mask[0:31];

wire [63:0] rob_static_data_port0, rob_static_data_port1;
reg inst0_idx, inst1_idx;
// inst0
wire [63:0] rob_inst0_data_sel = (inst0_idx == 1'b1) ? rob_static_data_port1 : rob_static_data_port0;
wire [15:0] rob_inst0_addr = rob_inst0_data_sel[15:0];
wire [1:0]  rob_inst0_type = rob_inst0_data_sel[17:16];
wire [5:0]  rob_inst0_rs1_addr = rob_inst0_data_sel[23:18];
wire [4:0]  rob_inst0_rd = rob_inst0_data_sel[28:24];
wire [5:0]  rob_inst0_pwaddr = rob_inst0_data_sel[34:29];
wire [5:0]  rob_inst0_old_pwaddr = rob_inst0_data_sel[40:35];
wire [11:0] rob_inst0_csr_addr = rob_inst0_data_sel[52:41];
wire [1:0]  rob_inst0_op2_src = rob_inst0_data_sel[54:53];
wire [4:0]  rob_inst0_csr_imm = rob_inst0_data_sel[59:55];
wire [3:0]  rob_inst0_subtype = rob_inst0_data_sel[63:60];
// inst1
wire [63:0] rob_inst1_data_sel = (inst1_idx == 1'b1) ? rob_static_data_port1 : rob_static_data_port0;
wire [15:0] rob_inst1_addr = rob_inst1_data_sel[15:0];
wire [1:0]  rob_inst1_type = rob_inst1_data_sel[17:16];
wire [5:0]  rob_inst1_rs1_addr = rob_inst1_data_sel[23:18];
wire [4:0]  rob_inst1_rd = rob_inst1_data_sel[28:24];
wire [5:0]  rob_inst1_pwaddr = rob_inst1_data_sel[34:29];
wire [5:0]  rob_inst1_old_pwaddr = rob_inst1_data_sel[40:35];
wire [11:0] rob_inst1_csr_addr = rob_inst1_data_sel[52:41];
wire [1:0]  rob_inst1_op2_src = rob_inst1_data_sel[54:53];
wire [4:0]  rob_inst1_csr_imm = rob_inst1_data_sel[59:55];
wire [3:0]  rob_inst1_subtype = rob_inst1_data_sel[63:60];

// ila_0 ila(
//     .clk(clk),
//     .probe0(rob_inst0_addr),
//     .probe1(rob_inst1_addr),
//     .probe2(rob_complete[rob_rd_ptr]),
//     .probe3(rob_valid[rob_rd_ptr])
// );

// commit 提交
reg [4:0] rob_rd_ptr;
reg [4:0] rob_raddr_port0, rob_raddr_port1;
always @(*) begin
    if (rob_rd_ptr[0] == 1'b0) begin
        rob_raddr_port0 = rob_rd_ptr;
        inst0_idx = 1'b0;
        rob_raddr_port1 = rob_rd_ptr;
        inst1_idx = 1'b1;
    end
    else begin
        rob_raddr_port0 = rob_rd_ptr + 5'd1;
        inst1_idx = 1'b0;
        rob_raddr_port1 = rob_rd_ptr;
        inst0_idx = 1'b1;
    end
end
// 响应中断
assign int_ready_flag_o = rob_valid[rob_rd_ptr];
assign mret_inst_addr_o = {16'h8000, rob_inst0_addr};
// 指令提交逻辑
assign csr_reg_addr_o = rob_inst0_csr_addr;
assign reg_raddr_o = rob_inst0_rs1_addr;
assign reg_waddr_o = rob_inst0_pwaddr;
assign free_snap_id_inst0_o = rob_snap_id[rob_rd_ptr];
assign free_snap_id_inst1_o = rob_snap_id[(rob_rd_ptr + 5'd1) & 5'b11111];
assign waddr_commit0_o = rob_inst0_rd;
assign paddr_commit0_o = rob_inst0_pwaddr;
assign free_paddr_inst0_o = rob_inst0_old_pwaddr;
assign waddr_commit1_o = rob_inst1_rd;
assign paddr_commit1_o = rob_inst1_pwaddr;
assign free_paddr_inst1_o = rob_inst1_old_pwaddr;
// CSR指令多打一拍
reg [31:0] csr_reg_wdata;
reg [31:0] reg_wdata;
reg [31:0] csr_reg_wdata_d1;
reg [31:0] reg_wdata_d1;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        csr_reg_wdata_d1 <= 32'b0;
        reg_wdata_d1 <= 32'b0;
    end
    else begin
        csr_reg_wdata_d1 <= csr_reg_wdata;
        reg_wdata_d1 <= reg_wdata;
    end
end
reg csr_cnt;
reg w_csr_reg;
assign csr_reg_wflag_o = !int_w_disable_i && (csr_cnt == 1'b1) && rob_valid[rob_rd_ptr];
assign reg_wflag_o = !int_w_disable_i && (csr_cnt == 1'b1) && rob_valid[rob_rd_ptr];
assign csr_reg_wdata_o = csr_reg_wdata_d1;
assign reg_wdata_o = reg_wdata_d1;
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        csr_cnt <= 1'b0;
    end
    else if (csr_cnt == 1'b1) begin
        csr_cnt <= 1'b0;
    end
    else if (w_csr_reg) begin
        csr_cnt <= 1'b1;
    end
    else begin
        csr_cnt <= 1'b0;
    end
end
// 组合逻辑
always @(*) begin
    commit_inst0_o = 1'b0;
    commit_inst1_o = 1'b0;
    // S type
    sq_commit_cnt_o = 2'b0;
    commit_store_flag_o = 1'b0;
    perip_wen = 1'b0;
    dcache_wen = 1'b0;
    // CSR
    exception_flag_o = 1'b0;
    exception_cause_o = 32'b0;
    mret_flag_o = 1'b0;
    w_csr_reg = 1'b0;
    csr_reg_wdata = 32'b0;
    reg_wdata = 32'b0;
    //B type
    free_snap_flag_inst0_o = 1'b0;
    free_snap_flag_inst1_o = 1'b0;

    // 提交第一条指令
    if (rob_valid[rob_rd_ptr] && (rob_complete[rob_rd_ptr] || rob_inst0_type == TYPE_CSR)) begin
        case (rob_inst0_type)
            TYPE_STORE: begin
                commit_inst0_o = !stall_store;
                sq_commit_cnt_o = stall_store ? 2'b0 : 2'b1;
                commit_store_flag_o = !stall_store;
                perip_wen = !stall_store && !int_w_disable_i;
                dcache_wen = !int_w_disable_i;
            end
            TYPE_BRANCH: begin
                commit_inst0_o = 1'b1;
                free_snap_flag_inst0_o = 1'b1; // 分支指令提交时释放快照
            end
            TYPE_CSR: begin
                case (rob_inst0_subtype)
                    `CSR_ECALL: begin
                        commit_inst0_o = 1'b1;
                        exception_flag_o = 1'b1;
                        exception_cause_o = 32'h0000000b; // ECALL异常编号
                    end
                    `CSR_EBREAK: begin
                        commit_inst0_o = 1'b1;
                        exception_flag_o = 1'b1;
                        exception_cause_o = 32'h00000003; // EBREAK异常编号
                    end
                    `CSR_MRET: begin
                        commit_inst0_o = 1'b1;
                        mret_flag_o = 1'b1;
                    end
                    `CSR_RW: begin
                        w_csr_reg = 1'b1;
                        commit_inst0_o = (csr_cnt == 1'b1);
                        if (rob_inst0_op2_src == `OP2_REG) begin
                            csr_reg_wdata = reg1_rdata_i;
                            reg_wdata = csr_rdata_i;
                        end
                        else begin
                            csr_reg_wdata = {27'h0, rob_inst0_csr_imm};
                            reg_wdata = csr_rdata_i;
                        end
                    end
                    `CSR_RS: begin
                        w_csr_reg = 1'b1;
                        commit_inst0_o = (csr_cnt == 1'b1);
                        if (rob_inst0_op2_src == `OP2_REG) begin
                            csr_reg_wdata = csr_rdata_i | reg1_rdata_i;
                            reg_wdata = csr_rdata_i;
                        end
                        else begin
                            csr_reg_wdata = csr_rdata_i | {27'h0, rob_inst0_csr_imm};
                            reg_wdata = csr_rdata_i;
                        end
                    end
                    `CSR_RC: begin
                        w_csr_reg = 1'b1;
                        commit_inst0_o = (csr_cnt == 1'b1);
                        if (rob_inst0_op2_src == `OP2_REG) begin
                            csr_reg_wdata = csr_rdata_i & (~reg1_rdata_i);
                            reg_wdata = csr_rdata_i;
                        end
                        else begin
                            csr_reg_wdata = csr_rdata_i & (~{27'h0, rob_inst0_csr_imm});
                            reg_wdata = csr_rdata_i;
                        end
                    end
                    default: begin
                        exception_flag_o = 1'b0;
                        exception_cause_o = 32'b0;
                        mret_flag_o = 1'b0;
                        csr_reg_wdata = 32'b0;
                        reg_wdata = 32'b0;
                    end
                endcase
            end
            default: begin
                commit_inst0_o = 1'b1;
            end
        endcase

        // 提交第二条指令
        if (rob_valid[(rob_rd_ptr + 5'd1) & 5'b11111] && rob_complete[(rob_rd_ptr + 5'd1) & 5'b11111] && (rob_inst0_type != TYPE_STORE || rob_inst1_type != TYPE_STORE) && rob_inst0_type != TYPE_CSR) begin
            case (rob_inst1_type)
                TYPE_STORE: begin
                    commit_inst1_o = !stall_store;
                    sq_commit_cnt_o = stall_store ? 2'b0 : 2'b1;
                    commit_store_flag_o = !stall_store;
                    perip_wen = !stall_store && !int_w_disable_i;
                    dcache_wen = !int_w_disable_i;
                end
                TYPE_BRANCH: begin
                    commit_inst1_o = (rob_inst0_type == TYPE_STORE) ? !stall_store : 1'b1; // 如果inst0是store指令，则inst1提交还受store暂停的影响
                    free_snap_flag_inst1_o = (rob_inst0_type == TYPE_STORE) ? !stall_store : 1'b1; // 分支指令提交时释放快照
                end
                default: begin
                    commit_inst1_o = (rob_inst0_type == TYPE_STORE) ? !stall_store : 1'b1; // 如果inst0是store指令，则inst1提交还受store暂停的影响
                end
            endcase
        end
    end
end

// dispatch 写入
reg [1:0] rob_port0_type, rob_port1_type;
always @(*) begin
    rob_port0_type = 2'b11;
    rob_port1_type = 2'b11;
    // inst0
    if (inst_type_port0_i == `TYPE_MEM && inst_subtype_port0_i[3] == 1'b1) begin
        rob_port0_type = TYPE_STORE;
    end
    else if ((inst_type_port0_i == `TYPE_BR) || (inst_type_port0_i == `TYPE_JAL && inst_subtype_port0_i == `JUMP_JALR)) begin
        rob_port0_type = TYPE_BRANCH;
    end
    else if (inst_type_port0_i == `TYPE_CSR) begin
        rob_port0_type = TYPE_CSR;
    end
    // inst1
    if (inst_type_port1_i == `TYPE_MEM && inst_subtype_port1_i[3] == 1'b1) begin
        rob_port1_type = TYPE_STORE;
    end
    else if ((inst_type_port1_i == `TYPE_BR) || (inst_type_port1_i == `TYPE_JAL && inst_subtype_port1_i == `JUMP_JALR)) begin
        rob_port1_type = TYPE_BRANCH;
    end
    else if (inst_type_port1_i == `TYPE_CSR) begin
        rob_port1_type = TYPE_CSR;
    end
end
reg rob_port0_we, rob_port1_we;
reg [4:0] rob_wr_ptr;
reg [4:0] rob_id_port0, rob_id_port1;
reg [63:0] rob_port0_wdata, rob_port1_wdata;
wire [63:0] rob_inst0_wdata = {inst_subtype_port0_i, imm_port0_i[4:0], op2_src_port0_i, csr_addr_port0_i, old_paddr_inst0_i, pwaddr_inst0_i, reg_waddr_port0_i, praddr1_inst0_i, rob_port0_type, {inst_addr_i[15:3], 3'b000}};
wire [63:0] rob_inst1_wdata = {inst_subtype_port1_i, imm_port1_i[4:0], op2_src_port1_i, csr_addr_port1_i, old_paddr_inst1_i, pwaddr_inst1_i, reg_waddr_port1_i, praddr1_inst1_i, rob_port1_type, {inst_addr_i[15:3], 3'b100}};
always @(*) begin
    rob_port0_we = 1'b0;
    rob_port1_we = 1'b0;
    rob_id_port0 = 5'b0;
    rob_id_port1 = 5'b0;
    rob_port0_wdata = 64'b0;
    rob_port1_wdata = 64'b0;

    if (inst_valid_port0_i && inst_valid_port1_i) begin
        rob_port0_we = 1'b1;
        rob_port1_we = 1'b1;
        if (rob_wr_ptr[0] == 1'b0) begin // inst0写bank0, inst1写bank1
            rob_id_port0 = rob_wr_ptr;
            rob_id_port1 = rob_wr_ptr;
            rob_port0_wdata = rob_inst0_wdata;
            rob_port1_wdata = rob_inst1_wdata;
        end
        else begin // inst0写bank1, inst1写bank0
            rob_id_port0 = rob_wr_ptr + 5'd1; // 5位自动回绕
            rob_id_port1 = rob_wr_ptr;
            rob_port0_wdata = rob_inst1_wdata;
            rob_port1_wdata = rob_inst0_wdata;
        end
    end
    else if (inst_valid_port0_i) begin
        if (rob_wr_ptr[0] == 1'b0) begin
            rob_port0_we = 1'b1;
            rob_id_port0 = rob_wr_ptr;
            rob_port0_wdata = rob_inst0_wdata;
        end
        else begin
            rob_port1_we = 1'b1;
            rob_id_port1 = rob_wr_ptr;
            rob_port1_wdata = rob_inst0_wdata;
        end
    end
    else if (inst_valid_port1_i) begin
        if (rob_wr_ptr[0] == 1'b0) begin
            rob_port0_we = 1'b1;
            rob_id_port0 = rob_wr_ptr;
            rob_port0_wdata = rob_inst1_wdata;
        end
        else begin
            rob_port1_we = 1'b1;
            rob_id_port1 = rob_wr_ptr;
            rob_port1_wdata = rob_inst1_wdata;
        end
    end
end
// ROB id 分配
always @(*) begin
    rob_id_inst0_o = {1'b0, rob_wr_ptr};
    rob_id_inst1_o = {1'b0, rob_wr_ptr + 5'd1}; // 5位自动回绕

    if (!inst_valid_port0_i && inst_valid_port1_i) begin
        rob_id_inst1_o = {1'b0, rob_wr_ptr};
    end
end
// 暂停逻辑
reg [5:0] rob_free_cnt; // ROB空闲计数
wire [1:0] rob_req = inst_valid_port0_i + inst_valid_port1_i;
assign stall_o = (rob_free_cnt < rob_req);
wire stall = stall_i || stall_o;
// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
reg prev_flush_flag;
always @(posedge clk) prev_flush_flag <= jump_flag_i;
reg [5:0] restore_free_cnt;
reg [4:0] restore_wr_ptr;
integer k;
always @(*) begin
    restore_free_cnt = 6'd0;
    restore_wr_ptr = rob_rd_ptr;

    for (k = 0; k < 32; k = k + 1) begin
        if (!rob_valid[k[4:0]]) begin
            restore_free_cnt = restore_free_cnt + 6'd1;
        end
    end

    for (k = 0; k < 32; k = k + 1) begin
        if (rob_valid[(rob_rd_ptr + k[4:0]) & 5'b11111]) begin
            restore_wr_ptr = ((rob_rd_ptr + k[4:0]) & 5'b11111) + 5'd1;
        end
    end
end
wire [1:0] inst_commit_cnt = commit_inst0_o + commit_inst1_o;
// ROB动态信息更新
integer i;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        rob_rd_ptr <= 5'b0;
        rob_wr_ptr <= 5'b0;
        rob_free_cnt <= 6'd32;
        for (i = 0; i < 32; i = i + 1) begin
            rob_valid[i] <= 1'b0;
            rob_complete[i] <= 1'b0;
            rob_snap_id[i] <= 2'b0;
            rob_br_mask[i] <= 4'b0;
        end
    end
    else if (int_flag_i) begin
        rob_rd_ptr <= 5'b0;
        rob_wr_ptr <= 5'b0;
        rob_free_cnt <= 6'd32;
        for (i = 0; i < 32; i = i + 1) begin
            rob_valid[i] <= 1'b0; // 中断发生，清空ROB
        end
    end
    else if (jump_flag_i) begin
        for (i = 0; i < 32; i = i + 1) begin
            if ((rob_br_mask[i] & kill_mask) != 0) rob_valid[i] <= 1'b0;
        end
        // 指令完成更新
        if (alu0_complete_flag_i)  rob_complete[alu0_commit_rob_id_i[4:0]]  <= 1'b1;
        if (alu1_complete_flag_i)  rob_complete[alu1_commit_rob_id_i[4:0]]  <= 1'b1;
        if (br_complete_flag_i)    rob_complete[br_commit_rob_id_i[4:0]]    <= 1'b1;
        if (store_complete_flag_i) rob_complete[store_commit_rob_id_i[4:0]] <= 1'b1;
        if (load_complete_flag_i)  rob_complete[load_commit_rob_id_i[4:0]]  <= 1'b1;
        `ifdef use_m_extension
        if (mul_complete_flag_i)   rob_complete[mul_commit_rob_id_i[4:0]]   <= 1'b1;
        if (div_complete_flag_i)   rob_complete[div_commit_rob_id_i[4:0]]   <= 1'b1;
        `endif
        // 提交逻辑
        if (commit_inst0_o) begin
            rob_valid[rob_rd_ptr] <= 1'b0;

            if (commit_inst1_o) begin
                // 提交两条
                rob_valid[(rob_rd_ptr + 5'd1) & 5'b11111] <= 1'b0;
                rob_rd_ptr <= rob_rd_ptr + 5'd2;
            end 
            else begin
                // 只提交一条
                rob_rd_ptr <= rob_rd_ptr + 5'd1;
            end
        end
        // 提交释放掩码
        if (free_snap_flag_inst0_o) begin
            for (i = 0; i < 32; i = i + 1) begin
                rob_br_mask[i][free_snap_id_inst0_o] <= 1'b0; // 清除对应位
            end
        end
        if (free_snap_flag_inst1_o) begin
            for (i = 0; i < 32; i = i + 1) begin
                rob_br_mask[i][free_snap_id_inst1_o] <= 1'b0; // 清除对应位
            end
        end
    end
    else if (prev_flush_flag) begin
        rob_wr_ptr <= restore_wr_ptr;
        rob_free_cnt <= restore_free_cnt + inst_commit_cnt;
        // 指令完成更新
        if (alu0_complete_flag_i)  rob_complete[alu0_commit_rob_id_i[4:0]]  <= 1'b1;
        if (alu1_complete_flag_i)  rob_complete[alu1_commit_rob_id_i[4:0]]  <= 1'b1;
        if (br_complete_flag_i)    rob_complete[br_commit_rob_id_i[4:0]]    <= 1'b1;
        if (store_complete_flag_i) rob_complete[store_commit_rob_id_i[4:0]] <= 1'b1;
        if (load_complete_flag_i)  rob_complete[load_commit_rob_id_i[4:0]]  <= 1'b1;
        `ifdef use_m_extension
        if (mul_complete_flag_i)   rob_complete[mul_commit_rob_id_i[4:0]]   <= 1'b1;
        if (div_complete_flag_i)   rob_complete[div_commit_rob_id_i[4:0]]   <= 1'b1;
        `endif
        // 提交逻辑
        if (commit_inst0_o) begin
            rob_valid[rob_rd_ptr] <= 1'b0;

            if (commit_inst1_o) begin
                // 提交两条
                rob_valid[(rob_rd_ptr + 5'd1) & 5'b11111] <= 1'b0;
                rob_rd_ptr <= rob_rd_ptr + 5'd2;
            end
            else begin
                // 只提交一条
                rob_rd_ptr <= rob_rd_ptr + 5'd1;
            end
        end
        // 提交释放掩码
        if (free_snap_flag_inst0_o) begin
            for (i = 0; i < 32; i = i + 1) begin
                rob_br_mask[i][free_snap_id_inst0_o] <= 1'b0; // 清除对应位
            end
        end
        if (free_snap_flag_inst1_o) begin
            for (i = 0; i < 32; i = i + 1) begin
                rob_br_mask[i][free_snap_id_inst1_o] <= 1'b0; // 清除对应位
            end
        end
    end
    else begin
        // 指令完成更新
        if (alu0_complete_flag_i)  rob_complete[alu0_commit_rob_id_i[4:0]]  <= 1'b1;
        if (alu1_complete_flag_i)  rob_complete[alu1_commit_rob_id_i[4:0]]  <= 1'b1;
        if (br_complete_flag_i)    rob_complete[br_commit_rob_id_i[4:0]]    <= 1'b1;
        if (store_complete_flag_i) rob_complete[store_commit_rob_id_i[4:0]] <= 1'b1;
        if (load_complete_flag_i)  rob_complete[load_commit_rob_id_i[4:0]]  <= 1'b1;
        `ifdef use_m_extension
        if (mul_complete_flag_i)   rob_complete[mul_commit_rob_id_i[4:0]]   <= 1'b1;
        if (div_complete_flag_i)   rob_complete[div_commit_rob_id_i[4:0]]   <= 1'b1;
        `endif
        // 分配ROB条目
        if (~stall) begin
            if (inst_valid_port0_i) begin
                rob_valid[rob_id_inst0_o[4:0]] <= 1'b1;
                rob_complete[rob_id_inst0_o[4:0]] <= 1'b0;
                rob_snap_id[rob_id_inst0_o[4:0]] <= snap_id_inst0_i;
                rob_br_mask[rob_id_inst0_o[4:0]] <= branch_mask_inst0_i;
            end
            if (inst_valid_port1_i) begin
                rob_valid[rob_id_inst1_o[4:0]] <= 1'b1;
                rob_complete[rob_id_inst1_o[4:0]] <= 1'b0;
                rob_snap_id[rob_id_inst1_o[4:0]] <= snap_id_inst1_i;
                rob_br_mask[rob_id_inst1_o[4:0]] <= branch_mask_inst1_i;
            end
            rob_wr_ptr <= rob_wr_ptr + rob_req;
        end
        // 提交指令，释放ROB条目
        if (commit_inst0_o) begin
            rob_valid[rob_rd_ptr] <= 1'b0;
            
            if (commit_inst1_o) begin
                // 提交两条
                rob_valid[(rob_rd_ptr + 5'd1) & 5'b11111] <= 1'b0;
                rob_rd_ptr   <= rob_rd_ptr + 5'd2;
            end
            else begin
                // 只提交一条
                rob_rd_ptr   <= rob_rd_ptr + 5'd1;
            end
        end
        rob_free_cnt <= rob_free_cnt + inst_commit_cnt - ((~stall) ? rob_req : 0);
        // 提交释放掩码
        if (free_snap_flag_inst0_o) begin
            for (i = 0; i < 32; i = i + 1) begin
                rob_br_mask[i][free_snap_id_inst0_o] <= 1'b0; // 清除对应位
            end
        end
        if (free_snap_flag_inst1_o) begin
            for (i = 0; i < 32; i = i + 1) begin
                rob_br_mask[i][free_snap_id_inst1_o] <= 1'b0; // 清除对应位
            end
        end
    end
end
// ROB静态信息存储
rob_bank u_rob_static_bank0 (
    .a(rob_id_port0[4:1]),
    .d(rob_port0_wdata),
    .dpra(rob_raddr_port0[4:1]),
    .clk(clk),
    .we(rob_port0_we && !stall),
    .dpo(rob_static_data_port0)
);
rob_bank u_rob_static_bank1 (
    .a(rob_id_port1[4:1]),
    .d(rob_port1_wdata),
    .dpra(rob_raddr_port1[4:1]),
    .clk(clk),
    .we(rob_port1_we && !stall),
    .dpo(rob_static_data_port1)
);





endmodule