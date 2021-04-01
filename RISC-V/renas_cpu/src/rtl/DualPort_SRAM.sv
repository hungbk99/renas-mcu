//////////////////////////////////////////////////////////////////////////////////
// File Name: 		DualPort_SRAM.sv
// Module Name:		renas Branch Prediction Unit 		
// Project Name:	renas
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

import 	renas_package::*;
import	renas_user_parameters::*;
module	DualPort_SRAM
#(parameter	SRAM_LENGTH = 8, parameter SRAM_DEPTH =16)
(
	output 	logic 	[SRAM_LENGTH-1:0]	data_out1, data_out2,	
	input	[SRAM_LENGTH-1:0]			data_in1, data_in2,	
	input	[$clog2(SRAM_DEPTH)-1:0]	addr1, addr2,
	input	wen1, wen2, clk
);

	logic	[SRAM_LENGTH-1:0]	SRAM	[SRAM_DEPTH-1:0];
	
	
	always_ff	@(posedge clk)
	begin
		if(wen1)
		begin
			SRAM[addr1] <= data_in1;
			data_out1 <= data_in1;
		end
		else
			data_out1 <= SRAM[addr1];	
	end
	
	always_ff @(posedge clk)
	begin
		if(wen2)
		begin
			SRAM[addr2] <= data_in2;
			data_out2 <= data_in2;			
		end
		else
			data_out2 <= SRAM[addr2];			
	end

`ifdef 	SIMULATE

	initial begin
		for(int i = 0; i < SRAM_DEPTH; i++)
			SRAM[i] = '0;
		$readmemh("SRAM.txt", SRAM);	
	end
`endif
	
endmodule


