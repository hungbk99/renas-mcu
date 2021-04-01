//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Configurable_Mux_Write.sv
// Module Name:		renas Branch Prediction Unit 		
// Project Name:	renas
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

import 	renas_package::*;
import	renas_user_parameters::*;
module	Configurable_Mux_Write
(
	data_out,
	data_in,
	data_fb,
	sample_req,
	write
);
	parameter	SLOT = 8;
	
	output	logic	[SLOT-1:0][INST_LENGTH-1:0]	data_out ;
	input	logic	[INST_LENGTH-1:0] 	data_in;
	input	logic	[SLOT-1:0][INST_LENGTH-1:0] data_fb	;
	input	[$clog2(SLOT)-1:0]	sample_req;
	input 	write;
	
	always_comb	begin
		data_out = data_fb;
		for(int i = 0; i < SLOT; i++)
		begin
			if((sample_req == i)&&write)
				data_out[i] = data_in;
		end
	end
	
endmodule

