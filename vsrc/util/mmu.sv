`ifndef __MMU_SV
`define __MMU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module mmu
    import common::*;
    import pipes::*; 
    import csr_pkg::*;(
        input u1 clk, reset,
        input satp_t satp,
        input u2 mode,

        input u1 mmu_req_valid,
        output u1 mmu_ok,
        
        input cbus_req_t vreq,
        input cbus_resp_t presp,
        output cbus_req_t preq
    );

    u64 va;
    assign va = vreq.addr;

    u64 mem_rdata;
    assign mem_rdata = presp.data;

    mmu_state_t state, next_state;

    u9 vpn[2:0];
    u44 root_ppn;
    u64 pte;
    u2 level;
    u12 page_offset;

    assign vpn[0] = va[20:12];
    assign vpn[1] = va[29:21];
    assign vpn[2] = va[38:30];
    assign page_offset = va[11:0];

    /* FSM reg */
    always_ff @(posedge clk or posedge reset) begin 
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    /* State Transfer Logic */
    always_comb begin
        next_state = state;
        unique case (state)
            IDLE: begin
                if (mmu_req_valid) begin 
                    next_state = READ_L1;
                    if (mode == 2'd3) next_state = READ_DATA;
                end
            end
            READ_L1: begin next_state = WAIT_L1; end
            WAIT_L1: begin
                if (presp.ready) begin
                    next_state = (mem_rdata[1] || mem_rdata[2]) ? READ_DATA : READ_L2;
                end
            end
            READ_L2: begin next_state = WAIT_L2; end
            WAIT_L2: begin
                if (presp.ready) begin
                    next_state = (mem_rdata[1] || mem_rdata[2]) ? READ_DATA : READ_L3;
                end
            end
            READ_L3: begin next_state = WAIT_L3; end
            WAIT_L3: begin
                if (presp.ready) begin
                    next_state = READ_DATA;
                end
            end
            READ_DATA: next_state = presp.ready ? OUTPUT : WAIT_DATA;
            WAIT_DATA: if (presp.ready) next_state = OUTPUT;
            OUTPUT: if (!mmu_req_valid) next_state = IDLE;
        endcase
    end

    /* root addr */
    always_ff @(posedge clk or posedge reset) begin
        if (state == IDLE && mmu_req_valid) begin
            root_ppn <= satp.ppn;
        end
    end

    /* mem req */
    u64 table_base, pte_addr;

    always_comb begin
        table_base = (state == READ_L1 || state == WAIT_L1) ? {8'b0, root_ppn, 12'b0} : 
                     (state == READ_L2 || state == WAIT_L2) ? {8'b0, pte[53:10], 12'b0} :
                     (state == READ_L3 || state == WAIT_L3) ? {8'b0, pte[53:10], 12'b0} : 64'b0;

        level = (state == READ_L1 || state == WAIT_L1) ? 2 :
                (state == READ_L2 || state == WAIT_L2) ? 1 :
                (state == READ_L3 || state == WAIT_L3) ? 0 : 0;
 
        pte_addr = table_base + {52'b0, vpn[level], 3'b000};
    end   

    assign preq.valid = (
        state == READ_L1 || state == WAIT_L1 ||
        state == READ_L2 || state == WAIT_L2 ||
        state == READ_L3 || state == WAIT_L3 || 
        state == READ_DATA || state == WAIT_DATA
    );
    // assign preq.addr = pte_addr;
    assign preq.addr =  (mode == 2'd3) ? vreq.addr :
                        (state == READ_DATA || state == WAIT_DATA) ? {8'b0, pte[53:10], page_offset} : pte_addr;
    assign preq.size = vreq.size;
    assign preq.data = vreq.data;
    assign preq.strobe = (state == READ_DATA || state == WAIT_DATA) ? vreq.strobe : 8'b0;
    assign preq.is_write = vreq.is_write;

    always_ff @(posedge clk) begin
        if (presp.ready && (
            state == WAIT_L1 || state == WAIT_L2 || state == WAIT_L3
        )) pte <= mem_rdata;
    end

    // assign mmu_ok = (state == OUTPUT) ? 1'b1 : 1'b0;
    assign mmu_ok = state == WAIT_DATA && presp.ready;

endmodule 


`endif 