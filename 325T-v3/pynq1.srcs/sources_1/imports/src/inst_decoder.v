`include "defines.vh"

`timescale 1ns / 1ps

module inst_decoder (
    input [31:0] inst_i,
    input [31:0] inst_addr_i,
    input [31:0] imm_i,
    input [31:0] pre_addr_i,

    output reg [2:0] inst_type_o,
    output reg [3:0] inst_subtype_o,
    output reg [1:0] op1_src_o,
    output reg [1:0] op2_src_o,
    output reg [11:0] csr_addr_o,
    output reg csr_wflag_o,
    output reg [4:0] reg1_raddr_o,
    output reg [4:0] reg2_raddr_o,
    output reg reg_wflag_o,
    output reg [4:0] reg_waddr_o,
    output reg jal_flush_o,
    output reg [31:0] jal_addr_o,
    output reg [31:0] aux_addr_o

);
// opcode
wire [6:0] opcode = inst_i[6:0];
// funct3
wire [2:0] funct3 = inst_i[14:12];
// funct7
wire [6:0] funct7 = inst_i[31:25];
// rd
wire [4:0] rd = inst_i[11:7];
// rs1
wire [4:0] rs1 = inst_i[19:15];
// rs2
wire [4:0] rs2 = inst_i[24:20];

