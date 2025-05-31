`ifndef __CORE_SV
`define __CORE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/regfile/csrfile.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/pipeline_reg/pipeline_reg.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/writeback/writeback.sv"

`else

`endif

module core 
	import common::*;
	import pipes::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input logic trint, swint, exint
);
	/* TODO: Add your pipeline here. */
	
	u1 stallpc, stallf, stalld, stalle, stallm, stall_raw, stall, need_nop;


	// assign stallf = (dataE.ctl.op == LD);
	// assign stalld = stall_raw | stallpc | stall;
	// assign stalle = stallpc | stall;
	// assign stallm = stallpc | stall;
	// assign stalld = (dataD.rega != 0 && dataD.rega == dstE) || (dataD.regb != 0 && dataD.regb == dstE);
	// assign stallf = stallpc;
	assign stallm = dreq.valid && ~dresp.data_ok;
	// assign stall = dreq.valid && ~dresp.data_ok;

	u64 pc, pc_nxt, pc_prev;
	u1 branch;
	u64 jump;
	u1 branch_enable;
	u64 branch_target; 

	assign stallpc = ireq.valid && ~iresp.data_ok;

    // state_t state;

    // logic [4:0] temp_counter;

	always_ff @( posedge clk ) begin
		if(reset) begin
			pc <= 64'h8000_0000;
		end 
		else if(stallpc | stallm | stalld) begin
			pc <= pc;
		end
		// else if(branch_enable) begin
		// 	pc <= branch_target;
		// end
		else begin
			pc <= pc_nxt;
		end
	end

	always_ff @(posedge clk) begin
		if(reset) begin
			jump <= '0;
		end else if(branch | stallm) begin
			jump <= jump;
		end else if((!stallpc && !stalld && !stallm) || branch == '0) begin
			jump <= branch_target;
		end
	end
	
	always_ff @(posedge clk) begin
		if(reset) begin
			branch <= '0;
		end else if(stallm) begin
			branch <= branch;
		end
		else if((!stallpc && !stalld && !stallm) || branch == '0) begin
			branch <= branch_enable;
		end
	end

	// logic ireq_active;

	// // 更新请求活跃状态（时序逻辑）
    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         ireq_active <= 1'b1;
    //     end else begin
    //         if(iresp.data_ok) begin
	// 			if(stalld | stallm) begin
	// 				ireq_active <= 1'b0;
	// 			end
	// 		end
	// 		if(!stalld & !stallm) begin
	// 			ireq_active <= 1'b1;
	// 		end
    //     end
    // end

	assign ireq.valid = 1'b1;
	assign ireq.addr = pc;

	u32 raw_instr;

	assign raw_instr = iresp.data;

	fetch_data_t dataF, dataF_nxt;
	decode_data_t dataD, dataD_nxt;
	execute_data_t dataE, dataE_nxt;
	memory_data_t dataM, dataM_nxt;
	writeback_data_t dataW, dataW_nxt;
	
	creg_addr_t ra1, ra2;
	// csr_addr_t csraddr;  
	word_t rd1, rd2;
	// word_t csrdata;

	csr_addr_t csraddr;
	word_t csrdata;

	// assign csrdata = 64'b0;
	// assign csraddr = 12'b0;

	u1 flushF, stop;

	assign flushF = ireq.valid & ~iresp.data_ok;

	u5 dstD, dstE, dstM, dstW;
	// u1 branchD, branchE, branchM, branchW;

	assign dstD = (dataD.ctl.regwrite && dataD.valid) ? dataD.dst : 0;
	assign dstE = (dataE.ctl.regwrite && dataE.valid) ? dataE.dst : 0;
	assign dstM = (dataM.ctl.regwrite && dataM.valid) ? dataM.dst : 0;
	assign dstW = (dataW.ctl.regwrite && dataW.valid) ? dataW.dst : 0;

	// csr_addr_t csrD, csrE, csrM, csrW;

	// assign csrD = ((dataD.ctl.op == CSR || dataD.ctl.op == CSRI) && dataD.valid) ? dataD.instr[31:20] : 0;
	// assign csrE = ((dataE.ctl.op == CSR || dataE.ctl.op == CSRI) && dataE.valid) ? dataE.instr[31:20] : 0;
	// assign csrM = ((dataM.ctl.op == CSR || dataM.ctl.op == CSRI) && dataM.valid) ? dataM.instr[31:20] : 0;
	// assign csrW = ((dataW.ctl.op == CSR || dataW.ctl.op == CSRI) && dataW.valid) ? dataW.instr[31:20] : 0;

	// assign branchD = (dataD.ctl.op == JAL) || (dataD.ctl.op == JALR) || (dataD.ctl.op == BZ) || (dataD.ctl.op == BNZ);
	// assign branchE = (dataE.ctl.op == JAL) || (dataE.ctl.op == JALR) || (dataE.ctl.op == BZ) || (dataE.ctl.op == BNZ);
	// assign branchM = (dataM.ctl.op == JAL) || (dataM.ctl.op == JALR) || (dataM.ctl.op == BZ) || (dataM.ctl.op == BNZ);
	// assign branchW = (dataW.ctl.op == JAL) || (dataW.ctl.op == JALR) || (dataW.ctl.op == BZ) || (dataW.ctl.op == BNZ);

	// u12 csrs;

	logic flushall;
	// assign flushall = 1'b0;

	pipeline_reg pipeline_reg (
		.clk, .reset, 
		.flushF,
		.stallf, .stalld, .stalle, .stallm, .stall, .stallpc, .stall_raw,
		.ireq, .iresp, .dreq, .dresp,
		.dataF_nxt, .dataF,
		.dataD_nxt, .dataD,
		.dataE_nxt, .dataE,
		.dataM_nxt, .dataM,
		.dataW_nxt, .dataW,
		.need_nop,
		.branch,
		.branch_enable,
		.flushall
	);	

	regfile regfile(
		.clk, .reset,
		.ra1,
		.ra2,
		.rd1,
		.rd2
	);

	fetch fetch (
		.clk, .reset,
		.pcplus4(pc + 4),
		.pc_selected(pc_nxt),
		.dataF(dataF_nxt),
		.raw_instr(raw_instr),
		.pc(pc),
		.iresp,
		.dresp,
		.ireq,
		.dreq,
		.stallf, .stalld, .stalle, .stallm,
		.branch,
		.jump
	);

	decode decode (
		.clk, .reset,
		.dataF,
		.dataD(dataD_nxt),
		.ra1, .ra2, .rd1, .rd2,
		.ireq,
		.iresp, 
		.stallf, .stalld, .stalle, .stallm, .stall_raw,
		.dstD, .dstE, .dstM, .dstW,
		.dreq, .dresp,
		.branch,
		.csraddr,
		.csrdata,
		.csrD(((dataD.ctl.op == CSR || dataD.ctl.op == CSRI) && dataD.valid) ? dataD.instr[31:20] : 0),
		.csrE(((dataE.ctl.op == CSR || dataE.ctl.op == CSRI) && dataE.valid) ? dataE.instr[31:20] : 0),
		.csrM(((dataM.ctl.op == CSR || dataM.ctl.op == CSRI) && dataM.valid) ? dataM.instr[31:20] : 0),
		.csrW(((dataW.ctl.op == CSR || dataW.ctl.op == CSRI) && dataW.valid) ? dataW.instr[31:20] : 0),
		.iscsrD((dataD.ctl.op == CSR || dataD.ctl.op == CSRI) && dataD.valid),
		.iscsrE((dataE.ctl.op == CSR || dataE.ctl.op == CSRI) && dataE.valid),
		.iscsrM((dataM.ctl.op == CSR || dataM.ctl.op == CSRI) && dataM.valid),
		.iscsrW((dataW.ctl.op == CSR || dataW.ctl.op == CSRI) && dataW.valid)
	);

	execute execute(
		.clk, .reset,
		.dataD, 
		.dataE(dataE_nxt),
		.stallf, .stalld, .stalle, .stallm,
		.branch(branch_enable),
		.jump(branch_target),
		.iscsrD((dataD.ctl.op == CSR || dataD.ctl.op == CSRI) && dataD.valid),
		.iscsrE((dataE.ctl.op == CSR || dataE.ctl.op == CSRI) && dataE.valid),
		.iscsrM((dataM.ctl.op == CSR || dataM.ctl.op == CSRI) && dataM.valid),
		.iscsrW((dataW.ctl.op == CSR || dataW.ctl.op == CSRI) && dataW.valid)
	);

	memory memory(
		.clk, .reset,
		.dataE, 
		.dataM(dataM_nxt),
		.dreq,
		.dresp,
		.stallf, .stalld, .stalle, .stallm, .stall
	);

	writeback writeback(
		.clk, .reset,
		.dataM, 
		.dataW(dataW_nxt),
		.wvalid(dataM.ctl.regwrite),
		.regs(regfile.regs),
		.regs_nxt(regfile.regs_nxt)
	);

	csrfile csrfile(
		.clk, .reset,
		.csr_ra(csraddr),
		.csr_out(csrdata),
		.csr_wen(dataW.ctl.op == CSR || dataW.ctl.op == CSRI),
		.csr_wa(dataW.instr[31:20]),
		.csrresult(dataW.memaddr),
		.dataW,
		.flushall
	);

	// u1 commit_valid;
	// u64 pc_prev;
	// logic [63:0] pc_prev;
	// logic commit_ok;

	always_ff @(posedge clk) begin
		if(reset) begin
			pc_prev <= '0;
		end
		else if (dataW.valid) begin
			pc_prev <= dataW.pc;
		end
	end
	
	always_ff @(posedge clk) begin
		if(reset) begin
			pc_prev <= '0;
		end
		else if (dataW.instr != '0) begin
			pc_prev <= dataW.pc;
		end
	end

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (dataW.valid & dataW.pc != pc_prev),
		.pc                 (dataW.pc),
		.instr              (dataW.instr),
		.skip               ((dataW.ctl.op == LD || dataW.ctl.op == SD) && dataW.memaddr[31] == 0),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataW.ctl.regwrite),
		.wdest              ({3'b0, dataW.dst}),
		.wdata              (dataW.result)
	);

	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (regfile.regs_nxt[0]),
		.gpr_1              (regfile.regs_nxt[1]),
		.gpr_2              (regfile.regs_nxt[2]),
		.gpr_3              (regfile.regs_nxt[3]),
		.gpr_4              (regfile.regs_nxt[4]),
		.gpr_5              (regfile.regs_nxt[5]),
		.gpr_6              (regfile.regs_nxt[6]),
		.gpr_7              (regfile.regs_nxt[7]),
		.gpr_8              (regfile.regs_nxt[8]),
		.gpr_9              (regfile.regs_nxt[9]),
		.gpr_10             (regfile.regs_nxt[10]),
		.gpr_11             (regfile.regs_nxt[11]),
		.gpr_12             (regfile.regs_nxt[12]),
		.gpr_13             (regfile.regs_nxt[13]),
		.gpr_14             (regfile.regs_nxt[14]),
		.gpr_15             (regfile.regs_nxt[15]),
		.gpr_16             (regfile.regs_nxt[16]),
		.gpr_17             (regfile.regs_nxt[17]),
		.gpr_18             (regfile.regs_nxt[18]),
		.gpr_19             (regfile.regs_nxt[19]),
		.gpr_20             (regfile.regs_nxt[20]),
		.gpr_21             (regfile.regs_nxt[21]),
		.gpr_22             (regfile.regs_nxt[22]),
		.gpr_23             (regfile.regs_nxt[23]),
		.gpr_24             (regfile.regs_nxt[24]),
		.gpr_25             (regfile.regs_nxt[25]),
		.gpr_26             (regfile.regs_nxt[26]),
		.gpr_27             (regfile.regs_nxt[27]),
		.gpr_28             (regfile.regs_nxt[28]),
		.gpr_29             (regfile.regs_nxt[29]),
		.gpr_30             (regfile.regs_nxt[30]),
		.gpr_31             (regfile.regs_nxt[31])
	);

    DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);

	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (3),
		.mstatus            (csrfile.csrs_nxt.mstatus),
		.sstatus            (csrfile.csrs_nxt.mstatus & 64'h800000030001e000),
		.mepc               (csrfile.csrs_nxt.mepc),
		.sepc               (0),
		.mtval              (csrfile.csrs_nxt.mtval),
		.stval              (0),
		.mtvec              (csrfile.csrs_nxt.mtvec),
		.stvec              (0),
		.mcause             (csrfile.csrs_nxt.mcause),
		.scause             (0),
		.satp               (csrfile.csrs_nxt.satp),
		.mip                (csrfile.csrs_nxt.mip),
		.mie                (csrfile.csrs_nxt.mie),
		.mscratch           (csrfile.csrs_nxt.mscratch),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	);
`endif
endmodule
`endif