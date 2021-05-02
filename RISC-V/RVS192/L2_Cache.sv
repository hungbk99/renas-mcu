//////////////////////////////////////////////////////////////////////////////////
// File Name: 		L2_Cache.sv
// Module Name:		Level 2 Share Cache	
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
// Copyright (C) 	Le Quang Hung 
// Email: 			quanghungbk1999@gmail.com  
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// File Name: 		L2_Cache.sv
// Function:		Level 2 Share Cache	
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.1   24.04.2021  hungbk99  Mod: AHP Interface  
//                                   Read Mem                     -> AHB-INST Interface
//                                   Merge: Read Mem || Write Mem -> AHB-DATA Interface
//////////////////////////////////////////////////////////////////////////////////
import AHB_package::*;
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	L2_Cache
#(
	parameter	TAG_LENGTH = DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-$clog2(L2_CACHE_LINE)
)
(
//	Il1 Cache
	output	cache_update_type									                    IL2_out,
//	output 	logic											                    inst_update_ack,
	input 													                        inst_update_req,	//Use IL2_out.update to sync
	input 	[PC_LENGTH-1:0]							        			            pc,
	input 													                        inst_replace_il1_ack,
															                        data_replace_il1_ack,			
	output 	logic												                    L2_inst_il1_ack,
														                            L2_inst_dl1_ack,
														                            L2_data_il1_ack,
														                            L2_data_dl1_ack,
//	DL1 Cache
	output	cache_update_type									                    DL2_out,
//	output 	logic											                    data_update_ack,
	input 													                        data_update_req,	//Use DL2_out.update to sync
	input 	[PC_LENGTH-1:0]							                    			alu_out,	
	input	[DATA_LENGTH-1:0]						                    			dirty_data1,
	input	[DATA_LENGTH-1:0]						           				      	dirty_data2,
	input 	[DATA_LENGTH-1:0]						                			    dirty_addr,				// DL1 chi gui tag va index do do phai them bit 0 truoc khi su dung
	input 	 												                        dirty_req,
	output 	logic											                      	dirty_ack,
	input 	 												                        dirty_replace,	
	input 	[2*DATA_LENGTH-BYTE_OFFSET-1:0]		   						            wb_data,	
	input		 											                        wb_req,
	output 	logic 											                    	wb_ack,	
	output 	logic 											               	        full_flag,
	input 													                        inst_replace_dl1_ack,
															                        data_replace_dl1_ack,
															                        cpu_read,
//	To both IL1 and DL1
	output 	logic								                 	      			inst_replace_check,
															                        data_replace_check,
	output	logic 	[TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:0]	inst_addr_replace,
			                             											data_addr_replace,																
//	Mem
  	//I-AHB-ITF
  	output  mas_send_type                          									iahb_out,
  	input   slv_send_type                          									iahb_in,
  	//Interrupt Handler
  	output logic                                   									inst_dec_err,
  	//D-AHB-ITF
  	output  mas_send_type                          									dahb_out,
  	input   slv_send_type                          									dahb_in,
  	//Interrupt Handler
  	output logic                                   									data_dec_err,

//	System
	input					  								                        clk_l1,
	input 													                        clk_l2,
	input						  							                        rst_n
);

//================================================================================	
//	Internal Signals
	logic 	[TAG_LENGTH-1:0]						                  inst_tag,
																                        wb_tag_split,
																                        data_replace_tag,
																                        dirty_tag,
																                        data_tag,
																                        inst_hit_tag,
																                        data_hit_tag,
																                        inst_tag_out_way	[L2_CACHE_WAY],
																                        data_tag_out_way	[L2_CACHE_WAY];
																
	logic 	[$clog2(L2_CACHE_LINE)-1:0]	                  inst_index,
																                        data_index,
																                        wb_index_split,
																                        dirty_index,
																                        data_replace_index;
																
	logic 	[$clog2(CACHE_BLOCK_SIZE/4)-1:0]	            wb_word_split,	
																                        data_mem_word,	
																                        inst_mem_word;
																                        
	logic 	[DATA_LENGTH-1:0]			 						            wb_data_split,
																                        inst_hit_data,
																                        data_hit_data;
																
	logic 	[CACHE_BLOCK_SIZE/4-1:0][DATA_LENGTH-1:0]	    inst_hit_data_block,
																                        data_hit_data_block,
																                        inst_dirty_data_block,
																                        data_dirty_data_block;
	
	logic 	[DATA_LENGTH-$clog2(CACHE_BLOCK_SIZE/4)-3:0]	inst_dirty_tag,
																                        data_dirty_tag; 
	
	logic 	[CACHE_BLOCK_SIZE*8-1:0]		inst_ram_out_way	[L2_CACHE_WAY],
																      data_ram_out_way	[L2_CACHE_WAY],
																      wb_in				      [L2_CACHE_WAY],
																      data_mem_in			  [L2_CACHE_WAY],
																      single_data_up		[L2_CACHE_WAY],
																      inst_ram_in_way		[L2_CACHE_WAY],
																      data_ram_in_way		[L2_CACHE_WAY];
																
	logic 												      wb_req_ena,
																      wb_req_ena1,
																      dirty_req_sync,
																      dirty_write_ena_trigger1,
																      dirty_write_ena_trigger2,
																      dirty_req_ena,
																      wb_req_sync,
																      dirty_write_ena,
																      wb_write_en,
																      inst_dirty,
																      data_dirty,
																      inst_hit,
																      data_hit,
																      l1_inst_replace_req,
																      l1_data_replace_req,
																      inst_update_ena,
																      data_update_ena,
																      empty_flag,
																      overflow_flag,
																      underflow_flag,
																      wb_read_tag_hit,
																      load,
																      store,
																      inst_replace_req,
																      data_replace_req,
																      inst_mem_write_ena,
																      inst_mem_replace_done,
																      inst_mem_replace_req,
																      data_mem_write_ena,
																      data_mem_replace_done,
																      data_mem_replace_req,
																      inst_mem_dirty_done,
																      data_mem_dirty_done,
																      inst_mem_dirty_req,
																      data_mem_dirty_req,
																      data_addr_sel,
																      inst_replace_valid,
																      data_replace_valid,
																      inst_replace_il1_ack_sync,
																      inst_replace_dl1_ack_sync,
																      data_replace_il1_ack_sync,
																      data_replace_dl1_ack_sync,
																      inst_replace_req_dl,
																      data_replace_req_dl;
																
	logic	[DATA_LENGTH-1:0]							dirty_addr_sync,
																      inst_mem_read_sync,
																      data_mem_read_sync,
																      inst_replace_addr,
																      data_replace_addr,
																      wb_data_out,
																      read_data_addr,
																      write_data_addr;
	
	logic 	[DATA_LENGTH-3:0]					  wb_tag_out;
																
	logic 	[DATA_LENGTH*2-3:0]					wb_data_sync;
	
	logic 	[L2_CACHE_WAY-1:0]					inst_dirty_way,
																      inst_hit_way,
																      data_dirty_way,
																      data_hit_way,
																      inst_replace_way,
																      inst_replace_way_new,
																      data_replace_way,
																      data_replace_way_new,
																      inst_valid_way,
																      data_valid_way,
																      inst_mem_write_way,
																      data_mem_write_way,
																      data_dirty_write_way,
																      data_wb_write_way;
																

																
	logic 	[DATA_LENGTH-WORD_OFFSET-BYTE_OFFSET-1:0]		inst_check_tag,
																                      data_check_tag;
															
	logic 	[CACHE_BLOCK_SIZE/4-1:0][DATA_LENGTH-1:0]	  dirty_data_sync;

