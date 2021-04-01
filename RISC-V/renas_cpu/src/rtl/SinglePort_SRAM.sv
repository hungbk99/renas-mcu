//////////////////////////////////////////////////////////////////////////////////
// File Name: 		SinglePort_SRAM.sv
// Module Name:		renas Branch Prediction Unit 		
// Project Name:	renas
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

import 	renas_package::*;
import	renas_user_parameters::*;
module	SinglePort_SRAM
#(parameter	SRAM_LENGTH = 32, parameter SRAM_DEPTH =16)
(
	output 	logic 	[SRAM_LENGTH-1:0]	data_out,
	input	[SRAM_LENGTH-1:0]	data_in,
	input	[$clog2(SRAM_DEPTH)-1:0]	w_addr,
	input	[$clog2(SRAM_DEPTH)-1:0]	r_addr,
	input	wen,
	input	clk
);

	logic	[SRAM_LENGTH-1:0]	SRAM	[SRAM_DEPTH-1:0];
	
	
	always_ff	@(posedge clk)
	begin
		if(wen)
			SRAM[w_addr] = data_in;
		data_out = SRAM[r_addr];	
	end
	
endmodule

