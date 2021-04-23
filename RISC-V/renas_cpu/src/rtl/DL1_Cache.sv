//////////////////////////////////////////////////////////////////////////////////
// File Name: 		L1_data_cache.sv
// Module Name:		Level 1 Data Cache	
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   14.03.2021  hungbk99  Reused from renas cpu
//                              Remove L2 Cache 
//                              Remove support for inclusive cache
//        15.03.2021  hungbk99  Add support for AHB interface
//////////////////////////////////////////////////////////////////////////////////

`include"D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/renas_user_define.h"
import 	renas_package::*;
import	renas_user_parameters::*;
module	DL1_Cache
#(
	parameter	L2_TAG_LENGTH = DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-$clog2(L2_CACHE_LINE)
)
(
//	CPU
	output	logic													                    DCC_halt,
	output 	logic [DATA_LENGTH-1:0]								            data_read,
	input 	      [DATA_LENGTH-1:0]								            data_write,
	input	        [DATA_LENGTH-1:0]							              alu_out,
	input															                        cpu_read,
	input 															                      cpu_write,	
//	Dirty handshake	
	output	logic	[DATA_LENGTH-1:0]								            dirty_data1,
	output	logic	[DATA_LENGTH-1:0]								            dirty_data2,
	output 	logic [DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-1:0]		dl1_dirty_addr,	
	output 	logic 													                  dirty_req,
	input 	logic													                    dirty_ack,
	output 	logic 													                  dirty_replace,
//	Replace handshake	
	input 	cache_update_type 										            DL2_out,
	output 	logic 													                  data_update_req,
	output 	logic													                    inst_replace_dl1_ack,
																	                          data_replace_dl1_ack,
	input														                          inst_replace_req,
																	                          data_replace_req,
																	                          L2_inst_dl1_ack,
																	                          L2_data_dl1_ack,
	input 	[L2_TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:0]			  	inst_addr_replace,
																  	                        data_addr_replace,																		
	output 	logic 	[DATA_LENGTH-1:0]								          alu_out_up,
//	Write Buffer
	output 	[2*DATA_LENGTH-BYTE_OFFSET-1:0]							      wb_data,
	input															                        L2_full_flag,
	output 	logic 													                  wb_req,
	input 	logic 													                  wb_ack,
//	System	
	input 															                      cache_clk,
	input 															                      rst_n
);

//================================================================================	
//	Internal Signals
	parameter	TAG_LENGTH = DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-$clog2(DCACHE_LINE);
	
	logic [$clog2(CACHE_BLOCK_SIZE/4)-1:0]	word_sel,
												                  word_sel_sync;
	logic [$clog2(CACHE_BLOCK_SIZE/8)-1:0]	dirty_word_sel;
	logic	[DCACHE_WAY-1:0]					        dcache_valid,
												                  dcache_dirty,
												                  dcache_way_hit,
												                  replace_way,
												                  write_way,
												                  replace_way_new,
												                  inclusive_way_valid,
												                  inclusive_way_dirty,
												                  l2_clear_way,
												                  inclusive_inst_way_hit,
												                  inclusive_data_way_hit;
												
	logic	[$clog2(DCACHE_LINE)-1:0]		    	DL1_index,
												                  DL1_up_index,
												                  inst_index_inclusive,
												                  data_index_inclusive,
												                  inclusive_index,
												                  change_index,
												                  read_index,
												                  replace_index,
												                  DL1_index_dirty;
												
	logic 	[TAG_LENGTH-1:0]					      tag,
												                  tag_up,
												                  inst_tag_inclusive,
												                  data_tag_inclusive,
												                  TAG_dcache		    [DCACHE_WAY],
												                  TAG_read			    [DCACHE_WAY]; 
												
	logic 	[CACHE_BLOCK_SIZE*8-1:0]			  DCRAM_out 		    [DCACHE_WAY],		//	Use for replace
												                  DCRAM_read			  [DCACHE_WAY],		//	Use for Read
												                  DCRAM_in_replace 	[DCACHE_WAY],		//	Data replace mux
												                  DCRAM_in_write 		[DCACHE_WAY];		//	Data from write mux
	logic 	[CACHE_BLOCK_SIZE*4-1:0]			  DCRAM_out1 			  [DCACHE_WAY],
												                  DCRAM_out2 			  [DCACHE_WAY],	
												                  DCRAM_in1 			  [DCACHE_WAY],
												                  DCRAM_in2 			  [DCACHE_WAY];
												
	logic										                dcache_hit;
	
	logic 	[DATA_LENGTH-1:0]					      DL1_data,
												                  DL1_data_way	  	[DCACHE_WAY];	
												
	logic 								              		wb_hit,
												                  wb_full,
												                  wb_empty,
												                  wb_overflow,
												                  wb_underflow,
												                  wb_write,
												                  wb_read,
												                  wb_trigger,
												                  wb_done,
												                  wb_done_raw,
												                  update_trigger,
												                  inst_replace_dl1_ack_trigger,
												                  data_replace_dl1_ack_trigger,
												                  wb_read_tag_hit;			
												
	logic 	[DATA_LENGTH-BYTE_OFFSET-1:0]		wb_tag;	
	logic 	[DATA_LENGTH-1:0]					      wb_hit_data,
												                  data_write_sync;

	logic									                  dirty_trigger,
												                  dirty_done,
												                  dirty_done_raw,
												                  change_index_sel,
												                  inst_replace_sync,
												                  data_replace_sync,
												                  inst_replace_solve,
												                  data_replace_solve,
												                  inclusive_dirty_sel,
												                  replace_sel,
												                  cpu_write_sync;
												
	logic	[DCACHE_WAY-1:0]					        dirty_replace_way;
	logic 	[TAG_LENGTH-1:0]					      dl1_dirty_addr_buf;
	logic 	[CACHE_BLOCK_SIZE*8-1:0]			  dirty_data_buf;
	
	`ifdef	INST_VICTIM_CACHE
		logic									                update_vc,
												                  vc_hit;		
		logic 	[CACHE_BLOCK_SIZE*8-1:0]		  line_up_vc;
		logic 	[TAG_LENGTH-1:0]				      tag_up_vc;			
		logic 	[DATA_LENGTH-1:0]				      VC_data;
	`endif	
	
//================================================================================
//================================================================================
//	L1 Data Cache
	genvar	way;

	assign	DL1_index = alu_out[BYTE_OFFSET+WORD_OFFSET+$clog2(DCACHE_LINE)-1:BYTE_OFFSET+WORD_OFFSET];
	assign 	DL1_up_index = alu_out_up[BYTE_OFFSET+WORD_OFFSET+$clog2(DCACHE_LINE)-1:BYTE_OFFSET+WORD_OFFSET];
	assign 	tag = alu_out[DATA_LENGTH-1:BYTE_OFFSET+WORD_OFFSET+$clog2(DCACHE_LINE)];
	assign 	tag_up = alu_out_up[DATA_LENGTH-1:BYTE_OFFSET+WORD_OFFSET+$clog2(DCACHE_LINE)];
	assign 	word_sel = alu_out[BYTE_OFFSET+WORD_OFFSET-1:BYTE_OFFSET];
	
//	assign	write_way = cpu_write_sync ? dcache_way_hit : '0;
//	assign 	wb_tag = alu_out[DATA_LENGTH-1:BYTE_OFFSET];

	assign 	inst_tag_inclusive = inst_addr_replace[L2_TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:$clog2(DCACHE_LINE)];
	assign 	data_tag_inclusive = data_addr_replace[L2_TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:$clog2(DCACHE_LINE)];
	assign 	inst_index_inclusive = inst_addr_replace[$clog2(DCACHE_LINE)-1:0];
	assign 	data_index_inclusive = data_addr_replace[$clog2(DCACHE_LINE)-1:0];
	assign 	change_index = change_index_sel ? inclusive_index : DL1_up_index;
//	assign 	read_index = inclusive_dirty_sel ? inclusive_index : DL1_index;				//	add wen2 to solve write bug
//	assign 	replace_index = replace_sel ? DL1_up_index : DL1_index;

  //Unsafe latch -> ???
	always_latch begin
		if(inclusive_dirty_sel)
			read_index <= inclusive_index;
		else if(|write_way)
			read_index <= read_index;
		else
			read_index <= DL1_index;
	end
  

//	Solving data_write bug 
	always_ff @(posedge cache_clk)
	begin
		data_write_sync <= data_write;
		word_sel_sync <= word_sel;
		cpu_write_sync <= cpu_write;
		wb_tag <= alu_out[DATA_LENGTH-1:BYTE_OFFSET];		
		if(cpu_write)
			write_way <= dcache_way_hit;
		else
			write_way <= '0;
/*			
		if(inclusive_dirty_sel)	
			read_index <= inclusive_index;
		else 
			read_index <= DL1_index;
*/	
	end

	
//	Solving dirty set bug
	always_latch begin
		if(|write_way)
			DL1_index_dirty <= DL1_index_dirty;
		else 
			DL1_index_dirty <= alu_out[BYTE_OFFSET+WORD_OFFSET+$clog2(DCACHE_LINE)-1:BYTE_OFFSET+WORD_OFFSET];			
	end


//	Ack for inst_replace_check or data_replace_check from L2 Cache
	always_ff @(posedge cache_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_replace_dl1_ack <= 1'b0;
			data_replace_dl1_ack <= 1'b0;
		end
		else begin
			if(inst_replace_dl1_ack)
				inst_replace_dl1_ack <= !L2_inst_dl1_ack;
			else 
				inst_replace_dl1_ack <= inst_replace_dl1_ack_trigger;
				
			if(data_replace_dl1_ack)
				data_replace_dl1_ack <= !L2_data_dl1_ack;
			else 
				data_replace_dl1_ack <= data_replace_dl1_ack_trigger;				
		end
	end
	
//================================================================================
//================================================================================	
	generate			 	
	for(way = 0; way < DCACHE_WAY; way++) 
		begin:	way_gen	
		
		CHECK_SET
		#(
		.CHECK_LINE(DCACHE_LINE),
		.KIND ("VALID")		
		)
		DCACHE_VALID		
		(
		.l1_check(dcache_valid[way]),
		.l2_check(inclusive_way_valid[way]),
		.set(replace_way[way]),
		.clear(l2_clear_way[way]),
		.*
		);
		
		CHECK_SET
		#(
		.CHECK_LINE(DCACHE_LINE),
		.KIND ("DIRTY")		
		)
		DCACHE_DIRTY										// dirty will write into DL1_index => need sync
		(
		.l1_check(dcache_dirty[way]),
		.l2_check(inclusive_way_dirty[way]),
		.set(write_way[way]),
		.clear(l2_clear_way[way] || replace_way[way]),
		.*
		);
		
		DualPort_SRAM
		#(
		.SRAM_LENGTH(CACHE_BLOCK_SIZE*8), 
		.SRAM_DEPTH(DCACHE_LINE)
		)
		DCRAM
		(
		.data_out1(DCRAM_out[way]), 
		.data_out2(DCRAM_read[way]),	
		.data_in1(DCRAM_in_replace[way]),
		.data_in2(DCRAM_in_write[way]),	
		.addr1(DL1_up_index),
		.addr2(read_index),
		.wen1(replace_way[way]), 
		.wen2(write_way[way]), 
		.clk(cache_clk)
		);

		assign	{DCRAM_out2[way], DCRAM_out1[way]} = DCRAM_out[way];

		Configurable_Mux_Write	mux_write
		(
		.data_out(DCRAM_in_write[way]),
		.data_in(data_write_sync),				//	data_write_sync has to be sampled at the rising edge of cache_clk, not clk to avoid bug
		.data_fb(DCRAM_read[way]),
		.sample_req(word_sel_sync),
		.write(1'b1)			
		);	defparam	mux_write.SLOT = CACHE_BLOCK_SIZE/4;
				
		Configurable_Mux_Write	mux_replace1
		(
		.data_out(DCRAM_in1[way]),
		.data_in(DL2_out.w1_update),
		.data_fb(DCRAM_out1[way]),
		.sample_req(DL2_out.addr_update),
		.write(DL2_out.update)	
		);	defparam	mux_replace1.SLOT = CACHE_BLOCK_SIZE/8;
		
		Configurable_Mux_Write	mux_replace2
		(
		.data_out(DCRAM_in2[way]),
		.data_in(DL2_out.w2_update),
		.data_fb(DCRAM_out2[way]),
		.sample_req(DL2_out.addr_update),
		.write(DL2_out.update)			
		);	defparam	mux_replace2.SLOT = CACHE_BLOCK_SIZE/8;
		
		assign	DCRAM_in_replace[way] = {DCRAM_in2[way], DCRAM_in1[way]};

		Configurable_Multiplexer	mux_read_way
		(
		.data_out(DL1_data_way[way]),
		.data_in(DCRAM_read[way]),
		.sel(word_sel)
		);	defparam	mux_read_way.INPUT_SLOT = CACHE_BLOCK_SIZE/4;
		
		DualPort_SRAM
		#(
		.SRAM_LENGTH(TAG_LENGTH), 
		.SRAM_DEPTH(DCACHE_LINE)
		)
		ITAG
		( 
		.data_out1(TAG_dcache[way]), 								//	Use for Update
		.data_out2(TAG_read[way]),									//	Use for Read
		.data_in1(tag_up),
		.data_in2(),	
		.addr1(DL1_up_index),
		.addr2(read_index),
		.wen1(replace_way[way]), 
		.wen2(1'b0), 
		.clk(cache_clk)
		);
		
		assign	dcache_way_hit[way] = (TAG_dcache[way] == tag) && dcache_valid[way];	
		assign 	inclusive_inst_way_hit[way] = (TAG_read[way] == inst_tag_inclusive) && inclusive_way_valid[way];
		assign 	inclusive_data_way_hit[way] = (TAG_read[way] == data_tag_inclusive) && inclusive_way_valid[way];
		
		end		
		
	endgenerate

//	DL1 data ouput	
	always_comb	begin
		DL1_data = 'x;
		for(int i = 0; i < DCACHE_WAY; i++)
		begin
		if(dcache_way_hit == (1<<i))
			DL1_data = DL1_data_way[i];
		end
	end

	assign  dcache_hit = |dcache_way_hit;
	
//	Replacement

	`ifdef	DCACHE_ALRU
	ALRU	ALRU_U
	(
	.replace_way(replace_way_new),	
	.replace_index(DL1_index),
	.valid(dcache_valid),
	.hit(dcache_way_hit),
	.cache_clk(cache_clk)
	);
	`elsif	DCACHE_RANDOM
	RANDOM	
	#(
	.RANDOM_BIT(DCACHE_WAY),
	.RANDOM_LINE(DCACHE_LINE))
	RANDOM_U
	(
	.replace_way(replace_way_new),	
//	.replace_index(DL1_index),
	.valid(dcache_valid),
	.hit(dcache_way_hit),
	.cache_clk(cache_clk),
	.rst_n(rst_n)
	);
	`endif

