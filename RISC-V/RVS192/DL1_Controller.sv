//////////////////////////////////////////////////////////////////////////////////
// File Name: 		DL1_Controller.sv
// Module Name:		RVS192 Data Cache Controller 		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	DL1_Controller
(
//	CPU
	output 	logic	[INST_LENGTH-1:0]					data_out,
	output 	logic	[PC_LENGTH-1:0]						alu_out_up,
	input 	logic 	[PC_LENGTH-1:0]						alu_out,	
	output 	logic 										DCC_halt,
	input												cpu_read,
	input 												cpu_write,		
	input 												L2_full_flag,
//	Dirty Handshake
	output 	logic 										dirty_trigger,
	output 	logic 										dirty_replace,
	output	logic 	[$clog2(CACHE_BLOCK_SIZE/8)-1:0]	dirty_word_sel,
	input 	logic 										dirty_done,
//	VC	
	output 	logic 										update_vc,
	input 	[DATA_LENGTH-1:0]							VC_data,	
	input 												vc_hit,	
//	output	logic 										block_write,
//	output 	logic	[$clog2(CACHE_BLOCK_SIZE/8)-1:0]	block_write_addr,

//	DCACHE
	input 	[DATA_LENGTH-1:0]							DL1_data,
	input 	[DCACHE_WAY-1:0]							replace_way_new,
	input 	[DCACHE_WAY-1:0]							dcache_valid,
	input 	[DCACHE_WAY-1:0]							dcache_dirty,
														inclusive_inst_way_hit,
														inclusive_data_way_hit,
														inclusive_way_dirty,
	input 												dcache_hit,
														inst_replace_sync,
														data_replace_sync,
	input 	[DATA_LENGTH-1:0]							update_data,
	output 	logic 	[$clog2(DCACHE_LINE)-1:0]			inclusive_index,			
	output 	logic 										change_index_sel,
														inst_replace_solve,
														data_replace_solve,	
														inclusive_dirty_sel,
//														replace_sel,
	input 	[$clog2(DCACHE_LINE)-1:0]					inst_index_inclusive,
														data_index_inclusive,	
	output 	logic 										inst_replace_dl1_ack_trigger,
														data_replace_dl1_ack_trigger,	
	output 	logic	[DCACHE_WAY-1:0]					l2_clear_way,													
//	output	logic 	[DCACHE_WAY-1:0]					write_way,
	output 	logic 	[DCACHE_WAY-1:0]					replace_way,	
//	Replace Handshake	
	output 	logic 										update_trigger,
	input 												update,
//	WB
	output 	logic 										wb_trigger,
														wb_write,
														wb_read,														
	input 												wb_full,
														wb_empty,
														wb_overflow,
														wb_underflow,
														wb_done,
														wb_hit,
	input 	[DATA_LENGTH-1:0]							wb_hit_data,
	input												wb_read_tag_hit,
//	System	
	input 												clk_l1,
	input 												rst_n
);

//================================================================================	
//	Internal Signals
	parameter	TAG_LENGTH = DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-$clog2(DCACHE_LINE);

	enum	logic [2:0]
	{
	IDLE,
	WAIT_WB,
	HALT_REPLACE,
	HALT_DIRTY_1,
	HALT_DIRTY_2,
	CHALLENGE,
	PENALTY,
	WAIT_WRITE
	}	current_state, next_state;

	enum 	logic [3:0]
	{
	L2H_IDLE,
	L2H_D_DELAY,
	L2H_INST_BUSY,
	L2H_INST_SOLVE,
	L2H_INST_DIRTY,
	L2H_I_DELAY,
	L2H_DATA_BUSY,
	L2H_DATA_SOLVE,
	L2H_DATA_DIRTY
	}	L2_rep_current_state, L2_rep_next_state;
	
	enum	logic
	{
		WB_EMPT,
		WB_DONE	
	}	WB_state, WB_next_state;
	
	logic 	[DCACHE_WAY-1:0]	replace_way_buf,
								write_way_buf;	
	logic 	dirty,
			valid,
			miss,
			miss_read,
			miss_write,
			DCC_halt_raw,
			update_req_raw,
			update_req_raw1,
			update_req_raw2,
			dirty_req_raw,
			dirty_req_raw1,
			dirty_req_raw2,
			wb_req_raw,
			wb_req_raw1,
			wb_req_raw2,			
			wb_read_raw,
			wb_read_raw1,
			wb_read_raw2,
			L2_dirty_replace,
