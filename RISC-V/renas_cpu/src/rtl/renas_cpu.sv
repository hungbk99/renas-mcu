//////////////////////////////////////////////////////////////////////////////////
// File Name: 		renas_cpu.sv
// Function:		  Top Module for renas cpu
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   14.03.2021  hungbk99  Reused from renas cpu
//                              Remove L2 Cache 
//                              Remove support for inclusive cache
//        15.03.2021  hungbk99  Add support for AHB interface
//        03.04.2021  hungbk99  Add support for peripheral access
//                              Add navigator: choosing destination for data
//        04.04.2021  hungbk99  WB Buffer would not use ahb interface
//                              -> directly connected instead
//        10.04.2021  hungbk99  Add support for WB buffer                     
//        21.04.2021  hungbk99  Modify AHB-DATA Interface
//////////////////////////////////////////////////////////////////////////////////

`include"D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/renas_user_define.h"
`include"D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/renas_package.sv"
import 	renas_package::*;
import	renas_user_parameters::*;
import  AHB_package::*;

//=====================================================================	
// Top module for renas cpu
//=====================================================================	

module 	renas_cpu
(
  //-------------------------------------------------------------------
  //INST-AHB bus
  output  mas_send_type                         iahb_out_1,
  output  mas_send_type                         iahb_out_2,
  input   slv_send_type                         iahb_in_1,
  input   slv_send_type                         iahb_in_2,
  //Interrupt Handler
  output logic                                  inst_dec_err,
  //-------------------------------------------------------------------
  //DATA-AHB bus
  output  mas_send_type                         dahb_out_1,
  output  mas_send_type                         dahb_out_2,
  output  mas_send_type                         peri_ahb_out,
  input   slv_send_type                         dahb_in_1,
  input   slv_send_type                         dahb_in_2,
  input   slv_send_type                         peri_ahb_in,
  //Interrupt Handler
  output logic                                  data_dec_err,
                                                peri_dec_err, //Hung_add_21.04.2021
  //output  icache_itf_type_s                     inst_ahb_itf, //Hung_add_15_03
  //output  logic                                 inst_dec_err,
  //output  dcache_itf_type_s                     data_ahb_itf, //Hung_add_15_03
  //output  logic                                 data_dec_err,
  //output  logic                                 peri_dec_err,
  //-------------------------------------------------------------------
	//WB Buffer
  output 	logic [2*DATA_LENGTH-BYTE_OFFSET-1:0] wb_data,	
	output	logic 											          wb_req,
	input 												                wb_ack,	
	input 												                full_flag,
  //-------------------------------------------------------------------
	input 	                                      external_halt,
			                                          clk,
			                                          cache_clk, //Delay clock used for Cache
			                                          //Hung_mod_14_03 clk_l2,
			                                          //Hung_mod_14_03 mem_clk,
			                                          rst_n
);

//====================================================================
//						    Pipelined renas
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
									            FW_halt,
                              peri_halt;  //Hung_add_21.04.2021

	control_type_ex					    raw_control_signals;

	br_update_type					    br_update_ex;
									
	logic	[DATA_LENGTH-1:0]		  data_wb;

	logic 	[INST_LENGTH-1:0]		inst;

	logic	[DATA_LENGTH-1:0]		  add_result;
									
	logic							          ge,
									            eq;
									
	logic 	[DATA_LENGTH-1:0]		branch_cal_out,
									            alu_in1,
									            alu_in2,
//									rs2_out_fix,
									            data_r,
									            data_in,
                              data_dmem,
                              data_peri;
		
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

//	CPU
	logic												                      ICC_halt;
	logic												                      DCC_halt;
	logic												                      inst_replace_req,
														                        data_replace_req;	
	logic 	[DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-1:0]	dl1_dirty_addr;													
	logic												                      L2_full_flag;
	cache_update_type									                IL2_out;
	logic 												                    inst_update_req;
	logic 	[PC_LENGTH-1:0]								            pc_up;
	logic 												                    inst_replace_il1_ack,
														                        data_replace_il1_ack;			
	logic												                      L2_inst_il1_ack,
														                        L2_inst_dl1_ack,
														                        L2_data_il1_ack,
														                        L2_data_dl1_ack;
	cache_update_type									                DL2_out;
	logic 												                    data_update_req;
	logic 	[PC_LENGTH-1:0]								            alu_out_up;	
	logic	  [DATA_LENGTH-1:0]							            dirty_data1;
	logic	  [DATA_LENGTH-1:0]							            dirty_data2;
	logic 	[DATA_LENGTH-1:0]							            dirty_addr;				// DL1 chi gui tag va index do do phai them bit 0 truoc khi su dung
	logic 	 											                    dirty_req;
	logic												                      dirty_ack;
	logic 	 											                    dirty_replace;	
	//Hung_mod_04.04.2021 logic 	[2*DATA_LENGTH-BYTE_OFFSET-1:0]				    wb_data;	
	//Hung_mod_04.04.2021 logic		 										                      wb_req;
	//Hung_mod_04.04.2021 logic 												                    wb_ack;	
	//Hung_mod_04.04.2021 logic 												                    full_flag;
	logic 												                    inst_replace_dl1_ack,
														                        data_replace_dl1_ack;		