//================================================================================	
//	Data Victim Cache
	`ifdef	DATA_VICTIM_CACHE	
		
		always_comb	begin
			line_up_vc = 'x;
			tag_up_vc = 'x;
			for(int i = 0; i < DCACHE_WAY; i++)
			begin
			if(replace_way[i] == 1'b1)
			begin
				line_up_vc = DCRAM_read[i];
				tag_up_vc = TAG_dcache[i];
			end
			end
		end	
		
		Victim_Cache	
		#(
		.SLOT(CACHE_BLOCK_SIZE/4),
		.VCTAG_LENGTH(TAG_LENGTH + $clog2(DCACHE_LINE)),
		.SRAM_DEPTH(4),
		.KIND("DATA")
		)
		DVC
		(
		.data_out(VC_data),
		.vc_hit(vc_hit),
		.write(cpu_write_sync),
		.data_in(line_up_vc),
		.tag_in({tag_up_vc, DL1_index}),
		.addr(alu_out),	
		.wen(update_vc),
		.rst_n(rst_n),
		.cache_clk(cache_clk)
		);	defparam	DVC.SLOT = CACHE_BLOCK_SIZE/4;
			defparam	DVC.VCTAG_LENGTH = TAG_LENGTH + $clog2(DCACHE_LINE);
			defparam	DVC.SRAM_DEPTH = 4;
	`endif

