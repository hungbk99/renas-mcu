//////////////////////////////////////////////////////////////////////////////////
// File Name: 		RVS192_package.sv
// Module Name:		RVS192 Package		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Ver    Date        Author    Description
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// v0.0   05.18.2021  hungbk99  Mod: Solve bug: sw after a register type instruction
//                                   ex: addi x0, x0, 0x10 -> sw x0, 0x00(zero)
// v0.1   07.09.2021  hungbk99  Add pc in pp_ex_mem_type to support ISR
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//////////////////////////////////////////////////////////////////////////////////

//`include"RVS192_user_define.h"
package	RVS192_package;
	import RVS192_user_parameters::*;
//	export RVS192_user_define_package::*;
	
	parameter 	PC_LENGTH = 32;
	parameter 	INST_LENGTH = 32;	
	parameter	DATA_LENGTH = 32;
	parameter 	CONTROL_LENGTH = 21;
	parameter 	CONTROL_ADDR_LENGTH = 9;
	parameter 	BYTE_OFFSET = 2;
	parameter	WORD_OFFSET = $clog2(CACHE_BLOCK_SIZE/4);
	parameter	MEM_LINE = 2**17;		
	parameter 	REGISTER_FILE_DEPTH = 32;

//	Controller data type
	
	typedef	enum logic [3:0]	{
	//	ADD_SUB UNIT
		ADD = 4'b0000,
		SUB = 4'b0001,
		LUI = 4'b0010,
	//	SHIFT UNIT	
		SLL = 4'b0100,
		SRL = 4'b0101,
		SRA = 4'b0110,
	//	LOGICAL UNIT
		OR = 4'b1000,
		AND = 4'b1001,
		XOR = 4'b1010,
	//	COMPARE UNIT
		USC = 4'b1100,
		SC = 4'b1101	
	}	alu_op_type;
	
	typedef enum logic [1:0]	{
		EQUAL = 2'b00,
		N_EQUAL = 2'b01,
		LT = 2'b10,
		GE = 2'b11
	}	branch_kind_type;
	
	typedef enum logic [2:0]	{
		B = 3'b000,
		H = 3'b001,
		W = 3'b010,
		BU = 3'b011,
		HU = 3'b100
	}	mem_type;

	typedef enum logic [4:0]	{
		LUI_TYPE = 5'b01101,
		AUIPC_TYPE = 5'b00101,
		JAL_TYPE = 5'b11011,
		JALR_TYPE = 5'b11001,
		B_TYPE = 5'b11000,
		L_TYPE = 5'b00000,
		S_TYPE = 5'b01000,
		I_TYPE = 5'b00100,
		R_TYPE = 5'b01100
	}	op_type;

	typedef struct packed	{
		logic 	[6:0]		imm_op;
		logic 	[4:0]		s2_reg;		
		logic 	[4:0]		s1_reg;
		logic 	[2:0]		op3;
		logic 	[4:0]		des_reg;
		op_type				op5;
		logic 	[1:0]		redundant;
	}	i_extract_type;
		
/*	Quartus doesn't support unions		
	typedef union packed	{
		logic	[INST_LENGTH-1:0]	inst_raw_union;
		struct packed	{
		logic 	[6:0]		imm_op;
		logic 	[4:0]		s2_reg;		
		logic 	[4:0]		s1_reg;
		logic 	[2:0]		op3;
		logic 	[4:0]		des_reg;
		op_type				op5;
		logic 	[1:0]		redundant;
		}	i_extract_union;
	}	inst_type;
*/

