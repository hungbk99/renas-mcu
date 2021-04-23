//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ALU_RVS192.sv
// Module Name:		ALU for RVS192 cpu	
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
// Copyright (C) 	Le Quang Hung 
// Email: 			quanghungbk1999@gmail.com  
//////////////////////////////////////////////////////////////////////////////////


//`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	ALU_RVS192
(
	output	logic	[DATA_LENGTH-1:0]	alu_out,
										add_result,
										target_pc,
	output 	logic						ge,
										eq,
	input 	[DATA_LENGTH-1:0]			branch_cal_out,
										imm_ex,
										pc_ex,
										alu_in1,
										alu_in2,
	input 	alu_op_type					alu_op,
	input 								jal,
										jalr,
										branch_capture
);	

//================================================================================	
//	Internal Signals
	logic 					 	operate,
								shift_swap,
								sub,
								g_raw;
	
	logic 	[DATA_LENGTH-1:0]	comp_result,
								shift_result,
								logic_result,
								alu_cal,
								alu_in1_buf,
								alu_in2_buf,
								shift_in,
								shift_out;


//================================================================================	
//======================================ALU=======================================
//================================================================================	
//	ADD_SUB UNIT

	always_comb begin
		sub = 1'b0;
		alu_in1_buf = alu_in1;
		alu_in2_buf = alu_in2;
		if(alu_op == SUB)
		begin
			sub = 1'b1;
			alu_in2_buf = ~alu_in2;
		end
		else if(jalr)
			alu_in2_buf = imm_ex;
		else if(branch_capture || jal)
		begin
			alu_in1_buf = pc_ex;
			alu_in2_buf = imm_ex;
		end		
	end
	
	assign 	add_result = alu_in1_buf + alu_in2_buf + sub;
	assign 	target_pc = add_result;
/*
	always_comb begin
		if(alu_op == SUB)
			add_result = alu_in1 - alu_in2;
		else 
			add_result = alu_in1 + alu_in2;
	end
*/

//	COMPARE UNIT	
	assign 	g_raw = $signed(alu_in1) > $signed(alu_in2) ? 1'b1 : 1'b0; 	 
	assign 	eq = (alu_in1 == alu_in2) ? 1'b1 : 1'b0;
	
	always_comb begin
		ge = g_raw | eq;
		if(alu_op == USC)
		begin
			if(alu_in1[DATA_LENGTH-1] || alu_in2[DATA_LENGTH-1])
				ge = !g_raw | eq;
		end
	end

	assign	comp_result = (ge||eq) ? '0 : 32'h1;
	
//	LOGICAL UNIT
	always_comb begin
		logic_result = '0;
		unique case(alu_op)
		OR:		logic_result = alu_in1 | alu_in2;
		AND:	logic_result = alu_in1 & alu_in2;
		XOR:	logic_result = alu_in1 ^ alu_in2;	
		endcase
	end

//	SHIFT UNIT
	assign shift_swap = (alu_op == SLL)	? 1'b1 : 1'b0;

	genvar a;
	generate 
		for(a = 0; a < DATA_LENGTH; a++)
		begin: swap_gen
			assign	shift_in[a] = shift_swap ? alu_in1[DATA_LENGTH-1-a] : alu_in1[a];
			assign 	shift_result[a] = shift_swap ? shift_out[DATA_LENGTH-1-a]: shift_out[a];
		end
	endgenerate	
	
	always_comb begin
		if(alu_op == SRA)
			shift_out = shift_in >>> alu_in2;
		else 
			shift_out = shift_in >> alu_in2;
	end
	
//	ALU OUT	
	always_comb begin
		unique case(alu_op[3:2])
		2'b00:	
		begin	
			alu_cal = add_result;
			if(alu_op[1:0] == 2'b10)
				alu_cal = alu_in2;
		end
		2'b01:	alu_cal = shift_result;
		2'b10:	alu_cal = logic_result;
		2'b11:	alu_cal = comp_result;
		endcase
	end
	
	assign 	alu_out = (jal || jalr) ? branch_cal_out : alu_cal;
	
endmodule 

/*
	logic 	[DATA_LENGTH-1:0] 	cal_c_out,
								RCA_result,
								g_check,
								eq_check,
								ge_check;
								
	logic 	[DATA_LENGTH:0]		cal_c_in;


//	Ripple Carry Adder
	genvar a;
	generate
		for(a = 0; a < DATA_LENGTH; a = a + 1)
		begin:	full_adder
			assign RCA_result[a] = man_x[a] ^ (operate ^ man_y[a]) ^ cal_c_in[a];
			assign cal_c_out[a] = man_x[a] && (operate ^ man_y[a]) || cal_c_in[a] && (man_x[a] ^ (operate ^ man_y[a]));
			assign cal_c_in[a+1] = cal_c_out[a];
		end
	endgenerate		

//	Compare Unit
	genvar i;
	generate
		for(i = 0; i < DATA_LENGTH; i = i + 1)
		begin: comp_1
			assign 	eq_check[i] = alu_in1[i]~^alu_in2[i];
			assign 	g_check[i] = alu_in1[i]&&(~alu_in2[i]);
		end	
	endgenerate
	
	genvar j;
	generate
		assign 	ge_check[0] = eq_check[0] || g_check[0];	
		for(j = 1; j < DATA_LENGTH; j = j + 1)
		begin: comp_exp_2
			assign ge_check[j] = (eq_check[j]&&ge_check[j-1])||g_check[j];
		end		
	endgenerate

	assign	ge_raw = ge_check[DATA_LENGTH-1];
	assign	eq_raw = &eq_check;
	
//	Shift Unit
	always_comb begin
		shift_result = '0;
		unique case(alu_op)
		SLL:	shift_result = 	
		SRL:
		SRA:
	end
*/	