//================================================================================
//	Write Buffer
	Write_Buffer
	#(
	.DATA_LENGTH(DATA_LENGTH),
	.TAG_LENGTH(DATA_LENGTH-BYTE_OFFSET),
 	.WB_DEPTH(DCACHE_WB_DEPTH),
	.WORD_INDEX(WORD_OFFSET)	
	)
	DL1_WB
	(
	.data_out(wb_data),
	.data_hit(wb_hit_data),
	.full_flag(wb_full),
	.empty_flag(wb_empty),
	.overflow_flag(wb_overflow),
	.underflow_flag(wb_underflow),
	.hit(wb_hit),
	.data_in(data_write_sync),
	.tag_in(wb_tag),
	.read_tag_in(alu_out[DATA_LENGTH-1:BYTE_OFFSET+WORD_OFFSET]),	
	.store(wb_write),
	.load(wb_read),
	.*
	);


//================================================================================	
//	Data Cache Controller		
	DL1_Controller	Controller
	(
	.*,
	.data_out(data_read),
	.update_data((alu_out[BYTE_OFFSET+WORD_OFFSET-1]) ? DL2_out.w2_update : DL2_out.w1_update),
	.update(DL2_out.update)
	);

//	Handshake
	always_ff @(posedge cache_clk or negedge rst_n)
	begin
		if(!rst_n)
			data_update_req <= '0;
		else if(data_update_req)
			data_update_req <= !DL2_out.update;
		else 
			data_update_req <= update_trigger;
	end

	//Hung_mod_21.04.2021 always_ff @(posedge cache_clk or negedge rst_n)
	//Hung_mod_21.04.2021 begin
	//Hung_mod_21.04.2021 	if(!rst_n)
	//Hung_mod_21.04.2021 		dirty_req <= '0;
	//Hung_mod_21.04.2021 	else if(dirty_req)
	//Hung_mod_21.04.2021 		dirty_req <= !dirty_ack;
	//Hung_mod_21.04.2021 	else 
	//Hung_mod_21.04.2021 		dirty_req <= dirty_trigger;
	//Hung_mod_21.04.2021 end
	
	//Hung_mod_04.04.2021 always_ff @(posedge cache_clk or negedge rst_n)
	//Hung_mod_04.04.2021 begin
	//Hung_mod_04.04.2021 	if(!rst_n)
	//Hung_mod_04.04.2021 		dirty_done_raw <= '0;
	//Hung_mod_04.04.2021 	else 
	//Hung_mod_04.04.2021 		dirty_done_raw <= dirty_ack;
	//Hung_mod_04.04.2021 end
	//Hung_mod_04.04.2021 
	//Hung_mod_04.04.2021 assign 	dirty_done = !dirty_ack && dirty_done_raw;
  
  //Hung_add_04.04.2021 
  //Hung_mod_21.04.2021assign dirty_done = 1'b1;
  assign dirty_done = dirty_ack;
  //Hung_add_04.04.2021 
	assign 	dirty_replace_way = dcache_dirty & replace_way_new;		

	always_comb	begin
		dl1_dirty_addr_buf = 'x;
		for(int i = 0; i < DCACHE_WAY; i++)
		begin
		if(dirty_replace_way == (1<<i))
			dl1_dirty_addr_buf = TAG_read[i];		// DL1_index
		end
	end
