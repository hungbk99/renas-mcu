//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Decoder.sv
// Module Name:		Decoder for Control Signal and Immidiate Value		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

//`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	Decoder
(
	output	control_type_ex			control_dec,
	output 	[4:0]					rs1,
									rs2,
									rd,
	input	[INST_LENGTH-1:0]		inst_raw
);

	i_extract_type					inst_union;
	assign 	inst_union = inst_raw;
	
	always_comb begin
		control_dec.alu_op = ADD;
		control_dec.jal = 1'b0;
		control_dec.jalr = 1'b0;
		control_dec.alu_in1_sel = 1'b0;
		control_dec.alu_in2_sel = 1'b0;
//		control_dec.swap_j = 1'b0;
		control_dec.branch_capture = 1'b0;
//		control_dec.condition = 1'b0;
		control_dec.branch_kind = EQUAL;
		control_dec.imm_dec = 1'b0;
		control_dec.control_mem.cpu_read = 1'b0;
		control_dec.control_mem.cpu_write = 1'b0;
		control_dec.control_mem.mem_gen = W;
		control_dec.control_mem.control_wb.wb_sel = 1'b0;
		control_dec.control_mem.control_wb.reg_wen = 1'b0;
		unique case (inst_union.op5)
		LUI_TYPE:
		begin	
			control_dec.alu_op = LUI;
			control_dec.alu_in2_sel = 1'b1;
			control_dec.control_mem.control_wb.wb_sel = 1'b1;
			control_dec.control_mem.control_wb.reg_wen = 1'b1;
		end
		AUIPC_TYPE:
		begin
			control_dec.alu_op = ADD;
			control_dec.alu_in1_sel = 1'b1;
			control_dec.alu_in2_sel = 1'b1;
			control_dec.control_mem.control_wb.wb_sel = 1'b1;
			control_dec.control_mem.control_wb.reg_wen = 1'b1;		
		end
		JAL_TYPE:
		begin
			control_dec.alu_op = ADD;
			control_dec.jal = 1'b1;
			control_dec.branch_capture = 1'b1;
			control_dec.alu_in1_sel = 1'b1;
			control_dec.alu_in2_sel = 1'b1;
//			control_dec.swap_j = 1'b1;
			control_dec.control_mem.control_wb.wb_sel = 1'b1;
			control_dec.control_mem.control_wb.reg_wen = 1'b1;			
		end
		JALR_TYPE:
		begin
			control_dec.alu_op = ADD;
			control_dec.jalr = 1'b1;
			control_dec.branch_capture = 1'b1;			
			control_dec.alu_in2_sel = 1'b1;
//			control_dec.swap_j = 1'b1;
			control_dec.control_mem.control_wb.wb_sel = 1'b1;
			control_dec.control_mem.control_wb.reg_wen = 1'b1;	
		end
		B_TYPE:
		begin
			control_dec.branch_capture = 1'b1;
