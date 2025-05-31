`ifndef _MEMORY_SV
`define _MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module memory
    import common::*;
    import pipes::*;
    import csr_pkg::*;(
    input  logic clk, reset, 
    input  execute_data_t dataE,
    output memory_data_t dataM,
    output dbus_req_t dreq,
    input dbus_resp_t dresp,
    output logic stallf, stalld, stalle, stallm, stall,
    input satp_t satp,
    input u2 mode,
    input logic flushall, error, is_ecall
);

    msize_t size;
    strobe_t strobe;
    logic load, store;
    addr_t addr = dataE.result;

    logic req_active;
    logic new_request;

    assign load = dataE.ctl.op == LD;
    assign store = dataE.ctl.op == SD;

    assign new_request = (load | store) & dataE.valid;

    // 更新请求活跃状态（时序逻辑）
    always_ff @(posedge clk) begin
        if (reset) begin
            req_active <= 1'b0;
        end else begin
            if (dresp.data_ok) begin
                // 响应完成时清除活跃状态
                req_active <= 1'b0;
            end else if (new_request && !req_active) begin
                // 新请求且当前无活跃请求时激活
                req_active <= 1'b1;
            end
        end
    end

    u64 in = dataE.store_data;
    u64 off = {58'b0, addr[2:0], 3'b0};

    // always_ff @(posedge clk) begin
    //     if(reset) dreq <= '0;
    //     else if(dresp.data_ok && dresp.addr_ok) dreq <= '0;
    //     else if((load | store) & ~dreq.valid) begin
    //         dreq.valid <= '1;
    //         dreq.addr <= dataE.result;
    //         dreq.size <= size;
    //         if(store) begin
    //             dreq.data <= in << off;
    //             case(size)
    //                 MSIZE1: dreq.strobe <= 8'h01 << off;
    //                 MSIZE2: dreq.strobe <= 8'h03 << off;
    //                 MSIZE4: dreq.strobe <= 8'h0f << off;
    //                 MSIZE8: dreq.strobe <= 8'hff << off;
    //                 default: dreq.strobe <= '0;
    //             endcase
    //         end
    //     end
    // end

    // 输出 valid 信号：活跃状态或新请求（组合逻辑）
    assign dreq.valid = req_active || new_request;

    assign dreq.addr = addr;
    assign dreq.size = size;
    assign dreq.strobe = store ? strobe << addr[2:0] : 0;

    assign dreq.data = in << off;

    // always_comb begin
    //     case(size) 
    //         MSIZE1: begin
    //             case(addr[2:0]) 
    //                 3'b000: dreq.data = {56'b0, in[7:0]};
    //                 3'b001: dreq.data = {48'b0, in[7:0], 8'b0};
    //                 3'b010: dreq.data = {40'b0, in[7:0], 16'b0};
    //                 3'b011: dreq.data = {32'b0, in[7:0], 24'b0};
    //                 3'b100: dreq.data = {24'b0, in[7:0], 32'b0};
    //                 3'b101: dreq.data = {16'b0, in[7:0], 40'b0};
    //                 3'b110: dreq.data = {8'b0, in[7:0], 48'b0};
    //                 3'b111: dreq.data = {in[7:0], 56'b0};
    //             endcase
    //         end

    //         MSIZE2: begin
    //             case(addr[2:0]) 
    //                 3'b000: dreq.data = {48'b0, in[15:0]};
    //                 3'b010: dreq.data = {32'b0, in[15:0], 16'b0};
    //                 3'b100: dreq.data = {16'b0, in[15:0], 32'b0};
    //                 3'b110: dreq.data = {in[15:0], 48'b0};
    //                 default: dreq.data = {48'b0, in[15:0]};
    //             endcase
    //         end

    //         MSIZE4: begin
    //             case(addr[2:0]) 
    //                 3'b000: dreq.data = {32'b0, in[31:0]};
    //                 3'b100: dreq.data = {in[31:0], 32'b0};
    //                 default: dreq.data = {32'b0, in[31:0]};
    //             endcase
    //         end

    //         MSIZE8: begin
    //             dreq.data = in;
    //         end

    //         default: dreq.data = in;
    //     endcase
    // end

    // always_comb begin
    //     dreq.data = dataE.store_data;
    //     for (int i = 0;i < 8;i++) begin
    //         dreq.data = dreq.data << addr[2:0];
    //     end
    // end

    always_comb case (dataE.instr[13:12])
        2'b00: begin size = MSIZE1; strobe = 8'b00000001; end //sb
        2'b01: begin size = MSIZE2; strobe = 8'b00000011; end //sh
        2'b10: begin size = MSIZE4; strobe = 8'b00001111; end //sw
        2'b11: begin size = MSIZE8; strobe = 8'b11111111; end //sd
    endcase

    // logic misalign;
    // always_comb case(dataE.instr[13:12])
    //     'b00: misalign =                      0; // b
    //     'b01: misalign = dataE.result[0]   != 0; // h
    //     'b10: misalign = dataE.result[1:0] != 0; // w
    //     'b11: misalign = dataE.result[2:0] != 0; // d
    // endcase

    // logic misalign = dataE.instr[13:12] == 2'b00 ? 0 
    //                : dataE.instr[13:12] == 2'b01 ? dataE.result[0] != 'b0
    //                : dataE.instr[13:12] == 2'b10 ? dataE.result[1:0] != 'b00
    //                :                               dataE.result[2:0] != 'b000;

    // always_comb case (dataE.instr[13:12])
    //     2'b00: begin 
    //         size = MSIZE1;
    //         case(addr[2:0]) 
    //             3'b000: strobe = 8'b00000001;
    //             3'b001: strobe = 8'b00000010;
    //             3'b010: strobe = 8'b00000100;
    //             3'b011: strobe = 8'b00001000;
    //             3'b100: strobe = 8'b00010000;
    //             3'b101: strobe = 8'b00100000;
    //             3'b110: strobe = 8'b01000000;
    //             3'b111: strobe = 8'b10000000;
    //         endcase
    //     end //sb

    //     2'b01: begin 
    //         size = MSIZE2; 
    //         case(addr[2:0])
    //             3'b000: strobe = 8'b00000011; 
    //             3'b010: strobe = 8'b00001100; 
    //             3'b100: strobe = 8'b00110000; 
    //             3'b110: strobe = 8'b11000000; 
    //             default: strobe = 8'b00000000;
    //         endcase
    //     end //sh

    //     2'b10: begin 
    //         size = MSIZE4; 
    //         case(addr[2:0])
    //             3'b000: strobe = 8'b00001111; 
    //             3'b100: strobe = 8'b11110000; 
    //             default: strobe = 8'b00000000; 
    //         endcase
    //     end //sw

    //     2'b11: begin size = MSIZE8; strobe = 8'b11111111; end //sd
    // endcase

    u64 out, data;
    assign data = dresp.data >> off;

    always_comb case (dataE.instr[14:12])
        3'b000: out = {{56{data[7]}}, data[7:0]}; // lb
        3'b001: out = {{48{data[15]}}, data[15:0]}; // lh
        3'b010: out = {{32{data[31]}}, data[31:0]}; // lw
        3'b011: out = data; // ld
        3'b100: out = {{56'b0}, data[7:0]}; // lbu
        3'b101: out = {{48'b0}, data[15:0]}; // lhu
        3'b110: out = {{32'b0}, data[31:0]}; // lwu
        3'b111: out = 0; // not used
    endcase