//	To both IL1 and DL1
	logic												                      inst_replace_check,
														                        data_replace_check;
	logic 	[L2_TAG_LENGTH+$clog2(L2_CACHE_LINE)-1:0]	inst_addr_replace,
														                        data_addr_replace;																
	
	logic 	[INST_LENGTH-1:0]							            inst_mem_read;
	logic 	[DATA_LENGTH-1:0]							            data_mem_read;
	logic												                      inst_res,		//	Use for synchoronous
														                        data_res;
	logic	[DATA_LENGTH-1:0]							              data_mem_write,
													  	                      data_addr;
	logic 	[PC_LENGTH-1:0]								            inst_addr;
	logic 												                    inst_read_req,
														                        data_read_req,
														                        data_write_req;
//=============================Navigator===============================	         
//=====================================================================	
  logic peri_read;
  logic peri_write;
  logic peri_access;
  //Hung_add_21.04.2021
  logic mem_read;
  logic mem_write;
  //Hung_add_21.04.2021
  localparam PERI_BOUNDARY = 32'h011C;
	//Hung_mod_03.04.2021 .cpu_read(o_pp_ex_mem.control_signals.cpu_read),
	//Hung_mod_03.04.2021 .cpu_write(o_pp_ex_mem.control_signals.cpu_write),

  assign peri_access = (o_pp_ex_mem.alu_out <= PERI_BOUNDARY) ? 1'b1 : 1'b0;
    
  always_comb begin
    peri_read = 1'b0;
    peri_write = 1'b0;
    mem_read = 1'b0;
    mem_write = 1'b0;
    if(o_pp_ex_mem.control_signals.cpu_read) begin
      if(peri_access) 
        peri_read = 1'b1;
      else  
        mem_read = 1'b1;
    end

    if(o_pp_ex_mem.control_signals.cpu_write) begin
      if(peri_access) 
        peri_write = 1'b1;
      else
        mem_write = 1'b1;
    end
  end
//====================================================================
//===========================Halt Control=============================
	//Hung_mod_21.04.2021 assign 	pc_halt = DCC_halt || ICC_halt || FW_halt || external_halt;
	//Hung_mod_21.04.2021 assign 	fetch_dec_halt = pc_halt;
	//Hung_mod_21.04.2021 assign 	dec_ex_halt = FW_halt || DCC_halt || external_halt;
	//Hung_mod_21.04.2021 assign 	dec_ex_flush = ICC_halt;
	//Hung_mod_21.04.2021 assign 	ex_mem_halt =  DCC_halt || external_halt;
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
	
//============================Fetch Stage=============================
//====================================================================
	always_ff @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			o_pp_fetch_dec <= '0;
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
			pc_fetch <= 32'h0000_0ffc;
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
	.clk(cache_clk),
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
	
	register_file	REG_FILE
	(
	.rs1_out(i_pp_dec_ex.rs1_out),
	.rs2_out(i_pp_dec_ex.rs2_out),
	.rs1(i_pp_dec_ex.rs1),
	.rs2(i_pp_dec_ex.rs2),
	.rd(o_pp_mem_wb.rd),
	.reg_wen(o_pp_mem_wb.control_signals.reg_wen),
	.clk(cache_clk),
	.*
	);	

	decoder	DEC_U
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
	
	alu_renas	alu_U
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

	branch_handling	BRH_U
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
	
	forwarding_unit FW_U
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

	datagen	DG_U
	(
	.data_type(o_pp_ex_mem.control_signals.mem_gen),
	.data_out(i_pp_mem_wb.mem_out),
	.*
	);	
