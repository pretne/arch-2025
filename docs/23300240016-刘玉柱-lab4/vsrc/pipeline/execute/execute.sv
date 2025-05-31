`ifndef __EXCUTE_SV
`define __EXCUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu.sv"
`endif

module execute
    import common::*;
	import pipes::*;(
    input  u1 clk, reset,
    input  decode_data_t dataD,
    output execute_data_t dataE,
    input logic stallf, stalld, stalle, stallm,
    output u1 branch,
    output u64 jump,
    input logic iscsrD, iscsrE, iscsrM, iscsrW
);
    word_t result, csrresult;

    alu alu_inst(
        .clk(clk),
        .reset(reset),
        .srca(dataD.srca),
        .srcb(dataD.srcb),
        .alufunc(dataD.ctl.alufunc),
        .result(result),
        .csrres(csrresult),
        .choose(dataD.ctl.op == ALUW || dataD.ctl.op == ALUIW),
        .pc(dataD.pc)
    );

    assign branch = (dataD.ctl.op == CSR || dataD.ctl.op == CSRI) || ((dataD.ctl.op == BZ && result == 1) || (dataD.ctl.op == BNZ && result == 0) || dataD.ctl.op == JAL || dataD.ctl.op == JALR);
    
    assign jump =   dataD.ctl.op == JAL                  ? dataD.pc + {{44{dataD.instr[31]}}, dataD.instr[19:12], dataD.instr[20], dataD.instr[30:21], 1'b0}
                  : dataD.ctl.op == JALR                 ? (dataD.srca + {{52{dataD.instr[31]}}, dataD.instr[31:20]}) & (~1)
                  : (dataD.ctl.op == BZ && result == 1)  ? dataD.pc + {{52{dataD.instr[31]}}, dataD.instr[7], dataD.instr[30:25], dataD.instr[11:8], 1'b0}
                  : (dataD.ctl.op == BNZ && result == 0) ? dataD.pc + {{52{dataD.instr[31]}}, dataD.instr[7], dataD.instr[30:25], dataD.instr[11:8], 1'b0}
                  :                                        dataD.pc + 4;

    // always_ff @(posedge clk)
    //     if(reset)
    //         dataE <= '0;
    //     else begin
            assign dataE.result = (dataD.ctl.op == JAL || dataD.ctl.op == JALR) ? dataD.pc + 4 : result;
            assign dataE.ctl = dataD.ctl;
            assign dataE.dst = dataD.dst; 
            assign dataE.pc = dataD.pc;
            assign dataE.instr = dataD.instr;
            assign dataE.valid = ~stallm & dataD.valid;
            assign dataE.store_data = dataD.store_data;
            assign dataE.csrres = csrresult;
            // assign dataE.csr = dataD.csr;
            // assign dataE.csrdst = dataD.csrdst;
        // end

endmodule

`endif