//	dirty addr	
	assign 	dl1_dirty_addr = {dl1_dirty_addr_buf, DL1_index};

//	dirty word	
	always_comb	begin
		dirty_data_buf = 'x;
		for(int i = 0; i < DCACHE_WAY; i++)
		begin
		if(dirty_replace_way == (1<<i))
			dirty_data_buf = DCRAM_read[i];			// DL1_index
		end
	end

	Configurable_Multiplexer	mux_dirty1
	(
	.data_out(dirty_data1),
	.data_in(dirty_data_buf[CACHE_BLOCK_SIZE*4-1:0]),
	.sel(dirty_word_sel)
	);	defparam	mux_dirty1.INPUT_SLOT = CACHE_BLOCK_SIZE/8;

	Configurable_Multiplexer	mux_dirty2
	(
	.data_out(dirty_data2),
	.data_in(dirty_data_buf[CACHE_BLOCK_SIZE*8-1:CACHE_BLOCK_SIZE*4]),
	.sel(dirty_word_sel)
	);	defparam	mux_dirty2.INPUT_SLOT = CACHE_BLOCK_SIZE/8;		

//================================================================================	
//================================================================================		
//	Handshake
	always_ff @(posedge cache_clk or negedge rst_n)
	begin
		if(!rst_n)
			wb_req <= '0;
		else if(wb_req)
			wb_req <= !wb_ack;
		else 
			wb_req <= wb_trigger;
	end
	
	always_ff @(posedge cache_clk or negedge rst_n)
	begin
		if(!rst_n)
			wb_done_raw <= '0;
		else 
			wb_done_raw <= wb_ack;
	end
	
	assign 	wb_done = !wb_ack && wb_done_raw;

	always_ff @(posedge cache_clk or negedge rst_n)
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
`ifdef 	SIMULATE
	//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/RANDOM.sv"
	//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/ALRU.sv"
	//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/Victim_Cache.sv"
	//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/DualPort_SRAM.sv"	
	//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/DL1_Controller.sv" 
	//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/Configurable_Mux_Write.sv"
	//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/Configurable_Multiplexer.sv"
	//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/Write_Buffer.sv"
	
	//initial begin
	//	//Hung_mod_10.04.2021 $readmemh("WBL2.txt", DL1_WB.WB);			
	//	$readmemh("L2WB.txt", DL1_WB.WB);			
	//end	
`endif
	