/*	
	DMEM	DMEM_U
	(
	.clk(cache_clk),
	.*,
	.alu_mem(o_pp_ex_mem.alu_out),
	.data_w(i_pp_mem_wb.mem_out),
	.mem_wen(o_pp_ex_mem.control_signals.cpu_write)
	);	
*/
	DL1_Cache	DL1_DUT
	(
	//Hung_mod_03.04.2021 .cpu_read(o_pp_ex_mem.control_signals.cpu_read),
	//Hung_mod_03.04.2021 .cpu_write(o_pp_ex_mem.control_signals.cpu_write),
  .cpu_read(mem_read),
  .cpu_write(mem_write),
	.data_write(i_pp_mem_wb.mem_out),
	//Hung_mod_21.04.2021 .data_read(data_r),
  .data_read(data_dmem),
	.alu_out(o_pp_ex_mem.alu_out),
	.inst_replace_req(inst_replace_check),
	.data_replace_req(data_replace_check),	
	.L2_full_flag(full_flag),
	.*
	);

  //Hung_mod_21.04.2021
  assign  data_r = peri_access ? data_peri : data_dmem;
  //Hung_mod_21.04.2021
  
	assign 	data_in = o_pp_ex_mem.control_signals.cpu_read ? data_r : o_pp_ex_mem.rs2_out_fix;
	
//==========================Write Back Stage===========================	
//=====================================================================			
	
	assign data_wb = o_pp_mem_wb.control_signals.wb_sel ? o_pp_mem_wb.alu_out : o_pp_mem_wb.mem_out;
	
//=========================L2 Cache + Memory===========================
//=====================================================================		
	//Hung_mod_14_03 L2_Cache	L2_DUT
	//Hung_mod_14_03 (
	//Hung_mod_14_03 .dirty_addr({dl1_dirty_addr, {(BYTE_OFFSET+WORD_OFFSET){1'b0}}}),
	//Hung_mod_14_03 .alu_out(o_pp_ex_mem.alu_out),
	//Hung_mod_14_03 .pc(pc_fetch),		
	//Hung_mod_14_03 .cpu_read(o_pp_ex_mem.control_signals.cpu_read),
	//Hung_mod_14_03 .*
	//Hung_mod_14_03 );

	//Hung_mod_14_03 Memory 		MEM_DUT
	//Hung_mod_14_03 (
	//Hung_mod_14_03 .*
	//Hung_mod_14_03 );
  assign L2_inst_il1_ack = 1'b0;  //Hung_add_14_03 remove L2 Cache
  assign L2_inst_dl1_ack = 1'b0;  //Hung_add_14_03 remove L2 Cache
  assign L2_data_il1_ack = 1'b0;  //Hung_add_14_03 remove L2 Cache
  assign L2_data_dl1_ack = 1'b0;  //Hung_add_14_03 remove L2 Cache
	assign inst_replace_check = '0;  //Hung_add_14_03 remove support for inclusive cache
	assign data_replace_check = '0;  //Hung_add_14_03 remove support for inclusive //cache
	assign inst_addr_replace  = '0;  //Hung_add_14_03 remove support for inclusive //////cache
	assign data_addr_replace  = '0;  //Hung_add_14_03 remove support for inclusive //////cache 															
//===========================AHB Interface=============================	         
//=====================================================================	
  ahb_inst_interface  ahb_inst_itf 
  (
	  .pc(pc_fetch),
    .*
  );

  ahb_data_interface  ahb_data_itf
  (
    .data_peri_out(data_peri),
    .data_peri_in(i_pp_mem_wb.mem_out),
	  .alu_out(o_pp_ex_mem.alu_out),
    .dirty_done(dirty_ack),
	  .*
  );

endmodule: renas_cpu	

//=====================================================================	
// AHB-INST Interface: WRAP8 only
//=====================================================================	

module ahb_inst_interface
(
  //IL1 Cache
  output  cache_update_type       IL2_out,
  input   [PC_LENGTH-1:0]         pc,
  input                           inst_update_req,
  //AHB bus
  output  mas_send_type           iahb_out_1,
  output  mas_send_type           iahb_out_2,
  input   slv_send_type           iahb_in_1,
  input   slv_send_type           iahb_in_2,
  //Interrupt Handler
  output logic                    inst_dec_err,
  //System
  input                           cache_clk,
  input                           rst_n
);
//---------------------------------------------------------------------
//Internal Signals
//---------------------------------------------------------------------
  logic [2:0]   trans_count; 
  htrans_type   htrans_current_state, 
                htrans_next_state;
  logic         hlast,
                trans_enable;
  logic [2:0]   wrap_addr;
  logic         sample_req;
