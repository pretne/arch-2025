`ifndef __DECODER_SV
`define __DECODER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module decoder
    import common::*;
    import pipes::*;(
    input u32 raw_instr,
    output control_t ctl,
    input error_t error

);

    u7 f7 = raw_instr[6:0];
    u3 f3 = raw_instr[14:12];
    u7 f7_ = raw_instr[31:25];

    always_comb begin
        ctl = '0;
        if (error == INSTR_MISALIGN) begin
            ctl.op = UNKNOWN;
            ctl.alufunc = NOTALU;
        end
        unique case (f7)
            F7_ADDI: begin
                ctl.op = ALUI;
                ctl.regwrite = 1'b1;
                unique case (f3)
                    F3_ADDI: begin
                        ctl.alufunc = ADD;
                    end

                    F3_XORI: begin
                        ctl.alufunc = XOR;
                    end  

                    F3_ORI: begin
                        ctl.alufunc = OR;
                    end

                    F3_ANDI: begin
                        ctl.alufunc = AND;
                    end

                    F3_SLTI: begin
                        ctl.alufunc = SLT;
                    end

                    F3_SLTIU: begin
                        ctl.alufunc = SLTU;
                    end

                    F3_SLLI: begin
                        ctl.alufunc = SLL;
                    end

                    F3_SRLI: begin
                        ctl.alufunc = raw_instr[30] ? SRA : SRL;    
                    end

                    default: begin
                        ctl.alufunc = NOTALU;
                        ctl.regwrite = 1'b0;
                    end
                endcase
            end

            F7_ADD: begin
                ctl.op = ALU;
                ctl.regwrite = 1'b1;
                unique case (f3)
                    F3_ADD: begin
                        unique case (f7_)
                            F7_ADD_: begin
                                ctl.alufunc = ADD;              
                            end

                            F7_SUB_: begin
                                ctl.alufunc = SUB;
                            end

                            default: begin
                                ctl.alufunc = NOTALU;
                            end
                        endcase
                    end

                    F3_AND: begin
                        ctl.alufunc = AND;
                    end

                    F3_OR: begin
                        ctl.alufunc = OR;
                    end

                    F3_XOR: begin
                        ctl.alufunc = XOR;
                    end

                    F3_SLT: begin
                        ctl.alufunc = SLT;
                    end

                    F3_SLTU: begin
                        ctl.alufunc = SLTU;
                    end

                    F3_SLL: begin
                        ctl.alufunc = SLL;
                    end

                    F3_SRL: begin
                        unique case (f7_)
                            F7_SRL_: begin
                                ctl.alufunc = SRL;
                            end

                            F7_SRA_: begin
                                ctl.alufunc = SRA;
                            end

                            default: begin
                                ctl.alufunc = NOTALU;
                            end
                        endcase
                    end

                    default: begin
                        ctl.alufunc = NOTALU;
                    end
                endcase
            end

            F7_ADDIW: begin
                ctl.op = ALUIW;
                ctl.regwrite = 1'b1;
                unique case (f3)
                    F3_ADDIW: begin
                        ctl.alufunc = ADD;
                    end

                    F3_SLLIW: begin
                        ctl.alufunc = SLLW;
                    end

                    F3_SRLIW: begin
                        ctl.alufunc = raw_instr[30] ? SRAW : SRLW;    
                    end

                    default: begin
                        ctl.alufunc = NOTALU;
                    end
                endcase
            end

            F7_ADDW: begin
                ctl.op = ALUW;
                ctl.regwrite = 1'b1;
                unique case (f3)
                    F3_ADDW:
                    unique case (f7_)
                        F7_ADDW_: begin
                            ctl.alufunc = ADD;
                        end

                        F7_SUBW_: begin
                            ctl.alufunc = SUB;
                        end

                        default: begin
                            ctl.alufunc = NOTALU;
                        end
                    endcase

                    F3_SLLW: begin
                        ctl.alufunc = SLLW;
                    end

                    F3_SRLW: begin
                        unique case (f7_)
                            F7_SRLW_: begin
                                ctl.alufunc = SRLW;
                            end

                            F7_SRAW_: begin
                                ctl.alufunc = SRAW;
                            end

                            default: begin
                                ctl.alufunc = NOTALU;
                            end
                        endcase
                    end

                    default: begin
                        ctl.alufunc = NOTALU;
                    end
                endcase
            end

            F7_LD: begin
                ctl.op = LD;
                ctl.regwrite = 1'b1;
                ctl.memtoreg = 1'b1;
                ctl.alufunc = ADD;
            end

            F7_SD: begin
                ctl.op = SD;
                ctl.regwrite = 1'b0;
                ctl.memwrite = 1'b1;
                ctl.alufunc = ADD;
            end

            F7_LUI: begin
                ctl.op = LUI;
                ctl.regwrite = 1'b1;
                ctl.alufunc = CPYB;
            end

            F7_BEQ: begin
                ctl.regwrite = 1'b0;
                ctl.op = f3[0] ? BNZ : BZ;
                unique case (f3[2:1])  
                    2'b00: begin
                        ctl.alufunc = EQL;
                    end

                    2'b10: begin
                        ctl.alufunc = SLT;
                    end

                    2'b11: begin
                        ctl.alufunc = SLTU;
                    end

                    default: begin
                        ctl.alufunc = NOTALU;
                    end
                endcase  
            end

            F7_AUIPC: begin
                ctl.op = AUIPC;
                ctl.regwrite = 1'b1;
                ctl.alufunc = AUI;
            end

            F7_JAL: begin
                ctl.op = JAL;
                ctl.regwrite = 1'b1;
                ctl.alufunc = ADD;
            end

            F7_JALR: begin
                ctl.op = JALR;
                ctl.regwrite = 1'b1;
                ctl.alufunc = ADD;
            end

            F7_CSRRC: begin
                ctl.regwrite = 1'b1;
                unique case(f3)
                    F3_CSRRC: begin
                        ctl.op = CSR;
                        ctl.alufunc = ALU_CSRC;
                    end

                    F3_CSRRCI: begin
                        ctl.op = CSRI;
                        ctl.alufunc = ALU_CSRCI;
                    end

                    F3_CSRRS: begin
                        ctl.op = CSR;
                        ctl.alufunc = ALU_CSRS;
                    end

                    F3_CSRRSI: begin
                        ctl.op = CSRI;
                        ctl.alufunc = ALU_CSRSI;
                    end

                    F3_CSRRW: begin
                        ctl.op = CSR;
                        ctl.alufunc = ALU_CSRW;
                    end

                    F3_CSRRWI: begin
                        ctl.op = CSRI;
                        ctl.alufunc = ALU_CSRWI;
                    end

                    F3_MRET: begin
                        ctl.regwrite = 1'b0;
                        unique case(f7_)
                            F7_MRET_: begin
                                ctl.op = MRET;
                                ctl.alufunc = ALU_MRET;
                            end

                            F7_ECALL_: begin
                                ctl.op = ECALL;
                                ctl.alufunc = ALU_ECALL;
                            end

                            default: begin
                                ctl.op = UNKNOWN;
                                ctl.alufunc = NOTALU;
                            end
                        endcase
                    end

                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.alufunc = NOTALU;
                    end
                endcase
            end

            default: begin
                ctl.op = UNKNOWN;
                ctl.alufunc = NOTALU;
                ctl.regwrite = 1'b0;
            end
        endcase
        
    end

    
endmodule


`endif
