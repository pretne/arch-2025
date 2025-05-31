`ifndef __IMMEDIATE_SV
`define __IMMEDIATE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module immediate
	import common::*;
	import pipes::*;(
    input  word_t    scrb, scra,
    input  control_t ctl,
    input  u32    instr,
    output word_t temp1, temp2,
    output logic bubble,
    input logic bubble1, bubble2
);
    always_comb begin
        temp1 = scra;
        temp2 = scrb;
        unique case (ctl.op)
            ALUW: begin
                bubble = bubble1 | bubble2;
            end

            ALU: begin
                bubble = bubble1 | bubble2;
            end

            ALUI, ALUIW, LD: begin
                temp2 = {{52{instr[31]}}, instr[31:20]};
                bubble = bubble1;
            end

            LUI: begin
                temp2 = {{32{instr[31]}}, instr[31:12], 12'b0};
                bubble = bubble1;
            end

            SD: begin
                temp2 = {{52{instr[31]}}, instr[31:25], instr[11:7]};
                bubble = bubble1 | bubble2;
            end

            AUIPC: begin
                temp2 = {{32{instr[31]}}, instr[31:12], 12'b0};
                bubble = 0;
            end

            JAL: begin
                bubble = 0;
            end

            JALR: begin
                bubble = bubble1;
            end

            default: begin
                bubble = bubble1 | bubble2;
            end
        endcase 
    end
endmodule

`endif