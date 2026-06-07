`include "defines.vh"

`timescale 1ns / 1ps

// 发射模块
module Issue (
    input clk,
    input rst,

    // from dispatch
    input [15:0] inst_addr_i,                   // 指令地址
    input [2:0] ras_snap_ptr_i,                 // RAS快照指针
    input [2:0] inst_type_port0_i,              // 指令类型
    input [2:0] inst_type_port1_i,              // 指令类型
    input [3:0] inst_subtype_port0_i,           // 指令子类型
    input [3:0] inst_subtype_port1_i,           // 指令子类型
    input [1:0] op1_src_port0_i,                // 操作数1来源选择
    input [1:0] op1_src_port1_i,                // 操作数1来源选择
    input [1:0] op2_src_port0_i,                // 操作数2来源选择
    input [1:0] op2_src_port1_i,                // 操作数2来源选择
    input inst_valid_port0_i,                   // 指令有效标志
    input inst_valid_port1_i,                   // 指令有效标志
    input [31:0] imm_port0_i,                   // 立即数
    input [31:0] imm_port1_i,                   // 立即数
    input [31:0] aux_addr_port0_i,              // Auxiliary Address（辅助地址）
    input [31:0] aux_addr_port1_i,              // Auxiliary Address（辅助地址）
    input bpu_pre_flag_port0_i,                 // 预测标志
    input bpu_pre_flag_port1_i,                 // 预测标志
    input [31:0] bpu_pre_addr_port0_i,          // 预测地址
    input [31:0] bpu_pre_addr_port1_i,          // 预测地址
    input [5:0] praddr1_inst0_i,         // 指令0物理寄存器1读地址
    input [5:0] praddr2_inst0_i,         // 指令0物理寄存器2读地址
    input [5:0] praddr1_inst1_i,         // 指令1物理寄存器1读地址
    input [5:0] praddr2_inst1_i,         // 指令1物理寄存器2读地址
    input [5:0] pwaddr_inst0_i,          // 指令0物理寄存器写地址
    input [5:0] pwaddr_inst1_i,          // 指令1物理寄存器写地址
    input [3:0] branch_mask_inst0_i,     // 指令0分支掩码
    input [3:0] branch_mask_inst1_i,     // 指令1分支掩码
    input [1:0] snap_id_inst0_i,         // 指令0快照id
    input [1:0] snap_id_inst1_i,         // 指令1快照id

    // from ROB
    input rob_stall_i,                       // ROB满暂停标志
    input [5:0] rob_id_inst0_i,              // 指令0 ROB id
    input [5:0] rob_id_inst1_i,              // 指令1 ROB id

    // from commit
    input [1:0] sq_commit_cnt_i,               // store queue提交数量
    input free_mask_inst0_i,                   // 指令0释放掩码标志
    input [1:0] free_id_inst0_i,               // 指令0释放id
    input free_mask_inst1_i,                   // 指令1释放掩码标志
    input [1:0] free_id_inst1_i,               // 指令1释放id

    // from clint
    input int_flag_i,                       // 中断标志

    // from ex
    input jump_flag_i,                      // 跳转标志
    input [1:0] kill_mask_id_i,             // 杀死指令掩码
    input [2:0] restore_mem_wr_ptr_i,       // 恢复mem队列写指针
    input [2:0] restore_sq_ptr_i,           // 恢复store queue指针
    // from ALU0
    input [5:0] alu0_rf_pwaddr_i,           // ALU0读寄存器文件阶段物理寄存器地址
    // from ALU1
    input [5:0] alu1_rf_pwaddr_i,           // ALU1读寄存器文件阶段物理寄存器地址
    // from branch
    input [5:0] branch_rf_pwaddr_i,         // branch读寄存器文件阶段物理寄存器地址
    // from mem
    input mem_flush_i,                      // mem冲刷标志
    input mem_stall_i,                      // mem暂停标志
    input [5:0] mem_pwaddr_i,
    `ifdef use_m_extension
    // from div
    input div_flush_i,                      // div冲刷标志
    input div_stall_i,                      // div暂停标志
    `endif

    // from regs
    input [63:0] ready_flag_i,          // 寄存器就绪标志，位0-63分别对应物理寄存器0-63

    // to ALU0
    output alu_inst_valid_inst0_o,       // ALU0指令有效标志
    output [5:0] alu_rob_id_inst0_o,     // ALU0 ROB id
    output [3:0] alu_mask_inst0_o,       // ALU0分支掩码
    output [3:0] alu_subtype_inst0_o,    // ALU0指令子类型
    output [1:0] alu_op1_src_inst0_o,    // ALU0操作数1
    output [1:0] alu_op2_src_inst0_o,    // ALU0操作数2
    output [5:0] alu_praddr1_inst0_o,    // ALU0物理寄存器1读地址
    output [5:0] alu_praddr2_inst0_o,    // ALU0物理寄存器2读地址
    output [5:0] alu_pwaddr_inst0_o,     // ALU0物理寄存器写地址
    output [31:0] alu_imm_inst0_o,       // ALU0立即数

    // to ALU1
    output alu_inst_valid_inst1_o,       // ALU1指令有效标志
    output [5:0] alu_rob_id_inst1_o,     // ALU1 ROB id
    output [3:0] alu_mask_inst1_o,       // ALU1分支掩码
    output [3:0] alu_subtype_inst1_o,    // ALU1指令子类型
    output [1:0] alu_op1_src_inst1_o,    // ALU1操作数1
    output [1:0] alu_op2_src_inst1_o,    // ALU1操作数2
    output [5:0] alu_praddr1_inst1_o,    // ALU1物理寄存器1读地址
    output [5:0] alu_praddr2_inst1_o,    // ALU1物理寄存器2读地址
    output [5:0] alu_pwaddr_inst1_o,     // ALU1物理寄存器写地址
    output [31:0] alu_imm_inst1_o,       // ALU1立即数

    // to branch
    output br_inst_valid_o,              // branch指令有效标志
    output [15:0] br_inst_addr_o,        // branch指令地址
    output [5:0] br_rob_id_o,            // branch ROB id
    output br_bpu_pre_flag_o,            // branch BPU预测标志
    output [31:0] br_bpu_pre_addr_o,     // branch BPU预测地址
    output [3:0] br_mask_o,              // branch分支掩码
    output [2:0] br_ras_ptr_o,           // branch RAS快照指针
    output [2:0] br_mem_wr_ptr_o,        // branch mem队列写操作快照指针
    output [2:0] br_sq_ptr_o,            // branch store queue快照指针
    output [1:0] br_snap_id_o,           // branch快照id
    output [2:0] br_type_o,              // branch指令类型
    output [3:0] br_subtype_o,           // branch指令子类型
    output [1:0] br_op1_src_o,           // branch操作数1
    output [1:0] br_op2_src_o,           // branch操作数2
    output [5:0] br_praddr1_o,           // branch物理寄存器1读地址
    output [5:0] br_praddr2_o,           // branch物理寄存器2读地址
    output [5:0] br_pwaddr_o,            // branch物理寄存器写地址
    output [31:0] br_imm_o,              // branch立即数
    output [31:0] br_aux_addr_o,         // branch辅助地址

    // to mem
    output mem_inst_valid_o,             // mem指令有效标志
    output [5:0] mem_rob_id_o,           // mem ROB id
    output [3:0] mem_mask_o,             // mem分支掩码
    output [1:0] mem_sq_id_o,            // mem SQ id
    output [3:0] mem_subtype_o,          // mem指令子类型
    output [1:0] mem_op1_src_o,          // mem操作数1
    output [1:0] mem_op2_src_o,          // mem操作数2
    output [5:0] mem_praddr1_o,          // mem物理寄存器1读地址
    output [5:0] mem_praddr2_o,          // mem物理寄存器2读地址
    output [5:0] mem_pwaddr_o,           // mem物理寄存器写地址
    output [31:0] mem_imm_o,             // mem立即数

    `ifdef use_m_extension
    // to mul
    output mul_inst_valid_o,             // mul指令有效标志
    output [5:0] mul_rob_id_o,           // mul ROB id
    output [3:0] mul_mask_o,             // mul分支掩码
    output [3:0] mul_subtype_o,          // mul指令子类型
    output [5:0] mul_praddr1_o,          // mul物理寄存器1读地址
    output [5:0] mul_praddr2_o,          // mul物理寄存器2读地址
    output [5:0] mul_pwaddr_o,           // mul物理寄存器写地址
    // to div
    output div_inst_valid_o,             // div指令有效标志
    output [5:0] div_rob_id_o,           // div ROB id
    output [3:0] div_mask_o,             // div分支掩码
    output [3:0] div_subtype_o,          // div指令子类型
    output [5:0] div_praddr1_o,          // div物理寄存器1读地址
    output [5:0] div_praddr2_o,          // div物理寄存器2读地址
    output [5:0] div_pwaddr_o,           // div物理寄存器写地址
    `endif

    // to ROB
    output stall_rob_o,
    // to pipeline
    output stall_o
);

// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;

