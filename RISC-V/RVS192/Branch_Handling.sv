//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Branch_Handling.sv
// Module Name:		Branch Handling for RVS192 cpu	
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
// Copyright (C) 	Le Quang Hung 
// Email: 			quanghungbk1999@gmail.com  
//////////////////////////////////////////////////////////////////////////////////


//`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module Branch_Handling
(
	output 	br_update_type		br_update_ex,
	output 	[PC_LENGTH-1:0]		branch_cal_out,
								actual_pc,
	input 	br_check_type 		br_check_ex,
	input 						ge,
								eq,
//								swap_j,
								branch_capture,
								non_condition,
	input 	branch_kind_type	branch_kind,							
	input	[DATA_LENGTH-1:0]	imm_ex,
								add_result,
	input 	[PC_LENGTH-1:0]		pc_ex
);

//================================================================================	
//	Internal Signals
	logic 	condition_check;

	logic 	[1:0]	CPT_check;

	logic 	[PC_LENGTH-1:0]		operand_2;

//================================================================================	
//	Check br_check_ex.branch_take
	`ifdef	LOCAL_BP
//		assign	br_check_ex.branch_take = br_check_ex.LBP_predict[1];	
//		assign 	br_update_ex.LBHR_update = {br_check_ex.LBHR[LOCAL_HISTORY_LENGTH-1:1], br_update_ex.actual};
		assign 	br_update_ex.LBHR_old = br_check_ex.LBHR;
		
		always_comb begin
			br_update_ex.LBP_predict_update = br_check_ex.LBP_predict;
			if(branch_capture)
			begin
				if(non_condition) 	
					br_update_ex.LBP_predict_update = 2'b11;
				else begin					
					if((br_check_ex.LBP_predict != 2'b11) && br_update_ex.actual)
						br_update_ex.LBP_predict_update = br_check_ex.LBP_predict + 2'b01;			
					else if((br_check_ex.LBP_predict != 2'b00) && !br_update_ex.actual)				
						br_update_ex.LBP_predict_update = br_check_ex.LBP_predict - 2'b01;
				end		
			end
		end
	`elsif	GSHARE_BP
//		assign 	br_check_ex.branch_take = br_check_ex.GBP_predict[1];
//		assign 	br_update_ex.GBHR_update = {br_check_ex.GBHR[GSHARE_HISTORY_LENGTH-1:1], br_update_ex.actual};
		assign 	br_update_ex.GBHR_old = br_check_ex.GBHR;
		
		always_comb begin
			br_update_ex.GBP_predict_update = br_check_ex.GBP_predict;
			if(branch_capture)
			begin
				if(non_condition)	// Uncondition
					br_update_ex.GBP_predict_update = 2'b11;		
				else 
				begin       		// non_condition
					if((br_check_ex.GBP_predict != 2'b11) && br_update_ex.actual)
						br_update_ex.GBP_predict_update = br_check_ex.GBP_predict + 2'b01;			
					else if((br_check_ex.GBP_predict != 2'b00) && !br_update_ex.actual)				
						br_update_ex.GBP_predict_update = br_check_ex.GBP_predict - 2'b01;
				end
			end
		end	
	`elsif	HYBRID_BP
//		assign 	br_check_ex.branch_take = br_check_ex.CPT_predict[1] ?	br_check_ex.GBP_predict[1] : br_check_ex.LBP_predict[1];
//		assign 	br_update_ex.LBHR_update = {br_check_ex.LBHR[LOCAL_HISTORY_LENGTH-1:1], br_update_ex.actual};
//		assign 	br_update_ex.GBHR_update = {br_check_ex.GBHR[GSHARE_HISTORY_LENGTH-1:1], br_update_ex.actual};	
		assign 	br_update_ex.LBHR_old = br_check_ex.LBHR;	
		assign 	br_update_ex.GBHR_old = br_check_ex.GBHR;
		
		always_comb begin
			br_update_ex.LBP_predict_update = br_check_ex.LBP_predict;
			if(branch_capture)
			begin
				if(non_condition) 	
					br_update_ex.LBP_predict_update = 2'b11;
				else begin				// non_condition	
					if((br_check_ex.LBP_predict != 2'b11) && br_update_ex.actual)
						br_update_ex.LBP_predict_update = br_check_ex.LBP_predict + 2'b01;			
					else if((br_check_ex.LBP_predict != 2'b00) && !br_update_ex.actual)				
						br_update_ex.LBP_predict_update = br_check_ex.LBP_predict - 2'b01;
				end		
			end
		end

		always_comb begin
			br_update_ex.GBP_predict_update = br_check_ex.GBP_predict;
			if(branch_capture)
			begin
				if(non_condition)	// Uncondition
					br_update_ex.GBP_predict_update = 2'b11;		
				else 
				begin       		// non_condition
					if((br_check_ex.GBP_predict != 2'b11) && br_update_ex.actual)
						br_update_ex.GBP_predict_update = br_check_ex.GBP_predict + 2'b01;			
					else if((br_check_ex.GBP_predict != 2'b00) && !br_update_ex.actual)				
						br_update_ex.GBP_predict_update = br_check_ex.GBP_predict - 2'b01;
				end
			end
		end		

		always_comb begin
			br_update_ex.CPT_predict_update = br_check_ex.CPT_predict;	
			begin
				if((br_check_ex.CPT_predict != 2'b00)&&(CPT_check == 2'b01))	
					br_update_ex.CPT_predict_update = br_check_ex.CPT_predict - 2'b01;
				else if((br_check_ex.CPT_predict != 2'b11)&&(CPT_check == 2'b10))
					br_update_ex.CPT_predict_update = br_check_ex.CPT_predict + 2'b01;
			end
		end		
	`endif
	

//	Check actual decision
	always_comb begin	
		condition_check = 1'b0;
		if(branch_capture && !non_condition)
		begin
			unique case(branch_kind)
			EQUAL:		condition_check = eq;			
			N_EQUAL:	condition_check = !eq;
			LT:			condition_check = !ge;
			GE:			condition_check = ge;
			endcase  
		end	
	end
	
	assign 	CPT_check = br_check_ex.CPT_predict ~^ {br_update_ex.actual, br_update_ex.actual};

//	Actual PC Calculation
	assign 	operand_2 = ((br_update_ex.actual)&& ~non_condition) ?	imm_ex : 32'h4;
	assign 	branch_cal_out = pc_ex + operand_2;
	assign 	actual_pc = non_condition ? add_result : branch_cal_out; 

//	Check prediction
	always_comb begin
		br_update_ex.wrong = 1'b0;
		if(((non_condition || condition_check) ^ br_check_ex.branch_take) && branch_capture)
				br_update_ex.wrong = 1'b1;
	end
	
	assign 	br_update_ex.update = branch_capture;
	assign 	br_update_ex.actual = non_condition || condition_check;
	
endmodule