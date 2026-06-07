`include "defines.vh"

`timescale 1ns / 1ps

// 核心中断控制模块
module clint (
    input clk,
    input rst,

    // from uart
    input uart_int_i,         // 串口外部中断输入信号
    
    // from timer
    input timer_int_i,        // 定时器中断输入信号

    // from commit
    input exception_flag_i,              // 异常标志
    input [31:0] exception_cause_i,      // 异常编号
    input mret_flag_i,                   // 中断返回标志

    // from rob
    input inst_ready_flag_i,
    input [31:0] rob_inst_addr_i,       // 指令地址

    // from csr_reg
    input [31:0] csr_mtvec,             // mtvec寄存器
    input [31:0] csr_mepc,              // mepc寄存器
    input [31:0] csr_mstatus,           // mstatus寄存器

    input global_int_en_i,              // 全局中断使能标志
    input mie_MEIE,                     // 外部中断使能标志
    input mie_MTIE,                     // 定时器中断使能标志
    input mip_MEIP,                     // 外部中断挂起标志
    input mip_MTIP,                     // 定时器中断挂起标志

    // to csr_reg
    output reg mepc_we_o,                     // 写mepc寄存器标志
    output reg mstatus_we_o,                  // 写mstatus寄存器标志
    output reg mcause_we_o,                   // 写mcause寄存器标志
    output reg mip_we_o,                      // 写mip寄存器标志
    output reg [31:0] mepc_wdata_o,           // 写mepc寄存器数据
    output reg [31:0] mstatus_wdata_o,        // 写mstatus寄存器数据
    output reg [31:0] mcause_wdata_o,         // 写mcause寄存器数据
    output reg [31:0] mip_wdata_o,            // 写mip寄存器数据
    
    output uart_int_clear,                // MIP外部中断位清零
    output timer_int_clear,               // MIP定时器中断位清零

    // to PC
    output reg [31:0] int_addr_o,         // 中断入口地址

    // to ROB
    output int_w_disable_o,               // 中断发生时禁止写内存和CSR寄存器

    // to pipeline
    output int_flag_o                     // 中断标志
);

// 中断状态定义
localparam S_INT_IDLE            = 5'b00001;     // 空闲
localparam S_INT_SYNC_ASSERT     = 5'b00010;     // 同步异常
localparam S_INT_EXTERN_ASSERT   = 5'b00100;     // 外部中断
localparam S_INT_TIMER_ASSERT    = 5'b01000;     // 定时器中断
localparam S_INT_MRET            = 5'b10000;     // 中断返回

// 写CSR寄存器状态定义
localparam S_CSR_IDLE            = 3'b001;    // 空闲
localparam S_CSR_INT_W           = 3'b010;    // 中断时写mepc、mstatus、mcause
localparam S_CSR_MSTATUS_MRET    = 3'b100;    // 中断返回时写mstatus

reg[4:0] int_state;
reg[2:0] csr_state;
reg[31:0] inst_addr;
reg[31:0] cause;

assign int_flag_o = (int_state != S_INT_IDLE) | (csr_state != S_CSR_IDLE);
assign int_w_disable_o = global_int_en_i && ((mie_MEIE && mip_MEIP) || (mie_MTIE && mip_MTIP));

reg uart_int_i_d1, timer_int_i_d1;

// 捕获外设中断源的下降沿（中断清除时刻）
always @(posedge clk) begin
    uart_int_i_d1 <= uart_int_i;
    timer_int_i_d1 <= timer_int_i;
end

assign uart_int_clear = ~uart_int_i & uart_int_i_d1;  // 下降沿检测（中断清除）
assign timer_int_clear = ~timer_int_i & timer_int_i_d1;

// 中断检测并置位MIP
always @(*) begin
    mip_we_o = 1'b0;
    mip_wdata_o = 32'b0;
    if(uart_int_i) begin
        mip_we_o = 1'b1;
        mip_wdata_o[11] = 1'b1;
    end
    if(timer_int_i) begin
        mip_we_o = 1'b1;
        mip_wdata_o[7] = 1'b1;
    end
end

// reg [2:0] mret_cnt;
// reg mret_start;
// 中断仲裁逻辑
wire external_int_assert = inst_ready_flag_i && mie_MEIE && mip_MEIP && global_int_en_i;
wire timer_int_assert = inst_ready_flag_i && mie_MTIE && mip_MTIP && global_int_en_i;
always @(*) begin
    int_state = S_INT_IDLE;
    // 发生异常
    if(exception_flag_i) begin
        int_state = S_INT_SYNC_ASSERT;
    end
    // 外部中断
    else if(external_int_assert) begin
        int_state = S_INT_EXTERN_ASSERT;
    end
    // 定时器中断
    else if(timer_int_assert) begin
        int_state = S_INT_TIMER_ASSERT;
    end
    // 中断返回
    else if(mret_flag_i) begin
        int_state = S_INT_MRET;
    end
