//////////////////////////////////////////////////////////////////////////////////
// File Name: 		renas_mcu_top.sv
// Function:		  Top Module for renas mcu
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   10.04.2021  hungbk99  First Creation
//////////////////////////////////////////////////////////////////////////////////

`include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_define.h"
`include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_result/AHB_bus.sv"
`include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192.sv"
`include "D:/Project/renas-mcu/MMEM/renas_memory.sv"
module renas_mcu_top
(
  input                                 clk,
	                                      clk_l1, //Delay clock used for Cache
			                                  clk_l2,
                                        clk_mem,
                                        rst_n

);
  //==============================================================================
  //-------------------------------------------------------------------
  //CPU 
  //-------------------------------------------------------------------
  //INST-AHB bus
  mas_send_type           iahb_out_1;
  mas_send_type           iahb_out_2;
  slv_send_type           iahb_in_1;
  slv_send_type           iahb_in_2;
  //Interrupt Handler
  logic                    inst_dec_err;
  //-------------------------------------------------------------------
  //DATA-AHB bus
  mas_send_type                         dahb_out_1;
  mas_send_type                         dahb_out_2;
  mas_send_type                         peri_ahb_out;
  slv_send_type                         dahb_in_1;
  slv_send_type                         dahb_in_2;
  slv_send_type                         peri_ahb_in;
  //Interrupt Handler
  logic                                 data_dec_err,
                                        peri_dec_err;
  //-------------------------------------------------------------------
	//WB Buffer
  logic [2*DATA_LENGTH-BYTE_OFFSET-1:0] wb_data;	
	logic 											          wb_req,
												                wb_ack,	
												                full_flag,
	                                      external_halt;
  //==============================================================================
  //-------------------------------------------------------------------
  //AHB-Bus: AHB-lite -> single slave-single master only
  //-------------------------------------------------------------------
  logic [1:0]   hprior_master_peri,
                hprior_master_inst_1,
                hprior_master_inst_2,
                hprior_master_data_1,
                hprior_master_data_2;
  
  logic         dmem_hsel,
                imem_hsel,
                peri_hsel;
 
  logic         hsel_slave_peri,
                hsel_slave_inst_1,
                hsel_slave_inst_2,
                hsel_slave_data_1,
                hsel_slave_data_2;

  mas_send_type dmem_in_1;
  mas_send_type dmem_in_2;
  slv_send_type dmem_out_1;
  slv_send_type dmem_out_2;

  mas_send_type imem_in_1;
  mas_send_type imem_in_2;
  slv_send_type imem_out_1;
  slv_send_type imem_out_2;
  
  mas_send_type peri_apb_out;
  slv_send_type peri_apb_in;
  //==============================================================================
  //Connection
  //==============================================================================
 
  assign external_halt = 1'b0;

  //-------------------------------------------------------------------
  //Floating signals of AHB bus
  assign hprior_master_peri = '0;
  assign hprior_master_inst_1 = '0;
  assign hprior_master_inst_2 = '0;
  assign hprior_master_data_1 = '0;
  assign hprior_master_data_2 = '0;
  //-------------------------------------------------------------------

  assign dmem_hsel = hsel_slave_data_1 & hsel_slave_data_2; 
  assign imem_hsel = hsel_slave_inst_1 & hsel_slave_inst_2;
  assign peri_hsel = hsel_slave_peri;

  RVS192 renas_cpu_202
  (
    .*
  );
  AHB_bus ahb_matrix
  (
  //#INTERFACEGEN#
  //#SI#
  	.master_peri_in(),
  	.hprior_master_peri(),
  	.master_peri_out(),
  	.master_inst_in(),
  	.hprior_master_inst(),
  	.master_inst_out(),
  	.master_data_in(),
  	.hprior_master_data(),
  	.master_data_out(),
  //#MI#
  	.slave_peri_in(),
  	.hsel_slave_peri(),
  	.slave_peri_out(),
  	.slave_isnt_in(),
  	.hsel_slave_isnt(),
  	.slave_isnt_out(),
  	.slave_data_in(),
  	.hsel_slave_data(),
  	.slave_data_out(),
  	.hclk(),
  	.hreset_n()
  (
//#INTERFACEGEN#
//#SI#
	input  mas_send_type  master_peri_in,
	input  [2-1:0]  hprior_master_peri,
	output  slv_send_type  master_peri_out,
	input  mas_send_type  master_inst_in,
	input  [2-1:0]  hprior_master_inst,
	output  slv_send_type  master_inst_out,
	input  mas_send_type  master_data_in,
	input  [2-1:0]  hprior_master_data,
	output  slv_send_type  master_data_out,
//#MI#
	input  slv_send_type  slave_peri_in,
	output hsel_slave_peri,
	output mas_send_type  slave_peri_out,
	input  slv_send_type  slave_isnt_in,
	output hsel_slave_isnt,
	output mas_send_type  slave_isnt_out,
	input  slv_send_type  slave_data_in,
	output hsel_slave_data,
	output mas_send_type  slave_data_out,
	input					 hclk,
	input					 hreset_n
  AHB_bus ahb_matrix
  (
  //#INTERFACEGEN#
  //#SI#
  	.master_peri_in(peri_ahb_out),
  	.master_peri_out(peri_ahb_in),
  	.master_inst_1_in(iahb_out_1),
  	.master_inst_1_out(iahb_in_1),
  	.master_inst_2_in(iahb_out_2),
  	.master_inst_2_out(iahb_in_2),
  	.master_data_1_in(dahb_out_1),
  	.master_data_1_out(dahb_in_1),
  	.master_data_2_in(dahb_out_2),
  	.master_data_2_out(dahb_in_2),
  //#MI#
  	.slave_peri_in(peri_apb_in),
  	.slave_peri_out(peri_apb_out),
  	.slave_inst_1_in(imem_out_1),
  	.slave_inst_1_out(imem_in_1),
  	.slave_inst_2_in(imem_out_2),
  	.slave_inst_2_out(imem_in_2),
  	.slave_data_1_in(dmem_out_1),
  	.slave_data_1_out(dmem_in_1),
  	.slave_data_2_in(dmem_out_2),
  	.slave_data_2_out(dmem_in_2),
    .hclk(cache_clk),
    .hreset_n(rst_n),
    .*
  );

  renas_memory  mmem
  (
    .imem_hsel(),
    .imem_in(),
    .imem_out(),
    
    .dmem_hsel(),
    .dmem_in(),
    .dmem_out(),

    .clk_l2(),
	  .clk_mem(),
	  .rst_n()
  );
endmodule: renas_mcu_top
