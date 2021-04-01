/*
module	test(
		output [52:0] data_out,
		input 	[1:0]	r_addr,
		input 	[1:0] 	w_addr,
		input 	clk,
		input 	[52:0] data_in
);

	logic [52:0] mem [0:1023];
	always_ff @(posedge clk)
	begin
		mem[w_addr] <= data_in;
	end
	
	assign 	data_out = mem[r_addr];
endmodule 
*/

/*						1000MHz
module	test(
		input 	[31:0] data_in_1,
		input 	[31:0] data_in_2,	
		input 	[3:0]	r_addr_1,
		input 	[3:0]	r_addr_2,
		input 	[3:0]	r_addr_3,
		input 	[3:0] 	w_addr_1,
		input 	[3:0]	w_addr_2,
		input	wen_1,
		input 	wen_2,
		input 	clk,
		output 	[31:0] data_out_1,
		output 	[31:0] data_out_2,
		output	[31:0] data_out_3
);

	logic [31:0] mem [0:15];
	always_ff @(posedge clk)
	begin
		if(wen_1)
			mem[w_addr_1] <= data_in_1;
	end
	
	
	always_ff @(posedge clk)
	begin	
		if(wen_2)	
			mem[w_addr_2] <= data_in_2;
	end		

	assign 	data_out_1 = mem[r_addr_1];
	assign 	data_out_2 = mem[r_addr_2];
//	assign 	data_out_3 = mem[r_addr_3];	
//	assign 	data_out = mem[r_addr];
endmodule 

*/
/*
module	test(
		input 	[32:0] data_in,	
		input 	[6:0]	r_addr,
		input 	[6:0]	w_addr,
		input	wen_1,
		input 	wen_2,
		input 	clk,
		output 	[32:0] data_out_1,
		output 	[32:0] data_out_2	
);

	logic [1:0][32:0] mem [0:128];
	always_ff @(posedge clk)
	begin
		if(wen_1)
			mem[0][w_addr] <= data_in;
	end
	
	assign 	data_out_1 = mem[0][r_addr];
	
	always_ff @(posedge clk)	
	begin
		if(wen_2)
			mem[1][w_addr] <= data_in;
	end
	
	assign 	data_out_2 = mem[1][r_addr];	
	
endmodule 

*/

module 	test
(
	output	[31:0] ICRAM_out,
	input 	[31:0]	ICRAM_in,
	input 	clk,
	input 	update_res,
	input 	[31:0]	IL1_index,
	input 	[31:0]	IL1_up_index
);			 	
		logic [31:0]	ICRAM	[2**10-1:0];
		
		always_ff @(posedge clk)
		begin
			if(update_res)
				ICRAM[IL1_up_index] <= ICRAM_in;
		end

		assign	ICRAM_out = ICRAM[IL1_index];	
	
endmodule