//			control_dec.condition = 1'b1;
			control_dec.alu_op = SC;
			unique case(inst_union.op3)
			3'b000:	control_dec.branch_kind = EQUAL;
			3'b001:	control_dec.branch_kind = N_EQUAL;
			3'b100:	control_dec.branch_kind = LT;
			3'b101:	control_dec.branch_kind = GE;
			3'b110:	
			begin
				control_dec.branch_kind = EQUAL;
				control_dec.alu_op = USC;
			end	
			3'b111:
			begin
				control_dec.branch_kind = EQUAL;
				control_dec.alu_op = USC;
			end
			endcase
		end
		L_TYPE:
		begin
			control_dec.control_mem.cpu_read = 1'b1;
			control_dec.alu_in2_sel = 1'b1;
			control_dec.control_mem.control_wb.reg_wen = 1'b1;
			unique case(inst_union.op3)
			3'b000:	control_dec.control_mem.mem_gen = B;
			3'b001:	control_dec.control_mem.mem_gen = H;
			3'b010:	control_dec.control_mem.mem_gen = W;
			3'b100:	control_dec.control_mem.mem_gen = BU;
			3'b101:	control_dec.control_mem.mem_gen = HU;
			endcase
		end
		S_TYPE:
		begin
			control_dec.control_mem.cpu_write = 1'b1;
			control_dec.alu_in2_sel = 1'b1;		
			unique case(inst_union.op3)
			3'b000:	control_dec.control_mem.mem_gen = B;
			3'b001:	control_dec.control_mem.mem_gen = H;
			3'b010:	control_dec.control_mem.mem_gen = W;		
			endcase
		end
		I_TYPE:
		begin
			control_dec.alu_in2_sel = 1'b1;
			control_dec.control_mem.control_wb.wb_sel = 1'b1;
			control_dec.control_mem.control_wb.reg_wen = 1'b1;
			unique case(inst_union.op3)			
			3'b000:	control_dec.alu_op = ADD;
			3'b010:	control_dec.alu_op = SC;
			3'b011:	control_dec.alu_op = USC;
			3'b100:	control_dec.alu_op = XOR;
			3'b110:	control_dec.alu_op = OR;
			3'b111:	control_dec.alu_op = AND;
			3'b001: control_dec.alu_op = SLL;
			3'b101:
			begin
				if({inst_union.imm_op, inst_union.s2_reg}== 7'b000_0000)
					control_dec.alu_op = SRL;
				else if({inst_union.imm_op, inst_union.s2_reg} == 7'b010_0000)
					control_dec.alu_op = SRA;
			end
			endcase
		end
		R_TYPE:
		begin
			control_dec.control_mem.control_wb.wb_sel = 1'b1;
			control_dec.control_mem.control_wb.reg_wen = 1'b1;
			unique case(inst_union.op3)
			3'b000:	
			begin
				if({inst_union.imm_op, inst_union.s2_reg} == 7'b010_0000)
					control_dec.alu_op = SUB;
			end
			3'b010:	control_dec.alu_op = SC;
			3'b011:	control_dec.alu_op = USC;
			3'b100:	control_dec.alu_op = XOR;
			3'b110:	control_dec.alu_op = OR;
			3'b111:	control_dec.alu_op = AND;
			3'b001: control_dec.alu_op = SLL;
			3'b101:
			begin
				if({inst_union.imm_op, inst_union.s2_reg}== 7'b000_0000)
					control_dec.alu_op = SRL;
				else if({inst_union.imm_op, inst_union.s2_reg} == 7'b010_0000)
					control_dec.alu_op = SRA;
			end			
			endcase
		end
		endcase
		
		unique casez (inst_union.op5)
		I_TYPE, L_TYPE, JALR_TYPE: control_dec.imm_dec = {{20{inst_union[31]}}, inst_union[31:20]};
		S_TYPE:	control_dec.imm_dec = {{20{inst_union[31]}}, inst_union[31:25], inst_union[11:7]};
		B_TYPE: control_dec.imm_dec = {{20{inst_union[31]}}, inst_union[7], inst_union[30:25], inst_union[11:8], 1'b0};
		LUI_TYPE, AUIPC_TYPE: control_dec.imm_dec = {inst_union[31:12], 12'b0};
		JAL_TYPE: control_dec.imm_dec = {{12{inst_union[31]}}, inst_union[19:12], inst_union[20], inst_union[30:21] ,1'b0};
		default: control_dec.imm_dec = 'x;
		endcase
		
	end

	assign 	rs1 = inst_union.s1_reg;
	assign 	rs2 = inst_union.s2_reg;
	assign 	rd = inst_union.des_reg;

endmodule
/*
module Decoder
	import RVS192_package::*;
	(output control_type_ex control_dec,
	output 	logic [DATA_LENGTH-1:0] imm_dec,
	input	logic [INST_LENGTH-1:0] inst_union.,
	input 	logic	rst_n);
	
//================================================================================		
	localparam ADD = 9'b0_000_01100;
	localparam SUB = 9'b1_000_01100;
	localparam SLL = 9'b0_001_01100;
	localparam SLT = 9'b0_010_01100;
	localparam SLTU = 9'b0_011_01100;
	localparam XOR = 9'b0_100_01100;
	localparam SRL = 9'b0_101_01100;
	localparam SRA = 9'b1_101_01100;
	localparam OR = 9'b0_110_01100;
	localparam AND = 9'b0_111_01100;
					
	localparam ADDI = 9'b?_000_00100;
	localparam SLTI = 9'b?_010_00100;
	localparam SLTIU = 9'b?_011_00100;
	localparam XORI = 9'b?_100_00100;	
	localparam ORI = 9'b?_110_00100;
	localparam ANDI = 9'b?_111_00100;
	localparam SLLI = 9'b0_001_00100;
	localparam SRLI = 9'b0_101_00100;
	localparam SRAI = 9'b1_101_00100;
					
	localparam LB = 9'b?_000_00000;		//	=> nop
	localparam LH = 9'b?_010_00000;
	localparam LW = 9'b?_011_00000;
	localparam LBU = 9'b?_100_00000;
	localparam LHU = 9'b?_110_00000;
					
	localparam SB = 9'b?_000_01000;
	localparam SH = 9'b?_001_01000;
	localparam SW = 9'b?_010_01000;
					
	localparam BEQ	= 9'b?_000_11000;
	localparam BNE	= 9'b?_001_11000;
	localparam BLT	= 9'b?_100_11000;
//	Sua lai theo RARS	
	localparam BGE = 9'b?_110_11000;
	localparam BLTU = 9'b?_101_11000;
	localparam BGEU = 9'b?_111_11000;

	localparam LUI = 9'b?_???_01101;
	localparam AUIPC = 9'b?_???_00101;
					
	localparam JAL = 9'b?_???_11011;
	localparam JALR = 9'b?_000_11001;	
	
	localparam I_TYPE = 7'b0010011;
	localparam L_TYPE = 7'b0000011;
	localparam S_TYPE = 7'b0100011;
	localparam B_TYPE = 7'b1100011;
	localparam U_TYPE = 7'b0110111;
	localparam JAL_TYPE = 7'b1101111;
	localparam JALR_TYPE = 7'b1100111;
	
/*	enum logic [CONTROL_ADDR_LENGTH-1:0] {
	ADD	= 9'b0_000_01100,
	SUB = 9'b1_000_01100,
	SLL = 9'b0_001_01100,
	SLT = 9'b0_010_01100,
	SLTU = 9'b0_011_01100,
	XOR = 9'b0_100_01100,
	SRL = 9'b0_101_01100,
	SRA = 9'b1_101_01100,
	OR = 9'b0_110_01100,
	AND = 9'b0_111_01100,
					
	ADDI = 9'b?_000_00100,
	SLTI = 9'b?_010_00100,
	SLTIU = 9'b?_011_00100,
	XORI = 9'b?_100_00100,	
	ORI = 9'b?_110_00100,
	ANDI = 9'b?_111_00100,
	SLLI = 9'b0_001_00100,
	SRLI = 9'b0_101_00100,
	SRAI = 9'b1_101_00100,
					
	LB = 9'b?_000_00000,		//	=> nop
	LH = 9'b?_010_00000,
	LW = 9'b?_011_00000,
	LBU = 9'b?_100_00000,
	LHU = 9'b?_110_00000,
					
	SB = 9'b?_000_01000,
	SH = 9'b?_001_01000,
	SW = 9'b?_010_01000,
					
	BEQ	= 9'b?_000_11000,
	BNE	= 9'b?_001_11000,
	BLT	= 9'b?_100_11000,
//	Sua lai theo RARS	
	BGE = 9'b?_110_11000,
	BLTU = 9'b?_101_11000,
	BGEU = 9'b?_111_11000,

	LUI = 9'b?_???_01101,
	AUIPC = 9'b?_???_00101,
					
	JAL = 9'b?_???_11011,
	JALR = 9'b?_000_11001}	addr;
	
	enum logic [6:0]	{
	I_TYPE = 7'b0010011,
	L_TYPE = 7'b0000011,
	S_TYPE = 7'b0100011,
	B_TYPE = 7'b1100011,
	U_TYPE = 7'b0110111,
	JAL_TYPE = 7'b1101111,
	JALR_TYPE = 7'b1100111}	inst_type;
	

//================================================================================	
//	Internal Signals
	logic [CONTROL_ADDR_LENGTH-1:0] addr;
	logic [6:0]	inst_type;

//================================================================================	
//	control_dec Gen
	assign 	addr = {inst_union[30], inst_union[14:12], inst_union[6:2]};

	always_comb begin
		if(!rst_n)
			control_dec = '{4'b0000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b0, 1'b0}}};
		else
		begin
			unique casez (addr) 
				//	alu_op	alu_in1_sel alu_in2_sel	swap_j branch_capture	condition	branch_kind	mem_wen	mem_gen	wb_sel	reg_wen
				//R_TYPE
  				ADD:	control_dec = '{4'b0000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SUB:	control_dec = '{4'b0001, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SLL:	control_dec = '{4'b0100, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SLT:	control_dec = '{4'b1100, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SLTU:	control_dec = '{4'b1101, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				XOR:	control_dec = '{4'b1010, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SRL:	control_dec = '{4'b0101, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SRA:	control_dec = '{4'b0110, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				OR:		control_dec = '{4'b1000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				AND:	control_dec = '{4'b1001, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				//I_TYPE									
				ADDI:	control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SLTI:	control_dec = '{4'b1100, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SLTIU:	control_dec = '{4'b1101, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				XORI:	control_dec = '{4'b1010, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				ORI:	control_dec = '{4'b1000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				ANDI:	control_dec = '{4'b1001, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SLLI:	control_dec = '{4'b0100, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SRLI:	control_dec = '{4'b0101, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				SRAI:	control_dec = '{4'b0110, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b0, '{1'b1, 1'b1}}};
				//I(LOAD control_dec)								
				LB:		control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b000, '{1'b0, 1'b1}}};
				LH:		control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b001, '{1'b0, 1'b1}}};
				LW:		control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b010, '{1'b0, 1'b1}}};
				LBU:	control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b011, '{1'b0, 1'b1}}};
				LHU:	control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b100, '{1'b0, 1'b1}}};
				//S_TYPE									
				SB:		control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b1, 3'b000, '{1'b0, 1'b0}}};
				SH:		control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b1, 3'b001, '{1'b0, 1'b0}}};
				SW:		control_dec = '{4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b1, 3'b010, '{1'b0, 1'b0}}};
				
				//B_TYPE										
				
				BEQ:	control_dec = '{4'b1100, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b00, '{1'b0, 3'b000, '{1'b0, 1'b0}}};
				BNE:	control_dec = '{4'b1100, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b01, '{1'b0, 3'b000, '{1'b0, 1'b0}}};
				BLT:	control_dec = '{4'b1100, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b10, '{1'b0, 3'b000, '{1'b0, 1'b0}}};
				BGE:	control_dec = '{4'b1100, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b11, '{1'b0, 3'b000, '{1'b0, 1'b0}}};
				BLTU:	control_dec = '{4'b1101, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b10, '{1'b0, 3'b000, '{1'b0, 1'b0}}};
				BGEU:	control_dec = '{4'b1101, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b11, '{1'b0, 3'b000, '{1'b0, 1'b0}}};
				//U_TYPE						
				LUI:	control_dec = '{4'b0010, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b000, '{1'b1, 1'b1}}};
				AUIPC:	control_dec = '{4'b0000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b000, '{1'b1, 1'b1}}};
				//J_TYPE							
				JAL:	control_dec = '{4'b0000, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b000, '{1'b1, 1'b1}}};
				JALR:	control_dec = '{4'b0000, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b0, '{1'b0, 3'b000, '{1'b1, 1'b1}}};	//I-TYPE	
				default:	control_dec = '{4'bx, 1'bx, 1'bx, 1'bx, 1'bx, 1'bx, 2'bx, '{1'bx, 3'bx, '{1'bx, 1'bx}}};
			endcase
		end
	end
	
	assign	inst_type = inst_union[6:0];
	
	always_comb begin
		unique casez (inst_type)
		I_TYPE, L_TYPE, JALR_TYPE: imm_dec = {{20{inst_union[31]}}, inst_union[31:20]};
		S_TYPE:	imm_dec = {{20{inst_union[31]}}, inst_union[31:25], inst_union[11:7]};
		B_TYPE: imm_dec = {{20{inst_union[31]}}, inst_union[7], inst_union[30:25], inst_union[11:8], 1'b0};
		U_TYPE: imm_dec = {inst_union[31:12], 12'b0};
		JAL_TYPE: imm_dec = {{12{inst_union[31]}}, inst_union[19:12], inst_union[20], inst_union[30:21] ,1'b0};
		default: imm_dec = 'x;
		endcase
	end
	
endmodule
*/
