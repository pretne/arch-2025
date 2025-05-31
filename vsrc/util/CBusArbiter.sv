`ifndef __CBUSARBITER_SV
`define __CBUSARBITER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "util/mmu.sv"
`else

`endif
/**
 * this implementation is not efficient, since
 * it adds one cycle lantency to all requests.
 */

module CBusArbiter
	import common::*; import pipes::*; import csr_pkg::*;#(
    parameter int NUM_INPUTS = 2,  // NOTE: NUM_INPUTS >= 1

    localparam int MAX_INDEX = NUM_INPUTS - 1
) (
    input logic clk, reset,

    input satp_t satp,
    input u2 mode,

    input  cbus_req_t  [MAX_INDEX:0] ireqs,
    output cbus_resp_t [MAX_INDEX:0] iresps,
    output cbus_req_t  oreq,
    input  cbus_resp_t oresp
);
    logic busy;
    int index, select;
    cbus_req_t saved_req, selected_req;

    u1 mmu_ok = 1;
    // mmu mmu (
    //     .clk, .reset,
    //     .satp, .mode,

    //     .mmu_req_valid(busy ? ireqs[index].valid : 1'b0),
    //     .mmu_ok,

    //     .vreq(ireqs[index]),
    //     .presp(oresp),
    //     .preq(oreq)
    // );

    // assign oreq = ireqs[index];
    assign oreq = busy ? ireqs[index] : '0;  // prevent early issue
    assign selected_req = ireqs[select];

    // select a preferred request
    always_comb begin
        select = 0;

        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (ireqs[i].valid) begin
                select = i;
                break;
            end
        end
    end

    // feedback to selected request
    always_comb begin
        iresps = '0;

        if (busy) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (index == i && (mmu_ok || mode == 2'd3))
                    iresps[i] = oresp;
            end
        end
    end

    always_ff @(posedge clk)
    if (~reset) begin
        if (busy) begin
            if (oresp.last)
                {busy, saved_req} <= '0;
        end else begin
            // if not valid, busy <= 0
            busy <= selected_req.valid;
            index <= select;
            saved_req <= selected_req;
        end
    end else begin
        {busy, index, saved_req} <= '0;
    end

    `UNUSED_OK({saved_req});
endmodule



`endif