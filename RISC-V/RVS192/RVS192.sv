//////////////////////////////////////////////////////////////////////////////////
// File Name: 		RVS192.sv
// Module Name:		Top Module for RVS192 cpu
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
// Copyright (C) 	Le Quang Hung 
// Email: 			quanghungbk1999@gmail.com  
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// File Name: 		renas_cpu.sv
// Function:		Top Module for renas cpu
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.1   25.04.2021  hungbk99  Mod: AHP Interface  
//                                   Read Mem                     -> AHB-INST Interface
//                                   Merge: Read Mem || Write Mem -> AHB-DATA Interface
//        06.05.2021  hungbk99  Mod: Add support for peri slave
//////////////////////////////////////////////////////////////////////////////////
`ifndef TEST
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/AHB_package.sv"
  `include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_define.h"
  `include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_parameters.sv"
  `include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_package.sv"
`endif
import 	AHB_package::*;
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module 	RVS192
(
	//Hung_add_25.04.2021
  	//I-AHB-ITF
  	output  mas_send_type                           iahb_out,
  	input   slv_send_type                           iahb_in,
  	//Interrupt Handler
  	output logic                                    inst_dec_err,
  	//D-AHB-ITF
  	output  mas_send_type                           dahb_out,
  	input   slv_send_type                           dahb_in,
  	//Interrupt Handler
  	output logic                                    data_dec_err,
  	//PERI-ITF
    output  mas_send_type                           peri_out,
    input   slv_send_type                           peri_in,
  	//Interrupt Handler
    output logic                                    peri_dec_err,
	//Hung_add_25.04.2021

	input 											external_halt,
			    									clk,
			    									clk_l1,
			    									clk_l2,
			    									clk_mem,
			    									rst_n
);

//====================================================================
//						    Pipelined RVS192
//====================================================================		
	logic 	[PC_LENGTH-1:0]			pc_in,
									            pc_fetch,
									            target_predict,
									            target_pc,
									            pc_in_fix,
									            actual_pc;

	logic							          pc_sel,
									            pc_fix,
									            pc_halt,
//									          ICC_halt,
//									          DCC_halt,
									            FW_halt;

	control_type_ex		    			raw_control_signals;

	br_update_type				    	br_update_ex;
									
	logic	[DATA_LENGTH-1:0]		  data_wb;

	logic 	[INST_LENGTH-1:0]		inst;

	logic	[DATA_LENGTH-1:0]		  add_result;
									
	logic							          ge,
									            eq;
									
	logic 	[DATA_LENGTH-1:0]		branch_cal_out,
									            alu_in1,
									            alu_in2,
//								          	rs2_out_fix,
									            data_r,
									            data_in;
		
	logic 	[1:0]					      fw_sel_1,
									            fw_sel_2,
									            mem_fix;
	
	pp_fetch_dec_type				    i_pp_fetch_dec,
									            o_pp_fetch_dec;
									
	pp_dec_ex_type					    i_pp_dec_ex,
									            o_pp_dec_ex;
									
	pp_ex_mem_type					    i_pp_ex_mem,
									            o_pp_ex_mem;
		
	pp_mem_wb_type					    i_pp_mem_wb,
									            o_pp_mem_wb;
	
	logic 							        fetch_dec_halt,
									            dec_ex_halt,
									            dec_ex_flush,
									            ex_mem_halt,
									            ex_mem_flush,
									            wrong_dl,
									            wrong_dl_1;
//================================CACHE===============================
//====================================================================
	parameter	L2_TAG_LENGTH = DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-$clog2(L2_CACHE_LINE);

  //Hung_mod_peri
  logic                                             peri_halt;
  logic                                             peri_halt_raw;
  //Hung_mod_peri
//	CPU
	logic												                      ICC_halt;
	logic												                      DCC_halt;
//	Replace handshake	
	logic												                      inst_replace_req,
										  				                      data_replace_req;	
	logic 	[DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-1:0]	dl1_dirty_addr;													
//	Write Buffer
	logic												                      L2_full_flag;
//	System	

//	Il1 Cache
	cache_update_type									                IL2_out;
	logic 												                    inst_update_req;
	logic 	[PC_LENGTH-1:0]								            pc_up;
	logic 										                        inst_replace_il1_ack,
													                          data_replace_il1_ack;			
	logic											                        L2_inst_il1_ack,
														                        L2_inst_dl1_ack,
														                        L2_data_il1_ack,
														                        L2_data_dl1_ack;
//	DL1 Cache
	cache_update_type					                				DL2_out;
	logic 												                    data_update_req;
	logic 	[PC_LENGTH-1:0]								            alu_out_up;	
	logic	  [DATA_LENGTH-1:0]							            dirty_data1;
	logic	  [DATA_LENGTH-1:0]							            dirty_data2;
	logic 	[DATA_LENGTH-1:0]							            dirty_addr;				// DL1 chi gui tag va index do do phai them bit 0 truoc khi su dung
	logic 	 											                    dirty_req;
	logic												                      dirty_ack;
	logic 	 											                    dirty_replace;	
	logic 	[2*DATA_LENGTH-BYTE_OFFSET-1:0]				    wb_data;	
	logic		 										                      wb_req;
	logic 												                    wb_ack;	
	logic 												                    full_flag;
	logic 												                    inst_replace_dl1_ack,
														                        data_replace_dl1_ack;		
//	To both IL1 and DL1
	logic												                      inst_replace_check,
														                        data_replace_check;
	logic 	[L2_TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:0]	inst_addr_replace,
														                        data_addr_replace;																
//	Mem
//	System
	
	logic 	[INST_LENGTH-1:0]							            inst_mem_read;
	logic 	[DATA_LENGTH-1:0]							            data_mem_read;
	logic												                      inst_res,		//	Use for synchoronous
														                        data_res;
	logic 	[DATA_LENGTH-1:0]				 			            data_mem_write,
													             	            data_addr;
	logic 	[PC_LENGTH-1:0]								            inst_addr;
	logic 												                    inst_read_req,
														                        data_read_req,
														                        data_write_req;
														
//====================================================================
//===========================Halt Control=============================
	//Hung_mod_peri assign 	pc_halt = DCC_halt || ICC_halt || FW_halt || external_halt;
	//Hung_mod_peri assign 	fetch_dec_halt = pc_halt;
	//Hung_mod_peri assign 	dec_ex_halt = FW_halt || DCC_halt || external_halt;
	//Hung_mod_peri assign 	dec_ex_flush = ICC_halt;
	//Hung_mod_peri assign 	ex_mem_halt =  DCC_halt || external_halt;
	//Hung_mod_peri assign 	ex_mem_flush = FW_halt;
	assign 	pc_halt = (DCC_halt || peri_halt) || ICC_halt || FW_halt || external_halt;
	assign 	fetch_dec_halt = pc_halt;
	assign 	dec_ex_halt = FW_halt || (DCC_halt || peri_halt) || external_halt;
	assign 	dec_ex_flush = ICC_halt;
	assign 	ex_mem_halt =  (DCC_halt || peri_halt) || external_halt;
	assign 	ex_mem_flush = FW_halt;
	
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			wrong_dl <= 1'b0;
		else if(br_update_ex.wrong)
			wrong_dl <= 1'b1;
		else 
			wrong_dl <= 1'b0;
	end
	
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			wrong_dl_1 <= 1'b0;
		else 
			wrong_dl_1 <= wrong_dl;
	end
	
//=====================Pipelined Registers============================
//====================================================================
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
    begin
			//Hung_mod o_pp_fetch_dec <= '0;
      o_pp_fetch_dec.pc <= '0;
      o_pp_fetch_dec.br_check <= '0;
      o_pp_fetch_dec.inst <= 32'h00007033;

    end
		else if(fetch_dec_halt) 
			o_pp_fetch_dec <= o_pp_fetch_dec;
		else
			o_pp_fetch_dec <= i_pp_fetch_dec;
	end

	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			o_pp_dec_ex <= '0;
		else if(dec_ex_halt)
			o_pp_dec_ex <= o_pp_dec_ex;
		else if(dec_ex_flush)
			o_pp_dec_ex <= '0;					//	Only stop the fetch stage, flush the next inst to insure that the previous inst won't run again
		else
			o_pp_dec_ex <= i_pp_dec_ex;
	end
	
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			o_pp_ex_mem <= '0;
		else if(ex_mem_halt)
			o_pp_ex_mem <= o_pp_ex_mem;
		else if(ex_mem_flush)
			o_pp_ex_mem <= '0;
		else 
			o_pp_ex_mem <= i_pp_ex_mem;
	end

	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			o_pp_mem_wb <= '0;
		else
			o_pp_mem_wb <= i_pp_mem_wb;
	end

//============================Fetch Stage=============================
//====================================================================
	
	BPU	BPU_U
	(
	.br_check_fetch(i_pp_fetch_dec.br_check),
	.pc_ex(o_pp_dec_ex.pc),
	.pc_in(pc_fetch),
	.*
	);
	
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(rst_n == 1'b0)
		begin
			//Hung_mod pc_fetch <= 32'h0000_0ffc;
			//pc_fetch <= 32'h0000_03fc;
			pc_fetch <= 32'h0000_8000;
		end
		else if(pc_halt)
			pc_fetch <= pc_fetch;
		else
			pc_fetch <= pc_in_fix;
	end
	
	assign	pc_in = pc_sel ? (pc_fetch + 32'h4) : target_predict;
	assign 	pc_in_fix = pc_fix ? actual_pc : pc_in;	
/*	
	IMEM	IMEM_U
	(
	.clk(clk_l1),
	.*
	);
*/
	IL1_Cache	IL1_DUT
	(
	.*,
	.pc(pc_fetch),
	.inst_fetch(inst),
	.inst_replace_req(inst_replace_check),
	.data_replace_req(data_replace_check)	
	);
	
	assign	i_pp_fetch_dec.pc = pc_fetch;
	assign 	i_pp_fetch_dec.inst = br_update_ex.wrong ? 32'h00007033 : inst;

//=============================Decode Stage============================	
//=====================================================================	
	assign 	i_pp_dec_ex.pc = o_pp_fetch_dec.pc;
	assign 	i_pp_dec_ex.br_check = o_pp_fetch_dec.br_check;
	
	Register_File	REG_FILE
	(
	.rs1_out(i_pp_dec_ex.rs1_out),
	.rs2_out(i_pp_dec_ex.rs2_out),
	.rs1(i_pp_dec_ex.rs1),
	.rs2(i_pp_dec_ex.rs2),
	.rd(o_pp_mem_wb.rd),
	.reg_wen(o_pp_mem_wb.control_signals.reg_wen),
	.clk(clk_l1),
	.*
	);	

	Decoder	DEC_U
	(
	.control_dec(raw_control_signals),
	.rs1(i_pp_dec_ex.rs1),
	.rs2(i_pp_dec_ex.rs2),
	.rd(i_pp_dec_ex.rd),
	.inst_raw(o_pp_fetch_dec.inst)
	);
	
	assign 	i_pp_dec_ex.control_signals = (br_update_ex.wrong || wrong_dl) ? '0 : raw_control_signals;   
	
//============================Execute Stage============================	
//=====================================================================		
	assign 	i_pp_ex_mem.control_signals = o_pp_dec_ex.control_signals.control_mem;
	assign 	i_pp_ex_mem.rd = o_pp_dec_ex.rd;
	
	ALU_RVS192	ALU_U
	(
	.imm_ex(o_pp_dec_ex.control_signals.imm_dec),
	.pc_ex(o_pp_dec_ex.pc),
	.alu_out(i_pp_ex_mem.alu_out),
	.alu_op(o_pp_dec_ex.control_signals.alu_op),
//	.swap_j(o_pp_dec_ex.control_signals.swap_j),
	.branch_capture(o_pp_dec_ex.control_signals.branch_capture),
	.jal(o_pp_dec_ex.control_signals.jal),
	.jalr(o_pp_dec_ex.control_signals.jalr),
	.*
	);		

	Branch_Handling	BRH_U
	(
//	.actual_pc(i_pp_ex_mem.actual_pc),
	.br_check_ex(o_pp_dec_ex.br_check),
//	.swap_j(o_pp_dec_ex.control_signals.swap_j),
	.branch_capture(o_pp_dec_ex.control_signals.branch_capture),
	.non_condition(o_pp_dec_ex.control_signals.jal || o_pp_dec_ex.control_signals.jalr),
	.branch_kind(o_pp_dec_ex.control_signals.branch_kind),							
	.imm_ex(o_pp_dec_ex.control_signals.imm_dec),
	.pc_ex(o_pp_dec_ex.pc),
	.*
	);	
	
	Forwarding_Unit FW_U
	(
	.rs1_ex(o_pp_dec_ex.rs1),
	.rs2_ex(o_pp_dec_ex.rs2),
	.rd_mem(o_pp_ex_mem.rd),
	.rd_wb(o_pp_mem_wb.rd),
	.reg_wen_mem(o_pp_ex_mem.control_signals.control_wb.reg_wen),
	.reg_wen_wb(o_pp_mem_wb.control_signals.reg_wen),
	.alu_in1_sel(o_pp_dec_ex.control_signals.alu_in1_sel),
	.alu_in2_sel(o_pp_dec_ex.control_signals.alu_in2_sel),
	.wb_mem(o_pp_ex_mem.control_signals.control_wb.wb_sel),
	.cpu_write(o_pp_dec_ex.control_signals.control_mem.cpu_write),
	.*
	);	

//	OP_1		
	always_comb begin
		alu_in1 = '0; 
		unique case(fw_sel_1)
			2'b00:	alu_in1	= o_pp_dec_ex.rs1_out;
			2'b01:	alu_in1 = o_pp_dec_ex.pc;
			2'b10:	alu_in1 = o_pp_ex_mem.alu_out;
			2'b11:	alu_in1 = data_wb;
		endcase		
	end
	
//	OP_2
	always_comb begin
		alu_in2 = '0;
		unique case(fw_sel_2)
		2'b00:	alu_in2 = o_pp_dec_ex.rs2_out;
		2'b01:	alu_in2 = o_pp_dec_ex.control_signals.imm_dec;
		2'b10:	alu_in2 = o_pp_ex_mem.alu_out; 
		2'b11:	alu_in2 = data_wb;
		endcase
	end

// 	MEM FIX
	always_comb begin
		i_pp_ex_mem.rs2_out_fix = o_pp_dec_ex.rs2_out;
		if(mem_fix == 2'b01)
			i_pp_ex_mem.rs2_out_fix = data_wb;
		else if(mem_fix == 2'b10)
			i_pp_ex_mem.rs2_out_fix = o_pp_ex_mem.alu_out;
	end
		
//=============================Memory Stage============================	
//=====================================================================		
	assign 	i_pp_mem_wb.control_signals = o_pp_ex_mem.control_signals.control_wb;
	assign	i_pp_mem_wb.rd = o_pp_ex_mem.rd;
	assign 	i_pp_mem_wb.alu_out = o_pp_ex_mem.alu_out;

  //-------------------------------------------------------------------
  //Add support for Peri Interface
  //assign peri_halt = 1'b0;  //Mod this

  logic mem_read, mem_write, peri_read, peri_write;
  logic [DATA_LENGTH-1:0]    //datar_peri, dataw_peri;
                             peri_read_data, peri_write_data; 
  logic                      peri_ena;
  //assign mem_read = o_pp_ex_mem.control_signals.cpu_read;
  //assign mem_write = o_pp_ex_mem.control_signals.cpu_write;
  //assign peri_read = 1'b0;
  //assign peri_write = 1'b0;
  always_comb begin      
    //mem_read = 1'b0;
    //peri_read = 1'b0;
    //if(o_pp_ex_mem.control_signals.cpu_read)
    //begin
    //  if(o_pp_ex_mem.alu_out < 32'h8000)
    //    mem_read = 1'b1;
    //  else
    //    peri_read = 1'b1;
    //end else begin
    //  mem_read = 1'b0;
    //  peri_read = 1'b0;
    //end

    ////mem_write = 1'b0;
    ////peri_write = 1'b0;
    //if(o_pp_ex_mem.control_signals.cpu_write)
    //begin
    //  if(o_pp_ex_mem.alu_out < 32'h8000)
    //    mem_write = 1'b1;
    //  else
    //    peri_write = 1'b1;
    //end
    //else begin
    //  mem_write = 1'b0;
    //  peri_write = 1'b0;
    //end
  end

  always_comb begin
    if(o_pp_ex_mem.control_signals.cpu_write && (o_pp_ex_mem.alu_out < 32'h8000))
      mem_write = 1'b1;
    else
      mem_write = 1'b0;

    if(o_pp_ex_mem.control_signals.cpu_read && (o_pp_ex_mem.alu_out < 32'h8000))
      mem_read = 1'b1;
    else
      mem_read = 1'b0;
  end

  always_comb begin
    if(o_pp_ex_mem.control_signals.cpu_write && (o_pp_ex_mem.alu_out >= 32'h8000))
      peri_write = 1'b1;
    else
      peri_write = 1'b0;

    if(o_pp_ex_mem.control_signals.cpu_read && (o_pp_ex_mem.alu_out >= 32'h8000))
      peri_read = 1'b1;
    else
      peri_read = 1'b0;
  end

  assign peri_halt_raw = peri_read | peri_write;
  assign peri_halt = peri_halt_raw & ~peri_ena;
  //-------------------------------------------------------------------
  
	DataGen	DG_U
	(
	.data_type(o_pp_ex_mem.control_signals.mem_gen),
	.data_out(i_pp_mem_wb.mem_out),
	.*
	);	
/*	
	DMEM	DMEM_U
	(
	.clk(clk_l1),
	.*,
	.alu_mem(o_pp_ex_mem.alu_out),
	.data_w(i_pp_mem_wb.mem_out),
	.mem_wen(o_pp_ex_mem.control_signals.cpu_write)
	);	
*/
	DL1_Cache	DL1_DUT
	(
	//Hung_mod_peri.cpu_read(o_pp_ex_mem.control_signals.cpu_read),
	//Hung_mod_peri.cpu_write(o_pp_ex_mem.control_signals.cpu_write),
	.cpu_read(mem_read),
	.cpu_write(mem_write),
	.data_write(i_pp_mem_wb.mem_out),
	.data_read(data_r),
	.alu_out(o_pp_ex_mem.alu_out),
	.inst_replace_req(inst_replace_check),
	.data_replace_req(data_replace_check),	
	.L2_full_flag(full_flag),
	.*
	);
	
	//Hung_mod_peri assign 	data_in = o_pp_ex_mem.control_signals.cpu_read ? data_r : o_pp_ex_mem.rs2_out_fix;
	//assign 	data_in = o_pp_ex_mem.control_signals.cpu_read ? (peri_read ? datar_peri : data_r) : o_pp_ex_mem.rs2_out_fix;
	assign 	data_in = o_pp_ex_mem.control_signals.cpu_read ? (peri_read ? peri_read_data : data_r) : (peri_write ? peri_write_data : o_pp_ex_mem.rs2_out_fix);
	
  ahb_peri_itf  
  //#(
  //  //Using default parameter
  //)
  ahb_peri_itf
  (
    //.peri_out(),
    //.peri_in(),
    //.peri_dec_err(),
    //.peri_ena(),
  	.peri_addr(o_pp_ex_mem.alu_out),
  	//.peri_read_data(),
  	//.peri_read(),
  	.peri_write_data(i_pp_mem_wb.mem_out),	
  	//.peri_write(),
  	//.clk_l2(clk),
  	.*
  );
//==========================Write Back Stage===========================	
//=====================================================================			
	
	assign data_wb = o_pp_mem_wb.control_signals.wb_sel ? o_pp_mem_wb.alu_out : o_pp_mem_wb.mem_out;
	
//=========================L2 Cache + Memory===========================
//=====================================================================		
	L2_Cache	L2_DUT
	(
	.dirty_addr({dl1_dirty_addr, {(BYTE_OFFSET+WORD_OFFSET){1'b0}}}),
	.alu_out(o_pp_ex_mem.alu_out),
	.pc(pc_fetch),		
	.cpu_read(o_pp_ex_mem.control_signals.cpu_read),
	.*
	);

	//Memory 		MEM_DUT
	//(
	//.*
	//);
endmodule	
	
//=====================================================================	
//=====================================================================	
		`include "D:/Project/renas-mcu/RISC-V/RVS192/BPU.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/Register_File.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/Decoder.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/ALU_RVS192.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/Branch_Handling.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/Forwarding_Unit.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/Datagen.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/RANDOM.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/ALRU.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/Victim_Cache.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/DualPort_SRAM.sv"	
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/IL1_Controller.sv" 
		`include "D:/Project/renas-mcu/RISC-V/RVS192/IL1_Cache.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/DL1_Controller.sv" 
		`include "D:/Project/renas-mcu/RISC-V/RVS192/DL1_Cache.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/Check_Set_L2.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/Write_Buffer_L2.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/L2C_Controller.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/L2_Cache.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/Configurable_Mux_Write.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/Configurable_Multiplexer.sv"
  	`include "D:/Project/renas-mcu/RISC-V/RVS192/Write_Buffer.sv"
		`include "D:/Project/renas-mcu/RISC-V/RVS192/Memory.sv"
