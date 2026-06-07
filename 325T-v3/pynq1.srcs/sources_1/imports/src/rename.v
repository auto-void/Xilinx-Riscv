`include "defines.vh"

`timescale 1ns / 1ps

// 寄存器重命名模块
module rename(
    input clk,
    input rst,

    // from ctrl
    input int_flag_i,                  // 中断信号
    input flush_i,                     // 流水线冲刷信号
    input [1:0] restore_snap_id_i,     // 需要恢复的快照id
    input alloc_snap_inst0_i,          // 为指令0分配快照标志
    input alloc_snap_inst1_i,          // 为指令1分配快照标志

    // from id
    input inst0_valid_i,              // 指令0有效标志
    input inst1_valid_i,              // 指令1有效标志

    input [4:0] raddr1_inst0_i,       // 读寄存器1地址
    input [4:0] raddr2_inst0_i,       // 读寄存器2地址

    input [4:0] raddr1_inst1_i,       // 读寄存器1地址
    input [4:0] raddr2_inst1_i,       // 读寄存器2地址

    input [4:0] waddr_inst0_i,        // 目标寄存器地址
    input [4:0] waddr_inst1_i,        // 目标寄存器地址
    input wflag_inst0_i,              // 写寄存器标志
    input wflag_inst1_i,              // 写寄存器标志

    // from dispatch
    input stall_flag_i,               // RS/ROB满暂停

    // from commit
    input free_snap_flag_inst0_i,         // 指令0释放快照标志
    input free_snap_flag_inst1_i,         // 指令1释放快照标志

    // 释放 ID，用于清理内部 Mask
    input [1:0] free_snap_id_inst0_i,     
    input [1:0] free_snap_id_inst1_i,
    
    input commit_inst0_i,                 // 指令0提交使能
    input [4:0] waddr_commit0_i,          // 提交指令的目标逻辑寄存器
    input [5:0] paddr_commit0_i,          // 提交指令的目标物理寄存器(成为架构状态)
    input [5:0] free_paddr_inst0_i,       // 释放的物理寄存器地址

    input commit_inst1_i,                 // 指令1提交使能
    input [4:0] waddr_commit1_i,          // 提交指令的目标逻辑寄存器
    input [5:0] paddr_commit1_i,          // 提交指令的目标物理寄存器(成为架构状态)
    input [5:0] free_paddr_inst1_i,       // 释放的物理寄存器地址

    // to pipeline
    output stall_o,                          // 重命名阶段暂停信号

    // to RS
    output reg [5:0] praddr1_inst0_o,        // 物理寄存器1地址
    output reg [5:0] praddr2_inst0_o,        // 物理寄存器2地址

    output reg [5:0] praddr1_inst1_o,        // 物理寄存器1地址
    output reg [5:0] praddr2_inst1_o,        // 物理寄存器2地址

    output reg [5:0] pwaddr_inst0_o,         // 分配的物理寄存器地址
    output reg [5:0] pwaddr_inst1_o,         // 分配的物理寄存器地址

    output reg [3:0] branch_mask_inst0_o,    // 指令0携带的依赖掩码
    output reg [3:0] branch_mask_inst1_o,    // 指令1携带的依赖掩码

    // To ROB - 旧的物理映射 (用于提交时释放)
    output reg [5:0] old_paddr_inst0_o,
    output reg [5:0] old_paddr_inst1_o,

    // to regs
    output alloc_flag_inst0_o,             // Inst0是否分配物理寄存器
    output alloc_flag_inst1_o,             // Inst1是否分配物理寄存器

    // To Dispatch - 分配给当前分支指令的快照 ID (随指令流水线流动)
    output reg [1:0] snap_id_inst0_o,
    output reg [1:0] snap_id_inst1_o

);

    // 数据结构
    integer i;
    // RAT 映射表 (32个逻辑寄存器，64个物理寄存器，6位物理寄存器地址)
    reg [5:0] RAT[0:31];
    reg [5:0] committed_RAT[0:31];    // 提交映射表 (用于中断恢复)

    // 空闲列表 (Free List) - 环形 FIFO
    reg [5:0] free_list[0:31];
    reg [5:0] head_ptr;    // 分配指针 (Head)
    reg [5:0] tail_ptr;    // 回收指针 (Tail)
    
    // 资源计数器
    reg [5:0] free_cnt;           // 空闲物理寄存器数量

    // 快照存储 (4组备份)
    reg [5:0] rat_snapshots[0:3][0:31];
    reg [5:0] head_snapshots[0:3];

    // Mask 快照存储 (备份进入分支前的 Mask)
    reg [3:0] mask_snapshots[0:3];

    // 当前全局 Mask
    reg [3:0] current_mask;

    reg [1:0] next_alloc_ptr;   // 下一个可用快照 ID
    reg [2:0] active_snap_cnt;  // 当前活跃（已分配）的快照数量

    reg [1:0] next_snap_id_0;
    reg [1:0] next_snap_id_1;

    // 计算快照需求
    wire [1:0] req_snaps = alloc_snap_inst0_i + alloc_snap_inst1_i;

    // ID 分配逻辑
    always @(*) begin
        // 默认分配策略：顺序递增 (Ring)
        next_snap_id_0 = next_alloc_ptr;
        next_snap_id_1 = next_alloc_ptr + 1'b1; // 2位自动溢出回绕
        
        // 如果 Inst0 不需要，只有 Inst1 需要, 那么 Inst1 拿走 next_alloc_ptr 指向的那个 ID
        if (!alloc_snap_inst0_i && alloc_snap_inst1_i) begin
            next_snap_id_1 = next_alloc_ptr;
        end
    end

    // 计算物理寄存器需求 (0, 1, 2)
    wire need_p0 = inst0_valid_i && wflag_inst0_i && (waddr_inst0_i != 5'd0);
    wire need_p1 = inst1_valid_i && wflag_inst1_i && (waddr_inst1_i != 5'd0);
    wire [1:0] req_regs = need_p0 + need_p1;

    // 预取空闲寄存器
    wire [5:0] alloc_p0 = free_list[head_ptr[4:0]];
    wire [5:0] alloc_p1 = free_list[(head_ptr + 1'b1) & 5'b11111];

    // 计算提交回收量
    wire [1:0] retire_cnt = (commit_inst0_i && free_paddr_inst0_i != 0) + 
                            (commit_inst1_i && free_paddr_inst1_i != 0);

    // 没有空闲物理寄存器分配，快照资源不足或ROB满了时暂停前端不分配寄存器和快照
    // assign stall_o = (free_cnt < req_regs) || (req_snaps + active_snap_cnt > 4) || stall_flag_i;
    wire lack_regs = (req_regs == 2'd2) ? (free_cnt == 6'd0 || free_cnt == 6'd1) : 
                     (req_regs == 2'd1) ? (free_cnt == 6'd0) : 1'b0;

    wire lack_snaps = (req_snaps == 2'd2) ? (active_snap_cnt >= 3'd3) : 
                      (req_snaps == 2'd1) ? (active_snap_cnt >= 3'd4) : 1'b0;

    assign stall_o = lack_regs || lack_snaps || stall_flag_i;

    wire do_alloc = ~stall_o; // 有足够资源

    assign alloc_flag_inst0_o = need_p0 && ~lack_regs;
    assign alloc_flag_inst1_o = need_p1 && ~lack_regs;


    // 输出生成
    always @(*) begin
        // 分配新寄存器
        pwaddr_inst0_o = need_p0 ? alloc_p0 : 6'd0;
        // 如果 Inst0 占了一个，Inst1 就拿下一个；否则 Inst1 拿头一个
        pwaddr_inst1_o = need_p1 ? (need_p0 ? alloc_p1 : alloc_p0) : 6'd0;

        // 记录旧映射 (提交时释放用)
        old_paddr_inst0_o = need_p0 ? RAT[waddr_inst0_i] : 6'd0;
        old_paddr_inst1_o = need_p1 ? ((need_p0 && waddr_inst0_i == waddr_inst1_i) ? alloc_p0 : RAT[waddr_inst1_i]) : 6'd0;

        // 源寄存器映射与旁路
        // Inst0 Sources
        praddr1_inst0_o = RAT[raddr1_inst0_i];
        praddr2_inst0_o = RAT[raddr2_inst0_i];

        // Inst1 Sources (必须检查对 Inst0 的依赖)
        // Check Src1
        if (need_p0 && (raddr1_inst1_i == waddr_inst0_i))
            praddr1_inst1_o = alloc_p0;    // 旁路：直接拿 Inst0 刚分到的新物理号
        else
            praddr1_inst1_o = RAT[raddr1_inst1_i];

        // Check Src2
        if (need_p0 && (raddr2_inst1_i == waddr_inst0_i))
            praddr2_inst1_o = alloc_p0;
        else
            praddr2_inst1_o = RAT[raddr2_inst1_i];

        // 快照 ID 输出
        // 指令携带分配到的 ID 走下去
        snap_id_inst0_o = next_snap_id_0;
        snap_id_inst1_o = next_snap_id_1;

        // Inst0 Mask: 继承当前环境
        branch_mask_inst0_o = current_mask;
        if (free_snap_flag_inst0_i) branch_mask_inst0_o[free_snap_id_inst0_i] = 1'b0; // 释放快照时，强制清除对应位
        if (free_snap_flag_inst1_i) branch_mask_inst0_o[free_snap_id_inst1_i] = 1'b0;

        // Inst1 Mask: 继承中间环境
        if (alloc_snap_inst0_i)
            branch_mask_inst1_o = current_mask | (4'b1 << next_snap_id_0);
        else
            branch_mask_inst1_o = current_mask;
        if (free_snap_flag_inst0_i) branch_mask_inst1_o[free_snap_id_inst0_i] = 1'b0; // 释放快照时，强制清除对应位
        if (free_snap_flag_inst1_i) branch_mask_inst1_o[free_snap_id_inst1_i] = 1'b0;
    end


    // 状态更新
    // 保存RAT快照用
    reg [5:0] rat_after_inst0[0:31]; // 指令0执行完后的RAT状态
    reg [5:0] rat_after_inst1[0:31]; // 指令1执行完后的RAT状态
    always @(*) begin
        // i=0的情况特殊处理：始终保持映射为0
        rat_after_inst0[0] = 6'd0;
        rat_after_inst1[0] = 6'd0;
        
        for (i = 1; i < 32; i = i + 1) begin
            // 计算指令 0 执行后的状态
            if (need_p0 && waddr_inst0_i == i[4:0]) 
                rat_after_inst0[i] = alloc_p0;
            else 
                rat_after_inst0[i] = RAT[i];

            // 计算指令 1 执行后的状态
            if (need_p1 && waddr_inst1_i == i[4:0])
                rat_after_inst1[i] = need_p0 ? alloc_p1 : alloc_p0;
            else if (need_p0 && waddr_inst0_i == i[4:0])
                rat_after_inst1[i] = alloc_p0;
            else 
                rat_after_inst1[i] = RAT[i];
        end
    end
    // 时序逻辑更新
    wire [1:0] rollback_dist = next_alloc_ptr - restore_snap_id_i - 1'b1; // 计算回滚步数 (在环上的距离)
    // 计算本周期释放了几个快照 (Commit阶段)
    wire [1:0] total_release_snaps = (free_snap_flag_inst0_i ? 1'b1 : 1'b0) + 
                                     (free_snap_flag_inst1_i ? 1'b1 : 1'b0);
    
    // 掩码更新临时变量
    reg [3:0] mask_alloc_update;
    reg [3:0] mask_final_update;
    always @(*) begin
        mask_alloc_update = current_mask;
        // 分配
        if (do_alloc) begin
            if (alloc_snap_inst1_i)
                mask_alloc_update = branch_mask_inst1_o | (4'b1 << next_snap_id_1);
            else if (alloc_snap_inst0_i)
                mask_alloc_update = branch_mask_inst1_o;
            else
                mask_alloc_update = current_mask;
        end
        mask_final_update = mask_alloc_update;
        // 释放
        if (free_snap_flag_inst0_i) mask_final_update[free_snap_id_inst0_i] = 1'b0; // 强制清某一位
        if (free_snap_flag_inst1_i) mask_final_update[free_snap_id_inst1_i] = 1'b0;
    end
    
    // 冲刷恢复mask
    reg [3:0] younger_mask; // 晚辈掩码
    integer j;
    always @(*) begin
        younger_mask = 4'b0;
        // 遍历所有 4 个槽位
        for (j = 0; j < 4; j = j + 1) begin
            // 判断 j 是否属于 (restore_id, next_alloc_ptr) 这一段环形区间（开区间）
            if (next_alloc_ptr > restore_snap_id_i) begin
                // 正常情况：区间在 [restore+1, next-1]
                if (j > restore_snap_id_i && j < next_alloc_ptr)
                    younger_mask[j] = 1'b1;
            end 
            else begin
                // 回绕情况：区间在 [restore+1, 3] U [0, next-1]
                if (j > restore_snap_id_i || j < next_alloc_ptr)
                    younger_mask[j] = 1'b1;
            end
        end
    end
    reg [3:0] mask_restored;
    always @(*) begin
        // 先计算基本的恢复值
        mask_restored = (mask_snapshots[restore_snap_id_i] & current_mask) & (~younger_mask);

        // 叠加当前周期的提交释放（拉低）
        if (free_snap_flag_inst0_i) mask_restored[free_snap_id_inst0_i] = 1'b0;
        if (free_snap_flag_inst1_i) mask_restored[free_snap_id_inst1_i] = 1'b0;
    end
    wire [5:0] restore_free_cnt = (head_snapshots[restore_snap_id_i] - tail_ptr);
    // 时序更新
    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                // 初始化 RAT (x0->p0, x1->p1...)
                RAT[i] <= i[5:0];    
                committed_RAT[i] <= i[5:0];
                // 初始化 Free List (p32-p63 空闲)
                free_list[i] <= i[5:0] + 6'd32;    
            end
            head_ptr <= 6'd0;     // 初始化分配指针
            tail_ptr <= 6'd0;     // 初始化回收指针
            free_cnt <= 6'd32;    // 初始32个空闲物理寄存器
            
            // 快照复位
            next_alloc_ptr <= 2'd0;
            active_snap_cnt <= 3'd0;
            current_mask <= 4'd0;
        end
        else if (int_flag_i) begin
            // 中断恢复 (最高优先级)
            // 将前端 RAT 强行覆盖为 后端 Committed RAT
            for (i = 1; i < 32; i = i + 1) RAT[i] <= committed_RAT[i];
            
            // 恢复空闲列表：Head 拉回 Tail
            head_ptr <= tail_ptr;
            free_cnt <= 6'd32;    // 回到满状态(32个真正空闲)

            // 释放所有快照
            next_alloc_ptr <= 2'd0;
            active_snap_cnt <= 3'd0;
            current_mask <= 4'd0;
        end
        else if (flush_i) begin
            // 分支预测错误恢复
            for (i = 1; i < 32; i = i + 1) RAT[i] <= rat_snapshots[restore_snap_id_i][i];
            
            head_ptr <= head_snapshots[restore_snap_id_i];

            free_cnt <= 6'd32 - restore_free_cnt  + {4'b0, retire_cnt};

            next_alloc_ptr <= restore_snap_id_i + 1'b1; // 提交释放当前分支快照，下一次分配当前分支的下一个ID，覆盖错误路径的分配
            current_mask <= mask_restored;
            active_snap_cnt <= active_snap_cnt - {1'b0, rollback_dist} - {1'b0, total_release_snaps};

            // 提交/回收逻辑
            // 更新 Committed RAT (中断时恢复用)
            if (commit_inst0_i && waddr_commit0_i != 0)
                committed_RAT[waddr_commit0_i] <= paddr_commit0_i;
            if (commit_inst1_i && waddr_commit1_i != 0)
                committed_RAT[waddr_commit1_i] <= paddr_commit1_i;

            // 回收寄存器 (Free List Update) - 用低5位索引
            if (commit_inst0_i && free_paddr_inst0_i != 0)
                free_list[tail_ptr[4:0]] <= free_paddr_inst0_i;
  
            if (commit_inst1_i && free_paddr_inst1_i != 0)
                free_list[(tail_ptr + ((commit_inst0_i && free_paddr_inst0_i != 0) ? 1'd1 : 1'd0)) & 5'b11111] <= free_paddr_inst1_i;

            tail_ptr <= tail_ptr + retire_cnt;    // 更新回收指针

        end
        else begin
            // 分配逻辑
            if (do_alloc) begin
                // 更新RAT
                if (need_p0) RAT[waddr_inst0_i] <= pwaddr_inst0_o;
                if (need_p1) RAT[waddr_inst1_i] <= pwaddr_inst1_o;
                // 更新分配指针
                head_ptr <= head_ptr + req_regs;

                // 更新快照
                // 快照保存
                if (alloc_snap_inst0_i) begin
                    mask_snapshots[next_snap_id_0] <= current_mask;
                    head_snapshots[next_snap_id_0] <= head_ptr + need_p0;
                    for(i = 0; i < 32; i = i + 1) rat_snapshots[next_snap_id_0][i] <= rat_after_inst0[i];

                    if (alloc_snap_inst1_i) begin
                        mask_snapshots[next_snap_id_1] <= branch_mask_inst1_o;
                        head_snapshots[next_snap_id_1] <= head_ptr + req_regs;
                        for(i = 0; i < 32; i = i + 1) rat_snapshots[next_snap_id_1][i] <= rat_after_inst1[i];
                    end
                end 
                else if (alloc_snap_inst1_i) begin
                    mask_snapshots[next_snap_id_1] <= branch_mask_inst1_o;
                    head_snapshots[next_snap_id_1] <= head_ptr + req_regs;
                    for(i = 0; i < 32; i = i + 1) rat_snapshots[next_snap_id_1][i] <= rat_after_inst1[i];
                end

                // 更新下一个分配指针
                if (alloc_snap_inst0_i && alloc_snap_inst1_i)
                    next_alloc_ptr <= next_alloc_ptr + 2'd2;
                else if (alloc_snap_inst0_i || alloc_snap_inst1_i)
                    next_alloc_ptr <= next_alloc_ptr + 1'b1;
            end

            // 更新全局 Mask
            current_mask <= mask_final_update;

            // 更新活跃快照计数器
            active_snap_cnt <= active_snap_cnt - {1'b0, total_release_snaps} + (do_alloc ? {1'b0, req_snaps} : 3'd0);


            // 提交/回收逻辑
            // 更新 Committed RAT (中断时恢复用)
            if (commit_inst0_i && waddr_commit0_i != 0)
                committed_RAT[waddr_commit0_i] <= paddr_commit0_i;
            if (commit_inst1_i && waddr_commit1_i != 0)
                committed_RAT[waddr_commit1_i] <= paddr_commit1_i;

            // 回收寄存器 (Free List Update) - 用低5位索引
            if (commit_inst0_i && free_paddr_inst0_i != 0)
                free_list[tail_ptr[4:0]] <= free_paddr_inst0_i;
  
            if (commit_inst1_i && free_paddr_inst1_i != 0)
                free_list[(tail_ptr + ((commit_inst0_i && free_paddr_inst0_i != 0) ? 1'd1 : 1'd0)) & 5'b11111] <= free_paddr_inst1_i;

            tail_ptr <= tail_ptr + retire_cnt;    // 更新回收指针
            free_cnt <= free_cnt + retire_cnt - (do_alloc ? req_regs : 0);    // 更新空闲计数器

        end
    end

    
    

endmodule