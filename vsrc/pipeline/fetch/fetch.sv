`ifndef __FETCH_SV
`define __FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/decode/decoder.sv"
`else

`endif 

module fetch 
    import common::*;
    import pipes::*;(
    input u1 clk, reset,
    input u64 pcplus4,
    output u64 pc_selected,
    output fetch_data_t dataF,
    input u32 raw_instr,
    input u64 pc,
    input ibus_resp_t iresp,
    input dbus_resp_t dresp,
    output dbus_req_t dreq,
    output ibus_req_t ireq,
    output logic stallf, 
    input logic stalld, stalle, stallm,
    input u1 branch,
    input u64 jump,
    input logic flushall, error, is_ecall,
    input u64 csrpc, errpc
);

    assign pc_selected = branch ? jump :
                        //  error ? errpc :
                        //  flushall ? csrpc : 
                         pcplus4;

    // assign stallf = (~iresp.data_ok);

    // always_ff @(posedge clk) begin
	// 	if(dataF.valid) $display("pc = %h branch = %h jump = %h error = %h errpc = %h flushall = %h csrpc = %h", pc, branch, jump, error, errpc, flushall, csrpc);
	// end

    // assign stallf = ireq.valid && ~iresp.data_ok;

    // always_ff @(posedge clk)
    //     if(reset)
    //         dataF <= '0;
    //     else begin
            assign dataF.pc = pc;
            assign dataF.instr = raw_instr;
            assign dataF.valid = ~stalld & ~stallm & iresp.data_ok;
            assign dataF.error = pc[1:0] == 'b00 ? NOERROR : INSTR_MISALIGN;
        // end

endmodule



`endif


