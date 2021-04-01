//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Check.sv
// Module Name:		renas Check Set Unit 		
// Project Name:	renas
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

module	Check_Set
#(
parameter	CHECK_LINE = 128,
parameter 	KIND = "L1"
)
(
	output										check,	
	input			[$clog2(CHECK_LINE)-1:0]	read_index,
	input			[$clog2(CHECK_LINE)-1:0]	write_index,	
	input 										set,
	input										clear,
	input 										clk,
	input 										rst_n
);
	
	logic 	[CHECK_LINE-1:0]	CHECK;
	
	generate
	if(KIND == "L1") 
	begin
		always_ff @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				CHECK <= '0;
			else if(set)
				CHECK[write_index] <= 1'b1;
			else if(clear)
				CHECK[write_index] <= 1'b0;
		end
	
		assign 	check = CHECK[read_index];	
	end 
	else if(KIND == "L2") 
	begin
		always_ff @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				CHECK <= '0;
			else if(write)
				CHECK[replace_index] <= 1'b1;
		end
	
		assign 	check = CHECK[index];	
	end
	endgenerate
	
endmodule