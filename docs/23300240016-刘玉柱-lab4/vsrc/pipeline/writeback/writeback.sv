`ifndef _WRITEBACK_SV
`define _WRITEBACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module writeback
    import common::*;
    import pipes::*;(
    input  logic clk, reset, 
    input memory_data_t dataM,
    output writeback_data_t dataW,
    input logic wvalid,
    output logic [63:0] regs[31:0],
    output logic [63:0] regs_nxt[31:0]
);
    
    creg_addr_t wa;
    word_t wd;
    
    assign wa = dataM.dst;
    assign wd = dataM.result;

    always_ff @(posedge clk) begin
		regs_nxt <= regs;
		regs_nxt[0] <= '0;
	end

	for (genvar i = 1; i < 32; i++)
		always_comb
			regs[i] = (i == wa && wvalid) ? wd : regs_nxt[i];

    // always_ff @(posedge clk)
    //     if(reset)
    //         dataW <= '0;
    //     else begin
            assign dataW.result = dataM.result;
            assign dataW.ctl = dataM.ctl;
            assign dataW.dst = dataM.dst;
            assign dataW.pc = dataM.pc;
            assign dataW.instr = dataM.instr;
            assign dataW.valid = dataM.valid;
            assign dataW.memaddr = dataM.memaddr;
            // assign dataW.csrres = dataM.csrres;
            // assign dataW.csr = dataM.csr;
            // assign dataW.csrdst = dataM.csrdst;
        // end

endmodule

`endif