`ifdef 	SIMULATE
	logic 	[L2_CACHE_LINE-1:0]	VALID_CHECK [L2_CACHE_WAY-1:0];	
	logic 	[L2_CACHE_LINE-1:0]	DIRTY_CHECK [L2_CACHE_WAY-1:0];		
`endif	
	
//================================================================================	
	assign	inst_tag = inst_replace_addr[PC_LENGTH-1:$clog2(L2_CACHE_LINE)+BYTE_OFFSET+WORD_OFFSET];
	assign 	inst_index = inst_replace_addr[$clog2(L2_CACHE_LINE)+BYTE_OFFSET+WORD_OFFSET-1:BYTE_OFFSET+WORD_OFFSET];
	assign 	data_replace_tag = data_replace_addr[DATA_LENGTH-1:$clog2(L2_CACHE_LINE)+BYTE_OFFSET+WORD_OFFSET];
	assign 	data_replace_index = data_replace_addr[$clog2(L2_CACHE_LINE)+BYTE_OFFSET+WORD_OFFSET-1:BYTE_OFFSET+WORD_OFFSET];
	assign 	dirty_tag = dirty_addr_sync[DATA_LENGTH-1:$clog2(L2_CACHE_LINE)+BYTE_OFFSET+WORD_OFFSET];
	assign 	dirty_index = dirty_addr_sync[$clog2(L2_CACHE_LINE)+BYTE_OFFSET+WORD_OFFSET-1:BYTE_OFFSET+WORD_OFFSET];
	assign	wb_data_split = wb_data_sync[DATA_LENGTH-1:0];
	assign 	wb_tag_split =  wb_data_sync[DATA_LENGTH+TAG_LENGTH-1:$clog2(L2_CACHE_LINE)+WORD_OFFSET+DATA_LENGTH];
	assign 	wb_index_split = wb_data_sync[DATA_LENGTH+$clog2(L2_CACHE_LINE)+WORD_OFFSET-1:WORD_OFFSET+DATA_LENGTH];
	assign 	wb_word_split = wb_data_sync[DATA_LENGTH+WORD_OFFSET-1:DATA_LENGTH];	
	assign 	data_tag =  (wb_req_ena||wb_req_ena1) ? wb_tag_split : (dirty_req_sync ?	dirty_tag : data_replace_tag);
	assign	data_index = (wb_req_ena||wb_req_ena1) ? wb_index_split : (dirty_req_sync ? dirty_index : data_replace_index);
	assign 	inst_check_tag = {inst_tag, inst_index};
	assign	data_check_tag = {data_tag, data_index}; 

	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			L2_data_dl1_ack <= 1'b0;
			L2_data_il1_ack <= 1'b0;
			L2_inst_dl1_ack <= 1'b0;
			L2_inst_il1_ack <= 1'b0;
		end
		else begin
			L2_inst_il1_ack <= inst_replace_il1_ack;
			L2_inst_dl1_ack <= inst_replace_dl1_ack;
			L2_data_il1_ack <= data_replace_il1_ack;
			L2_data_dl1_ack <= data_replace_dl1_ack;
		end		
	end
	
	assign 	inst_replace_il1_ack_sync = !L2_inst_il1_ack && inst_replace_il1_ack || !inst_replace_valid;
	assign 	inst_replace_dl1_ack_sync = !L2_inst_dl1_ack && inst_replace_dl1_ack || !inst_replace_valid;
	assign 	data_replace_il1_ack_sync = !L2_data_il1_ack && data_replace_il1_ack || !data_replace_valid;
	assign 	data_replace_dl1_ack_sync = !L2_data_dl1_ack && data_replace_dl1_ack || !data_replace_valid;
	
//================================================================================	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			wb_req_ena1 <= 1'b0;
			wb_ack <= 1'b0;
//			dirty_write_ena_trigger1 <= 1'b0;
			dirty_write_ena_trigger2 <= 1'b0;
		end
		else begin
			wb_req_ena1 <= wb_req_ena;
			wb_ack <= wb_req_ena1;
//			dirty_write_ena_trigger1 <= dirty_req_sync && !wb_req_ena && !wb_req_ena1;
			dirty_write_ena_trigger2 <= dirty_write_ena_trigger1;
		end
	end
	
	assign 	dirty_write_ena_trigger1 = dirty_req_sync && !wb_req_ena && !wb_req_ena1;
	assign 	dirty_ack = dirty_req_sync && dirty_write_ena;	
	assign	dirty_write_ena = !dirty_write_ena_trigger2 && dirty_write_ena_trigger1;
	assign	store = wb_req_ena1 && !data_hit;
	assign 	wb_write_en = wb_req_ena1 && data_hit;
	assign 	inst_dirty = |(inst_dirty_way & inst_replace_way_new) ? 1'b1 : 1'b0;					// Replace way bi dirty moi trigger
	assign 	data_dirty = |(data_dirty_way & data_replace_way_new) ? 1'b1 : 1'b0;					// Replace way bi dirty moi trigger
	assign 	inst_hit = |inst_hit_way;
	assign 	data_hit = |data_hit_way;	
	assign 	data_mem_write_way = data_mem_write_ena ? data_replace_way_new : '0;
	assign 	data_dirty_write_way = dirty_write_ena ? data_hit_way : '0;
	assign	data_wb_write_way = wb_write_en ? data_hit_way : '0;
	assign 	inst_mem_write_way = inst_mem_write_ena ? inst_replace_way_new : '0;
	
	
	
//================================================================================	
//	Inst
	cc_update_handshake
	#(
	.DATA_LENGTH(INST_LENGTH),
	.TAG_LENGTH(DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET),
	.ADDR_LENGTH(DATA_LENGTH),
	.SLOT(CACHE_BLOCK_SIZE/4),
	.KIND("INST")
	)
	inst_update_handshake
	(
	.w1_update(IL2_out.w1_update),
	.w2_update(IL2_out.w2_update),	
	.addr_update(IL2_out.addr_update),
	.update(IL2_out.update),
	.miss_addr_sync(inst_replace_addr),	
	.update_req_ena(l1_inst_replace_req),	
	.update_req_sync(),
	.data_update(inst_hit_data_block),
	.check_addr(pc),
//	.check_tag(inst_check_tag[PC_LENGTH-1:BYTE_OFFSET+WORD_OFFSET]),	
	.check_tag(inst_check_tag),
	.enable(inst_update_ena),
	.update_req(inst_update_req),
	.*
	);
	
//	Data
	cc_update_handshake
	#(
	.DATA_LENGTH(DATA_LENGTH),
	.TAG_LENGTH(DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET),
	.ADDR_LENGTH(DATA_LENGTH),
	.SLOT(CACHE_BLOCK_SIZE/4),
	.KIND("DATA")	
	)
	data_update_handshake
	(
	.w1_update(DL2_out.w1_update),
	.w2_update(DL2_out.w2_update),	
	.addr_update(DL2_out.addr_update),
	.update(DL2_out.update),
	.miss_addr_sync(data_replace_addr),	
	.update_req_ena(l1_data_replace_req),	
	.update_req_sync(),
	.data_update(data_hit_data_block),
	.check_addr(alu_out),
	.check_tag(data_check_tag),	
	.enable(data_update_ena),
	.update_req(data_update_req),
	.*
	);

	cc_dirty_handshake
	#(
	.DATA_LENGTH(DATA_LENGTH),
	.TAG_LENGTH(TAG_LENGTH),
	.ADDR_LENGTH(DATA_LENGTH),
	.SLOT(CACHE_BLOCK_SIZE/4)
	)
	data_dirty_handshake
	(
	.update(dirty_replace),
	.*
	);	
	
	cc_wb_handshake
	#(
	.TAG_LENGTH(30)
	)
	cc_wb_handshake_u
	(
	.*
	);	


	
