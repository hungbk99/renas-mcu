//////////////////////////////////////////////////////////////////////////////////
// File Name: 		IL1_Controller.sv
// Module Name:		RVS192 Instruction Cache Controller 		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	IL1_Controller
(
	output 	logic	[INST_LENGTH-1:0]			inst_fetch,
	output 	logic	[PC_LENGTH-1:0]				pc_up,
	output 	logic 	[ICACHE_WAY-1:0]			replace_way,
												l2_clear_way,
	output 	logic 								ICC_halt,
												update_trigger,
												update_vc,	
	output 	logic 	[$clog2(ICACHE_LINE)-1:0]	inclusive_index,			
	output 	logic 								change_index_sel,
												inst_replace_solve,
												data_replace_solve,
												inst_replace_il1_ack_trigger,
												data_replace_il1_ack_trigger,
	input 	[$clog2(ICACHE_LINE)-1:0]			inst_index_inclusive,
												data_index_inclusive,	
	input 	[PC_LENGTH-1:0]						pc,
	input 	[INST_LENGTH-1:0]					IL1_inst,
												VC_inst,	
	input 	[ICACHE_WAY-1:0]					replace_way_new,
												icache_way_valid,
	input										icache_hit,
												vc_hit,
												update,	
	input 	[INST_LENGTH-1:0]					update_inst,	
	input 										inst_replace_sync,
												data_replace_sync,
	input 	[ICACHE_WAY-1:0]					inclusive_inst_way_hit,
												inclusive_data_way_hit,
	input										clk_l1,
												rst_n
);

//================================================================================	
//	Internal Signals
	enum	logic [1:0]
	{
	IDLE = 2'b00,
	HALT_L1 = 2'b01,
	CHALLENGE = 2'b10,
	PENALTY = 2'b11
	}	current_state, next_state;
	
	enum 	logic [2:0]
	{
	L2H_IDLE,
	L2H_D_DELAY,
	L2H_INST_BUSY,
	L2H_INST_SOLVE,
	L2H_I_DELAY,
	L2H_DATA_BUSY,
	L2H_DATA_SOLVE
	}	L2_rep_current_state, L2_rep_next_state;
	
	logic 	valid,
			miss,
			ICC_halt_raw,
			update_req_raw,
			update_req_raw1,
			update_req_raw2,
			inclusive_data_hit,
			inclusive_inst_hit;
			
	logic 	[ICACHE_WAY-1:0]	replace_way_buf;
//================================================================================		
//	Update L1 Cache	
	assign	miss = (!icache_hit)&&(!vc_hit);					// if one of these bit is x 
																// metastability will propagate 
																// Note thissssssss
	assign 	valid = &icache_way_valid;															
	assign 	inclusive_inst_hit = |inclusive_inst_way_hit;	
	assign 	inclusive_data_hit = |inclusive_data_way_hit;
		
	
//	Next State Logic
	always_comb	begin
		next_state = IDLE;
		ICC_halt_raw = 1'b0;
		update_req_raw = 1'b0;
		unique case(current_state)
			IDLE:	
			begin
				if(miss)										
				begin
					next_state = HALT_L1;
					ICC_halt_raw = 1'b1;
					update_req_raw = 1'b1;
				end
				else											
					next_state = current_state;
			end		
			HALT_L1:	
			begin
				ICC_halt_raw = 1'b1;			
				if(update)
				begin
					next_state = CHALLENGE;
					ICC_halt_raw = 1'b0;
					update_req_raw = 1'b0;
				end
				else
					next_state = current_state;
			end
			CHALLENGE:
			begin
				if(miss && !update)		
				begin
					next_state = HALT_L1;					// Highest priority
					ICC_halt_raw = 1'b1;
					update_req_raw = 1'b1;
				end
				else if(miss)	
				begin
					next_state = PENALTY;					// High priority
					ICC_halt_raw = 1'b1;
				end
				else if(!update && !miss)
					next_state = IDLE;						// Lower priority	
				else
					next_state = current_state;	
			end
			PENALTY:
			begin
				ICC_halt_raw = 1'b1;				
				if(!update)
				begin
					next_state = HALT_L1;
					update_req_raw = 1'b1;  
				end
				else
					next_state = current_state;	
			end		
			default:	next_state = IDLE;
		endcase	
	end
	
//	State Memory	
	always_ff @(negedge clk_l1 or negedge rst_n)							// Using posedge clk_l1 will be wrong
	begin																// Changing from miss to hit will cause bug				
		if(!rst_n)																
			current_state <= IDLE;	
		else 
			current_state <= next_state;
	end

// 	DFF to remove glitches
	always_ff @(negedge clk_l1 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			ICC_halt <= 1'b0;;
			update_req_raw1 <= 1'b0;
		end
		else begin
			ICC_halt <= ICC_halt_raw;
			update_req_raw1 <= update_req_raw;
		end
	end
//================================================================================	
//	Next State Logic
	always_comb	begin
		L2_rep_next_state = L2H_IDLE;
		inst_replace_solve = 1'b0;
		data_replace_solve = 1'b0;
		change_index_sel = 1'b0;
		inclusive_index = inst_index_inclusive;
		inst_replace_il1_ack_trigger = 1'b0;
		data_replace_il1_ack_trigger = 1'b0;
		l2_clear_way = '0;
		unique case(L2_rep_current_state)
			L2H_IDLE:	
			begin
				if(inst_replace_sync && !update)
				begin
					L2_rep_next_state = L2H_I_DELAY;
					change_index_sel = 1'b1;
				end
				else if(data_replace_sync && !update)
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
				if(inclusive_inst_hit)
				begin
					l2_clear_way = inclusive_inst_way_hit;
					inst_replace_il1_ack_trigger = 1'b1;
				end				
				inst_replace_solve = 1'b1;				
				L2_rep_next_state = L2H_INST_SOLVE;
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
				if(inclusive_data_hit)
				begin
					l2_clear_way = inclusive_data_way_hit;
					data_replace_il1_ack_trigger = 1'b1;
				end	
				data_replace_solve = 1'b1;				
				L2_rep_next_state = L2H_DATA_SOLVE;
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
	always_ff @(negedge clk_l1)
	begin
		if(current_state == HALT_L1)
		begin
			pc_up <= pc;					// Update miss PC
			replace_way_buf <= replace_way_new;
		end
	end
	
	always_ff @(negedge clk_l1)
	begin
		update_req_raw2 <= update_req_raw1;	
	end
	
	assign 	replace_way = (update) ? replace_way_buf : '0;
	assign 	update_trigger = !update_req_raw2 && update_req_raw1;
	assign 	update_vc = valid && update_trigger;
	assign	inst_fetch = ((pc[INST_LENGTH-1:BYTE_OFFSET + WORD_OFFSET]==pc_up[INST_LENGTH-1:BYTE_OFFSET + WORD_OFFSET])&&update) ? update_inst : ((icache_hit) ? IL1_inst : (vc_hit ? VC_inst : 32'h00007033));
	
endmodule