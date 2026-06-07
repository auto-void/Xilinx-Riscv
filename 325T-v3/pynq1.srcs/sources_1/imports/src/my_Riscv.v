`include "defines.vh"

`timescale 1ns / 1ps

// cpu顶层模块
module my_Riscv(
    input clk,
    input rst_p,

    // IROM接口
    output [31:0] irom_addr,
    // input [63:0] irom_data,
    input [255:0] cache_line,
    
    // 外设接口
    output [31:0] perip_waddr,
    output [31:0] perip_addr,
    output perip_wen,
    output [1:0] perip_mask,
    output [31:0] perip_wdata,
    input [127:0] dcache_line,
    input [31:0] perip_rdata,
    input timer_int_flag,
    input uart_int_flag

    `ifdef DEBUG
    ,output [31:0] ex_branch_hit_cnt,
    output [31:0] ex_branch_miss_cnt
    `endif

);

// 外部复位高有效，内部cpu低有效，异步复位，时钟下降沿同步释放
reg rst;
always @(negedge clk or posedge rst_p) begin
    if (rst_p) begin
        rst <= 1'b0;
    end
    else begin
        rst <= 1'b1;
    end
end


// IFU模块输出信号
wire [31:0] pc_o;
assign irom_addr = pc_o;
wire ifu_ras_pop_flag_o;
wire ifu_ras_push_flag_o;
wire [31:0] ifu_ras_push_data_o;
wire [2:0] if_id_ras_snap_ptr_o;
wire if_id_inst_valid_port0_o;
wire if_id_inst_valid_port1_o;
wire [31:0] if_id_inst_port0_o;
wire [31:0] if_id_inst_port1_o;
wire [31:0] if_id_inst_addr_o;
wire [31:0] if_id_imm_port0_o;
wire [31:0] if_id_imm_port1_o;
wire if_id_bpu_pre_flag_port0_o;
wire if_id_bpu_pre_flag_port1_o;
wire [31:0] if_id_bpu_pre_addr_port0_o;
wire [31:0] if_id_bpu_pre_addr_port1_o;

// BPU模块输出信号
wire [2:0] bpu_ras_snap_ptr;             // 传到取指阶段2的快照栈指针
wire [31:0] bpu_ras_data_out;            // 传到取指阶段2的弹栈数据
wire bpu_odd_inst_jump;            // 跳转的是否是奇数指令（1为奇数，0为偶数，不跳默认为1）
wire bpu_jump_flag_o;                 // 跳转使能
wire [31:0] bpu_jump_addr_o;           // 跳转地址

// IDU模块输出信号
wire idu_jal_flush_o;                   // jal指令跳转冲刷
wire [31:0] idu_jal_addr_o;             // jal指令的跳转地址
wire rn_alloc_flag_inst0_o;             // Inst0是否分配物理寄存器
wire rn_alloc_flag_inst1_o;             // Inst1是否分配物理寄存器
wire [5:0] rn_pwaddr_inst0_o;           // 指令0物理寄存器写地址
wire [5:0] rn_pwaddr_inst1_o;           // 指令1物理寄存器写地址
wire rn_stall_o;                        // 重命名和RS/ROB暂停信号
wire [2:0] rn_dp_ras_snap_ptr_o;            // RAS快照指针
wire [31:0] rn_dp_inst_addr_o;              // 指令地址
wire [2:0] rn_dp_inst_type_port0_o;         // 指令类型
wire [2:0] rn_dp_inst_type_port1_o;         // 指令类型
wire [3:0] rn_dp_inst_subtype_port0_o;      // 指令子类型
wire [3:0] rn_dp_inst_subtype_port1_o;      // 指令子类型
wire [1:0] rn_dp_op1_src_port0_o;           // 操作数1来源选择
wire [1:0] rn_dp_op1_src_port1_o;           // 操作数1来源选择
wire [1:0] rn_dp_op2_src_port0_o;           // 操作数2来源选择
wire [1:0] rn_dp_op2_src_port1_o;           // 操作数2来源选择
wire [11:0] rn_dp_csr_addr_port0_o;         // CSR寄存器地址
wire [11:0] rn_dp_csr_addr_port1_o;         // CSR寄存器地址
wire rn_dp_csr_wflag_port0_o;               // CSR寄存器写使能
wire rn_dp_csr_wflag_port1_o;               // CSR寄存器写使能
wire rn_dp_reg_wflag_port0_o;               // 通用寄存器写使能
wire rn_dp_reg_wflag_port1_o;               // 通用寄存器写使能
wire [4:0] rn_dp_reg_waddr_port0_o;         // 写通用寄存器地址
wire [4:0] rn_dp_reg_waddr_port1_o;         // 写通用寄存器地址
wire rn_dp_inst_valid_port0_o;              // 指令有效标志
wire rn_dp_inst_valid_port1_o;              // 指令有效标志
wire [31:0] rn_dp_imm_port0_o;              // 立即数
wire [31:0] rn_dp_imm_port1_o;              // 立即数
wire [31:0] rn_dp_aux_addr_port0_o;         // Auxiliary Address（辅助地址）
wire [31:0] rn_dp_aux_addr_port1_o;         // Auxiliary Address（辅助地址）
wire rn_dp_bpu_pre_flag_port0_o;            // 预测标志
wire rn_dp_bpu_pre_flag_port1_o;            // 预测标志
wire [31:0] rn_dp_bpu_pre_addr_port0_o;     // 预测地址
wire [31:0] rn_dp_bpu_pre_addr_port1_o;     // 预测地址
wire [5:0] rn_dp_praddr1_inst0_o;           // 指令0物理寄存器1读地址
wire [5:0] rn_dp_praddr2_inst0_o;           // 指令0物理寄存器2读地址
wire [5:0] rn_dp_praddr1_inst1_o;           // 指令1物理寄存器1读地址
wire [5:0] rn_dp_praddr2_inst1_o;           // 指令1物理寄存器2读地址
wire [5:0] rn_dp_pwaddr_inst0_o;            // 指令0物理寄存器写地址
wire [5:0] rn_dp_pwaddr_inst1_o;            // 指令1物理寄存器写地址
wire [3:0] rn_dp_branch_mask_inst0_o;       // 指令0分支掩码
wire [3:0] rn_dp_branch_mask_inst1_o;       // 指令1分支掩码
wire [5:0] rn_dp_old_paddr_inst0_o;         // 指令0旧物理寄存器地址
wire [5:0] rn_dp_old_paddr_inst1_o;         // 指令1旧物理寄存器地址
wire [1:0] rn_dp_snap_id_inst0_o;           // 指令0快照id
wire [1:0] rn_dp_snap_id_inst1_o;           // 指令1快照id

// regs模块输出信号
wire [31:0] regs_csr_rdata_o;           // CSR指令读RS1数据
wire [63:0] regs_ready_flag_o;          // 寄存器就绪标志，位0-63分别对应物理寄存器0-63
wire [31:0] regs_alu_inst0_rdata1_o;    // 读寄存器1数据
wire [31:0] regs_alu_inst0_rdata2_o;    // 读寄存器2数据
wire [31:0] regs_alu_inst1_rdata1_o;    // 读寄存器1数据
wire [31:0] regs_alu_inst1_rdata2_o;    // 读寄存器2数据
wire [31:0] regs_branch_rdata1_o;       // 读寄存器1数据
wire [31:0] regs_branch_rdata2_o;       // 读寄存器2数据
wire [31:0] regs_mem_rdata1_o;          // 读寄存器1数据
wire [31:0] regs_mem_rdata2_o;          // 读寄存器2数据
`ifdef use_m_extension
wire [31:0] regs_mul_rdata1_o;          // 读寄存器1数据
wire [31:0] regs_mul_rdata2_o;          // 读寄存器2数据
wire [31:0] regs_div_rdata1_o;          // 读寄存器1数据
wire [31:0] regs_div_rdata2_o;          // 读寄存器2数据
`endif

// Issue模块输出信号
wire iss_alu_inst_valid_inst0_o;       // ALU0指令有效标志
wire [5:0] iss_alu_rob_id_inst0_o;     // ALU0 ROB id
wire [3:0] iss_alu_mask_inst0_o;       // ALU0分支掩码
wire [3:0] iss_alu_subtype_inst0_o;    // ALU0指令子类型
wire [1:0] iss_alu_op1_src_inst0_o;    // ALU0操作数1
wire [1:0] iss_alu_op2_src_inst0_o;    // ALU0操作数2
wire [5:0] iss_alu_praddr1_inst0_o;    // ALU0物理寄存器1读地址
wire [5:0] iss_alu_praddr2_inst0_o;    // ALU0物理寄存器2读地址
wire [5:0] iss_alu_pwaddr_inst0_o;     // ALU0物理寄存器写地址
wire [31:0] iss_alu_imm_inst0_o;       // ALU0立即数
wire iss_alu_inst_valid_inst1_o;       // ALU1指令有效标志
wire [5:0] iss_alu_rob_id_inst1_o;     // ALU1 ROB id
wire [3:0] iss_alu_mask_inst1_o;       // ALU1分支掩码
wire [3:0] iss_alu_subtype_inst1_o;    // ALU1指令子类型
wire [1:0] iss_alu_op1_src_inst1_o;    // ALU1操作数1
wire [1:0] iss_alu_op2_src_inst1_o;    // ALU1操作数2
wire [5:0] iss_alu_praddr1_inst1_o;    // ALU1物理寄存器1读地址
wire [5:0] iss_alu_praddr2_inst1_o;    // ALU1物理寄存器2读地址
wire [5:0] iss_alu_pwaddr_inst1_o;     // ALU1物理寄存器写地址
wire [31:0] iss_alu_imm_inst1_o;       // ALU1立即数
wire iss_br_inst_valid_o;              // branch指令有效标志
wire [15:0] iss_br_inst_addr_o;        // branch指令地址
wire [5:0] iss_br_rob_id_o;            // branch ROB id
wire iss_br_bpu_pre_flag_o;            // branch BPU预测标志
wire [31:0] iss_br_bpu_pre_addr_o;     // branch BPU预测地址
wire [3:0] iss_br_mask_o;              // branch分支掩码
wire [2:0] iss_br_ras_ptr_o;           // branch RAS快照指针
wire [2:0] iss_br_mem_wr_ptr_o;        // branch mem队列写操作快照指针
wire [2:0] iss_br_sq_ptr_o;            // branch store queue快照指针
wire [1:0] iss_br_snap_id_o;           // branch快照id
wire [2:0] iss_br_type_o;              // branch指令类型
wire [3:0] iss_br_subtype_o;           // branch指令子类型
wire [1:0] iss_br_op1_src_o;           // branch操作数1
wire [1:0] iss_br_op2_src_o;           // branch操作数2
wire [5:0] iss_br_praddr1_o;           // branch物理寄存器1读地址
wire [5:0] iss_br_praddr2_o;           // branch物理寄存器2读地址
wire [5:0] iss_br_pwaddr_o;            // branch物理寄存器写地址
wire [31:0] iss_br_imm_o;              // branch立即数
wire [31:0] iss_br_aux_addr_o;         // branch辅助地址
wire iss_mem_inst_valid_o;             // mem指令有效标志
wire [5:0] iss_mem_rob_id_o;           // mem ROB id
wire [3:0] iss_mem_mask_o;             // mem分支掩码
wire [1:0] iss_mem_sq_id_o;            // mem SQ id
wire [3:0] iss_mem_subtype_o;          // mem指令子类型
wire [1:0] iss_mem_op1_src_o;          // mem操作数1
wire [1:0] iss_mem_op2_src_o;          // mem操作数2
wire [5:0] iss_mem_praddr1_o;          // mem物理寄存器1读地址
wire [5:0] iss_mem_praddr2_o;          // mem物理寄存器2读地址
wire [5:0] iss_mem_pwaddr_o;           // mem物理寄存器写地址
wire [31:0] iss_mem_imm_o;             // mem立即数
`ifdef use_m_extension
wire iss_mul_inst_valid_o;             // mul指令有效标志
wire [5:0] iss_mul_rob_id_o;           // mul ROB id
wire [3:0] iss_mul_mask_o;             // mul分支掩码
wire [3:0] iss_mul_subtype_o;          // mul指令子类型
wire [5:0] iss_mul_praddr1_o;          // mul物理寄存器1读地址
wire [5:0] iss_mul_praddr2_o;          // mul物理寄存器2读地址
wire [5:0] iss_mul_pwaddr_o;           // mul物理寄存器写地址
wire iss_div_inst_valid_o;             // div指令有效标志
wire [5:0] iss_div_rob_id_o;           // div ROB id
wire [3:0] iss_div_mask_o;             // div分支掩码
wire [3:0] iss_div_subtype_o;          // div指令子类型
wire [5:0] iss_div_praddr1_o;          // div物理寄存器1读地址
wire [5:0] iss_div_praddr2_o;          // div物理寄存器2读地址
wire [5:0] iss_div_pwaddr_o;           // div物理寄存器写地址
`endif
wire iss_stall_rob_o;
wire iss_stall_o;