//================================================================================
//	L2 Cache

	genvar way;
	
	generate
	for(way = 0; way < L2_CACHE_WAY; way++) 
		begin:	way_gen	
		
		`ifdef SIMULATE
			assign VALID_CHECK[way] = VALID_SET.CHECK;
			assign DIRTY_CHECK[way] = DIRTY_SET.CHECK;
		`endif
		
		Check_Set_L2
		#(
		.CHECK_LINE(L2_CACHE_LINE),
		.KIND("VALID")
		)
		VALID_SET
		(
		.inst_check(inst_valid_way[way]),
		.data_check(data_valid_way[way]),
		.inst_index(inst_index),
		.data_index(data_index),			
		.inst_set(inst_mem_write_way[way]),
		.data_set(data_mem_write_way[way]),
		.inst_clear(),
		.data_clear(), 
		.clk(clk_l2),
		.rst_n(rst_n)
		);
		
		Check_Set_L2
		#(
		.CHECK_LINE(L2_CACHE_LINE),
		.KIND("DIRTY")
		)
		DIRTY_SET
		(
		.inst_check(inst_dirty_way[way]),
		.data_check(data_dirty_way[way]),
		.inst_index(inst_index),
		.data_index(data_index),			
		.inst_set(),
		.data_set(data_wb_write_way[way] || data_dirty_write_way[way]),
		.inst_clear(inst_mem_write_way[way]),
		.data_clear(data_mem_write_way[way]),
		.clk(clk_l2),
		.rst_n(rst_n)
		);
	
		
		DualPort_SRAM
		#(
		.SRAM_LENGTH(CACHE_BLOCK_SIZE*8), 
		.SRAM_DEPTH(L2_CACHE_LINE)
		)
		L2DATA
		(
		.data_out1(inst_ram_out_way[way]), 
		.data_out2(data_ram_out_way[way]),	
		.data_in1(inst_ram_in_way[way]),
		.data_in2(data_ram_in_way[way]),	
		.addr1(inst_index),
		.addr2(data_index),
		.wen1(inst_mem_write_way[way]), 
		.wen2(data_mem_write_way[way] ||  data_dirty_write_way[way] || data_wb_write_way[way]), 
		.clk(clk_l2)
		);
		
		// data mux
		Configurable_Mux_Write	mux_wb
		(
		.data_out(wb_in[way]),
		.data_in(wb_data_split),
		.data_fb(data_ram_out_way[way]),
		.sample_req(wb_word_split),
		.write(1'b1)
		);	defparam	mux_wb.SLOT = CACHE_BLOCK_SIZE/4;				

		Configurable_Mux_Write	mux_mem_data
		(
		.data_out(data_mem_in[way]),
		.data_in(data_mem_read_sync),
		.data_fb(data_ram_out_way[way]),
		.sample_req(data_mem_word),
		.write(1'b1)
		);	defparam	mux_mem_data.SLOT = CACHE_BLOCK_SIZE/4;		

		Configurable_Mux_Write	mux_mem_inst
		(
		.data_out(inst_ram_in_way[way]),
		.data_in(inst_mem_read_sync),
		.data_fb(inst_ram_out_way[way]),
		.sample_req(inst_mem_word),
		.write(1'b1)
		);	defparam	mux_mem_inst.SLOT = CACHE_BLOCK_SIZE/4;			
		
		assign	single_data_up[way] = wb_write_en ? wb_in[way] : data_mem_in[way];
		assign 	data_ram_in_way[way] = dirty_write_ena ? dirty_data_sync : single_data_up[way];	

		DualPort_SRAM
		#(
		.SRAM_LENGTH(TAG_LENGTH), 
		.SRAM_DEPTH(L2_CACHE_LINE)
		)
		L2TAG
		(
		.data_out1(inst_tag_out_way[way]), 
		.data_out2(data_tag_out_way[way]),	
		.data_in1(inst_tag),
		.data_in2(data_tag),	
		.addr1(inst_index),
		.addr2(data_index),
		.wen1(inst_mem_write_way[way]), 
		.wen2(data_mem_write_way[way]), 
		.clk(clk_l2)
		);
		
		assign	inst_hit_way[way] = (inst_tag_out_way[way] == inst_tag) && inst_valid_way[way];	
		assign	data_hit_way[way] = (data_tag_out_way[way] == data_tag) && data_valid_way[way];	
		
		end						
	endgenerate

//================================================================================	
//	Inst & Data Update Level 1
	always_comb	begin
		inst_hit_data_block = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
		if(inst_hit_way == (1<<i))
			inst_hit_data_block = inst_ram_out_way[i];
		end
	end

	always_comb	begin
		data_hit_data_block = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
		if(data_hit_way == (1<<i))
			data_hit_data_block = data_ram_out_way[i];
		end
	end

//	Inst & Data Check Level 1 (Inclusive Check)
	always_comb	begin
		inst_addr_replace = 'x;
		inst_replace_valid = 1'b0;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
			if(inst_replace_way_new == (1<<i))
			begin
				inst_addr_replace = {inst_tag_out_way[i], inst_index};
				inst_replace_valid = inst_valid_way[i];			
			end
		end
	end

	always_comb	begin
		data_addr_replace = 'x;
		data_replace_valid = 1'b0;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
			if(data_replace_way_new == (1<<i))
			begin
				data_addr_replace = {data_tag_out_way[i], data_index};
				data_replace_valid = data_valid_way[i];
			end
		end
	end
	
//	assign 	inst_replace_check = inst_replace_req && inst_replace_valid;
//	assign	data_replace_check = data_replace_req && data_replace_valid;

	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_replace_req_dl <= 1'b0;
			data_replace_req_dl <= 1'b0;
		end
		else 
		begin
			inst_replace_req_dl <= inst_replace_req;
			data_replace_req_dl <= data_replace_req;
		end
	end

	assign 	inst_replace_check = inst_replace_req_dl && inst_replace_valid;
	assign	data_replace_check = data_replace_req_dl && data_replace_valid;

//	Inst & Data Dirty to Mem
	always_comb	begin
		inst_dirty_data_block = 'x;
		inst_dirty_tag = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
			if((inst_dirty_way & inst_replace_way_new) == (1<<i))
			begin
				inst_dirty_data_block = inst_ram_out_way[i];
				inst_dirty_tag = {inst_tag_out_way[i], inst_index};
			end
		end
	end

	always_comb	begin
		data_dirty_data_block = 'x;
		data_dirty_tag = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
			if((data_dirty_way & data_replace_way_new) == (1<<i))
			begin
				data_dirty_data_block = data_ram_out_way[i];
				data_dirty_tag = {data_tag_out_way[i], data_index};
			end
		end
	end
	
/*	
	always_comb	begin
		inst_hit_data = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
		if(inst_hit_way == (1<<i))
			inst_hit_data = inst_hit_data_block[i];
		end
	end

	always_comb	begin
		data_hit_data = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
		if(data_hit_way == (1<<i))
			data_hit_data = data_hit_data_block[i];
		end
	end
*/	
	always_comb	begin
		inst_hit_tag = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
		if(inst_hit_way == (1<<i))
			inst_hit_tag = inst_tag_out_way[i];
		end
	end

	always_comb	begin
		data_hit_tag = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
		if(data_hit_way == (1<<i))
			data_hit_tag = data_tag_out_way[i];
		end
	end
	
//================================================================================		
//	Write Buffer
	Write_Buffer_L2
	#(
	.DATA_LENGTH(DATA_LENGTH),
	.TAG_LENGTH(DATA_LENGTH-BYTE_OFFSET),
	.WB_DEPTH(L2_CACHE_WB_DEPTH),
	.WORD_INDEX(WORD_OFFSET)
	)
	WB_L2
	(
	.data_in(wb_data_split),
	.write_tag_in(wb_data_sync[DATA_LENGTH*2-3:DATA_LENGTH]),
	.read_tag_in({data_tag, data_index}),	
	.*
	);
//================================================================================		
//	Replacement
	RAMDOM_L2
	#(
	.RANDOM_BIT(L2_CACHE_WAY)
	)
	RANDOM
	(
	.conflict(inst_index == data_index),
	.*
	);

