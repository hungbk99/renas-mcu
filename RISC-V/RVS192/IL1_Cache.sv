//////////////////////////////////////////////////////////////////////////////////
// File Name: 		L1_inst_cache.sv
// Module Name:		Level 1 Instruction Cache	
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	IL1_Cache
#(
	parameter	L2_TAG_LENGTH = DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-$clog2(L2_CACHE_LINE)
)
(
//	CPU
	output	logic										ICC_halt,
	output 	logic 	[INST_LENGTH-1:0]					inst_fetch,
	input 	[PC_LENGTH-1:0]								pc,
//	HANDSHAKE	
	output 	logic	[PC_LENGTH-1:0]						pc_up,
	output 	logic 										inst_update_req,
														inst_replace_il1_ack,
														data_replace_il1_ack,		
	input  	cache_update_type 							IL2_out, 
	input												inst_replace_req,
														data_replace_req,
	input 	[L2_TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:0]	inst_addr_replace,
														data_addr_replace,		
	input 												L2_inst_il1_ack,	
														L2_data_il1_ack,
//	System	
	input 												clk_l1,
	input 												rst_n
);

//================================================================================	
//	Internal Signals
	parameter	TAG_LENGTH = INST_LENGTH-BYTE_OFFSET-WORD_OFFSET-$clog2(ICACHE_LINE);
	
	logic	[$clog2(ICACHE_LINE)-1:0]					IL1_index,
														IL1_up_index,
														change_index,
														inclusive_index,
														inst_index_inclusive,
														data_index_inclusive;
															
	logic 	[INST_LENGTH-1:0]							IL1_inst,
														IL1_way_inst[ICACHE_WAY];
	logic 	[$clog2(CACHE_BLOCK_SIZE/4)-1:0]			word_read_sel,
														word_wen;
	logic 	[$clog2(ICACHE_WAY)-1:0]					way_sel;	
	
	logic 	[CACHE_BLOCK_SIZE*8-1:0]					ICRAM_in 	[ICACHE_WAY],
														ICRAM_out 	[ICACHE_WAY],
														ICRAM_read	[ICACHE_WAY];	
	logic 	[CACHE_BLOCK_SIZE*4-1:0]					ICRAM_out1 	[ICACHE_WAY],
														ICRAM_out2 	[ICACHE_WAY],	
														ICRAM_in1 	[ICACHE_WAY],
														ICRAM_in2 	[ICACHE_WAY];
//	logic	[$clog2(ICACHE_WAY)-1:0]					way_up;
	
	logic 	[TAG_LENGTH-1:0]							tag,
														tag_up,
														inst_tag_inclusive,
														data_tag_inclusive,
														TAG_icache	[ICACHE_WAY],
														TAG_read	[ICACHE_WAY]; 
	logic 	[ICACHE_WAY-1:0]							icache_way_hit,
														inclusive_inst_way_hit,
														inclusive_data_way_hit,
														icache_way_valid, 
														inclusive_way_valid,
														replace_way,
														l2_clear_way,
														replace_way_new;
	logic												icache_hit,
														inst_replace_sync,
														inst_replace_solve,
														data_replace_sync,
														data_replace_solve,
														change_index_sel,
														inst_replace_il1_ack_trigger,
														data_replace_il1_ack_trigger;

	`ifdef	INST_VICTIM_CACHE
		logic											update_vc,
														vc_hit;		
		logic 	[CACHE_BLOCK_SIZE*8-1:0]				line_up_vc;
		logic 	[TAG_LENGTH-1:0]						tag_up_vc;			
		logic 	[INST_LENGTH-1:0]						VC_inst;
	`endif	
	
//	logic 	[PC_LENGTH-1:0]								pc_up;
	logic												update_trigger;
//================================================================================
//================================================================================
//	L1 Instruction Cache
	genvar 	way;
	
	assign	IL1_index = pc[BYTE_OFFSET+WORD_OFFSET+$clog2(ICACHE_LINE)-1:BYTE_OFFSET+WORD_OFFSET];
	assign 	IL1_up_index = pc_up[BYTE_OFFSET+WORD_OFFSET+$clog2(ICACHE_LINE)-1:BYTE_OFFSET+WORD_OFFSET];
	assign 	tag = pc[INST_LENGTH-1:BYTE_OFFSET+WORD_OFFSET+$clog2(ICACHE_LINE)];
	assign 	tag_up = pc_up[INST_LENGTH-1:BYTE_OFFSET+WORD_OFFSET+$clog2(ICACHE_LINE)];
	assign 	word_read_sel = pc[BYTE_OFFSET+WORD_OFFSET-1:BYTE_OFFSET];
	assign 	inst_tag_inclusive = inst_addr_replace[L2_TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:$clog2(ICACHE_LINE)];
	assign 	data_tag_inclusive = data_addr_replace[L2_TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:$clog2(ICACHE_LINE)];
	assign 	inst_index_inclusive = inst_addr_replace[$clog2(ICACHE_LINE)-1:0];
	assign 	data_index_inclusive = data_addr_replace[$clog2(ICACHE_LINE)-1:0];
	assign 	change_index = change_index_sel ? inclusive_index : IL1_up_index;
	