// decode
always@(*) begin
    // 给信号赋默认值
    inst_type_o = 3'b0;
    inst_subtype_o = 4'b0;
    op1_src_o = 2'b0;
    op2_src_o = 2'b0;
    csr_addr_o = 12'b0;
    csr_wflag_o = 1'b0;
    reg1_raddr_o = 5'b0;
    reg2_raddr_o = 5'b0;
    reg_waddr_o = 5'b0;
    reg_wflag_o = 1'b0;
    jal_flush_o = 1'b0;
    jal_addr_o = 32'b0;
    aux_addr_o = 32'b0;

    case (opcode)
        `INST_TYPE_I:begin
            inst_type_o = `TYPE_ALU;
            op1_src_o = `OP1_REG;
            op2_src_o = `OP2_IMM;
            reg1_raddr_o = rs1;
            reg2_raddr_o = 5'b0;
            reg_waddr_o = rd;
            reg_wflag_o = 1'b1;

            case (funct3)
                `INST_ADDI:begin
                    inst_subtype_o = `ALU_ADD;
                end
                `INST_SLTI:begin
                    inst_subtype_o = `ALU_SLT;
                end
                `INST_SLTIU:begin
                    inst_subtype_o = `ALU_SLTU;
                end
                `INST_XORI:begin
                    inst_subtype_o = `ALU_XOR;
                end
                `INST_ORI:begin
                    inst_subtype_o = `ALU_OR;
                end
                `INST_ANDI:begin
                    inst_subtype_o = `ALU_AND;
                end
                `INST_SLLI:begin
                    inst_subtype_o = `ALU_SLL;
                end
                `INST_SRI:begin
                    if(inst_i[30]) begin
                        inst_subtype_o = `ALU_SRA;
                    end
                    else begin
                        inst_subtype_o = `ALU_SRL;
                    end
                end
                default:begin
                    inst_subtype_o = 4'b0;
                end
            endcase
        end
        `INST_TYPE_R:begin
            op1_src_o = `OP1_REG;
            op2_src_o = `OP2_REG;
            reg1_raddr_o = rs1;
            reg2_raddr_o = rs2;
            reg_waddr_o = rd;
            reg_wflag_o = 1'b1;

            `ifdef use_m_extension
            if (funct7 == 7'b0000001) begin    // M extension
                inst_type_o = `TYPE_M_EXT;
                case (funct3)
                    `INST_MUL: begin
                        inst_subtype_o = `M_MUL;
                    end
                    `INST_MULH: begin
                        inst_subtype_o = `M_MULH;
                    end
                    `INST_MULHU: begin
                        inst_subtype_o = `M_MULHU;
                    end
                    `INST_MULHSU: begin
                        inst_subtype_o = `M_MULHSU;
                    end
                    `INST_DIV: begin
                        inst_subtype_o = `M_DIV;
                    end
                    `INST_DIVU: begin
                        inst_subtype_o = `M_DIVU;
                    end
                    `INST_REM: begin
                        inst_subtype_o = `M_REM;
                    end
                    `INST_REMU: begin
                        inst_subtype_o = `M_REMU;
                    end
                    default: begin
                        inst_subtype_o = 4'b0;
                    end
                endcase
            end
            else begin    // 普通R型指令
            `endif
                inst_type_o = `TYPE_ALU;
                case (funct3)
                    `INST_ADD_SUB:begin
                        if(inst_i[30]) begin
                            inst_subtype_o = `ALU_SUB;
                        end
                        else begin
                            inst_subtype_o = `ALU_ADD;
                        end
                    end
                    `INST_SLL:begin
                        inst_subtype_o = `ALU_SLL;
                    end
                    `INST_SLT:begin
                        inst_subtype_o = `ALU_SLT;
                    end
                    `INST_SLTU:begin
                        inst_subtype_o = `ALU_SLTU;
                    end
                    `INST_XOR:begin
                        inst_subtype_o = `ALU_XOR;
                    end
                    `INST_SR:begin
                        if(inst_i[30])begin
                            inst_subtype_o = `ALU_SRA;
                        end
                        else begin
                            inst_subtype_o = `ALU_SRL;
                        end
                    end
                    `INST_OR:begin
                        inst_subtype_o = `ALU_OR;
                    end
                    `INST_AND:begin
                        inst_subtype_o = `ALU_AND;
                    end
                    default:begin
                        inst_subtype_o = 4'b0;
                    end
                endcase
            `ifdef use_m_extension
            end
            `endif
        end
        `INST_TYPE_L:begin
            inst_type_o = `TYPE_MEM;
            op1_src_o = `OP1_REG;
            op2_src_o = `OP2_IMM;
            reg1_raddr_o = rs1;
            reg2_raddr_o = 5'b0;
            reg_waddr_o = rd;
            reg_wflag_o = 1'b1;

            case (funct3)
                `INST_LB: begin
                    inst_subtype_o = `MEM_LB;
                end
                `INST_LH: begin
                    inst_subtype_o = `MEM_LH;
                end
                `INST_LW: begin
                    inst_subtype_o = `MEM_LW;
                end
                `INST_LBU: begin
                    inst_subtype_o = `MEM_LBU;
                end
                `INST_LHU: begin
                    inst_subtype_o = `MEM_LHU;
                end
                default:begin
                    inst_subtype_o = 4'b0;
                end
            endcase
        end
        `INST_TYPE_S:begin
            inst_type_o = `TYPE_MEM;
            op1_src_o = `OP1_REG;
            op2_src_o = `OP2_REG;
            reg1_raddr_o = rs1;
            reg2_raddr_o = rs2;
            reg_waddr_o = 5'b0;
            reg_wflag_o = 1'b0;

            case (funct3)
                `INST_SB:begin
                    inst_subtype_o = `MEM_SB;
                end
                `INST_SH:begin
                    inst_subtype_o = `MEM_SH;
                end
                `INST_SW:begin
                    inst_subtype_o = `MEM_SW;
                end
                default:begin
                    inst_subtype_o = 4'b0;
                end
            endcase
        end
        `INST_TYPE_B:begin
            inst_type_o = `TYPE_BR;
            op1_src_o = `OP1_REG;
            op2_src_o = `OP2_REG;
            reg1_raddr_o = rs1;
            reg2_raddr_o = rs2;
            reg_waddr_o = 5'b0;
            reg_wflag_o = 1'b0;
            aux_addr_o = inst_addr_i + imm_i;

            case (funct3)
                `INST_BEQ: begin
                    inst_subtype_o = `BR_EQ;
                end
                `INST_BNE: begin
                    inst_subtype_o = `BR_NE;
                end
                `INST_BLT: begin
                    inst_subtype_o = `BR_LT;
                end
                `INST_BGE: begin
                    inst_subtype_o = `BR_GE;
                end
                `INST_BLTU: begin
                    inst_subtype_o = `BR_LTU;
                end
                `INST_BGEU: begin
                    inst_subtype_o = `BR_GEU;
                end
                default: begin
                    inst_subtype_o = 4'b0;
                end
            endcase
        end
        `INST_JAL:begin
            inst_type_o = `TYPE_JAL;
            inst_subtype_o = `JUMP_JAL;
            op1_src_o = `OP1_PC;
            op2_src_o = `OP2_4;
            reg1_raddr_o = 5'b0;
            reg2_raddr_o = 5'b0;
            reg_waddr_o = rd;
            reg_wflag_o = 1'b1;
            aux_addr_o = inst_addr_i + imm_i;
            if (inst_addr_i + imm_i == pre_addr_i) begin
                jal_flush_o = 1'b0;           // 预测成功无需冲刷
                jal_addr_o = 32'b0;
            end
            else begin
                jal_flush_o = 1'b1;
                jal_addr_o = inst_addr_i + imm_i;
            end
        end
        `INST_JALR:begin
            inst_type_o = `TYPE_JAL;
            inst_subtype_o = `JUMP_JALR;
            op1_src_o = `OP1_REG;
            op2_src_o = `OP2_IMM;
            reg1_raddr_o = rs1;
            reg2_raddr_o = 5'b0;
            reg_waddr_o = rd;
            reg_wflag_o = 1'b1;
            aux_addr_o = inst_addr_i + 32'd4;
        end
        `INST_LUI:begin
            inst_type_o = `TYPE_ALU;
            inst_subtype_o = `ALU_LUI;
            op1_src_o = `OP1_ZERO;
            op2_src_o = `OP2_IMM;
            reg1_raddr_o = 5'b0;
            reg2_raddr_o = 5'b0;
            reg_waddr_o = rd;
            reg_wflag_o = 1'b1;
        end
        `INST_AUIPC:begin
            inst_type_o = `TYPE_ALU;
            inst_subtype_o = `ALU_AUIPC;
            op1_src_o = `OP1_PC;
            op2_src_o = `OP2_IMM;
            reg1_raddr_o = 5'b0;
            reg2_raddr_o = 5'b0;
            reg_waddr_o = rd;
            reg_wflag_o = 1'b1;
        end
        `INST_CSR: begin
            inst_type_o = `TYPE_CSR;

            if (funct3 == 3'b000) begin
                op1_src_o = 2'b0;    // 不需要源
                op2_src_o = 2'b0;    
                reg1_raddr_o = 5'b0;
                reg2_raddr_o = 5'b0;
                reg_waddr_o = 5'b0;    // 不写回寄存器
                reg_wflag_o = 1'b0;
                
                case (inst_i)
                    `INST_ECALL:  inst_subtype_o = `CSR_ECALL;
                    `INST_EBREAK: inst_subtype_o = `CSR_EBREAK;
                    `INST_MRET:   inst_subtype_o = `CSR_MRET;
                    default:      inst_subtype_o = 4'b0; 
                endcase
            end
            else begin
                op1_src_o = `OP1_CSR;
                csr_addr_o = inst_i[31:20];
                csr_wflag_o = 1'b1;
                reg2_raddr_o = 5'b0;
                reg_waddr_o = rd;
                reg_wflag_o = 1'b1;

                case (funct3)
                    `INST_CSRRW: begin
                        inst_subtype_o = `CSR_RW;
                        op2_src_o = `OP2_REG;
                        reg1_raddr_o = rs1;
                    end
                    `INST_CSRRS: begin
                        inst_subtype_o = `CSR_RS;
                        op2_src_o = `OP2_REG;
                        reg1_raddr_o = rs1;
                    end
                    `INST_CSRRC: begin
                        inst_subtype_o = `CSR_RC;
                        op2_src_o = `OP2_REG;
                        reg1_raddr_o = rs1;
                    end
                    `INST_CSRRWI: begin
                        inst_subtype_o = `CSR_RW;
                        op2_src_o = `OP2_IMM;
                        reg1_raddr_o = 5'b0;
                    end
                    `INST_CSRRSI: begin
                        inst_subtype_o = `CSR_RS;
                        op2_src_o = `OP2_IMM;
                        reg1_raddr_o = 5'b0;
                    end
                    `INST_CSRRCI: begin
                        inst_subtype_o = `CSR_RC;
                        op2_src_o = `OP2_IMM;
                        reg1_raddr_o = 5'b0;
                    end
                    default: begin
                        inst_subtype_o = 4'b0;
                        op2_src_o = 2'b0;
                        reg1_raddr_o = 5'b0;
                    end
                endcase
            end
        end
        default:begin
            inst_type_o = 3'b0;
            inst_subtype_o = 4'b0;
            op1_src_o = 2'b0;
            op2_src_o = 2'b0;
            csr_addr_o = 12'b0;
            csr_wflag_o = 1'b0;
            reg1_raddr_o = 5'b0;
            reg2_raddr_o = 5'b0;
            reg_waddr_o = 5'b0;
            reg_wflag_o = 1'b0;
            jal_flush_o = 1'b0;
            jal_addr_o = 32'b0;
            aux_addr_o = 32'b0;
        end
    endcase
end



endmodule