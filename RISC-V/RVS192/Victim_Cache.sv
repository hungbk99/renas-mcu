//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Victim_Cache.sv
// Module Name:		RVS192 Branch Prediction Unit 		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	Victim_Cache
#(parameter	SLOT = 4, 
parameter	VCTAG_LENGTH = 26,	
parameter	SRAM_DEPTH = 2,
parameter	ADDR_LENGTH = 32, 
parameter 	DATA_LENGTH = 32,
parameter 	KIND = "DATA"
)
(
	output 	logic 	[DATA_LENGTH-1:0]	data_out,
	output								vc_hit,	
	input 								write,
	input	[SLOT*DATA_LENGTH-1:0]		data_in,
	input	[VCTAG_LENGTH-1:0]			tag_in,
	input	[ADDR_LENGTH-1:0]			addr,	
	input								wen,
	input 								rst_n,
	input								clk_l1
);

	logic	[DATA_LENGTH*SLOT-1:0]				SRAM		[SRAM_DEPTH-1:0],
												data_buf_1	[SRAM_DEPTH-1:0];
	logic	[DATA_LENGTH-1:0]					data_buf_2	[SRAM_DEPTH];
	logic	[VCTAG_LENGTH-1:0]					TAG			[SRAM_DEPTH-1:0];	
	logic	[SRAM_DEPTH-1:0]					valid,
												dirty,	
												hit,
												hit_raw;
	logic 	[VCTAG_LENGTH-1:0]					check_tag;
	logic 	[$clog2(SRAM_DEPTH)-1:0]			w_addr;
	logic	[$clog2(SLOT)-1:0]					word_sel;
		
	assign 	check_tag = addr[ADDR_LENGTH-1:BYTE_OFFSET+WORD_OFFSET];
	assign 	word_sel = addr[BYTE_OFFSET+WORD_OFFSET+$clog2(SLOT)-1:BYTE_OFFSET+WORD_OFFSET];
	
	always_ff	@(posedge clk_l1)
	begin
		if(wen)
		begin
			SRAM[w_addr] <= data_in;
			TAG[w_addr] <= tag_in;
		end
	end
	
	always_ff	@(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			valid <= '0;
			w_addr <= '0;
		end
		else if(wen)
		begin
			valid[w_addr] <= 1'b1;
			w_addr <= w_addr + 1'b1;
		end
	end
	
	genvar i;
	generate 
		for(i = 0; i < SRAM_DEPTH; i++)
		begin:	o_gen	
			assign	data_buf_1[i] = SRAM[i];
			
			if(KIND == "DATA")
			begin
				assign 	hit_raw[i] = valid[i] && (TAG[i] == check_tag);
				assign 	hit[i] = hit_raw[i] && !dirty[i];
			
				always_ff	@(posedge clk_l1 or negedge rst_n)
				begin
					if(!rst_n)
						dirty[i] <= 1'b0;
					else if(hit_raw[i] && write)
						dirty[i] <= 1'b1;
					else if(wen && (w_addr == i))
						dirty[i] <= 1'b0;
				end			
			end
			else
			assign 	hit[i] = valid[i] && (TAG[i] == check_tag);
			
			Configurable_Multiplexer	mux_read
			(
			.data_out(data_buf_2[i]),
			.data_in(data_buf_1[i]),
			.sel(word_sel)
			);	defparam	mux_read.INPUT_SLOT = SLOT;
			
		end
	endgenerate
	
	always_comb	begin
		data_out = 'x;
		for(int j = 0; j < SRAM_DEPTH; j++)
		begin
		if(hit == (1<<j))
			data_out = data_buf_2[j];
		end
	end
	
	assign	vc_hit = |hit;
	
endmodule