//================================================================================		
//	L2 Cache Controller 
 
	L2C_Controller	Controller
(
	.inst_miss(!inst_hit),
	.data_miss(!data_hit),
	.*
);

//================================================================================		
//AHB Interface
//================================================================================		
ahb_inst_itf
#(
.WORD_LENGTH(CACHE_BLOCK_SIZE/4)
)
ahb_inst_interface
(
  //AHB-ITF
  //Interrupt Handler
  //Cache-ITF
	.data_read_sync(inst_mem_read_sync),
	.word_sel(inst_mem_word),
	.write_en(inst_mem_write_ena),
	.replace_done(inst_mem_replace_done),
	.replace_req(inst_mem_replace_req),
	.addr({inst_tag, inst_index}),
	.*
);

ahb_data_itf	
#(
.WORD_LENGTH(CACHE_BLOCK_SIZE/4)
)
ahb_data_interface	
(
  //AHB-ITF
  //Interrupt Handler
  //Cache-ITF
  //Read
	.data_read_sync(data_mem_read_sync),
	.word_sel(data_mem_word),
	.write_en(data_mem_write_ena),
	.replace_done(data_mem_replace_done),
	.replace_req(data_mem_replace_req),
	.addr({data_tag, data_index}),

  //Write
	.inst_dirty_done(inst_mem_dirty_done),
	.data_dirty_done(data_mem_dirty_done),
	.inst_dirty_req(inst_mem_dirty_req),
	.inst_dirty_tag(inst_dirty_tag),
	.inst_dirty_data(inst_dirty_data_block),
	.data_dirty_req(data_mem_dirty_req),
	.data_dirty_tag(data_dirty_tag),
	.data_dirty_data(data_dirty_data_block),	
	.wb_empty(empty_flag),
	.wb_tag(wb_tag_out),	
	.wb_data(wb_data_out),
	.*
);

	//Hung_add_25.04.2021	assign	data_addr = (data_addr_sel || data_write_req) ? write_data_addr : read_data_addr;
	assign	data_addr = (data_addr_sel || (dahb_out.htrans )) ? write_data_addr : read_data_addr;
	
//================================================================================	
//	Simulate
	//include "Write_Buffer_L2.sv";
	//include "Check_Set_L2.sv";
	//include "DualPort_SRAM.sv";	
	//include "L2C_Controller.sv"; 
		
	//Hung_mod_25.04.2021 initial begin
	//Hung_mod_25.04.2021 	$readmemh("WBL2.txt", WB_L2.WB);			
	//Hung_mod_25.04.2021 end
	
endmodule

//================================================================================	
//================================================================================	
//================================================================================	
//================================================================================	
//================================================================================	
//================================================================================	
//================================================================================	
module	cc_update_handshake
#(
	parameter	DATA_LENGTH = 32,
	parameter 	TAG_LENGTH = 26,
	parameter 	ADDR_LENGTH = 32,
	parameter 	SLOT = 4,
	parameter 	KIND = "DATA"
)
(
	output	logic	[DATA_LENGTH-1:0]		w1_update,
	output	logic	[DATA_LENGTH-1:0]		w2_update,
	output 	logic 	[$clog2(SLOT)-2:0]		addr_update,
	output 	logic							update,	
	output 	logic	[ADDR_LENGTH-1:0]		miss_addr_sync,		
	output 	logic							update_req_ena,
											update_req_sync,
	input 	[SLOT-1:0][DATA_LENGTH-1:0]		data_update,
	input 	[ADDR_LENGTH-1:0]				check_addr,
	input 	[TAG_LENGTH-1:0]				check_tag,	
	input									enable,
											cpu_read,
											update_req,
											clk_l1,
											clk_l2,
											rst_n
);
	logic 	[TAG_LENGTH-1:0]				tag;
	logic 	[SLOT-1:0][DATA_LENGTH-1:0]		data;
	logic									update_req_ena_raw,
											update_req_ena1;
	logic 	[$clog2(SLOT)-2:0]				addr_update_raw;
	logic 	[SLOT/2-2:0]					sent;
	logic 									check_sent;

	assign 	check_sent = &sent;
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			sent <= '0;
		else if(enable)
			sent <= '0;
		else if(update)
			sent[addr_update] <= 1'b1;
	end
	
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			tag <='0;
			data <= '0;
		end
		else if(enable)
		begin
			tag <= check_tag;
			data <= data_update;		
		end
	end
	
	assign 	w1_update = data[addr_update];
	assign	w2_update = data[addr_update + SLOT/2];
	
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			update <= 1'b0;
		else if((addr_update_raw != SLOT/2-1)&&(!check_sent))
			update <= 1'b1;
		else 
			update <= 1'b0;
	end


	generate
	if(KIND == "DATA")
	begin
		always_ff @(posedge clk_l1 or negedge rst_n)
		begin
			if(!rst_n)
				addr_update_raw <= SLOT/2-1;
			else if(enable)
				addr_update_raw <= '0;
			else if((addr_update_raw != SLOT/2-1)&&!((tag == check_addr[ADDR_LENGTH-1:2+$clog2(SLOT)])&&cpu_read))  
				addr_update_raw <= addr_update_raw + 1;
			else 
				addr_update_raw <=  addr_update_raw;
		end
		
		assign 	addr_update = (cpu_read&&(tag == check_addr[ADDR_LENGTH-1:2+$clog2(SLOT)])) ? check_addr[$clog2(SLOT)+2:2] : addr_update_raw;
	end
	else 
	begin
		always_ff @(posedge clk_l1 or negedge rst_n)
		begin
			if(!rst_n)
				addr_update_raw <= SLOT/2-1;
			else if(enable)
				addr_update_raw <= '0;
			else if((addr_update_raw != SLOT/2-1)&&(tag != check_addr[ADDR_LENGTH-1:2+$clog2(SLOT)]))  
				addr_update_raw <= addr_update_raw + 1;
			else 
				addr_update_raw <=  addr_update_raw;
		end
		
		assign 	addr_update = (tag == check_addr[ADDR_LENGTH-1:2+$clog2(SLOT)]) ? check_addr[$clog2(SLOT)+2:2] : addr_update_raw;
	end
	endgenerate
	
	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			update_req_sync <= '0;
		else
			update_req_sync <= update_req;
	end
	
