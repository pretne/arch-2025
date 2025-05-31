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
    input u64 jump
);

    assign pc_selected = branch ? jump : pcplus4;

    // assign stallf = (~iresp.data_ok);

    // assign stallf = ireq.valid && ~iresp.data_ok;

    // always_ff @(posedge clk)
    //     if(reset)
    //         dataF <= '0;
    //     else begin
            assign dataF.pc = pc;
            assign dataF.instr = raw_instr;
            assign dataF.valid = ~stalld & ~stallm & iresp.data_ok;
        // end

endmodule



`endif


