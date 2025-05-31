`ifndef __REGFILE_SV
`define __REGFILE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module regfile
	import common::*;
    import pipes::*;(
	input logic clk, reset,
	input creg_addr_t ra1, ra2,
	output word_t rd1, rd2
);
	logic [63:0] regs[31:0], regs_nxt[31:0];

	assign rd1 = (ra1 != 0) ? regs[ra1] : 0;
	assign rd2 = (ra2 != 0) ? regs[ra2] : 0;

endmodule

`endif