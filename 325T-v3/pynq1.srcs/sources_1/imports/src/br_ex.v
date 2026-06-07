`include "defines.vh"

`timescale 1ns / 1ps

module br_ex (
    // from RF
    input br_inst_valid_i,              // branch指令有效标志
    input [15:0] br_inst_addr_i,        // branch指令地址
    input [5:0] br_rob_id_i,            // branch ROB id
    input br_bpu_pre_flag_i,            // branch BPU预测标志
    input [31:0] br_bpu_pre_addr_i,     // branch BPU预测地址
    input [3:0] br_mask_i,              // branch分支掩码
    input [2:0] br_ras_ptr_i,           // branch RAS快照指针
    input [2:0] br_mem_wr_ptr_i,        // branch mem队列写操作快照指针
    input [2:0] br_sq_ptr_i,            // branch store queue快照指针
    input [1:0] br_snap_id_i,           // branch快照id
    input [2:0] br_type_i,              // branch指令类型
    input [3:0] br_subtype_i,           // branch指令子类型
    input [31:0] br_rs1_data_i,         // rs1数据
    input [31:0] br_rs2_data_i,         // rs2数据
    input [5:0] br_waddr_i,             // RF 阶段写寄存器地址(同时传到issue阶段和ex阶段)
    input [31:0] br_imm_i,              // branch立即数
    input [31:0] br_aux_addr_i,         // branch辅助地址

    // from br_flush
    input jump_flag_i,                  // 跳转标志
    input [1:0] kill_mask_id_i,         // 分支掩码id

    // to pipeline
    output reg jump_flag_o,                 // 跳转标志
    output [1:0] kill_mask_id_o,            // 分支掩码id

    // to RAS
    output [2:0] ras_snap_ptr_o,              // RAS快照指针

    // to issue
    output [2:0] br_mem_wr_ptr_o,        // branch mem队列写操作快照指针
    output [2:0] br_sq_ptr_o,            // branch store queue快照指针

    // to PC
    output reg [31:0] jump_addr_o,          // 跳转地址(同时传到bpu_update_buffer)

    // to bpu_update_buffer
    output reg btb_update_en,                     // 执行阶段更新BTB使能
    output [15:0] ex_pc,                          // 执行阶段的pc
    output is_branch,                             // 是否为分支指令
    output reg lhp_update_en,                     // 更新使能
    output reg branch_taken,                      // 实际跳转结果(1为跳转)

    // to regs
    output reg_wflag_o,                 // 写寄存器标志
    output [5:0] reg_waddr_o,           // 写寄存器地址
    output reg [31:0] reg_wdata_o,      // 写寄存器数据

    // to flush
    output br_inst_valid_o,
    output [5:0] commit_rob_id_o        // 提交ROB id
);
// 冲刷逻辑
wire [3:0] kill_mask = jump_flag_i ? (4'b0001 << kill_mask_id_i) : 4'b0000;
assign br_inst_valid_o = br_inst_valid_i && ((br_mask_i & kill_mask) == 0); // 如果指令的掩码位被kill_mask覆盖，则无效

assign kill_mask_id_o = br_snap_id_i;
assign ras_snap_ptr_o = br_ras_ptr_i;
assign br_mem_wr_ptr_o = br_mem_wr_ptr_i;
assign br_sq_ptr_o = br_sq_ptr_i;
assign reg_wflag_o = br_inst_valid_i && (br_type_i == `TYPE_JAL);
assign reg_waddr_o = br_waddr_i;
assign ex_pc = br_inst_addr_i;
assign is_branch = (br_type_i == `TYPE_BR);
assign commit_rob_id_o = br_rob_id_i;
// 执行
always @(*) begin
    // 默认值
    jump_flag_o = 1'b0;
    jump_addr_o = 32'h0;
    lhp_update_en = 1'b0;
    branch_taken = 1'b0;
    btb_update_en = 1'b0;
    reg_wdata_o = 32'h0;

    if (br_inst_valid_o) begin
        case (br_type_i)
            `TYPE_JAL: begin
                if (br_subtype_i == `JUMP_JALR) begin // JALR
                    jump_flag_o = (br_rs1_data_i + br_imm_i != br_bpu_pre_addr_i);
                    jump_addr_o = br_rs1_data_i + br_imm_i;
                    btb_update_en = 1'b0;
                    reg_wdata_o = br_aux_addr_i;
                end
                else begin // JAL
                    jump_flag_o = 1'b0; // id已经冲刷
                    jump_addr_o = br_aux_addr_i;
                    btb_update_en = 1'b1;
                    reg_wdata_o = {16'h8000, br_inst_addr_i} + 32'h4;
                end
            end
            `TYPE_BR: begin
                lhp_update_en = 1'b1;
                case (br_subtype_i)
                    `BR_EQ: begin
                        `BRANCH_EX_LOGIC((br_rs1_data_i == br_rs2_data_i))
                    end
                    `BR_NE: begin
                        `BRANCH_EX_LOGIC((br_rs1_data_i != br_rs2_data_i))
                    end
                    `BR_LT: begin
                        `BRANCH_EX_LOGIC(($signed(br_rs1_data_i) < $signed(br_rs2_data_i)))
                    end
                    `BR_GE: begin
                        `BRANCH_EX_LOGIC(($signed(br_rs1_data_i) >= $signed(br_rs2_data_i)))
                    end
                    `BR_LTU: begin
                        `BRANCH_EX_LOGIC((br_rs1_data_i < br_rs2_data_i))
                    end
                    `BR_GEU: begin
                        `BRANCH_EX_LOGIC((br_rs1_data_i >= br_rs2_data_i))
                    end
                    default: begin
                        jump_flag_o = 1'b0;
                        jump_addr_o = 32'h0;
                        lhp_update_en = 1'b0;
                        branch_taken = 1'b0;
                        btb_update_en = 1'b0;
                        reg_wdata_o = 32'h0;
                    end
                endcase
            end
            default: begin
                jump_flag_o = 1'b0;
                jump_addr_o = 32'h0;
                lhp_update_en = 1'b0;
                branch_taken = 1'b0;
                btb_update_en = 1'b0;
                reg_wdata_o = 32'h0;
            end
        endcase
    end
    else begin
        jump_flag_o = 1'b0;
        jump_addr_o = 32'h0;
        lhp_update_en = 1'b0;
        branch_taken = 1'b0;
        btb_update_en = 1'b0;
        reg_wdata_o = 32'h0;
    end
end




endmodule