endmodule

//================================================================================	
//================================================================================	
//================================================================================	
//================================================================================	

module CHECK_SET
#(
parameter	CHECK_LINE = 128,
parameter 	KIND = "VALID"
)
(
	output										l1_check,
	output 										l2_check,
	input			[$clog2(CHECK_LINE)-1:0]	change_index,
												DL1_index,
												DL1_index_dirty,
	input 										set,
	input										clear,
	input 										cache_clk,
	input 										rst_n
);
	
	logic 	[CHECK_LINE-1:0]	CHECK;
	
	generate
	if(KIND == "VALID") 
	begin
		always_ff @(posedge cache_clk or negedge rst_n)
		begin
			if(!rst_n)
				CHECK <= '0;
			else begin 
				if(set)
					CHECK[change_index] <= 1'b1;
				if(clear)
					CHECK[change_index] <= 1'b0;
			end
		end
	
		assign 	l1_check = CHECK[DL1_index];
		assign	l2_check = CHECK[change_index];
		
	end 
	else if(KIND == "DIRTY") 
	begin
		always_ff @(posedge cache_clk or negedge rst_n)
		begin
			if(!rst_n)
				CHECK <= '0;
			else begin 
				if(set)
					CHECK[DL1_index_dirty] <= 1'b1;				// This can cause bug
				if(clear)
					CHECK[change_index] <= 1'b0;
			end
		end
	
		assign 	l1_check = CHECK[DL1_index];
		assign	l2_check = CHECK[change_index];
	end
	endgenerate
	
endmodule