//	assign 	update_ack = update_req_sync;
	assign 	update_req_ena_raw = !update_req_sync && update_req;
	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			miss_addr_sync <= '0;
		else if(update_req_ena_raw)
			miss_addr_sync <= check_addr;
		else 
			miss_addr_sync <= miss_addr_sync;
	end

	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
		update_req_ena <= 1'b0;
		update_req_ena1 <= 1'b0;
		end
		else
		begin
		update_req_ena1 <= update_req_ena_raw;	
		update_req_ena <= update_req_ena1;
		end
	end
	
endmodule


//================================================================================	
module	cc_dirty_handshake
#(
	parameter	DATA_LENGTH = 32,
	parameter 	TAG_LENGTH = 26,
	parameter 	ADDR_LENGTH = 32,
	parameter 	SLOT = 4
)
(
	output	logic	[SLOT-1:0][DATA_LENGTH-1:0]	dirty_data_sync,
	output 	logic	[ADDR_LENGTH-1:0]			dirty_addr_sync,
	output 	logic								dirty_req_sync,
//	output 	logic 								dirty_req_ena,
//	output 	logic								dirty_ack,
	input 	[DATA_LENGTH-1:0]					dirty_data1,
	input 	[DATA_LENGTH-1:0]					dirty_data2,
	input 	[ADDR_LENGTH-1:0]					dirty_addr,
	input 										dirty_req,
	input 										update,
//	input 										dirty_solve,
	input 										clk_l1,
	input 										clk_l2,
	input 										rst_n
);

	logic	[SLOT-1:0][DATA_LENGTH-1:0]			dirty_data;
	logic										dirty_req_ena_raw,
												dirty_req_sync_1;
	logic 	[$clog2(CACHE_BLOCK_SIZE/4)-1:0]	addr;
	
	always_ff @(posedge clk_l1)
	begin
		if(update)
		begin
			dirty_data[addr] <= dirty_data1;
			dirty_data[addr + SLOT/2] <= dirty_data2;
		end
		else 
			dirty_data <= dirty_data;
	end
	
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			addr <= '0;
		else if(update)
			addr <= addr + 1;
		else	
			addr <= '0;
	end

	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			dirty_req_sync_1 <= '0;
			dirty_req_sync <= '0;
		end
		else
			dirty_req_sync_1 <= dirty_req;
		dirty_req_sync <= dirty_req_sync_1;	
	end
	
//	assign 	dirty_ack = dirty_req_sync && dirty_solve;
//	assign 	dirty_ack = dirty_req_sync && dirty_req_ena;
	assign 	dirty_req_ena_raw = !dirty_req_sync_1 && dirty_req;

	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			dirty_addr_sync <= '0;
			dirty_data_sync <= '0;
		end
		else if(dirty_req_ena_raw)
		begin
			dirty_addr_sync <= dirty_addr;
			dirty_data_sync <= dirty_data;
		end 
		else begin		
			dirty_addr_sync <= dirty_addr_sync;
			dirty_data_sync <= dirty_data_sync;
		end
	end	

/*
	always_ff @(posedge clk_l2)
	begin
		dirty_req_ena <= dirty_req_ena_raw;	
	end
*/		
	
endmodule

//================================================================================	
module 	cc_wb_handshake
#(
	parameter	DATA_LENGTH = 32,
	parameter	TAG_LENGTH = 30
)
(
	output	logic	[DATA_LENGTH+TAG_LENGTH-1:0]	wb_data_sync,
//	output 											wb_ack,
	output	logic									wb_req_ena,
													wb_req_sync,
	input 	[DATA_LENGTH+TAG_LENGTH-1:0]			wb_data,
	input 											wb_req,	
													clk_l2,
													rst_n	
);
	logic									wb_req_ena_raw;
	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			wb_req_sync <= '0;
		else
			wb_req_sync <= wb_req;
	end
	
	assign	wb_req_ena_raw = !wb_req_sync && wb_req;
//	assign	wb_ack = wb_req_sync;

	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			wb_data_sync <= '0;
		else if(wb_req_ena_raw)
			wb_data_sync <= wb_data;
		else 
			wb_data_sync <= wb_data_sync;
	end

	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		wb_req_ena <= 1'b0;
		else
		wb_req_ena <= wb_req_ena_raw;
	end
	
endmodule

//================================================================================

//================================================================================