// ALU发射队列
reg alu_inst_valid[0:7];       // 指令有效标志
reg [5:0] alu_rob_id[0:7];     // ROB id
reg [3:0] alu_mask[0:7];       // 分支掩码
reg [3:0] alu_subtype[0:7];    // 指令子类型
reg [1:0] alu_op1_src[0:7];    // 操作数1来源选择
reg [1:0] alu_op2_src[0:7];    // 操作数2来源选择
reg [5:0] alu_praddr1[0:7];    // 物理寄存器1读地址
reg [5:0] alu_praddr2[0:7];    // 物理寄存器2读地址
reg [5:0] alu_pwaddr[0:7];     // 物理寄存器写地址
reg [31:0] alu_imm[0:7];       // 立即数
// 空闲计数
wire [3:0] alu_busy_cnt = alu_inst_valid[0] + alu_inst_valid[1] + alu_inst_valid[2] + alu_inst_valid[3] +
                          alu_inst_valid[4] + alu_inst_valid[5] + alu_inst_valid[6] + alu_inst_valid[7];
wire [3:0] alu_free_cnt = 4'd8 - alu_busy_cnt;
// 分配需求
wire alu_need_slot0 = (inst_valid_port0_i && inst_type_port0_i == `TYPE_ALU);
wire alu_need_slot1 = (inst_valid_port1_i && inst_type_port1_i == `TYPE_ALU);
wire [1:0] alu_req = alu_need_slot0 + alu_need_slot1;
// 暂停信号
wire alu_stall = (alu_req > alu_free_cnt);
// 发射逻辑
integer i;
reg alu_issue_flag_inst0, alu_issue_flag_inst1;
reg [2:0] alu_issue_slot_inst0, alu_issue_slot_inst1;
// 检查操作数是否就绪
reg alu_op1_ready[0:7];
reg alu_op2_ready[0:7];
reg alu_dep_mem[0:7];
always @(*) begin
    for (i = 0; i < 8; i = i + 1) begin
        alu_op1_ready[i] = (alu_op1_src[i] != `OP1_REG) || ready_flag_i[alu_praddr1[i]] || 
                       (alu_praddr1[i] == alu0_rf_pwaddr_i) || (alu_praddr1[i] == alu1_rf_pwaddr_i) ||
                       (alu_praddr1[i] == mem_pwaddr_i);
        alu_op2_ready[i] = (alu_op2_src[i] != `OP2_REG) || ready_flag_i[alu_praddr2[i]] || 
                       (alu_praddr2[i] == alu0_rf_pwaddr_i) || (alu_praddr2[i] == alu1_rf_pwaddr_i) ||
                       (alu_praddr2[i] == mem_pwaddr_i);

        alu_dep_mem[i] = ((alu_praddr1[i] == mem_pwaddr_i) || (alu_praddr2[i] == mem_pwaddr_i)) 
                                && (mem_pwaddr_i != 6'b0);
    end
end
// 选择发射指令
reg alu_ns_flag0, alu_ns_flag1;
reg [2:0] alu_ns_slot0, alu_ns_slot1;
reg alu_s_flag0, alu_s_flag1;
reg [2:0] alu_s_slot0, alu_s_slot1;

always @(*) begin
    alu_ns_flag0 = 1'b0;
    alu_ns_flag1 = 1'b0;
    alu_ns_slot0 = 3'd0;
    alu_ns_slot1 = 3'd0;
    alu_s_flag0 = 1'b0;
    alu_s_flag1 = 1'b0;
    alu_s_slot0 = 3'd0;
    alu_s_slot1 = 3'd0;
    for (i = 0; i < 8; i = i + 1) begin
        if (alu_inst_valid[i] && alu_op1_ready[i] && alu_op2_ready[i] && ((alu_mask[i] & kill_mask) == 0)) begin // 找到就绪指令
            // 没有stall的情况
            if (!alu_ns_flag0) begin
                alu_ns_flag0 = 1'b1;
                alu_ns_slot0 = i[2:0];
            end
            else if (!alu_ns_flag1) begin
                alu_ns_flag1 = 1'b1;
                alu_ns_slot1 = i[2:0];
            end
            
            // 有stall的情况
            if (!alu_dep_mem[i]) begin
                if (!alu_s_flag0) begin
                    alu_s_flag0 = 1'b1;
                    alu_s_slot0 = i[2:0];
                end
                else if (!alu_s_flag1) begin
                    alu_s_flag1 = 1'b1;
                    alu_s_slot1 = i[2:0];
                end
            end
        end
    end
end

always @(*) begin
    if (mem_stall_i) begin
        alu_issue_flag_inst0 = alu_s_flag0;
        alu_issue_slot_inst0 = alu_s_slot0;
        alu_issue_flag_inst1 = alu_s_flag1;
        alu_issue_slot_inst1 = alu_s_slot1;
    end else begin
        alu_issue_flag_inst0 = alu_ns_flag0;
        alu_issue_slot_inst0 = alu_ns_slot0;
        alu_issue_flag_inst1 = alu_ns_flag1;
        alu_issue_slot_inst1 = alu_ns_slot1;
    end
end
// 分配逻辑
// 寻找空位
reg [2:0] alu_free_slot0, alu_free_slot1;
reg alu_found_slot0, alu_found_slot1;
always @(*) begin
    alu_found_slot0 = 1'b0;
    alu_found_slot1 = 1'b0;
    alu_free_slot0 = 3'd0;
    alu_free_slot1 = 3'd0;
    for (i = 0; i < 8; i = i + 1) begin
        if (!alu_inst_valid[i]) begin // 发现空位
            if (!alu_found_slot0) begin
                // 找到第一个空位
                alu_free_slot0 = i[2:0];
                alu_found_slot0 = 1'b1;
            end
            else if (!alu_found_slot1) begin
                // 已经找到第一个了，现在找到第二个
                alu_free_slot1 = i[2:0];
                alu_found_slot1 = 1'b1;
            end
        end
    end
end
// 写入队列
always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 8; i = i + 1) begin
            alu_inst_valid[i] <= 1'b0;
            alu_rob_id[i] <= 6'b0;
            alu_mask[i] <= 4'b0;
            alu_subtype[i] <= 4'b0;
            alu_op1_src[i] <= 2'b0;
            alu_op2_src[i] <= 2'b0;
            alu_praddr1[i] <= 6'b0;
            alu_praddr2[i] <= 6'b0;
            alu_pwaddr[i] <= 6'b0;
            alu_imm[i] <= 32'b0;
        end
    end
    else if (int_flag_i) begin
        // 冲刷所有指令
        for (i = 0; i < 8; i = i + 1) begin
            alu_inst_valid[i] <= 1'b0; // 冲刷指令
        end
    end
    else if (jump_flag_i) begin
        // 冲刷所有被杀死的指令
        for (i = 0; i < 8; i = i + 1) begin
            if ((alu_mask[i] & kill_mask) != 0) begin
                alu_inst_valid[i] <= 1'b0; // 冲刷指令
            end
        end
        // 发射后将指令无效化
        if (alu_issue_flag_inst0) alu_inst_valid[alu_issue_slot_inst0] <= 1'b0;
        if (alu_issue_flag_inst1) alu_inst_valid[alu_issue_slot_inst1] <= 1'b0;
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                alu_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                alu_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
    else begin
        // 发射后将指令无效化
        if (alu_issue_flag_inst0) alu_inst_valid[alu_issue_slot_inst0] <= 1'b0;
        if (alu_issue_flag_inst1) alu_inst_valid[alu_issue_slot_inst1] <= 1'b0;
        // 写入新指令
        if (~stall_o) begin
            // 分配指令0
            if (alu_need_slot0) begin
                alu_inst_valid[alu_free_slot0] <= 1'b1;
                alu_rob_id[alu_free_slot0] <= rob_id_inst0_i;
                alu_mask[alu_free_slot0] <= branch_mask_inst0_i;
                alu_subtype[alu_free_slot0] <= inst_subtype_port0_i;
                alu_op1_src[alu_free_slot0] <= op1_src_port0_i;
                alu_op2_src[alu_free_slot0] <= op2_src_port0_i;
                alu_praddr1[alu_free_slot0] <= praddr1_inst0_i;
                alu_praddr2[alu_free_slot0] <= praddr2_inst0_i;
                alu_pwaddr[alu_free_slot0] <= pwaddr_inst0_i;
                alu_imm[alu_free_slot0] <= imm_port0_i;
                // 分配指令1
                if (alu_need_slot1) begin
                    alu_inst_valid[alu_free_slot1] <= 1'b1;
                    alu_rob_id[alu_free_slot1] <= rob_id_inst1_i;
                    alu_mask[alu_free_slot1] <= branch_mask_inst1_i;
                    alu_subtype[alu_free_slot1] <= inst_subtype_port1_i;
                    alu_op1_src[alu_free_slot1] <= op1_src_port1_i;
                    alu_op2_src[alu_free_slot1] <= op2_src_port1_i;
                    alu_praddr1[alu_free_slot1] <= praddr1_inst1_i;
                    alu_praddr2[alu_free_slot1] <= praddr2_inst1_i;
                    alu_pwaddr[alu_free_slot1] <= pwaddr_inst1_i;
                    alu_imm[alu_free_slot1] <= imm_port1_i;
                end
            end
            else if (alu_need_slot1) begin // 指令0不需要但指令1需要
                alu_inst_valid[alu_free_slot0] <= 1'b1;
                alu_rob_id[alu_free_slot0] <= rob_id_inst1_i;
                alu_mask[alu_free_slot0] <= branch_mask_inst1_i;
                alu_subtype[alu_free_slot0] <= inst_subtype_port1_i;
                alu_op1_src[alu_free_slot0] <= op1_src_port1_i;
                alu_op2_src[alu_free_slot0] <= op2_src_port1_i;
                alu_praddr1[alu_free_slot0] <= praddr1_inst1_i;
                alu_praddr2[alu_free_slot0] <= praddr2_inst1_i;
                alu_pwaddr[alu_free_slot0] <= pwaddr_inst1_i;
                alu_imm[alu_free_slot0] <= imm_port1_i;
            end
        end
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                alu_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                alu_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
end