//	assign 	inst_replace_il1_ack = inst_replace_solve;
//	assign 	data_replace_il1_ack = data_replace_solve;
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_replace_il1_ack <= 1'b0;
			data_replace_il1_ack <= 1'b0;
		end
		else begin
			if(inst_replace_il1_ack)
				inst_replace_il1_ack <= !L2_inst_il1_ack;
			else 
				inst_replace_il1_ack <= inst_replace_il1_ack_trigger;
			if(data_replace_il1_ack)
				data_replace_il1_ack <= !L2_data_il1_ack;
			else 
				data_replace_il1_ack <= data_replace_il1_ack_trigger;				
		end
	end
		
//	INST AND TAG
	generate			 	
	for(way = 0; way < ICACHE_WAY; way++) 
		begin:	way_gen	

		VALID_BLOCK
		#(
		.CHECK_LINE(ICACHE_LINE)
		)
		IC_VALID		
		(
		.l1_check(icache_way_valid[way]),
		.l2_check(inclusive_way_valid[way]),
		.set(replace_way[way]),
		.clear(l2_clear_way[way]),
		.*
		);
		
		DualPort_SRAM
		#(
		.SRAM_LENGTH(CACHE_BLOCK_SIZE*8), 
		.SRAM_DEPTH(ICACHE_LINE)
		)
		ICRAM
		( 
		.data_out1(ICRAM_out[way]), 									//	Use for Update
		.data_out2(ICRAM_read[way]),									//	Use for Read
		.data_in1(ICRAM_in[way]),
		.data_in2(),	
		.addr1(IL1_up_index),
		.addr2(IL1_index),
		.wen1(replace_way[way]), 
		.wen2(1'b0), 
		.clk(clk_l1)
		);
		
		assign	{ICRAM_out2[way], ICRAM_out1[way]} = ICRAM_out[way];
		
		Configurable_Mux_Write	mux_write1
		(
		.data_out(ICRAM_in1[way]),
		.data_in(IL2_out.w1_update),
		.data_fb(ICRAM_out1[way]),
		.sample_req(IL2_out.addr_update),
		.write(IL2_out.update)		
		);	defparam	mux_write1.SLOT = CACHE_BLOCK_SIZE/8;
		
		Configurable_Mux_Write	mux_write2
		(
		.data_out(ICRAM_in2[way]),
		.data_in(IL2_out.w2_update),
		.data_fb(ICRAM_out2[way]),
		.sample_req(IL2_out.addr_update),
		.write(IL2_out.update)
		);	defparam	mux_write2.SLOT = CACHE_BLOCK_SIZE/8;
		
		assign	ICRAM_in[way] = {ICRAM_in2[way], ICRAM_in1[way]};

		Configurable_Multiplexer	mux_read_way
		(
		.data_out(IL1_way_inst[way]),
		.data_in(ICRAM_read[way]),
		.sel(word_read_sel)
		);	defparam	mux_read_way.INPUT_SLOT = CACHE_BLOCK_SIZE/4;

		DualPort_SRAM
		#(
		.SRAM_LENGTH(TAG_LENGTH), 
		.SRAM_DEPTH(ICACHE_LINE)
		)
		ITAG
		( 
		.data_out1(TAG_icache[way]), 								//	Use for Update
		.data_out2(TAG_read[way]),									//	Use for Read
		.data_in1(tag_up),
		.data_in2(),	
		.addr1(IL1_up_index),
		.addr2(IL1_index),
		.wen1(replace_way[way]), 
		.wen2(1'b0), 
		.clk(clk_l1)
		);
		
		assign	icache_way_hit[way] = (TAG_icache[way] == tag) && icache_way_valid[way];	
		assign 	inclusive_inst_way_hit[way] = (TAG_read[way] == inst_tag_inclusive) && inclusive_way_valid[way];
		assign 	inclusive_data_way_hit[way] = (TAG_read[way] == data_tag_inclusive) && inclusive_way_valid[way];
		
		end		
	endgenerate

//	IL1 inst ouput	
	always_comb	begin
		IL1_inst = 'x;
		for(int i = 0; i < ICACHE_WAY; i++)
		begin
		if(icache_way_hit == (1<<i))
			IL1_inst = IL1_way_inst[i];
		end
	end

	assign  icache_hit = |icache_way_hit;
	
//	Replacement

	`ifdef	ICACHE_ALRU
	ALRU	ALRU_U
	(
	.replace_way(replace_way_new),	
	.replace_index(IL1_index),
	.valid(icache_way_valid),
	.hit(icache_way_hit),
	.clk_l1(clk_l1)
	);
	`elsif	ICACHE_RANDOM
	RANDOM	
	#(
	.RANDOM_BIT(ICACHE_WAY),
	.RANDOM_LINE(ICACHE_LINE))
	RANDOM_U
	(
	.replace_way(replace_way_new),	
	.valid(icache_way_valid),
	.hit(icache_way_hit),
	.clk_l1(clk_l1),
	.rst_n(rst_n)
	);
	`endif

//================================================================================	
//	Inst Victim Cache
	`ifdef	INST_VICTIM_CACHE	
		
		always_comb	begin
			line_up_vc = 'x;
			tag_up_vc = 'x;
			for(int i = 0; i < ICACHE_WAY; i++)
			begin
			if(replace_way[i] == 1'b1)
			begin
				line_up_vc = ICRAM_read[i];
				tag_up_vc = TAG_icache[i];
			end
			end
		end	
		
		Victim_Cache	
		#(
		.SLOT(CACHE_BLOCK_SIZE/4),
		.VCTAG_LENGTH(TAG_LENGTH + $clog2(ICACHE_LINE)),
		.SRAM_DEPTH(4),
		.KIND("INST")
		)
		IVC
		(
		.data_out(VC_inst),
		.vc_hit(vc_hit),	
		.write(1'b0),
		.data_in(line_up_vc),
		.tag_in({tag_up_vc, IL1_index}),
		.addr(pc),	
		.wen(update_vc),
		.rst_n(rst_n),
		.clk_l1(clk_l1)
		);
	`endif
	
//================================================================================	
//================================================================================	
//	Inst Cache Controller		
	
	IL1_Controller	Controller
	(
	.*,
	.update(IL2_out.update),
	.update_inst( (pc[BYTE_OFFSET+WORD_OFFSET-1]) ? IL2_out.w2_update : IL2_out.w1_update)
	);

//	IL1 HANDSHAKE
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			inst_update_req <= '0;
		else if(inst_update_req)
			inst_update_req <= !IL2_out.update;
		else 
			inst_update_req <= update_trigger;
	end
	
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_replace_sync <= 1'b0;
			data_replace_sync <= 1'b0;
		end
		else
		begin
			if(inst_replace_req)
				inst_replace_sync <= 1'b1;
			else if(inst_replace_solve)
				inst_replace_sync <= 1'b0;
			else 
				inst_replace_sync <= inst_replace_sync;
				
			if(data_replace_req)
				data_replace_sync <= 1'b1;
			else if(data_replace_solve)
				data_replace_sync <= 1'b0;
			else 
				data_replace_sync <= data_replace_sync;				
		end
	end
//================================================================================	
//	Simulate
`ifdef 	SIMULATE
	include "RANDOM.sv";
	include "ALRU.sv";
	include "Victim_Cache.sv";
	include "DualPort_SRAM.sv";	
	include "IL1_Controller.sv"; 
`endif
	
endmodule		

//================================================================================	
//================================================================================
//================================================================================	
//================================================================================
module	VALID_BLOCK
#(
parameter	CHECK_LINE = 128
)
(
	output										l1_check,
	output 										l2_check,
	input			[$clog2(CHECK_LINE)-1:0]	change_index,
												IL1_index,	
	input 										set,
	input										clear,
	input 										clk_l1,
	input 										rst_n
);
	
	logic 	[CHECK_LINE-1:0]	CHECK;

	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			CHECK <= '0;
		else if(set)
			CHECK[change_index] <= 1'b1;
		else if (clear)
			CHECK[change_index] <= 1'b0;
	end
	
	assign 	l1_check = CHECK[IL1_index];
	assign 	l2_check = CHECK[change_index];
	
endmodule 	