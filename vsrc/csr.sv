`ifndef __CSR_SV
`define __CSR_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else
`endif

module csr
    import common::*;
    import csr_pkg::*;
    import pipes::*; (
    input clk, reset,
    input u12 ra,
    output u64 rd,
    output u64 csrpc,
    input writeback_data_t dataW
);
    csr_regs_t csrs = '{
        mhartid: 0,
        mie: 0,
        mip: 0,
        mtvec: 0,
        mstatus: '0,
        mscratch: 0,
        mepc: 64'h80000000,
        mcause: 64'b10,
        mcycle: 0,
        mtval: 0,
        satp: 0
    };
    csr_regs_t csrs_nxt;
    word_t csrresult;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            csrs           = '0;
            csrs.mcause[1] = 1'b1;
            csrs.mepc[31]  = 1'b1;
        end else begin
            csrs           = csrs_nxt;
        end
    end

    // read
    always_comb begin
        rd = '0;
        unique case(ra)
            CSR_MIE: rd = csrs.mie;
            CSR_MIP: rd = csrs.mip;
            CSR_MTVEC: rd = csrs.mtvec;
            CSR_MSTATUS: rd = csrs.mstatus;
            CSR_MSCRATCH: rd = csrs.mscratch;
            CSR_MEPC: rd = csrs.mepc;
            CSR_MCAUSE: rd = csrs.mcause;
            CSR_MCYCLE: rd = csrs.mcycle;
            CSR_MTVAL: rd = csrs.mtval;
            default: begin
                rd = '0;
            end
        endcase
    end

    always_comb begin
        csrs_nxt = csrs;
        csrresult = 0;
        csrpc = '0;
        csrs_nxt.mcycle = csrs.mcycle + 1;
        if (dataW.valid) begin
            begin
                csrpc = csrs_nxt.mtvec;
                csrs_nxt.mepc = dataW.pc;
                csrs_nxt.mcause[63:0] = 64'b0;
                csrs_nxt.mstatus.mpie = csrs_nxt.mstatus.mie;
                csrs_nxt.mstatus.mie = '0;
            end
        end else if (dataW.valid) begin
            begin
                csrpc = csrs_nxt.mtvec;
                csrs_nxt.mepc = dataW.pc;
                csrs_nxt.mcause[62:0] = 63'b0;
                csrs_nxt.mcause[63] = 1'b1;
                csrs_nxt.mstatus.mpie = csrs_nxt.mstatus.mie;
                csrs_nxt.mstatus.mie = '0;
            end
        end else if ((dataW.ctl.op == CSR || dataW.ctl.op == CSRI) && dataW.valid) begin
            begin
                csrpc = dataW.pc + 4;
                unique case(dataW.ctl.alufunc) 
                    ALU_CSRW: csrresult = dataW.csr;
                    ALU_CSRS: csrresult = dataW.result | dataW.csr;
                    ALU_CSRC: csrresult = dataW.result & ~dataW.csr;
                    default: begin end
                endcase
                unique case(dataW.csrdst)
                    CSR_MIE: csrs_nxt.mie = csrresult;
                    CSR_MIP: csrs_nxt.mip = csrresult;
                    CSR_MTVEC: csrs_nxt.mtvec = csrresult;
                    CSR_MSTATUS: csrs_nxt.mstatus = csrresult;
                    CSR_MSCRATCH: csrs_nxt.mscratch = csrresult;
                    CSR_MEPC: csrs_nxt.mepc = csrresult;
                    CSR_MCAUSE: csrs_nxt.mcause = csrresult;
                    CSR_MCYCLE: csrs_nxt.mcycle = csrresult;
                    CSR_MTVAL: csrs_nxt.mtval = csrresult;
                    CSR_SATP: csrs_nxt.satp = csrresult;
                    default: begin end
                endcase
            end
        end
    end

/*     // write
    always_comb begin
     csrs_nxt = csrs;
     csrs_nxt.mcycle = csrs.mcycle + 1;
     // Writeback: W stage
     unique if (wvalid) begin
         unique case(wa)
             CSR_MIE: csrs_nxt.mie = wd;
             CSR_MIP:  csrs_nxt.mip = wd;
             CSR_MTVEC: csrs_nxt.mtvec = wd;
             CSR_MSTATUS: csrs_nxt.mstatus = wd;
             CSR_MSCRATCH: csrs_nxt.mscratch = wd;
             CSR_MEPC: csrs_nxt.mepc = wd;
             CSR_MCAUSE: csrs_nxt.mcause = wd;
             CSR_MCYCLE: csrs_nxt.mcycle = wd;
             CSR_MTVAL: csrs_nxt.mtval = wd;
             default: begin
                        
             end
                 
         endcase
         csrs_nxt.mstatus.sd = csrs_nxt.mstatus.fs != 0;
     end else if (is_mret) begin
         csrs_nxt.mstatus.mie = csrs_nxt.mstatus.mpie;
         csrs_nxt.mstatus.mpie = 1'b1;
         csrs_nxt.mstatus.mpp = 2'b0;
         csrs_nxt.mstatus.xs = 0;
     end
     else begin end
    end
    assign pcselect = csrs.mepc; */

endmodule

`endif