end

// 写CSR寄存器状态切换
always @ (posedge clk) begin
    if (!rst) begin
        csr_state <= S_CSR_IDLE;
        cause <= 32'b0;
        inst_addr <= 32'b0;
    end 
    else begin
        case (csr_state)
            S_CSR_IDLE: begin
                // 同步异常
                if (int_state == S_INT_SYNC_ASSERT) begin
                    cause <= exception_cause_i;
                    csr_state <= S_CSR_INT_W;
                    // 在ecall/ebreak中断处理函数里会将中断返回地址加4
                    inst_addr <= rob_inst_addr_i;
                end
                // 异步中断 
                // 串口中断
                else if(int_state == S_INT_EXTERN_ASSERT) begin
                    cause <= 32'h8000000b;
                    csr_state <= S_CSR_INT_W;
                    inst_addr <= rob_inst_addr_i;
                end
                // 定时器中断
                else if(int_state == S_INT_TIMER_ASSERT) begin
                    cause <= 32'h80000007;
                    csr_state <= S_CSR_INT_W;
                    inst_addr <= rob_inst_addr_i;
                end
                // 中断返回
                else if (int_state == S_INT_MRET) begin
                    csr_state <= S_CSR_MSTATUS_MRET;
                end
            end
            S_CSR_INT_W: begin
                csr_state <= S_CSR_IDLE;
            end
            S_CSR_MSTATUS_MRET: begin
                csr_state <= S_CSR_IDLE;
            end
            default: begin
                csr_state <= S_CSR_IDLE;
            end
        endcase
    end
end

// 发出中断信号前，先写几个CSR寄存器
always @ (*) begin
    mepc_we_o = 1'b0;
    mstatus_we_o = 1'b0;
    mcause_we_o = 1'b0;
    mepc_wdata_o = 32'b0;
    mstatus_wdata_o = 32'b0;
    mcause_wdata_o = 32'b0;

    case (csr_state)
        // 中断时写mepc、mstatus、mcause
        S_CSR_INT_W: begin
            mepc_we_o = 1'b1;
            mstatus_we_o = 1'b1;
            mcause_we_o = 1'b1;
            mepc_wdata_o = inst_addr;
            mstatus_wdata_o = {csr_mstatus[31:8], csr_mstatus[3], csr_mstatus[6:4], 1'b0, csr_mstatus[2:0]};  // 第七位MPIE保存原先的第三位MIE
            mcause_wdata_o = cause;
        end
        // 中断返回
        S_CSR_MSTATUS_MRET: begin
            mstatus_we_o = 1'b1;
            mstatus_wdata_o = {csr_mstatus[31:8], 1'b1, csr_mstatus[6:4], csr_mstatus[7], csr_mstatus[2:0]};
        end
        default: begin
            mepc_we_o = 1'b0;
            mstatus_we_o = 1'b0;
            mcause_we_o = 1'b0;
            mepc_wdata_o = 32'b0;
            mstatus_wdata_o = 32'b0;
            mcause_wdata_o = 32'b0;
        end
    endcase
end


// 发出中断入口地址
always @ (*) begin
    case (csr_state)
        S_CSR_INT_W: begin
            // 直接模式或发生的是异常
            if(csr_mtvec[0] == 0 || cause[31] == 0) begin
                int_addr_o = {csr_mtvec[31:2], 2'b0};
            end
            // 向量模式且发生的是中断
            else begin
                int_addr_o = {csr_mtvec[31:2], 2'b0} + cause[11:0] << 2;
            end
        end
        // 发出中断返回地址
        S_CSR_MSTATUS_MRET: begin
            int_addr_o = csr_mepc;
        end
        default: begin
            int_addr_o = 32'b0;
        end
    endcase
end


// always @(posedge clk or negedge rst) begin
//     if(!rst) begin
//         mret_cnt <= 3'd7;
//         mret_start <= 1'b0;
//     end
//     else if(csr_state == S_CSR_MSTATUS_MRET) begin
//         mret_cnt <= 3'd1;
//         mret_start <= 1'b1;
//     end
//     else if(mret_start) begin
//         if(mret_cnt == 6) begin
//             mret_cnt <= 3'd7;
//             mret_start <= 1'b0;
//         end
//         else begin
//             mret_cnt <= mret_cnt + 1;
//         end
//     end
// end



endmodule