// ALU_0模块输出信号
wire [5:0] alu0_rf_waddr_o;            // RF 阶段写寄存器地址
wire [5:0] alu0_rf_raddr1_o;           // RF 阶段读寄存器1地址（同时传到转发模块）
wire [5:0] alu0_rf_raddr2_o;           // RF 阶段读寄存器2地址（同时传到转发模块）
wire alu0_reg_wflag_o;                 // 写回阶段写寄存器标志
wire [5:0] alu0_reg_waddr_o;           // 写回阶段写寄存器地址
wire [31:0] alu0_reg_wdata_o;          // 写回阶段写寄存器数据
wire alu0_rf_wflag_o;                  // RF 阶段写寄存器标志
wire [5:0] alu0_exe_waddr_o;           // 执行阶段写寄存器地址
wire [31:0] alu0_exe_wdata_o;          // 执行阶段写寄存器数据
wire alu0_complete_flag_o;             // 指令完成标志
wire [5:0] alu0_commit_rob_id_o;       // 提交ROB id

// ALU_1模块输出信号
wire [5:0] alu1_rf_waddr_o;            // RF 阶段写寄存器地址
wire [5:0] alu1_rf_raddr1_o;           // RF 阶段读寄存器1地址（同时传到转发模块）
wire [5:0] alu1_rf_raddr2_o;           // RF 阶段读寄存器2地址（同时传到转发模块）
wire alu1_reg_wflag_o;                 // 写回阶段写寄存器标志
wire [5:0] alu1_reg_waddr_o;           // 写回阶段写寄存器地址
wire [31:0] alu1_reg_wdata_o;          // 写回阶段写寄存器数据
wire alu1_rf_wflag_o;                  // RF 阶段写寄存器标志
wire [5:0] alu1_exe_waddr_o;           // 执行阶段写寄存器地址
wire [31:0] alu1_exe_wdata_o;          // 执行阶段写寄存器数据
wire alu1_complete_flag_o;             // 指令完成标志
wire [5:0] alu1_commit_rob_id_o;       // 提交ROB id

// Branch模块输出信号
wire br_jump_flag_o;                 // 跳转标志
wire [1:0] br_kill_mask_id_o;        // 分支掩码id
wire [2:0] br_ras_snap_ptr_o;        // RAS快照指针
wire [2:0] br_mem_wr_ptr_o;          // branch mem队列写操作快照指针
wire [2:0] br_sq_ptr_o;              // branch store queue快照指针
wire [31:0] br_jump_addr_o;          // 跳转地址(同时传到bpu_update_buffer)
wire br_btb_update_en;               // 执行阶段更新BTB使能
wire [15:0] br_ex_pc;                // 执行阶段的pc
wire [31:0] br_ex_jump_addr_o;       // 跳转地址
wire br_is_branch;                   // 是否为分支指令
wire br_lhp_update_en;               // 更新使能
wire br_branch_taken;                // 实际跳转结果(1为跳转)
wire [5:0] br_rf_raddr1_o;           // RF 阶段读寄存器1地址（同时传到转发模块）
wire [5:0] br_rf_raddr2_o;           // RF 阶段读寄存器2地址（同时传到转发模块）
wire br_rf_wflag_o;                  // RF 阶段写寄存器标志
wire [5:0] br_rf_waddr_o;            // RF 阶段写寄存器地址(同时传到issue阶段)
wire br_reg_wflag_o;                 // 写回阶段写寄存器标志
wire [5:0] br_reg_waddr_o;           // 写回阶段写寄存器地址
wire [31:0] br_reg_wdata_o;          // 写回阶段写寄存器数据
wire br_complete_flag_o;             // 指令完成标志
wire [5:0] br_commit_rob_id_o;       // 提交ROB id

// bpu_update_buffer模块输出信号
wire [31:0] buf_jump_addr_o;
wire buf_btb_update_en_o;
wire [15:0] buf_ex_pc_o;
wire buf_is_branch_o;
wire buf_lhp_update_en_o;
wire buf_branch_taken_o;

// LSU模块输出信号
wire lsu_stall_store;                 // store指令暂停标志
wire [5:0] lsu_rf_raddr1_o;           // RF 阶段读寄存器1地址（同时传到转发模块）
wire [5:0] lsu_rf_raddr2_o;           // RF 阶段读寄存器2地址（同时传到转发模块）
wire lsu_reg_wflag_o;                 // 写回阶段写寄存器标志
wire [5:0] lsu_reg_waddr_o;           // 写回阶段写寄存器地址
wire [31:0] lsu_reg_wdata_o;          // 写回阶段写寄存器数据
wire lsu_mem_reg_wflag_o;             // Mem阶段写寄存器标志
wire lsu_flush_o;                     // 冲刷标志
wire lsu_stall_o;                     // stall标志
wire [5:0] lsu_mem_reg_waddr_o;           // Mem阶段写寄存器地址(同时传到regs)
wire [31:0] lsu_mem_reg_wdata_o;          // Mem阶段写寄存器数据
wire store_complete_flag_o;             // store指令完成标志
wire [5:0] store_commit_rob_id_o;       // store提交ROB id
wire load_complete_flag_o;              // load指令完成标志
wire [5:0] load_commit_rob_id_o;       // load提交ROB id

`ifdef use_m_extension
// MUL模块输出信号
wire [5:0] mul_rf_raddr1_o;           // RF 阶段读寄存器1地址（同时传到转发模块）
wire [5:0] mul_rf_raddr2_o;           // RF 阶段读寄存器2地址（同时传到转发模块）
wire mul_reg_wflag_o;                 // 写回阶段写寄存器标志
wire [5:0] mul_reg_waddr_o;           // 写回阶段写寄存器地址
wire [31:0] mul_reg_wdata_o;          // 写回阶段写寄存器数据
wire mul_ex_wflag_o;                  // 执行阶段写寄存器标志
wire [5:0] mul_ex_waddr_o;            // 执行阶段写寄存器地址
wire mul_complete_flag_o;             // 指令完成标志
wire [5:0] mul_commit_rob_id_o;       // 提交ROB id
// DIV模块输出信号
wire div_flush_o;
wire div_stall_o;
wire [5:0] div_rf_raddr1_o;           // RF 阶段读寄存器1地址（同时传到转发模块）
wire [5:0] div_rf_raddr2_o;           // RF 阶段读寄存器2地址（同时传到转发模块）
wire div_reg_wflag_o;                 // 写回阶段写寄存器标志
wire [5:0] div_reg_waddr_o;           // 写回阶段写寄存器地址
wire [31:0] div_reg_wdata_o;          // 写回阶段写寄存器数据
wire div_ex_wflag_o;                  // 执行阶段写寄存器标志
wire [5:0] div_ex_waddr_o;            // 执行阶段写寄存器地址(同时传到wb)
wire div_complete_flag_o;             // 指令完成标志
wire [5:0] div_commit_rob_id_o;       // 提交ROB id
`endif

// ROB模块输出信号
wire rob_int_ready_flag_o;                   // 中断准备好标志
wire [31:0] rob_mret_inst_addr_o;            // mret指令的返回地址（mepc寄存器的值）
wire rob_exception_flag_o;               // 异常发生标志
wire [31:0] rob_exception_cause_o;       // 异常编号
wire rob_mret_flag_o;                    // 中断返回标志
wire rob_stall_o;
wire [1:0] rob_sq_commit_cnt_o;             // store queue提交数量
wire [5:0] rob_id_inst0_o;              // 指令0 ROB id
wire [5:0] rob_id_inst1_o;              // 指令1 ROB id
wire rob_commit_store_flag_o;             // 提交store指令标志
wire rob_dcache_wen;
wire rob_csr_reg_wflag_o;
wire [11:0] rob_csr_reg_addr_o;
wire [31:0] rob_csr_reg_wdata_o;
wire [5:0] rob_reg_raddr_o;                 // CSR指令在提交阶段才读取执行结果，所以CSR寄存器的读地址由commit阶段提供
wire rob_reg_wflag_o;                   // CSR指令写回阶段写寄存器标志
wire [5:0] rob_reg_waddr_o;                 // CSR指令写回阶段写寄存器地址
wire [31:0] rob_reg_wdata_o;            // CSR指令写回阶段写寄存器数据
wire rob_free_snap_flag_inst0_o;         // 指令0释放快照标志
wire rob_free_snap_flag_inst1_o;         // 指令1释放快照标志
wire [1:0] rob_free_snap_id_inst0_o;         // 指令0释放快照id
wire [1:0] rob_free_snap_id_inst1_o;         // 指令1释放快照id
wire rob_commit_inst0_o;                 // 指令0提交使能
wire [4:0] rob_waddr_commit0_o;              // 提交指令的目标逻辑寄存器
wire [5:0] rob_paddr_commit0_o;              // 提交指令的目标物理寄存器(成为架构状态)
wire [5:0] rob_free_paddr_inst0_o;           // 释放的物理寄存器地址
wire rob_commit_inst1_o;                 // 指令1提交使能
wire [4:0] rob_waddr_commit1_o;              // 提交指令的目标逻辑寄存器
wire [5:0] rob_paddr_commit1_o;              // 提交指令的目标物理寄存器(成为架构状态)
wire [5:0] rob_free_paddr_inst1_o;           // 释放的物理寄存器地址

// Forward_unit模块输出信号
wire alu0_rs1_forward_flag_o;           // ALU_0 rs1转发标志
wire [31:0] alu0_rs1_forward_data_o;    // ALU_0 rs1转发数据
wire alu0_rs2_forward_flag_o;           // ALU_0 rs2转发标志
wire [31:0] alu0_rs2_forward_data_o;    // ALU_0 rs2转发数据
wire alu1_rs1_forward_flag_o;           // ALU_1 rs1转发标志
wire [31:0] alu1_rs1_forward_data_o;    // ALU_1 rs1转发数据
wire alu1_rs2_forward_flag_o;           // ALU_1 rs2转发标志
wire [31:0] alu1_rs2_forward_data_o;    // ALU_1 rs2转发数据
wire mem_rs1_forward_flag_o;            // mem rs1转发标志
wire [31:0] mem_rs1_forward_data_o;     // mem rs1转发数据
wire mem_rs2_forward_flag_o;            // mem rs2转发标志
wire [31:0] mem_rs2_forward_data_o;     // mem rs2转发数据
wire branch_rs1_forward_flag_o;         // branch rs1转发标志
wire [31:0] branch_rs1_forward_data_o;  // branch rs1转发数据
wire branch_rs2_forward_flag_o;         // branch rs2转发标志
wire [31:0] branch_rs2_forward_data_o;  // branch rs2转发数据
`ifdef use_m_extension
wire mul_rs1_forward_flag_o;           // mul rs1转发标志
wire [31:0] mul_rs1_forward_data_o;     // mul rs1转发数据
wire mul_rs2_forward_flag_o;            // mul rs2转发标志
wire [31:0] mul_rs2_forward_data_o;     // mul rs2转发数据
wire div_rs1_forward_flag_o;            // div rs1转发标志
wire [31:0] div_rs1_forward_data_o;     // div rs1转发数据
wire div_rs2_forward_flag_o;            // div rs2转发标志
wire [31:0] div_rs2_forward_data_o;     // div rs2转发数据
`endif

