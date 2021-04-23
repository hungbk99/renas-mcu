//================================================================
// File name: 		Pipeline_testbench.v
// Project name:	A 32-bit pipeline RISC-V cpu using SV
// Author: 			hungbk99
//================================================================
`timescale 10ps/1ps
`define TEST
`include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_define.h"
`include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_parameters.sv"
`include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_package.sv"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module cpu_tb();
	
	parameter 	SLOT = CACHE_BLOCK_SIZE/4;
	logic	clk;
	logic 	rst_n;
	logic 	clk_l1;
	logic 	clk_l2;
	logic 	mem_clk;
	logic [11:0] GBHR;
	logic [11:0] GBHR_mem;
	logic GPT_predict;
	logic PHT_predict;	
	logic P_choice;
	logic 	[$clog2(SLOT)-2:0] 	addr_update_raw;
	logic 	[SLOT/2-2:0]	sent;
	logic [2:0]		current_state;
	logic			external_halt;
	pp_fetch_dec_type				i_pp_fetch_dec,
									o_pp_fetch_dec;
									
	pp_dec_ex_type					i_pp_dec_ex,
									o_pp_dec_ex;
									
	pp_ex_mem_type					i_pp_ex_mem,
									o_pp_ex_mem;
		
	pp_mem_wb_type					i_pp_mem_wb,
									o_pp_mem_wb;	
	
  //include "RVS192.sv";
	RVS192 RISC_U
	(
	.*
	);
	
	assign 	i_pp_fetch_dec = RISC_U.i_pp_fetch_dec;
	assign 	o_pp_fetch_dec = RISC_U.o_pp_fetch_dec;
	assign 	i_pp_dec_ex = RISC_U.i_pp_dec_ex;
	assign 	o_pp_dec_ex =RISC_U.o_pp_dec_ex;
	assign 	i_pp_ex_mem = RISC_U.i_pp_ex_mem;
	assign 	o_pp_ex_mem = RISC_U.o_pp_ex_mem;
	assign 	i_pp_mem_wb = RISC_U.i_pp_mem_wb;
	assign 	o_pp_mem_wb = RISC_U.o_pp_mem_wb;
	
/*	
	assign GBHR = cpu_tb.Pipeline_U.BHT_U.GBHR;
	assign GBHR_mem = cpu_tb.Pipeline_U.BHT_U.GBHR_mem;
	assign GPT_predict = cpu_tb.Pipeline_U.BHT_U.GPT_predict;
	assign PHT_predict = cpu_tb.Pipeline_U.BHT_U.PHT_predict;	
	assign P_choice = cpu_tb.Pipeline_U.BHT_U.P_choice;
	assign sent = cpu_tb.Pipeline_U.L2_DUT.data_update_handshake.sent;
	assign addr_update_raw = cpu_tb.Pipeline_U.L2_DUT.data_update_handshake.addr_update_raw;
	assign current_state = cpu_tb.Pipeline_U.DL1_DUT.Controller.current_state;
*/	
	initial begin
		external_halt = 1'b0;
		clk = 1;	
		clk_l1 = 1'b1;
		clk_l2 = 1'b1;
		mem_clk = 1'b1;
		rst_n = 0;
		#42
		rst_n = 1;
	end

//	Clock Gen		
	always #10 clk = !clk; 
	initial begin	
		#1
		forever #10 clk_l1 = !clk_l1;
	end

	initial begin
		#1
		forever #20	clk_l2 = !clk_l2;	
	end
	
	initial begin
		#1
		forever #30	mem_clk = !mem_clk;			
	end	



endmodule	