//---------------------------------------------------------------------
//AHB-INST
//---------------------------------------------------------------------
  assign iahb_out_1.hwrite = 0;
  assign iahb_out_1.hburst = WRAP8; 
  assign iahb_out_1.htrans = htrans_current_state;
  assign iahb_out_1.haddr = {pc[31:6], 1'b0, wrap_addr, 2'b0};
  assign iahb_out_1.hsize = WORD;
  assign iahb_out_1.hmastlock = 1'b0;
  assign iahb_out_1.hprot = 4'h0;
  assign iahb_out_1.hwdata = '0;

  assign iahb_out_2.hwrite = 0;
  assign iahb_out_2.hburst = WRAP8; 
  assign iahb_out_2.htrans = htrans_current_state;
  assign iahb_out_2.haddr = {pc[31:6], 1'b1, wrap_addr, 2'b0};
  assign iahb_out_2.hsize = WORD;
  assign iahb_out_2.hmastlock = 1'b0;
  assign iahb_out_2.hprot = 4'h0;
  assign iahb_out_2.hwdata = '0;

  assign IL2_out.update = iahb_in_1.hreadyout && iahb_in_2.hreadyout;
  assign IL2_out.addr_update = wrap_addr;
  assign IL2_out.w1_update = iahb_in_1.hrdata;
  assign IL2_out.w2_update = iahb_in_2.hrdata;

  always_ff @(posedge cache_clk, negedge rst_n)
  begin
    if(!rst_n) begin
      trans_count <= '0;
      wrap_addr <= '0;
    end
    else if(hlast || sample_req)
    begin
      trans_count <= '0;
      wrap_addr <= pc[4:2];
    end
    else if(trans_enable && IL2_out.update) //Timing problem???
    begin
      trans_count <= trans_count + 1;
      wrap_addr <= wrap_addr + 1;
    end
  end

  assign hlast = (trans_count == 7) ? 1'b1 : 1'b0;

  always_ff @(posedge cache_clk, negedge rst_n)
  begin
    if(!rst_n)
      htrans_current_state <= IDLE;
    else
      htrans_current_state <= htrans_next_state;
  end

  always_comb begin
    inst_dec_err = 1'b0;
    trans_enable = 1'b0;
    htrans_next_state = IDLE;
    sample_req = 1'b0;
    unique case(htrans_current_state)
      IDLE: begin
        sample_req = 1'b1;
        if(inst_update_req)
          htrans_next_state = NONSEQ;
        else
          htrans_next_state = htrans_current_state;
      end
      BUSY: begin
      //Does not support this yet...
      end
      NONSEQ: begin
        trans_enable = 1'b1;
        if(iahb_in_1.hreadyout ^ iahb_in_2.hreadyout)
          inst_dec_err = 1'b1;
        else if (iahb_in_1.hreadyout && iahb_in_2.hreadyout)
          htrans_next_state = SEQ;
        else
          htrans_next_state = htrans_current_state;
      end
      SEQ: begin
        trans_enable = 1'b1;
        if(iahb_in_1.hreadyout ^ iahb_in_2.hreadyout) begin
          inst_dec_err = 1'b1;
          htrans_next_state = htrans_current_state;
        end
        else if((iahb_in_1.hreadyout && iahb_in_1.hresp) || (iahb_in_1.hreadyout && iahb_in_1.hresp)) begin
          htrans_next_state = IDLE;
          inst_dec_err = 1'b1;
        end
        else if((iahb_in_1.hreadyout && !iahb_in_1.hresp) && (iahb_in_1.hreadyout && !iahb_in_1.hresp)) begin
          if(hlast && inst_update_req) //Debug
            htrans_next_state = NONSEQ;
          else if(hlast && !inst_update_req)
            htrans_next_state = IDLE;
          else
            htrans_next_state = htrans_current_state;
        end
        else
          htrans_next_state = htrans_current_state;
      end
    endcase
  end

endmodule: ahb_inst_interface

//=====================================================================	
// AHB-DATA Interface: 
//  * WRAP8 only when access memory
//  * SINGLE only when access spi
//=====================================================================	