// csr_reg模块输出信号
wire csr_global_int_en_o;           
wire csr_mie_MEIE;                    
wire csr_mie_MTIE;                    
wire csr_mip_MEIP;                    
wire csr_mip_MTIP;                    
wire [31:0] csr_clint_csr_mtvec;
wire [31:0] csr_clint_csr_mepc;     
wire [31:0] csr_clint_csr_mstatus;     
wire [31:0] csr_data_o;           

// clint模块输出信号
wire clint_mepc_we_o;                  
wire clint_mstatus_we_o;                  
wire clint_mcause_we_o;         
wire clint_mip_we_o;               
wire [31:0] clint_mepc_wdata_o;         
wire [31:0] clint_mstatus_wdata_o;   
wire [31:0] clint_mcause_wdata_o;         
wire [31:0] clint_mip_wdata_o;       
wire clint_uart_int_clear;              
wire clint_timer_int_clear;       
wire [31:0] clint_int_addr_o;
wire clint_int_w_disable_o;    
wire clint_int_flag_o;                

// 分支预测单元
BPU u_BPU(
    .clk(clk),
    .rst(rst),
    .if_pc(pc_o),                                // 来自取指阶段的PC
    .btb_update_en(buf_btb_update_en_o),             // 来自执行阶段的BTB更新使能
    .jump_target(buf_jump_addr_o),        // 来自执行阶段的实际跳转目标地址
    .ex_pc(buf_ex_pc_o),              // 来自执行阶段的PC
    .is_branch(buf_is_branch_o),                 // 来自执行阶段的是否为分支指令
    // LHP
    .lhp_update_en(buf_lhp_update_en_o),                   // 来自执行阶段的更新使能
    .branch_taken(buf_branch_taken_o),                    // 来自执行阶段实际跳转结果
    // RAS
    .ras_push_en(ifu_ras_push_flag_o),                     // 来自取指阶段的压栈使能
    .ras_data_in(ifu_ras_push_data_o),              // 来自取指阶段的压栈数据
    .ras_pop_en(ifu_ras_pop_flag_o),                      // 来自取指阶段的弹栈使能
    .ras_restore_en(br_jump_flag_o),                 // 来自执行阶段的恢复栈指针使能
    .ras_restore_ptr(br_ras_snap_ptr_o),          // 来自执行阶段的恢复栈指针值
    .ras_hold_flag_i(rn_stall_o),                // 来自dispatch的流水线暂停信号
    .ras_snap_ptr(bpu_ras_snap_ptr),            // 传到取指阶段2的快照栈指针
    .ras_data_out(bpu_ras_data_out),           // 传到取指阶段2的弹栈数据
    // to if
    .odd_inst_jump(bpu_odd_inst_jump),            // 跳转的是否是奇数指令（1为奇数，0为偶数）
    // to PC
    .jump_flag_o(bpu_jump_flag_o),                 // 跳转使能
    .jump_addr_o(bpu_jump_addr_o)           // 跳转地址
);

// 取指单元
IFU u_IFU(
    .clk(clk),
    .rst(rst),
    // pc_reg
    .jump_flag_i(br_jump_flag_o),
    .jump_addr_i(br_jump_addr_o),
    .int_flag_i(clint_int_flag_o),
    .int_addr_i(clint_int_addr_o),
    .stall_flag_i(rn_stall_o),           // RS/ROB满，暂停取指
    .jal_flush_i(idu_jal_flush_o),
    .jal_addr_i(idu_jal_addr_o),
    .ras_pre_addr_i(bpu_ras_data_out),    // 来自BPU的RAS预测地址
    .bpu_pre_flag_i(bpu_jump_flag_o),
    .bpu_pre_addr_i(bpu_jump_addr_o),
    .pc_o(pc_o),
    // IF_Stage1
    .bpu_jump_odd_i(bpu_odd_inst_jump),
    // .rom_inst_i(irom_data),
    // icache
    .icache_line_i(cache_line),
    // if_stage2
    .ras_snap_ptr_i(bpu_ras_snap_ptr),    // RAS快照指针
    .ras_pop_flag_o(ifu_ras_pop_flag_o),
    .ras_push_flag_o(ifu_ras_push_flag_o),
    .ras_push_data_o(ifu_ras_push_data_o),
    // if_id
    .if_id_ras_snap_ptr_o(if_id_ras_snap_ptr_o),
    .if_id_inst_valid_port0_o(if_id_inst_valid_port0_o),
    .if_id_inst_valid_port1_o(if_id_inst_valid_port1_o),
    .if_id_inst_port0_o(if_id_inst_port0_o),
    .if_id_inst_port1_o(if_id_inst_port1_o),
    .if_id_inst_addr_o(if_id_inst_addr_o),
    .if_id_imm_port0_o(if_id_imm_port0_o),
    .if_id_imm_port1_o(if_id_imm_port1_o),
    .if_id_bpu_pre_flag_port0_o(if_id_bpu_pre_flag_port0_o),
    .if_id_bpu_pre_flag_port1_o(if_id_bpu_pre_flag_port1_o),
    .if_id_bpu_pre_addr_port0_o(if_id_bpu_pre_addr_port0_o),
    .if_id_bpu_pre_addr_port1_o(if_id_bpu_pre_addr_port1_o)
);

// 译码单元
IDU u_IDU(
    .clk(clk),
    .rst(rst),
    // from if_id
    .ras_snap_ptr_i(if_id_ras_snap_ptr_o),               // RAS快照指针
    .inst_valid_port0_i(if_id_inst_valid_port0_o),                 // 指令有效标志
    .inst_valid_port1_i(if_id_inst_valid_port1_o),                 // 指令有效标志
    .inst_port0_i(if_id_inst_port0_o),                // 指令内容
    .inst_port1_i(if_id_inst_port1_o),                // 指令内容
    .inst_addr_i(if_id_inst_addr_o),                 // 指令地址
    .imm_port0_i(if_id_imm_port0_o),                 // 立即数
    .imm_port1_i(if_id_imm_port1_o),                 // 立即数
    .bpu_pre_flag_port0_i(if_id_bpu_pre_flag_port0_o),               // 预测标志
    .bpu_pre_flag_port1_i(if_id_bpu_pre_flag_port1_o),               // 预测标志
    .bpu_pre_addr_port0_i(if_id_bpu_pre_addr_port0_o),        // 预测地址
    .bpu_pre_addr_port1_i(if_id_bpu_pre_addr_port1_o),        // 预测地址
    // to pc and if_id
    .jal_flush_o(idu_jal_flush_o),                   // jal指令跳转冲刷
    .jal_addr_o(idu_jal_addr_o),             // jal指令的跳转地址
    // from ctrl
    .int_flag_i(clint_int_flag_o),                          // 中断标志
    .jump_flag_i(br_jump_flag_o),                         // 执行确认阶段跳转标志
    .restore_snap_id_i(br_kill_mask_id_o),             // 需要恢复的快照id
    .stall_flag_i(iss_stall_o),                        // RS/ROB满暂停
    // from commit
    .free_snap_flag_inst0_i(rob_free_snap_flag_inst0_o),
    .free_snap_flag_inst1_i(rob_free_snap_flag_inst1_o),
    .free_snap_id_inst0_i(rob_free_snap_id_inst0_o),     
    .free_snap_id_inst1_i(rob_free_snap_id_inst1_o),
    .commit_inst0_i(rob_commit_inst0_o),                 // 指令0提交使能
    .waddr_commit0_i(rob_waddr_commit0_o),          // 提交指令的目标逻辑寄存器
    .paddr_commit0_i(rob_paddr_commit0_o),          // 提交指令的目标物理寄存器(成为架构状态)
    .free_paddr_inst0_i(rob_free_paddr_inst0_o),       // 释放的物理寄存器地址
    .commit_inst1_i(rob_commit_inst1_o),                 // 指令1提交使能
    .waddr_commit1_i(rob_waddr_commit1_o),          // 提交指令的目标逻辑寄存器
    .paddr_commit1_i(rob_paddr_commit1_o),          // 提交指令的目标物理寄存器(成为架构状态)
    .free_paddr_inst1_i(rob_free_paddr_inst1_o),       // 释放的物理寄存器地址
    // to regs
    .rn_alloc_flag_inst0_o(rn_alloc_flag_inst0_o),             // Inst0是否分配物理寄存器
    .rn_alloc_flag_inst1_o(rn_alloc_flag_inst1_o),             // Inst1是否分配物理寄存器
    .rn_pwaddr_inst0_o(rn_pwaddr_inst0_o),           // 指令0物理寄存器写地址
    .rn_pwaddr_inst1_o(rn_pwaddr_inst1_o),           // 指令1物理寄存器写地址
    // to pipeline
    .rn_stall_o(rn_stall_o),                        // 重命名和RS/ROB暂停信号
    // to Issue
    .rn_dp_ras_snap_ptr_o(rn_dp_ras_snap_ptr_o),            // RAS快照指针
    .rn_dp_inst_addr_o(rn_dp_inst_addr_o),              // 指令地址
    .rn_dp_inst_type_port0_o(rn_dp_inst_type_port0_o),         // 指令类型
    .rn_dp_inst_type_port1_o(rn_dp_inst_type_port1_o),         // 指令类型
    .rn_dp_inst_subtype_port0_o(rn_dp_inst_subtype_port0_o),      // 指令子类型
    .rn_dp_inst_subtype_port1_o(rn_dp_inst_subtype_port1_o),      // 指令子类型
    .rn_dp_op1_src_port0_o(rn_dp_op1_src_port0_o),           // 操作数1来源选择
    .rn_dp_op1_src_port1_o(rn_dp_op1_src_port1_o),           // 操作数1来源选择
    .rn_dp_op2_src_port0_o(rn_dp_op2_src_port0_o),           // 操作数2来源选择
    .rn_dp_op2_src_port1_o(rn_dp_op2_src_port1_o),           // 操作数2来源选择
    .rn_dp_csr_addr_port0_o(rn_dp_csr_addr_port0_o),         // CSR寄存器地址
    .rn_dp_csr_addr_port1_o(rn_dp_csr_addr_port1_o),         // CSR寄存器地址
    .rn_dp_csr_wflag_port0_o(rn_dp_csr_wflag_port0_o),               // CSR寄存器写使能
    .rn_dp_csr_wflag_port1_o(rn_dp_csr_wflag_port1_o),               // CSR寄存器写使能
    .rn_dp_reg_wflag_port0_o(rn_dp_reg_wflag_port0_o),               // 通用寄存器写使能
    .rn_dp_reg_wflag_port1_o(rn_dp_reg_wflag_port1_o),               // 通用寄存器写使能
    .rn_dp_reg_waddr_port0_o(rn_dp_reg_waddr_port0_o),               // 写通用寄存器地址
    .rn_dp_reg_waddr_port1_o(rn_dp_reg_waddr_port1_o),               // 写通用寄存器地址
    .rn_dp_inst_valid_port0_o(rn_dp_inst_valid_port0_o),              // 指令有效标志
    .rn_dp_inst_valid_port1_o(rn_dp_inst_valid_port1_o),              // 指令有效标志
    .rn_dp_imm_port0_o(rn_dp_imm_port0_o),              // 立即数
    .rn_dp_imm_port1_o(rn_dp_imm_port1_o),              // 立即数
    .rn_dp_aux_addr_port0_o(rn_dp_aux_addr_port0_o),         // Auxiliary Address（辅助地址）
    .rn_dp_aux_addr_port1_o(rn_dp_aux_addr_port1_o),         // Auxiliary Address（辅助地址）
    .rn_dp_bpu_pre_flag_port0_o(rn_dp_bpu_pre_flag_port0_o),            // 预测标志
    .rn_dp_bpu_pre_flag_port1_o(rn_dp_bpu_pre_flag_port1_o),            // 预测标志
    .rn_dp_bpu_pre_addr_port0_o(rn_dp_bpu_pre_addr_port0_o),     // 预测地址
    .rn_dp_bpu_pre_addr_port1_o(rn_dp_bpu_pre_addr_port1_o),     // 预测地址
    .rn_dp_praddr1_inst0_o(rn_dp_praddr1_inst0_o),           // 指令0物理寄存器1读地址
    .rn_dp_praddr2_inst0_o(rn_dp_praddr2_inst0_o),           // 指令0物理寄存器2读地址
    .rn_dp_praddr1_inst1_o(rn_dp_praddr1_inst1_o),           // 指令1物理寄存器1读地址
    .rn_dp_praddr2_inst1_o(rn_dp_praddr2_inst1_o),           // 指令1物理寄存器2读地址
    .rn_dp_pwaddr_inst0_o(rn_dp_pwaddr_inst0_o),            // 指令0物理寄存器写地址
    .rn_dp_pwaddr_inst1_o(rn_dp_pwaddr_inst1_o),            // 指令1物理寄存器写地址
    .rn_dp_branch_mask_inst0_o(rn_dp_branch_mask_inst0_o),       // 指令0分支掩码
    .rn_dp_branch_mask_inst1_o(rn_dp_branch_mask_inst1_o),       // 指令1分支掩码
    .rn_dp_old_paddr_inst0_o(rn_dp_old_paddr_inst0_o),         // 指令0旧物理寄存器地址
    .rn_dp_old_paddr_inst1_o(rn_dp_old_paddr_inst1_o),         // 指令1旧物理寄存器地址
    .rn_dp_snap_id_inst0_o(rn_dp_snap_id_inst0_o),           // 指令0快照id
    .rn_dp_snap_id_inst1_o(rn_dp_snap_id_inst1_o)            // 指令1快照id
);

