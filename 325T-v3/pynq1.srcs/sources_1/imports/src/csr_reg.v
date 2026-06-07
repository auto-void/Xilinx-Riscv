`include "defines.vh"

`timescale 1ns / 1ps

module csr_reg (
    input clk,
    input rst,

    // from id
    input [11:0] raddr_i,        // id模块读寄存器地址

    // from ex
    input we_i,                  // ex模块写寄存器标志
    input [11:0] waddr_i,        // ex模块写寄存器地址
    input [31:0] data_i,         // ex模块写寄存器数据

    // from clint
    // input [11:0] clint_raddr_i,        // clint模块读寄存器地址
    input mepc_we_i,                     // 写mepc寄存器标志
    input mstatus_we_i,                  // 写mstatus寄存器标志
    input mcause_we_i,                   // 写mcause寄存器标志
    input mip_we_i,                      // 写mip寄存器标志
    input [31:0] mepc_wdata_i,           // 写mepc寄存器数据
    input [31:0] mstatus_wdata_i,        // 写mstatus寄存器数据
    input [31:0] mcause_wdata_i,         // 写mcause寄存器数据
    input [31:0] mip_wdata_i,            // 写mepc寄存器数据

    input uart_int_clear,                // MIP外部中断位清零
    input timer_int_clear,               // MIP定时器中断位清零

    // to clint
    output global_int_en_o,              // 全局中断使能标志
    output mie_MEIE,                     // 外部中断使能标志
    output mie_MTIE,                     // 定时器中断使能标志
    output mip_MEIP,                     // 外部中断挂起标志
    output mip_MTIP,                     // 定时器中断挂起标志
    // output reg[31:0] clint_data_o,       // clint模块读寄存器数据
    output [31:0] clint_csr_mtvec,       // mtvec
    output [31:0] clint_csr_mepc,        // mepc
    output [31:0] clint_csr_mstatus,     // mstatus

    // to id
    output reg[31:0] data_o              // id模块读寄存器数据

);

// reg [63:0] cycle;
reg [31:0] mtvec;
reg [31:0] mcause;
reg [31:0] mepc;
reg [31:0] mie;
reg [31:0] mstatus;
reg [31:0] mscratch;
reg [31:0] mip;

assign global_int_en_o = mstatus[3];
assign mie_MEIE = mie[11];
assign mie_MTIE = mie[7];
assign mip_MEIP = mip[11];
assign mip_MTIP = mip[7];

assign clint_csr_mtvec = mtvec;
assign clint_csr_mepc = mepc;
assign clint_csr_mstatus = mstatus;

reg [31:0] mip_next;
always @(*) begin
    mip_next = mip;
    if (uart_int_clear)  mip_next[11] = 1'b0;                 // 清零UART中断位
    if (timer_int_clear) mip_next[7]  = 1'b0;                 // 清零定时器中断位
    if (mip_we_i)        mip_next = mip_next | mip_wdata_i;   // 置位
end

// cycle counter
// 复位释放后就一直计数
// always @ (posedge clk or negedge rst) begin
//     if (!rst) begin
//         cycle <= 64'b0;
//     end
//     else begin
//         cycle <= cycle + 1'b1;
//     end
// end

// 写
always @ (posedge clk) begin
    if (!rst) begin
        mtvec <= 32'b0;    // 后续由软件初始化为中断向量表起始地址
        mcause <= 32'b0;
        mepc <= 32'b0;
        mie <= 32'b0;
        mstatus <= 32'b0;
        mscratch <= 32'b0;
        mip <= 32'b0;
    end
    else begin
        // clint模块写操作
        mip <= mip_next;
        if (mepc_we_i) begin
            mepc <= mepc_wdata_i;
        end
        if (mstatus_we_i) begin
            mstatus <= mstatus_wdata_i;
        end
        if (mcause_we_i) begin
            mcause <= mcause_wdata_i;
        end
        // ex模块的写操作
        if (we_i) begin
            case (waddr_i)
                `CSR_MTVEC: begin
                    mtvec <= data_i;
                end
                `CSR_MCAUSE: begin
                    mcause <= data_i;
                end
                `CSR_MEPC: begin
                    mepc <= data_i;
                end
                `CSR_MIE: begin
                    mie <= data_i;
                end
                `CSR_MSTATUS: begin
                    mstatus <= data_i;
                end
                `CSR_MSCRATCH: begin
                    mscratch <= data_i;
                end
                `CSR_MIP: begin
                    mip <= data_i;
                end
                default: ;
            endcase
        end
    end
end

// id模块读CSR
always @ (*) begin
    case (raddr_i)
        // `CSR_CYCLE: begin
        //     data_o = cycle[31:0];
        // end
        // `CSR_CYCLEH: begin
        //     data_o = cycle[63:32];
        // end
        `CSR_MTVEC: begin
            data_o = mtvec;
        end
        `CSR_MCAUSE: begin
            data_o = mcause;
        end
        `CSR_MEPC: begin
            data_o = mepc;
        end
        `CSR_MIE: begin
            data_o = mie;
        end
        `CSR_MSTATUS: begin
            data_o = mstatus;
        end
        `CSR_MSCRATCH: begin
            data_o = mscratch;
        end
        `CSR_MIP: begin
            data_o = mip;
        end
        default: begin
            data_o = 32'b0;
        end
    endcase
end


// clint模块读CSR
// always @ (*) begin
//     if ((clint_waddr_i == clint_raddr_i) && clint_we_i) begin
//         clint_data_o = clint_data_i;
//     end 
//     else begin
//         case (clint_raddr_i)
//             `CSR_CYCLE: begin
//                 clint_data_o = cycle[31:0];
//             end
//             `CSR_CYCLEH: begin
//                 clint_data_o = cycle[63:32];
//             end
//             `CSR_MTVEC: begin
//                 clint_data_o = mtvec;
//             end
//             `CSR_MCAUSE: begin
//                 clint_data_o = mcause;
//             end
//             `CSR_MEPC: begin
//                 clint_data_o = mepc;
//             end
//             `CSR_MIE: begin
//                 clint_data_o = mie;
//             end
//             `CSR_MSTATUS: begin
//                 clint_data_o = mstatus;
//             end
//             `CSR_MSCRATCH: begin
//                 clint_data_o = mscratch;
//             end
//             `CSR_MIP: begin
//                 clint_data_o = mip;
//             end
//             default: begin
//                 clint_data_o = 32'b0;
//             end
//         endcase
//     end
// end


endmodule