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
	input execute_data_t dataW,
	output logic flushall,
	output u64 csrpc,
	input logic trint, swint, exint
);

csr_regs_t csrs, csrs_nxt;
word_t csr_wd;

logic error = dataW.error != NOERROR;
logic is_ecall = dataW.ctl.op == ECALL;
logic interrupt = (mode != 2'd3 || csrs.mstatus.mie) && ((trint && csrs.mie[7] && csrs.mip[7]) || (swint && csrs.mie[3] && csrs.mip[3]) || (exint & csrs.mie[11] & csrs.mip[11]));

u2 mode, mode_nxt;

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
// assign flushall = (dataW.ctl.op == MRET);
assign flushall = dataW.ctl.op == MRET;
// assign csrpc = '0;

// assign mode_nxt = 2'd3;

always_comb begin
	csrpc = '0;
	// flushall = 0;
	mode_nxt = mode;
	csrs_nxt = csrs;
	csrs_nxt.mcycle = csrs.mcycle + 1;
	// if(dataW.valid && dataW.ctl.op == ECALL) begin
	// 	csrs_nxt.mepc = dataW.pc;
	// 	csrs_nxt.mcause[63:0] = 64'b0;
	// 	if(mode == 2'b0) csrs_nxt.mcause[62:0] = 63'd8;
	// 	else if(mode == 2'd3) csrs_nxt.mcause[62:0] = 63'd11;
	// 	csrs_nxt.mstatus.mpie = csrs.mstatus.mie;
	// 	csrs_nxt.mstatus.mie = '0;
	// 	csrs_nxt.mstatus.mpp = mode;
	//  	mode_nxt = 2'd3;
	// end
	if((dataW.valid && (is_ecall))) begin
		csrs_nxt.mepc = dataW.pc;
		csrs_nxt.mcause[63:0] = 64'b0;
		unique case(dataW.error)
			INSTR_MISALIGN: csrs_nxt.mcause[62:0] = 63'd0;
			EDECODE: csrs_nxt.mcause[62:0] = 63'd2;
			LOAD_MISALIGN: csrs_nxt.mcause[62:0] = 63'd4;
			STORE_MISALIGN: csrs_nxt.mcause[62:0] = 63'd6;
			default: begin
				if(mode == 2'b0) csrs_nxt.mcause[62:0] = 63'd8;
				else if(mode == 2'd3) csrs_nxt.mcause[62:0] = 63'd11;
			end
		endcase
		csrs_nxt.mstatus.mpie = csrs.mstatus.mie;
		csrs_nxt.mstatus.mie = '0;
		csrs_nxt.mstatus.mpp = mode;
	 	mode_nxt = 2'd3;
	end
	else if (dataW.valid && interrupt) begin
		mode_nxt = 2'd3;
        // csrpc = csrs.mtvec;
        csrs_nxt.mepc = dataW.pc;
        csrs_nxt.mcause[62:0] = 63'b0;
        csrs_nxt.mcause[63] = 1'b1;
        if (trint) csrs_nxt.mcause[62:0] = 63'd7;
        else if (swint) csrs_nxt.mcause[62:0] = 63'd3;
        else if (exint) csrs_nxt.mcause[62:0] = 63'd11;
        csrs_nxt.mstatus.mpie = csrs.mstatus.mie;
        csrs_nxt.mstatus.mie = '0;
        csrs_nxt.mstatus.mpp = mode;
	end	
	else if (csr_wen) begin
		// flushall = 1;
		// csrpc = dataW.pc + 4;
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
	else if (dataW.valid && flushall) begin
		// flushall = 1;
		// csrpc = csrs_nxt.mepc;
		csrs_nxt.mstatus.mie = csrs.mstatus.mpie;
		csrs_nxt.mstatus.mpie = 1'b1;
		mode_nxt = csrs.mstatus.mpp;
		csrs_nxt.mstatus.mpp = 2'b0;
		csrs_nxt.mstatus.xs = '0;
	end
	else begin
		// flushall = 0;
	end
end

always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		csrs <= '0;
		mode <= 2'd3;
		csrs.mcause[1] <= 1'b1;
        csrs.mepc[31]  <= 1'b1;
	end else begin
		csrs <= csrs_nxt;
		mode <= mode_nxt;
	end
end


endmodule

`endif