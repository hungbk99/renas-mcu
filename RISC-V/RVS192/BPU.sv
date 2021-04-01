//////////////////////////////////////////////////////////////////////////////////
// File Name: 		BPU.sv
// Module Name:		RVS192 Branch Prediction Unit 		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////
`include"RVS192_user_define.h"
	`ifdef	HYBRID_BP
	`define GBP_GEN;
	`define LBP_GEN;
	`elsif	GSHARE_BP
	`define	GBP_GEN;
	`elsif	LOCAL_BP
	`define LBP_GEN;
	`endif
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	BPU
//	#(`include"RVS192_user_parameters.h")
//	import	RVS192_user_parameters::*;	
(
	output	br_check_type	br_check_fetch,
	output 	logic			pc_sel,
							pc_fix,
	output	[PC_LENGTH-1:0]	target_predict,
	input 	br_update_type	br_update_ex,
	input 	[PC_LENGTH-1:0]	pc_ex,
							pc_in,
							target_pc,
	input 					clk,
							rst_n
);

//================================================================================	
//	Internal Signals
//	logic 	[1:0]	byte_index;
	logic 	[1:0]	byte_index_mem;
//	logic 	br_check_fetch.branch_take;
	logic 	[PC_LENGTH+BTB_TAG_LENGTH-1:0]	BTB [2**BTB_INDEX-1:0];
	logic 	[2**BTB_INDEX-1:0]	VALID;
	logic 	valid_bit;
	logic 	avail_bit;
	logic 	BTB_hit;
	
`ifdef 	GBP_GEN
	logic 	[GSHARE_HISTORY_LENGTH-1:0]	GBHR;
	logic	[1:0]	GPT [2**GSHARE_GPT_INDEX-1:0];
	logic 	[GSHARE_GPT_INDEX-1:0]	GPT_index;
	logic 	[GSHARE_GPT_INDEX-1:0]	GPT_index_update;	
`endif
	
`ifdef	LBP_GEN
	logic	[LOCAL_HISTORY_LENGTH-1:0]	LHT [2**LOCAL_LHT_INDEX-1:0];
	logic 	[1:0]	LPT	[2**LOCAL_LPT_INDEX-1:0];
//	logic 	[LOCAL_LHT_INDEX-1:0]	LHT_index;
	logic 	[LOCAL_LHT_INDEX-1:0]	LHT_index_update;	
	logic 	[LOCAL_LPT_INDEX-1:0]	LPT_index;	
	logic 	[LOCAL_LPT_INDEX-1:0]	LPT_index_update;
`endif

`ifdef	HYBRID_BP
	logic	[1:0]	CPT	[2**GSHARE_GPT_INDEX-1:0];
	logic 	[1:0] 	CPT_predict;
	logic 	[GSHARE_GPT_INDEX-1:0]	CPT_index;	
`endif
//================================================================================	

//	assign	byte_index = pc_in[1:0];
	assign 	byte_index_mem = pc_ex[1:0];

//	BHT	
`ifdef 	GBP_GEN																				//	Fixing pc_ex if not enough 
	assign 	GPT_index = pc_in[GSHARE_GPT_INDEX+1:2] ^ GBHR;
	assign	br_check_fetch.GBHR = GBHR;
	assign 	GPT_index_update = pc_ex[GSHARE_GPT_INDEX+1:2] ^ br_update_ex.GBHR_old;
	
	always_ff @(posedge clk)
	begin
		if((byte_index_mem == 2'b0)&&(br_update_ex.update))
			GPT[GPT_index_update] <= br_update_ex.GBP_predict_update;
	end
	
	assign 	br_check_fetch.GBP_predict = GPT[GPT_index];
	
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			GBHR <= '0;	
		else if((byte_index_mem == 2'b0)&&(br_update_ex.update))
//			GBHR <= {GBHR[GSHARE_HISTORY_LENGTH-1:1], br_update_ex.actual};		//This code line will create latch
//			GBHR <= (GBHR << 1) | br_update_ex.actual;
			GBHR <= {br_update_ex.GBHR_old[GSHARE_HISTORY_LENGTH-1:1], br_update_ex.actual};
		else 
			GBHR <= GBHR;
	end
`endif

