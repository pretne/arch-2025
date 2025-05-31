`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

module alu
	import common::*;(
	input u1 clk, reset,
	input word_t srca, srcb,
	input alufunc_t alufunc,
	output word_t result,
	output word_t csrres,
	input u1 choose,
	input u64 pc
);

	always_comb begin
        result = 0;
		csrres = 0;
        unique case (alufunc)
			ALU_CSRC: begin result = srcb; csrres = srcb & ~srca; end
			ALU_CSRS: begin result = srcb; csrres = srcb | srca; end
			ALU_CSRW: begin result = srcb; csrres = srca; end
			ALU_CSRCI: begin result = srca; csrres = srca & ~srcb; end
			ALU_CSRSI: begin result = srca; csrres = srca | srcb; end
			ALU_CSRWI: begin result = srca; csrres = srcb; end
			ADD: result = srca + srcb;
			SUB: result = srca - srcb;
			AND: result = srca & srcb;
			OR:  result = srca | srcb;
			XOR: result = srca ^ srcb;
			CPYB: result = srcb;
			AUI: result = pc + srcb;
			EQL: result = {63'b0, (srca == srcb)};
			SLT: result = $signed(srca) < $signed(srcb) ? 1 : 0;
            SLTU: result = {63'b0, $unsigned(srca) < $unsigned(srcb)};
			SLL: result = srca << srcb[5:0];
			SRL: result = $unsigned(srca) >> srcb[5:0];
			SRA: result = $signed(srca) >>> srcb[5:0];
			SLLW: result = srca << srcb[4:0];
			SRLW: result[31:0] = $unsigned(srca[31:0]) >> srcb[4:0];
			SRAW: result[31:0] = $signed(srca[31:0]) >>> srcb[4:0];
            default: result = 0;
        endcase
        if(choose) begin
			result = {{32{result[31]}}, result[31:0]};	
		end
    end
	
endmodule

`endif