module RAMDOM_L2
#(parameter	RANDOM_BIT = 4)
(
	output			logic	[RANDOM_BIT-1:0]	data_replace_way_new,
	output 			logic 	[RANDOM_BIT-1:0]	inst_replace_way_new,
	input 			[RANDOM_BIT-1:0]			inst_valid_way,
	input 			[RANDOM_BIT-1:0]			data_valid_way,
	input 										conflict,
	input 										inst_replace_req,
	input 										data_replace_req,
	input 										clk_l2,
	input 										rst_n
);
	logic [RANDOM_BIT-1:0]			inst_replace_way_buf,
									data_replace_way_buf,
									inst_replace_way_valid,
									data_replace_way_valid;
	logic [$clog2(RANDOM_BIT)-1:0]	random_num;	
	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			random_num <= '0;
		else if(inst_replace_req || data_replace_req)
			random_num <= random_num + 1'b1;
	end

	always_comb	begin
		inst_replace_way_valid = '0;
		for(int i = 0; i < RANDOM_BIT; i++)
		begin
			if(inst_valid_way[i] == 1'b0)
				inst_replace_way_valid = 1<<i;
		end
	end	

	always_comb	begin
		data_replace_way_valid = '0;
		for(int i = 0; i < RANDOM_BIT; i++)
		begin
			if(data_valid_way[i] == 1'b0)
				data_replace_way_valid = 1<<i;
		end
	end	
/*
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_replace_way_new <= 1;
			data_replace_way_new <= 1;
		end
		else begin
			if(inst_replace_req)
			begin
				if(&inst_valid_way)
					inst_replace_way_new <= (1<<random_num);
				else
					inst_replace_way_new <= inst_replace_way_buf;
			end	
			else
				inst_replace_way_new <= inst_replace_way_new;
		
			if(data_replace_req)
			begin			
				if(inst_replace_req && conflict)	
					data_replace_way_new <= {(inst_replace_way_new << 1), inst_replace_way_new[RANDOM_BIT-1]};
				else if(&data_valid_way) 
					data_replace_way_new <= (1<<random_num);
				else
					data_replace_way_new <= data_replace_way_buf;
			end
			else
				data_replace_way_new <= data_replace_way_new;
		end
	end
*/
	always_comb begin
		if(&data_valid_way) 
			inst_replace_way_buf = inst_replace_way_valid;
		else 
			inst_replace_way_buf = (1<<random_num);
			
		if(&data_valid_way) 
			data_replace_way_buf = data_replace_way_valid;
		else 
			data_replace_way_buf = (1<<random_num);
	end
	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_replace_way_new <= 1;
			data_replace_way_new <= 1;
		end
		else begin
			if(inst_replace_req) 
				inst_replace_way_new <= inst_replace_way_buf;
			else
				inst_replace_way_new <= inst_replace_way_new;				
			if(data_replace_req)
			begin
				if(inst_replace_req && conflict)
					data_replace_way_new <= {(inst_replace_way_buf << 1), inst_replace_way_buf[RANDOM_BIT-1]};
				else 			
					data_replace_way_new <= data_replace_way_buf;
			end
			else
				data_replace_way_new <= data_replace_way_new;
		end		
	end
	
endmodule


//================================================================================

	
module Read_Mem
#(
parameter	DATA_LENGTH = 32,
parameter ADDR_LENGTH = 32,
parameter	WORD_LENGTH = 16
)
(
	output	logic	[DATA_LENGTH-1:0]					        data_read_sync,
	output 	logic	[ADDR_LENGTH-1:0]					        addr_read,
	output 	logic	[$clog2(WORD_LENGTH)-1:0]		      word_sel,
	output 	logic										                read_req,
														                      write_en,
														                      replace_done,
	input 												                  replace_req,
	input 												                  read_res,	
	input 	[DATA_LENGTH-1:0]			    				      data_read,
	input 	[ADDR_LENGTH-$clog2(WORD_LENGTH)-3:0]		addr,
	input 												                  clk_l2,
	input 												                  rst_n
);

	logic 	[$clog2(WORD_LENGTH)-1:0]	word_count;
	logic								              stop,
										                write_en_raw,
										                read_req_raw,
										                read_done,
										                read_done1,
										                replace_done1,
										                replace_done2;
	enum 	logic [1:0]
	{
	READY,
	REQ,
	BUSY
	}	current_state, next_state;

//	Next State Logic	
	always_comb begin
		read_req_raw = 1'b0;
		//Hung_mod write_en_raw = 1'b0;
		next_state = READY;
		unique case(current_state)
		READY:
		begin
			if(replace_req)
			begin
				next_state = REQ;
			end
			else 
				next_state = current_state;
		end
		REQ:
		begin
			//Hung_mod write_en_raw = 1'b0;
			//Hung_mod if(!stop)
      if(!(stop && write_en))
			begin
				next_state = BUSY;
				read_req_raw = 1'b1;
			end
			else 
				next_state = READY;
		end
		BUSY:
		//Hung_mod begin
		//Hung_mod 	if(read_done)
		//Hung_mod 	begin
		//Hung_mod 		//Hung_mod write_en_raw = 1'b1;
		//Hung_mod 		next_state = REQ;
		//Hung_mod 	end
		//Hung_mod 	else 
		//Hung_mod 		next_state = current_state;
		//Hung_mod end
		begin
      if(stop && replace_done)
        next_state = READY;
			else if(read_done)
			begin
				//Hung_mod write_en_raw = 1'b1;
				next_state = REQ;
			end
			else 
				next_state = current_state;
		end
		default: next_state = READY;		
		endcase
	end
	
// 	State Memory
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			current_state <= READY;
		else 
			current_state <=  next_state;
	end
	
	always_ff @(posedge clk_l2)
	begin
		//Hung_mod write_en <= write_en_raw;
		if(read_req)
			read_req <= !read_res;
		else
			read_req <= read_req_raw;
		read_done1 <= read_res;
	end	

  //Hung_add
  assign write_en = read_req & read_res;

	assign read_done = !read_res && read_done1;
	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			word_count <= WORD_LENGTH-1;
		else if(replace_req)
			word_count <= '0;
		else if(write_en && !stop)
			word_count <= word_count+1;
		else  
			word_count <= word_count;	
	end

	//Hung_mod always_ff @(posedge clk_l2 or negedge rst_n)
	//Hung_mod begin
	//Hung_mod 	if(!rst_n)
	//Hung_mod 		data_read_sync <= '0;
	//Hung_mod 	else if(read_res)
	//Hung_mod 		data_read_sync <= data_read;
	//Hung_mod 	else 
	//Hung_mod 		data_read_sync <= data_read_sync;
	//Hung_mod end
  //Hung_add
  assign data_read_sync = data_read;


	assign	stop = (word_count == WORD_LENGTH-1) ? 1'b1 : 1'b0;	
	assign	addr_read = {addr, word_count, 2'b0};
	assign	word_sel = word_count;

	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			replace_done1 <= 1'b0;
		else if(write_en)	
			replace_done1 <= stop;
		else	
			replace_done1 <= replace_done1;
		replace_done2 <= replace_done1;
	end
	
	assign 	replace_done = !replace_done2 && replace_done1;
	
endmodule: Read_Mem
	
//================================================================================
	
module	Write_Mem
#(
parameter	DATA_LENGTH = 32,
parameter ADDR_LENGTH = 32,
parameter	WORD_LENGTH = 16
)
(
	output	logic	[DATA_LENGTH-1:0]				        data_write_sync,
	output 	logic	[ADDR_LENGTH-1:0]				        addr_write_sync,
	output 	logic									                write_req,	
													                      load,
													                      inst_dirty_done,
													                      data_dirty_done,
	input 											                  write_res,
	input 											                  inst_dirty_req,	
	input 	[ADDR_LENGTH-$clog2(WORD_LENGTH)-3:0]	inst_dirty_tag,
	input 	[WORD_LENGTH-1:0][DATA_LENGTH-1:0]		inst_dirty_data,
	input 											                  data_dirty_req,
	input 	[ADDR_LENGTH-$clog2(WORD_LENGTH)-3:0]	data_dirty_tag,
	input 	[WORD_LENGTH-1:0][DATA_LENGTH-1:0]		data_dirty_data,	
	input 											                  wb_empty,
	input 	[ADDR_LENGTH-3:0]						          wb_tag,	
	input 	[DATA_LENGTH-1:0]						          wb_data,
	input 											                  clk_l2,
	input 											                  rst_n
);

	logic											load_raw,
													write_req_raw,
													write_req_raw1,
													dirty_done_raw,
													inst_write_ena_raw,
													data_write_ena_raw,
													inst_dirty_done_raw,
													data_dirty_done_raw,
													write_done,
													write_done1,
													write_done_dl,
													inst_clear,
													data_clear,
													inst_clear_raw,
													data_clear_raw,
													inst_write_en,
													data_write_en,
													stop,
													wb_en;
	logic 	[WORD_LENGTH-1:0][DATA_LENGTH-1:0]		dirty_data_way;
	logic 	[DATA_LENGTH-1:0]						dirty_data;
	logic 	[ADDR_LENGTH-$clog2(WORD_LENGTH)-3:0]	dirty_tag;
	logic 	[$clog2(WORD_LENGTH)-1:0]				word_count;
	
	enum logic [2:0]
	{
	READY,
	WB_BUSY,
	I_SETUP,
	I_BUSY,
	I_DONE,
	D_SETUP,
	D_BUSY,
	D_DONE
	}	current_state, next_state;

//	Next State Logic 
	always_comb begin
		load_raw = 1'b0;
		write_req_raw = 1'b0;
		inst_dirty_done_raw = 1'b0;
		data_dirty_done_raw = 1'b0;
		inst_write_ena_raw = 1'b0;
		data_write_ena_raw = 1'b0;	
		inst_clear_raw = 1'b0;
		data_clear_raw = 1'b0;
		next_state = READY;
		wb_en = 1'b1;
		unique case(current_state)
		READY:
		begin
			inst_dirty_done_raw = 1'b0;
			data_dirty_done_raw = 1'b0;
			if(!inst_dirty_req && !data_dirty_req && !wb_empty)
			begin
				next_state =  WB_BUSY;
				write_req_raw = 1'b1;
			end
			else if(inst_dirty_req)
			begin
				next_state = I_SETUP;
				inst_clear_raw = 1'b1;
			end
			else if(data_dirty_req)
			begin
				next_state = D_SETUP;
				data_clear_raw = 1'b1;
			end
			else
				next_state = current_state;
		end
		WB_BUSY:
		begin
			if(write_done)
			begin
				load_raw = 1'b1;
				next_state = READY;
			end
			else
				next_state = current_state;
		end
/*
		I_SETUP:
		begin
			wb_en = 1'b0;		
			if(stop && write_res)
			begin
				next_state = I_DONE;
				inst_dirty_done_raw = 1'b1;
				inst_write_ena_raw = 1'b0;
			end
			else 
			begin
				next_state = I_BUSY;
				write_req_raw = 1'b1;
				inst_write_ena_raw = 1'b0;
			end
		end		
		I_BUSY:
		begin
			wb_en = 1'b0;
			if(write_done)
			begin
				inst_write_ena_raw = 1'b1;
				next_state = I_SETUP;
			end
			else
				next_state = current_state;
		end	
*/
		I_SETUP:
		begin
			wb_en = 1'b0;		
			next_state = I_BUSY;
			write_req_raw = 1'b1;
			inst_write_ena_raw = 1'b0;
		end		
		I_BUSY:
		begin
			wb_en = 1'b0;
			if(write_done && !stop)
			begin
				inst_write_ena_raw = 1'b1;
				next_state = I_SETUP;
			end
			else if(stop && write_done)
			begin
				next_state = I_DONE;
				inst_dirty_done_raw = 1'b1;
				inst_write_ena_raw = 1'b0;
			end			
			else
				next_state = current_state;
		end				
		I_DONE:
		begin
			if(!inst_dirty_req)
				next_state = READY;
			else 
				next_state = current_state;
		end
/*		
		D_SETUP:
		begin
			wb_en = 1'b0;		
			if(stop && write_done)
			begin
				next_state = D_DONE;
				data_dirty_done_raw = 1'b1;
				data_write_ena_raw = 1'b0;
			end
			else if(!stop)
			begin
				next_state = D_BUSY;
				write_req_raw = 1'b1;
				data_write_ena_raw = 1'b0;
			end	
			else
				next_state = current_state;
		end		
		D_BUSY:
		begin
			wb_en = 1'b0;		
			if(write_done)
			begin
				data_write_ena_raw = 1'b1;
				next_state = D_SETUP;
			end
			else
				next_state = current_state;
		end
*/	
		D_SETUP:
		begin
			wb_en = 1'b0;		
			next_state = D_BUSY;
			write_req_raw = 1'b1;
			inst_write_ena_raw = 1'b0;
		end		
		D_BUSY:
		begin
			wb_en = 1'b0;
			if(write_done && !stop)
			begin
				data_write_ena_raw = 1'b1;
				next_state = D_SETUP;
			end
			else if(stop && write_done)
			begin
				next_state = D_DONE;
				data_dirty_done_raw = 1'b1;
				data_write_ena_raw = 1'b0;
			end			
			else
				next_state = current_state;
		end	
		D_DONE:
		begin
			if(!data_dirty_req)
				next_state = READY;
			else 
				next_state = current_state;
		end		
		default: next_state = READY;
		endcase
	end

// 	State Memory
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			current_state <= READY;
		else 
			current_state <=  next_state;
	end

//	DFF to remove glitches
	always_ff @(posedge clk_l2)
	begin
		/*
		inst_write_en <= inst_write_ena_raw;
		data_write_en <= data_write_ena_raw;		
		inst_dirty_done <= inst_dirty_done_raw;		//	Dung DFF nhu tren thi tin hieu stop bi delay
		data_dirty_done <= data_dirty_done_raw;		//	Mach chay sai
		inst_clear <= inst_clear_raw;
		data_clear <= data_clear_raw;
		load <= load_raw;
		*/
		write_done_dl <= write_done;
		write_req_raw1 <= write_req_raw;
		if(write_req)
			write_req <= !write_res;
		else
			write_req <= write_req_raw1;
		write_done1 <= write_res;
	end	

	assign	inst_write_en = inst_write_ena_raw;
	assign	data_write_en = data_write_ena_raw;		
	assign	inst_dirty_done = inst_dirty_done_raw;		
	assign	data_dirty_done = data_dirty_done_raw;		
	assign	inst_clear = inst_clear_raw;
	assign	data_clear = data_clear_raw;
	assign	load = load_raw;
	
	assign write_done = !write_res && write_done1;
//	Dirty Update
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			word_count <= WORD_LENGTH-1;
		else if(inst_clear || data_clear)
			word_count <= '0;
		else if(write_done && !stop)
			word_count <=  word_count+1;
		else 
			word_count <= word_count;			
	end
	
	always_comb	begin
		dirty_data = 'x;
		for(int i = 0; i < L2_CACHE_WAY; i++)
		begin
		if(word_count == i)
			dirty_data = dirty_data_way[i];
		end
	end
	
	always_ff @(posedge clk_l2)
	begin
		if(current_state == I_SETUP)
		begin
			dirty_tag <= inst_dirty_tag;
			dirty_data_way <= inst_dirty_data;
		end
		else if(current_state == D_SETUP)
		begin
			dirty_tag <= data_dirty_tag;
			dirty_data_way <= data_dirty_data;		
		end
	end	
	
	assign	stop = (word_count == WORD_LENGTH-1) ? 1'b1 : 1'b0;
//	assign 	addr_write_sync = inst_dirty_req ? {dirty_tag, word_count, 2'b0} : {wb_tag, 2'b0}; 
//	assign 	data_write_sync = inst_dirty_req ? dirty_data : wb_data;
	
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			addr_write_sync	<= '0;
			data_write_sync <= '0;
		end
		else if(wb_en)
		begin
			addr_write_sync = {wb_tag, 2'b0};
			data_write_sync = wb_data;			
		end
		else
		begin
			addr_write_sync = {dirty_tag, word_count, 2'b0};
			data_write_sync = dirty_data;			
		end
	end
	
endmodule: Write_Mem

//================================================================================

module ahb_inst_itf
#(
parameter	DATA_LENGTH = 32,
parameter ADDR_LENGTH = 32,
parameter	WORD_LENGTH = 16
)
(
  //AHB-ITF
  output  mas_send_type                           iahb_out,
  input   slv_send_type                           iahb_in,
  //Interrupt Handler
  output logic                                    inst_dec_err,
  //Cache-ITF
	output  logic	[DATA_LENGTH-1:0]					        data_read_sync,
	output 	logic	[$clog2(WORD_LENGTH)-1:0]		      word_sel,
	output 	logic													          write_en,
	output 	logic												            replace_done,
	input 												                  replace_req,
	input 	[ADDR_LENGTH-$clog2(WORD_LENGTH)-3:0]		addr,
	input 												                  clk_l2,
	input 												                  rst_n
);

  //------------------------------------------------------------------------------
	logic	[ADDR_LENGTH-1:0]					                addr_read;
	logic										                        read_req,
												                          read_res;
	logic [DATA_LENGTH-1:0]			    				        data_read;

  enum logic [1:0] {IDLE_I, NONSEQ_I, SEQ_I, BUSY_I}      state, n_state;
  //------------------------------------------------------------------------------
  Read_Mem
  #(
	  .WORD_LENGTH(CACHE_BLOCK_SIZE/4)
  )
  inst_read_inst
  (
    .*
  );
  //------------------------------------------------------------------------------
  assign iahb_out.hwrite    = 0;
  assign iahb_out.hburst    = INCR16; 
  assign iahb_out.haddr     = addr_read;//{pc[31:6], 1'b0, wrap_addr, 2'b0};
  assign iahb_out.hsize     = WORD;
  assign iahb_out.hmastlock = 1'b0;
  assign iahb_out.hprot     = 4'h0;
  assign iahb_out.hwdata    = '0;

  assign read_res = iahb_in.hreadyout;
  assign data_read = iahb_in.hrdata;
  assign inst_dec_err = iahb_in.hreadyout & iahb_in.hresp;

  always_ff @(posedge clk_l2, negedge rst_n)
  begin
    if(!rst_n)
      state <= IDLE_I;
    else
      state <= n_state;
  end
  
  always_comb begin
    //n_state = IDLE_I;
    //iahb_out.htrans = IDLE;
    unique case(state)
    IDLE_I: begin
      iahb_out.htrans = IDLE;
      if(read_req) begin
        //iahb_out.htrans = NONSEQ;
        n_state = NONSEQ_I;
      end
      else
        n_state = state;
    end
    NONSEQ_I: begin
      iahb_out.htrans = NONSEQ;
      if(read_req && read_res) 
      begin
        //n_state = BUSY_I;
        n_state = SEQ_I;
        //iahb_out.htrans = SEQ;
      end
      else
        n_state = state;
    end
    SEQ_I: begin
      iahb_out.htrans = SEQ;
      //if(read_req && read_res && !inst_read_inst.stop) 
      //begin
      //  n_state = BUSY_I;
      //  iahb_out.htrans = BUSY;
      //end
      //else 
      if(read_req && read_res && inst_read_inst.stop)
      begin
        n_state = IDLE_I;
        //iahb_out.htrans = IDLE;
      end
      else
        n_state = state;
    end
    //BUSY_I: begin
    //  iahb_out.htrans = BUSY;
    //  if(!read_res && read_req)
    //  begin
    //    iahb_out.htrans = SEQ;
    //    n_state = SEQ_I;
    //  end
    //  else
    //    n_state = state;
    //end
    default: n_state = state;
    endcase
  end

endmodule: ahb_inst_itf

//================================================================================

module ahb_data_itf
#(
parameter	DATA_LENGTH = 32,
parameter 	ADDR_LENGTH = 32,
parameter	WORD_LENGTH = 16
)
(
  //AHB-ITF
  output  mas_send_type                           dahb_out,
  input   slv_send_type                           dahb_in,
  //Interrupt Handler
  output logic                                    data_dec_err,
  //Cache-ITF
  //Read
	output  logic	[DATA_LENGTH-1:0]					        data_read_sync,
	output 	logic	[$clog2(WORD_LENGTH)-1:0]		      word_sel,
	output 	logic													          write_en,
	output 	logic												            replace_done,
	input 												                  replace_req,
	input 	[ADDR_LENGTH-$clog2(WORD_LENGTH)-3:0]		addr,
  //Write
	output 	logic												            load,
	output 	logic												            inst_dirty_done,
	output 	logic												            data_dirty_done,
	input 											                    inst_dirty_req,	
	input 	[ADDR_LENGTH-$clog2(WORD_LENGTH)-3:0]	  inst_dirty_tag,
	input 	[WORD_LENGTH-1:0][DATA_LENGTH-1:0]		  inst_dirty_data,
	input 											                    data_dirty_req,
	input 	[ADDR_LENGTH-$clog2(WORD_LENGTH)-3:0]	  data_dirty_tag,
	input 	[WORD_LENGTH-1:0][DATA_LENGTH-1:0]		  data_dirty_data,	
	input 											                    wb_empty,
	input 	[ADDR_LENGTH-3:0]						            wb_tag,	
	input 	[DATA_LENGTH-1:0]						            wb_data,
	input 											                    clk_l2,
	input 											                    rst_n
);
  //------------------------------------------------------------------------------
	logic	[DATA_LENGTH-1:0]				                  data_write_sync;
	logic	[ADDR_LENGTH-1:0]				                  addr_write_sync;
	logic									                          write_req,	
											                            write_res;
	
  logic	[ADDR_LENGTH-1:0]					                addr_read;
	logic										                        read_req,
												                          read_res;
	logic [DATA_LENGTH-1:0]			    				        data_read;

  logic                                           direction,
                                                  wb_empty_mod,
                                                  busy;
  enum logic [1:0] {IDLE_D, NONSEQ_D, SEQ_D, BUSY_D}      state, n_state;
  //------------------------------------------------------------------------------
	Read_Mem
	#(
	.WORD_LENGTH(CACHE_BLOCK_SIZE/4)
	)
  	data_read_inst
	(
	.*
	);	
	
	Write_Mem
	#(
	.WORD_LENGTH(CACHE_BLOCK_SIZE/4)
	)
 	data_write_inst
	(
  .wb_empty(wb_empty_mod),  
	.*
  );
  
  //------------------------------------------------------------------------------
  assign wb_empty_mod = wb_empty & busy; 
  always_ff @(posedge clk_l2, negedge rst_n) 
  begin
    if(!rst_n)
    begin
      direction <= 1'b0;
      busy <= 1'b0;
	end
    else if((state == IDLE) && (replace_req))
    begin
      if(replace_req)
      begin
        direction <= 1'b0;
        busy <= 1'b1;
      end
      else if(inst_dirty_req || data_dirty_req || !wb_empty)
      begin
        direction <= 1'b1;
        busy <= 1'b0;
      end
      else begin
        direction <= 1'b0;
        busy <= 1'b0;
      end
    end
  end

  //------------------------------------------------------------------------------
  assign dahb_out.hwrite    = direction;
  assign dahb_out.hburst    = INCR16; 
  assign dahb_out.haddr     = direction ? addr_write_sync : addr_read;//{pc[31:6], 1'b0, wrap_addr, 2'b0};
  assign dahb_out.hsize     = WORD;
  assign dahb_out.hmastlock = 1'b0;
  assign dahb_out.hprot     = 4'h0;
  assign dahb_out.hwdata    = data_write_sync;

  assign read_res = dahb_in.hreadyout;
  assign data_read = dahb_in.hrdata;
  assign data_dec_err = dahb_in.hreadyout & dahb_in.hresp;

  always_ff @(posedge clk_l2, negedge rst_n)
  begin
    if(!rst_n)
      state <= IDLE_D;
    else
      state <= n_state;
  end
  
  always_comb begin
    //direction = 1'b0;
    n_state = IDLE_D;
    dahb_out.htrans = IDLE;
    unique case(n_state)
    IDLE_D: begin
      if(read_req) begin
        dahb_out.htrans = NONSEQ;
        n_state = NONSEQ_D;
      end
    end
    NONSEQ_D: begin
      dahb_out.htrans = NONSEQ;
      if(read_req && read_res) 
      begin
        n_state = BUSY_D;
        dahb_out.htrans = BUSY;
      end
      else
        n_state = state;
    end
    SEQ_D: begin
      dahb_out.htrans = SEQ;
      if(read_req && read_res && !data_read_inst.stop) 
      begin
        n_state = BUSY_D;
        dahb_out.htrans = BUSY;
      end
      else if(read_req && read_res && data_read_inst.stop)
      begin
        n_state = IDLE_D;
        dahb_out.htrans = IDLE;
      end
      else
        n_state = state;
    end
    BUSY_D: begin
      dahb_out.htrans = BUSY;
      if(!read_res && read_req)
      begin
        dahb_out.htrans = SEQ;
        n_state = SEQ_D;
      end
      else
        n_state = state;
    end
    default: n_state = state;
    endcase
  end

endmodule: ahb_data_itf