module ahb_data_interface
(
  //Hung_add_21.04.2021
  output [DATA_LENGTH-1:0]                          data_peri_out,
	input [DATA_LENGTH-1:0]								            data_peri_in,
  input                                             peri_read,
                                                    peri_write,
  output  logic                                     peri_halt,
  //Hung_add_21.04.2021
  //DL1 Cache
  output  cache_update_type                         DL2_out,
  input   [DATA_LENGTH-1:0]                         alu_out,
  input                                             data_update_req,
  input                                             //mem_read,
                                                    //mem_write,
                                                    dirty_req,
                                                    dirty_replace,
  //Hung_mod_21.04.2021output                                            dirty_ack,
  output logic                                      dirty_done,
	input [DATA_LENGTH-1:0]								            dirty_data1,
	input [DATA_LENGTH-1:0]								            dirty_data2,
	input [DATA_LENGTH-BYTE_OFFSET-WORD_OFFSET-1:0]		dl1_dirty_addr,	
  //AHB bus
  output  mas_send_type                             dahb_out_1,
  output  mas_send_type                             dahb_out_2,
  output  mas_send_type                             peri_ahb_out,
  input   slv_send_type                             dahb_in_1,
  input   slv_send_type                             dahb_in_2,
  input   slv_send_type                             peri_ahb_in,
  //Interrupt Handler
  output logic                                      data_dec_err,
                                                    peri_dec_err,
  //System
  input                                             cache_clk,
  input                                             rst_n
);
//---------------------------------------------------------------------
//Internal Signals
//---------------------------------------------------------------------
  logic [2:0]   trans_count; 
  htrans_type   htrans_current_state, 
                htrans_next_state;
  logic         hlast,
                trans_enable;
  logic [2:0]   wrap_addr;
  logic         direction;
  logic         addr_sample;
  logic         peri_direction;
