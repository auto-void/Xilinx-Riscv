`include "defines.vh"

`timescale 1ns / 1ps

module uart #(
    parameter CLK_FREQ = 250_000_000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire rst,
    input wire rx,
    output reg [31:0] rdata,

    output reg tx,
    input wire [7:0] tx_data,
    input wire tx_start,
    input wire we,
    input wire tx_ie,
    input wire [31:0] addr,
    output wire int_flag_o
);
    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;
    reg [7:0] rx_data;
    // 状态寄存器
    reg rx_ready;
    reg rx_en;
    reg tx_busy;
    reg tx_en;

    // rx_ready上升沿检测
    wire rx_ready_posedge;
    reg rx_ready_d1;
    always @(posedge clk) begin
        rx_ready_d1 <= rx_ready;
    end
    assign rx_ready_posedge = ~rx_ready_d1 & rx_ready;

    // 触发中断
    assign int_flag_o = (rx_en) | (~tx_busy & tx_en);

    // cpu读写
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            rx_en <= 1'b0;
        end
        else if(rx_ready_posedge) begin
            rx_en <= 1'b1;
        end
        else if(addr == 32'h80200060) begin
            rx_en <= 1'b0;
        end
    end

    always @(*) begin
        case(addr)
            32'h80200060: rdata = {24'b0, rx_data};
            32'h80200068: rdata = {30'b0, tx_en, rx_en};
            default: rdata = 32'b0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            tx_en <= 1'b0;
        end
        else if(we) begin
            tx_en <= tx_ie;
        end
    end

    // 串口接收
    reg [1:0] rx_state;
    reg [15:0] rx_cnt;
    reg [7:0] rx_shift;
    reg rx_d0, rx_d1, rx_d2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_d0 <= 1'b1;
            rx_d1 <= 1'b1;
            rx_d2 <= 1'b1;
        end else begin
            rx_d0 <= rx;
            rx_d1 <= rx_d0;
            rx_d2 <= rx_d1;
        end
    end
    wire rx_negedge;
    assign rx_negedge = rx_d2 & ~rx_d1;

    reg [3:0] rx_bit_cnt;
    reg rx_ready_pulse;
    reg [15:0] rx_ready_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_state <= 0;
            rx_cnt <= 0;
            rx_bit_cnt <= 0;
            rx_shift <= 0;
            rx_data <= 0;
            rx_ready_pulse <= 0;
        end else begin
            rx_ready_pulse <= 0;
            case(rx_state)
                0: begin
                    if(rx_negedge) begin
                        rx_state <= 1;
                        rx_cnt <= BAUD_DIV >> 1;
                        rx_bit_cnt <= 0;
                    end
                end
                1: begin
                    if(rx_cnt == BAUD_DIV-1) begin
                        rx_cnt <= 0;
                        rx_state <= 2;
                    end else
                        rx_cnt <= rx_cnt + 1;
                end
                2: begin
                    if(rx_cnt == BAUD_DIV-1) begin
                        rx_cnt <= 0;
                        rx_shift <= {rx_d2, rx_shift[7:1]};
                        if(rx_bit_cnt == 7)
                            rx_state <= 3;
                        else
                            rx_bit_cnt <= rx_bit_cnt + 1;
                    end else
                        rx_cnt <= rx_cnt + 1;
                end
                3: begin
                    if(rx_cnt == BAUD_DIV-1) begin
                        rx_cnt <= 0;
                        rx_state <= 0;
                        rx_data <= rx_shift;
                        rx_ready_pulse <= 1'b1;
                    end else begin
                        rx_cnt <= rx_cnt + 1;
                    end
                end
                default: rx_state <= 0;
            endcase
        end
    end
    
    // rx_ready delay for half of BAUD_DIV
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_ready <= 1'b0;
            rx_ready_cnt <= 0;
        end else begin
            if (rx_ready_pulse) begin
                rx_ready <= 1'b1;
                rx_ready_cnt <= 0;
            end else if (rx_ready) begin
                if (rx_ready_cnt < BAUD_DIV - 1) begin
                    rx_ready_cnt <= rx_ready_cnt + 1;
                end else begin
                    rx_ready <= 1'b0;
                end
            end
        end
    end

    // 串口发送
    // tx state machine
    reg [3:0] tx_state;
    reg [15:0] tx_cnt;
    reg [3:0] tx_bit_cnt;
    reg [9:0] tx_shift;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_state <= 0;
            tx_busy <= 0;
            tx_cnt <= 0;
            tx_bit_cnt <= 0;
            tx_shift <= 10'b1111111111;
            tx <= 1'b1;
        end else begin
            case(tx_state)
                0: begin
                    tx_busy <= 0;
                    if(tx_start) begin
                        tx_shift <= {1'b1, tx_data, 1'b0};
                        tx_state <= 1;
                        tx_cnt <= 0;
                        tx_bit_cnt <= 0;
                        tx_busy <= 1;
                    end
                end
                1: begin
                    if(tx_cnt == BAUD_DIV-1) begin
                        tx_cnt <= 0;
                        tx <= tx_shift[0];
                        tx_shift <= {1'b1, tx_shift[9:1]};
                        if(tx_bit_cnt == 9)
                            tx_state <= 0;
                        else
                            tx_bit_cnt <= tx_bit_cnt + 1;
                    end else
                        tx_cnt <= tx_cnt + 1;
                end
            endcase
        end
    end

endmodule