//			L2_replace_halt,
			L2_dirty_req,
			inclusive_inst_hit,
			inclusive_data_hit,
			inst_inclusive_dirty,
			data_inclusive_dirty;
			
	logic 	[TAG_LENGTH-1:0]					tag,
												tag_up;
												
//================================================================================	
	assign	dirty = |(dcache_dirty & replace_way_new); 
	assign 	miss_read = !dcache_hit && !vc_hit && !wb_hit && cpu_read;
	assign 	miss_write = !dcache_hit && !wb_hit && cpu_write && wb_full;
	assign 	miss = miss_read || miss_write;
	assign 	valid = &dcache_valid;
	
	assign 	tag = alu_out[DATA_LENGTH-1:BYTE_OFFSET+WORD_OFFSET+$clog2(DCACHE_LINE)];
	assign 	tag_up = alu_out_up[DATA_LENGTH-1:BYTE_OFFSET+WORD_OFFSET+$clog2(DCACHE_LINE)];	
	
	assign 	inclusive_inst_hit = |inclusive_inst_way_hit;	
	assign 	inclusive_data_hit = |inclusive_data_way_hit;
	assign 	inst_inclusive_dirty = |(inclusive_inst_way_hit & inclusive_way_dirty);
	assign 	data_inclusive_dirty = |(inclusive_data_way_hit & inclusive_way_dirty);
	
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			dirty_word_sel <= '0;
		else if(!dirty_replace && !L2_dirty_replace)
			dirty_word_sel <= '0;
		else
			dirty_word_sel <= dirty_word_sel + 1;
	end	
	
//	DIRTY & REPLACE FSM
//	Next State Logic
	always_comb	begin
		next_state = IDLE;
		DCC_halt_raw = 1'b0;
		update_req_raw = 1'b0;
		dirty_req_raw = 1'b0;
		dirty_replace = 1'b0;
//		replace_sel = 1'b0;
		unique case(current_state)
			IDLE:
			begin
				if(miss && wb_read_tag_hit)
				begin
					DCC_halt_raw = 1'b1;
					next_state = WAIT_WB;					
				end
				else if(!dirty && miss)
				begin
					update_req_raw = 1'b1;
					DCC_halt_raw = 1'b1;
					next_state = HALT_REPLACE;
				end
				else if(dirty && miss)
				begin
					dirty_replace = 1'b1;
					DCC_halt_raw = 1'b1;
					next_state = HALT_DIRTY_1;				
				end
				else
					next_state = current_state;
			end
			WAIT_WB:
			begin
				DCC_halt_raw = 1'b1;
				if(!wb_read_tag_hit)	
					next_state = IDLE;
				else
					next_state = current_state;
			end
			HALT_REPLACE:
			begin
//				replace_sel = 1'b1;
				DCC_halt_raw = 1'b1;			
				if(update && cpu_read)
				begin
					update_req_raw = 1'b0;
					DCC_halt_raw = 1'b0;
					next_state = CHALLENGE;				
				end
				else if(update && cpu_write)
				begin
					update_req_raw = 1'b0;
					next_state = WAIT_WRITE;						
				end
				else 
					next_state = current_state;
			end
			HALT_DIRTY_1:
			begin
				DCC_halt_raw = 1'b1;			
				dirty_replace = 1'b1;
				if(dirty_word_sel == CACHE_BLOCK_SIZE/8-1)
				begin
					dirty_req_raw = 1'b1;
//					dirty_replace = 1'b0;
					next_state = HALT_DIRTY_2;
				end			
				else 
					next_state = current_state;
			end
			HALT_DIRTY_2:
			begin
				if(dirty_done)
				begin
					dirty_req_raw = 1'b0;
					update_req_raw = 1'b1;
					next_state = HALT_REPLACE;				
				end
				else 
					next_state = current_state;				
			end
			CHALLENGE:
			begin
//				replace_sel = 1'b1;			
				if(!miss && !update)
					next_state = IDLE;
				else if(miss)
				begin
					next_state = PENALTY;
					DCC_halt_raw = 1'b1;
				end	
				else if(cpu_write && (tag == tag_up))
				begin
					DCC_halt_raw = 1'b1;
					next_state = WAIT_WRITE;
				end
				else 
					next_state = current_state;
			end
			PENALTY:
			begin
//				replace_sel = 1'b1;			
				DCC_halt_raw = 1'b1;			
				if(!update && dirty)
				begin
					dirty_replace = 1'b1;
					next_state = HALT_DIRTY_1;
				end
				else if(!update && !dirty)
				begin
					update_req_raw = 1'b1;
					next_state = HALT_REPLACE;
				end
				else 
					next_state = current_state;
			end
			WAIT_WRITE:
			begin
