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
    input logic iscsrD, iscsrE, iscsrM, iscsrW,
    input logic flushall, error, is_ecall, interrupt,
    input u64 csrpc, ecallpc, errpc
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

    assign branch = (dataD.ctl.op == CSR || dataD.ctl.op == CSRI || dataD.ctl.op == MRET || dataD.ctl.op == ECALL) || ((dataD.ctl.op == BZ && result == 1) || (dataD.ctl.op == BNZ && result == 0) || dataD.ctl.op == JAL || dataD.ctl.op == JALR);
    
    assign jump =   dataD.ctl.op == JAL                  ? dataD.pc + {{44{dataD.instr[31]}}, dataD.instr[19:12], dataD.instr[20], dataD.instr[30:21], 1'b0}
                  : dataD.ctl.op == JALR                 ? (dataD.srca + {{52{dataD.instr[31]}}, dataD.instr[31:20]}) & (~1)
                  : (dataD.ctl.op == BZ && result == 1)  ? dataD.pc + {{52{dataD.instr[31]}}, dataD.instr[7], dataD.instr[30:25], dataD.instr[11:8], 1'b0}
                  : (dataD.ctl.op == BNZ && result == 0) ? dataD.pc + {{52{dataD.instr[31]}}, dataD.instr[7], dataD.instr[30:25], dataD.instr[11:8], 1'b0}
                  : dataD.ctl.op == MRET                 ? csrpc 
                  : dataD.ctl.op == ECALL                ? ecallpc  
                //   : error                                ? errpc 
                //   : interrupt                            ? errpc
                //   : misalign                             ? errpc  
                //   : dataD.error == INSTR_MISALIGN               ? errpc                                                                                               
                  :                                        dataD.pc + 4;

    // always_ff @(posedge clk) begin
	// 	if(dataD.valid) $display("pc = %h flushall = %h csrpc = %h is_ecall = %h errpc = %h", dataD.pc, flushall, csrpc, is_ecall, errpc);
	// end

    logic misalign = (dataD.instr[13:12] == 2'b00 ? 0 
                   : dataD.instr[13:12] == 2'b01 ? result[0] != 'b0
                   : dataD.instr[13:12] == 2'b10 ? result[1:0] != 'b00
                   :                               result[2:0] != 'b000) && (dataD.ctl.op == LD || dataD.ctl.op == SD);

    // always_ff @(posedge clk)
    //     if(reset)
    //         dataE <= '0;
    //     else begin
            assign dataE.result = (dataD.ctl.op == JAL || dataD.ctl.op == JALR) ? dataD.pc + 4 : result;
            // assign dataE.ctl.op = ((misalign)) ? ECALL : dataD.ctl.op;
            assign dataE.ctl.op = dataD.ctl.op;
            assign dataE.ctl.alufunc = dataD.ctl.alufunc;
            assign dataE.ctl.regwrite = dataD.ctl.regwrite;
            assign dataE.ctl.memtoreg = dataD.ctl.memtoreg;
            assign dataE.ctl.memwrite = dataD.ctl.memwrite;
            assign dataE.dst = dataD.dst; 
            assign dataE.pc = dataD.pc;
            assign dataE.instr = dataD.instr;
            assign dataE.valid = ~stallm & dataD.valid;
            assign dataE.store_data = dataD.store_data;
            assign dataE.csrres = csrresult;
            assign dataE.error = dataD.error != NOERROR ? dataD.error :
                                 misalign ? (dataD.ctl.op == LD ? LOAD_MISALIGN : (dataD.ctl.op == SD ? STORE_MISALIGN : NOERROR)) : 
                                 NOERROR;
            // assign dataE.csr = dataD.csr;
            // assign dataE.csrdst = dataD.csrdst;
        // end

endmodule

`endif