//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ALRU.sv
// Module Name:		RVS192 Least Recently Used Unit 		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	ALRU
#(parameter	ALRU_BIT = 4)
(
	output			logic	[ALRU_BIT-1:0]		replace_way,	
	input			[$clog2(ICACHE_LINE)-1:0]	replace_index,
	input 			[ALRU_BIT-1:0]				valid,
	input 			[ALRU_BIT-1:0]				hit,
	input 										clk_l1
);

//================================================================================
//	Internal Signals
	logic 	[ALRU_BIT-2:0]	ALRU_out;
	logic	[ALRU_BIT-2:0]	ALRU_in;
	logic	wen;
	
//================================================================================
	assign 	wen = |hit;
		
	SinglePort_SRAM	ALRU_U
	(
	.data_out(ALRU_out),
	.data_in(ALRU_in),
	.w_addr(replace_index),
	.r_addr(replace_index),
	.wen(wen),
	.clk_l1(clk_l1)
	);	defparam	ALRU_U.SRAM_LENGTH = ALRU_BIT-1;
		defparam	ALRU_U.SRAM_DEPTH = ICACHE_LINE;	

	always_comb begin
		if(!valid[3])
			replace_way = 4'b1000;
		else if(!valid[2])
			replace_way = 4'b0100;
		else if(!valid[1])
			replace_way = 4'b0010;
		else if(!valid[0])
			replace_way = 4'b0001;	
		else begin
			unique casez(ALRU_out)
			3'b?11:	replace_way = 4'b1000;
			3'b?01:	replace_way = 4'b0100;
			3'b1?0:	replace_way = 4'b0010;
			3'b0?0:	replace_way = 4'b0001;	
			default:	replace_way = '0;
			endcase
		end
	end
	
	always_comb begin
		unique casez(hit)
		4'b1000:	ALRU_in = {ALRU_out[2], 2'b0};
		4'b0100:	ALRU_in = {ALRU_out[2], 2'b10};
		4'b0010:	ALRU_in = {1'b0, ALRU_out[1], 1'b1};
		4'b0001:	ALRU_in = {1'b1, ALRU_out[1], 1'b1};
		default:	ALRU_in = '0;
		endcase
	end
	
endmodule
