//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Configurable_Multiplexer.sv
// Module Name:		RVS192 Branch Prediction Unit 		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	Configurable_Multiplexer
(
	data_out,
	data_in,
	sel
);
	parameter	INPUT_SLOT = 4;
	
	output	logic	[INST_LENGTH-1:0]	data_out;
	input	logic	[INPUT_SLOT-1:0][INST_LENGTH-1:0] 	data_in	;
	input	[$clog2(INPUT_SLOT)-1:0]	sel;
	
	always_comb	begin
		data_out = 'x;
		for(int i = 0; i < (INPUT_SLOT); i++)
		begin
			if(sel == i)
				data_out = data_in[i];
		end
	end

endmodule