// 输出寄存器
reg [3:0] alu0_mask_new, alu1_mask_new;
always @(*) begin
    alu0_mask_new = alu_mask[alu_issue_slot_inst0];
    alu1_mask_new = alu_mask[alu_issue_slot_inst1];
    if (free_mask_inst0_i) begin
        alu0_mask_new[free_id_inst0_i] = 1'b0;
        alu1_mask_new[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        alu0_mask_new[free_id_inst1_i] = 1'b0;
        alu1_mask_new[free_id_inst1_i] = 1'b0;
    end
end
iss_alu u_iss_alu_inst0 (
    .clk(clk),
    .rst(rst),
    // from issue
    .int_flag_i(int_flag_i),                     // 中断标志
    .issue_flag_i(alu_issue_flag_inst0),                   // 发射标志
    .alu_rob_id_i(alu_rob_id[alu_issue_slot_inst0]),                   // ROB id
    .alu_mask_i(alu0_mask_new),                                        // 分支掩码
    .alu_subtype_i(alu_subtype[alu_issue_slot_inst0]),                 // 指令子类型
    .alu_op1_src_i(alu_op1_src[alu_issue_slot_inst0]),                 // 操作数1来源选择
    .alu_op2_src_i(alu_op2_src[alu_issue_slot_inst0]),                 // 操作数2来源选择
    .alu_praddr1_i(alu_praddr1[alu_issue_slot_inst0]),                 // 物理寄存器1读地址
    .alu_praddr2_i(alu_praddr2[alu_issue_slot_inst0]),                 // 物理寄存器2读地址
    .alu_pwaddr_i(alu_pwaddr[alu_issue_slot_inst0]),                   // 物理寄存器写地址
    .alu_imm_i(alu_imm[alu_issue_slot_inst0]),                           // 立即数
    // to ex
    .alu_inst_valid_o(alu_inst_valid_inst0_o),          // 指令有效标志
    .alu_rob_id_o(alu_rob_id_inst0_o),                   // ROB id
    .alu_mask_o(alu_mask_inst0_o),                       // 分支掩码
    .alu_subtype_o(alu_subtype_inst0_o),                 // 指令子类型
    .alu_op1_src_o(alu_op1_src_inst0_o),                 // 操作数1
    .alu_op2_src_o(alu_op2_src_inst0_o),                 // 操作数2
    .alu_praddr1_o(alu_praddr1_inst0_o),                 // 物理寄存器1读地址
    .alu_praddr2_o(alu_praddr2_inst0_o),                 // 物理寄存器2读地址
    .alu_pwaddr_o(alu_pwaddr_inst0_o),                   // 物理寄存器写地址
    .alu_imm_o(alu_imm_inst0_o)                           // 立即数
);
iss_alu u_iss_alu_inst1 (
    .clk(clk),
    .rst(rst),
    // from issue
    .int_flag_i(int_flag_i),                     // 中断标志
    .issue_flag_i(alu_issue_flag_inst1),                   // 发射标志
    .alu_rob_id_i(alu_rob_id[alu_issue_slot_inst1]),                   // ROB id
    .alu_mask_i(alu1_mask_new),                                        // 分支掩码
    .alu_subtype_i(alu_subtype[alu_issue_slot_inst1]),                 // 指令子类型
    .alu_op1_src_i(alu_op1_src[alu_issue_slot_inst1]),                 // 操作数1来源选择
    .alu_op2_src_i(alu_op2_src[alu_issue_slot_inst1]),                 // 操作数2来源选择
    .alu_praddr1_i(alu_praddr1[alu_issue_slot_inst1]),                 // 物理寄存器1读地址
    .alu_praddr2_i(alu_praddr2[alu_issue_slot_inst1]),                 // 物理寄存器2读地址
    .alu_pwaddr_i(alu_pwaddr[alu_issue_slot_inst1]),                   // 物理寄存器写地址
    .alu_imm_i(alu_imm[alu_issue_slot_inst1]),                           // 立即数
    // to ex
    .alu_inst_valid_o(alu_inst_valid_inst1_o),          // 指令有效标志
    .alu_rob_id_o(alu_rob_id_inst1_o),                   // ROB id
    .alu_mask_o(alu_mask_inst1_o),                       // 分支掩码
    .alu_subtype_o(alu_subtype_inst1_o),                 // 指令子类型
    .alu_op1_src_o(alu_op1_src_inst1_o),                 // 操作数1
    .alu_op2_src_o(alu_op2_src_inst1_o),                 // 操作数2
    .alu_praddr1_o(alu_praddr1_inst1_o),                 // 物理寄存器1读地址
    .alu_praddr2_o(alu_praddr2_inst1_o),                 // 物理寄存器2读地址
    .alu_pwaddr_o(alu_pwaddr_inst1_o),                   // 物理寄存器写地址
    .alu_imm_o(alu_imm_inst1_o)                           // 立即数
);



// Branch发射队列
reg branch_inst_valid[0:3];        // 指令有效标志
reg [15:0] branch_inst_addr[0:3];  // 指令地址
reg [5:0] branch_rob_id[0:3];      // ROB id
reg branch_pre_flag[0:3];          // 预测标志
reg [31:0] branch_pre_addr[0:3];   // 预测地址
reg [3:0] branch_mask[0:3];        // 分支掩码
reg [2:0] branch_ras_ptr[0:3];     // RAS快照指针
reg [2:0] branch_mem_wr_ptr[0:3];  // mem队列写操作快照指针
reg [2:0] branch_sq_ptr[0:3];      // store queue分配快照指针
reg [1:0] branch_snap_id[0:3];     // 快照id
reg [2:0] branch_type[0:3];        // 指令类型
reg [3:0] branch_subtype[0:3];     // 指令子类型
reg [1:0] branch_op1_src[0:3];     // 操作数1来源选择
reg [1:0] branch_op2_src[0:3];     // 操作数2来源选择
reg [5:0] branch_praddr1[0:3];     // 物理寄存器1读地址
reg [5:0] branch_praddr2[0:3];     // 物理寄存器2读地址
reg [5:0] branch_pwaddr[0:3];      // 物理寄存器写地址
reg [31:0] branch_imm[0:3];        // 立即数
reg [31:0] branch_aux_addr[0:3];   // 辅助地址
// 空闲计数
wire [2:0] branch_busy_cnt = branch_inst_valid[0] + branch_inst_valid[1] + branch_inst_valid[2] + branch_inst_valid[3];
wire [2:0] branch_free_cnt = 3'd4 - branch_busy_cnt;
// 分配需求
wire branch_need_slot0 = (inst_valid_port0_i && (inst_type_port0_i == `TYPE_BR || inst_type_port0_i == `TYPE_JAL));
wire branch_need_slot1 = (inst_valid_port1_i && (inst_type_port1_i == `TYPE_BR || inst_type_port1_i == `TYPE_JAL));
wire [1:0] branch_req = branch_need_slot0 + branch_need_slot1;
// 暂停信号
wire branch_stall = (branch_req > branch_free_cnt);
// 发射逻辑
reg br_issue_flag;
reg [1:0] br_issue_slot;
// 检查操作数是否就绪
reg br_op1_ready[0:3];
reg br_op2_ready[0:3];
reg br_dep_mem[0:3];
always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        br_op1_ready[i] = (branch_op1_src[i] != `OP1_REG) || ready_flag_i[branch_praddr1[i]] || 
                       (branch_praddr1[i] == alu0_rf_pwaddr_i) || (branch_praddr1[i] == alu1_rf_pwaddr_i) ||
                       (branch_praddr1[i] == mem_pwaddr_i);
        br_op2_ready[i] = (branch_op2_src[i] != `OP2_REG) || ready_flag_i[branch_praddr2[i]] || 
                       (branch_praddr2[i] == alu0_rf_pwaddr_i) || (branch_praddr2[i] == alu1_rf_pwaddr_i) ||
                       (branch_praddr2[i] == mem_pwaddr_i);

        br_dep_mem[i] = ((branch_praddr1[i] == mem_pwaddr_i) || (branch_praddr2[i] == mem_pwaddr_i)) 
                               && (mem_pwaddr_i != 6'b0);
    end
end
// 选择发射指令
reg br_ns_flag;
reg [1:0] br_ns_slot;
reg br_s_flag;
reg [1:0] br_s_slot;

always @(*) begin
    br_ns_flag = 1'b0;
    br_ns_slot = 2'd0;
    br_s_flag = 1'b0;
    br_s_slot = 2'd0;
    for (i = 0; i < 4; i = i + 1) begin
        if (branch_inst_valid[i] && br_op1_ready[i] && br_op2_ready[i] && ((branch_mask[i] & kill_mask) == 0)) begin // 找到就绪指令
            // 假设没有 stall
            if (!br_ns_flag) begin
                br_ns_flag = 1'b1;
                br_ns_slot = i[1:0];
            end
            
            // 假设有 stall
            if (!br_dep_mem[i]) begin
                if (!br_s_flag) begin
                    br_s_flag = 1'b1;
                    br_s_slot = i[1:0];
                end
            end
        end
    end
end

always @(*) begin
    if (mem_stall_i) begin
        br_issue_flag = br_s_flag;
        br_issue_slot = br_s_slot;
    end else begin
        br_issue_flag = br_ns_flag;
        br_issue_slot = br_ns_slot;
    end
end
// 分配逻辑
// 寻找空位
reg [1:0] br_free_slot0, br_free_slot1;
reg br_found_slot0, br_found_slot1;
always @(*) begin
    br_found_slot0 = 1'b0;
    br_found_slot1 = 1'b0;
    br_free_slot0 = 2'd0;
    br_free_slot1 = 2'd0;
    for (i = 0; i < 4; i = i + 1) begin
        if (!branch_inst_valid[i]) begin // 发现空位
            if (!br_found_slot0) begin
                // 找到第一个空位
                br_free_slot0 = i[1:0];
                br_found_slot0 = 1'b1;
            end
            else if (!br_found_slot1) begin
                // 已经找到第一个了，现在找到第二个
                br_free_slot1 = i[1:0];
                br_found_slot1 = 1'b1;
            end
        end
    end
end
// 写入队列
always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 4; i = i + 1) begin
            branch_inst_valid[i] <= 1'b0;
            branch_inst_addr[i] <= 16'b0;
            branch_rob_id[i] <= 6'b0;
            branch_pre_flag[i] <= 1'b0;
            branch_pre_addr[i] <= 32'b0;
            branch_mask[i] <= 4'b0;
            branch_ras_ptr[i] <= 3'b0;
            branch_mem_wr_ptr[i] <= 3'b0;
            branch_sq_ptr[i] <= 3'b0;
            branch_snap_id[i] <= 2'b0;
            branch_type[i] <= 3'b0;
            branch_subtype[i] <= 4'b0;
            branch_op1_src[i] <= 2'b0;
            branch_op2_src[i] <= 2'b0;
            branch_praddr1[i] <= 6'b0;
            branch_praddr2[i] <= 6'b0;
            branch_pwaddr[i] <= 6'b0;
            branch_imm[i] <= 32'b0;
            branch_aux_addr[i] <= 32'b0;
        end
    end
    else if (int_flag_i) begin
        // 冲刷所有指令
        for (i = 0; i < 4; i = i + 1) begin
            branch_inst_valid[i] <= 1'b0; // 冲刷指令
        end
    end
    else if (jump_flag_i) begin
        // 冲刷所有被杀死的指令
        for (i = 0; i < 4; i = i + 1) begin
            if ((branch_mask[i] & kill_mask) != 0) begin
                branch_inst_valid[i] <= 1'b0; // 冲刷指令
            end
        end
        // 发射后将指令无效化
        if (br_issue_flag) branch_inst_valid[br_issue_slot] <= 1'b0;
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                branch_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                branch_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
    else begin
        // 发射后将指令无效化
        if (br_issue_flag) branch_inst_valid[br_issue_slot] <= 1'b0;
        // 写入新指令
        if (~stall_o) begin
            // 分配指令0
            if (branch_need_slot0) begin
                branch_inst_valid[br_free_slot0] <= 1'b1;
                branch_inst_addr[br_free_slot0] <= {inst_addr_i[15:3], 3'b000};
                branch_rob_id[br_free_slot0] <= rob_id_inst0_i;
                branch_pre_flag[br_free_slot0] <= bpu_pre_flag_port0_i;
                branch_pre_addr[br_free_slot0] <= bpu_pre_addr_port0_i;
                branch_mask[br_free_slot0] <= branch_mask_inst0_i;
                branch_ras_ptr[br_free_slot0] <= ras_snap_ptr_i;
                branch_mem_wr_ptr[br_free_slot0] <= mem_wr_ptr;
                branch_sq_ptr[br_free_slot0] <= sq_alloc_ptr;
                branch_snap_id[br_free_slot0] <= snap_id_inst0_i;
                branch_type[br_free_slot0] <= inst_type_port0_i;
                branch_subtype[br_free_slot0] <= inst_subtype_port0_i;
                branch_op1_src[br_free_slot0] <= op1_src_port0_i;
                branch_op2_src[br_free_slot0] <= op2_src_port0_i;
                branch_praddr1[br_free_slot0] <= praddr1_inst0_i;
                branch_praddr2[br_free_slot0] <= praddr2_inst0_i;
                branch_pwaddr[br_free_slot0] <= pwaddr_inst0_i;
                branch_imm[br_free_slot0] <= imm_port0_i;
                branch_aux_addr[br_free_slot0] <= aux_addr_port0_i;
                // 分配指令1
                if (branch_need_slot1) begin
                    branch_inst_valid[br_free_slot1] <= 1'b1;
                    branch_inst_addr[br_free_slot1] <= {inst_addr_i[15:3], 3'b100};
                    branch_rob_id[br_free_slot1] <= rob_id_inst1_i;
                    branch_pre_flag[br_free_slot1] <= bpu_pre_flag_port1_i;
                    branch_pre_addr[br_free_slot1] <= bpu_pre_addr_port1_i;
                    branch_mask[br_free_slot1] <= branch_mask_inst1_i;
                    branch_ras_ptr[br_free_slot1] <= ras_snap_ptr_i;
                    branch_mem_wr_ptr[br_free_slot1] <= mem_wr_ptr;
                    branch_sq_ptr[br_free_slot1] <= sq_alloc_ptr;
                    branch_snap_id[br_free_slot1] <= snap_id_inst1_i;
                    branch_type[br_free_slot1] <= inst_type_port1_i;
                    branch_subtype[br_free_slot1] <= inst_subtype_port1_i;
                    branch_op1_src[br_free_slot1] <= op1_src_port1_i;
                    branch_op2_src[br_free_slot1] <= op2_src_port1_i;
                    branch_praddr1[br_free_slot1] <= praddr1_inst1_i;
                    branch_praddr2[br_free_slot1] <= praddr2_inst1_i;
                    branch_pwaddr[br_free_slot1] <= pwaddr_inst1_i;
                    branch_imm[br_free_slot1] <= imm_port1_i;
                    branch_aux_addr[br_free_slot1] <= aux_addr_port1_i;
                end
            end
            else if (branch_need_slot1) begin // 指令0不需要但指令1需要
                branch_inst_valid[br_free_slot0] <= 1'b1;
                branch_inst_addr[br_free_slot0] <= {inst_addr_i[15:3], 3'b100};
                branch_rob_id[br_free_slot0] <= rob_id_inst1_i;
                branch_pre_flag[br_free_slot0] <= bpu_pre_flag_port1_i;
                branch_pre_addr[br_free_slot0] <= bpu_pre_addr_port1_i;
                branch_mask[br_free_slot0] <= branch_mask_inst1_i;
                branch_ras_ptr[br_free_slot0] <= ras_snap_ptr_i;
                branch_mem_wr_ptr[br_free_slot0] <= mem_wr_ptr + {2'b0, mem_need_slot0};
                branch_sq_ptr[br_free_slot0] <= sq_alloc_ptr + {2'b0, is_store_inst0};
                branch_snap_id[br_free_slot0] <= snap_id_inst1_i;
                branch_type[br_free_slot0] <= inst_type_port1_i;
                branch_subtype[br_free_slot0] <= inst_subtype_port1_i;
                branch_op1_src[br_free_slot0] <= op1_src_port1_i;
                branch_op2_src[br_free_slot0] <= op2_src_port1_i;
                branch_praddr1[br_free_slot0] <= praddr1_inst1_i;
                branch_praddr2[br_free_slot0] <= praddr2_inst1_i;
                branch_pwaddr[br_free_slot0] <= pwaddr_inst1_i;
                branch_imm[br_free_slot0] <= imm_port1_i;
                branch_aux_addr[br_free_slot0] <= aux_addr_port1_i;
            end
        end
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                branch_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                branch_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
end

// 输出寄存器
reg [3:0] br_mask_new;
always @(*) begin
    br_mask_new = branch_mask[br_issue_slot];
    if (free_mask_inst0_i) begin
        br_mask_new[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        br_mask_new[free_id_inst1_i] = 1'b0;
    end
end
iss_br u_iss_br (
    .clk(clk),
    .rst(rst),
    // from issue
    .int_flag_i(int_flag_i),                 // 中断标志
    .issue_flag_i(br_issue_flag),               // 发射标志
    .bpu_pre_flag_i(branch_pre_flag[br_issue_slot]),           // 预测标志
    .bpu_pre_addr_i(branch_pre_addr[br_issue_slot]),           // 预测地址
    .inst_addr_i(branch_inst_addr[br_issue_slot]),               // 指令地址
    .rob_id_i(branch_rob_id[br_issue_slot]),                   // ROB id
    .mask_i(br_mask_new),                                 // 分支掩码
    .ras_ptr_i(branch_ras_ptr[br_issue_slot]),            // RAS快照指针
    .mem_wr_ptr_i(branch_mem_wr_ptr[br_issue_slot]),            // mem队列写操作快照指针
    .sq_ptr_i(branch_sq_ptr[br_issue_slot]),            // store queue快照指针
    .snap_id_i(branch_snap_id[br_issue_slot]),            // 快照id
    .type_i(branch_type[br_issue_slot]),               // 指令类型
    .subtype_i(branch_subtype[br_issue_slot]),            // 指令子类型
    .op1_src_i(branch_op1_src[br_issue_slot]),            // 操作数1来源选择
    .op2_src_i(branch_op2_src[br_issue_slot]),            // 操作数2来源选择
    .praddr1_i(branch_praddr1[br_issue_slot]),            // 物理寄存器1读地址
    .praddr2_i(branch_praddr2[br_issue_slot]),            // 物理寄存器2读地址
    .pwaddr_i(branch_pwaddr[br_issue_slot]),              // 物理寄存器写地址
    .imm_i(branch_imm[br_issue_slot]),               // 立即数
    .aux_addr_i(branch_aux_addr[br_issue_slot]),          // 辅助地址
    // to ex
    .inst_valid_o(br_inst_valid_o),          // 指令有效标志
    .inst_addr_o(br_inst_addr_o),          // 指令地址
    .rob_id_o(br_rob_id_o),               // ROB id
    .bpu_pre_flag_o(br_bpu_pre_flag_o),        // BPU预测标志
    .bpu_pre_addr_o(br_bpu_pre_addr_o),       // BPU预测地址
    .mask_o(br_mask_o),                 // 分支掩码
    .ras_ptr_o(br_ras_ptr_o),               // RAS快照指针
    .mem_wr_ptr_o(br_mem_wr_ptr_o),         // mem队列写操作快照指针
    .sq_ptr_o(br_sq_ptr_o),                 // store queue快照指针
    .snap_id_o(br_snap_id_o),       // 快照id
    .type_o(br_type_o),          // 指令类型
    .subtype_o(br_subtype_o),       // 指令子类型
    .op1_src_o(br_op1_src_o),       // 操作数1
    .op2_src_o(br_op2_src_o),       // 操作数2
    .praddr1_o(br_praddr1_o),       // 物理寄存器1读地址
    .praddr2_o(br_praddr2_o),       // 物理寄存器2读地址
    .pwaddr_o(br_pwaddr_o),         // 物理寄存器写地址
    .imm_o(br_imm_o),               // 立即数
    .aux_addr_o(br_aux_addr_o)      // 辅助地址
);



// mem发射队列
reg mem_inst_valid[0:7];       // 指令有效标志
reg [5:0] mem_rob_id[0:7];     // ROB id
reg [3:0] mem_mask[0:7];       // 分支掩码
reg [1:0] mem_sq_id[0:7];      // store queue id
reg [3:0] mem_subtype[0:7];    // 指令子类型
reg [1:0] mem_op1_src[0:7];    // 操作数1来源选择
reg [1:0] mem_op2_src[0:7];    // 操作数2来源选择
reg [5:0] mem_praddr1[0:7];    // 物理寄存器1读地址
reg [5:0] mem_praddr2[0:7];    // 物理寄存器2读地址
reg [5:0] mem_pwaddr[0:7];     // 物理寄存器写地址
reg [31:0] mem_imm[0:7];       // 立即数
// 指针管理 (Ring Buffer)
reg [2:0] mem_wr_ptr;      // 写指针 (Dispatch 阶段入队)
reg [2:0] mem_rd_ptr;      // 读指针 (Issue 阶段出队)
// MEM 队列占用计数
wire [3:0] mem_count = mem_inst_valid[0] + mem_inst_valid[1] + mem_inst_valid[2] + mem_inst_valid[3] +
                       mem_inst_valid[4] + mem_inst_valid[5] + mem_inst_valid[6] + mem_inst_valid[7];
reg [2:0] sq_alloc_ptr;    // SQ 分配指针 (截取低两位0~3)
reg [2:0] sq_count;        // SQ 占用计数 (0~4)
// Store 指令判断
wire is_store_inst0 = inst_valid_port0_i && (inst_type_port0_i == `TYPE_MEM && inst_subtype_port0_i[3] == 1'b1); // mem指令且是store
wire is_store_inst1 = inst_valid_port1_i && (inst_type_port1_i == `TYPE_MEM && inst_subtype_port1_i[3] == 1'b1); // mem指令且是store
wire [1:0] store_req = is_store_inst0 + is_store_inst1;
// 分配需求
wire mem_need_slot0 = (inst_valid_port0_i && inst_type_port0_i == `TYPE_MEM);
wire mem_need_slot1 = (inst_valid_port1_i && inst_type_port1_i == `TYPE_MEM);
wire [1:0] mem_req = mem_need_slot0 + mem_need_slot1;
// 暂停信号
wire mem_stall = (mem_req + mem_count > 4'd8) || (sq_count + store_req > 3'd4);
// 发射逻辑
reg mem_issue_flag;
wire mem_op1_ready = (mem_op1_src[mem_rd_ptr] != `OP1_REG) || ready_flag_i[mem_praddr1[mem_rd_ptr]] || 
                     (mem_praddr1[mem_rd_ptr] == alu0_rf_pwaddr_i) || (mem_praddr1[mem_rd_ptr] == alu1_rf_pwaddr_i) ||
                     (mem_praddr1[mem_rd_ptr] == mem_pwaddr_i);
wire mem_op2_ready = (mem_op2_src[mem_rd_ptr] != `OP2_REG) || ready_flag_i[mem_praddr2[mem_rd_ptr]] || 
                     (mem_praddr2[mem_rd_ptr] == alu0_rf_pwaddr_i) || (mem_praddr2[mem_rd_ptr] == alu1_rf_pwaddr_i) ||
                     (mem_praddr2[mem_rd_ptr] == mem_pwaddr_i);
always @(*) begin
    mem_issue_flag = 1'b0;
    if (mem_inst_valid[mem_rd_ptr] && mem_op1_ready && mem_op2_ready && ((mem_mask[mem_rd_ptr] & kill_mask) == 0) && !mem_stall_i) begin
        mem_issue_flag = 1'b1; // 当前队头指令就绪，未被冲刷杀死且访存没有因为miss暂停，可以发射
    end
end
// 写入队列
// 临时变量：计算 store 分配后的指针
reg [2:0] next_sq_ptr_0;
reg [2:0] next_sq_ptr_1;
always @(*) begin
    // Inst0 的 SQ ID (如果是 store)
    if (is_store_inst0) next_sq_ptr_0 = sq_alloc_ptr + 3'd1; // 自动回绕
    else next_sq_ptr_0 = sq_alloc_ptr;

    // Inst1 的 SQ ID (如果是 store)
    if (is_store_inst1) next_sq_ptr_1 = next_sq_ptr_0 + 3'd1; // 自动回绕
    else next_sq_ptr_1 = next_sq_ptr_0;
end
// 统计本拍 Flush 掉了多少个 Store
// reg [2:0] flushed_store_cnt;
// always @(*) begin
//     flushed_store_cnt = 0;
//     for (i = 0; i < 8; i = i + 1) begin
//         if ((mem_mask[i] & kill_mask) != 0) begin
//             // 它是有效的且是 Store
//             if (mem_inst_valid[i] && mem_subtype[i][3]) begin
//                 flushed_store_cnt = flushed_store_cnt + 1;
//             end
//         end
//     end
// end
// 写指针回滚
// reg [2:0] recovered_wr_ptr;
// reg [2:0] p_idx;
// integer k;
// always @(*) begin
//     // 默认回退到读指针（假设全部被 Kill 或 队列为空）
//     recovered_wr_ptr = mem_rd_ptr;
//     // 逻辑倒序遍历：从 rd_ptr 开始往后找，找到逻辑上最新的一个幸存者
//     // 只有在有效范围内 (count) 才检查
//     for (k = 0; k < 8; k = k + 1) begin
//         p_idx = mem_rd_ptr + k[2:0]; // 计算物理索引（自动回绕）
//         // 如果该指令有效 且 没有被杀死
//         if (mem_inst_valid[p_idx] && ((mem_mask[p_idx] & kill_mask) == 0)) begin
//             // 更新恢复指针为：当前幸存者位置 + 1
//             recovered_wr_ptr = p_idx + 3'd1;
//         end
//     end
// end
// 计算sq指针回滚距离
wire [2:0] rollback_dist = sq_alloc_ptr - restore_sq_ptr_i; // 3位自动回绕
// 时序逻辑
always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 8; i = i + 1) begin
            mem_inst_valid[i] <= 1'b0;
            mem_rob_id[i] <= 6'b0;
            mem_mask[i] <= 4'b0;
            mem_sq_id[i] <= 2'b0;
            mem_subtype[i] <= 4'b0;
            mem_op1_src[i] <= 2'b0;
            mem_op2_src[i] <= 2'b0;
            mem_praddr1[i] <= 6'b0;
            mem_praddr2[i] <= 6'b0;
            mem_pwaddr[i] <= 6'b0;
            mem_imm[i] <= 32'b0;
        end
        mem_wr_ptr <= 3'b0;
        mem_rd_ptr <= 3'b0;
        sq_alloc_ptr <= 3'b0;
        sq_count <= 3'b0;
    end
    else if (int_flag_i) begin
        // 冲刷所有指令
        for (i = 0; i < 8; i = i + 1) begin
            mem_inst_valid[i] <= 1'b0; // 冲刷指令
        end
        // 重置指针和计数
        mem_wr_ptr <= 3'b0;
        mem_rd_ptr <= 3'b0;
        sq_alloc_ptr <= 3'b0;
        sq_count <= 3'b0;
    end
    else if (jump_flag_i) begin
        // 冲刷所有被杀死的指令
        for (i = 0; i < 8; i = i + 1) begin
            if ((mem_mask[i] & kill_mask) != 0) mem_inst_valid[i] <= 1'b0; // 冲刷指令
        end
        // 发射后将指令无效化并更新读指针
        if (mem_issue_flag) begin
            mem_inst_valid[mem_rd_ptr] <= 1'b0;
            mem_rd_ptr <= mem_rd_ptr + 3'd1; // 读指针前移,溢出自动回绕
        end
        // 更新写指针
        if (mem_inst_valid[mem_rd_ptr] && ((mem_mask[mem_rd_ptr] & kill_mask) != 0)) begin
            mem_wr_ptr <= mem_rd_ptr; // 队头是有效指令，且命中 Kill Mask，说明整个队列都是错误路上的，拉回队头开始写
        end
        else if (mem_inst_valid[mem_rd_ptr]) begin
            mem_wr_ptr <= restore_mem_wr_ptr_i; 
        end
        else begin
            mem_wr_ptr <= mem_rd_ptr; 
        end
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                mem_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                mem_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
        // 更新SQ占用计数
        sq_count <= sq_count - rollback_dist - {1'b0, sq_commit_cnt_i};
        // sq_count <= sq_count - flushed_store_cnt - sq_commit_cnt_i;
        // 恢复 SQ 分配指针 (回滚)
        sq_alloc_ptr <= restore_sq_ptr_i;
        // sq_alloc_ptr <= sq_alloc_ptr - flushed_store_cnt[1:0]; // 2-bit 自然回绕
    end
    else begin
        // 发射后将指令无效化并更新读指针
        if (mem_issue_flag) begin
            mem_inst_valid[mem_rd_ptr] <= 1'b0;
            mem_rd_ptr <= mem_rd_ptr + 3'd1; // 读指针前移,溢出自动回绕
        end
        // 更新SQ占用计数
        sq_count <= sq_count + ((~stall_o) ? {1'b0, store_req} : 3'd0) - {1'b0, sq_commit_cnt_i};
        if (~stall_o) begin // 资源足够可以分配
            // 更新SQ分配指针
            sq_alloc_ptr <= next_sq_ptr_1;
            // 更新队列写指针
            mem_wr_ptr <= mem_wr_ptr + mem_req;
            // 写入新指令
            if (mem_need_slot0) begin
                mem_inst_valid[mem_wr_ptr] <= 1'b1;
                mem_rob_id[mem_wr_ptr] <= rob_id_inst0_i;
                mem_mask[mem_wr_ptr] <= branch_mask_inst0_i;
                mem_sq_id[mem_wr_ptr] <= sq_alloc_ptr[1:0]; // store指令分配SQ id，load指令是什么都无所谓
                mem_subtype[mem_wr_ptr] <= inst_subtype_port0_i;
                mem_op1_src[mem_wr_ptr] <= op1_src_port0_i;
                mem_op2_src[mem_wr_ptr] <= op2_src_port0_i;
                mem_praddr1[mem_wr_ptr] <= praddr1_inst0_i;
                mem_praddr2[mem_wr_ptr] <= praddr2_inst0_i;
                mem_pwaddr[mem_wr_ptr] <= pwaddr_inst0_i;
                mem_imm[mem_wr_ptr] <= imm_port0_i;
                if (mem_need_slot1) begin // 指令0和指令1都需要
                    mem_inst_valid[(mem_wr_ptr + 3'd1) & 3'b111] <= 1'b1; // 3位指针溢出自动回绕到0
                    mem_rob_id[(mem_wr_ptr + 3'd1) & 3'b111] <= rob_id_inst1_i;
                    mem_mask[(mem_wr_ptr + 3'd1) & 3'b111] <= branch_mask_inst1_i;
                    mem_sq_id[(mem_wr_ptr + 3'd1) & 3'b111] <= next_sq_ptr_0[1:0];
                    mem_subtype[(mem_wr_ptr + 3'd1) & 3'b111] <= inst_subtype_port1_i;
                    mem_op1_src[(mem_wr_ptr + 3'd1) & 3'b111] <= op1_src_port1_i;
                    mem_op2_src[(mem_wr_ptr + 3'd1) & 3'b111] <= op2_src_port1_i;
                    mem_praddr1[(mem_wr_ptr + 3'd1) & 3'b111] <= praddr1_inst1_i;
                    mem_praddr2[(mem_wr_ptr + 3'd1) & 3'b111] <= praddr2_inst1_i;
                    mem_pwaddr[(mem_wr_ptr + 3'd1) & 3'b111] <= pwaddr_inst1_i;
                    mem_imm[(mem_wr_ptr + 3'd1) & 3'b111] <= imm_port1_i;
                end
            end
            else if (mem_need_slot1) begin // 指令0不需要但指令1需要
                mem_inst_valid[mem_wr_ptr] <= 1'b1;
                mem_rob_id[mem_wr_ptr] <= rob_id_inst1_i;
                mem_mask[mem_wr_ptr] <= branch_mask_inst1_i;
                mem_sq_id[mem_wr_ptr] <= sq_alloc_ptr[1:0];
                mem_subtype[mem_wr_ptr] <= inst_subtype_port1_i;
                mem_op1_src[mem_wr_ptr] <= op1_src_port1_i;
                mem_op2_src[mem_wr_ptr] <= op2_src_port1_i;
                mem_praddr1[mem_wr_ptr] <= praddr1_inst1_i;
                mem_praddr2[mem_wr_ptr] <= praddr2_inst1_i;
                mem_pwaddr[mem_wr_ptr] <= pwaddr_inst1_i;
                mem_imm[mem_wr_ptr] <= imm_port1_i;
            end
        end
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                mem_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                mem_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
end

// 输出寄存器
reg [3:0] mem_mask_new;
always @(*) begin
    mem_mask_new = mem_mask[mem_rd_ptr];
    if (free_mask_inst0_i) begin
        mem_mask_new[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        mem_mask_new[free_id_inst1_i] = 1'b0;
    end
end
iss_mem u_iss_mem(
    .clk(clk),
    .rst(rst),
    // from issue
    .int_flag_i(int_flag_i),                 // 中断标志
    .flush_flag_i(mem_flush_i),               // 冲刷标志
    .mem_stall_i(mem_stall_i),               // 访存暂停标志
    .issue_flag_i(mem_issue_flag),               // 发射标志
    .rob_id_i(mem_rob_id[mem_rd_ptr]),                   // ROB id
    .mask_i(mem_mask_new),               // 分支掩码
    .sq_id_i(mem_sq_id[mem_rd_ptr]),              // SQ id
    .subtype_i(mem_subtype[mem_rd_ptr]),            // 指令子类型
    .op1_src_i(mem_op1_src[mem_rd_ptr]),            // 操作数1来源选择
    .op2_src_i(mem_op2_src[mem_rd_ptr]),            // 操作数2来源选择
    .praddr1_i(mem_praddr1[mem_rd_ptr]),            // 物理寄存器1读地址
    .praddr2_i(mem_praddr2[mem_rd_ptr]),            // 物理寄存器2读地址
    .pwaddr_i(mem_pwaddr[mem_rd_ptr]),             // 物理寄存器写地址
    .imm_i(mem_imm[mem_rd_ptr]),               // 立即数
    // from commit
    .free_mask_inst0_i(free_mask_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_mask_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_id_inst1_i),               // 指令1释放id
    // from branch
    .jump_flag_i(jump_flag_i),                      // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),             // 杀死指令掩码id
    // to ex
    .inst_valid_o(mem_inst_valid_o),          // 指令有效标志
    .rob_id_o(mem_rob_id_o),               // ROB id
    .mask_o(mem_mask_o),          // 分支掩码
    .sq_id_o(mem_sq_id_o),         // SQ id
    .subtype_o(mem_subtype_o),       // 指令子类型
    .op1_src_o(mem_op1_src_o),       // 操作数1
    .op2_src_o(mem_op2_src_o),       // 操作数2
    .praddr1_o(mem_praddr1_o),       // 物理寄存器1读地址
    .praddr2_o(mem_praddr2_o),       // 物理寄存器2读地址
    .pwaddr_o(mem_pwaddr_o),        // 物理寄存器写地址
    .imm_o(mem_imm_o)               // 立即数
);



`ifdef use_m_extension
// M扩展指令
// mul发射队列
reg mul_inst_valid[0:3];       // 指令有效标志
reg [5:0] mul_rob_id[0:3];     // ROB id
reg [3:0] mul_mask[0:3];       // 分支掩码
reg [3:0] mul_subtype[0:3];    // 指令子类型
reg [5:0] mul_praddr1[0:3];    // 物理寄存器1读地址
reg [5:0] mul_praddr2[0:3];    // 物理寄存器2读地址
reg [5:0] mul_pwaddr[0:3];     // 物理寄存器写地址
// 空闲计数
wire [2:0] mul_busy_cnt = mul_inst_valid[0] + mul_inst_valid[1] + mul_inst_valid[2] + mul_inst_valid[3];
wire [2:0] mul_free_cnt = 3'd4 - mul_busy_cnt;
// 分配需求
wire mul_need_slot0 = (inst_valid_port0_i && (inst_type_port0_i == `TYPE_M_EXT && inst_subtype_port0_i < 4'd4)); // 0123属于mul，4567属于div
wire mul_need_slot1 = (inst_valid_port1_i && (inst_type_port1_i == `TYPE_M_EXT && inst_subtype_port1_i < 4'd4));
wire [1:0] mul_req = mul_need_slot0 + mul_need_slot1;
// 暂停信号
wire mul_stall = (mul_req > mul_free_cnt);
// 发射逻辑
reg mul_issue_flag;
reg [1:0] mul_issue_slot;
// 检查操作数是否就绪
reg mul_op1_ready[0:3];
reg mul_op2_ready[0:3];
reg mul_dep_mem[0:3];
always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        // 乘除法只需要寄存器
        mul_op1_ready[i] = ready_flag_i[mul_praddr1[i]] || (mul_praddr1[i] == alu0_rf_pwaddr_i) ||
                        (mul_praddr1[i] == alu1_rf_pwaddr_i) || (mul_praddr1[i] == mem_pwaddr_i);
        mul_op2_ready[i] = ready_flag_i[mul_praddr2[i]] || (mul_praddr2[i] == alu0_rf_pwaddr_i) ||
                       (mul_praddr2[i] == alu1_rf_pwaddr_i) || (mul_praddr2[i] == mem_pwaddr_i);

        mul_dep_mem[i] = ((mul_praddr1[i] == mem_pwaddr_i) || (mul_praddr2[i] == mem_pwaddr_i)) 
                                && (mem_pwaddr_i != 6'b0);
    end
end
// 选择发射指令
reg mul_ns_flag;
reg [1:0] mul_ns_slot;
reg mul_s_flag;
reg [1:0] mul_s_slot;

always @(*) begin
    mul_ns_flag = 1'b0;
    mul_ns_slot = 2'd0;
    mul_s_flag = 1'b0;
    mul_s_slot = 2'd0;
    for (i = 0; i < 4; i = i + 1) begin
        if (mul_inst_valid[i] && mul_op1_ready[i] && mul_op2_ready[i] && ((mul_mask[i] & kill_mask) == 0)) begin // 找到就绪指令
            // 假设没有 stall
            if (!mul_ns_flag) begin
                mul_ns_flag = 1'b1;
                mul_ns_slot = i[1:0];
            end
            
            // 假设有 stall
            if (!mul_dep_mem[i]) begin
                if (!mul_s_flag) begin
                    mul_s_flag = 1'b1;
                    mul_s_slot = i[1:0];
                end
            end
        end
    end
end

always @(*) begin
    if (mem_stall_i) begin
        mul_issue_flag = mul_s_flag;
        mul_issue_slot = mul_s_slot;
    end else begin
        mul_issue_flag = mul_ns_flag;
        mul_issue_slot = mul_ns_slot;
    end
end
// 分配逻辑
// 寻找空位
reg [1:0] mul_free_slot0, mul_free_slot1;
reg mul_found_slot0, mul_found_slot1;
always @(*) begin
    mul_found_slot0 = 1'b0;
    mul_found_slot1 = 1'b0;
    mul_free_slot0 = 2'd0;
    mul_free_slot1 = 2'd0;
    for (i = 0; i < 4; i = i + 1) begin
        if (!mul_inst_valid[i]) begin // 发现空位
            if (!mul_found_slot0) begin
                // 找到第一个空位
                mul_free_slot0 = i[1:0];
                mul_found_slot0 = 1'b1;
            end
            else if (!mul_found_slot1) begin
                // 已经找到第一个了，现在找到第二个
                mul_free_slot1 = i[1:0];
                mul_found_slot1 = 1'b1;
            end
        end
    end
end
// 写入队列
always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 4; i = i + 1) begin
            mul_inst_valid[i] <= 1'b0;
            mul_rob_id[i] <= 6'b0;
            mul_mask[i] <= 4'b0;
            mul_subtype[i] <= 4'b0;
            mul_praddr1[i] <= 6'b0;
            mul_praddr2[i] <= 6'b0;
            mul_pwaddr[i] <= 6'b0;
        end
    end
    else if (int_flag_i) begin
        // 冲刷所有指令
        for (i = 0; i < 4; i = i + 1) begin
            mul_inst_valid[i] <= 1'b0; // 冲刷指令
        end
    end
    else if (jump_flag_i) begin
        // 冲刷所有被杀死的指令
        for (i = 0; i < 4; i = i + 1) begin
            if ((mul_mask[i] & kill_mask) != 0) begin
                mul_inst_valid[i] <= 1'b0; // 冲刷指令
            end
        end
        // 发射后将指令无效化
        if (mul_issue_flag) mul_inst_valid[mul_issue_slot] <= 1'b0;
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                mul_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                mul_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
    else begin
        // 发射后将指令无效化
        if (mul_issue_flag) mul_inst_valid[mul_issue_slot] <= 1'b0;
        // 写入新指令
        if (~stall_o) begin
            // 分配指令0
            if (mul_need_slot0) begin
                mul_inst_valid[mul_free_slot0] <= 1'b1;
                mul_rob_id[mul_free_slot0] <= rob_id_inst0_i;
                mul_mask[mul_free_slot0] <= branch_mask_inst0_i;
                mul_subtype[mul_free_slot0] <= inst_subtype_port0_i;
                mul_praddr1[mul_free_slot0] <= praddr1_inst0_i;
                mul_praddr2[mul_free_slot0] <= praddr2_inst0_i;
                mul_pwaddr[mul_free_slot0] <= pwaddr_inst0_i;
                // 分配指令1
                if (mul_need_slot1) begin
                    mul_inst_valid[mul_free_slot1] <= 1'b1;
                    mul_rob_id[mul_free_slot1] <= rob_id_inst1_i;
                    mul_mask[mul_free_slot1] <= branch_mask_inst1_i;
                    mul_subtype[mul_free_slot1] <= inst_subtype_port1_i;
                    mul_praddr1[mul_free_slot1] <= praddr1_inst1_i;
                    mul_praddr2[mul_free_slot1] <= praddr2_inst1_i;
                    mul_pwaddr[mul_free_slot1] <= pwaddr_inst1_i;
                end
            end
            else if (mul_need_slot1) begin // 指令0不需要但指令1需要
                mul_inst_valid[mul_free_slot0] <= 1'b1;
                mul_rob_id[mul_free_slot0] <= rob_id_inst1_i;
                mul_mask[mul_free_slot0] <= branch_mask_inst1_i;
                mul_subtype[mul_free_slot0] <= inst_subtype_port1_i;
                mul_praddr1[mul_free_slot0] <= praddr1_inst1_i;
                mul_praddr2[mul_free_slot0] <= praddr2_inst1_i;
                mul_pwaddr[mul_free_slot0] <= pwaddr_inst1_i;
            end
        end
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                mul_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                mul_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
end

// 输出寄存器
reg [3:0] mul_mask_new;
always @(*) begin
    mul_mask_new = mul_mask[mul_issue_slot];
    if (free_mask_inst0_i) begin
        mul_mask_new[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        mul_mask_new[free_id_inst1_i] = 1'b0;
    end
end
iss_mul u_iss_mul(
    .clk(clk),
    .rst(rst),
    // from issue
    .int_flag_i(int_flag_i),                 // 中断标志
    .issue_flag_i(mul_issue_flag),               // 发射标志
    .rob_id_i(mul_rob_id[mul_issue_slot]),                   // ROB id
    .mask_i(mul_mask_new),               // 分支掩码
    .subtype_i(mul_subtype[mul_issue_slot]),            // 指令子类型
    .praddr1_i(mul_praddr1[mul_issue_slot]),            // 物理寄存器1读地址
    .praddr2_i(mul_praddr2[mul_issue_slot]),            // 物理寄存器2读地址
    .pwaddr_i(mul_pwaddr[mul_issue_slot]),             // 物理寄存器写地址
    // to ex
    .inst_valid_o(mul_inst_valid_o),          // 指令有效标志
    .rob_id_o(mul_rob_id_o),               // ROB id
    .mask_o(mul_mask_o),          // 分支掩码
    .subtype_o(mul_subtype_o),       // 指令子类型
    .praddr1_o(mul_praddr1_o),       // 物理寄存器1读地址
    .praddr2_o(mul_praddr2_o),       // 物理寄存器2读地址
    .pwaddr_o(mul_pwaddr_o)         // 物理寄存器写地址
);




// div发射队列
reg div_inst_valid[0:3];       // 指令有效标志
reg [5:0] div_rob_id[0:3];     // ROB id
reg [3:0] div_mask[0:3];       // 分支掩码
reg [3:0] div_subtype[0:3];    // 指令子类型
reg [5:0] div_praddr1[0:3];    // 物理寄存器1读地址
reg [5:0] div_praddr2[0:3];    // 物理寄存器2读地址
reg [5:0] div_pwaddr[0:3];     // 物理寄存器写地址
// 空闲计数
wire [2:0] div_busy_cnt = div_inst_valid[0] + div_inst_valid[1] + div_inst_valid[2] + div_inst_valid[3];
wire [2:0] div_free_cnt = 3'd4 - div_busy_cnt;
// 分配需求
wire div_need_slot0 = (inst_valid_port0_i && (inst_type_port0_i == `TYPE_M_EXT && inst_subtype_port0_i >= 4'd4)); // 0123属于mul，4567属于div
wire div_need_slot1 = (inst_valid_port1_i && (inst_type_port1_i == `TYPE_M_EXT && inst_subtype_port1_i >= 4'd4));
wire [1:0] div_req = div_need_slot0 + div_need_slot1;
// 暂停信号
wire div_stall = (div_req > div_free_cnt);
// 发射逻辑
reg div_issue_flag;
reg [1:0] div_issue_slot;
// 检查操作数是否就绪
reg div_op1_ready[0:3];
reg div_op2_ready[0:3];
reg div_dep_mem[0:3];
always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        // 乘除法只需要寄存器
        div_op1_ready[i] = ready_flag_i[div_praddr1[i]] || (div_praddr1[i] == alu0_rf_pwaddr_i) ||
                       (div_praddr1[i] == alu1_rf_pwaddr_i) || (div_praddr1[i] == mem_pwaddr_i);
        div_op2_ready[i] = ready_flag_i[div_praddr2[i]] || (div_praddr2[i] == alu0_rf_pwaddr_i) ||
                       (div_praddr2[i] == alu1_rf_pwaddr_i) || (div_praddr2[i] == mem_pwaddr_i);

        div_dep_mem[i] = ((div_praddr1[i] == mem_pwaddr_i) || (div_praddr2[i] == mem_pwaddr_i)) 
                                && (mem_pwaddr_i != 6'b0);
    end
end
// 选择发射指令
reg div_ns_flag;
reg [1:0] div_ns_slot;
reg div_s_flag;
reg [1:0] div_s_slot;

always @(*) begin
    div_ns_flag = 1'b0;
    div_ns_slot = 2'd0;
    div_s_flag = 1'b0;
    div_s_slot = 2'd0;
    for (i = 0; i < 4; i = i + 1) begin
        if (div_inst_valid[i] && div_op1_ready[i] && div_op2_ready[i] && ((div_mask[i] & kill_mask) == 0) && !div_stall_i) begin // div自身有一个状态机暂停标志div_stall_i
            // 假设没有 stall
            if (!div_ns_flag) begin
                div_ns_flag = 1'b1;
                div_ns_slot = i[1:0];
            end
            
            // 假设有 stall
            if (!div_dep_mem[i]) begin
                if (!div_s_flag) begin
                    div_s_flag = 1'b1;
                    div_s_slot = i[1:0];
                end
            end
        end
    end
end

always @(*) begin
    if (mem_stall_i) begin
        div_issue_flag = div_s_flag;
        div_issue_slot = div_s_slot;
    end else begin
        div_issue_flag = div_ns_flag;
        div_issue_slot = div_ns_slot;
    end
end
// 分配逻辑
// 寻找空位
reg [1:0] div_free_slot0, div_free_slot1;
reg div_found_slot0, div_found_slot1;
always @(*) begin
    div_found_slot0 = 1'b0;
    div_found_slot1 = 1'b0;
    div_free_slot0 = 2'd0;
    div_free_slot1 = 2'd0;
    for (i = 0; i < 4; i = i + 1) begin
        if (!div_inst_valid[i]) begin // 发现空位
            if (!div_found_slot0) begin
                // 找到第一个空位
                div_free_slot0 = i[1:0];
                div_found_slot0 = 1'b1;
            end
            else if (!div_found_slot1) begin
                // 已经找到第一个了，现在找到第二个
                div_free_slot1 = i[1:0];
                div_found_slot1 = 1'b1;
            end
        end
    end
end
// 写入队列
always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 4; i = i + 1) begin
            div_inst_valid[i] <= 1'b0;
            div_rob_id[i] <= 6'b0;
            div_mask[i] <= 4'b0;
            div_subtype[i] <= 4'b0;
            div_praddr1[i] <= 6'b0;
            div_praddr2[i] <= 6'b0;
            div_pwaddr[i] <= 6'b0;
        end
    end
    else if (int_flag_i) begin
        // 冲刷所有指令
        for (i = 0; i < 4; i = i + 1) begin
            div_inst_valid[i] <= 1'b0; // 冲刷指令
        end
    end
    else if (jump_flag_i) begin
        // 冲刷所有被杀死的指令
        for (i = 0; i < 4; i = i + 1) begin
            if ((div_mask[i] & kill_mask) != 0) begin
                div_inst_valid[i] <= 1'b0; // 冲刷指令
            end
        end
        // 发射后将指令无效化
        if (div_issue_flag) div_inst_valid[div_issue_slot] <= 1'b0;
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                div_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                div_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
    else begin
        // 发射后将指令无效化
        if (div_issue_flag) div_inst_valid[div_issue_slot] <= 1'b0;
        // 写入新指令
        if (~stall_o) begin
            // 分配指令0
            if (div_need_slot0) begin
                div_inst_valid[div_free_slot0] <= 1'b1;
                div_rob_id[div_free_slot0] <= rob_id_inst0_i;
                div_mask[div_free_slot0] <= branch_mask_inst0_i;
                div_subtype[div_free_slot0] <= inst_subtype_port0_i;
                div_praddr1[div_free_slot0] <= praddr1_inst0_i;
                div_praddr2[div_free_slot0] <= praddr2_inst0_i;
                div_pwaddr[div_free_slot0] <= pwaddr_inst0_i;
                // 分配指令1
                if (div_need_slot1) begin
                    div_inst_valid[div_free_slot1] <= 1'b1;
                    div_rob_id[div_free_slot1] <= rob_id_inst1_i;
                    div_mask[div_free_slot1] <= branch_mask_inst1_i;
                    div_subtype[div_free_slot1] <= inst_subtype_port1_i;
                    div_praddr1[div_free_slot1] <= praddr1_inst1_i;
                    div_praddr2[div_free_slot1] <= praddr2_inst1_i;
                    div_pwaddr[div_free_slot1] <= pwaddr_inst1_i;
                end
            end
            else if (div_need_slot1) begin // 指令0不需要但指令1需要
                div_inst_valid[div_free_slot0] <= 1'b1;
                div_rob_id[div_free_slot0] <= rob_id_inst1_i;
                div_mask[div_free_slot0] <= branch_mask_inst1_i;
                div_subtype[div_free_slot0] <= inst_subtype_port1_i;
                div_praddr1[div_free_slot0] <= praddr1_inst1_i;
                div_praddr2[div_free_slot0] <= praddr2_inst1_i;
                div_pwaddr[div_free_slot0] <= pwaddr_inst1_i;
            end
        end
        // 提交释放掩码
        if (free_mask_inst0_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                div_mask[i][free_id_inst0_i] <= 1'b0; // 清除对应位
            end
        end
        if (free_mask_inst1_i) begin
            for (i = 0; i < 4; i = i + 1) begin
                div_mask[i][free_id_inst1_i] <= 1'b0; // 清除对应位
            end
        end
    end
end

// 输出寄存器
reg [3:0] div_mask_new;
always @(*) begin
    div_mask_new = div_mask[div_issue_slot];
    if (free_mask_inst0_i) begin
        div_mask_new[free_id_inst0_i] = 1'b0;
    end
    if (free_mask_inst1_i) begin
        div_mask_new[free_id_inst1_i] = 1'b0;
    end
end
iss_div u_iss_div(
    .clk(clk),
    .rst(rst),
    // from issue
    .int_flag_i(int_flag_i),                 // 中断标志
    .div_flush_i(div_flush_i),                    // div冲刷标志
    .div_stall_i(div_stall_i),               // div暂停标志
    .issue_flag_i(div_issue_flag),               // 发射标志
    .rob_id_i(div_rob_id[div_issue_slot]),                   // ROB id
    .mask_i(div_mask_new),               // 分支掩码
    .subtype_i(div_subtype[div_issue_slot]),            // 指令子类型
    .praddr1_i(div_praddr1[div_issue_slot]),            // 物理寄存器1读地址
    .praddr2_i(div_praddr2[div_issue_slot]),            // 物理寄存器2读地址
    .pwaddr_i(div_pwaddr[div_issue_slot]),             // 物理寄存器写地址
    // from commit
    .free_mask_inst0_i(free_mask_inst0_i),                   // 指令0释放掩码标志
    .free_id_inst0_i(free_id_inst0_i),               // 指令0释放id
    .free_mask_inst1_i(free_mask_inst1_i),                   // 指令1释放掩码标志
    .free_id_inst1_i(free_id_inst1_i),               // 指令1释放id
    // from branch
    .jump_flag_i(jump_flag_i),                      // 跳转标志
    .kill_mask_id_i(kill_mask_id_i),             // 杀死指令掩码id
    // to ex
    .inst_valid_o(div_inst_valid_o),          // 指令有效标志
    .rob_id_o(div_rob_id_o),               // ROB id
    .mask_o(div_mask_o),          // 分支掩码
    .subtype_o(div_subtype_o),       // 指令子类型
    .praddr1_o(div_praddr1_o),       // 物理寄存器1读地址
    .praddr2_o(div_praddr2_o),       // 物理寄存器2读地址
    .pwaddr_o(div_pwaddr_o)         // 物理寄存器写地址
);
`endif

// 总暂停信号
assign stall_rob_o = alu_stall || branch_stall || mem_stall
                    `ifdef use_m_extension
                     || mul_stall || div_stall
                    `endif
                    ;
assign stall_o = rob_stall_i || alu_stall || branch_stall || mem_stall
                `ifdef use_m_extension
                 || mul_stall || div_stall
                `endif
                ;

endmodule