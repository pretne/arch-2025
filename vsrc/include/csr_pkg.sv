`ifndef __CSR_PKG_SV
`define __CSR_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif
package csr_pkg;
	import common::*;

	// csrs
	 parameter u12 CSR_MHARTID = 12'hf14;
  parameter u12 CSR_MIE = 12'h304;
  parameter u12 CSR_MIP = 12'h344;
  parameter u12 CSR_MTVEC = 12'h305;
  parameter u12 CSR_MSTATUS = 12'h300;
  parameter u12 CSR_MSCRATCH = 12'h340;
  parameter u12 CSR_MEPC = 12'h341;
  parameter u12 CSR_SATP = 12'h180;
  parameter u12 CSR_MCAUSE = 12'h342;
  parameter u12 CSR_MCYCLE = 12'hb00;
  parameter u12 CSR_MTVAL = 12'h343;
  parameter u12 CSR_PMPADDR0 = 12'h3b0;
  parameter u12 CSR_PMPCFG0 = 12'h3a0;
  parameter u12 CSR_MEDELEG = 12'h302;
  parameter u12 CSR_MIDELEG = 12'h303;
  parameter u12 CSR_STVEC = 12'h105;
  parameter u12 CSR_SSTATUS = 12'h100;
  parameter u12 CSR_SSCRATCH = 12'h140;
  parameter u12 CSR_SEPC = 12'h141;
  parameter u12 CSR_SCAUSE = 12'h142;
  parameter u12 CSR_STVAL = 12'h143;
  parameter u12 CSR_SIE = 12'h104;
  parameter u12 CSR_SIP = 12'h144;

  parameter u64 MSTATUS_MASK = 64'h7e79bb;
  parameter u64 SSTATUS_MASK = 64'h800000030001e000;
  parameter u64 MIP_MASK = 64'h333;
  parameter u64 MTVEC_MASK = ~(64'h2);
  parameter u64 MEDELEG_MASK = 64'h0;
  parameter u64 MIDELEG_MASK = 64'h0;


	typedef struct packed {
		reg sd;
		reg [MXLEN-2-36:0] wpri1;
		reg[1:0] sxl;
		reg[1:0] uxl;
		reg[8:0] wpri2;
		reg tsr;
		reg tw;
		reg tvm;
		reg mxr;
		reg sum;
		reg mprv;
		reg[1:0] xs;
		reg[1:0] fs;
		reg[1:0] mpp;
		reg[1:0] wpri3;
		reg spp;
		reg mpie;
		reg wpri4;
		reg spie;
		reg upie;
		reg mie;
		reg wpri5;
		reg sie;
		reg uie;
	} mstatus_t;

	typedef struct packed {
		u4 mode;
		u16 asid;
		u44 ppn;
	} satp_t;

	typedef struct packed {
		reg[63:0]
		mhartid, // Hardware thread Id, read-only as 0 in this work
		mie,	 // Machine interrupt-enable register
		mip,	 // Machine interrupt pending
		mtvec;	 // Machine trap-handler base address
		mstatus_t
		mstatus; // Machine status register
		reg[63:0]
		mscratch, // Scratch register for machine trap handlers
		mepc;	 // Machine exception program counter
		satp_t satp;	 // Supervisor address translation and protection
		reg[63:0]
		mcause,  // Machine trap cause
		mcycle,  // Counter
		mtval;
	} csr_regs_t;
	
endpackage

`endif