//=====================================================================	
//=====================================================================	
	
module ahb_peri_itf
#(
parameter	DATA_LENGTH = 32,
parameter 	ADDR_LENGTH = 32
)
(
  //AHB-ITF
  output  mas_send_type                           peri_out,
  input   slv_send_type                           peri_in,
  //Interrupt Handler
  output logic                                    peri_dec_err,
  output logic                                    peri_ena,
  //RISC-ITF
	input 	[ADDR_LENGTH-1:0]		                    peri_addr,
  //Read
	output  logic	[DATA_LENGTH-1:0]					        peri_read_data,
	input 												                  peri_read,
  //Write
	input 	[DATA_LENGTH-1:0]		                    peri_write_data,	
	input 												                  peri_write,
	input 											                    clk,
	input 											                    rst_n
);
  //------------------------------------------------------------------------------
	logic									                          write_res;	
	logic										                        peri_res;
  logic                                           direction;
  //enum logic [1:0] {IDLE_D, NONSEQ_D, SEQ_D, BUSY_D}      state, n_state;
  enum logic [1:0] {IDLE_D, NONSEQ_D}             state, n_state;
  //------------------------------------------------------------------------------
  //------------------------------------------------------------------------------
  
  always_ff @(posedge clk, negedge rst_n) 
  begin
    if(!rst_n)
    begin
      direction <= 1'b0;
	  end
    else if(state == IDLE)
    begin
      if(peri_read)
        direction <= 1'b0;
      else if(peri_write)  //DEBUG
        direction <= 1'b1;
      else 
        direction <= 1'b0;
    end
  end

  //------------------------------------------------------------------------------
  assign peri_out.hwrite    = direction;
  assign peri_out.hburst    = SINGLE; 
  assign peri_out.haddr     = peri_addr; 
  assign peri_out.hsize     = WORD;
  assign peri_out.hmastlock = 1'b0;
  assign peri_out.hprot     = 4'h0;
  assign peri_out.hwdata    = peri_write_data;

  assign read_res = ~direction & peri_in.hreadyout;
  assign write_res = direction & peri_in.hreadyout;
  assign peri_read_data = peri_in.hrdata;
  assign peri_dec_err = peri_in.hreadyout & peri_in.hresp;

  always_ff @(posedge clk, negedge rst_n)
  begin
    if(!rst_n)
      state <= IDLE_D;
    else
      state <= n_state;
  end
  
  always_comb begin
    //direction = 1'b0;
    //Hung_mod n_state = IDLE_D;
    //Hung_mod peri_out.htrans = IDLE;
    peri_ena = 1'b0;
    unique case(state)
    IDLE_D: begin
      peri_out.htrans = IDLE;
      if(peri_read || peri_write) begin
        //Hung_mod peri_out.htrans = NONSEQ;
        n_state = NONSEQ_D;
      end
      else
        n_state = state;
    end
    NONSEQ_D: begin
      peri_out.htrans = NONSEQ;
      if((peri_read && read_res) || (peri_write && write_res)) 
      begin
		    n_state = IDLE_D;
        peri_ena = 1'b1;
      end
      else
        n_state = state;
    end
    default: n_state = state;
    endcase
  end

endmodule: ahb_peri_itf
