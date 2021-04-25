//////////////////////////////////////////////////////////////////////////////////
// File Name: 		L2C_Controller.sv
// Module Name:		Level 2 Cache Controller	
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

//`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	L2C_Controller
(
	output 	logic 								  data_addr_sel,
//	Update IL1
	output 	logic								    inst_update_ena,
	output 	logic								    inst_mem_dirty_req,
										          		inst_mem_replace_req,
												          inst_replace_req,
	input 										      inst_mem_dirty_done,
												          inst_mem_replace_done,
												          l1_inst_replace_req,
												          inst_replace_il1_ack_sync,
												          inst_replace_dl1_ack_sync,
//	Update DL1
	output 	logic								    data_update_ena,
	output 	logic 	  							data_mem_dirty_req,
		        		  								data_mem_replace_req,	
										          		data_replace_req,
	input 										      data_mem_dirty_done,
												          data_mem_replace_done,
												          l1_data_replace_req,
												          data_replace_il1_ack_sync,
												          data_replace_dl1_ack_sync,
//	L2 Cache
	input 										      inst_miss,
	input 										      data_miss,
	input 										      inst_dirty,
	input 										      data_dirty,
//	WB
	input 										      wb_read_tag_hit,
//	System
	input								        		clk_l2,
	input								        		rst_n
);
	

//================================================================================
	logic 	inst_replace_req_raw,
			inst_mem_dirty_req_raw,
			inst_mem_replace_req_raw,
			data_replace_req_raw,
			data_mem_dirty_req_raw,
			data_mem_replace_req_raw,
			inst_update_ena_raw,
			data_update_ena_raw,
			data_addr_sel_raw;	
			
	enum	logic [2:0]
	{
		I_IDLE,
		I_REPLACEMENT,
		I_WAIT_ACK,
		I_M_DIRTY,
		I_M_REPLACE
	}	inst_current_state, inst_next_state;
	
	enum	logic [2:0]
	{
		D_IDLE,
		D_REPLACEMENT,
		D_WAIT_ACK,
		D_M_DIRTY,
		D_WAIT,
		D_M_REPLACE
	}	data_current_state, data_next_state;	
	
//================================================================================
//	Inst Controller
//	Next State Logic

	always_comb begin
		inst_next_state = I_IDLE;
		inst_replace_req_raw = 1'b0;
		inst_mem_dirty_req_raw = 1'b0;
		inst_mem_replace_req_raw = 1'b0;
		inst_update_ena_raw = 1'b0;
		data_addr_sel_raw = 1'b0;
		unique case(inst_current_state)
		I_IDLE:
		begin
			if(l1_inst_replace_req && inst_miss)
			begin
				inst_next_state = I_WAIT_ACK;
				inst_replace_req_raw = 1'b1;
			end
			else if(l1_inst_replace_req && !inst_miss)
			begin
				inst_next_state = I_IDLE;
				inst_update_ena_raw = 1'b1;
			end			
			else
			begin
				inst_next_state = inst_current_state;
//				inst_update_ena_raw = 1'b0;
			end
		end
		I_WAIT_ACK:
		begin
			if(inst_replace_il1_ack_sync || inst_replace_dl1_ack_sync)
				inst_next_state = I_REPLACEMENT;
			else 
				inst_next_state = inst_current_state;
		end	
		I_REPLACEMENT:
		begin
			inst_replace_req_raw = 1'b0;
			if(inst_dirty)
			begin
				inst_next_state = I_M_DIRTY;
				inst_mem_dirty_req_raw = 1'b1;
			end
			else if(!inst_dirty)
			begin
				inst_next_state = I_M_REPLACE;
				inst_mem_replace_req_raw = 1'b1;
			end
			else
				inst_next_state = inst_current_state;				
		end
		I_M_DIRTY:
		begin
			inst_mem_dirty_req_raw = 1'b1;		
			data_addr_sel_raw = 1'b1;
			if(inst_mem_dirty_done)
			begin
				inst_next_state = I_M_REPLACE;
				inst_mem_replace_req_raw = 1'b1;	
//				inst_mem_dirty_req_raw = 1'b0;
			end
			else
				inst_next_state = inst_current_state;			
		end
		I_M_REPLACE:
		begin
			if(inst_mem_replace_done)
			begin
				inst_next_state = I_IDLE;
				inst_mem_replace_req_raw = 1'b0;
				inst_update_ena_raw = 1'b1;
			end
			else
				inst_next_state = inst_current_state;				
		end
		default:	inst_next_state = I_IDLE;	
		endcase
	end
	
//	State Memory
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			inst_current_state <= I_IDLE;
		else 
			inst_current_state <= inst_next_state;
	end
	
