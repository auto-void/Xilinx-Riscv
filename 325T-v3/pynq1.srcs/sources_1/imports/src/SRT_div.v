`include "defines.vh"

`timescale 1ns / 1ps

module SRT_div (
    input           clk,
    input           rst_n,
    input           start,
    input           signed_div,    // 有符号除法标志
    input  [31:0]   dividend,      // 被除数
    input  [31:0]   divisor,       // 除数
    output [31:0]   quotient,      // 商
    output [31:0]   remainder,     // 余数
    output          ready_for_wakeup,
    output          done
    // output          busy
);

    parameter IDLE = 2'b00;
    parameter RUN  = 2'b01;
    parameter FIX  = 2'b10;

    reg [1:0]   state, state_n;
    reg [31:0]  dvd_reg;    // 被除数寄存器存储绝对值
    reg [31:0]  dvs_reg;    // 除数寄存器存储绝对值
    // reg         sgn_reg;
    reg [4:0]   cnt;

    // 37位宽：防止溢出
    // bit[36:34] : 符号与溢出保护 (3位)
    // bit[33:2]  : 32位整数数据
    // bit[1:0]   : 定点小数位 (Scale=4, 恒为0)
    reg signed [36:0] rem;
    reg [31:0]  q_pos, q_neg;   // 正商与负商

    wire        dvd_sign     = signed_div & dividend[31];
    wire        dvs_sign     = signed_div & divisor[31];
    wire [31:0] dvd_abs      = dvd_sign ? (~dividend + 1'b1) : dividend;
    wire [31:0] dvs_abs      = dvs_sign ? (~divisor + 1'b1) : divisor;
    wire        q_final_sign = dvd_sign ^ dvs_sign;
    wire        r_final_sign = dvd_sign;
    wire        div_zero     = (divisor == 32'd0);

    // --- 定点化扩展 (Scale = 4) ---
    // dvs_ext = 4 * D
    // wire signed [36:0] dvs_ext = {3'b0, dvs_reg, 2'b0}; 
    reg signed [36:0] dvs_ext;
    
    // 阈值：
    // wire signed [36:0] dvs_0_5 = {4'b0, dvs_reg, 1'b0};     // 2 * D
    // wire signed [36:0] dvs_1_5 = dvs_ext + dvs_0_5;         // 6 * D
    reg signed [36:0] dvs_0_5, dvs_1_5;

    reg signed [36:0] rem_sh, rem_step;
    reg signed [2:0]  q;
    reg [31:0] q_pos_next, q_neg_next;
    reg [31:0] dvd_next; 

    always @(*) begin
        // 默认值
        q = 0; 
        rem_step = rem;
        q_pos_next = q_pos; 
        q_neg_next = q_neg;
        dvd_next = dvd_reg << 2;

        // 移入被除数的高2位。
        // Scale=4，rem 的 bit[1:0] 始终为 0
        // 33'b0 + 2位数据 + 2'b0 = 37位
        rem_sh = (rem <<< 2) | {33'b0, dvd_reg[31:30], 2'b0};

        // 选商 (比较阈值)
        if      (rem_sh >= dvs_1_5)  q = 3'sd2;
        else if (rem_sh >= dvs_0_5)  q = 3'sd1;
        else if (rem_sh >= -dvs_0_5) q = 3'sd0;
        else if (rem_sh >= -dvs_1_5) q = -3'sd1;
        else                         q = -3'sd2;

        // 更新余数
        case (q)
            3'sd2:    rem_step = rem_sh - (dvs_ext <<< 1); // -2 * (4D)
            3'sd1:    rem_step = rem_sh - dvs_ext;         // -1 * (4D)
            3'sd0:    rem_step = rem_sh;
            -3'sd1:   rem_step = rem_sh + dvs_ext;
            -3'sd2:   rem_step = rem_sh + (dvs_ext <<< 1);
            default:  rem_step = rem_sh;
        endcase

        // =========================================================
        // 更新商
        // =========================================================
        q_pos_next = {q_pos[29:0], 2'b0};
        q_neg_next = {q_neg[29:0], 2'b0};

        if (q > 0)      q_pos_next[1:0] = q[1:0]; 
        else if (q < 0) q_neg_next[1:0] = -q[1:0]; 

    end

    // =========================================================
    // 时序逻辑
    // =========================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            state   <= IDLE;
            dvd_reg <= 0; 
            dvs_reg <= 0;
            dvs_ext <= 0;
            dvs_0_5 <= 0;
            dvs_1_5 <= 0;
            // sgn_reg <= 0;
            rem     <= 0; 
            q_pos   <= 0; 
            q_neg   <= 0; 
            cnt     <= 0;
        end 
        else begin
            state <= state_n;
            case (state)
                IDLE: begin
                    if (start) begin
                        dvd_reg <= dvd_abs;
                        dvs_reg <= dvs_abs;
                        dvs_ext <= {3'b0, dvs_abs, 2'b0};
                        dvs_0_5 <= {4'b0, dvs_abs, 1'b0};
                        dvs_1_5 <= {3'b0, dvs_abs, 2'b0} + {4'b0, dvs_abs, 1'b0};
                        // sgn_reg <= signed_div;
                        rem     <= 0;
                        q_pos   <= 0; 
                        q_neg   <= 0; 
                        cnt     <= 0;
                    end
                end
                RUN: begin
                    rem     <= rem_step;
                    q_pos   <= q_pos_next;
                    q_neg   <= q_neg_next;
                    dvd_reg <= dvd_next;
                    cnt     <= cnt + 1'b1;
                end
                FIX: ;
            endcase
        end
    end

    always @(*) begin
        state_n = state;
        case (state)
            IDLE: if (start) state_n = RUN;
            RUN: begin
                if (~start) state_n = IDLE;
                else if (cnt == 5'd15) state_n = FIX;
            end
            FIX:  state_n = IDLE;
            default: state_n = IDLE;
        endcase
    end

    assign ready_for_wakeup = (state == RUN) && (cnt == 5'd15);

    // =========================================================
    // 输出逻辑
    // =========================================================
    reg [31:0] q_raw, r_raw;
    always @(*) begin
        q_raw = q_pos - q_neg;
        
        // 还原余数：Scale=4，所以舍弃低2位
        // rem[33:2] 对应 32位整数
        r_raw = rem[33:2]; 

        // 修正逻辑：如果余数是负数，加回除数
        if (rem[36] == 1'b1) begin
            r_raw = r_raw + dvs_reg;
            q_raw = q_raw - 1'b1;
        end
    end

    assign quotient  = div_zero ? 32'hFFFFFFFF : (q_final_sign ? (~q_raw + 1'b1) : q_raw);
    assign remainder = div_zero ? dividend     : (r_final_sign ? (~r_raw + 1'b1) : r_raw);
    assign done      = (state == FIX);
    // assign busy      = (state != IDLE);

endmodule