//				replace_sel = 1'b1;			
				DCC_halt_raw = 1'b1;			
				if(!update)
				begin
					DCC_halt_raw = 1'b0;
					next_state = IDLE;
				end
				else
					next_state = current_state;				
			end
			default: 	next_state = IDLE;
		endcase
	end
	
//	State Memory
	always_ff @(negedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			current_state <= IDLE;
		else 
			current_state <= next_state;
	end
//================================================================================
//================================================================================
//================================================================================	
//	DFF to remove glitches
	always_ff @(negedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			DCC_halt <= 1'b0;;
			update_req_raw1 <= 1'b0;
			dirty_req_raw1 <= 1'b0;
		end
		else begin
			DCC_halt <= DCC_halt_raw || L2_dirty_replace;
			update_req_raw1 <= update_req_raw;
			dirty_req_raw1 <= dirty_req_raw || L2_dirty_req;
		end
	end

//================================================================================
//================================================================================
//================================================================================
//	L2 Replace FSM
//	Next State Logic
	always_comb	begin
		L2_rep_next_state = L2H_IDLE;
		inst_replace_solve = 1'b0;
		data_replace_solve = 1'b0;
		change_index_sel = 1'b0;
		inclusive_dirty_sel = 1'b0;
		inclusive_index = inst_index_inclusive;
		inst_replace_dl1_ack_trigger = 1'b0;
		data_replace_dl1_ack_trigger = 1'b0;	
		L2_dirty_req = 1'b0;
		L2_dirty_replace = 1'b0;
		l2_clear_way = 1'b0;
//		L2_replace_halt = 1'b0;
		unique case(L2_rep_current_state)
			L2H_IDLE:	
			begin
				if(inst_replace_sync && !update && !(dirty && miss))
				begin
					L2_rep_next_state = L2H_I_DELAY;
					change_index_sel = 1'b1;
				end
				else if(data_replace_sync && !update && !(dirty && miss))
				begin
					L2_rep_next_state = L2H_D_DELAY;
					change_index_sel = 1'b1;
					inclusive_index = data_index_inclusive;
				end
				else 
					L2_rep_next_state = L2_rep_current_state;						
			end
			L2H_I_DELAY:
			begin
				change_index_sel = 1'b1;			
				L2_rep_next_state = L2H_INST_BUSY;						
			end
			L2H_D_DELAY:
			begin
				change_index_sel = 1'b1;			
				L2_rep_next_state = L2H_DATA_BUSY;			
				inclusive_index = data_index_inclusive;				
			end			
			L2H_INST_BUSY:
			begin
				change_index_sel = 1'b1;
				if(inclusive_inst_hit && !inst_inclusive_dirty)
				begin
					l2_clear_way = inclusive_inst_way_hit;
					inst_replace_solve = 1'b1;
					L2_rep_next_state = L2H_INST_SOLVE;					
				end	
				else if(inst_inclusive_dirty)
				begin
					l2_clear_way = inclusive_inst_way_hit;
					L2_dirty_replace = 1'b1;
					L2_rep_next_state = L2H_INST_DIRTY;								
				end
				else 
					L2_rep_next_state = L2H_INST_SOLVE;						
			end
			L2H_INST_DIRTY:
			begin
				L2_dirty_replace = 1'b1;	
				inclusive_dirty_sel = 1'b1;
				if(dirty_word_sel == CACHE_BLOCK_SIZE/8-1)
				begin
					L2_dirty_req = 1'b1;
//					L2_dirty_replace = 1'b0;
					inst_replace_solve = 1'b1;			
					inst_replace_dl1_ack_trigger = 1'b1;					
					L2_rep_next_state = L2H_INST_SOLVE;
				end			
				else 
					L2_rep_next_state = L2_rep_current_state;				
			end
			L2H_INST_SOLVE:
			begin
				if(!inst_replace_sync)
					L2_rep_next_state = L2H_IDLE;
				else 
					L2_rep_next_state = L2_rep_current_state;				
			end
			L2H_DATA_BUSY:
			begin
				change_index_sel = 1'b1;
				inclusive_index = data_index_inclusive;				
				if(inclusive_data_hit && !data_inclusive_dirty)
				begin
					l2_clear_way = inclusive_data_way_hit;
					data_replace_solve = 1'b1;
					L2_rep_next_state = L2H_INST_SOLVE;					
				end	
				else if(data_inclusive_dirty)
				begin
					l2_clear_way = inclusive_data_way_hit;
					L2_dirty_replace = 1'b1;
					L2_rep_next_state = L2H_INST_DIRTY;								
				end
				else 
					L2_rep_next_state = L2H_INST_SOLVE;						
			end
			L2H_DATA_DIRTY:
			begin
				L2_dirty_replace = 1'b1;	
				inclusive_dirty_sel = 1'b1;
				inclusive_index = data_index_inclusive;						
				if(dirty_word_sel == CACHE_BLOCK_SIZE/8-1)
				begin
					L2_dirty_req = 1'b1;
//					L2_dirty_replace = 1'b0;
					data_replace_solve = 1'b1;			
					data_replace_dl1_ack_trigger = 1'b1;					
					L2_rep_next_state = L2H_INST_SOLVE;
				end			
				else 
					L2_rep_next_state = L2_rep_current_state;					
			end
			L2H_DATA_SOLVE:
			begin
				if(!data_replace_sync)
					L2_rep_next_state = L2H_IDLE;
				else 
					L2_rep_next_state = L2_rep_current_state;				
			end			
		endcase
	end	

//	State Memory		
	always_ff @(negedge clk_l1 or negedge rst_n)							
	begin																		
		if(!rst_n)																
			L2_rep_current_state <= L2H_IDLE;	
		else 
			L2_rep_current_state <= L2_rep_next_state;
	end	
	
//================================================================================	
//	assign wb_write = ((!wb_full || wb_hit) && cpu_write && !dcache_hit) ? 1'b1 : 1'b0;
	always_ff @(posedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			wb_write <= 1'b0;
		else if((!wb_full || wb_hit) && cpu_write && !dcache_hit)	
			wb_write <= 1'b1;
		else 
			wb_write <= 1'b0;
	end

//	WB FSM			
//	Next State Logic
	always_comb begin
		wb_req_raw = 1'b0;
		wb_read_raw = 1'b0;
		WB_next_state = WB_EMPT;
		unique case(WB_state)
		WB_EMPT:
		begin
			if(!wb_empty && !L2_full_flag)
			begin
				wb_req_raw = 1'b1;
				wb_read_raw = 1'b0;
				WB_next_state = WB_DONE;
			end
			else
				WB_next_state = WB_state;
		end
		WB_DONE:
		begin
			if(wb_done)
			begin
				wb_req_raw = 1'b0;
				wb_read_raw = 1'b1;
				WB_next_state = WB_EMPT;
			end
			else
				WB_next_state = WB_state;
		end
		default:	WB_next_state = WB_EMPT;
		endcase
	end
	
//	State Memory
	always_ff @(negedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
			WB_state <= WB_EMPT;
		else 
			WB_state <= WB_next_state;
	end
	
//	DFF to remove glitches		
	always_ff @(negedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			wb_read_raw1 <= 1'b0;
			wb_req_raw1 <= 1'b0;
		end
		else 
		begin
			wb_read_raw1 <= wb_read_raw; 
			wb_req_raw1 <= wb_req_raw;
		end
	end
//================================================================================
//	Replace handle

//================================================================================	
//	Trigger Output	
	always_ff @(negedge clk_l1)
	begin
		if(current_state == HALT_REPLACE)
		begin
			alu_out_up <= alu_out;					// Update miss PC
			replace_way_buf <= replace_way_new;
		end
	end	
	
	always_ff @(negedge clk_l1)
	begin
		update_req_raw2 <= update_req_raw1;	
		dirty_req_raw2 <= dirty_req_raw1;
		wb_req_raw2 <= wb_req_raw1;
		wb_read_raw2 <= wb_read_raw1;
	end	
	
	assign 	replace_way = (update) ? replace_way_buf : '0;
	assign 	update_trigger = !update_req_raw2 && update_req_raw1;
	assign 	update_vc = valid && update_trigger;
	assign 	wb_trigger = !wb_req_raw2 && wb_req_raw1;
	assign 	wb_read = !wb_read_raw2 && wb_read_raw1;	
	assign 	dirty_trigger = !dirty_req_raw2 && dirty_req_raw1;

	assign 	data_out = ((alu_out[DATA_LENGTH-1:BYTE_OFFSET+WORD_OFFSET] == alu_out_up[DATA_LENGTH-1:BYTE_OFFSET+WORD_OFFSET])&&update) ? update_data : (dcache_hit ? DL1_data : (vc_hit ? VC_data : (wb_hit ? wb_hit_data : '0)));
	
endmodule	