//	DFF to remove glitches
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_replace_req <= 1'b0;
			inst_mem_dirty_req <= 1'b0;
			inst_mem_replace_req <= 1'b0;
			inst_update_ena <= 1'b0;
		end
		else begin
			inst_replace_req <= inst_replace_req_raw;
			inst_mem_dirty_req <= inst_mem_dirty_req_raw;
			inst_mem_replace_req <= inst_mem_replace_req_raw;		
			inst_update_ena <= inst_update_ena_raw;			
		end
	end	

//================================================================================
//	Data Controller
//	Next State Logic

	always_comb begin
		data_next_state = D_IDLE;
		data_replace_req_raw = 1'b0;
		data_mem_dirty_req_raw = 1'b0;
		data_mem_replace_req_raw = 1'b0;
		data_update_ena_raw = 1'b0;
		unique case(data_current_state)
		D_IDLE:
		begin
			if(l1_data_replace_req && data_miss)
			begin
				data_next_state = D_WAIT_ACK;
				data_replace_req_raw = 1'b1;
			end
			//else if(l1_data_replace_req && data_miss)
			//begin
			//	data_next_state = D_IDLE;
			//	data_update_ena_raw = 1'b1;
			//end
			else
			begin
				data_next_state = data_current_state;
//				data_update_ena_raw = 1'b0;				
			end
		end
		D_WAIT_ACK:
		begin
			if(data_replace_il1_ack_sync || data_replace_dl1_ack_sync)
				data_next_state = D_REPLACEMENT;
			else 
				data_next_state = data_current_state;
		end			
		D_REPLACEMENT:
		begin
			data_replace_req_raw = 1'b0;
			if(data_dirty)
			begin
				data_next_state = D_M_DIRTY;
				data_mem_dirty_req_raw = 1'b1;
			end
			else if(!data_dirty && wb_read_tag_hit)					//	=>	Nếu yêu cầu replace ngay sẽ sai 
				data_next_state = D_WAIT;							//	=>  Chờ cho ô nhớ có tag trùng đó được đưa xuống MEM, cho phép replace 		
			else if(!data_dirty)
			begin
				data_next_state = D_M_REPLACE;
				data_mem_replace_req_raw = 1'b1;
			end
			else
				data_next_state = data_current_state;				
		end
		D_M_DIRTY:
		begin
			data_mem_dirty_req_raw = 1'b1;		
			if(data_mem_dirty_done && !wb_read_tag_hit)
			begin
				data_next_state = D_M_REPLACE;
				data_mem_replace_req_raw = 1'b1;	
				data_mem_dirty_req_raw = 1'b0;
			end
			else if(data_mem_dirty_done && wb_read_tag_hit)			//	Dữ liệu cần đọc ra có tag trùng với ô nhớ nằm trong WB, không có trong Cache
			begin													//	=>	Nếu yêu cầu replace ngay sẽ sai 
				data_next_state = D_WAIT;							//	=>  Chờ cho ô nhớ có tag trùng đó được đưa xuống MEM, cho phép replace 
				data_mem_dirty_req_raw = 1'b0;				
			end
			else
				data_next_state = data_current_state;			
		end
		D_WAIT:
		begin
			if(!wb_read_tag_hit)
			begin
				data_next_state = D_M_REPLACE;
				data_mem_replace_req_raw = 1'b1;			
			end
			else
				data_next_state = data_current_state;
		end
		D_M_REPLACE:
		begin
			if(data_mem_replace_done)
			begin
				data_next_state = D_IDLE;
				data_mem_replace_req_raw = 1'b0;
				data_update_ena_raw = 1'b1;
			end
			else
				data_next_state = data_current_state;				
		end
		default:	data_next_state = D_IDLE;	
		endcase
	end
	
//	State Memory
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
			data_current_state <= D_IDLE;
		else 
			data_current_state <= data_next_state;
	end
	
//	DFF to remove glitches
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			data_replace_req <= 1'b0;
			data_mem_dirty_req <= 1'b0;
			data_mem_replace_req <= 1'b0;
			data_update_ena <= 1'b0;
			data_addr_sel <= 1'b0;
		end
		else begin
			data_replace_req <= data_replace_req_raw;
			data_mem_dirty_req <= data_mem_dirty_req_raw;
			data_mem_replace_req <= data_mem_replace_req_raw;		
			data_update_ena <= data_update_ena_raw;
			data_addr_sel <= data_addr_sel_raw;
		end
	end	
	
//	replace_way	
/*
	always_ff @(posedge clk_l2 or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_replace_way <= '0;
			data_replace_way <= '0;
		end
		else begin
			if(inst_current_state == I_REPLACEMENT)
			begin
				inst_replace_way <= inst_replace_way_new;
	//			inst_check_tag <= inst_index;
			end
			if(data_current_state == D_REPLACEMENT)
			begin
				data_replace_way <= data_replace_way_new;
	//			data_check_tag <= data_index;
			end
		end	
	end
*/

endmodule