// Issue模块
Issue u_Issue(
    .clk(clk),
    .rst(rst),
    // from dispatch
    .inst_addr_i(rn_dp_inst_addr_o[15:0]),              // 指令地址
    .ras_snap_ptr_i(rn_dp_ras_snap_ptr_o),                 // RAS快照指针
    .inst_type_port0_i(rn_dp_inst_type_port0_o),              // 指令类型
    .inst_type_port1_i(rn_dp_inst_type_port1_o),              // 指令类型
    .inst_subtype_port0_i(rn_dp_inst_subtype_port0_o),           // 指令子类型
    .inst_subtype_port1_i(rn_dp_inst_subtype_port1_o),           // 指令子类型
    .op1_src_port0_i(rn_dp_op1_src_port0_o),                // 操作数1来源选择
    .op1_src_port1_i(rn_dp_op1_src_port1_o),                // 操作数1来源选择
    .op2_src_port0_i(rn_dp_op2_src_port0_o),                // 操作数2来源选择
    .op2_src_port1_i(rn_dp_op2_src_port1_o),                // 操作数2来源选择
    .inst_valid_port0_i(rn_dp_inst_valid_port0_o),                   // 指令有效标志
    .inst_valid_port1_i(rn_dp_inst_valid_port1_o),                   // 指令有效标志
    .imm_port0_i(rn_dp_imm_port0_o),                   // 立即数
    .imm_port1_i(rn_dp_imm_port1_o),                   // 立即数
    .aux_addr_port0_i(rn_dp_aux_addr_port0_o),              // Auxiliary Address（辅助地址）
    .aux_addr_port1_i(rn_dp_aux_addr_port1_o),              // Auxiliary Address（辅助地址）
    .bpu_pre_flag_port0_i(rn_dp_bpu_pre_flag_port0_o),                 // 预测标志
    .bpu_pre_flag_port1_i(rn_dp_bpu_pre_flag_port1_o),                 // 预测标志
    .bpu_pre_addr_port0_i(rn_dp_bpu_pre_addr_port0_o),          // 预测地址
    .bpu_pre_addr_port1_i(rn_dp_bpu_pre_addr_port1_o),          // 预测地址
    .praddr1_inst0_i(rn_dp_praddr1_inst0_o),         // 指令0物理寄存器1读地址
    .praddr2_inst0_i(rn_dp_praddr2_inst0_o),         // 指令0物理寄存器2读地址
    .praddr1_inst1_i(rn_dp_praddr1_inst1_o),         // 指令1物理寄存器1读地址
    .praddr2_inst1_i(rn_dp_praddr2_inst1_o),         // 指令1物理寄存器2读地址
    .pwaddr_inst0_i(rn_dp_pwaddr_inst0_o),          // 指令0物理寄存器写地址
    .pwaddr_inst1_i(rn_dp_pwaddr_inst1_o),          // 指令1物理寄存器写地址
    .branch_mask_inst0_i(rn_dp_branch_mask_inst0_o),     // 指令0分支掩码
    .branch_mask_inst1_i(rn_dp_branch_mask_inst1_o),     // 指令1分支掩码
    .snap_id_inst0_i(rn_dp_snap_id_inst0_o),         // 指令0快照id
    .snap_id_inst1_i(rn_dp_snap_id_inst1_o),         // 指令1快照id
    // from ROB
    .rob_stall_i(rob_stall_o),                       // ROB满暂停标志
    .rob_id_inst0_i(rob_id_inst0_o),              // 指令0 ROB id
    .rob_id_inst1_i(rob_id_inst1_o),              // 指令1 ROB id
    // from commit
    .sq_commit_cnt_i(rob_sq_commit_cnt_o),               // store queue提交数量
    .free_mask_inst0_i(rob_free_snap_flag_inst0_o),                   // 指令0释放掩码标志
    .free_id_inst0_i(rob_free_snap_id_inst0_o),               // 指令0释放id
    .free_mask_inst1_i(rob_free_snap_flag_inst1_o),                   // 指令1释放掩码标志
    .free_id_inst1_i(rob_free_snap_id_inst1_o),               // 指令1释放id
    // from clint
    .int_flag_i(clint_int_flag_o),                       // 中断标志
    // from ex
    .jump_flag_i(br_jump_flag_o),                      // 跳转标志
    .kill_mask_id_i(br_kill_mask_id_o),             // 杀死指令掩码
    .restore_mem_wr_ptr_i(br_mem_wr_ptr_o),       // 恢复mem队列写指针
    .restore_sq_ptr_i(br_sq_ptr_o),           // 恢复store queue指针
    // from ALU0
    .alu0_rf_pwaddr_i(alu0_rf_waddr_o),           // ALU0读寄存器文件阶段物理寄存器地址
    // from ALU1
    .alu1_rf_pwaddr_i(alu1_rf_waddr_o),           // ALU1读寄存器文件阶段物理寄存器地址
    // from branch
    .branch_rf_pwaddr_i(br_rf_waddr_o),         // branch读寄存器文件阶段物理寄存器地址
    // from mem
    .mem_flush_i(lsu_flush_o),                      // mem冲刷标志
    .mem_stall_i(lsu_stall_o),                      // mem暂停标志
    .mem_pwaddr_i(lsu_mem_reg_waddr_o),
`ifdef use_m_extension
    // from div
    .div_flush_i(div_flush_o),                      // div冲刷标志
    .div_stall_i(div_stall_o),                      // div暂停标志
`endif
    // from regs
    .ready_flag_i(regs_ready_flag_o),          // 寄存器就绪标志，位0-63分别对应物理寄存器0-63
    // to ALU0
    .alu_inst_valid_inst0_o(iss_alu_inst_valid_inst0_o),       // ALU0指令有效标志
    .alu_rob_id_inst0_o(iss_alu_rob_id_inst0_o),               // ALU0 ROB id
    .alu_mask_inst0_o(iss_alu_mask_inst0_o),       // ALU0分支掩码
    .alu_subtype_inst0_o(iss_alu_subtype_inst0_o),    // ALU0指令子类型
    .alu_op1_src_inst0_o(iss_alu_op1_src_inst0_o),    // ALU0操作数1
    .alu_op2_src_inst0_o(iss_alu_op2_src_inst0_o),    // ALU0操作数2
    .alu_praddr1_inst0_o(iss_alu_praddr1_inst0_o),    // ALU0物理寄存器1读地址
    .alu_praddr2_inst0_o(iss_alu_praddr2_inst0_o),    // ALU0物理寄存器2读地址
    .alu_pwaddr_inst0_o(iss_alu_pwaddr_inst0_o),     // ALU0物理寄存器写地址
    .alu_imm_inst0_o(iss_alu_imm_inst0_o),       // ALU0立即数
    // to ALU1
    .alu_inst_valid_inst1_o(iss_alu_inst_valid_inst1_o),       // ALU1指令有效标志
    .alu_rob_id_inst1_o(iss_alu_rob_id_inst1_o),               // ALU1 ROB id
    .alu_mask_inst1_o(iss_alu_mask_inst1_o),       // ALU1分支掩码
    .alu_subtype_inst1_o(iss_alu_subtype_inst1_o),    // ALU1指令子类型
    .alu_op1_src_inst1_o(iss_alu_op1_src_inst1_o),    // ALU1操作数1
    .alu_op2_src_inst1_o(iss_alu_op2_src_inst1_o),    // ALU1操作数2
    .alu_praddr1_inst1_o(iss_alu_praddr1_inst1_o),    // ALU1物理寄存器1读地址
    .alu_praddr2_inst1_o(iss_alu_praddr2_inst1_o),    // ALU1物理寄存器2读地址
    .alu_pwaddr_inst1_o(iss_alu_pwaddr_inst1_o),     // ALU1物理寄存器写地址
    .alu_imm_inst1_o(iss_alu_imm_inst1_o),       // ALU1立即数
    // to branch
    .br_inst_valid_o(iss_br_inst_valid_o),              // branch指令有效标志
    .br_inst_addr_o(iss_br_inst_addr_o),                // branch指令地址
    .br_rob_id_o(iss_br_rob_id_o),                       // branch ROB id
    .br_bpu_pre_flag_o(iss_br_bpu_pre_flag_o),            // branch BPU预测标志
    .br_bpu_pre_addr_o(iss_br_bpu_pre_addr_o),     // branch BPU预测地址
    .br_mask_o(iss_br_mask_o),              // branch分支掩码
    .br_ras_ptr_o(iss_br_ras_ptr_o),           // branch RAS快照指针
    .br_mem_wr_ptr_o(iss_br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_o(iss_br_sq_ptr_o),            // branch store queue快照指针
    .br_snap_id_o(iss_br_snap_id_o),           // branch快照id
    .br_type_o(iss_br_type_o),              // branch指令类型
    .br_subtype_o(iss_br_subtype_o),           // branch指令子类型
    .br_op1_src_o(iss_br_op1_src_o),           // branch操作数1
    .br_op2_src_o(iss_br_op2_src_o),           // branch操作数2
    .br_praddr1_o(iss_br_praddr1_o),           // branch物理寄存器1读地址
    .br_praddr2_o(iss_br_praddr2_o),           // branch物理寄存器2读地址
    .br_pwaddr_o(iss_br_pwaddr_o),            // branch物理寄存器写地址
    .br_imm_o(iss_br_imm_o),              // branch立即数
    .br_aux_addr_o(iss_br_aux_addr_o),         // branch辅助地址
    // to mem
    .mem_inst_valid_o(iss_mem_inst_valid_o),             // mem指令有效标志
    .mem_rob_id_o(iss_mem_rob_id_o),                       // mem ROB id
    .mem_mask_o(iss_mem_mask_o),             // mem分支掩码
    .mem_sq_id_o(iss_mem_sq_id_o),            // mem SQ id
    .mem_subtype_o(iss_mem_subtype_o),          // mem指令子类型
    .mem_op1_src_o(iss_mem_op1_src_o),          // mem操作数1
    .mem_op2_src_o(iss_mem_op2_src_o),          // mem操作数2
    .mem_praddr1_o(iss_mem_praddr1_o),          // mem物理寄存器1读地址
    .mem_praddr2_o(iss_mem_praddr2_o),          // mem物理寄存器2读地址
    .mem_pwaddr_o(iss_mem_pwaddr_o),           // mem物理寄存器写地址
    .mem_imm_o(iss_mem_imm_o),             // mem立即数
`ifdef use_m_extension
    // to mul
    .mul_inst_valid_o(iss_mul_inst_valid_o),             // mul指令有效标志
    .mul_rob_id_o(iss_mul_rob_id_o),                       // mul ROB id
    .mul_mask_o(iss_mul_mask_o),             // mul分支掩码
    .mul_subtype_o(iss_mul_subtype_o),          // mul指令子类型
    .mul_praddr1_o(iss_mul_praddr1_o),          // mul物理寄存器1读地址
    .mul_praddr2_o(iss_mul_praddr2_o),          // mul物理寄存器2读地址
    .mul_pwaddr_o(iss_mul_pwaddr_o),           // mul物理寄存器写地址
    // to div
    .div_inst_valid_o(iss_div_inst_valid_o),             // div指令有效标志
    .div_rob_id_o(iss_div_rob_id_o),                       // div ROB id
    .div_mask_o(iss_div_mask_o),             // div分支掩码
    .div_subtype_o(iss_div_subtype_o),          // div指令子类型
    .div_praddr1_o(iss_div_praddr1_o),          // div物理寄存器1读地址
    .div_praddr2_o(iss_div_praddr2_o),          // div物理寄存器2读地址
    .div_pwaddr_o(iss_div_pwaddr_o),           // div物理寄存器写地址
`endif
    // to ROB
    .stall_rob_o(iss_stall_rob_o),
    // to pipeline
    .stall_o(iss_stall_o)
);

// ALU_0
ALU u_ALU_0(
    .clk(clk),
    .rst(rst),
    // from issue
    .inst_valid_i(iss_alu_inst_valid_inst0_o),                 // ALU指令有效标志
    .rob_id_i(iss_alu_rob_id_inst0_o),               // ALU ROB id
    .mask_i(iss_alu_mask_inst0_o),                 // ALU分支掩码
    .subtype_i(iss_alu_subtype_inst0_o),              // ALU指令子类型
    .op1_src_i(iss_alu_op1_src_inst0_o),              // ALU操作数1
    .op2_src_i(iss_alu_op2_src_inst0_o),              // ALU操作数2
    .praddr1_i(iss_alu_praddr1_inst0_o),              // ALU物理寄存器1读地址
    .praddr2_i(iss_alu_praddr2_inst0_o),              // ALU物理寄存器2读地址
    .pwaddr_i(iss_alu_pwaddr_inst0_o),               // ALU物理寄存器写地址
    .imm_i(iss_alu_imm_inst0_o),                 // ALU立即数
    // from forward_unit
    .rs1_forward_flag_i(alu0_rs1_forward_flag_o),           // rs1转发标志
    .rs1_forward_data_i(alu0_rs1_forward_data_o),    // rs1转发数据
    .rs2_forward_flag_i(alu0_rs2_forward_flag_o),           // rs2转发标志
    .rs2_forward_data_i(alu0_rs2_forward_data_o),    // rs2转发数据
    // from clint
    .int_flag_i(clint_int_flag_o),                   // 中断标志
    // from branch
    .jump_flag_i(br_jump_flag_o),                  // 跳转标志
    .kill_mask_id_i(br_kill_mask_id_o),         // 分支掩码id
    // from commit
    .free_mask_inst0_i(rob_free_snap_flag_inst0_o),                   // 指令0释放掩码标志
    .free_id_inst0_i(rob_free_snap_id_inst0_o),               // 指令0释放id
    .free_mask_inst1_i(rob_free_snap_flag_inst1_o),                   // 指令1释放掩码标志
    .free_id_inst1_i(rob_free_snap_id_inst1_o),               // 指令1释放id
    // from regs
    .reg_rdata1_i(regs_alu_inst0_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_i(regs_alu_inst0_rdata2_o),          // 寄存器2读数据
    // to regs
    .rf_raddr1_o(alu0_rf_raddr1_o),           // RF 阶段读寄存器1地址（同时传到转发模块）
    .rf_raddr2_o(alu0_rf_raddr2_o),           // RF 阶段读寄存器2地址（同时传到转发模块）
    .reg_wflag_o(alu0_reg_wflag_o),                 // 写回阶段写寄存器标志
    .reg_waddr_o(alu0_reg_waddr_o),           // 写回阶段写寄存器地址
    .reg_wdata_o(alu0_reg_wdata_o),          // 写回阶段写寄存器数据
    .rf_wflag_o(alu0_rf_wflag_o),                  // RF 阶段写寄存器标志
    .rf_waddr_o(alu0_rf_waddr_o),            // RF 阶段写寄存器地址(同时传到issue阶段和ex)
    // to forward_unit
    .exe_waddr_o(alu0_exe_waddr_o),           // 执行阶段写寄存器地址
    .exe_wdata_o(alu0_exe_wdata_o),          // 执行阶段写寄存器数据
    // to ROB
    .complete_flag_o(alu0_complete_flag_o),             // 指令完成标志
    .commit_rob_id_o(alu0_commit_rob_id_o)        // 提交ROB id
);

// ALU_1
ALU u_ALU_1(
    .clk(clk),
    .rst(rst),
    // from issue
    .inst_valid_i(iss_alu_inst_valid_inst1_o),                 // ALU指令有效标志
    .rob_id_i(iss_alu_rob_id_inst1_o),               // ALU ROB id
    .mask_i(iss_alu_mask_inst1_o),                 // ALU分支掩码
    .subtype_i(iss_alu_subtype_inst1_o),              // ALU指令子类型
    .op1_src_i(iss_alu_op1_src_inst1_o),              // ALU操作数1
    .op2_src_i(iss_alu_op2_src_inst1_o),              // ALU操作数2
    .praddr1_i(iss_alu_praddr1_inst1_o),              // ALU物理寄存器1读地址
    .praddr2_i(iss_alu_praddr2_inst1_o),              // ALU物理寄存器2读地址
    .pwaddr_i(iss_alu_pwaddr_inst1_o),               // ALU物理寄存器写地址
    .imm_i(iss_alu_imm_inst1_o),                 // ALU立即数
    // from forward_unit
    .rs1_forward_flag_i(alu1_rs1_forward_flag_o),           // rs1转发标志
    .rs1_forward_data_i(alu1_rs1_forward_data_o),    // rs1转发数据
    .rs2_forward_flag_i(alu1_rs2_forward_flag_o),           // rs2转发标志
    .rs2_forward_data_i(alu1_rs2_forward_data_o),    // rs2转发数据
    // from clint
    .int_flag_i(clint_int_flag_o),                   // 中断标志
    // from branch
    .jump_flag_i(br_jump_flag_o),                  // 跳转标志
    .kill_mask_id_i(br_kill_mask_id_o),         // 分支掩码id
    // from commit
    .free_mask_inst0_i(rob_free_snap_flag_inst0_o),                   // 指令0释放掩码标志
    .free_id_inst0_i(rob_free_snap_id_inst0_o),               // 指令0释放id
    .free_mask_inst1_i(rob_free_snap_flag_inst1_o),                   // 指令1释放掩码标志
    .free_id_inst1_i(rob_free_snap_id_inst1_o),               // 指令1释放id
    // from regs
    .reg_rdata1_i(regs_alu_inst1_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_i(regs_alu_inst1_rdata2_o),          // 寄存器2读数据
    // to regs
    .rf_raddr1_o(alu1_rf_raddr1_o),           // RF 阶段读寄存器1地址（同时传到转发模块）
    .rf_raddr2_o(alu1_rf_raddr2_o),           // RF 阶段读寄存器2地址（同时传到转发模块）
    .reg_wflag_o(alu1_reg_wflag_o),                 // 写回阶段写寄存器标志
    .reg_waddr_o(alu1_reg_waddr_o),           // 写回阶段写寄存器地址
    .reg_wdata_o(alu1_reg_wdata_o),          // 写回阶段写寄存器数据
    .rf_wflag_o(alu1_rf_wflag_o),                  // RF 阶段写寄存器标志
    .rf_waddr_o(alu1_rf_waddr_o),            // RF 阶段写寄存器地址(同时传到issue阶段和ex)
    // to forward_unit
    .exe_waddr_o(alu1_exe_waddr_o),           // 执行阶段写寄存器地址(同时传到issue阶段和regs)
    .exe_wdata_o(alu1_exe_wdata_o),          // 执行阶段写寄存器数据
    // to ROB
    .complete_flag_o(alu1_complete_flag_o),             // 指令完成标志
    .commit_rob_id_o(alu1_commit_rob_id_o)        // 提交ROB id
);

// Branch
Branch u_Branch(
    .clk(clk),
    .rst(rst),
    // from issue
    .br_inst_valid_i(iss_br_inst_valid_o),              // branch指令有效标志
    .br_inst_addr_i(iss_br_inst_addr_o),        // branch指令地址
    .br_rob_id_i(iss_br_rob_id_o),            // branch ROB id
    .br_bpu_pre_flag_i(iss_br_bpu_pre_flag_o),            // branch BPU预测标志
    .br_bpu_pre_addr_i(iss_br_bpu_pre_addr_o),     // branch BPU预测地址
    .br_mask_i(iss_br_mask_o),              // branch分支掩码
    .br_ras_ptr_i(iss_br_ras_ptr_o),           // branch RAS快照指针
    .br_mem_wr_ptr_i(iss_br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_i(iss_br_sq_ptr_o),            // branch store queue快照指针
    .br_snap_id_i(iss_br_snap_id_o),           // branch快照id
    .br_type_i(iss_br_type_o),              // branch指令类型
    .br_subtype_i(iss_br_subtype_o),           // branch指令子类型
    .br_praddr1_i(iss_br_praddr1_o),           // branch物理寄存器1读地址
    .br_praddr2_i(iss_br_praddr2_o),           // branch物理寄存器2读地址
    .br_pwaddr_i(iss_br_pwaddr_o),            // branch物理寄存器写地址
    .br_imm_i(iss_br_imm_o),              // branch立即数
    .br_aux_addr_i(iss_br_aux_addr_o),         // branch辅助地址
    // from forward_unit
    .rs1_forward_flag_i(branch_rs1_forward_flag_o),           // rs1转发标志
    .rs1_forward_data_i(branch_rs1_forward_data_o),    // rs1转发数据
    .rs2_forward_flag_i(branch_rs2_forward_flag_o),           // rs2转发标志
    .rs2_forward_data_i(branch_rs2_forward_data_o),    // rs2转发数据
    // from regs
    .reg_rdata1_i(regs_branch_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_i(regs_branch_rdata2_o),          // 寄存器2读数据
    // from clint
    .int_flag_i(clint_int_flag_o),                   // 中断标志
    // to pipeline
    .jump_flag_o(br_jump_flag_o),                 // 跳转标志
    .kill_mask_id_o(br_kill_mask_id_o),        // 分支掩码id
    // to RAS
    .ras_snap_ptr_o(br_ras_snap_ptr_o),              // RAS快照指针
    // to issue
    .br_mem_wr_ptr_o(br_mem_wr_ptr_o),        // branch mem队列写操作快照指针
    .br_sq_ptr_o(br_sq_ptr_o),            // branch store queue快照指针
    // to PC
    .jump_addr_o(br_jump_addr_o),          // 跳转地址
    // to bpu_update_buffer
    .btb_update_en(br_btb_update_en),                     // 执行阶段更新BTB使能
    .ex_pc(br_ex_pc),                          // 执行阶段的pc
    .ex_jump_addr_o(br_ex_jump_addr_o),             // 跳转地址
    .is_branch(br_is_branch),                             // 是否为分支指令
    .lhp_update_en(br_lhp_update_en),                     // 更新使能
    .branch_taken(br_branch_taken),                      // 实际跳转结果(1为跳转)
    // to regs
    .rf_raddr1_o(br_rf_raddr1_o),           // RF 阶段读寄存器1地址（同时传到转发模块）
    .rf_raddr2_o(br_rf_raddr2_o),           // RF 阶段读寄存器2地址（同时传到转发模块）
    .rf_wflag_o(br_rf_wflag_o),                  // RF 阶段写寄存器标志
    .rf_waddr_o(br_rf_waddr_o),            // RF 阶段写寄存器地址(同时传到issue阶段)
    .reg_wflag_o(br_reg_wflag_o),                 // 写回阶段写寄存器标志
    .reg_waddr_o(br_reg_waddr_o),           // 写回阶段写寄存器地址
    .reg_wdata_o(br_reg_wdata_o),          // 写回阶段写寄存器数据
    // to ROB
    .complete_flag_o(br_complete_flag_o),             // 指令完成标志
    .commit_rob_id_o(br_commit_rob_id_o)        // 提交ROB id
);

// bpu_update_buffer
bpu_update_buffer u_bpu_update_buffer(
    .clk(clk),
    .rst(rst),
    // from br_ex
    .jump_addr_i(br_ex_jump_addr_o),          // 跳转地址
    .btb_update_en_i(br_btb_update_en),                     // 执行阶段更新BTB使能
    .ex_pc_i(br_ex_pc),                          // 执行阶段的pc
    .is_branch_i(br_is_branch),                             // 是否为分支指令
    .lhp_update_en_i(br_lhp_update_en),                     // 更新使能
    .branch_taken_i(br_branch_taken),                       // 实际跳转结果(1为跳转)
    // to BPU
    .jump_addr_o(buf_jump_addr_o),          // 跳转地址
    .btb_update_en_o(buf_btb_update_en_o),                     // 执行阶段更新BTB使能
    .ex_pc_o(buf_ex_pc_o),                          // 执行阶段的pc
    .is_branch_o(buf_is_branch_o),                             // 是否为分支指令
    .lhp_update_en_o(buf_lhp_update_en_o),                     // 更新使能
    .branch_taken_o(buf_branch_taken_o)                       // 实际跳转结果(1为跳转)
);

// LSU
LSU u_LSU(
    .clk(clk),
    .rst(rst),
    // from issue
    .inst_valid_i(iss_mem_inst_valid_o),               // 指令有效标志
    .rob_id_i(iss_mem_rob_id_o),             // ROB id
    .mask_i(iss_mem_mask_o),               // 分支掩码
    .sq_id_i(iss_mem_sq_id_o),              // SQ id
    .subtype_i(iss_mem_subtype_o),            // 指令子类型
    .praddr1_i(iss_mem_praddr1_o),            // 物理寄存器1读地址
    .praddr2_i(iss_mem_praddr2_o),            // 物理寄存器2读地址
    .pwaddr_i(iss_mem_pwaddr_o),              // 物理寄存器写地址
    .imm_i(iss_mem_imm_o),                    // 立即数
    // from forward_unit
    .rs1_forward_flag_i(mem_rs1_forward_flag_o),           // rs1转发标志
    .rs1_forward_data_i(mem_rs1_forward_data_o),    // rs1转发数据
    .rs2_forward_flag_i(mem_rs2_forward_flag_o),           // rs2转发标志
    .rs2_forward_data_i(mem_rs2_forward_data_o),    // rs2转发数据
    // from regs
    .reg_rdata1_i(regs_mem_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_i(regs_mem_rdata2_o),          // 寄存器2读数据
    // from clint
    .int_flag_i(clint_int_flag_o),                   // 中断标志
    // from branch
    .jump_flag_i(br_jump_flag_o),                 // 跳转标志
    .kill_mask_id_i(br_kill_mask_id_o),        // 分支掩码id
    // from commit
    .free_mask_inst0_i(rob_free_snap_flag_inst0_o),                   // 指令0释放掩码标志
    .free_id_inst0_i(rob_free_snap_id_inst0_o),               // 指令0释放id
    .free_mask_inst1_i(rob_free_snap_flag_inst1_o),                   // 指令1释放掩码标志
    .free_id_inst1_i(rob_free_snap_id_inst1_o),               // 指令1释放id
    // from commit
    .commit_store_flag_i(rob_commit_store_flag_o),             // 提交store指令标志
    // from peripheral
    .perip_rdata(perip_rdata),
    // to peripheral
    .mem_addr_o(perip_addr),
    // dcache 接口
    // from dram
    .cache_line(dcache_line),
    // from commit
    .mem_wen(rob_dcache_wen),
    // to peripheral
    .sq_mask_o(perip_mask),
    .sq_addr_o(perip_waddr),
    .sq_data_o(perip_wdata),
    // to commit
    .stall_store(lsu_stall_store),                 // store指令暂停标志
    // to regs
    .rf_raddr1_o(lsu_rf_raddr1_o),           // RF 阶段读寄存器1地址（同时传到转发模块）
    .rf_raddr2_o(lsu_rf_raddr2_o),           // RF 阶段读寄存器2地址（同时传到转发模块）
    .reg_wflag_o(lsu_reg_wflag_o),                 // 写回阶段写寄存器标志
    .reg_waddr_o(lsu_reg_waddr_o),           // 写回阶段写寄存器地址
    .reg_wdata_o(lsu_reg_wdata_o),          // 写回阶段写寄存器数据
    .mem_reg_wflag_o(lsu_mem_reg_wflag_o),             // Mem阶段写寄存器标志
    // to issue
    .flush_o(lsu_flush_o),                     // 冲刷标志
    .stall_o(lsu_stall_o),
    // to forward_unit
    .mem_reg_waddr_o(lsu_mem_reg_waddr_o),           // Mem阶段写寄存器地址(同时传到regs)
    .mem_reg_wdata_o(lsu_mem_reg_wdata_o),          // Mem阶段写寄存器数据
    // to ROB
    .store_complete_flag_o(store_complete_flag_o),             // store指令完成标志
    .store_commit_rob_id_o(store_commit_rob_id_o),       // store提交ROB id
    .load_complete_flag_o(load_complete_flag_o),              // load指令完成标志
    .load_commit_rob_id_o(load_commit_rob_id_o)         // load提交ROB id
);

`ifdef use_m_extension
// MUL
MUL u_MUL(
    .clk(clk),
    .rst(rst),
    // from issue
    .inst_valid_i(iss_mul_inst_valid_o),               // 指令有效标志
    .rob_id_i(iss_mul_rob_id_o),             // ROB id
    .mask_i(iss_mul_mask_o),               // 分支掩码
    .subtype_i(iss_mul_subtype_o),            // 指令子类型
    .praddr1_i(iss_mul_praddr1_o),            // 物理寄存器1读地址
    .praddr2_i(iss_mul_praddr2_o),            // 物理寄存器2读地址
    .pwaddr_i(iss_mul_pwaddr_o),             // 物理寄存器写地址
    // from forward_unit
    .rs1_forward_flag_i(mul_rs1_forward_flag_o),           // rs1转发标志
    .rs1_forward_data_i(mul_rs1_forward_data_o),    // rs1转发数据
    .rs2_forward_flag_i(mul_rs2_forward_flag_o),           // rs2转发标志
    .rs2_forward_data_i(mul_rs2_forward_data_o),    // rs2转发数据
    // from clint
    .int_flag_i(clint_int_flag_o),                   // 中断标志
    // from branch
    .jump_flag_i(br_jump_flag_o),                  // 跳转标志
    .kill_mask_id_i(br_kill_mask_id_o),         // 分支掩码id
    // from regs
    .reg_rdata1_i(regs_mul_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_i(regs_mul_rdata2_o),          // 寄存器2读数据
    // to regs
    .rf_raddr1_o(mul_rf_raddr1_o),           // RF 阶段读寄存器1地址（同时传到转发模块）
    .rf_raddr2_o(mul_rf_raddr2_o),           // RF 阶段读寄存器2地址（同时传到转发模块）
    .reg_wflag_o(mul_reg_wflag_o),                 // 写回阶段写寄存器标志
    .reg_waddr_o(mul_reg_waddr_o),           // 写回阶段写寄存器地址
    .reg_wdata_o(mul_reg_wdata_o),          // 写回阶段写寄存器数据
    .ex_wflag_o(mul_ex_wflag_o),                  // 执行阶段写寄存器标志
    .ex_waddr_o(mul_ex_waddr_o),            // 执行阶段写寄存器地址
    // to ROB
    .complete_flag_o(mul_complete_flag_o),             // 指令完成标志
    .commit_rob_id_o(mul_commit_rob_id_o)        // 提交ROB id
);

// DIV
DIV u_DIV(
    .clk(clk),
    .rst(rst),
    // from issue
    .inst_valid_i(iss_div_inst_valid_o),               // 指令有效标志
    .rob_id_i(iss_div_rob_id_o),             // ROB id
    .mask_i(iss_div_mask_o),               // 分支掩码
    .subtype_i(iss_div_subtype_o),            // 指令子类型
    .praddr1_i(iss_div_praddr1_o),            // 物理寄存器1读地址
    .praddr2_i(iss_div_praddr2_o),            // 物理寄存器2读地址
    .pwaddr_i(iss_div_pwaddr_o),             // 物理寄存器写地址
    // from forward_unit
    .rs1_forward_flag_i(div_rs1_forward_flag_o),           // rs1转发标志
    .rs1_forward_data_i(div_rs1_forward_data_o),    // rs1转发数据
    .rs2_forward_flag_i(div_rs2_forward_flag_o),           // rs2转发标志
    .rs2_forward_data_i(div_rs2_forward_data_o),    // rs2转发数据
    // from clint
    .int_flag_i(clint_int_flag_o),                   // 中断标志
    // from branch
    .jump_flag_i(br_jump_flag_o),                  // 跳转标志
    .kill_mask_id_i(br_kill_mask_id_o),         // 分支掩码id
    // from commit
    .free_mask_inst0_i(rob_free_snap_flag_inst0_o),                   // 指令0释放掩码标志
    .free_id_inst0_i(rob_free_snap_id_inst0_o),               // 指令0释放id
    .free_mask_inst1_i(rob_free_snap_flag_inst1_o),                   // 指令1释放掩码标志
    .free_id_inst1_i(rob_free_snap_id_inst1_o),               // 指令1释放id
    // from regs
    .reg_rdata1_i(regs_div_rdata1_o),          // 寄存器1读数据
    .reg_rdata2_i(regs_div_rdata2_o),          // 寄存器2读数据
    // to issue
    .flush_o(div_flush_o),
    .stall_o(div_stall_o),
    // to regs
    .rf_raddr1_o(div_rf_raddr1_o),           // RF 阶段读寄存器1地址（同时传到转发模块）
    .rf_raddr2_o(div_rf_raddr2_o),           // RF 阶段读寄存器2地址（同时传到转发模块）
    .reg_wflag_o(div_reg_wflag_o),                 // 写回阶段写寄存器标志
    .reg_waddr_o(div_reg_waddr_o),           // 写回阶段写寄存器地址
    .reg_wdata_o(div_reg_wdata_o),          // 写回阶段写寄存器数据
    .ex_wflag_o(div_ex_wflag_o),                  // 执行阶段写寄存器标志
    .ex_waddr_o(div_ex_waddr_o),            // 执行阶段写寄存器地址(同时传到wb)
    // to ROB
    .complete_flag_o(div_complete_flag_o),             // 指令完成标志
    .commit_rob_id_o(div_commit_rob_id_o)        // 提交ROB id
);
`endif

// Forwarding_Unit
Forwarding_Unit u_Forwarding_Unit(
    // from RF
    // from ALU_0
    .alu0_rf_raddr1_i(alu0_rf_raddr1_o),     // ALU_0 RF阶段读寄存器1地址
    .alu0_rf_raddr2_i(alu0_rf_raddr2_o),     // ALU_0 RF阶段读寄存器2地址
    // from ALU_1
    .alu1_rf_raddr1_i(alu1_rf_raddr1_o),     // ALU_1 RF阶段读寄存器1地址
    .alu1_rf_raddr2_i(alu1_rf_raddr2_o),     // ALU_1 RF阶段读寄存器2地址
    // from mem
    .mem_rf_raddr1_i(lsu_rf_raddr1_o),      // mem RF阶段读寄存器1地址
    .mem_rf_raddr2_i(lsu_rf_raddr2_o),      // mem RF阶段读寄存器2地址
    // from branch
    .branch_rf_raddr1_i(br_rf_raddr1_o),   // branch RF阶段读寄存器1地址
    .branch_rf_raddr2_i(br_rf_raddr2_o),   // branch RF阶段读寄存器2地址
`ifdef use_m_extension
    // from mul
    .mul_rf_raddr1_i(mul_rf_raddr1_o),       // mul RF阶段读寄存器1地址
    .mul_rf_raddr2_i(mul_rf_raddr2_o),       // mul RF阶段读寄存器2地址
    // from div
    .div_rf_raddr1_i(div_rf_raddr1_o),       // div RF阶段读寄存器1地址
    .div_rf_raddr2_i(div_rf_raddr2_o),       // div RF阶段读寄存器2地址
`endif
    // from ex
    // from ALU_0
    .alu0_exe_waddr_i(alu0_exe_waddr_o),     // ALU_0 执行阶段写寄存器地址
    .alu0_exe_wdata_i(alu0_exe_wdata_o),     // ALU_0 执行阶段写寄存器数据
    // from ALU_1
    .alu1_exe_waddr_i(alu1_exe_waddr_o),     // ALU_1 执行阶段写寄存器地址
    .alu1_exe_wdata_i(alu1_exe_wdata_o),     // ALU_1 执行阶段写寄存器数据
    // from mem
    .mem_exe_waddr_i(lsu_mem_reg_waddr_o),      // mem 执行阶段写寄存器地址
    .mem_exe_wdata_i(lsu_mem_reg_wdata_o),      // mem 执行阶段写寄存器数据
// `ifdef use_m_extension
//     // from mul
//     .mul_exe_waddr_i,      // mul 执行阶段写寄存器地址
//     .mul_exe_wdata_i,      // mul 执行阶段写寄存器数据
// `endif
    // to RF
    // to ALU_0
    .alu0_rs1_forward_flag_o(alu0_rs1_forward_flag_o),           // ALU_0 rs1转发标志
    .alu0_rs1_forward_data_o(alu0_rs1_forward_data_o),    // ALU_0 rs1转发数据
    .alu0_rs2_forward_flag_o(alu0_rs2_forward_flag_o),           // ALU_0 rs2转发标志
    .alu0_rs2_forward_data_o(alu0_rs2_forward_data_o),    // ALU_0 rs2转发数据
    // to ALU_1
    .alu1_rs1_forward_flag_o(alu1_rs1_forward_flag_o),           // ALU_1 rs1转发标志
    .alu1_rs1_forward_data_o(alu1_rs1_forward_data_o),    // ALU_1 rs1转发数据
    .alu1_rs2_forward_flag_o(alu1_rs2_forward_flag_o),           // ALU_1 rs2转发标志
    .alu1_rs2_forward_data_o(alu1_rs2_forward_data_o),    // ALU_1 rs2转发数据
    // to mem
    .mem_rs1_forward_flag_o(mem_rs1_forward_flag_o),            // mem rs1转发标志
    .mem_rs1_forward_data_o(mem_rs1_forward_data_o),     // mem rs1转发数据
    .mem_rs2_forward_flag_o(mem_rs2_forward_flag_o),            // mem rs2转发标志
    .mem_rs2_forward_data_o(mem_rs2_forward_data_o),     // mem rs2转发数据
    // to branch
    .branch_rs1_forward_flag_o(branch_rs1_forward_flag_o),         // branch rs1转发标志
    .branch_rs1_forward_data_o(branch_rs1_forward_data_o),  // branch rs1转发数据
    .branch_rs2_forward_flag_o(branch_rs2_forward_flag_o),         // branch rs2转发标志
    .branch_rs2_forward_data_o(branch_rs2_forward_data_o)   // branch rs2转发数据
`ifdef use_m_extension
    // to mul
    ,.mul_rs1_forward_flag_o(mul_rs1_forward_flag_o),           // mul rs1转发标志
    .mul_rs1_forward_data_o(mul_rs1_forward_data_o),     // mul rs1转发数据
    .mul_rs2_forward_flag_o(mul_rs2_forward_flag_o),            // mul rs2转发标志
    .mul_rs2_forward_data_o(mul_rs2_forward_data_o),     // mul rs2转发数据
    // to div
    .div_rs1_forward_flag_o(div_rs1_forward_flag_o),            // div rs1转发标志
    .div_rs1_forward_data_o(div_rs1_forward_data_o),     // div rs1转发数据
    .div_rs2_forward_flag_o(div_rs2_forward_flag_o),            // div rs2转发标志
    .div_rs2_forward_data_o(div_rs2_forward_data_o)      // div rs2转发数据
`endif
);

// 物理寄存器文件
regs u_regs(
    .clk(clk),
    .rst(rst),
    // from ALU0
    .alu0_exe_wflag_i(alu0_rf_wflag_o),         // 执行阶段写寄存器标志
    .alu0_exe_waddr_i(alu0_rf_waddr_o),   // 执行阶段写寄存器地址
    .alu0_wflag_i(alu0_reg_wflag_o),             // 写回阶段写寄存器标志
    .alu0_waddr_i(alu0_reg_waddr_o),       // 写回阶段写寄存器地址
    .alu0_wdata_i(alu0_reg_wdata_o),      // 写回阶段写寄存器数据
    // from ALU1
    .alu1_exe_wflag_i(alu1_rf_wflag_o),         // 执行阶段写寄存器标志
    .alu1_exe_waddr_i(alu1_rf_waddr_o),   // 执行阶段写寄存器地址
    .alu1_wflag_i(alu1_reg_wflag_o),             // 写回阶段写寄存器标志
    .alu1_waddr_i(alu1_reg_waddr_o),       // 写回阶段写寄存器地址
    .alu1_wdata_i(alu1_reg_wdata_o),      // 写回阶段写寄存器数据
    // from branch
    .branch_rf_wflag_i(br_rf_wflag_o),            // 读寄存器文件阶段写寄存器标志
    .branch_rf_waddr_i(br_rf_waddr_o),      // 读寄存器文件阶段写寄存器地址
    .branch_wflag_i(br_reg_wflag_o),               // 写回阶段写寄存器标志
    .branch_waddr_i(br_reg_waddr_o),         // 写回阶段写寄存器地址
    .branch_wdata_i(br_reg_wdata_o),        // 写回阶段写寄存器数据
    // from mem
    .mem_exe_wflag_i(lsu_mem_reg_wflag_o),           // 执行阶段写寄存器标志
    .mem_exe_waddr_i(lsu_mem_reg_waddr_o),     // 执行阶段写寄存器地址
    .mem_wflag_i(lsu_reg_wflag_o),               // 写回阶段写寄存器标志
    .mem_waddr_i(lsu_reg_waddr_o),         // 写回阶段写寄存器地址
    .mem_wdata_i(lsu_reg_wdata_o),        // 写回阶段写寄存器数据
`ifdef use_m_extension
    // from mul
    .mul_exe_wflag_i(mul_ex_wflag_o),           // 执行阶段写寄存器标志
    .mul_exe_waddr_i(mul_ex_waddr_o),     // 执行阶段写寄存器地址
    .mul_wflag_i(mul_reg_wflag_o),               // 写回阶段写寄存器标志
    .mul_waddr_i(mul_reg_waddr_o),         // 写回阶段写寄存器地址
    .mul_wdata_i(mul_reg_wdata_o),        // 写回阶段写寄存器数据
    // from div
    .div_exe_wflag_i(div_ex_wflag_o),           // 执行阶段写寄存器标志
    .div_exe_waddr_i(div_ex_waddr_o),     // 执行阶段写寄存器地址
    .div_wflag_i(div_reg_wflag_o),               // 写回阶段写寄存器标志
    .div_waddr_i(div_reg_waddr_o),         // 写回阶段写寄存器地址
    .div_wdata_i(div_reg_wdata_o),        // 写回阶段写寄存器数据
`endif
    // from RF
    // from ALU_iss_que
    .alu_inst0_raddr1_i(alu0_rf_raddr1_o),      // 读寄存器1地址
    .alu_inst0_raddr2_i(alu0_rf_raddr2_o),      // 读寄存器2地址
    .alu_inst1_raddr1_i(alu1_rf_raddr1_o),      // 读寄存器1地址
    .alu_inst1_raddr2_i(alu1_rf_raddr2_o),      // 读寄存器2地址
    // from branch_iss_que
    .branch_raddr1_i(br_rf_raddr1_o),         // 读寄存器1地址
    .branch_raddr2_i(br_rf_raddr2_o),         // 读寄存器2地址
    // from mem_iss_que
    .mem_raddr1_i(lsu_rf_raddr1_o),            // 读寄存器1地址
    .mem_raddr2_i(lsu_rf_raddr2_o),            // 读寄存器2地址
`ifdef use_m_extension
    // from mul_iss_que
    .mul_raddr1_i(mul_rf_raddr1_o),            // 读寄存器1地址
    .mul_raddr2_i(mul_rf_raddr2_o),            // 读寄存器2地址
    // from div_iss_que
    .div_raddr1_i(div_rf_raddr1_o),            // 读寄存器1地址
    .div_raddr2_i(div_rf_raddr2_o),            // 读寄存器2地址
`endif
    // from commit
    .csr_raddr_i(rob_reg_raddr_o),             // CSR指令在提交阶段才读取执行结果，所以CSR寄存器的读地址由commit阶段提供
    .csr_wflag_i(rob_reg_wflag_o),                   // CSR指令写回阶段写寄存器标志
    .csr_waddr_i(rob_reg_waddr_o),             // CSR指令写回阶段写寄存器地址
    .csr_wdata_i(rob_reg_wdata_o),            // CSR指令写回阶段写寄存器数据
    // from rename
    .alloc_flag_inst0_i(rn_alloc_flag_inst0_o),             // Inst0是否分配物理寄存器
    .alloc_paddr_inst0_i(rn_pwaddr_inst0_o),      // Inst0分配的物理寄存器地址
    .alloc_flag_inst1_i(rn_alloc_flag_inst1_o),             // Inst1是否分配物理寄存器
    .alloc_paddr_inst1_i(rn_pwaddr_inst1_o),      // Inst1分配的物理寄存器地址
    // to commit
    .csr_rdata_o(regs_csr_rdata_o),       // CSR指令读RS1数据
    // to RF
    .ready_flag_o(regs_ready_flag_o),              // 寄存器就绪标志，位0-63分别对应物理寄存器0-63
    .alu_inst0_rdata1_o(regs_alu_inst0_rdata1_o),    // 读寄存器1数据
    .alu_inst0_rdata2_o(regs_alu_inst0_rdata2_o),    // 读寄存器2数据
    .alu_inst1_rdata1_o(regs_alu_inst1_rdata1_o),    // 读寄存器1数据
    .alu_inst1_rdata2_o(regs_alu_inst1_rdata2_o),    // 读寄存器2数据
    .branch_rdata1_o(regs_branch_rdata1_o),       // 读寄存器1数据
    .branch_rdata2_o(regs_branch_rdata2_o),       // 读寄存器2数据
    .mem_rdata1_o(regs_mem_rdata1_o),          // 读寄存器1数据
    .mem_rdata2_o(regs_mem_rdata2_o)           // 读寄存器2数据
`ifdef use_m_extension
    ,.mul_rdata1_o(regs_mul_rdata1_o),         // 读寄存器1数据
    .mul_rdata2_o(regs_mul_rdata2_o),          // 读寄存器2数据
    .div_rdata1_o(regs_div_rdata1_o),          // 读寄存器1数据
    .div_rdata2_o(regs_div_rdata2_o)           // 读寄存器2数据
`endif
);

// ROB
ROB u_ROB(
    .clk(clk),
    .rst(rst),
    // from dispatch
    .inst_addr_i(rn_dp_inst_addr_o),                   // 指令地址
    .inst_type_port0_i(rn_dp_inst_type_port0_o),              // 指令类型
    .inst_type_port1_i(rn_dp_inst_type_port1_o),              // 指令类型
    .inst_subtype_port0_i(rn_dp_inst_subtype_port0_o),           // 指令子类型
    .inst_subtype_port1_i(rn_dp_inst_subtype_port1_o),           // 指令子类型
    .op2_src_port0_i(rn_dp_op2_src_port0_o),                // 操作数2来源选择
    .op2_src_port1_i(rn_dp_op2_src_port1_o),                // 操作数2来源选择
    .csr_addr_port0_i(rn_dp_csr_addr_port0_o),              // CSR寄存器地址
    .csr_addr_port1_i(rn_dp_csr_addr_port1_o),              // CSR寄存器地址
    .reg_waddr_port0_i(rn_dp_reg_waddr_port0_o),              // 写通用寄存器地址
    .reg_waddr_port1_i(rn_dp_reg_waddr_port1_o),              // 写通用寄存器地址
    .inst_valid_port0_i(rn_dp_inst_valid_port0_o),                   // 指令有效标志
    .inst_valid_port1_i(rn_dp_inst_valid_port1_o),                   // 指令有效标志
    .imm_port0_i(rn_dp_imm_port0_o),                   // 立即数
    .imm_port1_i(rn_dp_imm_port1_o),                   // 立即数
    .praddr1_inst0_i(rn_dp_praddr1_inst0_o),        // 指令0物理寄存器1读地址
    .praddr1_inst1_i(rn_dp_praddr1_inst1_o),        // 指令1物理寄存器1读地址
    .pwaddr_inst0_i(rn_dp_pwaddr_inst0_o),         // 指令0物理寄存器写地址
    .pwaddr_inst1_i(rn_dp_pwaddr_inst1_o),         // 指令1物理寄存器写地址
    .branch_mask_inst0_i(rn_dp_branch_mask_inst0_o),    // 指令0分支掩码
    .branch_mask_inst1_i(rn_dp_branch_mask_inst1_o),    // 指令1分支掩码
    .snap_id_inst0_i(rn_dp_snap_id_inst0_o),        // 指令0快照id
    .snap_id_inst1_i(rn_dp_snap_id_inst1_o),        // 指令1快照id
    .old_paddr_inst0_i(rn_dp_old_paddr_inst0_o),      // 指令0旧的物理寄存器映射
    .old_paddr_inst1_i(rn_dp_old_paddr_inst1_o),      // 指令1旧的物理寄存器映射
    // from clint
    .int_flag_i(clint_int_flag_o),                   // 中断标志
    .int_w_disable_i(clint_int_w_disable_o),              // 中断发生时禁止写内存和CSR寄存器
    // from issue
    .stall_i(iss_stall_rob_o),
    // from branch
    .jump_flag_i(br_jump_flag_o),                  // 跳转标志
    .kill_mask_id_i(br_kill_mask_id_o),            // 分支掩码id
    // from mem
    .stall_store(lsu_stall_store),                 // store指令暂停标志
    // from ex
    .alu0_complete_flag_i(alu0_complete_flag_o),             // ALU_0指令完成标志
    .alu0_commit_rob_id_i(alu0_commit_rob_id_o),       // ALU_0提交ROB id
    .alu1_complete_flag_i(alu1_complete_flag_o),             // ALU_1指令完成标志
    .alu1_commit_rob_id_i(alu1_commit_rob_id_o),       // ALU_1提交ROB id
    .br_complete_flag_i(br_complete_flag_o),               // branch指令完成标志
    .br_commit_rob_id_i(br_commit_rob_id_o),         // branch提交ROB id
    .store_complete_flag_i(store_complete_flag_o),            // store指令完成标志
    .store_commit_rob_id_i(store_commit_rob_id_o),      // store提交ROB id
    .load_complete_flag_i(load_complete_flag_o),             // load指令完成标志
    .load_commit_rob_id_i(load_commit_rob_id_o),       // load提交ROB id
    `ifdef use_m_extension
    .mul_complete_flag_i(mul_complete_flag_o),              // mul指令完成标志
    .mul_commit_rob_id_i(mul_commit_rob_id_o),        // mul提交ROB id
    .div_complete_flag_i(div_complete_flag_o),              // div指令完成标志
    .div_commit_rob_id_i(div_commit_rob_id_o),        // div提交ROB id
    `endif
    // from csr_reg
    .csr_rdata_i(csr_data_o),               // CSR寄存器读数据
    // from regs
    .reg1_rdata_i(regs_csr_rdata_o),              // 通用寄存器1读数据
    // to clint
    .int_ready_flag_o(rob_int_ready_flag_o),                   // 中断准备好标志
    .mret_inst_addr_o(rob_mret_inst_addr_o),            // mret指令的返回地址（mepc寄存器的值）
    .exception_flag_o(rob_exception_flag_o),               // 异常发生标志
    .exception_cause_o(rob_exception_cause_o),       // 异常编号
    .mret_flag_o(rob_mret_flag_o),                    // 中断返回标志
    // to pipeline
    .stall_o(rob_stall_o),
    // to issue
    .sq_commit_cnt_o(rob_sq_commit_cnt_o),             // store queue提交数量
    .rob_id_inst0_o(rob_id_inst0_o),              // 指令0 ROB id
    .rob_id_inst1_o(rob_id_inst1_o),              // 指令1 ROB id
    // to mem
    .commit_store_flag_o(rob_commit_store_flag_o),             // 提交store指令标志
    // to peripheral
    .perip_wen(perip_wen),
    // to dcache
    .dcache_wen(rob_dcache_wen),
    // to csr_reg
    .csr_reg_wflag_o(rob_csr_reg_wflag_o),
    .csr_reg_addr_o(rob_csr_reg_addr_o),
    .csr_reg_wdata_o(rob_csr_reg_wdata_o),
    // to regs
    .reg_raddr_o(rob_reg_raddr_o),                 // CSR指令在提交阶段才读取执行结果，所以CSR寄存器的读地址由commit阶段提供
    .reg_wflag_o(rob_reg_wflag_o),                   // CSR指令写回阶段写寄存器标志
    .reg_waddr_o(rob_reg_waddr_o),                 // CSR指令写回阶段写寄存器地址
    .reg_wdata_o(rob_reg_wdata_o),            // CSR指令写回阶段写寄存器数据
    // to rename
    .free_snap_flag_inst0_o(rob_free_snap_flag_inst0_o),         // 指令0释放快照标志
    .free_snap_flag_inst1_o(rob_free_snap_flag_inst1_o),         // 指令1释放快照标志
    // 释放 ID，用于清理内部 Mask
    .free_snap_id_inst0_o(rob_free_snap_id_inst0_o),     
    .free_snap_id_inst1_o(rob_free_snap_id_inst1_o),
    .commit_inst0_o(rob_commit_inst0_o),                 // 指令0提交使能
    .waddr_commit0_o(rob_waddr_commit0_o),              // 提交指令的目标逻辑寄存器
    .paddr_commit0_o(rob_paddr_commit0_o),              // 提交指令的目标物理寄存器(成为架构状态)
    .free_paddr_inst0_o(rob_free_paddr_inst0_o),           // 释放的物理寄存器地址
    .commit_inst1_o(rob_commit_inst1_o),                 // 指令1提交使能
    .waddr_commit1_o(rob_waddr_commit1_o),              // 提交指令的目标逻辑寄存器
    .paddr_commit1_o(rob_paddr_commit1_o),              // 提交指令的目标物理寄存器(成为架构状态)
    .free_paddr_inst1_o(rob_free_paddr_inst1_o)            // 释放的物理寄存器地址
);

// CSR寄存器模块
csr_reg u_csr_reg(
    .clk(clk),
    .rst(rst),
    // from id
    .raddr_i(rob_csr_reg_addr_o),        
    // from ex
    .we_i(rob_csr_reg_wflag_o),               
    .waddr_i(rob_csr_reg_addr_o),       
    .data_i(rob_csr_reg_wdata_o),         
    // from clint
    .mepc_we_i(clint_mepc_we_o),                     // 写mepc寄存器标志
    .mstatus_we_i(clint_mstatus_we_o),                  // 写mstatus寄存器标志
    .mcause_we_i(clint_mcause_we_o),                   // 写mcause寄存器标志
    .mip_we_i(clint_mip_we_o),                      // 写mip寄存器标志
    .mepc_wdata_i(clint_mepc_wdata_o),           // 写mepc寄存器数据
    .mstatus_wdata_i(clint_mstatus_wdata_o),        // 写mstatus寄存器数据
    .mcause_wdata_i(clint_mcause_wdata_o),         // 写mcause寄存器数据
    .mip_wdata_i(clint_mip_wdata_o),            // 写mepc寄存器数据
    .uart_int_clear(clint_uart_int_clear),                // MIP外部中断位清零
    .timer_int_clear(clint_timer_int_clear),               // MIP定时器中断位清零
    // to clint
    .global_int_en_o(csr_global_int_en_o),             
    .mie_MEIE(csr_mie_MEIE),                     
    .mie_MTIE(csr_mie_MTIE),                   
    .mip_MEIP(csr_mip_MEIP),                    
    .mip_MTIP(csr_mip_MTIP),                     
    .clint_csr_mtvec(csr_clint_csr_mtvec),     
    .clint_csr_mepc(csr_clint_csr_mepc),     
    .clint_csr_mstatus(csr_clint_csr_mstatus),     
    // to id
    .data_o(csr_data_o)         
);

clint u_clint(
    .clk(clk),
    .rst(rst),
    // from uart
    .uart_int_i(uart_int_flag),          // 串口外部中断输入信号
    // from timer
    .timer_int_i(timer_int_flag),        // 定时器中断输入信号
    // from commit
    .exception_flag_i(rob_exception_flag_o),              // 异常标志
    .exception_cause_i(rob_exception_cause_o),      // 异常编号
    .mret_flag_i(rob_mret_flag_o),                   // 中断返回标志
    // from rob
    .inst_ready_flag_i(rob_int_ready_flag_o),
    .rob_inst_addr_i(rob_mret_inst_addr_o),       // 指令地址
    // from csr_reg
    .csr_mtvec(csr_clint_csr_mtvec),           
    .csr_mepc(csr_clint_csr_mepc),            
    .csr_mstatus(csr_clint_csr_mstatus),           
    .global_int_en_i(csr_global_int_en_o),           
    .mie_MEIE(csr_mie_MEIE),                    
    .mie_MTIE(csr_mie_MTIE),                  
    .mip_MEIP(csr_mip_MEIP),                 
    .mip_MTIP(csr_mip_MTIP),           
    // to csr_reg
    .mepc_we_o(clint_mepc_we_o),                   
    .mstatus_we_o(clint_mstatus_we_o),                 
    .mcause_we_o(clint_mcause_we_o),                 
    .mip_we_o(clint_mip_we_o),                     
    .mepc_wdata_o(clint_mepc_wdata_o),         
    .mstatus_wdata_o(clint_mstatus_wdata_o),       
    .mcause_wdata_o(clint_mcause_wdata_o),        
    .mip_wdata_o(clint_mip_wdata_o),            
    .uart_int_clear(clint_uart_int_clear),               
    .timer_int_clear(clint_timer_int_clear),              
    // to PC
    .int_addr_o(clint_int_addr_o),
    // to ROB
    .int_w_disable_o(clint_int_w_disable_o),               // 中断发生时禁止写内存和CSR寄存器
    // to pipeline
    .int_flag_o(clint_int_flag_o)                 
);




endmodule