//	Pipelined Control Type	
	typedef struct packed	{
		logic										wb_sel;
		logic										reg_wen;
	}	control_type_wb;
	
	typedef struct packed	{
		logic 										cpu_write;
		logic 										cpu_read;	
//		logic 										mem_ren;
//		logic										mem_wen;
		mem_type									mem_gen;
		control_type_wb								control_wb;
	}	control_type_mem;
	
	typedef struct packed	{
		alu_op_type									alu_op;
		logic 										jal;
		logic 										jalr;
		logic 										alu_in1_sel;
		logic 										alu_in2_sel;
//		logic 										swap_j;
		logic 										branch_capture;
//		logic 										condition;
		branch_kind_type							branch_kind;
		logic 	[DATA_LENGTH-1:0]					imm_dec;
		control_type_mem							control_mem;
	}	control_type_ex;
	
	`ifdef	HYBRID_BP
		typedef struct packed	{
			logic	[1:0]								GBP_predict;
			logic 	[1:0] 								LBP_predict;
			logic	[1:0]								CPT_predict;
			logic 	[GSHARE_HISTORY_LENGTH-1:0]			GBHR;
			logic 	[LOCAL_HISTORY_LENGTH-1:0]			LBHR;
			logic 										branch_take;
		}	br_check_type;
		
		typedef struct packed	{
			logic	[1:0]								GBP_predict_update;
			logic 	[1:0] 								LBP_predict_update;
			logic 	[1:0]								CPT_predict_update;
			logic 	[GSHARE_HISTORY_LENGTH-1:0]			GBHR_old;
			logic 	[LOCAL_HISTORY_LENGTH-1:0]			LBHR_old;	
//			logic 	[PC_LENGTH-1:0] 					actual_pc;		
			logic 										update;
			logic 										wrong;
			logic 										actual;			
		}	br_update_type;
	`elsif	LOCAL_BP
		typedef struct packed	{	
			logic 	[1:0] 								LBP_predict;	
			logic 	[LOCAL_HISTORY_LENGTH-1:0]			LBHR;	
			logic 										branch_take;			
		}	br_check_type;	

		typedef struct packed	{
			logic 	[1:0] 								LBP_predict_update;	
			logic 	[LOCAL_HISTORY_LENGTH-1:0]			LBHR_old;
//			logic 	[PC_LENGTH-1:0] 					actual_pc;
			logic 										update;	
			logic 										wrong;
			logic 										actual;		
		}	br_update_type;	
	`elsif	GSHARE_BP
		typedef struct packed	{		
			logic	[1:0]								GBP_predict;
			logic 	[GSHARE_HISTORY_LENGTH-1:0]			GBHR;		
			logic 										branch_take;			
		}	br_check_type;
		
		typedef struct packed	{	
			logic	[1:0]								GBP_predict_update;
			logic 	[GSHARE_HISTORY_LENGTH-1:0]			GBHR_old;	
//			logic 	[PC_LENGTH-1:0] 					actual_pc;		
			logic 										update;
			logic 										wrong;
			logic 										actual;		
		}	br_update_type;	
	`endif	
	
	typedef	struct packed	{
		logic 										update;
		logic 	[INST_LENGTH-1:0]					w1_update;
		logic 	[INST_LENGTH-1:0]					w2_update;
		logic	[ $clog2(CACHE_BLOCK_SIZE/4)-2:0]	addr_update;
	}	cache_update_type;
	
	typedef struct packed	{
		logic	[PC_LENGTH-1:0]		pc;
		br_check_type 				br_check;
		logic 	[INST_LENGTH-1:0]	inst;
	}	pp_fetch_dec_type;
	
	typedef struct packed	{
		logic	[PC_LENGTH-1:0]		pc;
		br_check_type 				br_check;	
		logic 	[4:0]				rs1;
		logic 	[4:0]				rs2;	
		logic 	[4:0]				rd;
		logic 	[DATA_LENGTH-1:0]	rs1_out;
		logic 	[DATA_LENGTH-1:0]	rs2_out;
		control_type_ex				control_signals;		
	}	pp_dec_ex_type;
	
	typedef	struct packed	{
    //Hung_mod_05.17.2021
    logic [4:0]       rs1;
    //Hung_mod_05.17.2021
		logic	[4:0]				rd;
//		logic 	[PC_LENGTH-1:0]		actual_pc;
		logic 	[DATA_LENGTH-1:0]	alu_out;
		logic 	[DATA_LENGTH-1:0]	rs2_out_fix;
		control_type_mem			control_signals;
		//v[0.1]
    logic	[PC_LENGTH-1:0]		pc;
	}	pp_ex_mem_type;
	
	typedef struct packed	{
		logic 	[4:0]				rd;
		logic 	[DATA_LENGTH-1:0]	alu_out;
		logic 	[DATA_LENGTH-1:0]	mem_out;
		control_type_wb				control_signals;
	}	pp_mem_wb_type;
	
endpackage
