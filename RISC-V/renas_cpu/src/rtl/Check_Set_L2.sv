//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Check_Set_L2.sv
// Module Name:		renas Check Set L2 Unit 		
// Project Name:	renas
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

module	Check_Set_L2
#(
parameter	CHECK_LINE = 128,
parameter 	KIND = "VALID"
)
(
	output										inst_check,
	output 										data_check,
	input			[$clog2(CHECK_LINE)-1:0]	inst_index,
	input			[$clog2(CHECK_LINE)-1:0]	data_index,	
	input 										inst_set,
	input 										data_set,
	input										inst_clear,
	input										data_clear,
	input 										clk,
	input 										rst_n
);
	
	logic 	[CHECK_LINE-1:0]	CHECK;
	
	generate
	if(KIND == "VALID") 
	begin
		always_ff @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				CHECK <= '0;
			else begin 
				if(inst_set)
					CHECK[inst_index] <= 1'b1;
				if(data_set)
					CHECK[data_index] <= 1'b1;
			end
		end
	
		assign 	inst_check = CHECK[inst_index];
		assign	data_check = CHECK[data_index];
		
	end 
	else if(KIND == "DIRTY") 
	begin
		always_ff @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				CHECK <= '0;
			else if(data_set)
				CHECK[data_index] <= 1'b1;
			else
			begin
				if(data_clear)
				CHECK[data_index] <= 1'b0;
				if(inst_clear)
				CHECK[inst_index] <= 1'b0;			
			end
		end
		
		assign 	inst_check = CHECK[inst_index];	
		assign 	data_check = CHECK[data_index];	
	end
	endgenerate
	
endmodule

