//////////////////////////////////////////////////////////////////////////////////
// File Name: 		RVS192.sv
// Module Name:		Top Module for RVS192 cpu
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
// Copyright (C) 	Le Quang Hung 
// Email: 			quanghungbk1999@gmail.com  
//////////////////////////////////////////////////////////////////////////////////

//`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module Forwarding_Unit 
(
	output	logic 	[1:0]	fw_sel_1,
							fw_sel_2,
							mem_fix,
	output					FW_halt,
	input 	[4:0]			rs1_ex,
							rs2_ex,
							rd_mem,
							rd_wb,
	input 					reg_wen_mem,
							reg_wen_wb,
							alu_in1_sel,
							alu_in2_sel,
							wb_mem,
							cpu_write
);

//================================================================================	
//	Internal Signals
	logic 	halt_op1,
			halt_op2,
			halt_mem;

//================================================================================	
//	Op_1
	always_comb begin															//  Newer stage has the higher priority			
		halt_op1 = 1'b0;														//	Forwarding mem from mem need 1 stall cycle, kill the inst from ex to mem stage
		fw_sel_1 = {1'b0, alu_in1_sel};											//	To end the halt cycle above
		if((rd_mem == rs1_ex) && (rd_mem != '0) && reg_wen_mem && !alu_in1_sel && !wb_mem) 	//	Forwarding mem from mem stage	 			
			halt_op1 = 1'b1;
		else if((rd_mem == rs1_ex) && (rd_mem != '0) && reg_wen_mem && !alu_in1_sel && wb_mem) //	Forwarding alu from mem stage 
			fw_sel_1 = 2'b10;
		else if((rd_wb == rs1_ex) && (rd_wb != '0) && reg_wen_wb && !alu_in1_sel)			// Forwarding from wb stage
			fw_sel_1 = 2'b11;
	end

// Op_2
	always_comb begin
		halt_op2 = 1'b0;
		fw_sel_2 = {1'b0, alu_in2_sel};
		if((rd_mem == rs2_ex) && (rd_mem != '0) && reg_wen_mem && !alu_in2_sel && !wb_mem)	//	Forwarding mem from mem need 1 stall cycle, kill the inst from ex to mem stage
			halt_op2 = 1'b1;
		else if((rd_mem == rs2_ex) && (rd_mem != '0) && reg_wen_mem && !alu_in2_sel && wb_mem)	//	Forwarding alu from mem stage
			fw_sel_2 = 2'b10;
		else if((rd_wb == rs2_ex) && (rd_wb != '0) && reg_wen_wb && !alu_in2_sel)			//	Forwarding from wb stage
			fw_sel_2 = 2'b11;
	end

//	mem_fix	for store instructions
	always_comb begin
		mem_fix = 2'b0;	
		halt_mem = 1'b0;
		if(cpu_write && (rd_mem == rs2_ex) && (rd_mem != '0) && reg_wen_mem && !wb_mem)		//	Stall 1 cycle due to delay cycle when cpu read mem
			halt_mem = 1'b1;	
		else if (cpu_write && (rd_mem == rs2_ex) && (rd_mem != '0) && reg_wen_mem && wb_mem)
			mem_fix = 2'b10;																// 	Forward from mem 
		else if(cpu_write && (rd_wb == rs2_ex) && (rd_wb != '0) && reg_wen_wb)
			mem_fix = 2'b01;																//	Forward from wb
	end

	assign 	FW_halt = halt_op1 || halt_op2 || halt_mem;

endmodule