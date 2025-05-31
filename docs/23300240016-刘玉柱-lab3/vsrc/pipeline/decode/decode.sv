`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`include "pipeline/decode/immediate.sv"
`else

`endif

module decode
    import common::*;
    import pipes::*;(
    input u1 clk, reset,
    input fetch_data_t dataF,
    output decode_data_t dataD,
    output creg_addr_t ra1, ra2,
    input word_t rd1, rd2,
    input ibus_req_t ireq,
    input ibus_resp_t iresp,
    output logic stallf, stalld, stalle, stallm, stall_raw,
    input u5 dstD, dstE, dstM, dstW,
    output dbus_req_t dreq,
    input dbus_resp_t dresp,
    input u1 branch
);

    control_t ctl;

    // assign stall_raw = bubble;

    decoder decoder (
        .raw_instr(dataF.instr),
        .ctl(ctl)
    );

    assign ra1 = dataF.instr[19:15];
    assign ra2 = dataF.instr[24:20];

    word_t temp1, temp2;
    logic bubble, bubble1, bubble2;

    assign bubble1 = ra1 != 0 && (ra1 == dstD || ra1 == dstE || ra1 == dstM);
    assign bubble2 = ra2 != 0 && (ra2 == dstD || ra2 == dstE || ra2 == dstM);

    immediate immediate(
        .scra(rd1),
        .scrb(rd2),
        .ctl(ctl),
        .instr(dataF.instr),
        .temp1,
        .temp2,
        .bubble,
        .bubble1,
        .bubble2
    );

    assign stalld = bubble;

//         reg [63:0] prev_addr;
// always @(posedge clk) begin
//     if (addr == 64'h80028768) begin
//         $display("New PC: 0x%h", dataE.pc);
//     end
//     prev_addr <= addr;
// end
    
    // always_ff @(posedge clk)
    //     if(reset)
    //         stall_raw <= 0;
    //     else begin
    //         if(ctl.op == LD || ctl.op == SD) 
    //             stall_raw <= 1;
    //         if(dresp.data_ok)
    //             stall_raw <= 0;

    // always_ff @(posedge clk)
    //     if(reset)
    //         dataD <= '0;
    //     else begin
            assign dataD.pc = dataF.pc;
            assign dataD.instr = dataF.instr;
            assign dataD.valid = ~stalld & ~stallm & dataF.valid;
            assign dataD.ctl = ctl;
            assign dataD.dst = dataF.instr[11:7];
            assign dataD.srca = temp1;
            assign dataD.srcb = temp2;
            assign dataD.rega = ra1;
            assign dataD.regb = ra2;
            assign dataD.store_data = rd2;
        // end
    
endmodule


`endif