`ifdef	LBP_GEN
//	assign 	LHT_index = pc_in[LOCAL_LHT_INDEX+1:2];
	assign 	LHT_index_update = pc_ex[LOCAL_LHT_INDEX+1:2];	
	assign 	LPT_index = pc_in[LOCAL_LPT_INDEX+1:2] ^ br_check_fetch.LBHR;						// 	ignore 2 LSB bit (Byte index)
	assign 	LPT_index_update = pc_ex[LOCAL_LPT_INDEX+1:2] ^ br_update_ex.LBHR_old; 
	
	always_ff @(posedge clk)
	begin
		if((byte_index_mem == 2'b0)&&(br_update_ex.update))
			LHT[LHT_index_update] <= {br_update_ex.LBHR_old[LOCAL_HISTORY_LENGTH-1:1], br_update_ex.actual};
	end
	
	always_ff @(posedge clk)
	begin
		if((byte_index_mem == 2'b00)&&(br_update_ex.update))
			LPT[LPT_index_update] <= br_update_ex.LBP_predict_update;
	end
	
	assign	br_check_fetch.LBP_predict = LPT[LPT_index];	 
	assign 	br_check_fetch.LBHR = LHT[pc_in[LOCAL_LPT_INDEX+1:2]];
`endif

//	BTB
	always_ff @(posedge clk)
	begin
		if((byte_index_mem == 2'b00)&&(br_update_ex.update))
			BTB[pc_ex[BTB_INDEX+1:2]] <= {pc_ex[PC_LENGTH-1:BTB_INDEX+2], target_pc};
	end
	
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			VALID <= '0;
		else if((byte_index_mem == 2'b00)&&(br_update_ex.update))
			VALID[pc_ex[BTB_INDEX+1:2]] <= 1'b1;  
	end
	
	assign 	target_predict = BTB[pc_in[BTB_INDEX+1:2]][PC_LENGTH-1:0];
	assign	avail_bit = ~|(BTB[pc_in[BTB_INDEX+1:2]][PC_LENGTH+BTB_TAG_LENGTH-1:PC_LENGTH] ^ pc_in[PC_LENGTH-1:BTB_INDEX+2]);
	assign 	valid_bit = VALID[pc_in[BTB_INDEX+1:2]];
	assign	BTB_hit = valid_bit && avail_bit;	
	
`ifdef	HYBRID_BP
//	Choose Pattern Table
	always_ff @(posedge clk)
	begin
		if((byte_index_mem == 2'b0)&&(br_update_ex.update))
			CPT[GPT_index_update] <= br_update_ex.CPT_predict_update;
	end	
	
	assign 	CPT_index = GPT_index;
	assign 	br_check_fetch.CPT_predict = CPT[CPT_index];
	
	always_comb begin
		br_check_fetch.branch_take = 1'b0;
		if(BTB_hit)
			br_check_fetch.branch_take = (br_check_fetch.CPT_predict[1]) ? br_check_fetch.GBP_predict[1] : br_check_fetch.LBP_predict[1];
	end
`elsif	GSHARE_BP
	always_comb begin
		br_check_fetch.branch_take = 1'b0;
		if(BTB_hit)
			br_check_fetch.branch_take = br_check_fetch.GBP_predict[1];
	end		
`elsif	LOCAL_BP
	always_comb begin
		br_check_fetch.branch_take = 1'b0;
		if(BTB_hit)	
			br_check_fetch.branch_take = br_check_fetch.LBP_predict[1];
	end
`endif	
	
//	Next PC Logic	
	always_comb begin
		pc_sel = 1'b1;
		if(BTB_hit && br_check_fetch.branch_take)
			pc_sel = 1'b0;
	end
	
//	assign	pc_fix = (rst_n) ? (br_update_ex.wrong ? 1'b1 : 1'b0) : 1'b0;
	always_comb begin
		pc_fix = 1'b0;
		if(br_update_ex.wrong)
			pc_fix = 1'b1;
	end

//================================================================================	
	`ifdef SIMULATE
		`ifdef	GBP_GEN
		initial begin
			for(int i = 0; i < 2**GSHARE_GPT_INDEX; i++)
				GPT[i] = '0;
		end
		`endif
		
		`ifdef 	LBP_GEN
		initial begin
			for(int i = 0; i < 2**LOCAL_LHT_INDEX; i++)		
				LHT[i] = '0;
				
			for(int i = 0; i < 2**LOCAL_LPT_INDEX; i++)		
				LPT[i] = '0;				
		end
		`endif
		
		`ifdef	HYBRID_BP
		initial begin
			for(int i = 0; i < 2**GSHARE_GPT_INDEX; i++)		
				CPT[i] = '0;
		end
		`endif
		
		initial begin
			for(int i = 0; i < 2**BTB_INDEX; i++)		
				BTB[i] = '0;
		end
		
		initial begin
			$readmemh("SRAM.txt", GPT);	
			$readmemh("SRAM.txt", LHT);			
			$readmemh("SRAM.txt", LPT);		
			$readmemh("SRAM.txt", CPT);	
			$readmemh("SRAM.txt", BTB);			
		end
	`endif

endmodule


