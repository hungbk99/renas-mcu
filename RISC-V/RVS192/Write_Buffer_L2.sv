//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Write_Buffer_L2.sv
// Module Name:		RVS192 Branch Prediction Unit 		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

//`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	Write_Buffer_L2
#(
parameter	DATA_LENGTH = 32,
parameter	TAG_LENGTH = 30,
parameter 	WB_DEPTH = 16,
parameter 	WORD_INDEX = 4
)
(
	output 	logic 	[DATA_LENGTH-1:0]	wb_data_out,
	output 	logic 	[TAG_LENGTH-1:0]	wb_tag_out,
	output 	logic 						full_flag,
										empty_flag,
										overflow_flag,
										underflow_flag,
										wb_read_tag_hit,
	input	[DATA_LENGTH-1:0]			data_in,
	input 	[TAG_LENGTH-1:0]			write_tag_in,
	input 	[TAG_LENGTH-WORD_INDEX-1:0]	read_tag_in,	
	input								store,
	input 								load,
	input								clk_l2,
	input 								rst_n
);
 
	parameter	POINTER_WIDTH = $clog2(WB_DEPTH);
	logic	[DATA_LENGTH+TAG_LENGTH-1:0]	WB	[WB_DEPTH-1:0];
	logic 	[WB_DEPTH-1:0]								valid;
	logic												write_en,
														read_en,
														wb_write_hit;
	logic	[POINTER_WIDTH:0] 							w_ptr,
														r_ptr;
	logic	[POINTER_WIDTH-1:0]	 						w_addr,
														r_addr,
														hit_addr;
	logic 	[WB_DEPTH-1:0]	[TAG_LENGTH-1:0]			tag_check_write;
	logic 	[WB_DEPTH-1:0]	[TAG_LENGTH-WORD_INDEX-1:0]	tag_check_read;									
//	Valid Set & Clear
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			valid <= '0;
		else begin
			if(write_en)
				valid[w_addr] <= 1'b1;
			if(read_en)
				valid[r_addr] <= 1'b0;
		end
	end
	
//	Write Counter
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			w_ptr <= '0;
		else if(write_en && !wb_write_hit)
			w_ptr <= w_ptr + 1'b1;
	end
	
	assign 	write_en = store && !full_flag;
	
//	Read Counter
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			r_ptr <= '0;
		else if(read_en)
			r_ptr <= r_ptr + 1'b1;
	end		
	
	assign	read_en = load && !empty_flag;
	
//	Sync RAM with sync read, write, reset
	assign	w_addr = w_ptr[POINTER_WIDTH-1:0];
	assign	r_addr = r_ptr[POINTER_WIDTH-1:0];
	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			wb_data_out <= '0;
			wb_tag_out <= '0;		
		end
		else begin
			if(write_en)
				WB[w_addr] <= {write_tag_in, data_in};
			if(wb_write_hit)
				WB[hit_addr] <= {write_tag_in, data_in};
			wb_data_out <= WB[r_addr][DATA_LENGTH-1:0];
			wb_tag_out <= WB[r_addr][DATA_LENGTH+TAG_LENGTH-1:DATA_LENGTH];
		end
	end
	
//	Interrupt Flag Generator
	assign	full_flag = (w_ptr[POINTER_WIDTH-1:0] == r_ptr[POINTER_WIDTH-1:0]) && (w_ptr[POINTER_WIDTH] != r_ptr[POINTER_WIDTH]);
	assign 	empty_flag = w_ptr[POINTER_WIDTH:0] == r_ptr[POINTER_WIDTH:0];
	assign 	overflow_flag = full_flag && store;
	assign 	underflow_flag = empty_flag && load;
	
//	Hit
	always_comb	begin
		hit_addr = 'x;
		wb_write_hit = '0;
		wb_read_tag_hit = 1'b0;		
		for(int i = 0; i < WB_DEPTH; i++)
		begin
			tag_check_write[i] = WB[i][DATA_LENGTH+TAG_LENGTH-1:DATA_LENGTH];
			tag_check_read[i] = tag_check_write[i][TAG_LENGTH-1:WORD_INDEX];
			if((write_tag_in == tag_check_write[i]) && valid[i])
			begin
				wb_write_hit = 1'b1;
				hit_addr = i;
			end
			if((read_tag_in == tag_check_read[i]) && valid[i])
				wb_read_tag_hit = 1'b1;
		end
	end

`ifdef 	SIMULATE
	initial begin
		$readmemh("L2WB.txt", WB);
	end
`endif
	
endmodule