//     reg [63:0] prev_addr;
// always @(posedge clk) begin
//     if (addr == 64'h80028768) begin
//         $display("New PC: 0x%h", dataE.pc);
//     end
//     prev_addr <= addr;
// end

    // always_ff @(posedge clk) begin
	// 	if(dataM.valid & dataM.pc <= 64'h80006084 && misalign) $display("pc = %h misalign = %h error = %h", dataM.pc, misalign, dataM.error);
	// end

    // word_t csrresult;
    // assign csrrresult = dataE.csrres;
    
    // always_ff @(posedge clk)
    //     if(reset)
    //         dataM <= '0;
    //     else begin
            assign dataM.result = (load | store) ? out : dataE.result;
            assign dataM.ctl = dataE.ctl;
            assign dataM.dst = dataE.dst; 
            assign dataM.pc = dataE.pc;
            assign dataM.instr = dataE.instr;
            assign dataM.valid = ~stallm & dataE.valid;
            assign dataM.memaddr = (load | store) ? dataE.result : dataE.csrres;
            assign dataM.error   = dataE.error != NOERROR ? dataE.error :
                        // misalign ? (load ? LOAD_MISALIGN : STORE_MISALIGN) :
                        NOERROR;
            // assign dataM.csrres = dataE.csrres;
            // assign dataM.csrdst = dataE.csrdst;
            // assign dataM.csr = dataE.csr;
        // end

endmodule

`endif