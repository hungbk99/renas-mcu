//////////////////////////////////////////////////////////////////////////////////
// File Name: 		RANDOM.sv
// Module Name:		renas Least Recently Used Unit 		
// Project Name:	renas
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

module	RANDOM
#(parameter	RANDOM_BIT = 4, RANDOM_LINE = 128)
(
	output			logic	[RANDOM_BIT-1:0]	replace_way,	
	input 			[RANDOM_BIT-1:0]			valid,
	input 			[RANDOM_BIT-1:0]			hit,
	input 										cache_clk,
	input 										rst_n
);
	logic [RANDOM_BIT-1:0]			replace_way_buf;
	logic [$clog2(RANDOM_BIT)-1:0]	random_num;	
	
	always_ff @(posedge cache_clk or negedge rst_n)
	begin
		if(!rst_n)
			random_num <= '0;
		else if(~hit)
			random_num <= random_num + 1'b1;
	end

	always_comb	begin
		replace_way_buf = '0;
		for(int i = 0; i < RANDOM_BIT; i++)
		begin
			if(valid[i] == 1'b0)
				replace_way_buf = 1<<i;
		end
	end	

	assign	replace_way = (&hit)	?	(1<<random_num)	: replace_way_buf;

endmodule