`ifndef __CSRFILE_SV
`define __CSRFILE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else

`endif

module csrfile 
	import common::*;
	import pipes::*;
    import csr_pkg::*;(
	input logic clk, reset,
    input u12 csr_ra,
    output word_t csr_out,
    input logic csr_wen,
    input u12 csr_wa,
    input word_t csrresult,
	input writeback_data_t dataW,
	output logic flushall
);

csr_regs_t csrs, csrs_nxt;
word_t csr_wd;

always_comb begin
	unique case(csr_ra)
		CSR_MIE: begin csr_out = csrs_nxt.mie; end
		CSR_MIP: begin csr_out = csrs_nxt.mip; end
		CSR_MTVEC: begin csr_out = csrs_nxt.mtvec; end
		CSR_MSTATUS: begin csr_out = csrs_nxt.mstatus; end
		CSR_MSCRATCH: begin csr_out = csrs_nxt.mscratch; end
		CSR_MEPC: begin csr_out = csrs_nxt.mepc; end
		CSR_SATP: begin csr_out = csrs_nxt.satp; end
		CSR_MCAUSE: begin csr_out = csrs_nxt.mcause; end
		CSR_MCYCLE: begin csr_out = csrs_nxt.mcycle; end
		CSR_MTVAL: begin csr_out = csrs_nxt.mtval; end
		CSR_SSTATUS: begin csr_out = csrs_nxt.mstatus & SSTATUS_MASK; end
		default: csr_out = '0;
	endcase
end

// assign flushall = 0;

always_comb begin
	flushall = csr_wen;
	csrs_nxt = csrs;
	csrs_nxt.mcycle = csrs.mcycle + 1;
	if (csr_wen) begin
		// flushall = 1;
		csr_wd = csrresult;
		// unique case(dataW.ctl.alufunc)
		// 	ALU_CSRW: csr_wd = csrresult;
		// 	ALU_CSRS: csr_wd = csrresult;
		// 	ALU_CSRC: csr_wd = csrresult;
		// 	default: ;
		// endcase
		unique case(csr_wa)
			CSR_MIE: csrs_nxt.mie = csr_wd;
			CSR_MIP: csrs_nxt.mip = csr_wd & MIP_MASK;
			CSR_MTVEC: csrs_nxt.mtvec = csr_wd & MTVEC_MASK;
			CSR_MSTATUS: csrs_nxt.mstatus = csr_wd & MSTATUS_MASK;
			CSR_MSCRATCH: csrs_nxt.mscratch = csr_wd;
			CSR_MEPC: csrs_nxt.mepc = csr_wd;
			CSR_SATP: csrs_nxt.satp = csr_wd;
			CSR_MCAUSE: csrs_nxt.mcause = csr_wd;
			CSR_MCYCLE: csrs_nxt.mcycle = csr_wd;
			CSR_MTVAL: csrs_nxt.mtval = csr_wd;
			CSR_SSTATUS: csrs_nxt.mstatus = csr_wd & SSTATUS_MASK;
			default: ;
		endcase
	end
end

always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		csrs <= '0;
		// csrs.mcause[1] <= 1'b1;
        // csrs.mepc[31]  <= 1'b1;
	end else begin
		csrs <= csrs_nxt;
	end
end


endmodule

`endif