//---------------------------------------------------------------------
//AHB-INST
//---------------------------------------------------------------------
  assign dahb_out_1.hwrite = direction;
  assign dahb_out_1.hburst = WRAP8; 
  assign dahb_out_1.htrans = htrans_current_state;
  assign dahb_out_1.haddr = {alu_out[31:6], 1'b0, wrap_addr, 2'b0};
  assign dahb_out_1.hsize = WORD;
  assign dahb_out_1.hmastlock = 1'b0;
  assign dahb_out_1.hprot = 4'h0;
  assign dahb_out_1.hwdata = dirty_data1;

  assign dahb_out_2.hwrite = direction;
  assign dahb_out_2.hburst = WRAP8; 
  assign dahb_out_2.htrans = htrans_current_state;
  assign dahb_out_2.haddr = {alu_out[31:6], 1'b1, wrap_addr, 2'b0};
  assign dahb_out_2.hsize = WORD;
  assign dahb_out_2.hmastlock = 1'b0;
  assign dahb_out_2.hprot = 4'h0;
  assign dahb_out_2.hwdata = dirty_data2;

  assign DL2_out.update = ~dirty_replace & dahb_in_1.hreadyout & dahb_in_2.hreadyout;
  assign DL2_out.addr_update = wrap_addr;
  assign DL2_out.w1_update = dahb_in_1.hrdata;
  assign DL2_out.w2_update = dahb_in_2.hrdata;
 
  //Hung_add_21.04.2021
  assign dirty_done = hlast && dirty_replace; 

  assign peri_ahb_out.hwrite = peri_direction;
  assign peri_ahb_out.hburst = SINGLE; 
  //assign peri_ahb_out.htrans = htrans_current_state;
  assign peri_ahb_out.haddr = {alu_out[31:2], 2'b0};
  assign peri_ahb_out.hsize = WORD;
  assign peri_ahb_out.hmastlock = 1'b0;
  assign peri_ahb_out.hprot = 4'h0;
  assign peri_ahb_out.hwdata = data_peri_in;
  assign data_peri_out = peri_ahb_in.hrdata;

  assign peri_halt = (peri_read | peri_write) & ~peri_ahb_in.hreadyout;

  always_comb begin
    peri_direction = 1'b0;
    if(peri_read)
      peri_direction = 1'b0;
    else if(peri_write)
      peri_direction = 1'b1;
  end

  always_ff @(posedge cache_clk, negedge rst_n)
  begin
    if(!rst_n) begin
      peri_ahb_out.htrans <= IDLE;
      peri_dec_err <= 1'b1;
    end
    else if(peri_read || peri_write)
    begin 
      peri_ahb_out.htrans <= NONSEQ;
      peri_dec_err <= 1'b0;
      if(peri_ahb_in.hreadyout) begin
        if(!peri_ahb_in.hresp)
          peri_ahb_out.htrans <= IDLE;
        else 
          peri_dec_err <= 1'b1;
      end
    end
  end
  //-------------------------------------------------------------------------------------
  //trans_count: count the number of transastion been sent
  //wwrap_addr: start at 0 when doing the dirty replace
  //            start at alu_out when doing the data replace
  //-------------------------------------------------------------------------------------

  always_ff @(posedge cache_clk, negedge rst_n)
  begin
    if(!rst_n) begin
      trans_count <= '0;
      wrap_addr <= '0;
      direction <= 1'b0;
    end
    else if(hlast || addr_sample)
    begin
      trans_count <= '0;
      if(!dirty_replace) 
      begin
        wrap_addr <= alu_out[4:2];
        //Hung_mod_21.04.2021 direction <= 1'b1;
        direction <= 1'b0;
      end
      else begin
        //Debug dirty_replace <= '0;
        //Hung_mod_10.04.2021
        wrap_addr <= '0;
        //Hung_mod_10.04.2021
        //Hung_mod_21.04.2021 direction <= 1'b0;
        direction <= 1'b1;
      end
    end
    else if(trans_enable && dahb_in_1.hreadyout && dahb_in_2.hreadyout) //Timing problem???
    begin
      trans_count <= trans_count + 1;
      wrap_addr <= wrap_addr + 1;
    end
  end

  assign hlast = (trans_count == 7) ? 1'b1 : 1'b0;

  always_ff @(posedge cache_clk, negedge rst_n)
  begin
    if(!rst_n)
      htrans_current_state <= IDLE;
    else
      htrans_current_state <= htrans_next_state;
  end

  always_comb begin
    data_dec_err = 1'b0;
    trans_enable = 1'b0;
    addr_sample = 1'b0;
    htrans_next_state = IDLE; 
    unique case(htrans_current_state)
      IDLE: begin
        //Hung_mod_21.04.2021 if(data_update_req) begin
        if(data_update_req || dirty_replace) begin
          htrans_next_state = NONSEQ;
          addr_sample = 1'b1;
        end
        else
          htrans_next_state = htrans_current_state;
      end
      BUSY: begin
      //Does not support this yet...
      end
      NONSEQ: begin
        trans_enable = 1'b1;
        if(dahb_in_1.hreadyout ^ dahb_in_2.hreadyout)
        begin
          data_dec_err = 1'b1;
          htrans_next_state = htrans_current_state;
        end
        else if (dahb_in_1.hreadyout && dahb_in_2.hreadyout)
          htrans_next_state = SEQ;
        else
          htrans_next_state = htrans_current_state;
      end
      SEQ: begin
        trans_enable = 1'b1;
        if(dahb_in_1.hreadyout ^ dahb_in_2.hreadyout)
          data_dec_err = 1'b1;
        else if((dahb_in_1.hreadyout && dahb_in_1.hresp) || (dahb_in_1.hreadyout && dahb_in_1.hresp)) begin
          htrans_next_state = IDLE;
          data_dec_err = 1'b1;
        end
        else if((dahb_in_1.hreadyout && !dahb_in_1.hresp) && (dahb_in_1.hreadyout && !dahb_in_1.hresp)) begin
          //Hung_mod_21.04.2021 if(hlast && data_update_req) //Debug
          //Hung_mod_21.04.2021   htrans_next_state = NONSEQ;
          //Hung_mod_21.04.2021 else if(hlast && !data_update_req)
          if(hlast)
            htrans_next_state = IDLE;
          else
            htrans_next_state = htrans_current_state;
        end
        else
          htrans_next_state = htrans_current_state;
      end
      default: htrans_next_state = htrans_current_state;
    endcase
  end

endmodule: ahb_data_interface

//=============================Simulation==============================	
//=====================================================================	
//	`ifdef SIMULATE
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/BPU.sv"
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/register_file.sv"
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/decoder.sv"
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/alu_renas.sv"
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/branch_handling.sv"
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/forwarding_unit.sv"
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/datagen.sv"
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/RANDOM.sv"
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/ALRU.sv"
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/Victim_Cache.sv"
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/DualPort_SRAM.sv"	
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/IL1_Controller.sv" 
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/IL1_Cache.sv"
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/DL1_Controller.sv" 
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/Configurable_Mux_Write.sv"
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/Configurable_Multiplexer.sv"
	`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/Write_Buffer.sv"
		`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/DL1_Cache.sv"
//Hung_mod_1.4.2021		include"L2_cache.sv";
//	`endif
