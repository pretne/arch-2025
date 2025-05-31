`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

package pipes;
    import common::*;


    // 定义指令解码规则
    parameter F7_ADDI = 7'b0010011;
    parameter F3_ADDI = 3'b000;

    parameter F7_XORI = 7'b0010011;
    parameter F3_XORI = 3'b100;

    parameter F7_ORI = 7'b0010011;
    parameter F3_ORI = 3'b110;

    parameter F7_ANDI = 7'b0010011;
    parameter F3_ANDI = 3'b111;

    parameter F7_ADD = 7'b0110011;
    parameter F3_ADD = 3'b000;
    parameter F7_ADD_ = 7'b0000000;

    parameter F7_SUB = 7'b0110011;
    parameter F3_SUB = 3'b000;
    parameter F7_SUB_ = 7'b0100000;

    parameter F7_AND = 7'b0110011;
    parameter F3_AND = 3'b111;

    parameter F7_OR = 7'b0110011;
    parameter F3_OR = 3'b110;

    parameter F7_XOR = 7'b0110011;
    parameter F3_XOR = 3'b100;

    parameter F7_ADDIW = 7'b0011011;
    parameter F3_ADDIW = 3'b000;

    parameter F7_ADDW = 7'b0111011;
    parameter F3_ADDW = 3'b000;
    parameter F7_ADDW_ = 7'b0000000;

    parameter F7_SUBW = 7'b0111011;
    parameter F3_SUBW = 3'b000;
    parameter F7_SUBW_ = 7'b0100000;

    parameter F7_LD = 7'b0000011;
    parameter F3_LD = 3'b011;

    parameter F7_SD = 7'b0100011;
    parameter F3_SD = 3'b011;

    parameter F7_LB = 7'b0000011;
    parameter F3_LB = 3'b000;

    parameter F7_LH = 7'b0000011;
    parameter F3_LH = 3'b001;

    parameter F7_LW = 7'b0000011;
    parameter F3_LW = 3'b010;

    parameter F7_LBU = 7'b0000011;
    parameter F3_LBU = 3'b100;

    parameter F7_LHU = 7'b0000011;
    parameter F3_LHU = 3'b101;

    parameter F7_LWU = 7'b0000011;
    parameter F3_LWU = 3'b110;

    parameter F7_SB = 7'b0100011;
    parameter F3_SB = 3'b000;

    parameter F7_SH = 7'b0100011;
    parameter F3_SH = 3'b001;

    parameter F7_SW = 7'b0100011;
    parameter F3_SW = 3'b010;

    parameter F7_LUI = 7'b0110111;

    parameter F7_BEQ = 7'b1100011;
    parameter F3_BEQ = 3'b000;

    parameter F7_BNE = 7'b1100011;  
    parameter F3_BNE = 3'b001;

    parameter F7_BLT = 7'b1100011;
    parameter F3_BLT = 3'b100;

    parameter F7_BGE = 7'b1100011;
    parameter F3_BGE = 3'b101;

    parameter F7_BLTU = 7'b1100011;
    parameter F3_BLTU = 3'b110;

    parameter F7_BGEU = 7'b1100011;
    parameter F3_BGEU = 3'b111;

    parameter F7_SLTI = 7'b0010011;
    parameter F3_SLTI = 3'b010;

    parameter F7_SLTIU = 7'b0010011;
    parameter F3_SLTIU = 3'b011;

    parameter F7_SLLI = 7'b0010011;
    parameter F3_SLLI = 3'b001;

    parameter F7_SRLI = 7'b0010011;
    parameter F3_SRLI = 3'b101;

    parameter F7_SRAI = 7'b0010011;
    parameter F3_SRAI = 3'b101;

    parameter F7_SLL = 7'b0110011;
    parameter F3_SLL = 3'b001;

    parameter F7_SLT = 7'b0110011;
    parameter F3_SLT = 3'b010;

    parameter F7_SLTU = 7'b0110011;
    parameter F3_SLTU = 3'b011;

    parameter F7_SRL = 7'b0110011;
    parameter F3_SRL = 3'b101;
    parameter F7_SRL_ = 7'b0000000;

    parameter F7_SRA = 7'b0110011;
    parameter F3_SRA = 3'b101;
    parameter F7_SRA_ = 7'b0100000;

    parameter F7_SLLIW = 7'b0011011;
    parameter F3_SLLIW = 3'b001;

    parameter F7_SRLIW = 7'b0011011;
    parameter F3_SRLIW = 3'b101;

    parameter F7_SRAIW = 7'b0011011;
    parameter F3_SRAIW = 3'b101;

    parameter F7_SLLW = 7'b0111011;
    parameter F3_SLLW = 3'b001;

    parameter F7_SRLW = 7'b0111011;
    parameter F3_SRLW = 3'b101;
    parameter F7_SRLW_ = 7'b0000000;

    parameter F7_SRAW = 7'b0111011;
    parameter F3_SRAW = 3'b101;
    parameter F7_SRAW_ = 7'b0100000;

    parameter F7_AUIPC = 7'b0010111;

    parameter F7_JAL = 7'b1101111;

    parameter F7_JALR = 7'b1100111;

    parameter F7_CSRRW = 7'b1110011;
    parameter F3_CSRRW = 3'b001;

    parameter F7_CSRRS = 7'b1110011;
    parameter F3_CSRRS = 3'b010;

    parameter F7_CSRRC = 7'b1110011;
    parameter F3_CSRRC = 3'b011;

    parameter F7_CSRRWI = 7'b1110011;
    parameter F3_CSRRWI = 3'b101;

    parameter F7_CSRRCI = 7'b1110011;
    parameter F3_CSRRCI = 3'b111;

    parameter F7_CSRRSI = 7'b1110011;
    parameter F3_CSRRSI = 3'b110;

    parameter F3_MRET = 3'b000;

    parameter F7_MRET_ = 7'b0011000;

    parameter F7_ECALL_ = 7'b0000000;
    
    // typedef enum logic {
    //     IDLE,
    //     TEMP
    // } state_t;

    typedef struct packed {
        logic valid;
        u64 pc;
        u32 instr;  
        error_t error;
    } fetch_data_t;

    typedef struct packed {
        decode_op_t op;
        alufunc_t alufunc;
        u1 regwrite, memtoreg, memwrite;  
    } control_t;

    typedef struct packed {
        logic valid;
        u64 pc;
        u32 instr;
        u5 rega, regb;
        word_t srca, srcb; 
        // word_t rd1, rd2; 
        logic [51:0] rd1;
        csr_addr_t csrdst;
        word_t csr;
        word_t store_data;
        control_t ctl;    
        creg_addr_t dst;  
        error_t error;
        // csr_t csr;
        // csr_addr_t csrdst;
        // u12 csrdst;
        // word_t csr;
    } decode_data_t;

    typedef struct packed {
        logic valid;
        u64 pc;
        u32 instr;
        word_t result;
        // csr_addr_t csrdst;
        // word_t csr;
        word_t store_data;
        control_t ctl;
        creg_addr_t dst;
        word_t csrres;
        error_t error;
        // csr_addr_t csrdst;
        // u12 csrdst;
        // word_t csr;
    } execute_data_t;

    typedef struct packed {
        logic valid;
        u64 pc;
        u32 instr;
        word_t result;
        word_t memaddr;
        control_t ctl;
        creg_addr_t dst;
        word_t csrres;
        error_t error;
        // csr_addr_t csrdst;
        // u12 csrdst;
        // word_t csr;
    } memory_data_t;

    typedef struct packed {
        logic valid;
        u64 pc;
        u32 instr;
        word_t result;
        word_t memaddr;
        control_t ctl;
        creg_addr_t dst;
        word_t csrres;
        error_t error;
        // error_t error;
        // csr_addr_t csrdst;
        // u12 csrdst;
        // word_t csr;
    } writeback_data_t;

    typedef enum u4 {
        IDLE,
        READ_L1, WAIT_L1,
        READ_L2, WAIT_L2,
        READ_L3, WAIT_L3,
        READ_DATA, WAIT_DATA,
        OUTPUT
    } mmu_state_t;
    
endpackage

`endif
